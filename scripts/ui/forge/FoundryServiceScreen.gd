extends Control
class_name FoundryServiceScreen


const RunState = preload("res://scripts/core/battle/RunState.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const FoundryService = preload("res://scripts/rules/forge/FoundryService.gd")
const FoundryServiceCatalog = preload("res://scripts/rules/forge/FoundryServiceCatalog.gd")
const FoundryServiceDef = preload("res://scripts/data_defs/FoundryServiceDef.gd")


signal service_target_requested(service_id: StringName)
signal service_applied(result: Dictionary)


var run_state: RunState = null
var services: Array[FoundryServiceDef] = []
var foundry_service := FoundryService.new()
var pending_service_id: StringName = &""
var pending_args: Dictionary = {}
var pending_resolution: Dictionary = {}

var root: VBoxContainer = null
var candidate_panel: PanelContainer = null
var candidate_box: VBoxContainer = null
var confirm_dialog: ConfirmationDialog = null


func setup(new_run_state: RunState, new_services: Array = []) -> void:
	run_state = new_run_state
	services.clear()
	if new_services.is_empty():
		services = FoundryServiceCatalog.get_all_defs()
	else:
		for item in new_services:
			if item is FoundryServiceDef:
				services.append(item)


func _ready() -> void:
	_build_view()


func confirm_and_apply_with_args(service_id: StringName, args: Dictionary) -> void:
	pending_service_id = service_id
	pending_args = args.duplicate(true)
	_request_confirmation(service_id)


func show_reforge_candidates(resolution: Dictionary) -> void:
	pending_resolution = resolution.duplicate(true)
	_refresh_candidate_panel()


func _build_view() -> void:
	_clear_view()

	var background := ColorRect.new()
	background.color = Color(0.06, 0.065, 0.072)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(root)

	root.add_child(_make_text_label("铸骰坊", 28, Color(0.95, 0.9, 0.78)))
	root.add_child(_make_text_label("选择一项高风险服务。", 15, Color(0.76, 0.84, 0.78)))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(row)

	for service_def in services:
		row.add_child(_make_service_card(service_def))

	candidate_panel = PanelContainer.new()
	candidate_panel.visible = false
	candidate_panel.custom_minimum_size = Vector2(0, 220)
	candidate_box = VBoxContainer.new()
	candidate_box.add_theme_constant_override("separation", 8)
	candidate_panel.add_child(candidate_box)
	root.add_child(candidate_panel)

	confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "确认服务"
	confirm_dialog.confirmed.connect(_on_confirmed)
	add_child(confirm_dialog)


func _make_service_card(service_def: FoundryServiceDef) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(270, 320)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	box.add_child(_make_text_label(service_def.get_display_name(), 20, Color(0.96, 0.86, 0.58)))
	box.add_child(_make_text_label(service_def.get_description(), 14, Color(0.86, 0.86, 0.8)))
	box.add_child(_make_text_label("风险 / 代价：%s" % [service_def.risk_note], 13, Color(0.95, 0.72, 0.58)))
	box.add_child(_make_text_label("需要道具槽位：%s" % ["是" if service_def.requires_item_slot else "否"], 13, Color(0.74, 0.84, 0.94)))

	var unavailable_reason := foundry_service.get_service_card_unavailable_reason(run_state, service_def.service_id)
	var reason_text := "不可用原因：%s" % [unavailable_reason] if unavailable_reason != "" else "可用"
	box.add_child(_make_text_label(reason_text, 13, Color(0.92, 0.68, 0.62) if unavailable_reason != "" else Color(0.66, 0.9, 0.72)))

	var button := Button.new()
	button.text = "选择目标" if service_def.target_rule != FoundryServiceCatalog.TARGET_NONE else "确认"
	button.disabled = unavailable_reason != ""
	button.custom_minimum_size = Vector2(0, 36)
	button.pressed.connect(_on_service_button_pressed.bind(service_def.service_id, service_def.target_rule))
	box.add_child(button)
	return panel


func _on_service_button_pressed(service_id: StringName, target_rule: StringName) -> void:
	if target_rule != FoundryServiceCatalog.TARGET_NONE:
		service_target_requested.emit(service_id)
		return
	pending_service_id = service_id
	pending_args = {}
	_request_confirmation(service_id)


func _request_confirmation(service_id: StringName) -> void:
	if confirm_dialog == null:
		return
	var def := FoundryServiceCatalog.get_def(service_id)
	var service_name := def.get_display_name() if def != null else str(service_id)
	var risk_note := def.risk_note if def != null else ""
	confirm_dialog.dialog_text = "%s\n%s\n确认执行？" % [service_name, risk_note]
	confirm_dialog.popup_centered()


func _on_confirmed() -> void:
	if _is_reforge_service(pending_service_id):
		var pending := foundry_service.create_reforge_resolution(run_state, pending_service_id, pending_args)
		if bool(pending.get("success", false)):
			show_reforge_candidates(pending)
		else:
			service_applied.emit(pending)
		return

	var result := foundry_service.apply_service(run_state, pending_service_id, pending_args)
	service_applied.emit(result)
	_build_view()


func _refresh_candidate_panel() -> void:
	if candidate_panel == null or candidate_box == null:
		return
	for child in candidate_box.get_children():
		candidate_box.remove_child(child)
		child.queue_free()

	if pending_resolution.is_empty():
		candidate_panel.visible = false
		return

	candidate_panel.visible = true
	var sacrifice = pending_resolution.get("sacrifice_face", null)
	candidate_box.add_child(_make_text_label("牺牲面：%s" % [DisplayNames.face_summary(sacrifice)], 15, Color(0.95, 0.78, 0.58)))

	var candidates: Array = pending_resolution.get("candidates", [])
	for index in range(candidates.size()):
		var face := candidates[index] as FaceState
		var button := Button.new()
		button.text = "候选 %d：%s" % [index + 1, DisplayNames.face_summary(face).replace("\n", " / ")]
		button.custom_minimum_size = Vector2(0, 36)
		button.pressed.connect(_on_candidate_pressed.bind(index))
		candidate_box.add_child(button)


func _on_candidate_pressed(candidate_index: int) -> void:
	var result := foundry_service.commit_reforge_candidate(run_state, pending_resolution, candidate_index)
	pending_resolution.clear()
	service_applied.emit(result)
	_build_view()


func _is_reforge_service(service_id: StringName) -> bool:
	return [
		FoundryServiceCatalog.FOUNDRY_HIGH_PIP_REFORGE,
		FoundryServiceCatalog.FOUNDRY_SIX_PIP_REFORGE,
		FoundryServiceCatalog.FOUNDRY_RANDOM_PIP_REFORGE,
	].has(service_id)


func _make_text_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _clear_view() -> void:
	root = null
	candidate_panel = null
	candidate_box = null
	confirm_dialog = null
	for child in get_children():
		remove_child(child)
		child.queue_free()
