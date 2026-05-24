# 2026-05-24 中文编码乱码彻查计划

## 追加处理：本地化测试与终端 UTF-8
- 状态：complete
- 范围：修复 `DebugLocalizationSmokeTest.gd` 既有失败；让 `tools/dev/godot.cmd` / `godot.ps1` 在 Windows 下以 UTF-8 输出 Godot 日志，降低中文显示乱码风险。
- 处理：补 `TAG.EVEN`，把过时的“源码不得有中文”断言改为“源码不得有 mojibake”，动态铸骰件改为校验最终显示文本；新增 `upgrade/combo_upgrade` 标签中文映射。
- 验证：`DebugLocalizationSmokeTest.gd`、`DebugChineseEncodingSmokeTest.gd`、通过包装器运行的 `DebugChineseDisplaySmokeTest.gd`、主场景 headless 均通过。

## 目标
彻查项目文本文件中真实写入仓库的中文乱码、非 UTF-8 内容和典型误编码痕迹；修复确认的问题，并加入防回归检查。保持现有功能逻辑不变。

## 阶段
| 阶段 | 状态 | 内容 |
|---|---|---|
| 1. 范围确认 | complete | 已确认判断依据为原始字节与 UTF-8 解码结果，PowerShell 显示乱码不直接作为文件损坏证据 |
| 2. 全量扫描 | complete | 已扫描 UTF-8 解码错误、替换字符、典型 mojibake 模式和中文可见文本 |
| 3. 修复 | complete | 无真实中文乱码；已移除 5 个 UTF-8 BOM，统一为 UTF-8 无 BOM |
| 4. 防回归 | complete | 已新增独立 `DebugChineseEncodingSmokeTest.gd`，覆盖项目文本扩展名、UTF-8 BOM 和典型 mojibake 模式 |
| 5. 验证 | complete | 已运行编码复扫、`DebugChineseEncodingSmokeTest.gd`、中文显示/面显示 Debug、主场景 headless 和 `git diff --check` |

## 决策
- 不根据 PowerShell `Get-Content` 的显示结果直接判定文件乱码；以原始字节和 UTF-8 解码结果为准。
- 本轮不回退已有 dirty/untracked 改动，只在编码排查需要的文件上做最小改动。
- 功能行为不变，新增检查只做验证和防回归。

# 骰商铺实现计划

## 2026-05-23 追加处理：商店骰包总表
- 状态：complete
- 目标：商店骰包槽只保留骰面改造包、主骰型包、遗物包三类包。
- 范围：正式包 ID 改为 `pack_face_*`、`pack_combo_*`、`pack_relic_*` 共 9 个；移除 `pack_tool_*` 正式 ID；遗物包选择后直接进入遗物栏，并按选择数检查遗物槽位。
- 验证结果：`DebugShopPackSmokeTest.gd`、`DebugLongTermUnlockSmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugDiceToolThirdBatchSmokeTest.gd`、`DebugForgeItemFormalSmokeTest.gd`、主场景 headless 和 `git diff --check` 均通过。

## 2026-05-23 追加处理：长期解锁保留表
- 状态：complete
- 目标：按最新“长期解锁槽可保留内容”表收敛长期解锁池。
- 范围：长期解锁目录改为 29 项；移除铸骰坊相关长期解锁；新增“宽幅调色板”；主型商人 / 骰面陈列改为商店骰包权重；幻彩陈列改为骰面改造包高级奖励开关。
- 验证结果：`DebugLongTermUnlockSmokeTest.gd`、`DebugShopPackSmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugForgeRewardSmokeTest.gd` 和主场景 headless 均通过。

## 2026-05-23 追加处理：商店最终结构收窄
- 状态：complete
- 目标：按最新口径把骰商铺最终结构固定为长期解锁 ×1、商店骰包 ×2、骰具遗物 ×2、刷新按钮、离开按钮。
- 范围：移除商人服务槽；随机商品槽改为遗物货架且只给骰具遗物；骰包槽只保留骰面包 / 主骰型包 / 遗物包；长期解锁池剔除铸骰坊相关与不再有收益的商铺项。
- 验证结果：`DebugShopPackSmokeTest.gd`、`DebugLongTermUnlockSmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`、主场景 headless 和商铺截图均通过。

