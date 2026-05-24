extends PanelContainer
class_name BattleDiceStage3D


const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")
const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleIconLibrary = preload("res://scripts/ui/battle/resources/BattleIconLibrary.gd")
const DiceVisualLibrary = preload("res://scripts/ui/battle/resources/DiceVisualLibrary.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const RichTextHighlighter = preload("res://scripts/ui/RichTextHighlighter.gd")
const HoverInfoOverlay = preload("res://scripts/ui/battle/components/HoverInfoOverlay.gd")
const GmDiceDefinitionScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd")
const GmDiceFaceDefinitionScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceFaceDefinition.gd")
const GmDiceViewportScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceViewport.gd")
const GmReadyMgrScript = preload("res://scripts/ui/debug/gm_dice_port/GmReadyMgr.gd")
const GmBattleMgrScript = preload("res://scripts/ui/debug/gm_dice_port/GmBattleMgr.gd")
const BATTLE_STAGE_BACKGROUND_TEXTURE = preload("res://assets/ui/map/map_tabletop_neon_comic.png")
const FORMAL_BATTLE_DEFAULT_MATERIAL_ID := GmDiceDefinitionScript.MATERIAL_REPRO_LAPIS


signal die_pressed(index: int)
signal die_hovered(index: int)
signal die_info_requested(index: int)
signal ornament_link_requested(id: StringName)
signal mark_link_requested(id: StringName)
signal reroll_pressed()
signal score_pressed()
signal install_face_selected(die_index: int, face_index: int)
signal install_requested(die_index: int, face_index: int)
signal reward_choice_pressed(choice)
signal reward_ornament_link_requested(id: StringName)
signal reward_mark_link_requested(id: StringName)
signal roll_finished(results: Dictionary)


const ROLL_WAIT_TIMEOUT_SECONDS := 8.0
const ENTRY_RETURN_WAIT_TIMEOUT_SECONDS := 4.0


@export_range(20.0, 70.0, 0.1) var camera_fov := 38.0
@export var camera_position := Vector3(0.0, 18.5, 1.0)
@export var camera_look_at := Vector3(0.0, 0.72, -0.04)
@export_range(0.8, 10.0, 0.01) var dice_initial_height := 7.5
@export_range(-90.0, 0.0, 0.1) var key_light_pitch := -63.0
@export_range(-180.0, 180.0, 0.1) var key_light_yaw := 115.0

var style_config: BattleUiStyleConfig = null
var icon_library: BattleIconLibrary = null
var dice_visual_library: DiceVisualLibrary = null
var dice_info_popup_scene: PackedScene = null
var face_info_card_scene: PackedScene = null
var floating_score_text_scene: PackedScene = null
var stage_background_texture: TextureRect = null
var current_state: BattleHudState = null
var dice_viewport: GmDiceViewport = null
var ready_mgr: GmReadyMgr = null
var battle_mgr: GmBattleMgr = null
var overlay_layer: Control = null
var hover_overlay_layer: HoverInfoOverlay = null
var action_buttons_layer: Control = null
var reroll_button: Button = null
var organize_button: Button = null
var score_button: Button = null
var popup: Control = null
var reward_overlay: Control = null
var floating_layer: Control = null
var marker_layer: Control = null
var roster_signature := ""
var face_state_signature := ""
var display_die_order: Array[int] = []
var hidden_die_indices: Array[int] = []
var highlighted_die_indices: Array[int] = []
var resolution_die_indices: Array[int] = []
var focused_die_index := 0
var popup_die_index := -1
var hover_die_index := -1
var install_mode_active := false
var install_piece_name := ""
var install_action_text := ""
var is_sorting_dice := false
var entry_return_revealing := false
var last_entry_return_started_from_hidden := false
var debug_render_call_count: int = 0


func setup(
	arg1 = null,
	arg2 = null,
	arg3 = null,
	arg4 = null,
	arg5 = null,
	arg6 = null
) -> void:
	style_config = arg1 as BattleUiStyleConfig
	if arg2 is BattleIconLibrary:
		icon_library = arg2 as BattleIconLibrary
		dice_visual_library = arg3 as DiceVisualLibrary
		dice_info_popup_scene = arg5 as PackedScene
		face_info_card_scene = arg6 as PackedScene
	else:
		floating_score_text_scene = arg3 as PackedScene
		icon_library = arg5 as BattleIconLibrary
		dice_visual_library = arg6 as DiceVisualLibrary
	if is_node_ready():
		_apply_style()


func _ready() -> void:
	_build()
	_apply_style()


func _process(_delta: float) -> void:
	if hover_die_index >= 0:
		if not _can_start_dice_hover(hover_die_index):
			_clear_hovered_die()
			return
		_position_hover_widgets(hover_die_index)


func render(state: BattleHudState) -> void:
	debug_render_call_count += 1
	current_state = state
	if state == null:
		return
	_ensure_roster_for_state(state)
	var next_face_signature := _face_state_signature(state)
	if next_face_signature != face_state_signature:
		face_state_signature = next_face_signature
		_sync_faces_from_state(state)
	_sync_selection_from_state(state)
	_apply_transient_state()
	_render_overlay_text(state)
	_refresh_hover_presentation()


func play_reroll_for_selected() -> void:
	await roll_selected_and_wait([])


func roll_all_and_wait() -> Dictionary:
	if battle_mgr == null:
		return {}
	var indices: Array[int] = []
	for index in range(battle_mgr.using_dices.size()):
		indices.append(index)
	return await _roll_indices_and_wait(indices)


func roll_selected_and_wait(selected_indices: Array[int] = []) -> Dictionary:
	if battle_mgr == null:
		return {}
	var indices := selected_indices.duplicate()
	if indices.is_empty() and current_state != null:
		indices = current_state.selected_dice_indices.duplicate()
	if indices.is_empty():
		return {}
	return await _roll_indices_and_wait(indices)


func play_entry_return_and_wait(entry_indices: Array[int] = []) -> Dictionary:
	if battle_mgr == null:
		return {}
	var indices := _valid_roll_indices(entry_indices)
	if indices.is_empty():
		for index in range(battle_mgr.using_dices.size()):
			indices.append(index)
	if indices.is_empty():
		return {}
	last_entry_return_started_from_hidden = _indices_are_hidden(indices)
	entry_return_revealing = true
	if not battle_mgr.request_dice_entry_return():
		entry_return_revealing = false
		return {}
	hidden_die_indices.clear()
	var completed := await _wait_for_entry_return_finished()
	entry_return_revealing = false
	_apply_transient_state()
	if not completed:
		return {}
	return _formal_roll_results_for_indices(indices)


func show_reward_choices(choices: Array) -> void:
	_ensure_reward_overlay()
	_clear_children(reward_overlay)
	reward_overlay.visible = true

	var scrim := ColorRect.new()
	scrim.name = "RewardChoiceScrim"
	scrim.color = Color(0.0, 0.0, 0.0, 0.34)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reward_overlay.add_child(scrim)

	var center := CenterContainer.new()
	center.name = "RewardChoiceCenter"
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reward_overlay.add_child(center)

	var content := VBoxContainer.new()
	content.name = "RewardChoiceContent"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 24)
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(content)

	var title := Label.new()
	title.name = "RewardChoiceTitle"
	title.text = "常规奖励"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0.0, 58.0)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.96, 0.78, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.02, 0.95))
	title.add_theme_constant_override("outline_size", 5)
	if style_config != null and style_config.font != null:
		title.add_theme_font_override("font", style_config.font)
	content.add_child(title)

	var row := HBoxContainer.new()
	row.name = "RewardChoiceRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	content.add_child(row)
	if choices.is_empty():
		var empty_label := Label.new()
		empty_label.text = "没有可选奖励"
		empty_label.add_theme_font_size_override("font_size", 24)
		empty_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.72, 1.0))
		row.add_child(empty_label)
		return
	for choice in choices:
		row.add_child(_make_reward_choice_card(choice))


