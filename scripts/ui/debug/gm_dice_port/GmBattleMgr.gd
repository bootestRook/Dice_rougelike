extends Node
class_name GmBattleMgr


signal dice_roster_changed(snapshot: Dictionary)
signal roll_started(snapshot: Dictionary)
signal roll_finished(snapshot: Dictionary)
signal resolution_requested(payload: Dictionary)
signal dice_exit_requested(payload: Dictionary)
signal dice_exit_return_finished(snapshot: Dictionary)
signal score_updated(snapshot: Dictionary)


const FALL_RECOVER_Y := -2.20
const FAR_OUTSIDE_X := 10.50
const FAR_OUTSIDE_Z := 7.20
const DEFAULT_IDLE_DRIFT_TUNING := {
	"min_seconds": 1.15,
	"max_seconds": 2.35,
	"max_distance": 0.07,
	"speed": 0.05,
}
const DEFAULT_THROW_SPEED_TUNING := {
	"linear_speed_min": 8.0,
	"linear_speed_max": 12.0,
}
const DEFAULT_THROW_SPIN_TUNING := {
	"angular_speed_min": 4.0,
	"angular_speed_max": 9.5,
	"torque_min": 2.0,
	"torque_max": 5.0,
}
const DEFAULT_EXIT_RETURN_TUNING := {
	"screen_x": 0.66,
	"screen_y": 0.44,
	"spawn_y": 20.0,
}
const DEFAULT_UNSELECTED_HOLD_TUNING := {
	"screen_x": 0.50,
	"screen_y": 0.84,
	"max_width": 8.00,
	"duration": 0.36,
}
const READY_RETURN_DURATION := 0.58
const EXIT_RETURN_DURATION := 0.55
const EXIT_RETURN_STEP_DELAY := 0.12

const GmDiceInstanceScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceInstance.gd")


@export var ready_mgr: GmReadyMgr = null
@export var dice_container: Node3D = null

var max_roll_num := 3
var roll_num := 0
var dice_change_num := 0
var target_score_num := 0
var current_score_num := 0

var bag_dices: Array = []
var tomb_dices: Array = []
var using_dices: Array = []
var score_dices: Array = []
var destroy_dices: Array = []
var temp_dices: Array = []
var reserve_dices: Array = []
var hot_dices: Array = []
var boss_dice: GmDiceInstance = null

var base_score := 0
var mult_score := 1
var final_score := 0
var last_values: Array[int] = []
var last_targets: Array = []
var last_rolled_dice_indices: Array[int] = []
var selected_dice_indices: Array[int] = []
var display_die_order: Array[int] = []
var rolling := false
var formal_battle_mode := false
var emit_debug_score_signals := true
var emit_debug_resolution_signals := true
var idle_drift_tuning := DEFAULT_IDLE_DRIFT_TUNING.duplicate(true)
var throw_speed_tuning := DEFAULT_THROW_SPEED_TUNING.duplicate(true)
var throw_spin_tuning := DEFAULT_THROW_SPIN_TUNING.duplicate(true)
var exit_return_tuning := DEFAULT_EXIT_RETURN_TUNING.duplicate(true)
var unselected_hold_tuning := DEFAULT_UNSELECTED_HOLD_TUNING.duplicate(true)

var _roll_elapsed := 0.0
var _pending_launches := 0
var _pending_ready_returns := 0
var _returning_to_ready := false
var _roll_generation := 0
var _recover_count := 0
var _resolution_request_count := 0
var _last_resolution_request := {}
var _dice_exit_request_count := 0
var _last_dice_exit_request := {}
var _dice_exit_animating := false
var _dice_exit_completed := false
var _pending_dice_exit_animations := 0
var _dice_exit_return_animating := false
var _dice_exit_return_completed := false
var _pending_dice_exit_return_animations := 0
var _last_exit_return_face_indices: Array[int] = []
var _held_unselected_dice_indices: Array[int] = []
var _pending_unselected_hold_returns := 0
var _rng := RandomNumberGenerator.new()


func setup(p_ready_mgr: GmReadyMgr, p_dice_container: Node3D) -> void:
	ready_mgr = p_ready_mgr
	dice_container = p_dice_container
	_rng.randomize()


func set_display_die_order(order: Array[int]) -> void:
	display_die_order = _complete_display_order(order)


func clear_display_die_order() -> void:
	display_die_order.clear()


func get_ready_slot_for_die(die_index: int) -> int:
	return _ready_slot_for_die(die_index)


func get_ready_position_for_die(die_index: int) -> Vector3:
	return _ready_position_for_die(die_index)


func apply_display_order_to_ready_positions() -> void:
	if ready_mgr == null or using_dices.is_empty():
		return
	var count := using_dices.size()
	var order := _resolved_display_die_order()
	for visual_slot_index in range(order.size()):
		var die_index := int(order[visual_slot_index])
		if die_index < 0 or die_index >= count:
			continue
		var dice_instance := using_dices[die_index] as GmDiceInstance
		if dice_instance == null or dice_instance.avatar == null:
			continue
		var avatar = dice_instance.avatar
		if avatar.get("is_rolling") or avatar.get("is_returning_to_ready"):
			continue
		if avatar.get("is_exiting") or avatar.get("is_exited") or avatar.get("is_returning_from_exit"):
			continue
		if avatar.get("is_moving_to_unselected_hold") or avatar.get("is_returning_from_unselected_hold"):
			continue
		dice_instance.avatar.set_ready_hover(
			ready_mgr.get_spawn_position(visual_slot_index, count),
			GmReadyMgr.READY_ROW_YAW_DEGREES
		)


