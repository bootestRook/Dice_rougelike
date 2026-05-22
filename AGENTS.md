# AGENTS.md

> 适用范围：本文件放在仓库根目录时，约束整个 Godot 项目。若子目录存在更近的 `AGENTS.md`，以更近文件为准。  
> 项目：骰子构筑 Roguelite / dice-rougelike  
> 引擎：Godot 4.x，优先使用 GDScript，不引入 C# 或第三方运行时框架，除非任务明确要求。

---

## 1. 项目当前设计口径

本项目是一个以目标战力为唯一战斗目标的纯骰子构筑 Roguelite。

核心循环：

```text
投出所有出战骰
↓
选择骰子 → 重投所选
选择骰子 → 结算所选
↓
限定手数内累计战力达到目标
↓
战后 3 选 1 铸骰件
↓
安装到骰面
↓
下一场继续变强
```

必须遵守的当前口径：

- 不做血量、护甲、治疗、敌人攻击、防御回合。
- 不做独立“锁定”操作。
- 玩家操作是“选择骰子后重投”或“选择骰子后结算”。
- 单个骰面常规维度只保留：`点数 / 面饰 / 印记`。
- 整颗骰子的扩展维度是：`面数 / 骰胚 / 面分布`。
- 普通战奖励优先是：点数片、面饰片、印记片、复合件。
- 符文、等级、骰面材质不作为当前常规骰面槽位。
- 所有玩家可见文本必须是中文。

内部英文 ID 可以继续使用，例如：

```text
pip, ornament_id, mark_id, body_id
chip, mult, burst, stay
red, blue, purple
standard, iron, glass, biased, hollow, mirror
```

但 UI、结算日志、奖励描述、安装提示不得直接显示内部英文 ID。

---

## 2. 开发优先级

Codex 修改项目时，优先级如下：

1. **脚本逻辑**
   - `res://scripts/core/`
   - `res://scripts/rules/`
   - `res://scripts/runtime/`
   - `res://scripts/ui/`
   - `res://scripts/data_defs/`

2. **工具脚本 / 生成脚本**
   - `res://tools/`
   - `res://tools/editor/`
   - `res://tools/scene_builders/`
   - `res://tests_or_debug/`

3. **测试与调试脚本**
   - `res://tests_or_debug/Debug*.gd`
   - 每次规则变更必须补或更新对应 Debug 测试。

4. **资源定义 / 内容数据**
   - `res://content/`
   - `.tres` / `.res` 可以改，但不要批量手写无结构资源。

5. **导出配置**
   - `export_presets.cfg`
   - 仅在任务明确涉及打包、导出、图标、平台配置时修改。

6. **场景文件**
   - `.tscn` 可以小规模修改。
   - 对复杂场景、复杂 UI、批量节点变化，不要直接大量手写 `.tscn`。
   - 优先写 EditorScript 或小型生成 / 修补脚本，再用 Godot 运行生成或修改场景。

---

## 3. 场景编辑原则

### 3.1 可以直接改 `.tscn` 的情况

以下情况可以直接编辑 `.tscn`：

- 修改少量 Label 文案。
- 调整少量节点路径、脚本绑定、按钮文案。
- 添加一两个简单节点。
- 修复明显错误的 NodePath。

### 3.2 不应直接大量改 `.tscn` 的情况

以下情况必须优先写生成 / 修补脚本：

- 重排大型 UI 层级。
- 批量创建按钮、卡片、槽位、骰面格子。
- 大量修改 Control 的锚点、容器、尺寸、主题。
- 新建复杂界面，例如 BattleScreen、ForgeInstallScreen、RunResultScreen 的大段结构。
- 需要稳定复现的 UI 布局生成。

推荐做法：

```text
1. 写小型脚本到 res://tools/scene_builders/ 或 res://tools/editor/
2. 让脚本加载 / 创建 / 修改 PackedScene
3. 用 Godot 运行脚本
4. 检查生成后的 .tscn diff
5. 保留脚本，方便下次重复生成或修补
```

示例命名：

```text
res://tools/scene_builders/RebuildBattleScreenLayout.gd
res://tools/scene_builders/PatchForgeInstallScreen.gd
res://tools/editor/GenerateDiceSlotViews.gd
```

生成脚本要求：

- 节点命名稳定。
- 不依赖随机数，除非任务明确要求。
- 不覆盖无关节点。
- 不删除用户已有手工节点，除非任务明确要求。
- 运行后输出修改摘要。