## 2026-05-23 追加处理：长期解锁槽总表
- 状态：complete
- 目标：用用户给出的长期解锁总表替换当前长期解锁池；无前置、购买立刻生效、已购买不再出现、当前局无收益时不进池。
- 范围：`LongTermUnlockCatalog` / `LongTermUnlockService` / `RunState` 参数，商铺生成筛选，能直接接上的商铺、骰包、战斗资源、经济和危急值效果。
- 第 32 项 `unlock_battle_reward_extra_choice` 目前只有 ID，缺少显示名、价格、类型和具体效果；本轮不进池，避免生成不可解释项。
- 验证结果：`DebugLongTermUnlockSmokeTest.gd`、`DebugShopPackSmokeTest.gd`、运行流程、战斗、中文显示、地图商铺入口、骰具商铺钩子、地图非战斗视觉状态、主场景 headless 和 `git diff --check` 均通过。

## 目标
从地图进入商店格子时展示“骰商铺”界面。最终结构固定为：1 个长期解锁槽、2 个商店骰包槽、2 个可刷新的遗物货架槽、1 个刷新按钮、1 个离开按钮。刷新只影响遗物货架，所有玩家可见文本保持中文。

## 阶段
| 阶段 | 状态 | 内容 |
|---|---|---|
| 1. 现状审查 | complete | 梳理地图节点类型、进入商店流程、Reward/RunState 数据与现有 UI |
| 2. 规则与状态 | complete | 增加商店库存生成、刷新随机商品、购买/服务数据结构 |
| 3. 商铺 UI | complete | 新增或接入商店界面，展示固定槽位和刷新/离开操作 |
| 4. 流程接入 | complete | 地图商店格子进入商铺，离开后返回地图 |
| 5. Debug 测试 | complete | 补商店库存、刷新范围、流程中文显示测试 |
| 6. 验证 | complete | 运行相关 Debug 脚本、主场景 headless、diff 检查 |

## 决策
- 本轮不做血量、敌人、Boss、商店存档或大规模地图重构。
- 商店 UI 只显示库存和转发购买/刷新/离开操作，商品生成与刷新逻辑放在规则/运行层。
- 遗物货架可刷新；长期解锁和骰包进入商铺时生成，不被刷新按钮改变。

## 错误记录
| 时间 | 错误 | 处理 |
|---|---|---|
| 2026-05-23 | `session-catchup.py` 返回 exit 1 且无输出 | 已记录，改用现有计划文件、`git status` 和源码审查继续 |
| 2026-05-23 | `CaptureShopScreenLayout.gd` 首次运行超时 | 已确认 Godot headless 可启动；后续调整截图脚本后重试 |
| 2026-05-23 | `DebugShopPackSmokeTest.gd` 报 `gain` Variant 类型推断错误 | 已将 `gain` 显式声明为 `int` |
| 2026-05-23 | `DebugMapStageFlowSmokeTest.gd` 商店节点进入按钮断言失败 | 改为在测试中跑真实地图抬升流程后再断言 |

