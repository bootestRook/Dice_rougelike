# DicePlayerOne Godot 移植任务书

目标：在 Godot 中复刻 `DicePlayerOne` 的核心投骰闭环、场景职责和 UI 结构，先做可玩的技术原型，再逐步补齐规则、视觉、音效和复杂数据。

本任务书基于 `E:\researchDice\DicePlayerOne_Godot_Port_Study.md`、运行时 IL2CPP 探针和场景序列化证据整理。原游戏目录只作为只读研究来源，Godot 项目和中间输出都应放在独立目录，不写入 `D:\steam\steamapps\common\DicePlayerOne`。

重要修正：这里的“3D”只指骰子底层物理和 mesh 旋转，不是要做一个自由视角 3D 桌面/沙盘场景。画面目标应是固定机位、UI 优先、接近原游戏的 2.5D 投骰界面；相机不可由玩家自由控制，3D 物理层可以放进 `SubViewport` 或固定 `Node3D` 区域里，只服务于骰子投掷表现。

## 1. 移植边界

### 必须复刻

- 骰子底层可由 `RigidBody3D` 驱动物理运动，但呈现方式必须是固定视角/2.5D，不做自由 3D 场景。
- 投出前先随机/指定结果 face index。
- 内部骰子 mesh 根据 face index 旋到预设角度。
- 线性运动通过直接写 `linear_velocity` 实现。
- 旋转运动通过扭矩/角速度实现。
- 停稳后冻结物理体，再读取已保存结果并更新 UI。
- 管理器职责保持接近原结构：`GameMgr`、`ReadyMgr`、`BattleMgr`、`DiceCtrl`、数据/规则层。

### 不要求第一阶段复刻

- 原游戏完整美术资源、音效、视频、后处理、TMP 字体效果。
- 全量 `DiceNG`、`DiceNode`、`DiceRuleSO`、`DiceGroupSO` 数据。
- `DiceNcalc` 的完整 token、副作用函数和特殊规则。
- Unity 物理数值 1:1 手感。

### 禁止误移植

- 不要把原投骰逻辑实现成单纯 `apply_force()`。
- 不要在停稳后通过本地轴朝上判断结果；原主链路是先选结果再显示。
- 不要把可读 UI 全部挂在滚动刚体下随骰子旋转。
- 不要默认复制 Steam 游戏内商业资源到 Godot 项目。
- 不要做大尺度斜视 3D 托盘、自由摄像机、GM 调试面板式界面作为正式方向。

## 2. Godot 技术假设

- Godot 版本：Godot 4.x。
- 脚本语言：优先 GDScript；如项目决定用 C#，保持同样模块边界。
- 物理：GodotPhysics 或 Jolt 都可以，但它只服务于骰子层，不能把项目导向自由 3D 沙盘。
- UI：以 `Control`/`CanvasLayer` 为主体。骰子物理层建议嵌在固定 `SubViewportContainer` 或固定机位 `Node3D` 下。
- 数据：第一阶段用 JSON 或 `.tres Resource`；正式编辑体验可再做 Godot Resource。

## 3. 推荐目录结构

```text
res://
  scenes/
    main/Game.tscn
    dice/Dice.tscn
    dice/DiceBox.tscn
    ui/BattleHUD.tscn
    ui/DiceInfoPanel.tscn
  scripts/
    managers/GameMgr.gd
    managers/ReadyMgr.gd
    managers/BattleMgr.gd
    dice/DiceCtrl.gd
    dice/DiceInstance.gd
    data/DiceDefinition.gd
    data/DiceFaceDefinition.gd
    data/DiceRuleDefinition.gd
    rules/DiceExpressionContext.gd
    rules/DiceRuleEvaluator.gd
    ui/BattleHUD.gd
  data/
    dice/test_dice.json
    rules/test_rules.json
  assets/
    placeholder/
```

## 4. 场景设计

### `Game.tscn`

职责：主运行界面，承载固定投骰视窗、骰子盒锚点、管理器和 HUD。这里不是自由 3D 场景；`Node3D` 只作为受控的骰子物理层。

推荐结构：

