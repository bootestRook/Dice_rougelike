extends Control
class_name BattleScreen


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")
const ComboEvaluator = preload("res://scripts/rules/combo/ComboEvaluator.gd")
const ComboUpgradeItem = preload("res://scripts/rules/combo/ComboUpgradeItem.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")
const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const SlotViewData = preload("res://scripts/ui/battle/view_models/SlotViewData.gd")
const ComboInfoRowData = preload("res://scripts/ui/battle/view_models/ComboInfoRowData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleIconLibrary = preload("res://scripts/ui/battle/resources/BattleIconLibrary.gd")
const DiceVisualLibrary = preload("res://scripts/ui/battle/resources/DiceVisualLibrary.gd")


@export var style_config: BattleUiStyleConfig = preload("res://scenes/battle/resources/BattleUiStyleConfig.tres")
@export var icon_library: BattleIconLibrary = preload("res://scenes/battle/resources/BattleIconLibrary.tres")
@export var dice_visual_library: DiceVisualLibrary = preload("res://scenes/battle/resources/DiceVisualLibrary.tres")
@export var left_sidebar_scene: PackedScene = preload("res://scenes/battle/components/LeftBattleSidebar.tscn")
@export var top_inventory_bar_scene: PackedScene = preload("res://scenes/battle/components/TopInventoryBar.tscn")
@export var inventory_slot_view_scene: PackedScene = preload("res://scenes/battle/components/InventorySlotView.tscn")
@export var segment_scoring_area_scene: PackedScene = preload("res://scenes/battle/components/SegmentScoringArea.tscn")
@export var dice_bench_area_scene: PackedScene = preload("res://scenes/battle/components/DiceBenchArea.tscn")
@export var dice_view_scene: PackedScene = preload("res://scenes/battle/components/DiceView.tscn")
@export var dice_info_popup_scene: PackedScene = preload("res://scenes/battle/components/DiceInfoPopup.tscn")
@export var face_info_card_scene: PackedScene = preload("res://scenes/battle/components/FaceInfoCard.tscn")
@export var combo_info_popup_scene: PackedScene = preload("res://scenes/battle/components/ComboInfoPopup.tscn")
@export var combo_info_row_scene: PackedScene = preload("res://scenes/battle/components/ComboInfoRow.tscn")
@export var score_log_row_scene: PackedScene = preload("res://scenes/battle/components/ScoreLogRow.tscn")
@export var floating_score_text_scene: PackedScene = preload("res://scenes/battle/components/FloatingScoreText.tscn")
@export var design_resolution: Vector2 = Vector2(1920, 1080)
@export var relic_capacity: int = 6
@export var item_capacity: int = 3


var controller: BattleController = null
var game_flow_controller: GameFlowController = null
var run_state: RunState = null
var left_sidebar: Control = null
var top_inventory_bar: Control = null
var scoring_area: Control = null
var dice_bench_area: Control = null
var combo_info_popup: Control = null
var layout_root: Control = null
var last_score_result: ScoreResult = null
var current_preview_result: ScoreResult = null
var status_text: String = "战斗准备中。"
var wild_selection_dialog: ConfirmationDialog = null
var wild_button_rows: Dictionary = {}
var local_combo_appearance_counts: Dictionary = {}
var local_combo_last_formula_by_id: Dictionary = {}


func setup(new_game_flow_controller: GameFlowController = null, new_run_state: RunState = null) -> void:
	game_flow_controller = new_game_flow_controller
	run_state = new_run_state


func _ready() -> void:
	_ensure_resources()
	_build_view()
	_create_controller()
	controller.start_battle(null, run_state)
	call_deferred("_apply_resolution_scale")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_resolution_scale()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if _is_combo_info_popup_visible():
			return
		if dice_bench_area == null:
			return
		if not dice_bench_area.has_method("is_info_visible") or not dice_bench_area.is_info_visible():
			return
		if dice_bench_area.has_method("is_global_point_inside_info_popup") and dice_bench_area.is_global_point_inside_info_popup(mouse_event.position):
			return
		if dice_bench_area.has_method("hide_info"):
			dice_bench_area.hide_info()


func _build_view() -> void:
	var background := ColorRect.new()
	background.color = style_config.background_color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	layout_root = Control.new()
	layout_root.name = "ResolutionScaledBattleLayout"
	layout_root.size = design_resolution
	add_child(layout_root)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	style_config.apply_margin(margin, style_config.outer_margin)
	layout_root.add_child(margin)

	var root := HBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", style_config.layout_gap)
	margin.add_child(root)

	left_sidebar = _instantiate_control(left_sidebar_scene, PanelContainer.new())
	root.add_child(left_sidebar)
	if left_sidebar.has_method("setup_style"):
		left_sidebar.setup_style(style_config)
	if left_sidebar.has_signal("info_pressed"):
		left_sidebar.info_pressed.connect(_on_info_pressed)
	if left_sidebar.has_signal("options_pressed"):
		left_sidebar.options_pressed.connect(_on_options_pressed)

	var main_area := VBoxContainer.new()
	main_area.name = "MainBattleArea"
	main_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_area.add_theme_constant_override("separation", style_config.layout_gap)
	root.add_child(main_area)

	top_inventory_bar = _instantiate_control(top_inventory_bar_scene, HBoxContainer.new())
	main_area.add_child(top_inventory_bar)
	if top_inventory_bar.has_method("setup"):
		top_inventory_bar.setup(style_config, icon_library, inventory_slot_view_scene)

	scoring_area = _instantiate_control(segment_scoring_area_scene, PanelContainer.new())
	scoring_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_area.add_child(scoring_area)
	if scoring_area.has_method("setup"):
		scoring_area.setup(style_config, score_log_row_scene, floating_score_text_scene)

	dice_bench_area = _instantiate_control(dice_bench_area_scene, PanelContainer.new())
	main_area.add_child(dice_bench_area)
	if dice_bench_area.has_method("setup"):
		dice_bench_area.setup(
			style_config,
			icon_library,
			dice_visual_library,
			dice_view_scene,
			dice_info_popup_scene,
			face_info_card_scene
		)
	if dice_bench_area.has_signal("die_pressed"):
		dice_bench_area.die_pressed.connect(_on_die_pressed)
	if dice_bench_area.has_signal("die_hovered"):
		dice_bench_area.die_hovered.connect(_on_die_hovered)
	if dice_bench_area.has_signal("die_info_requested"):
		dice_bench_area.die_info_requested.connect(_on_die_info_requested)
	if dice_bench_area.has_signal("ornament_link_requested"):
		dice_bench_area.ornament_link_requested.connect(_on_ornament_link_requested)
	if dice_bench_area.has_signal("mark_link_requested"):
		dice_bench_area.mark_link_requested.connect(_on_mark_link_requested)
	if dice_bench_area.has_signal("reroll_pressed"):
		dice_bench_area.reroll_pressed.connect(_on_reroll_pressed)
	if dice_bench_area.has_signal("score_pressed"):
		dice_bench_area.score_pressed.connect(_on_score_pressed)

	_ensure_combo_info_popup()


func _apply_resolution_scale() -> void:
	if layout_root == null:
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var scale_factor: float = minf(
		viewport_size.x / max(1.0, design_resolution.x),
		viewport_size.y / max(1.0, design_resolution.y)
	)
	layout_root.size = design_resolution
	layout_root.scale = Vector2(scale_factor, scale_factor)
	layout_root.position = (viewport_size - design_resolution * scale_factor) * 0.5


func _create_controller() -> void:
	controller = BattleController.new()
	add_child(controller)
	controller.battle_started.connect(_on_battle_started)
	controller.hand_started.connect(_on_hand_started)
	controller.dice_changed.connect(_on_dice_changed)
	controller.rerolls_changed.connect(_on_rerolls_changed)
	controller.score_changed.connect(_on_score_changed)
	controller.selection_changed.connect(_on_selection_changed)
	controller.hand_scored.connect(_on_hand_scored)
	controller.battle_won.connect(_on_battle_won)
	controller.battle_lost.connect(_on_battle_lost)
	controller.phase_changed.connect(_on_phase_changed)
	controller.score_preview_changed.connect(_on_score_preview_changed)


func _on_battle_started() -> void:
	last_score_result = null
	current_preview_result = null
	local_combo_appearance_counts.clear()
	local_combo_last_formula_by_id.clear()
	status_text = "战斗开始。选择骰子后，可以重投所选，或直接结算所选。"
	_refresh_hud()


func _on_hand_started(_hand_index: int) -> void:
	current_preview_result = null
	status_text = "选择要重投或结算的骰子。"
	_refresh_hud()


func _on_dice_changed(_rolls: Array) -> void:
	_refresh_hud()


func _on_rerolls_changed(_rerolls_left: int) -> void:
	_refresh_hud()


func _on_score_changed(_total_score: int, _target_score: int) -> void:
	_refresh_hud()


func _on_selection_changed(selected_count: int) -> void:
	status_text = "已选择：%d / %d" % [selected_count, controller.get_max_selected_dice() if controller != null else 0]
	_refresh_hud()


func _on_hand_scored(result: ScoreResult) -> void:
	last_score_result = result
	current_preview_result = null
	_record_local_combo_stats(result)
	status_text = "本手结算：%d 战力。" % [result.final_score]
	if game_flow_controller != null:
		game_flow_controller.record_hand_score(result, controller.get_current_hand_number())
	elif run_state != null:
		run_state.record_hand_score(result, controller.get_current_hand_number())
	if scoring_area != null and scoring_area.has_method("show_floating_score"):
		scoring_area.show_floating_score("+%d" % [result.final_score])
		for event in result.floating_texts:
			var text := str(event.get("text", ""))
			if text != "":
				scoring_area.show_floating_score(text)
	_refresh_hud()


func _on_battle_won() -> void:
	status_text = "战斗胜利"
	_refresh_hud()
	if game_flow_controller != null:
		call_deferred("_notify_battle_won")


func _on_battle_lost() -> void:
	status_text = "战斗失败"
	_refresh_hud()
	if game_flow_controller != null:
		call_deferred("_notify_battle_lost")


func _on_phase_changed(_phase: int) -> void:
	_refresh_hud()


func _on_score_preview_changed(result: ScoreResult) -> void:
	current_preview_result = result
	_refresh_hud()


func _on_info_pressed() -> void:
	_show_combo_info_popup()


func _on_options_pressed() -> void:
	status_text = "选项暂未开放。"
	_refresh_hud()


func _on_die_pressed(index: int) -> void:
	if controller == null:
		return
	controller.toggle_select(index)


func _on_die_info_requested(index: int) -> void:
	if controller == null:
		return
	if dice_bench_area == null:
		return
	if dice_bench_area.has_method("request_info_for_die"):
		dice_bench_area.request_info_for_die(index)
	elif dice_bench_area.has_method("show_info_for_die"):
		dice_bench_area.show_info_for_die(index)


func _on_ornament_link_requested(id: StringName) -> void:
	_show_ornament_info_popup(id)


func _on_mark_link_requested(id: StringName) -> void:
	_show_mark_info_popup(id)


func _on_die_hovered(_index: int) -> void:
	pass


func _on_reroll_pressed() -> void:
	if controller != null:
		controller.reroll()


func _on_score_pressed() -> void:
	if controller == null:
		return
	var wild_requests := controller.get_selected_wild_face_requests()
	if wild_requests.is_empty():
		controller.score_selected()
		return
	_show_wild_selection_dialog(wild_requests)


func _refresh_hud() -> void:
	if left_sidebar == null or top_inventory_bar == null or scoring_area == null or dice_bench_area == null:
		return

	var state := _build_hud_state()
	if left_sidebar.has_method("render"):
		left_sidebar.render(state)
	if top_inventory_bar.has_method("render"):
		top_inventory_bar.render(state)
	if scoring_area.has_method("render"):
		scoring_area.render(state)
	if dice_bench_area.has_method("render"):
		dice_bench_area.render(state)
	if _is_combo_info_popup_visible() and combo_info_popup.has_method("render"):
		combo_info_popup.render(_build_combo_info_rows())


func _build_hud_state() -> BattleHudState:
	var state := BattleHudState.new()
	state.relic_capacity = relic_capacity
	state.item_capacity = item_capacity
	state.relics = _build_relic_slots()
	state.items = _build_item_slots()
	state.money = _get_money()
	state.status_text = status_text

	if run_state != null:
		state.battle_number = run_state.battle_index + 1
		state.max_battles = run_state.max_battles
		state.item_capacity = run_state.item_slot_capacity

	if controller == null:
		state.preview_text = "计分预览\n等待战斗开始。"
		return state

	state.target_score = controller.get_target_score()
	state.current_score = controller.get_total_score()
	state.rerolls_left = controller.get_rerolls_left()
	state.rerolls_total = controller.get_rerolls_per_hand()
	state.current_hand = controller.get_current_hand_number()
	state.max_hands = controller.get_hands_per_battle()
	state.phase_text = DisplayNames.phase_name(controller.get_phase_name())
	state.can_reroll = controller.can_reroll()
	state.can_score = controller.can_score()
	state.dice_results = _build_die_view_data()
	state.selected_dice_indices = _selected_dice_indices()
	state.score_log = _score_log_lines()
	state.preview_text = _preview_text()

	var formula_result := current_preview_result if current_preview_result != null else last_score_result
	if formula_result != null:
		state.core_combo_name = _combo_name(formula_result)
		state.base_chips = formula_result.chips
		state.base_mult = formula_result.mult
		state.xmult = formula_result.xmult
		state.formula_score = formula_result.final_score

	return state


func _build_die_view_data() -> Array[DieViewData]:
	var result: Array[DieViewData] = []
	var dice := _get_dice()
	var rolled_by_die := _current_rolls_by_die()
	var dice_enabled := controller != null and controller.get_phase() == BattleController.BattlePhase.WAITING_ACTION
	var hand_scored := controller != null and controller.hand_state != null and controller.hand_state.scored

	for die_index in range(dice.size()):
		var rolled_face = rolled_by_die.get(die_index, null)
		var disabled := rolled_face == null or not dice_enabled
		var die_data = DieViewData.new()
		die_data.setup_from_die(dice[die_index], die_index, rolled_face, dice_enabled, hand_scored, disabled)
		result.append(die_data)

	return result


func _build_relic_slots() -> Array[SlotViewData]:
	var slots: Array[SlotViewData] = []
	if run_state == null:
		return slots

	for relic_id in run_state.relic_ids:
		var slot_data = SlotViewData.new()
		slot_data.setup_from_id(relic_id, str(relic_id), relic_id)
		slots.append(slot_data)

	return slots


func _build_item_slots() -> Array[SlotViewData]:
	var slots: Array[SlotViewData] = []
	if run_state != null:
		run_state.ensure_item_slots_from_legacy()
		for item in run_state.item_slots:
			if item == null:
				continue
			var slot_data = SlotViewData.new()
			slot_data.setup_from_id(item.item_id, _item_display_name(item.item_id), item.item_id)
			slot_data.tooltip = item.display_name
			slots.append(slot_data)
		return slots

	var item_ids = _get_optional_property(&"item_ids")
	if item_ids is Array:
		for item_id in item_ids:
			var id := StringName(str(item_id))
			var slot_data = SlotViewData.new()
			slot_data.setup_from_id(id, _item_display_name(id), id)
			slots.append(slot_data)
	return slots


func _selected_dice_indices() -> Array[int]:
	var result: Array[int] = []
	if controller == null:
		return result
	for rolled_face in controller.get_current_rolls():
		if rolled_face.selected:
			result.append(rolled_face.die_index)
	return result


func _is_die_selected(index: int) -> bool:
	if controller == null:
		return false
	for rolled_face in controller.get_current_rolls():
		if int(rolled_face.die_index) == index:
			return bool(rolled_face.selected)
	return false


func _preview_text() -> String:
	if current_preview_result != null:
		return "计分预览\n%s" % [current_preview_result.get_summary_text_zh()]

	var selected_count := _selected_dice_indices().size()
	var max_selected := controller.get_max_selected_dice() if controller != null else 0
	if max_selected > 0 and selected_count > max_selected:
		return "计分预览\n已选择 %d / %d，最多只能结算 %d 颗骰子。" % [selected_count, max_selected, max_selected]
	return "计分预览\n未选择骰子。"


func _score_log_lines() -> Array[String]:
	var lines: Array[String] = []
	if last_score_result == null:
		lines.append("选择骰子后，可以重投所选，或直接结算所选。")
		lines.append("本手结算动画、分数日志和触发文本会显示在这里。")
		return lines

	lines.append("上次结算")
	lines.append("实际结算战力：%d" % [last_score_result.final_score])
	for line in last_score_result.get_summary_text_zh().split("\n"):
		lines.append(line)
	lines.append("结算日志")
	for entry in last_score_result.logs:
		lines.append(entry.get_text())
	return lines


func _combo_name(result: ScoreResult) -> String:
	if result == null:
		return "未选择"
	var combo_id := result.primary_combo
	if combo_id == &"":
		combo_id = result.combo_id
	return DisplayNames.combo_name(combo_id) if combo_id != &"" else "无"


func _show_combo_info_popup() -> void:
	_ensure_combo_info_popup()
	if combo_info_popup == null:
		return
	if dice_bench_area != null and dice_bench_area.has_method("hide_info"):
		dice_bench_area.hide_info()
	combo_info_popup.visible = true
	if combo_info_popup.has_method("render"):
		combo_info_popup.render(_build_combo_info_rows())


func _show_ornament_info_popup(id: StringName) -> void:
	_ensure_combo_info_popup()
	if combo_info_popup == null:
		return
	if dice_bench_area != null and dice_bench_area.has_method("hide_info"):
		dice_bench_area.hide_info()
	combo_info_popup.visible = true
	if combo_info_popup.has_method("show_ornament_tab"):
		combo_info_popup.show_ornament_tab(id)


func _show_mark_info_popup(id: StringName) -> void:
	_ensure_combo_info_popup()
	if combo_info_popup == null:
		return
	if dice_bench_area != null and dice_bench_area.has_method("hide_info"):
		dice_bench_area.hide_info()
	combo_info_popup.visible = true
	if combo_info_popup.has_method("show_mark_tab"):
		combo_info_popup.show_mark_tab(id)


func _hide_combo_info_popup() -> void:
	if combo_info_popup != null:
		combo_info_popup.visible = false


func _is_combo_info_popup_visible() -> bool:
	return combo_info_popup != null and combo_info_popup.visible


func _build_combo_info_rows() -> Array[ComboInfoRowData]:
	var rows: Array[ComboInfoRowData] = []
	var active_result := current_preview_result if current_preview_result != null else last_score_result
	var active_combo_id := _normalized_combo_id(_result_combo_id(active_result))

	for combo_id in _combo_info_order():
		var normalized_id := _normalized_combo_id(combo_id)
		var formula := _combo_formula_for_row(normalized_id, active_result, active_combo_id)
		var row_data := ComboInfoRowData.new()
		row_data.setup(
			normalized_id,
			DisplayNames.combo_name(normalized_id),
			_combo_level(normalized_id),
			int(formula.get("chips", 0)),
			int(formula.get("mult", 1)),
			_combo_appearance_count(normalized_id),
			active_combo_id != &"" and normalized_id == active_combo_id
		)
		rows.append(row_data)

	return rows


func _combo_info_order() -> Array[StringName]:
	return [
		ComboEvaluator.FIVE_KIND,
		ComboEvaluator.STRAIGHT,
		ComboEvaluator.FOUR_KIND,
		ComboEvaluator.FULL_HOUSE,
		ComboEvaluator.THREE_KIND,
		ComboEvaluator.TWO_PAIR,
		ComboEvaluator.PAIR,
		ComboEvaluator.SCATTER,
	]


func _combo_formula_for_row(combo_id: StringName, active_result: ScoreResult, active_combo_id: StringName) -> Dictionary:
	if active_result != null and active_combo_id == combo_id:
		return {
			"chips": active_result.combo_chips_bonus,
			"mult": active_result.combo_mult,
		}

	var last_formula := _combo_last_formula(combo_id)
	if not last_formula.is_empty():
		return last_formula

	return _base_formula_for_combo(combo_id)


func _base_formula_for_combo(combo_id: StringName) -> Dictionary:
	var engine = controller.score_engine if controller != null else ScoreEngine.new()
	if engine != null and engine.has_method("get_base_values_for_combo"):
		if run_state != null and run_state.has_method("ensure_combo_levels"):
			run_state.ensure_combo_levels()
		var combo_levels := run_state.combo_levels if run_state != null else {}
		return engine.get_base_values_for_combo(combo_id, 0, combo_levels)
	return {"chips": 0, "mult": 1}


func _combo_appearance_count(combo_id: StringName) -> int:
	var normalized_id := _normalized_combo_id(combo_id)
	if run_state != null:
		return run_state.get_combo_appearance_count(normalized_id)
	return int(local_combo_appearance_counts.get(normalized_id, 0))


func _combo_level(combo_id: StringName) -> int:
	var normalized_id := _normalized_combo_id(combo_id)
	if run_state != null:
		return run_state.get_combo_level(normalized_id)
	return 1


func _combo_last_formula(combo_id: StringName) -> Dictionary:
	var normalized_id := _normalized_combo_id(combo_id)
	if run_state != null:
		return run_state.get_combo_last_formula(normalized_id)
	if not local_combo_last_formula_by_id.has(normalized_id):
		return {}
	return local_combo_last_formula_by_id[normalized_id].duplicate(true)


func _record_local_combo_stats(result: ScoreResult) -> void:
	var combo_id := _normalized_combo_id(_result_combo_id(result))
	if combo_id == &"":
		return
	local_combo_appearance_counts[combo_id] = int(local_combo_appearance_counts.get(combo_id, 0)) + 1
	local_combo_last_formula_by_id[combo_id] = {
		"chips": result.combo_chips_bonus,
		"mult": result.combo_mult,
	}


func _result_combo_id(result: ScoreResult) -> StringName:
	if result == null:
		return &""
	if result.primary_combo != &"":
		return result.primary_combo
	return result.combo_id


func _normalized_combo_id(combo_id: StringName) -> StringName:
	return ComboEvaluator.new().normalize_combo_id(combo_id) if combo_id != &"" else &""


func _item_display_name(item_id: StringName) -> String:
	var text := str(item_id)
	var item := ComboUpgradeItem.from_item_id(item_id)
	if item != null:
		return item.display_name
	var forge_def := ForgeItemCatalog.get_def(item_id)
	if forge_def != null:
		return forge_def.get_display_name()
	var forge_name := ForgeItemCatalog.display_name_for_id(item_id)
	if forge_name != text:
		return forge_name
	return text


func _get_dice() -> Array:
	if controller != null and not controller.dice.is_empty():
		return controller.dice
	if run_state != null:
		run_state.ensure_starting_dice()
		return run_state.dice
	return []


func _current_rolls_by_die() -> Dictionary:
	var result := {}
	if controller == null:
		return result
	for rolled_face in controller.get_current_rolls():
		result[rolled_face.die_index] = rolled_face
	return result


func _get_money() -> int:
	if run_state != null:
		return run_state.coins
	var value = _get_optional_property(&"money")
	return int(value) if value != null else 0


func _show_wild_selection_dialog(requests: Array[Dictionary]) -> void:
	_ensure_wild_selection_dialog()
	if wild_selection_dialog == null:
		controller.score_selected()
		return

	wild_button_rows.clear()
	var root := wild_selection_dialog.get_node_or_null("WildSelectionRoot/Rows")
	if root == null:
		return
	_clear_children(root)

	var title := Label.new()
	title.text = "为每个万能面饰选择本手临时点数"
	root.add_child(title)

	for request in requests:
		var key := str(request.get("key", ""))
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		root.add_child(row)

		var label := Label.new()
		label.text = "骰子 %d / 面 %d，原始点数 %d" % [
			int(request.get("die_index", -1)) + 1,
			int(request.get("face_index", -1)) + 1,
			int(request.get("original_pip", 0)),
		]
		row.add_child(label)

		var buttons := HBoxContainer.new()
		buttons.add_theme_constant_override("separation", 6)
		row.add_child(buttons)

		var group := ButtonGroup.new()
		var row_buttons: Array[Button] = []
		var default_pip := int(request.get("default_pip", request.get("original_pip", 1)))
		for option in request.get("options", []):
			var pip := int(option)
			var button := Button.new()
			button.text = str(pip)
			button.toggle_mode = true
			button.button_group = group
			button.button_pressed = pip == default_pip
			button.set_meta("pip", pip)
			buttons.add_child(button)
			row_buttons.append(button)
		if not row_buttons.is_empty() and group.get_pressed_button() == null:
			row_buttons[0].button_pressed = true
		wild_button_rows[key] = row_buttons

	wild_selection_dialog.popup_centered()


func _ensure_wild_selection_dialog() -> void:
	if wild_selection_dialog != null:
		return
	wild_selection_dialog = ConfirmationDialog.new()
	wild_selection_dialog.name = "WildSelectionDialog"
	wild_selection_dialog.title = "万能面饰点数选择"
	wild_selection_dialog.ok_button_text = "确认"
	wild_selection_dialog.cancel_button_text = "取消"
	wild_selection_dialog.exclusive = true
	wild_selection_dialog.confirmed.connect(_confirm_wild_selection)
	add_child(wild_selection_dialog)

	var margin := MarginContainer.new()
	margin.name = "WildSelectionRoot"
	margin.custom_minimum_size = Vector2(520, 160)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	wild_selection_dialog.add_child(margin)

	var rows := VBoxContainer.new()
	rows.name = "Rows"
	rows.add_theme_constant_override("separation", 12)
	margin.add_child(rows)


func _confirm_wild_selection() -> void:
	if controller == null:
		return
	var selections := {}
	for key in wild_button_rows.keys():
		for button in wild_button_rows[key]:
			if button.button_pressed:
				selections[key] = int(button.get_meta("pip", 1))
				break
	controller.score_selected(selections)


func _get_optional_property(property_name: StringName):
	if run_state == null:
		return null
	var property_key := str(property_name)
	for property in run_state.get_property_list():
		if str(property.get("name", "")) == property_key:
			return run_state.get(property_name)
	return null


func _ensure_combo_info_popup() -> void:
	if combo_info_popup != null:
		return
	if layout_root == null:
		return

	combo_info_popup = _instantiate_control(combo_info_popup_scene, Control.new())
	combo_info_popup.name = "ComboInfoPopup"
	combo_info_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	combo_info_popup.z_index = 200
	layout_root.add_child(combo_info_popup)
	if combo_info_popup.has_method("setup"):
		combo_info_popup.setup(style_config, combo_info_row_scene)
	if combo_info_popup.has_signal("close_requested"):
		combo_info_popup.close_requested.connect(_hide_combo_info_popup)
	combo_info_popup.visible = false


func _instantiate_control(scene: PackedScene, fallback: Control) -> Control:
	if scene != null:
		var instance := scene.instantiate()
		if instance is Control:
			return instance
	return fallback


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _ensure_resources() -> void:
	if style_config == null:
		style_config = BattleUiStyleConfig.new()
	if icon_library == null:
		icon_library = BattleIconLibrary.new()
	if dice_visual_library == null:
		dice_visual_library = DiceVisualLibrary.new()


func _notify_battle_won() -> void:
	game_flow_controller.on_battle_won()


func _notify_battle_lost() -> void:
	game_flow_controller.on_battle_lost()


func _on_locale_changed(_locale: String) -> void:
	_refresh_hud()
