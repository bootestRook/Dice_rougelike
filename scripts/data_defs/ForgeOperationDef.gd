extends Resource
class_name ForgeOperationDef


const LocKeys = preload("res://scripts/i18n/LocKeys.gd")
const LocService = preload("res://scripts/i18n/LocService.gd")


const OP_SET_PIP := &"set_pip"
const OP_SET_MATERIAL := &"set_material"
const OP_SET_MARK := &"set_mark"
const OP_SET_RUNE := &"set_rune"
const OP_UPGRADE := &"upgrade"
const OP_CLEANSE := &"cleanse"
const OP_RESET_FACE := &"reset_face"
const OP_COPY_FROM_FACE := &"copy_from_face"

const OP_ADD_LEVEL := &"add_level"
const OP_COPY_FACE := &"copy_face"
const OP_CLEAR_FACE := &"clear_face"


@export var op: StringName = &""
@export var value_int: int = 0
@export var value_float: float = 0.0
@export var value_id: StringName = &""

@export var operation_type: StringName = &""
@export var pip: int = 0
@export var material_id: StringName = &""
@export var mark_id: StringName = &""
@export var rune_id: StringName = &""
@export var level_delta: int = 0


func get_effective_op() -> StringName:
	if op != &"":
		return op

	match operation_type:
		OP_ADD_LEVEL:
			return OP_UPGRADE
		OP_COPY_FACE:
			return OP_COPY_FROM_FACE
		OP_CLEAR_FACE:
			return OP_RESET_FACE
		&"":
			return OP_SET_PIP
		_:
			return operation_type


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
	if value_id != &"":
		return value_id

	match get_effective_op():
		OP_SET_MATERIAL:
			return material_id
		OP_SET_MARK:
			return mark_id
		OP_SET_RUNE:
			return rune_id
		_:
			return value_id


func get_debug_text() -> String:
	return get_display_text()


func get_display_text() -> String:
	return LocService.t(get_text_key(), _localized_text_args())


func get_text_key() -> StringName:
	var effective_op := get_effective_op()
	match effective_op:
		OP_SET_PIP:
			return &"FORGE_OP.SET_PIP"
		OP_SET_MATERIAL:
			return &"FORGE_OP.SET_MATERIAL"
		OP_SET_MARK:
			return &"FORGE_OP.SET_IMPRINT"
		OP_SET_RUNE:
			return &"FORGE_OP.SET_RUNE"
		OP_UPGRADE:
			return &"FORGE_OP.UPGRADE"
		OP_CLEANSE:
			return &"FORGE_OP.CLEANSE"
		OP_RESET_FACE:
			return &"FORGE_OP.RESET_FACE"
		OP_COPY_FROM_FACE:
			return &"FORGE_OP.COPY_FROM_FACE"
		_:
			return &"FORGE_OP.UNKNOWN"


func get_text_args() -> Dictionary:
	var effective_op := get_effective_op()
	match effective_op:
		OP_SET_PIP:
			return {"pip": get_effective_value_int()}
		OP_SET_MATERIAL:
			return {"material": LocKeys.material_name_key(get_effective_value_id())}
		OP_SET_MARK:
			return {"imprint": LocKeys.imprint_name_key(get_effective_value_id())}
		OP_SET_RUNE:
			return {"rune": LocKeys.rune_name_key(get_effective_value_id())}
		OP_UPGRADE:
			var delta := get_effective_value_int()
			if delta <= 0:
				delta = 1
			return {"level": delta}
		_:
			return {"op": str(effective_op)}


func _localized_text_args() -> Dictionary:
	var formatted_args := {}
	for arg_key in get_text_args().keys():
		var value = get_text_args()[arg_key]
		if value is StringName:
			formatted_args[arg_key] = LocService.t(value)
		else:
			formatted_args[arg_key] = value
	return formatted_args
