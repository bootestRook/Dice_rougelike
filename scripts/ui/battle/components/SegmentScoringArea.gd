extends PanelContainer
class_name SegmentScoringArea


const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")


var style_config: BattleUiStyleConfig = null
var score_log_row_scene: PackedScene = null
var floating_score_text_scene: PackedScene = null

@onready var margin: MarginContainer = %ScoringMargin
@onready var title_label: Label = %TitleLabel
@onready var stage_panel: PanelContainer = %StagePanel
@onready var settlement_slots: HBoxContainer = %SettlementSlots
@onready var preview_label: Label = %PreviewLabel
@onready var status_label: Label = %StatusLabel
@onready var log_rows: VBoxContainer = %LogRows
@onready var floating_layer: Control = %FloatingScoreLayer


func setup(
	new_style_config: BattleUiStyleConfig,
	new_score_log_row_scene: PackedScene,
	new_floating_score_text_scene: PackedScene
) -> void:
	style_config = new_style_config
	score_log_row_scene = new_score_log_row_scene
	floating_score_text_scene = new_floating_score_text_scene
	if is_node_ready():
		_apply_style()


func _ready() -> void:
	_apply_style()


func render(state: BattleHudState) -> void:
	if state == null:
		return

	status_label.text = state.status_text
	preview_label.text = _compact_preview(state.preview_text)
	_render_log(state.score_log)


func _apply_style() -> void:
	if not is_node_ready() or style_config == null:
		return
	add_theme_stylebox_override("panel", style_config.get_panel_style())
	stage_panel.add_theme_stylebox_override("panel", style_config.get_panel_style())
	style_config.apply_margin(margin, style_config.panel_padding)
	style_config.apply_label(title_label, style_config.title_font_size)
	style_config.apply_label(preview_label, style_config.small_font_size)
	style_config.apply_label(status_label, style_config.body_font_size)
	preview_label.clip_text = true
	preview_label.max_lines_visible = 2
	log_rows.add_theme_constant_override("separation", max(2, style_config.card_gap / 2))
	settlement_slots.add_theme_constant_override("separation", style_config.layout_gap)
	for slot in settlement_slots.get_children():
		if slot is PanelContainer:
			(slot as PanelContainer).add_theme_stylebox_override("panel", style_config.get_slot_style())


func _render_log(lines: Array[String]) -> void:
	_clear_children(log_rows)
	if lines.is_empty():
		_add_log_row("结算日志会显示在这里。")
		return

	for line in lines:
		_add_log_row(line)


func _add_log_row(text: String) -> void:
	var row := _make_log_row()
	log_rows.add_child(row)
	if row.has_method("render"):
		row.render(text, style_config)
	elif row is Label:
		row.text = text


func _compact_preview(text: String) -> String:
	var lines := text.split("\n", false)
	if lines.size() <= 2:
		return text
	return "%s\n%s" % [lines[0], lines[1]]


func _make_log_row() -> Control:
	if score_log_row_scene != null:
		var row := score_log_row_scene.instantiate()
		if row is Control:
			return row

	var fallback := Label.new()
	if style_config != null:
		style_config.apply_label(fallback, style_config.small_font_size)
	return fallback


func show_floating_score(text: String) -> void:
	if floating_score_text_scene == null:
		return
	var floating := floating_score_text_scene.instantiate()
	if not floating is Control:
		return
	floating_layer.add_child(floating)
	if floating.has_method("render"):
		floating.render(text, style_config)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
