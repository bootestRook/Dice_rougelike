extends RefCounted
class_name EffectResolver


const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const BattleLogEntry = preload("res://scripts/log/BattleLogEntry.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const ComboUpgradeItem = preload("res://scripts/rules/combo/ComboUpgradeItem.gd")


var reward_generator := RewardGenerator.new()


func resolve(context: ScoreContext, result: ScoreResult) -> ScoreResult:
	return apply_effects(context, result)


func apply_effects(context: ScoreContext, result: ScoreResult) -> ScoreResult:
	if context == null or result == null:
		return result

	_apply_selected_face_effects(context, result)
	_apply_unselected_effects(context, result)
	return result


func apply_post_score_effects(context: ScoreContext, result: ScoreResult) -> ScoreResult:
	if context == null or result == null or context.is_preview:
		return result

	for roll in context.selected_faces:
		if roll == null or roll.face == null:
			continue
		if _effective_ornament_id_for_roll(roll, context) != FaceState.ORN_BURST:
			continue
		if _active_rng(context).randf() < 0.25:
			_clear_face_ornament(context, roll)
			result.add_floating_text("爆裂破碎", roll.die_index, roll.face_index)
			_add_log(result, &"LOG.ORNAMENT_BURST_BREAK", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
			}, &"ornament_burst")

	return result


func is_face_protected_by_white_mark(face_ref, negative_rule_id: StringName) -> bool:
	return _mark_id_from_ref(face_ref) == FaceState.MARK_WHITE and negative_rule_targets_face(negative_rule_id)


func negative_rule_targets_face(negative_rule_id: StringName) -> bool:
	match negative_rule_id:
		&"disable_face", &"disable_ornament", &"disable_mark", &"force_face_unscored", &"force_pip_zero", &"force_cannot_select", &"force_no_point_logic", &"boss_disable_face", &"boss_disable_ornament", &"boss_disable_mark":
			return true
		_:
			return false


func try_apply_face_negative_rule(face_ref, negative_rule_id: StringName, result: ScoreResult = null) -> bool:
	if not is_face_protected_by_white_mark(face_ref, negative_rule_id):
		return true

	if result != null:
		_add_log(result, &"LOG.MARK_WHITE_IMMUNE", {
			"die": _die_index_from_ref(face_ref) + 1,
			"face": _face_index_from_ref(face_ref) + 1,
			"rule": negative_rule_id,
		}, &"mark_white")
		result.add_floating_text("白印：免疫", _die_index_from_ref(face_ref), _face_index_from_ref(face_ref))
	return false


func _apply_unselected_effects(context: ScoreContext, result: ScoreResult) -> void:
	for roll in context.all_rolled_faces:
		if roll == null or roll.face == null or _is_face_selected(roll, context):
			continue

		var triggered := _apply_single_unselected_stay_trigger(roll, context, result)
		var mark_id := _normalized_mark_id(roll.face.mark_id)
		if mark_id == FaceState.MARK_RED and triggered:
			_add_log(result, &"LOG.MARK_RED_RETRIGGER", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
			}, &"mark_red")
			result.add_floating_text("红印：额外触发", roll.die_index, roll.face_index)
			_apply_single_unselected_stay_trigger(roll, context, result)
		elif mark_id == FaceState.MARK_BLUE:
			_try_trigger_blue_mark(roll, context, result, triggered)


func _apply_selected_face_effects(context: ScoreContext, result: ScoreResult) -> void:
	for roll in context.selected_faces:
		if roll == null or roll.face == null:
			continue

		_apply_single_face_trigger(roll, result, 0, context)

		var mark_id := _normalized_mark_id(roll.face.mark_id)
		match mark_id:
			FaceState.MARK_RED:
				_add_log(result, &"LOG.MARK_RED_RETRIGGER", {
					"die": roll.die_index + 1,
					"face": roll.face_index + 1,
				}, &"mark_red")
				result.add_floating_text("红印：额外触发", roll.die_index, roll.face_index)
				_apply_single_face_trigger(roll, result, 1, context)
			FaceState.MARK_GOLD:
				_apply_gold_mark(roll, context, result)
			FaceState.MARK_PURPLE:
				_try_trigger_purple_mark(roll, result)


