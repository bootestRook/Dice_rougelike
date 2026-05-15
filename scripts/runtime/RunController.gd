extends Node
class_name RunController


const RunState = preload("res://scripts/core/battle/RunState.gd")


signal run_started(run_state: RunState)
signal run_finished(run_state: RunState)


var run_state: RunState = null


func start_new_run() -> void:
	run_state = RunState.new()
	run_state.create_default_loadout()
	run_started.emit(run_state)


func finish_run() -> void:
	if run_state == null:
		return

	run_finished.emit(run_state)
