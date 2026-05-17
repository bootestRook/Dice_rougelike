extends Control
class_name RoundIntroBanner


const BANNER_SIZE := Vector2(680.0, 154.0)
const CENTER_Y_RATIO := 0.5
const START_PADDING := 96.0
const EXIT_PADDING := 120.0
const ENTER_DURATION := 0.36
const HOLD_DURATION := 1.5
const EXIT_DURATION := 0.42


var _elapsed := 0.0
var _playing := false

@onready var banner_root: Control = %BannerRoot
@onready var band_panel: PanelContainer = %BandPanel
@onready var accent_bar: ColorRect = %AccentBar
@onready var trail_fx: TextureRect = %TrailFx
@onready var flare_fx: TextureRect = %FlareFx
@onready var glow_fx: TextureRect = %GlowFx
@onready var magic_fx: TextureRect = %MagicFx
@onready var star_left: TextureRect = %StarLeft
@onready var star_right: TextureRect = %StarRight
@onready var spark_a: TextureRect = %SparkA
@onready var spark_b: TextureRect = %SparkB
@onready var small_label: Label = %SmallLabel
@onready var round_label: Label = %RoundLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_apply_style()
	set_process(false)


func play(round_number: int, fast: bool = false) -> void:
	await play_at_rect(round_number, Rect2(Vector2.ZERO, _resolve_viewport_size()), fast)


