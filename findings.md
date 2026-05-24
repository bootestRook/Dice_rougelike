# 2026-05-24 中文编码乱码发现

## 追加发现：本地化测试与终端 UTF-8

- `DebugLocalizationSmokeTest.gd` 的 CJK 禁止断言来自旧本地化迁移口径；当前项目按 AGENTS 要求保留大量中文可见文本，因此应检查乱码而不是禁止中文。
- 动态复合铸骰件如 `stay_4`、`red_2` 等不需要逐个静态 `FORGE_PART.*.NAME` key；它们已有动态 `display_name/description`。测试应验证最终显示文本，不应把缺少冗余 key 当作失败。
- Windows 终端中文显示乱码可以通过项目包装器缓解：`.cmd` 切到 UTF-8 代码页，`.ps1` 设置 `[Console]::OutputEncoding` 和 `$OutputEncoding` 为 UTF-8。直接调用 `Get-Content` 或 `godot` 仍取决于外部终端配置。

- `.editorconfig` 已声明 `charset = utf-8`。
- 直接用 PowerShell `Get-Content` 查看中文文件时，工具输出会把 UTF-8 中文误显示成类似 `涓婚...` 的乱码；这不是充分证据，后续判断以 Python 按 UTF-8 读取的原始代码点为准。
- `task_plan.md` 文件头按 UTF-8 读取为 `# 骰商铺实现计划`，说明该文件本身不是乱码。
- `tests_or_debug/DebugChineseDisplaySmokeTest.gd` 中的断言字符串按 UTF-8 读取为 `主骰型`、`标准骰胚`、`爆裂面饰` 等正确中文，说明该文件在终端中的乱码显示同样属于输出编码问题。
- 全量文本扫描结果：798 个文本文件均可按 UTF-8 解码，没有真实 UTF-8 损坏。
- 典型乱码扫描没有命中源代码、场景、资源、i18n 或测试文件；唯一初版命中来自本文件记录的终端乱码示例，不属于项目代码。
- 存在 5 个 UTF-8 BOM 文件：`docs/dice_tools_catalog.md`、`openspec/changes/archive/2026-05-22-match-reference-star-dice-visuals/tasks.md`、`tests_or_debug/captures/battle_screen_1920x1080_stage_frame_removed_after_manifest.json`、`tests_or_debug/DebugLeftSidebarFixedLayoutSmokeTest.gd`、`tools/scene_builders/BuildGmDiceVisualRepro.gd`。
- `DebugLocalizationSmokeTest.gd` 当前不适合作为编码防回归入口，因为该脚本还有既有本地化失败项；独立编码测试能避免把本轮验收和无关本地化迁移混在一起。

# 骰商铺发现记录

## 2026-05-23 第一圈商店保护发现
- 第一圈地图生成旧实现曾把中间 30 个节点全部设为 `shop`，这会让玩家刚出出生点就频繁踩商店，和“出生点后 1-12 格禁止 shop、最早第 15 格出现 shop”的保护规则冲突。
- 保护规则需要分两层处理：地图层负责首个 shop 的位置，商店层负责该 shop 的商品池；只改其中一层都会漏掉问题。
- “第一圈第一个商店”不应靠 `RunState.current_circle_index` 单独判断，还需要确认当前地图节点就是本圈第一个 shop；否则普通调试入口或后续商店也会误套保护池。
- 保护商店的刷新费应在当前店内固定走正常公式 `5 + reroll_count`，否则玩家可能通过当前店买到“刷新补贴 / 刷新过载”后立刻改变这个保护商店自身的刷新规则。
- 地图截图需要完整主场景承载才能看到节点图标；单独实例化 `MapStageView` 只能验证 manifest，不适合作为最终视觉图。

## 2026-05-23 购买遗物后顶部栏未同步发现
- 商店遗物货架购买链路已经把骰具遗物实例安装到 `RunState.dice_tools`，不是旧的 `relic_ids` 字段。
- 顶部战斗 HUD 的遗物栏仍由 `BattleScreen._build_relic_slots()` 从 `run_state.relic_ids` 构建，因此购买后底层状态已变化，但可见遗物栏仍显示空。
- 遗物容量也不应在 HUD 侧固定沿用旧展示容量；应从 `RunState.dice_tool_capacity + RunState.contract_tool_slots` 读取，才能和商店“遗物槽位剩余”一致。
- 修复方向是让商店、战斗 HUD、测试都以 `RunState.dice_tools` 作为骰具遗物的唯一运行时数据源，旧 `relic_ids` 仅保留为兼容回退。

