extends SceneTree


const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")

const OUTPUT_PATH := "res://tests_or_debug/captures/formal_battle_dice_qingjin_after.png"


func _init() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests_or_debug/captures"))

	var scene := load("res://scenes/battle/components/BattleDiceStage3D.tscn") as PackedScene
	if scene == null:
		push_error("Cannot load BattleDiceStage3D scene")
		quit(1)
		return

	var stage := scene.instantiate() as Control
	root.add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame

	stage.call("render", _make_state())
	for _frame in range(30):
		await process_frame

	var image := root.get_texture().get_image()
	var output := ProjectSettings.globalize_path(OUTPUT_PATH)
	var error := image.save_png(output)
	print("saved=%s error=%s" % [output, error])
	quit(0 if error == OK else 1)


func _make_state() -> BattleHudState:
	var state := BattleHudState.new()
	state.dice_results = []
	state.rerolls_left = 2
	state.rerolls_total = 2
	state.current_hand = 1
	state.max_hands = 4
	state.max_selected_dice = 5
	for die_index in range(6):
		var die := DieState.create_normal_d6(StringName("formal_capture_d6_%d" % [die_index + 1]))
		var die_data := DieViewData.new()
		die_data.setup_from_die(die, die_index, null, true, false, false)
		die_data.current_face_index = die_index
		die_data.current_face = die_data.faces[die_index]
		state.dice_results.append(die_data)
	return state
