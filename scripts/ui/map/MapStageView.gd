extends Control
class_name MapStageView

signal interaction_lock_changed(locked: bool)


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const MapStageArtConfig = preload("res://scripts/ui/map/resources/MapStageArtConfig.gd")
const MapMovementDicePhysicsView = preload("res://scripts/ui/map/components/MapMovementDicePhysicsView.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleIconLibrary = preload("res://scripts/ui/battle/resources/BattleIconLibrary.gd")
const DiceVisualLibrary = preload("res://scripts/ui/battle/resources/DiceVisualLibrary.gd")
const DEFAULT_ART_CONFIG = preload("res://scenes/map/resources/MapStageArtConfig.tres")


@export var art_config: MapStageArtConfig = DEFAULT_ART_CONFIG
@export var movement_dice_view_scene: PackedScene = preload("res://scenes/battle/components/DiceView.tscn")
@export var movement_magic_fx_scene: PackedScene = preload("res://scenes/battle/components/RerollMagicFx.tscn")
@export var battle_style_config: BattleUiStyleConfig = preload("res://scenes/battle/resources/BattleUiStyleConfig.tres")
@export var battle_icon_library: BattleIconLibrary = preload("res://scenes/battle/resources/BattleIconLibrary.tres")
@export var battle_dice_visual_library: DiceVisualLibrary = preload("res://scenes/battle/resources/DiceVisualLibrary.tres")


var game_flow_controller: GameFlowController = null
var map_state: Dictionary = {}
var board_root: Control = null
var backdrop_texture: TextureRect = null
var board_texture: TextureRect = null
var path_layer: Control = null
var node_layer: Control = null
var map_fx_layer: Control = null
var center_root: Control = null
var circle_action_badge: PanelContainer = null
var circle_action_label: Label = null
var title_label: Label = null
var current_node_label: Label = null
var next_node_label: Label = null
var move_dice_label: Label = null
var movement_dice_row: HBoxContainer = null
var movement_dice_physics_view: MapMovementDicePhysicsView = null
var roll_result_label: Label = null
var node_type_label: Label = null
var danger_label: Label = null
var roll_button_wrapper: Control = null
var roll_button: TextureButton = null
var enter_battle_button_wrapper: Control = null
var enter_battle_button: TextureButton = null
var player_marker: TextureRect = null
var movement_step_label: Label = null
var node_views: Array[Control] = []
var movement_dice_views: Array[Control] = []
var movement_dice: Array = []
var selected_movement_dice_indices: Array[int] = [0, 1]
var is_marker_animating: bool = false
var is_board_animating: bool = false
var is_movement_roll_pending: bool = false
var last_emitted_interaction_locked: bool = false


func setup(new_game_flow_controller: GameFlowController, initial_map_state: Dictionary = {}) -> void:
	game_flow_controller = new_game_flow_controller
	if not initial_map_state.is_empty():
		map_state = initial_map_state.duplicate(true)
	_connect_flow_signals()
	if is_node_ready():
		_render_state()


func _ready() -> void:
	_ensure_art_config()
	_build_view()
	_connect_flow_signals()
	_render_state()
	call_deferred("_layout_route_nodes")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_route_nodes()
		_layout_center_panel()
		if not is_marker_animating:
			_place_player_marker(_current_index())


func play_raise() -> void:
	if not is_node_ready():
		await ready
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	is_board_animating = true
	_refresh_interaction_lock_state()
	board_root.position = _lowered_board_position()
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(board_root, "position", Vector2.ZERO, art_config.board_raise_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, art_config.board_raise_duration * 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	board_root.position = Vector2.ZERO
	modulate.a = 1.0
	is_board_animating = false
	_refresh_interaction_lock_state()


func play_lower() -> void:
	if not is_node_ready():
		await ready
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	is_board_animating = true
	_refresh_interaction_lock_state()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(board_root, "position", _lowered_board_position(), art_config.board_lower_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, art_config.board_lower_duration * 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_board_animating = false
	_refresh_interaction_lock_state()


func automation_get_snapshot() -> Dictionary:
	return {
		"current_index": _current_index(),
		"current_node_type": str(_current_node_type()),
		"last_roll": int(map_state.get("last_roll", 0)),
		"last_rolls": map_state.get("last_rolls", []).duplicate(),
		"last_rolled_dice_indices": map_state.get("last_rolled_dice_indices", []).duplicate(),
		"selected_movement_dice_indices": selected_movement_dice_indices.duplicate(),
		"pending_battle": bool(map_state.get("pending_battle", false)),
		"circle": int(map_state.get("circle", 1)),
		"circle_base_score": int(map_state.get("circle_base_score", 0)),
		"circle_action_count": int(map_state.get("circle_action_count", 0)),
		"danger_bonus_percent": int(map_state.get("danger_bonus_percent", 0)),
		"current_node_target_score": int(map_state.get("current_node_target_score", 0)),
		"movement_dice_count": int(map_state.get("movement_dice_count", 2)),
		"node_count": _nodes().size(),
		"has_movement_magic_fx": movement_magic_fx_scene != null,
		"has_movement_physics_dice": movement_dice_physics_view != null,
		"movement_physics_dice": movement_dice_physics_view.automation_get_snapshot() if movement_dice_physics_view != null else {},
		"is_board_animating": is_board_animating,
		"is_movement_roll_pending": is_movement_roll_pending,
		"interaction_locked": _is_interaction_locked(),
		"board_raise_duration": art_config.board_raise_duration if art_config != null else 0.0,
		"board_lower_duration": art_config.board_lower_duration if art_config != null else 0.0,
		"roll_button_disabled": roll_button.disabled if roll_button != null else false,
		"enter_battle_button_disabled": enter_battle_button.disabled if enter_battle_button != null else false,
		"marker_step_duration": art_config.marker_step_duration if art_config != null else 0.0,
		"movement_step_label_visible": movement_step_label.visible if movement_step_label != null else false,
		"circle_action_label_text": circle_action_label.text if circle_action_label != null else "",
		"visible": visible,
	}


func _ensure_art_config() -> void:
	if art_config == null:
		art_config = DEFAULT_ART_CONFIG


func _connect_flow_signals() -> void:
	if game_flow_controller == null:
		return
	if game_flow_controller.has_signal("map_state_changed") and not game_flow_controller.map_state_changed.is_connected(_on_map_state_changed):
		game_flow_controller.map_state_changed.connect(_on_map_state_changed)


func _build_view() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	board_root = Control.new()
	board_root.name = "MapBoardRoot"
	board_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(board_root)

	backdrop_texture = TextureRect.new()
	backdrop_texture.name = "MapBackdropTexture"
	backdrop_texture.texture = art_config.backdrop_texture
	backdrop_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop_texture.stretch_mode = TextureRect.STRETCH_SCALE
	backdrop_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop_texture.offset_left = art_config.board_margin
	backdrop_texture.offset_top = art_config.board_margin
	backdrop_texture.offset_right = -art_config.board_margin
	backdrop_texture.offset_bottom = -art_config.board_margin
	backdrop_texture.visible = false
	board_root.add_child(backdrop_texture)

	board_texture = TextureRect.new()
	board_texture.name = "MapBoardTexture"
	board_texture.texture = art_config.board_texture
	board_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board_texture.stretch_mode = TextureRect.STRETCH_SCALE
	board_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_texture.offset_left = art_config.board_margin
	board_texture.offset_top = art_config.board_margin
	board_texture.offset_right = -art_config.board_margin
	board_texture.offset_bottom = -art_config.board_margin
	board_texture.visible = board_texture.texture != null
	board_root.add_child(board_texture)

	movement_dice_physics_view = MapMovementDicePhysicsView.new()
	movement_dice_physics_view.name = "MapStagePerspective3DView"
	movement_dice_physics_view.z_index = 30
	movement_dice_physics_view.mouse_filter = Control.MOUSE_FILTER_PASS
	board_root.add_child(movement_dice_physics_view)
	movement_dice_physics_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	movement_dice_physics_view.offset_left = art_config.board_margin
	movement_dice_physics_view.offset_top = art_config.board_margin
	movement_dice_physics_view.offset_right = -art_config.board_margin
	movement_dice_physics_view.offset_bottom = -art_config.board_margin
	movement_dice_physics_view.die_pressed.connect(_on_movement_die_pressed)

	path_layer = Control.new()
	path_layer.name = "PathFloorLayer"
	path_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	path_layer.visible = true
	path_layer.z_index = 5
	path_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_root.add_child(path_layer)

	node_layer = Control.new()
	node_layer.name = "MapNodeLayer"
	node_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node_layer.visible = true
	node_layer.z_index = 10
	node_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_root.add_child(node_layer)

	player_marker = TextureRect.new()
	player_marker.name = "PlayerMarker"
	player_marker.texture = art_config.player_marker_texture
	player_marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_marker.stretch_mode = TextureRect.STRETCH_SCALE
	player_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_marker.visible = false
	player_marker.z_index = 20
	board_root.add_child(player_marker)

	_build_circle_action_badge()

	movement_step_label = _make_label("", art_config.movement_step_font_size, art_config.accent_text_color, HORIZONTAL_ALIGNMENT_CENTER)
	movement_step_label.name = "MovementStepLabel"
	movement_step_label.visible = false
	movement_step_label.custom_minimum_size = Vector2(96.0, 42.0)
	movement_step_label.size = movement_step_label.custom_minimum_size
	movement_step_label.z_index = 26
	board_root.add_child(movement_step_label)

	_build_center_panel()

	map_fx_layer = Control.new()
	map_fx_layer.name = "MovementRollFxLayer"
	map_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_fx_layer.z_index = 360
	map_fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board_root.add_child(map_fx_layer)


func _build_center_panel() -> void:
	center_root = Control.new()
	center_root.name = "MapCenterRollArea"
	center_root.z_index = 80
	board_root.add_child(center_root)

	var center_texture := TextureRect.new()
	center_texture.name = "MoveDicePanelTexture"
	center_texture.texture = art_config.center_panel_texture
	center_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	center_texture.stretch_mode = TextureRect.STRETCH_SCALE
	center_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_texture.visible = false
	center_root.add_child(center_texture)

	var margin := MarginContainer.new()
	margin.name = "CenterContentMargin"
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center_root.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "CenterContent"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(content)

	title_label = _make_label("地图阶段", art_config.title_font_size, art_config.accent_text_color, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.name = "MapStageTitle"
	content.add_child(title_label)

	current_node_label = _make_label("当前位置：起点", art_config.body_font_size, art_config.text_color, HORIZONTAL_ALIGNMENT_CENTER)
	current_node_label.name = "CurrentNodeLabel"
	content.add_child(current_node_label)

	next_node_label = _make_label("即将前往：等待投掷", art_config.body_font_size, art_config.muted_text_color, HORIZONTAL_ALIGNMENT_CENTER)
	next_node_label.name = "NextNodeLabel"
	content.add_child(next_node_label)

	move_dice_label = _make_label("前进骰：两颗普通六面骰", art_config.body_font_size, art_config.text_color, HORIZONTAL_ALIGNMENT_CENTER)
	move_dice_label.name = "MoveDiceLabel"
	content.add_child(move_dice_label)

	movement_dice_row = HBoxContainer.new()
	movement_dice_row.name = "MovementDiceRow"
	movement_dice_row.alignment = BoxContainer.ALIGNMENT_CENTER
	movement_dice_row.add_theme_constant_override("separation", 16)
	movement_dice_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(movement_dice_row)
	_ensure_movement_dice_views()

	roll_result_label = _make_label("本次结果：尚未投掷", art_config.body_font_size, art_config.accent_text_color, HORIZONTAL_ALIGNMENT_CENTER)
	roll_result_label.name = "RollResultLabel"
	content.add_child(roll_result_label)

	node_type_label = _make_label("节点类型：起点", art_config.body_font_size, art_config.text_color, HORIZONTAL_ALIGNMENT_CENTER)
	node_type_label.name = "NodeTypeLabel"
	content.add_child(node_type_label)

	danger_label = _make_label("本圈行动：0 次｜本圈基础分：0｜危急值：+0%", art_config.body_font_size, art_config.accent_text_color, HORIZONTAL_ALIGNMENT_CENTER)
	danger_label.name = "DangerLabel"
	content.add_child(danger_label)

	roll_button_wrapper = _make_texture_button("投掷前进骰子")
	roll_button_wrapper.name = "RollMovementButton"
	roll_button = roll_button_wrapper.get_node("ButtonTexture") as TextureButton
	roll_button.pressed.connect(_on_roll_pressed)
	content.add_child(roll_button_wrapper)

	enter_battle_button_wrapper = _make_texture_button("进入战斗")
	enter_battle_button_wrapper.name = "EnterBattleButton"
	enter_battle_button = enter_battle_button_wrapper.get_node("ButtonTexture") as TextureButton
	enter_battle_button.pressed.connect(_on_enter_battle_pressed)
	content.add_child(enter_battle_button_wrapper)

	_layout_center_panel()


func _build_circle_action_badge() -> void:
	circle_action_badge = PanelContainer.new()
	circle_action_badge.name = "CircleActionBadge"
	circle_action_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	circle_action_badge.z_index = 34
	circle_action_badge.add_theme_stylebox_override("panel", _make_circle_action_badge_style())
	board_root.add_child(circle_action_badge)

	var margin := MarginContainer.new()
	margin.name = "CircleActionBadgeMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 6)
	circle_action_badge.add_child(margin)

	circle_action_label = _make_label("", max(18, art_config.body_font_size - 2), art_config.accent_text_color, HORIZONTAL_ALIGNMENT_CENTER)
	circle_action_label.name = "CircleActionLabel"
	circle_action_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	circle_action_label.clip_text = false
	margin.add_child(circle_action_label)


func _make_circle_action_badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.10, 0.08, 0.86)
	style.border_color = Color(0.92, 0.70, 0.28, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.36)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 3.0)
	return style


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", art_config.shadow_color)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_texture_button(text: String) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(310.0, 72.0)
	wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var button := TextureButton.new()
	button.name = "ButtonTexture"
	button.texture_normal = art_config.button_normal_texture
	button.texture_hover = art_config.button_hover_texture
	button.texture_pressed = art_config.button_pressed_texture
	button.texture_disabled = art_config.resolved_disabled_button_texture()
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(button)

	var label := _make_label(text, art_config.button_font_size, art_config.text_color, HORIZONTAL_ALIGNMENT_CENTER)
	label.name = "ButtonLabel"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(label)
	return wrapper


func _make_node_label_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = art_config.node_label_background_color
	style.border_color = art_config.node_label_border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 4
	style.content_margin_right = 4
	return style


func _make_node_label() -> Label:
	var label := _make_label("", art_config.node_font_size, art_config.node_label_text_color, HORIZONTAL_ALIGNMENT_CENTER)
	label.clip_text = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	return label


func _ensure_movement_dice_views() -> void:
	if movement_dice_row == null or movement_dice_physics_view == null:
		return
	while movement_dice.size() < 2:
		movement_dice.append(DieState.create_normal_d6(StringName("map_move_d6_%d" % [movement_dice.size() + 1])))

	movement_dice_views.clear()
	for index in range(2):
		var button := movement_dice_physics_view.get_die_button(index)
		if button != null:
			movement_dice_views.append(button)


func _render_movement_dice() -> void:
	if movement_dice_row == null:
		return
	_ensure_movement_dice_views()
	var rolls := _movement_rolls_for_render()
	if movement_dice_physics_view != null:
		movement_dice_physics_view.set_display_state(rolls, selected_movement_dice_indices, is_board_animating)


func _movement_rolls_for_render() -> Array[int]:
	var raw_rolls: Array = map_state.get("last_rolls", [])
	var result: Array[int] = []
	for index in range(2):
		if index < raw_rolls.size():
			var pip := int(raw_rolls[index])
			result.append(clampi(pip, 1, 6) if pip > 0 else 1)
		else:
			result.append(1)
	return result


func _rolled_dice_indices_for_state() -> Array[int]:
	var raw_indices: Array = map_state.get("last_rolled_dice_indices", [])
	var result: Array[int] = []
	for raw_index in raw_indices:
		var index := int(raw_index)
		if index < 0 or index >= 2:
			continue
		if result.has(index):
			continue
		result.append(index)
	if not result.is_empty():
		result.sort()
		return result

	var raw_rolls: Array = map_state.get("last_rolls", [])
	for index in range(min(2, raw_rolls.size())):
		if int(raw_rolls[index]) > 0:
			result.append(index)
	result.sort()
	return result


func _roll_result_text() -> String:
	if is_movement_roll_pending:
		return "本次结果：投掷中..."

	var last_roll := int(map_state.get("last_roll", 0))
	if last_roll <= 0:
		return "本次结果：尚未投掷"

	var raw_rolls: Array = map_state.get("last_rolls", [])
	var rolled_indices := _rolled_dice_indices_for_state()
	var formula := ""
	for die_index in rolled_indices:
		if die_index < 0 or die_index >= raw_rolls.size():
			continue
		var pip := int(raw_rolls[die_index])
		if pip <= 0:
			continue
		if formula != "":
			formula += " + "
		formula += str(pip)
	if formula == "":
		formula = str(last_roll)
	return "本次结果：%s = %d 步" % [formula, last_roll]


func _on_movement_die_pressed(index: int) -> void:
	if is_marker_animating or is_board_animating:
		return
	if index < 0 or index >= 2:
		return
	if selected_movement_dice_indices.has(index):
		if selected_movement_dice_indices.size() <= 1:
			return
		selected_movement_dice_indices.erase(index)
	else:
		selected_movement_dice_indices.append(index)
		selected_movement_dice_indices.sort()
	_render_center_text()
	_render_movement_dice()


func _refresh_interaction_lock_state() -> void:
	if is_node_ready():
		_render_center_text()
	_emit_interaction_lock_if_changed()


func _is_interaction_locked() -> bool:
	return is_board_animating or is_marker_animating or is_movement_roll_pending


func _emit_interaction_lock_if_changed() -> void:
	var locked := _is_interaction_locked()
	if locked == last_emitted_interaction_locked:
		return
	last_emitted_interaction_locked = locked
	interaction_lock_changed.emit(locked)


func _rolled_face_for_pip(die, die_index: int, pip: int) -> RolledFace:
	var face_index := clampi(pip, 1, 6) - 1
	var rolled_face := RolledFace.new()
	rolled_face.set_roll(die_index, face_index, die.faces[face_index], die)
	return rolled_face


func _play_movement_dice_roll_feedback() -> void:
	_render_movement_dice()
	if movement_dice_views.is_empty():
		return
	var feedback_indices := _rolled_dice_indices_for_state()
	if feedback_indices.is_empty():
		feedback_indices = selected_movement_dice_indices.duplicate()
	var punch := create_tween()
	punch.set_parallel(true)
	for index in range(movement_dice_views.size()):
		if not feedback_indices.has(index):
			continue
		var view := movement_dice_views[index]
		view.pivot_offset = view.size * 0.5
		var direction := -1.0 if index % 2 == 0 else 1.0
		punch.tween_property(view, "scale", Vector2(1.14, 1.14), 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		punch.tween_property(view, "rotation", direction * 0.12, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await punch.finished

	var settle := create_tween()
	settle.set_parallel(true)
	for index in range(movement_dice_views.size()):
		if not feedback_indices.has(index):
			continue
		var view := movement_dice_views[index]
		settle.tween_property(view, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		settle.tween_property(view, "rotation", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await settle.finished


func _spawn_movement_magic_effects(die_indices: Array[int]) -> Array[Control]:
	var result: Array[Control] = []
	if map_fx_layer == null or movement_magic_fx_scene == null:
		return result

	for die_index in die_indices:
		if die_index < 0 or die_index >= movement_dice_views.size():
			continue
		var rect := _movement_die_magic_global_rect(die_index)
		if rect.size == Vector2.ZERO:
			continue
		var instance := movement_magic_fx_scene.instantiate()
		if not instance is Control:
			if instance != null:
				instance.queue_free()
			continue
		var effect := instance as Control
		map_fx_layer.add_child(effect)
		var local_rect := _global_rect_to_fx_layer_local(rect)
		if effect.has_method("play_at_local_rect"):
			effect.call("play_at_local_rect", local_rect, false)
		elif effect.has_method("play_at_rect"):
			effect.call("play_at_rect", rect, false)
		else:
			effect.position = local_rect.position
			effect.size = local_rect.size
		result.append(effect)
	return result


func _movement_die_magic_global_rect(die_index: int) -> Rect2:
	if die_index < 0 or die_index >= movement_dice_views.size():
		return Rect2()
	var view := movement_dice_views[die_index]
	if view == null:
		return Rect2()
	if view.has_method("get_magic_fx_global_rect"):
		var rect: Rect2 = view.call("get_magic_fx_global_rect")
		return rect
	return view.get_global_rect()


func _global_rect_to_fx_layer_local(global_rect: Rect2) -> Rect2:
	if map_fx_layer == null:
		return global_rect
	var inverse: Transform2D = map_fx_layer.get_global_transform_with_canvas().affine_inverse()
	var local_position: Vector2 = inverse * global_rect.position
	var local_end: Vector2 = inverse * (global_rect.position + global_rect.size)
	return Rect2(local_position, local_end - local_position)


func _begin_movement_magic_reveal_fade(effects: Array[Control], duration: float) -> void:
	for effect in effects:
		if is_instance_valid(effect) and effect.has_method("begin_reveal_fade"):
			effect.call("begin_reveal_fade", duration)


func _clear_movement_magic_effects(effects: Array[Control]) -> void:
	for effect in effects:
		if is_instance_valid(effect) and not effect.is_queued_for_deletion():
			effect.queue_free()


func _layout_center_panel() -> void:
	if center_root == null:
		return
	var board_size := _board_size()
	var panel_size := Vector2(
		minf(maxf(art_config.center_area_minimum_size.x, board_size.x * 0.38), maxf(320.0, board_size.x - art_config.route_margin * 3.0)),
		minf(maxf(art_config.center_area_minimum_size.y, board_size.y * 0.36), maxf(220.0, board_size.y - art_config.route_margin * 3.0))
	)
	center_root.size = panel_size
	center_root.position = (board_size - panel_size) * 0.5
	_layout_circle_action_badge(panel_size)


func _layout_circle_action_badge(panel_size: Vector2 = Vector2.ZERO) -> void:
	if circle_action_badge == null:
		return
	var board_size := _board_size()
	var reference_size := panel_size
	if reference_size == Vector2.ZERO and center_root != null:
		reference_size = center_root.size
	if reference_size == Vector2.ZERO:
		reference_size = Vector2(520.0, 260.0)
	var badge_size := Vector2(minf(maxf(380.0, reference_size.x * 0.92), 560.0), 44.0)
	circle_action_badge.size = badge_size
	var x := (board_size.x - badge_size.x) * 0.5
	var center_top := center_root.position.y if center_root != null else (board_size.y - reference_size.y) * 0.5
	var y := maxf(12.0, center_top - badge_size.y - 12.0)
	circle_action_badge.position = Vector2(x, y)


func _layout_route_nodes() -> void:
	if board_root == null:
		return
	var nodes := _nodes()
	_ensure_node_views(nodes.size())
	if nodes.is_empty():
		player_marker.visible = false
		return

	var positions := _route_positions(nodes.size())
	for index in range(nodes.size()):
		var node_view := node_views[index]
		node_view.visible = true
		node_view.size = art_config.path_tile_size
		node_view.position = positions[index] - art_config.path_tile_size * 0.5

		var path_texture := node_view.get_node("PathFloorTexture") as TextureRect
		path_texture.texture = art_config.path_floor_texture
		path_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		var node_texture := node_view.get_node("NodeTexture") as TextureRect
		node_texture.texture = art_config.node_texture_for_type(StringName(str(nodes[index].get("node_type", "event"))))
		node_texture.size = art_config.node_size
		node_texture.position = (art_config.path_tile_size - art_config.node_size) * 0.5

		var label := node_view.get_node("NodeLabel") as Label
		label.visible = art_config.show_node_text_labels
		label.text = _node_short_name(StringName(str(nodes[index].get("node_type", "event"))))
		label.position = art_config.node_label_offset
		label.size = art_config.node_label_size
		label.add_theme_font_size_override("font_size", art_config.node_font_size)
		label.add_theme_color_override("font_color", art_config.node_label_text_color)

		var label_background := node_view.get_node("NodeLabelBackground") as Panel
		label_background.visible = art_config.show_node_text_labels
		label_background.position = art_config.node_label_offset
		label_background.size = art_config.node_label_size

	for index in range(nodes.size(), node_views.size()):
		node_views[index].visible = false

	_render_node_states()
	if not is_marker_animating:
		_place_player_marker(_current_index())


func _ensure_node_views(count: int) -> void:
	while node_views.size() < count:
		var index := node_views.size()
		var node_view := Control.new()
		node_view.name = "MapNode_%02d" % [index]
		node_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node_layer.add_child(node_view)

		var path_texture := TextureRect.new()
		path_texture.name = "PathFloorTexture"
		path_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		path_texture.stretch_mode = TextureRect.STRETCH_SCALE
		path_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node_view.add_child(path_texture)

		var node_texture := TextureRect.new()
		node_texture.name = "NodeTexture"
		node_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		node_texture.stretch_mode = TextureRect.STRETCH_SCALE
		node_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node_texture.z_index = 2
		node_view.add_child(node_texture)

		var label_background := Panel.new()
		label_background.name = "NodeLabelBackground"
		label_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label_background.z_index = 3
		label_background.add_theme_stylebox_override("panel", _make_node_label_style())
		node_view.add_child(label_background)

		var label := _make_node_label()
		label.name = "NodeLabel"
		label.self_modulate = Color.WHITE
		label.z_index = 4
		node_view.add_child(label)

		node_views.append(node_view)


func _route_positions(count: int) -> Array[Vector2]:
	if count == 32:
		return _route_positions_for_32_nodes()

	var result: Array[Vector2] = []
	var board_size := _board_size()
	var left := art_config.route_margin
	var top := art_config.route_margin
	var right := maxf(left + 1.0, board_size.x - art_config.route_margin)
	var bottom := maxf(top + 1.0, board_size.y - art_config.route_margin)
	var width := maxf(1.0, right - left)
	var height := maxf(1.0, bottom - top)
	var perimeter := width * 2.0 + height * 2.0
	for index in range(count):
		var distance := perimeter * float(index) / float(max(1, count))
		var position := Vector2.ZERO
		if distance <= width:
			position = Vector2(left + distance, top)
		elif distance <= width + height:
			position = Vector2(right, top + distance - width)
		elif distance <= width * 2.0 + height:
			position = Vector2(right - (distance - width - height), bottom)
		else:
			position = Vector2(left, bottom - (distance - width * 2.0 - height))
		result.append(position)
	return result


func _route_positions_for_32_nodes() -> Array[Vector2]:
	var board_size := _board_size()
	var left := art_config.route_margin
	var top := art_config.route_margin
	var right := maxf(left + 1.0, board_size.x - art_config.route_margin)
	var bottom := maxf(top + 1.0, board_size.y - art_config.route_margin)
	var result: Array[Vector2] = []
	result.append_array(_line_positions(Vector2(left, top), Vector2(right, top), 11))
	result.append_array(_line_positions(Vector2(right, top), Vector2(right, bottom), 7).slice(1, 6))
	result.append_array(_line_positions(Vector2(right, bottom), Vector2(left, bottom), 11))
	result.append_array(_line_positions(Vector2(left, bottom), Vector2(left, top), 7).slice(1, 6))
	return result


func _line_positions(start: Vector2, end: Vector2, count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if count <= 1:
		result.append(start)
		return result
	for index in range(count):
		var t := float(index) / float(count - 1)
		result.append(start.lerp(end, t))
	return result


func _render_state() -> void:
	if board_root == null:
		return
	_layout_center_panel()
	_layout_route_nodes()
	_render_node_states()
	_sync_perspective_stage()
	_render_center_text()
	_render_movement_dice()
	if not is_marker_animating:
		_place_player_marker(_current_index())


func _sync_perspective_stage() -> void:
	if movement_dice_physics_view == null:
		return
	movement_dice_physics_view.set_map_visual_state(art_config, _nodes(), _current_index(), false)


func _render_node_states() -> void:
	var nodes := _nodes()
	for index in range(min(nodes.size(), node_views.size())):
		var node_view := node_views[index]
		var node_texture := node_view.get_node("NodeTexture") as TextureRect
		var is_current := bool(nodes[index].get("is_current", false))
		var is_cleared := bool(nodes[index].get("is_cleared", false))
		node_texture.modulate.a = 1.0 if not is_cleared else 0.68
		node_view.scale = Vector2(1.06, 1.06) if is_current else Vector2.ONE


func _render_center_text() -> void:
	var current_node := _current_node()
	var current_type := StringName(str(current_node.get("node_type", "start")))
	if circle_action_label != null:
		circle_action_label.text = _circle_action_badge_text()
	current_node_label.text = "当前位置：%s" % [_node_label(current_node)]
	next_node_label.text = "即将前往：%s" % [_next_hint_text()]
	move_dice_label.text = "前进骰：已选择 %d 颗普通六面骰" % [selected_movement_dice_indices.size()]
	roll_result_label.text = _roll_result_text()
	node_type_label.text = "节点类型：%s" % [_node_type_name(current_type)]
	danger_label.text = _danger_text(current_type)

	var pending_battle := bool(map_state.get("pending_battle", false))
	roll_button_wrapper.visible = not pending_battle
	enter_battle_button_wrapper.visible = pending_battle
	if roll_button != null:
		roll_button.disabled = pending_battle or is_marker_animating or is_board_animating
	if enter_battle_button != null:
		enter_battle_button.disabled = not pending_battle or is_marker_animating or is_board_animating
	_set_texture_button_label(enter_battle_button_wrapper, "进入首领战" if current_type == &"boss" else "进入战斗")
	_render_movement_dice()


func _on_map_state_changed(new_map_state: Dictionary) -> void:
	map_state = new_map_state.duplicate(true)
	if is_node_ready() and not is_marker_animating:
		_render_state()


func _on_roll_pressed() -> void:
	if game_flow_controller == null or is_marker_animating or is_board_animating:
		return
	is_marker_animating = true
	is_movement_roll_pending = true
	var selected_indices: Array[int] = selected_movement_dice_indices.duplicate()
	_refresh_interaction_lock_state()

	var prepared := game_flow_controller.prepare_map_movement_roll(selected_indices)
	if not bool(prepared.get("success", false)):
		is_movement_roll_pending = false
		is_marker_animating = false
		_refresh_interaction_lock_state()
		_render_state()
		return

	var prepared_rolls: Array = prepared.get("rolls", [])
	if movement_dice_physics_view != null:
		await movement_dice_physics_view.play_roll(prepared_rolls, selected_indices)
	else:
		await get_tree().create_timer(0.35, false).timeout

	var result := game_flow_controller.apply_prepared_map_movement_roll(selected_indices, prepared_rolls)
	is_movement_roll_pending = false
	if not bool(result.get("success", false)):
		is_marker_animating = false
		_refresh_interaction_lock_state()
		_render_state()
		return
	var path: Array = result.get("path", [])
	if next_node_label != null:
		next_node_label.text = "即将前往：%s" % [_next_hint_text()]
	if roll_result_label != null:
		roll_result_label.text = _roll_result_text()
	_render_movement_dice()
	var refresh_path_index := int(result.get("refresh_path_index", -1))
	await _animate_marker_path(path, refresh_path_index)
	is_marker_animating = false
	_refresh_interaction_lock_state()
	_render_state()
	_notify_map_movement_settled()


func _on_enter_battle_pressed() -> void:
	if game_flow_controller == null or is_marker_animating or is_board_animating:
		return
	game_flow_controller.request_enter_battle_from_map()


func _notify_map_movement_settled() -> void:
	if game_flow_controller == null:
		return
	if game_flow_controller.has_method("notify_map_movement_settled"):
		game_flow_controller.notify_map_movement_settled()


func _animate_marker_path(path: Array, refresh_path_index: int = -1) -> void:
	if player_marker == null:
		return
	if path.is_empty():
		_hide_movement_step_label()
		return
	for path_index in range(path.size()):
		var raw_index = path[path_index]
		var index := int(raw_index)
		var target_position := _marker_position_for_index(index)
		_show_movement_step_label(path_index + 1, player_marker.position)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(player_marker, "position", target_position, art_config.marker_step_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		if movement_step_label != null:
			tween.tween_property(movement_step_label, "position", _movement_step_label_position_for_marker_position(target_position), art_config.marker_step_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		if path_index == refresh_path_index:
			await _pause_and_refresh_map_ring()
	_hide_movement_step_label()


func _pause_and_refresh_map_ring() -> void:
	var pause_duration := maxf(0.0, art_config.map_refresh_pause_duration)
	if pause_duration > 0.0:
		await get_tree().create_timer(pause_duration, false).timeout
	_render_state()


func _place_player_marker(index: int) -> void:
	if player_marker == null:
		return
	player_marker.visible = not _nodes().is_empty()
	player_marker.size = art_config.player_marker_size
	player_marker.position = _marker_position_for_index(index)
	if not is_marker_animating:
		_hide_movement_step_label()


func _marker_position_for_index(index: int) -> Vector2:
	var positions := _route_positions(max(1, _nodes().size()))
	if positions.is_empty():
		return Vector2.ZERO
	var clamped_index := wrapi(index, 0, positions.size())
	return positions[clamped_index] - art_config.player_marker_size * 0.5 + art_config.player_marker_offset


func _show_movement_step_label(step_number: int, marker_position: Vector2) -> void:
	if movement_step_label == null:
		return
	movement_step_label.text = str(step_number)
	movement_step_label.size = movement_step_label.custom_minimum_size
	movement_step_label.position = _movement_step_label_position_for_marker_position(marker_position)
	movement_step_label.visible = true


func _hide_movement_step_label() -> void:
	if movement_step_label == null:
		return
	movement_step_label.visible = false


func _movement_step_label_position_for_marker_position(marker_position: Vector2) -> Vector2:
	var label_size := movement_step_label.size if movement_step_label != null and movement_step_label.size != Vector2.ZERO else Vector2(96.0, 42.0)
	return marker_position + art_config.player_marker_size * 0.5 - label_size * 0.5 + art_config.movement_step_label_offset


func _lowered_board_position() -> Vector2:
	var distance := maxf(_board_size().y, 1.0) * maxf(0.1, art_config.board_slide_distance_ratio)
	return Vector2(0.0, distance)


func _board_size() -> Vector2:
	if board_root != null and board_root.size.x > 0.0 and board_root.size.y > 0.0:
		return board_root.size
	if size.x > 0.0 and size.y > 0.0:
		return size
	return Vector2(1920.0, 1080.0)


func _nodes() -> Array:
	return map_state.get("nodes", [])


func _current_index() -> int:
	return int(map_state.get("current_index", 0))


func _current_node() -> Dictionary:
	var nodes := _nodes()
	if nodes.is_empty():
		return {
			"index": 0,
			"node_type": &"start",
			"is_start": true,
			"is_current": true,
		}
	return nodes[wrapi(_current_index(), 0, nodes.size())]


func _current_node_type() -> StringName:
	return StringName(str(_current_node().get("node_type", "start")))


func _next_hint_text() -> String:
	var nodes := _nodes()
	if nodes.is_empty():
		return "等待地图生成"
	var last_path: Array = map_state.get("last_path", [])
	if not last_path.is_empty():
		var destination_index := int(last_path[last_path.size() - 1])
		return _node_label(nodes[wrapi(destination_index, 0, nodes.size())])
	var next_index := wrapi(_current_index() + 1, 0, nodes.size())
	return "%s 或更远节点" % [_node_type_name(StringName(str(nodes[next_index].get("node_type", "event"))))]


func _node_label(node: Dictionary) -> String:
	var index := int(node.get("index", 0))
	var node_type := StringName(str(node.get("node_type", "event")))
	if bool(node.get("is_start", false)):
		return "起点"
	return "%02d 号 %s" % [index + 1, _node_type_name(node_type)]


func _node_short_name(node_type: StringName) -> String:
	match node_type:
		&"start":
			return "起点"
		&"battle":
			return "战斗"
		&"elite":
			return "精英"
		&"boss":
			return "首领"
		&"shop":
			return "商店"
		&"forge":
			return "铸骰"
		&"reward":
			return "奖励"
		&"penalty":
			return "惩罚"
		&"event":
			return "奇遇"
		&"rest":
			return "休整"
		_:
			return "?"


func _node_type_name(node_type: StringName) -> String:
	match node_type:
		&"start":
			return "起点"
		&"battle":
			return "战斗"
		&"elite":
			return "精英战斗"
		&"boss":
			return "首领战"
		&"shop":
			return "商店"
		&"forge":
			return "铸骰坊"
		&"reward":
			return "奖励"
		&"penalty":
			return "惩罚"
		&"event":
			return "奇遇"
		&"rest":
			return "休整"
		_:
			return "未知"


func _danger_text(current_type: StringName) -> String:
	var circle := int(map_state.get("circle", 1))
	var max_circles := int(map_state.get("max_circles", 8))
	var base_score := int(map_state.get("circle_base_score", 0))
	var action_count := int(map_state.get("circle_action_count", 0))
	var danger_bonus := int(map_state.get("danger_bonus_percent", 0))
	var target_score := int(map_state.get("current_node_target_score", 0))
	var prefix := "第 %d / %d 圈｜本圈行动：%d 次｜本圈基础分：%d｜危急值：+%d%%" % [
		circle,
		max_circles,
		action_count,
		base_score,
		danger_bonus,
	]
	if _is_battle_node_type(current_type) and target_score > 0:
		return "%s｜本节点目标 %d" % [prefix, target_score]
	return prefix


func _circle_action_badge_text() -> String:
	var action_count := int(map_state.get("circle_action_count", 0))
	var danger_bonus := int(map_state.get("danger_bonus_percent", 0))
	return "本圈行动：%d 次｜危急值：+%d%%" % [action_count, danger_bonus]


func _is_battle_node_type(node_type: StringName) -> bool:
	return node_type == &"battle" or node_type == &"elite" or node_type == &"boss"


func _set_texture_button_label(wrapper: Control, text: String) -> void:
	if wrapper == null:
		return
	var label := wrapper.get_node_or_null("ButtonLabel") as Label
	if label == null:
		return
	label.text = text
