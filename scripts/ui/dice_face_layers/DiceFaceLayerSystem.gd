extends RefCounted
class_name DiceFaceLayerSystem


const DiceFaceLayerScript := preload("res://scripts/ui/dice_face_layers/DiceFaceLayer.gd")
const DiceFaceLayerSetScript := preload("res://scripts/ui/dice_face_layers/DiceFaceLayerSet.gd")

const DEFAULT_FACE_COUNT := 6
const DEFAULT_CELL_SIZE := 128
const ATLAS_COLS := 3
const ATLAS_ROWS := 2
const FACE_INDEX_TO_ATLAS_VALUE := [1, 6, 5, 2, 3, 4]

const NUMBER_COLOR := Color(0.960784, 0.949020, 0.909804, 1.0)
const MARK_COLORS := {
	&"red": Color(1.0, 0.22, 0.16, 1.0),
	&"mark_red": Color(1.0, 0.22, 0.16, 1.0),
	&"blue": Color(0.25, 0.62, 1.0, 1.0),
	&"mark_blue": Color(0.25, 0.62, 1.0, 1.0),
	&"purple": Color(0.82, 0.42, 1.0, 1.0),
	&"mark_purple": Color(0.82, 0.42, 1.0, 1.0),
	&"gold": Color(1.0, 0.80, 0.25, 1.0),
	&"mark_gold": Color(1.0, 0.80, 0.25, 1.0),
	&"white": Color(0.96, 0.98, 1.0, 1.0),
	&"mark_white": Color(0.96, 0.98, 1.0, 1.0),
}

const DIGIT_SEGMENTS := {
	"0": ["a", "b", "c", "d", "e", "f"],
	"1": ["b", "c"],
	"2": ["a", "b", "g", "e", "d"],
	"3": ["a", "b", "g", "c", "d"],
	"4": ["f", "g", "b", "c"],
	"5": ["a", "f", "g", "c", "d"],
	"6": ["a", "f", "g", "c", "d", "e"],
	"7": ["a", "b", "c"],
	"8": ["a", "b", "c", "d", "e", "f", "g"],
	"9": ["a", "b", "c", "d", "f", "g"],
}

var face_count: int = DEFAULT_FACE_COUNT
var cell_size: int = DEFAULT_CELL_SIZE
var face_sets: Array[DiceFaceLayerSet] = []
var face_albedo_texture: Texture2D = null
var normal_mask_texture: Texture2D = null
var height_mask_texture: Texture2D = null
var roughness_mask_texture: Texture2D = null


func _init(p_face_count: int = DEFAULT_FACE_COUNT, p_cell_size: int = DEFAULT_CELL_SIZE) -> void:
	face_count = maxi(1, p_face_count)
	cell_size = maxi(16, p_cell_size)
	face_sets.clear()
	for _index in range(face_count):
		face_sets.append(DiceFaceLayerSet.new())


static func from_face_rows(face_rows: Array, options: Dictionary = {}) -> DiceFaceLayerSystem:
	var system := DiceFaceLayerSystem.new(face_rows.size() if not face_rows.is_empty() else DEFAULT_FACE_COUNT, int(options.get("cell_size", DEFAULT_CELL_SIZE)))
	system.configure_from_face_rows(face_rows, options)
	return system


static func make_number_layer(label: String, color: Color = NUMBER_COLOR, order: int = 10) -> DiceFaceLayer:
	var layer := DiceFaceLayer.make(make_number_texture(label), color, 0.92, DiceFaceLayer.BLEND_NORMAL, order)
	layer.uv_scale = Vector2(0.72, 0.72)
	return layer


static func make_mark_layer(mark_id: StringName, order: int = 30) -> DiceFaceLayer:
	var layer := DiceFaceLayer.make(
		make_mark_texture(mark_id),
		mark_color(mark_id),
		0.82,
		DiceFaceLayer.BLEND_SCREEN,
		order
	)
	layer.uv_offset = Vector2(0.23, -0.23)
	layer.uv_scale = Vector2(0.34, 0.34)
	return layer


static func make_number_texture(label: String, size: int = DEFAULT_CELL_SIZE) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 0.0))
	var text := label.strip_edges()
	if text.is_empty():
		return ImageTexture.create_from_image(image)
	var chars: Array[String] = []
	for index in range(text.length()):
		var ch := text.substr(index, 1)
		if DIGIT_SEGMENTS.has(ch) or ch == "-":
			chars.append(ch)
	if chars.is_empty():
		chars.append("?")
	var count := mini(chars.size(), 3)
	var total_width := 0.82
	var digit_width := total_width / float(count)
	var start_x := 0.5 - total_width * 0.5
	for index in range(count):
		var rect := Rect2(
			Vector2(start_x + digit_width * float(index), 0.11),
			Vector2(digit_width * 0.92, 0.78)
		)
		_draw_digit(image, chars[index], rect)
	return ImageTexture.create_from_image(image)