## 2026-05-23 商店骰包总表发现
- 商店骰包最终只保留 9 个正式 ID：`pack_face_basic/large/mega`、`pack_combo_basic/large/mega`、`pack_relic_basic/large/mega`。
- 旧 `pack_tool_*` 不再符合最终命名，虽然显示名仍是骰具包，但内部正式 ID 应改为遗物包 ID。
- 遗物包的购买后效果不是进入普通道具槽，而是选择骰具遗物后直接进入遗物栏；因此购买前应检查遗物槽位，不应检查普通道具槽位。
- 铸骰件包和工坊服务包继续不属于商店骰包目录。

## 2026-05-23 长期解锁保留表发现
- 最新保留表为 29 项，之前只有 ID 的 `unlock_battle_reward_extra_choice` 现在明确为“宽幅调色板”，效果是战斗胜利奖励候选数 +1。
- 主型商人不再影响随机商品槽或主骰型升级件货架，改为商店骰包槽中主骰型包权重 ×2。
- 骰面陈列不再直接出售骰面商品，改为商店骰包槽中骰面改造包权重 ×2。
- 幻彩陈列不再创建高级骰面橱窗槽，改为让骰面改造包允许出现更高级骰面奖励。
- 储物水晶和反物质槽需要在文案上区分：前者是道具槽位，后者是遗物槽位。

## 2026-05-23 商店最终结构收窄发现
- 最新口径把骰商铺固定为长期解锁 ×1、商店骰包 ×2、骰具遗物 ×2、刷新按钮、离开按钮。
- 商店骰包目录应只保留骰面改造包、主骰型包、骰具包；铸骰件包和工坊服务包从商店骰包目录移除。
- 原随机商品槽需要收窄为遗物货架，商品池只出骰具遗物；刷新按钮只替换遗物货架。
- 商人服务槽和高级骰面橱窗不再属于最终商铺结构；长期解锁池也需要剔除对应不再产生当前局收益的商铺项。

## 2026-05-23 遗物货架规则发现
- 遗物货架不是道具货架：购买骰具遗物后必须直接进入 `RunState.dice_tools`，不占用 `item_slots`。
- 满栏阻止应检查 `get_free_dice_tool_slot_count()`，提示固定为“遗物栏已满，请先出售一个遗物。”；道具槽满不再影响遗物货架购买。
- 传说骰具遗物不能出现在普通骰商铺：除了遗物货架直接售卖，商铺内出售的骰具包也应过滤传说遗物，否则仍等价于普通商铺卖传说。
- 当前 `DiceToolCatalog` 没有史诗骰具遗物；第 6–8 圈 2% 史诗权重会在无史诗池时回退到其他非传说池，等后续有史诗遗物数据后自动生效。
- 商铺出售遗物需要走规则层统一入口，以便触发 `DiceToolService.on_tool_sold()`，否则双奖汽水、营火出售器等已有出售钩子会被绕过。
- `CaptureShopScreenLayout.gd` 不能在 headless 模式下取 `root.get_texture()`；截图验收需要非 headless Godot，并加 `--quit-after` 防止截图失败时进程挂起。
- 商铺卡片只写“购买后进入遗物栏 / 购买后打开”不足以支撑购买决策；需要在卡片正文直接展示骰具效果、骰包候选数、选择数和内容范围。
- `purchase_offer_by_slot()` 最初只在长期解锁和遗物货架购买后清槽，骰包购买后虽然打开了候选包，但 `booster_slots` 原槽位仍保留旧 offer，导致玩家完成包选择后还能看到原骰包卡；骰包槽也需要购买成功即设为 `null`。

## 2026-05-23 长期解锁总表发现
- 当前 `LongTermUnlockCatalog` 只有 10 项旧长期解锁，需要替换为新总表。
- `LongTermUnlockDef` 当前只支持 `effect_type + int effect_value`，无法表达折扣、布尔开关、权重倍率等复合效果；需要扩展为参数字典或用服务层按 ID 分发。
- `RunState` 已有部分字段：`shop_random_item_slot_bonus`、`shop_booster_slot_bonus`、`shop_reroll_base_cost`、`item_slot_capacity`、`dice_tool_capacity`、`battle_rounds_available_delta`、`battle_rerolls_per_hand_delta`、`max_scored_faces_per_round_delta`，可直接映射部分新项。
- 第 32 项缺完整规格，不应放入商铺池。
- 已落地发现：完整 31 项可用；第 32 项 `unlock_battle_reward_extra_choice` 没有显示名、价格、类型和具体效果，保持不入池。
- 工坊服务包此前默认在骰包池内；现在改为必须购买“工坊预兆”后才进入骰商铺骰包槽。
- “骰面陈列”通过随机商品槽出售基础骰面改造商品并复用骰包候选处理；“幻彩陈列”通过额外高级骰面橱窗槽展示大型/豪华骰面改造包。
- Boss 规则重拟/追溯当前以 `RunState` 参数形式保存，供后续 Boss 规则选择界面读取；危急值减免已接入目标分计算。

