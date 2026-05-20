# DicePlayerOne 扔骰子系统与 Godot 移植研究

研究目录：`E:\researchDice`

原始项目目录：`D:\steam\steamapps\common\DicePlayerOne`

> 本文档只记录分析结论和移植建议。分析过程只读访问原游戏目录，生成文件放在 `E:\researchDice` 下，未向原游戏目录写入文件。

## 1. 项目形态

`DicePlayerOne` 是 Unity IL2CPP 成品包，不是 Unity 工程源码。

关键文件：

| 路径 | 作用 |
| --- | --- |
| `DicePlayerOne.exe` | Windows 启动程序 |
| `UnityPlayer.dll` | Unity 播放器 |
| `GameAssembly.dll` | IL2CPP 编译后的 C++/Native 代码 |
| `DicePlayerOne_Data\level0` | 主场景数据，包含大量 GameObject/Component |
| `DicePlayerOne_Data\sharedassets0.assets` | 场景共享资源、贴图、材质、部分 prefab/config |
| `DicePlayerOne_Data\resources.assets` | Resources 资源，包含部分骰子配置 |
| `DicePlayerOne_Data\il2cpp_data\Metadata\global-metadata.dat` | IL2CPP 元数据，可提取类名、方法名、字符串 |
| `DicePlayerOne_Data\StreamingAssets` | 视频 bundle、prototype.zip 等运行时资源 |

Unity 运行时信息：

- `app.info`：公司/组织为 `KDREAM`，产品名为 `DicePlayerOne`。
- `boot.config`：`build-guid=3167868df4674799a71a8ce9006a167b`。
- `ScriptingAssemblies.json` 显示使用了 Unity URP/Core Render Pipelines 14.0.12、TextMeshPro、DOTween、UniTask、UniRx、Odin/Sirenix、NCalc、XNode、Facepunch Steamworks、ACTk AntiCheat、ProCamera2D、SensorToolkit、EasySave3 等库。

结论：这是一个 Unity 3D/2.5D 骰子战斗/构筑类项目，核心逻辑在 IL2CPP native 代码里，资源和场景结构仍可从 assets 文件中恢复大量信息。

## 2. 资源规模概览

通过 UnityPy 对 Unity 资源做只读解析，主要对象分布如下。

### `level0`

主场景对象数约 72,230：

| 类型 | 数量 |
| --- | ---: |
| `MonoBehaviour` | 17,855 |
| `GameObject` | 17,274 |
| `RectTransform` | 11,652 |
| `CanvasRenderer` | 9,133 |
| `Transform` | 5,622 |
| `MeshRenderer` | 5,174 |
| `MeshFilter` | 3,608 |
| `Canvas` | 681 |
| `BoxCollider` | 344 |
| `Rigidbody` | 314 |
| `CanvasGroup` | 107 |
| `MeshCollider` | 46 |
| `ParticleSystem` | 40 |
| `Camera` | 1 |
| `AudioListener` | 1 |
| `Light` | 1 |
| `Animator` | 1 |
| `VideoPlayer` | 1 |

这说明游戏的主界面、战斗界面、骰子 prefab、商店/详情/结算 UI 很可能集中在单个大场景中，通过管理器和显隐状态切换。

### `sharedassets0.assets`

共享资源对象数约 23,860：

| 类型 | 数量 |
| --- | ---: |
| `MonoBehaviour` | 7,299 |
| `GameObject` | 3,381 |
| `Transform` | 2,998 |
| `ParticleSystem` | 2,874 |
| `ParticleSystemRenderer` | 2,874 |
| `Texture2D` | 1,851 |
| `Sprite` | 901 |
| `Material` | 569 |
| `RectTransform` | 383 |
| `CanvasRenderer` | 292 |
| `Mesh` | 60 |

### `resources.assets`

Resources 对象数约 2,302：

| 类型 | 数量 |
| --- | ---: |
| `MonoBehaviour` | 766 |
| `GameObject` | 489 |
| `RectTransform` | 476 |
| `CanvasRenderer` | 318 |
| `AudioClip` | 85 |
| `Texture2D` | 38 |
| `Sprite` | 32 |
| `MonoScript` | 1 |

## 3. 关键脚本与数据模型

从 `globalgamemanagers.assets`、`global-metadata.dat` 和场景 MonoBehaviour 关联中定位到以下核心类。

| 类/脚本 | 推测职责 | 证据 |
| --- | --- | --- |
| `DiceCtrl` | 单个骰子的场景控制、物理、显示、点击/选择状态 | `level0` 中约 313 个实例，挂在大量骰子 GameObject 上 |
| `DiceCls` | 骰子运行时数据类或领域模型 | 脚本路径 `Assets/_Script/DiceCls.cs` |
| `DiceNcalc` | 骰子公式/条件表达式解析 | 项目使用 NCalc，metadata 中存在大量公式 token |
| `DiceNode` | 骰子节点/面/效果配置 | `resources.assets` 13 个，`sharedassets0.assets` 849 个 |
| `DiceNG` | 骰子组合或节点图配置 | `resources.assets` 13 个，`sharedassets0.assets` 849 个 |
| `DiceGroupSO` | 骰组 ScriptableObject | `resources.assets` 1 个，`sharedassets0.assets` 50 个 |
| `DiceRuleSO` | 骰子规则 ScriptableObject | `sharedassets0.assets` 26 个 |
| `BattleMgr` | 战斗流程、投骰、结算前后的场景调度 | `level0` 有一个 `战斗管理器` |
| `ReadyMgr` | 局间/准备阶段管理 | `level0` 有一个 `局间管理器` |
| `GameMgr` | 全局主流程 | `level0` 有一个 `主管理器` |
| `ResultCtrl` | 结算 UI | `level0` 有一个 `结算Canvas` |
| `InfoCtrl` | 信息 UI | `level0` 有一个 `信息Canvas` |
| `RuleCtrl` | 规则展示/交互 | `level0` 有 13 个实例 |
| `StartMgr` | 开始界面 | `level0` 有一个 `开始界面Canvas` |