func set_formal_battle_mode(enabled: bool) -> void:
	formal_battle_mode = enabled
	emit_debug_score_signals = not enabled
	emit_debug_resolution_signals = not enabled


func set_idle_drift_tuning(config_values: Dictionary) -> void:
	var min_seconds := clampf(float(config_values.get("min_seconds", idle_drift_tuning["min_seconds"])), 0.10, 10.0)
	var max_seconds := clampf(float(config_values.get("max_seconds", idle_drift_tuning["max_seconds"])), 0.10, 12.0)
	if max_seconds < min_seconds:
		max_seconds = min_seconds
	idle_drift_tuning = {
		"min_seconds": min_seconds,
		"max_seconds": max_seconds,
		"max_distance": clampf(float(config_values.get("max_distance", idle_drift_tuning["max_distance"])), 0.0, 1.5),
		"speed": clampf(float(config_values.get("speed", idle_drift_tuning["speed"])), 0.0, 1.5),
	}
	for dice_instance in using_dices:
		if dice_instance == null or dice_instance.avatar == null:
			continue
		if dice_instance.avatar.has_method("set_idle_drift_tuning"):
			dice_instance.avatar.call("set_idle_drift_tuning", idle_drift_tuning)


func set_throw_spin_tuning(config_values: Dictionary) -> void:
	var angular_min := clampf(float(config_values.get("angular_speed_min", throw_spin_tuning["angular_speed_min"])), 0.0, 48.0)
	var angular_max := clampf(float(config_values.get("angular_speed_max", throw_spin_tuning["angular_speed_max"])), 0.0, 48.0)
	if angular_max < angular_min:
		angular_max = angular_min
	var torque_min := clampf(float(config_values.get("torque_min", throw_spin_tuning["torque_min"])), 0.0, 32.0)
	var torque_max := clampf(float(config_values.get("torque_max", throw_spin_tuning["torque_max"])), 0.0, 32.0)
	if torque_max < torque_min:
		torque_max = torque_min
	throw_spin_tuning = {
		"angular_speed_min": angular_min,
		"angular_speed_max": angular_max,
		"torque_min": torque_min,
		"torque_max": torque_max,
	}
	for dice_instance in using_dices:
		if dice_instance == null or dice_instance.avatar == null:
			continue
		if dice_instance.avatar.has_method("set_throw_spin_tuning"):
			dice_instance.avatar.call("set_throw_spin_tuning", throw_spin_tuning)


func set_throw_speed_tuning(config_values: Dictionary) -> void:
	var speed_min := clampf(float(config_values.get("linear_speed_min", throw_speed_tuning["linear_speed_min"])), 0.0, 24.0)
	var speed_max := clampf(float(config_values.get("linear_speed_max", throw_speed_tuning["linear_speed_max"])), 0.0, 24.0)
	if speed_max < speed_min:
		speed_max = speed_min
	throw_speed_tuning = {
		"linear_speed_min": speed_min,
		"linear_speed_max": speed_max,
	}
	for dice_instance in using_dices:
		if dice_instance == null or dice_instance.avatar == null:
			continue
		if dice_instance.avatar.has_method("set_throw_speed_tuning"):
			dice_instance.avatar.call("set_throw_speed_tuning", throw_speed_tuning)


func set_exit_return_tuning(config_values: Dictionary) -> void:
	var fallback_screen_x := float(exit_return_tuning.get("screen_x", DEFAULT_EXIT_RETURN_TUNING["screen_x"]))
	if config_values.has("spawn_x"):
		fallback_screen_x = clampf(float(config_values["spawn_x"]) / 8.0, 0.0, 1.0)
	var fallback_spawn_y := float(exit_return_tuning.get("spawn_y", DEFAULT_EXIT_RETURN_TUNING["spawn_y"]))
	exit_return_tuning = {
		"screen_x": clampf(float(config_values.get("screen_x", fallback_screen_x)), 0.0, 1.0),
		"screen_y": clampf(float(config_values.get("screen_y", exit_return_tuning.get("screen_y", DEFAULT_EXIT_RETURN_TUNING["screen_y"]))), 0.0, 1.0),
		"spawn_y": clampf(float(config_values.get("spawn_y", fallback_spawn_y)), 0.0, 30.0),
	}
	if config_values.has("entry_world_position") and config_values["entry_world_position"] is Vector3:
		exit_return_tuning["entry_world_position"] = config_values["entry_world_position"]


func set_unselected_hold_tuning(config_values: Dictionary) -> void:
	var fallback_screen_x := float(unselected_hold_tuning.get("screen_x", DEFAULT_UNSELECTED_HOLD_TUNING["screen_x"]))
	var fallback_screen_y := float(unselected_hold_tuning.get("screen_y", DEFAULT_UNSELECTED_HOLD_TUNING["screen_y"]))
	unselected_hold_tuning = {
		"screen_x": clampf(float(config_values.get("screen_x", fallback_screen_x)), 0.0, 1.0),
		"screen_y": clampf(float(config_values.get("screen_y", fallback_screen_y)), 0.0, 1.0),
		"max_width": clampf(float(config_values.get("max_width", unselected_hold_tuning.get("max_width", DEFAULT_UNSELECTED_HOLD_TUNING["max_width"]))), 0.10, 8.0),
		"duration": clampf(float(config_values.get("duration", unselected_hold_tuning.get("duration", DEFAULT_UNSELECTED_HOLD_TUNING["duration"]))), 0.05, 2.0),
	}
	if config_values.has("center_world_position") and config_values["center_world_position"] is Vector3:
		unselected_hold_tuning["center_world_position"] = config_values["center_world_position"]


