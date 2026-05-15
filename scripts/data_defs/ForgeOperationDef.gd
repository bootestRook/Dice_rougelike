extends Resource
class_name ForgeOperationDef


const OP_SET_PIP := &"set_pip"
const OP_SET_MATERIAL := &"set_material"
const OP_SET_MARK := &"set_mark"
const OP_SET_RUNE := &"set_rune"
const OP_ADD_LEVEL := &"add_level"
const OP_COPY_FACE := &"copy_face"
const OP_CLEAR_FACE := &"clear_face"


@export var operation_type: StringName = OP_SET_PIP
@export var pip: int = 0
@export var material_id: StringName = &""
@export var mark_id: StringName = &""
@export var rune_id: StringName = &""
@export var level_delta: int = 0