func _apply_single_face_trigger(roll: RolledFace, result: ScoreResult, trigger_index: int, context: ScoreContext = null) -> void:
	var face = roll.face
	if face == null:
		return
	var ornament_id: StringName = _effective_ornament_id_for_roll(roll, context)

	if trigger_index > 0:
		var retrigger_pip = _pip_for_retrigger(roll, context)
		if retrigger_pip != null:
			result.chips += int(retrigger_pip)
			_add_log(result, &"LOG.EXTRA_TRIGGER_PIP", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"chips": int(retrigger_pip),
			}, &"extra_pip")

	match ornament_id:
		FaceState.ORN_CHIP:
			result.chips += 30
			_add_log(result, &"LOG.ORNAMENT_CHIP", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"ornament": DisplayNames.ornament_name(ornament_id),
				"chips": 30,
			}, &"ornament_chip")
			result.add_floating_text("+30 Chips", roll.die_index, roll.face_index)
		FaceState.ORN_MULT:
			result.mult += 4
			_add_log(result, &"LOG.ORNAMENT_MULT", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"ornament": DisplayNames.ornament_name(ornament_id),
				"mult": 4,
			}, &"ornament_mult")
			result.add_floating_text("+4 Mult", roll.die_index, roll.face_index)
		FaceState.ORN_STONE:
			result.chips += 50
			_add_log(result, &"LOG.ORNAMENT_STONE", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"chips": 50,
			}, &"ornament_stone")
			result.add_floating_text("+50 Chips", roll.die_index, roll.face_index)
		FaceState.ORN_BURST:
			result.xmult *= 2.0
			_add_log(result, &"LOG.ORNAMENT_BURST", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"ornament": DisplayNames.ornament_name(ornament_id),
				"xmult": _format_xmult(2.0),
			}, &"ornament_burst")
			result.add_floating_text("X2", roll.die_index, roll.face_index)
		FaceState.ORN_LUCKY:
			_apply_lucky(roll, context, result)
		FaceState.ORN_FOIL:
			result.chips += 50
			_add_log(result, &"LOG.ORNAMENT_FOIL", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"chips": 50,
			}, &"ornament_foil")
			result.add_floating_text("+50 Chips", roll.die_index, roll.face_index)
		FaceState.ORN_HOLO:
			result.mult += 10
			_add_log(result, &"LOG.ORNAMENT_HOLO", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"mult": 10,
			}, &"ornament_holo")
			result.add_floating_text("+10 Mult", roll.die_index, roll.face_index)
		FaceState.ORN_POLY:
			result.xmult *= 1.5
			_add_log(result, &"LOG.ORNAMENT_POLY", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"xmult": _format_xmult(1.5),
			}, &"ornament_poly")
			result.add_floating_text("X1.5", roll.die_index, roll.face_index)


func _apply_single_unselected_stay_trigger(roll: RolledFace, context: ScoreContext, result: ScoreResult) -> bool:
	if roll == null or roll.face == null:
		return false

	var triggered := false
	var ornament_id: StringName = _effective_ornament_id_for_roll(roll, context)
	match ornament_id:
		FaceState.ORN_STAY:
			result.xmult *= 1.5
			_add_log(result, &"LOG.ORNAMENT_STAY", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"ornament": DisplayNames.ornament_name(ornament_id),
				"xmult": _format_xmult(1.5),
			}, &"ornament_stay")
			result.add_floating_text("X1.5", roll.die_index, roll.face_index)
			triggered = true
		FaceState.ORN_GOLD:
			_add_coins(context, result, 3, "金辉面饰：+3 金币", roll)
			_add_log(result, &"LOG.ORNAMENT_GOLD", {
				"die": roll.die_index + 1,
				"face": roll.face_index + 1,
				"coins": 3,
			}, &"ornament_gold")
			triggered = true
	return triggered