脚本路径示例：

- `Assets/_Script/ConfigScript/DiceGroupSO.cs`
- `Assets/_Script/ConfigScript/DiceNG.cs`
- `Assets/_Script/ConfigScript/DiceNode.cs`
- `Assets/_Script/ConfigScript/DiceRuleSO.cs`
- `Assets/_Script/DiceCls.cs`
- `Assets/_Script/DiceCtrl.cs`
- `Assets/_Script/DiceNcalc.cs`

注意：该包是 IL2CPP 成品，UnityPy 目前只能稳定读出 MonoBehaviour 的 Unity 基础字段和脚本关联，自定义序列化字段在当前解析结果里不可直接完整读取。要恢复 `DiceCtrl`、`BattleMgr`、`DiceNcalc` 的精确字段和方法体，需要用 Il2CppDumper、Cpp2IL、Ghidra/IDA 等工具继续反编译 `GameAssembly.dll` 和 `global-metadata.dat`。

## 4. 骰子 prefab/场景结构

游戏中的骰子不是单纯 2D 图片，而是带物理、mesh、世界空间 UI 和效果挂点的复合对象。

典型骰子对象：`主页面骰子`

```text
主页面骰子
├─ Transform
├─ DiceCtrl
├─ Rigidbody
├─ BoxCollider
├─ Canvas
│  ├─ 技能按钮
│  ├─ 购买按钮
│  ├─ 选择按钮
│  ├─ 名字
│  ├─ 名字2
│  ├─ Text (TMP)
│  ├─ 问号
│  ├─ 附魔指示
│  ├─ 附魔指示2
│  ├─ 未解锁
│  ├─ 锁定框
│  ├─ 选定框
│  ├─ 删除
│  ├─ 进度条
│  ├─ 点击区域
│  └─ 对话框
├─ 内骰子
│  ├─ 新内骰子
│  │  ├─ 骰子面1
│  │  │  └─ Text
│  │  ├─ 骰子面2
│  │  │  └─ Text
│  │  ├─ 骰子面3
│  │  │  └─ Text
│  │  ├─ 骰子面4
│  │  │  └─ Text
│  │  ├─ 骰子面5
│  │  │  └─ Text
│  │  └─ 骰子面6
│  │     └─ Text
│  ├─ 附魔模型
│  ├─ BOSS模型
│  ├─ 工具模型
│  └─ 内置中心点
└─ 特效位置
   ├─ 中心点
   ├─ 骰面
   └─ 顶点
```

同类结构还出现在：

- `新手引导骰子`
- `Boss骰子`
- `大学导演骰子`
- `爱情麻雀骰子`
- `打工麻雀骰子`
- `影像导演骰子`
- `暗黑导演骰子`
- `研究导演骰子`
- 大量 `新骰子 (...)`

### 物理组件样例

`主页面骰子` 的关键物理参数：

| 组件/字段 | 值 |
| --- | --- |
| `Transform.localPosition` | `(-15, 50, -9)` |
| `Transform.localRotation` | `(-0.8110383, 0, 0, 0.5849932)` |
| `Transform.localScale` | `(500, 500, 500)` |
| `Rigidbody.mass` | `1` |
| `Rigidbody.drag` | `0` |
| `Rigidbody.angularDrag` | `0.05` |
| `Rigidbody.useGravity` | `true` |
| `Rigidbody.isKinematic` | `true` 初始为真 |
| `Rigidbody.constraints` | `0` |
| `BoxCollider.center` | `(0, 0, 0)` |
| `BoxCollider.size` | `(0.24, 0.24, 0.24)` |
| `BoxCollider.material` | 外部资源引用 |

这个组合说明骰子在静态展示时被设为 kinematic，需要投掷时再交给物理系统。

### 骰子视觉层

`内骰子` 和 `新内骰子` 负责实际骰子模型：

| 节点 | 关键值 |
| --- | --- |
| `内骰子.localScale` | `(11, 11, 11)` |
| `新内骰子.localPosition` | `(0, 0, -0.0100000007)` |
| `新内骰子.localScale` | `(11.2181816, 11.2181816, 11.2181816)` |
| `新内骰子.MeshRenderer.material` | 外部资源引用 |

六个 `骰子面1` 到 `骰子面6` 子节点可以作为面文本/图标承载点，也可以作为判定朝上的 face marker。

## 5. 骰子盒与出生点

场景里有一个明确的投骰容器：`骰子盒`。

```text
骰子盒
├─ Animator
├─ 盒子
│  ├─ MeshFilter
│  ├─ MeshRenderer
│  ├─ MeshCollider
│  └─ Cube
│     └─ BoxCollider
├─ 盒盖
│  ├─ MeshFilter
│  ├─ MeshRenderer
│  ├─ MeshCollider
│  └─ Text (TMP)
└─ 骰子出生位置
```

关键参数：

