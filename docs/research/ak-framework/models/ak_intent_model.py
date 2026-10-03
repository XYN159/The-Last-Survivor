#!/usr/bin/env python3
"""设计意图模型：从明日方舟资料算出干员/敌人逆向表与 DPS、COST 效率、SP 循环、关卡压力，
再用同一套模型检查守幻录 PR #8 现值。

只读 /workspace/research/arknights 与守幻录 git 分支，输出写到本目录 models/out/。
标注约定（写进每个输出文件的表头注释）：
  [官方公式]  游戏实际使用、资料核对过的公式（伤害 5% 保底、攻击间隔 = baseAttackTime / (攻速/100)）
  [自建模型]  我们为了看设计意图自己定义的指标（DPS、单位费用战斗力、技能平均倍率、压力比等）
用法：python3 models/ak_intent_model.py
"""
import csv, json, math, os, statistics, subprocess, io
from collections import defaultdict

AK = '/workspace/research/arknights'
REPO = '/workspace/Touhou-forgotten-defense'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'out')
os.makedirs(OUT, exist_ok=True)

DEF_GRID = [0, 100, 200, 300, 500, 800, 1000]
RES_GRID = [0, 10, 20, 30, 50, 60]
med = statistics.median


def rows(path):
    with open(os.path.join(AK, path), encoding='utf-8') as f:
        return list(csv.DictReader(f))


def fnum(x, d=0.0):
    try:
        return float(x)
    except (TypeError, ValueError):
        return d


# ---------- [官方公式] ----------
def hit_damage(atk, dmg_type, d=0.0, r=0.0):
    """单次命中伤害。物理 max(0.05A, A-D)；法术 max(0.05A, A(100-R)/100)；其他按 0。"""
    if dmg_type == 'PHYSICAL':
        return max(0.05 * atk, atk - d)
    if dmg_type == 'MAGICAL':
        return max(0.05 * atk, atk * (100 - r) / 100)
    return 0.0


def interval(bat, aspd=100.0):
    """实际攻击间隔 = baseAttackTime / (clamp(攻速,10,600)/100)。"""
    return bat / (min(max(aspd, 10), 600) / 100)


# ---------- [自建模型] ----------
def dps(atk, bat, dmg_type, d=0.0, r=0.0, mult=1.0):
    return hit_damage(atk * mult, dmg_type, d, r) / interval(bat)


def write(name, header, data, note):
    p = os.path.join(OUT, name)
    with open(p, 'w', encoding='utf-8', newline='') as f:
        f.write('# ' + note + '\n')
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(data)
    return p


summary = []


def say(*a):
    s = ' '.join(str(x) for x in a)
    summary.append(s)
    print(s)


# ---------- 1. 干员逆向表 ----------
const = json.load(open(os.path.join(AK, 'raw/excel/gamedata_const.json'), encoding='utf-8'))
dtype = const['subProfessionDamageTypePairs']
ops = [o for o in rows('stats/operators_maxstats.csv') if int(o['rarity']) >= 4]
for o in ops:
    o['dtype'] = dtype.get(o['subId'], 'NONE')
    for k in ('hp', 'atk', 'def_', 'res', 'cost', 'block', 'bat', 'respawn'):
        o[k] = fnum(o[k])

