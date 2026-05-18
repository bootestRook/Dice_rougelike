extends Control
class_name MainPrototypeView


const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const GMGravityThrowSandbox = preload("res://scripts/ui/gm/GMGravityThrowSandbox.gd")
const DEFAULT_MENU_ART = preload("res://scenes/main/resources/MainMenuArtConfig.tres")


const BATTLE_SCREEN_PATH := "res://scenes/battle/BattleScreen.tscn"
const FORGE_INSTALL_SCREEN_PATH := "res://scenes/forge/ForgeInstallScreen.tscn"
const REWARD_SCREEN_PATH := "res://scenes/reward/RewardScreen.tscn"
const RUN_RESULT_SCREEN_PATH := "res://scenes/run/RunResultScreen.tscn"


@export var menu_art_config: MainMenuArtConfig = DEFAULT_MENU_ART

var game_flow_controller: GameFlowController = null
var current_view_id: StringName = &""
var start_button_control: Control = null
var gm_test_button_control: Control = null
var exit_button_control: Control = null
var gm_gravity_button_control: Control = null
var gm_back_button_control: Control = null
var gm_sandbox_control: GMGravityThrowSandbox = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_create_flow_controller()
	_show_main_menu()


func _input(event: InputEvent) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or mouse_event.button_index != MOUSE_BUTTON_LEFT or mouse_event.pressed:
		return
	if current_view_id == &"main":
		if _click_hits_control(mouse_event.global_position, start_button_control):
			get_viewport().set_input_as_handled()
			_on_start_battle_pressed()
		elif _click_hits_control(mouse_event.global_position, gm_test_button_control):
			get_viewport().set_input_as_handled()
			_on_gm_test_pressed()
		elif _click_hits_control(mouse_event.global_position, exit_button_control):
			get_viewport().set_input_as_handled()
			_on_exit_pressed()
	elif current_view_id == &"gm_test":
		if _click_hits_control(mouse_event.global_position, gm_gravity_button_control):
			get_viewport().set_input_as_handled()
			_on_gm_gravity_throw_pressed()
		elif _click_hits_control(mouse_event.global_position, gm_back_button_control):
			get_viewport().set_input_as_handled()
			_on_gm_menu_back_pressed()


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
	_reset_view_controls()
	_clear_screen()

	var art := _get_menu_art()
	var root := Control.new()
	root.name = "MainMenuRoot"
	root.mouse_filter = Control.MOUSE_FILTER_PASS
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
	logo_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	version_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
	panel_root.mouse_filter = Control.MOUSE_FILTER_PASS
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
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_root.add_child(margin)

	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.mouse_filter = Control.MOUSE_FILTER_PASS
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 28)
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(buttons)

	start_button_control = _make_art_button(
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
	)
	buttons.add_child(start_button_control)
	gm_test_button_control = _make_art_button(
		"GM测试",
		Vector2(280, 104),
		null,
		null,
		null,
		Color(0.90, 0.48, 0.04, 0.94),
		Color(1.0, 0.60, 0.10, 0.98),
		Color(0.64, 0.30, 0.02, 0.98),
		art,
		_on_gm_test_pressed
	)
	buttons.add_child(gm_test_button_control)
	exit_button_control = _make_art_button(
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
	)
	buttons.add_child(exit_button_control)


func _show_gm_test_menu() -> void:
	current_view_id = &"gm_test"
	_reset_view_controls()
	_clear_screen()

	var art := _get_menu_art()
	var root := Control.new()
	root.name = "GMTestRoot"
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_add_background(root, art)
	_add_center_panel(root, "GM测试", _gm_test_entries(), _on_gm_menu_back_pressed)


func _show_gm_gravity_throw_sandbox() -> void:
	current_view_id = &"gm_gravity_throw"
	_reset_view_controls()
	_clear_screen()

	var art := _get_menu_art()
	var root := Control.new()
	root.name = "GMGravityThrowRoot"
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_add_background(root, art)

	gm_sandbox_control = GMGravityThrowSandbox.new()
	gm_sandbox_control.name = "GMGravityThrowSandbox"
	gm_sandbox_control.back_requested.connect(_on_gm_sandbox_back_requested)
	gm_sandbox_control.anchor_left = 0.08
	gm_sandbox_control.anchor_top = 0.08
	gm_sandbox_control.anchor_right = 0.92
	gm_sandbox_control.anchor_bottom = 0.92
	root.add_child(gm_sandbox_control)


func _gm_test_entries() -> Array[Dictionary]:
	return [
		{
			"text": "骰子重力投掷",
			"callback": _on_gm_gravity_throw_pressed,
		},
	]


