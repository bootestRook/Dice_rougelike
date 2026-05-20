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
		var fly_button := _find_node_by_name(screen, "FlyAwayButton") as Button
		var hud_node = screen.get("hud")
		var return_button = hud_node.return_button as Button if hud_node != null else null
		all_passed = _check("fly away button exists", fly_button != null and fly_button.text == "飞走") and all_passed
		all_passed = _check("return placeholder button exists", return_button != null and return_button.text == "回归") and all_passed
		all_passed = _check("return placeholder button is disabled", return_button != null and return_button.disabled) and all_passed
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
		var throw_dock := _find_node_by_name(screen, "ThrowDock") as Control
		all_passed = _check("throw dock is moved to upper play area", throw_dock != null and throw_dock.anchor_left <= 0.14 and throw_dock.anchor_top <= 0.13 and throw_dock.anchor_bottom <= 0.28) and all_passed
		all_passed = _check("tuning panel exists", _find_node_by_name(screen, "TuningPanel") != null) and all_passed
		all_passed = _check("tuning button exists", _find_node_by_name(screen, "TuningButton") != null) and all_passed
		all_passed = _check("tuning scroll exists", _find_node_by_name(screen, "TuningScroll") != null) and all_passed
		all_passed = _check("old throw tuning group is removed", _find_node_by_name(screen, "ThrowTuningGroup") == null) and all_passed
		all_passed = _check("old forward speed slider is removed", _find_node_by_name(screen, "ForwardSpeedSlider") == null) and all_passed
		all_passed = _check("old lateral speed slider is removed", _find_node_by_name(screen, "LateralSpeedSlider") == null) and all_passed
		all_passed = _check("old upward speed slider is removed", _find_node_by_name(screen, "UpwardSpeedSlider") == null) and all_passed
		all_passed = _check("old angular speed slider is removed", _find_node_by_name(screen, "AngularSpeedSlider") == null) and all_passed
		all_passed = _check("old torque impulse slider is removed", _find_node_by_name(screen, "TorqueImpulseSlider") == null) and all_passed
		all_passed = _check("throw speed tuning group exists", _find_node_by_name(screen, "ThrowSpeedTuningGroup") != null) and all_passed
		all_passed = _check("throw speed min slider exists", _find_node_by_name(screen, "ThrowSpeedLinearSpeedMinSlider") != null) and all_passed
		all_passed = _check("throw speed max slider exists", _find_node_by_name(screen, "ThrowSpeedLinearSpeedMaxSlider") != null) and all_passed
		all_passed = _check("throw spin tuning group exists", _find_node_by_name(screen, "ThrowSpinTuningGroup") != null) and all_passed
		all_passed = _check("throw spin angular min slider exists", _find_node_by_name(screen, "ThrowSpinAngularSpeedMinSlider") != null) and all_passed
		all_passed = _check("throw spin angular max slider exists", _find_node_by_name(screen, "ThrowSpinAngularSpeedMaxSlider") != null) and all_passed
		all_passed = _check("throw spin torque min slider exists", _find_node_by_name(screen, "ThrowSpinTorqueMinSlider") != null) and all_passed
		all_passed = _check("throw spin torque max slider exists", _find_node_by_name(screen, "ThrowSpinTorqueMaxSlider") != null) and all_passed
		all_passed = _check("idle drift tuning group exists", _find_node_by_name(screen, "IdleDriftTuningGroup") != null) and all_passed
		all_passed = _check("idle drift min seconds slider exists", _find_node_by_name(screen, "IdleDriftMinSecondsSlider") != null) and all_passed
		all_passed = _check("idle drift max seconds slider exists", _find_node_by_name(screen, "IdleDriftMaxSecondsSlider") != null) and all_passed
		all_passed = _check("idle drift max distance slider exists", _find_node_by_name(screen, "IdleDriftMaxDistanceSlider") != null) and all_passed
		all_passed = _check("idle drift speed slider exists", _find_node_by_name(screen, "IdleDriftSpeedSlider") != null) and all_passed
		all_passed = _check("exit return tuning group exists", _find_node_by_name(screen, "ExitReturnTuningGroup") != null) and all_passed
		all_passed = _check("exit return screen x slider exists", _find_node_by_name(screen, "ExitReturnScreenXSlider") != null) and all_passed
		all_passed = _check("exit return screen y slider exists", _find_node_by_name(screen, "ExitReturnScreenYSlider") != null) and all_passed
		all_passed = _check("exit return spawn y slider exists", _find_node_by_name(screen, "ExitReturnSpawnYSlider") != null) and all_passed
		all_passed = _check("camera tuning group exists", _find_node_by_name(screen, "CameraTuningGroup") != null) and all_passed
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
		all_passed = _check("hidden ceiling bound is removed", _find_node_by_name(screen, "CeilingBound") == null) and all_passed
		all_passed = _check("gm game manager exists", _find_node_by_name(screen, "GameMgr") != null) and all_passed
		all_passed = _check("gm ready manager exists", _find_node_by_name(screen, "ReadyMgr") != null) and all_passed
		all_passed = _check("gm battle manager exists", _find_node_by_name(screen, "BattleMgr") != null) and all_passed
		all_passed = _check("gm reusable dice flow module exists", _find_node_by_name(screen, "DiceFlowModule") != null) and all_passed
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
			var entry_auto_result: Dictionary = await _wait_for_auto_roll_all_cycle(screen, [0, 1, 2], 720)
			var entry_auto_snapshot: Dictionary = entry_auto_result.get("snapshot", {})
			all_passed = _check("gm entry calls auto roll-all module", bool(entry_auto_result.get("started", false)) and bool(entry_auto_result.get("finished", false))) and all_passed
			all_passed = _check("gm entry auto roll launches all dice together", entry_auto_result.get("rolled_indices", []) == [0, 1, 2]) and all_passed
			all_passed = _check("gm entry auto roll records request state", int(entry_auto_snapshot.get("auto_roll_all_request_count", 0)) >= 1 and not bool(entry_auto_snapshot.get("auto_roll_all_pending", true))) and all_passed

		screen.call("automation_clear")
		screen.call("automation_set_dice_count", 3)
		screen.call("automation_request_auto_roll_all", 0.50)
		var locked_auto_snapshot: Dictionary = screen.call("automation_get_snapshot")
		all_passed = _check("auto roll-all state locks dice selection input", bool(locked_auto_snapshot.get("auto_roll_all_input_locked", false))) and all_passed
		screen.call("automation_select_dice", [1])
		locked_auto_snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("auto roll-all state ignores automation selection", locked_auto_snapshot.get("selected_dice_indices", []) == []) and all_passed
		screen.call("automation_click_dice", 1)
		locked_auto_snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("auto roll-all state ignores click selection", locked_auto_snapshot.get("selected_dice_indices", []) == []) and all_passed
		var locked_auto_result: Dictionary = await _wait_for_auto_roll_all_cycle(screen, [0, 1, 2], 720)
		all_passed = _check("locked auto roll-all still completes full cycle", bool(locked_auto_result.get("started", false)) and bool(locked_auto_result.get("finished", false))) and all_passed

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
		var default_drift_tuning: Dictionary = snapshot.get("idle_drift_tuning", {})
		all_passed = _check("initial idle drift max distance uses requested default", is_equal_approx(float(default_drift_tuning.get("max_distance", 0.0)), 0.07)) and all_passed
		all_passed = _check("initial idle drift speed uses requested default", is_equal_approx(float(default_drift_tuning.get("speed", 0.0)), 0.05)) and all_passed
		var default_speed_tuning: Dictionary = snapshot.get("throw_speed_tuning", {})
		all_passed = _check("initial throw linear speed min uses requested default", is_equal_approx(float(default_speed_tuning.get("linear_speed_min", 0.0)), 8.0)) and all_passed
		all_passed = _check("initial throw linear speed max uses requested default", is_equal_approx(float(default_speed_tuning.get("linear_speed_max", 0.0)), 12.0)) and all_passed
		var default_spin_tuning: Dictionary = snapshot.get("throw_spin_tuning", {})
		all_passed = _check("initial throw angular speed min uses requested default", is_equal_approx(float(default_spin_tuning.get("angular_speed_min", 0.0)), 4.0)) and all_passed
		all_passed = _check("initial throw angular speed max uses requested default", is_equal_approx(float(default_spin_tuning.get("angular_speed_max", 0.0)), 9.5)) and all_passed
		all_passed = _check("initial throw torque min uses requested default", is_equal_approx(float(default_spin_tuning.get("torque_min", 0.0)), 2.0)) and all_passed
		all_passed = _check("initial throw torque max uses requested default", is_equal_approx(float(default_spin_tuning.get("torque_max", 0.0)), 5.0)) and all_passed
		var default_exit_return_tuning: Dictionary = snapshot.get("exit_return_tuning", {})
		all_passed = _check("initial exit return screen x uses requested default", is_equal_approx(float(default_exit_return_tuning.get("screen_x", 0.0)), 0.66)) and all_passed
		all_passed = _check("initial exit return screen y uses requested default", is_equal_approx(float(default_exit_return_tuning.get("screen_y", 0.0)), 0.44)) and all_passed
		all_passed = _check("initial exit return spawn y uses requested default", is_equal_approx(float(default_exit_return_tuning.get("spawn_y", 0.0)), 20.0)) and all_passed
		all_passed = _check("initial gm dice are unselected", snapshot.get("selected_dice_indices", []) == []) and all_passed
		all_passed = _check("initial gm dice selection frames are hidden", _selected_frame_indices(snapshot).is_empty()) and all_passed
		for _i in range(18):
			await physics_frame
		snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("unselected gm dice slowly drift", _any_idle_drift_moved(snapshot)) and all_passed
		all_passed = _check("unselected gm dice drift stays within max distance", _all_drift_offsets_within_limit(snapshot)) and all_passed
		await physics_frame
		var dice_viewport_node := _find_node_by_name(screen, "DiceViewport")
		var dice_click_points: Array = dice_viewport_node.call("get_dice_local_points") if dice_viewport_node != null else []
		all_passed = _check("gm dice viewport exposes clickable dice points", dice_click_points.size() >= 3) and all_passed
		if dice_viewport_node != null and dice_click_points.size() >= 2:
			var picked_dice = dice_viewport_node.call("pick_dice_at_local_position", dice_click_points[1])
			all_passed = _check("gm dice viewport picks die at projected point", picked_dice != null) and all_passed
			var click_event := InputEventMouseButton.new()
			click_event.button_index = MOUSE_BUTTON_LEFT
			click_event.pressed = true
			click_event.position = dice_click_points[1]
			dice_viewport_node.call("_gui_input", click_event)
			await process_frame
			snapshot = screen.call("automation_get_snapshot")
			all_passed = _check("left click on gm viewport selects a die", snapshot.get("selected_dice_indices", []) == [1]) and all_passed
			all_passed = _check("left clicked gm die shows selection frame", _selected_frame_indices(snapshot) == [1]) and all_passed
			all_passed = _check("selected gm die returns to idle anchor", _die_returned_to_idle_anchor(snapshot, 1)) and all_passed
			all_passed = _check("selected gm die stops idle drift", _die_idle_drift_stopped(snapshot, 1)) and all_passed
			dice_viewport_node.call("_gui_input", click_event)
			await process_frame
			snapshot = screen.call("automation_get_snapshot")
			all_passed = _check("left click on selected gm die deselects it", snapshot.get("selected_dice_indices", []) == []) and all_passed
		screen.call("automation_select_dice", [0, 2])
		snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("gm dice can be selected by index", snapshot.get("selected_dice_indices", []) == [0, 2]) and all_passed
		all_passed = _check("selected gm dice show selection frames", _selected_frame_indices(snapshot) == [0, 2]) and all_passed
		var face_indices_before_selected_roll: Array = snapshot.get("last_face_indices", []).duplicate()
		var positions_before_selected_roll: Array = snapshot.get("dice_positions", []).duplicate()
		screen.call("automation_set_targets", [6, 1, 5])
		screen.call("_drop_with_current_settings", true)
		var immediate_selected_roll_snapshot: Dictionary = screen.call("automation_get_snapshot")
		all_passed = _check("gm selected dice launch together without stagger", _rolling_indices(immediate_selected_roll_snapshot) == [0, 2] and int(immediate_selected_roll_snapshot.get("pending_launches", -1)) == 0) and all_passed
		all_passed = _check("gm selected roll holds unselected dice", immediate_selected_roll_snapshot.get("held_unselected_dice_indices", []) == [1] and _indices_in_unselected_hold(immediate_selected_roll_snapshot, [1])) and all_passed
		all_passed = _check("gm held unselected dice disable collision", _held_dice_collision_disabled(immediate_selected_roll_snapshot, [1])) and all_passed
		all_passed = _check("gm held unselected dice target bottom center", _unselected_hold_targets_match_center(immediate_selected_roll_snapshot, [1])) and all_passed
		all_passed = _check("gm selected dice are not put in unselected hold", _indices_clear_of_unselected_hold(immediate_selected_roll_snapshot, [0, 2])) and all_passed
		var selected_roll_snapshot: Dictionary = {}
		for _i in range(30):
			await physics_frame
			selected_roll_snapshot = screen.call("automation_get_snapshot")
			if _rolling_indices(selected_roll_snapshot) == [0, 2]:
				break
		all_passed = _check("selected gm dice roll starts", bool(selected_roll_snapshot.get("rolling", false))) and all_passed
		all_passed = _check("gm roll starts only selected dice", _rolling_indices(selected_roll_snapshot) == [0, 2]) and all_passed
		all_passed = _check("gm selection clears after roll starts", selected_roll_snapshot.get("selected_dice_indices", []) == []) and all_passed
		all_passed = _check("gm selection frames hide after roll starts", _selected_frame_indices(selected_roll_snapshot).is_empty()) and all_passed
		all_passed = _check("gm selected dice throw from current positions", _rolled_from_current_positions(selected_roll_snapshot, positions_before_selected_roll, [0, 2])) and all_passed
		all_passed = _check("gm selected dice throw toward random negative-y target", _rolling_throw_velocities_are_downward(selected_roll_snapshot, [0, 2])) and all_passed
		var face_indices_during_selected_roll: Array = selected_roll_snapshot.get("last_face_indices", [])
		all_passed = _check("gm roll leaves unselected die face untouched", face_indices_before_selected_roll.size() > 1 and face_indices_during_selected_roll.size() > 1 and int(face_indices_during_selected_roll[1]) == int(face_indices_before_selected_roll[1])) and all_passed
		var selected_throw_descended := false
		for _i in range(90):
			await physics_frame
			selected_roll_snapshot = screen.call("automation_get_snapshot")
			if _min_indexed_dice_y(selected_roll_snapshot, [0, 2]) < 6.10:
				selected_throw_descended = true
				break
		all_passed = _check("gm selected dice pass below old hidden ceiling height", selected_throw_descended) and all_passed
		var simultaneous_ready_return_seen := false
		var selected_roll_finished := false
		for _i in range(720):
			await physics_frame
			selected_roll_snapshot = screen.call("automation_get_snapshot")
			if _indices_returning_to_ready(selected_roll_snapshot, [0, 2]) and _indices_returning_from_unselected_hold(selected_roll_snapshot, [1]):
				simultaneous_ready_return_seen = true
			if not bool(selected_roll_snapshot.get("rolling", true)) and int(selected_roll_snapshot.get("pending_ready_returns", 0)) == 0:
				selected_roll_finished = true
				break
		all_passed = _check("gm held unselected dice return together with rolled dice", simultaneous_ready_return_seen) and all_passed
		all_passed = _check("gm selected roll completes after synchronized return", selected_roll_finished) and all_passed
		all_passed = _check("gm held unselected dice return to original hover slot", _die_returned_to_idle_anchor(selected_roll_snapshot, 1) and _indices_clear_of_unselected_hold(selected_roll_snapshot, [1])) and all_passed
		screen.call("automation_clear")
		screen.call("automation_set_dice_count", 6)
		screen.call("automation_select_dice", [0, 5])
		screen.call("automation_set_targets", [1, 2, 3, 4, 5, 6])
		screen.call("_drop_with_current_settings", true)
		var multi_hold_snapshot: Dictionary = screen.call("automation_get_snapshot")
		all_passed = _check("gm selected roll holds multiple unselected dice", multi_hold_snapshot.get("held_unselected_dice_indices", []) == [1, 2, 3, 4] and _indices_in_unselected_hold(multi_hold_snapshot, [1, 2, 3, 4])) and all_passed
		all_passed = _check("gm multiple held dice stay centered and auto-spaced", _unselected_hold_targets_match_center(multi_hold_snapshot, [1, 2, 3, 4])) and all_passed
		all_passed = _check("gm multiple held dice disable collision", _held_dice_collision_disabled(multi_hold_snapshot, [1, 2, 3, 4])) and all_passed
		screen.call("automation_clear")
		screen.call("automation_set_dice_count", 3)
		screen.call("automation_set_targets", [1, 2, null])
		snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("gm port interface source is isolated", str(snapshot.get("target_plan_source", "")) == "GM复刻接口") and all_passed
		all_passed = _check("gm scene interface is ready", bool(snapshot.get("interface_ready", false))) and all_passed
		all_passed = _check("gm scene bridge uses reusable source label", str(snapshot.get("interface_source", "")) == "GM场景接口") and all_passed
		var bridge_contract: Dictionary = snapshot.get("bridge_contract", {})
		all_passed = _check("gm scene bridge exposes contract", int(bridge_contract.get("version", 0)) >= 1) and all_passed
		all_passed = _check("gm scene bridge exposes resolution event", (bridge_contract.get("events", []) as Array).has("resolution_requested")) and all_passed
		all_passed = _check("gm scene bridge exposes dice exit event", (bridge_contract.get("events", []) as Array).has("dice_exit_requested")) and all_passed
		all_passed = _check("gm scene bridge exposes throw speed tuning action", (bridge_contract.get("actions", []) as Array).has("set_throw_speed_tuning")) and all_passed
		all_passed = _check("gm scene bridge exposes throw speed tuning snapshot key", (bridge_contract.get("snapshot_keys", []) as Array).has("throw_speed_tuning")) and all_passed
		all_passed = _check("gm scene bridge exposes throw spin tuning action", (bridge_contract.get("actions", []) as Array).has("set_throw_spin_tuning")) and all_passed
		all_passed = _check("gm scene bridge exposes throw spin tuning snapshot key", (bridge_contract.get("snapshot_keys", []) as Array).has("throw_spin_tuning")) and all_passed
		all_passed = _check("gm scene bridge exposes exit return tuning action", (bridge_contract.get("actions", []) as Array).has("set_exit_return_tuning")) and all_passed
		all_passed = _check("gm scene bridge exposes exit return tuning snapshot key", (bridge_contract.get("snapshot_keys", []) as Array).has("exit_return_tuning")) and all_passed
		all_passed = _check("gm scene bridge exposes unselected hold tuning snapshot key", (bridge_contract.get("snapshot_keys", []) as Array).has("unselected_hold_tuning")) and all_passed
		all_passed = _check("gm scene bridge exposes held unselected dice snapshot key", (bridge_contract.get("snapshot_keys", []) as Array).has("held_unselected_dice_indices")) and all_passed
		all_passed = _check("gm scene bridge exposes unselected hold active snapshot key", (bridge_contract.get("snapshot_keys", []) as Array).has("unselected_hold_active")) and all_passed
		all_passed = _check("gm scene bridge exposes dice exit action", (bridge_contract.get("actions", []) as Array).has("request_dice_exit")) and all_passed
		all_passed = _check("gm scene bridge exposes dice return action", (bridge_contract.get("actions", []) as Array).has("request_dice_return")) and all_passed
		all_passed = _check("gm scene bridge exposes auto roll-all action", (bridge_contract.get("actions", []) as Array).has("request_auto_roll_all")) and all_passed
		all_passed = _check("gm scene bridge exposes launch status snapshot key", (bridge_contract.get("snapshot_keys", []) as Array).has("pending_launches")) and all_passed
		all_passed = _check("gm scene bridge exposes return duration snapshot key", (bridge_contract.get("snapshot_keys", []) as Array).has("ready_return_duration_seconds")) and all_passed
		all_passed = _check("gm scene bridge exposes exit return status key", (bridge_contract.get("snapshot_keys", []) as Array).has("dice_exit_return_animating")) and all_passed
		all_passed = _check("gm scene bridge exposes exit return random face key", (bridge_contract.get("snapshot_keys", []) as Array).has("last_exit_return_face_indices")) and all_passed
		all_passed = _check("gm scene bridge exposes auto roll-all snapshot key", (bridge_contract.get("snapshot_keys", []) as Array).has("auto_roll_all_pending")) and all_passed
		all_passed = _check("gm scene bridge exposes auto roll-all active key", (bridge_contract.get("snapshot_keys", []) as Array).has("auto_roll_all_active")) and all_passed
		all_passed = _check("gm scene bridge exposes auto roll-all input lock key", (bridge_contract.get("snapshot_keys", []) as Array).has("auto_roll_all_input_locked")) and all_passed
		all_passed = _check("gm scene bridge exposes resolution snapshot key", (bridge_contract.get("snapshot_keys", []) as Array).has("last_resolution_request")) and all_passed
		all_passed = _check("gm scene bridge exposes dice exit snapshot key", (bridge_contract.get("snapshot_keys", []) as Array).has("last_dice_exit_request")) and all_passed
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

		screen.call("automation_set_exit_return_tuning", {
			"screen_x": 0.66,
			"screen_y": 0.44,
			"spawn_y": 19.50,
		})
		snapshot = screen.call("automation_get_snapshot")
		var exit_return_tuning: Dictionary = snapshot.get("exit_return_tuning", {})
		all_passed = _check("exit return tuning stores screen x", is_equal_approx(float(exit_return_tuning.get("screen_x", 0.0)), 0.66)) and all_passed
		all_passed = _check("exit return tuning stores screen y", is_equal_approx(float(exit_return_tuning.get("screen_y", 0.0)), 0.44)) and all_passed
		all_passed = _check("exit return tuning stores spawn y", is_equal_approx(float(exit_return_tuning.get("spawn_y", 0.0)), 19.50)) and all_passed
		all_passed = _check("exit return tuning resolves fixed screen point to world point", exit_return_tuning.has("entry_world_position")) and all_passed

		var dice_exit_count_before := int(snapshot.get("dice_exit_request_count", 0))
		var exit_start_z := _min_dice_z(snapshot)
		if fly_button != null:
			fly_button.pressed.emit()
			await process_frame
			snapshot = screen.call("automation_get_snapshot")
			all_passed = _check("fly away button requests current dice exit", int(snapshot.get("dice_exit_request_count", 0)) == dice_exit_count_before + 1 and _dice_exit_request_matches_snapshot(snapshot)) and all_passed
			all_passed = _check("fly away button starts visible exit preview", bool(snapshot.get("dice_exit_animating", false)) and _any_dice_exiting(snapshot)) and all_passed
			var exit_motion_seen := false
			for _i in range(30):
				await physics_frame
				snapshot = screen.call("automation_get_snapshot")
				if _min_dice_z(snapshot) < exit_start_z - 0.50:
					exit_motion_seen = true
					break
			all_passed = _check("fly away preview moves dice toward requested Z direction", exit_motion_seen) and all_passed
			var exit_completed := false
			for _i in range(90):
				await physics_frame
				snapshot = screen.call("automation_get_snapshot")
				if bool(snapshot.get("dice_exit_completed", false)) and _all_dice_exited(snapshot):
					exit_completed = true
					break
			all_passed = _check("fly away preview finishes offscreen", exit_completed) and all_passed
			var return_button_enabled := false
			for _i in range(10):
				await physics_frame
				screen.call("_update_hud")
				hud_node = screen.get("hud")
				return_button = hud_node.return_button as Button if hud_node != null else null
				snapshot = screen.call("automation_get_snapshot")
				if return_button != null and not return_button.disabled:
					return_button_enabled = true
					break
			all_passed = _check("return button enables after fly away completes", return_button_enabled) and all_passed
			if return_button != null:
				var auto_request_count_before_exit_return := int(snapshot.get("auto_roll_all_request_count", 0))
				return_button.pressed.emit()
				await process_frame
				snapshot = screen.call("automation_get_snapshot")
				all_passed = _check("return button starts exit return preview", bool(snapshot.get("dice_exit_return_animating", false)) and _any_dice_returning_from_exit(snapshot)) and all_passed
				all_passed = _check("return button is disabled during exit return", return_button.disabled) and all_passed
				all_passed = _check("exit return starts from configured entry point", _exit_return_starts_from_tuning(snapshot, exit_return_tuning)) and all_passed
				all_passed = _check("exit return delay follows left to right order", _exit_return_delays_follow_left_to_right(snapshot)) and all_passed
				var exit_return_completed := false
				for _i in range(120):
					await physics_frame
					snapshot = screen.call("automation_get_snapshot")
					if bool(snapshot.get("dice_exit_return_completed", false)) and _all_dice_returned_from_exit(snapshot):
						exit_return_completed = true
						break
				all_passed = _check("return preview finishes back at hover row", exit_return_completed) and all_passed
				all_passed = _check("return preview randomizes dice face values", _return_faces_match_randomized_indices(snapshot)) and all_passed
				all_passed = _check("return button disables again after return completes", return_button.disabled) and all_passed
				var return_auto_result: Dictionary = await _wait_for_auto_roll_all_cycle(screen, [0, 1, 2], 720)
				var return_auto_snapshot: Dictionary = return_auto_result.get("snapshot", {})
				all_passed = _check("exit return schedules auto roll-all after delay", bool(return_auto_result.get("started", false)) and bool(return_auto_result.get("finished", false)) and int(return_auto_snapshot.get("auto_roll_all_request_count", 0)) > auto_request_count_before_exit_return) and all_passed
				all_passed = _check("exit return auto roll launches all dice together", return_auto_result.get("rolled_indices", []) == [0, 1, 2]) and all_passed
				snapshot = return_auto_snapshot

		snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("old throw tuning snapshot is removed", not snapshot.has("throw_tuning")) and all_passed
		all_passed = _check("old throw tuning automation is removed", not screen.has_method("automation_set_throw_tuning")) and all_passed
		screen.call("automation_set_throw_speed_tuning", {
			"linear_speed_min": 4.4,
			"linear_speed_max": 4.4,
		})
		snapshot = screen.call("automation_get_snapshot")
		var speed_tuning: Dictionary = snapshot.get("throw_speed_tuning", {})
		all_passed = _check("throw speed tuning stores linear speed min", is_equal_approx(float(speed_tuning.get("linear_speed_min", 0.0)), 4.4)) and all_passed
		all_passed = _check("throw speed tuning stores linear speed max", is_equal_approx(float(speed_tuning.get("linear_speed_max", 0.0)), 4.4)) and all_passed
		all_passed = _check("throw speed tuning propagates to dice", _all_dice_throw_speed_tuning(snapshot, speed_tuning)) and all_passed
		screen.call("automation_set_throw_spin_tuning", {
			"angular_speed_min": 5.5,
			"angular_speed_max": 7.5,
			"torque_min": 3.0,
			"torque_max": 4.5,
		})
		snapshot = screen.call("automation_get_snapshot")
		var spin_tuning: Dictionary = snapshot.get("throw_spin_tuning", {})
		all_passed = _check("throw spin tuning stores angular speed min", is_equal_approx(float(spin_tuning.get("angular_speed_min", 0.0)), 5.5)) and all_passed
		all_passed = _check("throw spin tuning stores angular speed max", is_equal_approx(float(spin_tuning.get("angular_speed_max", 0.0)), 7.5)) and all_passed
		all_passed = _check("throw spin tuning stores torque min", is_equal_approx(float(spin_tuning.get("torque_min", 0.0)), 3.0)) and all_passed
		all_passed = _check("throw spin tuning stores torque max", is_equal_approx(float(spin_tuning.get("torque_max", 0.0)), 4.5)) and all_passed
		all_passed = _check("throw spin tuning propagates to dice", _all_dice_throw_spin_tuning(snapshot, spin_tuning)) and all_passed
		screen.call("automation_set_idle_drift_tuning", {
			"min_seconds": 0.50,
			"max_seconds": 0.70,
			"max_distance": 0.12,
			"speed": 0.30,
		})
		snapshot = screen.call("automation_get_snapshot")
		var drift_tuning: Dictionary = snapshot.get("idle_drift_tuning", {})
		all_passed = _check("idle drift tuning stores min seconds", is_equal_approx(float(drift_tuning.get("min_seconds", 0.0)), 0.50)) and all_passed
		all_passed = _check("idle drift tuning stores max seconds", is_equal_approx(float(drift_tuning.get("max_seconds", 0.0)), 0.70)) and all_passed
		all_passed = _check("idle drift tuning stores max distance", is_equal_approx(float(drift_tuning.get("max_distance", 0.0)), 0.12)) and all_passed
		all_passed = _check("idle drift tuning stores speed", is_equal_approx(float(drift_tuning.get("speed", 0.0)), 0.30)) and all_passed
		all_passed = _check("idle drift tuning propagates to dice", _all_dice_idle_tuning(snapshot, drift_tuning)) and all_passed
		for _i in range(18):
			await physics_frame
		snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("tuned gm dice drift stays within max distance", _all_drift_offsets_within_limit(snapshot)) and all_passed
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
		var downward_throw_seen := false
		var tuned_linear_speed_seen := false
		var never_fell_below_stage := true
		var never_crossed_hidden_bounds := true
		for _i in range(90):
			await physics_frame
			snapshot = screen.call("automation_get_snapshot")
			var rolling_now := _rolling_indices(snapshot)
			if (
				not rolling_now.is_empty()
				and _max_dice_speed(snapshot, "linear_speed") >= 1.2
				and _max_dice_speed(snapshot, "angular_speed") >= 3.0
				and _rolling_throw_velocities_are_downward(snapshot, rolling_now)
			):
				downward_throw_seen = true
			if not rolling_now.is_empty() and _last_throw_speeds_in_range(snapshot, rolling_now, 4.35, 4.45):
				tuned_linear_speed_seen = true
			if _min_dice_y(snapshot) < -0.85:
				never_fell_below_stage = false
				break
			if _max_abs_position(snapshot, "x") > collision_stage.x * 0.5 + 0.45 or _max_abs_position(snapshot, "z") > collision_stage.y * 0.5 + 0.45:
				never_crossed_hidden_bounds = false
				break
		all_passed = _check("random throw creates visible physics dice", int(snapshot.get("active_dice", 0)) == 2 and bool(snapshot.get("rolling", false))) and all_passed
		all_passed = _check("random throw uses negative-y target ray motion", downward_throw_seen) and all_passed
		all_passed = _check("random throw uses tuned linear speed", tuned_linear_speed_seen) and all_passed
		all_passed = _check("random throw does not fall below full stage", never_fell_below_stage) and all_passed
		all_passed = _check("random throw stays inside hidden bounds", never_crossed_hidden_bounds) and all_passed
		all_passed = _check("normal random throw does not trigger recovery", int(snapshot.get("recover_count", -1)) == 0) and all_passed
		var settled_back_to_hover := false
		var ready_return_seen := false
		var curved_ready_return_seen := false
		for _i in range(540):
			await physics_frame
			snapshot = screen.call("automation_get_snapshot")
			if _any_ready_returning(snapshot):
				ready_return_seen = true
			if _any_curved_ready_return(snapshot):
				curved_ready_return_seen = true
			if not bool(snapshot.get("rolling", true)) and _min_dice_y(snapshot) >= 1.55 and _all_hover_shadows_visible(snapshot):
				settled_back_to_hover = true
				break
		all_passed = _check("settled dice return to hover ready row", settled_back_to_hover) and all_passed
		all_passed = _check("settled dice animate ready return", ready_return_seen) and all_passed
		all_passed = _check("settled dice ready return uses curved path", curved_ready_return_seen) and all_passed
		all_passed = _check("settled dice sample ground face before return", _dice_settled_on_ground(snapshot)) and all_passed
		all_passed = _check("settled dice return starts from settled ground position", _return_starts_from_settled_position(snapshot)) and all_passed
		all_passed = _check("ready row keeps settled ground pips", _ready_faces_match_settled_faces(snapshot)) and all_passed
		all_passed = _check("ready row exposes post-return resolution request", _resolution_request_matches_snapshot(snapshot, [0, 1])) and all_passed
		all_passed = _check("ready row exposes post-score dice exit request", _dice_exit_request_matches_snapshot(snapshot)) and all_passed
		screen.call("automation_clear")
		snapshot = screen.call("automation_get_snapshot")
		all_passed = _check("clear removes visible dice", int(snapshot.get("active_dice", -1)) == 0) and all_passed
		screen.call("automation_set_dice_count", 2)
		screen.call("automation_select_dice", [1])
		if drop_button != null:
			drop_button.pressed.emit()
			var rerolled_after_clear := false
			for _i in range(30):
				await physics_frame
				snapshot = screen.call("automation_get_snapshot")
				if int(snapshot.get("active_dice", 0)) == 2 and bool(snapshot.get("rolling", false)) and _rolling_indices(snapshot) == [1]:
					rerolled_after_clear = true
					break
			all_passed = _check("drop button rolls selected die after clear", rerolled_after_clear) and all_passed

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


