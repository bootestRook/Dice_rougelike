extends Control
class_name MainPrototypeView


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const AutomationBridge = preload("res://scripts/debug/AutomationBridge.gd")
const DEFAULT_MENU_ART = preload("res://scenes/main/resources/MainMenuArtConfig.tres")


const BATTLE_SCREEN_PATH := "res://scenes/battle/BattleScreen.tscn"
const MapStageViewScript = preload("res://scripts/ui/map/MapStageView.gd")
const FORGE_INSTALL_SCREEN_PATH := "res://scenes/forge/ForgeInstallScreen.tscn"
const REWARD_SCREEN_PATH := "res://scenes/reward/RewardScreen.tscn"
const RUN_RESULT_SCREEN_PATH := "res://scenes/run/RunResultScreen.tscn"
const SHOP_SCREEN_PATH := "res://scenes/shop/ShopScreen.tscn"
const GM_PHYSICS_DICE_TEST_SCREEN_PATH := "res://scenes/debug/GmPhysicsDiceTestScreen.tscn"
const GM_DICE_MATERIAL_INSPECTOR_SCREEN_PATH := "res://scenes/debug/GmDiceMaterialInspectorScreen.tscn"


@export var menu_art_config: MainMenuArtConfig = DEFAULT_MENU_ART

var game_flow_controller: GameFlowController = null
var current_view_id: StringName = &""
var automation_bridge: AutomationBridge = null
var automation_input_shield: Control = null
var run_stage_root: Control = null
var main_stage_container: Control = null
var run_stage_input_shield: Control = null
var battle_stage_view: Control = null
var map_stage_view: Control = null
var battle_screen: Control = null


func _ready() -> void:
	_create_flow_controller()
	_show_main_menu()
	_maybe_start_automation_bridge()


func _create_flow_controller() -> void:
	game_flow_controller = GameFlowController.new()
	add_child(game_flow_controller)
	game_flow_controller.map_requested.connect(_on_map_requested)
	game_flow_controller.battle_requested.connect(_on_battle_requested)
	game_flow_controller.reward_requested.connect(_on_reward_requested)
	game_flow_controller.forge_install_requested.connect(_on_forge_install_requested)
	game_flow_controller.shop_requested.connect(_on_shop_requested)
	game_flow_controller.run_result_requested.connect(_on_run_result_requested)
	game_flow_controller.flow_state_changed.connect(_on_flow_state_changed)


func _show_main_menu() -> void:
	_build_view()


func _build_view() -> void:
	current_view_id = &"main"
	_clear_screen()

	var art := _get_menu_art()
	var root := Control.new()
	root.name = "MainMenuRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_add_background(root, art)
	_add_logo(root, art)
	_add_version_label(root, art)
	_add_button_bar(root, art)
	_add_gm_floating_entry(root, art)


func _get_menu_art() -> MainMenuArtConfig:
	if menu_art_config != null:
		return menu_art_config
	return DEFAULT_MENU_ART


func _add_background(root: Control, art: MainMenuArtConfig) -> void:
	if art.background_texture != null:
		var background := TextureRect.new()
		background.name = "BackgroundArt"
		background.texture = art.background_texture
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(background)
	else:
		var fallback := ColorRect.new()
		fallback.name = "BackgroundFallback"
		fallback.color = art.background_fallback_color
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(fallback)

	var overlay := ColorRect.new()
	overlay.name = "ReadabilityOverlay"
	overlay.color = art.overlay_color
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)


func _add_logo(root: Control, art: MainMenuArtConfig) -> void:
	var logo_area := Control.new()
	logo_area.name = "LogoArea"
	_apply_anchor_rect(logo_area, art.logo_area)
	root.add_child(logo_area)

	if art.logo_texture != null:
		var logo := TextureRect.new()
		logo.name = "LogoArt"
		logo.texture = art.logo_texture
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		logo_area.add_child(logo)
		return

	var title_shadow := _make_title_label(art, art.red_glow_color, Vector2(6, 6), 92)
	logo_area.add_child(title_shadow)

	var title_glow := _make_title_label(art, art.blue_glow_color, Vector2(-6, 4), 92)
	logo_area.add_child(title_glow)

	var title := _make_title_label(art, art.text_color, Vector2.ZERO, 92)
	logo_area.add_child(title)


