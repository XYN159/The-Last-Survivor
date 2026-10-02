# -*- coding: utf-8 -*-
"""数值脚本的可调参数（模拟假设 + 局外养成公式参数）。

改这里之后运行：
    python tools/numeric/gen_progression.py   # 重新生成 data/progression/*.csv
    python tools/numeric/run_all.py           # 重新模拟并生成报告
"""

# ---------------- 模拟：玩家怎么玩（假设）
SEEDS = [1, 2, 3, 4, 5]          # 每关用 5 个随机种子（影响刷怪顺序和三选一选项）取平均
CALIBRATE_SEEDS = SEEDS          # 校准威胁预算系数时用的种子（和出报告用同一批，避免校准和结果对不上）
# 带谁进场：按这个偏好从已解锁角色里选，最多 squad_cap 名（battle_rules.csv）
SQUAD_PREFERENCE = ["reimu", "marisa", "yukari", "sakuya", "sanae", "cirno", "keine", "meiling", "mokou"]
# 进场后的部署顺序（越靠前越先放、越先占好位置）
DEPLOY_ORDER = ["reimu", "cirno", "marisa", "yukari", "sanae", "sakuya", "meiling", "keine", "aya", "mokou"]

# ---------------- 局外养成（提议值，待用户拍板）
CURRENCY_NAME = "记忆碎片"       # 暂名，待文案策划确认
# 升级花费：从 n 级升到 n+1 级需要 cost(n) = A + B×(n-1) + C×(n-1)^2，取整到 5
LEVEL_COST_A = 80
LEVEL_COST_B = 25
LEVEL_COST_C = 0
# 首通奖励：reward(L) = BASE + STEP×(L-1)，取整到 5；Boss 关 ×BOSS_MULT
FIRST_CLEAR_BASE = 50
FIRST_CLEAR_STEP = 70
BOSS_REWARD_MULT = 1.5
REPEAT_RATIOS = [0.5, 0.3, 0.2]  # 第 2 次通关 50%，第 3 次 30%，第 4 次起 20%（保底）
CATCH_UP_GAP = 3                 # 比最高等级角色低 3 级及以上时……
CATCH_UP_DISCOUNT = 0.5          # ……升级花费打 5 折
JOIN_RULE = "avg_floor"          # 新角色加入时等级 = 已有角色平均等级（向下取整）
# 星星只解锁外观和故事，不给资源（系统策划 PR #3）；所以这里没有任何「三星奖励」
# 两种分资源的玩法（系统策划要求都验证「不需要刷关」）：
#   even  = 每次给出战阵容里等级最低的人升 1 级（平均分）
#   focus = 只培养偏好最靠前的 FOCUS_COUNT 人，其他人停在加入时的等级
FOCUS_COUNT = 3
# 方案 B（琪露诺通关 ch1_01 后加入）下「同样的养成假设」：第一章 2–4 关首通时碎片照旧只花在灵梦和魔理沙身上，
# 两人的局外等级和上一版首通推演完全一样（ch1_02 4/3 级、ch1_03 5/5 级、ch1_04 6/6 级），琪露诺按加入规则停在 3 级。
# 打完 ch1_04 后恢复「平均分」。对照：run_campaign(spend_rule="even_all") = 碎片也平均分给琪露诺。
SPEND_ONLY = {"ch1_02": ["reimu", "marisa"], "ch1_03": ["reimu", "marisa"], "ch1_04": ["reimu", "marisa"]}

# ---------------- 校准
COEF_MIN, COEF_MAX = 0.2, 3.0
COEF_ROUND = 0.05
CAL_FINE_STEP = 0.01             # 校准第 2 步：在粗扫结果左右 ±0.10 按 0.01 细扫（0 = 不细扫）
CAL_SMOOTH = 0.02                # 细扫时每个系数取左右 ±0.02 内的点一起平均（抹平锯齿），见 campaign.calibrate
# 手动锁定的系数：--calibrate 时这些关不再自动校准，直接用这里的值（状态写 locked），重跑不会覆盖。
# 只重算这个系数下的每点伤害充能、期望（±0.02 平滑）和「再加 0.05」的剩余。
# ch1_03：关卡策划在 PR #5（cursor/design-level-framework-01a3，f2212be，2026-09-28 00:33 UTC+8）确认 0.75，
#         硬残影 8 只、排法同 extra_spawns。自动校准会算出 0.77，按确认值锁定。要解锁就删掉这一项。
# ch1_04：D-01 已定（第 11 波登场，血量不乘倍率）。允许 0.70–0.74。
#         2026-10-02 用首通阵容（灵梦 6 / 琪露诺 3 / 魔理沙 6）重跑：0.74 的平滑期望剩余 11.9，
#         是这个区间里仍不低于「目标 11 减 0.5」的最大系数。5 个种子平均 10.0，最差种子 -9。
FIX_COEF = {"ch1_03": 0.75, "ch1_04": 0.74}
SPELL_MODE = "manual"            # 符卡默认手动放（自动释放是全局开关、默认关，系统策划 PR #3）；报告另有自动释放对照