---

## 4. Godot 运行与验证

不要只凭静态分析判断成功。完成任务后尽量运行 Godot 验证。

### 4.1 Godot 命令

优先使用环境变量或系统可用命令：

```powershell
$env:GODOT_BIN
```

如果项目已有明确路径，可以使用现有路径。不要强行假设固定路径。

常用命令模板：

```powershell
& $env:GODOT_BIN --headless --path . --quit-after 3
```

运行 Debug 脚本：

```powershell
& $env:GODOT_BIN --headless --path . --script "res://tests_or_debug/DebugCoreSmokeTest.gd"
```

如果 `$env:GODOT_BIN` 不存在，先尝试：

```powershell
godot --headless --path . --quit-after 3
```

如果仍失败，在完成说明中写清楚无法运行的原因，不要伪造测试通过。

### 4.2 必跑检查

涉及战斗、骰子、奖励、结算、UI 主流程时，至少运行：

```text
主场景启动检查：--headless --path . --quit-after 3
相关 Debug*.gd 测试
```

涉及算分时，优先运行或补充：

```text
DebugComboEvaluator.gd
DebugBattleSmokeTest.gd
DebugOrnamentScoringSmokeTest.gd
DebugResolutionTraceSmokeTest.gd
DebugStepOrderSmokeTest.gd
```

涉及铸骰件 / 安装时，优先运行或补充：

```text
DebugForgeRewardSmokeTest.gd
DebugInstallRulesSmokeTest.gd
DebugDiceModelRefactorSmokeTest.gd
```

涉及中文显示时，优先运行或补充：

```text
DebugChineseDisplaySmokeTest.gd
DebugFaceDisplaySmokeTest.gd
```

---

## 5. 架构边界

### 5.1 UI 不写规则

UI 只负责：

- 显示状态。
- 转发玩家操作。
- 播放动画。
- 显示规则层返回的结果、日志、结算轨迹。

UI 不应：

- 自己判断骰型。
- 自己算 `Chips × Mult × XMult`。
- 自己推导面饰 / 印记效果。
- 自己决定奖励池。
- 自己修改 `RunState.dice`。

### 5.2 规则层职责

规则层负责：

```text
RollService      投骰 / 重投
ComboEvaluator   主骰型判断
TagEvaluator     条件标签判断
ScoreEngine      总体算分流程
EffectResolver   面饰、印记、未结算留场等效果
ForgeService     铸骰件安装
RewardGenerator  奖励生成
```

### 5.3 Runtime Controller 职责

Runtime 层负责流程，不负责 UI 细节：

```text
BattleController       单场战斗流程
GameFlowController     Main -> Battle -> Reward -> ForgeInstall -> Battle
RunState               局内持久骰组、战斗序号、统计
RunController          如存在，保持最小职责，不重复 GameFlowController
```

---

## 6. 当前数据模型约束

### 6.1 DieState

整颗骰子建议字段：

```gdscript
var id: StringName
var face_count: int = 6
var body_id: StringName = &"standard"
var faces: Array[FaceState] = []
var face_weights: Array[int] = []
```

要求：

- `create_normal_d6()` 默认创建标准 D6。
- 当前先不实现 D4 / D8，除非任务明确要求。
- RollService 应尽量使用 `die.faces.size()`，不要硬编码 6。
- `face_weights` 当前可预留；如果实现，必须有测试。

### 6.2 FaceState

单个骰面建议字段：

```gdscript
var pip: int = 1
var ornament_id: StringName = &"none"
var mark_id: StringName = &"none"
```

兼容旧字段时：

```gdscript
var material_id: StringName = &"none" # deprecated
var rune_id: StringName = &"none"     # deprecated
var level: int = 1                    # deprecated
```

要求：

- 新逻辑优先使用 `ornament_id` 和 `mark_id`。
- 旧字段不得影响普通结算，除非明确作为兼容映射。
- `material_id == glass` 可兼容映射为 `ornament_id == burst`。
- `material_id == steel` 可兼容映射为 `ornament_id == stay`。
- `rune_id` 和 `level` 不再作为普通骰面槽位参与结算。

---

## 7. 战斗操作约束

当前没有独立锁定。

正确模型：

```text
选择骰子 + 重投所选
选择骰子 + 结算所选
```

要求：