```text
Game : Control
  DiceViewport : SubViewportContainer
    SubViewport
      DiceWorld : Node3D
        WorldEnvironment
        DirectionalLight3D
        FixedCamera : Camera3D
        ThrowPlane : StaticBody3D
          CollisionShape3D
        Bounds : StaticBody3D
          CollisionShape3D
        DiceBoxAnchors : Node3D
          SpawnPoint : Marker3D
          FlyPoint : Marker3D
          ShowPoint : Marker3D
          ShopDicePoint : Marker3D
          BossDicePoint : Marker3D
        DiceContainer : Node3D
        CardContainer : Node3D
        JudgeDiceAnchor : Marker3D
  Managers : Node
    GameMgr
    ReadyMgr
    BattleMgr
  HUDLayer : CanvasLayer
    BattleHUD : Control
```

显示约束：

- `FixedCamera` 使用固定位置和固定 FOV/orthographic，不允许玩家自由旋转。
- `ThrowPlane` 和 `Bounds` 可以不可见，只用于物理碰撞，避免出现大桌面/大托盘主视觉。
- `BattleHUD` 是主画面组织者，骰子视窗只是其中一个受控区域。
- Debug/GM 控件只允许临时开发使用，不进入正式界面。

### `Dice.tscn`

职责：单个可投掷骰子。注意原游戏是外层刚体负责物理，内部骰子 mesh 根据预设结果旋转。

推荐结构：

```text
Dice : RigidBody3D
  CollisionShape3D
  ShellMesh : MeshInstance3D
  InnerDice : Node3D
    DiceMesh : MeshInstance3D
    FaceVisuals : Node3D
      Face0
      Face1
      Face2
      Face3
      Face4
      Face5
  FxAnchors : Node3D
    Center
    Face
    Vertex
    InnerCenter
  SelectArea : Area3D
  NumberLabel : Label3D
```

`Dice` 根节点挂 `DiceCtrl.gd`。

### `BattleHUD.tscn`

职责：显示回合状态、投骰按钮、当前结果、基础分、倍率分、最终分、锁定/选择状态。

推荐结构：

```text
BattleHUD : Control
  TopBar
    CoinLabel
    RollCountLabel
    TargetScoreLabel
  ResultPanel
    BaseScoreLabel
    RateLabel
    FinalScoreLabel
  RollButton
  DiceInfoPanel
  DebugPanel
    SelectedFaceLabel
    VelocityLabel
```

## 5. 核心常量

来自运行时反汇编和序列化证据：

```gdscript
const FACE_ROTATIONS_DEG := [
    Vector3(0.0, 0.0, 0.0),
    Vector3(90.0, 0.0, 0.0),
    Vector3(0.0, 0.0, 90.0),
    Vector3(0.0, 0.0, -90.0),
    Vector3(270.0, 0.0, 0.0),
    Vector3(180.0, 0.0, 0.0),
]

const UNITY_VECTOR3_EQUAL_EPS_SQ := 1.0e-10
const GODOT_STOP_EPS_SQ_INITIAL := 1.0e-4
const GODOT_STOP_STABLE_FRAMES := 8

const VELOCITY_SCALE := 0.1
const TORQUE_SCALE := 0.5
const MAX_ANGULAR_SPEED := 1000.0
```

说明：

- `FACE_ROTATIONS_DEG` 是 Unity `m_innerFaceV3Lis`，普通骰和 Boss 骰一致。
- `1e-10` 是 Unity `Vector3 == Vector3.zero` 的平方阈值。Godot 物理可能很难自然达到，应先用 `1e-4` 加连续稳定帧。
- Godot/Unity 坐标系和欧拉角顺序不同，面旋转表需要用逐面截图校准。

## 6. 脚本职责

### `DiceInstance.gd`

运行时骰子实例，对应原 `DiceCls` 的最小子集。

字段：

```gdscript
class_name DiceInstance
extends RefCounted

var definition: DiceDefinition
var run_faces: Array[DiceFaceDefinition] = []
var value: int = 0
var avatar: DiceCtrl
var is_locked: bool = false
var extra_score: int = 0
var buffs: Array = []
var enchanted: Array = []
```

方法：

- `get_actual_face_one() -> int`
- `get_actual_face() -> Array[int]`
- `get_actual_val(rule_ctrl) -> int`
- `send_message(trigger_type, ignore_ani := false, info := 0, source := null) -> void`

