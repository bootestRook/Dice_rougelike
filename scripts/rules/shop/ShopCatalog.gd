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
		"补充包槽"
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


static func get_random_item_kind_weights() -> Array[Dictionary]:
	return [
		{"payload_kind": ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM, "weight": RANDOM_ITEM_WEIGHT_DICE_TOOL},
		{"payload_kind": ShopOfferDef.PAYLOAD_FORGE_ITEM, "weight": RANDOM_ITEM_WEIGHT_FORGE},
		{"payload_kind": ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM, "weight": RANDOM_ITEM_WEIGHT_COMBO},
	]


static func get_payload_pool(payload_kind: StringName) -> Array:
	match payload_kind:
		ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
			return DiceToolCatalog.get_item_pool_for_rarity()
		ShopOfferDef.PAYLOAD_FORGE_ITEM:
			return ForgeItemCatalog.get_all_ids()
		ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM:
			return ComboUpgradeCatalog.get_item_ids()
		_:
			return []


static func display_name_for_payload(payload_kind: StringName, payload_id: StringName) -> String:
	match payload_kind:
		ShopOfferDef.PAYLOAD_DICE_TOOL_ITEM:
			return DiceToolCatalog.display_name_for_id(payload_id)
		ShopOfferDef.PAYLOAD_FORGE_ITEM:
			return ForgeItemCatalog.display_name_for_id(payload_id)
		ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM:
			var combo_id := ComboUpgradeCatalog.combo_id_from_item_id(payload_id)
			return ComboUpgradeCatalog.display_name_for_combo(combo_id)
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
				match def.rarity:
					&"legendary":
						return 18
					&"rare":
						return 12
					&"uncommon":
						return 8
					_:
						return 5
			return 5
		ShopOfferDef.PAYLOAD_FORGE_ITEM:
			return 4
		ShopOfferDef.PAYLOAD_COMBO_UPGRADE_ITEM:
			return 4
		_:
			return 0
