extends SceneTree


const BATTLE_SCREEN_PATH := "res://scenes/battle/BattleScreen.tscn"
const STAGE_SCENE_PATH := "res://scenes/battle/components/BattleDiceStage3D.tscn"


func _init() -> void:
	var scene := load(BATTLE_SCREEN_PATH) as PackedScene
	if scene == null:
		push_error("无法加载战斗场景：%s" % [BATTLE_SCREEN_PATH])
		quit(1)
		return

	var root := scene.instantiate()
	if root == null:
		push_error("无法实例化战斗场景：%s" % [BATTLE_SCREEN_PATH])
		quit(1)
		return

	var stage_scene := load(STAGE_SCENE_PATH) as PackedScene
	if stage_scene == null:
		push_error("无法加载 3D 骰子舞台：%s" % [STAGE_SCENE_PATH])
		root.free()
		quit(1)
		return

	root.set("battle_dice_stage_3d_scene", stage_scene)
	var packed := PackedScene.new()
	var pack_result := packed.pack(root)
	root.free()
	if pack_result != OK:
		push_error("打包战斗场景失败：%s" % [str(pack_result)])
		quit(1)
		return

	var save_result := ResourceSaver.save(packed, BATTLE_SCREEN_PATH)
	if save_result != OK:
		push_error("保存战斗场景失败：%s" % [str(save_result)])
		quit(1)
		return

	print("PASS: BattleScreen 已接入 BattleDiceStage3D")
	quit(0)