# 技能：每名干员取 7 级（levels[6]）数据，算 SP 循环
skills = json.load(open(os.path.join(AK, 'raw/excel/skill_table.json'), encoding='utf-8'))
chars = json.load(open(os.path.join(AK, 'raw/excel/character_table.json'), encoding='utf-8'))
skill_rows = []
op_skill_mult = {}
for o in ops:
    c = chars.get(o['id'])
    if not c:
        continue
    best = None
    for s in c.get('skills') or []:
        sk = skills.get(s.get('skillId'))
        if not sk or len(sk['levels']) < 7:
            continue
        lv = sk['levels'][6]
        sp = lv['spData']
        cost, init, dur = sp['spCost'], sp['initSp'], lv['duration'] or 0
        bb = {b['key']: b['value'] for b in lv['blackboard'] if b['value'] is not None}
        atk_up = bb.get('atk', 0.0)
        aspd_up = bb.get('attack_speed', 0.0)
        st = sp['spType']
        # 充能秒数：随时间 = spCost 秒；攻击回复 = spCost 次攻击 × 攻击间隔；受击回复按 2 秒挨一下估
        if st == 'INCREASE_WITH_TIME':
            charge = cost
        elif st == 'INCREASE_WHEN_ATTACK':
            charge = cost * o['bat']
        elif st == 'INCREASE_WHEN_TAKEN_DAMAGE':
            charge = cost * 2.0
        else:
            charge = None
        uptime = dur / (charge + dur) if (charge and dur > 0) else 0.0
        # 技能期间 DPS 倍率 ≈ (1+atk)·(1+攻速/100)，只算这两个通用键
        burst = (1 + atk_up) * (1 + aspd_up / 100)
        avg = 1 + uptime * (burst - 1)
        skill_rows.append([o['id'], o['name'], o['prof'], o['sub'], s['skillId'], lv['skillType'], st, cost, init,
                           dur, round(charge or 0, 1), round(uptime, 3), atk_up, aspd_up, round(burst, 2), round(avg, 3)])
        if lv['skillType'] == 'MANUAL' and dur > 0 and (best is None or avg > best):
            best = avg
    op_skill_mult[o['id']] = best or 1.0

write('skill_cycle.csv',
      ['id', 'name', 'prof', 'sub', 'skillId', 'skillType', 'spType', 'spCost', 'initSp', 'duration',
       'charge_s', 'uptime', 'atk_up', 'aspd_up', 'burst_mult', 'avg_mult'],
      skill_rows,
      '[自建模型] 7 级技能 SP 循环：uptime = duration/(充能秒+duration)，假定技能期间不回 SP；'
      'burst_mult 只计 blackboard 的 atk 与 attack_speed；受击回复按每 2 秒受击 1 次估')

# 按职业汇总技能循环
by_prof = defaultdict(list)
for r in skill_rows:
    if r[5] == 'MANUAL' and r[9] > 0 and r[6] == 'INCREASE_WITH_TIME':
        by_prof[r[2]].append(r)
say('## 技能循环（4–6★，7 级手动、随时间回复、有持续）')
for p, rs in sorted(by_prof.items()):
    say(f'{p}: n={len(rs)} spCost中位 {med([r[7] for r in rs])} 持续中位 {med([r[9] for r in rs])}s '
        f'覆盖率中位 {med([r[11] for r in rs]):.2f} 技能期倍率中位 {med([r[14] for r in rs]):.2f} '
        f'平均倍率中位 {med([r[15] for r in rs]):.2f}')

# ---------- 2. 分支表 + DPS 曲线 ----------
by_sub = defaultdict(list)
for o in ops:
    if o['rarity'] in ('5', '6'):
        by_sub[(o['prof'], o['sub'], o['dtype'])].append(o)

# 敌人参照：主线 0–3 章出场次数加权
usage = rows('stats/enemy_main_usage.csv')
weighted = []
for e in usage:
    if e['first_zone'] in ('main_0', 'main_1', 'main_2', 'main_3'):
        weighted += [e] * max(1, int(fnum(e['total_count'])))
ref = {k: med([fnum(e[k]) for e in weighted]) for k in ('maxHp', 'atk', 'def_', 'res', 'moveSpeed')}
say('## 敌人参照（主线 0–3 章首登场的敌人，按出场只数加权中位）', ref)
lt = {r['levelType']: r for r in rows('stats/enemy_by_leveltype.csv')}