func _try_trigger_blue_mark(roll: RolledFace, context: ScoreContext, result: ScoreResult, triggered_stay: bool) -> void:
	if result == null:
		return

	var mult_bonus := 2
	if triggered_stay:
		mult_bonus += 1
	result.mult += mult_bonus
	_add_log(result, &"LOG.MARK_BLUE", {
		"die": roll.die_index + 1,
		"face": roll.face_index + 1,
		"mark": DisplayNames.mark_name(FaceState.MARK_BLUE),
		"mult": mult_bonus,
	}, &"mark_blue")
	result.add_floating_text("+%d Mult" % [mult_bonus], roll.die_index, roll.face_index)

	if context == null or context.is_preview or context.run_state == null:
		return
	if context.primary_combo == &"":
		return

	var item_id := reward_generator.combo_upgrade_item_id(context.primary_combo)
	if item_id == &"":
		return

	if not _has_free_item_slot(context):
		_add_log(result, &"LOG.MARK_BLUE_NO_SLOT", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
		}, &"mark_blue")
		result.add_floating_text("道具槽位不足", roll.die_index, roll.face_index)
		return

	if _add_item_to_inventory_or_pending(context, item_id):
		_add_log(result, &"LOG.MARK_BLUE_GENERATE", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
			"item": item_id,
			"item_name": _upgrade_item_name(context.primary_combo),
		}, &"mark_blue")
		result.add_floating_text("蓝印：生成", roll.die_index, roll.face_index)
	else:
		_add_log(result, &"LOG.MARK_BLUE_NO_SLOT", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
		}, &"mark_blue")
		result.add_floating_text("道具槽位不足", roll.die_index, roll.face_index)


func _try_trigger_purple_mark(roll: RolledFace, result: ScoreResult) -> void:
	if roll == null or result == null or not roll.was_rerolled:
		return

	var mult_bonus := 4
	result.mult += mult_bonus
	_add_log(result, &"LOG.MARK_PURPLE", {
		"die": roll.die_index + 1,
		"face": roll.face_index + 1,
		"mark": DisplayNames.mark_name(FaceState.MARK_PURPLE),
		"mult": mult_bonus,
	}, &"mark_purple")
	result.add_floating_text("+%d Mult" % [mult_bonus], roll.die_index, roll.face_index)


func _apply_gold_mark(roll: RolledFace, context: ScoreContext, result: ScoreResult) -> void:
	_add_coins(context, result, 1, "金印：+1 金币", roll)
	_add_log(result, &"LOG.MARK_GOLD_COINS", {
		"die": roll.die_index + 1,
		"face": roll.face_index + 1,
		"coins": 1,
	}, &"mark_gold")


func _is_face_selected(roll: RolledFace, context: ScoreContext) -> bool:
	if roll == null:
		return false

	for selected_roll in context.selected_faces:
		if selected_roll == roll:
			return true
		if selected_roll != null and selected_roll.die_index == roll.die_index and selected_roll.face_index == roll.face_index:
			return true

	return false


func _apply_lucky(roll: RolledFace, context: ScoreContext, result: ScoreResult) -> void:
	if context == null or context.is_preview:
		_add_log(result, &"LOG.ORNAMENT_LUCKY_MISS", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
		}, &"ornament_lucky")
		return

	var triggered_mult := false
	var triggered_coins := false
	var rng = _active_rng(context)
	if rng.randf() < 0.20:
		triggered_mult = true
		result.mult += 20
		result.add_floating_text("+20 Mult", roll.die_index, roll.face_index)
		_add_log(result, &"LOG.ORNAMENT_LUCKY_MULT", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
			"mult": 20,
		}, &"ornament_lucky")

	if rng.randf() < (1.0 / 15.0):
		triggered_coins = true
		_add_coins(context, result, 20, "幸运面饰：+20 金币", roll)
		_add_log(result, &"LOG.ORNAMENT_LUCKY_COINS", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
			"coins": 20,
		}, &"ornament_lucky")

	if not triggered_mult and not triggered_coins:
		_add_log(result, &"LOG.ORNAMENT_LUCKY_MISS", {
			"die": roll.die_index + 1,
			"face": roll.face_index + 1,
		}, &"ornament_lucky")


