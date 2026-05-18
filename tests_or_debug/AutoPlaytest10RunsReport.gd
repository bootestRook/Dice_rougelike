extends SceneTree
class_name AutoPlaytest10RunsReport


const BattleState = preload("res://scripts/core/battle/BattleState.gd")
const BattleController = preload("res://scripts/runtime/BattleController.gd")
const DiceToolService = preload("res://scripts/rules/dice_tools/DiceToolService.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const ForgeService = preload("res://scripts/rules/forge/ForgeService.gd")
const HandState = preload("res://scripts/core/battle/HandState.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ScoreContext = preload("res://scripts/core/scoring/ScoreContext.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const RewardGenerator = preload("res://scripts/rules/reward/RewardGenerator.gd")
const ComboUpgradeItem = preload("res://scripts/rules/combo/ComboUpgradeItem.gd")


const RUN_COUNT := 10
const REPORT_ROOT := "res://reports"
const BASE_SEED := 2026051801
const LOW_SCORE_REROLL_FLOOR := 220


var reward_generator := RewardGenerator.new()
var forge_service := ForgeService.new()
var dice_tool_service := DiceToolService.new()
var score_engine := ScoreEngine.new()
var report_dir := ""


func _init() -> void:
	TranslationServer.set_locale("zh_Hans")
	report_dir = _create_report_dir()
	var summaries: Array[Dictionary] = []
	var total_started_msec: int = Time.get_ticks_msec()

	print("--- AutoPlaytest10RunsReport: start ---")
	print("报告目录: %s" % [ProjectSettings.globalize_path(report_dir)])

	for run_number in range(1, RUN_COUNT + 1):
		var run_seed := BASE_SEED + run_number * 1000
		var result := _play_run(run_number, run_seed)
		summaries.append(result)
		_write_text("%s/run_%02d.md" % [report_dir, run_number], "\n".join(result["lines"]))
		print("第 %02d 局完成: %s，推进到第 %d 战，最佳单手 %d，耗时 %s" % [
			run_number,
			str(result["status"]),
			int(result["battles_reached"]),
			int(result["best_hand_score"]),
			_format_duration_ms(int(result["elapsed_ms"])),
		])

	var total_elapsed_msec: int = Time.get_ticks_msec() - total_started_msec
	_write_text("%s/summary.md" % [report_dir], _build_summary_report(summaries))
	_write_text("%s/rewards_overview.md" % [report_dir], _build_reward_overview_report(summaries))
	_write_text("%s/optimization_suggestions.md" % [report_dir], _build_optimization_report(summaries))
	print("总耗时: %s" % [_format_duration_ms(total_elapsed_msec)])
	print("PASS: AutoPlaytest10RunsReport")
	print("--- AutoPlaytest10RunsReport: end ---")
	quit(0)


func _play_run(run_number: int, run_seed: int) -> Dictionary:
	var run_started_msec: int = Time.get_ticks_msec()
	_seed_report_services(run_seed)
	var run_state := RunState.new()
	run_state.setup_new_run()

	var lines := PackedStringArray()
	var battle_records: Array[Dictionary] = []
	var reward_records: Array[Dictionary] = []
	var item_use_records: Array[String] = []

	lines.append("# 自动游玩第 %02d 局" % [run_number])
	lines.append("")
	lines.append("- 随机种子：`%d`" % [run_seed])
	lines.append("- 策略说明：每手先枚举所有可结算组合；若当前可达标，选择破坏风险最低的达标组合；若未达标，则用骰型启发式保留三同/对子/顺子听牌/高价值面，并在低于回合压力时主动重投。")
	lines.append("")

	while not run_state.run_won and not run_state.run_lost:
		_use_available_items(run_state, item_use_records)
		var battle_record := _play_battle(run_state, run_seed + run_state.battle_index * 100, lines)
		battle_records.append(battle_record)

		if bool(battle_record.get("victory", false)):
			if run_state.is_final_battle():
				run_state.mark_run_won()
				lines.append("")
				lines.append("## 通关")
				lines.append("")
				lines.append("第 %d 战获胜后已完成全部 %d 战。" % [run_state.battle_index + 1, run_state.max_battles])
				break

			var reward_record := _choose_reward_and_advance(run_state, lines)
			reward_records.append(reward_record)
		else:
			run_state.mark_run_lost()
			lines.append("")
			lines.append("## 失败")
			lines.append("")
			lines.append("第 %d 战未达到目标战力，流程结束。" % [run_state.battle_index + 1])
			break

	if not item_use_records.is_empty():
		lines.append("")
		lines.append("## 道具使用")
		lines.append("")
		for text in item_use_records:
			lines.append("- %s" % [text])

	var elapsed_ms: int = Time.get_ticks_msec() - run_started_msec
	_append_run_summary(lines, run_state, battle_records, reward_records, elapsed_ms)

	return {
		"run_number": run_number,
		"seed": run_seed,
		"status": "通关" if run_state.run_won else "失败",
		"won": run_state.run_won,
		"lost": run_state.run_lost,
		"battles_reached": min(run_state.battle_index + (1 if run_state.run_won else 0), run_state.max_battles),
		"battle_index": run_state.battle_index,
		"total_hands": run_state.total_hands_scored,
		"total_score": run_state.total_score_scored,
		"best_hand_score": run_state.best_hand_score,
		"installed_piece_count": run_state.installed_piece_count,
		"coins": run_state.coins,
		"elapsed_ms": elapsed_ms,
		"lines": lines,
		"battle_records": battle_records,
		"reward_records": reward_records,
	}


func _play_battle(run_state: RunState, battle_seed: int, lines: PackedStringArray) -> Dictionary:
	var battle_number := run_state.battle_index + 1
	var target_score := run_state.get_target_score()
	var controller := BattleController.new()
	controller.roll_service.rng.seed = battle_seed + 11
	controller.score_rng.seed = battle_seed + 37
	controller.reward_generator.rng.seed = battle_seed + 41
	controller.dice_tool_service.rng.seed = battle_seed + 43
	_seed_score_engine_services(controller.score_engine, battle_seed + 47)
	controller.start_battle(null, run_state)

	var hand_records: Array[Dictionary] = []
	lines.append("## 第 %d 战%s" % [battle_number, "（首领战）" if run_state.is_boss_battle() else ""])
	lines.append("")
	lines.append("- 目标战力：%d" % [target_score])
	lines.append("- 开战骰组：%s" % [_dice_loadout_summary(run_state)])
	lines.append("")

	while controller.battle_state != null and not controller.battle_state.battle_finished:
		var hand_record := _play_hand(controller, run_state, battle_seed, lines)
		hand_records.append(hand_record)

	var victory := controller.battle_state != null and controller.battle_state.victory
	var final_score := controller.battle_state.total_score if controller.battle_state != null else 0
	lines.append("")
	lines.append("第 %d 战结果：%s，累计战力 %d / %d。" % [
		battle_number,
		"胜利" if victory else "失败",
		final_score,
		target_score,
	])
	lines.append("")

	var record := {
		"battle": battle_number,
		"target": target_score,
		"victory": victory,
		"score": final_score,
		"hands": hand_records,
	}
	controller.free()
	return record


func _play_hand(controller: BattleController, run_state: RunState, battle_seed: int, lines: PackedStringArray) -> Dictionary:
	var hand_number := controller.get_current_hand_number()
	var actions := PackedStringArray()
	var start_rolls := _rolls_summary(controller.get_current_rolls())
	var settled_record := {}

	lines.append("### 第 %d 手" % [hand_number])
	lines.append("")
	lines.append("- 初始投骰：%s" % [start_rolls])

	while controller.get_phase() == BattleController.BattlePhase.WAITING_ACTION:
		var current_rolls := controller.get_current_rolls()
		var best_current := _best_score_action(controller, current_rolls, battle_seed + hand_number * 101)
		var needed: int = maxi(0, controller.get_target_score() - controller.get_total_score())
		var hands_left: int = maxi(1, controller.get_hands_per_battle() - controller.battle_state.hands_played)

		if int(best_current.get("score", 0)) >= needed:
			var winning := _best_winning_action(controller, current_rolls, needed, battle_seed + hand_number * 131)
			settled_record = _settle_action(controller, run_state, winning, hand_number)
			actions.append("结算达标组合：%s。" % [_action_short_text(winning)])
			break

		if controller.get_rerolls_left() > 0:
			var reroll_decision := _choose_reroll_action(controller, current_rolls, best_current, needed, hands_left, battle_seed + hand_number * 151)
			if bool(reroll_decision.get("should_reroll", false)):
				var mask := int(reroll_decision.get("mask", 0))
				var before := _rolls_summary(controller.get_current_rolls())
				_set_selection_mask(controller, mask)
				controller.reroll()
				var after := _rolls_summary(controller.get_current_rolls())
				actions.append("重投 %s：当前最佳 %d，保留评分 %.1f，%s -> %s" % [
					_indices_text(_mask_to_indices(mask, current_rolls.size())),
					int(best_current.get("score", 0)),
					float(reroll_decision.get("expected_score", 0.0)),
					before,
					after,
				])
				continue

		settled_record = _settle_action(controller, run_state, best_current, hand_number)
		actions.append("结算当前最佳：%s。" % [_action_short_text(best_current)])
		break

	for action in actions:
		lines.append("- %s" % [action])

	if not settled_record.is_empty():
		lines.append("- 实际结算：%s；本手 +%d，战斗累计 %d / %d。" % [
			_action_short_text(settled_record),
			int(settled_record.get("score", 0)),
			controller.get_total_score(),
			controller.get_target_score(),
		])
		var log_preview: Array[String] = settled_record.get("logs", [])
		if not log_preview.is_empty():
			lines.append("- 关键日志：%s" % ["；".join(log_preview)])
	lines.append("")

	return {
		"hand": hand_number,
		"start_rolls": start_rolls,
		"actions": actions,
		"settled": settled_record,
	}


func _settle_action(controller: BattleController, run_state: RunState, action: Dictionary, hand_number: int) -> Dictionary:
	var mask := int(action.get("mask", 0))
	var selected_text := str(action.get("selected_text", ""))
	var selected_faces_text := str(action.get("selected_faces", ""))
	_set_selection_mask(controller, mask)
	var selected_order: Array[int] = []
	for index in _mask_to_indices(mask, controller.get_current_rolls().size()):
		selected_order.append(index)

	var trace = controller.request_settle_selected({}, selected_order)
	if trace == null:
		return {
			"mask": mask,
			"score": 0,
			"combo_name": "无法结算",
			"selected_text": _indices_text(selected_order),
			"logs": ["结算请求被拒绝"],
		}

	controller.commit_pending_resolution()
	var result = trace.score_result
	if result != null:
		run_state.record_hand_score(result, hand_number)

	var logs: Array[String] = []
	if result != null:
		for entry in result.logs:
			if entry == null:
				continue
			var text: String = entry.get_text()
			if text != "" and logs.size() < 4:
				logs.append(text)

	return {
		"mask": mask,
		"score": trace.hand_score_final,
		"combo_name": trace.primary_combo_display_name,
		"combo_id": trace.primary_combo_id,
		"chips": trace.chips_final,
		"mult": trace.mult_final,
		"xmult": trace.xmult_final,
		"selected_text": selected_text,
		"selected_faces": selected_faces_text,
		"logs": logs,
	}


func _best_score_action(controller: BattleController, rolls: Array, seed: int) -> Dictionary:
	var best := {}
	for mask in _score_masks(rolls.size(), controller.get_max_selected_dice()):
		var action := _score_action_for_mask(controller, rolls, mask, seed + mask * 17)
		if _is_better_score_action(action, best):
			best = action
	return best


func _best_winning_action(controller: BattleController, rolls: Array, needed: int, seed: int) -> Dictionary:
	var best := {}
	for mask in _score_masks(rolls.size(), controller.get_max_selected_dice()):
		var action := _score_action_for_mask(controller, rolls, mask, seed + mask * 19)
		if int(action.get("score", 0)) < needed:
			continue
		if best.is_empty() or _winning_sort_key(action) < _winning_sort_key(best):
			best = action
	if best.is_empty():
		return _best_score_action(controller, rolls, seed)
	return best


func _score_action_for_mask(controller: BattleController, rolls: Array, mask: int, seed: int) -> Dictionary:
	var cloned_rolls := _clone_rolls(rolls)
	var selected: Array[RolledFace] = []
	var selected_order: Array[int] = []
	for index in range(cloned_rolls.size()):
		var selected_bit := (mask & (1 << index)) != 0
		cloned_rolls[index].selected = selected_bit
		if selected_bit:
			selected.append(cloned_rolls[index])
			selected_order.append(index)

	var context := _build_score_context_snapshot(controller, cloned_rolls, selected, seed)
	context.selected_die_order = selected_order
	var trace = score_engine.build_resolution_trace(context)
	return {
		"mask": mask,
		"score": trace.hand_score_final,
		"combo_name": trace.primary_combo_display_name,
		"combo_id": trace.primary_combo_id,
		"chips": trace.chips_final,
		"mult": trace.mult_final,
		"xmult": trace.xmult_final,
		"selected_text": _indices_text(selected_order),
		"selected_faces": _selected_faces_text(cloned_rolls, mask),
		"risk": _selection_risk(cloned_rolls, mask),
	}


func _choose_reroll_action(
	controller: BattleController,
	rolls: Array,
	best_current: Dictionary,
	needed: int,
	hands_left: int,
	seed: int
) -> Dictionary:
	var needed_per_hand := ceili(float(needed) / float(max(1, hands_left)))
	var current_score := int(best_current.get("score", 0))
	var decision := _heuristic_reroll_decision(controller, rolls, int(best_current.get("mask", 0)), seed)
	var pressure_floor: int = maxi(LOW_SCORE_REROLL_FLOOR, needed_per_hand)
	var should_reroll := current_score < pressure_floor
	if current_score >= 320 and current_score >= needed_per_hand:
		should_reroll = false
	if hands_left <= 1 and current_score < needed:
		should_reroll = true
	if controller.get_rerolls_left() >= controller.get_rerolls_per_hand() and current_score < ceili(float(needed_per_hand) * 1.35):
		should_reroll = true
	decision["should_reroll"] = should_reroll and int(decision.get("mask", 0)) != 0
	return decision


func _heuristic_reroll_decision(controller: BattleController, rolls: Array, best_score_mask: int, _seed: int) -> Dictionary:
	var count := rolls.size()
	var all_mask := (1 << count) - 1
	var keep_masks: Array[int] = []
	_add_unique_int(keep_masks, best_score_mask)
	_add_unique_int(keep_masks, _multi_pair_mask(rolls))
	_add_unique_int(keep_masks, _most_common_pip_mask(rolls))
	_add_unique_int(keep_masks, _longest_straight_draw_mask(rolls))
	_add_unique_int(keep_masks, _high_or_effect_mask(rolls))
	keep_masks.append(0)

	var best_keep := 0
	var best_keep_score := -99999.0
	for keep_mask in keep_masks:
		var score := _keep_mask_score(rolls, int(keep_mask))
		if score > best_keep_score:
			best_keep_score = score
			best_keep = int(keep_mask)

	var reroll_mask := all_mask & ~best_keep
	if reroll_mask == 0:
		reroll_mask = _lowest_pip_mask(rolls, 1)
	return {
		"should_reroll": false,
		"expected_score": best_keep_score,
		"mask": reroll_mask,
	}


func _multi_pair_mask(rolls: Array) -> int:
	var counts := {}
	for index in range(rolls.size()):
		var roll: RolledFace = rolls[index]
		if roll == null or roll.face == null:
			continue
		var pip := roll.face.pip
		var data: Dictionary = counts.get(pip, {"count": 0, "mask": 0})
		data["count"] = int(data["count"]) + 1
		data["mask"] = int(data["mask"]) | (1 << index)
		counts[pip] = data

	var mask := 0
	for pip in counts.keys():
		var data: Dictionary = counts[pip]
		if int(data["count"]) >= 2:
			mask |= int(data["mask"])
	return mask


func _high_or_effect_mask(rolls: Array) -> int:
	var mask := 0
	for index in range(rolls.size()):
		var roll: RolledFace = rolls[index]
		if roll == null or roll.face == null:
			continue
		if roll.face.pip >= 5 or _face_power_score(roll.face) >= 35.0:
			mask |= (1 << index)
	return mask


func _keep_mask_score(rolls: Array, keep_mask: int) -> float:
	if keep_mask == 0:
		return 35.0
	var score := 0.0
	var counts := {}
	var unique_pips: Array[int] = []
	for index in range(rolls.size()):
		if (keep_mask & (1 << index)) == 0:
			continue
		var roll: RolledFace = rolls[index]
		if roll == null or roll.face == null:
			continue
		var pip := roll.face.pip
		counts[pip] = int(counts.get(pip, 0)) + 1
		if not unique_pips.has(pip):
			unique_pips.append(pip)
		score += float(pip) * 4.0 + min(_face_power_score(roll.face), 90.0) * 0.4

	var max_count := 0
	var pair_count := 0
	for pip in counts.keys():
		var count := int(counts[pip])
		max_count = maxi(max_count, count)
		if count >= 2:
			pair_count += 1
		score += float(count * count) * 15.0 + float(pip) * float(count)
	if max_count >= 4:
		score += 260.0
	elif max_count >= 3:
		score += 135.0
	elif pair_count >= 2:
		score += 28.0
	elif pair_count >= 1:
		score += 18.0

	var straight_draw := _straight_draw_count(unique_pips)
	score += float(straight_draw * straight_draw) * 18.0
	if straight_draw >= 4:
		score += 220.0
	elif straight_draw >= 3:
		score += 80.0
	return score


func _straight_draw_count(unique_pips: Array[int]) -> int:
	var best := 0
	for start in range(1, 5):
		var count := 0
		for pip in unique_pips:
			if pip >= start and pip <= start + 4:
				count += 1
		best = maxi(best, count)
	return best


func _choose_reward_and_advance(run_state: RunState, lines: PackedStringArray) -> Dictionary:
	var choices := reward_generator.generate_forge_choices(3, run_state.battle_index)
	run_state.last_reward_choices = choices
	var battle_number := run_state.battle_index + 1
	var best := {}

	for choice in choices:
		var candidate := _evaluate_reward_choice(run_state, choice)
		if best.is_empty() or float(candidate.get("score", -99999.0)) > float(best.get("score", -99999.0)):
			best = candidate

	var piece: ForgePieceDef = best.get("piece")
	lines.append("### 第 %d 战奖励选择" % [battle_number])
	lines.append("")
	lines.append("- 可选奖励：%s" % [_reward_choices_text(choices)])

	if piece == null:
		lines.append("- 未能选择有效奖励，直接进入下一战。")
		run_state.advance_battle()
		return {"battle": battle_number, "piece": "", "piece_name": "无"}

	if run_state.apply_combo_upgrade_piece(piece):
		lines.append("- 选择：%s；理由：直接提升常用骰型等级。" % [piece.get_display_name()])
		run_state.last_reward_choices.clear()
		run_state.advance_battle()
		return {"battle": battle_number, "piece": str(piece.id), "piece_name": piece.get_display_name()}

	var die_index := int(best.get("die_index", 0))
	var face_index := int(best.get("face_index", 0))
	var before_face = run_state.dice[die_index].faces[face_index].clone()
	var before_text := _face_report_text(before_face)
	forge_service.apply_piece(piece, run_state.dice[die_index], face_index)
	dice_tool_service.on_face_changed(run_state, before_face, run_state.dice[die_index].faces[face_index], &"forge_piece")
	var after_text := _face_report_text(run_state.dice[die_index].faces[face_index])
	run_state.record_installed_piece(piece, die_index, face_index)
	run_state.pending_forge_piece = null
	run_state.last_reward_choices.clear()

	lines.append("- 选择：%s（%s）。" % [piece.get_display_name(), piece.get_tags_display_text()])
	lines.append("- 安装：第 %d 颗骰子的第 %d 面；%s -> %s。" % [die_index + 1, face_index + 1, before_text, after_text])
	lines.append("- 理由：%s" % [str(best.get("reason", ""))])
	lines.append("")

	run_state.advance_battle()
	return {
		"battle": battle_number,
		"piece": str(piece.id),
		"piece_name": piece.get_display_name(),
		"die": die_index + 1,
		"face": face_index + 1,
		"before": before_text,
		"after": after_text,
	}


func _evaluate_reward_choice(run_state: RunState, piece: ForgePieceDef) -> Dictionary:
	var best := {
		"piece": piece,
		"score": -99999.0,
		"die_index": 0,
		"face_index": 0,
		"reason": "",
	}
	if piece == null:
		return best

	if _is_combo_upgrade_piece(piece):
		best["score"] = 75.0
		best["reason"] = "骰型升级不占骰面槽位，长期收益稳定。"
		return best

	for die_index in range(run_state.dice.size()):
		var die = run_state.dice[die_index]
		if die == null:
			continue
		for face_index in range(die.faces.size()):
			if not forge_service.can_apply_piece(piece, die, face_index):
				continue
			var face = die.faces[face_index]
			var score := _piece_base_value(piece) + _target_face_value(piece, face)
			if score > float(best.get("score", -99999.0)):
				best["score"] = score
				best["die_index"] = die_index
				best["face_index"] = face_index
				best["reason"] = _install_reason(piece, face)
	return best


func _use_available_items(run_state: RunState, item_use_records: Array[String]) -> void:
	run_state.ensure_item_slots_from_legacy()
	var used_any := true
	while used_any:
		used_any = false
		for index in range(run_state.item_slots.size()):
			var item: ItemInstance = run_state.item_slots[index]
			if item == null:
				continue
			if ComboUpgradeItem.from_item_id(item.item_id) != null and run_state.use_item(item.item_id):
				item_use_records.append("使用 %s，提升对应骰型等级。" % [item.display_name])
				used_any = true
				break
			if item.item_type == ItemInstance.TYPE_DICE_TOOL and run_state.install_dice_tool_item_from_slot(index):
				item_use_records.append("安装骰具 %s。" % [item.display_name])
				used_any = true
				break


func _build_score_context_snapshot(controller: BattleController, rolls: Array[RolledFace], selected: Array[RolledFace], seed: int) -> ScoreContext:
	var context := ScoreContext.new()
	for roll in rolls:
		context.all_rolled_faces.append(roll)
	for roll in selected:
		context.selected_faces.append(roll)
		context.scored_faces.append(roll)

	context.battle_state = _battle_state_snapshot(controller)
	context.hand_state = _hand_state_snapshot(controller, rolls)
	context.run_state = controller.run_state
	for die in controller.dice:
		context.source_dice.append(die)
	context.rerolls_used = controller.hand_state.rerolls_used if controller.hand_state != null else 0
	context.used_reroll = context.rerolls_used > 0 or _any_roll_was_rerolled(rolls)
	context.is_last_hand = _is_last_hand(controller)
	context.defer_runtime_mutations = true
	context.rerolled_die_ids_this_round = context.hand_state.rerolled_die_ids_this_round.duplicate(true)
	context.body_triggered_flags_this_round = context.hand_state.body_triggered_flags_this_round.duplicate(true)
	context.body_triggered_flags_this_battle = context.battle_state.body_triggered_flags_this_battle.duplicate(true)
	context.rng = RandomNumberGenerator.new()
	context.rng.seed = seed
	return context


func _battle_state_snapshot(controller: BattleController) -> BattleState:
	var snapshot := BattleState.new()
	if controller.battle_state == null:
		return snapshot
	snapshot.config = controller.battle_state.config.clone()
	for die in controller.battle_state.dice:
		snapshot.dice.append(die.clone())
	snapshot.hands_played = controller.battle_state.hands_played
	snapshot.total_score = controller.battle_state.total_score
	snapshot.battle_started = controller.battle_state.battle_started
	snapshot.battle_finished = controller.battle_state.battle_finished
	snapshot.victory = controller.battle_state.victory
	snapshot.purple_mark_triggered_this_battle = controller.battle_state.purple_mark_triggered_this_battle.duplicate(true)
	snapshot.white_mark_active_faces = controller.battle_state.white_mark_active_faces.duplicate(true)
	snapshot.body_triggered_flags_this_battle = controller.battle_state.body_triggered_flags_this_battle.duplicate(true)
	return snapshot


func _hand_state_snapshot(controller: BattleController, rolls: Array[RolledFace]) -> HandState:
	var snapshot := HandState.new()
	if controller.hand_state == null:
		return snapshot
	snapshot.hand_index = controller.hand_state.hand_index
	snapshot.rerolls_used = controller.hand_state.rerolls_used
	snapshot.scored = controller.hand_state.scored
	for roll in rolls:
		snapshot.rolled_faces.append(roll)
	snapshot.rerolled_die_ids_this_round = controller.hand_state.rerolled_die_ids_this_round.duplicate(true)
	for roll in rolls:
		if roll != null and roll.was_rerolled:
			snapshot.rerolled_die_ids_this_round[_die_key_for_roll(roll)] = true
	snapshot.body_triggered_flags_this_round = controller.hand_state.body_triggered_flags_this_round.duplicate(true)
	return snapshot


func _score_masks(roll_count: int, max_selected: int) -> Array[int]:
	var result: Array[int] = []
	var limit := 1 << roll_count
	for mask in range(1, limit):
		if _bit_count(mask) <= max_selected:
			result.append(mask)
	return result


func _clone_rolls(rolls: Array) -> Array[RolledFace]:
	var cloned: Array[RolledFace] = []
	for roll in rolls:
		cloned.append(_clone_roll(roll))
	return cloned


func _clone_roll(roll: RolledFace) -> RolledFace:
	var cloned := RolledFace.new()
	if roll == null:
		return cloned
	cloned.die_index = roll.die_index
	cloned.face_index = roll.face_index
	cloned.die_id = roll.die_id
	cloned.face_instance_id = roll.face_instance_id
	cloned.die = roll.die
	cloned.face = roll.face.clone() if roll.face != null else null
	cloned.rolled_pip = roll.rolled_pip
	cloned.locked = roll.locked
	cloned.selected = roll.selected
	cloned.was_rerolled = roll.was_rerolled
	cloned.is_scored = roll.is_scored
	cloned.is_unscored_stay = roll.is_unscored_stay
	cloned.is_temporary = roll.is_temporary
	return cloned


func _set_selection_mask(controller: BattleController, mask: int) -> void:
	if controller.hand_state == null:
		return
	for index in range(controller.hand_state.rolled_faces.size()):
		controller.hand_state.rolled_faces[index].selected = (mask & (1 << index)) != 0


func _is_better_score_action(candidate: Dictionary, current: Dictionary) -> bool:
	if current.is_empty():
		return true
	var candidate_score := int(candidate.get("score", 0))
	var current_score := int(current.get("score", 0))
	if candidate_score != current_score:
		return candidate_score > current_score
	var candidate_rank := _combo_rank(StringName(str(candidate.get("combo_id", &""))))
	var current_rank := _combo_rank(StringName(str(current.get("combo_id", &""))))
	if candidate_rank != current_rank:
		return candidate_rank > current_rank
	return int(candidate.get("risk", 0)) < int(current.get("risk", 0))


func _winning_sort_key(action: Dictionary) -> int:
	return int(action.get("risk", 0)) * 1000000 + int(action.get("score", 0))


func _selection_risk(rolls: Array, mask: int) -> int:
	var risk := 0
	for index in range(rolls.size()):
		if (mask & (1 << index)) == 0:
			continue
		var roll: RolledFace = rolls[index]
		if roll == null or roll.face == null:
			continue
		if roll.face.get_effective_ornament_id() == FaceState.ORN_BURST:
			risk += 100
		risk += 1
	return risk


func _piece_base_value(piece: ForgePieceDef) -> float:
	var value := 0.0
	for operation in piece.get_operations():
		match operation.get_effective_op():
			ForgeOperationDef.OP_SET_PIP:
				value += float(operation.get_effective_value_int()) * 4.0
			ForgeOperationDef.OP_SET_ORNAMENT:
				value += _ornament_reward_value(operation.get_effective_value_id())
			ForgeOperationDef.OP_SET_MARK:
				value += _mark_reward_value(operation.get_effective_value_id())
			ForgeOperationDef.OP_COMBO_UPGRADE:
				value += 75.0
			ForgeOperationDef.OP_CLEANSE:
				value += 5.0
	return value


func _target_face_value(piece: ForgePieceDef, face) -> float:
	if face == null:
		return -9999.0
	var value := 0.0
	for operation in piece.get_operations():
		match operation.get_effective_op():
			ForgeOperationDef.OP_SET_PIP:
				value += float(6 - face.pip) * 5.0
				value -= _face_power_score(face) * 0.25
			ForgeOperationDef.OP_SET_ORNAMENT:
				var ornament_id := FaceState.normalize_ornament_id(operation.get_effective_value_id())
				value += _ornament_target_value(ornament_id, face)
				value -= _ornament_reward_value(face.get_effective_ornament_id()) * 0.6
			ForgeOperationDef.OP_SET_MARK:
				var mark_id := FaceState.normalize_mark_id(operation.get_effective_value_id())
				value += _mark_target_value(mark_id, face)
				value -= _mark_reward_value(face.mark_id) * 0.6
	return value


func _ornament_reward_value(id: StringName) -> float:
	match FaceState.normalize_ornament_id(id):
		FaceState.ORN_POLY:
			return 95.0
		FaceState.ORN_BURST:
			return 80.0
		FaceState.ORN_HOLO:
			return 65.0
		FaceState.ORN_FOIL:
			return 55.0
		FaceState.ORN_STAY:
			return 52.0
		FaceState.ORN_WILD:
			return 45.0
		FaceState.ORN_STONE:
			return 42.0
		FaceState.ORN_LUCKY:
			return 34.0
		FaceState.ORN_MULT:
			return 32.0
		FaceState.ORN_CHIP:
			return 28.0
		FaceState.ORN_GOLD:
			return 18.0
		_:
			return 0.0


func _mark_reward_value(id: StringName) -> float:
	match FaceState.normalize_mark_id(id):
		FaceState.MARK_RED:
			return 55.0
		FaceState.MARK_BLUE:
			return 38.0
		FaceState.MARK_PURPLE:
			return 34.0
		FaceState.MARK_GOLD:
			return 22.0
		FaceState.MARK_WHITE:
			return 16.0
		_:
			return 0.0


func _ornament_target_value(ornament_id: StringName, face) -> float:
	match ornament_id:
		FaceState.ORN_STAY, FaceState.ORN_GOLD:
			return float(7 - face.pip) * 5.0
		FaceState.ORN_WILD:
			return float(6 - face.pip) * 3.0
		_:
			return float(face.pip) * 4.0


func _mark_target_value(mark_id: StringName, face) -> float:
	match mark_id:
		FaceState.MARK_RED:
			return float(face.pip) * 5.0 + _ornament_reward_value(face.get_effective_ornament_id()) * 0.35
		FaceState.MARK_BLUE:
			return _ornament_reward_value(face.get_effective_ornament_id()) * 0.3 + float(7 - face.pip) * 2.0
		FaceState.MARK_PURPLE:
			return float(7 - face.pip) * 3.0
		FaceState.MARK_WHITE:
			return _face_power_score(face) * 0.8
		_:
			return float(face.pip)


func _face_power_score(face) -> float:
	if face == null:
		return 0.0
	return float(face.pip) + _ornament_reward_value(face.get_effective_ornament_id()) + _mark_reward_value(face.mark_id)


func _install_reason(piece: ForgePieceDef, face) -> String:
	var op_texts := PackedStringArray()
	for operation in piece.get_operations():
		match operation.get_effective_op():
			ForgeOperationDef.OP_SET_PIP:
				op_texts.append("把低点数面改成高点数，提升六点密度与基础战力")
			ForgeOperationDef.OP_SET_ORNAMENT:
				var id := FaceState.normalize_ornament_id(operation.get_effective_value_id())
				if id == FaceState.ORN_STAY:
					op_texts.append("留场面饰适合装在低点数面，结算时可留作终倍率来源")
				elif id == FaceState.ORN_POLY or id == FaceState.ORN_BURST:
					op_texts.append("终倍率面饰优先给高点数面，配合主骰型放大得分")
				else:
					op_texts.append("该面饰能提高结算稳定收益")
			ForgeOperationDef.OP_SET_MARK:
				var id := FaceState.normalize_mark_id(operation.get_effective_value_id())
				if id == FaceState.MARK_RED:
					op_texts.append("红印适合放在高价值面上，重复触发可放大点数和面饰")
				elif id == FaceState.MARK_BLUE:
					op_texts.append("蓝印适合留场，能补倍率并产出骰型升级道具")
				else:
					op_texts.append("印记提供额外触发或保护价值")
	if op_texts.is_empty():
		return "当前可选目标中该面替换代价最低。"
	return "；".join(op_texts)


func _is_combo_upgrade_piece(piece: ForgePieceDef) -> bool:
	for operation in piece.get_operations():
		if operation.get_effective_op() == ForgeOperationDef.OP_COMBO_UPGRADE:
			return true
	return false


func _most_common_pip_mask(rolls: Array) -> int:
	var counts := {}
	for index in range(rolls.size()):
		var roll: RolledFace = rolls[index]
		if roll == null or roll.face == null:
			continue
		var pip := roll.face.pip
		var data: Dictionary = counts.get(pip, {"count": 0, "mask": 0})
		data["count"] = int(data["count"]) + 1
		data["mask"] = int(data["mask"]) | (1 << index)
		counts[pip] = data
	var best_mask := 0
	var best_count := 0
	for pip in counts.keys():
		var data: Dictionary = counts[pip]
		if int(data["count"]) > best_count:
			best_count = int(data["count"])
			best_mask = int(data["mask"])
	return best_mask


func _longest_straight_draw_mask(rolls: Array) -> int:
	var best_mask := 0
	var best_count := 0
	for start in range(1, 5):
		var mask := 0
		var seen := {}
		for index in range(rolls.size()):
			var roll: RolledFace = rolls[index]
			if roll == null or roll.face == null:
				continue
			var pip := roll.face.pip
			if pip < start or pip > start + 4 or seen.has(pip):
				continue
			seen[pip] = true
			mask |= (1 << index)
		if seen.size() > best_count:
			best_count = seen.size()
			best_mask = mask
	return best_mask


func _lowest_pip_mask(rolls: Array, count: int) -> int:
	var entries: Array[Dictionary] = []
	for index in range(rolls.size()):
		var roll: RolledFace = rolls[index]
		var pip := roll.face.pip if roll != null and roll.face != null else 99
		entries.append({"index": index, "pip": pip, "power": _face_power_score(roll.face) if roll != null and roll.face != null else 0.0})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["pip"]) == int(b["pip"]):
			return float(a["power"]) < float(b["power"])
		return int(a["pip"]) < int(b["pip"])
	)
	var mask := 0
	for i in range(min(count, entries.size())):
		mask |= (1 << int(entries[i]["index"]))
	return mask


