## Context

CodeGraph 通过 tree-sitter 解析源文件，生成本地 SQLite 知识图，并通过 CLI/MCP 暴露符号搜索、调用关系、影响范围和上下文构建能力。当前上游 CodeGraph 支持多种语言，但不支持 GDScript，也没有 `.gd` 扩展名映射。

本项目的核心代码集中在 `scripts/`、`tests_or_debug/`、`tools/scene_builders/` 的 GDScript 文件中。未适配 GDScript 时，CodeGraph 只能覆盖少量 `native/*.cpp/.h`、`tools/*.py` 和 YAML 文件，对本项目主体开发帮助有限。

`tree-sitter-gdscript@6.1.0` 已提供 GDScript grammar，AST 中包含 CodeGraph 需要的核心节点：`class_definition`、`class_name_statement`、`function_definition`、`constructor_definition`、`variable_statement`、`const_statement`、`signal_statement`、`enum_definition`、`call`。当前本机缺少 `emcc`、`docker` 或 `podman`，不能直接构建 wasm，因此 GDScript wasm 获取方式是关键前置风险。

## Goals / Non-Goals

**Goals:**

- 让 CodeGraph 能识别 `.gd` 文件并把语言标记为 `gdscript`。
- 抽取 GDScript 脚本类、内部类、函数/方法、构造函数、变量、常量、信号、枚举和调用关系。
- 在本项目上验证索引覆盖主体 GDScript 文件，并能查询关键入口与影响范围。
- 保持 CodeGraph 为开发工具链能力，不进入 Godot 运行时、导出配置或玩家可见流程。
- 明确 `.codegraph/` 是本地索引产物，不能作为项目内容提交。

**Non-Goals:**

- 不修改战斗、骰子、奖励、结算、UI 主流程或中文文案。
- 不把 CodeGraph 源码批量 vendor 到本 Godot 仓库。
- 不要求第一版解析 `.tscn`、`.tres`、`.gdshader` 或 Godot 场景节点图。
- 不要求第一版做到 Godot LSP 级别的类型推断或跨场景 NodePath 分析。
- 不把 CodeGraph 作为 CI 必跑检查，除非后续明确引入开发工具链 CI。

## Decisions

### Decision: 在 CodeGraph 外部 fork/工作区完成语言适配

原因：CodeGraph 的语言支持属于外部工具实现，涉及 TypeScript、tree-sitter wasm、extractor 和上游测试。本 Godot 仓库只需要记录能力合同、使用说明、`.gitignore` 边界和本地验证结果。

备选方案：把 CodeGraph 源码作为第三方目录引入本仓库。放弃原因是体积大、维护边界差，且与 Godot 运行时无关。

### Decision: 第一版只索引 `.gd`，不索引 `.tscn/.tres`

原因：本轮目标是让 Codex 理解脚本逻辑。`.tscn/.tres` 是 Godot 资源格式，适合作为后续独立能力处理；提前混入会扩大 grammar 与关系解析范围。

备选方案：同时解析场景资源并建立脚本绑定关系。放弃原因是复杂度高，且 GDScript 符号图已经能覆盖当前最重要的开发痛点。

### Decision: 用“隐式脚本类”表示每个 GDScript 文件

原因：Godot 中每个 `.gd` 文件本身就是可挂载脚本。即使没有 `class_name`，顶层 `func`、`var`、`const` 也应归属到一个稳定 owner，便于调用关系和影响分析。owner 名称优先使用 `class_name`，否则使用文件名 stem。

备选方案：把顶层 `func` 全部抽成普通 function。放弃原因是会丢失 Godot 脚本的主要组织结构，`BattleController._ready` 这类入口也不易查询。

### Decision: 先做结构抽取，再逐步增强 Godot 专用引用

第一版必须支持基础调用：`foo()`、`obj.foo()`、`ClassName.static_call()`、`super.foo()`。Godot 专用引用如 `preload("res://...")`、`load("res://...")`、`extends "res://..."` 可以作为 import/reference 处理，但不要求第一版解析场景 NodePath。

备选方案：第一版就实现完整 Godot 资源图。放弃原因是路径、场景、autoload、资源 UID、动态加载会带来较多边界情况，适合在 GDScript 基础索引稳定后再做。

### Decision: 本项目初始化索引前必须通过覆盖验证

不能只以 `codegraph init -i` 成功作为完成标准。必须确认索引中存在 `gdscript` 文件统计，并能查询本项目关键类/方法，例如 `BattleController`、`RewardGenerator`、`DisplayNames`。

## Risks / Trade-offs

- GDScript wasm 获取失败 -> 先安装 Docker/Podman/Emscripten 或从可信 grammar 包构建 wasm；无法获得健康 wasm 时停止适配，不提交半成品。
- tree-sitter grammar 对 Godot 4 新语法覆盖不足 -> 用本项目真实 `.gd` 文件做抽样解析，失败样例回补 extractor 或记录为限制。
- 调用关系不完整 -> 第一版优先保证符号发现和常见调用；把动态调用、信号连接、NodePath 解析列为后续增强。
- `.codegraph/` 被误提交 -> 在初始化索引前把 `.codegraph/` 加入 `.gitignore`，并在完成报告中确认未提交索引数据库。
- 外部工具变更与本项目变更混淆 -> CodeGraph fork 的代码修改单独管理；本项目只保留 OpenSpec、说明文档和必要的本地忽略配置。

## Migration Plan

1. 在外部 CodeGraph 工作区添加 `gdscript` 语言支持并通过 extractor 单元测试。
2. 用支持 GDScript 的 CodeGraph 构建索引本项目，确认 `.gd` 文件覆盖与关键符号查询。
3. 在本项目记录安装/初始化/验证步骤，并确保 `.codegraph/` 本地索引不被提交。
4. 配置 Codex MCP 使用支持 GDScript 的 CodeGraph 构建。
5. 若适配失败，移除本地 `.codegraph/`，恢复 Codex MCP 到原 CodeGraph 或不启用 CodeGraph。

## Open Questions

- GDScript wasm 最终使用本地构建产物、npm 包产物，还是提交到 CodeGraph fork 的 `src/extraction/wasm/`？
- 第一版是否把 `preload/load` 资源路径作为 `import` 节点，还是先只做 `references` 边？
- 本项目是否需要保留一份 `docs/dev/codegraph_gdscript.md` 作为长期使用手册？
