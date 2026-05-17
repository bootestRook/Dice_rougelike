extends RefCounted
class_name ResolutionStep


const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


enum Phase {
	COMBO_BASE,
	PIP_SCORE,
	ORNAMENT_ON_SCORE,
	MARK_ON_SCORE,
	UNSELECTED_STAY,
	DIE_BODY,
	RELIC,
	ITEM,
	RETRIGGER,
	FINAL_XMULT,
	FINAL_SCORE,
}


var phase: int = Phase.COMBO_BASE

var source_type: StringName = &""
var source_id: StringName = &""
var source_display_name: String = ""

var bench_slot_index: int = -1
var resolution_index: int = -1
var relic_index: int = -1
var item_index: int = -1

var title: String = ""
var detail: String = ""
var floating_text: String = ""

var chips_delta: int = 0
var mult_delta: int = 0
var xmult_factor: float = 1.0

var chips_before: int = 0
var mult_before: int = 1
var xmult_before: float = 1.0

var chips_after: int = 0
var mult_after: int = 1
var xmult_after: float = 1.0

var partial_score_after: int = 0

var retrigger_target_resolution_index: int = -1
var retrigger_count: int = 0

var log_line: String = ""


func set_before(chips: int, mult: int, xmult: float) -> void:
	chips_before = chips
	mult_before = mult
	xmult_before = xmult


func set_after(chips: int, mult: int, xmult: float) -> void:
	chips_after = chips
	mult_after = mult
	xmult_after = xmult
	chips_delta = chips_after - chips_before
	mult_delta = mult_after - mult_before
	if is_zero_approx(xmult_before):
		xmult_factor = xmult_after
	else:
		xmult_factor = xmult_after / xmult_before
	partial_score_after = ScoreResult.final_score_for(chips_after, mult_after, xmult_after)
