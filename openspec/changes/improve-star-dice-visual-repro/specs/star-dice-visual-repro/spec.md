## ADDED Requirements

### Requirement: Visual reproduction uses layered dice presentation
The star dice visual reproduction SHALL separate dice body material, edge/rim glow, face value or symbol presentation, battle state overlay, and contact shadow into independently tunable presentation layers or resources.

#### Scenario: Dice material layers can be inspected separately
- **WHEN** the visual reproduction dice resources or debug snapshot are inspected
- **THEN** the dice exposes distinct body, edge/rim, face marker, state overlay, and contact shadow responsibilities instead of relying on one monolithic effect with no separable controls

#### Scenario: Face value remains readable over stylized material
- **WHEN** a colored star dice is rendered in the visual acceptance scene
- **THEN** the visible face value remains readable over the dice material and does not disappear into bloom, rim light, or surface noise

### Requirement: Lighting rig covers target-scene light roles
The star dice visual reproduction SHALL provide a named lighting rig with a large soft key or top light, cool blue table bounce, warm gold edge kicker, local glint highlights, controlled ambient light, and a reflection reference for glossy or metallic surfaces.

#### Scenario: Lighting roles are present
- **WHEN** the reproduction scene or battle dice viewport lighting snapshot is inspected
- **THEN** each required light role is present with a stable node name or snapshot entry and has bounded energy, color, range, and specular settings

#### Scenario: Dice retain blue-gold depth
- **WHEN** the full reproduction visual acceptance case is captured
- **THEN** dice and table surfaces retain both cool blue environmental depth and warm gold edge accents without being flattened by ambient light

### Requirement: Rendering features support glossy star-table presentation
The star dice visual reproduction SHALL use Godot built-in rendering features or documented fallbacks to support reflection context, controlled bloom, ambient occlusion, contact shadows, and transparent or decal-like face/edge layers.

#### Scenario: Reflection and contact cues are available
- **WHEN** the reproduction scene is loaded in a graphical Godot run
- **THEN** glossy dice and star-table surfaces have a reflection or environment reference and dice-to-table contact is visible through shadow, contact shadow, or a documented fallback layer

#### Scenario: Bloom does not wash out UI or face values
- **WHEN** glow/bloom is enabled for the reproduction scene
- **THEN** bloom accents edges, stars, and highlights while face values and nearby Chinese UI text remain readable

### Requirement: Star astrology table remains a first-class visual element
The star dice visual reproduction SHALL preserve the deep-blue astrology table as a visible stage with radial structure, star details, gold/blue line accents, material texture, and perspective depth.

#### Scenario: Table shader case validates stage materials
- **WHEN** the table shader visual acceptance case is captured
- **THEN** the table shows textured deep-blue material, readable radial or constellation structure, and controlled gold/blue accent emission

#### Scenario: Battle composition shows stage context
- **WHEN** the full battle reproduction case is captured
- **THEN** the dice row sits visibly on the astrology table and the stage context is not hidden by UI panels or cropped out of the first viewport

### Requirement: Full-scene visual acceptance anchors the target reproduction
The visual acceptance workflow SHALL include a full-scene reproduction case in addition to local shader, table, and light cases. The full-scene case MUST fix resolution, camera, seed, dice values, material palette, UI overlay state, run metadata, and manifest registration.

#### Scenario: Full-scene case produces manifest-registered image
- **WHEN** the shader/light visual acceptance runner is executed for all cases
- **THEN** it captures the full-scene reproduction image, records it in the run manifest, writes a run_id watermark, and reports no unregistered latest PNGs

#### Scenario: Acceptance images are not confused with stale captures
- **WHEN** the latest visual acceptance directory contains an image not listed in the current manifest
- **THEN** the visual acceptance run reports invalid status instead of silently accepting the stale image

### Requirement: Visual changes remain isolated from battle rules
The star dice visual reproduction SHALL NOT change battle scoring, reroll/score selection rules, reward generation, forge installation rules, or dice face data semantics.

#### Scenario: Visual implementation does not alter rule layer behavior
- **WHEN** the visual reproduction change is implemented and relevant Debug tests are run
- **THEN** battle, dice, reward, scoring, and forge tests continue to pass without new rule behavior or player-visible English internal IDs

### Requirement: Reproduction resources remain deterministic and licensed
The star dice visual reproduction SHALL be generated or edited through deterministic project scripts and existing project resources unless the user explicitly approves external assets with recorded attribution.

#### Scenario: Complex scene updates are generated by scripts
- **WHEN** the reproduction scene, stage, or visual acceptance layout requires complex node changes
- **THEN** the implementation uses a builder or patch script under `res://tools/scene_builders/` or `res://tools/editor/` rather than large hand-written `.tscn` edits

#### Scenario: External assets are not introduced without attribution
- **WHEN** new art, font, icon, texture, or image assets are considered
- **THEN** the change either uses existing/generated deterministic project assets or records source URL, license, author/project name, and attribution before inclusion
