# 12_长期解锁实现计划

## 目标
实现 12_长期解锁：长期解锁只修改本局全局规则参数、商店参数、槽位参数、经济参数、Boss 服务钩子等，不引入旧概念，不新增骰面槽位、骰子等级、骰面等级或条件标签等级，终倍率仍保持整数。

## 阶段
| 阶段 | 状态 | 内容 |
|---|---|---|
| 1. 指令与现状审查 | complete | 查找指令文件、读取现有 LongTermUnlockService / RunState / Shop 接入 |
| 2. 数据模型与目录 | complete | 新增长期解锁定义、目录、中文显示、旧词规避 |
| 3. 服务与参数应用 | complete | 实现购买/应用/重算、接入 RunState 参数与 ShopCatalog |
| 4. Debug 测试 | complete | 新增 DebugLongTermUnlockSmokeTest，覆盖约束与主要效果 |
| 5. 回归验证 | complete | 跑用户指定 Debug、主场景 headless、git diff --check、旧词扫描 |

## 决策
- `codex_12_long_term_unlocks_instruction_v1.md` 未在仓库和 `.codex` 下找到；按用户消息中的硬性约束和 11 的接入口实现。
- 不回滚 11，不清理 unrelated dirty / untracked 文件。
- Godot 临时路径：`C:\Users\Arche\AppData\Local\Temp\codex-godot-4.6.2\Godot_v4.6.2-stable_win64_console.exe`。

## 错误记录
| 时间 | 错误 | 处理 |
|---|---|---|
| 2026-05-19 | 未找到 `codex_12_long_term_unlocks_instruction_v1.md` | 记录缺失，按用户消息与现有架构实现 |
| 2026-05-19 | `session-catchup.py` 返回 exit 1 且无输出 | 记录异常，继续基于 `git status` 和现有文件审查 |
