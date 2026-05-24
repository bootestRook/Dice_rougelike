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
	all_passed = _check("道具槽悬浮走统一信息层，点击直接使用主骰型升级件", await _check_battle_screen_item_hover_info_and_click_uses_combo_upgrade()) and all_passed
	all_passed = _check("目标类铸骰道具点击直接进入目标选择", await _check_battle_screen_target_forge_item_use()) and all_passed
	all_passed = _check("遗物槽悬浮走统一信息层，点击不打开战斗信息弹窗", await _check_battle_screen_relic_hover_info()) and all_passed
	all_passed = _check("运行时按槽使用铸骰道具会消耗道具并修改骰面", _check_game_flow_forge_item_use()) and all_passed
	all_passed = _check("运行时按槽使用骰具道具会安装骰具", _check_game_flow_dice_tool_item_use()) and all_passed

	print("PASS: DebugInventoryItemUseSmokeTest" if all_passed else "FAIL: DebugInventoryItemUseSmokeTest")
	print("--- DebugInventoryItemUseSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_battle_screen_item_hover_info_and_click_uses_combo_upgrade() -> bool:
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

	_set_hover_fill_seconds(battle_screen, 0.02)
	first_slot.mouse_entered.emit()
	await _wait_for_hover_info(battle_screen)
	var hover_panel := _find_node_by_name(battle_screen, "InventoryHoverInfoPanel") as Control
	var hover_text := _collect_text(hover_panel)
	var popup := battle_screen.get("combo_info_popup") as Control
	var hover_opened_info := hover_panel != null \
		and hover_panel.visible \
		and (popup == null or not popup.visible) \
		and hover_text.contains("类型") \
		and hover_text.contains("效果")

	_emit_left_click(first_slot)
	await process_frame

	var passed := hover_opened_info and run_state.get_combo_level(&"pair") == 2 and run_state.item_slots.is_empty()
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

	var item_slots := _find_node_by_name(battle_screen, "ItemSlots") as HBoxContainer
	if item_slots == null or item_slots.get_child_count() <= 0:
		_cleanup_nodes([battle_screen, flow])
		return false
	var first_slot := item_slots.get_child(0) as Control
	if first_slot == null:
		_cleanup_nodes([battle_screen, flow])
		return false

	_set_hover_fill_seconds(battle_screen, 0.08)
	first_slot.mouse_entered.emit()
	await process_frame
	var hover_overlay := _find_node_by_name(battle_screen, "InventoryHoverInfoOverlay")
	var inventory_ring := _find_node_by_name(hover_overlay, "DiceHoverRing") as Control
	var hover_panel := _find_node_by_name(battle_screen, "InventoryHoverInfoPanel") as Control
	var ring_started := inventory_ring != null and inventory_ring.visible and (hover_panel == null or not hover_panel.visible)
	_emit_left_click(first_slot)
	await _wait_frames(8)
	var snapshot: Dictionary = battle_screen.call("automation_get_snapshot")
	var popup := battle_screen.get("combo_info_popup") as Control
	var click_interrupted_hover := ring_started \
		and inventory_ring != null \
		and not inventory_ring.visible \
		and hover_panel != null \
		and not hover_panel.visible
	var click_entered_target_mode := click_interrupted_hover \
		and bool(snapshot.get("reward_install_active", false)) \
		and run_state.item_slots.size() == 1 \
		and (popup == null or not popup.visible) \
		and str(snapshot.get("pending_forge_item_id", "")) == str(ForgeItemCatalog.FORGE_PIP_UP)

	var before_pip := int(run_state.dice[0].faces[0].pip)
	battle_screen.call("automation_install_pending_piece", 0, 0)
	await process_frame
	var passed := click_entered_target_mode \
		and run_state.item_slots.is_empty() \
		and int(run_state.dice[0].faces[0].pip) == before_pip + 1
	_cleanup_nodes([battle_screen, flow])
	return passed


func _check_battle_screen_relic_hover_info() -> bool:
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

	_set_hover_fill_seconds(battle_screen, 0.02)
	first_slot.mouse_entered.emit()
	await _wait_for_hover_info(battle_screen)
	var hover_panel := _find_node_by_name(battle_screen, "InventoryHoverInfoPanel") as Control
	var hover_text := _collect_text(hover_panel)
	_emit_left_click(first_slot)
	await process_frame

	var popup := battle_screen.get("combo_info_popup") as Control
	var passed := hover_panel != null \
		and hover_panel.visible \
		and (popup == null or not popup.visible) \
		and hover_text.contains("遗物") \
		and hover_text.contains(DiceToolCatalog.display_name_for_id(DiceToolCatalog.TOOL_BASIC_MULT))
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


func _set_hover_fill_seconds(root_node: Node, seconds: float) -> void:
	for ring in _find_nodes_by_name(root_node, "DiceHoverRing"):
		ring.set("fill_seconds", seconds)


func _wait_for_hover_info(root_node: Node) -> void:
	for _index in range(12):
		var panel := _find_node_by_name(root_node, "InventoryHoverInfoPanel") as Control
		if panel != null and panel.visible:
			return
		await process_frame


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


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


func _find_nodes_by_name(root_node: Node, node_name: String) -> Array[Node]:
	var result: Array[Node] = []
	if root_node == null:
		return result
	if root_node.name == node_name:
		result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_find_nodes_by_name(child, node_name))
	return result


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
