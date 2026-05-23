# 骰商铺进度记录

## 2026-05-23 追加：第一圈商店保护
- 根据新规则，第一圈地图生成已改为出生点后第 1-14 格不出现商店，首个商店固定在第 15 格；本轮生成示例商店索引为 15、24、29。
- `GameFlowController.enter_shop()` 现在会识别当前节点是否为第一圈第一个商店，并向 `ShopService.generate_shop()` 传入 `first_circle_first_shop` 保护上下文。
- 第一圈第一个商店的骰包池只允许基础包和大型包：骰面改造包 / 大型骰面改造包、主骰型包 / 大型主骰型包、骰具包 / 大型骰具包；豪华三类包不进池，大型包权重低于基础包。
- 第一圈第一个商店保证骰包槽至少 1 个 4 金币基础包，遗物货架至少 1 个普通骰具遗物；刷新费强制走正常 5 金币起步，不吃首刷免费或刷新补贴对当前店的改价。
- 已新增截图脚本 `CaptureFirstCircleShopProtectionMap.gd`，并扩展 `CaptureShopScreenLayout.gd` 支持 `first_circle` 参数。
- 验证通过：`DebugShopPackSmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、`DebugLongTermUnlockSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`、主场景 headless。
- 新视觉截图：`G:/Dice_rougelike/tests_or_debug/captures/map_first_circle_shop_protection_after.png`、`G:/Dice_rougelike/tests_or_debug/captures/shop_screen/shop_screen_after_first_circle_shop_protection_1920x1080.png`。

## 2026-05-23 追加：购买遗物后顶部遗物栏同步
- 根据用户反馈“购买遗物后没显示在遗物栏”，定位到商店购买已正确写入 `RunState.dice_tools`，但战斗顶部 HUD 仍读取旧字段 `run_state.relic_ids`，导致栏位计数和显示不更新。
- 已修改 `BattleScreen._build_relic_slots()`，优先从 `run_state.dice_tools` 构建顶部遗物栏槽位，并使用 `DiceToolCatalog` 补齐显示名与效果提示。
- 已修改 `BattleScreen._build_hud_state()`，遗物栏容量读取 `dice_tool_capacity + contract_tool_slots`，与商店中“遗物槽位剩余”规则保持同一数据源。
- `DebugShopPackSmokeTest.gd` 新增购买遗物后顶部遗物栏模型断言，确认购买成功后 HUD 能显示对应遗物并更新容量。
- `CaptureBattleScreenLayout.gd` 新增 `relic` 截图参数，用于生成带已拥有遗物的战斗界面截图。
- 追加强化验证通过：`DebugShopPackSmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、`DebugBattleSmokeTest.gd`、主场景 headless、`git diff --check`。
- 新视觉截图：`G:/Dice_rougelike/tests_or_debug/captures/battle_screen_1920x1080.png`。

## 2026-05-23 追加：商店骰包总表
- 收到商店骰包槽最终总表：骰面改造包、主骰型包、遗物包三类，各三档，共 9 个。
- 已将骰具包正式 ID 从 `pack_tool_basic/large/mega` 改为 `pack_relic_basic/large/mega`。
- `BoosterPackDef` 新增 `KIND_RELIC`，商店骰包池只允许 face / combo / relic 三类。
- 遗物包候选选择后不再进入道具槽位，改为直接装备到遗物栏；豪华遗物包购买前要求至少 2 个空遗物槽。
- 验证通过：`DebugShopPackSmokeTest.gd`、`DebugLongTermUnlockSmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugDiceToolThirdBatchSmokeTest.gd`、`DebugForgeItemFormalSmokeTest.gd`、主场景 headless、`git diff --check`。

