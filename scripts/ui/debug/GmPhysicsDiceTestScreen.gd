extends Control
class_name GmPhysicsDiceTestScreen


const GmDiceDefinitionScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")
const GmDiceHudScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceHud.gd")
const GmDiceViewportScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceViewport.gd")
const GmReadyMgrScript = preload("res://scripts/ui/debug/gm_dice_port/GmReadyMgr.gd")
const GmBattleMgrScript = preload("res://scripts/ui/debug/gm_dice_port/GmBattleMgr.gd")
const GmGameMgrScript = preload("res://scripts/ui/debug/gm_dice_port/GmGameMgr.gd")
const GmSceneBridgeScript = preload("res://scripts/ui/debug/gm_dice_port/GmSceneBridge.gd")


signal back_requested
signal roll_requested(payload: Dictionary)
signal snapshot_changed(snapshot: Dictionary)


const DEFAULT_TARGET_SCORE := 100


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
var dice_viewport: SubViewportContainer = null
var ready_mgr: GmReadyMgr = null
var battle_mgr: GmBattleMgr = null
var game_mgr: GmGameMgr = null
var hud: GmDiceHud = null
var target_score := DEFAULT_TARGET_SCORE
var throw_tuning := {
	"forward_speed": 10.0,
	"lateral_speed": 5.0,
	"upward_speed": 3.2,
	"angular_speed": 28.0,
	"torque_impulse": 24.0,
}


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
	_build_hud()
	_build_managers()
	game_mgr.boot(4)
	_update_hud()


func _physics_process(_delta: float) -> void:
	if hud != null and game_mgr != null:
		hud.update_state(automation_get_snapshot())


func automation_get_snapshot() -> Dictionary:
	var snapshot := game_mgr.get_snapshot() if game_mgr != null else {}
	snapshot["throw_tuning"] = throw_tuning.duplicate()
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
	if config.has("throw_tuning") and config["throw_tuning"] is Dictionary:
		automation_set_throw_tuning(config["throw_tuning"] as Dictionary)
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


func automation_set_throw_tuning(config: Dictionary) -> void:
	if hud != null:
		hud.set_throw_tuning(config)
	throw_tuning = hud.get_throw_tuning() if hud != null else config.duplicate(true)
	if battle_mgr != null:
		battle_mgr.set_throw_tuning(throw_tuning)
	_update_hud()


func automation_set_camera_tuning(config: Dictionary) -> void:
	_apply_camera_tuning(config)
	if hud != null:
		hud.set_camera_tuning(_camera_tuning())
	_update_hud()


func automation_drop_random(count: int = 2) -> void:
	automation_set_dice_count(count)
	var targets: Array = []
	for _i in range(clampi(count, 1, 6)):
		targets.append(null)
	automation_set_targets(targets)
	_drop_with_current_settings(false)


func automation_roll_targets(values: Array) -> void:
	automation_set_dice_count(values.size())
	automation_set_targets(values)
	_drop_with_current_settings(true)


func automation_clear() -> void:
	if scene_bridge != null:
		scene_bridge.notify_clear()
	if game_mgr != null:
		game_mgr.clear()
	_update_hud()


func _drop_with_current_settings(use_targets: bool) -> void:
	if game_mgr == null:
		return
	var targets := hud.get_targets() if hud != null else []
	if hud != null:
		throw_tuning = hud.get_throw_tuning()
	if battle_mgr != null:
		battle_mgr.set_throw_tuning(throw_tuning)
	if scene_bridge != null:
		var payload: Dictionary = scene_bridge.make_roll_payload(use_targets, game_mgr.dice_count, targets)
		payload["throw_tuning"] = throw_tuning.duplicate()
		roll_requested.emit(payload)
	game_mgr.set_targets(targets)
	game_mgr.roll_current(use_targets)
	_update_hud()


func _build_screen_backdrop() -> void:
	var background := ColorRect.new()
	background.name = "GmSceneBackdrop"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.12, 0.08, 0.20)
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
	dice_viewport.configure_camera(camera_fov, camera_position, camera_look_at)
	dice_viewport.configure_ready_row_height(dice_initial_height)
	dice_viewport.configure_key_light(key_light_pitch, key_light_yaw)


func _build_hud() -> void:
	hud = GmDiceHudScript.new() as GmDiceHud
	hud.name = "GmDiceHud"
	add_child(hud)
	hud.build()
	hud.set_camera_tuning(_camera_tuning())
	hud.roll_requested.connect(_on_hud_roll_requested)
	hud.clear_requested.connect(_on_hud_clear_requested)
	hud.back_requested.connect(_on_hud_back_requested)
	hud.dice_count_changed.connect(_on_hud_dice_count_changed)
	hud.targets_changed.connect(_on_hud_targets_changed)
	hud.throw_tuning_changed.connect(_on_hud_throw_tuning_changed)
	hud.camera_tuning_changed.connect(_on_hud_camera_tuning_changed)
	throw_tuning = hud.get_throw_tuning()


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
	battle_mgr.set_throw_tuning(throw_tuning)
	battle_mgr.score_updated.connect(_on_battle_snapshot_changed)
	battle_mgr.roll_started.connect(_on_battle_snapshot_changed)
	battle_mgr.roll_finished.connect(_on_battle_snapshot_changed)
	battle_mgr.dice_roster_changed.connect(_on_battle_snapshot_changed)

	game_mgr = GmGameMgrScript.new() as GmGameMgr
	game_mgr.name = "GameMgr"
	managers.add_child(game_mgr)
	game_mgr.setup(ready_mgr, battle_mgr, GmDiceDefinitionScript.create_standard_d6())
	game_mgr.state_changed.connect(_on_game_state_changed)


func _on_hud_roll_requested(use_targets: bool) -> void:
	_drop_with_current_settings(use_targets)


func _on_hud_clear_requested() -> void:
	automation_clear()


func _on_hud_back_requested() -> void:
	if scene_bridge != null:
		scene_bridge.notify_back()
	back_requested.emit()
	if back_callback.is_valid():
		back_callback.call()


func _on_hud_dice_count_changed(count: int) -> void:
	if game_mgr != null:
		game_mgr.set_dice_count(count)
	_update_hud()


func _on_hud_targets_changed(values: Array) -> void:
	if game_mgr != null:
		game_mgr.set_targets(values)
	_update_hud()


func _on_hud_throw_tuning_changed(config: Dictionary) -> void:
	throw_tuning = config.duplicate()
	if battle_mgr != null:
		battle_mgr.set_throw_tuning(throw_tuning)


func _on_hud_camera_tuning_changed(config: Dictionary) -> void:
	_apply_camera_tuning(config)


func _on_battle_snapshot_changed(_snapshot: Dictionary) -> void:
	_update_hud()


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


func _camera_pitch_degrees() -> float:
	var direction := camera_look_at - camera_position
	var flat_distance := Vector2(direction.x, direction.z).length()
	return rad_to_deg(atan2(direction.y, flat_distance))
