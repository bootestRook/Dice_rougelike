extends Node
class_name GameFlowController


const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const ForgeService = preload("res://scripts/rules/forge/ForgeService.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")


signal flow_state_changed(state_id: StringName)
signal run_started(run_state: RunState)
signal battle_requested(run_state: RunState)
signal reward_requested(choices: Array)
signal forge_install_requested(piece: ForgePieceDef)
signal run_result_requested(run_state: RunState)
signal run_state_changed(run_state: RunState)


var current_state_id: StringName = &"boot"
var run_state: RunState = null
var reward_generator := RewardGenerator.new()
var forge_service := ForgeService.new()


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


func choose_reward(piece: ForgePieceDef) -> void:
	if run_state == null:
		push_warning("GameFlowController.choose_reward without run_state.")
		return
	if piece == null:
		push_warning("GameFlowController.choose_reward called with null piece.")
		return

	run_state.pending_forge_piece = piece
	set_flow_state(&"forge")
	run_state_changed.emit(run_state)
	forge_install_requested.emit(piece)


func install_pending_piece(die_index: int, face_index: int) -> void:
	if run_state == null:
		push_warning("GameFlowController.install_pending_piece without run_state.")
		return
	if run_state.pending_forge_piece == null:
		push_warning("GameFlowController.install_pending_piece without pending piece.")
		return
	if die_index < 0 or die_index >= run_state.dice.size():
		push_warning("GameFlowController.install_pending_piece die_index out of range: %d" % [die_index])
		return

	var piece := run_state.pending_forge_piece
	if not forge_service.can_apply_piece(piece, run_state.dice[die_index], face_index):
		push_warning("GameFlowController.install_pending_piece cannot apply piece.")
		return

	forge_service.apply_piece(piece, run_state.dice[die_index], face_index)
	run_state.record_installed_piece(piece, die_index, face_index)
	run_state.pending_forge_piece = null
	run_state.advance_battle()
	run_state_changed.emit(run_state)
	start_next_battle()


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