## 2026-05-23 追加：长期解锁保留表
- 收到长期解锁槽可保留内容表，共 29 项。
- 已移除长期解锁池中的铸骰坊相关保留项：工坊预兆、铸骰商人、铸骰大亨。
- 已把“主型商人”改为商店骰包槽中主骰型包权重 ×2；“骰面陈列”改为骰面改造包权重 ×2；“幻彩陈列”改为骰面改造包允许出现更高级骰面奖励。
- 已新增“宽幅调色板”：战斗胜利奖励候选数 +1，接入 `GameFlowController.on_battle_won()`。
- 已新增运行参数：`shop_face_pack_weight_multiplier`、`shop_combo_pack_weight_multiplier`、`advanced_face_pack_rewards_enabled`、`battle_reward_choice_bonus`。
- 验证通过：`DebugLongTermUnlockSmokeTest.gd`、`DebugShopPackSmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugForgeRewardSmokeTest.gd`、主场景 headless。
- 新视觉截图：`G:/Dice_rougelike/tests_or_debug/captures/shop_screen/shop_screen_after_retained_long_term_unlocks_1920x1080.png`。

## 2026-05-23 追加：商店最终结构收窄
- 收到最终结构口径：长期解锁 ×1、商店骰包 ×2、骰具遗物 ×2、刷新按钮、离开按钮。
- 决策：删除商人服务槽；随机商品槽改名并收窄为遗物货架；刷新只刷新遗物货架；骰包槽移除工坊服务包和铸骰件包。
- 已完成：`ShopService.generate_shop()` 只生成 `long_term_unlock_slot`、`booster_slots`、`relic_shelf_slots`；`ShopScreen` 只渲染长期解锁槽、商店骰包槽和遗物货架。
- 已完成：`BoosterPackCatalog` 收窄为 9 个正式商店骰包，分别为骰面改造包、主骰型包、骰具包三档；铸骰件包和工坊服务包不再属于商店骰包目录。
- 已完成：`ShopCatalog` 的遗物货架池只返回骰具遗物；商人服务商品类型和高级骰面橱窗生成路径已移除。
- 验证通过：`DebugShopPackSmokeTest.gd`、`DebugLongTermUnlockSmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`、主场景 headless。
- 新视觉截图：`G:/Dice_rougelike/tests_or_debug/captures/shop_screen/shop_screen_after_final_shop_structure_1920x1080.png`。