| 节点/组件 | 值 |
| --- | --- |
| `骰子盒.localPosition` | `(-1.023, 0.537, -1.801)` |
| `骰子盒.Animator.enabled` | `false` |
| `盒子.localRotation` | `(-0.7020687, 0.0842590, 0.0842590, 0.7020687)` |
| `盒子.localScale` | `(30.8235435, 30.8235435, 30.8235435)` |
| `盒子.MeshCollider.convex` | `true` |
| `盒盖.localScale` | `(32.8296013, 32.8296013, 7.9075427)` |
| `盒盖.MeshCollider.convex` | `false` |
| `骰子出生位置.localPosition` | `(0, -0.2033349, 0)` |

推断：投骰流程大概率会从 `骰子出生位置` 生成/重置骰子，然后打开 rigidbody 物理，等待骰子停稳后结算。

## 6. 扔骰子功能的运行方式推断

以下是基于场景结构、组件参数、资源命名和脚本命名的推断，精确实现仍需 IL2CPP 反编译确认。

### 可能的流程

1. `BattleMgr` 或 `ReadyMgr` 选择当前需要投掷的 `DiceCtrl`。
2. 将骰子放到 `骰子盒/骰子出生位置` 或战斗区容器中的指定位置。
3. 重置骰子旋转和速度。
4. 将 `Rigidbody.isKinematic` 从 `true` 切到 `false`。
5. 给骰子施加初速度、冲量和随机角速度/扭矩。
6. 骰子与盒子、场景碰撞体发生物理碰撞。
7. 当线速度和角速度低于阈值，或 rigidbody 进入 sleep 状态时，锁定骰子。
8. 根据六个 `骰子面1..6` 的 world up 朝向，判断当前朝上的面。
9. 将结果交给 `DiceNcalc`、`DiceRuleSO`、`DiceNode`、`DiceNG` 等规则系统计算分数、触发技能、附魔、BOSS 效果。
10. 更新骰子自带 Canvas、战斗 UI、结算 UI 和音效/特效。

### 判面方式

骰子 prefab 中有明确的六个面节点和中心/面/顶点挂点：

- `骰子面1` 到 `骰子面6`
- `内置中心点`
- `特效位置/中心点`
- `特效位置/骰面`
- `特效位置/顶点`

Godot 移植时可直接用 face marker 判定：

```gdscript
func get_top_face(face_markers: Array[Node3D]) -> int:
    var best_index := -1
    var best_dot := -INF
    for i in face_markers.size():
        var marker := face_markers[i]
        var d := marker.global_transform.basis.y.dot(Vector3.UP)
        if d > best_dot:
            best_dot = d
            best_index = i
    return best_index + 1
```

如果每个面节点的本地 `+Y` 不一定是面法线，则需要在 Godot prefab 中统一 marker 朝向，或改用 `-Z/+Z` 等实际法线轴。

### 音效证据

共享资源中存在投掷/落下音效名称：

- `DICE on Cardboard, Throw and Roll, Foam, 1 One Die, v2/v3`
- `DICE on Cardboard, Throw and Roll, Metal, 1 One Die, v1/v2/v3`
- `DICE on Cardboard, Drop, Standard, 1 One Die, v1/v2`
- `DiceSkill`

这进一步支持“真实 rigidbody 滚动 + 停稳判定 + 规则结算”的架构。

## 7. 规则与公式系统

metadata 字符串中存在大量表达式 token，说明骰子结算不是硬编码在单个 if/else 中，而是数据驱动/公式驱动。

代表性 token：

| token | 可能含义 |
| --- | --- |
| `TX(ID)` / `STX(ID)` | 文本或状态文本查找 |
| `JOIN` / `JOIN2` | 拼接/组合 |
| `POINT` / `BPOINT` / `JPOINT` | 点数、基础点数、加成点数 |
| `PNUM(xxx)` | 指定条件数量 |
| `ISSELF` | 是否自身 |
| `DIDNUM()` / `DIDUSENUM()` | 骰子 ID/使用次数统计 |
| `COIN` / `USECOIN` | 金币与消耗 |
| `CSCORE` / `TSCORE` / `CTSCORE` / `LTSCORE` | 分数相关 |
| `MONTH:` / `HOUR:` | 时间/回合维度 |
| `BOXDICENUM:` / `BOXDICENUM2:` | 骰盒骰子数量 |
| `ROLLNUM` / `REROLLNUM` | 投掷/重投次数 |
| `HANDNUM` / `MHANDNUM` | 手牌或手中骰数量 |
| `LEFTEX` / `RIGHTEX` | 左右相邻/扩展效果 |
| `USEDICENUM` / `LOCKNUM` / `CARDNUM` | 使用、锁定、卡牌数量 |
| `BID(XXX)` | 根据 ID 查询 |
| `FILLNUM` | 填充数量 |
| `NEWDICE` | 新骰子 |
| `GETEX(xxx)` / `GETALLEX(xxx)` | 获取扩展/效果 |
| `BOSS` / `ISBOSS` | BOSS 骰相关 |
| `CHARGENUM` / `MAXCHARGE` | 充能 |
| `USECHARGENUM(xxx)` / `ADDCHARGENUM(xxx)` | 使用/增加充能 |
| `RULENAME(xxx)` | 规则名 |
| `ALL` / `UP` / `DOWN` / `SELECT` / `RANDOM` | 选择范围或方向 |
| `BOX` / `POOL` | 骰盒/池 |
| `LRECORD()` / `RECORDT()` | 历史记录 |
| `HAVE()` / `GAME()` | 状态查询 |

Godot 移植时不建议把这些规则散落到各个脚本里。应保留数据驱动架构：