- UI 不显示“锁定 / 解锁”。
- 不使用“重投未锁定”。
- 重投时只重投当前 selected 的骰子。
- 结算时只结算当前 selected 的骰子。
- 未被结算但已投出的骰面属于“未结算留场”。

如代码仍有 `locked` 字段，只能作为 deprecated 兼容字段，不能作为玩家可见核心操作。

---

## 8. 算分和结算表现

核心公式：

```text
最终战力 = Chips × Mult × XMult
```

中文显示：

```text
Chips  -> 基础战力
Mult   -> 倍率
XMult  -> 终倍率
Combo  -> 骰型
```

结算表现层规则：

- UI 应播放规则层产出的 `ResolutionTrace` 或等价结构。
- UI 不自己重新推导结算步骤。
- 结算动画期间禁止重复点击。
- 当前分数应在所有结算步骤播放完成后再增加。
- 骰子结算先于遗物结算。
- 每个加成步骤应有结构化 step，方便飘字、日志、测试。

---

## 9. 主骰型与包含结构

主骰型只取一个，用于基础战力与基础倍率。

不要让五同在基础结算里重复获得一对、三同、四同的基础分。

需要区分：

```text
主骰型：本手实际主分类
包含结构：用于外部效果触发
```

例如：

```text
6,6,6,6,6
主骰型：五同
包含结构：包含一对 / 包含三同 / 包含四同 / 包含五同
基础分只按五同计算一次
```

文案必须区分：

```text
“主骰型为一对”
“本手包含一对”
```

---

## 10. 铸骰件和奖励池

普通战奖励当前优先：

```text
点数片
面饰片
印记片
复合件
```

不应作为普通奖励池返回：

```text
符文片
升级件
骰面材质片
整颗骰子
骰胚更换
面数改变
```

整颗骰子、骰胚、D4 / D8 属于低频系统奖励，后续再做。

铸骰件安装规则：

```text
点数片：替换点数，不影响面饰和印记
面饰片：替换面饰，不影响点数和印记
印记片：替换印记，不影响点数和面饰
复合件：只修改声明的槽位，不清除未声明槽位
净化件：只清负面面饰 / 负面印记
```

安装 UI 必须显示中文 Before / After 和替换提示。

---

## 11. 中文显示规范

所有玩家可见文本必须中文。

不得显示：

```text
material
rune
level
glass
steel
rune_six
upgrade
lock
unlock
```

推荐使用 `DisplayNames.gd` 或等价工具统一映射：

```gdscript
DisplayNames.combo_name(id)
DisplayNames.tag_name(id)
DisplayNames.ornament_name(id)
DisplayNames.ornament_effect_text(id)
DisplayNames.mark_name(id)
DisplayNames.mark_effect_text(id)
DisplayNames.body_name(id)
DisplayNames.face_summary(face)
DisplayNames.face_detail_text(face)
DisplayNames.die_summary(die)
```

示例：

```text
6
面饰：爆裂面饰
印记：红印
```

不要显示：

```text
6
ornament: burst
mark: red
```

---

## 12. 美术与资源规范

Codex 不应通过代码批量生成正式美术表现。

禁止：

- 用 GDScript / Python 批量生成正式图标、骰子贴图、角色图、遗物图。
- 用纯代码画一堆临时素材后当作正式美术。
- 下载或嵌入版权不明素材。
- 引入未经确认授权的字体、图标包、图片包。

允许：

- 使用 Godot 自带控件、Panel、Label、Button、ColorRect 做临时 UI 占位。
- 使用用户提供的美术资源。
- 使用 ChatGPT / 图像生成工具生成后由用户确认的资源。
- 使用 Godot Asset Library 中授权明确的资源。
- 从网上下载授权明确的资源。

下载或引入外部资源时必须：

```text
1. 记录来源 URL
2. 记录许可证
3. 记录作者 / 项目名
4. 放入 assets/ATTRIBUTION.md 或 docs/asset_sources.md
5. 不确定授权时不要使用
```

资源目录建议：

```text
res://assets/ui/
res://assets/dice/
res://assets/icons/
res://assets/generated/
res://assets/external/
res://assets/source/
```

---

## 13. 导出配置规范

仅在任务明确要求时修改：

```text
export_presets.cfg
project.godot 的导出相关字段
应用图标
Windows / macOS / Linux 打包配置
```

修改导出配置时：

- 不写入本机绝对路径，除非 Godot 要求且无法避免。
- 不写入密钥、证书、账号、token。
- 不误改 `run/main_scene`。
- 修改后运行主场景启动检查。
- 如能导出，执行一次导出 dry run 或说明无法执行原因。

