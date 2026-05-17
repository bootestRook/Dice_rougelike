extends Control
class_name BattleScreen


const BattleController = preload("res://scripts/runtime/BattleController.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")
const ResolutionTrace = preload("res://scripts/core/scoring/ResolutionTrace.gd")
const ResolutionStep = preload("res://scripts/core/scoring/ResolutionStep.gd")
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
var animation_layer: Control = null
var last_score_result: ScoreResult = null
var current_preview_result: ScoreResult = null
var status_text: String = str(TranslationServer.translate(&"AUTO.TEXT.DE7851F4F172"))
var wild_selection_dialog: ConfirmationDialog = null
var wild_button_rows: Dictionary = {}
var local_combo_appearance_counts: Dictionary = {}
var local_combo_last_formula_by_id: Dictionary = {}
var is_resolution_playing: bool = false
var suppress_next_hand_scored_fx: bool = false
var active_resolution_trace: ResolutionTrace = null
var resolution_log_lines: Array[String] = []
var resolution_start_score: int = 0
var resolution_display_score: int = 0
var resolution_display_combo_name: String = ""
var resolution_display_chips: int = 0
var resolution_display_mult: int = 0
var resolution_display_xmult: float = 1.0
var resolution_display_formula_score: int = 0
var resolution_final_score_visible: bool = false
var resolution_fast_mode: bool = false
var resolution_visual_index_by_trace_index: Dictionary = {}


enum BattleUiState {
	IDLE,
	ROLLING,
	SELECTING,
	MOVING_TO_RESOLVE,
	PLAYING_RESOLUTION,
	COMMITTING_SCORE,
	CLEANUP,
}


var battle_ui_state: int = BattleUiState.IDLE


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

	animation_layer = Control.new()
	animation_layer.name = "ResolutionAnimationLayer"
	animation_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	animation_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	animation_layer.z_index = 300
	layout_root.add_child(animation_layer)

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
		scoring_area.setup(
			style_config,
			score_log_row_scene,
			floating_score_text_scene,
			dice_view_scene,
			icon_library,
			dice_visual_library
		)

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
	status_text = str(TranslationServer.translate(&"AUTO.TEXT.FB26E473E039"))
	_refresh_hud()


func _on_hand_started(_hand_index: int) -> void:
	current_preview_result = null
	status_text = str(TranslationServer.translate(&"AUTO.TEXT.629A9098C25D"))
	_refresh_hud()


func _on_dice_changed(_rolls: Array) -> void:
	_refresh_hud()


func _on_rerolls_changed(_rerolls_left: int) -> void:
	_refresh_hud()


func _on_score_changed(_total_score: int, _target_score: int) -> void:
	_refresh_hud()


func _on_selection_changed(selected_count: int) -> void:
	status_text = str(TranslationServer.translate(&"AUTO.TEXT.34EB0A73B9C4")) % [selected_count, controller.get_max_selected_dice() if controller != null else 0]
	_refresh_hud()


func _on_hand_scored(result: ScoreResult) -> void:
	last_score_result = result
	current_preview_result = null
	_record_local_combo_stats(result)
	status_text = ""
	if game_flow_controller != null:
		game_flow_controller.record_hand_score(result, controller.get_current_hand_number())
	elif run_state != null:
		run_state.record_hand_score(result, controller.get_current_hand_number())
	suppress_next_hand_scored_fx = false
	_refresh_hud()


func _on_battle_won() -> void:
	status_text = str(TranslationServer.translate(&"AUTO.TEXT.BD9FEA62A9DC"))
	_refresh_hud()
	if game_flow_controller != null:
		call_deferred("_notify_battle_won")


func _on_battle_lost() -> void:
	status_text = str(TranslationServer.translate(&"AUTO.TEXT.D2C21A5E1F56"))
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
	status_text = str(TranslationServer.translate(&"AUTO.TEXT.BE260021E2DD"))
	_refresh_hud()


func _on_die_pressed(index: int) -> void:
	if is_resolution_playing:
		return
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
	if is_resolution_playing:
		return
	if controller != null:
		controller.reroll()