- `DiceDefinition`：骰子基础信息、六面、标签、稀有度、模型/UI 配置。
- `DiceFace`：单面点数、文本、图标、触发条件、效果表达式。
- `DiceRule`：规则名、触发时机、目标选择、条件表达式、效果表达式。
- `DiceRuntimeState`：战斗内临时状态，如锁定、充能、投掷次数、是否 BOSS、附魔等。
- `DiceExpressionContext`：提供 token 函数和运行时变量。

可选实现方式：

1. 用 Godot `Expression` 实现简单数学/布尔表达式，但自定义函数支持有限，需要包一层 token registry。
2. 自己写一个小型 DSL 解释器，只覆盖当前游戏实际使用的 token。
3. 用 C# 版 Godot，并引入 NCalc 或兼容表达式库，这样最接近 Unity 原实现。

如果目标是快速复刻玩法，优先选 2；如果目标是尽量还原原项目数据，优先选 3。

## 8. UI 构建方式

UI 同时存在两层：

### 1. 骰子自带 UI

每个骰子 prefab 内部都有 Canvas，挂着：

- `技能按钮`
- `购买按钮`
- `选择按钮`
- `名字`
- `名字2`
- `问号`
- `附魔指示`
- `未解锁`
- `锁定框`
- `选定框`
- `删除`
- `进度条`
- `点击区域`
- `对话框`

这类 UI 与单个骰子强绑定，负责商店、选择、展示、提示、解锁、技能等状态。

### 2. 管理器/界面 Canvas

场景中还有多个整体 UI：

- `开始界面Canvas`
- `信息Canvas`
- `结算Canvas`
- `战斗管理器` 下的大量战斗 UI
- `骰子选择`
- `骰子详情`
- `骰子结算`
- `挑战商店骰子容器`
- `商店骰子容器`
- `历史骰子容器`
- `BOSS骰区域`
- `BOSS骰子容器`

Unity 侧使用 uGUI、CanvasRenderer、TextMeshPro。Godot 迁移时可拆成：

- 全局 `Control` UI：主菜单、战斗 HUD、结算、商店、详情面板。
- 骰子 overlay UI：名字、选中框、锁定框、进度条等，不建议全部作为 `RigidBody3D` 子节点一起旋转。
- 必须贴在骰子模型上的面文本/图标：用 `Label3D`、`Sprite3D` 或贴图材质。

## 9. Godot 移植架构建议

建议 Godot 项目采用“物理场景 + 数据驱动规则 + 屏幕空间 UI”的结构，而不是逐字复刻 Unity 的层级。

### 场景划分

```text
res://scenes/main/Main.tscn
├─ GameManager
├─ CameraRig
├─ BattleRoot
│  ├─ BattleManager
│  ├─ DiceBox
│  ├─ DiceContainer
│  └─ EffectContainer
└─ UI
   ├─ StartScreen
   ├─ BattleHud
   ├─ DiceInfoPanel
   ├─ ShopPanel
   └─ ResultPanel
```

### 骰子场景

```text
Dice.tscn
├─ RigidBody3D
│  ├─ CollisionShape3D
│  ├─ VisualRoot
│  │  ├─ MeshInstance3D
│  │  ├─ FaceMarkers
│  │  │  ├─ Face1
│  │  │  ├─ Face2
│  │  │  ├─ Face3
│  │  │  ├─ Face4
│  │  │  ├─ Face5
│  │  │  └─ Face6
│  │  ├─ FaceLabels 或贴图材质
│  │  ├─ EnchantModel
│  │  ├─ BossModel
│  │  └─ ToolModel
│  ├─ EffectSockets
│  │  ├─ Center
│  │  ├─ Face
│  │  └─ Vertex
│  └─ ClickArea
└─ DiceOverlayPresenter
```

建议脚本：

| 脚本 | 职责 |
| --- | --- |
| `dice_body.gd` | 物理控制、投掷、停稳判定、判面 |
| `dice_visual.gd` | 面文本、材质、附魔/BOSS/工具模型显隐 |
| `dice_overlay_presenter.gd` | 把骰子世界坐标投影到屏幕 UI |
| `dice_definition.gd` | Resource，静态骰子定义 |
| `dice_rule.gd` | Resource，规则配置 |
| `dice_expression.gd` | 公式 token 解析和执行 |
| `battle_manager.gd` | 投骰流程、回合、结算 |
| `dice_registry.gd` | 加载所有骰子定义和规则 |

### Godot 投骰伪代码

```gdscript
extends RigidBody3D

signal roll_finished(face_index: int)

@export var linear_impulse_range := Vector2(2.5, 5.0)
@export var torque_impulse_range := Vector2(5.0, 12.0)
@export var settle_linear_threshold := 0.05
@export var settle_angular_threshold := 0.05
@export var settle_time := 0.35

@onready var face_markers: Array[Node3D] = [
    %Face1, %Face2, %Face3, %Face4, %Face5, %Face6
]

var _settle_accumulator := 0.0
var _rolling := false

func throw_from(spawn_transform: Transform3D) -> void:
    global_transform = spawn_transform
    linear_velocity = Vector3.ZERO
    angular_velocity = Vector3.ZERO
    freeze = false
    sleeping = false
    _rolling = true
    _settle_accumulator = 0.0

    var forward := -global_transform.basis.z
    var impulse := forward * randf_range(linear_impulse_range.x, linear_impulse_range.y)
    impulse += Vector3.UP * randf_range(1.0, 2.0)
    apply_central_impulse(impulse)
    apply_torque_impulse(Vector3(
        randf_range(-1.0, 1.0),
        randf_range(-1.0, 1.0),
        randf_range(-1.0, 1.0)
    ).normalized() * randf_range(torque_impulse_range.x, torque_impulse_range.y))

func _physics_process(delta: float) -> void:
    if not _rolling:
        return

    var settled := linear_velocity.length() < settle_linear_threshold \
        and angular_velocity.length() < settle_angular_threshold

    if settled:
        _settle_accumulator += delta
    else:
        _settle_accumulator = 0.0

    if _settle_accumulator >= settle_time:
        _rolling = false
        freeze = true
        roll_finished.emit(get_top_face())

func get_top_face() -> int:
    var best_index := 0
    var best_dot := -INF
    for i in face_markers.size():
        var d := face_markers[i].global_transform.basis.y.dot(Vector3.UP)
        if d > best_dot:
            best_dot = d
            best_index = i
    return best_index + 1
```

