extends RefCounted
class_name MapEventChoice


var id: StringName = &""
var event_id: StringName = &""
var event_name: String = ""
var event_type_display_name: String = ""
var scene_text: String = ""
var npc_text: String = ""
var event_type: StringName = &""
var option_id: StringName = &""
var option_label: String = ""
var display_name: String = ""
var description: String = ""
var effect_text: String = ""
var effect_id: StringName = &""
var effect_args: Dictionary = {}
var rarity: StringName = &"common"
var tags: Array[StringName] = []


static func from_data(event_def: Dictionary, option_def: Dictionary, first_protected_segment: bool = false):
	var choice = load("res://scripts/data_defs/MapEventChoice.gd").new()
	choice.event_id = StringName(str(event_def.get("id", &"")))
	choice.event_name = str(event_def.get("name", "奇遇"))
	choice.event_type_display_name = str(event_def.get("type_display_name", "奇遇"))
	choice.scene_text = str(event_def.get("scene_text", ""))
	choice.npc_text = str(event_def.get("npc_text", ""))
	choice.event_type = StringName(str(event_def.get("type", &"")))
	choice.option_id = StringName(str(option_def.get("id", &"")))
	choice.id = StringName("%s:%s" % [str(choice.event_id), str(choice.option_id)])
	choice.option_label = str(option_def.get("label", ""))
	choice.display_name = "%s：%s" % [choice.event_name, choice.option_label]
	choice.description = str(option_def.get("description", event_def.get("summary", "")))
	choice.effect_text = str(option_def.get("effect_text", ""))
	choice.effect_id = StringName(str(option_def.get("effect_id", &"")))
	choice.effect_args = Dictionary(option_def.get("args", {})).duplicate(true)
	if first_protected_segment and option_def.has("first_protected_args"):
		for key in Dictionary(option_def.get("first_protected_args", {})).keys():
			choice.effect_args[key] = Dictionary(option_def.get("first_protected_args", {}))[key]
	choice.rarity = StringName(str(option_def.get("rarity", "common")))
	for tag in option_def.get("tags", []):
		choice.tags.append(StringName(str(tag)))
	return choice


func get_event_title() -> String:
	return event_name


func get_event_type_display_name() -> String:
	return event_type_display_name


func get_scene_text() -> String:
	return scene_text


func get_npc_text() -> String:
	return npc_text


func get_button_text() -> String:
	return "【%s】" % [option_label]


func get_display_name() -> String:
	return display_name


func get_description() -> String:
	return description


func get_effect_text() -> String:
	return effect_text


func get_rarity_display_name() -> String:
	match rarity:
		&"common":
			return "普通"
		&"uncommon":
			return "进阶"
		&"rare":
			return "稀有"
		&"epic":
			return "史诗"
		&"legendary":
			return "传奇"
		_:
			return "普通"


func get_tags_display_text() -> String:
	if tags.is_empty():
		return "奇遇"
	var names := PackedStringArray()
	for tag in tags:
		names.append(_tag_name(tag))
	return " / ".join(names)


func _tag_name(tag: StringName) -> String:
	match tag:
		&"positive_reward":
			return "正向奖励"
		&"trade":
			return "代价交易"
		&"risk":
			return "风险赌局"
		&"penalty":
			return "轻惩罚"
		&"map":
			return "地图情报"
		&"boss":
			return "首领对策"
		&"build":
			return "流派定向"
		&"coins":
			return "金币"
		&"forge_piece":
			return "铸骰件"
		&"dice_tool":
			return "骰具"
		&"combo":
			return "主骰型"
		&"battle_modifier":
			return "战斗调整"
		&"shop":
			return "商店"
		&"copy":
			return "复制"
		&"clear_face":
			return "清理"
		_:
			return "奇遇"


func is_available(run_state) -> bool:
	return get_unavailable_reason(run_state) == ""


func get_unavailable_reason(run_state) -> String:
	if run_state == null:
		return ""
	var cost := int(effect_args.get("cost", 0))
	var min_coins := int(effect_args.get("min_coins", 0))
	if cost > 0 and int(run_state.get("coins")) < cost:
		return "金币不足"
	if min_coins > 0 and int(run_state.get("coins")) < min_coins:
		return "金币不足"
	match effect_id:
		&"replace_dice_tool", &"sell_dice_tool":
			if run_state.get("dice_tools").is_empty():
				return "没有可用骰具遗物"
		_:
			pass
	return ""
