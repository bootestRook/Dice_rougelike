extends SceneTree
class_name DebugInventoryItemUseSmokeTest


const RunState = preload("res://scripts/core/battle/RunState.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const DiceToolState = preload("res://scripts/core/dice/DiceToolState.gd")
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")


func _init() -> void:
	print("--- DebugInventoryItemUseSmokeTest: start ---")

	var all_passed := true
	all_passed = _check("道具槽点击只打开信息，使用按钮才使用主骰型升级件", await _check_battle_screen_item_info_button_uses_combo_upgrade()) and all_passed
	all_passed = _check("目标类铸骰道具点击使用后才进入目标选择", await _check_battle_screen_target_forge_item_use()) and all_passed
	all_passed = _check("遗物槽点击会打开战斗信息弹窗且没有使用按钮", await _check_battle_screen_relic_info_popup()) and all_passed
	all_passed = _check("运行时按槽使用铸骰道具会消耗道具并修改骰面", _check_game_flow_forge_item_use()) and all_passed
	all_passed = _check("运行时按槽使用骰具道具会安装骰具", _check_game_flow_dice_tool_item_use()) and all_passed

	print("PASS: DebugInventoryItemUseSmokeTest" if all_passed else "FAIL: DebugInventoryItemUseSmokeTest")
	print("--- DebugInventoryItemUseSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_battle_screen_item_info_button_uses_combo_upgrade() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.add_item_to_inventory_or_pending(&"upgrade_combo_pair")
	var flow := _make_flow(run_state)
	root.add_child(flow)

	var battle_screen = _make_battle_screen(flow, run_state)
	root.add_child(battle_screen)
	await process_frame
	await process_frame

	var item_slots := _find_node_by_name(battle_screen, "ItemSlots") as HBoxContainer
	if item_slots == null or item_slots.get_child_count() <= 0:
		_cleanup_nodes([battle_screen, flow])
		return false
	var first_slot := item_slots.get_child(0) as Control
	if first_slot == null:
		_cleanup_nodes([battle_screen, flow])
		return false

	_emit_left_click(first_slot)
	await process_frame

	var popup := battle_screen.get("combo_info_popup") as Control
	var action_button := _find_node_by_name(popup, "CustomInfoActionButton") as Button
	var click_only_opened_info := run_state.get_combo_level(&"pair") == 1 \
		and run_state.item_slots.size() == 1 \
		and popup != null \
		and popup.visible \
		and action_button != null \
		and action_button.visible \
		and action_button.text == "使用"
	if action_button != null:
		action_button.pressed.emit()
	await process_frame

	var passed := click_only_opened_info and run_state.get_combo_level(&"pair") == 2 and run_state.item_slots.is_empty()
	_cleanup_nodes([battle_screen, flow])
	return passed


func _check_battle_screen_target_forge_item_use() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.add_item_to_inventory_or_pending(ForgeItemCatalog.FORGE_PIP_UP)
	var flow := _make_flow(run_state)
	root.add_child(flow)

	var battle_screen = _make_battle_screen(flow, run_state)
	root.add_child(battle_screen)
	await process_frame
	await process_frame

	battle_screen.call("_on_item_slot_pressed", 0)
	await process_frame
	var snapshot: Dictionary = battle_screen.call("automation_get_snapshot")
	var popup := battle_screen.get("combo_info_popup") as Control
	var action_button := _find_node_by_name(popup, "CustomInfoActionButton") as Button
	var click_only_opened_info := not bool(snapshot.get("reward_install_active", false)) \
		and int(snapshot.get("pending_info_item_slot_index", -1)) == 0 \
		and run_state.item_slots.size() == 1 \
		and popup != null \
		and popup.visible \
		and action_button != null \
		and action_button.visible \
		and action_button.text == "使用"
	if action_button != null:
		action_button.pressed.emit()
	await process_frame
	snapshot = battle_screen.call("automation_get_snapshot")
	var entered_target_mode := bool(snapshot.get("reward_install_active", false)) \
		and str(snapshot.get("pending_forge_item_id", "")) == str(ForgeItemCatalog.FORGE_PIP_UP)

	var before_pip := int(run_state.dice[0].faces[0].pip)
	battle_screen.call("automation_install_pending_piece", 0, 0)
	await process_frame
	var passed := click_only_opened_info \
		and entered_target_mode \
		and run_state.item_slots.is_empty() \
		and int(run_state.dice[0].faces[0].pip) == before_pip + 1
	_cleanup_nodes([battle_screen, flow])
	return passed


func _check_battle_screen_relic_info_popup() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	var tool: DiceToolState = DiceToolState.create(
		DiceToolCatalog.TOOL_BASIC_MULT,
		DiceToolCatalog.display_name_for_id(DiceToolCatalog.TOOL_BASIC_MULT),
		2,
		&"common"
	)
	run_state.install_dice_tool_state(tool)
	var flow := _make_flow(run_state)
	root.add_child(flow)

	var battle_screen = _make_battle_screen(flow, run_state)
	root.add_child(battle_screen)
	await process_frame
	await process_frame

	var relic_slots := _find_node_by_name(battle_screen, "RelicSlots") as HBoxContainer
	if relic_slots == null or relic_slots.get_child_count() <= 0:
		_cleanup_nodes([battle_screen, flow])
		return false
	var first_slot := relic_slots.get_child(0) as Control
	if first_slot == null:
		_cleanup_nodes([battle_screen, flow])
		return false
	_emit_left_click(first_slot)
	await process_frame

	var popup := battle_screen.get("combo_info_popup") as Control
	var action_button := _find_node_by_name(popup, "CustomInfoActionButton") as Button
	var popup_text := _collect_text(popup)
	var passed := popup != null \
		and popup.visible \
		and (action_button == null or not action_button.visible) \
		and popup_text.contains("遗物") \
		and popup_text.contains(DiceToolCatalog.display_name_for_id(DiceToolCatalog.TOOL_BASIC_MULT))
	_cleanup_nodes([battle_screen, flow])
	return passed


func _check_game_flow_forge_item_use() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.add_item_to_inventory_or_pending(ForgeItemCatalog.FORGE_PIP_UP)
	var flow := _make_flow(run_state)
	var before_pip := int(run_state.dice[0].faces[0].pip)
	var result: Dictionary = flow.use_inventory_item_from_slot(0, [_target(0, 0)])
	return bool(result.get("success", false)) \
		and run_state.item_slots.is_empty() \
		and int(run_state.dice[0].faces[0].pip) == before_pip + 1


func _check_game_flow_dice_tool_item_use() -> bool:
	var run_state := RunState.new()
	run_state.setup_new_run()
	var item: ItemInstance = ItemInstance.create_dice_tool(DiceToolCatalog.TOOL_BASIC_MULT, "基础倍率器", 2)
	item.metadata["rarity"] = &"common"
	run_state.add_item_instance_to_slots(item)
	var flow := _make_flow(run_state)
	var result: Dictionary = flow.use_inventory_item_from_slot(0)
	return bool(result.get("success", false)) \
		and run_state.item_slots.is_empty() \
		and run_state.dice_tools.size() == 1 \
		and run_state.dice_tools[0].tool_id == DiceToolCatalog.TOOL_BASIC_MULT


func _make_flow(run_state: RunState) -> GameFlowController:
	var flow := GameFlowController.new()
	flow.run_state = run_state
	return flow


func _make_battle_screen(flow: GameFlowController, run_state: RunState):
	var scene := load("res://scenes/battle/BattleScreen.tscn")
	var battle_screen = scene.instantiate()
	battle_screen.setup(flow, run_state, true)
	return battle_screen


func _emit_left_click(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	control.gui_input.emit(event)


func _target(die_index: int, face_index: int) -> Dictionary:
	return {
		"die_index": die_index,
		"face_index": face_index,
	}


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


func _collect_text(root_node: Node) -> String:
	if root_node == null:
		return ""
	var parts := PackedStringArray()
	if root_node is Label:
		parts.append((root_node as Label).text)
	if root_node is RichTextLabel:
		parts.append((root_node as RichTextLabel).text)
	for child in root_node.get_children():
		var child_text := _collect_text(child)
		if child_text != "":
			parts.append(child_text)
	return "\n".join(parts)


func _cleanup_nodes(nodes: Array) -> void:
	for node in nodes:
		if node != null and is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
