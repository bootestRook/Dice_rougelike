extends Control
class_name GmPhysicsDiceTestScreen


const GmDiceDefinitionScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")
const GmDiceHudScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceHud.gd")
const GmDiceViewportScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceViewport.gd")
const GmReadyMgrScript = preload("res://scripts/ui/debug/gm_dice_port/GmReadyMgr.gd")
const GmBattleMgrScript = preload("res://scripts/ui/debug/gm_dice_port/GmBattleMgr.gd")
const GmGameMgrScript = preload("res://scripts/ui/debug/gm_dice_port/GmGameMgr.gd")
const GmDiceFlowModuleScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceFlowModule.gd")
const GmSceneBridgeScript = preload("res://scripts/ui/debug/gm_dice_port/GmSceneBridge.gd")
const GmProjectedUiBoardScript = preload("res://scripts/ui/debug/gm_dice_port/GmProjectedUiBoard.gd")


signal back_requested
signal roll_requested(payload: Dictionary)
signal resolution_requested(payload: Dictionary)
signal dice_exit_requested(payload: Dictionary)
signal snapshot_changed(snapshot: Dictionary)


const DEFAULT_TARGET_SCORE := 100
const AUTO_ROLL_ALL_AFTER_ENTER_DELAY := 1.0
const AUTO_ROLL_ALL_AFTER_EXIT_RETURN_DELAY := 1.0
const AUTO_ROLL_ALL_RETRY_DELAY := 0.20
const AUTO_ROLL_ALL_MAX_RETRIES := 50


@export_group("Camera")
@export_range(20.0, 70.0, 0.1) var camera_fov := 38.0
@export var camera_position := Vector3(0.0, 18.5, 1.0)
@export var camera_look_at := Vector3(0.0, 0.72, -0.04)
@export_group("Stage")
@export_range(0.8, 10.0, 0.01) var dice_initial_height := 7.5
@export_range(-90.0, 0.0, 0.1) var key_light_pitch := -63.0
@export_range(-180.0, 180.0, 0.1) var key_light_yaw := 115.0

var back_callback: Callable
var scene_bridge: Node = null
var dice_viewport: GmDiceViewport = null
var ready_mgr: GmReadyMgr = null
var battle_mgr: GmBattleMgr = null
var game_mgr: GmGameMgr = null
var dice_flow_module: GmDiceFlowModule = null
var hud: GmDiceHud = null
var projected_ui_board: GmProjectedUiBoard = null
var target_score := DEFAULT_TARGET_SCORE
var idle_drift_tuning := {
	"min_seconds": 1.15,
	"max_seconds": 2.35,
	"max_distance": 0.07,
	"speed": 0.05,
}
var throw_speed_tuning := {
	"linear_speed_min": 8.0,
	"linear_speed_max": 12.0,
}
var throw_spin_tuning := {
	"angular_speed_min": 4.0,
	"angular_speed_max": 9.5,
	"torque_min": 2.0,
	"torque_max": 5.0,
}
var exit_return_tuning := {
	"screen_x": 0.66,
	"screen_y": 0.44,
	"spawn_y": 20.0,
}
var unselected_hold_tuning := {
	"screen_x": 0.50,
	"screen_y": 0.84,
	"max_width": 8.00,
	"duration": 0.36,
}
var auto_roll_all_pending := false
var auto_roll_all_active := false
var auto_roll_all_request_count := 0
var auto_roll_all_last_delay_seconds := 0.0
var _auto_roll_all_roll_in_progress := false
var _auto_roll_all_generation := 0


func setup(return_callback: Callable = Callable()) -> void:
	back_callback = return_callback


func _ready() -> void:
	name = "GmPhysicsDiceTestRoot"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_clear_runtime_nodes()
	_build_screen_backdrop()
	_build_bridge()
	_build_dice_viewport()
	_build_projected_ui_board()
	_build_hud()
	_build_managers()
	game_mgr.boot(4)
	_update_hud()
	if dice_flow_module != null:
		dice_flow_module.request_entry_auto_roll()


func _physics_process(_delta: float) -> void:
	if hud != null and game_mgr != null:
		hud.update_state(automation_get_snapshot())


