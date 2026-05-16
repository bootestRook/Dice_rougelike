extends RefCounted
class_name ForgeService


const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")


func can_apply_piece(piece: ForgePieceDef, die: DieState, face_index: int) -> bool:
	if piece == null or die == null:
		return false
	if face_index < 0 or face_index >= die.faces.size():
		return false
	for operation in piece.get_operations():
		if operation != null and operation.get_effective_op() == ForgeOperationDef.OP_COMBO_UPGRADE:
			return false
		if operation != null and operation.get_effective_op() == ForgeOperationDef.OP_SET_ORNAMENT:
			if not FaceState.is_valid_face_ornament_id(operation.get_effective_value_id()):
				return false
	return not piece.get_operations().is_empty()


func apply_piece(piece: ForgePieceDef, die: DieState, face_index: int) -> void:
	if piece == null:
		push_warning("ForgeService.apply_piece called with null piece.")
		return
	if die == null:
		push_warning("ForgeService.apply_piece called with null die.")
		return
	if face_index < 0 or face_index >= die.faces.size():
		push_warning("ForgeService.apply_piece face_index out of range: %d" % [face_index])
		return

	var face := die.faces[face_index]
	if face == null:
		push_warning("ForgeService.apply_piece target face is null.")
		return

	for operation in piece.get_operations():
		_apply_operation(operation, face, die, face_index)


func get_face_preview_after_apply(piece: ForgePieceDef, face: FaceState) -> String:
	if face == null:
		return "无骰面"
	return DisplayNames.face_summary(preview_face_after_apply(piece, face))


func preview_face_after_apply(piece: ForgePieceDef, face: FaceState) -> FaceState:
	if face == null:
		return null

	var preview := face.clone()
	if piece == null:
		return preview

	for operation in piece.get_operations():
		_apply_operation(operation, preview)

	return preview


func get_install_warning_text(piece: ForgePieceDef, face: FaceState) -> String:
	if piece == null or face == null:
		return ""

	var warnings := PackedStringArray()
	var preview := face.clone()
	for operation in piece.get_operations():
		if operation == null:
			continue

		match operation.get_effective_op():
			ForgeOperationDef.OP_SET_ORNAMENT:
				_append_slot_warning(
					warnings,
					"面饰",
					preview.get_effective_ornament_id(),
					operation.get_effective_value_id(),
					DisplayNames.ornament_name(preview.get_effective_ornament_id()),
					DisplayNames.ornament_name(operation.get_effective_value_id())
				)
			ForgeOperationDef.OP_SET_MARK:
				_append_slot_warning(
					warnings,
					"印记",
					preview.mark_id,
					operation.get_effective_value_id(),
					DisplayNames.mark_name(preview.mark_id),
					DisplayNames.mark_name(operation.get_effective_value_id())
				)

		_apply_operation(operation, preview)

	return "\n".join(warnings)


func get_install_preview_text(piece: ForgePieceDef, face: FaceState) -> String:
	if face == null:
		return "安装前：\n无骰面\n\n安装后：\n无骰面"

	var preview := preview_face_after_apply(piece, face)
	return "安装前：\n%s\n\n安装后：\n%s" % [
		_face_slot_text(face),
		_face_slot_text(preview),
	]


func face_has_forge_effect(face: FaceState, default_pip: int = 0) -> bool:
	if face == null:
		return false
	if default_pip > 0 and face.pip != default_pip:
		return true
	return (
		not _is_none_id(face.get_effective_ornament_id())
		or not _is_none_id(face.mark_id)
	)


func _apply_operation(operation: ForgeOperationDef, face: FaceState, die: DieState = null, face_index: int = -1) -> void:
	if operation == null:
		return

	match operation.get_effective_op():
		ForgeOperationDef.OP_SET_PIP:
			var new_pip := operation.get_effective_value_int()
			assert(DieState.is_valid_pip(new_pip))
			if not DieState.is_valid_pip(new_pip):
				push_warning("set_pip ignored invalid pip: %d" % [new_pip])
				return
			if die != null and face_index >= 0:
				die.set_face_pip(face_index, new_pip)
			else:
				face.pip = new_pip
		ForgeOperationDef.OP_SET_ORNAMENT:
			var ornament_id := FaceState.normalize_ornament_id(operation.get_effective_value_id())
			if not FaceState.is_valid_face_ornament_id(ornament_id):
				push_warning("orn_negative is an item modifier and cannot be installed on a face.")
				return
			face.ornament_id = ornament_id
			face.material_id = &"none"
		ForgeOperationDef.OP_SET_MARK:
			face.mark_id = FaceState.normalize_mark_id(operation.get_effective_value_id())
		ForgeOperationDef.OP_SET_BODY:
			if die != null:
				push_warning("set_body is reserved and is not installed through the face forge screen.")
			else:
				push_warning("set_body preview is reserved and does not change a face.")
		ForgeOperationDef.OP_SET_RUNE:
			push_warning("set_rune is deprecated and disabled in the current design.")
		ForgeOperationDef.OP_UPGRADE:
			push_warning("upgrade is deprecated and disabled in the current design.")
		ForgeOperationDef.OP_COMBO_UPGRADE:
			push_warning("combo_upgrade is generated as an item and is not installed on a face yet.")
		ForgeOperationDef.OP_CLEANSE:
			if face.ornament_id == &"curse":
				face.ornament_id = FaceState.ORN_NONE
			if face.material_id == &"curse":
				face.material_id = &"none"
			if face.mark_id == &"black":
				face.mark_id = FaceState.MARK_NONE
		ForgeOperationDef.OP_RESET_FACE:
			face.ornament_id = FaceState.ORN_NONE
			face.material_id = &"none"
			face.mark_id = FaceState.MARK_NONE
		ForgeOperationDef.OP_COPY_FROM_FACE:
			push_warning("ForgeService copy_from_face is reserved for a later stage.")
		_:
			push_warning("Unknown forge operation: %s" % [str(operation.get_effective_op())])


func _face_slot_text(face: FaceState) -> String:
	if face == null:
		return "无骰面"

	var lines := PackedStringArray()
	var ornament_id := face.get_effective_ornament_id()
	lines.append("点数：%d" % [face.pip])
	lines.append("面饰：%s" % [DisplayNames.ornament_name(ornament_id)])
	lines.append("印记：%s" % [DisplayNames.mark_name(face.mark_id)])
	return "\n".join(lines)


func _append_slot_warning(
		warnings: PackedStringArray,
		slot_name: String,
		old_id: StringName,
		new_id: StringName,
		old_name: String,
		new_name: String
) -> void:
	if _is_none_id(old_id):
		return
	if old_id == new_id:
		return

	warnings.append("将替换%s：%s → %s" % [slot_name, old_name, new_name])


func _is_none_id(value: StringName) -> bool:
	return value == &"" or value == &"none" or value == FaceState.ORN_NONE or value == FaceState.MARK_NONE