func replace_selected_dice_material_and_pips(material_id, face_pips: Array) -> Dictionary:
	return replace_dice_material_and_pips(selected_dice_indices, material_id, face_pips)


func replace_all_dice_material_and_pips(material_id, face_pips: Array) -> Dictionary:
	var indices: Array[int] = []
	for index in range(using_dices.size()):
		indices.append(index)
	return replace_dice_material_and_pips(indices, material_id, face_pips)


func replace_dice_material_and_pips(indices: Array, material_id, face_pips: Array) -> Dictionary:
	var normalized_material_id := GmDiceDefinition.normalize_material_id(StringName(str(material_id)))
	var normalized_pips := _normalize_face_pips(face_pips)
	var result := {
		"success": false,
		"changed_indices": [],
		"material_id": str(normalized_material_id),
		"face_pips": normalized_pips,
		"reason": "",
	}
	if rolling or _dice_exit_animating or _dice_exit_return_animating or _dice_exit_completed:
		result["reason"] = "当前不能改骰"
		return result
	if indices.is_empty():
		result["reason"] = "请先选择骰子"
		return result
	var changed_indices: Array[int] = []
	for raw_index in indices:
		var index := int(raw_index)
		if index < 0 or index >= using_dices.size() or changed_indices.has(index):
			continue
		var dice_instance := using_dices[index] as GmDiceInstance
		if dice_instance == null:
			continue
		dice_instance.set_material_id(normalized_material_id)
		dice_instance.replace_face_pips(normalized_pips)
		if dice_instance.avatar != null and dice_instance.avatar.has_method("refresh_from_config"):
			dice_instance.avatar.call("refresh_from_config")
		changed_indices.append(index)
	if changed_indices.is_empty():
		result["reason"] = "没有可替换的骰子"
		return result
	result["success"] = true
	result["changed_indices"] = changed_indices
	compute_score(false)
	dice_roster_changed.emit(get_snapshot())
	return result


func create_dice_from_box(count: int, definition: GmDiceDefinition) -> void:
	clear()
	if ready_mgr == null:
		return
	selected_dice_indices.clear()
	using_dices = ready_mgr.create_initial_dices(count, definition)
	for index in range(using_dices.size()):
		var instance := using_dices[index] as GmDiceInstance
		var avatar := ready_mgr.spawn_dice_avatar(instance, index, using_dices.size())
		if avatar != null:
			avatar.set_idle_drift_tuning(idle_drift_tuning)
			avatar.set_throw_speed_tuning(throw_speed_tuning)
			avatar.set_throw_spin_tuning(throw_spin_tuning)
			avatar.roll_started.connect(_on_dice_roll_started)
			avatar.roll_stopped.connect(_on_dice_roll_stopped)
			avatar.selection_requested.connect(_on_dice_selection_requested)
	_sync_selection_visuals()
	compute_score(false)
	dice_roster_changed.emit(get_snapshot())


func create_dice_from_definitions(definitions: Array) -> void:
	clear()
	if ready_mgr == null:
		return
	selected_dice_indices.clear()
	for raw_definition in definitions:
		var definition := raw_definition as GmDiceDefinition
		if definition == null:
			continue
		var instance := GmDiceInstanceScript.from_definition(definition)
		using_dices.append(instance)
	for index in range(using_dices.size()):
		var instance := using_dices[index] as GmDiceInstance
		var avatar := ready_mgr.spawn_dice_avatar(instance, index, using_dices.size())
		if avatar != null:
			avatar.set_idle_drift_tuning(idle_drift_tuning)
			avatar.set_throw_speed_tuning(throw_speed_tuning)
			avatar.set_throw_spin_tuning(throw_spin_tuning)
			avatar.roll_started.connect(_on_dice_roll_started)
			avatar.roll_stopped.connect(_on_dice_roll_stopped)
			avatar.selection_requested.connect(_on_dice_selection_requested)
	_sync_selection_visuals()
	compute_score(false)
	dice_roster_changed.emit(get_snapshot())


func clear() -> void:
	rolling = false
	_roll_elapsed = 0.0
	_pending_launches = 0
	_pending_ready_returns = 0
	_returning_to_ready = false
	_roll_generation += 1
	_recover_count = 0
	_resolution_request_count = 0
	_dice_exit_request_count = 0
	_dice_exit_animating = false
	_dice_exit_completed = false
	_pending_dice_exit_animations = 0
	_dice_exit_return_animating = false
	_dice_exit_return_completed = false
	_pending_dice_exit_return_animations = 0
	_last_exit_return_face_indices.clear()
	_held_unselected_dice_indices.clear()
	_pending_unselected_hold_returns = 0
	last_values.clear()
	last_targets.clear()
	last_rolled_dice_indices.clear()
	display_die_order.clear()
	_last_resolution_request.clear()
	_last_dice_exit_request.clear()
	bag_dices.clear()
	tomb_dices.clear()
	using_dices.clear()
	score_dices.clear()
	destroy_dices.clear()
	temp_dices.clear()
	reserve_dices.clear()
	hot_dices.clear()
	boss_dice = null
	base_score = 0
	mult_score = 1
	final_score = 0
	current_score_num = 0
	selected_dice_indices.clear()
	if ready_mgr != null:
		ready_mgr.clear_avatars()
	dice_roster_changed.emit(get_snapshot())


func start_new_turn() -> void:
	roll_num = 0
	dice_change_num = 0
	score_dices.clear()
	last_values.clear()
	last_rolled_dice_indices.clear()
	selected_dice_indices.clear()
	_sync_selection_visuals()
	compute_score(false)