func _add_unique_int(values: Array[int], value: int) -> void:
	if value != 0 and not values.has(value):
		values.append(value)


func _bit_count(mask: int) -> int:
	var count := 0
	var value := mask
	while value > 0:
		count += value & 1
		value = value >> 1
	return count


func _mask_to_indices(mask: int, count: int) -> Array[int]:
	var result: Array[int] = []
	for index in range(count):
		if (mask & (1 << index)) != 0:
			result.append(index)
	return result


func _indices_text(indices: Array[int]) -> String:
	var parts := PackedStringArray()
	for index in indices:
		parts.append("D%d" % [int(index) + 1])
	return "、".join(parts)


func _selected_faces_text(rolls: Array, mask: int) -> String:
	var parts := PackedStringArray()
	for index in range(rolls.size()):
		if (mask & (1 << index)) == 0:
			continue
		var roll: RolledFace = rolls[index]
		if roll == null or roll.face == null:
			continue
		parts.append("D%d=%s" % [index + 1, _face_report_text(roll.face)])
	return "，".join(parts)


func _rolls_summary(rolls: Array) -> String:
	var parts := PackedStringArray()
	for index in range(rolls.size()):
		var roll: RolledFace = rolls[index]
		if roll == null or roll.face == null:
			parts.append("D%d=空" % [index + 1])
		else:
			parts.append("D%d[%d面]=%s%s" % [
				index + 1,
				roll.face_index + 1,
				_face_report_text(roll.face),
				"（重投）" if roll.was_rerolled else "",
			])
	return "；".join(parts)