func play_at_rect(round_number: int, target_rect: Rect2, fast: bool = false) -> void:
	if not is_node_ready():
		await ready

	round_label.text = "回合 %d" % maxi(1, round_number)
	var viewport_size := _resolve_viewport_size()
	_layout_static_nodes(viewport_size)

	var center_position := _target_banner_position(target_rect, viewport_size)
	var start_position := Vector2(-BANNER_SIZE.x - START_PADDING, center_position.y)
	var exit_position := Vector2(viewport_size.x + EXIT_PADDING, center_position.y)

	_elapsed = 0.0
	_playing = true
	visible = true
	_set_alpha(1.0)
	banner_root.position = start_position
	banner_root.scale = Vector2(0.96, 1.02)
	set_process(true)
	_apply_fx_motion(0.0)

	var enter_duration: float = ENTER_DURATION * (0.62 if fast else 1.0)
	var hold_duration: float = 0.45 if fast else HOLD_DURATION
	var exit_duration: float = EXIT_DURATION * (0.62 if fast else 1.0)

	var tween := create_tween()
	tween.tween_property(banner_root, "position", center_position, enter_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(banner_root, "scale", Vector2.ONE, enter_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold_duration)
	tween.tween_property(banner_root, "position", exit_position, exit_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_method(Callable(self, "_set_alpha"), 1.0, 0.0, exit_duration * 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished

	_playing = false
	set_process(false)
	queue_free()


func _process(delta: float) -> void:
	if not _playing:
		return
	_elapsed += delta
	_apply_fx_motion(_elapsed)


func _resolve_viewport_size() -> Vector2:
	var viewport_size := size
	if viewport_size == Vector2.ZERO and get_parent() is Control:
		viewport_size = (get_parent() as Control).size
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		viewport_size = Vector2(1920.0, 1080.0)
	return viewport_size


func _target_banner_position(target_rect: Rect2, viewport_size: Vector2) -> Vector2:
	var target_center := target_rect.get_center()
	if target_rect.size == Vector2.ZERO:
		target_center = Vector2(viewport_size.x * 0.5, viewport_size.y * CENTER_Y_RATIO)
	var unclamped_position := target_center - BANNER_SIZE * 0.5
	var max_position := Vector2(
		maxf(0.0, viewport_size.x - BANNER_SIZE.x),
		maxf(0.0, viewport_size.y - BANNER_SIZE.y)
	)
	return Vector2(
		clampf(unclamped_position.x, 0.0, max_position.x),
		clampf(unclamped_position.y, 0.0, max_position.y)
	)


func _layout_static_nodes(viewport_size: Vector2) -> void:
	size = viewport_size
	custom_minimum_size = viewport_size
	banner_root.size = BANNER_SIZE
	banner_root.custom_minimum_size = BANNER_SIZE
	banner_root.pivot_offset = BANNER_SIZE * 0.5

	band_panel.position = Vector2(54.0, 28.0)
	band_panel.size = Vector2(572.0, 94.0)
	accent_bar.position = Vector2(82.0, 121.0)
	accent_bar.size = Vector2(516.0, 5.0)

	_set_rect(trail_fx, Vector2(-48.0, 17.0), Vector2(214.0, 120.0))
	_set_rect(magic_fx, Vector2(-70.0, -39.0), Vector2(252.0, 232.0))
	_set_rect(flare_fx, Vector2(515.0, -6.0), Vector2(186.0, 174.0))
	_set_rect(glow_fx, Vector2(478.0, -44.0), Vector2(250.0, 250.0))
	_set_rect(star_left, Vector2(31.0, 15.0), Vector2(76.0, 76.0))
	_set_rect(star_right, Vector2(563.0, 74.0), Vector2(58.0, 58.0))
	_set_rect(spark_a, Vector2(117.0, -8.0), Vector2(66.0, 66.0))
	_set_rect(spark_b, Vector2(498.0, 7.0), Vector2(72.0, 72.0))

	small_label.position = Vector2(176.0, 34.0)
	small_label.size = Vector2(328.0, 28.0)
	round_label.position = Vector2(176.0, 55.0)
	round_label.size = Vector2(328.0, 61.0)


func _set_rect(node: Control, target_position: Vector2, target_size: Vector2) -> void:
	node.position = target_position
	node.size = target_size
	node.custom_minimum_size = target_size
	node.pivot_offset = target_size * 0.5


func _apply_style() -> void:
	var band_style := StyleBoxFlat.new()
	band_style.bg_color = Color(0.025, 0.205, 0.82, 0.90)
	band_style.border_color = Color(0.48, 0.84, 1.0, 0.82)
	band_style.set_border_width_all(3)
	band_style.set_corner_radius_all(8)
	band_style.shadow_color = Color(0.0, 0.03, 0.24, 0.42)
	band_style.shadow_size = 22
	band_panel.add_theme_stylebox_override("panel", band_style)

	accent_bar.color = Color(0.55, 0.95, 1.0, 0.70)
	small_label.text = "当前回合"
	small_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	small_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	small_label.add_theme_font_size_override("font_size", 24)
	small_label.add_theme_color_override("font_color", Color(0.84, 0.96, 1.0, 0.95))
	small_label.add_theme_color_override("font_outline_color", Color(0.02, 0.08, 0.28, 0.88))
	small_label.add_theme_constant_override("outline_size", 3)

	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	round_label.add_theme_font_size_override("font_size", 54)
	round_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.86, 1.0))
	round_label.add_theme_color_override("font_outline_color", Color(0.02, 0.08, 0.28, 0.94))
	round_label.add_theme_constant_override("outline_size", 6)


func _apply_fx_motion(time: float) -> void:
	var pulse := (sin(time * 5.0) + 1.0) * 0.5
	var quick_pulse := (sin(time * 9.0) + 1.0) * 0.5

	trail_fx.rotation = -0.04 + sin(time * 3.0) * 0.018
	trail_fx.modulate = Color(0.38, 0.82, 1.0, 0.34 + pulse * 0.14)

	magic_fx.rotation = -0.08 + sin(time * 2.6) * 0.035
	magic_fx.scale = Vector2.ONE * (1.0 + pulse * 0.06)
	magic_fx.modulate = Color(0.45, 0.82, 1.0, 0.42 + quick_pulse * 0.16)

	flare_fx.rotation = 0.05 + sin(time * 3.4) * 0.026
	flare_fx.scale = Vector2.ONE * (0.96 + quick_pulse * 0.07)
	flare_fx.modulate = Color(0.58, 0.91, 1.0, 0.45 + pulse * 0.16)

	glow_fx.rotation = time * 0.18
	glow_fx.scale = Vector2.ONE * (1.0 + pulse * 0.08)
	glow_fx.modulate = Color(0.40, 0.76, 1.0, 0.30 + pulse * 0.16)

	star_left.rotation = time * 1.85
	star_left.scale = Vector2.ONE * (0.95 + quick_pulse * 0.12)
	star_left.modulate = Color(0.82, 0.95, 1.0, 0.78 + pulse * 0.18)

	star_right.rotation = -time * 2.2
	star_right.scale = Vector2.ONE * (0.88 + pulse * 0.16)
	star_right.modulate = Color(1.0, 0.94, 0.58, 0.74 + quick_pulse * 0.18)

	spark_a.rotation = -time * 2.8
	spark_a.scale = Vector2.ONE * (0.82 + quick_pulse * 0.20)
	spark_a.modulate = Color(0.76, 0.94, 1.0, 0.58 + quick_pulse * 0.28)

	spark_b.rotation = time * 2.4
	spark_b.scale = Vector2.ONE * (0.86 + pulse * 0.18)
	spark_b.modulate = Color(1.0, 0.98, 0.74, 0.58 + pulse * 0.24)


func _set_alpha(alpha: float) -> void:
	modulate = Color(modulate.r, modulate.g, modulate.b, alpha)