func hide_reward_choices() -> void:
	if reward_overlay != null:
		reward_overlay.visible = false


func request_info_for_die(index: int) -> void:
	show_info_for_die(index)


func show_info_for_die(index: int) -> void:
	if current_state == null:
		return
	var die_data := _die_data_at(index)
	if die_data == null:
		return
	focused_die_index = index
	popup_die_index = index
	_ensure_popup()
	if popup == null:
		return
	popup.visible = true
	if popup.has_method("set_install_context"):
		popup.call("set_install_context", install_mode_active, install_piece_name, install_action_text)
	if popup.has_method("render"):
		popup.call("render", die_data)
	_position_popup(index)


func hide_info() -> void:
	if popup != null:
		popup.visible = false
	popup_die_index = -1
	_clear_hovered_die()


func is_info_visible() -> bool:
	return popup != null and popup.visible


func is_global_point_inside_info_popup(global_point: Vector2) -> bool:
	if popup == null or not popup.visible:
		return false
	return popup.get_global_rect().has_point(global_point)


func set_install_mode(enabled: bool, piece_name: String = "", action_text: String = "") -> void:
	install_mode_active = enabled
	install_piece_name = piece_name
	install_action_text = action_text
	if popup != null and popup.has_method("set_install_context"):
		popup.call("set_install_context", install_mode_active, install_piece_name, install_action_text)


func is_install_mode_active() -> bool:
	return install_mode_active


func set_hidden_die_indices(indices: Array) -> void:
	hidden_die_indices = _int_indices_from_array(indices)
	_apply_transient_state()


func clear_hidden_die_indices() -> void:
	hidden_die_indices.clear()
	_apply_transient_state()


func clear_for_map_stage() -> void:
	current_state = null
	roster_signature = ""
	face_state_signature = ""
	display_die_order.clear()
	hidden_die_indices.clear()
	highlighted_die_indices.clear()
	resolution_die_indices.clear()
	entry_return_revealing = false
	last_entry_return_started_from_hidden = false
	hide_info()
	hide_reward_choices()
	if marker_layer != null:
		_clear_children(marker_layer)
	if floating_layer != null:
		_clear_children(floating_layer)
	if action_buttons_layer != null:
		action_buttons_layer.visible = false
	if battle_mgr != null:
		battle_mgr.clear()


func set_highlighted_die_indices(indices: Array) -> void:
	highlighted_die_indices = _int_indices_from_array(indices)
	_apply_transient_state()


func clear_highlights() -> void:
	highlighted_die_indices.clear()
	_apply_transient_state()


func get_die_view_global_rect(index: int) -> Rect2:
	return _dice_global_rect(index)


func get_die_magic_fx_global_rect(index: int) -> Rect2:
	return _dice_global_rect(index)


func get_display_die_order() -> Array[int]:
	if not display_die_order.is_empty():
		return display_die_order.duplicate()
	var order: Array[int] = []
	if current_state != null:
		for die_data in current_state.dice_results:
			if die_data != null:
				order.append(die_data.die_index)
	return order


func get_visual_die_order_left_to_right() -> Array[int]:
	var order: Array[int] = []
	if battle_mgr == null:
		return order
	var rows: Array = []
	for index in range(battle_mgr.using_dices.size()):
		var instance = battle_mgr.using_dices[index]
		if instance == null or instance.avatar == null:
			continue
		rows.append({
			"die_index": index,
			"x": (instance.avatar as Node3D).global_position.x,
		})
	rows.sort_custom(func(a, b) -> bool:
		var ax := float((a as Dictionary).get("x", 0.0))
		var bx := float((b as Dictionary).get("x", 0.0))
		if is_equal_approx(ax, bx):
			return int((a as Dictionary).get("die_index", 0)) < int((b as Dictionary).get("die_index", 0))
		return ax < bx
	)
	for row in rows:
		order.append(int((row as Dictionary).get("die_index", -1)))
	return order


func reset_display_order() -> void:
	display_die_order.clear()
	if battle_mgr != null and battle_mgr.has_method("clear_display_die_order"):
		battle_mgr.clear_display_die_order()
	if battle_mgr != null and battle_mgr.has_method("apply_display_order_to_ready_positions"):
		battle_mgr.apply_display_order_to_ready_positions()


func show_resolution_dice(dice_data: Array[DieViewData], _transparent: bool = false) -> void:
	resolution_die_indices.clear()
	for data in dice_data:
		if data != null:
			resolution_die_indices.append(data.die_index)
	_rebuild_resolution_markers()


func clear_resolution_dice() -> void:
	resolution_die_indices.clear()
	if marker_layer != null:
		_clear_children(marker_layer)
	clear_highlights()


func set_resolution_dice_visible(value: bool) -> void:
	if marker_layer != null:
		marker_layer.visible = value