func _wait_for_auto_roll_all_cycle(screen: Node, expected_indices: Array, timeout_frames: int) -> Dictionary:
	var started := false
	var finished := false
	var rolled_indices: Array = []
	var snapshot: Dictionary = {}
	for _i in range(timeout_frames):
		await physics_frame
		snapshot = screen.call("automation_get_snapshot")
		var last_rolled: Array = snapshot.get("last_rolled_dice_indices", [])
		if bool(snapshot.get("rolling", false)) and last_rolled == expected_indices:
			started = true
			rolled_indices = last_rolled.duplicate()
		if started and not bool(snapshot.get("rolling", true)) and int(snapshot.get("pending_ready_returns", 0)) == 0:
			finished = true
			break
	return {
		"started": started,
		"finished": finished,
		"rolled_indices": rolled_indices,
		"snapshot": snapshot,
	}


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


func _max_dice_y(snapshot: Dictionary) -> float:
	var max_y := -INF
	var dice_rows: Array = snapshot.get("dice", [])
	for row in dice_rows:
		if row is Dictionary:
			var position: Vector3 = row.get("position", Vector3.ZERO)
			max_y = maxf(max_y, position.y)
	return max_y if max_y > -INF else 0.0


func _max_dice_z(snapshot: Dictionary) -> float:
	var max_z := -INF
	var dice_rows: Array = snapshot.get("dice", [])
	for row in dice_rows:
		if row is Dictionary:
			var position: Vector3 = row.get("position", Vector3.ZERO)
			max_z = maxf(max_z, position.z)
	return max_z if max_z > -INF else 0.0


