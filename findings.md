# 12_长期解锁发现记录

## 初始发现
- 现有 12 模块只有 `scripts/rules/long_term/LongTermUnlockService.gd`，目前是购买后把 `unlock_id` 标记到 `run_state.long_term_unlocks` 的 stub。
- 11 的商店通过 `ShopCatalog.make_long_term_unlock_offer()` 生成长期解锁槽，默认 `unlock_future_shop_slot`，`ShopService._purchase_long_term_unlock()` 调用 `LongTermUnlockService.apply_unlock()`。
- `RunState` 已有 `coins`、`item_slot_capacity`、`dice_tool_capacity`、`shop_reroll_base_cost`、`current_shop_state`、`long_term_unlocks`、`shop_logs`。
- `DiceToolService` 和商店已有参数相关逻辑：免费刷新、价格查询、道具槽位、骰具槽位等，可以把长期解锁做成对 RunState 参数的修改。

## 指令文件状态
- `codex_12_long_term_unlocks_instruction_v1.md` 未在仓库、`.codex` 目录或递归文件名搜索中找到。
- 用户消息明确了核心边界：不使用旧概念、不新增槽位/等级、只改全局规则参数/商店参数/槽位参数/经济参数/Boss 服务钩子、终倍率整数。

## 设计方向
- 新增 `LongTermUnlockDef` 与 `LongTermUnlockCatalog`，用正式 ID 和中文名称描述长期解锁项。
- `LongTermUnlockService` 负责应用一次性解锁、重算参数、查询可购买项和中文日志。
- 通过 `RunState` 提供 `apply_long_term_unlock_parameters()` / `get_long_term_unlock_bonus()` 一类钩子，避免 UI 或商店写规则。

## 目录草案
- 10 个长期解锁：道具槽扩容、骰具槽扩容、刷新议价、商品陈列位、补充包陈列位、额外出手机会、额外重投机会、结算位扩容、金币储备、首领规则保险。
- 全部为参数或服务钩子，不涉及骰面槽位、骰子等级、骰面等级、条件标签等级，也不改变终倍率类型。