func _face_report_text(face) -> String:
	if face == null:
		return "空面"
	var parts := PackedStringArray()
	parts.append("%d点" % [face.pip])
	var ornament_id: StringName = face.get_effective_ornament_id()
	if not _is_none_ornament(ornament_id):
		parts.append(DisplayNames.ornament_name(ornament_id))
	if not _is_none_mark(face.mark_id):
		parts.append(DisplayNames.mark_name(face.mark_id))
	return " / ".join(parts)


func _action_short_text(action: Dictionary) -> String:
	return "%s；%s；%s；%d = %d 基础战力 × %d 倍率 × %s 终倍率" % [
		str(action.get("selected_text", "")),
		str(action.get("selected_faces", "")),
		str(action.get("combo_name", "")),
		int(action.get("score", 0)),
		int(action.get("chips", 0)),
		int(action.get("mult", 1)),
		_format_xmult(float(action.get("xmult", 1.0))),
	]


func _dice_loadout_summary(run_state: RunState) -> String:
	var parts := PackedStringArray()
	for die_index in range(run_state.dice.size()):
		var die = run_state.dice[die_index]
		if die == null:
			continue
		var face_parts := PackedStringArray()
		for face in die.faces:
			face_parts.append(_face_report_text(face))
		parts.append("D%d{%s}" % [die_index + 1, "；".join(face_parts)])
	return " | ".join(parts)