func _add_version_label(root: Control, art: MainMenuArtConfig) -> void:
	var version_label := Label.new()
	version_label.name = "VersionLabel"
	version_label.text = art.version_text
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	version_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	version_label.add_theme_font_size_override("font_size", 28)
	version_label.add_theme_color_override("font_color", art.text_color)
	version_label.add_theme_color_override("font_shadow_color", art.dark_text_shadow_color)
	version_label.add_theme_constant_override("shadow_offset_x", 3)
	version_label.add_theme_constant_override("shadow_offset_y", 3)
	version_label.anchor_left = art.version_position.x - 0.18
	version_label.anchor_right = minf(art.version_position.x + 0.08, 0.98)
	version_label.anchor_top = art.version_position.y
	version_label.anchor_bottom = art.version_position.y + 0.05
	root.add_child(version_label)


func _add_button_bar(root: Control, art: MainMenuArtConfig) -> void:
	var panel_root := Control.new()
	panel_root.name = "ButtonBar"
	_apply_anchor_rect(panel_root, art.button_bar_area)
	root.add_child(panel_root)

	if art.button_panel_texture != null:
		var panel_texture := TextureRect.new()
		panel_texture.name = "ButtonBarArt"
		panel_texture.texture = art.button_panel_texture
		panel_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		panel_texture.stretch_mode = TextureRect.STRETCH_SCALE
		panel_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel_root.add_child(panel_texture)
	else:
		var panel_background := PanelContainer.new()
		panel_background.name = "ButtonBarFallback"
		panel_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel_background.add_theme_stylebox_override(
			"panel",
			_make_panel_style(art.button_panel_color, Color(0.58, 0.66, 0.76, 0.75), 3, 6)
		)
		panel_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel_root.add_child(panel_background)

	var margin := MarginContainer.new()
	margin.name = "ButtonMargin"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_root.add_child(margin)

	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 28)
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(buttons)

	buttons.add_child(_make_art_button(
		str(TranslationServer.translate(&"AUTO.TEXT.2857A3704A65")),
		art.start_button_size,
		art.start_button_normal_texture,
		art.start_button_hover_texture,
		art.start_button_pressed_texture,
		art.start_button_color,
		art.start_button_hover_color,
		art.start_button_pressed_color,
		art,
		_on_start_battle_pressed
	))
	buttons.add_child(_make_art_button(
		"GM物理投骰",
		Vector2(320, art.start_button_size.y),
		null,
		null,
		null,
		Color(0.06, 0.48, 0.56, 0.94),
		Color(0.08, 0.60, 0.70, 0.98),
		Color(0.03, 0.33, 0.42, 0.98),
		art,
		_on_gm_physics_dice_test_pressed
	))
	buttons.add_child(_make_art_button(
		str(TranslationServer.translate(&"AUTO.TEXT.FEECB1E6ADEC")),
		art.exit_button_size,
		art.exit_button_normal_texture,
		art.exit_button_hover_texture,
		art.exit_button_pressed_texture,
		art.exit_button_color,
		art.exit_button_hover_color,
		art.exit_button_pressed_color,
		art,
		_on_exit_pressed
	))


