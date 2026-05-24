extends RefCounted
class_name MapEventGenerator


const MapEventCatalog = preload("res://scripts/rules/event/MapEventCatalog.gd")
const MapEventChoice = preload("res://scripts/data_defs/MapEventChoice.gd")


const FIRST_PROTECTED_LAST_INDEX := 12


var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


func generate_event_choices(run_state, map_index: int, count: int = 3) -> Array:
	var circle := 1
	if run_state != null and run_state.has_method("get_circle_number"):
		circle = int(run_state.get_circle_number())
	var first_protected := _is_first_protected_segment(circle, map_index)
	var event_def := _roll_event_def(run_state, circle, first_protected)
	if event_def.is_empty():
		return []
	var options := MapEventCatalog.get_available_options(event_def, first_protected)
	var choices: Array = []
	var limit: int = maxi(options.size(), count)
	for option in options:
		if choices.size() >= limit:
			break
		choices.append(MapEventChoice.from_data(event_def, option, first_protected))
	return choices


func roll_event_def_for_debug(run_state, map_index: int) -> Dictionary:
	var circle := 1
	if run_state != null and run_state.has_method("get_circle_number"):
		circle = int(run_state.get_circle_number())
	return _roll_event_def(run_state, circle, _is_first_protected_segment(circle, map_index))


static func is_first_protected_segment(circle: int, map_index: int) -> bool:
	return circle == 1 and map_index > 0 and map_index <= FIRST_PROTECTED_LAST_INDEX


func _is_first_protected_segment(circle: int, map_index: int) -> bool:
	return is_first_protected_segment(circle, map_index)


func _roll_event_def(run_state, circle: int, first_protected: bool) -> Dictionary:
	var eligible := MapEventCatalog.get_eligible_event_defs(circle, first_protected)
	if eligible.is_empty():
		return {}
	var events_by_type := _events_by_type(eligible)
	var selected_type := _roll_event_type(events_by_type, run_state)
	if selected_type == &"":
		return {}
	var candidates: Array = events_by_type.get(selected_type, [])
	return _roll_event_from_candidates(candidates, circle)


func _events_by_type(events: Array[Dictionary]) -> Dictionary:
	var result := {}
	for event_def in events:
		var event_type := StringName(str(event_def.get("type", &"")))
		if not result.has(event_type):
			result[event_type] = []
		result[event_type].append(event_def)
	return result


func _roll_event_type(events_by_type: Dictionary, run_state) -> StringName:
	var weights := MapEventCatalog.get_generator_type_weights()
	var bias_type := &""
	var bias_multiplier := 1.0
	if run_state != null:
		bias_type = StringName(str(run_state.get("next_event_bias"))) if _object_has_property(run_state, "next_event_bias") else &""
		bias_multiplier = float(run_state.get("next_event_bias_multiplier")) if _object_has_property(run_state, "next_event_bias_multiplier") else 1.0
	var total := 0.0
	for event_type in weights.keys():
		if not events_by_type.has(event_type):
			continue
		var weight := float(weights[event_type])
		if event_type == bias_type:
			weight *= maxf(0.0, bias_multiplier)
		total += maxf(0.0, weight)
	if total <= 0.0:
		return &""
	var roll := rng.randf() * total
	var cursor := 0.0
	for event_type in weights.keys():
		if not events_by_type.has(event_type):
			continue
		var weight := float(weights[event_type])
		if event_type == bias_type:
			weight *= maxf(0.0, bias_multiplier)
		cursor += maxf(0.0, weight)
		if roll < cursor:
			return StringName(str(event_type))
	for event_type in events_by_type.keys():
		return StringName(str(event_type))
	return &""


func _roll_event_from_candidates(candidates: Array, circle: int) -> Dictionary:
	if candidates.is_empty():
		return {}
	var total := 0.0
	for candidate_any in candidates:
		total += maxf(0.0, MapEventCatalog.event_weight_for_circle(Dictionary(candidate_any), circle))
	if total <= 0.0:
		return Dictionary(candidates[rng.randi_range(0, candidates.size() - 1)]).duplicate(true)
	var roll := rng.randf() * total
	var cursor := 0.0
	for candidate_any in candidates:
		var candidate := Dictionary(candidate_any)
		cursor += maxf(0.0, MapEventCatalog.event_weight_for_circle(candidate, circle))
		if roll < cursor:
			return candidate.duplicate(true)
	return Dictionary(candidates[candidates.size() - 1]).duplicate(true)


func _shuffle_dictionaries(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var old_value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = old_value


func _object_has_property(object, property_name: String) -> bool:
	if object == null:
		return false
	for property in object.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false