func _reward_choices_text(choices: Array) -> String:
	var parts := PackedStringArray()
	for choice in choices:
		var piece := choice as ForgePieceDef
		if piece != null:
			parts.append("%s（%s）" % [piece.get_display_name(), piece.get_tags_display_text()])
	return "；".join(parts)


func _append_run_summary(
	lines: PackedStringArray,
	run_state: RunState,
	battle_records: Array[Dictionary],
	reward_records: Array[Dictionary],
	elapsed_ms: int
) -> void:
	lines.append("")
	lines.append("## 本局汇总")
	lines.append("")
	lines.append("- 结果：%s" % ["通关" if run_state.run_won else "失败"])
	lines.append("- 推进：%d / %d 战" % [min(run_state.battle_index + (1 if run_state.run_won else 0), run_state.max_battles), run_state.max_battles])
	lines.append("- 本局耗时：%s" % [_format_duration_ms(elapsed_ms)])
	lines.append("- 结算手数：%d" % [run_state.total_hands_scored])
	lines.append("- 总结算战力：%d" % [run_state.total_score_scored])
	lines.append("- 最佳单手：%d" % [run_state.best_hand_score])
	lines.append("- 安装铸骰件：%d" % [run_state.installed_piece_count])
	lines.append("- 金币：%d" % [run_state.coins])
	lines.append("")
	lines.append("### 奖励路线")
	lines.append("")
	if reward_records.is_empty():
		lines.append("- 无。")
	else:
		for record in reward_records:
			lines.append("- 第 %d 战后：%s，安装位置：D%d 第%d面，%s -> %s" % [
				int(record.get("battle", 0)),
				str(record.get("piece_name", "")),
				int(record.get("die", 0)),
				int(record.get("face", 0)),
				str(record.get("before", "")),
				str(record.get("after", "")),
			])


