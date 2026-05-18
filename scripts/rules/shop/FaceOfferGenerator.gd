extends RefCounted
class_name FaceOfferGenerator


const BoosterOfferDef = preload("res://scripts/data_defs/BoosterOfferDef.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")
const DisplayNames = preload("res://scripts/ui/DisplayNames.gd")
const FaceOffer = preload("res://scripts/data_defs/FaceOffer.gd")
const FaceState = preload("res://scripts/core/dice/FaceState.gd")


const ORDINARY_ORNAMENT_POOL := [
	FaceState.ORN_NONE,
	FaceState.ORN_CHIP,
	FaceState.ORN_MULT,
	FaceState.ORN_WILD,
	FaceState.ORN_BURST,
	FaceState.ORN_STAY,
	FaceState.ORN_STONE,
	FaceState.ORN_GOLD,
	FaceState.ORN_LUCKY,
]

const BASIC_MARK_POOL := [
	FaceState.MARK_RED,
	FaceState.MARK_BLUE,
	FaceState.MARK_PURPLE,
]


var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


func generate_face_offers(run_state, count: int) -> Array[BoosterOfferDef]:
	var result: Array[BoosterOfferDef] = []
	for index in range(max(0, count)):
		var face_offer := _make_face_offer(run_state, index)
		result.append(_to_booster_offer(face_offer, index))
	return result


func can_apply_to_target(run_state, face_offer: FaceOffer, die_index: int, face_index: int) -> Dictionary:
	var entry := _get_face_entry(run_state, die_index, face_index)
	if not bool(entry.get("valid", false)):
		return {"success": false, "reason": str(entry.get("reason", "目标骰面无效"))}
	if face_offer == null:
		return {"success": false, "reason": "候选无效"}

	var die: DieState = entry["die"]
	if face_offer.covers_pip() and not DieState.get_legal_pips(die.face_count).has(face_offer.pip):
		return {"success": false, "reason": "点数不适用于该骰子"}

	return {"success": true, "reason": ""}


func apply_to_target(run_state, face_offer: FaceOffer, die_index: int, face_index: int) -> Dictionary:
	var validation := can_apply_to_target(run_state, face_offer, die_index, face_index)
	if not bool(validation.get("success", false)):
		return {
			"success": false,
			"message": str(validation.get("reason", "目标骰面无效")),
			"changed_faces": [],
		}

	var entry := _get_face_entry(run_state, die_index, face_index)
	var face: FaceState = entry["face"]
	if face_offer.covers_pip():
		face.pip = face_offer.pip
	if face_offer.covers_ornament():
		face.ornament_id = FaceState.normalize_ornament_id(face_offer.ornament_id)
		face.material_id = &"none"
	if face_offer.covers_mark():
		face.mark_id = FaceState.normalize_mark_id(face_offer.mark_id)

	var message := "[补充包] 骰面改造：将 %s 第 %d 面覆盖为 %d / %s / %s。" % [
		_die_label(entry),
		face_index + 1,
		face.pip,
		DisplayNames.ornament_name(face.ornament_id),
		DisplayNames.mark_name(face.mark_id),
	]
	if run_state != null and run_state.has_method("record_shop_log"):
		run_state.record_shop_log(message, {
			"kind": &"booster_face",
			"die_index": die_index,
			"face_index": face_index,
			"offer_id": face_offer.offer_id,
		})
	return {
		"success": true,
		"message": message,
		"changed_faces": [{"die_index": die_index, "face_index": face_index}],
	}


func _make_face_offer(run_state, index: int) -> FaceOffer:
	var pip := _draw_legal_pip_seen_in_run(run_state)
	match index % 5:
		0, 1:
			return FaceOffer.create(
				StringName("face_offer_pip_%d_%d" % [index, pip]),
				"%d 点改造" % [pip],
				FaceOffer.COVER_PIP_ONLY,
				pip
			)
		2:
			var ornament_id := _draw_ordinary_ornament()
			return FaceOffer.create(
				StringName("face_offer_pip_orn_%d" % [index]),
				"%d 点 / %s" % [pip, DisplayNames.ornament_name(ornament_id)],
				FaceOffer.COVER_PIP_ORNAMENT,
				pip,
				ornament_id
			)
		3:
			var ornament_only := _draw_ordinary_ornament()
			return FaceOffer.create(
				StringName("face_offer_orn_%d" % [index]),
				DisplayNames.ornament_name(ornament_only),
				FaceOffer.COVER_ORNAMENT_ONLY,
				0,
				ornament_only
			)
		_:
			var mark_id: StringName = BASIC_MARK_POOL[rng.randi_range(0, BASIC_MARK_POOL.size() - 1)]
			return FaceOffer.create(
				StringName("face_offer_mark_%d" % [index]),
				DisplayNames.mark_name(mark_id),
				FaceOffer.COVER_MARK_ONLY,
				0,
				FaceState.ORN_NONE,
				mark_id
			)


func _to_booster_offer(face_offer: FaceOffer, index: int) -> BoosterOfferDef:
	return BoosterOfferDef.create(
		StringName("booster_face_%d_%s" % [index, str(face_offer.offer_id)]),
		face_offer.display_name,
		&"face",
		BoosterOfferDef.PAYLOAD_FACE_OFFER,
		face_offer.offer_id,
		face_offer.to_dict()
	)


func _draw_ordinary_ornament() -> StringName:
	var pool := ORDINARY_ORNAMENT_POOL
	return pool[rng.randi_range(0, pool.size() - 1)]


func _draw_legal_pip_seen_in_run(run_state) -> int:
	var pips: Array[int] = []
	if run_state != null:
		for die in run_state.dice:
			if die == null:
				continue
			for pip in DieState.get_legal_pips(die.face_count):
				if not pips.has(pip):
					pips.append(pip)
	if pips.is_empty():
		pips.append_array([1, 2, 3, 4, 5, 6])
	pips.sort()
	return pips[rng.randi_range(0, pips.size() - 1)]


func _get_face_entry(run_state, die_index: int, face_index: int) -> Dictionary:
	if run_state == null:
		return {"valid": false, "reason": "缺少本局状态"}
	if run_state.has_method("ensure_starting_dice"):
		run_state.ensure_starting_dice()
	if die_index < 0 or die_index >= run_state.dice.size():
		return {"valid": false, "reason": "目标骰子无效"}
	var die: DieState = run_state.dice[die_index]
	if die == null:
		return {"valid": false, "reason": "目标骰子无效"}
	if face_index < 0 or face_index >= die.faces.size():
		return {"valid": false, "reason": "目标骰面无效"}
	var face: FaceState = die.faces[face_index]
	if face == null:
		return {"valid": false, "reason": "目标骰面无效"}
	return {
		"valid": true,
		"die": die,
		"face": face,
		"die_index": die_index,
		"face_index": face_index,
	}


func _die_label(entry: Dictionary) -> String:
	var die: DieState = entry.get("die", null)
	var die_index := int(entry.get("die_index", -1))
	if die == null:
		return "D?-?"
	return "D%d-%d" % [die.face_count, die_index + 1]
