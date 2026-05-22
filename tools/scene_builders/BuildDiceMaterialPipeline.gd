extends SceneTree


const BUILDER_SCRIPT_PATH := "res://tools/scene_builders/DiceMaterialPipelineBuilder.gd"

var _builder: RefCounted = null


func _init() -> void:
	print("BuildDiceMaterialPipeline runner init")
	var builder_script := load(BUILDER_SCRIPT_PATH)
	if builder_script == null:
		push_error("Cannot load builder script: %s" % BUILDER_SCRIPT_PATH)
		quit(1)
		return
	_builder = builder_script.new()
	_builder.run(self)


func _process(delta: float) -> bool:
	if _builder == null:
		quit(1)
		return true
	return _builder.process_step(delta)
