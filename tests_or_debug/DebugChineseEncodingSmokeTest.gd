extends SceneTree
class_name DebugChineseEncodingSmokeTest


const TEXT_EXTENSIONS := [
	"bat",
	"cfg",
	"cmd",
	"csv",
	"gd",
	"gdshader",
	"godot",
	"html",
	"import",
	"ini",
	"json",
	"md",
	"po",
	"pot",
	"ps1",
	"py",
	"shader",
	"sh",
	"svg",
	"toml",
	"tres",
	"tscn",
	"tsv",
	"txt",
	"uid",
	"xml",
	"yaml",
	"yml",
]
const MAX_REPORTED := 80


func _init() -> void:
	print("--- DebugChineseEncodingSmokeTest: start ---")

	var paths: Array[String] = []
	_collect_text_files("res://", paths)

	var unreadable_paths: PackedStringArray = []
	var bom_paths: PackedStringArray = []
	var mojibake_paths: PackedStringArray = []

	for path in paths:
		var bytes := FileAccess.get_file_as_bytes(path)
		if FileAccess.get_open_error() != OK:
			unreadable_paths.append(path)
			continue

		if _has_utf8_bom(bytes):
			bom_paths.append(path)

		var text := bytes.get_string_from_utf8()
		var pattern_name := _first_mojibake_pattern_name(text)
		if pattern_name != "":
			mojibake_paths.append("%s (%s)" % [path, pattern_name])

	var all_passed := unreadable_paths.is_empty() and bom_paths.is_empty() and mojibake_paths.is_empty()
	_report_paths("unreadable text file", unreadable_paths)
	_report_paths("UTF-8 BOM found", bom_paths)
	_report_paths("possible mojibake found", mojibake_paths)

	if all_passed:
		print("PASS: scanned %d text files; UTF-8 clean, no BOM, no mojibake pattern" % [paths.size()])
	else:
		print("FAIL: DebugChineseEncodingSmokeTest")

	print("--- DebugChineseEncodingSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _collect_text_files(root_path: String, output: Array[String]) -> void:
	var dir := DirAccess.open(root_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if _directory_name_excluded(file_name):
			file_name = dir.get_next()
			continue

		var path := root_path.path_join(file_name)
		if dir.current_is_dir():
			_collect_text_files(path, output)
		else:
			var extension := path.get_extension().to_lower()
			if TEXT_EXTENSIONS.has(extension):
				output.append(path)

		file_name = dir.get_next()


func _directory_name_excluded(file_name: String) -> bool:
	return file_name.begins_with(".") or file_name == "__pycache__"


func _has_utf8_bom(bytes: PackedByteArray) -> bool:
	return bytes.size() >= 3 and bytes[0] == 0xef and bytes[1] == 0xbb and bytes[2] == 0xbf


func _first_mojibake_pattern_name(text: String) -> String:
	var patterns := _mojibake_patterns()
	for pattern_name in patterns.keys():
		if text.contains(patterns[pattern_name]):
			return str(pattern_name)
	return ""


func _mojibake_patterns() -> Dictionary:
	return {
		"replacement_char": String.chr(0xFFFD),
		"gbk_punctuation": String.chr(0x951B),
		"gbk_times_symbol": String.chr(0x8133),
		"gbk_common_1": String.chr(0x9416),
		"gbk_common_2": String.chr(0x9369),
		"gbk_common_3": String.chr(0x7EDB),
		"gbk_common_4": String.chr(0x95B2),
		"gbk_common_5": String.chr(0x9483),
		"gbk_common_6": String.chr(0x7EF1),
		"gbk_common_7": String.chr(0x9427),
		"gbk_common_8": String.chr(0x59B2),
		"gbk_common_9": String.chr(0x74D2),
		"gbk_dice_word": String.chr(0x6960) + String.chr(0x677F),
		"gbk_combo_word": String.chr(0x9357) + String.chr(0x62CC),
		"latin_c1_prefix": String.chr(0x00C2),
		"latin_utf8_prefix": String.chr(0x00C3),
		"latin_smart_quote_prefix": String.chr(0x00E2),
		"known_garbled_kou": String.chr(0x951F) + String.chr(0x65A4) + String.chr(0x62F7),
	}


func _report_paths(label: String, paths: PackedStringArray) -> void:
	if paths.is_empty():
		return

	var count := 0
	for path in paths:
		push_error("%s: %s" % [label, path])
		count += 1
		if count >= MAX_REPORTED:
			var remaining := paths.size() - count
			if remaining > 0:
				push_error("%s: ... %d more" % [label, remaining])
			return
