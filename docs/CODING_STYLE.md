# GDScript 写法

格式和静态检查用 gdtoolkit 4.5.0（`gdformat` / `gdlint`）。配置是仓库根目录的 `gdformatrc` 和 `.gdlintrc`。提交前 CI 会跑 `./ci/lint.sh`。

## 类型

给变量、参数和返回值写类型。

```gdscript
func squad_size_after_gates(gate_count: int) -> int:
	return starting_squad_size + gate_count
```

能用具体类型就不用 `Variant`。解析 JSON 时，先放进 `Variant`，再用 `typeof` 确认是字典。

## 命名

| 对象 | 形式 | 例子 |
| --- | --- | --- |
| 文件 | 小写加下划线 | `battle_lane.gd` |
| 类 | 大驼峰 | `BalanceConfig` |
| 函数、变量、信号 | 小写加下划线 | `squad_size_changed` |
| 常量 | 大写加下划线 | `BALANCE_PATH` |
| 场景里只给脚本用的节点 | 大驼峰，并设成唯一名 | `%StartButton` |
| 私有成员 | 前导下划线 | `_start_button` |

信号用能听懂的短语，带上参数类型：`signal squad_size_changed(new_size: int)`。

## 文件里的顺序

和 gdlint 的 `class-definitions-order` 一致：

1. `class_name`（纯数据类才写；场景脚本不写）
2. `extends`
3. 用 `##` 写的一行说明
4. `signal`
5. `enum`
6. `const`
7. 普通变量
8. `@onready` 变量
9. 函数

`class_name` 放在 `extends` 前面。

## 场景脚本

- 在 `_ready` 里用 `pressed.connect(...)` 连接按钮，不在检查器里连信号。这样连接关系在脚本里看得见。
- 用 `%唯一名` 取节点，并标上类型。
- 换场景用 `get_tree().change_scene_to_file(...)`，路径写完整的 `res://`。

## 数值和注释

- 会调平衡的数字放进 `data/balance/`，不写在场景脚本里。
- 注释和 `##` 文档用简体中文，解释为什么这样写。代码标识符保持英文。
- 不要注释每一行在做什么。

## 测试

测试放在 `tests/unit/`，继承 `GutTest`，文件名以 `test_` 开头，函数名以 `test_` 开头。一个测试只断言一件事。能测纯函数时，就不要启动整个场景。

第三方目录 `addons/gut/` 不跑格式化，也不要为了通过检查去改它。
