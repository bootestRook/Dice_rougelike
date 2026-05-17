extends PanelContainer
class_name DiceBenchArea


const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")
const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleIconLibrary = preload("res://scripts/ui/battle/resources/BattleIconLibrary.gd")
const DiceVisualLibrary = preload("res://scripts/ui/battle/resources/DiceVisualLibrary.gd")


signal die_pressed(index: int)
signal die_hovered(index: int)
signal die_info_requested(index: int)
signal ornament_link_requested(id: StringName)
signal mark_link_requested(id: StringName)
signal reroll_pressed()
signal score_pressed()
signal install_face_selected(die_index: int, face_index: int)
signal install_requested(die_index: int, face_index: int)


var style_config: BattleUiStyleConfig = null
var icon_library: BattleIconLibrary = null
var dice_visual_library: DiceVisualLibrary = null
var dice_view_scene: PackedScene = null
var dice_info_popup_scene: PackedScene = null
var face_info_card_scene: PackedScene = null
var current_state: BattleHudState = null
var focused_die_index: int = 0
var popup_die_index: int = -1
var popup: Control = null
var pending_info_die_index: int = -1
var info_request_queued: bool = false
var hidden_die_indices: Array[int] = []
var highlighted_die_indices: Array[int] = []
var display_die_order: Array[int] = []
var dice_signature: String = ""
var is_sorting_dice: bool = false
var selection_counter_layer: Control = null
var selection_counter_label: Label = null
var install_mode_active: bool = false
var install_piece_name: String = ""

@onready var margin: MarginContainer = %BenchMargin
@onready var title_label: Label = %TitleLabel
@onready var hint_label: Label = %HintLabel
@onready var reroll_button: Button = %RerollButton
@onready var organize_button: Button = %OrganizeButton
@onready var score_button: Button = %ScoreButton
@onready var bench_overlay: Control = %BenchOverlay
@onready var dice_center: CenterContainer = $BenchMargin/Rows/BenchOverlay/DiceCenter
@onready var action_buttons_center: CenterContainer = $BenchMargin/Rows/BenchOverlay/ActionButtonsCenter
@onready var action_buttons_row: HBoxContainer = $BenchMargin/Rows/BenchOverlay/ActionButtonsCenter/ActionButtonsRow
@onready var dice_row: HBoxContainer = %DiceRow
@onready var popup_mount: CenterContainer = %PopupMount


func setup(
	new_style_config: BattleUiStyleConfig,
	new_icon_library: BattleIconLibrary,
	new_dice_visual_library: DiceVisualLibrary,
	new_dice_view_scene: PackedScene,
	new_dice_info_popup_scene: PackedScene,
	new_face_info_card_scene: PackedScene
) -> void:
	style_config = new_style_config
	icon_library = new_icon_library
	dice_visual_library = new_dice_visual_library
	dice_view_scene = new_dice_view_scene
	dice_info_popup_scene = new_dice_info_popup_scene
	face_info_card_scene = new_face_info_card_scene
	if is_node_ready():
		_apply_style()


func _ready() -> void:
	reroll_button.pressed.connect(func() -> void: reroll_pressed.emit())
	organize_button.pressed.connect(_on_organize_pressed)
	score_button.pressed.connect(func() -> void: score_pressed.emit())
	_ensure_selection_counter()
	_apply_selection_counter_style()
	_apply_style()


func render(state: BattleHudState) -> void:
	current_state = state
	if state == null:
		return

	hint_label.text = "%s  |  %s" % [state.phase_text, state.status_text]
	reroll_button.disabled = not state.can_reroll
	organize_button.disabled = install_mode_active or state.controls_locked or is_sorting_dice or _organize_disabled(state)
	score_button.disabled = not state.can_score
	_set_selection_counter_text(state)
	var next_signature := _dice_order_signature(state)
	if next_signature != dice_signature:
		dice_signature = next_signature
		display_die_order.clear()
	_render_dice(state.dice_results)

	if popup != null and popup.visible:
		show_info_for_die(focused_die_index)
	else:
		_update_info_focus()
		_update_viewing_title()


