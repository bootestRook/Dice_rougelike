extends Node
class_name GmSceneBridge


signal roll_requested(payload: Dictionary)
signal clear_requested
signal back_requested
signal snapshot_pushed(snapshot: Dictionary)


const CONTRACT_VERSION := 1
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
			"set_throw_tuning",
			"roll",
			"clear",
			"back",
		],
		"snapshot_keys": [
			"dice_count",
			"targets",
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
			"throw_tuning",
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


func make_roll_payload(use_targets: bool, dice_count: int, targets: Array) -> Dictionary:
	var payload := {
		"contract_version": CONTRACT_VERSION,
		"source": INTERFACE_SOURCE,
		"use_targets": use_targets,
		"dice_count": clampi(dice_count, 1, 6),
		"targets": normalize_targets(targets, dice_count),
	}
	roll_requested.emit(payload)
	return payload


func notify_clear() -> void:
	clear_requested.emit()


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
