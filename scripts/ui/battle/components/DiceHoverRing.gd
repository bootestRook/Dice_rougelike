extends Control
class_name DiceHoverRing


signal completed()


@export_range(0.05, 2.0, 0.01) var fill_seconds := 0.34
@export_range(1.0, 20.0, 0.5) var line_width := 5.0
@export var track_color := Color(0.34, 0.34, 0.34, 0.72)
@export var progress_color := Color(0.78, 0.78, 0.74, 0.92)

var progress := 0.0
var completed_emitted := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func restart() -> void:
	progress = 0.0
	completed_emitted = false
	visible = true
	set_process(true)
	queue_redraw()


func stop() -> void:
	visible = false
	set_process(false)
	progress = 0.0
	completed_emitted = false
	queue_redraw()


func is_complete() -> bool:
	return progress >= 1.0


func _process(delta: float) -> void:
	progress = minf(1.0, progress + delta / maxf(0.01, fill_seconds))
	if progress >= 1.0:
		if not completed_emitted:
			completed_emitted = true
			completed.emit()
		set_process(false)
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var points := 96
	draw_arc(center, radius, 0.0, TAU, points, track_color, line_width, true)
	if progress > 0.0:
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, points, progress_color, line_width, true)