func set_resolution_index_visible(index: int, value: bool) -> void:
	var marker := _resolution_marker_at(index)
	if marker != null:
		marker.visible = value


func get_resolution_dice_global_position(index: int) -> Vector2:
	return get_resolution_dice_global_rect(index).position


func get_resolution_dice_global_center(index: int) -> Vector2:
	return get_resolution_dice_global_rect(index).get_center()


func get_resolution_dice_global_rect(index: int) -> Rect2:
	var die_index := _resolution_die_index_at(index)
	if die_index >= 0:
		return _dice_global_rect(die_index)
	return get_global_rect()


func get_resolution_dice_global_floating_anchor(index: int) -> Vector2:
	var rect := get_resolution_dice_global_rect(index)
	return Vector2(rect.get_center().x, rect.position.y - 22.0)


func highlight_resolution_index(index: int) -> void:
	var die_index := _resolution_die_index_at(index)
	set_highlighted_die_indices([die_index] if die_index >= 0 else [])


func show_step_text(_title: String, _detail: String) -> void:
	pass


func show_floating_score(text: String) -> void:
	show_floating_score_at(text, get_global_rect().get_center())


func show_floating_score_at(text: String, global_position: Vector2) -> void:
	var floating := _make_floating_label(text)
	if floating == null:
		return
	_position_floating(floating, global_position)
	_animate_and_free_floating(floating)


func play_floating_score(text: String) -> void:
	await play_floating_score_at(text, get_global_rect().get_center())


func play_floating_score_at(text: String, global_position: Vector2) -> void:
	var floating := _make_floating_label(text)
	if floating == null:
		return
	_position_floating(floating, global_position)
	await _animate_and_free_floating(floating)


func _build() -> void:
	_clear_children(self)
	mouse_filter = Control.MOUSE_FILTER_PASS

	var margin := MarginContainer.new()
	margin.name = "BattleDiceStage3DMargin"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var stage_root := Control.new()
	stage_root.name = "BattleDiceStage3DRoot"
	stage_root.clip_contents = true
	stage_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(stage_root)

	stage_background_texture = TextureRect.new()
	stage_background_texture.name = "BattleStageBackgroundTexture"
	stage_background_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_background_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage_background_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stage_background_texture.texture = BATTLE_STAGE_BACKGROUND_TEXTURE
	stage_background_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_root.add_child(stage_background_texture)

	dice_viewport = GmDiceViewportScript.new()
	dice_viewport.name = "FormalBattleDiceViewport"
	stage_root.add_child(dice_viewport)
	dice_viewport.build()
	dice_viewport.configure_camera(camera_fov, camera_position, camera_look_at)
	dice_viewport.configure_ready_row_height(dice_initial_height)
	dice_viewport.configure_key_light(key_light_pitch, key_light_yaw)
	dice_viewport.dice_clicked.connect(_on_dice_viewport_dice_clicked)
	if dice_viewport.has_signal("dice_hovered"):
		dice_viewport.dice_hovered.connect(_on_dice_viewport_dice_hovered)
	if dice_viewport.has_signal("dice_hover_cleared"):
		dice_viewport.dice_hover_cleared.connect(_on_dice_viewport_dice_hover_cleared)
	_configure_battle_stage_background()

	ready_mgr = GmReadyMgrScript.new()
	ready_mgr.name = "FormalBattleReadyMgr"
	add_child(ready_mgr)
	ready_mgr.setup(dice_viewport.dice_box_anchors, dice_viewport.spawn_point, dice_viewport.dice_container)
	ready_mgr.fly_dice_pos = dice_viewport.dice_box_anchors.get_node("FlyPoint") as Marker3D
	ready_mgr.show_dice_pos = dice_viewport.dice_box_anchors.get_node("ShowPoint") as Marker3D
	ready_mgr.shop_dice_pos = dice_viewport.dice_box_anchors.get_node("ShopDicePoint") as Marker3D
	ready_mgr.shop_boss_pos = dice_viewport.dice_box_anchors.get_node("BossDicePoint") as Marker3D
	ready_mgr.dice_call_pos = dice_viewport.dice_box_anchors.get_node("DiceCallPoint") as Marker3D

	battle_mgr = GmBattleMgrScript.new()
	battle_mgr.name = "FormalBattleDiceMgr"
	add_child(battle_mgr)
	battle_mgr.setup(ready_mgr, dice_viewport.dice_container)
	if battle_mgr.has_method("set_formal_battle_mode"):
		battle_mgr.set_formal_battle_mode(true)
	battle_mgr.set_unselected_hold_tuning(_resolved_unselected_hold_tuning())
	battle_mgr.dice_roster_changed.connect(func(_snapshot: Dictionary) -> void:
		_apply_transient_state()
	)
	battle_mgr.roll_finished.connect(func(_snapshot: Dictionary) -> void:
		_apply_transient_state()
	)

	overlay_layer = Control.new()
	overlay_layer.name = "BattleDiceStage3DOverlay"
	overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.z_index = 20
	stage_root.add_child(overlay_layer)

	floating_layer = Control.new()
	floating_layer.name = "FloatingScoreLayer"
	floating_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	floating_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_layer.z_index = 40
	stage_root.add_child(floating_layer)

	marker_layer = Control.new()
	marker_layer.name = "ResolutionMarkerLayer"
	marker_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	marker_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker_layer.z_index = 35
	stage_root.add_child(marker_layer)

	_build_hover_overlay(stage_root)
	_build_action_buttons(stage_root)


func _configure_battle_stage_background() -> void:
	if stage_background_texture != null:
		stage_background_texture.texture = BATTLE_STAGE_BACKGROUND_TEXTURE
		stage_background_texture.visible = stage_background_texture.texture != null
	if dice_viewport == null or dice_viewport.sub_viewport == null:
		return
	dice_viewport.sub_viewport.transparent_bg = true
	dice_viewport.sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	var environment := dice_viewport.sub_viewport.get_node_or_null("DiceWorld/WorldEnvironment") as WorldEnvironment
	if environment != null and environment.environment != null:
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
	if dice_viewport.has_method("set_throw_surface_texture"):
		dice_viewport.call("set_throw_surface_texture", null, Color.WHITE, false)