func _add_gm_floating_entry(root: Control, art: MainMenuArtConfig) -> void:
	var host := Control.new()
	host.name = "GmFloatingEntry"
	host.anchor_left = 1.0
	host.anchor_top = 0.0
	host.anchor_right = 1.0
	host.anchor_bottom = 0.0
	host.offset_left = -230.0
	host.offset_top = 26.0
	host.offset_right = -28.0
	host.offset_bottom = 210.0
	host.z_index = 30
	root.add_child(host)

	var gm_button := Button.new()
	gm_button.name = "GmFloatingButton"
	gm_button.text = "GM"
	gm_button.custom_minimum_size = Vector2(86, 46)
	gm_button.anchor_left = 1.0
	gm_button.anchor_top = 0.0
	gm_button.anchor_right = 1.0
	gm_button.anchor_bottom = 0.0
	gm_button.offset_left = -86.0
	gm_button.offset_top = 0.0
	gm_button.offset_right = 0.0
	gm_button.offset_bottom = 46.0
	gm_button.focus_mode = Control.FOCUS_NONE
	gm_button.add_theme_font_size_override("font_size", 24)
	gm_button.add_theme_color_override("font_color", art.text_color)
	gm_button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.06, 0.18, 0.28, 0.96), Color(0.86, 0.94, 1.0, 0.86), 2, 6))
	gm_button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.08, 0.28, 0.40, 0.98), Color(1.0, 0.95, 0.70, 0.94), 2, 6))
	gm_button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.03, 0.12, 0.22, 0.98), Color(0.80, 0.88, 1.0, 0.78), 2, 6))
	host.add_child(gm_button)

	var menu := PanelContainer.new()
	menu.name = "GmFunctionMenu"
	menu.visible = false
	menu.anchor_left = 0.0
	menu.anchor_top = 0.0
	menu.anchor_right = 1.0
	menu.anchor_bottom = 0.0
	menu.offset_left = 0.0
	menu.offset_top = 54.0
	menu.offset_right = 0.0
	menu.offset_bottom = 176.0
	menu.mouse_filter = Control.MOUSE_FILTER_STOP
	menu.add_theme_stylebox_override("panel", _make_panel_style(Color(0.025, 0.050, 0.095, 0.97), Color(0.72, 0.86, 1.0, 0.78), 2, 6))
	host.add_child(menu)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	menu.add_child(margin)

	var actions := VBoxContainer.new()
	actions.name = "GmFunctionList"
	actions.add_theme_constant_override("separation", 8)
	margin.add_child(actions)

	var material_button := _make_gm_menu_button("骰子材质检查", "GmDiceMaterialInspectorButton")
	material_button.pressed.connect(_on_gm_dice_material_inspector_pressed)
	actions.add_child(material_button)

	var physics_button := _make_gm_menu_button("GM物理投骰", "GmPhysicsDiceTestButton")
	physics_button.pressed.connect(_on_gm_physics_dice_test_pressed)
	actions.add_child(physics_button)

	gm_button.pressed.connect(func() -> void:
		menu.visible = not menu.visible
	)