static func make_mark_texture(mark_id: StringName, size: int = DEFAULT_CELL_SIZE) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 1.0, 1.0, 0.0))
	var normalized := _normalized_mark_id(mark_id)
	for y in range(size):
		for x in range(size):
			var uv := Vector2((float(x) + 0.5) / float(size), (float(y) + 0.5) / float(size))
			var centered := uv - Vector2(0.5, 0.5)
			var alpha := 0.0
			match normalized:
				&"red", &"mark_red":
					var distance := centered.length()
					alpha = _soft_band(distance, 0.25, 0.045, 0.030)
				&"blue", &"mark_blue":
					var diamond := absf(centered.x) + absf(centered.y)
					alpha = 1.0 - _smoothstep(0.30, 0.37, diamond)
				&"purple", &"mark_purple":
					var cross := maxf(_soft_band(absf(centered.x), 0.0, 0.035, 0.035), _soft_band(absf(centered.y), 0.0, 0.035, 0.035))
					var diag := maxf(_soft_band(absf(centered.x - centered.y), 0.0, 0.030, 0.034), _soft_band(absf(centered.x + centered.y), 0.0, 0.030, 0.034))
					alpha = clampf(maxf(cross, diag) * (1.0 - _smoothstep(0.26, 0.38, centered.length())), 0.0, 1.0)
				&"gold", &"mark_gold":
					var ring_distance := centered.length()
					alpha = maxf(_soft_band(ring_distance, 0.24, 0.030, 0.024), 1.0 - _smoothstep(0.055, 0.095, ring_distance))
				&"white", &"mark_white":
					alpha = 1.0 - _smoothstep(0.22, 0.29, centered.length())
				_:
					alpha = 0.0
			if alpha > 0.0:
				image.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)


static func mark_color(mark_id: StringName) -> Color:
	return MARK_COLORS.get(_normalized_mark_id(mark_id), Color(1.0, 0.80, 0.25, 1.0))


func configure_from_face_rows(face_rows: Array, options: Dictionary = {}) -> void:
	var number_color: Color = options.get("number_color", NUMBER_COLOR)
	var enable_numbers := bool(options.get("enable_numbers", true))
	var enable_marks := bool(options.get("enable_marks", true))
	for index in range(face_sets.size()):
		var label := str(index + 1)
		var mark_id := &"none"
		var existing_set: DiceFaceLayerSet = null
		if index < face_rows.size():
			var row = face_rows[index]
			if row is Dictionary:
				label = str((row as Dictionary).get("label", label))
				mark_id = StringName(str((row as Dictionary).get("mark_id", "none")))
				existing_set = (row as Dictionary).get("layer_set") as DiceFaceLayerSet
			elif row != null:
				if row.get("label") != null:
					label = str(row.get("label"))
				if row.get("mark_id") != null:
					mark_id = StringName(str(row.get("mark_id")))
				if row.get("layer_set") != null:
					existing_set = row.get("layer_set") as DiceFaceLayerSet
		var layer_set := existing_set.clone() if existing_set != null else DiceFaceLayerSet.new()
		if enable_numbers and layer_set.number_layer == null:
			layer_set.number_layer = make_number_layer(label, number_color)
		if enable_marks and layer_set.mark_layer == null and not _is_empty_mark(mark_id):
			layer_set.mark_layer = make_mark_layer(mark_id)
		face_sets[index] = layer_set


func set_face_layer(face_index: int, role: StringName, layer: DiceFaceLayer) -> void:
	if not _is_valid_face_index(face_index):
		push_warning("DiceFaceLayerSystem.set_face_layer face_index out of range: %d" % face_index)
		return
	face_sets[face_index].set_layer(role, layer)


func get_face_layer(face_index: int, role: StringName) -> DiceFaceLayer:
	if not _is_valid_face_index(face_index):
		return null
	return face_sets[face_index].get_layer(role)


func bake_face_albedo_texture() -> Texture2D:
	var image := bake_face_albedo_image()
	face_albedo_texture = ImageTexture.create_from_image(image)
	return face_albedo_texture


