extends RefCounted
class_name PhysicsDiceThrowService


const MAX_DICE := 6
const SOURCE_NATIVE := "原生快速求解器"
const SOURCE_GDSCRIPT := "脚本备用求解器"
const NATIVE_EXTENSION_PATH := "res://addons/physics_dice_solver/physics_dice_solver.gdextension"

var rng := RandomNumberGenerator.new()
var _native_solver: Object = null
var _native_checked := false


func _init() -> void:
	rng.randomize()


func has_native_solver() -> bool:
	return _get_native_solver() != null


func solve_throw(count: int, targets: Array, options: Dictionary = {}) -> Dictionary:
	var start_ms := Time.get_ticks_msec()
	var resolved_count := clampi(count, 1, MAX_DICE)
	var resolved_targets := _sanitize_targets(resolved_count, targets)

	var native_solver := _get_native_solver()
	if native_solver != null:
		var native_options := options.duplicate(true)
		native_options["seed"] = int(rng.randi())
		var result = native_solver.call("solve_throw", resolved_count, resolved_targets, native_options)
		if result is Dictionary and bool(result.get("ok", false)):
			result["latency_ms"] = int(Time.get_ticks_msec() - start_ms)
			result["source"] = SOURCE_NATIVE
			result["targets"] = resolved_targets
			return result

	return _solve_gdscript(resolved_count, resolved_targets, options, start_ms)


func _get_native_solver() -> Object:
	if _native_checked:
		return _native_solver
	_native_checked = true
	_ensure_native_extension_loaded()
	if not ClassDB.class_exists(&"NativeDiceThrowSolver"):
		return null
	var instance = ClassDB.instantiate(&"NativeDiceThrowSolver")
	if instance != null and instance.has_method("solve_throw"):
		_native_solver = instance
	return _native_solver


func _ensure_native_extension_loaded() -> void:
	var manager := Engine.get_singleton(&"GDExtensionManager")
	if manager == null:
		return
	if manager.has_method("is_extension_loaded") and bool(manager.call("is_extension_loaded", NATIVE_EXTENSION_PATH)):
		return
	if manager.has_method("load_extension"):
		manager.call("load_extension", NATIVE_EXTENSION_PATH)


func _sanitize_targets(count: int, targets: Array) -> Array:
	var resolved: Array = []
	for i in range(count):
		var value = targets[i] if i < targets.size() else null
		if value != null:
			var pip := int(value)
			resolved.append(pip if pip >= 1 and pip <= 6 else null)
		else:
			resolved.append(null)
	return resolved


func _solve_gdscript(count: int, targets: Array, options: Dictionary, start_ms: int) -> Dictionary:
	var plans: Array = []
	for i in range(count):
		var target_value = targets[i]
		plans.append(_make_throw_params(i, count, int(target_value) if target_value != null else 0, options))
	return {
		"ok": true,
		"plans": plans,
		"source": SOURCE_GDSCRIPT,
		"latency_ms": int(Time.get_ticks_msec() - start_ms),
		"targets": targets,
	}


func _make_throw_params(index: int, count: int, target_value: int, options: Dictionary) -> Dictionary:
	var target_mode := target_value >= 1 and target_value <= 6
	var lane := _lane_position(index, count, target_mode)
	var height := float(options.get("entry_height", 3.25 if target_mode else 3.35))
	var position := Vector3(
		lane.x + rng.randf_range(-0.22, 0.22),
		height + float(index) * 0.1 + rng.randf_range(0.0, 0.35),
		lane.z + rng.randf_range(-0.22, 0.22)
	)
	var q := _make_random_quaternion()
	var outward := Vector3(position.x, 0.0, position.z)
	if outward.length_squared() < 0.001:
		outward = Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
	outward = outward.normalized()
	var tangent := Vector3(-outward.z, 0.0, outward.x)
	var radial_speed := rng.randf_range(0.9, 1.2)
	var sideways_speed := rng.randf_range(-1.35, 1.35)
	if absf(sideways_speed) < 0.65:
		sideways_speed += 0.65 if sideways_speed >= 0.0 else -0.65
	var velocity := outward * radial_speed + tangent * sideways_speed
	velocity.y = rng.randf_range(-0.62, 0.18)
	var angular_velocity := Vector3(
		rng.randf_range(-10.8, 10.8),
		rng.randf_range(-10.8, 10.8),
		rng.randf_range(-10.8, 10.8)
	)
	if angular_velocity.length() < 6.0:
		angular_velocity.y += 6.5 if angular_velocity.y >= 0.0 else -6.5
	return {
		"position": position,
		"quaternion": q,
		"velocity": velocity,
		"angular_velocity": angular_velocity,
	}


func _lane_position(index: int, count: int, target_mode: bool) -> Vector3:
	var cols := int(ceil(float(count) / 2.0))
	var col := index % cols
	var row := int(floor(float(index) / float(cols)))
	var spacing_x := 1.22
	var spacing_z := 1.08
	return Vector3(
		(float(col) - (float(cols) - 1.0) * 0.5) * spacing_x,
		0.0,
		(float(row) - 0.5) * spacing_z
	)


func _make_random_quaternion() -> Quaternion:
	return Basis.from_euler(Vector3(
		rng.randf_range(0.0, TAU),
		rng.randf_range(0.0, TAU),
		rng.randf_range(0.0, TAU)
	)).get_rotation_quaternion().normalized()
