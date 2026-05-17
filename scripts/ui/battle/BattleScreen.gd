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
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")
const ForgeService = preload("res://scripts/rules/forge/ForgeService.gd")
const ScoreEngine = preload("res://scripts/rules/scoring/ScoreEngine.gd")
const BattleHudState = preload("res://scripts/ui/battle/view_models/BattleHudState.gd")
const DieViewData = preload("res://scripts/ui/battle/view_models/DieViewData.gd")
const SlotViewData = preload("res://scripts/ui/battle/view_models/SlotViewData.gd")
const ComboInfoRowData = preload("res://scripts/ui/battle/view_models/ComboInfoRowData.gd")
const BattleUiStyleConfig = preload("res://scripts/ui/battle/resources/BattleUiStyleConfig.gd")
const BattleIconLibrary = preload("res://scripts/ui/battle/resources/BattleIconLibrary.gd")
const DiceVisualLibrary = preload("res://scripts/ui/battle/resources/DiceVisualLibrary.gd")
const RoundIntroBanner = preload("res://scripts/ui/battle/components/RoundIntroBanner.gd")


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
@export var reroll_magic_fx_scene: PackedScene = preload("res://scenes/battle/components/RerollMagicFx.tscn")
@export var round_intro_banner_scene: PackedScene = preload("res://scenes/battle/components/RoundIntroBanner.tscn")
@export var design_resolution: Vector2 = Vector2(1920, 1080)
@export var relic_capacity: int = 6
@export var item_capacity: int = 3


var controller: BattleController = null
var game_flow_controller: GameFlowController = null
var run_state: RunState = null
var forge_service := ForgeService.new()
var left_sidebar: Control = null
var top_inventory_bar: Control = null
var scoring_area: Control = null
var dice_bench_area: Control = null
var combo_info_popup: Control = null
var layout_root: Control = null
var animation_layer: Control = null
var options_menu_overlay: Control = null
var options_menu_previous_pause_state: bool = false
var install_focus_overlay: Control = null
var last_score_result: ScoreResult = null
var current_preview_result: ScoreResult = null
var status_text: String = str(TranslationServer.translate(&"AUTO.TEXT.DE7851F4F172"))
var wild_selection_dialog: ConfirmationDialog = null
var wild_button_rows: Dictionary = {}
var local_combo_appearance_counts: Dictionary = {}
var local_combo_last_formula_by_id: Dictionary = {}
var is_resolution_playing: bool = false
var is_reroll_playing: bool = false
var is_battle_intro_playing: bool = false
var battle_intro_pending: bool = false
var battle_intro_dice_revealed: bool = false
var battle_intro_die_indices: Array[int] = []
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
var resolution_return_rect_by_die_index: Dictionary = {}
var reward_phase_active: bool = false
var reward_install_active: bool = false
var victory_reward_showcase_active: bool = false
var victory_target_restore_pending: bool = false
var pending_install_piece: ForgePieceDef = null
var selected_install_die_index: int = -1
var selected_install_face_index: int = -1


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


func start_battle_with_run_state(new_game_flow_controller: GameFlowController = null, new_run_state: RunState = null) -> void:
	if new_game_flow_controller != null:
		game_flow_controller = new_game_flow_controller
	run_state = new_run_state
	_clear_reward_phase_ui()
	_clear_battle_animation_layer()
	cleanup_resolution_area()
	current_preview_result = null
	last_score_result = null
	active_resolution_trace = null
	resolution_log_lines.clear()
	resolution_return_rect_by_die_index.clear()
	if combo_info_popup != null:
		combo_info_popup.visible = false
	if controller != null:
		controller.start_battle(null, run_state)


func _ready() -> void:
	_ensure_resources()
	_build_view()
	_create_controller()
	controller.start_battle(null, run_state)
	call_deferred("_apply_resolution_scale")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_resolution_scale()
		_update_install_focus_overlay_layout()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _is_options_menu_visible():
		_hide_options_menu()
		get_viewport().set_input_as_handled()
		return

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
	if scoring_area.has_signal("reward_choice_pressed"):
		scoring_area.reward_choice_pressed.connect(_on_reward_choice_pressed)

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
	if dice_bench_area.has_signal("install_face_selected"):
		dice_bench_area.install_face_selected.connect(_on_install_face_selected)
	if dice_bench_area.has_signal("install_requested"):
		dice_bench_area.install_requested.connect(_on_install_requested)

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
	_update_install_focus_overlay_layout()


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
	victory_reward_showcase_active = false
	battle_intro_die_indices.clear()
	battle_intro_pending = false
	battle_intro_dice_revealed = false
	is_battle_intro_playing = false
	victory_target_restore_pending = _has_victory_target_feedback()
	if not victory_target_restore_pending:
		_clear_victory_target_feedback()
	status_text = str(TranslationServer.translate(&"AUTO.TEXT.FB26E473E039"))
	_refresh_hud()


func _on_hand_started(_hand_index: int) -> void:
	current_preview_result = null
	victory_reward_showcase_active = false
	status_text = str(TranslationServer.translate(&"AUTO.TEXT.629A9098C25D"))
	_prepare_hand_intro_magic()
	_refresh_hud()
	if battle_intro_pending:
		call_deferred("_play_battle_intro_magic")


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
	if is_battle_intro_playing:
		return
	_show_combo_info_popup()