## 2026-05-23 追加：长期解锁总表
- 收到长期解锁槽最终总表。
- 决策：玩家可见按新表替换；第 32 项只有 ID，暂不进入池。
- 已扩展 `RunState` 长期解锁参数，替换 `LongTermUnlockCatalog` 为 31 个完整项。
- 已接入骰商铺折扣、随机商品权重、工坊服务包解锁、骰包候选数、主骰型偏好、战斗得分加成、胜利经济与危急值减免。
- 已重写 `DebugLongTermUnlockSmokeTest.gd` 覆盖新总表口径。
- 验证通过：`DebugLongTermUnlockSmokeTest.gd`（含契约骰具槽断言）、`DebugShopPackSmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、`DebugBattleSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugDiceToolThirdBatchSmokeTest.gd`、`DebugMapNonCombatVisualStateSmokeTest.gd`、主场景 headless、`git diff --check`。
- 新视觉截图：`G:/Dice_rougelike/tests_or_debug/captures/shop_screen/shop_screen_after_long_term_unlock_table_1920x1080.png`。

## 2026-05-23
- 启动本轮任务：实现地图商店格子的“骰商铺”推荐结构。
- 使用 `planning-with-files` 技能。
- `session-catchup.py` 返回 exit 1 且无输出，已记录。
- 已在计划文件顶部追加本轮目标、阶段、决策和错误记录，保留上一轮完成记录。
- 初步搜索发现商店系统已存在；本轮重点转为补齐“商人服务槽”和固定展示顺序，尽量复用现有 ShopService / ShopScreen。
- 新增 `CaptureShopScreenLayout.gd` 用于商店界面截图基线。
- 第一次运行商店截图脚本超时，未生成截图；主场景 headless `--quit-after 1` 可正常启动，已清理本次遗留 Godot 进程。
- 改用非 headless Godot 运行截图脚本成功，改动前截图：`G:/Dice_rougelike/tests_or_debug/captures/shop_screen/shop_screen_before_shop_structure_1920x1080.png`。
- 规则层开始接入：`ShopOfferDef` 增加商人服务类型，`ShopCatalog` 增加商人服务定义，`ShopService` 生成 `merchant_service_slot` 并支持购买低风险商人服务。
- 首次复跑 `DebugShopPackSmokeTest.gd` 失败：`ShopService.gd` 第 320 行 `gain` 从 Variant 推断类型被当作错误处理；已改为显式 `int`。
- `DebugShopPackSmokeTest.gd` 已通过，并新增商人服务槽、刷新范围和商人服务效果断言。
- 首次复跑 `DebugMapStageFlowSmokeTest.gd` 新增商店节点断言时，手动设置骰子台揭示状态导致进入按钮未显示；测试改为调用真实 `play_raise()` 流程。
- 根据用户反馈统一玩家可见命名：入口、地图节点、日志、骰具描述、长期解锁说明、骰包消息均改为“骰商铺 / 骰包”，不再混用“商店 / 补充包”。
- 改动后截图已生成：`G:/Dice_rougelike/tests_or_debug/captures/shop_screen/shop_screen_after_shop_structure_1920x1080.png`，1080p 首屏可见完整固定结构。
- 验证通过：`DebugShopPackSmokeTest.gd`、`DebugLongTermUnlockSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugDiceToolThirdBatchSmokeTest.gd`、`DebugMapNonCombatVisualStateSmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、主场景 headless、`git diff --check`。
- 追加实现遗物货架最终规则：货架只生成骰具遗物，购买直接安装进遗物栏并立即生效，购买后槽位变为“已售罄”。
- 遗物货架新增圈数稀有度权重，普通商铺和商铺骰具包均排除传说遗物；遗物价格更新为普通 6、罕见 9、稀有 13、史诗 18。
- 新增商铺内出售已拥有遗物：UI 二次确认，规则层按 `max(1, floor(base_price * 0.5))` 发放金币并释放遗物槽，出售时触发已有骰具出售钩子。
- 刷新逻辑确认只刷新遗物货架，不刷新长期解锁、骰包或遗物栏；刷新不改变危急值行动次数。
- 离开商铺后地图节点保持 cleared；同一圈再次触发该商铺节点不会重新进入商铺，地图中心文本显示“店铺已打烊”。
- 截图脚本增加 `with_relics` 参数用于展示已拥有遗物出售区；headless 无法读取 viewport texture，最终使用非 headless + `--quit-after 5` 成功截图。
- 新视觉截图：`G:/Dice_rougelike/tests_or_debug/captures/shop_screen/shop_screen_after_relic_shelf_rules_1920x1080.png`。
- 追加验证通过：`DebugShopPackSmokeTest.gd`、`DebugLongTermUnlockSmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`、`DebugDiceToolFirstBatchSmokeTest.gd`、`DebugDiceToolSecondBatchSmokeTest.gd`、`DebugDiceToolThirdBatchSmokeTest.gd`、`DebugForgeItemFormalSmokeTest.gd`、主场景 headless、`git diff --check`。
- 根据用户反馈补充商铺卡片效果可读性：骰具遗物货架直接显示骰具效果文本，骰包显示候选数、选择数、内容范围和选择后效果。
- 新截图：`G:/Dice_rougelike/tests_or_debug/captures/shop_screen/shop_screen_after_shop_effect_text_1920x1080.png`。
- 追加验证通过：`DebugShopPackSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`、主场景 headless、`git diff --check`。
- 根据用户反馈修复骰包槽购买后未显示售罄：`ShopService.purchase_offer_by_slot()` 现在在 `booster_slots` 购买成功后同步把对应槽位设为 `null`，UI 渲染为“已售罄”。
- 截图脚本增加 `sold_pack` 参数用于捕捉骰包购买后的售罄状态；新截图：`G:/Dice_rougelike/tests_or_debug/captures/shop_screen/shop_screen_after_booster_sold_out_1920x1080.png`。
- 追加验证通过：`DebugShopPackSmokeTest.gd`、主场景 headless、`git diff --check`。

# 战斗入场与操作按钮进度记录