第一阶段只实现 `get_actual_face_one()`：

```gdscript
func get_actual_face_one() -> int:
    if value < 0 or value >= run_faces.size():
        return 0
    return run_faces[value].value
```

### `DiceCtrl.gd`

对应原 `DiceCtrl`。

核心字段：

```gdscript
class_name DiceCtrl
extends RigidBody3D

signal roll_started(dice: DiceCtrl)
signal roll_stopped(dice: DiceCtrl, face_index: int, face_value: int)

@export var inner_dice: Node3D
@export var number_label: Label3D
@export var select_area: Area3D

var config: DiceInstance
var is_rolling := false
var stable_frames := 0
var roll_multiplier := 1.0
```

核心方法：

- `init_dice(instance: DiceInstance, skip_init_app := false) -> void`
- `roll(requested_face := -1, need_broadcast := true) -> void`
- `random_face(requested_face := -1, tween_time := 0.15) -> void`
- `change_inner_by_value(tween_time := 0.15) -> void`
- `check_roll_stop() -> bool`
- `after_roll(need_broadcast := true) -> void`
- `show_number(show := true) -> void`

投骰伪代码：

```gdscript
func roll(requested_face := -1, need_broadcast := true) -> void:
    if config == null:
        return

    is_rolling = true
    stable_frames = 0
    freeze = false
    sleeping = false
    linear_velocity = Vector3.ZERO
    angular_velocity = Vector3.ZERO

    rotation_degrees = Vector3(
        randi_range(-360, 359),
        randi_range(-360, 359),
        randi_range(-360, 359)
    )

    random_face(requested_face, 0.15)

    var m := max(0.1, roll_multiplier)
    linear_velocity = Vector3(
        randi_range(0, 24),
        -randi_range(0, 24),
        randi_range(0, 24)
    ) * VELOCITY_SCALE * m

    var tx := randi_range(100, 199) * (1 if randi_range(0, 1) == 0 else -1)
    var tz := randi_range(100, 199) * (1 if randi_range(0, 1) == 0 else -1)
    var torque := Vector3(tx, 0.0, tz) * TORQUE_SCALE * m

    # Unity 原逻辑是 AddTorque(..., mode=2)。Godot 中先用扭矩冲量近似，再按手感调。
    apply_torque_impulse(torque)
    angular_velocity = angular_velocity.limit_length(MAX_ANGULAR_SPEED)

    roll_started.emit(self)
```

选面与内部旋转：

```gdscript
func random_face(requested_face := -1, tween_time := 0.15) -> void:
    var face_index := requested_face
    if face_index < 0:
        face_index = randi_range(0, 5)
    face_index = clampi(face_index, 0, 5)
    config.value = face_index
    change_inner_by_value(tween_time)

func change_inner_by_value(tween_time := 0.15) -> void:
    if inner_dice == null:
        return
    var target_deg := FACE_ROTATIONS_DEG[config.value]
    var target_rad := Vector3(
        deg_to_rad(target_deg.x),
        deg_to_rad(target_deg.y),
        deg_to_rad(target_deg.z)
    )
    var tween := create_tween()
    tween.tween_property(inner_dice, "rotation", target_rad, tween_time)
```

停稳检测：

```gdscript
func check_roll_stop() -> bool:
    var stopped := (
        linear_velocity.length_squared() <= GODOT_STOP_EPS_SQ_INITIAL
        and angular_velocity.length_squared() <= GODOT_STOP_EPS_SQ_INITIAL
    )
    if stopped:
        stable_frames += 1
    else:
        stable_frames = 0
    return stable_frames >= GODOT_STOP_STABLE_FRAMES
```

结算：

```gdscript
func after_roll(need_broadcast := true) -> void:
    freeze = true
    is_rolling = false
    var face_value := config.get_actual_face_one()
    show_number(true)
    roll_stopped.emit(self, config.value, face_value)
```

### `BattleMgr.gd`

对应原 `BattleMgr`。

核心字段：