func _on_score_pressed() -> void:
	if is_resolution_playing:
		return
	if controller == null:
		return
	var wild_requests := controller.get_selected_wild_face_requests()
	if wild_requests.is_empty():
		await _settle_selected({})
		return
	_show_wild_selection_dialog(wild_requests)


func _settle_selected(wild_effective_pips: Dictionary = {}) -> void:
	if controller == null or is_resolution_playing:
		return
	if not controller.can_score():
		return

	var trace := controller.request_settle_selected(wild_effective_pips, _selected_die_order_for_resolution())
	if trace == null:
		return

	await play_resolution(trace)
	suppress_next_hand_scored_fx = true
	controller.commit_pending_resolution()
	cleanup_resolution_area()
	_refresh_hud()


func play_resolution(trace: ResolutionTrace) -> void:
	if trace == null:
		return

	active_resolution_trace = trace
	is_resolution_playing = true
	battle_ui_state = BattleUiState.MOVING_TO_RESOLVE
	resolution_final_score_visible = false
	resolution_start_score = controller.get_total_score() if controller != null else 0
	resolution_display_score = resolution_start_score
	_prime_resolution_display_from_trace(trace)
	resolution_log_lines.clear()
	for index in range(min(3, trace.log_lines.size())):
		resolution_log_lines.append(trace.log_lines[index])
	status_text = "Resolution..."
	_refresh_hud()

	await move_selected_dice_to_resolution_by_trace(trace)

	battle_ui_state = BattleUiState.PLAYING_RESOLUTION
	for step in trace.steps:
		await play_resolution_step(step)

	battle_ui_state = BattleUiState.COMMITTING_SCORE
	await play_final_score_fly(trace)
	is_resolution_playing = false