func _build_summary_report(summaries: Array[Dictionary]) -> String:
	var lines := PackedStringArray()
	var wins := 0
	var total_battles := 0
	var total_best := 0
	var total_hands := 0
	var total_elapsed_ms := 0
	var fail_battles := {}

	for summary in summaries:
		if bool(summary.get("won", false)):
			wins += 1
		else:
			var battle := int(summary.get("battle_index", 0)) + 1
			fail_battles[battle] = int(fail_battles.get(battle, 0)) + 1
		total_battles += int(summary.get("battles_reached", 0))
		total_best += int(summary.get("best_hand_score", 0))
		total_hands += int(summary.get("total_hands", 0))
		total_elapsed_ms += int(summary.get("elapsed_ms", 0))

	lines.append("# 10 局自动游玩总报告")
	lines.append("")
	lines.append("- 报告目录：`%s`" % [report_dir])
	lines.append("- 自动玩家：枚举当前结算 + 骰型启发式重投 + 奖励启发式安装")
	lines.append("- 固定基础种子：`%d`" % [BASE_SEED])
	lines.append("- 完成局数：%d" % [summaries.size()])
	lines.append("- 通关局数：%d / %d" % [wins, summaries.size()])
	lines.append("- 平均推进战数：%.2f" % [float(total_battles) / float(max(1, summaries.size()))])
	lines.append("- 平均最佳单手：%.1f" % [float(total_best) / float(max(1, summaries.size()))])
	lines.append("- 总结算手数：%d" % [total_hands])
	lines.append("- 总运行耗时：%s" % [_format_duration_ms(total_elapsed_ms)])
	lines.append("- 平均每局耗时：%s" % [_format_duration_ms(int(total_elapsed_ms / max(1, summaries.size())))])
	lines.append("")
	lines.append("## 分局结果")
	lines.append("")
	lines.append("| 局数 | 结果 | 推进 | 耗时 | 结算手数 | 总结算战力 | 最佳单手 | 安装数 | 金币 |")
	lines.append("|---:|---|---:|---:|---:|---:|---:|---:|---:|")
	for summary in summaries:
		lines.append("| %02d | %s | %d | %s | %d | %d | %d | %d | %d |" % [
			int(summary.get("run_number", 0)),
			str(summary.get("status", "")),
			int(summary.get("battles_reached", 0)),
			_format_duration_ms(int(summary.get("elapsed_ms", 0))),
			int(summary.get("total_hands", 0)),
			int(summary.get("total_score", 0)),
			int(summary.get("best_hand_score", 0)),
			int(summary.get("installed_piece_count", 0)),
			int(summary.get("coins", 0)),
		])
	lines.append("")
	lines.append("## 失败分布")
	lines.append("")
	if fail_battles.is_empty():
		lines.append("- 10 局均通关。")
	else:
		for battle in fail_battles.keys():
			lines.append("- 第 %d 战附近失败：%d 次" % [int(battle), int(fail_battles[battle])])
	lines.append("")
	lines.append("## 奖励路线总览")
	lines.append("")
	_append_reward_overview_lines(lines, summaries)
	lines.append("")
	lines.append("## 详细报告索引")
	lines.append("")
	for summary in summaries:
		lines.append("- [第 %02d 局](run_%02d.md)" % [int(summary.get("run_number", 0)), int(summary.get("run_number", 0))])
	lines.append("- [奖励路线总览](rewards_overview.md)")
	return "\n".join(lines)