func request_dice_exit_from_current_state() -> Dictionary:
	if using_dices.is_empty() or rolling or _dice_exit_animating or _dice_exit_completed or _dice_exit_return_animating:
		return {}
	var score_snapshot := compute_score(true)
	var request := _request_dice_exit_after_score(score_snapshot)
	_play_dice_exit_preview(request)
	return request


func request_dice_return_from_exit() -> bool:
	if using_dices.is_empty() or rolling or _dice_exit_animating or _dice_exit_return_animating or not _dice_exit_completed:
		return false
	_play_dice_exit_return_preview()
	return true


func request_dice_entry_return() -> bool:
	if using_dices.is_empty() or rolling or _dice_exit_animating or _dice_exit_return_animating:
		return false
	_play_dice_exit_return_preview()
	return true


func roll_using_dices(target_values: Array = []) -> void:
	if using_dices.is_empty():
		return
	var roll_indices := selected_dice_indices.duplicate()
	if roll_indices.is_empty():
		return
	roll_num += 1
	rolling = true
	_returning_to_ready = false
	_pending_ready_returns = 0
	_dice_exit_animating = false
	_dice_exit_completed = false
	_pending_dice_exit_animations = 0
	_dice_exit_return_animating = false
	_dice_exit_return_completed = false
	_pending_dice_exit_return_animations = 0
	_last_exit_return_face_indices.clear()
	_held_unselected_dice_indices.clear()
	_pending_unselected_hold_returns = 0
	_roll_elapsed = 0.0
	_roll_generation += 1
	_recover_count = 0
	last_values.clear()
	last_rolled_dice_indices = roll_indices.duplicate()
	_last_resolution_request.clear()
	_last_dice_exit_request.clear()
	last_targets = _normalize_targets(target_values)
	var launch_items: Array = []
	for index in range(using_dices.size()):
		if not roll_indices.has(index):
			continue
		var dice_instance := using_dices[index] as GmDiceInstance
		if dice_instance == null or not dice_instance.can_roll or dice_instance.avatar == null:
			continue
		var requested = last_targets[index] if index < last_targets.size() else null
		launch_items.append({
			"dice": dice_instance,
			"index": index,
			"requested": requested,
		})
	if launch_items.is_empty():
		rolling = false
		return
	_move_unselected_dice_to_hold(roll_indices)
	_pending_launches = launch_items.size()
	selected_dice_indices.clear()
	_sync_selection_visuals()
	roll_started.emit(get_snapshot())
	var generation := _roll_generation
	for item in launch_items:
		_launch_dice_avatar(item["dice"] as GmDiceInstance, int(item["index"]), item["requested"], generation)


func all_dice_stop() -> bool:
	for dice_instance in using_dices:
		if dice_instance == null or dice_instance.avatar == null:
			continue
		if dice_instance.avatar.is_rolling and not dice_instance.avatar.check_roll_stop():
			return false
	return true


func compute_score(ignore_status := false) -> Dictionary:
	base_score = 0
	last_values.clear()
	for dice_instance in using_dices:
		if dice_instance == null:
			continue
		var face_value: int = dice_instance.get_actual_face_one()
		last_values.append(face_value)
		base_score += face_value
	mult_score = max(1, using_dices.size())
	final_score = base_score * mult_score
	current_score_num = final_score
	var snapshot := get_snapshot()
	if not ignore_status:
		score_updated.emit(snapshot)
	return snapshot


func check_fit_rule() -> Dictionary:
	return {
		"ok": true,
		"rule": "GM 原型：POINT 合计后乘参与骰数",
		"context": get_score_context(),
	}


func check_result() -> bool:
	return target_score_num <= 0 or current_score_num >= target_score_num


func get_score_context() -> Dictionary:
	return {
		"POINT": base_score,
		"ROLLNUM": roll_num,
		"REROLLNUM": max(0, roll_num - 1),
		"USEDICENUM": using_dices.size(),
		"BOSS": boss_dice != null,
		"ISBOSS": boss_dice != null,
	}


func get_snapshot() -> Dictionary:
	var face_indices: Array[int] = []
	var positions: Array[Vector3] = []
	var dice_rows: Array = []
	var active_count := 0
	for dice_instance in using_dices:
		if dice_instance == null:
			continue
		active_count += 1
		face_indices.append(dice_instance.value)
		var avatar = dice_instance.avatar
		if avatar != null:
			positions.append(avatar.global_position)
			dice_rows.append(avatar.get_debug_snapshot())
		else:
			positions.append(Vector3.ZERO)
			dice_rows.append(dice_instance.to_dictionary())
	return {
		"dice_count": using_dices.size(),
		"active_dice": active_count,
		"rolling": rolling,
		"roll_num": roll_num,
		"last_values": last_values.duplicate(),
		"last_face_indices": face_indices,
		"targets": last_targets.duplicate(),
		"last_rolled_dice_indices": last_rolled_dice_indices.duplicate(),
		"selected_dice_indices": selected_dice_indices.duplicate(),
		"display_die_order": _resolved_display_die_order(),
		"dice_positions": positions,
		"dice": dice_rows,
		"score": {
			"base_score": base_score,
			"mult_score": mult_score,
			"final_score": final_score,
			"current_score": current_score_num,
		},
		"score_context": get_score_context(),
		"idle_drift_tuning": idle_drift_tuning.duplicate(true),
		"throw_speed_tuning": throw_speed_tuning.duplicate(true),
		"throw_spin_tuning": throw_spin_tuning.duplicate(true),
		"exit_return_tuning": exit_return_tuning.duplicate(true),
		"unselected_hold_tuning": unselected_hold_tuning.duplicate(true),
		"held_unselected_dice_indices": _held_unselected_dice_indices.duplicate(),
		"pending_unselected_hold_returns": _pending_unselected_hold_returns,
		"unselected_hold_active": not _held_unselected_dice_indices.is_empty() or _pending_unselected_hold_returns > 0,
		"recover_count": _recover_count,
		"pending_launches": _pending_launches,
		"pending_ready_returns": _pending_ready_returns,
		"ready_return_duration_seconds": _ready_return_duration_for_current_roll(),
		"dice_exit_animating": _dice_exit_animating,
		"dice_exit_completed": _dice_exit_completed,
		"pending_dice_exit_animations": _pending_dice_exit_animations,
		"dice_exit_return_animating": _dice_exit_return_animating,
		"dice_exit_return_completed": _dice_exit_return_completed,
		"pending_dice_exit_return_animations": _pending_dice_exit_return_animations,
		"last_exit_return_face_indices": _last_exit_return_face_indices.duplicate(),
		"resolution_request_count": _resolution_request_count,
		"last_resolution_request": _last_resolution_request.duplicate(true),
		"dice_exit_request_count": _dice_exit_request_count,
		"last_dice_exit_request": _last_dice_exit_request.duplicate(true),
	}


