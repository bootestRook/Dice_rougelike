extends RefCounted
class_name ScoreContext


const BattleState = preload("res://scripts/core/battle/BattleState.gd")
const HandState = preload("res://scripts/core/battle/HandState.gd")
const RunState = preload("res://scripts/core/battle/RunState.gd")
const RolledFace = preload("res://scripts/core/dice/RolledFace.gd")
const DieState = preload("res://scripts/core/dice/DieState.gd")


var selected_faces: Array[RolledFace] = []
var scored_faces: Array[RolledFace] = []
var all_rolled_faces: Array[RolledFace] = []
var unscored_faces: Array[RolledFace] = []
var selected_die_order: Array[int] = []
var battle_state: BattleState = null
var hand_state: HandState = null
var run_state: RunState = null
var source_dice: Array[DieState] = []
var primary_combo: StringName = &""
var combo_id: StringName = &""
var combo_type = &""
var display_combo_ids: Array[StringName] = []
var contained_patterns: Array[StringName] = []
var facts: Dictionary = {}
var active_tags: Array[StringName] = []
var tags: Array[StringName] = []
var condition_tags: Array[StringName] = []
var operation_tags: Array[StringName] = []
var state_tags: Array[StringName] = []
var used_reroll: bool = false
var is_last_hand: bool = false
var rerolls_used: int = 0
var coins_delta: int = 0
var score_events: Array[Dictionary] = []
var wild_effective_pips: Dictionary = {}
var rerolled_die_ids_this_round: Dictionary = {}
var body_triggered_flags_this_round: Dictionary = {}
var body_triggered_flags_this_battle: Dictionary = {}
var rng = null
var is_preview: bool = false
var defer_runtime_mutations: bool = false


func clear() -> void:
	selected_faces.clear()
	scored_faces.clear()
	all_rolled_faces.clear()
	unscored_faces.clear()
	selected_die_order.clear()
	battle_state = null
	hand_state = null
	run_state = null
	source_dice.clear()
	primary_combo = &""
	combo_id = &""
	combo_type = &""
	display_combo_ids.clear()
	contained_patterns.clear()
	facts.clear()
	active_tags.clear()
	tags.clear()
	condition_tags.clear()
	operation_tags.clear()
	state_tags.clear()
	used_reroll = false
	is_last_hand = false
	rerolls_used = 0
	coins_delta = 0
	score_events.clear()
	wild_effective_pips.clear()
	rerolled_die_ids_this_round.clear()
	body_triggered_flags_this_round.clear()
	body_triggered_flags_this_battle.clear()
	rng = null
	is_preview = false
	defer_runtime_mutations = false
