## Why

当前骰子材质已经有多套正式资源与 GM 原型材质，但查看它们需要进入特定调试场景或手动替换骰子，检查效率低。新增主菜单 GM 材质检查入口，可以让美术与开发在不进入战斗流程的情况下集中查看所有骰子材质，并快速放大检查光照、透明、金属、发光等表现。

## What Changes

- 仅在主菜单右上角新增浮动 `GM` 按钮，点击后展开 GM 功能列表。
- 功能列表新增 `骰子材质检查` 按钮，进入新的 GM 材质检查界面。
- 新界面以可滑动“材质橱柜”形式展示当前所有骰子材质，包括资源材质和程序回退材质。
- 点击橱柜中的骰子后，打开游戏内可拖拽检查弹窗。
- 检查弹窗支持单颗骰子的旋转、缩放、自动旋转、视角重置、点数显示切换和光照调节。
- 所有新增玩家可见/调试可见文本使用中文。
- 不改变战斗、奖励、铸骰、GM 物理投骰和骰子结算规则。

## Capabilities

### New Capabilities
- `gm-dice-material-inspector`: 定义主菜单 GM 材质检查工具、材质橱柜展示、单骰检查弹窗和交互控制要求。

### Modified Capabilities
- 无。

## Impact

- 影响主菜单 UI：`scripts/ui/MainPrototypeView.gd` 和 `scenes/main/Main.tscn` 的运行时界面构建。
- 新增 GM 调试 UI 脚本与场景：预计位于 `scripts/ui/debug/`、`scenes/debug/`。
- 复用现有 GM 骰子材质定义、骰子模型和材质加载路径：`scripts/ui/debug/gm_dice_port/GmDiceDefinition.gd`、`GmDiceCtrl.gd`、`assets/materials/dice/`、`assets/models/dice/rounded_d6_mesh.tres`。
- 需要新增或更新 Debug 测试，覆盖主菜单 GM 入口、材质列表、检查弹窗和基础交互节点。