func _build_action_buttons(parent: Control) -> void:
	action_buttons_layer = Control.new()
	action_buttons_layer.name = "BattleActionButtonsLayer"
	action_buttons_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action_buttons_layer.anchor_left = 0.0
	action_buttons_layer.anchor_top = 1.0
	action_buttons_layer.anchor_right = 1.0
	action_buttons_layer.anchor_bottom = 1.0
	action_buttons_layer.offset_left = 0.0
	action_buttons_layer.offset_top = -126.0
	action_buttons_layer.offset_right = 0.0
	action_buttons_layer.offset_bottom = -24.0
	action_buttons_layer.z_index = 75
	parent.add_child(action_buttons_layer)

	var center := CenterContainer.new()
	center.name = "ActionButtonsCenter"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	action_buttons_layer.add_child(center)

	var actions := HBoxContainer.new()
	actions.name = "ActionButtonsRow"
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 42)
	center.add_child(actions)

	reroll_button = Button.new()
	reroll_button.name = "RerollButton"
	reroll_button.text = "重投所选"
	reroll_button.focus_mode = Control.FOCUS_NONE
	reroll_button.custom_minimum_size = Vector2(260.0, 82.0)
	reroll_button.pressed.connect(func() -> void: reroll_pressed.emit())
	actions.add_child(reroll_button)

	organize_button = Button.new()
	organize_button.name = "OrganizeButton"
	organize_button.text = "整理"
	organize_button.focus_mode = Control.FOCUS_NONE
	organize_button.custom_minimum_size = Vector2(122.0, 58.0)
	organize_button.pressed.connect(_on_organize_pressed)
	actions.add_child(organize_button)

	score_button = Button.new()
	score_button.name = "ScoreButton"
	score_button.text = "结算所选"
	score_button.focus_mode = Control.FOCUS_NONE
	score_button.custom_minimum_size = Vector2(260.0, 82.0)
	score_button.pressed.connect(func() -> void: score_pressed.emit())
	actions.add_child(score_button)


func _build_hover_overlay(parent: Control) -> void:
	hover_overlay_layer = HoverInfoOverlay.new()
	hover_overlay_layer.name = "DiceHoverOverlayLayer"
	hover_overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hover_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_overlay_layer.z_index = 70
	hover_overlay_layer.setup(style_config, "DiceHoverFaceInfoPanel", Vector2(340.0, 156.0))
	parent.add_child(hover_overlay_layer)

func _apply_style() -> void:
	if not is_node_ready():
		return
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if style_config != null:
		for button in [reroll_button, organize_button, score_button]:
			if button != null:
				style_config.apply_button(button)
		_apply_action_button_styles()
	if hover_overlay_layer != null:
		hover_overlay_layer.setup(style_config, "DiceHoverFaceInfoPanel", Vector2(340.0, 156.0))


func _apply_action_button_styles() -> void:
	_apply_banner_action_button_style(
		reroll_button,
		Color(0.03, 0.12, 0.10, 0.96),
		Color(0.05, 0.90, 0.58, 1.0),
		Color(0.70, 1.00, 0.86, 1.0)
	)
	_apply_banner_action_button_style(
		score_button,
		Color(0.12, 0.05, 0.08, 0.96),
		Color(1.00, 0.66, 0.18, 1.0),
		Color(1.00, 0.90, 0.62, 1.0)
	)
	_apply_banner_action_button_style(
		organize_button,
		Color(0.07, 0.10, 0.11, 0.92),
		Color(0.48, 0.62, 0.64, 0.95),
		Color(0.88, 0.95, 0.94, 1.0),
		20
	)

func _apply_banner_action_button_style(button: Button, fill: Color, accent: Color, text_color: Color, font_size: int = 34) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", _make_banner_button_style(fill, accent, 0.0, 1.0))
	button.add_theme_stylebox_override("hover", _make_banner_button_style(fill.lightened(0.10), accent.lightened(0.08), -2.0, 1.0))
	button.add_theme_stylebox_override("pressed", _make_banner_button_style(fill.darkened(0.10), accent, 2.0, 1.0))
	button.add_theme_stylebox_override("disabled", _make_banner_button_style(fill.darkened(0.24), accent.darkened(0.42), 0.0, 0.58))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", text_color.darkened(0.08))
	button.add_theme_color_override("font_disabled_color", Color(text_color.r, text_color.g, text_color.b, 0.48))
	button.add_theme_color_override("font_outline_color", Color(0.0, 0.02, 0.02, 0.96))
	button.add_theme_constant_override("outline_size", 6 if font_size >= 30 else 4)


func _make_banner_button_style(fill: Color, accent: Color, y_offset: float, alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill.r, fill.g, fill.b, fill.a * alpha)
	style.border_color = Color(accent.r, accent.g, accent.b, accent.a * alpha)
	style.set_border_width_all(4)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 3
	style.content_margin_left = 26.0
	style.content_margin_right = 26.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.50 * alpha)
	style.shadow_size = 12
	style.shadow_offset = Vector2(7.0, 8.0 + y_offset)
	return style


func _ensure_roster_for_state(state: BattleHudState) -> void:
	var next_signature := _roster_signature(state)
	var has_live_roster := battle_mgr != null and battle_mgr.using_dices.size() > 0
	if next_signature == roster_signature and (next_signature != "" or not has_live_roster):
		return
	roster_signature = next_signature
	face_state_signature = ""
	display_die_order.clear()
	_clear_hovered_die()
	if battle_mgr != null and battle_mgr.has_method("clear_display_die_order"):
		battle_mgr.clear_display_die_order()
	var definitions: Array = []
	for die_data in state.dice_results:
		definitions.append(_definition_from_die_data(die_data))
	if battle_mgr != null:
		if definitions.is_empty():
			battle_mgr.clear()
		else:
			battle_mgr.create_dice_from_definitions(definitions)


func _definition_from_die_data(die_data: DieViewData) -> GmDiceDefinition:
	var definition := GmDiceDefinitionScript.new() as GmDiceDefinition
	definition.id = die_data.die_id if die_data != null else &"formal_battle_die"
	definition.display_name = "战斗骰子 %d" % [die_data.die_index + 1 if die_data != null else 1]
	definition.description = "正式战斗 3D 骰子"
	definition.material_id = FORMAL_BATTLE_DEFAULT_MATERIAL_ID
	definition.faces.clear()
	if die_data != null:
		for face in die_data.faces:
			var pip := int(face.pip) if face != null else 1
			definition.faces.append(GmDiceFaceDefinitionScript.make(pip, str(pip)))
	if definition.faces.is_empty():
		for value in range(1, 7):
			definition.faces.append(GmDiceFaceDefinitionScript.make(value, str(value)))
	return definition


