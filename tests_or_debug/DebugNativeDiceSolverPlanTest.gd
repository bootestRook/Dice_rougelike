extends SceneTree
class_name DebugNativeDiceSolverPlanTest


const PhysicsDiceThrowService = preload("res://scripts/rules/physics_dice/PhysicsDiceThrowService.gd")
const FACE_DEFINITIONS := [
	{"value": 1, "normal": Vector3.UP},
	{"value": 6, "normal": Vector3.DOWN},
	{"value": 2, "normal": Vector3.BACK},
	{"value": 5, "normal": Vector3.FORWARD},
	{"value": 3, "normal": Vector3.RIGHT},
	{"value": 4, "normal": Vector3.LEFT},
]


func _init() -> void:
	print("--- DebugNativeDiceSolverPlanTest: start ---")
	var all_passed := true
	var service := PhysicsDiceThrowService.new()
	var result := service.solve_throw(6, [1, 2, 3, 4, 5, 6], {"max_attempts_per_die": 512})
	print("source=%s latency=%s" % [str(result.get("source", "")), str(result.get("latency_ms", ""))])
	all_passed = _check("native solver is used", str(result.get("source", "")) == "原生快速求解器") and all_passed
	var plans: Array = result.get("plans", [])
	all_passed = _check("solver returns six plans", plans.size() == 6) and all_passed
	var initial_values: Array[int] = []
	var min_horizontal_speed := INF
	var min_spin_speed := INF
	var min_trajectory_size := 999999
	var min_trajectory_displacement := INF
	var max_initial_radius := 0.0
	var final_positions: Array[Vector3] = []
	var trajectories: Array = []
	for plan in plans:
		initial_values.append(_get_up_face_value(plan["quaternion"] as Quaternion))
		var velocity := plan["velocity"] as Vector3
		var angular_velocity := plan["angular_velocity"] as Vector3
		min_horizontal_speed = minf(min_horizontal_speed, Vector2(velocity.x, velocity.z).length())
		min_spin_speed = minf(min_spin_speed, angular_velocity.length())
		var trajectory: Array = plan.get("trajectory", [])
		trajectories.append(trajectory)
		min_trajectory_size = mini(min_trajectory_size, trajectory.size())
		if trajectory.size() >= 2:
			var first := trajectory[0] as Dictionary
			var first_xz := Vector2((first["position"] as Vector3).x, (first["position"] as Vector3).z)
			max_initial_radius = maxf(max_initial_radius, first_xz.length())
			var max_displacement := 0.0
			for frame_value in trajectory:
				var frame := frame_value as Dictionary
				var frame_position := frame["position"] as Vector3
				max_displacement = maxf(max_displacement, first_xz.distance_to(Vector2(frame_position.x, frame_position.z)))
			min_trajectory_displacement = minf(min_trajectory_displacement, max_displacement)
			var last_frame := trajectory[trajectory.size() - 1] as Dictionary
			final_positions.append(last_frame["position"] as Vector3)
	var min_final_separation := _min_xz_separation(final_positions)
	var min_path_separation := _min_temporal_xz_separation(trajectories)
	var min_table_margin := _min_table_margin(trajectories)
	print("initial values: %s" % [str(initial_values)])
	print("predicted values: %s" % [str(result.get("predicted_values", []))])
	print("min horizontal speed: %.2f, min spin speed: %.2f" % [min_horizontal_speed, min_spin_speed])
	print("min trajectory frames: %d, min trajectory displacement: %.2f, max initial radius: %.2f, min final separation: %.2f, min path separation: %.2f, min table margin: %.2f" % [min_trajectory_size, min_trajectory_displacement, max_initial_radius, min_final_separation, min_path_separation, min_table_margin])
	all_passed = _check("native prediction matches targets", result.get("predicted_values", []) == [1, 2, 3, 4, 5, 6]) and all_passed
	all_passed = _check("target throw is not vertical drop", min_horizontal_speed >= 1.0) and all_passed
	all_passed = _check("target throw has visible spin", min_spin_speed >= 6.0) and all_passed
	all_passed = _check("target throw returns full trajectory", min_trajectory_size >= 30) and all_passed
	all_passed = _check("target trajectory visibly drifts from drop point", min_trajectory_displacement >= 0.5) and all_passed
	all_passed = _check("target throw starts from center area", max_initial_radius <= 2.0) and all_passed
	all_passed = _check("target dice do not settle embedded", min_final_separation >= 0.86) and all_passed
	all_passed = _check("target trajectories avoid visible clipping", min_path_separation >= 0.9) and all_passed
	all_passed = _check("target trajectories stay inside table", min_table_margin >= 0.55) and all_passed
	print("PASS: DebugNativeDiceSolverPlanTest" if all_passed else "FAIL: DebugNativeDiceSolverPlanTest")
	print("--- DebugNativeDiceSolverPlanTest: end ---")
	quit(0 if all_passed else 1)


func _get_up_face_value(q: Quaternion) -> int:
	var best_value := 1
	var best_dot := -INF
	var basis := Basis(q)
	for face in FACE_DEFINITIONS:
		var normal := basis * (face["normal"] as Vector3)
		var dot := normal.dot(Vector3.UP)
		if dot > best_dot:
			best_dot = dot
			best_value = int(face["value"])
	return best_value


func _min_xz_separation(positions: Array[Vector3]) -> float:
	if positions.size() < 2:
		return INF
	var min_distance := INF
	for i in range(positions.size()):
		for j in range(i + 1, positions.size()):
			var a := Vector2(positions[i].x, positions[i].z)
			var b := Vector2(positions[j].x, positions[j].z)
			min_distance = minf(min_distance, a.distance_to(b))
	return min_distance


func _min_table_margin(trajectories: Array) -> float:
	if trajectories.is_empty():
		return INF
	var safe_half_width := 12.8 * 0.5 - 0.78
	var safe_half_depth := 9.2 * 0.5 - 0.78
	var min_margin := INF
	for trajectory_value in trajectories:
		var trajectory := trajectory_value as Array
		for frame_value in trajectory:
			var frame := frame_value as Dictionary
			var position := frame["position"] as Vector3
			if position.y > 1.55:
				continue
			var x_margin := safe_half_width - absf(position.x)
			var z_margin := safe_half_depth - absf(position.z)
			min_margin = minf(min_margin, minf(x_margin, z_margin))
	return min_margin


func _min_temporal_xz_separation(trajectories: Array) -> float:
	if trajectories.size() < 2:
		return INF
	var min_distance := INF
	for i in range(trajectories.size()):
		var a_trajectory := trajectories[i] as Array
		for j in range(i + 1, trajectories.size()):
			var b_trajectory := trajectories[j] as Array
			if a_trajectory.is_empty() or b_trajectory.is_empty():
				continue
			var max_size := maxi(a_trajectory.size(), b_trajectory.size())
			for frame_index in range(max_size):
				var a_frame := a_trajectory[mini(frame_index, a_trajectory.size() - 1)] as Dictionary
				var b_frame := b_trajectory[mini(frame_index, b_trajectory.size() - 1)] as Dictionary
				var a_position := a_frame["position"] as Vector3
				var b_position := b_frame["position"] as Vector3
				if absf(a_position.y - b_position.y) > 0.72 * 0.92:
					continue
				var a_xz := Vector2(a_position.x, a_position.z)
				var b_xz := Vector2(b_position.x, b_position.z)
				min_distance = minf(min_distance, a_xz.distance_to(b_xz))
	return min_distance


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
