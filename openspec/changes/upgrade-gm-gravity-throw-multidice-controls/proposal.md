## Why

当前 GM“骰子重力投掷”工具只能通过 6 个目标面按钮测试单颗骰子，无法快速观察多颗骰子在空中、落地和相互碰撞时的真实投掷手感。正式战斗已经有多骰物理投掷表现，GM 工具需要补齐可配置入口，方便验证目标面校准是否自然。

## What Changes

- 将 GM 投掷控制从“6 个目标面按钮”改为“骰子数量选择 + 6 个目标点数输入框 + 投掷按钮”。
- 目标点数输入框默认均为 `1`，投掷时按当前骰子数量读取前 N 个目标点数。
- GM sandbox 支持一次投掷多颗骰子，并表现空中碰撞、落地碰撞、边界碰撞和骰子间碰撞。
- 投掷节奏恢复旧版单骰手感：落地过程约 `0.3s` 且全程使用类重力曲线，触地后弹起/滚动约 `0.5s`，目标面预旋约 `0.2s`。
- 定向目标面的校准只在骰子首次落地并弹起过程中接管，不提前覆盖空中下落表现。
- 当骰子当前朝向距离目标面较远时，校准旋转应伴随轻微滚动位移，避免看起来原地转面。
- GM sandbox 新增摄像机视角按钮，可在上方视角和侧面视角之间切换。
- 保持 GM sandbox 只作为表现调试工具，不修改战斗、骰子、奖励或结算规则状态。

## Capabilities

### New Capabilities

无。

### Modified Capabilities

- `gm-gravity-throw-sandbox`: 扩展 GM 骰子重力投掷 sandbox 的控制方式、多骰物理投掷、碰撞表现和落地后目标面校准要求。

## Impact

- 主要影响 `res://scripts/ui/gm/GMGravityThrowSandbox.gd`。
- 需要更新 `res://tests_or_debug/DebugGmGravityThrowSmokeTest.gd` 覆盖数量选择、6 个输入框、多刚体投掷、物理碰撞标记和校准接管时机。
- 可能参考 `res://scripts/ui/battle/components/Dice3DThrowLayer.gd` 的多骰物理投掷与最终校准思路，但不得把战斗规则逻辑引入 GM 工具。