func _sync_faces_from_state(state: BattleHudState) -> void:
	if battle_mgr == null or bool(battle_mgr.get_snapshot().get("rolling", false)):
		return
	for die_data in state.dice_results:
		if die_data == null:
			continue
		var index := die_data.die_index
		if index < 0 or index >= battle_mgr.using_dices.size():
			continue
		var instance = battle_mgr.using_dices[index]
		if instance == null:
			continue
		var face_index := clampi(die_data.current_face_index, 0, max(0, instance.run_faces.size() - 1))
		instance.set_face_index(face_index)
		var avatar = instance.avatar
		if avatar != null:
			avatar.change_inner_by_value(0.0)
			avatar.apply_hover_presentation_rotation()
			avatar.show_number(true)
	_apply_display_order_positions()


func _sync_selection_from_state(state: BattleHudState) -> void:
	if battle_mgr == null:
		return
	battle_mgr.selected_dice_indices = state.selected_dice_indices.duplicate()
	for index in range(battle_mgr.using_dices.size()):
		var instance = battle_mgr.using_dices[index]
		if instance != null and instance.avatar != null and instance.avatar.has_method("set_selected"):
			instance.avatar.call("set_selected", state.selected_dice_indices.has(index))


func _apply_transient_state() -> void:
	if battle_mgr == null:
		return
	for index in range(battle_mgr.using_dices.size()):
		var instance = battle_mgr.using_dices[index]
		if instance == null or instance.avatar == null:
			continue
		var avatar = instance.avatar
		if not entry_return_revealing:
			avatar.visible = not hidden_die_indices.has(index)
		if avatar.has_method("set_selected") and current_state != null:
			avatar.call("set_selected", current_state.selected_dice_indices.has(index) or highlighted_die_indices.has(index))
	if hover_die_index >= 0 and hidden_die_indices.has(hover_die_index):
		_clear_hovered_die()


func _render_overlay_text(state: BattleHudState) -> void:
	if action_buttons_layer != null:
		action_buttons_layer.visible = not state.dice_results.is_empty() and not state.controls_locked
	if reroll_button != null:
		reroll_button.disabled = not state.can_reroll
	if score_button != null:
		score_button.disabled = not state.can_score
	if organize_button != null:
		organize_button.disabled = state.controls_locked or is_sorting_dice


func _show_hover_face_info(index: int) -> void:
	if hover_overlay_layer == null:
		return
	if not _can_start_dice_hover(index):
		_clear_hovered_die()
		return
	if current_state == null:
		_clear_hovered_die()
		return
	var die_data := _die_data_at(index)
	if die_data == null or die_data.current_face == null:
		_clear_hovered_die()
		return
	hover_overlay_layer.show_hover(
		_hover_die_target_id(index),
		_dice_global_rect(index),
		"骰面信息",
		_hover_face_info_rows(die_data)
	)


func _refresh_hover_presentation() -> void:
	if hover_die_index < 0:
		return
	if not _can_start_dice_hover(hover_die_index):
		_clear_hovered_die()
		return
	_show_hover_face_info(hover_die_index)


func _can_start_dice_hover(index: int) -> bool:
	if index < 0 or hidden_die_indices.has(index):
		return false
	if current_state == null or _die_data_at(index) == null:
		return false
	if battle_mgr == null or index >= battle_mgr.using_dices.size():
		return false
	var snapshot := battle_mgr.get_snapshot()
	if bool(snapshot.get("rolling", false)) or entry_return_revealing:
		return false
	if int(snapshot.get("pending_launches", 0)) > 0 or int(snapshot.get("pending_ready_returns", 0)) > 0:
		return false
	if bool(snapshot.get("dice_exit_animating", false)) or bool(snapshot.get("dice_exit_return_animating", false)):
		return false
	if int(snapshot.get("pending_dice_exit_animations", 0)) > 0 or int(snapshot.get("pending_dice_exit_return_animations", 0)) > 0:
		return false
	if bool(snapshot.get("unselected_hold_active", false)) or int(snapshot.get("pending_unselected_hold_returns", 0)) > 0:
		return false
	var instance = battle_mgr.using_dices[index]
	if instance == null or instance.avatar == null:
		return false
	var avatar = instance.avatar
	if not avatar.visible:
		return false
	if bool(avatar.get("is_rolling")) or bool(avatar.get("is_returning_to_ready")):
		return false
	if bool(avatar.get("is_returning_from_exit")) or bool(avatar.get("is_exiting")) or bool(avatar.get("is_exited")):
		return false
	if bool(avatar.get("is_moving_to_unselected_hold")) or bool(avatar.get("is_in_unselected_hold")) or bool(avatar.get("is_returning_from_unselected_hold")):
		return false
	return true


func _hover_face_info_rows(die_data: DieViewData) -> Array[Dictionary]:
	var face = die_data.current_face
	return [
		{"key": "Body", "name": "骰胚", "effect": die_data.body_name},
		{"key": "Pip", "name": "点数", "effect": str(face.pip) if face != null else "-"},
		{"key": "Ornament", "name": "面饰", "effect": face.ornament_name if face != null else "-"},
		{"key": "Mark", "name": "印记", "effect": face.mark_name if face != null else "-"},
	]


func _position_hover_widgets(index: int) -> void:
	if hover_overlay_layer == null:
		return
	hover_overlay_layer.update_target_rect(_dice_global_rect(index))


func _clear_hovered_die() -> void:
	hover_die_index = -1
	if hover_overlay_layer != null:
		hover_overlay_layer.hide_hover()


func _hover_die_target_id(index: int) -> StringName:
	return StringName("die_%d" % [index])


func _on_dice_viewport_dice_clicked(dice) -> void:
	var index := _avatar_index(dice)
	if index < 0:
		return
	if hover_overlay_layer != null:
		hover_overlay_layer.interrupt_target(_hover_die_target_id(index))
	focused_die_index = index
	die_pressed.emit(index)


func _on_dice_viewport_dice_hovered(dice) -> void:
	var index := _avatar_index(dice)
	if index < 0 or not _can_start_dice_hover(index):
		_clear_hovered_die()
		return
	var previous_index := hover_die_index
	hover_die_index = index
	if previous_index != index and hover_overlay_layer != null:
		hover_overlay_layer.hide_hover()
	if popup == null or not popup.visible:
		focused_die_index = index
	_show_hover_face_info(index)
	die_hovered.emit(index)


