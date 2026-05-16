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


var style_config: BattleUiStyleConfig = null
var icon_library: BattleIconLibrary = null
var dice_visual_library: DiceVisualLibrary = null
var dice_view_scene: PackedScene = null
var dice_info_popup_scene: PackedScene = null
var face_info_card_scene: PackedScene = null
var current_state: BattleHudState = null
var focused_die_index: int = 0
var popup: Control = null
var pending_info_die_index: int = -1
var info_request_queued: bool = false

@onready var margin: MarginContainer = %BenchMargin
@onready var title_label: Label = %TitleLabel
@onready var hint_label: Label = %HintLabel
@onready var reroll_button: Button = %RerollButton
@onready var score_button: Button = %ScoreButton
@onready var bench_overlay: Control = %BenchOverlay
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
	score_button.pressed.connect(func() -> void: score_pressed.emit())
	_apply_style()


func render(state: BattleHudState) -> void:
	current_state = state
	if state == null:
		return

	hint_label.text = "%s  |  %s" % [state.phase_text, state.status_text]
	reroll_button.disabled = not state.can_reroll
	score_button.disabled = not state.can_score
	_render_dice(state.dice_results)

	if popup != null and popup.visible:
		show_info_for_die(focused_die_index)
	else:
		_update_info_focus()
		_update_viewing_title()


func show_info_for_selected_or_focused() -> void:
	if current_state == null or current_state.dice_results.is_empty():
		return
	var target_index := focused_die_index
	if not current_state.selected_dice_indices.is_empty():
		target_index = current_state.selected_dice_indices[current_state.selected_dice_indices.size() - 1]
	toggle_info_for_die(target_index)


func request_info_for_die(index: int) -> void:
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
	_ensure_popup()
	if popup == null:
		return
	popup.visible = true
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
	_update_info_focus()
	_update_viewing_title()


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
	hint_label.visible = false
	style_config.apply_button(reroll_button)
	style_config.apply_button(score_button)
	dice_row.add_theme_constant_override("separation", style_config.layout_gap)


func _render_dice(dice: Array[DieViewData]) -> void:
	_clear_children(dice_row)
	for die_data in dice:
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
	_update_info_focus()


func _make_dice_view(die_data: DieViewData) -> Control:
	if dice_view_scene != null:
		var view := dice_view_scene.instantiate()
		if view is Control:
			return view

	var fallback := Button.new()
	fallback.text = "骰子 %d" % [die_data.die_index + 1]
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
	if popup != null and popup.visible:
		title_label.text = "骰子备战区 · 正在查看骰子 %d" % [focused_die_index + 1]
	else:
		title_label.text = "骰子备战区"


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