func _min_dice_z(snapshot: Dictionary) -> float:
	var min_z := INF
	var dice_rows: Array = snapshot.get("dice", [])
	for row in dice_rows:
		if row is Dictionary:
			var position: Vector3 = row.get("position", Vector3.ZERO)
			min_z = minf(min_z, position.z)
	return min_z if min_z < INF else 0.0


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


func _min_indexed_dice_y(snapshot: Dictionary, indices: Array) -> float:
	var dice_rows: Array = snapshot.get("dice", [])
	var min_y := INF
	for raw_index in indices:
		var index := int(raw_index)
		if index < 0 or index >= dice_rows.size() or not (dice_rows[index] is Dictionary):
			continue
		var row: Dictionary = dice_rows[index]
		var position: Vector3 = row.get("position", Vector3.ZERO)
		min_y = minf(min_y, position.y)
	return min_y if min_y < INF else 0.0


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


func _selected_frame_indices(snapshot: Dictionary) -> Array[int]:
	var indices: Array[int] = []
	var dice_rows: Array = snapshot.get("dice", [])
	for index in range(dice_rows.size()):
		var row = dice_rows[index]
		if row is Dictionary and bool(row.get("selection_frame_visible", false)):
			indices.append(index)
	return indices


func _rolling_indices(snapshot: Dictionary) -> Array[int]:
	var indices: Array[int] = []
	var dice_rows: Array = snapshot.get("dice", [])
	for index in range(dice_rows.size()):
		var row = dice_rows[index]
		if row is Dictionary and bool(row.get("rolling", false)):
			indices.append(index)
	return indices