func _make_gm_menu_button(text: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(178, 42)
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color(1.0, 0.98, 0.90, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.90, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.98, 0.90, 1.0))
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.10, 0.24, 0.35, 0.96), Color(0.62, 0.78, 0.96, 0.64), 1, 5))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.14, 0.34, 0.48, 0.98), Color(0.88, 0.94, 1.0, 0.82), 1, 5))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.06, 0.18, 0.28, 0.98), Color(0.70, 0.84, 1.0, 0.76), 1, 5))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _make_title_label(art: MainMenuArtConfig, color: Color, offset: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = art.title_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", art.dark_text_shadow_color)
	label.add_theme_constant_override("shadow_offset_x", 4)
	label.add_theme_constant_override("shadow_offset_y", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left += offset.x
	label.offset_top += offset.y
	label.offset_right += offset.x
	label.offset_bottom += offset.y
	return label


func _make_art_button(
	text: String,
	minimum_size: Vector2,
	normal_texture: Texture2D,
	hover_texture: Texture2D,
	pressed_texture: Texture2D,
	normal_color: Color,
	hover_color: Color,
	pressed_color: Color,
	art: MainMenuArtConfig,
	pressed_callback: Callable
) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = minimum_size
	wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var fallback_panel := PanelContainer.new()
	fallback_panel.name = "FallbackPanel"
	fallback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(fallback_panel)

	var texture_rect := TextureRect.new()
	texture_rect.name = "ButtonArt"
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(texture_rect)

	var button := Button.new()
	button.name = text
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 44)
	button.add_theme_color_override("font_color", art.text_color)
	button.add_theme_color_override("font_hover_color", art.text_color)
	button.add_theme_color_override("font_pressed_color", art.text_color)
	button.add_theme_color_override("font_shadow_color", art.dark_text_shadow_color)
	button.add_theme_constant_override("shadow_offset_x", 3)
	button.add_theme_constant_override("shadow_offset_y", 4)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(pressed_callback)
	button.mouse_entered.connect(func() -> void:
		_apply_button_visual(texture_rect, fallback_panel, hover_texture, normal_texture, hover_color)
	)
	button.mouse_exited.connect(func() -> void:
		_apply_button_visual(texture_rect, fallback_panel, normal_texture, normal_texture, normal_color)
	)
	button.button_down.connect(func() -> void:
		_apply_button_visual(texture_rect, fallback_panel, pressed_texture, normal_texture, pressed_color)
	)
	button.button_up.connect(func() -> void:
		var next_texture := hover_texture if button.is_hovered() else normal_texture
		var next_color := hover_color if button.is_hovered() else normal_color
		_apply_button_visual(texture_rect, fallback_panel, next_texture, normal_texture, next_color)
	)
	wrapper.add_child(button)

	_apply_button_visual(texture_rect, fallback_panel, normal_texture, normal_texture, normal_color)
	return wrapper


func _apply_button_visual(
	texture_rect: TextureRect,
	fallback_panel: PanelContainer,
	texture: Texture2D,
	normal_texture: Texture2D,
	fallback_color: Color
) -> void:
	var resolved_texture := texture if texture != null else normal_texture
	texture_rect.texture = resolved_texture
	texture_rect.visible = resolved_texture != null
	fallback_panel.visible = resolved_texture == null
	fallback_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(fallback_color, Color(0.98, 0.9, 0.55, 0.95), 3, 5)
	)


func _make_panel_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	return style


func _apply_anchor_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = rect.position.x
	control.anchor_top = rect.position.y
	control.anchor_right = rect.position.x + rect.size.x
	control.anchor_bottom = rect.position.y + rect.size.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _on_start_battle_pressed() -> void:
	game_flow_controller.start_new_run()


func _on_gm_physics_dice_test_pressed() -> void:
	current_view_id = &"gm_physics_dice_test"
	_clear_screen()
	var screen = load(GM_PHYSICS_DICE_TEST_SCREEN_PATH).instantiate()
	if screen.has_method("setup"):
		screen.call("setup", Callable(self, "_show_main_menu"))
	add_child(screen)


func _on_gm_dice_material_inspector_pressed() -> void:
	current_view_id = &"gm_dice_material_inspector"
	_clear_screen()
	var screen = load(GM_DICE_MATERIAL_INSPECTOR_SCREEN_PATH).instantiate()
	if screen.has_method("setup"):
		screen.call("setup", Callable(self, "_show_main_menu"))
	add_child(screen)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_battle_requested(requested_run_state: RunState) -> void:
	current_view_id = &"battle"
	_ensure_run_stage(game_flow_controller.get_map_state() if game_flow_controller != null else {})
	_ensure_battle_stage_screen(requested_run_state, true)
	await _ensure_map_stage_view(game_flow_controller.get_map_state() if game_flow_controller != null else {})
	if map_stage_view != null and map_stage_view.has_method("play_lower"):
		_set_run_stage_input_locked(true)
		await map_stage_view.call("play_lower")
		_set_run_stage_input_locked(false)
	elif map_stage_view != null:
		map_stage_view.visible = false
		_set_run_stage_input_locked(false)
	if battle_screen != null and battle_screen.has_method("start_battle_with_run_state"):
		battle_screen.call("start_battle_with_run_state", game_flow_controller, requested_run_state)