### DiceBox 场景

```text
DiceBox.tscn
├─ Node3D
│  ├─ StaticBody3D
│  │  ├─ BoxCollision
│  │  └─ WallCollisions
│  ├─ Lid
│  │  ├─ MeshInstance3D
│  │  └─ AnimationPlayer
│  └─ SpawnPoint
```

Unity 中 `盒子` 使用 `MeshCollider.convex=true`，`盒盖` 使用非 convex mesh collider。Godot 中建议不要直接依赖复杂三角面碰撞，先用多个 `BoxShape3D`/`ConvexPolygonShape3D` 近似，稳定性更好，也更容易调投骰手感。

## 10. Unity 到 Godot 对应表

| Unity | Godot |
| --- | --- |
| `GameObject` | `Node` / `Node3D` / `Control` |
| `Transform` | `Node3D.transform` |
| `Rigidbody` | `RigidBody3D` |
| `Rigidbody.isKinematic=true` | `RigidBody3D.freeze=true` 或切换物理模式 |
| `BoxCollider` | `CollisionShape3D` + `BoxShape3D` |
| `MeshCollider` | `CollisionShape3D` + `ConcavePolygonShape3D` / `ConvexPolygonShape3D` |
| `MeshRenderer` + `MeshFilter` | `MeshInstance3D` |
| `Canvas` / uGUI | `Control` UI 或 `SubViewport`/`Label3D` |
| `TextMeshPro` | `Label` / `RichTextLabel` / `Label3D` |
| `Animator` | `AnimationPlayer` / `AnimationTree` |
| `ScriptableObject` | `Resource` |
| `Resources` | `res://data` Resource/JSON 目录 |
| `DOTween` | Godot `Tween` |
| `UniTask` | Godot signal/await |
| `NCalc` | Godot `Expression`、自研 DSL、或 Godot C# + NCalc |

## 11. 迁移注意点

1. **不要照搬 Unity 的缩放值。** 原场景里出现 root scale `500`、内部 dice scale `11`、collider size `0.24` 这类组合，说明 Unity 资产单位和 UI/相机布局强绑定。Godot 应归一化到清晰单位，例如骰子边长 `1.0`，相机和 UI 再重新适配。
2. **UI 不要全部绑在刚体下。** Unity prefab 把很多 Canvas 子节点挂在骰子里，但 Godot 里如果这些 UI 跟着刚体旋转，会难以保持可读和可点。建议把交互 UI 做成屏幕 overlay，只把真正贴在骰子面的文本/图标做成 3D。
3. **规则系统优先迁移数据结构。** 该游戏核心复杂度在 `DiceNcalc`、`DiceRuleSO`、`DiceNode`，不在物理投掷本身。Godot 原型应先跑通“投骰 -> 判面 -> 触发规则 -> 更新 UI”的闭环。
4. **物理手感需要重新调。** Unity PhysX 和 Godot Physics/Jolt 参数不同，mass、drag、angularDrag、physic material 不能一比一照搬。
5. **面判定要使用稳定 marker。** 不要用碰撞点或欧拉角硬判断；每面放一个朝外 marker，用 dot product 判断最稳。
6. **原资产授权要单独处理。** 如果目标是公开发布 Godot 版本，不能默认复制 Steam 游戏内模型、贴图、音效和视频。技术移植和资产复用是两件事。

## 12. 仍需反编译确认的点

以下内容目前只能推断，不能当作最终源码级结论：

- `DiceCtrl` 具体如何施加力、扭矩和随机旋转。
- `BattleMgr` 是否真正使用 `骰子出生位置`，以及回合内投骰队列如何组织。
- 骰子停稳阈值、超时重投、卡住处理逻辑。
- 判面轴向到底使用哪个本地轴。第 16 节已修正：主结果不靠最终物理朝向判面，而是先写入 face index，再旋转内部 mesh。
- `DiceNcalc` 的 token 映射、变量上下文和副作用函数。
- `DiceGroupSO`、`DiceNG`、`DiceNode`、`DiceRuleSO` 的完整字段结构。
- 特效、附魔、BOSS、工具模型的运行时显隐条件。

推荐后续工具：

- `Il2CppDumper` 或 `Cpp2IL`：从 `GameAssembly.dll` + `global-metadata.dat` 导出类型、字段、方法签名。
- `dnSpyEx`/`ILSpy`：查看 Cpp2IL 生成的伪 C#。
- `AssetRipper`：尝试恢复 Unity 工程结构和 prefab/ScriptableObject 字段。
- `Ghidra`/`IDA`：必要时分析 native 方法体。

所有这些工具的输出也应放在 `E:\researchDice` 下，避免污染原游戏目录。

## 13. 建议的 Godot 原型里程碑

### 阶段 A：最小投骰闭环