func bake_face_albedo_image() -> Image:
	var image := Image.create(cell_size * ATLAS_COLS, cell_size * ATLAS_ROWS, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	for face_index in range(face_sets.size()):
		var cell_rect := _cell_rect_for_face_index(face_index)
		_bake_face_set(image, cell_rect, face_sets[face_index])
	return image


func get_face_albedo_texture() -> Texture2D:
	if face_albedo_texture == null:
		return bake_face_albedo_texture()
	return face_albedo_texture


func get_normal_mask_texture() -> Texture2D:
	return normal_mask_texture


func get_height_mask_texture() -> Texture2D:
	return height_mask_texture


func get_roughness_mask_texture() -> Texture2D:
	return roughness_mask_texture


func to_dictionary() -> Dictionary:
	var faces: Array[Dictionary] = []
	for index in range(face_sets.size()):
		faces.append({
			"face_index": index,
			"atlas_value": atlas_value_for_face_index(index),
			"layers": face_sets[index].to_dictionary(),
		})
	return {
		"face_count": face_count,
		"cell_size": cell_size,
		"atlas_size": Vector2i(cell_size * ATLAS_COLS, cell_size * ATLAS_ROWS),
		"has_face_albedo_texture": face_albedo_texture != null,
		"has_normal_mask_texture": normal_mask_texture != null,
		"has_height_mask_texture": height_mask_texture != null,
		"has_roughness_mask_texture": roughness_mask_texture != null,
		"faces": faces,
	}


static func atlas_value_for_face_index(face_index: int) -> int:
	if face_index >= 0 and face_index < FACE_INDEX_TO_ATLAS_VALUE.size():
		return int(FACE_INDEX_TO_ATLAS_VALUE[face_index])
	return clampi(face_index + 1, 1, DEFAULT_FACE_COUNT)


static func _draw_digit(image: Image, ch: String, rect: Rect2) -> void:
	var segments: Array = DIGIT_SEGMENTS.get(ch, [])
	if ch == "-":
		segments = ["g"]
	if segments.is_empty():
		segments = ["a", "d", "g"]
	var size := image.get_width()
	for y in range(size):
		for x in range(size):
			var uv := Vector2((float(x) + 0.5) / float(size), (float(y) + 0.5) / float(size))
			if not rect.has_point(uv):
				continue
			var local := Vector2(
				(uv.x - rect.position.x) / rect.size.x,
				(uv.y - rect.position.y) / rect.size.y
			)
			var alpha := 0.0
			for segment in segments:
				alpha = maxf(alpha, _segment_alpha(local, str(segment)))
			if alpha <= 0.0:
				continue
			var previous := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, maxf(previous.a, alpha)))


static func _segment_alpha(local: Vector2, segment: String) -> float:
	var rect := _segment_rect(segment)
	var center := rect.position + rect.size * 0.5
	var half := rect.size * 0.5
	var d := Vector2(absf(local.x - center.x), absf(local.y - center.y)) - half
	var outside := Vector2(maxf(d.x, 0.0), maxf(d.y, 0.0)).length()
	return 1.0 - _smoothstep(0.0, 0.042, outside)


static func _segment_rect(segment: String) -> Rect2:
	match segment:
		"a":
			return Rect2(0.24, 0.08, 0.52, 0.125)
		"b":
			return Rect2(0.68, 0.17, 0.13, 0.31)
		"c":
			return Rect2(0.68, 0.52, 0.13, 0.31)
		"d":
			return Rect2(0.24, 0.79, 0.52, 0.125)
		"e":
			return Rect2(0.19, 0.52, 0.13, 0.31)
		"f":
			return Rect2(0.19, 0.17, 0.13, 0.31)
		"g":
			return Rect2(0.24, 0.435, 0.52, 0.13)
	return Rect2(0.24, 0.435, 0.52, 0.13)


func _bake_face_set(atlas: Image, cell_rect: Rect2i, layer_set: DiceFaceLayerSet) -> void:
	if layer_set == null:
		return
	for layer in layer_set.get_ordered_layers():
		_composite_layer(atlas, cell_rect, layer)


func _composite_layer(atlas: Image, cell_rect: Rect2i, layer: DiceFaceLayer) -> void:
	var source_image := _image_from_texture(layer.texture)
	if source_image == null or source_image.is_empty():
		return
	if source_image.get_format() != Image.FORMAT_RGBA8:
		source_image.convert(Image.FORMAT_RGBA8)
	for y in range(cell_rect.position.y, cell_rect.position.y + cell_rect.size.y):
		for x in range(cell_rect.position.x, cell_rect.position.x + cell_rect.size.x):
			var face_uv := Vector2(
				(float(x - cell_rect.position.x) + 0.5) / float(cell_rect.size.x),
				(float(y - cell_rect.position.y) + 0.5) / float(cell_rect.size.y)
			)
			var layer_uv := _layer_sample_uv(face_uv, layer)
			if layer_uv.x < 0.0 or layer_uv.x > 1.0 or layer_uv.y < 0.0 or layer_uv.y > 1.0:
				continue
			var src := _sample_image(source_image, layer_uv)
			src = Color(src.r * layer.color.r, src.g * layer.color.g, src.b * layer.color.b, src.a * layer.color.a * layer.opacity)
			if src.a <= 0.0:
				continue
			var dst := atlas.get_pixel(x, y)
			atlas.set_pixel(x, y, _blend_pixel(dst, src, layer.blend_mode))