func show_info_for_selected_or_focused() -> void:
	if current_state == null or (current_state.controls_locked and not install_mode_active) or current_state.dice_results.is_empty():
		return
	var target_index := focused_die_index
	if not current_state.selected_dice_indices.is_empty():
		target_index = current_state.selected_dice_indices[current_state.selected_dice_indices.size() - 1]
	toggle_info_for_die(target_index)


func request_info_for_die(index: int) -> void:
	if current_state != null and current_state.controls_locked and not install_mode_active:
		return
	pending_info_die_index = index
	if info_request_queued:
		return
	info_request_queued = true
	call_deferred("_flush_info_request")


func _flush_info_request() -> void:
	info_request_queued = false
	var target_index := pending_info_die_index
	pending_info_die_index = -1
	if target_index < 0:
		return
	show_info_for_die(target_index)


func toggle_info_for_die(index: int) -> void:
	if popup != null and popup.visible and focused_die_index == index:
		hide_info()
		return
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
		popup.set_install_context(install_mode_active, install_piece_name)
	if popup.has_method("render"):
		popup.render(die_data)
	_position_popup(die_data)
	call_deferred("_position_popup", die_data)
	_update_info_focus()
	_update_viewing_title()


func hide_info() -> void:
	if popup != null:
		popup.visible = false
		if popup.has_method("clear_tail"):
			popup.clear_tail()
	popup_die_index = -1
	_update_info_focus()
	_update_viewing_title()


func set_install_mode(enabled: bool, piece_name: String = "") -> void:
	install_mode_active = enabled
	install_piece_name = piece_name
	if popup != null and popup.has_method("set_install_context"):
		popup.set_install_context(install_mode_active, install_piece_name)
		if popup.visible:
			show_info_for_die(focused_die_index)


func is_install_mode_active() -> bool:
	return install_mode_active


func is_info_visible() -> bool:
	return popup != null and popup.visible


func is_global_point_inside_info_popup(global_point: Vector2) -> bool:
	if popup == null or not popup.visible:
		return false
	var popup_rect := popup.get_global_rect()
	popup_rect.size.y += 32.0
	return popup_rect.has_point(global_point)


func _apply_style() -> void:
	if not is_node_ready() or style_config == null:
		return
	custom_minimum_size.y = style_config.bottom_dice_area_height
	add_theme_stylebox_override("panel", style_config.get_panel_style())
	style_config.apply_margin(margin, style_config.panel_padding)
	style_config.apply_label(title_label, style_config.title_font_size)
	style_config.apply_label(hint_label, style_config.small_font_size)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.visible = false
	hint_label.visible = false
	style_config.apply_button(reroll_button)
	style_config.apply_button(organize_button)
	style_config.apply_button(score_button)
	_position_dice_row_near_top()
	_position_action_buttons()
	_position_selection_counter()
	_apply_selection_counter_style()
	dice_row.add_theme_constant_override("separation", style_config.layout_gap)


func _position_dice_row_near_top() -> void:
	if dice_center == null or style_config == null:
		return
	var top_offset := -18.0
	var row_height := style_config.dice_display_size.y
	dice_center.anchor_left = 0.0
	dice_center.anchor_top = 0.0
	dice_center.anchor_right = 1.0
	dice_center.anchor_bottom = 0.0
	dice_center.offset_left = 0.0
	dice_center.offset_top = top_offset
	dice_center.offset_right = 0.0
	dice_center.offset_bottom = top_offset + row_height


func _position_action_buttons() -> void:
	if action_buttons_center == null or action_buttons_row == null or style_config == null:
		return

	var button_size := Vector2(124.0, 54.0)
	var top_offset := style_config.dice_display_size.y + 28.0
	for button in [reroll_button, organize_button, score_button]:
		button.custom_minimum_size = button_size
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reroll_button.text = str(TranslationServer.translate(&"AUTO.TEXT.332A22260969"))
	organize_button.text = str(TranslationServer.translate(&"AUTO.TEXT.BD63F469A7E6"))
	score_button.text = str(TranslationServer.translate(&"AUTO.TEXT.4C506E4EF106"))

	action_buttons_center.anchor_left = 0.0
	action_buttons_center.anchor_top = 0.0
	action_buttons_center.anchor_right = 1.0
	action_buttons_center.anchor_bottom = 0.0
	action_buttons_center.offset_left = 0.0
	action_buttons_center.offset_top = top_offset
	action_buttons_center.offset_right = 0.0
	action_buttons_center.offset_bottom = top_offset + button_size.y
	action_buttons_row.add_theme_constant_override("separation", 120)
	action_buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER


func _ensure_selection_counter() -> void:
	if selection_counter_layer != null or bench_overlay == null:
		return

	selection_counter_layer = Control.new()
	selection_counter_layer.name = "SelectionCounterLayer"
	selection_counter_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_counter_layer.visible = false
	selection_counter_layer.z_index = 2
	bench_overlay.add_child(selection_counter_layer)
	_position_selection_counter()

	selection_counter_label = Label.new()
	selection_counter_label.name = "SelectionCounterLabel"
	selection_counter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selection_counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selection_counter_layer.add_child(selection_counter_label)
	selection_counter_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _position_selection_counter() -> void:
	if selection_counter_layer == null:
		return
	var counter_size := Vector2(230.0, 44.0)
	selection_counter_layer.anchor_left = 1.0
	selection_counter_layer.anchor_top = 0.0
	selection_counter_layer.anchor_right = 1.0
	selection_counter_layer.anchor_bottom = 0.0
	selection_counter_layer.offset_left = -counter_size.x - 34.0
	selection_counter_layer.offset_top = 62.0
	selection_counter_layer.offset_right = -34.0
	selection_counter_layer.offset_bottom = 62.0 + counter_size.y


func _apply_selection_counter_style() -> void:
	_ensure_selection_counter()
	if selection_counter_label == null:
		return
	if style_config != null:
		style_config.apply_label(selection_counter_label, style_config.body_font_size, Color(0.95, 0.94, 0.86, 1.0))
	else:
		selection_counter_label.add_theme_font_size_override("font_size", 22)
		selection_counter_label.add_theme_color_override("font_color", Color(0.95, 0.94, 0.86, 1.0))
	selection_counter_label.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.04, 0.78))
	selection_counter_label.add_theme_constant_override("outline_size", 3)
	selection_counter_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	selection_counter_label.clip_text = true
	selection_counter_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _set_selection_counter_text(state: BattleHudState) -> void:
	_ensure_selection_counter()
	if selection_counter_layer == null or selection_counter_label == null:
		return
	if state == null or state.max_selected_dice <= 0:
		selection_counter_layer.visible = false
		return
	selection_counter_layer.visible = true
	selection_counter_label.text = str(TranslationServer.translate(&"AUTO.TEXT.34EB0A73B9C4")) % [
		state.selected_dice_indices.size(),
		state.max_selected_dice,
	]


func _render_dice(dice: Array[DieViewData]) -> void:
	_clear_children(dice_row)
	for die_data in _ordered_dice(dice):
		var view := _make_dice_view(die_data)
		view.set_meta("die_index", die_data.die_index)
		dice_row.add_child(view)
		if view.has_method("render"):
			view.render(die_data, style_config, icon_library, dice_visual_library)
		if view.has_signal("die_pressed"):
			view.die_pressed.connect(_on_die_view_pressed)
		if view.has_signal("die_hovered"):
			view.die_hovered.connect(_on_die_view_hovered)
		if view.has_signal("die_info_requested"):
			view.die_info_requested.connect(_on_die_info_requested)
		_apply_die_view_transient_state(view, die_data.die_index)
	_update_info_focus()


func _on_organize_pressed() -> void:
	if current_state == null or is_sorting_dice:
		return
	if current_state.controls_locked:
		return

	var sorted_order := _sorted_die_order(current_state.dice_results)
	if sorted_order.is_empty():
		return
	if _same_int_order(_current_display_order(), sorted_order):
		display_die_order = sorted_order
		return

	var old_rects := _current_die_global_rects()
	var clones := _make_sort_animation_clones(old_rects)
	display_die_order = sorted_order
	is_sorting_dice = true
	organize_button.disabled = true
	_render_dice(current_state.dice_results)
	_set_current_die_views_visible(false)
	await get_tree().process_frame

	var new_rects := _current_die_global_rects()
	await _play_sort_animation(clones, new_rects)
	is_sorting_dice = false
	_set_current_die_views_visible(true)
	organize_button.disabled = _organize_disabled(current_state)
	_apply_transient_states_to_current_views()


