extends Node
class_name GmReadyMgr


const GmDiceCtrlScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceCtrl.gd")
const GmDiceInstanceScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceInstance.gd")

const READY_ROW_SPACING_X := 1.06
const READY_ROW_FALLBACK_POSITION := Vector3(0.0, 7.5, 0.08)
const READY_ROW_YAW_DEGREES := 0.0
const LAUNCH_ROW_SPACING_X := 0.42
const LAUNCH_ROW_STAGGER_Z := 0.18


@export var box_trans: Node3D = null
@export var box_dice_pos: Marker3D = null
@export var fly_dice_pos: Marker3D = null
@export var show_dice_pos: Marker3D = null
@export var shop_dice_pos: Marker3D = null
@export var shop_boss_pos: Marker3D = null
@export var dice_call_pos: Marker3D = null
@export var dice_container: Node3D = null

var dice_cfgs: Array = []
var hot_cfgs: Array = []
var record := {}


func setup(p_box_trans: Node3D, p_box_dice_pos: Marker3D, p_dice_container: Node3D) -> void:
	box_trans = p_box_trans
	box_dice_pos = p_box_dice_pos
	dice_container = p_dice_container


func create_initial_dices(count: int, definition: GmDiceDefinition) -> Array:
	dice_cfgs.clear()
	for _i in range(clampi(count, 1, 6)):
		dice_cfgs.append(GmDiceInstanceScript.from_definition(definition))
	return dice_cfgs.duplicate()


func spawn_dice_avatar(instance: GmDiceInstance, index: int, count: int) -> GmDiceCtrl:
	if dice_container == null or instance == null:
		return null
	var avatar := GmDiceCtrlScript.new() as GmDiceCtrl
	avatar.name = "GmDiceCtrl%d" % [index + 1]
	avatar.build_visuals(_body_color(index), Color(0.12, 0.15, 0.19))
	dice_container.add_child(avatar)
	avatar.global_position = _spawn_position(index, count)
	avatar.rotation_degrees = Vector3(0.0, READY_ROW_YAW_DEGREES, 0.0)
	avatar.init_dice(instance)
	avatar.set_ready_hover(_spawn_position(index, count), READY_ROW_YAW_DEGREES)
	return avatar


func clear_avatars() -> void:
	if dice_container == null:
		return
	for child in dice_container.get_children():
		dice_container.remove_child(child)
		child.queue_free()


func refresh_ready_positions() -> void:
	if dice_container == null:
		return
	var avatars := dice_container.get_children()
	var count := avatars.size()
	for index in range(count):
		var avatar := avatars[index] as GmDiceCtrl
		if avatar == null or avatar.is_rolling:
			continue
		avatar.set_ready_hover(_spawn_position(index, count), READY_ROW_YAW_DEGREES)


func add_record(record_type: String, add_val: int) -> void:
	record[record_type] = int(record.get(record_type, 0)) + add_val


func get_record_snapshot() -> Dictionary:
	return record.duplicate(true)


func get_spawn_position(index: int, count: int) -> Vector3:
	return _spawn_position(index, count)


func get_launch_position(index: int, count: int) -> Vector3:
	var base := fly_dice_pos.global_position if fly_dice_pos != null else Vector3(0.0, 1.15, 3.05)
	var lane := float(index) - (float(maxi(1, count)) - 1.0) * 0.5
	var row := 1.0 if index % 2 == 0 else -1.0
	return base + Vector3(
		lane * LAUNCH_ROW_SPACING_X,
		float(index) * 0.045,
		row * LAUNCH_ROW_STAGGER_Z
	)


func _spawn_position(index: int, count: int) -> Vector3:
	var base := show_dice_pos.global_position if show_dice_pos != null else (
		box_dice_pos.global_position if box_dice_pos != null else READY_ROW_FALLBACK_POSITION
	)
	var lane := float(index) - (float(maxi(1, count)) - 1.0) * 0.5
	return base + Vector3(lane * READY_ROW_SPACING_X, 0.0, 0.0)


func _body_color(index: int) -> Color:
	var palette := [
		Color(0.40, 0.78, 1.00),
		Color(0.64, 0.52, 1.00),
		Color(0.18, 0.86, 0.72),
		Color(1.00, 0.46, 0.70),
		Color(0.96, 0.82, 0.32),
		Color(0.84, 0.92, 1.00),
	]
	return palette[index % palette.size()]
