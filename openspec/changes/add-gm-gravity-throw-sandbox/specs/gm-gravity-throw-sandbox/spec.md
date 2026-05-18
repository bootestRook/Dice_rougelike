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

#### Scenario: Function list shows gravity throw tool

- **WHEN** 玩家进入 GM 测试功能列表
- **THEN** 界面 MUST 显示中文功能按钮“方块重力投掷”
- **AND** 界面 MUST 显示中文按钮“返回主页”

#### Scenario: Return to main menu

- **WHEN** 玩家在 GM 测试功能列表点击“返回主页”
- **THEN** 界面 MUST 返回主页
- **AND** 主页 MUST 可继续点击“开始游戏”进入战斗

### Requirement: Cube gravity throw sandbox

方块重力投掷 sandbox SHALL 提供一个独立 3D 物理测试区域，点击投掷后让方块从上方落下，并与地面和边界产生物理碰撞反馈。

#### Scenario: Open cube gravity throw sandbox

- **WHEN** 玩家在 GM 测试功能列表点击“方块重力投掷”
- **THEN** 界面 MUST 显示方块重力投掷 sandbox
- **AND** sandbox MUST 包含中文投掷按钮
- **AND** sandbox MUST 包含中文返回按钮

#### Scenario: Throw cube with gravity

- **WHEN** 玩家点击 sandbox 的投掷按钮
- **THEN** sandbox MUST 创建或重置一个 `RigidBody3D` 方块
- **AND** 方块 MUST 从测试区域上方开始下落
- **AND** 方块 MUST 受到重力影响
- **AND** 方块 MUST 与测试区域地面和边界碰撞体交互

#### Scenario: Repeated throw resets cube

- **WHEN** 玩家在一次投掷后再次点击投掷按钮
- **THEN** sandbox MUST 将方块重置到新的投掷起点
- **AND** sandbox MUST 清理或复用上一轮方块状态，不得持续堆积无用刚体节点

### Requirement: GM sandbox is presentation-only

GM 方块重力投掷 sandbox SHALL 只作为表现调试工具，不得修改战斗、骰子、奖励或结算规则状态。

#### Scenario: Sandbox does not use roll rules

- **WHEN** 玩家在 sandbox 中投掷方块
- **THEN** sandbox MUST NOT 调用 `RollService`
- **AND** sandbox MUST NOT 调用 `BattleController.reroll`
- **AND** sandbox MUST NOT 修改 `RunState.dice`

#### Scenario: Sandbox does not produce battle result

- **WHEN** 方块投掷完成或停止
- **THEN** sandbox MUST NOT 产生战斗点数、骰型、基础战力、倍率、终倍率或奖励结果

### Requirement: GM gravity throw debug coverage

GM 测试入口和方块重力投掷 sandbox SHALL 具备 Debug 测试覆盖，验证入口、功能列表、sandbox 结构和投掷按钮基本行为。

#### Scenario: Debug test covers main menu GM entry

- **WHEN** 相关 Debug 测试加载主页
- **THEN** 测试 MUST 验证“GM测试”按钮存在
- **AND** 测试 MUST 验证点击“GM测试”后进入 GM 测试功能列表

#### Scenario: Debug test covers cube sandbox

- **WHEN** 相关 Debug 测试打开方块重力投掷 sandbox
- **THEN** 测试 MUST 验证 sandbox 创建 3D viewport、相机、地面、边界和方块刚体
- **AND** 测试 MUST 验证点击投掷按钮后记录到有效投掷状态