func _on_options_pressed() -> void:
	if is_battle_intro_playing:
		return
	_show_options_menu()


func _show_options_menu() -> void:
	if _is_options_menu_visible() or layout_root == null:
		return

	options_menu_overlay = Control.new()
	options_menu_overlay.name = "OptionsMenuOverlay"
	options_menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	options_menu_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	options_menu_overlay.focus_mode = Control.FOCUS_ALL
	options_menu_overlay.z_index = 720
	options_menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	options_menu_overlay.gui_input.connect(_on_options_overlay_gui_input)
	layout_root.add_child(options_menu_overlay)

	var scrim := ColorRect.new()
	scrim.name = "OptionsMenuScrim"
	scrim.color = Color(0.0, 0.0, 0.0, 0.64)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.gui_input.connect(_on_options_scrim_gui_input)
	options_menu_overlay.add_child(scrim)

	var panel := PanelContainer.new()
	panel.name = "OptionsMenuPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = Vector2(560.0, 310.0)
	panel.add_theme_stylebox_override("panel", _make_options_menu_panel_style())
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -280.0
	panel.offset_top = -155.0
	panel.offset_right = 280.0
	panel.offset_bottom = 155.0
	options_menu_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 22)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(content)

	var title := Label.new()
	title.text = "选项"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.04, 0.95))
	title.add_theme_constant_override("outline_size", 5)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(title)

	var restart_button := _make_options_menu_button("再来一局", Color(0.86, 0.08, 0.06, 1.0), Color(1.0, 0.18, 0.14, 1.0))
	restart_button.pressed.connect(_on_options_restart_pressed)
	content.add_child(restart_button)

	var main_menu_button := _make_options_menu_button("主菜单", Color(0.92, 0.50, 0.0, 1.0), Color(1.0, 0.64, 0.06, 1.0))
	main_menu_button.pressed.connect(_on_options_main_menu_pressed)
	content.add_child(main_menu_button)

	options_menu_previous_pause_state = get_tree().paused
	get_tree().paused = true
	options_menu_overlay.modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(options_menu_overlay, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	options_menu_overlay.grab_focus()


func _hide_options_menu(restore_pause_state: bool = true) -> void:
	if not _is_options_menu_visible():
		options_menu_overlay = null
		if restore_pause_state:
			_restore_options_menu_pause_state()
		return

	var overlay := options_menu_overlay
	options_menu_overlay = null
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		if is_instance_valid(overlay):
			overlay.queue_free()
		if restore_pause_state:
			_restore_options_menu_pause_state()
	)


func _is_options_menu_visible() -> bool:
	return options_menu_overlay != null and is_instance_valid(options_menu_overlay) and not options_menu_overlay.is_queued_for_deletion()


func _on_options_scrim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_hide_options_menu()


func _on_options_overlay_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_hide_options_menu()
		get_viewport().set_input_as_handled()


func _on_options_restart_pressed() -> void:
	_hide_options_menu(false)
	_force_options_menu_unpause()
	if game_flow_controller != null:
		game_flow_controller.start_new_run()
		return
	_restart_battle_locally()


func _on_options_main_menu_pressed() -> void:
	_hide_options_menu(false)
	_force_options_menu_unpause()
	if game_flow_controller != null:
		game_flow_controller.back_to_main()
		return
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _restore_options_menu_pause_state() -> void:
	get_tree().paused = options_menu_previous_pause_state


func _force_options_menu_unpause() -> void:
	options_menu_previous_pause_state = false
	get_tree().paused = false


func _restart_battle_locally() -> void:
	_clear_reward_phase_ui()
	_clear_battle_animation_layer()
	cleanup_resolution_area()
	current_preview_result = null
	last_score_result = null
	if run_state != null:
		run_state.setup_new_run()
	if controller != null:
		controller.start_battle(null, run_state)


func _clear_battle_animation_layer() -> void:
	if animation_layer == null:
		return
	for child in animation_layer.get_children():
		child.queue_free()


func _make_options_menu_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.095, 0.075, 0.96)
	style.border_color = Color(0.80, 1.0, 0.88, 0.86)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 28
	style.shadow_offset = Vector2(0.0, 8.0)
	return style


func _make_options_menu_button(text: String, normal_color: Color, hover_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.custom_minimum_size = Vector2(390.0, 66.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 0.93, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.93, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 0.93, 1.0))
	button.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.03, 0.95))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 3)
	button.add_theme_stylebox_override("normal", _make_options_button_style(normal_color, Color(1.0, 0.88, 0.58, 0.72), 0.0))
	button.add_theme_stylebox_override("hover", _make_options_button_style(hover_color, Color(1.0, 0.95, 0.68, 0.92), -2.0))
	button.add_theme_stylebox_override("pressed", _make_options_button_style(normal_color.darkened(0.20), Color(1.0, 0.80, 0.44, 0.82), 2.0))
	button.add_theme_stylebox_override("disabled", _make_options_button_style(normal_color.darkened(0.35), Color(0.55, 0.55, 0.50, 0.45), 0.0))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _make_options_button_style(fill: Color, border: Color, shadow_y: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.42)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, shadow_y + 5.0)
	return style


