extends PanelContainer
class_name InventorySlotView


const SlotViewData = preload("res://scripts/ui/battle/view_models/SlotViewData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleIconLibrary = preload("res://scripts/ui/battle/resources/BattleIconLibrary.gd")


@onready var icon_rect: TextureRect = %IconRect
@onready var count_label: Label = %CountLabel
@onready var name_label: Label = %NameLabel


func render(slot_data: SlotViewData, icon_library: BattleIconLibrary, style_config: BattleUiStyleConfig, icon_category: StringName) -> void:
	if style_config != null:
		add_theme_stylebox_override("panel", style_config.get_slot_style())
		custom_minimum_size = style_config.inventory_slot_size
		style_config.apply_label(count_label, style_config.small_font_size)
		style_config.apply_label(name_label, style_config.small_font_size)
		icon_rect.custom_minimum_size = style_config.icon_size

	if slot_data == null or slot_data.empty:
		icon_rect.texture = null
		icon_rect.visible = false
		count_label.text = ""
		name_label.text = ""
		tooltip_text = ""
		return

	icon_rect.visible = true
	icon_rect.texture = icon_library.get_icon(icon_category, slot_data.icon_id) if icon_library != null else null
	name_label.text = slot_data.display_name
	count_label.text = str(slot_data.count) if slot_data.count > 1 else ""
	tooltip_text = slot_data.tooltip if slot_data.tooltip != "" else slot_data.display_name
