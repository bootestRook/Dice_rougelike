# 战斗入场与操作按钮实现计划

## 2026-05-21 追加处理：地图前进骰正式化
- 状态：complete
- 范围：地图移动只绑定 `RunState.dice` 的前两颗正式战斗骰，流程层通过 `RollService` 投掷并记录 `last_roll_face_indices`；地图 UI 同步这两颗正式骰的 id / 面数，物理表现层接收正式骰引用。
- 验证：`DebugRunFlowSmokeTest.gd` 新增“前两颗正式骰决定地图步数”断言；`DebugMapStageFlowSmokeTest.gd` 新增地图 UI 绑定正式骰断言；相关地图、战斗、骰子模型、中文显示和主场景 headless 检查通过。

## 追加处理：结算高亮 typed array 报错
- 状态：complete
- 范围：`BattleDiceStage3D` 对外高亮 / 隐藏索引入口改为接收普通 `Array`，内部转换为 `Array[int]`，避免 Godot typed array 运行时不匹配。
- 验证：结算高亮路径、整理结算顺序、战斗输入、基础战斗流程和主场景 headless 均通过。

## 追加处理：整理后重投留场顺序
- 状态：complete
- 范围：未选骰进入留场区时也按整理后的视觉槽位排序，避免回位路径交叉造成“交换位置”的观感。
- 验证：`DebugDiceBenchOrganizeSmokeTest.gd` 新增中间槽位重投与留场顺序断言并通过，相关战斗输入、地图入场、整理结算顺序、未选骰可见性和主场景 headless 均通过。

## 追加处理：整理后的回归槽位
- 状态：complete
- 范围：`GmBattleMgr` 统一保存整理后的 `display_die_order`，所有准备位回归目标都通过整理后的视觉槽位计算；`BattleDiceStage3D` 只负责同步整理顺序和触发摆位。
- 验证：`DebugDiceBenchOrganizeSmokeTest.gd` 新增回归槽位断言并通过，相关战斗输入、地图入场、整理结算顺序、未选骰可见性和主场景 headless 均通过。

## 目标
从地图进入战斗后，先播放回合横幅；横幅播放完成后，再让骰子通过“回归”方式入场。同时补回战斗界面的“重投”和“结算”按钮，按钮视觉参考用户给出的涂鸦横幅样式，但保持既有重投/结算逻辑不变。

## 阶段
| 阶段 | 状态 | 内容 |
|---|---|---|
| 1. 现状审查 | complete | 梳理地图进战斗、横幅动画、骰子舞台和按钮绑定 |
| 2. 入场时序调整 | complete | 横幅完成后再触发骰子回归入场 |
| 3. 操作按钮恢复 | complete | 添加/恢复重投与结算按钮，套用中文样式并保持逻辑接口 |
| 4. Debug 测试 | complete | 更新相关战斗/地图流程测试 |
| 5. 回归验证 | complete | 运行相关 Debug 脚本、主场景 headless、diff 检查 |

## 决策
- 不回退当前 dirty/untracked 改动，直接基于现有工作区继续。
- UI 只转发操作和播放表现，不把重投或结算规则写进 UI。
- 所有玩家可见按钮文本使用中文。
- 正式战斗初始手牌使用 `BattleDiceStage3D.play_entry_return_and_wait()` 取得回归入场后的面结果，再提交给 `BattleController.commit_initial_roll_results()`。
- `GmBattleMgr.request_dice_entry_return()` 复用既有回归动画，不改变重投和结算 Controller 入口。

## 错误记录
| 时间 | 错误 | 处理 |
|---|---|---|
| 2026-05-21 | `session-catchup.py` 返回 exit 1 且无输出 | 已记录，改用 `git status`、现有计划文件和源码审查继续 |
## 2026-05-21 追加处理：地图前进骰接入 GM 场景骰子 - 状态：complete
- 范围：`MapMovementDicePhysicsView` 内部改为复用 `GmDiceViewport` / `GmReadyMgr` / `GmBattleMgr`，地图上实际显示和投掷的是 GM 场景同一套 3D 骰子，不再使用自写 D6 网格只换颜色。
- 逻辑：地图 UI 等待 GM 物理骰实际落面，读取点数和 face index 后调用 `GameFlowController.apply_prepared_map_movement_roll()`；流程层继续校验这些结果必须来自 `RunState.dice` 的前两颗正式战斗骰。
- 兼容：GM target 参数补充 `{face_index: ...}` 格式，保留原 pip target 行为；地图只启用两颗骰，GM 视口透明叠在 2D 地图上。
- 验证：地图流程、地图背景、运行流程、GM 物理骰、正式战斗输入、战斗 smoke、骰子模型、中文显示、主场景 headless、`git diff --check` 均通过。