branch, dps_def, dps_res = [], [], []
for (prof, sub, dt), os_ in sorted(by_sub.items()):
    if dt not in ('PHYSICAL', 'MAGICAL') or len(os_) < 2:
        continue
    m = {k: med([o[k] for o in os_]) for k in ('hp', 'atk', 'def_', 'res', 'cost', 'block', 'bat')}
    smult = med([op_skill_mult.get(o['id'], 1.0) for o in os_])
    d0 = dps(m['atk'], m['bat'], dt)
    dref = dps(m['atk'], m['bat'], dt, ref['def_'], ref['res'])
    # 生存：被参照敌人（物理，攻 ref.atk，间隔 2.0）按阻挡数围攻
    take = max(0.05 * ref['atk'], ref['atk'] - m['def_']) / 2.0 * max(m['block'], 1)
    surv = m['hp'] / take
    ttk = ref['maxHp'] / dref
    branch.append([prof, sub, dt, len(os_), m['hp'], m['atk'], m['def_'], m['res'], m['bat'], m['cost'], m['block'],
                   round(d0, 1), round(dref, 1), round(dref / m['cost'], 2), round(m['hp'] / m['cost'], 1),
                   round(smult, 2), round(ttk, 1), round(surv, 1)])
    if dt == 'PHYSICAL':
        dps_def.append([prof, sub] + [round(dps(m['atk'], m['bat'], dt, d), 1) for d in DEF_GRID])
    else:
        dps_res.append([prof, sub] + [round(dps(m['atk'], m['bat'], dt, 0, r), 1) for r in RES_GRID])

write('branch_table.csv',
      ['prof', 'sub', 'dmg', 'n', 'hp', 'atk', 'def', 'res', 'bat', 'cost', 'block', 'dps_raw', 'dps_vs_ref',
       'dps_per_cost', 'hp_per_cost', 'skill_avg_mult', 'ttk_ref_s', 'survive_ref_s'],
      branch,
      '[自建模型] 5/6★ 满级中位；dps_vs_ref 打主线 0–3 章参照敌人；ttk_ref_s 单人单体击杀参照敌人秒数；'
      'survive_ref_s 被 block 个参照敌人同时攻击能撑几秒（伤害按 [官方公式]）')
write('dps_vs_def.csv', ['prof', 'sub'] + [f'def{d}' for d in DEF_GRID], dps_def,
      '[官方公式]+[自建模型] 物理分支单体 DPS 随目标防御变化（无技能、无天赋）')
write('dps_vs_res.csv', ['prof', 'sub'] + [f'res{r}' for r in RES_GRID], dps_res,
      '[官方公式]+[自建模型] 法术分支单体 DPS 随目标法抗变化（无技能、无天赋）')

say('## 分支表（选摘：每职业 DPS/费最高与最低的分支）')
byp = defaultdict(list)
for b in branch:
    byp[b[0]].append(b)
for p, bs in sorted(byp.items()):
    bs.sort(key=lambda b: b[13])
    lo, hi = bs[0], bs[-1]
    say(f'{p}: {lo[1]} DPS/费 {lo[13]}（费 {lo[9]} 挡 {lo[10]} 撑 {lo[17]}s） … {hi[1]} DPS/费 {hi[13]}（费 {hi[9]} 挡 {hi[10]} 撑 {hi[17]}s）')

say('## 物理 DPS 随防御（选 4 个代表分支）')
for r in dps_def:
    if r[1] in ('冲锋手', '剑豪', '速射手', '铁卫', '重剑手', '无畏者'):
        say(r[1], dict(zip(DEF_GRID, r[2:])), f'800 防时剩 {r[2+5]/r[2]:.1%}')
say('## 法术 DPS 随法抗')
for r in dps_res:
    if r[1] in ('中坚术师', '扩散术师', '秘术师', '凝滞师'):
        say(r[1], dict(zip(RES_GRID, r[2:])))

# ---------- 3. 关卡压力（难度曲线）----------
st = [s for s in rows('stats/stages_main.csv') if s['kind'] == 'MAIN']
ref_dps = med([dps(o['atk'], o['bat'], o['dtype']) for o in ops if o['rarity'] == '5' and o['dtype'] in ('PHYSICAL', 'MAGICAL')])
ch = defaultdict(list)
for s in st:
    span = fnum(s['spawn_span_s'])
    if span <= 0:
        continue
    ch[int(s['chapter'])].append((fnum(s['total_hp']) / span, fnum(s['hp_per_cost']), fnum(s['maxLifePoint']),
                                  fnum(s['enemies']), fnum(s['peak_in_10s']), fnum(s['elite']) + fnum(s['boss'])))
