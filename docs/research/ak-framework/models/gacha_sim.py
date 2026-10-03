#!/usr/bin/env python3
"""明日方舟标准寻访模拟（给守幻录「幻想的邂逅」招募系统做参照）。

规则来源 raw/excel/gacha_table.json：
  - 星级概率 6★2% / 5★8% / 4★50% / 3★40%：gachaPoolClient[NORM_0_1_1].gachaPoolDetail 文本
  - 保底：连续 50 次没出 6★，下一次 6★ 概率 +2%，逐次 +2% 直到 100%；出 6★ 后回到 2%（同上文本）
  - 前 10 次寻访必出 5★ 以上：gachaPoolClient[].guarantee5Avail=1 / guarantee5Count=10
[自建假设]（数据表里没写，标出来）：
  - 6★ 概率上升时，其余星级按原比例缩小
  - 第 10 抽触发 5★ 保底时，6★ 仍按当次 6★ 概率判定，没中就给 5★（保守读法）
  - 十连 = 连续 10 次单抽，没有额外规则（数据里十连只是道具 / gachaTimes 字段）
用法：python3 models/gacha_sim.py [--n 100000] [--seed 1]
"""
import argparse, csv, os, random

BASE = {6: 0.02, 5: 0.08, 4: 0.50, 3: 0.40}
PITY_START, PITY_STEP = 50, 0.02
G5_COUNT = 10
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'out')


def p6_at(miss):
    """已连续 miss 次没出 6★ 时，本次 6★ 概率。"""
    return min(1.0, BASE[6] + max(0, miss - PITY_START + 1) * PITY_STEP)


def one_pull(rng, miss, need5):
    p6 = p6_at(miss)
    scale = (1 - p6) / (1 - BASE[6])
    p5 = BASE[5] * scale
    if need5:  # 第 10 抽 5★ 保底：6★ 仍按当次概率，否则给 5★
        return 6 if rng.random() < p6 else 5
    x = rng.random()
    if x < p6:
        return 6
    x -= p6
    if x < p5:
        return 5
    x -= p5
    return 4 if x < BASE[4] * scale else 3


def exact_curve(n_max):
    """不计 5★ 保底时「前 n 抽至少一个 6★」的解析值。"""
    surv, out = 1.0, []
    for n in range(1, n_max + 1):
        surv *= 1 - p6_at(n - 1)
        out.append(1 - surv)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--n', type=int, default=100000)
    ap.add_argument('--seed', type=int, default=1)
    a = ap.parse_args()
    rng = random.Random(a.seed)
    os.makedirs(OUT, exist_ok=True)

    # A. 10 万名新玩家各自从第 1 抽开始，一直抽到首个 6★
    first6 = []
    for _ in range(a.n):
        miss, got5, k = 0, False, 0
        while True:
            k += 1
            r = one_pull(rng, miss, need5=(k == G5_COUNT and not got5))
            got5 = got5 or r >= 5
            if r == 6:
                first6.append(k)
                break
            miss += 1
    # B. 连续 10 万抽的星级分布（保底计数跨抽延续）
    dist, miss, got5 = {3: 0, 4: 0, 5: 0, 6: 0}, 0, False
    for k in range(1, a.n + 1):
        r = one_pull(rng, miss, need5=(k == G5_COUNT and not got5))
        got5 = got5 or r >= 5
        dist[r] += 1
        miss = 0 if r == 6 else miss + 1

    mx = max(first6)
    cnt = [0] * (mx + 1)
    for k in first6:
        cnt[k] += 1
    cum, curve = 0, []
    ex = exact_curve(mx)
    for n in range(1, mx + 1):
        cum += cnt[n]
        curve.append((n, cum / a.n, ex[n - 1]))
    with open(os.path.join(OUT, 'gacha_curve.csv'), 'w', newline='', encoding='utf-8') as f:
        f.write(f'# 抽数 n 对「至少 1 个 6★」的概率；sim = {a.n} 次模拟（含前 10 抽 5★ 保底），exact = 解析值（不含 5★ 保底）\n')
        w = csv.writer(f)
        w.writerow(['pulls', 'p_ge1_6star_sim', 'p_ge1_6star_exact'])
        for n, s, e in curve:
            w.writerow([n, round(s, 4), round(e, 4)])

    mean = sum(first6) / a.n
    srt = sorted(first6)
    lines = [
        f'模拟次数 {a.n}，seed {a.seed}',
        '星级分布（连续 {} 抽）：'.format(a.n) + '，'.join(f'{s}★ {dist[s] / a.n:.2%}' for s in (6, 5, 4, 3)),
        f'首个 6★ 平均抽数 {mean:.2f}，中位 {srt[a.n // 2]}，P90 {srt[int(a.n * 0.9)]}，最多 {mx}',
        f'50 抽仍未出 6★：模拟 {1 - curve[49][1]:.2%}，解析 {1 - curve[49][2]:.2%}',
        f'100 抽仍未出 6★：模拟 {1 - curve[min(99, mx - 1)][1]:.2%}（规则上第 99 抽必出；模拟中最晚第 {mx} 抽）',
        '至少 1 个 6★ 的累计概率：' + '，'.join(f'{n} 抽 {curve[n - 1][1]:.1%}' for n in (10, 20, 30, 40, 50, 60, 70, 80, 90) if n <= mx),
    ]
    with open(os.path.join(OUT, 'gacha_summary.txt'), 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines) + '\n')
    print('\n'.join(lines))


if __name__ == '__main__':
    main()
