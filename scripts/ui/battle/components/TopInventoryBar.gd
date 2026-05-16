extends HBoxContainer
class_name TopInventoryBar


const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")
const SlotViewData = preload("res://scripts/ui/battle/view_models/SlotViewData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleIconLibrary = preload("res://scripts/ui/battle/resources/BattleIconLibrary.gd")


var style_config: BattleUiStyleConfig = null
var icon_library: BattleIconLibrary = null
var slot_scene: PackedScene = null

@onready var relic_panel: PanelContainer = %RelicPanel
@onready var item_panel: PanelContainer = %ItemPanel
@onready var relic_title: Label = %RelicTitle
@onready var item_title: Label = %ItemTitle
@onready var relic_capacity_label: Label = %RelicCapacityLabel
@onready var item_capacity_label: Label = %ItemCapacityLabel
@onready var relic_slots: HBoxContainer = %RelicSlots
@onready var item_slots: HBoxContainer = %ItemSlots


func setup(
	new_style_config: BattleUiStyleConfig,
	new_icon_library: BattleIconLibrary,
	new_slot_scene: PackedScene
) -> void:
	style_config = new_style_config
	icon_library = new_icon_library
	slot_scene = new_slot_scene
	if is_node_ready():
		_apply_style()


func _ready() -> void:
	_apply_style()


func render(state: BattleHudState) -> void:
	if state == null:
		return
	_render_slots(relic_slots, state.relics, state.relic_capacity, &"relic")
	_render_slots(item_slots, state.items, state.item_capacity, &"item")
	relic_capacity_label.text = "%d / %d" % [min(state.relics.size(), state.relic_capacity), state.relic_capacity]
	item_capacity_label.text = "%d / %d" % [min(state.items.size(), state.item_capacity), state.item_capacity]


func _apply_style() -> void:
	if not is_node_ready() or style_config == null:
		return
	custom_minimum_size.y = style_config.top_inventory_bar_height
	add_theme_constant_override("separation", style_config.layout_gap)
	for panel in [relic_panel, item_panel]:
		panel.add_theme_stylebox_override("panel", style_config.get_panel_style())
	for label in [relic_title, item_title]:
		style_config.apply_label(label, style_config.title_font_size)
	for label in [relic_capacity_label, item_capacity_label]:
		style_config.apply_label(label, style_config.body_font_size)
	for slots in [relic_slots, item_slots]:
		slots.add_theme_constant_override("separation", style_config.card_gap)


func _render_slots(container: HBoxContainer, slots: Array[SlotViewData], capacity: int, category: StringName) -> void:
	_clear_children(container)
	for index in range(capacity):
		var slot_data = slots[index] if index < slots.size() else _empty_slot_data()
		var slot_view := _make_slot_view()
		container.add_child(slot_view)
		if slot_view.has_method("render"):
			slot_view.render(slot_data, icon_library, style_config, category)


func _make_slot_view() -> Control:
	if slot_scene != null:
		var slot := slot_scene.instantiate()
		if slot is Control:
			return slot
	var fallback := PanelContainer.new()
	if style_config != null:
		fallback.custom_minimum_size = style_config.inventory_slot_size
		fallback.add_theme_stylebox_override("panel", style_config.get_slot_style())
	return fallback


func _empty_slot_data():
	var slot_data = SlotViewData.new()
	slot_data.setup_empty()
	return slot_data


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