func _add_coins(context: ScoreContext, result: ScoreResult, amount: int, event_text: String, roll: RolledFace) -> void:
	if amount == 0:
		return
	if context != null:
		context.coins_delta += amount
		context.score_events.append({
			"type": &"coins",
			"amount": amount,
			"text": event_text,
			"die_index": roll.die_index if roll != null else -1,
			"face_index": roll.face_index if roll != null else -1,
		})
		if not context.is_preview and context.run_state != null:
			if context.run_state.has_method("add_coins"):
				context.run_state.add_coins(amount, &"score_effect")
			else:
				context.run_state.coins += amount
	if result != null:
		result.coins_delta += amount
		var die_index := roll.die_index if roll != null else -1
		var face_index := roll.face_index if roll != null else -1
		result.add_floating_text("+%d 金币" % [amount], die_index, face_index)


func _has_free_item_slot(context: ScoreContext) -> bool:
	return context != null and context.run_state != null and context.run_state.has_free_item_slot()


func _add_item_to_inventory_or_pending(context: ScoreContext, item_id: StringName) -> bool:
	return context != null and context.run_state != null and context.run_state.add_item_to_inventory_or_pending(item_id)


func _clear_face_ornament(context: ScoreContext, roll: RolledFace) -> void:
	if roll == null:
		return
	if roll.face != null:
		roll.face.ornament_id = FaceState.ORN_NONE
	var source_face := _source_face_for_roll(context, roll)
	if source_face != null:
		source_face.ornament_id = FaceState.ORN_NONE
		source_face.material_id = &"none"


func _source_face_for_roll(context: ScoreContext, roll: RolledFace) -> FaceState:
	if roll == null:
		return null
	if roll.die != null and roll.face_index >= 0 and roll.face_index < roll.die.faces.size():
		return roll.die.faces[roll.face_index]
	if context != null and roll.die_index >= 0 and roll.die_index < context.source_dice.size():
		var source_die = context.source_dice[roll.die_index]
		if source_die != null and roll.face_index >= 0 and roll.face_index < source_die.faces.size():
			return source_die.faces[roll.face_index]
	if context != null and context.battle_state != null and roll.die_index >= 0 and roll.die_index < context.battle_state.dice.size():
		var battle_die = context.battle_state.dice[roll.die_index]
		if battle_die != null and roll.face_index >= 0 and roll.face_index < battle_die.faces.size():
			return battle_die.faces[roll.face_index]
	return null


func _active_rng(context: ScoreContext):
	if context != null and context.rng != null:
		return context.rng
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng


func _pip_for_retrigger(roll: RolledFace, context: ScoreContext = null):
	if roll == null or roll.face == null:
		return null
	if _effective_ornament_id_for_roll(roll, context) == FaceState.ORN_STONE:
		return null
	return roll.face.pip


func _effective_ornament_id_for_roll(roll: RolledFace, context: ScoreContext = null) -> StringName:
	if roll == null:
		return FaceState.ORN_NONE

	var rolled_id := FaceState.ORN_NONE
	if roll.face != null:
		rolled_id = roll.face.get_effective_ornament_id()
		if rolled_id != FaceState.ORN_NONE:
			return rolled_id

	var source_face := _source_face_for_roll(context, roll)
	if source_face != null:
		return source_face.get_effective_ornament_id()
	return rolled_id


func _normalized_mark_id(id: StringName) -> StringName:
	return FaceState.normalize_mark_id(id)


func _mark_id_from_ref(face_ref) -> StringName:
	if face_ref is RolledFace:
		var roll := face_ref as RolledFace
		return _normalized_mark_id(roll.face.mark_id) if roll.face != null else FaceState.MARK_NONE
	if face_ref is FaceState:
		return _normalized_mark_id((face_ref as FaceState).mark_id)
	return FaceState.MARK_NONE


func _die_index_from_ref(face_ref) -> int:
	if face_ref is RolledFace:
		return (face_ref as RolledFace).die_index
	return -1


func _face_index_from_ref(face_ref) -> int:
	if face_ref is RolledFace:
		return (face_ref as RolledFace).face_index
	return -1


func _upgrade_item_name(combo_id: StringName) -> String:
	var item := ComboUpgradeItem.create_for_combo(combo_id)
	if item != null:
		return item.display_name
	return "%s升级件" % [DisplayNames.combo_name(combo_id)]


func _add_log(result: ScoreResult, key: StringName, args: Dictionary = {}, category: StringName = &"general") -> void:
	var entry := BattleLogEntry.new(key, args, category)
	result.add_log(entry)


func _format_xmult(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.2f" % [value]