func _physics_process(delta: float) -> void:
	if not rolling:
		return
	_roll_elapsed += delta
	if _returning_to_ready:
		return
	_recover_fallen_dice()
	if _pending_launches > 0:
		return
	if not all_dice_stop():
		return
	_begin_ready_return_after_roll()


func _begin_ready_return_after_roll() -> void:
	_returning_to_ready = true
	_pending_ready_returns = 0
	var ready_return_duration := _ready_return_duration_for_current_roll()
	for index in range(using_dices.size()):
		var dice_instance := using_dices[index] as GmDiceInstance
		if dice_instance == null or dice_instance.avatar == null or ready_mgr == null:
			continue
		if dice_instance.avatar.is_rolling:
			dice_instance.avatar.after_roll(true)
			_pending_ready_returns += 1
			dice_instance.avatar.ready_return_finished.connect(_on_dice_ready_return_finished, CONNECT_ONE_SHOT)
			dice_instance.avatar.return_to_ready_hover(
				_ready_position_for_die(index),
				GmReadyMgr.READY_ROW_YAW_DEGREES,
				ready_return_duration
			)
	_begin_unselected_hold_return(ready_return_duration)
	if _pending_ready_returns <= 0:
		_finish_ready_return()


func _ready_return_duration_for_current_roll() -> float:
	return READY_RETURN_DURATION
	if _pending_ready_returns <= 0:
		_finish_ready_return()


func _finish_ready_return() -> void:
	_pending_ready_returns = 0
	_returning_to_ready = false
	rolling = false
	if emit_debug_resolution_signals:
		_request_resolution_after_ready_return()
	var score_snapshot := compute_score(not emit_debug_score_signals)
	if emit_debug_resolution_signals:
		_request_dice_exit_after_score(score_snapshot)
	roll_finished.emit(get_snapshot())


func _request_resolution_after_ready_return() -> Dictionary:
	_resolution_request_count += 1
	var request := _build_resolution_request(_resolution_request_count)
	_last_resolution_request = request.duplicate(true)
	resolution_requested.emit(request.duplicate(true))
	return request


func _build_resolution_request(request_index: int) -> Dictionary:
	var dice_rows := _build_resolution_dice_rows()
	var pip_values: Array[int] = []
	var point_total := 0
	for row in dice_rows:
		if not (row is Dictionary):
			continue
		var pip := int(row.get("face_value", 0))
		pip_values.append(pip)
		point_total += pip
	var score_request := {
		"formula": "POINT",
		"pip_values": pip_values,
		"point_total": point_total,
	}
	return {
		"source": "gm_physics_dice",
		"phase": "after_ready_return",
		"request_index": request_index,
		"roll_num": roll_num,
		"rolled_dice_indices": last_rolled_dice_indices.duplicate(),
		"targets": last_targets.duplicate(),
		"dice": dice_rows,
		"score_request": score_request,
		"effect_request": {
			"status": "reserved_for_formal_game",
			"steps": [],
		},
	}


func _build_resolution_dice_rows() -> Array:
	var rows: Array = []
	for index in range(using_dices.size()):
		var dice_instance := using_dices[index] as GmDiceInstance
		if dice_instance == null:
			continue
		var row := {
			"die_index": index,
			"face_index": dice_instance.value,
			"face_value": dice_instance.get_actual_face_one(),
			"face_label": dice_instance.get_actual_face_label(),
			"rolled": last_rolled_dice_indices.has(index),
		}
		if dice_instance.avatar != null and dice_instance.avatar.has_method("get_debug_snapshot"):
			var avatar_snapshot: Dictionary = dice_instance.avatar.call("get_debug_snapshot")
			row["settled_face_index"] = int(avatar_snapshot.get("last_settled_face_index", dice_instance.value))
			row["settled_face_value"] = int(avatar_snapshot.get("last_settled_face_value", dice_instance.get_actual_face_one()))
			row["visual_top_face_index"] = int(avatar_snapshot.get("visual_top_face_index", dice_instance.value))
			row["visual_top_face_value"] = int(avatar_snapshot.get("visual_top_face_value", dice_instance.get_actual_face_one()))
		rows.append(row)
	return rows


func _request_dice_exit_after_score(score_snapshot: Dictionary) -> Dictionary:
	_dice_exit_request_count += 1
	var request := _build_dice_exit_request(_dice_exit_request_count, score_snapshot)
	_last_dice_exit_request = request.duplicate(true)
	dice_exit_requested.emit(request.duplicate(true))
	return request


