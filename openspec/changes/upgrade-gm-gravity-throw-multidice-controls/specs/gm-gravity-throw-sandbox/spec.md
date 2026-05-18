## MODIFIED Requirements

### Requirement: Dice gravity throw sandbox

骰子重力投掷 sandbox SHALL 提供一个独立 3D 测试区域，玩家可选择一次投掷的骰子数量，并通过 6 个中文点数输入框指定每颗骰子最终朝上的目标点数。

#### Scenario: Open dice gravity throw sandbox
- **WHEN** 玩家在 GM 测试功能列表点击“骰子重力投掷”
- **THEN** 界面 MUST 显示骰子重力投掷 sandbox
- **AND** sandbox MUST 包含中文“投掷骰子数”选择控件，合法范围为 1 到 6
- **AND** sandbox MUST 包含 6 个目标点数输入框
- **AND** 每个目标点数输入框默认值 MUST 为 `1`
- **AND** sandbox MUST 包含中文“投掷骰子”按钮
- **AND** sandbox MUST 包含中文摄像机视角切换按钮
- **AND** sandbox MUST 包含中文返回按钮

#### Scenario: Throw selected dice count with input target pips
- **WHEN** 玩家选择投掷骰子数为 N 并点击“投掷骰子”
- **THEN** sandbox MUST 读取前 N 个目标点数输入框
- **AND** sandbox MUST 创建或重置 N 个 `RigidBody3D` 骰子
- **AND** 每颗骰子 MUST 从测试区域上方开始下落
- **AND** 每颗骰子 MUST 显示六个骰面和共 21 个可见点数
- **AND** 每颗骰子最终朝上的骰面 MUST 对应其目标点数输入框指定的点数

#### Scenario: Invalid target pip input is constrained
- **WHEN** 玩家在目标点数输入框中输入小于 1、大于 6 或非整数内容并点击“投掷骰子”
- **THEN** sandbox MUST 将该输入用于投掷前校正为 1 到 6 之间的整数点数
- **AND** sandbox MUST 不得因为非法输入中断或崩溃

#### Scenario: Repeated throw resets all dice
- **WHEN** 玩家在一次投掷后再次点击“投掷骰子”
- **THEN** sandbox MUST 将所有参与投掷的骰子重置到新的投掷起点
- **AND** sandbox MUST 清理或复用上一轮骰子状态，不得持续堆积无用刚体节点
- **AND** 当前刚体骰子数量 MUST 等于本次选择的投掷骰子数

#### Scenario: Sandbox bounds do not occlude dice
- **WHEN** sandbox 创建地面和边界碰撞体
- **THEN** 地面 SHOULD 可见以提供落地参照
- **AND** 边界碰撞体 MUST 不显示会遮挡骰子的墙面网格

### Requirement: Dice throw animation timing

骰子投掷动画 SHALL 在可控时长内完成，且表现为物理感下落、空中碰撞反馈、触地弹起、滚动调整和指定点数朝上的连续过程。

#### Scenario: Airborne throw uses physics and collision
- **WHEN** 玩家触发一次多骰投掷
- **THEN** 每颗骰子 MUST 在空中阶段保持 `RigidBody3D` 骰子节点和类重力下落运动
- **AND** 骰子 MUST 可与其他活动骰子产生空中碰撞反馈
- **AND** 定向目标面的校准 MUST NOT 在首次落地前接管骰子朝向

#### Scenario: Landing uses physical ground contact
- **WHEN** 玩家触发一次骰子投掷
- **THEN** 骰子 MUST 使用类重力加速曲线下落
- **AND** 骰子 MUST 与地面和边界碰撞体产生碰撞反馈
- **AND** sandbox MUST 记录骰子已发生落地接触后才允许进入目标面校准阶段
- **AND** 落地过程 SHOULD 保持在约 `0.3s`

#### Scenario: Target face control takes over during bounce
- **WHEN** 骰子已经首次落地并处于弹起或滚动阶段
- **THEN** sandbox MUST 开始将骰子朝向校准到对应输入点数
- **AND** 校准完成时目标点数 MUST 朝上
- **AND** 触地后的弹起/滚动过程 SHOULD 保持在约 `0.5s`
- **AND** 目标面预旋过程 SHOULD 保持在约 `0.2s`
- **AND** 总投掷表现 MUST 在最大演出时长内完成，且 SHOULD 保持旧版单骰的紧凑总时长

#### Scenario: Far target rotation rolls slightly while calibrating
- **WHEN** 骰子当前朝向与目标朝上姿态距离超过校准阈值
- **THEN** sandbox MUST 在旋转到目标面的过程中加入轻微水平滚动位移
- **AND** 骰子 MUST NOT 仅在原地无位移转面

### Requirement: GM gravity throw debug coverage

GM 测试入口和骰子重力投掷 sandbox SHALL 具备 Debug 测试覆盖，验证入口、功能列表、sandbox 结构、数量选择、点数输入、多骰刚体和投掷动画关键状态。

#### Scenario: Debug test covers main menu GM entry
- **WHEN** 相关 Debug 测试加载主页
- **THEN** 测试 MUST 验证“GM测试”按钮存在
- **AND** 测试 MUST 验证点击“GM测试”后进入 GM 测试功能列表

#### Scenario: Debug test covers multi-dice sandbox controls
- **WHEN** 相关 Debug 测试打开骰子重力投掷 sandbox
- **THEN** 测试 MUST 验证 sandbox 创建 3D viewport、相机、地面、边界和骰子刚体
- **AND** 测试 MUST 验证存在投掷骰子数选择控件
- **AND** 测试 MUST 验证存在 6 个默认值为 `1` 的目标点数输入框
- **AND** 测试 MUST 验证存在“投掷骰子”按钮
- **AND** 测试 MUST 验证存在摄像机视角切换按钮

#### Scenario: Debug test covers multi-dice physical throw
- **WHEN** 测试设置投掷骰子数和目标点数后点击“投掷骰子”
- **THEN** 测试 MUST 验证创建的刚体骰子数量等于选择数量
- **AND** 测试 MUST 验证每颗骰子都有 21 个可见点数
- **AND** 测试 MUST 验证投掷记录包含空中下落、落地接触、弹起后校准和最终目标点数
- **AND** 测试 MUST 验证目标姿态距离较远时发生过校准滚动位移
- **AND** 测试 MUST 验证落地约 `0.3s`、弹起约 `0.5s`、目标面预旋约 `0.2s`

### Requirement: Camera view control

骰子重力投掷 sandbox SHALL 提供玩家可见的中文摄像机视角按钮，用于在上方视角和侧面视角之间切换观察投掷过程。

#### Scenario: Camera defaults to side view
- **WHEN** 玩家打开骰子重力投掷 sandbox
- **THEN** sandbox MUST 默认使用侧面视角
- **AND** 摄像机视角按钮 MUST 使用中文显示当前侧面视角状态

#### Scenario: Toggle camera to top view
- **WHEN** 玩家点击摄像机视角按钮且当前为侧面视角
- **THEN** sandbox MUST 切换到上方视角
- **AND** 物理投掷状态、目标点数输入和已创建骰子 MUST 不被该操作修改

#### Scenario: Toggle camera back to side view
- **WHEN** 玩家点击摄像机视角按钮且当前为上方视角
- **THEN** sandbox MUST 切换回侧面视角
- **AND** 物理投掷状态、目标点数输入和已创建骰子 MUST 不被该操作修改