func automation_get_snapshot() -> Dictionary:
	var snapshot := game_mgr.get_snapshot() if game_mgr != null else {}
	snapshot["editable_materials"] = GmDiceDefinitionScript.get_material_options()
	snapshot["idle_drift_tuning"] = idle_drift_tuning.duplicate()
	snapshot["throw_speed_tuning"] = throw_speed_tuning.duplicate()
	snapshot["throw_spin_tuning"] = throw_spin_tuning.duplicate()
	snapshot["exit_return_tuning"] = _resolved_exit_return_tuning()
	snapshot["unselected_hold_tuning"] = _resolved_unselected_hold_tuning()
	var flow_fields := _dice_flow_snapshot_fields()
	for key in flow_fields.keys():
		snapshot[key] = flow_fields[key]
	var hud_targets := hud.get_targets() if hud != null else []
	var camera_state: Dictionary = dice_viewport.get_camera_state() if dice_viewport != null else {
		"display_mode": "fixed_2_5d_subviewport",
		"camera_control_enabled": false,
		"camera_projection": "perspective",
		"camera_fov": camera_fov,
		"camera_yaw": 0.0,
		"camera_pitch": _camera_pitch_degrees(),
		"camera_distance": camera_position.distance_to(camera_look_at),
		"camera_position": camera_position,
		"camera_look_at": camera_look_at,
		"dice_initial_height": dice_initial_height,
		"key_light_pitch": key_light_pitch,
		"key_light_yaw": key_light_yaw,
	}
	var projected_ui_snapshot := projected_ui_board.automation_get_snapshot() if projected_ui_board != null else {}
	snapshot["projected_ui_board"] = projected_ui_snapshot
	snapshot["projected_ui_board_ready"] = bool(projected_ui_snapshot.get("ready", false))
	snapshot["projected_ui_board_visible"] = bool(projected_ui_snapshot.get("visible", false))
	snapshot["projected_ui_board_flat"] = bool(projected_ui_snapshot.get("flat", false))
	var bridged_snapshot: Dictionary = scene_bridge.make_snapshot(snapshot, hud_targets, camera_state, target_score) if scene_bridge != null else snapshot
	snapshot_changed.emit(bridged_snapshot)
	return bridged_snapshot


func automation_configure_session(config: Dictionary) -> void:
	if config.has("target_score"):
		automation_set_target_score(int(config["target_score"]))
	if config.has("dice_count"):
		automation_set_dice_count(int(config["dice_count"]))
	if config.has("targets"):
		automation_set_targets(config["targets"] as Array)
	if config.has("idle_drift_tuning") and config["idle_drift_tuning"] is Dictionary:
		automation_set_idle_drift_tuning(config["idle_drift_tuning"] as Dictionary)
	if config.has("throw_speed_tuning") and config["throw_speed_tuning"] is Dictionary:
		automation_set_throw_speed_tuning(config["throw_speed_tuning"] as Dictionary)
	if config.has("throw_spin_tuning") and config["throw_spin_tuning"] is Dictionary:
		automation_set_throw_spin_tuning(config["throw_spin_tuning"] as Dictionary)
	if config.has("exit_return_tuning") and config["exit_return_tuning"] is Dictionary:
		automation_set_exit_return_tuning(config["exit_return_tuning"] as Dictionary)
	if config.has("camera_tuning") and config["camera_tuning"] is Dictionary:
		automation_set_camera_tuning(config["camera_tuning"] as Dictionary)
	_update_hud()


func automation_set_target_score(value: int) -> void:
	target_score = maxi(1, value)
	_update_hud()


func automation_set_dice_count(count: int) -> void:
	if hud != null:
		hud.set_dice_count(count)
	if game_mgr != null:
		game_mgr.set_dice_count(count)
	_update_hud()


func automation_set_targets(values: Array) -> void:
	if hud != null:
		hud.set_targets(values)
	if game_mgr != null:
		game_mgr.set_targets(values)
	_update_hud()