- 建 `Dice.tscn`：`RigidBody3D` + `BoxShape3D` + cube mesh + 6 个 face marker。
- 建 `DiceBox.tscn`：简单盒体碰撞 + `SpawnPoint`。
- 实现投掷、停稳、判面。
- 显示一个战斗 HUD，输出当前面数。

### 阶段 B：数据驱动骰子

- 建 `DiceDefinition` Resource。
- 每个 face 有文本、点数、标签和效果表达式。
- 用 JSON/Resource 加载一组测试骰子。
- UI 可查看骰子详情、锁定、选择。

### 阶段 C：规则系统

- 实现 `DiceExpressionContext`。
- 支持第一批 token：`POINT`、`ROLLNUM`、`REROLLNUM`、`COIN`、`LOCKNUM`、`USEDICENUM`、`BOSS`、`ISBOSS`。
- 跑通投骰后结算分数和触发效果。

### 阶段 D：还原完整场景

- 增加商店、历史骰子容器、BOSS 区、结算界面。
- 增加附魔/工具/BOSS 模型。
- 增加音效和特效挂点。
- 根据反编译结果补齐复杂规则。

## 14. 总结

`DicePlayerOne` 的扔骰子系统由三部分组成：

1. **物理骰子 prefab**：`DiceCtrl` + `Rigidbody` + `BoxCollider` + mesh + 六面节点 + 效果挂点。
2. **战斗/场景管理器**：`BattleMgr`、`ReadyMgr`、`GameMgr` 负责生成、投掷、状态切换和结算。
3. **数据驱动规则层**：`DiceNcalc`、`DiceNode`、`DiceNG`、`DiceGroupSO`、`DiceRuleSO` 负责把骰面和状态变成分数、技能、附魔和特殊效果。

Godot 移植的关键不是机械复制 Unity 层级，而是保留这三个边界：

- `RigidBody3D` 负责可见、可调的投骰手感。
- `Resource/JSON` 负责可编辑的骰子和规则数据。
- `Control` UI 负责可读、可维护的界面层。

按这个方式迁移，可以先用很少的资产做出完整玩法闭环，再逐步替换视觉、音效和复杂规则。

## 15. 反编译与序列化补充结果

在后续分析中尝试使用 Il2CppDumper 解析：

- 工具版本：`Il2CppDumper v6.7.46`
- 输入：`GameAssembly.dll` + `global-metadata.dat`
- 结果：未能直接解析，报错为 metadata not found or encrypted。
- 证据：`global-metadata.dat` 前 32 字节为 `1d 81 39 ff bd f7 9d 19 9f a1 33 ce 13 11 1d 6e 5b cd ab 1a 2b 6e d1 50 67 04 9c 08 98 47 d6 71`，标准 IL2CPP metadata magic `af 1b b1 fa` 在文件中偏移为 `-1`。

结论：metadata 字符串区仍可读，但文件头不是标准 IL2CPP metadata header。要恢复方法体，需要先解决 metadata 加密/混淆，或运行游戏后做内存中的解密 metadata dump。

### 已确认的场景引用

通过扫描 `MonoBehaviour` 原始序列化块中的 `PPtr` 引用，已把部分推断推进为序列化证据。

`DiceCtrl`：

- `主页面骰子` 的 `DiceCtrl#70568` 明确引用 `Rigidbody#32103`、`BoxCollider#32627`。
- 同一 `DiceCtrl` 明确引用多个 `MeshRenderer`、`Transform:内骰子`、`Transform:骰面`、`Transform:中心点`、`Transform:顶点`、`Transform:内置中心点`、`Canvas` 和一组 UI MonoBehaviour。
- `Boss骰子` 的 `DiceCtrl#60183` 有相同结构，说明普通骰子和 BOSS 骰走同一套 prefab 控制模式。

`ReadyMgr`：

- `ReadyMgr#60359` 明确引用 `Transform:骰子出生位置#17804`。
- 同一管理器还引用 `Animator#32712`、`Transform:盒盖#21571`、`骰子展示位置`、`骰子显现位置`、`传送门位置`、`卡牌显现位置`、`商店骰子容器`、`BOSS骰子容器`、`挑战商店骰子容器`、`场景中心`、`摄像机位置` 等。
- 这基本确认“骰子出生位置”不是孤立命名节点，而是局间/准备流程实际持有的投放锚点。

`BattleMgr`：

- `BattleMgr#61560` 的可见序列化字段包括 `m_bagDfgs`、`m_tombDfgs`、`m_usingDfgs`、`m_scoreDfgs`、`m_destroyDfgs`、`m_tempDfgs`、`m_unlockDfgs`、`m_bossDfg`、`m_hotDfgs`。
- 它明确引用 `ResultCtrl#62025`，以及 `骰子容器`、`卡牌容器`、`卡牌容器 (1)`、`审判骰子容器`。
- 这说明战斗阶段确实维护多组骰子运行时列表：背包、墓地、使用中、计分、销毁、临时、解锁、BOSS、热门/热规则相关。

`GameMgr`：

- `GameMgr#61293` 明确引用 `ReadyMgr#60359`、`BattleMgr#61560`、`StartMgr#61051` 和 `VideoPlayer#54374`。
- 这确认主流程是 `GameMgr` 串起开始界面、局间准备、战斗和视频播放。

### 已确认的配置结构

从 `resources.assets` 和 `sharedassets0.assets` 的 ScriptableObject 风格 MonoBehaviour 中确认：

- `resources.assets`：`DiceNG` 13 个、`DiceNode` 13 个、`DiceGroupSO` 1 个。
- `sharedassets0.assets`：`DiceNG` 849 个、`DiceNode` 849 个、`DiceGroupSO` 50 个、`DiceRuleSO` 26 个。

