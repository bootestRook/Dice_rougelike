extends RefCounted
class_name LongTermUnlockService


const LongTermUnlockCatalog = preload("res://scripts/rules/long_term/LongTermUnlockCatalog.gd")
const LongTermUnlockDef = preload("res://scripts/data_defs/LongTermUnlockDef.gd")


static func get_available_shop_unlock_ids(run_state) -> Array[StringName]:
	var result: Array[StringName] = []
	for unlock_id in LongTermUnlockCatalog.get_shop_pool_ids():
		if run_state != null and run_state.has_method("has_long_term_unlock") and run_state.has_long_term_unlock(unlock_id):
			continue
		result.append(unlock_id)
	return result


static func draw_shop_unlock_id(run_state, rng: RandomNumberGenerator = null) -> StringName:
	var ids := get_available_shop_unlock_ids(run_state)
	if ids.is_empty():
		return &""
	if rng == null:
		return ids[0]
	return ids[rng.randi_range(0, ids.size() - 1)]


static func get_unlock_unavailable_reason(run_state, unlock_id: StringName) -> String:
	if run_state == null:
		return "缺少本局状态"
	if unlock_id == &"":
		return "长期解锁项无效"
	if LongTermUnlockCatalog.get_def(unlock_id) == null:
		return "长期解锁项不存在"
	if run_state.has_method("has_long_term_unlock") and run_state.has_long_term_unlock(unlock_id):
		return "该长期解锁已获得"
	return ""


static func view_data_for_unlock(unlock_id: StringName) -> Dictionary:
	var def := LongTermUnlockCatalog.get_def(unlock_id)
	if def == null:
		return {}
	return {
		"unlock_id": def.unlock_id,
		"display_name": def.get_display_name(),
		"description": def.get_description(),
		"unlock_kind": def.unlock_kind,
		"price_coins": def.price_coins,
		"effect_type": def.effect_type,
		"effect_value": def.effect_value,
	}


func apply_unlock(run_state, unlock_id: StringName) -> Dictionary:
	var unavailable_reason := get_unlock_unavailable_reason(run_state, unlock_id)
	if unavailable_reason != "":
		return {"success": false, "message": unavailable_reason}

	var def := LongTermUnlockCatalog.get_def(unlock_id)
	run_state.long_term_unlocks[unlock_id] = true
	_apply_effect(run_state, def)

	var message := "[商店] 购买 长期解锁：%s，立即生效。" % [def.get_display_name()]
	if run_state.has_method("record_shop_log"):
		run_state.record_shop_log(message, {
			"kind": &"long_term_unlock",
			"unlock_id": unlock_id,
			"effect_type": def.effect_type,
			"effect_value": def.effect_value,
		})
	return {
		"success": true,
		"message": message,
		"unlock_id": unlock_id,
		"unlock_def": def,
	}


static func should_disable_boss_rules(run_state, battle_state = null) -> bool:
	if run_state == null or battle_state == null:
		return false
	if not _is_boss_battle_state(battle_state):
		return false
	if int(run_state.long_term_boss_rule_grace_per_battle) <= 0:
		return false
	if bool(battle_state.long_term_boss_rule_grace_used):
		return false
	battle_state.long_term_boss_rule_grace_used = true
	battle_state.boss_rule_disabled = true
	return true


func _apply_effect(run_state, def: LongTermUnlockDef) -> void:
	if run_state == null or def == null:
		return
	if run_state.has_method("add_long_term_unlock_effect"):
		run_state.add_long_term_unlock_effect(def.effect_type, def.effect_value)

	match def.effect_type:
		LongTermUnlockCatalog.EFFECT_ITEM_SLOT_BONUS:
			run_state.item_slot_capacity = max(0, run_state.item_slot_capacity + def.effect_value)
		LongTermUnlockCatalog.EFFECT_DICE_TOOL_SLOT_BONUS:
			run_state.dice_tool_capacity = max(0, run_state.dice_tool_capacity + def.effect_value)
		LongTermUnlockCatalog.EFFECT_SHOP_REROLL_BASE_DELTA:
			run_state.shop_reroll_base_cost = max(1, run_state.shop_reroll_base_cost + def.effect_value)
			if not run_state.current_shop_state.is_empty():
				run_state.current_shop_state["reroll_cost"] = run_state.get_shop_reroll_cost()
		LongTermUnlockCatalog.EFFECT_SHOP_RANDOM_ITEM_SLOT_BONUS:
			run_state.shop_random_item_slot_bonus = max(0, run_state.shop_random_item_slot_bonus + def.effect_value)
		LongTermUnlockCatalog.EFFECT_SHOP_BOOSTER_SLOT_BONUS:
			run_state.shop_booster_slot_bonus = max(0, run_state.shop_booster_slot_bonus + def.effect_value)
		LongTermUnlockCatalog.EFFECT_BATTLE_HAND_BONUS:
			run_state.battle_rounds_available_delta = max(0, run_state.battle_rounds_available_delta + def.effect_value)
		LongTermUnlockCatalog.EFFECT_BATTLE_REROLL_BONUS:
			run_state.battle_rerolls_per_hand_delta = max(0, run_state.battle_rerolls_per_hand_delta + def.effect_value)
		LongTermUnlockCatalog.EFFECT_SCORE_SLOT_BONUS:
			run_state.max_scored_faces_per_round_delta = max(0, run_state.max_scored_faces_per_round_delta + def.effect_value)
		LongTermUnlockCatalog.EFFECT_COIN_GAIN:
			run_state.add_coins(def.effect_value, def.unlock_id)
		LongTermUnlockCatalog.EFFECT_BOSS_RULE_GRACE:
			run_state.long_term_boss_rule_grace_per_battle = max(0, run_state.long_term_boss_rule_grace_per_battle + def.effect_value)
		_:
			pass


static func _is_boss_battle_state(battle_state) -> bool:
	if battle_state == null or battle_state.config == null:
		return false
	return bool(battle_state.config.is_boss_battle)
