## Why

青铜骰子和黄金骰子在 GM 物理骰子场景中暗面观感阴沉，且运动或角度变化时容易出现亮暗混乱；目前只有铁质骰子的简单材质观感稳定。视觉验收已定位到问题集中在金属骰胚材质流水线、贴图导入设置和场景反射/补光匹配上，需要建立可复跑的修复任务和验收口径。

## What Changes

- 调整青铜与黄金骰子的材质生成参数，使暗面保留可读的材质色，不再依赖过强边缘亮面掩盖问题。
- 降低黄金全图高金属度带来的暗场塌黑风险，并提高粗糙度/反射表现的稳定性。
- 收敛青铜 albedo 中大面积铜绿分布，让铜绿集中在边缘、划痕或局部噪声区域，避免主视面大片偏绿偏脏。
- 统一骰子材质贴图导入设置，尤其是 normal map、mipmap、ORM/height 数据贴图规则。
- 调整 GM 物理骰子视口和材质预览场景对金属骰子的光照/反射环境，保持铁质、青铜、黄金、水晶风格差异。
- 增加或扩展 Debug 视觉验收，覆盖暗场亮度下限、金属度占比、铜绿覆盖率、法线导入和 mipmap 设置。
- 更新 `MATERIAL_PIPELINE.md` 的验收规则，记录本次金属材质视觉口径。

## Capabilities

### New Capabilities

- `dice-material-visuals`: 约束骰子材质流水线在贴图、PBR 参数、导入设置、预览光照和自动验收上的可读性与稳定性。

### Modified Capabilities

- 无。

## Impact

- 影响 `res://tools/scene_builders/GenerateDiceMaterialTextures.py` 与 `res://tools/scene_builders/BuildDiceMaterialPipeline.gd`。
- 影响 `res://assets/textures/dice/{bronze,gold}`、`res://assets/materials/dice/{bronze_dice,gold_dice}.tres`、预览截图与导入配置。
- 影响 `res://assets/scenes/preview/*.tscn` 与 GM 物理骰子视口光照配置。
- 影响 `res://tests_or_debug/DebugDiceMaterialPipelineSmokeTest.gd`、`DebugGmDiceLightingSmokeTest.gd`，并可能新增金属材质视觉验收脚本。
- 不改变战斗规则、骰面槽位、奖励池、结算逻辑或玩家可见战斗流程。