func _on_map_requested(map_state: Dictionary) -> void:
	current_view_id = &"map"
	_ensure_run_stage(map_state)
	_ensure_battle_stage_screen(game_flow_controller.get_run_state() if game_flow_controller != null else null, true)
	_prepare_battle_screen_for_map_stage()
	await _ensure_map_stage_view(map_state)
	_prepare_battle_screen_for_map_stage()
	if map_stage_view != null:
		if map_stage_view.has_method("setup"):
			map_stage_view.call("setup", game_flow_controller, map_state)
		if map_stage_view.has_method("play_raise"):
			_set_run_stage_input_locked(true)
			await map_stage_view.call("play_raise")
			_set_run_stage_input_locked(false)
		else:
			map_stage_view.visible = true
			_set_run_stage_input_locked(false)


func _on_reward_requested(choices: Array) -> void:
	var existing_battle_screen := _current_battle_screen()
	if existing_battle_screen != null and existing_battle_screen.has_method("show_reward_choices"):
		current_view_id = &"battle_reward"
		existing_battle_screen.call("show_reward_choices", choices)
		return

	current_view_id = &"reward"
	_clear_screen()
	var reward_screen = load(REWARD_SCREEN_PATH).instantiate()
	reward_screen.setup(game_flow_controller, choices)
	add_child(reward_screen)


func _on_forge_install_requested(piece) -> void:
	var existing_battle_screen := _current_battle_screen()
	if existing_battle_screen != null and existing_battle_screen.has_method("begin_reward_install"):
		current_view_id = &"battle_forge"
		existing_battle_screen.call("begin_reward_install", piece)
		return

	current_view_id = &"forge"
	_clear_screen()
	var forge_screen = load(FORGE_INSTALL_SCREEN_PATH).instantiate()
	forge_screen.setup(game_flow_controller, game_flow_controller.get_run_state(), piece)
	add_child(forge_screen)


func _on_run_result_requested(result_run_state: RunState) -> void:
	current_view_id = &"run_result"
	_clear_screen()
	var run_result_screen = load(RUN_RESULT_SCREEN_PATH).instantiate()
	run_result_screen.setup(game_flow_controller, result_run_state)
	add_child(run_result_screen)


func _on_shop_requested(shop_state: Dictionary) -> void:
	current_view_id = &"shop"
	_clear_screen()
	var shop_screen = load(SHOP_SCREEN_PATH).instantiate()
	shop_screen.setup(game_flow_controller, game_flow_controller.get_run_state(), shop_state)
	add_child(shop_screen)


func _on_flow_state_changed(state_id: StringName) -> void:
	if state_id == &"main":
		_show_main_menu()


func _ensure_run_stage(map_state: Dictionary = {}) -> void:
	if run_stage_root != null and is_instance_valid(run_stage_root):
		return

	_clear_screen()
	run_stage_root = Control.new()
	run_stage_root.name = "RunStageRoot"
	run_stage_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(run_stage_root)

	main_stage_container = Control.new()
	main_stage_container.name = "MainStageContainer"
	main_stage_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	run_stage_root.add_child(main_stage_container)

	battle_stage_view = Control.new()
	battle_stage_view.name = "BattleStageView"
	battle_stage_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_stage_container.add_child(battle_stage_view)

	_ensure_run_stage_input_shield()


func _ensure_battle_stage_screen(requested_run_state: RunState, defer_start: bool = false) -> void:
	if battle_stage_view == null or not is_instance_valid(battle_stage_view):
		_ensure_run_stage(game_flow_controller.get_map_state() if game_flow_controller != null else {})

	var existing_battle_screen := _current_battle_screen()
	if existing_battle_screen != null:
		battle_screen = existing_battle_screen
		if not defer_start and existing_battle_screen.has_method("start_battle_with_run_state"):
			existing_battle_screen.call("start_battle_with_run_state", game_flow_controller, requested_run_state)
		return

	battle_screen = load(BATTLE_SCREEN_PATH).instantiate() as Control
	battle_screen.setup(game_flow_controller, requested_run_state, defer_start)
	battle_stage_view.add_child(battle_screen)


