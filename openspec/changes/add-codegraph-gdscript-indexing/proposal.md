## Why

当前项目主体逻辑是 Godot GDScript，但 CodeGraph 现有语言支持不包含 `.gd`，因此即使安装 CodeGraph，也只能索引少量 C++、Python、YAML 边缘文件，无法帮助理解战斗、规则、运行时和 UI 主流程。

为 CodeGraph 增加 GDScript 语义索引能力后，后续 Codex 可以用结构化查询定位类、方法、调用关系和影响范围，减少在大型 GDScript 代码区反复 `rg`/读文件的成本。

## What Changes

- 新增 `codegraph-gdscript-indexing` 能力，约束 CodeGraph 的 GDScript 支持、项目初始化方式和验证标准。
- 在 CodeGraph 外部适配中接入 `tree-sitter-gdscript`，让 `.gd` 文件能被识别并抽取脚本类、函数、变量、常量、信号、枚举和调用关系。
- 明确本项目的验证目标：至少能索引 `scripts/`、`tests_or_debug/`、`tools/` 中的 GDScript 文件，并能查询关键入口如 `BattleController`、`RewardGenerator`、`DisplayNames`。
- 明确本项目不引入 CodeGraph 作为 Godot 运行时依赖；CodeGraph 仅作为本地开发工具链和 Codex MCP 能力。
- 初始化 `.codegraph/` 前必须确认使用的是支持 GDScript 的 CodeGraph 构建，并且索引结果覆盖项目主体 GDScript 文件。

## Capabilities

### New Capabilities

- `codegraph-gdscript-indexing`: 约束本项目使用 CodeGraph 索引 GDScript 代码的语言支持、集成边界、初始化流程和验证要求。

### Modified Capabilities

- 无。

## Impact

- 影响开发工具链：CodeGraph CLI/MCP 配置、GDScript tree-sitter grammar、CodeGraph language extractor、索引初始化流程。
- 影响项目本地开发体验：后续可生成 `.codegraph/` 本地索引目录，并让 Codex 使用 CodeGraph 查询项目结构。
- 可能新增项目文档或工具说明，例如 `docs/` 下的 CodeGraph/GDScript 使用说明；不修改 Godot 主流程、战斗规则、UI 文案或导出配置。
- 外部 CodeGraph 适配应在独立 CodeGraph fork 或临时工作区完成，未经明确决定不把 CodeGraph 源码批量引入本 Godot 仓库。
