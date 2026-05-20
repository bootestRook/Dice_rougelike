extends Node
class_name GmDiceFlowModule


signal auto_roll_all_requested(snapshot: Dictionary)
signal auto_roll_all_started(snapshot: Dictionary)
signal auto_roll_all_finished(snapshot: Dictionary)
signal input_lock_changed(locked: bool)
signal state_changed(snapshot: Dictionary)


const AUTO_ROLL_ALL_AFTER_ENTER_DELAY := 1.0
const AUTO_ROLL_ALL_AFTER_EXIT_RETURN_DELAY := 1.0
const AUTO_ROLL_ALL_RETRY_DELAY := 0.20
const AUTO_ROLL_ALL_MAX_RETRIES := 50


var game_mgr: GmGameMgr = null
var battle_mgr: GmBattleMgr = null
var roll_all_callable: Callable
var refresh_callable: Callable

var auto_roll_all_pending := false
var auto_roll_all_active := false
var auto_roll_all_request_count := 0
var auto_roll_all_last_delay_seconds := 0.0

var _auto_roll_all_roll_in_progress := false
var _auto_roll_all_generation := 0


func setup(p_game_mgr: GmGameMgr, p_battle_mgr: GmBattleMgr, p_roll_all_callable: Callable, p_refresh_callable: Callable = Callable()) -> void:
	game_mgr = p_game_mgr
	battle_mgr = p_battle_mgr
	roll_all_callable = p_roll_all_callable
	refresh_callable = p_refresh_callable
	if battle_mgr != null:
		var roll_finished_callable := Callable(self, "_on_battle_roll_finished")
		if not battle_mgr.roll_finished.is_connected(roll_finished_callable):
			battle_mgr.roll_finished.connect(roll_finished_callable)
		var exit_return_callable := Callable(self, "_on_battle_dice_exit_return_finished")
		if not battle_mgr.dice_exit_return_finished.is_connected(exit_return_callable):
			battle_mgr.dice_exit_return_finished.connect(exit_return_callable)


func request_entry_auto_roll() -> void:
	request_auto_roll_all(AUTO_ROLL_ALL_AFTER_ENTER_DELAY)


func request_after_exit_return_auto_roll() -> void:
	request_auto_roll_all(AUTO_ROLL_ALL_AFTER_EXIT_RETURN_DELAY)


func request_auto_roll_all(delay_seconds := AUTO_ROLL_ALL_AFTER_EXIT_RETURN_DELAY) -> void:
	if game_mgr == null or battle_mgr == null:
		return
	_auto_roll_all_generation += 1
	var generation := _auto_roll_all_generation
	_set_auto_roll_all_active(true)
	auto_roll_all_pending = true
	auto_roll_all_request_count += 1
	auto_roll_all_last_delay_seconds = maxf(0.0, float(delay_seconds))
	game_mgr.clear_selection()
	auto_roll_all_requested.emit(_snapshot_with_flow_state(_base_snapshot()))
	_emit_state_changed()
	_run_auto_roll_all_after_delay(generation, auto_roll_all_last_delay_seconds, 0)


func cancel() -> void:
	_auto_roll_all_generation += 1
	_auto_roll_all_roll_in_progress = false
	auto_roll_all_pending = false
	_set_auto_roll_all_active(false)
	_emit_state_changed()


func is_selection_input_locked() -> bool:
	return auto_roll_all_active


func get_snapshot_fields() -> Dictionary:
	return {
		"auto_roll_all_pending": auto_roll_all_pending,
		"auto_roll_all_active": auto_roll_all_active,
		"auto_roll_all_input_locked": is_selection_input_locked(),
		"auto_roll_all_request_count": auto_roll_all_request_count,
		"auto_roll_all_last_delay_seconds": auto_roll_all_last_delay_seconds,
	}


func _run_auto_roll_all_after_delay(generation: int, delay_seconds: float, retry_count: int) -> void:
	if delay_seconds > 0.0:
		var tree := get_tree()
		if tree == null:
			if generation == _auto_roll_all_generation:
				auto_roll_all_pending = false
				_set_auto_roll_all_active(false)
				_emit_state_changed()
			return
		await tree.create_timer(delay_seconds).timeout
	_execute_auto_roll_all(generation, retry_count)


func _execute_auto_roll_all(generation: int, retry_count: int) -> void:
	if generation != _auto_roll_all_generation:
		return
	if game_mgr == null or battle_mgr == null:
		_finish_auto_roll_all_without_roll()
		return
	var snapshot := _base_snapshot()
	if int(snapshot.get("active_dice", 0)) <= 0 or bool(snapshot.get("dice_exit_completed", false)):
		_finish_auto_roll_all_without_roll()
		return
	if (
		bool(snapshot.get("rolling", false))
		or bool(snapshot.get("dice_exit_animating", false))
		or bool(snapshot.get("dice_exit_return_animating", false))
		or int(snapshot.get("pending_ready_returns", 0)) > 0
	):
		if retry_count < AUTO_ROLL_ALL_MAX_RETRIES:
			_run_auto_roll_all_after_delay(generation, AUTO_ROLL_ALL_RETRY_DELAY, retry_count + 1)
			return
		_finish_auto_roll_all_without_roll()
		return
	auto_roll_all_pending = false
	_set_auto_roll_all_active(true)
	_auto_roll_all_roll_in_progress = true
	game_mgr.select_all_dice()
	if roll_all_callable.is_valid():
		roll_all_callable.call()
	else:
		game_mgr.roll_current(false)
	auto_roll_all_started.emit(_snapshot_with_flow_state(_base_snapshot()))
	_emit_state_changed()


func _finish_auto_roll_all_without_roll() -> void:
	auto_roll_all_pending = false
	_auto_roll_all_roll_in_progress = false
	_set_auto_roll_all_active(false)
	_emit_state_changed()


func _on_battle_roll_finished(snapshot: Dictionary) -> void:
	if not _auto_roll_all_roll_in_progress:
		return
	_auto_roll_all_roll_in_progress = false
	auto_roll_all_pending = false
	_set_auto_roll_all_active(false)
	var payload := _snapshot_with_flow_state(snapshot)
	auto_roll_all_finished.emit(payload)
	_emit_state_changed()


func _on_battle_dice_exit_return_finished(_snapshot: Dictionary) -> void:
	request_after_exit_return_auto_roll()


func _set_auto_roll_all_active(value: bool) -> void:
	if auto_roll_all_active == value:
		return
	auto_roll_all_active = value
	input_lock_changed.emit(auto_roll_all_active)


func _base_snapshot() -> Dictionary:
	return battle_mgr.get_snapshot() if battle_mgr != null else {}


func _snapshot_with_flow_state(base_snapshot: Dictionary) -> Dictionary:
	var snapshot := base_snapshot.duplicate(true)
	var fields := get_snapshot_fields()
	for key in fields.keys():
		snapshot[key] = fields[key]
	return snapshot


func _emit_state_changed() -> void:
	state_changed.emit(_snapshot_with_flow_state(_base_snapshot()))
	if refresh_callable.is_valid():
		refresh_callable.call()