func _build_reward_overview_report(summaries: Array[Dictionary]) -> String:
	var lines := PackedStringArray()
	lines.append("# 奖励路线总览")
	lines.append("")
	lines.append("这里汇总每次战斗胜利后的 3 选 1 奖励、实际选择和安装结果。更完整的手牌过程见各 `run_XX.md`。")
	lines.append("")
	_append_reward_overview_lines(lines, summaries)
	return "\n".join(lines)


func _append_reward_overview_lines(lines: PackedStringArray, summaries: Array[Dictionary]) -> void:
	for summary in summaries:
		var run_number := int(summary.get("run_number", 0))
		var rewards: Array = summary.get("reward_records", [])
		lines.append("### 第 %02d 局" % [run_number])
		if rewards.is_empty():
			lines.append("")
			lines.append("- 未战胜任何战斗，因此没有进入奖励选择。")
			lines.append("")
			continue
		lines.append("")
		for reward in rewards:
			lines.append("- 第 %d 战后：选择 %s，安装到 D%d 第%d面，%s -> %s。" % [
				int(reward.get("battle", 0)),
				str(reward.get("piece_name", "")),
				int(reward.get("die", 0)),
				int(reward.get("face", 0)),
				str(reward.get("before", "")),
				str(reward.get("after", "")),
			])
		lines.append("")