func automation_select_dice(indices: Array) -> void:
	if _is_selection_input_locked():
		_update_hud()
		return
	if game_mgr != null:
		game_mgr.set_selected_dice_indices(indices)
	_update_hud()


func automation_toggle_select(index: int) -> void:
	if _is_selection_input_locked():
		_update_hud()
		return
	if game_mgr != null:
		game_mgr.toggle_select(index)
	_update_hud()


func automation_clear_selection() -> void:
	if game_mgr != null:
		game_mgr.clear_selection()
	_update_hud()


func automation_replace_selected_dice(material_id, face_pips: Array) -> Dictionary:
	if _is_selection_input_locked():
		_update_hud()
		return {"success": false, "reason": "当前不能改骰"}
	if game_mgr == null:
		return {"success": false, "reason": "游戏管理器未就绪"}
	var result := game_mgr.replace_selected_dice_material_and_pips(material_id, face_pips)
	_update_hud()
	return result


func automation_replace_all_dice(material_id, face_pips: Array) -> Dictionary:
	if _is_selection_input_locked():
		_update_hud()
		return {"success": false, "reason": "当前不能改骰"}
	if game_mgr == null:
		return {"success": false, "reason": "游戏管理器未就绪"}
	var result := game_mgr.replace_all_dice_material_and_pips(material_id, face_pips)
	_update_hud()
	return result


func automation_click_dice(index: int) -> void:
	if _is_selection_input_locked():
		_update_hud()
		return
	if dice_viewport == null:
		return
	var points := dice_viewport.get_dice_local_points()
	if index < 0 or index >= points.size():
		return
	var dice := dice_viewport.pick_dice_at_local_position(points[index])
	if dice != null:
		_on_dice_viewport_dice_clicked(dice)


func automation_set_idle_drift_tuning(config: Dictionary) -> void:
	if hud != null:
		hud.set_idle_drift_tuning(config)
	idle_drift_tuning = hud.get_idle_drift_tuning() if hud != null else config.duplicate(true)
	if battle_mgr != null:
		battle_mgr.set_idle_drift_tuning(idle_drift_tuning)
	_update_hud()


func automation_set_throw_speed_tuning(config: Dictionary) -> void:
	if hud != null:
		hud.set_throw_speed_tuning(config)
	throw_speed_tuning = hud.get_throw_speed_tuning() if hud != null else config.duplicate(true)
	if battle_mgr != null:
		battle_mgr.set_throw_speed_tuning(throw_speed_tuning)
	_update_hud()


func automation_set_throw_spin_tuning(config: Dictionary) -> void:
	if hud != null:
		hud.set_throw_spin_tuning(config)
	throw_spin_tuning = hud.get_throw_spin_tuning() if hud != null else config.duplicate(true)
	if battle_mgr != null:
		battle_mgr.set_throw_spin_tuning(throw_spin_tuning)
	_update_hud()


func automation_set_exit_return_tuning(config: Dictionary) -> void:
	if hud != null:
		hud.set_exit_return_tuning(config)
	exit_return_tuning = _normalized_exit_return_tuning(hud.get_exit_return_tuning() if hud != null else config)
	if battle_mgr != null:
		battle_mgr.set_exit_return_tuning(_resolved_exit_return_tuning())
	_update_hud()


func automation_set_camera_tuning(config: Dictionary) -> void:
	_apply_camera_tuning(config)
	if hud != null:
		hud.set_camera_tuning(_camera_tuning())
	_update_hud()


func automation_set_projected_ui_board_visible(enabled: bool) -> void:
	if projected_ui_board != null:
		projected_ui_board.set_board_visible(enabled)
	if hud != null:
		hud.set_projected_ui_board_controls(
			projected_ui_board.is_board_visible() if projected_ui_board != null else enabled,
			projected_ui_board.is_flat_mode() if projected_ui_board != null else false
		)
	_update_hud()


func automation_set_projected_ui_board_flat(enabled: bool) -> void:
	if projected_ui_board != null:
		projected_ui_board.set_flat_mode(enabled)
	if hud != null:
		hud.set_projected_ui_board_controls(
			projected_ui_board.is_board_visible() if projected_ui_board != null else true,
			projected_ui_board.is_flat_mode() if projected_ui_board != null else enabled
		)
	_update_hud()


