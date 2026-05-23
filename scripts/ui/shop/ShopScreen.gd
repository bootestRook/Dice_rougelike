extends Control
class_name ShopScreen


const BoosterPackService = preload("res://scripts/rules/shop/BoosterPackService.gd")
const BoosterOfferDef = preload("res://scripts/data_defs/BoosterOfferDef.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const FaceOffer = preload("res://scripts/data_defs/FaceOffer.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")
const FoundryServiceCatalog = preload("res://scripts/rules/forge/FoundryServiceCatalog.gd")
const GameFlowController = preload("res://scripts/runtime/GameFlowController.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const ShopCatalog = preload("res://scripts/rules/shop/ShopCatalog.gd")
const ShopService = preload("res://scripts/rules/shop/ShopService.gd")
const ShopOfferDef = preload("res://scripts/data_defs/ShopOfferDef.gd")


var game_flow_controller: GameFlowController = null
var run_state: RunState = null
var shop_state: Dictionary = {}
var shop_service := ShopService.new()
var booster_pack_service := BoosterPackService.new()
var root: VBoxContainer = null
var booster_area: VBoxContainer = null
var message_label: Label = null
var last_message: String = ""
var pending_sell_relic_index: int = -1


func setup(new_game_flow_controller: GameFlowController, new_run_state: RunState, new_shop_state: Dictionary = {}) -> void:
	game_flow_controller = new_game_flow_controller
	run_state = new_run_state
	shop_state = new_shop_state.duplicate(true)


func _ready() -> void:
	if run_state != null and shop_state.is_empty():
		shop_state = shop_service.generate_shop(run_state)
	_build_view()


func _build_view() -> void:
	_clear_view()

	var background := ColorRect.new()
	background.color = Color(0.07, 0.075, 0.082)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	margin.add_child(root)

	root.add_child(_make_title_row())
	root.add_child(_make_single_offer_section("长期解锁槽", shop_state.get("long_term_unlock_slot", null), &"long_term_unlock_slot"))
	root.add_child(_make_offer_section("商店骰包槽", shop_state.get("booster_slots", []), &"booster_slots"))
	root.add_child(_make_offer_section("遗物货架", shop_state.get("relic_shelf_slots", []), &"relic_shelf_slots"))
	root.add_child(_make_owned_relic_section())

	booster_area = VBoxContainer.new()
	booster_area.add_theme_constant_override("separation", 8)
	root.add_child(booster_area)
	_render_pending_booster()

	message_label = _make_label("", 15, Color(0.95, 0.84, 0.64))
	message_label.text = last_message
	root.add_child(message_label)


func _make_title_row() -> Control:
	var panel := PanelContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)

	var title_label := _make_label("骰商铺", 28, Color(0.98, 0.92, 0.72))
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.custom_minimum_size = Vector2(150, 40)
	row.add_child(title_label)
	var coin_label := _make_label("金币：%d" % [run_state.coins if run_state != null else 0], 18, Color(0.92, 0.9, 0.84))
	coin_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	coin_label.custom_minimum_size = Vector2(110, 40)
	row.add_child(coin_label)
	var item_slot_label := _make_label("道具槽位剩余：%d" % [run_state.get_free_item_slot_count() if run_state != null else 0], 18, Color(0.78, 0.9, 0.82))
	item_slot_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	item_slot_label.custom_minimum_size = Vector2(180, 40)
	row.add_child(item_slot_label)
	var relic_slot_label := _make_label("遗物槽位剩余：%d" % [run_state.get_free_dice_tool_slot_count() if run_state != null else 0], 18, Color(0.8, 0.86, 0.98))
	relic_slot_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	relic_slot_label.custom_minimum_size = Vector2(180, 40)
	row.add_child(relic_slot_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var reroll_button := Button.new()
	reroll_button.text = "刷新：%d 金币" % [int(shop_state.get("reroll_cost", 5))]
	reroll_button.custom_minimum_size = Vector2(150, 40)
	reroll_button.pressed.connect(_on_reroll_pressed)
	row.add_child(reroll_button)

	var leave_button := Button.new()
	leave_button.text = "离开"
	leave_button.disabled = run_state != null and not run_state.pending_booster_resolution.is_empty()
	leave_button.custom_minimum_size = Vector2(120, 40)
	leave_button.pressed.connect(_on_leave_pressed)
	row.add_child(leave_button)
	return panel


func _make_offer_section(title: String, offers: Array, slot_group: StringName) -> Control:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 5)
	section.add_child(_make_label(title, 20, Color(0.9, 0.88, 0.78)))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	section.add_child(row)
	for index in range(offers.size()):
		row.add_child(_make_offer_card(offers[index], slot_group, index))
	return section


func _make_owned_relic_section() -> Control:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 5)
	section.add_child(_make_label("已拥有遗物", 20, Color(0.9, 0.88, 0.78)))

	if run_state == null or run_state.dice_tools.is_empty():
		section.add_child(_make_label("暂无已拥有遗物。", 14, Color(0.72, 0.76, 0.74)))
		return section

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	section.add_child(grid)
	for index in range(run_state.dice_tools.size()):
		grid.add_child(_make_owned_relic_card(index))
	return section


