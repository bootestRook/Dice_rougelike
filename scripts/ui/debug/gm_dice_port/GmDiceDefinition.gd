extends RefCounted
class_name GmDiceDefinition


const GmDiceFaceDefinitionScript = preload("res://scripts/ui/debug/gm_dice_port/GmDiceFaceDefinition.gd")


const MATERIAL_STANDARD := &"standard"
const MATERIAL_BRONZE := &"bronze"
const MATERIAL_GOLD := &"gold"
const MATERIAL_IRON := &"iron"
const MATERIAL_GLASS := &"glass"
const MATERIAL_CRYSTAL := &"crystal"
const MATERIAL_REPRO_BLUE := &"repro_blue"
const MATERIAL_REPRO_PURPLE := &"repro_purple"
const MATERIAL_REPRO_CYAN := &"repro_cyan"
const MATERIAL_REPRO_GOLD := &"repro_gold"
const MATERIAL_REPRO_SILVERWHITE := &"repro_silverwhite"
const MATERIAL_IDS := [
	MATERIAL_REPRO_BLUE,
	MATERIAL_REPRO_PURPLE,
	MATERIAL_REPRO_CYAN,
	MATERIAL_REPRO_GOLD,
	MATERIAL_REPRO_SILVERWHITE,
	MATERIAL_STANDARD,
	MATERIAL_BRONZE,
	MATERIAL_GOLD,
	MATERIAL_CRYSTAL,
	MATERIAL_IRON,
	MATERIAL_GLASS,
]

var id: StringName = &"gm_test_d6"
var display_name: String = "测试骰子"
var dice_type: StringName = &"normal"
var description: String = "GM 复刻原型用的标准六面骰。"
var material_id: StringName = MATERIAL_STANDARD
var faces: Array = []
var score_expr: String = "POINT"
var effects: Array[String] = []


static func create_standard_d6() -> GmDiceDefinition:
	var definition := GmDiceDefinition.new()
	definition.id = &"gm_standard_d6"
	definition.display_name = "标准六面骰"
	definition.description = "按 1 到 6 的点数参与测试结算。"
	definition.material_id = MATERIAL_STANDARD
	definition.faces.clear()
	for value in range(1, 7):
		definition.faces.append(GmDiceFaceDefinitionScript.make(value, str(value)))
	return definition


static func create_crystal_d6() -> GmDiceDefinition:
	var definition := create_standard_d6()
	definition.id = &"gm_crystal_d6"
	definition.display_name = "水晶六面骰"
	definition.description = "GM 原型用的水晶骰胚六面骰。"
	definition.material_id = MATERIAL_CRYSTAL
	return definition


static func normalize_material_id(value: StringName) -> StringName:
	match value:
		&"", &"none", &"standard", &"body_standard", MATERIAL_STANDARD:
			return MATERIAL_STANDARD
		&"bronze", &"body_bronze", &"bronze_dice", MATERIAL_BRONZE:
			return MATERIAL_BRONZE
		&"gold", &"body_gold", &"gold_dice", MATERIAL_GOLD:
			return MATERIAL_GOLD
		&"iron", &"body_iron", MATERIAL_IRON:
			return MATERIAL_IRON
		&"glass", &"body_glass", MATERIAL_GLASS:
			return MATERIAL_GLASS
		&"crystal", &"body_crystal", MATERIAL_CRYSTAL:
			return MATERIAL_CRYSTAL
		&"repro_blue", &"star_blue", &"visual_blue", MATERIAL_REPRO_BLUE:
			return MATERIAL_REPRO_BLUE
		&"repro_purple", &"star_purple", &"visual_purple", MATERIAL_REPRO_PURPLE:
			return MATERIAL_REPRO_PURPLE
		&"repro_cyan", &"star_cyan", &"visual_cyan", MATERIAL_REPRO_CYAN:
			return MATERIAL_REPRO_CYAN
		&"repro_gold", &"star_gold", &"visual_gold", MATERIAL_REPRO_GOLD:
			return MATERIAL_REPRO_GOLD
		&"repro_silverwhite", &"star_silverwhite", &"visual_silverwhite", MATERIAL_REPRO_SILVERWHITE:
			return MATERIAL_REPRO_SILVERWHITE
		_:
			return MATERIAL_STANDARD


static func material_name(value: StringName) -> String:
	match normalize_material_id(value):
		MATERIAL_REPRO_BLUE:
			return "星蓝骰胚"
		MATERIAL_REPRO_PURPLE:
			return "星紫骰胚"
		MATERIAL_REPRO_CYAN:
			return "星青骰胚"
		MATERIAL_REPRO_GOLD:
			return "星金骰胚"
		MATERIAL_REPRO_SILVERWHITE:
			return "银白骰胚"
		MATERIAL_BRONZE:
			return "青铜骰胚"
		MATERIAL_GOLD:
			return "黄金骰胚"
		MATERIAL_IRON:
			return "铁质骰胚"
		MATERIAL_GLASS:
			return "玻璃骰胚"
		MATERIAL_CRYSTAL:
			return "水晶骰胚"
		_:
			return "标准骰胚"


static func get_material_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for option_id in MATERIAL_IDS:
		options.append({
			"id": option_id,
			"name": material_name(option_id),
		})
	return options


func get_face(index: int) -> GmDiceFaceDefinition:
	if index < 0 or index >= faces.size():
		return null
	return faces[index] as GmDiceFaceDefinition


func get_face_count() -> int:
	return faces.size()


func get_face_index_for_value(face_value: int) -> int:
	for index in range(faces.size()):
		var face := faces[index] as GmDiceFaceDefinition
		if face != null and face.value == face_value:
			return index
	return -1


func clone() -> GmDiceDefinition:
	var cloned := GmDiceDefinition.new()
	cloned.id = id
	cloned.display_name = display_name
	cloned.dice_type = dice_type
	cloned.description = description
	cloned.material_id = normalize_material_id(material_id)
	cloned.score_expr = score_expr
	cloned.effects = effects.duplicate()
	for face in faces:
		if face != null and face.has_method("clone"):
			cloned.faces.append(face.clone())
	return cloned


func to_dictionary() -> Dictionary:
	var face_rows: Array = []
	for face in faces:
		if face != null and face.has_method("to_dictionary"):
			face_rows.append(face.to_dictionary())
	return {
		"id": str(id),
		"display_name": display_name,
		"dice_type": str(dice_type),
		"description": description,
		"material_id": str(normalize_material_id(material_id)),
		"material_name": material_name(material_id),
		"faces": face_rows,
		"score_expr": score_expr,
		"effects": effects,
	}