func _layer_sample_uv(face_uv: Vector2, layer: DiceFaceLayer) -> Vector2:
	var centered := face_uv - Vector2(0.5, 0.5) - layer.uv_offset
	if absf(layer.rotation) > 0.00001:
		var c := cos(-layer.rotation)
		var s := sin(-layer.rotation)
		centered = Vector2(centered.x * c - centered.y * s, centered.x * s + centered.y * c)
	var scale := Vector2(maxf(absf(layer.uv_scale.x), 0.001), maxf(absf(layer.uv_scale.y), 0.001))
	return Vector2(centered.x / scale.x, centered.y / scale.y) + Vector2(0.5, 0.5)


func _cell_rect_for_face_index(face_index: int) -> Rect2i:
	var value := atlas_value_for_face_index(face_index)
	var atlas_index := clampi(value - 1, 0, ATLAS_COLS * ATLAS_ROWS - 1)
	var col := atlas_index % ATLAS_COLS
	var row := int(atlas_index / ATLAS_COLS)
	return Rect2i(col * cell_size, row * cell_size, cell_size, cell_size)


func _is_valid_face_index(face_index: int) -> bool:
	return face_index >= 0 and face_index < face_sets.size()


static func _image_from_texture(texture: Texture2D) -> Image:
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null:
		return null
	return image


static func _sample_image(image: Image, uv: Vector2) -> Color:
	var x := clampi(roundi(uv.x * float(image.get_width() - 1)), 0, image.get_width() - 1)
	var y := clampi(roundi(uv.y * float(image.get_height() - 1)), 0, image.get_height() - 1)
	return image.get_pixel(x, y)


static func _blend_pixel(dst: Color, src: Color, blend_mode: StringName) -> Color:
	var mode := DiceFaceLayer.normalized_blend_mode(blend_mode)
	var src_alpha := clampf(src.a, 0.0, 1.0)
	var dst_alpha := clampf(dst.a, 0.0, 1.0)
	var blended_rgb := src
	match mode:
		DiceFaceLayer.BLEND_MULTIPLY:
			blended_rgb = Color(dst.r * src.r, dst.g * src.g, dst.b * src.b, src.a)
		DiceFaceLayer.BLEND_ADD:
			blended_rgb = Color(minf(dst.r + src.r, 1.0), minf(dst.g + src.g, 1.0), minf(dst.b + src.b, 1.0), src.a)
		DiceFaceLayer.BLEND_SCREEN:
			blended_rgb = Color(1.0 - (1.0 - dst.r) * (1.0 - src.r), 1.0 - (1.0 - dst.g) * (1.0 - src.g), 1.0 - (1.0 - dst.b) * (1.0 - src.b), src.a)
		_:
			blended_rgb = src
	var out_alpha := src_alpha + dst_alpha * (1.0 - src_alpha)
	if out_alpha <= 0.00001:
		return Color(0.0, 0.0, 0.0, 0.0)
	var out_rgb := Color(
		(blended_rgb.r * src_alpha + dst.r * dst_alpha * (1.0 - src_alpha)) / out_alpha,
		(blended_rgb.g * src_alpha + dst.g * dst_alpha * (1.0 - src_alpha)) / out_alpha,
		(blended_rgb.b * src_alpha + dst.b * dst_alpha * (1.0 - src_alpha)) / out_alpha,
		out_alpha
	)
	return out_rgb


static func _normalized_mark_id(mark_id: StringName) -> StringName:
	match mark_id:
		&"red", &"mark_red":
			return &"mark_red"
		&"blue", &"mark_blue":
			return &"mark_blue"
		&"purple", &"mark_purple":
			return &"mark_purple"
		&"gold", &"mark_gold":
			return &"mark_gold"
		&"white", &"mark_white":
			return &"mark_white"
	return &"none"


static func _is_empty_mark(mark_id: StringName) -> bool:
	return [&"", &"none", &"mark_none"].has(mark_id)


static func _soft_band(value: float, center: float, half_width: float, feather: float) -> float:
	return 1.0 - _smoothstep(half_width, half_width + feather, absf(value - center))


static func _smoothstep(edge0: float, edge1: float, value: float) -> float:
	if is_equal_approx(edge0, edge1):
		return 0.0 if value < edge0 else 1.0
	var t := clampf((value - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
