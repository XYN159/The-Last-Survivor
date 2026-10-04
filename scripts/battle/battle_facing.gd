class_name BattleFacing
extends RefCounted

## 放置朝向和结界格子的几何。朝向按地图表来认：up 是第 0 行那边（北），
## down 是守护点那边，right 是列号变大的那边。屏幕上怎么画由 board_view 换算。

const UP := "up"
const DOWN := "down"
const LEFT := "left"
const RIGHT := "right"
const ALL: Array[String] = [UP, DOWN, LEFT, RIGHT]


static func is_valid(facing: String) -> bool:
	return ALL.has(facing)


static func vector(facing: String) -> Vector2i:
	match facing:
		UP:
			return Vector2i(0, -1)
		DOWN:
			return Vector2i(0, 1)
		LEFT:
			return Vector2i(-1, 0)
		RIGHT:
			return Vector2i(1, 0)
	return Vector2i.ZERO


## 朝向前方 forward 格、左右各 side 格围出的格子，不含角色自己那一格。
## 只算几何，地面格的筛选交给模拟器。
static func area(col: int, row: int, facing: String, forward: int, side: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var ahead := vector(facing)
	if ahead == Vector2i.ZERO:
		return cells
	var across := Vector2i(-ahead.y, ahead.x)
	for step in range(1, forward + 1):
		for offset in range(-side, side + 1):
			cells.append(Vector2i(col, row) + ahead * step + across * offset)
	return cells
