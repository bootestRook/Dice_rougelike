extends RefCounted
class_name ScoreResult


const BattleLogEntry = preload("res://scripts/log/BattleLogEntry.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const LocService = preload("res://scripts/i18n/LocService.gd")


var chips: int = 0
var mult: int = 1
var xmult: float = 1.0
var final_score: int = 0
var combo_id: StringName = &""
var combo_name_key: StringName = &""
var display_combo_ids: Array[StringName] = []
var tags: Array[StringName] = []
var logs: Array[BattleLogEntry] = []


func recalculate_final_score() -> void:
	final_score = roundi(float(chips * mult) * xmult)


func add_log(entry: BattleLogEntry) -> void:
	logs.append(entry)


func get_summary_text() -> String:
	var lines := PackedStringArray()
	var tag_text := LocService.t(&"UI.SCORE_SUMMARY.NONE")
	if not tags.is_empty():
		var tag_parts := PackedStringArray()
		for tag in tags:
			tag_parts.append(LocService.t(LocKeys.tag_key(tag)))
		tag_text = ", ".join(tag_parts)

	lines.append(LocService.t(&"UI.SCORE_SUMMARY.COMBO", {"combo": _combo_text()}))
	lines.append(LocService.t(&"UI.SCORE_SUMMARY.TAGS", {"tags": tag_text}))
	lines.append(LocService.t(&"UI.SCORE_SUMMARY.CHIPS", {"chips": chips}))
	lines.append(LocService.t(&"UI.SCORE_SUMMARY.MULT", {"mult": mult}))
	lines.append(LocService.t(&"UI.SCORE_SUMMARY.XMULT", {"xmult": "%.2f" % [xmult]}))
	lines.append(LocService.t(&"UI.SCORE_SUMMARY.FINAL", {"score": final_score}))
	return "\n".join(lines)


func _combo_text() -> String:
	var combo_ids: Array[StringName] = []
	for display_combo_id in display_combo_ids:
		if display_combo_id != &"":
			combo_ids.append(display_combo_id)
	if combo_ids.is_empty() and combo_id != &"":
		combo_ids.append(combo_id)
	if not combo_ids.is_empty():
		var combo_parts := PackedStringArray()
		for display_combo_id in combo_ids:
			combo_parts.append(LocService.t(LocKeys.combo_key(display_combo_id)))
		return _combo_separator().join(combo_parts)
	if combo_id != &"":
		return LocService.t(LocKeys.combo_key(combo_id))
	if combo_name_key != &"":
		return LocService.t(combo_name_key)
	return LocService.t(&"UI.SCORE_SUMMARY.NONE")


func _combo_separator() -> String:
	if LocService.get_locale().begins_with("zh"):
		return "、"

	return ", "
