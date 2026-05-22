# Star Dice Visual Repro Baseline

## Scope

本报告对应 OpenSpec change `improve-star-dice-visual-repro` 的初始视觉基线。目标是把参考图中的星盘战斗画面拆成可复跑验收点：骰子材质分层、星盘台面、灯光角色、渲染特性和整图构图。

## Current Acceptance Baseline

- 当前 shader/light visual acceptance 已有局部 case：`dice_shader_basic`、`table_shader_basic`、`light_effect_basic`。
- 最近一次已知有效运行：`20260522_121514`，manifest 状态为 `valid`。
- 当前验收图路径位于 `res://tests_or_debug/tmp_report/visual_acceptance/shader_light/latest/`，该目录为本地忽略输出，不作为正式资源提交。

## Current Strengths

- `repro_*` 骰子材质已经有统一 shader 入口和固定 palette。
- 圆角 D6 mesh、Face Label、接触阴影、星盘台面、Glow、SSAO 和 tonemap 已接入复刻场景。
- 视觉验收 runner 已具备 run_id、水印、manifest、latest 清理和 stale png 防误用机制。
- 材质流水线诊断显示青铜、黄金、水晶贴图导入和暗场可读性已通过现有阈值。

## Visual Gaps Against Target

- 骰子材质仍偏单层程序发光，缺少目标图中的漆面/宝石质感、独立边缘描边、表面 glint 和贴花层次。
- 面值主要由 `Label3D` 表示，尚未形成可独立验收的 face marker layer；后续需要确保文字/符号不被 bloom 或材质噪声吞掉。
- 灯光虽然已有主光、补光、边缘光和多色漫射光，但缺少明确命名的柔光顶光、蓝色桌面反弹、金色边线 kicker、局部 glint 与反射参考角色。
- 台面已经有星盘结构，但整张战斗构图 case 尚未覆盖 UI 遮挡、骰子行位置、星盘深蓝背景和底部操作栏共同呈现。
- 渲染特性已有 Glow/SSAO，但反射参考、接触阴影 fallback、透明/贴花层和 bloom 不洗白文字的验收记录还不完整。

## First Implementation Targets

1. 新增 `battle_star_dice_repro_full` 整图 visual acceptance case。
2. 在复刻场景和 GM 视口中暴露可检查的分层骰子节点/快照字段。
3. 给灯光 rig 增加语义明确的角色名和快照。
4. 给 acceptance manifest 增加渲染特性诊断字段，方便区分内容失败与运行环境 fallback。
