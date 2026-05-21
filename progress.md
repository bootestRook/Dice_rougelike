# 战斗入场与操作按钮进度记录

## 2026-05-21 追加：结算高亮 typed array 报错
- 修复结算时报错：`Invalid type in function 'set_highlighted_die_indices' in base 'PanelContainer (BattleDiceStage3D)'`。
- 原因是外部调用传入普通 `Array`，而 `BattleDiceStage3D.set_highlighted_die_indices()` 声明为 `Array[int]`，Godot 运行时会拒绝不同元素类型的数组。
- `BattleDiceStage3D.set_hidden_die_indices()` / `set_highlighted_die_indices()` 现在接收普通 `Array`，内部通过 `_int_indices_from_array()` 统一转换为 `Array[int]`。
- 验证通过：`DebugUnselectedDiceVisibleDuringResolutionSmokeTest.gd`、`DebugOrganizedResolutionOrderSmokeTest.gd`、`DebugBattleDiceInputSmokeTest.gd`、`DebugBattleSmokeTest.gd`、主场景 headless、`git diff --check`。

## 2026-05-21 追加：整理后重投留场顺序
- 根据用户反馈继续修复“整理后重投所选，回位时像交换位置”的表现问题。
- 定位到未被重投的骰子进入留场区时仍按原始骰子索引排列，返回目标虽然已经是整理后的槽位，但移动路径会交叉，视觉上像互换。
- `GmBattleMgr._move_unselected_dice_to_hold()` 现在按 `_ready_slot_for_die()` 排序留场队列，使留场区左右顺序与整理后的显示顺序一致。
- `DebugDiceBenchOrganizeSmokeTest.gd` 改为重投整理后的中间槽位，并新增 `unselected_hold_keeps_display_order` 断言，覆盖留场目标顺序。
- 追加验证通过：`DebugDiceBenchOrganizeSmokeTest.gd`、`DebugBattleDiceInputSmokeTest.gd`、`DebugOrganizedResolutionOrderSmokeTest.gd`、`DebugUnselectedDiceVisibleDuringResolutionSmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、主场景 headless、`git diff --check`。Godot 退出时仍有既有 CanvasItem/ObjectDB 泄漏警告，相关命令退出码为 0。

## 2026-05-21 追加：整理回归槽位
- 根据用户截图继续修复整理后的回归位置：`GmBattleMgr` 现在保存 `display_die_order`，并通过 `get_ready_slot_for_die()` / `_ready_position_for_die()` 统一计算每颗骰子的视觉槽位。
- 已将重投后的准备位回归、结算退出后的回归、未选骰留场回归、跌落恢复目标全部改为使用整理后的视觉槽位，不再按骰子原始索引回位。
- `BattleDiceStage3D._apply_display_order_positions()` 现在先把整理顺序同步给 `GmBattleMgr`，由管理器负责实际准备位目标；动画进行中只更新顺序，不强行打断位置。
- 更新 `DebugDiceBenchOrganizeSmokeTest.gd`：新增整理后槽位映射断言、重投后 `ready_return_target_position` 匹配整理槽位断言。
- 追加验证通过：`DebugDiceBenchOrganizeSmokeTest.gd`、`DebugBattleDiceInputSmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugOrganizedResolutionOrderSmokeTest.gd`、`DebugUnselectedDiceVisibleDuringResolutionSmokeTest.gd`、主场景 headless、`git diff --check`。Godot 退出时仍有既有 CanvasItem/ObjectDB 泄漏警告，相关命令退出码为 0。

## 2026-05-21
- 启动本轮任务，使用 `planning-with-files`。
- `session-catchup.py` 返回 exit 1 且无输出。
- `git status --short` 显示战斗界面、流程控制、测试和 3D 骰子舞台已有 dirty/untracked 改动；本轮不回退这些改动。
- 已将计划文件从旧任务切换到本轮目标。
- 已审查 `BattleScreen.gd`、`BattleDiceStage3D.gd`、`GmBattleMgr.gd`、`GmReadyMgr.gd` 和地图流程测试。
- 发现正式战斗的初始 3D 投骰路径绕过了回合横幅；“回归”动画能力已在 `GmBattleMgr` 中存在但未暴露给正式战斗入场。
- 修改 `GmBattleMgr.gd`：新增 `request_dice_entry_return()`，复用已有回归动画。
- 修改 `BattleDiceStage3D.gd`：新增 `play_entry_return_and_wait()`，回归完成后返回当前骰面结果；重投/结算按钮改为横幅大按钮样式。
- 修改 `BattleScreen.gd`：外部初始 3D 结果路径改为“回合横幅 -> 回归入场 -> 提交结果”，并记录自动化顺序事件。
- 更新 `DebugBattleDiceInputSmokeTest.gd`：覆盖回合横幅先于回归入场、首手回归完成、按钮横幅尺寸和描边样式。
- 测试通过：`DebugBattleDiceInputSmokeTest.gd`、`DebugBattleOptionsMenuSmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、`DebugDiceBenchOrganizeSmokeTest.gd`、`DebugUnselectedDiceVisibleDuringResolutionSmokeTest.gd`、`DebugBattleSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`。
- 主场景 headless 启动通过；`git diff --check` 通过。Godot 退出时仍有既有 CanvasItem/ObjectDB 泄漏警告，相关命令退出码为 0。
- 根据用户反馈继续调整：战斗未开始 / 地图阶段时 `BattleHudState.dice_results` 为空，3D 战斗舞台不会生成骰子。
- 将重投/结算按钮从 HUD 面板中拆成独立 `BattleActionButtonsLayer`，战斗骰存在后才显示。
- 新增断言：`DebugMapStageFlowSmokeTest.gd` 检查地图阶段战斗骰数为 0；`DebugBattleDiceInputSmokeTest.gd` 检查入场前骰子隐藏、战斗按钮层可见。
- 追加验证通过：`DebugMapStageFlowSmokeTest.gd`、`DebugBattleDiceInputSmokeTest.gd`、`DebugBattleOptionsMenuSmokeTest.gd`、主场景 headless、`git diff --check`。
- 根据用户进一步反馈继续调整：横幅结束后不再先清隐藏 / 刷新出准备位骰子，而是在 `BattleDiceStage3D.play_entry_return_and_wait()` 内直接从隐藏状态启动“回归”动画。
- `BattleDiceStage3D` 新增 `entry_return_revealing`，回归动画期间 `_apply_transient_state()` 不主动改骰子可见性，避免中途闪现或被隐藏状态打断。
- `DebugBattleDiceInputSmokeTest.gd` 新增“回归入场直接从隐藏状态开始”断言；追加验证通过 `DebugBattleDiceInputSmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugBattleOptionsMenuSmokeTest.gd`、主场景 headless、`git diff --check`。
- 修复“整理”按钮：原先只更新 `display_die_order`，但 3D 准备位仍按原始节点顺序排布；现在会把整理顺序映射到每颗骰子的 3D 位置。
- 新增 `BattleDiceStage3D.get_visual_die_order_left_to_right()` 供 Debug 验证实际左到右顺序。
- 更新 `DebugDiceBenchOrganizeSmokeTest.gd`：检查整理后 3D 位置按显示顺序重排，且重投后仍保持整理位置顺序。
- 追加验证通过：`DebugDiceBenchOrganizeSmokeTest.gd`、`DebugBattleDiceInputSmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、主场景 headless、`git diff --check`。