func automation_drop_random(count: int = 2) -> void:
	automation_set_dice_count(count)
	var targets: Array = []
	for _i in range(clampi(count, 1, 6)):
		targets.append(null)
	automation_set_targets(targets)
	if game_mgr != null:
		game_mgr.select_all_dice()
	_drop_with_current_settings(false)


func automation_roll_targets(values: Array) -> void:
	automation_set_dice_count(values.size())
	automation_set_targets(values)
	if game_mgr != null:
		game_mgr.select_all_dice()
	_drop_with_current_settings(true)


func automation_clear() -> void:
	_cancel_auto_roll_all()
	if scene_bridge != null:
		scene_bridge.notify_clear()
	if game_mgr != null:
		game_mgr.clear()
	_update_hud()


func automation_toggle_dice_edit_panel() -> bool:
	if hud == null or not hud.has_method("toggle_dice_edit_panel"):
		return false
	return bool(hud.call("toggle_dice_edit_panel"))


func automation_apply_crystal_dice_preset() -> void:
	if hud != null and hud.has_method("apply_crystal_dice_preset"):
		hud.call("apply_crystal_dice_preset")


func automation_request_dice_exit() -> void:
	_request_dice_exit_with_current_state()


func automation_request_dice_return() -> void:
	_request_dice_return_from_exit()


func automation_request_auto_roll_all(delay_seconds := 0.0) -> void:
	_request_auto_roll_all(delay_seconds)


func _drop_with_current_settings(use_targets: bool, from_auto_roll_all := false) -> void:
	if game_mgr == null:
		return
	if not from_auto_roll_all:
		_cancel_auto_roll_all()
	var targets := hud.get_targets() if hud != null else []
	if hud != null:
		idle_drift_tuning = hud.get_idle_drift_tuning()
		throw_speed_tuning = hud.get_throw_speed_tuning()
		throw_spin_tuning = hud.get_throw_spin_tuning()
		exit_return_tuning = _normalized_exit_return_tuning(hud.get_exit_return_tuning())
	if battle_mgr != null:
		battle_mgr.set_idle_drift_tuning(idle_drift_tuning)
		battle_mgr.set_throw_speed_tuning(throw_speed_tuning)
		battle_mgr.set_throw_spin_tuning(throw_spin_tuning)
		battle_mgr.set_exit_return_tuning(_resolved_exit_return_tuning())
		battle_mgr.set_unselected_hold_tuning(_resolved_unselected_hold_tuning())
	if scene_bridge != null:
		var selected_indices := game_mgr.get_selected_dice_indices()
		var payload: Dictionary = scene_bridge.make_roll_payload(use_targets, game_mgr.dice_count, targets, selected_indices)
		payload["idle_drift_tuning"] = idle_drift_tuning.duplicate()
		payload["throw_speed_tuning"] = throw_speed_tuning.duplicate()
		payload["throw_spin_tuning"] = throw_spin_tuning.duplicate()
		payload["exit_return_tuning"] = exit_return_tuning.duplicate()
		payload["auto_roll_all"] = from_auto_roll_all
		roll_requested.emit(payload)
	game_mgr.set_targets(targets)
	game_mgr.roll_current(use_targets)
	_update_hud()


func _build_screen_backdrop() -> void:
	var background := ColorRect.new()
	background.name = "GmSceneBackdrop"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.022, 0.040, 0.120)
	add_child(background)


func _build_bridge() -> void:
	scene_bridge = GmSceneBridgeScript.new()
	scene_bridge.name = "GmSceneBridge"
	add_child(scene_bridge)


func _build_dice_viewport() -> void:
	dice_viewport = GmDiceViewportScript.new()
	dice_viewport.name = "DiceViewport"
	add_child(dice_viewport)
	dice_viewport.build()
	dice_viewport.dice_clicked.connect(_on_dice_viewport_dice_clicked)
	dice_viewport.configure_camera(camera_fov, camera_position, camera_look_at)
	dice_viewport.configure_ready_row_height(dice_initial_height)
	dice_viewport.configure_key_light(key_light_pitch, key_light_yaw)


