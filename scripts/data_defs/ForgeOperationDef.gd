extends Resource
class_name ForgeOperationDef


const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")


const OP_SET_PIP := &"set_pip"
const OP_SET_ORNAMENT := &"set_ornament"
const OP_SET_MARK := &"set_mark"
const OP_SET_BODY := &"set_body"
const OP_CLEANSE := &"cleanse"
const OP_RESET_FACE := &"reset_face"
const OP_COPY_FROM_FACE := &"copy_from_face"
const OP_COMBO_UPGRADE := &"combo_upgrade"

const OP_SET_MATERIAL := &"set_material" # deprecated: maps to set_ornament
const OP_SET_RUNE := &"set_rune" # deprecated: disabled in current design
const OP_UPGRADE := &"upgrade" # deprecated: disabled in current design
const OP_ADD_LEVEL := &"add_level" # deprecated alias for upgrade
const OP_COPY_FACE := &"copy_face"
const OP_CLEAR_FACE := &"clear_face"


@export var op: StringName = &""
@export var value_int: int = 0
@export var value_float: float = 0.0
@export var value_id: StringName = &""

@export var operation_type: StringName = &""
@export var pip: int = 0
@export var ornament_id: StringName = &""
@export var body_id: StringName = &""
@export var material_id: StringName = &"" # deprecated: use ornament_id/value_id
@export var mark_id: StringName = &""
@export var rune_id: StringName = &"" # deprecated
@export var level_delta: int = 0 # deprecated


func get_effective_op() -> StringName:
	var configured_op := _configured_op()
	match configured_op:
		OP_SET_MATERIAL:
			return OP_SET_ORNAMENT
		OP_ADD_LEVEL:
			return OP_UPGRADE
		OP_COPY_FACE:
			return OP_COPY_FROM_FACE
		OP_CLEAR_FACE:
			return OP_RESET_FACE
		&"":
			return OP_SET_PIP
		_:
			return configured_op


func get_effective_value_int() -> int:
	var effective_op := get_effective_op()
	if value_int != 0:
		return value_int
	if effective_op == OP_SET_PIP:
		return pip
	if effective_op == OP_UPGRADE:
		return level_delta
	return value_int


func get_effective_value_id() -> StringName:
	var configured_op := _configured_op()
	var raw_value := value_id
	if raw_value == &"":
		match configured_op:
			OP_SET_ORNAMENT:
				raw_value = ornament_id
			OP_SET_MATERIAL:
				raw_value = material_id
			OP_SET_MARK:
				raw_value = mark_id
			OP_SET_BODY:
				raw_value = body_id
			OP_SET_RUNE:
				raw_value = rune_id

	if configured_op == OP_SET_MATERIAL:
		return _legacy_material_to_ornament(raw_value)
	return raw_value


func get_debug_text() -> String:
	return get_display_text()


func get_display_text() -> String:
	match get_effective_op():
		OP_SET_PIP:
			return str(TranslationServer.translate(&"AUTO.TEXT.6DD5779493A0")) % [get_effective_value_int()]
		OP_SET_ORNAMENT:
			return str(TranslationServer.translate(&"AUTO.TEXT.D4AE8B2936A5")) % [DisplayNames.ornament_name(get_effective_value_id())]
		OP_SET_MARK:
			return str(TranslationServer.translate(&"AUTO.TEXT.2E05F223A24E")) % [DisplayNames.mark_name(get_effective_value_id())]
		OP_SET_BODY:
			return str(TranslationServer.translate(&"AUTO.TEXT.37DE58A32A38")) % [DisplayNames.body_name(get_effective_value_id())]
		OP_COMBO_UPGRADE:
			return str(TranslationServer.translate(&"AUTO.TEXT.7933F65671B8")) % [DisplayNames.combo_name(get_effective_value_id())]
		OP_SET_RUNE, OP_UPGRADE:
			return str(TranslationServer.translate(&"AUTO.TEXT.6F063F9A720B"))
		OP_CLEANSE:
			return str(TranslationServer.translate(&"AUTO.TEXT.C9CA5741CA3A"))
		OP_RESET_FACE:
			return str(TranslationServer.translate(&"AUTO.TEXT.45C08F3B5E42"))
		OP_COPY_FROM_FACE:
			return str(TranslationServer.translate(&"AUTO.TEXT.E6CD87AA4E74"))
		_:
			return str(get_effective_op())


func get_text_key() -> StringName:
	var effective_op := get_effective_op()
	match effective_op:
		OP_SET_PIP:
			return &"FORGE_OP.SET_PIP"
		OP_SET_ORNAMENT:
			return &"FORGE_OP.SET_ORNAMENT"
		OP_SET_MARK:
			return &"FORGE_OP.SET_IMPRINT"
		OP_SET_BODY:
			return &"FORGE_OP.SET_BODY"
		OP_CLEANSE:
			return &"FORGE_OP.CLEANSE"
		OP_RESET_FACE:
			return &"FORGE_OP.RESET_FACE"
		OP_COPY_FROM_FACE:
			return &"FORGE_OP.COPY_FROM_FACE"
		OP_COMBO_UPGRADE:
			return &"FORGE_OP.COMBO_UPGRADE"
		_:
			return &"FORGE_OP.UNKNOWN"


func get_text_args() -> Dictionary:
	match get_effective_op():
		OP_SET_PIP:
			return {"pip": get_effective_value_int()}
		OP_SET_ORNAMENT:
			return {"ornament": get_effective_value_id()}
		OP_SET_MARK:
			return {"imprint": LocKeys.imprint_name_key(get_effective_value_id())}
		OP_SET_BODY:
			return {"body": get_effective_value_id()}
		OP_COMBO_UPGRADE:
			return {"combo": get_effective_value_id()}
		_:
			return {"op": str(get_effective_op())}


func is_deprecated_disabled_op() -> bool:
	var configured_op := _configured_op()
	return configured_op == OP_SET_RUNE or configured_op == OP_UPGRADE or configured_op == OP_ADD_LEVEL


func _configured_op() -> StringName:
	if op != &"":
		return op
	if operation_type != &"":
		return operation_type
	return &""


static func _legacy_material_to_ornament(id: StringName) -> StringName:
	return FaceState.normalize_ornament_id(id)