func _build_dice_exit_request(request_index: int, score_snapshot: Dictionary) -> Dictionary:
	var sequence := _build_dice_exit_sequence()
	return {
		"source": "gm_physics_dice",
		"phase": "after_score_resolved",
		"request_index": request_index,
		"roll_num": roll_num,
		"score": score_snapshot.get("score", {}),
		"sequence": sequence,
		"animation": {
			"order": "left_to_right",
			"world_exit_direction": Vector3(0.0, 0.0, -1.0),
			"world_exit_offset": Vector3(0.0, 0.0, -8.0),
			"step_delay_seconds": 0.12,
			"duration_seconds": 0.55,
			"curve": "straight",
			"arc_height": 0.0,
		},
		"next_round": {
			"wait": true,
			"status": "reserved_for_formal_game",
		},
	}


func _build_dice_exit_sequence() -> Array:
	var items: Array = []
	for index in range(using_dices.size()):
		var dice_instance := using_dices[index] as GmDiceInstance
		if dice_instance == null:
			continue
		var start_position := Vector3.ZERO
		if dice_instance.avatar != null:
			start_position = dice_instance.avatar.global_position
		items.append({
			"die_index": index,
			"start_position": start_position,
			"face_index": dice_instance.value,
			"face_value": dice_instance.get_actual_face_one(),
		})
	items.sort_custom(func(a, b) -> bool:
		var a_item := a as Dictionary
		var b_item := b as Dictionary
		var a_position: Vector3 = a_item.get("start_position", Vector3.ZERO)
		var b_position: Vector3 = b_item.get("start_position", Vector3.ZERO)
		if is_equal_approx(a_position.x, b_position.x):
			return int(a_item.get("die_index", 0)) < int(b_item.get("die_index", 0))
		return a_position.x < b_position.x
	)
	for order_index in range(items.size()):
		var item: Dictionary = items[order_index]
		item["order_index"] = order_index
		item["delay_seconds"] = float(order_index) * 0.12
		item["exit_direction"] = Vector3(0.0, 0.0, -1.0)
	return items


func _play_dice_exit_preview(request: Dictionary) -> void:
	var sequence: Array = request.get("sequence", [])
	var animation: Dictionary = request.get("animation", {})
	if sequence.is_empty():
		return
	selected_dice_indices.clear()
	_sync_selection_visuals()
	_dice_exit_animating = true
	_dice_exit_completed = false
	_dice_exit_return_animating = false
	_dice_exit_return_completed = false
	_pending_dice_exit_animations = 0
	_pending_dice_exit_return_animations = 0
	var world_exit_offset := animation.get("world_exit_offset", Vector3(0.0, 0.0, -8.0)) as Vector3
	var duration := float(animation.get("duration_seconds", 0.55))
	var arc_height := float(animation.get("arc_height", 0.0))
	for raw_item in sequence:
		if not (raw_item is Dictionary):
			continue
		var item: Dictionary = raw_item
		var die_index := int(item.get("die_index", -1))
		if die_index < 0 or die_index >= using_dices.size():
			continue
		var dice_instance := using_dices[die_index] as GmDiceInstance
		if dice_instance == null or dice_instance.avatar == null:
			continue
		var start_position: Vector3 = item.get("start_position", dice_instance.avatar.global_position)
		var target_position := start_position + world_exit_offset
		var delay := float(item.get("delay_seconds", 0.0))
		_pending_dice_exit_animations += 1
		dice_instance.avatar.exit_finished.connect(_on_dice_exit_finished, CONNECT_ONE_SHOT)
		dice_instance.avatar.play_exit_to(target_position, duration, delay, arc_height)
	if _pending_dice_exit_animations <= 0:
		_dice_exit_animating = false
		_dice_exit_completed = true
	dice_roster_changed.emit(get_snapshot())


func _play_dice_exit_return_preview() -> void:
	if ready_mgr == null:
		return
	var items: Array = []
	for index in range(using_dices.size()):
		var dice_instance := using_dices[index] as GmDiceInstance
		if dice_instance == null or dice_instance.avatar == null:
			continue
		var target_position := _ready_position_for_die(index)
		items.append({
			"die_index": index,
			"dice": dice_instance,
			"target_position": target_position,
		})
	items.sort_custom(func(a, b) -> bool:
		var a_item := a as Dictionary
		var b_item := b as Dictionary
		var a_position: Vector3 = a_item.get("target_position", Vector3.ZERO)
		var b_position: Vector3 = b_item.get("target_position", Vector3.ZERO)
		if is_equal_approx(a_position.x, b_position.x):
			return int(a_item.get("die_index", 0)) < int(b_item.get("die_index", 0))
		return a_position.x < b_position.x
	)
	if items.is_empty():
		return
	selected_dice_indices.clear()
	_sync_selection_visuals()
	_dice_exit_completed = false
	_dice_exit_return_animating = true
	_dice_exit_return_completed = false
	_pending_dice_exit_return_animations = 0
	_held_unselected_dice_indices.clear()
	_pending_unselected_hold_returns = 0
	_last_exit_return_face_indices.clear()
	_last_exit_return_face_indices.resize(using_dices.size())
	for face_index in range(_last_exit_return_face_indices.size()):
		_last_exit_return_face_indices[face_index] = -1
	var spawn_y := float(exit_return_tuning.get("spawn_y", DEFAULT_EXIT_RETURN_TUNING["spawn_y"]))
	var spawn_position := Vector3(3.0, spawn_y, 0.08)
	if exit_return_tuning.has("entry_world_position") and exit_return_tuning["entry_world_position"] is Vector3:
		spawn_position = exit_return_tuning["entry_world_position"]
		spawn_position.y = spawn_y
	for order_index in range(items.size()):
		var item: Dictionary = items[order_index]
		var dice_instance := item.get("dice") as GmDiceInstance
		if dice_instance == null or dice_instance.avatar == null:
			continue
		var die_index := int(item.get("die_index", -1))
		var return_face_index := _random_exit_return_face_index(dice_instance)
		dice_instance.set_face_index(return_face_index)
		if die_index >= 0 and die_index < _last_exit_return_face_indices.size():
			_last_exit_return_face_indices[die_index] = return_face_index
		var target_position: Vector3 = item.get("target_position", Vector3.ZERO)
		var delay := float(order_index) * EXIT_RETURN_STEP_DELAY
		_pending_dice_exit_return_animations += 1
		dice_instance.avatar.exit_return_finished.connect(_on_dice_exit_return_finished, CONNECT_ONE_SHOT)
		dice_instance.avatar.play_exit_return_from(
			spawn_position,
			target_position,
			GmReadyMgr.READY_ROW_YAW_DEGREES,
			EXIT_RETURN_DURATION,
			delay
		)
	if _pending_dice_exit_return_animations <= 0:
		_dice_exit_return_animating = false
		_dice_exit_return_completed = true
	compute_score(false)
	dice_roster_changed.emit(get_snapshot())