func _ordered_dice(dice: Array[DieViewData]) -> Array[DieViewData]:
	var result: Array[DieViewData] = []
	if display_die_order.is_empty():
		result.append_array(dice)
		return result

	var by_index: Dictionary = {}
	for die_data in dice:
		if die_data != null:
			by_index[die_data.die_index] = die_data
	for die_index in display_die_order:
		if by_index.has(die_index):
			result.append(by_index[die_index])
			by_index.erase(die_index)
	for die_data in dice:
		if die_data != null and by_index.has(die_data.die_index):
			result.append(die_data)
			by_index.erase(die_data.die_index)
	return result


func _sorted_die_order(dice: Array[DieViewData]) -> Array[int]:
	var sorted: Array[DieViewData] = []
	for die_data in dice:
		if die_data != null:
			sorted.append(die_data)
	sorted.sort_custom(func(a: DieViewData, b: DieViewData) -> bool:
		var pip_a := _current_pip(a)
		var pip_b := _current_pip(b)
		if pip_a == pip_b:
			return a.die_index < b.die_index
		return pip_a > pip_b
	)

	var order: Array[int] = []
	for die_data in sorted:
		order.append(die_data.die_index)
	return order


func _current_pip(die_data: DieViewData) -> int:
	if die_data == null or die_data.current_face == null:
		return -1
	return die_data.current_face.pip


func _current_display_order() -> Array[int]:
	var order: Array[int] = []
	for child in dice_row.get_children():
		if child is Control:
			order.append(int(child.get_meta("die_index", -1)))
	return order


func _current_die_global_rects() -> Dictionary:
	var rects: Dictionary = {}
	for child in dice_row.get_children():
		if not child is Control:
			continue
		var view := child as Control
		var die_index := int(view.get_meta("die_index", -1))
		if die_index >= 0:
			rects[die_index] = view.get_global_rect()
	return rects


func _make_sort_animation_clones(old_rects: Dictionary) -> Array[Control]:
	var clones: Array[Control] = []
	if current_state == null:
		return clones

	for die_data in _ordered_dice(current_state.dice_results):
		if die_data == null or not old_rects.has(die_data.die_index):
			continue
		var rect := old_rects[die_data.die_index] as Rect2
		var clone := _make_dice_view(die_data)
		clone.set_meta("die_index", die_data.die_index)
		clone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clone.z_index = 80
		bench_overlay.add_child(clone)
		if clone.has_method("render"):
			clone.render(die_data, style_config, icon_library, dice_visual_library)
		clone.global_position = rect.position
		clone.size = rect.size
		clones.append(clone)
	return clones