`DiceNode` 可见字段/类型：

- `m_unlockDescribes`
- `m_otherDescribes`
- `m_faces`
- `List<DiceFace>`
- `DiceFace`
- `m_type`
- `m_val`

这确认每个骰子节点拥有解锁描述、额外描述和多个面配置；每个面主要由类型和值构成。

`DiceNG`：

- 示例 `186腾龙` 引用 `DiceNode:骰子`、效果对象和多个动画对象。
- 示例 `E0255魅惑` 同样引用 DiceNode、效果和动画对象。

`DiceRuleSO`：

- 示例 `10小顺` 引用 `DiceNG:倍率10`、`DiceNG:填写10` 和一个 `Sprite`。
- 这说明规则 SO 并非只存文本，它直接组合 DiceNG 配置和图标资源。

### 当时仍未源码级确认的点

以下是本阶段当时仍需要解密 metadata 或做内存 dump/Native 反汇编后才能确认的点；其中投骰 API 和停稳阈值已经在第 16 节通过运行时 `methodPointer` 反汇编补充确认。

- `DiceCtrl` 具体调用哪些 Unity 物理 API、施加多大的 force/torque。第 16 节已确认主投骰流程为“直接写 velocity + AddTorque”，不是 `AddForce`。
- 停稳阈值、超时重投、卡住处理逻辑。第 16 节已确认停稳使用 Unity `Vector3 == Vector3.zero` 的 `1e-10` 平方阈值；超时重投和卡住处理仍未完整确认。
- 判面到底使用哪个本地轴，以及是否有特殊修正。
- `DiceNcalc` 每个 token 的完整函数映射、上下文变量和副作用函数。

补充证据文件：

- `E:\researchDice\reverse\reports\il2cpp_scene_evidence.md`
- `E:\researchDice\reverse\reports\il2cpp_scene_evidence.json`

## 16. 运行时 methodPointer 反汇编补充

前面提到的 metadata 混淆并没有完全阻断分析。后续采用运行时 DLL 探针，通过 `GameAssembly.dll` 导出的 `il2cpp_*` API 枚举运行时 `MethodInfo`、字段、方法签名和 `methodPointer` RVA，再对关键 RVA 做反汇编。这样没有恢复完整 C# 源码，但已经可以确认投骰主链路。

新增证据文件：

- `E:\researchDice\reverse\runtime\il2cpp_runtime_dump.json`
- `E:\researchDice\reverse\reports\runtime_method_disasm.md`
- `E:\researchDice\reverse\reports\runtime_method_disasm.json`
- `E:\researchDice\reverse\reports\roll_flow_runtime_evidence.md`
- `E:\researchDice\reverse\reports\roll_flow_runtime_evidence.json`
- `E:\researchDice\reverse\reports\dice_face_rotations.md`
- `E:\researchDice\reverse\reports\dice_face_rotations.json`

### 已确认的关键字段

`DiceCtrl` 运行时字段确认：

- `m_rigidbody: UnityEngine.Rigidbody`，偏移 `0x60`。
- `m_collider: UnityEngine.BoxCollider`，偏移 `0x68`。
- `m_innerDice: UnityEngine.Transform`，偏移 `0xa0`。
- `m_innerFaceV3Lis: List<Vector3>`、`m_faceLis: List<MeshRenderer>`、`m_fxPosLis: List<Transform>`、`m_physicMaterial: List<PhysicMaterial>`。
- `m_canvas`、`m_clickArea`、`m_skillBtn`、`m_skillBtnText`、`m_lockImg` 等 UI 引用也在同一个控制器上。

`ReadyMgr` 运行时字段确认：

- `m_boxAnimator: Animator`。
- `m_boxTrans: Transform`。
- `m_boxDicePos: Transform`，这就是场景里的 `骰子出生位置`。
- 另有 `m_flyDicePos`、`m_showDicePos`、`m_shopDicePos`、`m_shopBossPos`、`m_diceCallPos` 等投放/展示锚点。

`BattleMgr` 运行时字段确认：

- `m_diceCon`、`m_cardCon`、`m_judgeCon`、`m_judgeDice`。
- `m_maxRollNum`、`m_rollNum`、`m_diceChangeNum`、`m_targetScoreNum`、`m_currentScoreNum`。
- 多组骰子列表继续印证了背包、墓地、使用中、计分、销毁、临时、解锁、BOSS 等运行时容器。

### 已确认的投骰流程

`DiceCtrl.RandomDice(int _sval, bool _needBroad)` 的异步状态机主体是 `<RandomDice>d__77.MoveNext`，RVA `0x6d8330`。

已确认行为：

- 投出前调用 `Rigidbody.set_isKinematic(false)`。
- 初始旋转由三次随机整数 `[-360, 360)` 生成，乘以 `0.01745329238` 后进入 `Quaternion.Internal_FromEulerRad`。
- 线速度不是通过 `Rigidbody.AddForce` 施加，而是构造向量后直接调用 `Rigidbody.set_velocity`。
- 线速度随机基础为三次 `Random.Range(0, 25)`，近似形态是 `(x, -y, z) * 0.1 * roll_multiplier`。
- 扭矩通过 `Rigidbody.AddTorque` 施加，`ForceMode` 参数的原始整数值为 `2`。
- 扭矩主要随机分量来自 `Random.Range(100, 200)` 并随机取正负，缩放常量为 `0.5 * roll_multiplier`。
- 投出时写入 `Rigidbody.maxAngularVelocity = 1000.0`。
- 状态机中没有观察到直接 `Rigidbody.AddForce` 调用；原报告里“施加 force”的说法应修正为“直接写线速度，再施加扭矩”。
- 同一状态机会调用 `RandomFace(-1, time)`，如果传入面值为 `-1`，则通过 `Random.Range(0, 6)` 先选出结果面索引。

