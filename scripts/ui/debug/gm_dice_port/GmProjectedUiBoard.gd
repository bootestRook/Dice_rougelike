extends Node3D
class_name GmProjectedUiBoard


const LEFT_VIEWPORT_SIZE := Vector2i(360, 720)
const RELIC_VIEWPORT_SIZE := Vector2i(760, 220)
const ITEM_VIEWPORT_SIZE := Vector2i(460, 220)
const BOARD_THICKNESS := 0.32
const EDGE_WIDTH := 0.13
const EDGE_HEIGHT := 0.13


var flat_mode := false
var panels := {}


func _ready() -> void:
	ensure_built()


func ensure_built() -> void:
	if not panels.is_empty():
		return
	name = "GmProjectedUiBoard"
	_add_projected_panel(
		"left_info",
		"ProjectedLeftInfoPanel3D",
		LEFT_VIEWPORT_SIZE,
		Vector2(2.45, 4.90),
		Vector3(-6.30, 2.65, -0.55),
		Vector3(82.0, 0.0, 0.0),
		Vector3(-5.20, 0.24, -0.20),
		Vector3(0.0, -12.0, 0.0),
		Color(0.00, 0.70, 0.56, 1.0),
		_build_left_info_ui()
	)
	_add_projected_panel(
		"relic_bar",
		"ProjectedRelicBarPanel3D",
		RELIC_VIEWPORT_SIZE,
		Vector2(5.62, 1.62),
		Vector3(-1.35, 3.20, -3.55),
		Vector3(82.0, 0.0, 0.0),
		Vector3(-1.30, 0.30, -3.15),
		Vector3(0.0, 7.5, 0.0),
		Color(0.78, 0.24, 1.0, 1.0),
		_build_relic_bar_ui()
	)
	_add_projected_panel(
		"item_bar",
		"ProjectedItemBarPanel3D",
		ITEM_VIEWPORT_SIZE,
		Vector2(3.36, 1.62),
		Vector3(4.02, 3.12, -3.40),
		Vector3(82.0, 0.0, 0.0),
		Vector3(4.08, 0.34, -3.25),
		Vector3(0.0, -8.0, 0.0),
		Color(0.00, 0.88, 0.72, 1.0),
		_build_item_bar_ui()
	)
	set_board_visible(true)
	set_flat_mode(false)


func set_board_visible(enabled: bool) -> void:
	visible = enabled


func is_board_visible() -> bool:
	return visible


func set_flat_mode(enabled: bool) -> void:
	flat_mode = enabled
	for id in panels.keys():
		var panel: Dictionary = panels[id]
		var root := panel.get("root") as Node3D
		if root == null:
			continue
		root.position = panel["flat_position"] if flat_mode else panel["floating_position"]
		root.rotation_degrees = panel["flat_rotation"] if flat_mode else panel["floating_rotation"]


func is_flat_mode() -> bool:
	return flat_mode


func automation_get_snapshot() -> Dictionary:
	var panel_snapshots := {}
	var total_controls := 0
	var all_ready := panels.size() >= 3
	for id in panels.keys():
		var panel: Dictionary = panels[id]
		var root := panel.get("root") as Node3D
		var viewport := panel.get("viewport") as SubViewport
		var plane := panel.get("plane") as MeshInstance3D
		var ui_root_name := str(panel.get("ui_root_name", ""))
		var ui_root := viewport.get_node_or_null(ui_root_name) if viewport != null else null
		var material := plane.material_override as StandardMaterial3D if plane != null else null
		var control_count := _count_controls(ui_root)
		total_controls += control_count
		var texture_valid := material != null and material.albedo_texture != null
		all_ready = all_ready and root != null and viewport != null and plane != null and texture_valid and ui_root != null
		panel_snapshots[id] = {
			"ready": root != null and viewport != null and plane != null and texture_valid and ui_root != null,
			"visible": visible and root != null and root.visible,
			"viewport_size": viewport.size if viewport != null else Vector2i.ZERO,
			"world_size": panel.get("world_size", Vector2.ZERO),
			"board_thickness": BOARD_THICKNESS,
			"edge_height": EDGE_HEIGHT,
			"world_position": root.position if root != null else Vector3.ZERO,
			"world_rotation_degrees": root.rotation_degrees if root != null else Vector3.ZERO,
			"texture_valid": texture_valid,
			"ui_root_exists": ui_root != null,
			"control_count": control_count,
		}
	return {
		"ready": all_ready,
		"visible": visible,
		"flat": flat_mode,
		"panel_count": panels.size(),
		"panels": panel_snapshots,
		"control_count": total_controls,
		"real_checkbox_exists": _find_control_named("ProjectedUiRealCheckBox") != null,
		"left_info_ready": bool((panel_snapshots.get("left_info", {}) as Dictionary).get("ready", false)),
		"relic_bar_ready": bool((panel_snapshots.get("relic_bar", {}) as Dictionary).get("ready", false)),
		"item_bar_ready": bool((panel_snapshots.get("item_bar", {}) as Dictionary).get("ready", false)),
	}


