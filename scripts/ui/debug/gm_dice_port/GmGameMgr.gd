extends Node
class_name GmGameMgr


signal state_changed(state_id: StringName, snapshot: Dictionary)


@export var ready_mgr: GmReadyMgr = null
@export var battle_mgr: GmBattleMgr = null

var dice_definition: GmDiceDefinition = null
var current_state_id: StringName = &"boot"
var dice_count := 4
var pending_targets: Array = []
var is_load_over := false
var save_data := {}


func setup(p_ready_mgr: GmReadyMgr, p_battle_mgr: GmBattleMgr, p_definition: GmDiceDefinition) -> void:
	ready_mgr = p_ready_mgr
	battle_mgr = p_battle_mgr
	dice_definition = p_definition


func boot(start_count := 4) -> void:
	is_load_over = true
	dice_count = clampi(start_count, 1, 6)
	start_new_run(dice_count)


func start_new_run(start_count := dice_count) -> void:
	dice_count = clampi(start_count, 1, 6)
	enter_ready()
	enter_battle()


func enter_ready() -> void:
	current_state_id = &"ready"
	_emit_state()


func enter_battle() -> void:
	current_state_id = &"battle"
	if battle_mgr != null:
		battle_mgr.create_dice_from_box(dice_count, dice_definition)
	_emit_state()


func set_dice_count(count: int) -> void:
	dice_count = clampi(count, 1, 6)
	if current_state_id == &"battle" and battle_mgr != null:
		battle_mgr.create_dice_from_box(dice_count, dice_definition)
	_emit_state()


func set_targets(values: Array) -> void:
	pending_targets.clear()
	for index in range(dice_count):
		var value = values[index] if index < values.size() else null
		if value == null:
			pending_targets.append(null)
		else:
			var pip := int(value)
			pending_targets.append(pip if pip >= 1 and pip <= 6 else null)
	_emit_state()


func roll_current(use_targets := true) -> void:
	if battle_mgr == null:
		return
	if battle_mgr.using_dices.is_empty():
		battle_mgr.create_dice_from_box(dice_count, dice_definition)
	var targets := pending_targets if use_targets else []
	battle_mgr.roll_using_dices(targets)
	_emit_state()


func clear() -> void:
	if battle_mgr != null:
		battle_mgr.clear()
	current_state_id = &"battle"
	_emit_state()


func save_game() -> void:
	save_data = get_snapshot()


func load_game() -> void:
	if save_data.has("dice_count"):
		set_dice_count(int(save_data["dice_count"]))


func get_snapshot() -> Dictionary:
	var battle_snapshot := battle_mgr.get_snapshot() if battle_mgr != null else {}
	battle_snapshot["state"] = str(current_state_id)
	battle_snapshot["dice_count"] = dice_count
	battle_snapshot["pending_targets"] = pending_targets.duplicate()
	battle_snapshot["definition"] = dice_definition.to_dictionary() if dice_definition != null else {}
	return battle_snapshot


func _emit_state() -> void:
	state_changed.emit(current_state_id, get_snapshot())
