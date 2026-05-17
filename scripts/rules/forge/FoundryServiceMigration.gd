extends RefCounted
class_name FoundryServiceMigration


const FoundryServiceCatalog = preload("res://scripts/rules/forge/FoundryServiceCatalog.gd")


static func migrate_legacy_service_id(legacy_id: StringName) -> StringName:
	match legacy_id:
		&"sp_familiar":
			return FoundryServiceCatalog.FOUNDRY_HIGH_PIP_REFORGE
		&"sp_grim":
			return FoundryServiceCatalog.FOUNDRY_SIX_PIP_REFORGE
		&"sp_incantation":
			return FoundryServiceCatalog.FOUNDRY_RANDOM_PIP_REFORGE
		&"sp_talisman":
			return FoundryServiceCatalog.FOUNDRY_GOLD_MARK
		&"sp_aura":
			return FoundryServiceCatalog.FOUNDRY_RARE_ORNAMENT
		&"sp_wraith":
			return FoundryServiceCatalog.FOUNDRY_RARE_TOOL_PACK
		&"sp_sigil":
			return &""
		&"sp_ouija":
			return FoundryServiceCatalog.FOUNDRY_SAME_PIP_SYNC
		&"sp_ectoplasm":
			return FoundryServiceCatalog.FOUNDRY_NEGATIVE_TOOL_SLOT
		&"sp_immolate":
			return FoundryServiceCatalog.FOUNDRY_BURN_FOR_COINS
		&"sp_ankh":
			return FoundryServiceCatalog.FOUNDRY_TOOL_CLONE_PURGE
		&"sp_dejavu":
			return FoundryServiceCatalog.FOUNDRY_RED_MARK
		&"sp_hex":
			return FoundryServiceCatalog.FOUNDRY_POLY_GAMBLE
		&"sp_trance":
			return FoundryServiceCatalog.FOUNDRY_BLUE_MARK
		&"sp_medium":
			return FoundryServiceCatalog.FOUNDRY_PURPLE_MARK
		&"sp_cryptid":
			return FoundryServiceCatalog.FOUNDRY_FACE_DOUBLE_COPY
		&"sp_soul":
			return FoundryServiceCatalog.FOUNDRY_LEGENDARY_TOOL_PACK
		&"sp_blackhole":
			return FoundryServiceCatalog.FOUNDRY_ALL_COMBO_UPGRADE
		_:
			return legacy_id
