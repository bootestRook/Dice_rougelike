extends RefCounted
class_name WholeDieServiceMigration


const WholeDieServiceCatalog = preload("res://scripts/rules/forge/WholeDieServiceCatalog.gd")


static func migrate_legacy_service_id(legacy_id: StringName) -> StringName:
	match legacy_id:
		&"reward_new_d4":
			return WholeDieServiceCatalog.DIE_CONVERT_D4
		&"reward_new_d8":
			return WholeDieServiceCatalog.DIE_CONVERT_D8
		&"reward_reroll_body":
			return WholeDieServiceCatalog.DIE_CHANGE_BODY
		&"reward_reforge":
			return WholeDieServiceCatalog.DIE_FULL_REFORGE
		&"reward_distribution":
			return &""
		_:
			return legacy_id
