## 1. External CodeGraph Workspace

- [x] 1.1 Create or select an external CodeGraph fork/worktree outside this Godot repository and record the upstream commit or npm version being adapted.
- [x] 1.2 Decide the GDScript wasm source: local build with Docker/Podman/Emscripten, a trusted package artifact, or a vendored wasm in the CodeGraph worktree.
- [x] 1.3 Run a grammar health check against representative Godot 4 GDScript samples, including files from this repository, and stop if the grammar cannot parse them reliably.
- [x] 1.4 Dump and inspect the GDScript AST for functions, classes, `class_name`, variables, constants, signals, enums, `extends`, `preload`, `load`, and common call forms.

## 2. CodeGraph GDScript Support

- [x] 2.1 Add `gdscript` to CodeGraph language definitions, display names, wasm grammar mapping, and `.gd` extension detection.
- [x] 2.2 Implement a GDScript language extractor for script owners, `class_name`, inner classes, functions, `_init`, variables, constants, signals, and enums.
- [x] 2.3 Model top-level GDScript members under an implicit script owner derived from `class_name` or the file name.
- [x] 2.4 Extract common call/reference relationships for `foo()`, `obj.foo()`, `ClassName.foo()`, `extends`, `preload("res://...")`, and `load("res://...")`.
- [x] 2.5 Register the extractor in CodeGraph and update CodeGraph tests to cover language detection, symbol extraction, implicit owner behavior, call references, and resource references.
- [x] 2.6 Build CodeGraph and run the relevant CodeGraph extraction tests until they pass.

## 3. Project Integration Boundary

- [x] 3.1 Add `.codegraph/` to this repository's ignore rules before generating any local index.
- [x] 3.2 Add project-local documentation for installing or selecting the GDScript-enabled CodeGraph build, initializing the index, and verifying coverage.
- [x] 3.3 Confirm no Godot runtime scripts, scenes, resources, export presets, or player-facing text are modified for CodeGraph support.
- [x] 3.4 Configure Codex MCP or local CLI usage to point at the GDScript-enabled CodeGraph build without committing machine-specific absolute paths.

## 4. Repository Verification

- [x] 4.1 Initialize CodeGraph for this repository using the GDScript-enabled build.
- [x] 4.2 Verify CodeGraph status reports a nonzero `gdscript` file count and covers `scripts/`, `tests_or_debug/`, and `tools/`.
- [x] 4.3 Verify CodeGraph search can find `BattleController`, `RewardGenerator`, and `DisplayNames`.
- [x] 4.4 Verify at least one call/reference query works for a real GDScript method in this repository.
- [x] 4.5 Confirm `.codegraph/` remains untracked and no external CodeGraph source has been copied into this Godot repository.
- [x] 4.6 Run `openspec validate add-codegraph-gdscript-indexing --strict` and resolve any proposal/spec/task validation failures.
- [x] 4.7 If any Godot runtime files were changed despite the intended boundary, run the relevant Debug tests and the main scene startup check; otherwise record Godot runtime validation as not applicable.
