extends RefCounted
class_name ForgeService


const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const ForgePieceDef = preload("res://scripts/data_defs/ForgePieceDef.gd")
const ForgeOperationDef = preload("res://scripts/data_defs/ForgeOperationDef.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const LocService = preload("res://scripts/i18n/LocService.gd")


func can_apply_piece(piece: ForgePieceDef, die: DieState, face_index: int) -> bool:
	if piece == null or die == null:
		return false
	if face_index < 0 or face_index >= die.faces.size():
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
		_apply_operation(operation, face)


func get_face_preview_after_apply(piece: ForgePieceDef, face: FaceState) -> String:
	if face == null:
		return LocService.t(&"UI.INSTALL.NO_FACE")

	var preview_die := DieState.new()
	preview_die.faces.append(face.clone())
	apply_piece(piece, preview_die, 0)
	return _format_face(preview_die.faces[0])


func _apply_operation(operation: ForgeOperationDef, face: FaceState) -> void:
	if operation == null:
		return

	match operation.get_effective_op():
		ForgeOperationDef.OP_SET_PIP:
			face.pip = operation.get_effective_value_int()
		ForgeOperationDef.OP_SET_MATERIAL:
			face.material_id = operation.get_effective_value_id()
		ForgeOperationDef.OP_SET_MARK:
			face.mark_id = operation.get_effective_value_id()
		ForgeOperationDef.OP_SET_RUNE:
			face.rune_id = operation.get_effective_value_id()
		ForgeOperationDef.OP_UPGRADE:
			var delta := operation.get_effective_value_int()
			if delta <= 0:
				delta = 1
			face.level += delta
		ForgeOperationDef.OP_CLEANSE:
			if face.material_id == &"curse":
				face.material_id = &"none"
			if face.mark_id == &"black":
				face.mark_id = &"none"
			if face.rune_id == &"curse":
				face.rune_id = &"none"
		ForgeOperationDef.OP_RESET_FACE:
			face.material_id = &"none"
			face.mark_id = &"none"
			face.rune_id = &"none"
			face.level = 1
		ForgeOperationDef.OP_COPY_FROM_FACE:
			push_warning("ForgeService copy_from_face is reserved for a later stage.")
		_:
			push_warning("Unknown forge operation: %s" % [str(operation.get_effective_op())])


func _format_face(face: FaceState) -> String:
	var lines := PackedStringArray()
	lines.append(str(face.pip))
	if not _is_none_id(face.material_id):
		lines.append(LocService.t(&"UI.FACE.MATERIAL", {"material": LocService.t(LocKeys.material_name_key(face.material_id))}))
	if not _is_none_id(face.mark_id):
		lines.append(LocService.t(&"UI.FACE.IMPRINT", {"imprint": LocService.t(LocKeys.imprint_name_key(face.mark_id))}))
	if not _is_none_id(face.rune_id):
		lines.append(LocService.t(&"UI.FACE.RUNE", {"rune": LocService.t(LocKeys.rune_name_key(face.rune_id))}))
	if face.level > 1:
		lines.append(LocService.t(&"UI.FACE.LEVEL", {"level": face.level}))
	return "\n".join(lines)


func _is_none_id(value: StringName) -> bool:
	return value == &"" or value == &"none"
