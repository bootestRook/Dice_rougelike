# CodeGraph GDScript 索引

本项目的 CodeGraph 支持是本地开发工具链能力，不是 Godot 运行时依赖。不要把 CodeGraph 源码、构建工具链或 `.codegraph/` 索引数据库提交到本仓库。

## 外部工作区

当前 GDScript 适配应在仓库外完成。建议用环境变量指向本机外部工作区：

```powershell
$env:CODEGRAPH_GDSCRIPT_DIR = "<path-to-codegraph-gdscript-worktree>"
$env:EMSDK = "<path-to-emsdk>"
```

基线信息：

```text
upstream: https://github.com/colbymchenry/codegraph
commit: f366222dbd6b7e43047072a9417289b1b02ae457
grammar: tree-sitter-gdscript@6.1.0
wasm: src/extraction/wasm/tree-sitter-gdscript.wasm
```

## 构建

在外部 CodeGraph 工作区运行：

```powershell
npm.cmd ci
npm.cmd run build
npx.cmd vitest run __tests__/extraction.test.ts --testNamePattern "GDScript"
```

如果需要重新构建 GDScript wasm，当前机器使用的 Emscripten SDK 在：

```powershell
$env:EMSDK
```

构建 grammar wasm 的流程：

```powershell
cmd /c "%EMSDK%\emsdk_env.bat >NUL && npx.cmd --yes tree-sitter-cli@0.24.7 build --wasm"
```

然后把生成的 `tree-sitter-gdscript.wasm` 放入外部 CodeGraph 工作区：

```text
%CODEGRAPH_GDSCRIPT_DIR%\src\extraction\wasm\tree-sitter-gdscript.wasm
```

## 初始化本项目索引

使用外部 CodeGraph 构建直接索引本仓库：

```powershell
node "$env:CODEGRAPH_GDSCRIPT_DIR\dist\bin\codegraph.js" init -i
```

初始化后应检查：

```powershell
node "$env:CODEGRAPH_GDSCRIPT_DIR\dist\bin\codegraph.js" status
node "$env:CODEGRAPH_GDSCRIPT_DIR\dist\bin\codegraph.js" query BattleController
node "$env:CODEGRAPH_GDSCRIPT_DIR\dist\bin\codegraph.js" query RewardGenerator
node "$env:CODEGRAPH_GDSCRIPT_DIR\dist\bin\codegraph.js" query DisplayNames
node "$env:CODEGRAPH_GDSCRIPT_DIR\dist\bin\codegraph.js" callees BattleController::start_battle
```

`status` 必须报告非零 `gdscript` 文件数量。只看到 C++、Python 或 YAML 不算完成。

## Codex MCP

Codex 可以临时使用外部构建启动 MCP：

```powershell
node "$env:CODEGRAPH_GDSCRIPT_DIR\dist\bin\codegraph.js" serve --mcp
```

不要把本机绝对路径写进项目配置。若需要长期使用，应配置到个人级 Codex 配置中。

## 边界

- 不修改 `project.godot`、运行时脚本、场景、资源或导出配置来接入 CodeGraph。
- `.codegraph/` 是本地生成索引，已加入 `.gitignore`。
- GDScript 索引增强属于外部 CodeGraph 工作区，不属于本 Godot 项目的运行内容。