func _build_projected_ui_board() -> void:
	if dice_viewport == null or dice_viewport.dice_world == null:
		return
	projected_ui_board = GmProjectedUiBoardScript.new() as GmProjectedUiBoard
	projected_ui_board.name = "GmProjectedUiBoard"
	dice_viewport.dice_world.add_child(projected_ui_board)
	projected_ui_board.ensure_built()


func _build_hud() -> void:
	hud = GmDiceHudScript.new() as GmDiceHud
	hud.name = "GmDiceHud"
	add_child(hud)
	hud.build()
	hud.set_camera_tuning(_camera_tuning())
	hud.set_idle_drift_tuning(idle_drift_tuning)
	hud.set_throw_speed_tuning(throw_speed_tuning)
	hud.set_throw_spin_tuning(throw_spin_tuning)
	hud.set_exit_return_tuning(exit_return_tuning)
	hud.roll_requested.connect(_on_hud_roll_requested)
	hud.clear_requested.connect(_on_hud_clear_requested)
	hud.back_requested.connect(_on_hud_back_requested)
	hud.dice_exit_requested.connect(_on_hud_dice_exit_requested)
	hud.dice_return_requested.connect(_on_hud_dice_return_requested)
	hud.dice_count_changed.connect(_on_hud_dice_count_changed)
	hud.targets_changed.connect(_on_hud_targets_changed)
	hud.idle_drift_tuning_changed.connect(_on_hud_idle_drift_tuning_changed)
	hud.throw_speed_tuning_changed.connect(_on_hud_throw_speed_tuning_changed)
	hud.throw_spin_tuning_changed.connect(_on_hud_throw_spin_tuning_changed)
	hud.exit_return_tuning_changed.connect(_on_hud_exit_return_tuning_changed)
	hud.camera_tuning_changed.connect(_on_hud_camera_tuning_changed)
	hud.dice_replace_requested.connect(_on_hud_dice_replace_requested)
	hud.projected_ui_board_visibility_changed.connect(_on_hud_projected_ui_board_visibility_changed)
	hud.projected_ui_board_flat_mode_changed.connect(_on_hud_projected_ui_board_flat_mode_changed)
	hud.set_projected_ui_board_controls(
		projected_ui_board.is_board_visible() if projected_ui_board != null else true,
		projected_ui_board.is_flat_mode() if projected_ui_board != null else false
	)
	idle_drift_tuning = hud.get_idle_drift_tuning()
	throw_speed_tuning = hud.get_throw_speed_tuning()
	throw_spin_tuning = hud.get_throw_spin_tuning()
	exit_return_tuning = _normalized_exit_return_tuning(hud.get_exit_return_tuning())