func _add_projected_panel(
	id: String,
	node_name: String,
	viewport_size: Vector2i,
	world_size: Vector2,
	floating_position: Vector3,
	floating_rotation: Vector3,
	flat_position: Vector3,
	flat_rotation: Vector3,
	edge_color: Color,
	ui_root: Control
) -> void:
	var panel_root := Node3D.new()
	panel_root.name = node_name
	add_child(panel_root)

	var viewport := SubViewport.new()
	viewport.name = "%sViewport" % node_name
	viewport.size = viewport_size
	viewport.transparent_bg = true
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.gui_disable_input = false
	panel_root.add_child(viewport)
	viewport.add_child(ui_root)

	var backing := MeshInstance3D.new()
	backing.name = "%sBackPlate" % node_name
	var back_box := BoxMesh.new()
	back_box.size = Vector3(world_size.x + EDGE_WIDTH * 2.4, BOARD_THICKNESS, world_size.y + EDGE_WIDTH * 2.4)
	backing.mesh = back_box
	backing.position = Vector3(0.0, -BOARD_THICKNESS * 0.5, 0.0)
	backing.material_override = _make_solid_material(Color(0.018, 0.022, 0.030, 1.0), 0.78, 0.0)
	backing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel_root.add_child(backing)
	_add_edge_rails(panel_root, node_name, world_size, edge_color)

	var plane := MeshInstance3D.new()
	plane.name = "%sPlane" % node_name
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = world_size
	plane.mesh = plane_mesh
	plane.position = Vector3(0.0, EDGE_HEIGHT * 0.5 + 0.012, 0.0)
	plane.material_override = _make_viewport_material(viewport)
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel_root.add_child(plane)

	panels[id] = {
		"root": panel_root,
		"viewport": viewport,
		"plane": plane,
		"backing": backing,
		"ui_root_name": ui_root.name,
		"world_size": world_size,
		"floating_position": floating_position,
		"floating_rotation": floating_rotation,
		"flat_position": flat_position,
		"flat_rotation": flat_rotation,
	}


func _add_edge_rails(parent: Node3D, node_name: String, world_size: Vector2, edge_color: Color) -> void:
	var material := _make_solid_material(edge_color.darkened(0.18), 0.58, 0.08)
	var top_z := -world_size.y * 0.5 - EDGE_WIDTH * 0.5
	var bottom_z := world_size.y * 0.5 + EDGE_WIDTH * 0.5
	var left_x := -world_size.x * 0.5 - EDGE_WIDTH * 0.5
	var right_x := world_size.x * 0.5 + EDGE_WIDTH * 0.5
	_add_edge_box(parent, "%sBackRail" % node_name, Vector3(0.0, EDGE_HEIGHT * 0.5, top_z), Vector3(world_size.x + EDGE_WIDTH * 2.0, EDGE_HEIGHT, EDGE_WIDTH), material)
	_add_edge_box(parent, "%sFrontRail" % node_name, Vector3(0.0, EDGE_HEIGHT * 0.5, bottom_z), Vector3(world_size.x + EDGE_WIDTH * 2.0, EDGE_HEIGHT, EDGE_WIDTH), material)
	_add_edge_box(parent, "%sLeftRail" % node_name, Vector3(left_x, EDGE_HEIGHT * 0.5, 0.0), Vector3(EDGE_WIDTH, EDGE_HEIGHT, world_size.y), material)
	_add_edge_box(parent, "%sRightRail" % node_name, Vector3(right_x, EDGE_HEIGHT * 0.5, 0.0), Vector3(EDGE_WIDTH, EDGE_HEIGHT, world_size.y), material)


