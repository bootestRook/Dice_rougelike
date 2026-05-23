extends SceneTree
class_name DebugBattleDiceHoverInfoSmokeTest


const BattleDiceStage3D = preload("res://scripts/ui/battle/components/BattleDiceStage3D.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")


func _init() -> void:
	print("--- DebugBattleDiceHoverInfoSmokeTest: start ---")

	var all_passed := true
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)

	var scene := load("res://scenes/battle/components/BattleDiceStage3D.tscn")
	var stage := scene.instantiate() as BattleDiceStage3D
	var style_config := load("res://scenes/battle/resources/BattleUiStyleConfig.tres") as BattleUiStyleConfig
	stage.setup(style_config, null, null, null, null, null)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(stage)

	await process_frame
	await process_frame

	var die := DieState.create_normal_d6(&"hover_test_die")
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
	all_passed = _check("3D 骰子实例已创建", avatar != null) and all_passed

	if avatar != null:
		stage.call("_on_dice_viewport_dice_hovered", avatar)
		await process_frame
		await process_frame

	var ring := _find_node_by_name(stage, "DiceHoverRing") as Control
	var panel := _find_node_by_name(stage, "DiceHoverFaceInfoPanel") as Control
	all_passed = _check("悬浮时显示灰色圆环进度条", ring != null and ring.visible) and all_passed
	all_passed = _check("悬浮后立即显示骰面信息面板", panel != null and panel.visible) and all_passed
	all_passed = _check("信息面板显示骰胚", _label_text(panel, "BodyValueLabel") == die_data.body_name) and all_passed
	all_passed = _check("信息面板显示点数", _label_text(panel, "PipValueLabel") == str(die_data.current_face.pip)) and all_passed
	all_passed = _check("信息面板显示面饰", _label_text(panel, "OrnamentValueLabel") == die_data.current_face.ornament_name) and all_passed
	all_passed = _check("信息面板显示印记", _label_text(panel, "MarkValueLabel") == die_data.current_face.mark_name) and all_passed
	all_passed = _check("信息面板字段值有可见布局宽度", _value_labels_have_visible_width(panel)) and all_passed
	all_passed = _check("信息面板不泄露内部英文 ID", not _panel_text_has_internal_id(panel)) and all_passed

	stage.call("_on_dice_viewport_dice_hover_cleared")
	await process_frame
	all_passed = _check("鼠标离开后隐藏圆环", ring != null and not ring.visible) and all_passed
	all_passed = _check("鼠标离开后隐藏信息面板", panel != null and not panel.visible) and all_passed

	stage.queue_free()
	print("PASS: DebugBattleDiceHoverInfoSmokeTest" if all_passed else "FAIL: DebugBattleDiceHoverInfoSmokeTest")
	print("--- DebugBattleDiceHoverInfoSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _label_text(root_node: Node, node_name: String) -> String:
	var label := _find_node_by_name(root_node, node_name) as Label
	return label.text if label != null else ""


func _panel_text_has_internal_id(panel: Node) -> bool:
	var text := _collect_label_text(panel)
	for token in ["body_", "orn_", "mark_", "iron", "burst", "red", "standard"]:
		if text.contains(token):
			return true
	return false


func _value_labels_have_visible_width(panel: Node) -> bool:
	for node_name in ["BodyValueLabel", "PipValueLabel", "OrnamentValueLabel", "MarkValueLabel"]:
		var label := _find_node_by_name(panel, node_name) as Label
		if label == null or label.size.x < 80.0:
			return false
	return true


func _collect_label_text(root_node: Node) -> String:
	if root_node == null:
		return ""
	var parts := PackedStringArray()
	if root_node is Label:
		parts.append((root_node as Label).text)
	for child in root_node.get_children():
		var child_text := _collect_label_text(child)
		if child_text != "":
			parts.append(child_text)
	return "\n".join(parts)


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


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