func _on_dice_viewport_dice_hover_cleared() -> void:
	_clear_hovered_die()


func _on_organize_pressed() -> void:
	if battle_mgr == null or current_state == null:
		return
	var order := _sorted_die_order(current_state.dice_results)
	display_die_order = order
	_apply_display_order_positions()


func _sorted_die_order(dice: Array[DieViewData]) -> Array[int]:
	var sorted: Array[DieViewData] = []
	for die_data in dice:
		if die_data != null:
			sorted.append(die_data)
	sorted.sort_custom(func(a: DieViewData, b: DieViewData) -> bool:
		var pip_a := a.current_face.pip if a.current_face != null else -1
		var pip_b := b.current_face.pip if b.current_face != null else -1
		if pip_a == pip_b:
			return a.die_index < b.die_index
		return pip_a > pip_b
	)
	var order: Array[int] = []
	for die_data in sorted:
		order.append(die_data.die_index)
	return order


func _roll_indices_and_wait(indices: Array[int]) -> Dictionary:
	var sanitized := _valid_roll_indices(indices)
	if sanitized.is_empty() or battle_mgr == null:
		return {}
	if current_state != null:
		_sync_selection_from_state(current_state)
	battle_mgr.selected_dice_indices = sanitized.duplicate()
	if battle_mgr.has_method("_sync_selection_visuals"):
		battle_mgr.call("_sync_selection_visuals")
	var before_roll_num := int(battle_mgr.get_snapshot().get("roll_num", 0))
	battle_mgr.roll_using_dices([])
	var completed := await _wait_for_roll_finished()
	if not completed:
		return {}
	var results := _formal_roll_results_for_indices(sanitized)
	if results.size() != sanitized.size():
		return {}
	if int(battle_mgr.get_snapshot().get("roll_num", 0)) <= before_roll_num:
		return {}
	roll_finished.emit(results)
	_apply_display_order_positions()
	return results


func _apply_display_order_positions() -> void:
	if battle_mgr == null:
		return
	if display_die_order.is_empty():
		if battle_mgr.has_method("clear_display_die_order"):
			battle_mgr.clear_display_die_order()
		return
	if ready_mgr == null:
		return
	var count := battle_mgr.using_dices.size()
	var order := _complete_display_order(count)
	if battle_mgr.has_method("set_display_die_order"):
		battle_mgr.set_display_die_order(order)
	var snapshot := battle_mgr.get_snapshot()
	if bool(snapshot.get("rolling", false)) or entry_return_revealing:
		return
	if bool(snapshot.get("dice_exit_animating", false)) or bool(snapshot.get("dice_exit_return_animating", false)):
		return
	if battle_mgr.has_method("apply_display_order_to_ready_positions"):
		battle_mgr.apply_display_order_to_ready_positions()
		return
	for visual_slot_index in range(order.size()):
		var die_index := int(order[visual_slot_index])
		if die_index < 0 or die_index >= count:
			continue
		var instance = battle_mgr.using_dices[die_index]
		if instance == null or instance.avatar == null:
			continue
		var avatar = instance.avatar
		if avatar.get("is_rolling") or avatar.get("is_returning_to_ready") or avatar.get("is_returning_from_exit"):
			continue
		if avatar.get("is_moving_to_unselected_hold") or avatar.get("is_returning_from_unselected_hold"):
			continue
		avatar.set_ready_hover(
			ready_mgr.get_spawn_position(visual_slot_index, count),
			GmReadyMgr.READY_ROW_YAW_DEGREES
		)


func _complete_display_order(count: int) -> Array[int]:
	var order: Array[int] = []
	for raw_index in display_die_order:
		var die_index := int(raw_index)
		if die_index < 0 or die_index >= count or order.has(die_index):
			continue
		order.append(die_index)
	for die_index in range(count):
		if not order.has(die_index):
			order.append(die_index)
	return order


func _wait_for_roll_finished() -> bool:
	if battle_mgr == null:
		return false
	var elapsed := 0.0
	while elapsed < ROLL_WAIT_TIMEOUT_SECONDS:
		await get_tree().physics_frame
		elapsed += 1.0 / maxf(1.0, Engine.physics_ticks_per_second)
		var snapshot := battle_mgr.get_snapshot()
		if not bool(snapshot.get("rolling", false)) and int(snapshot.get("pending_ready_returns", 0)) <= 0:
			return true
	return false


func _wait_for_entry_return_finished() -> bool:
	if battle_mgr == null:
		return false
	var elapsed := 0.0
	while elapsed < ENTRY_RETURN_WAIT_TIMEOUT_SECONDS:
		await get_tree().physics_frame
		elapsed += 1.0 / maxf(1.0, Engine.physics_ticks_per_second)
		var snapshot := battle_mgr.get_snapshot()
		if not bool(snapshot.get("dice_exit_return_animating", false)) and int(snapshot.get("pending_dice_exit_return_animations", 0)) <= 0:
			return true
	return false


func _valid_roll_indices(indices: Array[int]) -> Array[int]:
	var result: Array[int] = []
	if battle_mgr == null:
		return result
	for raw_index in indices:
		var index := int(raw_index)
		if index < 0 or index >= battle_mgr.using_dices.size():
			continue
		if result.has(index):
			continue
		result.append(index)
	return result


func _int_indices_from_array(indices: Array) -> Array[int]:
	var result: Array[int] = []
	for raw_index in indices:
		var index := int(raw_index)
		if result.has(index):
			continue
		result.append(index)
	return result


func _indices_are_hidden(indices: Array[int]) -> bool:
	if indices.is_empty():
		return hidden_die_indices.is_empty()
	for index in indices:
		if not hidden_die_indices.has(index):
			return false
	return true


