extends Control
class_name RerollMagicFx


signal cover_reached()
signal finished()


const VEIL_FRAMES: Array[Texture2D] = [
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/veil/frame_01.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/veil/frame_02.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/veil/frame_03.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/veil/frame_04.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/veil/frame_05.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/veil/frame_06.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/veil/frame_07.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/veil/frame_08.png"),
]
const SMOKE_FRAMES: Array[Texture2D] = [
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/smoke/frame_01.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/smoke/frame_02.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/smoke/frame_03.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/smoke/frame_04.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/smoke/frame_05.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/smoke/frame_06.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/smoke/frame_07.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/smoke/frame_08.png"),
]
const RING_FRAMES: Array[Texture2D] = [
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_01.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_02.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_03.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_04.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_05.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_06.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_07.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_08.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_09.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_10.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_11.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_12.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_13.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_14.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_15.png"),
	preload("res://assets/ui/battle/vfx/reroll_dark_magic/ring/frame_16.png"),
]

const BASE_TOTAL_DURATION := 1.45
const BASE_COVER_TIME := 0.52
const BASE_REVEAL_FADE_DURATION := 0.62
const SMOKE_FPS := 12.0
const RING_FPS := 18.0


var _elapsed := 0.0
var _total_duration := BASE_TOTAL_DURATION
var _cover_time := BASE_COVER_TIME
var _reveal_fade_elapsed := -1.0
var _reveal_fade_duration := BASE_REVEAL_FADE_DURATION
var _cover_emitted := false
var _playing := false

@onready var veil_frame: TextureRect = %VeilFrame
@onready var smoke_frame: TextureRect = %SmokeFrame
@onready var ring_frame: TextureRect = %RingFrame


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)


func play_at_rect(target_rect: Rect2, fast: bool = false) -> void:
	_play_at_rect(target_rect, fast, true)


func play_at_local_rect(target_rect: Rect2, fast: bool = false) -> void:
	_play_at_rect(target_rect, fast, false)


func begin_reveal_fade(duration: float = BASE_REVEAL_FADE_DURATION) -> void:
	if not _playing:
		return
	_reveal_fade_duration = maxf(0.05, duration)
	_reveal_fade_elapsed = 0.0


func _play_at_rect(target_rect: Rect2, fast: bool, use_global_position: bool) -> void:
	if not is_node_ready():
		call_deferred("_play_at_rect", target_rect, fast, use_global_position)
		return

	var padding: float = clampf(maxf(target_rect.size.x, target_rect.size.y) * 0.12, 12.0, 24.0)
	var effect_position: Vector2 = target_rect.position - Vector2(padding, padding)
	if use_global_position:
		global_position = effect_position
	else:
		position = effect_position
	size = target_rect.size + Vector2(padding * 2.0, padding * 2.0)
	custom_minimum_size = size
	pivot_offset = size * 0.5
	z_index = 360

	_total_duration = BASE_TOTAL_DURATION * (0.55 if fast else 1.0)
	_cover_time = BASE_COVER_TIME * (0.55 if fast else 1.0)
	_reveal_fade_duration = BASE_REVEAL_FADE_DURATION * (0.55 if fast else 1.0)
	_reveal_fade_elapsed = -1.0
	_elapsed = 0.0
	_cover_emitted = false
	_playing = true
	visible = true
	_sync_child_pivots()
	_apply_animation(0.0)
	set_process(true)


func _process(delta: float) -> void:
	if not _playing:
		return

	_elapsed += delta
	if _reveal_fade_elapsed >= 0.0:
		_reveal_fade_elapsed += delta
	var t: float = clampf(_elapsed / maxf(0.01, _total_duration), 0.0, 1.0)
	_apply_animation(t)

	if not _cover_emitted and _elapsed >= _cover_time:
		_cover_emitted = true
		cover_reached.emit()

	if _elapsed >= _total_duration or (_reveal_fade_elapsed >= _reveal_fade_duration and _reveal_fade_elapsed >= 0.0):
		_finish()


func _apply_animation(t: float) -> void:
	if veil_frame == null or smoke_frame == null or ring_frame == null:
		return

	var veil_index: int = mini(VEIL_FRAMES.size() - 1, int(floor(_elapsed * SMOKE_FPS)) % maxi(1, VEIL_FRAMES.size()))
	var smoke_index: int = mini(SMOKE_FRAMES.size() - 1, int(floor(_elapsed * SMOKE_FPS)) % maxi(1, SMOKE_FRAMES.size()))
	var ring_index: int = int(floor(_elapsed * RING_FPS)) % maxi(1, RING_FRAMES.size())
	veil_frame.texture = VEIL_FRAMES[veil_index]
	smoke_frame.texture = SMOKE_FRAMES[smoke_index]
	ring_frame.texture = RING_FRAMES[ring_index]

	var fade_in: float = smoothstep(0.0, 0.24, t)
	var timeline_fade_out: float = 1.0 - smoothstep(0.70, 1.0, t)
	var reveal_fade_out: float = 1.0
	if _reveal_fade_elapsed >= 0.0:
		var reveal_t: float = clampf(_reveal_fade_elapsed / maxf(0.01, _reveal_fade_duration), 0.0, 1.0)
		reveal_fade_out = 1.0 - smoothstep(0.0, 1.0, reveal_t)
	var fade_out: float = minf(timeline_fade_out, reveal_fade_out)
	var alpha: float = clampf(fade_in * fade_out, 0.0, 1.0)
	modulate = Color(1.0, 1.0, 1.0, alpha)
	scale = Vector2.ONE * lerpf(0.98, 1.03, smoothstep(0.0, 1.0, t))
	rotation = lerpf(-0.025, 0.035, t)

	veil_frame.scale = Vector2.ONE * lerpf(1.0, 1.06, smoothstep(0.0, 1.0, t))
	veil_frame.rotation = lerpf(-0.02, 0.025, t)
	veil_frame.modulate = Color(1.0, 1.0, 1.0, minf(1.0 - smoothstep(0.72, 1.0, t), reveal_fade_out))

	smoke_frame.scale = Vector2.ONE * lerpf(1.02, 1.14, smoothstep(0.12, 1.0, t))
	smoke_frame.rotation = lerpf(0.05, -0.08, t)
	smoke_frame.modulate = Color(1.0, 1.0, 1.0, 0.62)

	ring_frame.scale = Vector2(1.02, 0.72) * lerpf(0.96, 1.08, smoothstep(0.0, 1.0, t))
	ring_frame.rotation = lerpf(-0.10, 0.13, t)
	ring_frame.modulate = Color(1.0, 1.0, 1.0, 0.76 * minf(1.0 - smoothstep(0.72, 1.0, t), reveal_fade_out))


func _sync_child_pivots() -> void:
	for child in [veil_frame, smoke_frame, ring_frame]:
		if child == null:
			continue
		child.pivot_offset = size * 0.5


func _finish() -> void:
	if not _playing:
		return
	_playing = false
	set_process(false)
	finished.emit()
	queue_free()
