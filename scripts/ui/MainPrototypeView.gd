extends Control
class_name MainPrototypeView


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const DEFAULT_MENU_ART = preload("res://scenes/main/resources/MainMenuArtConfig.tres")


const BATTLE_SCREEN_PATH := "res://scenes/battle/BattleScreen.tscn"
const FORGE_INSTALL_SCREEN_PATH := "res://scenes/forge/ForgeInstallScreen.tscn"
const REWARD_SCREEN_PATH := "res://scenes/reward/RewardScreen.tscn"
const RUN_RESULT_SCREEN_PATH := "res://scenes/run/RunResultScreen.tscn"


@export var menu_art_config: MainMenuArtConfig = DEFAULT_MENU_ART

var game_flow_controller: GameFlowController = null
var current_view_id: StringName = &""


func _ready() -> void:
	_create_flow_controller()
	_show_main_menu()


func _create_flow_controller() -> void:
	game_flow_controller = GameFlowController.new()
	add_child(game_flow_controller)
	game_flow_controller.battle_requested.connect(_on_battle_requested)
	game_flow_controller.reward_requested.connect(_on_reward_requested)
	game_flow_controller.forge_install_requested.connect(_on_forge_install_requested)
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
		"开始游戏",
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
		"退出",
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


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_battle_requested(requested_run_state: RunState) -> void:
	current_view_id = &"battle"
	_clear_screen()
	var battle_screen = load(BATTLE_SCREEN_PATH).instantiate()
	battle_screen.setup(game_flow_controller, requested_run_state)
	add_child(battle_screen)


func _on_reward_requested(choices: Array) -> void:
	current_view_id = &"reward"
	_clear_screen()
	var reward_screen = load(REWARD_SCREEN_PATH).instantiate()
	reward_screen.setup(game_flow_controller, choices)
	add_child(reward_screen)


func _on_forge_install_requested(piece) -> void:
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


func _on_flow_state_changed(state_id: StringName) -> void:
	if state_id == &"main":
		_show_main_menu()


func _clear_screen() -> void:
	for child in get_children():
		if child != game_flow_controller:
			remove_child(child)
			child.queue_free()
