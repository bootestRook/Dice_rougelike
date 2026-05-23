extends SceneTree


const OUTPUT_DIR := "res://tests_or_debug/captures/shop_screen"
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")
const ItemInstance = preload("res://scripts/core/items/ItemInstance.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const ShopCatalog = preload("res://scripts/rules/shop/ShopCatalog.gd")
const ShopOfferDef = preload("res://scripts/data_defs/ShopOfferDef.gd")
const ShopService = preload("res://scripts/rules/shop/ShopService.gd")


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var capture_size := _capture_size_from_args()
	var label := _label_from_args()
	var output_path := "%s/shop_screen_%s_%dx%d.png" % [
		OUTPUT_DIR,
		label,
		capture_size.x,
		capture_size.y,
	]
	DisplayServer.window_set_size(capture_size)
	root.size = capture_size
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var run_state := RunState.new()
	run_state.setup_new_run()
	run_state.coins = 30
	if _has_flag("with_relics"):
		_install_capture_relic(run_state, DiceToolCatalog.TOOL_BASIC_MULT)
		_install_capture_relic(run_state, DiceToolCatalog.TOOL_EMPTY_SLOT_XMULT)

	var shop_service := ShopService.new()
	shop_service.rng.seed = 20260523
	var shop_options := {}
	if _has_flag("first_circle"):
		shop_options["first_circle_first_shop"] = true
	var shop_state := shop_service.generate_shop(run_state, shop_options)
	if _has_flag("sold_pack"):
		shop_service.purchase_offer_by_slot(run_state, &"booster_slots", 0)
		shop_state = run_state.current_shop_state

	var scene := load("res://scenes/shop/ShopScreen.tscn")
	var shop_screen = scene.instantiate()
	shop_screen.setup(null, run_state, shop_state)
	root.add_child(shop_screen)

	await process_frame
	await process_frame
	await process_frame

	var image := root.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(output_path))
	print("saved=%s" % [ProjectSettings.globalize_path(output_path)])
	quit(0)


func _capture_size_from_args() -> Vector2i:
	for arg in OS.get_cmdline_user_args():
		if not arg.contains("x"):
			continue
		var parts := arg.split("x")
		if parts.size() != 2:
			continue
		return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i(1920, 1080)


func _label_from_args() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("label="):
			return arg.trim_prefix("label=").strip_edges().validate_filename()
	return "current"


func _has_flag(flag: String) -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg == flag:
			return true
	return false


func _install_capture_relic(run_state: RunState, tool_id: StringName) -> void:
	var item: ItemInstance = ItemInstance.create_dice_tool(
		tool_id,
		DiceToolCatalog.display_name_for_id(tool_id),
		ShopCatalog.sell_price_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, tool_id)
	)
	item.metadata["rarity"] = ShopCatalog.rarity_for_payload(ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, tool_id)
	run_state.install_dice_tool_item_instance(item)