func _ensure_map_stage_view(map_state: Dictionary = {}) -> void:
	if battle_screen == null or not is_instance_valid(battle_screen):
		return
	if not battle_screen.is_node_ready():
		await battle_screen.ready
	if map_stage_view == null or not is_instance_valid(map_stage_view):
		map_stage_view = MapStageViewScript.new() as Control
		map_stage_view.name = "MapStageView"
	if map_stage_view.has_method("setup"):
		map_stage_view.call("setup", game_flow_controller, map_state)
	if map_stage_view.has_signal("interaction_lock_changed") and not map_stage_view.is_connected("interaction_lock_changed", Callable(self, "_on_map_interaction_lock_changed")):
		map_stage_view.connect("interaction_lock_changed", Callable(self, "_on_map_interaction_lock_changed"))
	if battle_screen.has_method("attach_map_stage_view"):
		battle_screen.call("attach_map_stage_view", map_stage_view)


func _ensure_run_stage_input_shield() -> void:
	if run_stage_root == null or not is_instance_valid(run_stage_root):
		return
	if run_stage_input_shield != null and is_instance_valid(run_stage_input_shield):
		return
	run_stage_input_shield = Control.new()
	run_stage_input_shield.name = "RunStageInputShield"
	run_stage_input_shield.mouse_filter = Control.MOUSE_FILTER_STOP
	run_stage_input_shield.z_index = 4090
	run_stage_input_shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	run_stage_input_shield.visible = false
	run_stage_root.add_child(run_stage_input_shield)


func _set_run_stage_input_locked(locked: bool) -> void:
	_ensure_run_stage_input_shield()
	if run_stage_input_shield != null and is_instance_valid(run_stage_input_shield):
		run_stage_input_shield.visible = locked


func _on_map_interaction_lock_changed(locked: bool) -> void:
	_set_run_stage_input_locked(locked)


func _prepare_battle_screen_for_map_stage() -> void:
	var existing_battle_screen := _current_battle_screen()
	if existing_battle_screen != null and existing_battle_screen.has_method("prepare_for_map_stage"):
		existing_battle_screen.call("prepare_for_map_stage")


func _clear_screen() -> void:
	for child in get_children():
		if child != game_flow_controller and child != automation_bridge and child != automation_input_shield:
			remove_child(child)
			child.queue_free()
	run_stage_root = null
	main_stage_container = null
	run_stage_input_shield = null
	battle_stage_view = null
	map_stage_view = null
	battle_screen = null


func _current_battle_screen() -> Control:
	if battle_screen != null and is_instance_valid(battle_screen):
		return battle_screen
	return _find_battle_screen(self)


func _find_battle_screen(root_node: Node) -> Control:
	for child in root_node.get_children():
		if child is Control and child.has_method("start_battle_with_run_state") and child.has_method("show_reward_choices"):
			return child as Control
		var nested := _find_battle_screen(child)
		if nested != null:
			return nested
	return null


func _maybe_start_automation_bridge() -> void:
	if not _automation_bridge_requested():
		return
	automation_bridge = AutomationBridge.new()
	automation_bridge.name = "AutomationBridge"
	add_child(automation_bridge)
	automation_bridge.setup(self, _automation_bridge_port())
	automation_set_input_locked(_automation_lock_requested())


func _automation_bridge_requested() -> bool:
	if OS.get_environment("DICE_AUTOMATION_BRIDGE") == "1":
		return true
	for arg in OS.get_cmdline_user_args():
		if arg == "--automation-bridge" or arg.begins_with("--automation-port="):
			return true
	return false


func _automation_lock_requested() -> bool:
	if OS.get_environment("DICE_AUTOMATION_LOCK_INPUT") == "1":
		return true
	for arg in OS.get_cmdline_user_args():
		if arg == "--automation-lock":
			return true
	return false


func _automation_bridge_port() -> int:
	var env_port := OS.get_environment("DICE_AUTOMATION_PORT")
	if env_port.is_valid_int():
		return max(1, int(env_port))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--automation-port="):
			var raw_port := arg.trim_prefix("--automation-port=")
			if raw_port.is_valid_int():
				return max(1, int(raw_port))
	return AutomationBridge.DEFAULT_PORT


