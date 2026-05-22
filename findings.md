# 战斗入场与操作按钮发现记录

## 2026-05-21 追加发现：地图前进骰仍是独立 D6
- `GameFlowController._roll_map_movement_dice()` 原先直接用 `map_rng.randi_range(1, 6)`，不读取 `RunState.dice`，因此安装到正式战斗骰上的点数分布不会影响地图投掷。
- `MapStageView._ensure_movement_dice_views()` 原先创建 `map_move_d6_*` 占位骰，地图 UI 无法证明自己绑定的是局内正式战斗骰。
- 修复方向：流程层只取 `RunState.dice` 前两颗并复用 `RollService.roll_die()`；地图状态额外暴露 face index / face count；地图视图同步这两颗正式骰给物理表现层。

## 2026-05-21 追加发现：结算高亮数组类型
- `BattleScreen.move_selected_dice_to_resolution_by_trace()` 构造的 `visual_slot_indices` 是普通 `Array`，通过 `has_method()` 后直接调用 `BattleDiceStage3D.set_highlighted_die_indices()`。
- `BattleDiceStage3D.set_highlighted_die_indices(indices: Array[int])` 要求 typed array，普通 `Array` 在运行时会被 Godot 拒绝，导致结算阶段报错。
- 修复方向：对外 UI 方法接收普通 `Array`，内部转换为 `Array[int]` 后再写入状态。

## 2026-05-21 追加发现：重投时未选骰留场顺序
- 整理后的回归槽位已经同步到 `GmBattleMgr`，但未选骰在重投期间进入留场区时仍按原始骰子索引排列。
- 当整理顺序和原始索引顺序不一致时，未选骰从留场区回到整理后槽位会产生交叉路径，视觉上像骰子交换位置。
- 修复方向：未选骰进入留场区前按 `_ready_slot_for_die()` 排序，使留场区顺序、回归目标顺序和整理后的显示顺序一致。

## 2026-05-21 追加发现：整理后回归目标
- 整理按钮此前只更新 `BattleDiceStage3D.display_die_order` 并在空闲时摆正最终位置；`GmBattleMgr` 的回归动画仍用骰子原始索引计算 `ready_mgr.get_spawn_position(index, count)`。
- 受影响的回归路径包括重投后准备位回归、结算退出后的“回归”入场、未选骰留场回归、跌落恢复。只在动画结束后摆正会造成中途飞向旧槽位或短暂错位。
- 修复方向是让 `GmBattleMgr` 成为准备位目标的统一来源：先同步整理后的显示顺序，再由 `_ready_position_for_die(die_index)` 计算实际回归目标。

## 当前发现
- 工作区已有未提交改动，涉及 `BattleScreen.tscn`、`BattleScreen.gd`、`BattleController.gd`、`GameFlowController.gd`、骰子输入测试和若干 Debug 脚本。
- `BattleController` 在正式战斗里启用外部 3D 投骰结果，`start_next_hand()` 会先进入等待初始物理结果状态。
- `BattleScreen._on_hand_started()` 遇到等待初始物理结果时直接调用 `_play_initial_3d_roll_for_hand()`，这条路径没有先播放 `RoundIntroBanner`。
- `BattleScreen._play_battle_intro_magic()` 已经是“横幅 -> 入场表现”的串行结构，但当前外部 3D 投骰路径没有走到它。
- `GmBattleMgr` 已有“回归”动画：`request_dice_return_from_exit()` / `_play_dice_exit_return_preview()`，会通过 `play_exit_return_from()` 从入口飞回准备位。
- `BattleDiceStage3D` 中已有 `RerollButton` / `ScoreButton` 节点和信号绑定，但当前只是普通 Button 样式，需要做成参考图那种黑绿涂鸦横幅感，并保证按钮足够可见。
- 已实现正式战斗入场顺序记录：`round_banner_finished` 早于 `entry_return_started`。
- 已给重投/结算按钮设置大尺寸、高对比描边、深色底和亮色边框；信号仍是 `reroll_pressed` / `score_pressed`。

## 待确认
- 视觉效果已由 Debug 测试验证节点尺寸和样式属性；仍建议后续人工看一眼实际动效观感。
## 2026-05-21 追加发现：地图骰子只是换色，没有接入 GM 场景链路
- 用户反馈“用 GM 场景的那种骰子和逻辑”，确认之前只把地图自写物理骰子的材质/数据换成正式骰引用，视觉和投掷链路仍不是正式战斗使用的 GM 3D 骰子。
- 正式战斗的实际链路是 `GmDiceViewport` 创建固定 2.5D 视口，`GmReadyMgr` 管准备位，`GmBattleMgr.roll_using_dices()` 投掷并在回位后暴露 face index / pip。
- 修复方向：地图组件直接复用这三者，只保留两个 formal dice definition；地图移动提交 GM 物理骰实际落面，而不是提前生成结果再播放旧骰子动画。
- 兼容点：GM target 原本只接受 pip，补充 `{face_index: ...}` 后可保留精确骰面请求，不影响原有 pip target 测试。
