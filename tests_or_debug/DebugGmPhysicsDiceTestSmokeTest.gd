extends SceneTree
class_name DebugGmPhysicsDiceTestSmokeTest


func _init() -> void:
	print("--- DebugGmPhysicsDiceTestSmokeTest: start ---")
	var all_passed := true

	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)

	var main_scene := load("res://scenes/main/Main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)

	await process_frame
	await process_frame
	await process_frame

	var gm_button := _find_button_by_text(main, "GM物理投骰")
	all_passed = _check("main menu has gm physics dice entry", gm_button != null) and all_passed
	if gm_button != null:
		gm_button.pressed.emit()
		await process_frame
		await process_frame

	var screen := _find_node_by_name(main, "GmPhysicsDiceTestRoot")
	all_passed = _check("gm physics dice screen opens from main menu", screen != null) and all_passed
	all_passed = _check("gm screen does not start formal game flow", main.current_view_id == &"gm_physics_dice_test") and all_passed

	if screen != null:
		all_passed = _check("dice count slider exists", _find_node_by_name(screen, "DiceCountSlider") != null) and all_passed
		var minus_button := _find_node_by_name(screen, "DiceCountMinusButton") as Button
		var plus_button := _find_node_by_name(screen, "DiceCountPlusButton") as Button
		all_passed = _check("dice count minus button exists", minus_button != null) and all_passed
		all_passed = _check("dice count plus button exists", plus_button != null) and all_passed
		var drop_button := _find_node_by_name(screen, "DropButton") as Button
		all_passed = _check("drop button exists", drop_button != null) and all_passed
		all_passed = _check("target grid exists", _find_node_by_name(screen, "TargetGrid") != null) and all_passed
		all_passed = _check("back button exists", _find_node_by_name(screen, "BackButton") != null) and all_passed
		var score_board := _find_node_by_name(screen, "ScoreBoardPanel") as Control
		all_passed = _check("legacy score board placeholder exists", score_board != null) and all_passed
		all_passed = _check("left score board is hidden for reference layout", score_board != null and not score_board.visible) and all_passed
		all_passed = _check("new throw dock exists", _find_node_by_name(screen, "ThrowDock") != null) and all_passed
		var stage_frame := _find_node_by_name(screen, "StageFrame") as Control
		all_passed = _check("stage compatibility node exists", stage_frame != null) and all_passed
		all_passed = _check("decorative stage frame is hidden", stage_frame != null and not stage_frame.visible) and all_passed
		all_passed = _check("top atmosphere overlay is removed", _find_node_by_name(screen, "TopAtmosphereBand") == null) and all_passed
		all_passed = _check("paper overlay is removed", _find_node_by_name(screen, "AngledPaperLayer") == null) and all_passed
		all_passed = _check("viewport shadow overlay is removed", _find_node_by_name(screen, "ViewportShadow") == null) and all_passed
		all_passed = _check("current score flag is removed", _find_node_by_name(screen, "CurrentScoreFlag") == null) and all_passed
		all_passed = _check("target score flag is removed", _find_node_by_name(screen, "TargetScoreFlag") == null) and all_passed
		all_passed = _check("right dice box is removed", _find_node_by_name(screen, "RightDiceBox") == null) and all_passed
		all_passed = _check("coin badge is removed", _find_label_by_text(screen, "金币") == null) and all_passed
		all_passed = _check("codex badge is removed", _find_label_by_text(screen, "图鉴") == null) and all_passed
		all_passed = _check("throw tuning panel exists", _find_node_by_name(screen, "ThrowTuningPanel") != null) and all_passed
		all_passed = _check("throw tuning button exists", _find_node_by_name(screen, "TuningButton") != null) and all_passed
		all_passed = _check("forward speed slider exists", _find_node_by_name(screen, "ForwardSpeedSlider") != null) and all_passed
		all_passed = _check("lateral speed slider exists", _find_node_by_name(screen, "LateralSpeedSlider") != null) and all_passed
		all_passed = _check("upward speed slider exists", _find_node_by_name(screen, "UpwardSpeedSlider") != null) and all_passed
		all_passed = _check("angular speed slider exists", _find_node_by_name(screen, "AngularSpeedSlider") != null) and all_passed
		all_passed = _check("torque impulse slider exists", _find_node_by_name(screen, "TorqueImpulseSlider") != null) and all_passed
		all_passed = _check("camera fov slider exists", _find_node_by_name(screen, "CameraFovSlider") != null) and all_passed
		all_passed = _check("camera height slider exists", _find_node_by_name(screen, "CameraPositionYSlider") != null) and all_passed
		all_passed = _check("camera depth slider exists", _find_node_by_name(screen, "CameraPositionZSlider") != null) and all_passed
		all_passed = _check("camera look height slider exists", _find_node_by_name(screen, "CameraLookAtYSlider") != null) and all_passed
		all_passed = _check("camera look depth slider exists", _find_node_by_name(screen, "CameraLookAtZSlider") != null) and all_passed
		all_passed = _check("dice initial height slider exists", _find_node_by_name(screen, "CameraDiceInitialHeightSlider") != null) and all_passed
		all_passed = _check("key light pitch slider exists", _find_node_by_name(screen, "CameraKeyLightPitchSlider") != null) and all_passed
		all_passed = _check("key light yaw slider exists", _find_node_by_name(screen, "CameraKeyLightYawSlider") != null) and all_passed
		all_passed = _check("gm scene bridge exists", _find_node_by_name(screen, "GmSceneBridge") != null) and all_passed
		all_passed = _check("fixed dice viewport exists", _find_node_by_name(screen, "DiceViewport") != null) and all_passed
		all_passed = _check("fixed camera exists", _find_node_by_name(screen, "FixedCamera") != null) and all_passed
		all_passed = _check("throw plane exists", _find_node_by_name(screen, "ThrowPlane") != null) and all_passed
		all_passed = _check("hidden safety net exists", _find_node_by_name(screen, "SafetyNet") != null) and all_passed
		all_passed = _check("bounds exist", _find_node_by_name(screen, "Bounds") != null) and all_passed
		all_passed = _check("gm game manager exists", _find_node_by_name(screen, "GameMgr") != null) and all_passed
		all_passed = _check("gm ready manager exists", _find_node_by_name(screen, "ReadyMgr") != null) and all_passed
		all_passed = _check("gm battle manager exists", _find_node_by_name(screen, "BattleMgr") != null) and all_passed
		all_passed = _check("gm dice container exists", _find_node_by_name(screen, "DiceContainer") != null) and all_passed

		if plus_button != null and minus_button != null:
			plus_button.pressed.emit()
			await process_frame
			var count_snapshot: Dictionary = screen.call("automation_get_snapshot")
			all_passed = _check("visible plus button increases dice count", int(count_snapshot.get("dice_count", 0)) == 5) and all_passed
			minus_button.pressed.emit()
			minus_button.pressed.emit()
			await process_frame
			count_snapshot = screen.call("automation_get_snapshot")
			all_passed = _check("visible minus button decreases dice count", int(count_snapshot.get("dice_count", 0)) == 3) and all_passed

		screen.call("automation_clear")
		screen.call("automation_set_dice_count", 3)
		screen.call("automation_set_targets", [1, 2, null])
		var snapshot: Dictionary = screen.call("automation_get_snapshot")
		all_passed = _check("automation sets requested dice count", int(snapshot.get("dice_count", 0)) == 3) and all_passed
		all_passed = _check("automation stores target pips", snapshot.get("targets", []) == [1, 2, null]) and all_passed
		all_passed = _check("initial dice are staged near center", _max_abs_position(snapshot, "x") <= 2.0 and _max_abs_position(snapshot, "z") <= 0.8) and all_passed
		all_passed = _check("initial dice are staged in one straight row", _position_span(snapshot, "z") <= 0.03 and _position_span(snapshot, "y") <= 0.03) and all_passed
		all_passed = _check("initial dice use requested default height", _min_dice_y(snapshot) >= 7.49) and all_passed
		all_passed = _check("initial dice keep zero outer yaw", _all_ready_yaw_zero(snapshot)) and all_passed
		all_passed = _check("initial dice have ground shadows", _all_hover_shadows_visible(snapshot) and _all_shadows_under_dice(snapshot)) and all_passed
		all_passed = _check("gm port interface source is isolated", str(snapshot.get("target_plan_source", "")) == "GM复刻接口") and all_passed
		all_passed = _check("gm scene interface is ready", bool(snapshot.get("interface_ready", false))) and all_passed
		all_passed = _check("gm scene bridge uses reusable source label", str(snapshot.get("interface_source", "")) == "GM场景接口") and all_passed
		var bridge_contract: Dictionary = snapshot.get("bridge_contract", {})
		all_passed = _check("gm scene bridge exposes contract", int(bridge_contract.get("version", 0)) >= 1) and all_passed
		all_passed = _check("gm viewport is fixed 2.5d", str(snapshot.get("display_mode", "")) == "fixed_2_5d_subviewport") and all_passed
		all_passed = _check("gm camera cannot be player controlled", not bool(snapshot.get("camera_control_enabled", true))) and all_passed
		all_passed = _check("gm camera uses reference perspective projection", str(snapshot.get("camera_projection", "")) == "perspective") and all_passed
		all_passed = _check("gm camera keeps tabletop fov", is_equal_approx(float(snapshot.get("camera_fov", 0.0)), 38.0)) and all_passed
		all_passed = _check("gm camera uses high tabletop pitch", float(snapshot.get("camera_pitch", 0.0)) > -89.5 and float(snapshot.get("camera_pitch", 0.0)) < -75.0) and all_passed
		var camera_position: Vector3 = snapshot.get("camera_position", Vector3.ZERO)
		all_passed = _check("gm camera uses requested default height", camera_position.y >= 18.0 and camera_position.z >= 0.5 and camera_position.z <= 1.5) and all_passed
		all_passed = _check("gm key light uses requested default angles", is_equal_approx(float(snapshot.get("key_light_pitch", 0.0)), -63.0) and is_equal_approx(float(snapshot.get("key_light_yaw", 0.0)), 115.0)) and all_passed
		var visible_stage: Vector2 = snapshot.get("visible_stage_size", Vector2.ZERO)
		var collision_stage: Vector2 = snapshot.get("collision_stage_size", Vector2.ZERO)
		all_passed = _check("visible throw mat fills tabletop viewport", visible_stage.x >= 15.0 and visible_stage.x <= 18.5 and visible_stage.y >= 10.0 and visible_stage.y <= 12.0) and all_passed
		all_passed = _check("hidden bounds sit inside the full mat", collision_stage.x < visible_stage.x and collision_stage.y < visible_stage.y) and all_passed

		screen.call("automation_set_throw_tuning", {
			"forward_speed": 12.0,
			"lateral_speed": 5.5,
			"upward_speed": 4.0,
			"angular_speed": 32.0,
			"torque_impulse": 28.0,
		})
		snapshot = screen.call("automation_get_snapshot")
		var tuning: Dictionary = snapshot.get("throw_tuning", {})
		all_passed = _check("throw tuning stores forward speed", is_equal_approx(float(tuning.get("forward_speed", 0.0)), 12.0)) and all_passed
		all_passed = _check("throw tuning stores lateral speed", is_equal_approx(float(tuning.get("lateral_speed", 0.0)), 5.5)) and all_passed
		all_passed = _check("throw tuning stores upward speed", is_equal_approx(float(tuning.get("upward_speed", 0.0)), 4.0)) and all_passed
		all_passed = _check("throw tuning stores angular speed", is_equal_approx(float(tuning.get("angular_speed", 0.0)), 32.0)) and all_passed
		all_passed = _check("throw tuning stores torque impulse", is_equal_approx(float(tuning.get("torque_impulse", 0.0)), 28.0)) and all_passed
		screen.call("automation_set_camera_tuning", {
			"fov": 35.5,
			"position_y": 10.4,
			"position_z": 4.3,
			"look_at_y": 0.8,
			"look_at_z": -0.2,
			"dice_initial_height": 2.10,
			"key_light_pitch": -40.0,
			"key_light_yaw": 32.0,
		})
		snapshot = screen.call("automation_get_snapshot")
		var tuned_camera_position: Vector3 = snapshot.get("camera_position", Vector3.ZERO)
		var tuned_camera_look_at: Vector3 = snapshot.get("camera_look_at", Vector3.ZERO)
		all_passed = _check("camera tuning stores fov", is_equal_approx(float(snapshot.get("camera_fov", 0.0)), 35.5)) and all_passed
		all_passed = _check("camera tuning stores position", is_equal_approx(tuned_camera_position.y, 10.4) and is_equal_approx(tuned_camera_position.z, 4.3)) and all_passed
		all_passed = _check("camera tuning stores look at", is_equal_approx(tuned_camera_look_at.y, 0.8) and is_equal_approx(tuned_camera_look_at.z, -0.2)) and all_passed
		all_passed = _check("dice initial height tuning stores and moves row", is_equal_approx(float(snapshot.get("dice_initial_height", 0.0)), 2.10) and _min_dice_y(snapshot) >= 2.09) and all_passed
		all_passed = _check("key light tuning stores angles", is_equal_approx(float(snapshot.get("key_light_pitch", 0.0)), -40.0) and is_equal_approx(float(snapshot.get("key_light_yaw", 0.0)), 32.0)) and all_passed
		screen.call("automation_set_camera_tuning", {
			"position_y": 28.0,
			"dice_initial_height": 8.0,
		})
		snapshot = screen.call("automation_get_snapshot")
		tuned_camera_position = snapshot.get("camera_position", Vector3.ZERO)
		all_passed = _check("expanded camera height range reaches 28", is_equal_approx(tuned_camera_position.y, 28.0)) and all_passed
		all_passed = _check("expanded dice height range reaches 8", is_equal_approx(float(snapshot.get("dice_initial_height", 0.0)), 8.0) and _min_dice_y(snapshot) >= 7.99) and all_passed
		screen.call("automation_set_camera_tuning", {
			"fov": 35.5,
			"position_y": 10.4,
			"position_z": 4.3,
			"look_at_y": 0.8,
			"look_at_z": -0.2,
			"dice_initial_height": 2.10,
			"key_light_pitch": -40.0,
			"key_light_yaw": 32.0,
		})
		snapshot = screen.call("automation_get_snapshot")

		screen.call("automation_drop_random", 2)
		var strong_throw_seen := false
		var never_fell_below_stage := true
		var never_crossed_hidden_bounds := true
		for _i in range(90):
			await physics_frame
			snapshot = screen.call("automation_get_snapshot")
			if _max_dice_speed(snapshot, "linear_speed") >= 7.0 and _max_dice_speed(snapshot, "angular_speed") >= 14.0:
				strong_throw_seen = true
			if _min_dice_y(snapshot) < -0.85:
				never_fell_below_stage = false
				break
			if _max_abs_position(snapshot, "x") > collision_stage.x * 0.5 + 0.45 or _max_abs_position(snapshot, "z") > collision_stage.y * 0.5 + 0.45:
				never_crossed_hidden_bounds = false
				break
		all_passed = _check("random throw creates visible physics dice", int(snapshot.get("active_dice", 0)) == 2 and bool(snapshot.get("rolling", false))) and all_passed
		all_passed = _check("random throw uses strong launch motion", strong_throw_seen) and all_passed
		all_passed = _check("random throw does not fall below full stage", never_fell_below_stage) and all_passed
		all_passed = _check("random throw stays inside hidden bounds", never_crossed_hidden_bounds) and all_passed
		all_passed = _check("normal random throw does not trigger recovery", int(snapshot.get("recover_count", -1)) == 0) and all_passed
		var settled_back_to_hover := false
		for _i in range(420):
			await physics_frame
			snapshot = screen.call("automation_get_snapshot")
			if not bool(snapshot.get("rolling", true)) and _min_dice_y(snapshot) >= 1.55 and _all_hover_shadows_visible(snapshot):
				settled_back_to_hover = true
				break
		all_passed = _check("settled dice return to hover ready row", settled_back_to_hover) and all_passed
		screen.call("automation_clear")
		snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("clear removes visible dice", int(snapshot.get("active_dice", -1)) == 0) and all_passed
		if drop_button != null:
			drop_button.pressed.emit()
			var rerolled_after_clear := false
			for _i in range(30):
				await physics_frame
				snapshot = screen.call("automation_get_snapshot")
				if int(snapshot.get("active_dice", 0)) == 2 and bool(snapshot.get("rolling", false)):
					rerolled_after_clear = true
					break
			all_passed = _check("drop button works after clear", rerolled_after_clear) and all_passed

	main.queue_free()
	print("PASS: DebugGmPhysicsDiceTestSmokeTest" if all_passed else "FAIL: DebugGmPhysicsDiceTestSmokeTest")
	print("--- DebugGmPhysicsDiceTestSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _find_node_by_name(root_node: Node, node_name: String) -> Node:
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var result := _find_node_by_name(child, node_name)
		if result != null:
			return result
	return null


func _find_button_by_text(root_node: Node, text: String) -> Button:
	if root_node is Button and (root_node as Button).text == text:
		return root_node as Button
	for child in root_node.get_children():
		var result := _find_button_by_text(child, text)
		if result != null:
			return result
	return null


func _find_label_by_text(root_node: Node, text: String) -> Label:
	if root_node is Label and (root_node as Label).text == text:
		return root_node as Label
	for child in root_node.get_children():
		var result := _find_label_by_text(child, text)
		if result != null:
			return result
	return null


func _max_dice_speed(snapshot: Dictionary, key: String) -> float:
	var max_speed := 0.0
	var dice_rows: Array = snapshot.get("dice", [])
	for row in dice_rows:
		if row is Dictionary:
			max_speed = maxf(max_speed, float(row.get(key, 0.0)))
	return max_speed


func _min_dice_y(snapshot: Dictionary) -> float:
	var min_y := INF
	var dice_rows: Array = snapshot.get("dice", [])
	for row in dice_rows:
		if row is Dictionary:
			var position: Vector3 = row.get("position", Vector3.ZERO)
			min_y = minf(min_y, position.y)
	return min_y if min_y < INF else 0.0


func _max_abs_position(snapshot: Dictionary, axis: String) -> float:
	var max_value := 0.0
	var positions: Array = snapshot.get("dice_positions", [])
	for position_value in positions:
		var position := position_value as Vector3
		var value := position.x if axis == "x" else position.z
		max_value = maxf(max_value, absf(value))
	return max_value


func _position_span(snapshot: Dictionary, axis: String) -> float:
	var min_value := INF
	var max_value := -INF
	var positions: Array = snapshot.get("dice_positions", [])
	for position_value in positions:
		var position := position_value as Vector3
		var value := position.x
		if axis == "y":
			value = position.y
		elif axis == "z":
			value = position.z
		min_value = minf(min_value, value)
		max_value = maxf(max_value, value)
	return max_value - min_value if min_value < INF and max_value > -INF else 0.0


func _all_hover_shadows_visible(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary) or not bool(row.get("hover_shadow_visible", false)):
			return false
	return true


func _all_shadows_under_dice(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		var dice_position: Vector3 = row.get("position", Vector3.ZERO)
		var shadow_position: Vector3 = row.get("hover_shadow_position", Vector3.ZERO)
		if shadow_position.y >= dice_position.y:
			return false
		if Vector2(dice_position.x, dice_position.z).distance_to(Vector2(shadow_position.x, shadow_position.z)) > 0.05:
			return false
	return true


func _all_ready_yaw_zero(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		var rotation: Vector3 = row.get("rotation_degrees", Vector3.ZERO)
		if absf(rotation.y) > 0.01:
			return false
	return true


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
