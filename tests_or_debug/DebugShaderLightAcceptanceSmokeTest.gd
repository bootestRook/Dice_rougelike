extends SceneTree
class_name DebugShaderLightAcceptanceSmokeTest


const BASE_DIR := "res://tests_or_debug/visual_acceptance/shader_light"
const TMP_REPORT_DIR := "res://tests_or_debug/tmp_report/visual_acceptance/shader_light"
const CASES_DIR := BASE_DIR + "/cases"
const RUNNER_PATH := BASE_DIR + "/tools/shader_light_acceptance_runner.gd"
const BUILDER_PATH := "res://tools/scene_builders/BuildGmDiceVisualRepro.gd"
const GM_SCENE_PATH := "res://scenes/debug/gm_dice_scene_visual_repro.tscn"
const EXPECTED_CASES := {
	"dice_shader_basic": "shader_material",
	"table_shader_basic": "shader_material",
	"light_effect_basic": "lighting_effect",
}
const EXPECTED_SCENE_NODES := [
	"VA_Camera3D",
	"VA_CameraMarkers",
	"VA_WatermarkLayer",
	"VA_WatermarkLabel",
	"VA_ShaderLightAcceptanceRunner",
]


func _init() -> void:
	print("--- DebugShaderLightAcceptanceSmokeTest: start ---")
	var all_passed := true
	all_passed = _check("runner script exists", FileAccess.file_exists(RUNNER_PATH)) and all_passed
	all_passed = _check("runner script loads", load(RUNNER_PATH) is Script) and all_passed
	all_passed = _check("GM visual repro builder script loads", load(BUILDER_PATH) is Script) and all_passed
	all_passed = _check("windows runner exists", FileAccess.file_exists("res://tests_or_debug/run_shader_light_acceptance.bat")) and all_passed
	all_passed = _check("shell runner exists", FileAccess.file_exists("res://tests_or_debug/run_shader_light_acceptance.sh")) and all_passed
	all_passed = _check("cases directory exists", DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(CASES_DIR))) and all_passed
	all_passed = _check("runner writes local outputs under tmp_report", FileAccess.get_file_as_string(RUNNER_PATH).contains(TMP_REPORT_DIR)) and all_passed
	all_passed = _check_cases() and all_passed
	all_passed = _check_scene_nodes() and all_passed
	print("PASS: DebugShaderLightAcceptanceSmokeTest" if all_passed else "FAIL: DebugShaderLightAcceptanceSmokeTest")
	print("--- DebugShaderLightAcceptanceSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _check_cases() -> bool:
	var ok := true
	for case_id in EXPECTED_CASES.keys():
		var path := CASES_DIR.path_join("%s.json" % case_id)
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		ok = _check("%s case json loads" % case_id, parsed is Dictionary) and ok
		if not (parsed is Dictionary):
			continue
		var data: Dictionary = parsed
		ok = _check("%s case id matches file name" % case_id, str(data.get("id", "")) == case_id) and ok
		ok = _check("%s case type is expected" % case_id, str(data.get("type", "")) == str(EXPECTED_CASES[case_id])) and ok
		ok = _check("%s has camera marker" % case_id, str(data.get("camera_marker", "")) == case_id) and ok
		ok = _check("%s has capture time" % case_id, data.get("capture", {}) is Dictionary and float((data.get("capture", {}) as Dictionary).get("time", 0.0)) > 0.0) and ok
	return ok


func _check_scene_nodes() -> bool:
	var scene := load(GM_SCENE_PATH) as PackedScene
	var ok := _check("GM visual acceptance scene loads", scene != null)
	if scene == null:
		return ok
	var state := scene.get_state()
	for node_name in EXPECTED_SCENE_NODES:
		ok = _check("scene has %s" % node_name, _scene_state_has_node_name(state, node_name)) and ok
	for case_id in EXPECTED_CASES.keys():
		ok = _check("scene has camera marker %s" % case_id, _scene_state_has_node_name(state, case_id)) and ok
	return ok


func _scene_state_has_node_name(state: SceneState, node_name: String) -> bool:
	for node_index in range(state.get_node_count()):
		if str(state.get_node_name(node_index)) == node_name:
			return true
	return false


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
