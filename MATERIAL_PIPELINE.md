# 骰子材质生产管线

本文档记录 `res://assets/` 下骰子材质的目录、命名、贴图通道和验收规则。当前首批材质为青铜骰子、黄金骰子、水晶骰子，后续其它骰胚、skill、relic 材质沿用同一套规范。

## 目录结构

```text
res://assets/textures/dice/bronze/
res://assets/textures/dice/gold/
res://assets/textures/dice/crystal/
res://assets/materials/dice/
res://assets/shaders/dice/
res://assets/models/dice/
res://assets/scenes/preview/
```

生成脚本：

```text
res://tools/scene_builders/BuildDiceMaterialPipeline.gd
res://tools/scene_builders/GenerateDiceMaterialTextures.py
```

验证脚本：

```text
res://tests_or_debug/DebugDiceMaterialPipelineSmokeTest.gd
```

## 命名规范

贴图使用：

```text
{material_id}_dice_albedo.png
{material_id}_dice_normal.png
{material_id}_dice_orm.png
{material_id}_dice_emission.png
{material_id}_dice_height.png
{material_id}_dice_flow_mask.png
```

材质使用：

```text
res://assets/materials/dice/bronze_dice.tres
res://assets/materials/dice/gold_dice.tres
res://assets/materials/dice/crystal_dice.tres
```

预览场景使用：

```text
res://assets/scenes/preview/dice_material_preview.tscn
res://assets/scenes/preview/bronze_dice_preview.tscn
res://assets/scenes/preview/gold_dice_preview.tscn
res://assets/scenes/preview/crystal_dice_preview.tscn
```

截图使用：

```text
res://assets/scenes/preview/preview_shots/{material_id}_dice_{bright|neutral|dark}.png
```

当前自动截图由 `GenerateDiceMaterialTextures.py` 基于已生成贴图输出离线预览图；Godot 预览场景仍是材质验收的主入口。在带图形渲染设备的环境中，可直接打开各 preview scene 重新截取真实视口图。

## 贴图内容边界

材质贴图只表达骰胚材质本身，不烘焙任何骰子点数、数字、符号或面值标记。

- 点数、数字和可读面值应由模型几何、独立贴花、Label3D 或后续专用标记层实现。
- `albedo`、`normal`、`orm`、`emission`、`height`、`flow_mask` 都不得包含固定面值图案。
- 贴图 atlas 可以保留 6 个面块布局，但每个面块只允许有材质纹理变化、边缘磨损、划痕、裂纹、铜绿、流光等材质信息。

## 贴图类型

- `albedo`：基础色。青铜包含旧铜色与局部铜绿；黄金包含古代金器暗部与磨损亮边；水晶使用带透明度的蓝白色基底。
- `normal`：切线空间法线。主要负责边缘磨损、划痕、晶体裂纹和材质微表面。
- `orm`：ORM 合图。R 通道为 AO，G 通道为 Roughness，B 通道为 Metallic。
- `emission`：发光贴图。青铜和黄金只保留轻微缝隙/磨损发光；水晶用于流光和边缘发光。
- `height`：高度图。用于高度贴图、后续离线烘焙或材质迭代。
- `flow_mask`：仅水晶使用。控制 shader 内部流光强度与流动区域。

## ORM 规范

`*_orm.png` 严格按以下通道打包：

```text
R = Ambient Occlusion
G = Roughness
B = Metallic
```

青铜与黄金优先使用 `ORMMaterial3D`。如果某个 Godot 版本缺少 `ORMMaterial3D`，生成脚本会回退到 `StandardMaterial3D`，但仍保留同名 ORM 贴图。

## 导入规范

- 所有贴图使用 PNG，开启 mipmap。
- `normal` 贴图应按法线图导入；如手工替换资源，在 Import 面板中设置为 normal map。
- `orm`、`height`、`flow_mask` 应按数据贴图处理，避免作为颜色图做额外色彩校正。
- `albedo` 与 `emission` 可保持颜色贴图导入。
- 替换贴图时保持同名文件路径，避免破坏已有材质引用。

## 材质规范

青铜骰子：

- 古旧青铜为主色。
- 局部铜绿集中在边缘、划痕和噪声区域。
- 铜绿不得在主视面形成连续大块绿色覆盖；自动验收会检查全图与单面铜绿占比。
- 材质贴图不包含骰点；数字可读性由后续独立标记层负责。

黄金骰子：

- 古代金器质感，金属度高但粗糙度不低。
- 边缘有磨损高光，面内有暗部与细划痕。
- 避免纯黄、高光过硬的塑料玩具金效果。
- 金属度不得全图锁满，暗场下暗面必须保留暖金 / 暗金材质色，不得塌成近黑块。

水晶骰子：

- 使用 `ShaderMaterial` 与 `crystal_dice.gdshader`。
- 支持 `alpha_base`、`emission_power`、`fresnel_power`、`flow_speed`、`glow_color`、`tint_color`。
- 表现重点为半透明、边缘光、内部流光和整体发光；面值标记不写入材质贴图。

## 预览规范

每种材质必须有独立 Godot 预览场景，并包含：

- 标准 D6 骰子模型。
- `DirectionalLight3D`。
- `AuxPointLight`。
- `WorldEnvironment`。
- Glow/Bloom 环境设置。
- 金属材质需要有中性反射 / 金属补光环境，确保青铜与黄金在暗面仍可读。

通用预览场景 `dice_material_preview.tscn` 同时展示三种材质，用于快速横向比较。

## 金属视觉验收

青铜与黄金的自动验收除资源存在外，还必须覆盖：

- `normal` 贴图按 normal map 导入，3D 表面贴图启用 mipmap。
- `orm` 通道保持 `R=AO / G=Roughness / B=Metallic`，不得被当作法线图导入。
- 黄金 `metallic` 保持高金属感，但不得全图达到最大值。
- 黄金 `roughness` 保持中等偏高，避免硬闪和角度亮暗跳变。
- 青铜铜绿只作为局部氧化特征，覆盖率需受阈值限制。
- `preview_shots/{bronze,gold}_dice_dark.png` 的骰体区域亮度需高于暗场可读阈值。

诊断命令：

```powershell
python tools\scene_builders\AnalyzeDiceMaterialVisuals.py
```

## 验收规则

1. `BuildDiceMaterialPipeline.gd` 能重复运行并稳定生成资源。
2. 三种材质都能在 Godot 中直接打开预览。
3. `normal`、`orm`、`emission`、`height` 已接入材质。
4. 水晶材质使用 `ShaderMaterial`，且 shader 参数可调。
5. 青铜、黄金、水晶在亮场、中性光、暗场截图中风格区分明显。
6. 生成贴图不包含骰子点数、数字、符号或固定面值标记。
7. 所有文件位于统一目录，命名无临时脏资源。
8. 青铜和黄金通过金属视觉阈值检查。
9. `DebugDiceMaterialPipelineSmokeTest.gd` 输出 `PASS`。

## 复跑命令

```powershell
python tools\scene_builders\GenerateDiceMaterialTextures.py
& (Get-Command godot).Source --headless --path . --script "tools\scene_builders\BuildDiceMaterialPipeline.gd"
& (Get-Command godot).Source --headless --path . --script "res://tests_or_debug/DebugDiceMaterialPipelineSmokeTest.gd"
```