func _on_die_pressed(index: int) -> void:
	if is_resolution_playing or is_reroll_playing or is_battle_intro_playing:
		return
	if reward_install_active:
		_request_install_info_for_die(index)
		return
	if reward_phase_active or victory_reward_showcase_active:
		return
	if controller == null:
		return
	controller.toggle_select(index)


func _on_die_info_requested(index: int) -> void:
	if is_reroll_playing or is_battle_intro_playing:
		return
	if reward_install_active:
		_request_install_info_for_die(index)
		return
	if reward_phase_active or victory_reward_showcase_active:
		return
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
	if is_resolution_playing or is_reroll_playing or is_battle_intro_playing:
		return
	if controller == null or not controller.can_reroll():
		return
	await _play_reroll_magic()


func _on_score_pressed() -> void:
	if is_resolution_playing or is_reroll_playing or is_battle_intro_playing:
		return
	if controller == null:
		return
	var wild_requests := controller.get_selected_wild_face_requests()
	if wild_requests.is_empty():
		await _settle_selected({})
		return
	_show_wild_selection_dialog(wild_requests)


func show_reward_choices(choices: Array) -> void:
	reward_phase_active = true
	reward_install_active = false
	pending_install_piece = null
	selected_install_die_index = -1
	selected_install_face_index = -1
	status_text = str(TranslationServer.translate(&"AUTO.TEXT.BD9FEA62A9DC"))
	_hide_install_focus_overlay()
	if scoring_area != null and scoring_area.has_method("show_reward_choices"):
		scoring_area.show_reward_choices(choices)
	if dice_bench_area != null:
		if dice_bench_area.has_method("hide_info"):
			dice_bench_area.hide_info()
		if dice_bench_area.has_method("set_install_mode"):
			dice_bench_area.set_install_mode(false)
	_refresh_hud()


func begin_reward_install(piece) -> void:
	var forge_piece := piece as ForgePieceDef
	if forge_piece == null:
		_clear_reward_phase_ui()
		return

	reward_phase_active = true
	reward_install_active = true
	pending_install_piece = forge_piece
	selected_install_die_index = -1
	selected_install_face_index = -1
	status_text = str(TranslationServer.translate(&"AUTO.TEXT.56B08BE6F8EA"))
	if scoring_area != null and scoring_area.has_method("hide_reward_choices"):
		scoring_area.hide_reward_choices()
	if dice_bench_area != null:
		if dice_bench_area.has_method("set_install_mode"):
			dice_bench_area.set_install_mode(true, pending_install_piece.get_display_name())
		if dice_bench_area.has_method("set_highlighted_die_indices"):
			dice_bench_area.set_highlighted_die_indices(_all_dice_indices())
	_show_install_focus_overlay()
	_refresh_hud()


func _on_reward_choice_pressed(choice) -> void:
	if game_flow_controller == null:
		return
	game_flow_controller.choose_reward(choice)


func _request_install_info_for_die(index: int) -> void:
	if dice_bench_area == null:
		return
	if dice_bench_area.has_method("request_info_for_die"):
		dice_bench_area.request_info_for_die(index)
	elif dice_bench_area.has_method("show_info_for_die"):
		dice_bench_area.show_info_for_die(index)


func _on_install_face_selected(die_index: int, face_index: int) -> void:
	if not reward_install_active:
		return
	selected_install_die_index = die_index
	selected_install_face_index = face_index
	if pending_install_piece != null:
		status_text = str(TranslationServer.translate(&"AUTO.TEXT.A211180FE768")) % [
			pending_install_piece.get_display_name(),
			die_index + 1,
			face_index + 1,
		]
	_refresh_hud()


func _on_install_requested(die_index: int, face_index: int) -> void:
	if not reward_install_active or pending_install_piece == null:
		return
	var target := _resolve_install_target(die_index, face_index)
	var target_die_index := int(target.get("die_index", -1))
	var target_face_index := int(target.get("face_index", -1))
	if not _can_install_pending_piece(target_die_index, target_face_index):
		return
	if game_flow_controller != null:
		if not game_flow_controller.install_pending_piece(target_die_index, target_face_index):
			status_text = str(TranslationServer.translate(&"AUTO.TEXT.C0469EBB56C8"))
			_refresh_hud()
		return
	_install_pending_piece_locally(target_die_index, target_face_index)


func _resolve_install_target(die_index: int, face_index: int) -> Dictionary:
	var target_die_index := die_index
	var target_face_index := face_index
	if target_die_index < 0 and selected_install_die_index >= 0:
		target_die_index = selected_install_die_index
	if target_face_index < 0 and selected_install_face_index >= 0:
		target_face_index = selected_install_face_index
	return {
		"die_index": target_die_index,
		"face_index": target_face_index,
	}


func _can_install_pending_piece(die_index: int, face_index: int) -> bool:
	if pending_install_piece == null:
		return false
	var dice := _get_dice()
	if die_index < 0 or die_index >= dice.size():
		return false
	var die = dice[die_index]
	if die == null:
		return false
	if not forge_service.can_apply_piece(pending_install_piece, die, face_index):
		status_text = str(TranslationServer.translate(&"AUTO.TEXT.C0469EBB56C8"))
		_refresh_hud()
		return false
	return true