```gdscript
class_name BattleMgr
extends Node

@export var dice_container: Node3D
@export var judge_dice: DiceCtrl
@export var hud: BattleHUD

var max_roll_num := 3
var roll_num := 0
var dice_change_num := 0
var target_score_num := 0
var current_score_num := 0

var bag_dices: Array[DiceInstance] = []
var tomb_dices: Array[DiceInstance] = []
var using_dices: Array[DiceInstance] = []
var score_dices: Array[DiceInstance] = []
var destroy_dices: Array[DiceInstance] = []
var temp_dices: Array[DiceInstance] = []
var unlock_dices: Array[DiceInstance] = []
var hot_dices: Array[DiceInstance] = []
var boss_dice: DiceInstance
```

核心方法：

- `create_dice_from_box(dices: Array[DiceInstance]) -> void`
- `roll_using_dices() -> void`
- `all_dice_stop() -> bool`
- `_physics_process(delta) -> void`
- `on_dice_change(send_msg := true) -> void`
- `compute_score(ignore_status := false) -> void`
- `check_fit_rule() -> void`
- `check_result() -> bool`
- `start_new_turn() -> void`

最小闭环：

```gdscript
func roll_using_dices() -> void:
    roll_num += 1
    for dice_instance in using_dices:
        if dice_instance.is_locked:
            continue
        dice_instance.avatar.roll(-1, true)

func _physics_process(_delta: float) -> void:
    if using_dices.is_empty():
        return
    if all_dice_stop():
        for dice_instance in using_dices:
            if dice_instance.avatar.is_rolling:
                dice_instance.avatar.after_roll(true)
        compute_score(false)

func all_dice_stop() -> bool:
    for dice_instance in using_dices:
        if dice_instance.avatar != null and dice_instance.avatar.is_rolling:
            if not dice_instance.avatar.check_roll_stop():
                return false
    return true
```

### `ReadyMgr.gd`

对应原 `ReadyMgr`。负责骰子盒、出生点、展示点、商店点和准备阶段状态。

字段：

```gdscript
class_name ReadyMgr
extends Node

@export var box_animator: AnimationPlayer
@export var box_trans: Node3D
@export var box_dice_pos: Marker3D
@export var fly_dice_pos: Marker3D
@export var show_dice_pos: Marker3D
@export var shop_dice_pos: Marker3D
@export var shop_boss_pos: Marker3D
@export var dice_call_pos: Marker3D

var dice_cfgs: Array[DiceInstance] = []
var hot_cfgs: Array[DiceInstance] = []
var record := {}
```

核心方法：

- `open_box() -> void`
- `create_initial_dices() -> Array[DiceInstance]`
- `add_record(record_type: String, add_val: int) -> void`
- `spawn_dice_avatar(instance: DiceInstance) -> DiceCtrl`

### `GameMgr.gd`

对应原 `GameMgr`，串起开始、准备、战斗、视频/菜单等流程。

字段：

```gdscript
class_name GameMgr
extends Node

@export var ready_mgr: ReadyMgr
@export var battle_mgr: BattleMgr
@export var hud: BattleHUD

var is_load_over := false
var save_data := {}
```

核心方法：

- `boot() -> void`
- `start_new_run() -> void`
- `enter_ready() -> void`
- `enter_battle() -> void`
- `save_game() -> void`
- `load_game() -> void`

## 7. 数据结构

### `DiceFaceDefinition.gd`

```gdscript
class_name DiceFaceDefinition
extends Resource

@export var value: int = 1
@export var type: String = "point"
@export var label: String = ""
@export var effect_expr: String = ""
```

### `DiceDefinition.gd`

对应 `DiceNode` / `DiceNG` 的最小可用合并版。

```gdscript
class_name DiceDefinition
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var dice_type: String = "normal"
@export var icon: Texture2D
@export var faces: Array[DiceFaceDefinition] = []
@export var description: String = ""
@export var unlock_conditions: Array[String] = []
@export var effects: Array[String] = []
```

### 测试 JSON

```json
{
  "id": "test_d6",
  "display_name": "测试骰子",
  "dice_type": "normal",
  "faces": [
    {"value": 1, "type": "point", "label": "1"},
    {"value": 2, "type": "point", "label": "2"},
    {"value": 3, "type": "point", "label": "3"},
    {"value": 4, "type": "point", "label": "4"},
    {"value": 5, "type": "point", "label": "5"},
    {"value": 6, "type": "point", "label": "6"}
  ]
}
```

## 8. 规则系统第一版

第一版只做最少 token，目标是投骰后能算分。

