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


static func ceil_multiplier(value: float) -> int:
	return ceili(value)


static func format_multiplier(value: float) -> String:
	return str(ceil_multiplier(value))


static func final_score_for(score_chips: int, score_mult: int, score_xmult: float) -> int:
	return ceili(float(score_chips * score_mult) * float(ceil_multiplier(score_xmult)))


func normalize_multipliers() -> void:
	xmult = float(ceil_multiplier(xmult))


func recalculate_final_score() -> void:
	normalize_multipliers()
	final_score = final_score_for(chips, mult, xmult)


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
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.EF0721A4BAA9")) % [_primary_combo_text()])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.DC6B0A9293A8")) % [combo_chips_bonus])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.C5FFC0D889DE")) % [combo_mult])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.2392B1DFA2A1")) % [scored_point_sum])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.135E3DF5C753")) % [_contained_patterns_text()])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.ABAAFC3C7A71")) % [_tags_text()])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.4175E1B87B17")) % [chips])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.B57562D610C0")) % [mult])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.135A684FBEFC")) % [format_multiplier(xmult)])
	if coins_delta != 0:
		var coin_prefix := "+" if coins_delta > 0 else ""
		lines.append(str(TranslationServer.translate(&"AUTO.TEXT.2D4DC8F81EEF")) % [coin_prefix, coins_delta])
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.6B7CB54D478C")) % [final_score])
	return "\n".join(lines)


func _primary_combo_text() -> String:
	var combo := primary_combo
	if combo == &"":
		combo = combo_id
	if combo != &"":
		return "%s Lv%d" % [DisplayNames.combo_name(combo), max(1, combo_level)]
	if combo_name_key != &"":
		return DisplayNames.display_from_key_or_id(combo_name_key)
	return str(TranslationServer.translate(&"AUTO.TEXT.72077749F794"))


func _combo_text() -> String:
	return _primary_combo_text()


func _contained_patterns_text() -> String:
	if contained_patterns.is_empty():
		return str(TranslationServer.translate(&"AUTO.TEXT.72077749F794"))

	var pattern_parts := PackedStringArray()
	for pattern in contained_patterns:
		pattern_parts.append(DisplayNames.contained_pattern_name(pattern))
	return " / ".join(pattern_parts)


func _tags_text() -> String:
	if tags.is_empty():
		return str(TranslationServer.translate(&"AUTO.TEXT.72077749F794"))

	var tag_parts := PackedStringArray()
	for tag in tags:
		tag_parts.append(DisplayNames.tag_name(tag))
	return " / ".join(tag_parts)