func _formal_roll_results_for_indices(indices: Array[int]) -> Dictionary:
	var results := {}
	if battle_mgr == null:
		return results
	var index_lookup := {}
	for index in indices:
		index_lookup[index] = true
	var rows := _last_formal_roll_rows()
	for raw_row in rows:
		if not (raw_row is Dictionary):
			continue
		var row: Dictionary = raw_row
		var die_index := int(row.get("die_index", -1))
		if not index_lookup.has(die_index):
			continue
		results[die_index] = {
			"die_index": die_index,
			"face_index": int(row.get("settled_face_index", row.get("face_index", -1))),
			"pip": int(row.get("settled_face_value", row.get("face_value", 0))),
		}
	for die_index in indices:
		if results.has(die_index):
			continue
		if die_index < 0 or die_index >= battle_mgr.using_dices.size():
			continue
		var instance = battle_mgr.using_dices[die_index]
		if instance == null:
			continue
		results[die_index] = {
			"die_index": die_index,
			"face_index": int(instance.value),
			"pip": int(instance.get_actual_face_one()),
		}
	return results


func _last_formal_roll_rows() -> Array:
	if battle_mgr == null:
		return []
	var snapshot := battle_mgr.get_snapshot()
	var request = snapshot.get("last_resolution_request", {})
	if request is Dictionary:
		var request_rows = (request as Dictionary).get("dice", [])
		if request_rows is Array and not (request_rows as Array).is_empty():
			return request_rows as Array
	return []


func _ensure_popup() -> void:
	if popup != null or dice_info_popup_scene == null:
		return
	var instance := dice_info_popup_scene.instantiate()
	if not instance is Control:
		return
	popup = instance
	popup.name = "BattleDiceStage3DInfoPopup"
	popup.z_index = 80
	add_child(popup)
	if popup.has_method("setup"):
		popup.call("setup", style_config, icon_library, face_info_card_scene)
	if popup.has_signal("close_requested"):
		popup.close_requested.connect(hide_info)
	if popup.has_signal("ornament_link_requested"):
		popup.ornament_link_requested.connect(func(id: StringName) -> void: ornament_link_requested.emit(id))
	if popup.has_signal("mark_link_requested"):
		popup.mark_link_requested.connect(func(id: StringName) -> void: mark_link_requested.emit(id))
	if popup.has_signal("face_selected"):
		popup.face_selected.connect(func(face_index: int) -> void:
			install_face_selected.emit(_current_popup_die_index(), face_index)
		)
	if popup.has_signal("install_requested"):
		popup.install_requested.connect(func(face_index: int) -> void:
			install_requested.emit(_current_popup_die_index(), face_index)
		)
	popup.visible = false


func _position_popup(index: int) -> void:
	if popup == null:
		return
	var rect := _dice_global_rect(index)
	var width := minf(760.0, maxf(420.0, size.x - 48.0))
	var height := minf(620.0, maxf(320.0, size.y - 120.0))
	popup.size = Vector2(width, height)
	var local_center := get_global_transform_with_canvas().affine_inverse() * rect.get_center()
	popup.position = Vector2(
		clampf(local_center.x - width * 0.5, 18.0, maxf(18.0, size.x - width - 18.0)),
		24.0
	)
	if popup.has_method("set_tail_target_global_x"):
		popup.call("set_tail_target_global_x", rect.get_center().x)


func _ensure_reward_overlay() -> void:
	if reward_overlay != null:
		return
	reward_overlay = Control.new()
	reward_overlay.name = "RewardChoiceOverlay"
	reward_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reward_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	reward_overlay.z_index = 90
	add_child(reward_overlay)


func _make_reward_choice_card(choice) -> Control:
	var button := Button.new()
	button.custom_minimum_size = Vector2(300.0, 300.0)
	button.text = ""
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(func() -> void: reward_choice_pressed.emit(choice))
	if style_config != null:
		style_config.apply_button(button)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(box)

	var label := RichTextLabel.new()
	label.name = "RewardChoiceRichText"
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	var text := _choice_display_text(choice)
	RichTextHighlighter.setup_rich_label(
		label,
		_reward_text_to_bbcode(text),
		style_config.body_font_size if style_config != null else 18,
		Color(0.96, 0.92, 0.78),
		style_config.font if style_config != null else null
	)
	label.text = _reward_text_to_bbcode(text)
	if _reward_text_has_info_link(text):
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		label.meta_clicked.connect(_on_reward_info_meta_clicked)

	box.add_child(label)

	var pick_label := Label.new()
	pick_label.name = "RewardChoicePickLabel"
	pick_label.text = "挑选"
	pick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pick_label.custom_minimum_size = Vector2(0.0, 42.0)
	pick_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pick_label.add_theme_font_size_override("font_size", 24)
	pick_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.65, 1.0))
	if style_config != null and style_config.font != null:
		pick_label.add_theme_font_override("font", style_config.font)
	box.add_child(pick_label)
	return button


func _choice_display_text(choice) -> String:
	var object := choice as Object
	var lines := PackedStringArray()
	if object != null and object.has_method("get_display_name"):
		lines.append(str(object.call("get_display_name")))
	if object != null and object.has_method("get_description"):
		lines.append(str(object.call("get_description")))
	if object != null and object.has_method("get_effect_text"):
		lines.append(str(object.call("get_effect_text")))
	return "\n".join(lines) if not lines.is_empty() else str(choice)


func _reward_text_to_bbcode(text: String) -> String:
	var keywords := _reward_info_keywords()
	var result := PackedStringArray()
	var index := 0
	while index < text.length():
		var keyword := _reward_info_keyword_at(text, index, keywords)
		if not keyword.is_empty():
			result.append(_reward_info_link_bbcode(keyword))
			index += str(keyword["name"]).length()
			continue

		var next_index := index + 1
		while next_index < text.length() and _reward_info_keyword_at(text, next_index, keywords).is_empty():
			next_index += 1
		result.append(RichTextHighlighter.score_text_to_bbcode(text.substr(index, next_index - index)))
		index = next_index
	return "".join(result)


func _reward_text_has_info_link(text: String) -> bool:
	var keywords := _reward_info_keywords()
	for index in range(text.length()):
		if not _reward_info_keyword_at(text, index, keywords).is_empty():
			return true
	return false


func _reward_info_keyword_at(text: String, index: int, keywords: Array[Dictionary]) -> Dictionary:
	for keyword in keywords:
		var name := str(keyword["name"])
		if name == "" or index + name.length() > text.length():
			continue
		if text.substr(index, name.length()) == name:
			return keyword
	return {}


func _reward_info_keywords() -> Array[Dictionary]:
	var keywords: Array[Dictionary] = []
	for id in _reward_ornament_ids():
		_append_reward_info_keyword(keywords, &"ornament", id, DisplayNames.ornament_name(id))
	for id in _reward_mark_ids():
		_append_reward_info_keyword(keywords, &"mark", id, DisplayNames.mark_name(id))
	keywords.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a["name"]).length() > str(b["name"]).length()
	)
	return keywords


