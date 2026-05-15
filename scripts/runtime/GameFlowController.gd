extends Node
class_name GameFlowController


signal flow_state_changed(state_id: StringName)


var current_state_id: StringName = &"boot"


func set_flow_state(state_id: StringName) -> void:
	current_state_id = state_id
	flow_state_changed.emit(current_state_id)


func enter_battle() -> void:
	set_flow_state(&"battle")


func enter_reward() -> void:
	set_flow_state(&"reward")


func enter_forge() -> void:
	set_flow_state(&"forge")