func move_selected_dice_to_resolution_by_trace(trace: ResolutionTrace) -> void:
	if trace == null or scoring_area == null:
		return

	var visual_slot_indices := _visual_selected_slot_indices(trace)
	_set_resolution_visual_index_map(trace, visual_slot_indices)
	var dice_datas := _resolution_die_view_data_for_slots(visual_slot_indices)
	if scoring_area.has_method("show_resolution_dice"):
		scoring_area.show_resolution_dice(dice_datas, true)
	await get_tree().process_frame

	if dice_bench_area != null and dice_bench_area.has_method("set_hidden_die_indices"):
		dice_bench_area.set_hidden_die_indices(trace.selected_slot_indices)

	var clones: Array[Control] = []
	for index in range(visual_slot_indices.size()):
		var die_index := visual_slot_indices[index]
		var data: DieViewData = dice_datas[index] if index < dice_datas.size() else null
		if data == null:
			continue
		var clone := _make_animation_dice_view()
		animation_layer.add_child(clone)
		if not clone.is_node_ready():
			await clone.ready
		if clone.has_method("render"):
			clone.render(data, style_config, icon_library, dice_visual_library)
		var start_rect := Rect2()
		if dice_bench_area != null and dice_bench_area.has_method("get_die_view_global_rect"):
			start_rect = dice_bench_area.get_die_view_global_rect(die_index)
		clone.global_position = start_rect.position
		clone.size = start_rect.size if start_rect.size != Vector2.ZERO else style_config.dice_display_size
		clones.append(clone)

	if clones.is_empty():
		if scoring_area.has_method("set_resolution_dice_visible"):
			scoring_area.set_resolution_dice_visible(true)
		return

	for index in range(clones.size()):
		var clone := clones[index]
		var target_pos: Vector2 = scoring_area.get_resolution_dice_global_position(index) if scoring_area.has_method("get_resolution_dice_global_position") else clone.global_position
		var move_duration := 0.12 if resolution_fast_mode else 0.35
		var tween := create_tween()
		tween.tween_property(clone, "global_position", target_pos, move_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await tween.finished
		clone.queue_free()
		if scoring_area.has_method("set_resolution_index_visible"):
			scoring_area.set_resolution_index_visible(index, true)
		if index < clones.size() - 1:
			await get_tree().create_timer(0.03 if resolution_fast_mode else 0.08).timeout
	if not scoring_area.has_method("set_resolution_index_visible") and scoring_area.has_method("set_resolution_dice_visible"):
		scoring_area.set_resolution_dice_visible(true)


func play_resolution_step(step: ResolutionStep) -> void:
	if step == null:
		return

	if step.log_line != "" and not resolution_log_lines.has(step.log_line):
		resolution_log_lines.append(step.log_line)
	_apply_resolution_step_values(step)
	resolution_final_score_visible = false
	_highlight_step_source(step)
	_refresh_hud()
	if scoring_area != null and scoring_area.has_method("show_step_text"):
		scoring_area.show_step_text("", "")
	var floating_text := str(step.floating_text)
	if step.phase != ResolutionStep.Phase.FINAL_SCORE and _should_show_floating_text(floating_text):
		await _show_step_floating_text(step, floating_text)
	else:
		await get_tree().create_timer(_resolution_step_duration()).timeout
	_clear_resolution_highlights()


func play_final_score_fly(trace: ResolutionTrace) -> void:
	if trace == null:
		return
	var final_score: int = maxi(0, trace.hand_score_final)
	resolution_display_score = resolution_start_score
	resolution_display_formula_score = final_score
	resolution_final_score_visible = final_score > 0
	_refresh_hud()
	if scoring_area != null and scoring_area.has_method("show_step_text"):
		scoring_area.show_step_text("", "")
	if final_score > 0 and not resolution_fast_mode and left_sidebar != null and left_sidebar.has_method("play_final_score_pop"):
		await left_sidebar.play_final_score_pop()
	else:
		await get_tree().create_timer(0.05 if resolution_fast_mode else 0.5).timeout
	await _play_score_transfer_countdown(final_score)


func _play_score_transfer_countdown(final_score: int) -> void:
	if final_score <= 0:
		resolution_display_formula_score = 0
		resolution_final_score_visible = false
		_refresh_hud()
		return

	var duration: float = 0.12 if resolution_fast_mode else 0.45
	var start_ticks: int = Time.get_ticks_msec()
	var transferred: int = 0
	while transferred < final_score:
		var elapsed: float = float(Time.get_ticks_msec() - start_ticks) / 1000.0
		var t: float = clampf(elapsed / duration, 0.0, 1.0)
		transferred = clampi(roundi(float(final_score) * t), 0, final_score)
		resolution_display_score = resolution_start_score + transferred
		resolution_display_formula_score = final_score - transferred
		resolution_final_score_visible = resolution_display_formula_score > 0
		_refresh_hud()
		if transferred >= final_score:
			break
		await get_tree().process_frame

	resolution_display_score = resolution_start_score + final_score
	resolution_display_formula_score = 0
	resolution_final_score_visible = false
	_refresh_hud()


func cleanup_resolution_area() -> void:
	battle_ui_state = BattleUiState.CLEANUP
	active_resolution_trace = null
	resolution_visual_index_by_trace_index.clear()
	resolution_log_lines.clear()
	if scoring_area != null and scoring_area.has_method("clear_resolution_dice"):
		scoring_area.clear_resolution_dice()
	if dice_bench_area != null:
		if dice_bench_area.has_method("clear_hidden_die_indices"):
			dice_bench_area.clear_hidden_die_indices()
		if dice_bench_area.has_method("clear_highlights"):
			dice_bench_area.clear_highlights()
	resolution_final_score_visible = false
	resolution_fast_mode = false
	battle_ui_state = BattleUiState.IDLE


func skip_resolution_animation() -> void:
	resolution_fast_mode = true


func _prime_resolution_display_from_trace(trace: ResolutionTrace) -> void:
	resolution_display_combo_name = trace.primary_combo_display_name if trace != null else ""
	resolution_display_chips = 0
	resolution_display_mult = 0
	resolution_display_xmult = 1.0
	resolution_display_formula_score = 0
	resolution_final_score_visible = false
	if trace == null:
		return

	for step in trace.steps:
		if step != null and step.phase == ResolutionStep.Phase.COMBO_BASE:
			_apply_resolution_step_values(step)
			return


func _apply_resolution_step_values(step: ResolutionStep) -> void:
	if step == null:
		return
	if active_resolution_trace != null and active_resolution_trace.primary_combo_display_name != "":
		resolution_display_combo_name = active_resolution_trace.primary_combo_display_name
	resolution_display_chips = step.chips_after
	resolution_display_mult = step.mult_after
	resolution_display_xmult = step.xmult_after
	resolution_display_formula_score = step.partial_score_after


func _highlight_step_source(step: ResolutionStep) -> void:
	_clear_resolution_highlights()
	match step.phase:
		ResolutionStep.Phase.PIP_SCORE, ResolutionStep.Phase.ORNAMENT_ON_SCORE, ResolutionStep.Phase.MARK_ON_SCORE, ResolutionStep.Phase.RETRIGGER:
			var resolution_index := _visual_resolution_index(step.resolution_index)
			if resolution_index < 0:
				resolution_index = _visual_resolution_index(step.retrigger_target_resolution_index)
			if scoring_area != null and scoring_area.has_method("highlight_resolution_index"):
				scoring_area.highlight_resolution_index(resolution_index)
		ResolutionStep.Phase.UNSELECTED_STAY, ResolutionStep.Phase.DIE_BODY:
			if dice_bench_area != null and dice_bench_area.has_method("set_highlighted_die_indices"):
				var highlighted_indices: Array[int] = [step.bench_slot_index]
				dice_bench_area.set_highlighted_die_indices(highlighted_indices)
		_:
			pass


func _clear_resolution_highlights() -> void:
	if scoring_area != null and scoring_area.has_method("clear_highlights"):
		scoring_area.clear_highlights()
	if dice_bench_area != null and dice_bench_area.has_method("clear_highlights"):
		dice_bench_area.clear_highlights()


func _show_step_floating_text(step: ResolutionStep, floating_text: String = "") -> void:
	if scoring_area == null:
		return
	var text: String = floating_text if floating_text != "" else str(step.floating_text)
	if not _should_show_floating_text(text):
		return
	var target := Vector2(-999999.0, -999999.0)
	if step.resolution_index >= 0:
		var visual_index := _visual_resolution_index(step.resolution_index)
		if scoring_area.has_method("get_resolution_dice_global_floating_anchor"):
			target = scoring_area.get_resolution_dice_global_floating_anchor(visual_index)
		elif scoring_area.has_method("get_resolution_dice_global_center"):
			target = scoring_area.get_resolution_dice_global_center(visual_index)
	if step.phase == ResolutionStep.Phase.UNSELECTED_STAY and dice_bench_area != null and dice_bench_area.has_method("get_die_view_global_rect"):
		target = dice_bench_area.get_die_view_global_rect(step.bench_slot_index).get_center()
	if scoring_area.has_method("play_floating_score_at"):
		await scoring_area.play_floating_score_at(text, target)
	elif scoring_area.has_method("show_floating_score_at"):
		scoring_area.show_floating_score_at(text, target)
	elif scoring_area.has_method("show_floating_score"):
		scoring_area.show_floating_score(text)


func _should_show_floating_text(text: String) -> bool:
	var stripped := text.strip_edges()
	if stripped == "":
		return false
	for index in range(stripped.length()):
		if stripped.unicode_at(index) > 127:
			return false
	if stripped.begins_with("+") or stripped.begins_with("-"):
		return true
	if stripped.begins_with("X") or stripped.begins_with("x"):
		return true
	return false


func _resolution_step_duration() -> float:
	return 0.22 if resolution_fast_mode else 0.82


func _resolution_state_text() -> String:
	match battle_ui_state:
		BattleUiState.MOVING_TO_RESOLVE:
			return "Moving dice to resolution..."
		BattleUiState.PLAYING_RESOLUTION:
			return "Playing resolution..."
		BattleUiState.COMMITTING_SCORE:
			return "Committing score..."
		_:
			return "Resolution..."


func _visual_selected_slot_indices(trace: ResolutionTrace) -> Array[int]:
	var result: Array[int] = []
	if trace == null:
		return result

	var selected_lookup: Dictionary = {}
	for slot_index in trace.selected_slot_indices:
		selected_lookup[int(slot_index)] = true

	var display_order: Array[int] = []
	if dice_bench_area != null and dice_bench_area.has_method("get_display_die_order"):
		display_order = dice_bench_area.get_display_die_order()
	for die_index in display_order:
		if selected_lookup.has(die_index):
			result.append(die_index)
			selected_lookup.erase(die_index)

	for slot_index in trace.selected_slot_indices:
		var die_index := int(slot_index)
		if selected_lookup.has(die_index):
			result.append(die_index)
			selected_lookup.erase(die_index)
	return result


func _selected_die_order_for_resolution() -> Array[int]:
	var result: Array[int] = []
	if dice_bench_area == null or not dice_bench_area.has_method("get_display_die_order"):
		return result

	var selected_lookup: Dictionary = {}
	for die_index in _selected_dice_indices():
		selected_lookup[die_index] = true

	for die_index in dice_bench_area.get_display_die_order():
		var resolved_index := int(die_index)
		if selected_lookup.has(resolved_index):
			result.append(resolved_index)
			selected_lookup.erase(resolved_index)

	for die_index in _selected_dice_indices():
		if selected_lookup.has(die_index):
			result.append(die_index)
			selected_lookup.erase(die_index)
	return result


func _set_resolution_visual_index_map(trace: ResolutionTrace, visual_slot_indices: Array[int]) -> void:
	resolution_visual_index_by_trace_index.clear()
	if trace == null:
		return
	for visual_index in range(visual_slot_indices.size()):
		var trace_index := trace.selected_slot_indices.find(visual_slot_indices[visual_index])
		if trace_index >= 0:
			resolution_visual_index_by_trace_index[trace_index] = visual_index


func _visual_resolution_index(trace_resolution_index: int) -> int:
	if trace_resolution_index < 0:
		return -1
	return int(resolution_visual_index_by_trace_index.get(trace_resolution_index, trace_resolution_index))


func _resolution_die_view_data(trace: ResolutionTrace) -> Array[DieViewData]:
	if trace == null:
		var empty_result: Array[DieViewData] = []
		return empty_result
	return _resolution_die_view_data_for_slots(trace.selected_slot_indices)


func _resolution_die_view_data_for_slots(slot_indices: Array[int]) -> Array[DieViewData]:
	var result: Array[DieViewData] = []
	var dice := _get_dice()
	var rolled_by_die := _current_rolls_by_die()
	for slot_index in slot_indices:
		if slot_index < 0 or slot_index >= dice.size():
			continue
		var rolled_face = rolled_by_die.get(slot_index, null)
		var die_data := DieViewData.new()
		die_data.setup_from_die(dice[slot_index], slot_index, rolled_face, false, false, false)
		die_data.selected = false
		result.append(die_data)
	return result


func _make_animation_dice_view() -> Control:
	var view := _instantiate_control(dice_view_scene, PanelContainer.new())
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.z_index = 320
	return view


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
		state.preview_text = str(TranslationServer.translate(&"AUTO.TEXT.83C19741CC0F"))
		return state

	state.target_score = controller.get_target_score()
	state.current_score = controller.get_total_score()
	state.rerolls_left = controller.get_rerolls_left()
	state.rerolls_total = controller.get_rerolls_per_hand()
	state.current_hand = controller.get_current_hand_number()
	state.max_hands = controller.get_hands_per_battle()
	state.phase_text = DisplayNames.phase_name(controller.get_phase_name())
	state.can_reroll = controller.can_reroll() and not is_resolution_playing
	state.can_score = controller.can_score() and not is_resolution_playing
	state.dice_results = _build_die_view_data()
	state.selected_dice_indices = _selected_dice_indices()
	state.score_log = _score_log_lines()
	state.preview_text = _preview_text()

	var formula_result: ScoreResult = current_preview_result
	if formula_result != null:
		state.core_combo_name = _combo_name(formula_result)
		state.core_combo_level = _combo_level(_result_combo_id(formula_result))
		state.combo_display_visible = true
		state.base_chips = formula_result.combo_chips_bonus
		state.base_mult = formula_result.combo_mult
		state.xmult = formula_result.xmult
		state.formula_score = formula_result.final_score

	if active_resolution_trace != null:
		state.current_score = resolution_display_score
		state.core_combo_name = resolution_display_combo_name if resolution_display_combo_name != "" else state.core_combo_name
		if active_resolution_trace.primary_combo_id != &"":
			state.core_combo_level = _combo_level(active_resolution_trace.primary_combo_id)
		state.combo_display_visible = battle_ui_state != BattleUiState.COMMITTING_SCORE and not resolution_final_score_visible
		state.final_score_display_visible = resolution_final_score_visible
		state.base_chips = resolution_display_chips
		state.base_mult = resolution_display_mult
		state.xmult = resolution_display_xmult
		state.formula_score = resolution_display_formula_score if resolution_final_score_visible else 0
		state.can_reroll = false
		state.can_score = false
		state.score_log = resolution_log_lines.duplicate()
		state.preview_text = ""
		state.status_text = ""

	return state


func _build_die_view_data() -> Array[DieViewData]:
	var result: Array[DieViewData] = []
	var dice := _get_dice()
	var rolled_by_die := _current_rolls_by_die()
	var dice_enabled := controller != null and controller.get_phase() == BattleController.BattlePhase.WAITING_ACTION and not is_resolution_playing
	var hand_scored := controller != null and controller.hand_state != null and controller.hand_state.scored and not is_resolution_playing

	for die_index in range(dice.size()):
		var rolled_face = rolled_by_die.get(die_index, null)
		var disabled := rolled_face == null or (not dice_enabled and not is_resolution_playing)
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
		return str(TranslationServer.translate(&"AUTO.TEXT.8E9702E096F5")) % [current_preview_result.get_summary_text_zh()]

	var selected_count := _selected_dice_indices().size()
	var max_selected: int = controller.get_max_selected_dice() if controller != null else 0
	if max_selected > 0 and selected_count > max_selected:
		return str(TranslationServer.translate(&"AUTO.TEXT.C235DFAE61D5")) % [selected_count, max_selected, max_selected]
	return str(TranslationServer.translate(&"AUTO.TEXT.6AA9A82B6ED6"))


func _score_log_lines() -> Array[String]:
	if active_resolution_trace != null:
		return resolution_log_lines.duplicate()

	var lines: Array[String] = []
	if last_score_result == null:
		lines.append(str(TranslationServer.translate(&"AUTO.TEXT.546DB6CEBB67")))
		lines.append(str(TranslationServer.translate(&"AUTO.TEXT.7F03BFBC43B6")))
		return lines

	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.CA6BB100A6B7")))
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.4788FB34D315")) % [last_score_result.final_score])
	for line in last_score_result.get_summary_text_zh().split("\n"):
		lines.append(line)
	lines.append(str(TranslationServer.translate(&"AUTO.TEXT.8BC289567504")))
	for entry in last_score_result.logs:
		lines.append(entry.get_text())
	return lines


func _combo_name(result: ScoreResult) -> String:
	if result == null:
		return str(TranslationServer.translate(&"AUTO.TEXT.53E2DB70167F"))
	var combo_id := result.primary_combo
	if combo_id == &"":
		combo_id = result.combo_id
	return DisplayNames.combo_name(combo_id) if combo_id != &"" else str(TranslationServer.translate(&"AUTO.TEXT.72077749F794"))


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
	var active_result: ScoreResult = current_preview_result if current_preview_result != null else last_score_result
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
		var combo_levels: Dictionary = run_state.combo_levels if run_state != null else {}
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
		call_deferred("_settle_selected", {})
		return

	wild_button_rows.clear()
	var root := wild_selection_dialog.get_node_or_null("WildSelectionRoot/Rows")
	if root == null:
		return
	_clear_children(root)

	var title := Label.new()
	title.text = str(TranslationServer.translate(&"AUTO.TEXT.7BB3EF323E38"))
	root.add_child(title)

	for request in requests:
		var key := str(request.get("key", ""))
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		root.add_child(row)

		var label := Label.new()
		label.text = str(TranslationServer.translate(&"AUTO.TEXT.D7707C2686A7")) % [
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
	wild_selection_dialog.title = str(TranslationServer.translate(&"AUTO.TEXT.8349FDE42757"))
	wild_selection_dialog.ok_button_text = str(TranslationServer.translate(&"AUTO.TEXT.B56D9AC6C5A0"))
	wild_selection_dialog.cancel_button_text = str(TranslationServer.translate(&"AUTO.TEXT.4D0B4688C787"))
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
	await _settle_selected(selections)


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