func automation_set_input_locked(locked: bool) -> void:
	_ensure_automation_input_shield()
	if automation_input_shield != null:
		automation_input_shield.visible = locked


func automation_is_input_locked() -> bool:
	return automation_input_shield != null and automation_input_shield.visible


func _ensure_automation_input_shield() -> void:
	if automation_input_shield != null:
		return
	automation_input_shield = Control.new()
	automation_input_shield.name = "AutomationInputShield"
	automation_input_shield.mouse_filter = Control.MOUSE_FILTER_STOP
	automation_input_shield.z_index = 4096
	automation_input_shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(automation_input_shield)

	var scrim := ColorRect.new()
	scrim.name = "ShieldScrim"
	scrim.color = Color(0.0, 0.0, 0.0, 0.18)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	automation_input_shield.add_child(scrim)

	var label := Label.new()
	label.name = "ShieldLabel"
	label.text = "自动运行中\n游戏视窗点击已暂时屏蔽"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.72, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.anchor_left = 0.34
	label.anchor_right = 0.66
	label.anchor_top = 0.04
	label.anchor_bottom = 0.16
	automation_input_shield.add_child(label)
	automation_input_shield.visible = false


func automation_get_snapshot() -> Dictionary:
	var snapshot := {
		"view": str(current_view_id),
		"flow_state": str(game_flow_controller.current_state_id) if game_flow_controller != null else "",
		"input_locked": automation_is_input_locked(),
	}
	if game_flow_controller != null:
		snapshot["run"] = _automation_run_snapshot(game_flow_controller.get_run_state())
	var battle_screen := _current_battle_screen()
	if battle_screen != null and battle_screen.has_method("automation_get_snapshot"):
		snapshot["battle"] = battle_screen.call("automation_get_snapshot")
	if map_stage_view != null and is_instance_valid(map_stage_view) and map_stage_view.has_method("automation_get_snapshot"):
		snapshot["map"] = map_stage_view.call("automation_get_snapshot")
	var gm_material_screen := _find_gm_material_inspector_screen(self)
	if gm_material_screen != null and gm_material_screen.has_method("automation_get_snapshot"):
		snapshot["gm_material_inspector"] = gm_material_screen.call("automation_get_snapshot")
	if current_view_id == &"main":
		snapshot["gm_main_menu"] = _automation_gm_main_menu_snapshot()
	return snapshot


func automation_open_gm_material_inspector() -> Dictionary:
	if current_view_id != &"main":
		return _automation_error("当前不在主菜单。")
	_on_gm_dice_material_inspector_pressed()
	return _automation_ok("已打开骰子材质检查。")


func automation_start_run() -> Dictionary:
	if game_flow_controller == null:
		return _automation_error("流程控制器尚未准备好。")
	automation_set_input_locked(true)
	game_flow_controller.start_new_run()
	return _automation_ok("已开始新一局。")


func automation_select_dice(indices: Array[int]) -> Dictionary:
	var battle_screen := _current_battle_screen()
	if battle_screen == null or not battle_screen.has_method("automation_select_dice"):
		return _automation_error("当前没有可操作的战斗界面。")
	return battle_screen.call("automation_select_dice", indices)


func automation_preview_selection(indices: Array[int]) -> Dictionary:
	var battle_screen := _current_battle_screen()
	if battle_screen == null or not battle_screen.has_method("automation_preview_selection"):
		return _automation_error("当前没有可预览的战斗界面。")
	return battle_screen.call("automation_preview_selection", indices)


func automation_preview_selections(selections: Array) -> Dictionary:
	var battle_screen := _current_battle_screen()
	if battle_screen == null or not battle_screen.has_method("automation_preview_selections"):
		return _automation_error("当前没有可批量预览的战斗界面。")
	return battle_screen.call("automation_preview_selections", selections)


func automation_reroll() -> Dictionary:
	var battle_screen := _current_battle_screen()
	if battle_screen == null or not battle_screen.has_method("automation_reroll"):
		return _automation_error("当前没有可重投的战斗界面。")
	return battle_screen.call("automation_reroll")


