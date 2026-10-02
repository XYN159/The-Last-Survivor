extends GutTest

const BATTLE_SCENE := preload("res://scenes/battle/battle_board.tscn")


func test_battle_board_shows_spirit_life_and_both_characters() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	var spirit := board.get_node("%SpiritLabel") as Label
	var life := board.get_node("%LifeLabel") as Label
	var wave := board.get_node("%WaveLabel") as Label
	assert_eq(spirit.text, "灵力 150")
	assert_eq(life.text, "生命 20/20")
	assert_eq(wave.text, "布阵 10 秒")
	var bar := board.get_node("%CharacterBar") as HBoxContainer
	assert_eq(bar.get_child_count(), 2)
	var call_button := board.get_node("%CallButton") as Button
	assert_eq(call_button.text, "开始 +10")
