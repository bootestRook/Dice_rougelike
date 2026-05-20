extends Node
class_name GmBattleMgr


signal dice_roster_changed(snapshot: Dictionary)
signal roll_started(snapshot: Dictionary)
signal roll_finished(snapshot: Dictionary)
signal score_updated(snapshot: Dictionary)


const FALL_RECOVER_Y := -2.20
const FAR_OUTSIDE_X := 10.50
const FAR_OUTSIDE_Z := 7.20
const DEFAULT_THROW_TUNING := {
	"forward_speed": 10.0,
	"lateral_speed": 5.0,
	"upward_speed": 3.2,
	"angular_speed": 28.0,
	"torque_impulse": 24.0,
}


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
var rolling := false
var throw_tuning := DEFAULT_THROW_TUNING.duplicate(true)

var _roll_elapsed := 0.0
var _pending_launches := 0
var _roll_generation := 0
var _recover_count := 0
var _rng := RandomNumberGenerator.new()


func setup(p_ready_mgr: GmReadyMgr, p_dice_container: Node3D) -> void:
	ready_mgr = p_ready_mgr
	dice_container = p_dice_container
	_rng.randomize()


func set_throw_tuning(config_values: Dictionary) -> void:
	for key in throw_tuning.keys():
		if config_values.has(key):
			throw_tuning[key] = maxf(0.0, float(config_values[key]))


func create_dice_from_box(count: int, definition: GmDiceDefinition) -> void:
	clear()
	if ready_mgr == null:
		return
	using_dices = ready_mgr.create_initial_dices(count, definition)
	for index in range(using_dices.size()):
		var instance := using_dices[index] as GmDiceInstance
		var avatar := ready_mgr.spawn_dice_avatar(instance, index, using_dices.size())
		if avatar != null:
			avatar.roll_started.connect(_on_dice_roll_started)
			avatar.roll_stopped.connect(_on_dice_roll_stopped)
	compute_score(false)
	dice_roster_changed.emit(get_snapshot())


func clear() -> void:
	rolling = false
	_roll_elapsed = 0.0
	_pending_launches = 0
	_roll_generation += 1
	_recover_count = 0
	last_values.clear()
	last_targets.clear()
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
	if ready_mgr != null:
		ready_mgr.clear_avatars()
	dice_roster_changed.emit(get_snapshot())


func start_new_turn() -> void:
	roll_num = 0
	dice_change_num = 0
	score_dices.clear()
	last_values.clear()
	compute_score(false)


func roll_using_dices(target_values: Array = []) -> void:
	if using_dices.is_empty():
		return
	roll_num += 1
	rolling = true
	_roll_elapsed = 0.0
	_roll_generation += 1
	_recover_count = 0
	last_values.clear()
	last_targets = _normalize_targets(target_values)
	var launch_items: Array = []
	for index in range(using_dices.size()):
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
	_pending_launches = launch_items.size()
	roll_started.emit(get_snapshot())
	var delay := 0.0
	var generation := _roll_generation
	for index in range(launch_items.size()):
		var item: Dictionary = launch_items[index]
		if index == 0:
			_launch_dice_avatar(item["dice"] as GmDiceInstance, int(item["index"]), item["requested"], generation)
			continue
		delay += _rng.randf_range(0.03, 0.08)
		var timer := get_tree().create_timer(delay)
		timer.timeout.connect(_launch_dice_avatar.bind(item["dice"], int(item["index"]), item["requested"], generation))


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
		"dice_positions": positions,
		"dice": dice_rows,
		"score": {
			"base_score": base_score,
			"mult_score": mult_score,
			"final_score": final_score,
			"current_score": current_score_num,
		},
		"score_context": get_score_context(),
		"throw_tuning": throw_tuning.duplicate(true),
		"recover_count": _recover_count,
	}


func _physics_process(delta: float) -> void:
	if not rolling:
		return
	_roll_elapsed += delta
	_recover_fallen_dice()
	if _pending_launches > 0:
		return
	if not all_dice_stop():
		return
	for dice_instance in using_dices:
		if dice_instance == null or dice_instance.avatar == null:
			continue
		if dice_instance.avatar.is_rolling:
			dice_instance.avatar.after_roll(true)
	for index in range(using_dices.size()):
		var dice_instance := using_dices[index] as GmDiceInstance
		if dice_instance == null or dice_instance.avatar == null or ready_mgr == null:
			continue
		dice_instance.avatar.set_ready_hover(ready_mgr.get_spawn_position(index, using_dices.size()), GmReadyMgr.READY_ROW_YAW_DEGREES)
	rolling = false
	compute_score(false)
	roll_finished.emit(get_snapshot())


func _launch_dice_avatar(dice_instance: GmDiceInstance, dice_index: int, requested, generation: int) -> void:
	if generation != _roll_generation or not rolling:
		return
	_pending_launches = maxi(0, _pending_launches - 1)
	if dice_instance == null or dice_instance.avatar == null or not dice_instance.can_roll:
		return
	if ready_mgr != null:
		dice_instance.avatar.global_position = ready_mgr.get_launch_position(dice_index, using_dices.size())
	dice_instance.avatar.set_throw_tuning(throw_tuning)
	dice_instance.avatar.roll(requested, true)


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
		var stage_position := ready_mgr.get_spawn_position(index, using_dices.size()) + Vector3(0.0, 0.35, 0.0)
		_recover_count += 1
		avatar.recover_to_stage(stage_position, requested)


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


func _on_dice_roll_started(_dice) -> void:
	pass


func _on_dice_roll_stopped(_dice, face_index: int, face_value: int) -> void:
	if ready_mgr != null:
		ready_mgr.add_record("face_%d" % face_value, 1)