func _append_reward_info_keyword(keywords: Array[Dictionary], kind: StringName, id: StringName, display_name: String) -> void:
	if display_name == "":
		return
	for keyword in keywords:
		if str(keyword["name"]) == display_name and StringName(str(keyword["kind"])) == kind:
			return
	keywords.append({
		"kind": kind,
		"id": id,
		"name": display_name,
	})


func _reward_ornament_ids() -> Array[StringName]:
	return [
		FaceState.ORN_CHIP,
		FaceState.ORN_MULT,
		FaceState.ORN_WILD,
		FaceState.ORN_BURST,
		FaceState.ORN_STAY,
		FaceState.ORN_STONE,
		FaceState.ORN_GOLD,
		FaceState.ORN_LUCKY,
		FaceState.ORN_FOIL,
		FaceState.ORN_HOLO,
		FaceState.ORN_POLY,
	]


func _reward_mark_ids() -> Array[StringName]:
	return [
		FaceState.MARK_RED,
		FaceState.MARK_BLUE,
		FaceState.MARK_PURPLE,
		FaceState.MARK_GOLD,
		FaceState.MARK_WHITE,
		&"black",
	]


func _reward_info_link_bbcode(keyword: Dictionary) -> String:
	var kind := StringName(str(keyword["kind"]))
	var id := StringName(str(keyword["id"]))
	var display_name := str(keyword["name"])
	var color := style_config.info_link_text_color.to_html(false) if style_config != null else "ff9300"
	return "[url=%s:%s][u][color=#%s]%s[/color][/u][/url]" % [
		str(kind),
		str(id),
		color,
		_escape_bbcode(display_name),
	]


func _on_reward_info_meta_clicked(meta) -> void:
	var text := str(meta)
	if text.begins_with("ornament:"):
		reward_ornament_link_requested.emit(StringName(text.trim_prefix("ornament:")))
	elif text.begins_with("mark:"):
		reward_mark_link_requested.emit(StringName(text.trim_prefix("mark:")))


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "\\[").replace("]", "\\]")


func _make_floating_label(text: String) -> Control:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(160, 48)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if style_config != null:
		style_config.apply_label(label, style_config.score_font_size, Color(1.0, 0.86, 0.26))
	floating_layer.add_child(label)
	return label


func _position_floating(floating: Control, global_position: Vector2) -> void:
	var local_position := floating_layer.get_global_transform_with_canvas().affine_inverse() * global_position
	var floating_size := floating.get_combined_minimum_size()
	floating.position = local_position - floating_size * 0.5
	floating.size = floating_size


func _animate_and_free_floating(floating: Control) -> void:
	if floating == null:
		return
	var tween := create_tween()
	tween.tween_property(floating, "position:y", floating.position.y - 34.0, 0.65)
	tween.parallel().tween_property(floating, "modulate:a", 0.0, 0.65)
	await tween.finished
	if is_instance_valid(floating):
		floating.queue_free()


func _rebuild_resolution_markers() -> void:
	if marker_layer == null:
		return
	_clear_children(marker_layer)
	for index in range(resolution_die_indices.size()):
		var marker := Control.new()
		marker.name = "ResolutionMarker%d" % [index + 1]
		marker.set_meta("resolution_index", index)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker_layer.add_child(marker)


func _resolution_marker_at(index: int) -> Control:
	if marker_layer == null:
		return null
	for child in marker_layer.get_children():
		if child is Control and int(child.get_meta("resolution_index", -1)) == index:
			return child as Control
	return null


func _resolution_die_index_at(index: int) -> int:
	if index < 0 or index >= resolution_die_indices.size():
		return -1
	return resolution_die_indices[index]


func _dice_global_rect(index: int) -> Rect2:
	if dice_viewport == null or battle_mgr == null:
		return get_global_rect()
	if index < 0 or index >= battle_mgr.using_dices.size():
		return get_global_rect()
	var instance = battle_mgr.using_dices[index]
	if instance == null or instance.avatar == null or dice_viewport.fixed_camera == null:
		return get_global_rect()
	var avatar := instance.avatar as Node3D
	var viewport_position := dice_viewport.fixed_camera.unproject_position(avatar.global_position)
	var local_position := dice_viewport.viewport_to_container_position(viewport_position)
	var global_position := dice_viewport.get_global_transform_with_canvas() * local_position
	var side := 92.0 * maxf(0.6, dice_viewport.size.x / 1280.0)
	return Rect2(global_position - Vector2(side, side) * 0.5, Vector2(side, side))


func _avatar_index(avatar: Node) -> int:
	if battle_mgr == null:
		return -1
	for index in range(battle_mgr.using_dices.size()):
		var instance = battle_mgr.using_dices[index]
		if instance != null and instance.avatar == avatar:
			return index
	return -1


func _die_data_at(index: int) -> DieViewData:
	if current_state == null:
		return null
	for die_data in current_state.dice_results:
		if die_data != null and die_data.die_index == index:
			return die_data
	return null


func _current_popup_die_index() -> int:
	if popup_die_index >= 0:
		return popup_die_index
	return focused_die_index


func _roster_signature(state: BattleHudState) -> String:
	var parts := PackedStringArray()
	for die_data in state.dice_results:
		if die_data == null:
			continue
		parts.append("%d:%s:%d" % [die_data.die_index, str(die_data.die_id), die_data.face_count])
	return "|".join(parts)


func _face_state_signature(state: BattleHudState) -> String:
	var parts := PackedStringArray()
	for die_data in state.dice_results:
		if die_data == null:
			continue
		var pip := die_data.current_face.pip if die_data.current_face != null else 0
		parts.append("%d:%d:%d" % [die_data.die_index, die_data.current_face_index, pip])
	return "|".join(parts)


func _resolved_unselected_hold_tuning() -> Dictionary:
	var config := {
		"screen_x": 0.50,
		"screen_y": 0.84,
		"max_width": 8.00,
		"duration": 0.36,
	}
	if dice_viewport != null and dice_viewport.has_method("screen_point_to_world_on_y"):
		config["center_world_position"] = dice_viewport.call("screen_point_to_world_on_y", 0.50, 0.84, dice_initial_height)
	return config


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