func _build_optimization_report(summaries: Array[Dictionary]) -> String:
	var wins := 0
	var fail_targets := {}
	var picked_rewards := {}
	var total_battles := 0
	for summary in summaries:
		if bool(summary.get("won", false)):
			wins += 1
		total_battles += int(summary.get("battles_reached", 0))
		for battle in summary.get("battle_records", []):
			if not bool(battle.get("victory", false)):
				var key := "第 %d 战（目标 %d）" % [int(battle.get("battle", 0)), int(battle.get("target", 0))]
				fail_targets[key] = int(fail_targets.get(key, 0)) + 1
		for reward in summary.get("reward_records", []):
			var name := str(reward.get("piece_name", ""))
			if name != "":
				picked_rewards[name] = int(picked_rewards.get(name, 0)) + 1

	var lines := PackedStringArray()
	lines.append("# 自动游玩优化建议")
	lines.append("")
	lines.append("## 结论")
	lines.append("")
	lines.append("- 10 局通关率：%d / %d。" % [wins, summaries.size()])
	lines.append("- 平均推进战数：%.2f。" % [float(total_battles) / float(max(1, summaries.size()))])
	lines.append("- 本报告基于自动玩家策略，不等同于数学最优解，但能稳定暴露目标曲线、奖励收益和操作反馈问题。")
	lines.append("")
	lines.append("## 建议")
	lines.append("")
	if wins == summaries.size():
		lines.append("- 当前目标曲线对该自动策略偏宽松。建议调高第 12 战后的目标战力，或降低终倍率类铸骰件出现频率，避免成型后滚雪球过快。")
	elif wins == 0:
		lines.append("- 新曲线已经明显给出前期发育空间，但自动玩家仍未通关。建议优先下调失败集中战斗的目标，或增强第 4-6 战奖励后的成长速度。")
	else:
		lines.append("- 通关率处于可调区间。建议重点观察失败集中战斗，而不是整体调高或调低所有目标。")

	if not fail_targets.is_empty():
		lines.append("- 失败集中点：%s。建议优先检查这些战斗前后的目标跃迁和奖励强度。" % [_dict_count_text(fail_targets)])
	lines.append("- 前 3 战目前更接近“发育期”：多数局能拿到多个铸骰件。下一轮调参重点不应继续大砍开局，而应观察第 5-8 战是否在构筑尚未成型前抬得过快。")
	lines.append("- 奖励策略上，终倍率面饰和红印的长期收益明显高于纯点数片。若希望点数片更有存在感，可以增加点数片的复合协同，或让部分骰型升级依赖点数分布。")
	lines.append("- 当前自动玩家必须用完整结算 trace 才能正确评估留场面饰、红印、蓝印等收益。建议检查 UI 预览是否覆盖所有结算效果，否则玩家容易低估留场与印记。")
	lines.append("- 爆裂面饰有破裂风险，但短期终倍率非常强。建议在 UI 中强化“本次会冒破裂风险”的中文提示，并在奖励描述中明确它是高风险爆发件。")
	lines.append("- 若后续加入更多骰胚/骰具，建议给自动测试保留这个脚本，作为目标曲线回归测试：每次改平衡后跑固定 10 局，比较通关率、失败战斗和最佳单手变化。")
	lines.append("")
	lines.append("## 常选奖励")
	lines.append("")
	if picked_rewards.is_empty():
		lines.append("- 无奖励记录。")
	else:
		lines.append("- %s" % [_dict_count_text(picked_rewards)])
	return "\n".join(lines)


