extends RefCounted
class_name ShopCatalog


const ShopOfferDef = preload("res://scripts/data_defs/ShopOfferDef.gd")
const ComboUpgradeCatalog = preload("res://scripts/rules/combo/ComboUpgradeCatalog.gd")
const DiceToolCatalog = preload("res://scripts/rules/dice_tools/DiceToolCatalog.gd")
const ForgeItemCatalog = preload("res://scripts/rules/forge/ForgeItemCatalog.gd")
const BoosterPackCatalog = preload("res://scripts/rules/shop/BoosterPackCatalog.gd")
const LongTermUnlockCatalog = preload("res://scripts/rules/long_term/LongTermUnlockCatalog.gd")


const RANDOM_ITEM_WEIGHT_DICE_TOOL := 20
const RANDOM_ITEM_WEIGHT_FORGE := 4
const RANDOM_ITEM_WEIGHT_COMBO := 4
const RANDOM_ITEM_WEIGHT_FACE_SHOP := 4


static func make_random_item_offer(
	offer_id: StringName,
	payload_kind: StringName,
	payload_id: StringName,
	display_name: String,
	price_coins: int,
	source_note: String = ""
) -> ShopOfferDef:
	return ShopOfferDef.create(
		offer_id,
		display_name,
		ShopOfferDef.KIND_RANDOM_ITEM,
		payload_id,
		payload_kind,
		price_coins,
		source_note
	)


static func make_booster_offer(offer_id: StringName, pack_id: StringName) -> ShopOfferDef:
	var pack_def := BoosterPackCatalog.get_def(pack_id)
	var display_name := pack_def.display_name if pack_def != null else str(pack_id)
	var price := pack_def.price_coins if pack_def != null else 0
	return ShopOfferDef.create(
		offer_id,
		display_name,
		ShopOfferDef.KIND_BOOSTER_PACK,
		pack_id,
		ShopOfferDef.PAYLOAD_BOOSTER_PACK,
		price,
		"骰包槽"
	)


static func make_long_term_unlock_offer(offer_id: StringName, unlock_id: StringName = &"unlock_future_shop_slot") -> ShopOfferDef:
	var unlock_def := LongTermUnlockCatalog.get_def(unlock_id)
	var display_name := unlock_def.get_display_name() if unlock_def != null else "长期解锁"
	var price := unlock_def.price_coins if unlock_def != null else 0
	return ShopOfferDef.create(
		offer_id,
		display_name,
		ShopOfferDef.KIND_LONG_TERM_UNLOCK,
		unlock_id,
		ShopOfferDef.PAYLOAD_LONG_TERM_UNLOCK,
		price,
		"长期解锁槽"
	)


static func get_random_item_kind_weights(run_state = null) -> Array[Dictionary]:
	return [
		{"payload_kind": ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, "weight": RANDOM_ITEM_WEIGHT_DICE_TOOL},
	]


static func get_payload_pool(payload_kind: StringName, run_state = null) -> Array:
	match payload_kind:
		ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
			return get_normal_shop_relic_pool(&"", run_state)
		_:
			return []


static func get_normal_shop_relic_pool(rarity: StringName = &"", run_state = null) -> Array:
	return DiceToolCatalog.get_normal_shop_item_pool(rarity, _circle_number_from_run_state(run_state))


static func relic_rarity_weights_for_circle(circle_number: int) -> Array[Dictionary]:
	if circle_number <= 2:
		return [
			{"rarity": &"common", "weight": 78},
			{"rarity": &"uncommon", "weight": 22},
			{"rarity": &"rare", "weight": 0},
			{"rarity": &"epic", "weight": 0},
		]
	if circle_number <= 5:
		return [
			{"rarity": &"common", "weight": 55},
			{"rarity": &"uncommon", "weight": 45},
			{"rarity": &"rare", "weight": 0},
			{"rarity": &"epic", "weight": 0},
		]
	return [
		{"rarity": &"common", "weight": 40},
		{"rarity": &"uncommon", "weight": 40},
		{"rarity": &"rare", "weight": 20},
		{"rarity": &"epic", "weight": 0},
	]


static func _circle_number_from_run_state(run_state = null) -> int:
	if run_state != null and run_state.has_method("get_circle_number"):
		return int(run_state.get_circle_number())
	return 8


static func display_name_for_payload(payload_kind: StringName, payload_id: StringName) -> String:
	match payload_kind:
		ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
			return DiceToolCatalog.display_name_for_id(payload_id)
		ShopOfferDef.PAYLOAD_FORGE_ITEM:
			return ForgeItemCatalog.display_name_for_id(payload_id)
		ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM:
			var combo_id := ComboUpgradeCatalog.combo_id_from_item_id(payload_id)
			return ComboUpgradeCatalog.display_name_for_combo(combo_id)
		ShopOfferDef.PAYLOAD_FACE_SHOP_ITEM:
			return BoosterPackCatalog.display_name_for_id(payload_id)
		ShopOfferDef.PAYLOAD_BOOSTER_PACK:
			return BoosterPackCatalog.display_name_for_id(payload_id)
		ShopOfferDef.PAYLOAD_LONG_TERM_UNLOCK:
			return LongTermUnlockCatalog.display_name_for_id(payload_id)
		_:
			return str(payload_id)


static func base_price_for_payload(payload_kind: StringName, payload_id: StringName) -> int:
	match payload_kind:
		ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
			var def := DiceToolCatalog.get_def(payload_id)
			if def != null:
				return relic_shop_price_for_rarity(def.rarity)
			return relic_shop_price_for_rarity(&"common")
		ShopOfferDef.PAYLOAD_FORGE_ITEM:
			return 4
		ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM:
			return 4
		ShopOfferDef.PAYLOAD_FACE_SHOP_ITEM:
			var pack_def := BoosterPackCatalog.get_def(payload_id)
			return pack_def.price_coins if pack_def != null else 4
		ShopOfferDef.PAYLOAD_BOOSTER_PACK:
			var pack_def := BoosterPackCatalog.get_def(payload_id)
			return pack_def.price_coins if pack_def != null else 0
		_:
			return 0


static func relic_shop_price_for_rarity(rarity: StringName) -> int:
	match rarity:
		&"epic", &"legendary":
			return 18
		&"rare":
			return 13
		&"uncommon":
			return 9
		_:
			return 6


static func sell_price_for_payload(payload_kind: StringName, payload_id: StringName) -> int:
	return max(1, int(floor(float(base_price_for_payload(payload_kind, payload_id)) * 0.5)))


static func rarity_for_payload(payload_kind: StringName, payload_id: StringName) -> StringName:
	match payload_kind:
		ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
			var def := DiceToolCatalog.get_def(payload_id)
			return def.rarity if def != null else &"common"
		_:
			return &"common"