`DiceExpressionContext.gd` 字段：

```gdscript
var point := 0
var roll_num := 0
var reroll_num := 0
var coin := 0
var lock_num := 0
var use_dice_num := 0
var boss := null
var is_boss := false
```

第一批 token：

- `POINT`
- `ROLLNUM`
- `REROLLNUM`
- `COIN`
- `LOCKNUM`
- `USEDICENUM`
- `BOSS`
- `ISBOSS`

实现建议：

- 原型期可以不用完整表达式引擎，先做白名单 token 替换和简单四则表达式。
- 如果使用 Godot `Expression`，只允许本地上下文字段，避免执行任意函数。
- 副作用规则单独做命令表，例如 `ADD_COIN:3`、`REROLL:1`，不要混进分数表达式。

## 9. UI 任务

### 第一阶段 UI

- 投骰按钮。
- 当前回合投骰次数。
- 每个骰子的 face index 和 face value。
- 当前基础分、倍率分、最终分。
- Debug 面板显示 `linear_velocity.length()`、`angular_velocity.length()`、`stable_frames`。

### 第二阶段 UI

- 骰子详情面板。
- 锁定/解锁按钮。
- 选择状态。
- 商店骰子列表。
- Boss 区。
- 结算面板。

UI 规则：

- 屏幕可读 UI 放 `CanvasLayer`。
- 骰面文本可以放 `Label3D` 或贴图，但不要把操作按钮挂在滚动刚体下。
- Debug 面板保留到物理手感调完再隐藏。

## 10. 实施阶段

### 阶段 A：最小投骰闭环

文件：

- `res://scenes/main/Game.tscn`
- `res://scenes/dice/Dice.tscn`
- `res://scripts/dice/DiceCtrl.gd`
- `res://scripts/dice/DiceInstance.gd`
- `res://scripts/managers/BattleMgr.gd`
- `res://scenes/ui/BattleHUD.tscn`

任务：

- 创建固定投骰视窗、隐藏碰撞平面和固定相机；不要做可自由观看的大 3D 桌面。
- 创建一个骰子刚体。
- 实现 `roll()`、`random_face()`、`change_inner_by_value()`、`check_roll_stop()`、`after_roll()`。
- HUD 显示结果。

验收：

- 点击投骰按钮，骰子会移动并旋转。
- HUD 显示的结果和 `DiceInstance.value` 一致。
- 骰子停稳后会 freeze。
- 强制调用 `roll(0..5)` 能得到指定结果并转到对应内部角度。

### 阶段 B：数据驱动骰子

文件：

- `res://scripts/data/DiceDefinition.gd`
- `res://scripts/data/DiceFaceDefinition.gd`
- `res://data/dice/test_dice.json`

任务：

- 从 JSON/Resource 创建 `DiceInstance`。
- `run_faces` 来自配置，而不是写死 1..6。
- HUD 显示骰子名、面文本、面值。

验收：

- 改 JSON 后，不改脚本即可改变骰面数值。
- 多个骰子能同时生成并分别投掷。

### 阶段 C：管理器闭环

文件：

- `res://scripts/managers/GameMgr.gd`
- `res://scripts/managers/ReadyMgr.gd`
- `res://scripts/managers/BattleMgr.gd`

任务：

- `ReadyMgr` 从 `box_dice_pos` 生成骰子。
- `BattleMgr` 管理 `using_dices`、`score_dices`、`roll_num`。
- `GameMgr` 串起加载、准备、进入战斗。

验收：

- 开局自动生成一组骰子。
- 投骰后统一等待所有骰子停稳再结算。
- 新回合能重置状态并再次投骰。

### 阶段 D：规则和分数

文件：

- `res://scripts/rules/DiceExpressionContext.gd`
- `res://scripts/rules/DiceRuleEvaluator.gd`
- `res://data/rules/test_rules.json`

任务：

- 实现第一批 token。
- 实现基础分、倍率分、最终分。
- `BattleMgr.compute_score()` 使用规则系统。

验收：

- 每次投骰后分数能随骰面变化。
- Debug 面板能列出参与计算的骰子和 token 值。

### 阶段 E：场景和 UI 补全

任务：

