extends RefCounted
class_name EffectResolver


const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const BattleLogEntry = preload("res://scripts/log/BattleLogEntry.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


func resolve(context: ScoreContext, result: ScoreResult) -> ScoreResult:
	return apply_effects(context, result)


func apply_effects(context: ScoreContext, result: ScoreResult) -> ScoreResult:
	if context == null or result == null:
		return result

	_apply_unselected_effects(context, result)
	_apply_selected_face_effects(context, result)
	return result


func _apply_unselected_effects(context: ScoreContext, result: ScoreResult) -> void:
	for roll in context.all_rolled_faces:
		if roll == null or roll.face == null or _is_face_selected(roll, context):
			continue

		var face = roll.face

		if face.material_id == &"steel":
			result.mult += 5
			_add_log(result, &"LOG.MATERIAL_STEEL", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"material": LocKeys.material_name_key(face.material_id),
				"mult": 5,
			}, &"material_steel")

		if face.mark_id == &"blue":
			result.mult += 3
			_add_log(result, &"LOG.IMPRINT_BLUE", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"imprint": LocKeys.imprint_name_key(face.mark_id),
				"mult": 3,
			}, &"mark_blue")


func _apply_selected_face_effects(context: ScoreContext, result: ScoreResult) -> void:
	for roll in context.selected_faces:
		if roll == null or roll.face == null:
			continue

		var trigger_count := _get_trigger_count(roll, context)

		if roll.face.mark_id == &"red":
			_add_log(result, &"LOG.IMPRINT_RED", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"imprint": LocKeys.imprint_name_key(roll.face.mark_id),
				"count": 1,
			}, &"mark_red")

		if _has_pair_rune_retrigger(roll, context):
			_add_log(result, &"LOG.RUNE_PAIR_RETRIGGER", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"rune": LocKeys.rune_name_key(roll.face.rune_id),
				"count": 1,
			}, &"rune_pair")

		for trigger_index in range(trigger_count):
			_apply_single_face_trigger(roll, context, result, trigger_index)


func _get_trigger_count(roll: RolledFace, context: ScoreContext) -> int:
	if roll == null or roll.face == null:
		return 0

	var trigger_count := 1
	if roll.face.mark_id == &"red":
		trigger_count += 1
	if _has_pair_rune_retrigger(roll, context):
		trigger_count += 1

	return trigger_count


func _apply_single_face_trigger(roll: RolledFace, context: ScoreContext, result: ScoreResult, trigger_index: int) -> void:
	var face = roll.face
	var trigger_number := trigger_index + 1

	if trigger_index > 0:
		result.chips += face.pip
		_add_log(result, &"LOG.EXTRA_TRIGGER_PIP", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
			"trigger": trigger_number,
			"chips": face.pip,
		}, &"extra_pip")

	if face.level > 1:
		var level_chips: int = (int(face.level) - 1) * 5
		result.chips += level_chips
		_add_log(result, &"LOG.LEVEL_CHIPS", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
			"level": face.level,
			"trigger": trigger_number,
			"chips": level_chips,
		}, &"level")

	if face.material_id == &"glass":
		result.xmult *= 2.0
		_add_log(result, &"LOG.MATERIAL_GLASS", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
			"material": LocKeys.material_name_key(face.material_id),
			"trigger": trigger_number,
			"xmult": _format_xmult(2.0),
		}, &"material_glass")

	if face.rune_id == &"six" and face.pip == 6:
		result.mult += 8
		_add_log(result, &"LOG.RUNE_SIX", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
			"rune": LocKeys.rune_name_key(face.rune_id),
			"trigger": trigger_number,
			"mult": 8,
		}, &"rune_six")

	if face.rune_id == &"straight" and _is_face_part_of_straight(roll, context):
		result.chips += 20
		_add_log(result, &"LOG.RUNE_STRAIGHT", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
			"rune": LocKeys.rune_name_key(face.rune_id),
			"trigger": trigger_number,
			"chips": 20,
		}, &"rune_straight")

	if face.rune_id == &"odd" and face.pip % 2 == 1:
		result.mult += 4
		_add_log(result, &"LOG.RUNE_ODD", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
			"rune": LocKeys.rune_name_key(face.rune_id),
			"trigger": trigger_number,
			"mult": 4,
		}, &"rune_odd")

	if face.rune_id == &"even" and face.pip % 2 == 0:
		result.chips += 8
		_add_log(result, &"LOG.RUNE_EVEN", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
			"rune": LocKeys.rune_name_key(face.rune_id),
			"trigger": trigger_number,
			"chips": 8,
		}, &"rune_even")


func _is_face_selected(roll: RolledFace, context: ScoreContext) -> bool:
	if roll == null:
		return false

	for selected_roll in context.selected_faces:
		if selected_roll == roll:
			return true
		if selected_roll != null and selected_roll.die_index == roll.die_index and selected_roll.face_index == roll.face_index:
			return true

	return false


func _selected_pip_counts(context: ScoreContext) -> Dictionary:
	var counts := {}

	for roll in context.selected_faces:
		if roll == null or roll.face == null:
			continue

		var pip := int(roll.face.pip)
		counts[pip] = int(counts.get(pip, 0)) + 1

	return counts


func _is_straight_combo(combo_type) -> bool:
	var combo_id := _combo_id_from_value(combo_type)
	return combo_id == ComboEvaluator.SMALL_STRAIGHT or combo_id == ComboEvaluator.LARGE_STRAIGHT


func _is_face_part_of_straight(roll: RolledFace, context: ScoreContext) -> bool:
	if roll == null or roll.face == null:
		return false
	if not _is_straight_combo(_active_combo_id(context)):
		return false

	var counts := _selected_pip_counts(context)
	var pip := int(roll.face.pip)

	for length in [4, 5]:
		for start_pip in range(1, 8 - length):
			var has_sequence := true
			for offset in range(length):
				if int(counts.get(start_pip + offset, 0)) <= 0:
					has_sequence = false
					break

			if has_sequence and pip >= start_pip and pip < start_pip + length:
				return true

	return false


func _has_pair_rune_retrigger(roll: RolledFace, context: ScoreContext) -> bool:
	if roll == null or roll.face == null or roll.face.rune_id != &"pair":
		return false

	var counts := _selected_pip_counts(context)
	return int(counts.get(roll.face.pip, 0)) >= 2


func _active_combo_id(context: ScoreContext) -> StringName:
	if context.combo_id != &"":
		return context.combo_id

	return _combo_id_from_value(context.combo_type)


func _combo_id_from_value(value) -> StringName:
	if value is StringName:
		return value
	if value is String:
		return StringName(value)
	return &""


func _add_log(result: ScoreResult, key: StringName, args: Dictionary = {}, category: StringName = &"general") -> void:
	var entry := BattleLogEntry.new(key, args, category)
	result.add_log(entry)


func _format_xmult(value: float) -> String:
	return "%.2f" % [value]
