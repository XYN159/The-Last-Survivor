#!/usr/bin/env python3
"""首领分量模型：用收集员第 4 轮的首领关统计，算出与尺度无关的首领比例，再套到守幻录 Boss。

输入（只读）：/workspace/research/arknights/stats/boss_stages.csv、stages_main.csv、chapter_end_stages.csv
输出：models/out/boss_scale.csv、models/out/boss_summary.txt
标注：
  [数据]      boss_hp、total_hp、spawn_span_s、boss_lpr、maxLifePoint 直接来自收集员统计
  [自建模型]  首领折合秒数 = 首领生命 ÷ 本关每秒来血（总血 ÷ 出怪时长）；守幻录目标血量 = 比例 × 守幻录对应量
用法：python3 models/boss_model.py
"""
import csv, os, statistics

AK = '/workspace/research/arknights/stats'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'out')
os.makedirs(OUT, exist_ok=True)
med = statistics.median

# 守幻录现值（PR #8 @ eddf21a，data/enemies.csv 与 shl_check.csv 同口径）
SHL_SMALL_HP = 60.0        # 小残影
SHL_BOSS_HP = 3000.0       # 琪露诺 Boss
SHL_K = 0.035              # 第 4.4 节比例 k


def load(name):
    with open(os.path.join(AK, name), encoding='utf-8') as f:
        return list(csv.DictReader(f))


def f(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None


stages = {r['stageId']: r for r in load('stages_main.csv')}
rows = []
for b in load('boss_stages.csv'):
    s = stages.get(b['stageId'], {})
    span = f(s.get('spawn_span_s'))
    total, bhp = f(b['total_hp']), f(b['boss_hp'])
    inflow = total / span if span else None
    rows.append({
        'code': b['code'], 'chapter': int(b['chapter']), 'boss': b['boss_name'],
        'boss_hp': bhp, 'boss_def': f(b['boss_def']), 'boss_res': f(b['boss_res']),
        'boss_share': f(b['boss_share']), 'boss_vs_normal': f(b['boss_vs_normal']),
        'boss_secs_of_inflow': round(bhp / inflow, 1) if inflow else None,
        'boss_first_frac': f(b['boss_first_frac']), 'lpr': f(b['boss_lpr']),
        'life': f(b['maxLifePoint']), 'leak_share': f(b['boss_leak_share']),
    })

with open(os.path.join(OUT, 'boss_scale.csv'), 'w', encoding='utf-8', newline='') as fo:
    fo.write('# [数据]+[自建模型] 首领关比例：boss_secs_of_inflow = 首领生命 ÷ 本关每秒来血\n')
    w = csv.DictWriter(fo, fieldnames=list(rows[0].keys()))
    w.writeheader()
    w.writerows(rows)

# 排除 6-17（整关只有首领）与 R8 剧情首领（扣 0 命）
core = [r for r in rows if r['code'] != '6-17' and r['lpr'] and r['lpr'] > 0]
by_ch = {}
for r in core:
    by_ch.setdefault(r['chapter'], []).append(r)

lines = ['# [自建模型] 首领分量（主线 0–8 章普通难度；去掉 6-17 与扣 0 命的剧情首领）',
         f'样本 {len(core)} 关']


def mq(key, rs):
    v = [r[key] for r in rs if r[key] is not None]
    return round(med(v), 3) if v else None


share, ratio, secs = mq('boss_share', core), mq('boss_vs_normal', core), mq('boss_secs_of_inflow', core)
lines.append(f'全体中位：首领占全关血 {share}；首领 ÷ 本关普通中位 ×{ratio}；首领折合本关来血 {secs} 秒；'
             f'漏一次扣命 ÷ 本关生命 {mq("leak_share", core)}；登场位置 {mq("boss_first_frac", core)}')
lines.append('分章：章 | 关数 | 首领生命 | 防 | 法抗 | 首领÷普通 | 占全关 | 折合来血秒')
for ch in sorted(by_ch):
    rs = by_ch[ch]
    lines.append(f'{ch} | {len(rs)} | {mq("boss_hp", rs)} | {mq("boss_def", rs)} | {mq("boss_res", rs)} | '
                 f'×{mq("boss_vs_normal", rs)} | {mq("boss_share", rs)} | {mq("boss_secs_of_inflow", rs)}')

lines.append('')
lines.append('# 守幻录对照（PR #8 现值；Q4 已删关卡血量倍率，小残影按 60 计）')
lines.append(f'琪露诺 Boss {SHL_BOSS_HP:.0f} ÷ 小残影 {SHL_SMALL_HP:.0f} = ×{SHL_BOSS_HP / SHL_SMALL_HP:.0f}；'
             f'AK 第 1 章 ×{mq("boss_vs_normal", by_ch[1])}、全体中位 ×{ratio}')
for lab, rr in (('按 AK 第 1 章首领÷普通', mq('boss_vs_normal', by_ch[1])), ('按全体中位', ratio)):
    lines.append(f'{lab}：Boss 目标 ≈ {SHL_SMALL_HP:.0f} × {rr} = {SHL_SMALL_HP * rr:.0f}')
ak1 = mq('boss_hp', by_ch[1])
lines.append(f'按 k={SHL_K}：AK 第 1 章首领中位 {ak1} × k = {ak1 * SHL_K:.0f}；第 7 章 '
             f'{mq("boss_hp", by_ch[7])} × k = {mq("boss_hp", by_ch[7]) * SHL_K:.0f}')
lines.append(f'按「首领占全关血 {share}」：Boss 目标 = 关卡小怪总血 × {share}/(1−{share}) = 小怪总血 × {share / (1 - share):.3f}')

with open(os.path.join(OUT, 'boss_summary.txt'), 'w', encoding='utf-8') as fo:
    fo.write('\n'.join(lines) + '\n')
print('\n'.join(lines))
