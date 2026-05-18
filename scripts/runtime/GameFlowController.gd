extends Node
class_name GameFlowController


const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const DiceToolService = preload("res://scripts/rules/dice_tools/DiceToolService.gd")
const ForgeService = preload("res://scripts/rules/forge/ForgeService.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ShopService = preload("res://scripts/rules/shop/ShopService.gd")


signal flow_state_changed(state_id: StringName)
signal run_started(run_state: RunState)
signal battle_requested(run_state: RunState)
signal reward_requested(choices: Array)
signal forge_install_requested(piece: ForgePieceDef)
signal shop_requested(shop_state: Dictionary)
signal booster_pack_opened(open_result: Dictionary)
signal run_result_requested(run_state: RunState)
signal run_state_changed(run_state: RunState)


var current_state_id: StringName = &"boot"
var run_state: RunState = null
var dice_tool_service := DiceToolService.new()
var reward_generator := RewardGenerator.new()
var forge_service := ForgeService.new()
var shop_service := ShopService.new()


func set_flow_state(state_id: StringName) -> void:
	current_state_id = state_id
	flow_state_changed.emit(current_state_id)


func start_new_run() -> void:
	run_state = RunState.new()
	run_state.setup_new_run()
	set_flow_state(&"run")
	run_started.emit(run_state)
	run_state_changed.emit(run_state)
	start_next_battle()


func start_next_battle() -> void:
	if run_state == null:
		start_new_run()
		return

	run_state.ensure_starting_dice()
	set_flow_state(&"battle")
	battle_requested.emit(run_state)


func on_battle_won() -> void:
	if run_state == null:
		push_warning("GameFlowController.on_battle_won without run_state.")
		return

	if run_state.is_final_battle():
		run_state.mark_run_won()
		set_flow_state(&"run_victory")
		run_state_changed.emit(run_state)
		run_result_requested.emit(run_state)
		return

	var choices := reward_generator.generate_forge_choices(3, run_state.battle_index)
	run_state.last_reward_choices = choices
	set_flow_state(&"reward")
	run_state_changed.emit(run_state)
	reward_requested.emit(choices)


func on_battle_lost() -> void:
	if run_state == null:
		return

	run_state.mark_run_lost()
	set_flow_state(&"run_defeat")
	run_state_changed.emit(run_state)
	run_result_requested.emit(run_state)


func choose_reward(reward) -> void:
	if run_state == null:
		push_warning("GameFlowController.choose_reward without run_state.")
		return
	var piece := reward as ForgePieceDef
	if piece == null:
		if _choose_direct_item_reward(reward):
			return
		push_warning("GameFlowController.choose_reward called with unsupported reward.")
		return

	if run_state.apply_combo_upgrade_piece(piece):
		run_state.last_reward_choices.clear()
		run_state.pending_forge_piece = null
		run_state.advance_battle()
		run_state_changed.emit(run_state)
		start_next_battle()
		return

	run_state.pending_forge_piece = piece
	set_flow_state(&"forge")
	run_state_changed.emit(run_state)
	forge_install_requested.emit(piece)


func _choose_direct_item_reward(reward) -> bool:
	var item_id := _reward_item_id(reward)
	if item_id == &"":
		return false
	if not run_state.add_item_to_inventory_or_pending(item_id):
		push_warning("GameFlowController.choose_reward could not add item reward: %s" % [str(item_id)])
		return false
	run_state.last_reward_choices.clear()
	run_state.pending_forge_piece = null
	run_state.advance_battle()
	run_state_changed.emit(run_state)
	start_next_battle()
	return true


func _reward_item_id(reward) -> StringName:
	if reward is StringName:
		return reward
	if reward is String:
		return StringName(reward)
	var object := reward as Object
	if object == null:
		return &""
	for property in object.get_property_list():
		if str(property.get("name", "")) != "id":
			continue
		var raw_id = object.get("id")
		if raw_id == null:
			return &""
		return StringName(str(raw_id))
	return &""


func install_pending_piece(die_index: int, face_index: int) -> bool:
	if run_state == null:
		push_warning("GameFlowController.install_pending_piece without run_state.")
		return false
	if run_state.pending_forge_piece == null:
		push_warning("GameFlowController.install_pending_piece without pending piece.")
		return false
	if die_index < 0 or die_index >= run_state.dice.size():
		push_warning("GameFlowController.install_pending_piece die_index out of range: %d" % [die_index])
		return false

	var piece := run_state.pending_forge_piece
	if not forge_service.can_apply_piece(piece, run_state.dice[die_index], face_index):
		push_warning("GameFlowController.install_pending_piece cannot apply piece.")
		return false

	var before_face = null
	if face_index >= 0 and face_index < run_state.dice[die_index].faces.size():
		before_face = run_state.dice[die_index].faces[face_index].clone()
	forge_service.apply_piece(piece, run_state.dice[die_index], face_index)
	if before_face != null and face_index >= 0 and face_index < run_state.dice[die_index].faces.size():
		dice_tool_service.on_face_changed(run_state, before_face, run_state.dice[die_index].faces[face_index], &"forge_piece")
	run_state.record_installed_piece(piece, die_index, face_index)
	run_state.pending_forge_piece = null
	run_state.last_reward_choices.clear()
	run_state.advance_battle()
	run_state_changed.emit(run_state)
	start_next_battle()
	return true


func apply_pending_dice_tool_face_copy(die_index: int, face_index: int) -> Dictionary:
	if run_state == null:
		return {"success": false, "reason": "当前没有局内状态。"}
	var result := dice_tool_service.apply_pending_face_copy(run_state, {
		"die_index": die_index,
		"face_index": face_index,
	})
	if bool(result.get("success", false)):
		run_state_changed.emit(run_state)
	return result


func record_hand_score(score_or_result, hand_number: int = 0) -> void:
	if run_state == null:
		return

	run_state.record_hand_score(score_or_result, hand_number)
	run_state_changed.emit(run_state)


func back_to_main() -> void:
	set_flow_state(&"main")


func get_run_state() -> RunState:
	return run_state


func enter_battle() -> void:
	start_next_battle()


func enter_reward() -> void:
	on_battle_won()


func enter_forge() -> void:
	set_flow_state(&"forge")


func enter_shop() -> Dictionary:
	if run_state == null:
		start_new_run()
		return {}
	var shop_state := shop_service.generate_shop(run_state)
	set_flow_state(&"shop")
	run_state_changed.emit(run_state)
	shop_requested.emit(shop_state)
	return shop_state


func reroll_shop_random_items() -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	var result := shop_service.reroll_random_shop_items(run_state)
	run_state_changed.emit(run_state)
	if bool(result.get("success", false)):
		shop_requested.emit(run_state.current_shop_state)
	return result


func purchase_shop_offer_by_slot(slot_group: StringName, index: int = 0) -> Dictionary:
	if run_state == null:
		return {"success": false, "message": "缺少本局状态"}
	var result := shop_service.purchase_offer_by_slot(run_state, slot_group, index)
	run_state_changed.emit(run_state)
	if bool(result.get("success", false)) and result.has("candidate_offers"):
		booster_pack_opened.emit(result)
	return result