func automation_score() -> Dictionary:
	var battle_screen := _current_battle_screen()
	if battle_screen == null or not battle_screen.has_method("automation_score"):
		return _automation_error("当前没有可结算的战斗界面。")
	return battle_screen.call("automation_score")


func automation_choose_reward(index: int) -> Dictionary:
	if game_flow_controller == null or game_flow_controller.get_run_state() == null:
		return _automation_error("当前没有局内状态。")
	var choices := game_flow_controller.get_run_state().last_reward_choices
	if index < 0 or index >= choices.size():
		return _automation_error("奖励序号无效。")
	game_flow_controller.choose_reward(choices[index])
	return _automation_ok("已选择奖励。")


func automation_install_piece(die_index: int, face_index: int) -> Dictionary:
	var battle_screen := _current_battle_screen()
	if battle_screen != null and battle_screen.has_method("automation_install_pending_piece"):
		return battle_screen.call("automation_install_pending_piece", die_index, face_index)
	if game_flow_controller == null or not game_flow_controller.install_pending_piece(die_index, face_index):
		return _automation_error("安装失败。")
	return _automation_ok("已安装铸骰件。")


func _automation_run_snapshot(state: RunState) -> Dictionary:
	if state == null:
		return {}
	var rewards: Array[Dictionary] = []
	for index in range(state.last_reward_choices.size()):
		var choice = state.last_reward_choices[index]
		if choice == null:
			continue
		rewards.append({
			"index": index,
			"id": str(choice.id),
			"name": choice.get_display_name(),
			"description": choice.get_description(),
			"tags": choice.get_tags_display_text(),
		})
	return {
		"battle": state.battle_index + 1,
		"circle": state.get_circle_number(),
		"max_circles": state.max_circles,
		"max_battles": state.max_battles,
		"circle_action_count": state.current_circle_action_count,
		"danger_bonus_percent": state.get_danger_bonus_percent(),
		"target_score": state.get_target_score(),
		"is_boss": state.is_boss_battle(),
		"is_final": state.is_final_battle(),
		"won": state.run_won,
		"lost": state.run_lost,
		"coins": state.coins,
		"total_hands_scored": state.total_hands_scored,
		"total_score_scored": state.total_score_scored,
		"best_hand_score": state.best_hand_score,
		"installed_piece_count": state.installed_piece_count,
		"reward_choices": rewards,
		"pending_piece": _automation_piece_snapshot(state.pending_forge_piece),
	}


func _automation_piece_snapshot(piece) -> Dictionary:
	if piece == null:
		return {}
	return {
		"id": str(piece.id),
		"name": piece.get_display_name(),
		"description": piece.get_description(),
		"tags": piece.get_tags_display_text(),
	}


func _automation_gm_main_menu_snapshot() -> Dictionary:
	var button := _find_node_by_name(self, "GmFloatingButton") as Button
	var menu := _find_node_by_name(self, "GmFunctionMenu") as Control
	var material_button := _find_node_by_name(self, "GmDiceMaterialInspectorButton") as Button
	return {
		"button_exists": button != null,
		"menu_exists": menu != null,
		"menu_visible": menu.visible if menu != null else false,
		"material_action_exists": material_button != null,
		"material_action_text": material_button.text if material_button != null else "",
	}


func _find_gm_material_inspector_screen(root_node: Node) -> Control:
	if root_node is Control and root_node.has_method("automation_open_material") and root_node.has_method("automation_get_snapshot"):
		return root_node as Control
	for child in root_node.get_children():
		var nested := _find_gm_material_inspector_screen(child)
		if nested != null:
			return nested
	return null


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var found := _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _automation_ok(message: String = "") -> Dictionary:
	return {
		"ok": true,
		"message": message,
		"snapshot": automation_get_snapshot(),
	}


func _automation_error(message: String) -> Dictionary:
	return {
		"ok": false,
		"error": message,
		"snapshot": automation_get_snapshot(),
	}