---

## 14. 测试策略

每个功能改动必须尽量配套测试。

优先测试纯规则层：

```text
ComboEvaluator
TagEvaluator
ScoreEngine
EffectResolver
ForgeService
RewardGenerator
RollService
RunState
BattleController
ResolutionTrace
```

UI 动画难以全自动测试时，至少测试：

- Controller 状态机。
- 结算 trace 顺序。
- 总分提交时机。
- 输入锁定 / 解锁状态。
- 生成的 UI 节点存在与路径正确。

测试脚本输出必须清晰：

```text
PASS
FAIL: 具体失败原因
```

不能伪造测试结果。

---

## 15. 修改流程

Codex 每次执行任务时应遵循：

1. 先检查当前目录结构和相关文件。
2. 明确本轮最小修改范围。
3. 优先改脚本和测试。
4. 复杂场景改动先写生成 / 修补脚本。
5. 修改后运行相关 Debug 测试。
6. 运行主场景启动检查。
7. 输出新增 / 修改文件列表。
8. 输出测试结果。
9. 明确哪些内容没有实现。
10. 如有无法运行的命令，说明原因。

不要一次性做大范围无关重构。

### 15.1 视觉验收截图规则

涉及 UI、美术、材质、灯光、渲染、场景构图或 visual acceptance 的任务，结算任务前必须执行：

1. 改动前先保留基线截图或记录已有 latest / run_id 截图路径。
2. 改动后复跑对应截图脚本或 visual acceptance runner，生成新的截图和 manifest。
3. 在最终回复前，用 Markdown 图片把“改动前”和“改动后”截图发在 Codex 对话里展示，图片路径必须使用本机绝对路径，便于人工验收。
4. 如果因为无图形环境、截图脚本失败或资源缺失无法截图，必须在完成报告中写明失败原因、已尝试命令和下一步建议。
5. OpenSpec 或任务清单中的视觉验收项，只有在截图生成并已在对话中展示后，才能标记为完成。

### 15.2 测试视角 / 临时调参还原规则

涉及相机、灯光、节点位置、Control 位置、材质参数等视觉验收时，允许为了截图或 Debug 临时设置测试参数，但必须遵守：

- 不得把测试相机位置、测试灯光、测试拖拽位置、截图专用构图写回默认导出值、场景资源或正式运行路径。
- 如必须通过代码设置测试视角，应只在 capture runner / Debug 脚本内部设置，并在脚本结束前恢复原值，或使用一次性实例，不污染项目默认状态。
- 修改前必须记录原始默认值；修改后检查 diff，确认没有把临时验收参数留在 `.gd`、`.tscn`、`.tres` 中。
- 最终说明中如涉及临时视角，必须明确“默认运行视角未改变”或说明已恢复到哪个原值。

---

## 16. 任务完成报告格式

每次完成后用中文输出：

```text
新增 / 修改文件：
- ...

本轮完成：
- ...

架构说明：
- ...

测试结果：
- DebugXXX：PASS / FAIL
- 主场景启动检查：PASS / FAIL

视觉对比截图：
- 改动前：...
- 改动后：...

未实现 / 暂未处理：
- ...

风险与后续建议：
- ...
```

如果有失败：

```text
失败项：
原因：
已尝试：
建议下一步：
```

---

## 17. 禁止事项清单

除非任务明确要求，否则不要做：

```text
血量 / 扣血 / 治疗 / 护甲
独立锁定操作
Boss
地图
商店
存档
联网
账号系统
D12 / D20
硬造花色 / 元素属性
卡牌抽牌 / 手牌 / 能量系统
大规模重写 .tscn
用代码生成正式美术
引入版权不明资源
把 UI 和规则逻辑混在一起
把算分逻辑写进 BattleScreen
删除已有 Debug 测试
删除用户已有资源
```

---

## 18. 当前最重要的项目口径

> 核心循环已经成立。后续不要推翻核心循环，只迁移旧维度、加强结算表现、补测试、改善可读性。

保留：

```text
投骰
选择骰子
重投所选
结算所选
目标分达标
三选一铸骰件
安装到骰面
下一场继续变强
Chips × Mult × XMult
结算日志 / 结算动画
```

清理或迁移：

```text
锁定
骰面材质
符文常规槽
等级常规槽
血量 / 扣血
```