func toggle_select(index: int) -> void:
	if rolling or _dice_exit_animating or _dice_exit_return_animating or _dice_exit_completed or index < 0 or index >= using_dices.size():
		return
	var existing_index := selected_dice_indices.find(index)
	if existing_index >= 0:
		selected_dice_indices.remove_at(existing_index)
	else:
		selected_dice_indices.append(index)
	selected_dice_indices.sort()
	_sync_selection_visuals()
	dice_roster_changed.emit(get_snapshot())


func set_selected_indices(indices: Array) -> void:
	if rolling or _dice_exit_animating or _dice_exit_return_animating or _dice_exit_completed:
		return
	var resolved: Array[int] = []
	for raw_index in indices:
		var index := int(raw_index)
		if index >= 0 and index < using_dices.size() and not resolved.has(index):
			resolved.append(index)
	resolved.sort()
	selected_dice_indices = resolved
	_sync_selection_visuals()
	dice_roster_changed.emit(get_snapshot())


func get_selected_indices() -> Array[int]:
	return selected_dice_indices.duplicate()


func toggle_select_by_avatar(dice) -> void:
	for index in range(using_dices.size()):
		var dice_instance := using_dices[index] as GmDiceInstance
		if dice_instance != null and dice_instance.avatar == dice:
			toggle_select(index)
			return


func _launch_dice_avatar(dice_instance: GmDiceInstance, _dice_index: int, requested, generation: int) -> void:
	if generation != _roll_generation or not rolling:
		return
	_pending_launches = maxi(0, _pending_launches - 1)
	if dice_instance == null or dice_instance.avatar == null or not dice_instance.can_roll:
		return
	dice_instance.avatar.roll(requested, true)


func _move_unselected_dice_to_hold(roll_indices: Array) -> void:
	_held_unselected_dice_indices.clear()
	_pending_unselected_hold_returns = 0
	if ready_mgr == null:
		return
	var items: Array = []
	for index in range(using_dices.size()):
		if roll_indices.has(index):
			continue
		var dice_instance := using_dices[index] as GmDiceInstance
		if dice_instance == null or dice_instance.avatar == null:
			continue
		items.append({
			"die_index": index,
			"dice": dice_instance,
		})
	if items.is_empty():
		return
	items.sort_custom(func(a, b) -> bool:
		var a_index := int((a as Dictionary).get("die_index", 0))
		var b_index := int((b as Dictionary).get("die_index", 0))
		var a_slot := _ready_slot_for_die(a_index)
		var b_slot := _ready_slot_for_die(b_index)
		if a_slot == b_slot:
			return a_index < b_index
		return a_slot < b_slot
	)
	var center_position := _unselected_hold_center_position()
	var spacing := _unselected_hold_spacing(items.size())
	var duration := float(unselected_hold_tuning.get("duration", DEFAULT_UNSELECTED_HOLD_TUNING["duration"]))
	for order_index in range(items.size()):
		var item: Dictionary = items[order_index]
		var dice_instance := item.get("dice") as GmDiceInstance
		if dice_instance == null or dice_instance.avatar == null:
			continue
		var die_index := int(item.get("die_index", -1))
		var lane := float(order_index) - (float(items.size()) - 1.0) * 0.5
		var target_position := center_position + Vector3(lane * spacing, 0.0, 0.0)
		_held_unselected_dice_indices.append(die_index)
		dice_instance.avatar.move_to_unselected_hold(
			target_position,
			duration,
			GmReadyMgr.READY_ROW_YAW_DEGREES
		)


func _begin_unselected_hold_return(duration: float) -> void:
	if _held_unselected_dice_indices.is_empty() or ready_mgr == null:
		return
	var return_indices := _held_unselected_dice_indices.duplicate()
	_held_unselected_dice_indices.clear()
	for raw_index in return_indices:
		var index := int(raw_index)
		if index < 0 or index >= using_dices.size():
			continue
		var dice_instance := using_dices[index] as GmDiceInstance
		if dice_instance == null or dice_instance.avatar == null:
			continue
		_pending_ready_returns += 1
		_pending_unselected_hold_returns += 1
		dice_instance.avatar.unselected_hold_return_finished.connect(_on_unselected_hold_return_finished, CONNECT_ONE_SHOT)
		dice_instance.avatar.return_unselected_hold_to_ready(
			_ready_position_for_die(index),
			GmReadyMgr.READY_ROW_YAW_DEGREES,
			duration
		)


