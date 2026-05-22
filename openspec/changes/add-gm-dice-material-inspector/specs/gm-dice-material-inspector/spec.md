## ADDED Requirements

### Requirement: Main menu exposes GM material inspector entry
系统 SHALL 仅在主菜单右上角显示浮动 `GM` 按钮。点击该按钮后，系统 SHALL 展开 GM 功能列表，并在列表中提供中文按钮 `骰子材质检查`。

#### Scenario: GM entry appears on main menu
- **WHEN** 主菜单界面完成构建
- **THEN** 右上角存在可点击的 `GM` 浮动按钮
- **AND** 点击后出现 GM 功能列表
- **AND** 功能列表包含 `骰子材质检查`

#### Scenario: GM entry does not persist into run views
- **WHEN** 玩家从主菜单进入地图、战斗、奖励、铸骰、商店或 GM 工具界面
- **THEN** 主菜单浮动 `GM` 按钮不再显示

### Requirement: Material cabinet lists all current dice materials
材质检查界面 SHALL 以可滑动橱柜形式展示当前 GM 可识别的全部骰子材质。展示范围 MUST 包含 `GmDiceDefinition.get_material_options()` 返回的所有材质，包括资源材质与程序回退材质。

#### Scenario: Cabinet includes resource and procedural materials
- **WHEN** 玩家打开 `骰子材质检查`
- **THEN** 橱柜中存在每个 GM 材质选项对应的骰子预览
- **AND** 展示范围包含 `repro_blue`、`repro_purple`、`repro_cyan`、`repro_gold`、`repro_silverwhite`、`standard`、`bronze`、`gold`、`crystal`、`iron`、`glass`

#### Scenario: Cabinet uses Chinese visible labels
- **WHEN** 材质橱柜显示材质名称、提示或按钮
- **THEN** 玩家可见文本使用中文名称
- **AND** 玩家可见文本不得直接显示内部材质 ID

#### Scenario: Cabinet supports scrolling
- **WHEN** 材质数量超过当前屏幕可同时展示的数量
- **THEN** 玩家可以通过滚动浏览全部材质卡片

### Requirement: Material preview cards open a single-dice inspector
每个材质卡片 SHALL 提供一个可点击的骰子预览。点击后系统 SHALL 打开游戏内可拖拽的单骰检查弹窗，并在弹窗中展示所点击材质的独立骰子预览。

#### Scenario: Clicking material opens inspector window
- **WHEN** 玩家点击橱柜中的某个材质骰子
- **THEN** 系统打开一个游戏内检查弹窗
- **AND** 弹窗标题显示该材质的中文名称
- **AND** 弹窗中的骰子使用被点击的材质

#### Scenario: Inspector window is draggable and closable
- **WHEN** 检查弹窗已打开
- **THEN** 玩家可以拖拽弹窗标题栏移动弹窗
- **AND** 玩家可以通过关闭按钮关闭弹窗
- **AND** 关闭弹窗不会离开材质检查界面

### Requirement: Single-dice inspector supports view controls
单骰检查弹窗 SHALL 支持旋转、缩放、自动旋转、视角重置和点数显示切换。旋转和缩放 MUST 只影响当前弹窗中的单骰预览。

#### Scenario: Player rotates and zooms inspected die
- **WHEN** 玩家在检查弹窗的骰子预览区域拖拽或滚动鼠标
- **THEN** 弹窗中的骰子旋转或缩放
- **AND** 橱柜中的其他材质预览不受影响

#### Scenario: Player resets inspector view
- **WHEN** 玩家点击 `重置视角`
- **THEN** 弹窗中的骰子恢复默认旋转和默认缩放

#### Scenario: Player toggles pip labels
- **WHEN** 玩家切换 `显示点数`
- **THEN** 弹窗中的骰子点数显示状态随之切换

### Requirement: Single-dice inspector supports isolated lighting controls
单骰检查弹窗 SHALL 提供光照调节控件。光照调节 MUST 只影响当前弹窗预览，不修改材质资源，不影响主菜单、材质橱柜或现有 GM 物理投骰界面。

#### Scenario: Player adjusts lighting
- **WHEN** 玩家调整主光强度、主光方向、环境光强度或补光强度
- **THEN** 当前弹窗中的骰子预览光照随控件变化
- **AND** 材质资源文件不被写入

#### Scenario: Player applies light preset
- **WHEN** 玩家选择明亮、中性或暗场光照预设
- **THEN** 当前弹窗预览使用对应预设参数
- **AND** 玩家仍可继续手动调节光照

### Requirement: GM material inspector is isolated from gameplay systems
材质检查工具 SHALL 作为 GM / debug UI 独立存在。它 MUST NOT 修改 `RunState.dice`、战斗分数、奖励池、铸骰安装结果或正式骰面数据模型。

#### Scenario: Opening inspector does not mutate run state
- **WHEN** 玩家从主菜单打开并关闭 `骰子材质检查`
- **THEN** 当前局内骰组、战斗状态和奖励状态不发生变化

#### Scenario: Material inspector does not expose deprecated gameplay slots
- **WHEN** 材质检查界面显示信息
- **THEN** 它不得把材质描述为正式骰面槽位
- **AND** 它不得显示 `material`、`rune`、`level`、`lock`、`unlock` 等内部或废弃玩家操作文本

### Requirement: GM material inspector exposes stable debug automation hooks
系统 SHALL 为材质检查工具提供稳定节点名称或自动化快照，以便 Debug 脚本验证主菜单入口、材质列表、弹窗和交互控件。

#### Scenario: Debug test can inspect material list
- **WHEN** Debug 脚本打开材质检查界面
- **THEN** 脚本可以读取材质卡片数量和每个材质的 ID、中文名称、材质资源路径或程序材质标记

#### Scenario: Debug test can inspect popup controls
- **WHEN** Debug 脚本打开单骰检查弹窗
- **THEN** 脚本可以找到关闭、重置视角、自动旋转、显示点数和光照调节控件