func _install_pending_piece_locally(die_index: int, face_index: int) -> void:
	if pending_install_piece == null:
		return
	var dice := _get_dice()
	if die_index < 0 or die_index >= dice.size():
		return
	var piece := pending_install_piece
	forge_service.apply_piece(piece, dice[die_index], face_index)
	if run_state != null:
		run_state.record_installed_piece(piece, die_index, face_index)
		run_state.pending_forge_piece = null
		run_state.last_reward_choices.clear()
		run_state.advance_battle()
	_clear_reward_phase_ui()
	_refresh_hud()


func _clear_reward_phase_ui() -> void:
	reward_phase_active = false
	reward_install_active = false
	victory_reward_showcase_active = false
	pending_install_piece = null
	selected_install_die_index = -1
	selected_install_face_index = -1
	_hide_install_focus_overlay()
	if scoring_area != null and scoring_area.has_method("hide_reward_choices"):
		scoring_area.hide_reward_choices()
	if dice_bench_area != null:
		if dice_bench_area.has_method("set_install_mode"):
			dice_bench_area.set_install_mode(false)
		if dice_bench_area.has_method("clear_highlights"):
			dice_bench_area.clear_highlights()
		if dice_bench_area.has_method("hide_info"):
			dice_bench_area.hide_info()


func _show_install_focus_overlay() -> void:
	_ensure_install_focus_overlay()
	if install_focus_overlay == null:
		return
	install_focus_overlay.visible = true
	_update_install_focus_overlay_layout()


func _hide_install_focus_overlay() -> void:
	if install_focus_overlay != null:
		install_focus_overlay.visible = false


func _ensure_install_focus_overlay() -> void:
	if install_focus_overlay != null or layout_root == null:
		return
	install_focus_overlay = Control.new()
	install_focus_overlay.name = "InstallFocusOverlay"
	install_focus_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	install_focus_overlay.z_index = 25
	install_focus_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout_root.add_child(install_focus_overlay)

	for rect_name in ["DimTop", "DimLeft", "DimRight", "DimBottom"]:
		var dim := ColorRect.new()
		dim.name = rect_name
		dim.color = _install_focus_scrim_color()
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		install_focus_overlay.add_child(dim)

	var border := Panel.new()
	border.name = "FocusBorder"
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.add_theme_stylebox_override("panel", _make_install_focus_border_style())
	install_focus_overlay.add_child(border)
	install_focus_overlay.visible = false


func _update_install_focus_overlay_layout() -> void:
	if install_focus_overlay == null or layout_root == null or dice_bench_area == null:
		return
	if not install_focus_overlay.visible:
		return

	install_focus_overlay.size = layout_root.size
	var root_size := layout_root.size
	var bench_rect := _control_rect_in_layout_root(dice_bench_area).grow(8.0)
	bench_rect.position.x = clampf(bench_rect.position.x, 0.0, root_size.x)
	bench_rect.position.y = clampf(bench_rect.position.y, 0.0, root_size.y)
	bench_rect.size.x = clampf(bench_rect.size.x, 0.0, root_size.x - bench_rect.position.x)
	bench_rect.size.y = clampf(bench_rect.size.y, 0.0, root_size.y - bench_rect.position.y)

	_set_overlay_child_rect("DimTop", Rect2(Vector2.ZERO, Vector2(root_size.x, bench_rect.position.y)))
	_set_overlay_child_rect("DimLeft", Rect2(
		Vector2(0.0, bench_rect.position.y),
		Vector2(bench_rect.position.x, bench_rect.size.y)
	))
	_set_overlay_child_rect("DimRight", Rect2(
		Vector2(bench_rect.position.x + bench_rect.size.x, bench_rect.position.y),
		Vector2(maxf(0.0, root_size.x - bench_rect.position.x - bench_rect.size.x), bench_rect.size.y)
	))
	_set_overlay_child_rect("DimBottom", Rect2(
		Vector2(0.0, bench_rect.position.y + bench_rect.size.y),
		Vector2(root_size.x, maxf(0.0, root_size.y - bench_rect.position.y - bench_rect.size.y))
	))
	_set_overlay_child_rect("FocusBorder", bench_rect)


func _set_overlay_child_rect(child_name: String, rect: Rect2) -> void:
	if install_focus_overlay == null:
		return
	var child := install_focus_overlay.get_node_or_null(child_name) as Control
	if child == null:
		return
	child.position = rect.position
	child.size = rect.size


func _control_rect_in_layout_root(control: Control) -> Rect2:
	if control == null or layout_root == null:
		return Rect2()
	var global_rect := control.get_global_rect()
	var inverse := layout_root.get_global_transform_with_canvas().affine_inverse()
	var local_position: Vector2 = inverse * global_rect.position
	var local_end: Vector2 = inverse * (global_rect.position + global_rect.size)
	return Rect2(local_position, local_end - local_position)


func _install_focus_scrim_color() -> Color:
	if style_config != null:
		var color := style_config.modal_scrim_color
		color.a = maxf(color.a, 0.58)
		return color
	return Color(0.0, 0.0, 0.0, 0.62)