func _unselected_hold_center_position() -> Vector3:
	if unselected_hold_tuning.has("center_world_position") and unselected_hold_tuning["center_world_position"] is Vector3:
		return unselected_hold_tuning["center_world_position"]
	if ready_mgr != null:
		var ready_center := ready_mgr.get_spawn_position(0, 1)
		return Vector3(ready_center.x, ready_center.y, ready_center.z + 2.40)
	return Vector3(0.0, 7.5, 2.40)


func _unselected_hold_spacing(count: int) -> float:
	if count <= 1:
		return 0.0
	var max_width := maxf(0.10, float(unselected_hold_tuning.get("max_width", DEFAULT_UNSELECTED_HOLD_TUNING["max_width"])))
	var spacing_limit := max_width / float(count - 1)
	return minf(GmReadyMgr.READY_ROW_SPACING_X, spacing_limit)


func _recover_fallen_dice() -> void:
	if ready_mgr == null:
		return
	for index in range(using_dices.size()):
		var dice_instance := using_dices[index] as GmDiceInstance
		if dice_instance == null or dice_instance.avatar == null:
			continue
		var avatar = dice_instance.avatar
		if not avatar.is_rolling:
			continue
		var pos: Vector3 = avatar.global_position
		var fallen := (
			pos.y < FALL_RECOVER_Y
			or absf(pos.x) > FAR_OUTSIDE_X
			or absf(pos.z) > FAR_OUTSIDE_Z
		)
		if not fallen:
			continue
		var requested = last_targets[index] if index < last_targets.size() else null
		var stage_position := _ready_position_for_die(index) + Vector3(0.0, 0.35, 0.0)
		_recover_count += 1
		avatar.recover_to_stage(stage_position, requested)


func _sync_selection_visuals() -> void:
	for index in range(using_dices.size()):
		var dice_instance := using_dices[index] as GmDiceInstance
		if dice_instance == null or dice_instance.avatar == null:
			continue
		if dice_instance.avatar.has_method("set_selected"):
			dice_instance.avatar.call("set_selected", selected_dice_indices.has(index))


func _normalize_targets(target_values: Array) -> Array:
	var normalized: Array = []
	for index in range(using_dices.size()):
		var value = target_values[index] if index < target_values.size() else null
		if value == null:
			normalized.append(null)
		else:
			var pip := int(value)
			normalized.append(pip if pip >= 1 and pip <= 6 else null)
	return normalized


func _resolved_display_die_order() -> Array[int]:
	if display_die_order.is_empty():
		var natural_order: Array[int] = []
		for index in range(using_dices.size()):
			natural_order.append(index)
		return natural_order
	return _complete_display_order(display_die_order)


func _complete_display_order(source: Array) -> Array[int]:
	var order: Array[int] = []
	var count := using_dices.size()
	for raw_index in source:
		var die_index := int(raw_index)
		if die_index < 0 or die_index >= count or order.has(die_index):
			continue
		order.append(die_index)
	for die_index in range(count):
		if not order.has(die_index):
			order.append(die_index)
	return order


func _ready_slot_for_die(die_index: int) -> int:
	var order := _resolved_display_die_order()
	var slot_index := order.find(die_index)
	if slot_index >= 0:
		return slot_index
	return clampi(die_index, 0, maxi(0, using_dices.size() - 1))


func _ready_position_for_die(die_index: int) -> Vector3:
	if ready_mgr == null:
		return Vector3.ZERO
	return ready_mgr.get_spawn_position(_ready_slot_for_die(die_index), using_dices.size())


func _normalize_face_pips(face_pips: Array) -> Array[int]:
	var normalized: Array[int] = []
	for index in range(6):
		var pip := index + 1
		if index < face_pips.size() and face_pips[index] != null:
			pip = clampi(int(face_pips[index]), 1, 6)
		normalized.append(pip)
	return normalized


func _random_exit_return_face_index(dice_instance: GmDiceInstance) -> int:
	if dice_instance == null or dice_instance.run_faces.is_empty():
		return 0
	return _rng.randi_range(0, dice_instance.run_faces.size() - 1)


func _on_dice_roll_started(_dice) -> void:
	pass


func _on_dice_roll_stopped(_dice, face_index: int, face_value: int) -> void:
	if ready_mgr != null:
		ready_mgr.add_record("face_%d" % face_value, 1)


func _on_dice_ready_return_finished(_dice) -> void:
	if not _returning_to_ready:
		return
	_pending_ready_returns = maxi(0, _pending_ready_returns - 1)
	if _pending_ready_returns <= 0:
		_finish_ready_return()


func _on_unselected_hold_return_finished(_dice) -> void:
	_pending_unselected_hold_returns = maxi(0, _pending_unselected_hold_returns - 1)
	_on_dice_ready_return_finished(_dice)


func _on_dice_exit_finished(_dice) -> void:
	_pending_dice_exit_animations = maxi(0, _pending_dice_exit_animations - 1)
	if _pending_dice_exit_animations <= 0:
		_dice_exit_animating = false
		_dice_exit_completed = true
	dice_roster_changed.emit(get_snapshot())


func _on_dice_exit_return_finished(_dice) -> void:
	_pending_dice_exit_return_animations = maxi(0, _pending_dice_exit_return_animations - 1)
	if _pending_dice_exit_return_animations <= 0:
		_dice_exit_return_animating = false
		_dice_exit_return_completed = true
		_dice_exit_completed = false
	var snapshot := get_snapshot()
	if _pending_dice_exit_return_animations <= 0:
		dice_exit_return_finished.emit(snapshot)
	dice_roster_changed.emit(snapshot)


func _on_dice_selection_requested(dice) -> void:
	toggle_select_by_avatar(dice)
