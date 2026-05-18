## ADDED Requirements

### Requirement: Main menu GM test entry

主页 SHALL 提供玩家可见的中文“GM测试”入口，用于进入独立 GM 测试功能列表，且不得破坏“开始游戏”和“退出”的既有行为。

#### Scenario: GM button is visible on main menu

- **WHEN** 玩家进入主页
- **THEN** 主页 MUST 显示中文按钮“GM测试”
- **AND** 主页 MUST 继续显示中文按钮“开始游戏”和“退出”

#### Scenario: GM button opens test list

- **WHEN** 玩家点击主页“GM测试”按钮
- **THEN** 界面 MUST 切换到 GM 测试功能列表
- **AND** 不得启动战斗流程或创建新的 `RunState`

#### Scenario: Start button remains unchanged

- **WHEN** 玩家点击主页“开始游戏”按钮
- **THEN** 游戏 MUST 继续进入现有战斗流程

### Requirement: GM test function list

GM 测试界面 SHALL 以中文功能列表展示可用调试功能，并提供返回主页的中文操作。

#### Scenario: Function list shows dice gravity throw tool

- **WHEN** 玩家进入 GM 测试功能列表
- **THEN** 界面 MUST 显示中文功能按钮“骰子重力投掷”
- **AND** 界面 MUST 显示中文按钮“返回主页”

#### Scenario: Return to main menu

- **WHEN** 玩家在 GM 测试功能列表点击“返回主页”
- **THEN** 界面 MUST 返回主页
- **AND** 主页 MUST 可继续点击“开始游戏”进入战斗

### Requirement: Dice gravity throw sandbox

骰子重力投掷 sandbox SHALL 提供一个独立 3D 测试区域，玩家可通过 6 个中文面数按钮指定最终朝上的骰面。

#### Scenario: Open dice gravity throw sandbox

- **WHEN** 玩家在 GM 测试功能列表点击“骰子重力投掷”
- **THEN** 界面 MUST 显示骰子重力投掷 sandbox
- **AND** sandbox MUST 包含 “1面” 到 “6面” 的中文目标面按钮
- **AND** sandbox MUST 包含中文返回按钮

#### Scenario: Throw dice with selected target face

- **WHEN** 玩家点击 sandbox 的任意目标面按钮
- **THEN** sandbox MUST 创建或重置一个 `RigidBody3D` 骰子
- **AND** 骰子 MUST 从测试区域上方开始下落
- **AND** 骰子 MUST 显示六个骰面和共 21 个可见点数
- **AND** 最终朝上的骰面 MUST 对应玩家点击的目标面

#### Scenario: Repeated throw resets dice

- **WHEN** 玩家在一次投掷后再次点击任意目标面按钮
- **THEN** sandbox MUST 将骰子重置到新的投掷起点
- **AND** sandbox MUST 清理或复用上一轮骰子状态，不得持续堆积无用刚体节点

#### Scenario: Sandbox bounds do not occlude dice

- **WHEN** sandbox 创建地面和边界碰撞体
- **THEN** 地面 SHOULD 可见以提供落地参照
- **AND** 边界碰撞体 MUST 不显示会遮挡骰子的墙面网格

### Requirement: Dice throw animation timing

骰子投掷动画 SHALL 在不超过 1.5 秒内完成，且表现为重力加速下落、触地弹起、滚动调整和指定面朝上的连续过程。

#### Scenario: Landing uses gravity acceleration

- **WHEN** 玩家触发一次骰子投掷
- **THEN** 落地阶段 MUST 使用符合重力加速语义的速度曲线
- **AND** 落地阶段 SHOULD 控制在 0.3 秒左右
- **AND** 骰子 MUST 在落地阶段结束时触碰地面

#### Scenario: Bounce starts from ground contact

- **WHEN** 骰子完成首次落地
- **THEN** 弹起阶段 MUST 从触地状态开始
- **AND** 骰子 MUST 先弹离地面再回到地面
- **AND** 弹起与滚动阶段 MUST 控制在 0.5 到 0.8 秒内

#### Scenario: Dice naturally adjusts to target face

- **WHEN** 骰子处于弹起和滚动阶段
- **THEN** 骰子 MUST 先随机经过一个非目标的假面姿态
- **AND** 骰子 MUST 在弹起和滚动过程中持续向目标面自然调整
- **AND** 动画结束时目标面 MUST 朝上

### Requirement: GM sandbox is presentation-only

GM 骰子重力投掷 sandbox SHALL 只作为表现调试工具，不得修改战斗、骰子、奖励或结算规则状态。

#### Scenario: Sandbox does not use roll rules

- **WHEN** 玩家在 sandbox 中投掷骰子
- **THEN** sandbox MUST NOT 调用 `RollService`
- **AND** sandbox MUST NOT 调用 `BattleController.reroll`
- **AND** sandbox MUST NOT 修改 `RunState.dice`

#### Scenario: Sandbox does not produce battle result

- **WHEN** 骰子投掷完成或停止
- **THEN** sandbox MUST NOT 产生战斗点数、骰型、基础战力、倍率、终倍率或奖励结果

### Requirement: GM gravity throw debug coverage

GM 测试入口和骰子重力投掷 sandbox SHALL 具备 Debug 测试覆盖，验证入口、功能列表、sandbox 结构、六面按钮和投掷动画关键状态。

#### Scenario: Debug test covers main menu GM entry

- **WHEN** 相关 Debug 测试加载主页
- **THEN** 测试 MUST 验证“GM测试”按钮存在
- **AND** 测试 MUST 验证点击“GM测试”后进入 GM 测试功能列表

#### Scenario: Debug test covers dice sandbox

- **WHEN** 相关 Debug 测试打开骰子重力投掷 sandbox
- **THEN** 测试 MUST 验证 sandbox 创建 3D viewport、相机、地面、边界和骰子刚体
- **AND** 测试 MUST 验证存在 6 个目标面按钮
- **AND** 测试 MUST 验证点击目标面按钮后记录到有效投掷状态
- **AND** 测试 MUST 验证落地、弹起、假面、调面和总时长约束
