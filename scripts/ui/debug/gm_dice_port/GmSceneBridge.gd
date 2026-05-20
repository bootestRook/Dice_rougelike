extends Node
class_name GmSceneBridge


signal roll_requested(payload: Dictionary)
signal resolution_requested(payload: Dictionary)
signal dice_exit_requested(payload: Dictionary)
signal clear_requested
signal back_requested
signal snapshot_pushed(snapshot: Dictionary)


const CONTRACT_VERSION := 12
const INTERFACE_SOURCE := "GM场景接口"
const LEGACY_TARGET_PLAN_SOURCE := "GM复刻接口"


func get_contract() -> Dictionary:
	return {
		"version": CONTRACT_VERSION,
		"source": INTERFACE_SOURCE,
		"legacy_source": LEGACY_TARGET_PLAN_SOURCE,
		"actions": [
			"configure_session",
			"set_dice_count",
			"set_targets",
			"set_selected_dice_indices",
			"set_idle_drift_tuning",
			"set_throw_speed_tuning",
			"set_throw_spin_tuning",
			"set_exit_return_tuning",
			"request_dice_exit",
			"request_dice_return",
			"request_auto_roll_all",
			"roll",
			"clear",
			"back",
		],
		"events": [
			"roll_requested",
			"resolution_requested",
			"dice_exit_requested",
			"snapshot_pushed",
			"clear_requested",
			"back_requested",
		],
		"snapshot_keys": [
			"dice_count",
			"targets",
			"selected_dice_indices",
			"last_rolled_dice_indices",
			"last_values",
			"score",
			"rolling",
			"target_score",
			"display_mode",
			"camera_control_enabled",
			"camera_projection",
			"camera_fov",
			"camera_yaw",
			"camera_pitch",
			"camera_distance",
			"camera_position",
			"camera_look_at",
			"dice_initial_height",
			"key_light_pitch",
			"key_light_yaw",
			"idle_drift_tuning",
			"throw_speed_tuning",
			"throw_spin_tuning",
			"exit_return_tuning",
			"unselected_hold_tuning",
			"held_unselected_dice_indices",
			"pending_unselected_hold_returns",
			"unselected_hold_active",
			"pending_launches",
			"pending_ready_returns",
			"ready_return_duration_seconds",
			"dice_exit_animating",
			"dice_exit_completed",
			"pending_dice_exit_animations",
			"dice_exit_return_animating",
			"dice_exit_return_completed",
			"pending_dice_exit_return_animations",
			"last_exit_return_face_indices",
			"auto_roll_all_pending",
			"auto_roll_all_active",
			"auto_roll_all_input_locked",
			"auto_roll_all_request_count",
			"auto_roll_all_last_delay_seconds",
			"resolution_request_count",
			"last_resolution_request",
			"dice_exit_request_count",
			"last_dice_exit_request",
		],
	}


func normalize_targets(values: Array, count: int) -> Array:
	var resolved: Array = []
	for index in range(clampi(count, 1, 6)):
		var value = values[index] if index < values.size() else null
		if value == null:
			resolved.append(null)
			continue
		var pip := int(value)
		resolved.append(pip if pip >= 1 and pip <= 6 else null)
	return resolved


func normalize_selected_indices(indices: Array, count: int) -> Array[int]:
	var resolved: Array[int] = []
	for raw_index in indices:
		var index := int(raw_index)
		if index >= 0 and index < count and not resolved.has(index):
			resolved.append(index)
	resolved.sort()
	return resolved


func make_roll_payload(use_targets: bool, dice_count: int, targets: Array, selected_indices: Array = []) -> Dictionary:
	var resolved_count := clampi(dice_count, 1, 6)
	var payload := {
		"contract_version": CONTRACT_VERSION,
		"source": INTERFACE_SOURCE,
		"use_targets": use_targets,
		"dice_count": resolved_count,
		"targets": normalize_targets(targets, resolved_count),
		"selected_dice_indices": normalize_selected_indices(selected_indices, resolved_count),
	}
	roll_requested.emit(payload)
	return payload


func notify_clear() -> void:
	clear_requested.emit()


func notify_resolution_requested(payload: Dictionary) -> void:
	resolution_requested.emit(payload.duplicate(true))


func notify_dice_exit_requested(payload: Dictionary) -> void:
	dice_exit_requested.emit(payload.duplicate(true))


func notify_back() -> void:
	back_requested.emit()


func make_snapshot(base_snapshot: Dictionary, hud_targets: Array, camera_state: Dictionary, target_score: int) -> Dictionary:
	var snapshot := base_snapshot.duplicate(true)
	var dice_count := int(snapshot.get("dice_count", hud_targets.size()))
	snapshot["interface_ready"] = true
	snapshot["interface_source"] = INTERFACE_SOURCE
	snapshot["bridge_contract"] = get_contract()
	snapshot["target_plan_source"] = LEGACY_TARGET_PLAN_SOURCE
	snapshot["targets"] = normalize_targets(hud_targets, maxi(1, dice_count))
	snapshot["selected_dice_indices"] = normalize_selected_indices(snapshot.get("selected_dice_indices", []), maxi(1, dice_count))
	snapshot["planning"] = false
	snapshot["recorded_playback"] = false
	snapshot["target_solver_ready"] = false
	snapshot["target_cache_ready"] = false
	snapshot["target_cache_counts"] = {}
	snapshot["target_min_path_separation"] = 0.0
	snapshot["target_min_table_margin"] = 0.0
	snapshot["target_score"] = target_score
	for key in camera_state.keys():
		snapshot[key] = camera_state[key]
	snapshot_pushed.emit(snapshot)
	return snapshot