相关常量：

| 含义 | RVA | 值 |
|---|---:|---:|
| Unity `Vector3` 等号平方阈值 | `0x2c0db60` | `9.99999944e-11` |
| Deg2Rad | `0x2c0db64` | `0.01745329238` |
| 扭矩缩放 | `0x2c0db70` | `0.5` |
| 投掷倍率偏移 | `0x2c0db80` | `1.0` |
| 物理材质分支阈值 | `0x2c0dbc0` | `5.0` |
| 最大角速度 | `0x2c0dde8` | `1000.0` |
| 线速度缩放 | `0x2c0ddf8` | `0.1` |

### 已确认的判面结果链路

这个点和前面的推断有明显差异：主链路不是“等物理骰子停下后检测哪个本地轴朝上”，而是“先选结果，再让内部骰子视觉转到对应面”。

证据链：

- `<RandomFace>d__78.MoveNext` 在 `_sval == -1` 时调用 `Random.Range(0, 6)`。
- 随后把选中的 face index 写入 `DiceCtrl.m_config.m_value`，也就是 `DiceCls.m_value: UniRx.IntReactiveProperty`。
- `DiceCtrl.ChangeInnerByVal(float _time)` 读取 `m_config.m_value.Value`，用它索引 `m_innerFaceV3Lis`，再把 `m_innerDice` 转到该预设本地欧拉角。
- `DiceCls.GetActualFaceOne()` 不读取刚体姿态；它读取 `m_value`，用这个索引访问 `m_runfaces`，返回对应 `DiceFace` 的值。
- `DiceCtrl.GetActualFaceNumer()` 同样根据 `m_config.m_value.Value` 走 UI/文本列表。

因此，原报告中“判面轴向到底使用哪个本地轴”的问题，对主投骰结果来说已经可以修正：主结果不依赖最终朝上的物理轴向。

`m_innerFaceV3Lis` 也已经从 `level0` 的 `DiceCtrl` 序列化数据里导出。普通骰 `MonoBehaviour#70568` 和 Boss 骰 `MonoBehaviour#60183` 完全一致：

| face index | Unity localEulerAngles.x | y | z |
|---:|---:|---:|---:|
| 0 | `0` | `0` | `0` |
| 1 | `90` | `0` | `0` |
| 2 | `0` | `0` | `90` |
| 3 | `0` | `0` | `-90` |
| 4 | `270` | `0` | `0` |
| 5 | `180` | `0` | `0` |

### 已确认的停稳与结算

`BattleMgr.AllDiceStop()` RVA `0x62a920` 明确调用 `DiceCtrl.CheckRollStop()` RVA `0x6b36a0`。

`CheckRollStop()` 的实际判断：

- 读取 `Rigidbody.velocity`。
- 读取 `Rigidbody.angularVelocity`。
- 两者都与 `Vector3.zero` 做 Unity `Vector3` 等号近似比较。
- 使用的平方距离阈值是 `9.99999944e-11`，接近“必须完全停住”，不是一个自定义的大容差。

`DiceCtrl.OnAfterRoll(int _sval, bool _needBroad)` RVA `0x6b5220` 已确认：

- 调用 `Rigidbody.set_isKinematic(true)`，把骰子锁回静态状态。
- 两次调用 `DiceCls.GetActualFaceOne()`。
- 根据 1..6 的判面结果调用 `ReadyMgr.AddRecord`，记录类型原始值为 `0x0f` 到 `0x14`。

### 对 Godot 移植的修正建议

Godot 侧投骰应按这个行为还原：

- 投出前：`RigidBody3D.freeze = false`，重置线速度和角速度，设置随机初始旋转。
- 投出时：直接写 `linear_velocity`，再施加扭矩；不要把 Unity 逻辑误移植成单纯 `apply_force`。
- 角速度限制：Godot 没有完全等价的 `maxAngularVelocity` 用户层 API 时，可以用 `angular_velocity` clamp 或物理参数近似。
- 停稳判断：同时检查 `linear_velocity.length_squared()` 和 `angular_velocity.length_squared()`，阈值可先用 Unity 的 `1e-10` 做源码级复刻；如果 Godot/Jolt 下永远不归零，则在原型中放宽到 `1e-4` 到 `1e-3` 并加稳定帧计数。
- 结果：如果目标是复刻原游戏，先随机/指定 face index，写入骰子状态，再把内部骰子 mesh 转到该 face 的预设本地角度；停稳后只读取这个已保存结果并更新记录/UI。
- 视觉旋转：Godot 里可按上表给内部骰子节点设置/补间本地旋转；注意 Unity/Godot 欧拉角顺序和坐标系不同，建议用测试场景逐面校正，而不是直接假设显示完全一致。
- 如果目标是做“真实物理判面”的 Godot 改造版，可以继续用 face marker + dot product，但这会偏离目前观察到的原实现。

仍未完全源码级恢复的点：

- `roll_multiplier` 的上游变量来自运行时对象/字典查询，反汇编已确认有 `+1` 和 `5.0` 材质分支阈值，但还没有还原成完整 C# 变量名。
- `m_innerFaceV3Lis` 角度表已导出；如果要 1:1 视觉复刻，还需要结合 Godot 坐标系做逐面截图校准。
- `DiceNcalc` 的 token 映射和副作用函数仍需要继续做运行时方法级分析。