## 待审查
- 需要确认地图是否已有商店格子/节点类型。
- 需要确认是否已有 Shop、Voucher、Pack、Service、Item 相关脚本或只存在奖励/铸骰件系统。
- 需要确认主流程 `GameFlowController` 如何在 Battle / Reward / Forge / Map 间切换，以最小范围接入 Shop。

## 2026-05-23 初步发现
- 仓库已有 `scenes/shop/ShopScreen.tscn`、`scripts/ui/shop/ShopScreen.gd`、`scripts/rules/shop/ShopService.gd`、`ShopCatalog.gd`、`BoosterPackService.gd`，以及 `DebugShopPackSmokeTest.gd`。
- `MainPrototypeView` 已监听 `GameFlowController.shop_requested` 并加载 `ShopScreen`。
- 现有 Debug 测试已覆盖 2 个随机商品槽、2 个补充包槽、1 个长期解锁槽和刷新只改随机商品槽，但需要确认商人服务槽是否缺失、UI 文案是否需要从“商店/补充包”调整为“骰商铺/商店骰包”。

## 2026-05-23 细化发现
- `ShopService.generate_shop()` 当前只生成 `random_item_slots`、`booster_slots`、`long_term_unlock_slot`，缺少 `merchant_service_slot`。
- `ShopScreen` 当前标题为“商店”，顺序为随机商品 -> 补充包 -> 长期解锁，缺少离开按钮。
- `GameFlowController` 已有 `enter_shop()`，但地图落到 `shop` 节点后没有 pending shop 状态，也没有从地图进入商店/离开商店回地图的专用方法。
- 商店截图脚本在 headless 模式会卡住取图；非 headless 运行可正常保存 PNG。

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
# Resource cleanup findings 2026-05-23

- Runtime reference scan found 124 image files under `assets/`.
- 100 images are referenced by current runtime files in `project.godot`, `scenes/`, `scripts/`, or active `.tres/.tscn` assets.
- Confirmed delete candidates: `assets/ui/map/node_*_placeholder.png` and `assets/ui/map/source/generated_node_icon_sheet_20260519.png`; their replacements are already wired through `scenes/map/resources/MapStageArtConfig.tres`.
- Kept `assets/scenes/preview/preview_shots/*.png`: not runtime game dependencies, but material pipeline Debug tests and docs still depend on them.
- No battle VFX frames in `assets/ui/battle/vfx` are unused: reroll frames are preloaded by `RerollMagicFx.gd`, and round intro textures are ext_resources in `RoundIntroBanner.tscn`.
- After cleanup, the only runtime-unreferenced images left under `assets/` are material preview screenshots intentionally retained for pipeline validation.
# 2026-05-24 Elite Victory Flow Findings

- User report: in an elite battle, score is already over the target and the UI displays "战斗胜利", but the flow still proceeds into the next hand roll.
- Working tree was already dirty before this pass: `scripts/ui/battle/components/BattleDiceStage3D.gd`, `tests_or_debug/CaptureBattleScreenLayout.gd`, and `tests_or_debug/DebugBattleDiceHoverInfoSmokeTest.gd`.
- `session-catchup.py` returned exit code 1 with no output; continue from current git status and source inspection.
- `BattleController.commit_pending_resolution()` already stops `start_next_hand()` when `battle_state.battle_finished` is true.
- `BattleScreen._play_battle_intro_magic()` restores/clears the victory target overlay before a new hand intro, but the newer external 3D entry path `_play_initial_3d_roll_for_hand()` does not.
- If the victory target overlay is active and the 3D path enters a hand, the left target panel can still show "战斗胜利" while dice are rolling.
# 2026-05-24 UI Debug Cleanup Warning Findings

- Known warning commands from the last pass: `DebugBattleDiceInputSmokeTest.gd`, `DebugBattleRewardFlowUiSmokeTest.gd`, `DebugEliteVictoryFlowSmokeTest.gd`, and `CaptureEliteVictoryFlowState.gd`.
- These scripts instantiate UI scenes or controls and call `quit()` immediately after `queue_free()` or without freeing the instantiated screen, so queued frees may not be flushed before SceneTree shutdown.
- Verbose leak output showed stray fallback `PanelContainer` / `HBoxContainer` / `Control` nodes from `BattleScreen._instantiate_control(scene, fallback)`: callers eagerly constructed fallback controls, but the helper returned the scene instance without freeing the unused fallback.
- After fixing the CanvasItem leaks, `DebugBattleDiceInputSmokeTest.gd` also exposed existing strict GDScript compile issues in map event scripts; they were small self-reference/type-inference fixes.