func _add_edge_box(parent: Node3D, node_name: String, local_position: Vector3, size: Vector3, material: Material) -> void:
	var rail := MeshInstance3D.new()
	rail.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	rail.mesh = mesh
	rail.position = local_position
	rail.material_override = material
	rail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(rail)


func _build_left_info_ui() -> Control:
	var root := _make_root("ProjectedLeftInfoUiRoot", LEFT_VIEWPORT_SIZE)
	var panel := _make_panel("ProjectedLeftInfoMainPanel", Color(0.020, 0.045, 0.050, 0.97), Color(0.00, 0.88, 0.66, 0.95), 5, 10)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(panel)

	var margin := _make_margin(18, 18, 18, 18)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.name = "ProjectedLeftInfoRows"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 12)
	margin.add_child(rows)

	var title := _make_label("战斗信息", 34, Color(0.94, 1.00, 0.95, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(title)
	rows.add_child(_make_stat_card("至少得分", "100", Color(0.95, 0.98, 0.82, 1.0)))
	rows.add_child(_make_stat_card("本场总分", "27", Color(0.78, 0.94, 1.00, 1.0)))
	rows.add_child(_make_formula_card())
	rows.add_child(_make_stat_card("回合", "1 / 8", Color(1.00, 0.84, 0.22, 1.0)))
	rows.add_child(_make_stat_card("重投", "1", Color(1.00, 0.84, 0.22, 1.0)))
	rows.add_child(_make_stat_card("当前资金", "$0", Color(1.00, 0.82, 0.15, 1.0)))
	return root


func _build_relic_bar_ui() -> Control:
	var root := _make_root("ProjectedRelicBarUiRoot", RELIC_VIEWPORT_SIZE)
	var panel := _make_inventory_panel("ProjectedRelicInventoryPanel", "遗物", ["裂纹面具", "幸运草", "骰谱", "金骰", "药剂"], 6, Color(0.08, 0.03, 0.13, 0.96), Color(0.82, 0.32, 1.0, 0.94))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(panel)
	return root


func _build_item_bar_ui() -> Control:
	var root := _make_root("ProjectedItemBarUiRoot", ITEM_VIEWPORT_SIZE)
	var panel := _make_inventory_panel("ProjectedItemInventoryPanel", "道具", ["月牙币 x2", "紫骰 x1", "药剂 x1"], 3, Color(0.02, 0.13, 0.12, 0.96), Color(0.00, 0.96, 0.78, 0.94))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(panel)

	var check := CheckBox.new()
	check.name = "ProjectedUiRealCheckBox"
	check.text = "真实控件"
	check.button_pressed = true
	check.disabled = true
	check.anchor_left = 0.64
	check.anchor_top = 0.02
	check.anchor_right = 0.98
	check.anchor_bottom = 0.20
	check.add_theme_font_size_override("font_size", 18)
	check.add_theme_color_override("font_color", Color(0.92, 0.98, 0.92, 1.0))
	root.add_child(check)
	return root


func _make_inventory_panel(node_name: String, title_text: String, names: Array, capacity: int, fill: Color, border: Color) -> Control:
	var panel := _make_panel(node_name, fill, border, 4, 9)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var margin := _make_margin(14, 12, 14, 12)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	margin.add_child(rows)

	var title := _make_label(title_text, 30, Color(0.96, 1.00, 0.94, 1.0))
	rows.add_child(title)
	var slots := HBoxContainer.new()
	slots.name = "%sSlots" % node_name
	slots.add_theme_constant_override("separation", 10)
	rows.add_child(slots)
	for index in range(capacity):
		var display_name := str(names[index]) if index < names.size() else "空"
		slots.add_child(_make_slot(display_name, index))
	return panel


func _make_stat_card(title_text: String, value_text: String, value_color: Color) -> Control:
	var panel := _make_panel("%sStatCard" % title_text, Color(0.025, 0.030, 0.040, 0.94), Color(0.14, 0.42, 0.38, 0.88), 3, 8)
	panel.custom_minimum_size = Vector2(0, 76)
	var margin := _make_margin(12, 7, 12, 8)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	var title := _make_label(title_text, 22, Color(0.86, 0.92, 0.88, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var value := _make_label(value_text, 36, value_color)
	value.custom_minimum_size = Vector2(126, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)
	return panel


func _make_formula_card() -> Control:
	var panel := _make_panel("ProjectedFormulaCard", Color(0.025, 0.030, 0.040, 0.94), Color(0.74, 0.84, 0.92, 0.86), 3, 8)
	panel.custom_minimum_size = Vector2(0, 112)
	var margin := _make_margin(12, 10, 12, 10)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	margin.add_child(rows)
	var title := _make_label("得分公式", 21, Color(0.90, 0.92, 0.86, 1.0))
	rows.add_child(title)
	var formula := _make_label("0 × 0 × 1", 34, Color(1.0, 0.94, 0.44, 1.0))
	formula.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(formula)
	return panel


func _make_slot(display_name: String, index: int) -> Control:
	var slot := _make_panel("ProjectedInventorySlot%d" % [index + 1], Color(0.030, 0.035, 0.046, 0.98), Color(0.64, 0.72, 0.86, 0.82), 3, 7)
	slot.custom_minimum_size = Vector2(104, 92)
	var margin := _make_margin(7, 7, 7, 7)
	slot.add_child(margin)
	var label := _make_label(display_name, 18, Color(0.94, 0.96, 0.90, 1.0 if display_name != "空" else 0.34))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(label)
	return slot


func _make_dice_chip(value: int) -> Control:
	var chip := _make_panel("ProjectedActionDice%d" % value, Color(0.82, 0.94, 1.0, 0.98), Color(0.28, 0.64, 1.0, 0.94), 4, 7)
	chip.custom_minimum_size = Vector2(84, 84)
	var margin := _make_margin(6, 5, 6, 6)
	chip.add_child(margin)
	var label := _make_label(str(value), 44, Color(0.04, 0.08, 0.12, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	margin.add_child(label)
	return chip


func _make_action_button(text: String) -> Button:
	var button := Button.new()
	button.name = "Projected%sButton" % text
	button.text = text
	button.custom_minimum_size = Vector2(150, 78)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", Color(0.14, 0.06, 0.00, 1.0))
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(1.0, 0.72, 0.18, 0.98), Color(1.0, 0.94, 0.54, 0.98), 3, 6))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(1.0, 0.82, 0.28, 1.0), Color(1.0, 1.0, 0.72, 1.0), 3, 6))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.86, 0.46, 0.10, 1.0), Color(1.0, 0.86, 0.34, 1.0), 3, 6))
	return button


func _make_root(node_name: String, viewport_size: Vector2i) -> Control:
	var root := Control.new()
	root.name = node_name
	root.size = Vector2(float(viewport_size.x), float(viewport_size.y))
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return root


func _make_panel(node_name: String, fill: Color, border: Color, border_width: int, radius: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.add_theme_stylebox_override("panel", _make_panel_style(fill, border, border_width, radius))
	return panel


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.78))
	label.add_theme_constant_override("outline_size", 4)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _make_margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _make_panel_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	style.shadow_size = 8
	return style


func _make_viewport_material(viewport: SubViewport) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = viewport.get_texture()
	material.albedo_color = Color.WHITE
	material.roughness = 0.72
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _make_solid_material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _find_control_named(target_name: String) -> Control:
	for id in panels.keys():
		var panel: Dictionary = panels[id]
		var viewport := panel.get("viewport") as SubViewport
		if viewport == null:
			continue
		var found := viewport.find_child(target_name, true, false)
		if found is Control:
			return found as Control
	return null


func _count_controls(node: Node) -> int:
	if node == null:
		return 0
	var count := 1 if node is Control else 0
	for child in node.get_children():
		count += _count_controls(child)
	return count