func _build_managers() -> void:
	var managers := Node.new()
	managers.name = "Managers"
	add_child(managers)

	ready_mgr = GmReadyMgrScript.new() as GmReadyMgr
	ready_mgr.name = "ReadyMgr"
	managers.add_child(ready_mgr)
	ready_mgr.setup(dice_viewport.dice_box_anchors, dice_viewport.spawn_point, dice_viewport.dice_container)
	ready_mgr.fly_dice_pos = dice_viewport.dice_box_anchors.get_node("FlyPoint") as Marker3D
	ready_mgr.show_dice_pos = dice_viewport.dice_box_anchors.get_node("ShowPoint") as Marker3D
	ready_mgr.shop_dice_pos = dice_viewport.dice_box_anchors.get_node("ShopDicePoint") as Marker3D
	ready_mgr.shop_boss_pos = dice_viewport.dice_box_anchors.get_node("BossDicePoint") as Marker3D
	ready_mgr.dice_call_pos = dice_viewport.dice_box_anchors.get_node("DiceCallPoint") as Marker3D

	battle_mgr = GmBattleMgrScript.new() as GmBattleMgr
	battle_mgr.name = "BattleMgr"
	managers.add_child(battle_mgr)
	battle_mgr.setup(ready_mgr, dice_viewport.dice_container)
	battle_mgr.set_idle_drift_tuning(idle_drift_tuning)
	battle_mgr.set_throw_speed_tuning(throw_speed_tuning)
	battle_mgr.set_throw_spin_tuning(throw_spin_tuning)
	battle_mgr.set_exit_return_tuning(_resolved_exit_return_tuning())
	battle_mgr.set_unselected_hold_tuning(_resolved_unselected_hold_tuning())
	battle_mgr.score_updated.connect(_on_battle_snapshot_changed)
	battle_mgr.roll_started.connect(_on_battle_snapshot_changed)
	battle_mgr.roll_finished.connect(_on_battle_snapshot_changed)
	battle_mgr.resolution_requested.connect(_on_battle_resolution_requested)
	battle_mgr.dice_exit_requested.connect(_on_battle_dice_exit_requested)
	battle_mgr.dice_roster_changed.connect(_on_battle_snapshot_changed)

	game_mgr = GmGameMgrScript.new() as GmGameMgr
	game_mgr.name = "GameMgr"
	managers.add_child(game_mgr)
	game_mgr.setup(ready_mgr, battle_mgr, GmDiceDefinitionScript.create_standard_d6())
	game_mgr.state_changed.connect(_on_game_state_changed)

	dice_flow_module = GmDiceFlowModuleScript.new() as GmDiceFlowModule
	dice_flow_module.name = "DiceFlowModule"
	managers.add_child(dice_flow_module)
	dice_flow_module.setup(
		game_mgr,
		battle_mgr,
		Callable(self, "_roll_all_dice_without_targets_from_flow"),
		Callable(self, "_update_hud")
	)
	dice_flow_module.state_changed.connect(_on_dice_flow_state_changed)


func _on_hud_roll_requested(use_targets: bool) -> void:
	_drop_with_current_settings(use_targets)


func _on_dice_viewport_dice_clicked(dice) -> void:
	if _is_selection_input_locked():
		_update_hud()
		return
	if battle_mgr != null:
		battle_mgr.toggle_select_by_avatar(dice)
	_update_hud()


func _on_hud_clear_requested() -> void:
	automation_clear()


func _on_hud_back_requested() -> void:
	if scene_bridge != null:
		scene_bridge.notify_back()
	back_requested.emit()
	if back_callback.is_valid():
		back_callback.call()


func _on_hud_dice_exit_requested() -> void:
	_request_dice_exit_with_current_state()


func _on_hud_dice_return_requested() -> void:
	_request_dice_return_from_exit()


func _on_hud_dice_count_changed(count: int) -> void:
	if game_mgr != null:
		game_mgr.set_dice_count(count)
	_update_hud()


func _on_hud_targets_changed(values: Array) -> void:
	if game_mgr != null:
		game_mgr.set_targets(values)
	_update_hud()


func _on_hud_dice_replace_requested(material_id: StringName, face_pips: Array, apply_to_all: bool) -> void:
	if apply_to_all:
		automation_replace_all_dice(material_id, face_pips)
	else:
		automation_replace_selected_dice(material_id, face_pips)


func _on_hud_idle_drift_tuning_changed(config: Dictionary) -> void:
	idle_drift_tuning = config.duplicate()
	if battle_mgr != null:
		battle_mgr.set_idle_drift_tuning(idle_drift_tuning)


func _on_hud_throw_speed_tuning_changed(config: Dictionary) -> void:
	throw_speed_tuning = config.duplicate()
	if battle_mgr != null:
		battle_mgr.set_throw_speed_tuning(throw_speed_tuning)


func _on_hud_throw_spin_tuning_changed(config: Dictionary) -> void:
	throw_spin_tuning = config.duplicate()
	if battle_mgr != null:
		battle_mgr.set_throw_spin_tuning(throw_spin_tuning)


func _on_hud_exit_return_tuning_changed(config: Dictionary) -> void:
	exit_return_tuning = _normalized_exit_return_tuning(config)
	if battle_mgr != null:
		battle_mgr.set_exit_return_tuning(_resolved_exit_return_tuning())
		battle_mgr.set_unselected_hold_tuning(_resolved_unselected_hold_tuning())


func _on_hud_camera_tuning_changed(config: Dictionary) -> void:
	_apply_camera_tuning(config)


