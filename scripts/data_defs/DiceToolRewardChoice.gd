extends RefCounted
class_name DiceToolRewardChoice


const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")


var id: StringName = &""
var display_name: String = ""
var description: String = ""
var effect_text: String = ""
var rarity: StringName = &"common"
var source_note: String = "骰具道具"


static func from_tool_data(data: Dictionary, new_source_note: String = "骰具道具") -> DiceToolRewardChoice:
	var choice := DiceToolRewardChoice.new()
	choice.id = StringName(str(data.get("id", &"")))
	choice.display_name = str(data.get("name", choice.id))
	choice.rarity = StringName(str(data.get("rarity", &"common")))
	choice.description = "获得后进入道具槽，使用后才会安装为骰具。"
	choice.effect_text = "效果：%s" % [str(data.get("effect_text", ""))]
	choice.source_note = new_source_note
	return choice


func get_display_name() -> String:
	return display_name if display_name != "" else str(id)


func get_description() -> String:
	return description


func get_effect_text() -> String:
	return effect_text


func get_rarity() -> StringName:
	return rarity


func get_rarity_display_name() -> String:
	return DisplayNames.rarity_name(rarity)


func get_tags_display_text() -> String:
	return source_note
