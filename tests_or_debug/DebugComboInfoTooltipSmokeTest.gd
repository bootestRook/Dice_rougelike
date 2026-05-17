extends SceneTree
class_name DebugComboInfoTooltipSmokeTest


func _init() -> void:
	print("--- DebugComboInfoTooltipSmokeTest: start ---")

	var all_passed := true
	var scene := load("res://scenes/battle/components/ComboInfoPopup.tscn")
	var popup = scene.instantiate()
	root.add_child(popup)

	await process_frame
	await process_frame

	popup.show_ornament_tab(&"orn_stay")
	await process_frame
	all_passed = _check("ornament rows do not expose tooltips", _effect_rows_hide_tooltips(popup)) and all_passed
	all_passed = _check("ornament rows do not expose internal ids", _effect_rows_hide_internal_ids(popup)) and all_passed
	all_passed = _check("ornament rows use unified rich text controls", _effect_rows_use_unified_rich_text(popup)) and all_passed

	popup.show_mark_tab(&"mark_red")
	await process_frame
	all_passed = _check("mark rows do not expose tooltips", _effect_rows_hide_tooltips(popup)) and all_passed
	all_passed = _check("mark rows do not expose internal ids", _effect_rows_hide_internal_ids(popup)) and all_passed
	all_passed = _check("mark rows use unified rich text controls", _effect_rows_use_unified_rich_text(popup)) and all_passed

	popup.queue_free()
	print("PASS: DebugComboInfoTooltipSmokeTest" if all_passed else "FAIL: DebugComboInfoTooltipSmokeTest")
	print("--- DebugComboInfoTooltipSmokeTest: end ---")
	quit(0 if all_passed else 1)


func _effect_rows_hide_tooltips(popup: Node) -> bool:
	var rows := _effect_rows(popup)
	if rows.is_empty():
		return false
	for row in rows:
		if row is Control and (row as Control).tooltip_text != "":
			return false
	return true


func _effect_rows_hide_internal_ids(popup: Node) -> bool:
	var rows := _effect_rows(popup)
	if rows.is_empty():
		return false
	for row in rows:
		var visible_text := _collect_visible_text(row)
		if _contains_internal_id(visible_text):
			return false
	return true


func _effect_rows_use_unified_rich_text(popup: Node) -> bool:
	var rows := _effect_rows(popup)
	if rows.is_empty():
		return false
	for row in rows:
		var rich_count := _rich_text_label_count(row)
		var plain_count := _plain_label_count(row)
		if rich_count < 2 or plain_count != 0:
			return false
	return true


func _effect_rows(popup: Node) -> Array:
	var container = popup.get_node_or_null("%InfoRowsContainer")
	if container == null:
		return []
	return container.get_children()


func _collect_visible_text(node: Node) -> String:
	var parts := PackedStringArray()
	if node is Label:
		parts.append((node as Label).text)
	elif node is RichTextLabel:
		parts.append((node as RichTextLabel).text)
	elif node is Button:
		parts.append((node as Button).text)
	for child in node.get_children():
		parts.append(_collect_visible_text(child))
	return "\n".join(parts)


func _rich_text_label_count(node: Node) -> int:
	var count := 1 if node is RichTextLabel else 0
	for child in node.get_children():
		count += _rich_text_label_count(child)
	return count


func _plain_label_count(node: Node) -> int:
	var count := 1 if node is Label and not (node is RichTextLabel) else 0
	for child in node.get_children():
		count += _plain_label_count(child)
	return count


func _contains_internal_id(text: String) -> bool:
	return (
		text.contains("orn_")
		or text.contains("mark_")
		or text.contains("id:")
		or text.contains("material")
		or text.contains("rune")
		or text.contains("level")
	)


func _check(label: String, passed: bool) -> bool:
	var status := "PASS" if passed else "FAIL"
	print("%s: %s" % [status, label])
	if not passed:
		push_error(label)
	return passed
