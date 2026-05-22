## Why

当前星盘战斗画面的 3D 骰子、台面、灯光和后处理已经有可复跑的视觉验收入口，但与目标参考图仍存在明显差距：骰子更像程序发光塑料，缺少漆面/宝石感材质层次、可控反射、柔光与局部高光。现在需要把差距拆成可执行的规格与任务，避免继续靠零散调参推进。

## What Changes

- 建立 `star-dice-visual-repro` 能力，约束星盘战斗视觉复刻的材质模型、灯光布置、渲染方式和验收流程。
- 拆分骰子材质模型改造：区分骰体底色、边缘发光、面值/符号贴花、表面高光、细节纹理与选择态，不再只依赖单个程序 shader 一次性混合所有效果。
- 补齐目标图需要的光照层：大面积柔光顶光、冷蓝桌面反弹光、金色边线 kicker、局部 glint 小高光、金属/漆面反射参考。
- 明确需要评估的渲染方式：反射探针或环境反射、屏幕空间效果、接触阴影、Glow/Bloom 分层、透明/贴花层、台面反射或湿润高光。
- 扩展视觉验收流程：保留现有 shader/light case，同时新增整张战斗场景构图级 case，覆盖骰子、星盘台面、UI 遮挡和目标参考差距。
- 不改变战斗规则、结算规则、奖励池、骰面槽位或玩家操作流程。

## Capabilities

### New Capabilities

- `star-dice-visual-repro`: 约束星盘战斗画面复刻所需的骰子材质分层、灯光环境、渲染特性、目标截图验收和调试流程。

### Modified Capabilities

- 无。

## Impact

- 影响视觉复刻相关资源与脚本：`assets/shaders/dice/repro_glow_dice.gdshader`、`assets/materials/dice/repro_*_dice.tres`、`assets/models/dice/rounded_d6_mesh.tres`、`assets/models/stage/star_astrology_disc.tscn`、`assets/materials/stage/`。
- 影响 GM/战斗 3D 视口：`scripts/ui/debug/gm_dice_port/GmDiceViewport.gd`、`GmDiceMaterialResolver.gd`、`GmDiceCtrl.gd`、`scripts/ui/battle/components/BattleDiceStage3D.gd`。
- 影响视觉验收工具与测试：`tests_or_debug/visual_acceptance/shader_light/`、`tests_or_debug/tmp_report/visual_acceptance/`、`DebugShaderLightAcceptanceSmokeTest.gd`、`DebugGmDiceLightingSmokeTest.gd`、`DebugGmDiceVisualTextureSmokeTest.gd`。
- 可能新增 visual acceptance case、调试场景生成脚本和诊断报告，但不引入外部美术、字体、图标包或第三方运行时。