func _indices_in_unselected_hold(snapshot: Dictionary, indices: Array) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for raw_index in indices:
		var index := int(raw_index)
		if index < 0 or index >= dice_rows.size() or not (dice_rows[index] is Dictionary):
			return false
		var row: Dictionary = dice_rows[index]
		if not bool(row.get("unselected_hold_active", false)):
			return false
	return true


func _indices_clear_of_unselected_hold(snapshot: Dictionary, indices: Array) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for raw_index in indices:
		var index := int(raw_index)
		if index < 0 or index >= dice_rows.size() or not (dice_rows[index] is Dictionary):
			return false
		var row: Dictionary = dice_rows[index]
		if bool(row.get("unselected_hold_active", false)) or bool(row.get("unselected_hold_collision_disabled", false)):
			return false
	return true


func _held_dice_collision_disabled(snapshot: Dictionary, indices: Array) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for raw_index in indices:
		var index := int(raw_index)
		if index < 0 or index >= dice_rows.size() or not (dice_rows[index] is Dictionary):
			return false
		var row: Dictionary = dice_rows[index]
		if not bool(row.get("unselected_hold_collision_disabled", false)):
			return false
	return true


func _unselected_hold_targets_match_center(snapshot: Dictionary, indices: Array) -> bool:
	var tuning: Dictionary = snapshot.get("unselected_hold_tuning", {})
	if not tuning.has("center_world_position") or not (tuning["center_world_position"] is Vector3):
		return false
	var expected_center: Vector3 = tuning["center_world_position"]
	var dice_rows: Array = snapshot.get("dice", [])
	var targets: Array[Vector3] = []
	var target_sum := Vector3.ZERO
	var count := 0
	for raw_index in indices:
		var index := int(raw_index)
		if index < 0 or index >= dice_rows.size() or not (dice_rows[index] is Dictionary):
			return false
		var row: Dictionary = dice_rows[index]
		var target: Vector3 = row.get("unselected_hold_target_position", Vector3.ZERO)
		targets.append(target)
		target_sum += target
		count += 1
	if count <= 0:
		return false
	var center := target_sum / float(count)
	if center.distance_to(expected_center) > 0.04:
		return false
	if targets.size() <= 1:
		return true
	targets.sort_custom(func(a: Vector3, b: Vector3) -> bool:
		return a.x < b.x
	)
	var expected_spacing := 1.06
	for index in range(1, targets.size()):
		if absf((targets[index].x - targets[index - 1].x) - expected_spacing) > 0.04:
			return false
	return true