## 2026-05-23 追加处理：遗物货架最终规则
- 状态：complete
- 范围：原随机商品槽最终收窄为“遗物货架”，只生成骰具遗物；购买后直接进入遗物栏并立即生效，不再进入道具槽。
- 规则：遗物货架默认 2 格、可刷新；刷新按钮只替换遗物货架，长期解锁槽和骰包槽保持不变；刷新费用按 `max(1, 5 + reroll_count - discount)`，首次免费刷新仍显示 0。
- 经济：普通 / 罕见 / 稀有 / 史诗遗物价格分别为 6 / 9 / 13 / 18；出售价格统一为 `floor(base_price * 0.5)` 且最低 1。
- 稀有度：普通商铺和商铺遗物包均排除传说骰具遗物；遗物货架按圈数权重抽取普通 / 罕见 / 稀有 / 史诗。
- UI：商铺界面增加已拥有遗物区，支持二次确认出售；已购买货架槽显示“已售罄”；遗物栏满时购买按钮禁用并提示“遗物栏已满，请先出售一个遗物。”。
- 地图：离开商铺后当前商铺节点标记已访问，同一地图圈再次尝试进入会保持地图阶段，并显示“店铺已打烊”状态。
- 验证：`DebugShopPackSmokeTest.gd`、`DebugLongTermUnlockSmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、中文显示、三批骰具测试、铸骰件正式测试、主场景 headless、`git diff --check` 均通过。

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
# Resource cleanup plan 2026-05-23

## Goal
Remove image/VFX resources that are not referenced by the current game runtime, while preserving resources that are still required by validation scripts or active configs.

## Phases
| Phase | Status | Notes |
|---|---|---|
| 1. Scan resources | complete | Scanned `assets/` images against `project.godot`, `scenes/`, `scripts/`, and runtime `.tres/.tscn` refs. |
| 2. Decide cleanup scope | complete | Delete old map node placeholder images and the unused generated source sheet; keep material preview screenshots because pipeline Debug tests assert them. |
| 3. Delete files | complete | Removed old map node placeholder PNG files, the unused source sheet, matching `.import` sidecars, and the now-empty source folder. |
| 4. Verify | complete | Main scene startup, focused Debug checks, targeted diff check, and before/after map screenshot hash comparison passed. |
# 2026-05-24 Elite Victory Flow Bug

## Goal
Fix the battle flow where an elite battle can show victory after the score reaches the target but still advance into the next hand roll.

## Phases
| Phase | Status | Notes |
|---|---|---|
| 1. Inspect flow | complete | Located controller finish guard and stale UI victory target overlay in the 3D hand entry path. |
| 2. Patch logic | complete | Restored the target panel before external 3D hand entry and marked predicted victory overlays for restoration. |
| 3. Add Debug coverage | complete | Added elite controller victory and stale victory overlay regression coverage. |
| 4. Verify | complete | Focused battle Debug tests, reward flow, run flow, visual capture, main scene startup, and `git diff --check` passed. |

## Decisions
- Preserve existing dirty files unless they are directly required for this bug.
- Keep the fix in runtime/controller logic; UI should only reflect returned battle state.

## Verification
- `DebugEliteVictoryFlowSmokeTest.gd`: PASS
- `DebugBattleSmokeTest.gd`: PASS
- `DebugBattleDiceInputSmokeTest.gd`: PASS
- `DebugBattleRewardFlowUiSmokeTest.gd`: PASS
- `DebugRunFlowSmokeTest.gd`: PASS
- Visual capture: PASS
- Main scene startup: PASS
- `git diff --check`: PASS

# 2026-05-24 UI Debug Cleanup Warnings

## Goal
Remove Godot CanvasItem/ObjectDB leak warnings from the UI Debug and capture commands used for the elite victory flow verification.

## Phases
| Phase | Status | Notes |
|---|---|---|
| 1. Inspect cleanup paths | complete | Found eager fallback controls leaked by `BattleScreen._instantiate_control()` and pending UI feedback tweens in Debug teardown. |
| 2. Patch cleanup waits | complete | Freed unused fallback controls, added sidebar feedback flush/exit cleanup, and cleaned Debug/capture roots before quitting. |
| 3. Verify warning-free runs | complete | Known headless UI Debug commands now exit without CanvasItem/ObjectDB warnings; capture is clean with OpenGL driver. |

## Decisions
- Scope this pass to Debug/capture scripts, not runtime UI behavior.
- Preserve unrelated current dirty files.

## Verification
- `DebugBattleDiceInputSmokeTest.gd`: PASS, no CanvasItem/ObjectDB warnings
- `DebugBattleRewardFlowUiSmokeTest.gd`: PASS, no CanvasItem/ObjectDB warnings
- `DebugEliteVictoryFlowSmokeTest.gd`: PASS, no CanvasItem/ObjectDB warnings
- `CaptureEliteVictoryFlowState.gd` with `--rendering-driver opengl3`: PASS, no leak warnings
- `DebugBattleSmokeTest.gd`: PASS
- Main scene startup: PASS
- `git diff --check`: PASS with existing CRLF normalization warnings on unrelated dirty files