- DiceBox 开盒动画。
- 商店骰子容器。
- Boss 骰子容器。
- 结算面板。
- 锁定/选择按钮。
- 粒子挂点：中心点、骰面、顶点、内置中心点。

验收：

- 场景动线接近原结构：准备区 -> 投骰区 -> 结算/商店。
- UI 不随骰子旋转，操作清晰。

### 阶段 F：手感校准

任务：

- 调整 mass、friction、bounce、linear/angular damp。
- 调整 `GODOT_STOP_EPS_SQ_INITIAL` 和稳定帧数。
- 校准 `linear_velocity` 和 `apply_torque_impulse` 的缩放。
- 逐面校准 `FACE_ROTATIONS_DEG` 在 Godot 坐标系下的视觉结果。

验收：

- 20 次投骰无卡死、无无限滚动。
- 停稳后结果不跳变。
- 骰子不会飞出固定投骰区域。
- 强制 0..5 面时视觉朝向可区分且 UI 结果正确。

## 11. 原 Unity 到 Godot 映射表

| Unity 原概念 | Godot 对应 |
|---|---|
| `DiceCtrl` | `DiceCtrl.gd` 挂在 `RigidBody3D` |
| `DiceCls` | `DiceInstance.gd` |
| `Rigidbody` | `RigidBody3D` |
| `BoxCollider` | `CollisionShape3D` + `BoxShape3D` |
| `m_innerDice` | `InnerDice: Node3D` |
| `m_innerFaceV3Lis` | `FACE_ROTATIONS_DEG` |
| `m_value: IntReactiveProperty` | `DiceInstance.value` |
| `ReadyMgr.m_boxDicePos` | `DiceBox/SpawnPoint: Marker3D` |
| `BattleMgr.m_diceCon` | `DiceContainer: Node3D` |
| `Canvas` / uGUI | `CanvasLayer` + `Control` |
| `DOTween` | Godot `Tween` |
| `ScriptableObject` | `Resource` 或 JSON |
| `DiceNcalc` | `DiceRuleEvaluator` |

## 12. 开发验收清单

- [ ] 所有新增文件在 Godot 项目目录或 `E:\researchDice`，没有写入原游戏目录。
- [ ] 首屏不是自由 3D 桌面/沙盘，玩家不能自由转相机。
- [ ] 骰子物理层只出现在固定投骰视窗或固定机位区域里。
- [ ] 正式 UI 不是 GM 调试面板，Debug 控件可隐藏或只在开发模式出现。
- [ ] `DiceCtrl.roll()` 不使用 `apply_force()` 作为主线性投掷方式。
- [ ] `DiceInstance.value` 在投出前已经确定。
- [ ] `InnerDice` 根据 `value` 转到对应内部角。
- [ ] 停稳检查同时检查线速度和角速度。
- [ ] 停稳后才调用 `after_roll()`。
- [ ] `after_roll()` 会 freeze 物理体。
- [ ] HUD 显示 face index、face value、分数。
- [ ] 能强制测试 0..5 面。
- [ ] 多骰子时 `BattleMgr.all_dice_stop()` 等全部停稳。

## 13. 可直接交给实现者的提示词

```text
请按 E:\researchDice\DicePlayerOne_Godot_Task_Book.md 实现 Godot 4.x 原型。
第一阶段只做固定视角/2.5D 的最小投骰闭环：Game.tscn、Dice.tscn、BattleHUD.tscn、DiceCtrl.gd、DiceInstance.gd、BattleMgr.gd。
核心要求：先随机 face index，写入 DiceInstance.value，再旋转 InnerDice；投骰时直接写 linear_velocity，再 apply_torque_impulse；停稳后 freeze 并读取保存结果。
画面要求：UI 优先，骰子物理层放在固定视窗里，不要做自由 3D 场景、大斜视桌面、GM 调试面板式成品界面。
不要复制原游戏资源，不要写入 D:\steam\steamapps\common\DicePlayerOne。
```

## 14. 后续仍需补齐

- `roll_multiplier` 的完整上游来源。
- 完整 `DiceNcalc` token 和副作用函数。
- 全量 `DiceNG`、`DiceNode`、`DiceRuleSO` 数据导出和转换。
- 真实 UI 视觉、音效、特效和动画。
- Godot 坐标系下 6 面视觉角度的最终校准。
