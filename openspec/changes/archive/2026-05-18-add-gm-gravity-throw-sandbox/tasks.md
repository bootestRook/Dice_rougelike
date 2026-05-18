## 1. 主页 GM 入口

- [x] 1.1 在 `MainPrototypeView.gd` 增加 `GM测试` 按钮状态引用和点击处理
- [x] 1.2 调整主页按钮栏布局，确保“开始游戏”“GM测试”“退出”均为中文且不互相遮挡
- [x] 1.3 实现从主页切换到 GM 测试功能列表的视图流程
- [x] 1.4 保持“开始游戏”继续进入现有战斗流程，“退出”继续退出游戏

## 2. GM 测试功能列表

- [x] 2.1 新增 GM 测试列表视图，显示标题、`骰子重力投掷` 按钮和 `返回主页` 按钮
- [x] 2.2 实现 `返回主页` 行为，返回后主页按钮仍可正常操作
- [x] 2.3 为后续 GM 功能预留稳定的按钮列表创建方式，避免把功能逻辑写死在输入处理里

## 3. 骰子重力投掷 Sandbox

- [x] 3.1 新增 `GMGravityThrowSandbox.gd`，创建独立 `SubViewportContainer`、`SubViewport`、`Camera3D` 和灯光
- [x] 3.2 在 sandbox 中创建地面和边界 `StaticBody3D` 碰撞体，并确保边界网格不遮挡骰子
- [x] 3.3 将测试对象从方块升级为六面骰子，显示 6 个面和 21 个点数
- [x] 3.4 新增 `1面` 到 `6面` 六个投掷按钮，用于指定最终朝上的骰面
- [x] 3.5 实现重复投掷清理或复用上一轮骰子状态，避免无用刚体节点堆积
- [x] 3.6 增加可测试的状态查询方法，例如是否已投掷、刚体数量、点数数量、目标面、假面和关键动画状态
- [x] 3.7 确保 sandbox 不调用 `RollService`、`BattleController.reroll`，不修改 `RunState.dice`

## 4. 投掷动画表现

- [x] 4.1 落地阶段使用符合重力加速语义的速度曲线，并控制在约 0.3 秒
- [x] 4.2 骰子首次落地后必须触碰地面，再进入弹起阶段
- [x] 4.3 弹起与滚动阶段控制在 0.5 到 0.8 秒，并在过程中回到地面
- [x] 4.4 弹起过程中先随机经过一个非目标假面，再持续自然调整到指定面朝上
- [x] 4.5 整个动画总时长不超过 1.5 秒

## 5. GM Sandbox 界面接入

- [x] 5.1 从 GM 功能列表点击 `骰子重力投掷` 时显示 sandbox
- [x] 5.2 在 sandbox 页面提供中文目标面按钮和中文返回按钮
- [x] 5.3 返回 GM 功能列表时清理或暂停 sandbox 物理节点

## 6. 测试与验证

- [x] 6.1 更新 `DebugMainStartButtonSmokeTest.gd`，验证主页存在 `GM测试`，且开始游戏行为不变
- [x] 6.2 新增 `DebugGmGravityThrowSmokeTest.gd`，验证 GM 功能列表和 `骰子重力投掷` 入口
- [x] 6.3 在 `DebugGmGravityThrowSmokeTest.gd` 中验证 sandbox 的 viewport、相机、地面、边界和骰子刚体节点
- [x] 6.4 在 `DebugGmGravityThrowSmokeTest.gd` 中验证 6 个目标面按钮、21 个点数和重复投掷不堆积刚体
- [x] 6.5 在 `DebugGmGravityThrowSmokeTest.gd` 中验证落地、弹起、假面、目标面和总时长约束
- [x] 6.6 运行 `DebugMainStartButtonSmokeTest.gd`
- [x] 6.7 运行 `DebugGmGravityThrowSmokeTest.gd`
- [x] 6.8 运行主场景启动检查：`--headless --path . --quit-after 3`
