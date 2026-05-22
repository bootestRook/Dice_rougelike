extends RefCounted
class_name DiceFaceLayerSet


const DiceFaceLayerScript := preload("res://scripts/ui/dice_face_layers/DiceFaceLayer.gd")


var number_layer: DiceFaceLayer = null
var mark_layer: DiceFaceLayer = null
var rarity_layer: DiceFaceLayer = null
var rune_layer: DiceFaceLayer = null
var effect_layer: DiceFaceLayer = null


func set_layer(role: StringName, layer: DiceFaceLayer) -> void:
	match role:
		&"number_layer", &"number":
			number_layer = layer
		&"mark_layer", &"mark":
			mark_layer = layer
		&"rarity_layer", &"rarity":
			rarity_layer = layer
		&"rune_layer", &"rune":
			rune_layer = layer
		&"effect_layer", &"effect":
			effect_layer = layer
		_:
			push_warning("Unknown dice face layer role: %s" % str(role))


func get_layer(role: StringName) -> DiceFaceLayer:
	match role:
		&"number_layer", &"number":
			return number_layer
		&"mark_layer", &"mark":
			return mark_layer
		&"rarity_layer", &"rarity":
			return rarity_layer
		&"rune_layer", &"rune":
			return rune_layer
		&"effect_layer", &"effect":
			return effect_layer
	return null


func get_ordered_layers() -> Array[DiceFaceLayer]:
	var layers: Array[DiceFaceLayer] = []
	for layer in [number_layer, mark_layer, rarity_layer, effect_layer, rune_layer]:
		if layer != null and layer.enabled and layer.texture != null and layer.opacity > 0.0:
			layers.append(layer)
	layers.sort_custom(func(a: DiceFaceLayer, b: DiceFaceLayer) -> bool:
		return a.order < b.order
	)
	return layers


func clone() -> DiceFaceLayerSet:
	var layer_set := DiceFaceLayerSet.new()
	layer_set.number_layer = number_layer.clone() if number_layer != null else null
	layer_set.mark_layer = mark_layer.clone() if mark_layer != null else null
	layer_set.rarity_layer = rarity_layer.clone() if rarity_layer != null else null
	layer_set.rune_layer = rune_layer.clone() if rune_layer != null else null
	layer_set.effect_layer = effect_layer.clone() if effect_layer != null else null
	return layer_set


func to_dictionary() -> Dictionary:
	return {
		"number_layer": number_layer.to_dictionary() if number_layer != null else {},
		"mark_layer": mark_layer.to_dictionary() if mark_layer != null else {},
		"rarity_layer": rarity_layer.to_dictionary() if rarity_layer != null else {},
		"rune_layer": rune_layer.to_dictionary() if rune_layer != null else {},
		"effect_layer": effect_layer.to_dictionary() if effect_layer != null else {},
		"ordered_roles": _ordered_role_names(),
	}


func _ordered_role_names() -> Array[String]:
	var rows: Array[Dictionary] = [
		{"role": "number_layer", "layer": number_layer},
		{"role": "mark_layer", "layer": mark_layer},
		{"role": "rarity_layer", "layer": rarity_layer},
		{"role": "rune_layer", "layer": rune_layer},
		{"role": "effect_layer", "layer": effect_layer},
	]
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var layer_a := a.get("layer") as DiceFaceLayer
		var layer_b := b.get("layer") as DiceFaceLayer
		var order_a := layer_a.order if layer_a != null else 999999
		var order_b := layer_b.order if layer_b != null else 999999
		return order_a < order_b
	)
	var names: Array[String] = []
	for row in rows:
		var layer := row.get("layer") as DiceFaceLayer
		if layer != null and layer.enabled:
			names.append(str(row.get("role", "")))
	return names
