extends RefCounted
class_name ResolutionTrace


const ResolutionStep = preload("res://scripts/core/scoring/ResolutionStep.gd")
const ScoreResult = preload("res://scripts/core/scoring/ScoreResult.gd")


var trace_id: String = ""

var selected_dice: Array[Dictionary] = []
var unselected_dice: Array[Dictionary] = []
var selected_slot_indices: Array[int] = []
var selected_dice_order: Array[int] = []

var primary_combo_id: StringName = &""
var primary_combo_display_name: String = ""

var chips_initial: int = 0
var mult_initial: int = 1
var xmult_initial: float = 1.0

var chips_final: int = 0
var mult_final: int = 1
var xmult_final: float = 1.0
var hand_score_final: int = 0

var steps: Array[ResolutionStep] = []
var log_lines: Array[String] = []
var score_result: ScoreResult = null


func append_step(step: ResolutionStep) -> void:
	if step == null:
		return
	steps.append(step)
	if step.log_line != "":
		log_lines.append(step.log_line)


func resolution_index_for_bench_slot(slot_index: int) -> int:
	for index in range(selected_slot_indices.size()):
		if selected_slot_indices[index] == slot_index:
			return index
	return -1