func _add_center_panel(
	root: Control,
	title_text: String,
	entries: Array[Dictionary],
	back_callback: Callable
) -> void:
	var panel := PanelContainer.new()
	panel.name = "GMTestPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.anchor_left = 0.30
	panel.anchor_top = 0.19
	panel.anchor_right = 0.70
	panel.anchor_bottom = 0.82
	panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0.025, 0.035, 0.052, 0.88), Color(0.72, 0.82, 0.94, 0.82), 3, 8)
	)
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 44)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 44)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.name = "GMTestContent"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 24)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(content)

	var title := Label.new()
	title.name = "GMTestTitle"
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.03, 0.96))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(title)

	for entry in entries:
		var button := _make_gm_plain_button(str(entry.get("text", "")), Color(0.07, 0.34, 0.76, 0.96), Color(0.10, 0.48, 0.92, 0.98))
		var callback: Callable = entry.get("callback", Callable())
		if callback.is_valid():
			button.pressed.connect(callback)
		content.add_child(button)
		if button.text == "骰子重力投掷":
			gm_gravity_button_control = button

	gm_back_button_control = _make_gm_plain_button("返回主页", Color(0.72, 0.16, 0.08, 0.96), Color(0.94, 0.24, 0.12, 0.98))
	gm_back_button_control.pressed.connect(back_callback)
	content.add_child(gm_back_button_control)


func _make_gm_plain_button(text: String, normal_color: Color, hover_color: Color) -> Button:
	var button := Button.new()
	button.name = text
	button.text = text
	button.custom_minimum_size = Vector2(360, 86)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_color_override("font_color", Color(0.98, 0.98, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.86, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.94, 0.72, 1.0))
	button.add_theme_color_override("font_shadow_color", Color(0.02, 0.02, 0.03, 0.92))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 3)
	button.add_theme_stylebox_override("normal", _make_panel_style(normal_color, Color(0.98, 0.90, 0.55, 0.88), 2, 7))
	button.add_theme_stylebox_override("hover", _make_panel_style(hover_color, Color(1.0, 0.96, 0.68, 0.95), 2, 7))
	button.add_theme_stylebox_override("pressed", _make_panel_style(normal_color.darkened(0.18), Color(1.0, 0.88, 0.44, 0.95), 2, 7))
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
	var button := Button.new()
	button.name = text
	button.text = text
	button.custom_minimum_size = minimum_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
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

	var fallback_panel := PanelContainer.new()
	fallback_panel.name = "FallbackPanel"
	fallback_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback_panel.show_behind_parent = true
	fallback_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(fallback_panel)

	var texture_rect := TextureRect.new()
	texture_rect.name = "ButtonArt"
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.show_behind_parent = true
	texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(texture_rect)

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

	_apply_button_visual(texture_rect, fallback_panel, normal_texture, normal_texture, normal_color)
	return button


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


func _on_gm_test_pressed() -> void:
	_show_gm_test_menu()


func _on_gm_gravity_throw_pressed() -> void:
	_show_gm_gravity_throw_sandbox()


func _on_gm_menu_back_pressed() -> void:
	_show_main_menu()


func _on_gm_sandbox_back_requested() -> void:
	if gm_sandbox_control != null and is_instance_valid(gm_sandbox_control):
		gm_sandbox_control.clear_sandbox()
	_show_gm_test_menu()


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_battle_requested(requested_run_state: RunState) -> void:
	current_view_id = &"battle"
	var existing_battle_screen := _current_battle_screen()
	if existing_battle_screen != null:
		if existing_battle_screen.has_method("start_battle_with_run_state"):
			existing_battle_screen.call("start_battle_with_run_state", game_flow_controller, requested_run_state)
			return

	_clear_screen()
	var battle_screen = load(BATTLE_SCREEN_PATH).instantiate()
	battle_screen.setup(game_flow_controller, requested_run_state)
	add_child(battle_screen)


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


func _on_flow_state_changed(state_id: StringName) -> void:
	if state_id == &"main":
		_show_main_menu()


func _clear_screen() -> void:
	for child in get_children():
		if child != game_flow_controller:
			remove_child(child)
			child.queue_free()
	gm_sandbox_control = null


func _reset_view_controls() -> void:
	start_button_control = null
	gm_test_button_control = null
	exit_button_control = null
	gm_gravity_button_control = null
	gm_back_button_control = null
	gm_sandbox_control = null


func _click_hits_control(position: Vector2, control: Control) -> bool:
	if control == null or not control.visible or not control.is_inside_tree():
		return false
	var button := control as BaseButton
	if button != null and button.disabled:
		return false
	return control.get_global_rect().has_point(position)


func _current_battle_screen() -> Control:
	for child in get_children():
		if child is Control and child.has_method("start_battle_with_run_state") and child.has_method("show_reward_choices"):
			return child as Control
	return null