func _dict_count_text(counts: Dictionary) -> String:
	var parts := PackedStringArray()
	for key in counts.keys():
		parts.append("%s × %d" % [str(key), int(counts[key])])
	return "；".join(parts)


func _create_report_dir() -> String:
	var now := Time.get_datetime_dict_from_system()
	var dir_name := "auto_playtest_%04d%02d%02d_%02d%02d%02d" % [
		int(now["year"]),
		int(now["month"]),
		int(now["day"]),
		int(now["hour"]),
		int(now["minute"]),
		int(now["second"]),
	]
	var root_abs := ProjectSettings.globalize_path(REPORT_ROOT)
	DirAccess.make_dir_recursive_absolute(root_abs)
	var dir := "%s/%s" % [REPORT_ROOT, dir_name]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	return dir


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("无法写入报告：%s" % [path])
		return
	file.store_string(text)
	file.close()


func _seed_report_services(seed_value: int) -> void:
	reward_generator.rng.seed = seed_value + 1
	dice_tool_service.rng.seed = seed_value + 2
	_seed_score_engine_services(score_engine, seed_value + 3)


func _seed_score_engine_services(engine: ScoreEngine, seed_value: int) -> void:
	if engine == null:
		return
	engine.dice_tool_service.rng.seed = seed_value + 1
	engine.effect_resolver.dice_tool_service.rng.seed = seed_value + 2
	engine.effect_resolver.reward_generator.rng.seed = seed_value + 3


func _is_last_hand(controller: BattleController) -> bool:
	if controller.hand_state == null or controller.battle_state == null:
		return false
	return controller.hand_state.hand_index >= max(0, controller.battle_state.config.hands_per_battle - 1)


func _any_roll_was_rerolled(rolls: Array) -> bool:
	for roll in rolls:
		if roll != null and roll.was_rerolled:
			return true
	return false


func _die_key_for_roll(roll: RolledFace) -> StringName:
	if roll == null:
		return &""
	if roll.die_id != &"":
		return roll.die_id
	if roll.die != null:
		return roll.die.die_id if roll.die.die_id != &"" else roll.die.id
	return StringName("die_%d" % [roll.die_index])


func _combo_rank(combo_id: StringName) -> int:
	match combo_id:
		&"five_kind":
			return 7
		&"straight":
			return 6
		&"four_kind":
			return 5
		&"full_house":
			return 4
		&"three_kind":
			return 3
		&"two_pair":
			return 2
		&"pair":
			return 1
		_:
			return 0


func _is_none_ornament(value: StringName) -> bool:
	return value == &"" or value == &"none" or value == FaceState.ORN_NONE


func _is_none_mark(value: StringName) -> bool:
	return value == &"" or value == &"none" or value == FaceState.MARK_NONE


func _format_xmult(value: float) -> String:
	return str(ceili(value))


func _format_duration_ms(elapsed_ms: int) -> String:
	return "%.2f 秒" % [float(max(0, elapsed_ms)) / 1000.0]
