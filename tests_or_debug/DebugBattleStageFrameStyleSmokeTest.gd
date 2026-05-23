extends SceneTree


const BattleDiceStage3D = preload("res://scripts/ui/battle/components/BattleDiceStage3D.gd")
const STYLE_CONFIG = preload("res://scenes/battle/resources/BattleUiStyleConfig.tres")


func _init() -> void:
	print("--- DebugBattleStageFrameStyleSmokeTest: start ---")

	var all_passed := true
	var stage := BattleDiceStage3D.new()
	root.add_child(stage)

	await process_frame
	await process_frame
	stage.setup(STYLE_CONFIG)
	await process_frame

	var panel_style := stage.get_theme_stylebox("panel")
	all_passed = _check("BattleDiceStage3D root panel has no visible frame", _has_no_visible_frame(panel_style)) and all_passed

	stage.queue_free()
	print("PASS: DebugBattleStageFrameStyleSmokeTest" if all_passed else "FAIL: DebugBattleStageFrameStyleSmokeTest")
	print("--- DebugBattleStageFrameStyleSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _has_no_visible_frame(style: StyleBox) -> bool:
	if style == null:
		return true
	if style is StyleBoxEmpty:
		return true
	if style is StyleBoxFlat:
		var flat := style as StyleBoxFlat
		return flat.bg_color.a <= 0.0 \
			and flat.get_border_width(SIDE_LEFT) == 0 \
			and flat.get_border_width(SIDE_TOP) == 0 \
			and flat.get_border_width(SIDE_RIGHT) == 0 \
			and flat.get_border_width(SIDE_BOTTOM) == 0
	return false


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