func _on_hud_projected_ui_board_visibility_changed(enabled: bool) -> void:
	automation_set_projected_ui_board_visible(enabled)


func _on_hud_projected_ui_board_flat_mode_changed(enabled: bool) -> void:
	automation_set_projected_ui_board_flat(enabled)


func _on_battle_snapshot_changed(_snapshot: Dictionary) -> void:
	_update_hud()


func _on_battle_resolution_requested(payload: Dictionary) -> void:
	if scene_bridge != null and scene_bridge.has_method("notify_resolution_requested"):
		scene_bridge.call("notify_resolution_requested", payload)
	resolution_requested.emit(payload.duplicate(true))
	_update_hud()


func _on_battle_dice_exit_requested(payload: Dictionary) -> void:
	if scene_bridge != null and scene_bridge.has_method("notify_dice_exit_requested"):
		scene_bridge.call("notify_dice_exit_requested", payload)
	dice_exit_requested.emit(payload.duplicate(true))
	_update_hud()


func _request_dice_exit_with_current_state() -> void:
	if battle_mgr != null and battle_mgr.has_method("request_dice_exit_from_current_state"):
		battle_mgr.call("request_dice_exit_from_current_state")
	_update_hud()


func _request_dice_return_from_exit() -> void:
	if battle_mgr != null and battle_mgr.has_method("request_dice_return_from_exit"):
		battle_mgr.call("request_dice_return_from_exit")
	_update_hud()


func _request_auto_roll_all(delay_seconds := AUTO_ROLL_ALL_AFTER_EXIT_RETURN_DELAY) -> void:
	if dice_flow_module != null:
		dice_flow_module.request_auto_roll_all(delay_seconds)
		_sync_dice_flow_fields(dice_flow_module.get_snapshot_fields())


func _cancel_auto_roll_all() -> void:
	if dice_flow_module != null:
		dice_flow_module.cancel()
		_sync_dice_flow_fields(dice_flow_module.get_snapshot_fields())


func _roll_all_dice_without_targets_from_flow() -> void:
	_drop_with_current_settings(false, true)


func _is_auto_roll_all_input_locked() -> bool:
	return dice_flow_module.is_selection_input_locked() if dice_flow_module != null else auto_roll_all_active


func _is_selection_input_locked() -> bool:
	return _is_auto_roll_all_input_locked()


func _on_dice_flow_state_changed(snapshot: Dictionary) -> void:
	_sync_dice_flow_fields(snapshot)


func _dice_flow_snapshot_fields() -> Dictionary:
	var fields := dice_flow_module.get_snapshot_fields() if dice_flow_module != null else {
		"auto_roll_all_pending": auto_roll_all_pending,
		"auto_roll_all_active": auto_roll_all_active,
		"auto_roll_all_input_locked": _is_auto_roll_all_input_locked(),
		"auto_roll_all_request_count": auto_roll_all_request_count,
		"auto_roll_all_last_delay_seconds": auto_roll_all_last_delay_seconds,
	}
	_sync_dice_flow_fields(fields)
	return fields


func _sync_dice_flow_fields(snapshot: Dictionary) -> void:
	auto_roll_all_pending = bool(snapshot.get("auto_roll_all_pending", auto_roll_all_pending))
	auto_roll_all_active = bool(snapshot.get("auto_roll_all_active", auto_roll_all_active))
	auto_roll_all_request_count = int(snapshot.get("auto_roll_all_request_count", auto_roll_all_request_count))
	auto_roll_all_last_delay_seconds = float(snapshot.get("auto_roll_all_last_delay_seconds", auto_roll_all_last_delay_seconds))


func _on_game_state_changed(_state_id: StringName, _snapshot: Dictionary) -> void:
	_update_hud()


func _update_hud() -> void:
	if hud != null:
		hud.update_state(automation_get_snapshot())


func _clear_runtime_nodes() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _camera_tuning() -> Dictionary:
	return {
		"fov": camera_fov,
		"position_y": camera_position.y,
		"position_z": camera_position.z,
		"look_at_y": camera_look_at.y,
		"look_at_z": camera_look_at.z,
		"dice_initial_height": dice_initial_height,
		"key_light_pitch": key_light_pitch,
		"key_light_yaw": key_light_yaw,
	}