func _make_install_focus_border_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(1.0, 0.66, 0.05, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	return style


func _settle_selected(wild_effective_pips: Dictionary = {}) -> void:
	if controller == null or is_resolution_playing or is_reroll_playing or is_battle_intro_playing:
		return
	if not controller.can_score():
		return

	var trace := controller.request_settle_selected(wild_effective_pips, _selected_die_order_for_resolution())
	if trace == null:
		return

	var will_win := _trace_will_win_battle(trace)
	await play_resolution(trace)
	if will_win:
		await _play_victory_target_feedback()
	await return_resolution_dice_to_bench_by_trace(trace, will_win)
	if will_win:
		await _play_victory_reward_showcase()
	suppress_next_hand_scored_fx = true
	controller.commit_pending_resolution()
	cleanup_resolution_area()
	_refresh_hud()


func _trace_will_win_battle(trace: ResolutionTrace) -> bool:
	if trace == null or controller == null:
		return false
	return controller.get_total_score() + maxi(0, trace.hand_score_final) >= controller.get_target_score()


func _play_victory_target_feedback() -> void:
	if left_sidebar == null or not left_sidebar.has_method("play_battle_victory_target_feedback"):
		return
	await left_sidebar.play_battle_victory_target_feedback()


func _clear_victory_target_feedback() -> void:
	victory_target_restore_pending = false
	if left_sidebar != null and left_sidebar.has_method("clear_battle_victory_target_feedback"):
		left_sidebar.clear_battle_victory_target_feedback()


func _has_victory_target_feedback() -> bool:
	if left_sidebar == null or not left_sidebar.has_method("is_battle_victory_target_active"):
		return false
	return bool(left_sidebar.is_battle_victory_target_active())


func _restore_victory_target_feedback_if_needed() -> void:
	if not victory_target_restore_pending:
		return
	victory_target_restore_pending = false
	if left_sidebar == null:
		return
	if left_sidebar.has_method("play_battle_target_restore_feedback"):
		await left_sidebar.play_battle_target_restore_feedback(_build_hud_state())
	elif left_sidebar.has_method("clear_battle_victory_target_feedback"):
		left_sidebar.clear_battle_victory_target_feedback()
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


func move_selected_dice_to_resolution_by_trace(trace: ResolutionTrace) -> void:
	if trace == null or scoring_area == null:
		return

	var visual_slot_indices := _visual_selected_slot_indices(trace)
	_set_resolution_visual_index_map(trace, visual_slot_indices)
	var dice_datas := _resolution_die_view_data_for_slots(visual_slot_indices)
	if scoring_area.has_method("show_resolution_dice"):
		scoring_area.show_resolution_dice(dice_datas, true)
	await get_tree().process_frame
	_cache_resolution_return_rects(visual_slot_indices)

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
			await _create_battle_timer(0.03 if resolution_fast_mode else 0.08).timeout
	if not scoring_area.has_method("set_resolution_index_visible") and scoring_area.has_method("set_resolution_dice_visible"):
		scoring_area.set_resolution_dice_visible(true)


func return_resolution_dice_to_bench_by_trace(trace: ResolutionTrace, simultaneous: bool = false) -> void:
	if trace == null:
		return

	battle_ui_state = BattleUiState.CLEANUP
	_clear_resolution_highlights()
	var visual_slot_indices := _visual_selected_slot_indices(trace)
	var dice_datas := _resolution_die_view_data_for_slots(visual_slot_indices)
	var clones: Array[Control] = []
	for index in range(visual_slot_indices.size()):
		var die_index := visual_slot_indices[index]
		var data: DieViewData = dice_datas[index] if index < dice_datas.size() else null
		var start_rect := _resolution_dice_global_rect(index)
		if data == null or start_rect.size == Vector2.ZERO or animation_layer == null:
			continue
		var clone := _make_animation_dice_view()
		clone.set_meta("die_index", die_index)
		animation_layer.add_child(clone)
		if not clone.is_node_ready():
			await clone.ready
		if clone.has_method("render"):
			clone.render(data, style_config, icon_library, dice_visual_library)
		clone.global_position = start_rect.position
		clone.size = start_rect.size
		clones.append(clone)
		if scoring_area != null and scoring_area.has_method("set_resolution_index_visible"):
			scoring_area.set_resolution_index_visible(index, false)

	var remaining_hidden: Array[int] = []
	remaining_hidden.append_array(trace.selected_slot_indices)
	if clones.is_empty():
		_clear_returning_resolution_state()
		return

	if simultaneous:
		var tween := create_tween()
		tween.set_parallel(true)
		for clone in clones:
			var die_index := int(clone.get_meta("die_index", -1))
			var target_rect := _bench_die_global_rect(die_index)
			var move_duration := 0.08 if resolution_fast_mode else 0.22
			tween.tween_property(clone, "global_position", target_rect.position, move_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(clone, "size", target_rect.size, move_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		for clone in clones:
			if is_instance_valid(clone):
				clone.queue_free()
		_clear_returning_resolution_state()
		await _create_battle_timer(0.025 if resolution_fast_mode else 0.08).timeout
		return

	for index in range(clones.size()):
		var clone := clones[index]
		var die_index := int(clone.get_meta("die_index", -1))
		var target_rect := _bench_die_global_rect(die_index)
		var move_duration := 0.08 if resolution_fast_mode else 0.22
		var tween := create_tween()
		tween.tween_property(clone, "global_position", target_rect.position, move_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(clone, "size", target_rect.size, move_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		await tween.finished
		if is_instance_valid(clone):
			clone.queue_free()
		remaining_hidden.erase(die_index)
		if dice_bench_area != null and dice_bench_area.has_method("set_hidden_die_indices"):
			dice_bench_area.set_hidden_die_indices(remaining_hidden)
		if index < clones.size() - 1:
			await _create_battle_timer(0.02 if resolution_fast_mode else 0.045).timeout

	_clear_returning_resolution_state()
	await _create_battle_timer(0.025 if resolution_fast_mode else 0.08).timeout


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
		await _create_battle_timer(_resolution_step_duration()).timeout
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
		await _create_battle_timer(0.05 if resolution_fast_mode else 0.5).timeout
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
	resolution_return_rect_by_die_index.clear()
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
	is_resolution_playing = false
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
		BattleUiState.CLEANUP:
			return "Returning dice..."
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


func _resolution_dice_global_rect(index: int) -> Rect2:
	var fallback_size := style_config.dice_display_size if style_config != null else Vector2(96.0, 96.0)
	if scoring_area == null:
		return Rect2(Vector2.ZERO, fallback_size)
	if scoring_area.has_method("get_resolution_dice_global_rect"):
		var rect: Rect2 = scoring_area.get_resolution_dice_global_rect(index)
		if rect.size != Vector2.ZERO:
			return rect
	if scoring_area.has_method("get_resolution_dice_global_position"):
		return Rect2(scoring_area.get_resolution_dice_global_position(index), fallback_size)
	return Rect2(Vector2.ZERO, fallback_size)


func _bench_die_global_rect(die_index: int) -> Rect2:
	var fallback_size := style_config.dice_display_size if style_config != null else Vector2(96.0, 96.0)
	if resolution_return_rect_by_die_index.has(die_index):
		var cached_rect: Rect2 = resolution_return_rect_by_die_index[die_index]
		return cached_rect
	var rect := _live_bench_die_global_rect(die_index)
	if rect.size == Vector2.ZERO:
		rect.size = fallback_size
	return rect


func _live_bench_die_global_rect(die_index: int) -> Rect2:
	if dice_bench_area == null or not dice_bench_area.has_method("get_die_view_global_rect"):
		return Rect2()
	var rect: Rect2 = dice_bench_area.get_die_view_global_rect(die_index)
	return rect


func _cache_resolution_return_rects(slot_indices: Array[int]) -> void:
	resolution_return_rect_by_die_index.clear()
	for die_index in slot_indices:
		var rect := _live_bench_die_global_rect(die_index)
		if rect.size != Vector2.ZERO:
			resolution_return_rect_by_die_index[die_index] = rect


func _clear_returning_resolution_state() -> void:
	if scoring_area != null and scoring_area.has_method("clear_resolution_dice"):
		scoring_area.clear_resolution_dice()
	if dice_bench_area != null and dice_bench_area.has_method("clear_hidden_die_indices"):
		dice_bench_area.clear_hidden_die_indices()


func _refresh_hud() -> void:
	if left_sidebar == null or top_inventory_bar == null or scoring_area == null or dice_bench_area == null:
		return

	_sync_battle_intro_hidden_dice()
	var state := _build_hud_state()
	if left_sidebar.has_method("render"):
		left_sidebar.render(state)
	if top_inventory_bar.has_method("render"):
		top_inventory_bar.render(state)
	if scoring_area.has_method("render"):
		scoring_area.render(state)
	if dice_bench_area.has_method("render"):
		dice_bench_area.render(state)
	_sync_battle_intro_hidden_dice()
	if _is_combo_info_popup_visible() and combo_info_popup.has_method("render"):
		combo_info_popup.render(_build_combo_info_rows())
	_update_install_focus_overlay_layout()


func _sync_battle_intro_hidden_dice() -> void:
	if dice_bench_area == null:
		return
	if battle_intro_dice_revealed:
		return
	if not battle_intro_pending and not is_battle_intro_playing:
		return
	if battle_intro_die_indices.is_empty():
		battle_intro_die_indices = _all_dice_indices()
	if battle_intro_die_indices.is_empty():
		return
	if dice_bench_area.has_method("set_hidden_die_indices"):
		dice_bench_area.set_hidden_die_indices(battle_intro_die_indices)


func _prepare_hand_intro_magic() -> void:
	battle_intro_die_indices = _all_dice_indices()
	battle_intro_pending = not battle_intro_die_indices.is_empty()
	battle_intro_dice_revealed = false
	is_battle_intro_playing = battle_intro_pending
	if dice_bench_area != null and dice_bench_area.has_method("set_hidden_die_indices"):
		dice_bench_area.set_hidden_die_indices(battle_intro_die_indices)


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
	state.max_selected_dice = controller.get_max_selected_dice()
	state.phase_text = DisplayNames.phase_name(controller.get_phase_name())
	state.controls_locked = is_battle_intro_playing
	state.can_reroll = controller.can_reroll() and not is_resolution_playing and not is_reroll_playing and not is_battle_intro_playing and not reward_phase_active
	state.can_score = controller.can_score() and not is_resolution_playing and not is_reroll_playing and not is_battle_intro_playing and not reward_phase_active
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
	var dice_interactive := dice_enabled or reward_install_active
	var hand_scored := controller != null and controller.hand_state != null and controller.hand_state.scored and not is_resolution_playing

	for die_index in range(dice.size()):
		var rolled_face = rolled_by_die.get(die_index, null)
		var disabled := (rolled_face == null and not reward_install_active) or (not dice_interactive and not is_resolution_playing)
		var die_data = DieViewData.new()
		die_data.setup_from_die(dice[die_index], die_index, rolled_face, dice_enabled, hand_scored, disabled)
		if reward_phase_active or victory_reward_showcase_active:
			die_data.disabled = false
			die_data.rerollable = false
			die_data.selected = false
			die_data.scored = false
			if victory_reward_showcase_active:
				_set_die_data_to_max_face(die_data)
			elif die_data.current_face == null and not die_data.faces.is_empty():
				die_data.current_face_index = 0
				die_data.current_face = die_data.faces[0]
		result.append(die_data)

	return result


func _set_die_data_to_max_face(die_data: DieViewData) -> void:
	if die_data == null or die_data.faces.is_empty():
		return
	var max_face = die_data.faces[0]
	for face_data in die_data.faces:
		if face_data == null:
			continue
		if max_face == null or face_data.pip > max_face.pip:
			max_face = face_data
	if max_face == null:
		return
	die_data.current_face_index = max_face.face_index
	die_data.current_face = max_face


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


func _all_dice_indices() -> Array[int]:
	var result: Array[int] = []
	var dice := _get_dice()
	for die_index in range(dice.size()):
		result.append(die_index)
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


func _play_reroll_magic() -> void:
	var selected_indices: Array[int] = _selected_dice_indices()
	if selected_indices.is_empty():
		return

	is_reroll_playing = true
	battle_ui_state = BattleUiState.ROLLING
	status_text = str(TranslationServer.translate(&"AUTO.TEXT.332A22260969"))
	if dice_bench_area != null and dice_bench_area.has_method("hide_info"):
		dice_bench_area.hide_info()
	var effects: Array[Control] = _spawn_reroll_magic_effects(selected_indices)
	_refresh_hud()

	var cover_wait: float = 0.28 if resolution_fast_mode else 0.52
	await _create_battle_timer(cover_wait).timeout

	if controller != null:
		controller.reroll()

	var reveal_fade_duration: float = 0.38 if resolution_fast_mode else 0.66
	_begin_magic_reveal_fade(effects, reveal_fade_duration)
	var finish_wait: float = reveal_fade_duration + (0.04 if resolution_fast_mode else 0.08)
	await _create_battle_timer(finish_wait).timeout
	for effect in effects:
		if is_instance_valid(effect):
			effect.queue_free()

	is_reroll_playing = false
	resolution_fast_mode = false
	battle_ui_state = BattleUiState.IDLE
	_refresh_hud()


func _play_victory_reward_showcase() -> void:
	var die_indices := _all_dice_indices()
	if die_indices.is_empty():
		victory_reward_showcase_active = true
		_refresh_hud()
		return

	if dice_bench_area != null:
		if dice_bench_area.has_method("hide_info"):
			dice_bench_area.hide_info()
		if dice_bench_area.has_method("clear_highlights"):
			dice_bench_area.clear_highlights()

	is_battle_intro_playing = true
	battle_intro_pending = false
	battle_intro_dice_revealed = false
	battle_intro_die_indices = die_indices.duplicate()
	status_text = str(TranslationServer.translate(&"AUTO.TEXT.BD9FEA62A9DC"))
	if dice_bench_area != null and dice_bench_area.has_method("set_hidden_die_indices"):
		dice_bench_area.set_hidden_die_indices(battle_intro_die_indices)
	_refresh_hud()
	await get_tree().process_frame
	await get_tree().process_frame

	var effects := _spawn_reroll_magic_effects(battle_intro_die_indices)
	var reveal_wait: float = 0.32 if resolution_fast_mode else 0.58
	await _create_battle_timer(reveal_wait).timeout

	victory_reward_showcase_active = true
	_reset_bench_display_order()
	var reveal_fade_duration: float = 0.34 if resolution_fast_mode else 0.62
	_begin_magic_reveal_fade(effects, reveal_fade_duration)
	battle_intro_dice_revealed = true
	if dice_bench_area != null and dice_bench_area.has_method("clear_hidden_die_indices"):
		dice_bench_area.clear_hidden_die_indices()
	_refresh_hud()

	var fade_tail_wait: float = reveal_fade_duration + (0.04 if resolution_fast_mode else 0.08)
	await _create_battle_timer(fade_tail_wait).timeout

	for effect in effects:
		if is_instance_valid(effect):
			effect.queue_free()
	is_battle_intro_playing = false
	battle_intro_dice_revealed = false
	battle_intro_die_indices.clear()
	_refresh_hud()


func _reset_bench_display_order() -> void:
	if dice_bench_area == null:
		return
	if dice_bench_area.has_method("reset_display_order"):
		dice_bench_area.reset_display_order()


func _play_battle_intro_magic() -> void:
	if not battle_intro_pending:
		return
	battle_intro_pending = false
	is_battle_intro_playing = true
	battle_intro_dice_revealed = false
	await _restore_victory_target_feedback_if_needed()
	if battle_intro_die_indices.is_empty():
		battle_intro_die_indices = _all_dice_indices()
	if battle_intro_die_indices.is_empty():
		is_battle_intro_playing = false
		battle_intro_dice_revealed = false
		_refresh_hud()
		return

	if dice_bench_area != null and dice_bench_area.has_method("set_hidden_die_indices"):
		dice_bench_area.set_hidden_die_indices(battle_intro_die_indices)
	_refresh_hud()
	await get_tree().process_frame
	await get_tree().process_frame

	var round_number := controller.get_current_hand_number() if controller != null else 1
	await _play_round_intro_banner(round_number)

	var effects: Array[Control] = _spawn_reroll_magic_effects(battle_intro_die_indices)
	var reveal_wait: float = 0.32 if resolution_fast_mode else 0.58
	await _create_battle_timer(reveal_wait).timeout

	var reveal_fade_duration: float = 0.34 if resolution_fast_mode else 0.62
	_begin_magic_reveal_fade(effects, reveal_fade_duration)
	battle_intro_dice_revealed = true
	if dice_bench_area != null and dice_bench_area.has_method("clear_hidden_die_indices"):
		dice_bench_area.clear_hidden_die_indices()
	_refresh_hud()

	var fade_tail_wait: float = reveal_fade_duration + (0.04 if resolution_fast_mode else 0.08)
	await _create_battle_timer(fade_tail_wait).timeout

	for effect in effects:
		if is_instance_valid(effect):
			effect.queue_free()
	is_battle_intro_playing = false
	battle_intro_dice_revealed = false
	battle_intro_die_indices.clear()
	resolution_fast_mode = false
	_refresh_hud()


func _play_round_intro_banner(round_number: int) -> void:
	if animation_layer == null:
		var fallback_hold := 0.45 if resolution_fast_mode else 1.5
		await _create_battle_timer(fallback_hold).timeout
		return

	var banner_control: Control = _instantiate_control(round_intro_banner_scene, Control.new())
	animation_layer.add_child(banner_control)
	banner_control.z_index = 430
	banner_control.size = animation_layer.size
	if not banner_control.is_node_ready():
		await banner_control.ready

	var target_rect := _round_intro_banner_target_rect()
	var banner := banner_control as RoundIntroBanner
	if banner != null:
		await banner.play_at_rect(round_number, target_rect, resolution_fast_mode)
	elif banner_control.has_method("play_at_rect"):
		await banner_control.call("play_at_rect", round_number, target_rect, resolution_fast_mode)
	elif banner_control.has_method("play"):
		await banner_control.call("play", round_number, resolution_fast_mode)
	else:
		var fallback_hold := 0.45 if resolution_fast_mode else 1.5
		await _create_battle_timer(fallback_hold).timeout

	if is_instance_valid(banner_control) and not banner_control.is_queued_for_deletion():
		banner_control.queue_free()


func _round_intro_banner_target_rect() -> Rect2:
	if animation_layer == null:
		return Rect2()
	if scoring_area != null:
		var scoring_rect := _global_rect_to_animation_layer_local(scoring_area.get_global_rect())
		if scoring_rect.size != Vector2.ZERO:
			return scoring_rect
	return Rect2(Vector2.ZERO, animation_layer.size)


func _begin_magic_reveal_fade(effects: Array[Control], duration: float) -> void:
	for effect in effects:
		if is_instance_valid(effect) and effect.has_method("begin_reveal_fade"):
			effect.call("begin_reveal_fade", duration)


func _spawn_reroll_magic_effects(die_indices: Array[int]) -> Array[Control]:
	var result: Array[Control] = []
	if animation_layer == null or dice_bench_area == null:
		return result

	for die_index in die_indices:
		var rect: Rect2 = Rect2()
		if dice_bench_area.has_method("get_die_magic_fx_global_rect"):
			rect = dice_bench_area.get_die_magic_fx_global_rect(die_index)
		elif dice_bench_area.has_method("get_die_view_global_rect"):
			rect = dice_bench_area.get_die_view_global_rect(die_index)
		if rect.size == Vector2.ZERO:
			continue

		var effect: Control = _instantiate_control(reroll_magic_fx_scene, Control.new())
		animation_layer.add_child(effect)
		var local_rect: Rect2 = _global_rect_to_animation_layer_local(rect)
		if effect.has_method("play_at_rect"):
			if effect.has_method("play_at_local_rect"):
				effect.play_at_local_rect(local_rect, resolution_fast_mode)
			else:
				effect.play_at_rect(rect, resolution_fast_mode)
		else:
			effect.position = local_rect.position
			effect.size = local_rect.size
		result.append(effect)

	return result


func _global_rect_to_animation_layer_local(global_rect: Rect2) -> Rect2:
	if animation_layer == null:
		return global_rect
	var inverse: Transform2D = animation_layer.get_global_transform_with_canvas().affine_inverse()
	var local_position: Vector2 = inverse * global_rect.position
	var local_end: Vector2 = inverse * (global_rect.position + global_rect.size)
	return Rect2(local_position, local_end - local_position)


func _create_battle_timer(duration: float) -> SceneTreeTimer:
	return get_tree().create_timer(maxf(0.0, duration), false)


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
