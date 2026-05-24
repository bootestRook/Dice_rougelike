## Implementation Notes

### 2026-05-24

- External CodeGraph worktree: `G:\codegraph-gdscript-indexing`
- Upstream repository: `https://github.com/colbymchenry/codegraph`
- Upstream commit: `f366222dbd6b7e43047072a9417289b1b02ae457`
- Published npm package observed earlier: `@colbymchenry/codegraph@0.9.3`
- Repository main package version at this commit: `0.9.4`
- GDScript grammar candidate: `tree-sitter-gdscript@6.1.0` (`https://github.com/prestonknopp/tree-sitter-gdscript`, MIT)
- Current local wasm build tools: `emcc`, `docker`, and `podman` are not available on PATH; Python launcher is also not available.
- Chosen wasm source direction: vendored `tree-sitter-gdscript.wasm` in the external CodeGraph worktree, built from `tree-sitter-gdscript@6.1.0` once a wasm toolchain is available.
- Checked package sources: `tree-sitter-gdscript@6.1.0` ships native prebuilds and grammar sources but no `.wasm`; `tree-sitter-wasms@0.1.13` does not include GDScript.
- Native grammar health check workspace: `G:\codegraph-gdscript-health`
- Native grammar health result: PASS on 10 real project samples (`BattleController.gd`, `RewardGenerator.gd`, `DisplayNames.gd`, `RunState.gd`, `ScoreEngine.gd`, `EffectResolver.gd`, `ForgeService.gd`, `BattleScreen.gd`, `DebugBattleSmokeTest.gd`, `BuildBattleStarDiceFull.gd`) with `rootNode.hasError=false`.
- Native `tree-sitter` string parsing failed on files larger than roughly 32 KiB with `Invalid argument`; parsing with a chunked callback succeeded. This is a Node binding behavior to account for in ad-hoc checks, not a grammar parse failure.
- AST inspection result: PASS. Key node types are `class_name_statement`, `class_definition`, `function_definition`, `constructor_definition`, `variable_statement`, `const_statement`, `signal_statement`, `enum_definition`, `enumerator`, `extends_statement`, `call`, and `attribute_call`.
- Godot 4 `@export var` parses as `variable_statement` with `annotations`, while old-style `export var` has a separate `export_variable_statement`; the extractor should support both.
- `preload("res://...")` and `load("res://...")` parse as `call` nodes with an identifier callee and string argument; member calls like `target.foo()` parse as `attribute` containing `attribute_call`.
- External CodeGraph implementation status: added `gdscript` language mapping, vendored wasm path lookup, GDScript extractor, function-body language hook support, extraction tests, README row, and CHANGELOG entry.
- CodeGraph build result: PASS (`npm.cmd run build`).
- Emscripten SDK installed outside the project at `G:\emsdk`; `tree-sitter-gdscript.wasm` was built from `tree-sitter-gdscript@6.1.0`.
- GDScript wasm health result: PASS via `node scripts/add-lang/check-grammar.mjs gdscript G:\Dice_rougelike\scripts\runtime\BattleController.gd 20`; ABI version 14, 20 clean parses / 0 errors.
- GDScript extraction test result after vendoring wasm: PASS via `npx.cmd vitest run __tests__/extraction.test.ts --testNamePattern "GDScript"`; 4 passed / 248 skipped.
- Project integration boundary: `.codegraph/` added to `.gitignore`; project usage docs added at `docs/dev/codegraph_gdscript.md` with environment-variable based commands instead of committed machine-specific paths.
- Runtime boundary check: no Godot runtime scripts, scenes, resources, export presets, or player-facing text were changed for CodeGraph support.
- Project CodeGraph init result: PASS via `node G:\codegraph-gdscript-indexing\dist\bin\codegraph.js init -i`; indexed 246 files with 9,623 nodes and 9,377 initial edges.
- Project CodeGraph status result: PASS; 253 files, 9,623 nodes, 23,917 edges, and 239 `gdscript` files reported.
- Project coverage check: PASS; `files --filter scripts`, `files --filter tests_or_debug`, and `files --filter tools` all report indexed files, including GDScript files in each area.
- Project symbol query result: PASS via `query BattleController`, `query RewardGenerator`, and `query DisplayNames`; each resolves the expected GDScript script class plus preload references.
- Project call/reference query result: PASS via `callees BattleController::start_battle` and `callers BattleController::start_battle`; both return real GDScript relationships.
- Project repository boundary check: PASS; `.codegraph/` is ignored/untracked and no external CodeGraph source was copied into this Godot repository.
- Godot validation: not applicable for this change because no Godot runtime scripts, scenes, resources, export presets, or player-facing text were modified for CodeGraph support.
- OpenSpec validation result: PASS via `openspec validate add-codegraph-gdscript-indexing --strict`.
