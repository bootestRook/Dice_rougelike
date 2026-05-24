extends SceneTree


const OUTPUT_DIR := "res://tests_or_debug/captures/battle_dice_hover_info"
const BattleDiceStage3D = preload("res://scripts/ui/battle/components/BattleDiceStage3D.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")


func _init() -> void:
	print("--- CaptureBattleDiceHoverInfo: start ---")
	DisplayServer.window_set_size(Vector2i(1366, 768))
	root.size = Vector2i(1366, 768)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var scene := load("res://scenes/battle/components/BattleDiceStage3D.tscn")
	var stage := scene.instantiate() as BattleDiceStage3D
	var style_config := load("res://scenes/battle/resources/BattleUiStyleConfig.tres") as BattleUiStyleConfig
	stage.setup(style_config, null, null, null, null, null)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(stage)

	await process_frame
	await process_frame

	var die := DieState.create_normal_d6(&"hover_capture_die")
	die.body_id = &"iron"
	die.faces[2].pip = 4
	die.faces[2].ornament_id = &"orn_burst"
	die.faces[2].mark_id = &"red"

	var rolled := RolledFace.new()
	rolled.set_roll(0, 2, die.faces[2], die)
	var die_data := DieViewData.new()
	die_data.setup_from_die(die, 0, rolled, true, false, false)

	var state := BattleHudState.new()
	state.dice_results.append(die_data)
	state.can_reroll = true
	state.can_score = true
	stage.render(state)

	await process_frame
	await process_frame

	var battle_mgr = stage.get("battle_mgr")
	var avatar = null
	if battle_mgr != null and battle_mgr.using_dices.size() > 0 and battle_mgr.using_dices[0] != null:
		avatar = battle_mgr.using_dices[0].avatar
	if avatar == null:
		print("FAIL: cannot find 3D dice avatar")
		quit(1)
		return

	var ring := _find_node_by_name(stage, "DiceHoverRing") as Control
	if ring != null:
		ring.set("fill_seconds", 0.60)

	stage.call("_on_dice_viewport_dice_hovered", avatar)
	await process_frame
	stage.call("_on_dice_viewport_dice_hovered", avatar)
	for _index in range(2):
		await process_frame
	var ring_path := "%s/hover_ring.png" % [OUTPUT_DIR]
	var ring_ok := _save_capture(ring_path)

	await _wait_for_hover_ring_to_finish(stage, avatar, ring)
	await process_frame
	var info_path := "%s/hover_info.png" % [OUTPUT_DIR]
	var info_ok := _save_capture(info_path)

	var manifest := {
		"scenario": "battle dice hover info sequence",
		"captures": [
			{
				"id": "hover_ring",
				"screenshot": ProjectSettings.globalize_path(ring_path),
				"expected": "鼠标悬浮后只显示灰色圆环进度条，信息框保持隐藏",
			},
			{
				"id": "hover_info",
				"screenshot": ProjectSettings.globalize_path(info_path),
				"expected": "圆环完成并消失后显示骰面信息框",
			},
		],
	}
	var manifest_path := "%s/manifest.json" % [OUTPUT_DIR]
	var file := FileAccess.open(ProjectSettings.globalize_path(manifest_path), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(manifest, "\t"))
		file.close()
		print("manifest=%s" % [ProjectSettings.globalize_path(manifest_path)])

	stage.queue_free()
	print("PASS: CaptureBattleDiceHoverInfo" if ring_ok and info_ok else "FAIL: CaptureBattleDiceHoverInfo")
	print("--- CaptureBattleDiceHoverInfo: end ---")
	quit(0 if ring_ok and info_ok else 1)


func _save_capture(output_res_path: String) -> bool:
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL: cannot capture %s" % [output_res_path])
		return false
	var output_path := ProjectSettings.globalize_path(output_res_path)
	var err := image.save_png(output_path)
	if err != OK:
		print("FAIL: cannot save %s err=%d" % [output_path, err])
		return false
	print("saved=%s" % [output_path])
	return true


func _wait_for_hover_ring_to_finish(stage: Node, avatar: Node, ring: Control) -> void:
	var frames := 0
	while ring != null and ring.visible and frames < 90:
		if stage != null and avatar != null:
			stage.call("_on_dice_viewport_dice_hovered", avatar)
		await process_frame
		frames += 1


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var result := _find_node_by_name(child, node_name)
		if result != null:
			return result
	return null
