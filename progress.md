# 12_长期解锁进度记录

## 2026-05-19
- 启动 12_长期解锁任务，使用 `planning-with-files`。
- 查找 `codex_12_long_term_unlocks_instruction_v1.md`：未找到。
- 读取现有 `LongTermUnlockService.gd`：目前仅为 stub。
- `git status --short` 显示 11 相关 dirty/untracked 仍存在，按用户要求不回滚、不清理。
- 新增 `LongTermUnlockDef.gd` 和 `LongTermUnlockCatalog.gd`，定义 10 个正式长期解锁项，覆盖槽位、商店、战斗全局规则、经济和首领规则钩子。
- 重写 `LongTermUnlockService.gd`，实现可购买查询、重复拦截、效果应用、中文日志和首领规则保险钩子。
- 接入 `RunState` 参数字段、`ShopService` 长期解锁抽取和槽位数量读取、`ShopCatalog` 名称/价格读取、`BattleController` 战斗参数应用、`DiceToolService` 首领规则禁用查询。
- 新增 `DebugLongTermUnlockSmokeTest.gd`，覆盖目录合法性、重复/无效拦截、槽位/商店参数、战斗参数、经济购买、首领钩子、无骰面/等级副作用和旧词扫描。
- 修复新测试中 `passed` 类型推断问题。
- `DebugLongTermUnlockSmokeTest`：PASS；Godot headless 退出时有资源仍在使用警告，进程返回 0。
- 用户指定关键回归：`DebugShopPackSmokeTest`、三批骰具测试、`DebugForgeRewardSmokeTest`、`DebugInstallRulesSmokeTest`、`DebugComboEvaluator`、`DebugBattleSmokeTest`、`DebugChineseDisplaySmokeTest` 全部 PASS；输出包含既有 deprecated warning。
- 主场景 headless 启动：PASS。
- `git diff --check`：PASS。
- 12 模块旧词扫描：PASS，无命中。