## 2026-05-21 追加：地图前进骰改为正式战斗骰
- `GameFlowController.gd`：地图移动骰固定取 `RunState.dice` 前两颗，使用 `RollService` 投掷，保留两格结果槽并新增 `last_roll_face_indices` / `movement_die_face_counts`。
- `MapStageView.gd`：地图 UI 同步两颗正式骰，按钮文案改为“正式战斗骰”，预投掷结果带 face index 回写流程层。
- `MapMovementDicePhysicsView.gd`：物理表现层接收正式骰引用，快照暴露正式骰 id / 面数，并按正式骰胚颜色刷新骰体材质。
- `DebugRunFlowSmokeTest.gd`：新增前两颗正式骰自定义点数分布决定地图步数的断言。
- `DebugMapStageFlowSmokeTest.gd`：新增地图 UI 绑定 `normal_d6_1` / `normal_d6_2` 和 face index 的断言。
- 验证通过：`DebugRunFlowSmokeTest.gd`、`DebugMapStageFlowSmokeTest.gd`、`DebugBattleSmokeTest.gd`、`DebugDiceModelRefactorSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`、主场景 headless、`git diff --check`。

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
## 2026-05-21 追加：地图前进骰改为 GM 场景骰子
- `MapMovementDicePhysicsView.gd`：内部改为创建 `GmDiceViewport`、`GmReadyMgr`、`GmBattleMgr`，用正式战斗 GM 骰子显示、选择、投掷和回位；旧自写 D6 物理网格不再作为地图主投掷表现。
- `MapStageView.gd`：地图投掷现在等待 GM 物理骰实际结果，读取 `last_values` / `last_face_indices` 后再提交地图移动；fallback 分支仍可用流程层预投结果。
- `GmBattleMgr.gd` / `GmDiceInstance.gd`：target 兼容 `{face_index: ...}`，为精确正式骰面请求留接口，同时保留原 pip target。
- `DebugMapStageFlowSmokeTest.gd`：新增地图骰使用 GM scene view 的断言，并把地图动画等待窗口调大到覆盖 GM 物理骰和回位耗时。
- 追加验证通过：`DebugMapStageFlowSmokeTest.gd`、`DebugMapBackgroundTextureVisibilitySmokeTest.gd`、`DebugRunFlowSmokeTest.gd`、`DebugGmPhysicsDiceTargetSmokeTest.gd`、`DebugGmPhysicsDiceTestSmokeTest.gd`、`DebugBattleDiceInputSmokeTest.gd`、`DebugMapNonCombatVisualStateSmokeTest.gd`、`DebugBattleSmokeTest.gd`、`DebugDiceModelRefactorSmokeTest.gd`、`DebugChineseDisplaySmokeTest.gd`、主场景 headless、`git diff --check`。Godot 退出时仍有既有 CanvasItem/ObjectDB 泄漏警告，相关命令退出码为 0。
# Resource cleanup progress 2026-05-23

- Used `planning-with-files` for this cleanup pass.
- Initial `python` command hit the Windows Store shim; switched to bundled Python from workspace dependencies.
- `GODOT_BIN` is set to `C:/Users/Arche/AppData/Local/CodexGodot/codex-godot-4.6.2/Godot_v4.6.2-stable_win64_console.exe`.
- Git working tree was already dirty before cleanup; this pass will only remove confirmed unused image resources and matching `.import` files.
- Deleted 10 old map `node_*_placeholder.png` files, their 10 `.import` sidecars, the unused generated source sheet, its `.import`, and the now-empty `assets/ui/map/source` folder.
- Updated `assets/ui/map/ATTRIBUTION.md` so attribution no longer points at deleted node placeholders or the deleted source sheet.
- Verification passed: main scene startup, `DebugMapBackgroundTextureVisibilitySmokeTest.gd`, `DebugMapStageFlowSmokeTest.gd`, `DebugBattleSmokeTest.gd`, `DebugBattleDiceInputSmokeTest.gd`, and targeted `git diff --check`.
- Visual acceptance: copied the existing map capture as a before baseline, reran `CaptureFirstCircleShopProtectionMap.gd`, and confirmed the before/after PNG hashes match.