func _play_sort_animation(clones: Array[Control], new_rects: Dictionary) -> void:
	if clones.is_empty():
		return

	var tween := create_tween()
	tween.set_parallel(true)
	for clone in clones:
		var die_index := int(clone.get_meta("die_index", -1))
		if new_rects.has(die_index):
			var target_rect := new_rects[die_index] as Rect2
			tween.tween_property(clone, "global_position", target_rect.position, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	for clone in clones:
		clone.queue_free()


func _set_current_die_views_visible(value: bool) -> void:
	for child in dice_row.get_children():
		if child is Control:
			(child as Control).modulate.a = 1.0 if value else 0.0


func _same_int_order(a: Array[int], b: Array[int]) -> bool:
	if a.size() != b.size():
		return false
	for index in range(a.size()):
		if a[index] != b[index]:
			return false
	return true


func _dice_order_signature(state: BattleHudState) -> String:
	if state == null:
		return ""

	var parts := PackedStringArray()
	parts.append("hand:%d" % [state.current_hand])
	for die_data in state.dice_results:
		if die_data == null:
			continue
		parts.append("%d:%s:%d" % [die_data.die_index, str(die_data.die_id), die_data.face_count])
	return "|".join(parts)


func _organize_disabled(state: BattleHudState) -> bool:
	if state == null or state.dice_results.is_empty():
		return true
	for die_data in state.dice_results:
		if die_data != null and not die_data.disabled:
			return false
	return true


func set_hidden_die_indices(indices: Array[int]) -> void:
	hidden_die_indices = indices.duplicate()
	_apply_transient_states_to_current_views()


func clear_hidden_die_indices() -> void:
	hidden_die_indices.clear()
	_apply_transient_states_to_current_views()


func set_highlighted_die_indices(indices: Array[int]) -> void:
	highlighted_die_indices = indices.duplicate()
	_apply_transient_states_to_current_views()


func clear_highlights() -> void:
	highlighted_die_indices.clear()
	_apply_transient_states_to_current_views()


func get_die_view_global_rect(index: int) -> Rect2:
	var die_view := _die_view_at(index)
	if die_view == null:
		return Rect2()
	return die_view.get_global_rect()


func get_die_magic_fx_global_rect(index: int) -> Rect2:
	var die_view := _die_view_at(index)
	if die_view == null:
		return Rect2()
	if die_view.has_method("get_magic_fx_global_rect"):
		return die_view.get_magic_fx_global_rect()
	return die_view.get_global_rect()


func get_display_die_order() -> Array[int]:
	var order := _current_display_order()
	if not order.is_empty():
		return order
	if not display_die_order.is_empty():
		return display_die_order.duplicate()

	var fallback: Array[int] = []
	if current_state == null:
		return fallback
	for die_data in current_state.dice_results:
		if die_data != null:
			fallback.append(die_data.die_index)
	return fallback


func reset_display_order() -> void:
	display_die_order.clear()
	dice_signature = ""
	if current_state != null:
		_render_dice(current_state.dice_results)
	_apply_transient_states_to_current_views()


func _make_dice_view(die_data: DieViewData) -> Control:
	if dice_view_scene != null:
		var view := dice_view_scene.instantiate()
		if view is Control:
			return view

	var fallback := Button.new()
	fallback.text = str(TranslationServer.translate(&"AUTO.TEXT.F5833D7A3D75")) % [die_data.die_index + 1]
	fallback.pressed.connect(_on_die_view_pressed.bind(die_data.die_index))
	return fallback


func _ensure_popup() -> void:
	if popup != null:
		return
	if dice_info_popup_scene == null:
		return
	var instance := dice_info_popup_scene.instantiate()
	if not instance is Control:
		return
	popup = instance
	bench_overlay.add_child(popup)
	popup.z_index = 50
	if popup.has_method("setup"):
		popup.setup(style_config, icon_library, face_info_card_scene)
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


func _position_popup(die_data: DieViewData) -> void:
	if popup == null or dice_row == null:
		return

	var padding := style_config.panel_padding if style_config != null else 12
	var gap := style_config.layout_gap if style_config != null else 12
	var min_size := popup.get_combined_minimum_size()
	var face_count := die_data.faces.size() if die_data != null else 6
	var columns := mini(3, max(1, face_count)) if face_count <= 6 else 4
	var rows := ceili(float(face_count) / float(max(1, columns)))
	var card_size := style_config.face_card_size if style_config != null else Vector2(176, 210)
	var calculated_width := float(columns) * card_size.x + float(max(0, columns - 1) * gap) + float(padding * 2)
	var calculated_height := float(rows) * card_size.y + float(max(0, rows - 1) * gap) + float(padding * 2 + 120)
	var overlay_size := bench_overlay.size
	var popup_width: float = minf(maxf(min_size.x, calculated_width), max(320.0, overlay_size.x - float(padding * 2)))
	var popup_height: float = minf(maxf(min_size.y, calculated_height), _max_popup_height_above_bench(gap))
	popup.size = Vector2(popup_width, popup_height)

	var target_x := overlay_size.x * 0.5
	var die_view := _die_view_at(die_data.die_index)
	if die_view != null:
		target_x = _control_center_in_bench_local(die_view).x
	var min_x := float(padding)
	var max_x := maxf(min_x, overlay_size.x - popup_width - float(padding))
	var popup_x := clampf(target_x - popup_width * 0.5, min_x, max_x)
	var popup_y := maxf(_viewport_top_in_bench_local_y(float(padding)), -popup_height - float(gap))

	popup.position = Vector2(
		popup_x,
		popup_y
	)
	_set_popup_tail_to_die(die_data.die_index)
	call_deferred("_set_popup_tail_to_die", die_data.die_index)


func _max_popup_height_above_bench(gap: int) -> float:
	if bench_overlay == null:
		return 560.0

	var top_y := _viewport_top_in_bench_local_y(float(style_config.panel_padding if style_config != null else 12))
	var available_local := -float(gap) - top_y
	return maxf(260.0, available_local)


func _viewport_top_in_bench_local_y(top_padding: float = 0.0) -> float:
	if bench_overlay == null:
		return -560.0
	var viewport_top := 0.0
	if get_viewport() != null:
		viewport_top = get_viewport().get_visible_rect().position.y
	var local_point := bench_overlay.get_global_transform_with_canvas().affine_inverse() * Vector2(0.0, viewport_top + top_padding)
	return local_point.y


func _control_center_in_bench_local(control: Control) -> Vector2:
	if control == null or bench_overlay == null:
		return bench_overlay.size * 0.5 if bench_overlay != null else Vector2.ZERO
	var canvas_center := control.get_global_transform_with_canvas() * (control.size * 0.5)
	return bench_overlay.get_global_transform_with_canvas().affine_inverse() * canvas_center


func _die_data_at(index: int) -> DieViewData:
	if current_state == null:
		return null
	for die_data in current_state.dice_results:
		if die_data.die_index == index:
			return die_data
	return null


func _current_popup_die_index() -> int:
	if popup_die_index >= 0:
		return popup_die_index
	return focused_die_index


func _on_die_view_pressed(index: int) -> void:
	focused_die_index = index
	die_pressed.emit(index)


func _on_die_view_hovered(index: int) -> void:
	if popup == null or not popup.visible:
		focused_die_index = index
	die_hovered.emit(index)


func _on_die_info_requested(index: int) -> void:
	focused_die_index = index
	die_info_requested.emit(index)


func _die_view_at(index: int) -> Control:
	for child in dice_row.get_children():
		if not child is Control:
			continue
		if int(child.get_meta("die_index", -1)) == index:
			return child as Control
	return null


func _apply_transient_states_to_current_views() -> void:
	for child in dice_row.get_children():
		if child is Control:
			_apply_die_view_transient_state(child as Control, int(child.get_meta("die_index", -1)))


func _apply_die_view_transient_state(view: Control, die_index: int) -> void:
	if view == null:
		return
	var hidden := hidden_die_indices.has(die_index)
	var highlighted := highlighted_die_indices.has(die_index)
	view.modulate = Color(1, 1, 1, 0.0) if hidden else (Color(1.0, 0.92, 0.45, 1.0) if highlighted else Color.WHITE)
	view.scale = Vector2(1.04, 1.04) if highlighted and not hidden else Vector2.ONE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE if hidden else Control.MOUSE_FILTER_STOP


func _set_popup_tail_to_die(index: int) -> void:
	if popup == null or not popup.visible or not popup.has_method("set_tail_target_global_x"):
		return
	var die_view := _die_view_at(index)
	if die_view == null:
		return
	var canvas_center := die_view.get_global_transform_with_canvas() * (die_view.size * 0.5)
	popup.set_tail_target_global_x(canvas_center.x)


func _update_info_focus() -> void:
	var has_visible_popup := popup != null and popup.visible
	for child in dice_row.get_children():
		if child.has_method("set_info_focused"):
			child.set_info_focused(has_visible_popup and int(child.get_meta("die_index", -1)) == focused_die_index)


func _update_viewing_title() -> void:
	title_label.visible = false
	if popup != null and popup.visible:
		title_label.text = str(TranslationServer.translate(&"AUTO.TEXT.32D3EE340AE5")) % [focused_die_index + 1]
	else:
		title_label.text = str(TranslationServer.translate(&"AUTO.TEXT.F490EA5EF76E"))


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