func _apply_camera_tuning(config: Dictionary) -> void:
	camera_fov = clampf(float(config.get("fov", camera_fov)), 20.0, 70.0)
	camera_position.y = clampf(float(config.get("position_y", camera_position.y)), 4.0, 30.0)
	camera_position.z = clampf(float(config.get("position_z", camera_position.z)), -1.0, 9.0)
	camera_look_at.y = clampf(float(config.get("look_at_y", camera_look_at.y)), -1.0, 3.0)
	camera_look_at.z = clampf(float(config.get("look_at_z", camera_look_at.z)), -3.0, 3.0)
	dice_initial_height = clampf(float(config.get("dice_initial_height", dice_initial_height)), 0.8, 10.0)
	key_light_pitch = clampf(float(config.get("key_light_pitch", key_light_pitch)), -90.0, 0.0)
	key_light_yaw = clampf(float(config.get("key_light_yaw", key_light_yaw)), -180.0, 180.0)
	if dice_viewport != null and dice_viewport.has_method("configure_camera"):
		dice_viewport.call("configure_camera", camera_fov, camera_position, camera_look_at)
	if dice_viewport != null and dice_viewport.has_method("configure_ready_row_height"):
		dice_viewport.call("configure_ready_row_height", dice_initial_height)
	if dice_viewport != null and dice_viewport.has_method("configure_key_light"):
		dice_viewport.call("configure_key_light", key_light_pitch, key_light_yaw)
	if ready_mgr != null and ready_mgr.has_method("refresh_ready_positions"):
		ready_mgr.call("refresh_ready_positions")
	if battle_mgr != null:
		battle_mgr.set_exit_return_tuning(_resolved_exit_return_tuning())


func _make_panel_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	return style


func _normalized_exit_return_tuning(config: Dictionary) -> Dictionary:
	var screen_x := float(config.get("screen_x", exit_return_tuning.get("screen_x", 0.66)))
	if config.has("spawn_x"):
		screen_x = clampf(float(config["spawn_x"]) / 8.0, 0.0, 1.0)
	return {
		"screen_x": clampf(screen_x, 0.0, 1.0),
		"screen_y": clampf(float(config.get("screen_y", exit_return_tuning.get("screen_y", 0.44))), 0.0, 1.0),
		"spawn_y": clampf(float(config.get("spawn_y", exit_return_tuning.get("spawn_y", 20.0))), 0.0, 30.0),
	}


func _resolved_exit_return_tuning() -> Dictionary:
	var config := _normalized_exit_return_tuning(exit_return_tuning)
	if dice_viewport != null and dice_viewport.has_method("screen_entry_to_world_position"):
		config["entry_world_position"] = dice_viewport.call(
			"screen_entry_to_world_position",
			float(config["screen_x"]),
			float(config["screen_y"]),
			float(config["spawn_y"]),
			dice_initial_height
		)
	return config


func _resolved_unselected_hold_tuning() -> Dictionary:
	var config := {
		"screen_x": clampf(float(unselected_hold_tuning.get("screen_x", 0.50)), 0.0, 1.0),
		"screen_y": clampf(float(unselected_hold_tuning.get("screen_y", 0.84)), 0.0, 1.0),
		"max_width": clampf(float(unselected_hold_tuning.get("max_width", 8.00)), 0.10, 8.0),
		"duration": clampf(float(unselected_hold_tuning.get("duration", 0.36)), 0.05, 2.0),
	}
	if dice_viewport != null and dice_viewport.has_method("screen_point_to_world_on_y"):
		config["center_world_position"] = dice_viewport.call(
			"screen_point_to_world_on_y",
			float(config["screen_x"]),
			float(config["screen_y"]),
			dice_initial_height
		)
	return config


func _camera_pitch_degrees() -> float:
	var direction := camera_look_at - camera_position
	var flat_distance := Vector2(direction.x, direction.z).length()
	return rad_to_deg(atan2(direction.y, flat_distance))
