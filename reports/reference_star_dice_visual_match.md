# 星盘骰子参考图视觉对齐报告

## Baseline

- 变更：`match-reference-star-dice-visuals`
- 原始基线 run_id：`20260522_133019`
- 原始基线截图：`res://tests_or_debug/tmp_report/visual_acceptance/shader_light/outputs/20260522_133019/full_scene_repro/battle_star_dice_repro_full/battle_star_dice_repro_full_main.png`
- 原始基线 manifest：`res://tests_or_debug/tmp_report/visual_acceptance/shader_light/reports/20260522_133019_manifest.json`
- 视觉接受状态：`not_accepted`

## UI Revert Round

- 撤回前 run_id：`20260522_135509`
- 撤回前截图：`res://tests_or_debug/tmp_report/visual_acceptance/shader_light/outputs/20260522_135509/full_scene_repro/battle_star_dice_repro_full/battle_star_dice_repro_full_main.png`
- 撤回后 run_id：`20260522_141900`
- 撤回后截图：`res://tests_or_debug/tmp_report/visual_acceptance/shader_light/outputs/20260522_141900/full_scene_repro/battle_star_dice_repro_full/battle_star_dice_repro_full_main.png`
- 撤回后 manifest：`res://tests_or_debug/tmp_report/visual_acceptance/shader_light/reports/20260522_141900_manifest.json`
- 撤回对比图：`res://reports/reference_star_dice_visual_match_ui_reverted_before_after.png`
- 工程状态：`pass`
- 视觉接受状态：`pending_human_review`

## Round Result

| Gap | Status | Notes |
| --- | --- | --- |
| 实体圆角骰体 | kept | 保留骰子实体层、边框条、顶面数值、前脸星徽、接触阴影等非 UI 改动。 |
| 三面可见 | kept | 保留当前相机、骰子缩放和骰子行位置。 |
| 顶面数值 | kept | 保留 `4,3,3,4,1,6` 的 full-scene case。 |
| 前脸星徽 | kept | 保留前脸星徽节点和相关结构测试。 |
| 光照 / 渲染 | kept | 保留补充灯位、反射 probe、Glow/SSAO/tonemap 调整和 runner 记录。 |
| 蓝金 UI | reverted | 已移除我新增的 `VA_CompositionOverlay`、左侧计分面板、顶部遗物/道具区、底部行动栏、选中计数和槽位节点。 |
| UI 槽位断言 | reverted | 已移除 `VA_RelicSlot`、`VA_ToolSlot`、`VA_DiceSlot` 相关测试断言。 |

## Unresolved

- 本轮没有继续推进 UI 复刻；OpenSpec 任务 4.4 和 4.6 已改回未完成并标注为按用户要求暂停。
- 视觉结果仍需人工确认，不能自动标记为 `accepted`。
- 骰子当前仍偏“发光线框”，后续要继续往参考图的厚实圆角材质靠，但不能再夹带 UI 改动。

## Hard Edge Dice Round

- 改动前 run_id：`20260522_141900`
- 改动后 run_id：`20260522_151210`
- 改动后截图：`res://tests_or_debug/tmp_report/visual_acceptance/shader_light/outputs/20260522_151210/full_scene_repro/battle_star_dice_repro_full/battle_star_dice_repro_full_main.png`
- 改动后 manifest：`res://tests_or_debug/tmp_report/visual_acceptance/shader_light/reports/20260522_151210_manifest.json`
- 改动前 / 改动后对比图：`res://reports/reference_star_dice_hard_edge_before_after.png`
- 工程状态：`pass`
- 视觉接受状态：`pending_human_review`

### Hard Edge Round Result

| Gap | Status | Notes |
| --- | --- | --- |
| 边框透明缺失 | improved | 每颗骰子加入 12 条不透明硬边条和 8 个硬角封口块，先消除透明断边。 |
| 线框感过强 | improved | 降低 shader Fresnel/EMISSION 和边框材质自发光，让实心面板成为主体。 |
| 实体面 | improved | 顶面、前脸、左右侧面加入不透明填充面，避免只靠线条表现骰体。 |
| 圆角质感 | unresolved | 目前是硬角修复版，角块偏硬，后续再收敛成参考图的厚实圆角倒角。 |

## Rounded Bevel Dice Round

- 改动前 run_id：`20260522_151210`
- 改动后 run_id：`20260522_153408`
- 改动后截图：`res://tests_or_debug/tmp_report/visual_acceptance/shader_light/outputs/20260522_153408/full_scene_repro/battle_star_dice_repro_full/battle_star_dice_repro_full_main.png`
- 改动后 manifest：`res://tests_or_debug/tmp_report/visual_acceptance/shader_light/reports/20260522_153408_manifest.json`
- 改动前 / 改动后对比图：`res://reports/reference_star_dice_rounded_bevel_before_after.png`
- 工程状态：`pass`
- 视觉接受状态：`pending_human_review`

### Rounded Bevel Round Result

| Gap | Status | Notes |
| --- | --- | --- |
| 硬角块 | improved | 将原先偏硬的边框块收敛为内嵌的圆柱倒角边梁，并让边梁长度贯穿到角点。 |
| 角帽突兀 | improved | 角帽半径改为与边梁一致，并把倒角中心压回骰体边缘内侧，减少独立球形角点。 |
| 线框发光感 | improved | 同步降低复刻场景和 GM dice 运行时边缘材质发光，避免边框压过骰体实心面。 |
| UI 改动 | not_changed | 本轮没有恢复或新增 UI overlay、遗物/道具槽、行动栏、计分面板等复刻 UI。 |
| 参考图厚实圆角 | pending_human_review | 目前仍是几何层的近似倒角，不是完整一体化倒角网格；还需要人工确认是否继续走 mesh 级倒角重建。 |
