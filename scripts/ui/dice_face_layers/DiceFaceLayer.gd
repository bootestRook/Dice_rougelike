extends RefCounted
class_name DiceFaceLayer


const BLEND_NORMAL := &"normal"
const BLEND_MULTIPLY := &"multiply"
const BLEND_ADD := &"add"
const BLEND_SCREEN := &"screen"
const VALID_BLEND_MODES := [
	BLEND_NORMAL,
	BLEND_MULTIPLY,
	BLEND_ADD,
	BLEND_SCREEN,
]

var texture: Texture2D = null
var color: Color = Color.WHITE
var opacity: float = 1.0
var blend_mode: StringName = BLEND_NORMAL
var uv_offset: Vector2 = Vector2.ZERO
var uv_scale: Vector2 = Vector2.ONE
var rotation: float = 0.0
var order: int = 0
var enabled: bool = true

var normal_mask: Texture2D = null
var height_mask: Texture2D = null
var roughness_mask: Texture2D = null


static func make(
	p_texture: Texture2D,
	p_color: Color = Color.WHITE,
	p_opacity: float = 1.0,
	p_blend_mode: StringName = BLEND_NORMAL,
	p_order: int = 0
) -> DiceFaceLayer:
	var layer := DiceFaceLayer.new()
	layer.texture = p_texture
	layer.color = p_color
	layer.opacity = clampf(p_opacity, 0.0, 1.0)
	layer.blend_mode = normalized_blend_mode(p_blend_mode)
	layer.order = p_order
	return layer


static func normalized_blend_mode(value: StringName) -> StringName:
	if VALID_BLEND_MODES.has(value):
		return value
	return BLEND_NORMAL


func clone() -> DiceFaceLayer:
	var layer := DiceFaceLayer.new()
	layer.texture = texture
	layer.color = color
	layer.opacity = opacity
	layer.blend_mode = blend_mode
	layer.uv_offset = uv_offset
	layer.uv_scale = uv_scale
	layer.rotation = rotation
	layer.order = order
	layer.enabled = enabled
	layer.normal_mask = normal_mask
	layer.height_mask = height_mask
	layer.roughness_mask = roughness_mask
	return layer


func to_dictionary() -> Dictionary:
	return {
		"has_texture": texture != null,
		"texture_path": texture.resource_path if texture != null else "",
		"color": color,
		"opacity": opacity,
		"blend_mode": str(blend_mode),
		"uv_offset": uv_offset,
		"uv_scale": uv_scale,
		"rotation": rotation,
		"order": order,
		"enabled": enabled,
		"has_normal_mask": normal_mask != null,
		"has_height_mask": height_mask != null,
		"has_roughness_mask": roughness_mask != null,
	}
