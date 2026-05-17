extends RefCounted
class_name RichTextHighlighter


const KEYWORD_COLOR := "a36b00"
const NUMBER_COLOR := "00ff00"
const KEYWORDS := ["基础战力", "终倍率", "倍率"]

static var fallback_font: Font = null


static func score_text_to_bbcode(text: String) -> String:
	var result := PackedStringArray()
	var index := 0
	while index < text.length():
		var keyword := _keyword_at(text, index)
		if keyword != "":
			result.append("[color=#%s]%s[/color]" % [KEYWORD_COLOR, _escape_bbcode(keyword)])
			index += keyword.length()
			continue

		var number_run := _number_run_at(text, index)
		if number_run != "":
			result.append("[color=#%s]%s[/color]" % [NUMBER_COLOR, _escape_bbcode(number_run)])
			index += number_run.length()
			continue

		result.append(_escape_bbcode(text.substr(index, 1)))
		index += 1
	return "".join(result)


static func setup_rich_label(
	label: RichTextLabel,
	text: String,
	font_size: int,
	color: Color,
	font: Font = null
) -> void:
	if label == null:
		return
	_setup_label_base(label, font_size, color, font)
	label.text = score_text_to_bbcode(text)


static func setup_plain_label(
	label: RichTextLabel,
	text: String,
	font_size: int,
	color: Color,
	font: Font = null
) -> void:
	if label == null:
		return
	_setup_label_base(label, font_size, color, font)
	label.text = _escape_bbcode(text)


static func set_rich_text(label: RichTextLabel, text: String) -> void:
	if label == null:
		return
	label.bbcode_enabled = true
	label.text = score_text_to_bbcode(text)


static func _keyword_at(text: String, index: int) -> String:
	for keyword in KEYWORDS:
		if keyword == "倍率" and _text_has_at(text, "倍率面饰", index):
			continue
		if _text_has_at(text, keyword, index):
			return keyword
	return ""


static func _text_has_at(text: String, needle: String, index: int) -> bool:
	if index + needle.length() > text.length():
		return false
	return text.substr(index, needle.length()) == needle


static func _number_run_at(text: String, index: int) -> String:
	var character := text.substr(index, 1)
	if _is_number_prefix(character):
		if index + 1 >= text.length() or not _is_digit(text.substr(index + 1, 1)):
			return ""
		return _collect_number_run(text, index)
	if _is_digit(character):
		return _collect_number_run(text, index)
	return ""


static func _collect_number_run(text: String, start_index: int) -> String:
	var end_index := start_index
	while end_index < text.length():
		var character := text.substr(end_index, 1)
		if not _is_number_body(character):
			break
		end_index += 1
	return text.substr(start_index, end_index - start_index)


static func _is_number_prefix(character: String) -> bool:
	return character == "+" or character == "-" or character == "×" or character == "x" or character == "X"


static func _is_number_body(character: String) -> bool:
	return (
		_is_digit(character)
		or _is_number_prefix(character)
		or character == "."
		or character == "/"
		or character == ","
		or character == "%"
		or character == "％"
	)


static func _is_digit(character: String) -> bool:
	if character.length() != 1:
		return false
	var code := character.unicode_at(0)
	return code >= 48 and code <= 57


static func _escape_bbcode(text: String) -> String:
	return text.replace("[", "\\[").replace("]", "\\]")


static func _setup_label_base(label: RichTextLabel, font_size: int, color: Color, font: Font = null) -> void:
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_font_size_override("bold_font_size", font_size)
	label.add_theme_color_override("default_color", color)
	var resolved_font := _resolved_font(font)
	if resolved_font != null:
		label.add_theme_font_override("normal_font", resolved_font)
		label.add_theme_font_override("bold_font", resolved_font)


static func _resolved_font(font: Font) -> Font:
	if font != null:
		return font
	if fallback_font == null:
		var system_font := SystemFont.new()
		system_font.font_names = PackedStringArray([
			"Microsoft YaHei UI",
			"Microsoft YaHei",
			"Noto Sans CJK SC",
			"Source Han Sans SC",
			"SimHei",
			"Arial",
		])
		fallback_font = system_font
	return fallback_font
