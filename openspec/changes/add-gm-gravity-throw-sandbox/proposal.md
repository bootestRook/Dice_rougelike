## Why

当前 3D 投骰表现已经接入战斗流程，但调试与观察必须进入真实战斗，反馈链路偏长。新增主页 GM 测试入口和独立方块重力投掷试验台，可以在不触碰规则层的前提下快速验证重力、碰撞、落点和镜头手感，为后续正式投掷骰子动画打底。

## What Changes

- 在主页新增玩家可见中文按钮“GM测试”，进入独立 GM 测试功能列表。
- 新增 GM 测试功能列表界面，首个功能为“方块重力投掷”。
- 新增方块重力投掷 sandbox：点击按钮后让一个 3D 方块从上方落入测试区域，受重力影响并与地面/边界碰撞。
- sandbox 仅用于表现调试，不调用 `RollService`，不修改 `RunState.dice`，不产生战斗点数、骰型或结算结果。
- 新增 Debug 测试覆盖主页入口、GM 功能列表、sandbox 节点结构和投掷按钮基本行为。

## Capabilities

### New Capabilities

- `gm-gravity-throw-sandbox`: 覆盖主页 GM 测试入口、GM 功能列表，以及方块重力投掷 sandbox 的调试行为契约。

### Modified Capabilities

- 无。

## Impact

- 主要影响主页 UI：`res://scripts/ui/MainPrototypeView.gd`。
- 新增 GM UI 脚本，建议放在 `res://scripts/ui/gm/`。
- 可能新增 GM 场景或由脚本动态创建 UI；若界面结构复杂，应优先使用脚本稳定生成。
- 新增或更新 Debug 测试：`res://tests_or_debug/DebugMainStartButtonSmokeTest.gd`、`res://tests_or_debug/DebugGmGravityThrowSmokeTest.gd`。
- 不影响战斗规则层、奖励层、铸骰件安装、现有 3D 骰子结算表现或导出配置。