func _make_owned_relic_card(index: int) -> Control:
	var tool = run_state.dice_tools[index] if run_state != null and index >= 0 and index < run_state.dice_tools.size() else null
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 112)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	if tool == null:
		box.add_child(_make_label("空槽", 16, Color(0.72, 0.72, 0.68)))
		return panel

	var tool_id := StringName(str(tool.tool_id))
	var rarity := StringName(str(tool.rarity))
	var name: String = tool.display_name if tool.display_name != "" else ShopCatalog.display_name_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, tool_id)
	var sell_price := ShopCatalog.sell_price_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, tool_id)
	box.add_child(_make_label(name, 16, Color(0.98, 0.88, 0.62)))
	box.add_child(_make_label("稀有度：%s" % [DisplayNames.rarity_name(rarity)], 13, Color(0.78, 0.86, 0.94)))
	box.add_child(_make_label("出售：%d 金币" % [sell_price], 13, Color(0.88, 0.86, 0.8)))

	var button := Button.new()
	button.text = "确认出售" if pending_sell_relic_index == index else "出售"
	button.custom_minimum_size = Vector2(0, 32)
	button.pressed.connect(_on_sell_relic_pressed.bind(index))
	box.add_child(button)
	return panel


func _make_single_offer_section(title: String, offer, slot_group: StringName) -> Control:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 5)
	section.add_child(_make_label(title, 20, Color(0.9, 0.88, 0.78)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	section.add_child(row)
	row.add_child(_make_offer_card(offer, slot_group, 0))
	return section


func _make_offer_card(offer_any, slot_group: StringName, index: int) -> Control:
	var view_data := shop_service.get_offer_view_data(run_state, offer_any)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 148)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	if view_data.is_empty():
		box.add_child(_make_label("已售罄", 18, Color(0.72, 0.72, 0.68)))
		box.add_child(_make_label("该槽位本次商铺不再提供商品。", 14, Color(0.72, 0.76, 0.74)))
		return panel

	box.add_child(_make_label(str(view_data.get("name", "商品")), 18, Color(0.98, 0.88, 0.62)))
	box.add_child(_make_label("价格：%d 金币" % [int(view_data.get("price", 0))], 14, Color(0.88, 0.86, 0.8)))
	box.add_child(_make_label("类型：%s" % [str(view_data.get("type", ""))], 14, Color(0.78, 0.86, 0.94)))
	box.add_child(_make_label(str(view_data.get("description", "")), 14, Color(0.78, 0.84, 0.78)))

	var reason := str(view_data.get("unavailable_reason", ""))
	if reason != "":
		box.add_child(_make_label(reason, 14, Color(1.0, 0.58, 0.48)))

	var button := Button.new()
	button.text = "购买"
	button.disabled = reason != ""
	button.custom_minimum_size = Vector2(0, 36)
	button.pressed.connect(_on_offer_pressed.bind(slot_group, index))
	box.add_child(button)
	return panel


func _render_pending_booster() -> void:
	if booster_area == null:
		return
	for child in booster_area.get_children():
		booster_area.remove_child(child)
		child.queue_free()
	if run_state == null or run_state.pending_booster_resolution.is_empty():
		return

	var pending: Dictionary = run_state.pending_booster_resolution
	var candidates: Array = pending.get("candidate_offers", [])
	var selected: Array = pending.get("selected_offers", [])
	var selected_indexes: Array = pending.get("selected_offer_indexes", [])
	booster_area.add_child(_make_label("%s候选" % [str(pending.get("pack_name", "骰包"))], 20, Color(0.9, 0.88, 0.78)))
	booster_area.add_child(_make_label("可选数量：%d    当前已选：%d" % [
		int(pending.get("choose_count", 1)),
		selected.size(),
	], 15, Color(0.86, 0.86, 0.8)))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	booster_area.add_child(row)
	for index in range(candidates.size()):
		var data: Dictionary = candidates[index]
		var button := Button.new()
		button.text = str(data.get("display_name", "候选"))
		button.disabled = not bool(data.get("is_selectable", true)) or bool(pending.get("completed", false)) or selected_indexes.has(index)
		button.custom_minimum_size = Vector2(180, 44)
		button.pressed.connect(_on_booster_candidate_pressed.bind(index))
		row.add_child(button)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	booster_area.add_child(actions)
	var confirm_button := Button.new()
	confirm_button.text = "确认"
	confirm_button.disabled = not bool(pending.get("completed", false))
	confirm_button.pressed.connect(_on_confirm_booster_pressed)
	actions.add_child(confirm_button)
	var skip_button := Button.new()
	skip_button.text = "跳过 / 关闭"
	skip_button.pressed.connect(_on_skip_booster_pressed)
	actions.add_child(skip_button)

	_render_pending_target_panel(pending)


func _render_pending_target_panel(pending: Dictionary) -> void:
	var target_state: Dictionary = pending.get("pending_target_selection", {})
	if target_state.is_empty():
		return
	var offer: BoosterOfferDef = BoosterOfferDef.from_dict(target_state.get("offer", {}))
	if offer == null:
		return
	booster_area.add_child(_make_label("请选择目标", 18, Color(0.92, 0.84, 0.66)))

	match offer.payload_kind:
		BoosterOfferDef.PAYLOAD_FACE_OFFER:
			_render_face_target_buttons(offer, &"face_offer")
		BoosterOfferDef.PAYLOAD_FORGE_ITEM:
			_render_forge_target_buttons(offer)
		BoosterOfferDef.PAYLOAD_FOUNDRY_SERVICE:
			_render_foundry_target_buttons(offer)
		_:
			booster_area.add_child(_make_label("该候选无需目标。", 14, Color(0.86, 0.86, 0.8)))


func _render_face_target_buttons(offer: BoosterOfferDef, target_mode: StringName) -> void:
	if run_state == null:
		return
	var row := GridContainer.new()
	row.columns = 6
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	booster_area.add_child(row)

	var face_offer: FaceOffer = null
	if offer.payload_kind == BoosterOfferDef.PAYLOAD_FACE_OFFER:
		face_offer = FaceOffer.from_dict(offer.payload_data)
	for die_index in range(run_state.dice.size()):
		var die: DieState = run_state.dice[die_index]
		if die == null:
			continue
		for face_index in range(die.faces.size()):
			var ref := {"die_index": die_index, "face_index": face_index}
			var button := Button.new()
			button.text = "D%d-%d 第%d面" % [die.face_count, die_index + 1, face_index + 1]
			button.custom_minimum_size = Vector2(120, 36)
			if face_offer != null:
				var validation := booster_pack_service.can_apply_face_offer_to_target(run_state, face_offer, die_index, face_index)
				button.disabled = not bool(validation.get("success", false))
				button.tooltip_text = str(validation.get("reason", ""))
			button.pressed.connect(_on_target_face_pressed.bind(target_mode, ref))
			row.add_child(button)


func _render_forge_target_buttons(offer: BoosterOfferDef) -> void:
	var def := ForgeItemCatalog.get_def(offer.payload_id)
	if def == null:
		booster_area.add_child(_make_label("候选无效。", 14, Color(1.0, 0.58, 0.48)))
		return
	match def.target_type:
		ForgeItemCatalog.TARGET_FACES:
			_render_face_target_buttons(offer, &"forge_faces")
		ForgeItemCatalog.TARGET_FACE_PAIR:
			_render_source_and_targets_panel(offer, &"forge_face_pair", 1)
		_:
			booster_area.add_child(_make_label("该候选无需目标。", 14, Color(0.86, 0.86, 0.8)))


func _render_foundry_target_buttons(offer: BoosterOfferDef) -> void:
	var def := FoundryServiceCatalog.get_def(offer.payload_id)
	if def == null:
		booster_area.add_child(_make_label("候选无效。", 14, Color(1.0, 0.58, 0.48)))
		return
	match def.target_rule:
		FoundryServiceCatalog.TARGET_DIE:
			_render_die_target_buttons()
		FoundryServiceCatalog.TARGET_FACE:
			_render_face_target_buttons(offer, &"foundry_face")
		FoundryServiceCatalog.TARGET_MULTI_FACES:
			_render_multi_face_target_panel(offer, &"foundry_multi_faces", 2)
		FoundryServiceCatalog.TARGET_FACE_DOUBLE_COPY:
			_render_source_and_targets_panel(offer, &"foundry_face_double_copy", 2)
		_:
			booster_area.add_child(_make_label("该候选无需目标。", 14, Color(0.86, 0.86, 0.8)))


func _render_die_target_buttons() -> void:
	if run_state == null:
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	booster_area.add_child(row)
	for die_index in range(run_state.dice.size()):
		var die: DieState = run_state.dice[die_index]
		if die == null:
			continue
		var button := Button.new()
		button.text = "D%d-%d" % [die.face_count, die_index + 1]
		button.custom_minimum_size = Vector2(96, 36)
		button.pressed.connect(_on_target_die_pressed.bind(die_index))
		row.add_child(button)


func _render_source_and_targets_panel(offer: BoosterOfferDef, target_mode: StringName, required_targets: int) -> void:
	var target_state := _current_target_state()
	var source_face: Dictionary = target_state.get("source_face", {})
	var target_faces: Array = target_state.get("target_faces", [])
	if source_face.is_empty():
		booster_area.add_child(_make_label("先选择来源骰面。", 14, Color(0.86, 0.86, 0.8)))
		_render_complex_face_buttons(offer, StringName("%s_source" % [str(target_mode)]), [], [])
		return

	booster_area.add_child(_make_label("来源：%s。请选择 %d 个目标骰面。" % [
		_face_ref_label(source_face),
		required_targets,
	], 14, Color(0.86, 0.86, 0.8)))
	var disabled_refs := [source_face]
	_render_complex_face_buttons(offer, StringName("%s_target" % [str(target_mode)]), disabled_refs, target_faces)
	_render_complex_target_actions(target_mode, required_targets, target_faces.size())


func _render_multi_face_target_panel(offer: BoosterOfferDef, target_mode: StringName, min_targets: int) -> void:
	var target_state := _current_target_state()
	var target_faces: Array = target_state.get("target_faces", [])
	booster_area.add_child(_make_label("请选择至少 %d 个目标骰面。当前已选：%d" % [
		min_targets,
		target_faces.size(),
	], 14, Color(0.86, 0.86, 0.8)))
	_render_complex_face_buttons(offer, StringName("%s_target" % [str(target_mode)]), [], target_faces)
	_render_complex_target_actions(target_mode, min_targets, target_faces.size())


func _render_complex_face_buttons(offer: BoosterOfferDef, target_mode: StringName, disabled_refs: Array, selected_refs: Array) -> void:
	if run_state == null:
		return
	var row := GridContainer.new()
	row.columns = 6
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	booster_area.add_child(row)

	for die_index in range(run_state.dice.size()):
		var die: DieState = run_state.dice[die_index]
		if die == null:
			continue
		for face_index in range(die.faces.size()):
			var ref := {"die_index": die_index, "face_index": face_index}
			var button := Button.new()
			var selected := _face_ref_in_array(ref, selected_refs)
			button.text = "%sD%d-%d 第%d面" % [
				"已选 " if selected else "",
				die.face_count,
				die_index + 1,
				face_index + 1,
			]
			button.custom_minimum_size = Vector2(120, 36)
			button.disabled = selected or _face_ref_in_array(ref, disabled_refs)
			button.pressed.connect(_on_complex_target_face_pressed.bind(target_mode, ref))
			row.add_child(button)


func _render_complex_target_actions(target_mode: StringName, required_targets: int, selected_count: int) -> void:
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	booster_area.add_child(actions)

	var confirm_button := Button.new()
	confirm_button.text = "确认目标"
	confirm_button.disabled = selected_count < required_targets
	confirm_button.pressed.connect(_on_confirm_complex_target_pressed.bind(target_mode, required_targets))
	actions.add_child(confirm_button)

	var reset_button := Button.new()
	reset_button.text = "重选目标"
	reset_button.pressed.connect(_on_reset_complex_target_pressed)
	actions.add_child(reset_button)


func _on_offer_pressed(slot_group: StringName, index: int) -> void:
	pending_sell_relic_index = -1
	if game_flow_controller != null:
		var result := game_flow_controller.purchase_shop_offer_by_slot(slot_group, index)
		_handle_purchase_result(result)
	elif run_state != null:
		var result := shop_service.purchase_offer_by_slot(run_state, slot_group, index)
		_handle_purchase_result(result)


func _on_reroll_pressed() -> void:
	pending_sell_relic_index = -1
	var result := {}
	if game_flow_controller != null:
		result = game_flow_controller.reroll_shop_random_items()
	elif run_state != null:
		result = shop_service.reroll_random_shop_items(run_state)
	if bool(result.get("success", false)):
		shop_state = Dictionary(result.get("shop_state", shop_state)).duplicate(true)
		last_message = str(result.get("message", ""))
		_build_view()
		return
	_set_message(str(result.get("message", "刷新失败")))


func _on_sell_relic_pressed(index: int) -> void:
	if run_state == null:
		_set_message("缺少本局状态")
		return
	if pending_sell_relic_index != index:
		pending_sell_relic_index = index
		var tool = run_state.dice_tools[index] if index >= 0 and index < run_state.dice_tools.size() else null
		var name: String = tool.display_name if tool != null and tool.display_name != "" else "该遗物"
		last_message = "再次点击确认出售：%s。" % [name]
		_build_view()
		return

	var result := {}
	if game_flow_controller != null and game_flow_controller.has_method("sell_shop_relic_by_index"):
		result = game_flow_controller.sell_shop_relic_by_index(index)
	else:
		result = shop_service.sell_relic_by_index(run_state, index)
	pending_sell_relic_index = -1
	last_message = str(result.get("message", "出售失败"))
	if run_state != null:
		shop_state = run_state.current_shop_state.duplicate(true)
	_build_view()


func _on_leave_pressed() -> void:
	if run_state != null and not run_state.pending_booster_resolution.is_empty():
		_set_message("请先处理已打开的骰包")
		return
	if game_flow_controller != null and game_flow_controller.has_method("leave_shop"):
		var result: Dictionary = game_flow_controller.leave_shop()
		if not bool(result.get("success", false)):
			_set_message(str(result.get("message", "暂时无法离开")))
		return
	_set_message("已离开骰商铺")


func _on_booster_candidate_pressed(index: int) -> void:
	if run_state == null:
		return
	var result := booster_pack_service.select_pending_offer(run_state, index)
	last_message = str(result.get("message", ""))
	_build_view()


func _on_skip_booster_pressed() -> void:
	if run_state == null:
		return
	var result := booster_pack_service.skip_pending_pack(run_state)
	last_message = str(result.get("message", ""))
	_build_view()


func _on_confirm_booster_pressed() -> void:
	if run_state == null:
		return
	var result := booster_pack_service.close_completed_pack(run_state)
	last_message = str(result.get("message", ""))
	_build_view()


func _on_target_face_pressed(target_mode: StringName, ref: Dictionary) -> void:
	if run_state == null:
		return
	var args := {}
	match target_mode:
		&"face_offer":
			args = ref
		&"forge_faces":
			args = {"target_faces": [ref]}
		&"foundry_face":
			args = {"target_face": ref}
		_:
			args = ref
	var result := booster_pack_service.resolve_pending_target(run_state, args)
	last_message = str(result.get("message", ""))
	_build_view()


func _on_target_die_pressed(die_index: int) -> void:
	if run_state == null:
		return
	var result := booster_pack_service.resolve_pending_target(run_state, {"die_index": die_index})
	last_message = str(result.get("message", ""))
	_build_view()


func _on_complex_target_face_pressed(target_mode: StringName, ref: Dictionary) -> void:
	var target_state := _current_target_state()
	if str(target_mode).ends_with("_source"):
		target_state["source_face"] = ref.duplicate(true)
		target_state["target_faces"] = []
	else:
		var target_faces: Array = target_state.get("target_faces", [])
		if not _face_ref_in_array(ref, target_faces):
			target_faces.append(ref.duplicate(true))
		target_state["target_faces"] = target_faces
	_save_target_state(target_state)
	_build_view()


func _on_confirm_complex_target_pressed(target_mode: StringName, required_targets: int) -> void:
	if run_state == null:
		return
	var target_state := _current_target_state()
	var target_faces: Array = target_state.get("target_faces", [])
	if target_faces.size() < required_targets:
		_set_message("目标数量不足")
		return

	var args := {"target_faces": target_faces}
	if target_mode == &"forge_face_pair" or target_mode == &"foundry_face_double_copy":
		args["source_face"] = Dictionary(target_state.get("source_face", {})).duplicate(true)
	var result := booster_pack_service.resolve_pending_target(run_state, args)
	last_message = str(result.get("message", ""))
	_build_view()


func _on_reset_complex_target_pressed() -> void:
	_save_target_state({
		"source_face": {},
		"target_faces": [],
	})
	_build_view()


func _handle_purchase_result(result: Dictionary) -> void:
	last_message = str(result.get("message", ""))
	if run_state != null:
		shop_state = run_state.current_shop_state.duplicate(true)
	_build_view()


func _set_message(text: String) -> void:
	if message_label != null:
		message_label.text = text
	last_message = text


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _clear_view() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _current_target_state() -> Dictionary:
	if run_state == null:
		return {}
	var pending: Dictionary = run_state.pending_booster_resolution
	var target_state: Dictionary = pending.get("pending_target_selection", {})
	return target_state.duplicate(true)


func _save_target_state(target_state: Dictionary) -> void:
	if run_state == null:
		return
	var pending: Dictionary = run_state.pending_booster_resolution
	if pending.is_empty():
		return
	var existing: Dictionary = pending.get("pending_target_selection", {})
	for key in target_state.keys():
		var value = target_state[key]
		existing[key] = value.duplicate(true) if value is Dictionary or value is Array else value
	pending["pending_target_selection"] = existing
	run_state.pending_booster_resolution = pending


func _face_ref_label(ref: Dictionary) -> String:
	var die_index := int(ref.get("die_index", -1))
	var face_index := int(ref.get("face_index", -1))
	if run_state == null or die_index < 0 or die_index >= run_state.dice.size():
		return "未知骰面"
	var die: DieState = run_state.dice[die_index]
	if die == null:
		return "未知骰面"
	return "D%d-%d 第%d面" % [die.face_count, die_index + 1, face_index + 1]


func _face_ref_in_array(ref: Dictionary, refs: Array) -> bool:
	for item in refs:
		if item is Dictionary and _same_face_ref(ref, item):
			return true
	return false


func _same_face_ref(left: Dictionary, right: Dictionary) -> bool:
	return (
		int(left.get("die_index", -1)) == int(right.get("die_index", -2))
		and int(left.get("face_index", -1)) == int(right.get("face_index", -2))
	)
