extends Control
class_name ComboInfoPopup


const ComboInfoRowData = preload("res://scripts/ui/battle/view_models/ComboInfoRowData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")


signal close_requested()


enum InfoTab {
	COMBO,
	ORNAMENT,
	MARK,
}


var style_config: BattleUiStyleConfig = null
var combo_info_row_scene: PackedScene = null
var combo_rows: Array[ComboInfoRowData] = []
var selected_ornament_id: StringName = &""
var selected_mark_id: StringName = &""
var current_tab: int = InfoTab.COMBO

@onready var scrim: ColorRect = %Scrim
@onready var window_panel: PanelContainer = %WindowPanel
@onready var popup_margin: MarginContainer = %PopupMargin
@onready var title_label: Label = %TitleLabel
@onready var info_tabs: TabBar = %InfoTabs
@onready var combo_header: HBoxContainer = %Header
@onready var header_level: Label = %HeaderLevel
@onready var header_combo: Label = %HeaderCombo
@onready var header_formula: Label = %HeaderFormula
@onready var header_count: Label = %HeaderCount
@onready var row_scroll: ScrollContainer = %RowScroll
@onready var rows_container: VBoxContainer = %RowsContainer
@onready var info_scroll: ScrollContainer = %InfoScroll
@onready var info_rows_container: VBoxContainer = %InfoRowsContainer
@onready var return_button: Button = %ReturnButton


func setup(new_style_config: BattleUiStyleConfig, new_combo_info_row_scene: PackedScene) -> void:
	style_config = new_style_config
	combo_info_row_scene = new_combo_info_row_scene
	if is_node_ready():
		_apply_style()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	return_button.pressed.connect(func() -> void: close_requested.emit())
	info_tabs.tab_changed.connect(_on_tab_changed)
	_apply_style()
	_apply_tab()


func render(rows: Array[ComboInfoRowData]) -> void:
	combo_rows = rows.duplicate()
	current_tab = InfoTab.COMBO
	_apply_style()
	_render_combo_rows()
	_apply_tab()


func show_ornament_tab(ornament_id: StringName) -> void:
	selected_ornament_id = FaceState.normalize_ornament_id(ornament_id)
	current_tab = InfoTab.ORNAMENT
	_apply_style()
	_render_effect_rows()
	_apply_tab()


func show_mark_tab(mark_id: StringName) -> void:
	selected_mark_id = FaceState.normalize_mark_id(mark_id)
	current_tab = InfoTab.MARK
	_apply_style()
	_render_effect_rows()
	_apply_tab()


func _on_tab_changed(tab: int) -> void:
	current_tab = tab
	if current_tab == InfoTab.COMBO:
		_render_combo_rows()
	else:
		_render_effect_rows()
	_apply_tab()


func _apply_tab() -> void:
	if not is_node_ready():
		return
	info_tabs.current_tab = current_tab
	var combo_visible := current_tab == InfoTab.COMBO
	combo_header.visible = combo_visible
	row_scroll.visible = combo_visible
	info_scroll.visible = not combo_visible
	match current_tab:
		InfoTab.ORNAMENT:
			title_label.text = "面饰信息"
		InfoTab.MARK:
			title_label.text = "印记信息"
		_:
			title_label.text = "骰型信息"


func _render_combo_rows() -> void:
	_clear_children(rows_container)
	for row_data in combo_rows:
		var row := _make_combo_row()
		rows_container.add_child(row)
		if row.has_method("render"):
			row.render(row_data, style_config)


func _render_effect_rows() -> void:
	_clear_children(info_rows_container)
	var rows := _ornament_rows() if current_tab == InfoTab.ORNAMENT else _mark_rows()
	for row in rows:
		info_rows_container.add_child(_make_effect_row(
			StringName(row["id"]),
			str(row["name"]),
			str(row["effect"]),
			bool(row["selected"])
		))


func _apply_style() -> void:
	if not is_node_ready() or style_config == null:
		return
	scrim.color = style_config.modal_scrim_color
	window_panel.custom_minimum_size = style_config.combo_info_popup_size
	window_panel.add_theme_stylebox_override("panel", style_config.get_popup_style())
	style_config.apply_margin(popup_margin, style_config.panel_padding * 2)
	style_config.apply_label(title_label, style_config.title_font_size)
	for label in [header_level, header_combo, header_formula, header_count]:
		style_config.apply_label(label, style_config.small_font_size)
	style_config.apply_button(return_button)
	if style_config.options_button_background != null:
		for state in ["normal", "hover", "pressed", "focus"]:
			return_button.add_theme_stylebox_override(state, style_config.options_button_background)
	rows_container.add_theme_constant_override("separation", max(4, style_config.card_gap / 2))
	info_rows_container.add_theme_constant_override("separation", max(6, style_config.card_gap / 2))


func _make_combo_row() -> Control:
	if combo_info_row_scene != null:
		var row := combo_info_row_scene.instantiate()
		if row is Control:
			return row
	var fallback := Label.new()
	fallback.text = "骰型"
	return fallback


func _make_effect_row(id: StringName, display_name: String, effect_text: String, selected: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 78)
	if style_config != null:
		panel.add_theme_stylebox_override(
			"panel",
			style_config.get_selected_style() if selected else style_config.get_combo_info_row_style()
		)

	var margin := MarginContainer.new()
	if style_config != null:
		style_config.apply_margin(margin, max(8, style_config.panel_padding - 2))
	panel.add_child(margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	margin.add_child(columns)

	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(170, 0)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text = display_name
	columns.add_child(name_label)

	var effect_label := Label.new()
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.text = effect_text
	columns.add_child(effect_label)

	if style_config != null:
		style_config.apply_label(name_label, style_config.body_font_size, style_config.info_link_text_color if selected else style_config.combo_info_row_text_color)
		var effect_color := style_config.combo_info_soft_text_color if selected else style_config.combo_info_row_text_color
		style_config.apply_label(effect_label, style_config.small_font_size, effect_color)

	panel.tooltip_text = "%s\n%s\nid: %s" % [display_name, effect_text, str(id)]
	return panel


func _ornament_rows() -> Array[Dictionary]:
	var ids: Array[StringName] = [
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
	var rows: Array[Dictionary] = []
	for id in ids:
		rows.append({
			"id": id,
			"name": DisplayNames.ornament_name(id),
			"effect": DisplayNames.ornament_effect_text(id),
			"selected": selected_ornament_id != &"" and FaceState.normalize_ornament_id(id) == selected_ornament_id,
		})
	return rows


func _mark_rows() -> Array[Dictionary]:
	var ids: Array[StringName] = [
		FaceState.MARK_RED,
		FaceState.MARK_BLUE,
		FaceState.MARK_PURPLE,
		FaceState.MARK_GOLD,
		FaceState.MARK_WHITE,
		&"black",
	]
	var rows: Array[Dictionary] = []
	for id in ids:
		rows.append({
			"id": id,
			"name": DisplayNames.mark_name(id),
			"effect": DisplayNames.mark_effect_text(id),
			"selected": selected_mark_id != &"" and FaceState.normalize_mark_id(id) == selected_mark_id,
		})
	return rows


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
