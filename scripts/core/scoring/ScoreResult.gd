extends RefCounted
class_name ScoreResult


const BattleLogEntry = preload("res://scripts/log/BattleLogEntry.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")


var chips: int = 0
var mult: int = 1
var xmult: float = 1.0
var final_score: int = 0
var coins_delta: int = 0
var primary_combo: StringName = &""
var combo_id: StringName = &""
var combo_name_key: StringName = &""
var combo_level: int = 1
var combo_chips_bonus: int = 0
var combo_mult: int = 1
var scored_point_sum: int = 0
var display_combo_ids: Array[StringName] = []
var contained_patterns: Array[StringName] = []
var facts: Dictionary = {}
var active_tags: Array[StringName] = []
var tags: Array[StringName] = []
var logs: Array[BattleLogEntry] = []
var score_events: Array[Dictionary] = []
var floating_texts: Array[Dictionary] = []


func recalculate_final_score() -> void:
	final_score = roundi(float(chips * mult) * xmult)


func add_log(entry: BattleLogEntry) -> void:
	logs.append(entry)


func add_score_event(event: Dictionary) -> void:
	score_events.append(event.duplicate(true))


func add_floating_text(text: String, die_index: int = -1, face_index: int = -1) -> void:
	floating_texts.append({
		"text": text,
		"die_index": die_index,
		"face_index": face_index,
	})


func get_summary_text() -> String:
	return get_summary_text_zh()


func get_summary_text_zh() -> String:
	var lines := PackedStringArray()
	lines.append("主骰型：%s" % [_primary_combo_text()])
	lines.append("骰型基础战力：+%d" % [combo_chips_bonus])
	lines.append("骰型倍率：x%d" % [combo_mult])
	lines.append("点数总和：%d" % [scored_point_sum])
	lines.append("包含结构：%s" % [_contained_patterns_text()])
	lines.append("标签：%s" % [_tags_text()])
	lines.append("基础战力：%d" % [chips])
	lines.append("倍率：%d" % [mult])
	lines.append("终倍率：%.2f" % [xmult])
	if coins_delta != 0:
		var coin_prefix := "+" if coins_delta > 0 else ""
		lines.append("金币：%s%d" % [coin_prefix, coins_delta])
	lines.append("最终战力：%d" % [final_score])
	return "\n".join(lines)


func _primary_combo_text() -> String:
	var combo := primary_combo
	if combo == &"":
		combo = combo_id
	if combo != &"":
		return "%s Lv%d" % [DisplayNames.combo_name(combo), max(1, combo_level)]
	if combo_name_key != &"":
		return DisplayNames.display_from_key_or_id(combo_name_key)
	return "无"


func _combo_text() -> String:
	return _primary_combo_text()


func _contained_patterns_text() -> String:
	if contained_patterns.is_empty():
		return "无"

	var pattern_parts := PackedStringArray()
	for pattern in contained_patterns:
		pattern_parts.append(DisplayNames.contained_pattern_name(pattern))
	return " / ".join(pattern_parts)


func _tags_text() -> String:
	if tags.is_empty():
		return "无"

	var tag_parts := PackedStringArray()
	for tag in tags:
		tag_parts.append(DisplayNames.tag_name(tag))
	return " / ".join(tag_parts)