func _indices_returning_to_ready(snapshot: Dictionary, indices: Array) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for raw_index in indices:
		var index := int(raw_index)
		if index < 0 or index >= dice_rows.size() or not (dice_rows[index] is Dictionary):
			return false
		if not bool((dice_rows[index] as Dictionary).get("returning_to_ready", false)):
			return false
	return true


func _indices_returning_from_unselected_hold(snapshot: Dictionary, indices: Array) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for raw_index in indices:
		var index := int(raw_index)
		if index < 0 or index >= dice_rows.size() or not (dice_rows[index] is Dictionary):
			return false
		if not bool((dice_rows[index] as Dictionary).get("returning_from_unselected_hold", false)):
			return false
	return true


func _any_dice_exiting(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for row in dice_rows:
		if row is Dictionary and bool(row.get("exiting", false)):
			return true
	return false


func _all_dice_exited(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary) or not bool(row.get("exited", false)):
			return false
	return true


func _any_dice_returning_from_exit(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for row in dice_rows:
		if row is Dictionary and bool(row.get("returning_from_exit", false)):
			return true
	return false


func _all_dice_returned_from_exit(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		if bool(row.get("returning_from_exit", false)) or bool(row.get("exiting", false)) or bool(row.get("exited", false)):
			return false
		if float(row.get("exit_return_progress", 0.0)) < 0.99:
			return false
		var position: Vector3 = row.get("position", Vector3.ZERO)
		var anchor: Vector3 = row.get("idle_anchor_position", Vector3.ZERO)
		if position.distance_to(anchor) > 0.12:
			return false
	return true


func _exit_return_starts_from_tuning(snapshot: Dictionary, tuning: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	var expected_y := float(tuning.get("spawn_y", 20.0))
	if not tuning.has("entry_world_position") or not (tuning["entry_world_position"] is Vector3):
		return false
	var expected_position: Vector3 = tuning["entry_world_position"]
	expected_position.y = expected_y
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		var start_position: Vector3 = row.get("exit_return_start_position", Vector3.ZERO)
		if start_position.distance_to(expected_position) > 0.02:
			return false
	return true


func _exit_return_delays_follow_left_to_right(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	var items: Array = []
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		items.append({
			"target_x": (row.get("exit_return_target_position", Vector3.ZERO) as Vector3).x,
			"delay": float(row.get("exit_return_delay_seconds", -1.0)),
		})
	items.sort_custom(func(a, b) -> bool:
		var a_item := a as Dictionary
		var b_item := b as Dictionary
		return float(a_item.get("target_x", 0.0)) < float(b_item.get("target_x", 0.0))
	)
	var previous_delay := -INF
	for item in items:
		var delay := float((item as Dictionary).get("delay", -1.0))
		if delay < previous_delay - 0.001:
			return false
		previous_delay = delay
	return true


func _return_faces_match_randomized_indices(snapshot: Dictionary) -> bool:
	var randomized_indices: Array = snapshot.get("last_exit_return_face_indices", [])
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.size() != randomized_indices.size() or dice_rows.is_empty():
		return false
	for index in range(dice_rows.size()):
		if not (dice_rows[index] is Dictionary):
			return false
		var row: Dictionary = dice_rows[index]
		var randomized_face_index := int(randomized_indices[index])
		if randomized_face_index < 0 or randomized_face_index > 5:
			return false
		if int(row.get("face_index", -1)) != randomized_face_index:
			return false
		if int(row.get("visual_top_face_index", -1)) != randomized_face_index:
			return false
	return true


func _rolled_from_current_positions(snapshot: Dictionary, before_positions: Array, indices: Array) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for raw_index in indices:
		var index := int(raw_index)
		if index < 0 or index >= dice_rows.size() or index >= before_positions.size():
			return false
		if not (dice_rows[index] is Dictionary):
			return false
		var row: Dictionary = dice_rows[index]
		var before_position := before_positions[index] as Vector3
		var origin_position: Vector3 = row.get("last_throw_origin_position", Vector3.ZERO)
		if origin_position.distance_to(before_position) > 0.12:
			return false
	return true


func _rolling_throw_velocities_are_downward(snapshot: Dictionary, indices: Array) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for raw_index in indices:
		var index := int(raw_index)
		if index < 0 or index >= dice_rows.size() or not (dice_rows[index] is Dictionary):
			return false
		var row: Dictionary = dice_rows[index]
		var origin: Vector3 = row.get("last_throw_origin_position", Vector3.ZERO)
		var target: Vector3 = row.get("last_throw_target_position", Vector3.ZERO)
		var direction: Vector3 = row.get("last_throw_direction", Vector3.ZERO)
		var velocity: Vector3 = row.get("last_throw_velocity", Vector3.ZERO)
		if target.y >= 0.0:
			return false
		var expected_direction := target - origin
		if expected_direction.length_squared() <= 0.001:
			return false
		expected_direction = expected_direction.normalized()
		if expected_direction.y >= -0.01:
			return false
		if direction.distance_to(expected_direction) > 0.02:
			return false
		if velocity.length() <= 1.00 or velocity.normalized().distance_to(expected_direction) > 0.02:
			return false
		if velocity.y >= -0.10:
			return false
	return true


func _any_idle_drift_moved(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for row in dice_rows:
		if row is Dictionary and bool(row.get("idle_drift_active", false)) and absf(float(row.get("idle_drift_offset", 0.0))) > 0.01:
			return true
	return false


func _all_drift_offsets_within_limit(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	var drift_tuning: Dictionary = snapshot.get("idle_drift_tuning", {})
	var max_distance := float(drift_tuning.get("max_distance", 0.07))
	for row in dice_rows:
		if row is Dictionary and absf(float(row.get("idle_drift_offset", 0.0))) > max_distance + 0.03:
			return false
	return true


func _all_dice_idle_tuning(snapshot: Dictionary, expected: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		var tuning: Dictionary = row.get("idle_drift_tuning", {})
		for key in expected.keys():
			if not is_equal_approx(float(tuning.get(key, -999.0)), float(expected[key])):
				return false
	return true


func _all_dice_throw_speed_tuning(snapshot: Dictionary, expected: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		var tuning: Dictionary = row.get("throw_speed_tuning", {})
		for key in expected.keys():
			if not is_equal_approx(float(tuning.get(key, -999.0)), float(expected[key])):
				return false
	return true


func _all_dice_throw_spin_tuning(snapshot: Dictionary, expected: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		var tuning: Dictionary = row.get("throw_spin_tuning", {})
		for key in expected.keys():
			if not is_equal_approx(float(tuning.get(key, -999.0)), float(expected[key])):
				return false
	return true


func _last_throw_speeds_in_range(snapshot: Dictionary, indices: Array, min_speed: float, max_speed: float) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for raw_index in indices:
		var index := int(raw_index)
		if index < 0 or index >= dice_rows.size() or not (dice_rows[index] is Dictionary):
			return false
		var row: Dictionary = dice_rows[index]
		var velocity: Vector3 = row.get("last_throw_velocity", Vector3.ZERO)
		var speed := velocity.length()
		if speed < min_speed or speed > max_speed:
			return false
	return true


func _any_ready_returning(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for row in dice_rows:
		if row is Dictionary and bool(row.get("returning_to_ready", false)):
			return true
	return false


func _any_curved_ready_return(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	for row in dice_rows:
		if row is Dictionary and bool(row.get("returning_to_ready", false)) and float(row.get("ready_return_curve_offset", 0.0)) > 0.10:
			return true
	return false


func _dice_settled_on_ground(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		var settled_face_value := int(row.get("last_settled_face_value", 0))
		if settled_face_value < 1 or settled_face_value > 6:
			continue
		var settled_position: Vector3 = row.get("last_settled_position", Vector3.ZERO)
		if settled_position.y < -0.20 or settled_position.y > 1.20:
			return false
		if float(row.get("last_settled_linear_speed", 999.0)) > 0.19:
			return false
		if float(row.get("last_settled_angular_speed", 999.0)) > 0.31:
			return false
		if int(row.get("last_settled_stable_frames", 0)) < 12:
			return false
	return true


func _return_starts_from_settled_position(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		var settled_face_value := int(row.get("last_settled_face_value", 0))
		if settled_face_value < 1 or settled_face_value > 6:
			continue
		var settled_position: Vector3 = row.get("last_settled_position", Vector3.ZERO)
		var return_start_position: Vector3 = row.get("ready_return_start_position", Vector3.ZERO)
		if settled_position.distance_to(return_start_position) > 0.02:
			return false
	return true


func _ready_faces_match_settled_faces(snapshot: Dictionary) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if dice_rows.is_empty():
		return false
	for row in dice_rows:
		if not (row is Dictionary):
			return false
		var settled_face_index := int(row.get("last_settled_face_index", -1))
		var settled_face_value := int(row.get("last_settled_face_value", 0))
		if settled_face_index < 0 or settled_face_value < 1 or settled_face_value > 6:
			continue
		if int(row.get("face_index", -2)) != settled_face_index:
			return false
		if int(row.get("face_value", 0)) != settled_face_value:
			return false
		if int(row.get("visual_top_face_index", -2)) != settled_face_index:
			return false
		if int(row.get("visual_top_face_value", 0)) != settled_face_value:
			return false
		if float(row.get("visual_top_text_alignment", -1.0)) < 0.95:
			return false
	return true


func _resolution_request_matches_snapshot(snapshot: Dictionary, expected_rolled_indices: Array) -> bool:
	if int(snapshot.get("resolution_request_count", 0)) < 1:
		return false
	var request: Dictionary = snapshot.get("last_resolution_request", {})
	if str(request.get("source", "")) != "gm_physics_dice":
		return false
	if str(request.get("phase", "")) != "after_ready_return":
		return false
	if request.get("rolled_dice_indices", []) != expected_rolled_indices:
		return false
	var dice_rows: Array = request.get("dice", [])
	var final_values: Array = snapshot.get("last_values", [])
	if dice_rows.size() != final_values.size():
		return false
	var total := 0
	for index in range(dice_rows.size()):
		if not (dice_rows[index] is Dictionary):
			return false
		var row: Dictionary = dice_rows[index]
		var face_value := int(row.get("face_value", 0))
		if face_value != int(final_values[index]):
			return false
		if bool(row.get("rolled", false)) != expected_rolled_indices.has(index):
			return false
		total += face_value
	var score_request: Dictionary = request.get("score_request", {})
	if int(score_request.get("point_total", -1)) != total:
		return false
	if score_request.get("pip_values", []) != final_values:
		return false
	var effect_request: Dictionary = request.get("effect_request", {})
	return str(effect_request.get("status", "")) == "reserved_for_formal_game" and effect_request.get("steps", []) == []


func _dice_exit_request_matches_snapshot(snapshot: Dictionary) -> bool:
	if int(snapshot.get("dice_exit_request_count", 0)) < 1:
		return false
	var request: Dictionary = snapshot.get("last_dice_exit_request", {})
	if str(request.get("source", "")) != "gm_physics_dice":
		return false
	if str(request.get("phase", "")) != "after_score_resolved":
		return false
	var animation: Dictionary = request.get("animation", {})
	if str(animation.get("order", "")) != "left_to_right":
		return false
	if str(animation.get("curve", "")) != "straight":
		return false
	if (animation.get("world_exit_direction", Vector3.ZERO) as Vector3).distance_to(Vector3(0.0, 0.0, -1.0)) > 0.01:
		return false
	if float(animation.get("step_delay_seconds", 0.0)) <= 0.0 or float(animation.get("duration_seconds", 0.0)) <= 0.0:
		return false
	var world_exit_offset := animation.get("world_exit_offset", Vector3.ZERO) as Vector3
	if world_exit_offset.z >= 0.0 or absf(world_exit_offset.y) > 0.01:
		return false
	if absf(float(animation.get("arc_height", -1.0))) > 0.01:
		return false
	var next_round: Dictionary = request.get("next_round", {})
	if not bool(next_round.get("wait", false)) or str(next_round.get("status", "")) != "reserved_for_formal_game":
		return false
	var score: Dictionary = snapshot.get("score", {})
	var request_score: Dictionary = request.get("score", {})
	if int(request_score.get("final_score", -1)) != int(score.get("final_score", -2)):
		return false
	if int(request_score.get("current_score", -1)) != int(score.get("current_score", -2)):
		return false
	var sequence: Array = request.get("sequence", [])
	var final_values: Array = snapshot.get("last_values", [])
	if sequence.size() != final_values.size() or sequence.is_empty():
		return false
	var previous_x := -INF
	var step_delay := float(animation.get("step_delay_seconds", 0.0))
	for order_index in range(sequence.size()):
		if not (sequence[order_index] is Dictionary):
			return false
		var item: Dictionary = sequence[order_index]
		if int(item.get("order_index", -1)) != order_index:
			return false
		if not is_equal_approx(float(item.get("delay_seconds", -1.0)), float(order_index) * step_delay):
			return false
		if (item.get("exit_direction", Vector3.ZERO) as Vector3).distance_to(Vector3(0.0, 0.0, -1.0)) > 0.01:
			return false
		var start_position := item.get("start_position", Vector3.ZERO) as Vector3
		if start_position.x < previous_x - 0.001:
			return false
		previous_x = start_position.x
		var die_index := int(item.get("die_index", -1))
		if die_index < 0 or die_index >= final_values.size():
			return false
		if int(item.get("face_value", 0)) != int(final_values[die_index]):
			return false
	return true


func _die_returned_to_idle_anchor(snapshot: Dictionary, index: int) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if index < 0 or index >= dice_rows.size() or not (dice_rows[index] is Dictionary):
		return false
	var row: Dictionary = dice_rows[index]
	var position: Vector3 = row.get("position", Vector3.ZERO)
	var anchor: Vector3 = row.get("idle_anchor_position", Vector3.ZERO)
	return position.distance_to(anchor) <= 0.01


func _die_idle_drift_stopped(snapshot: Dictionary, index: int) -> bool:
	var dice_rows: Array = snapshot.get("dice", [])
	if index < 0 or index >= dice_rows.size() or not (dice_rows[index] is Dictionary):
		return false
	var row: Dictionary = dice_rows[index]
	return not bool(row.get("idle_drift_active", true)) and absf(float(row.get("idle_drift_offset", 1.0))) <= 0.001


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
