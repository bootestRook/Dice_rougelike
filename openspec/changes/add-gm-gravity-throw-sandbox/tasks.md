## 1. 主页 GM 入口

- [x] 1.1 在 `MainPrototypeView.gd` 增加 `GM测试` 按钮状态引用和点击处理
- [x] 1.2 调整主页按钮栏布局，确保“开始游戏”“GM测试”“退出”均为中文且不互相遮挡
- [x] 1.3 实现从主页切换到 GM 测试功能列表的视图流程
- [x] 1.4 保持“开始游戏”继续进入现有战斗流程，“退出”继续退出游戏

## 2. GM 测试功能列表

- [x] 2.1 新增 GM 测试列表视图，显示标题、`方块重力投掷` 按钮和 `返回主页` 按钮
- [x] 2.2 实现 `返回主页` 行为，返回后主页按钮仍可正常操作
- [x] 2.3 为后续 GM 功能预留稳定的按钮列表创建方式，避免把功能逻辑写死在输入处理里

## 3. 方块重力投掷 Sandbox

- [x] 3.1 新增 `GMGravityThrowSandbox.gd`，创建独立 `SubViewportContainer`、`SubViewport`、`Camera3D` 和灯光
- [x] 3.2 在 sandbox 中创建地面和边界 `StaticBody3D` 碰撞体
- [x] 3.3 实现投掷按钮：创建或重置 `RigidBody3D` 方块，让其从上方以初始速度和角速度落下
- [x] 3.4 实现重复投掷清理或复用上一轮方块状态，避免无用刚体节点堆积
- [x] 3.5 增加可测试的状态查询方法，例如是否已投掷、当前方块类名、刚体数量和关键节点是否存在
- [x] 3.6 确保 sandbox 不调用 `RollService`、`BattleController.reroll`，不修改 `RunState.dice`

## 4. GM Sandbox 界面接入

- [x] 4.1 从 GM 功能列表点击 `方块重力投掷` 时显示 sandbox
- [x] 4.2 在 sandbox 页面提供中文投掷按钮和中文返回按钮
- [x] 4.3 返回 GM 功能列表时清理或暂停 sandbox 物理节点

## 5. 测试与验证

- [x] 5.1 更新 `DebugMainStartButtonSmokeTest.gd`，验证主页存在 `GM测试`，且开始游戏行为不变
- [x] 5.2 新增 `DebugGmGravityThrowSmokeTest.gd`，验证 GM 功能列表和 `方块重力投掷` 入口
- [x] 5.3 在 `DebugGmGravityThrowSmokeTest.gd` 中验证 sandbox 的 viewport、相机、地面、边界和方块刚体节点
- [x] 5.4 在 `DebugGmGravityThrowSmokeTest.gd` 中验证点击投掷按钮后记录有效投掷状态，并且重复投掷不会堆积无用刚体
- [x] 5.5 运行 `DebugMainStartButtonSmokeTest.gd`
- [x] 5.6 运行 `DebugGmGravityThrowSmokeTest.gd`
- [x] 5.7 运行主场景启动检查：`--headless --path . --quit-after 3`