pres = []
for c in sorted(ch):
    v = ch[c]
    hps = med([x[0] for x in v])
    pres.append([c, len(v), round(hps, 1), round(hps / ref_dps, 2), med([x[1] for x in v]), med([x[2] for x in v]),
                 med([x[4] for x in v])])
write('chapter_pressure.csv',
      ['chapter', 'stages', 'hp_per_s', 'ops_equiv', 'hp_per_cost', 'life', 'peak_in_10s'], pres,
      f'[自建模型] hp_per_s = 关卡总血/出怪时长；ops_equiv = hp_per_s / 5★ 满级无技能单体 DPS 中位 {ref_dps:.0f}'
      '（不计防御、技能、范围伤害，只看量级）')
say(f'## 章节压力（参照 DPS {ref_dps:.0f}）')
for p in pres:
    say(f'第{p[0]}章 n={p[1]}: 每秒来血 {p[2]} ≈ {p[3]} 名 5★ 满功率输出；血/费 {p[4]}；命 {p[5]}；10 秒峰值 {p[6]} 只')

# ---------- 4. 守幻录现值套同一模型 ----------
def git_show(path):
    r = subprocess.run(['git', 'show', path], cwd=REPO, capture_output=True, text=True)
    return list(csv.DictReader(io.StringIO(r.stdout)))

shl_c = {c['character_id']: c for c in git_show('origin/numeric/touhou-td-framework:data/characters.csv')}
shl_e = {e['enemy_id']: e for e in git_show('origin/numeric/touhou-td-framework:data/enemies.csv')}
small = shl_e['enm_shade_basic']
hard = shl_e['enm_shade_armored']
boss = shl_e['boss_cirno']
shl = []
for cid in ('reimu', 'marisa', 'cirno', 'yukari'):
    c = shl_c[cid]
    a, b, cost = fnum(c['attack']), fnum(c['attack_interval']), fnum(c['deploy_cost'])
    row = [cid, a, b, cost]
    for e in (small, hard, boss):
        hd = max(0.05 * a, a - fnum(e['armor']))  # 按 Q14 已定的 5% 保底
        row += [math.ceil(fnum(e['hp']) / hd - 1e-9), round(fnum(e['hp']) / (hd / b), 1)]
    row += [round(a / b / cost, 3)]
    shl.append(row)
write('shl_check.csv',
      ['char', 'atk', 'interval', 'cost', 'hits_small', 'ttk_small_s', 'hits_hard', 'ttk_hard_s', 'hits_boss',
       'ttk_boss_s', 'dps_per_cost'], shl,
      '[自建模型] 守幻录 PR #8 现值（灵力费用），伤害按 5% 保底；用于和 AK 同指标比较「几下打死」')
# AK 对照：参照普通敌人几下打死
ak_hits = med([ref['maxHp'] / max(1e-9, hit_damage(o['atk'], o['dtype'], ref['def_'], ref['res']))
               for o in ops if o['rarity'] == '5' and o['dtype'] in ('PHYSICAL', 'MAGICAL')])
heavy_hits = med([10000 / max(1e-9, hit_damage(o['atk'], 'PHYSICAL', 800)) for o in ops
                  if o['rarity'] == '5' and o['dtype'] == 'PHYSICAL'])
say('## 守幻录现值套同一模型')
for r in shl:
    say(f'{r[0]}: 攻 {r[1]} 间隔 {r[2]} 费 {r[3]} → 小残影 {r[4]} 下/{r[5]}s；硬残影 {r[6]} 下/{r[7]}s；'
        f'Boss {r[8]} 下/{r[9]}s；DPS/费 {r[10]}')
say(f'AK 对照：5★ 打主线 0–3 章参照敌人中位 {ak_hits:.1f} 下；5★ 物理打 1 万血 800 防（重装防御者量级）中位 {heavy_hits:.0f} 下')

with open(os.path.join(OUT, 'intent_summary.txt'), 'w', encoding='utf-8') as f:
    f.write('\n'.join(summary) + '\n')
