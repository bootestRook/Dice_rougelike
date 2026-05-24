## ADDED Requirements

### Requirement: CodeGraph recognizes GDScript sources
The CodeGraph build used for this project SHALL recognize `.gd` files as `gdscript` source files and include them in the index scan while respecting `.gitignore`.

#### Scenario: GDScript files are included in project index
- **WHEN** the supported CodeGraph build indexes this repository
- **THEN** indexed language statistics include `gdscript` files from `scripts/`, `tests_or_debug/`, and `tools/`

#### Scenario: Unsupported CodeGraph build is rejected for initialization
- **WHEN** the available CodeGraph build does not map `.gd` to `gdscript`
- **THEN** project initialization documentation or tooling MUST report that GDScript indexing is unavailable instead of treating the index as complete

### Requirement: GDScript script symbols are extracted
The GDScript extractor SHALL create searchable symbols for script owners, named classes, inner classes, functions, constructors, variables, constants, signals, and enums with source file and line locations.

#### Scenario: Script owner is searchable
- **WHEN** a `.gd` file declares `class_name BattleController`
- **THEN** CodeGraph search can find a class-like symbol named `BattleController` at the declaring file location

#### Scenario: File without class_name still has an owner
- **WHEN** a `.gd` file has top-level members but no `class_name`
- **THEN** the extractor creates a stable script owner derived from the file name and attaches top-level members to it

#### Scenario: GDScript members are searchable
- **WHEN** a `.gd` file contains `func`, `_init`, `var`, `const`, `signal`, and `enum` declarations
- **THEN** CodeGraph search can find the corresponding method, constructor, field or variable, constant, signal-like symbol, and enum entries with their source locations

### Requirement: GDScript relationships are extracted
The GDScript extractor SHALL extract structural relationships and common references needed for navigation and impact analysis.

#### Scenario: Method call references are recorded
- **WHEN** a GDScript method calls `foo()`, `obj.foo()`, or `ClassName.foo()`
- **THEN** CodeGraph records a call or reference edge from the caller to the callee name

#### Scenario: Extends references are recorded
- **WHEN** a script uses `extends Node`, `extends RefCounted`, or `extends "res://path/script.gd"`
- **THEN** CodeGraph records an inheritance or reference relationship for the declared base

#### Scenario: Resource load references are recorded
- **WHEN** a script calls `preload("res://...")` or `load("res://...")`
- **THEN** CodeGraph records a reference to the resource path so related scripts and resources can be discovered

### Requirement: Project integration remains development-only
CodeGraph integration SHALL remain a local development and Codex MCP capability, not a Godot runtime dependency.

#### Scenario: Runtime project files are not coupled to CodeGraph
- **WHEN** this change is implemented
- **THEN** `project.godot`, runtime scripts, scenes, export presets, and gameplay resources do not require CodeGraph to run

#### Scenario: Local index is not committed
- **WHEN** `.codegraph/` is generated for this repository
- **THEN** the index directory is ignored by git and is not included as project content

### Requirement: GDScript indexing is verified on this repository
The completed integration SHALL include repeatable verification that CodeGraph covers the repository's GDScript code and can answer basic structural queries.

#### Scenario: Key project symbols can be queried
- **WHEN** the supported CodeGraph build indexes this repository
- **THEN** CodeGraph queries can find `BattleController`, `RewardGenerator`, and `DisplayNames`

#### Scenario: Index status reports healthy GDScript coverage
- **WHEN** verification is run after indexing
- **THEN** the result reports a nonzero `gdscript` file count and does not rely only on C++, Python, or YAML files

#### Scenario: External extractor tests pass before project initialization
- **WHEN** the project is initialized with GDScript CodeGraph support
- **THEN** the corresponding CodeGraph GDScript extraction tests have passed in the CodeGraph worktree used for indexing
