## ADDED Requirements

### Requirement: Visual tasks require before and after evidence
The visual reproduction workflow SHALL capture a baseline screenshot before visual changes and a comparison screenshot after visual changes. The final response for a visual task MUST show the before/after image paths in the Codex conversation.

#### Scenario: Before and after screenshots are required
- **WHEN** a visual, UI, material, lighting, rendering, or scene composition task is ready to be reported complete
- **THEN** the report includes the baseline screenshot path, the updated screenshot path, and a before/after comparison image shown in the Codex conversation

#### Scenario: Missing screenshots block completion
- **WHEN** screenshots cannot be generated
- **THEN** the task report marks visual acceptance as failed or blocked and explains the failed command, reason, and next step

### Requirement: Visual acceptance is separate from engineering completion
The system SHALL distinguish engineering completion from visual acceptance for reference-image reproduction work. A task MUST NOT be treated as visually complete only because tests, resources, manifests, or OpenSpec tasks exist.

#### Scenario: Engineering checks pass but visual match fails
- **WHEN** automated tests and visual acceptance runner manifest are valid but the before/after screenshot does not visibly approach the reference image
- **THEN** the report marks engineering completion as pass and visual acceptance as not accepted

#### Scenario: User accepts visual result
- **WHEN** before/after screenshots are displayed and the user or human reviewer accepts the result
- **THEN** the report may mark visual acceptance as accepted for that round

### Requirement: Reference gap checklist drives work items
The change SHALL maintain a reference gap checklist that maps each visual task to a visible target in the reference image. Tasks MUST describe the intended screenshot outcome, not only the files or nodes to change.

#### Scenario: Work item has a visible outcome
- **WHEN** an implementation task is written for this change
- **THEN** it names the visible reference-image gap it addresses and the expected screenshot improvement

#### Scenario: Work item only adds structure
- **WHEN** a task only says to add a node, material, light, or script without naming the visible target
- **THEN** the task is insufficient for visual completion

### Requirement: Dice must read as solid rounded physical objects
The reference star dice view SHALL render dice as solid rounded physical objects. Dice MUST NOT appear as hollow transparent shells, missing panels, or flat glowing boxes.

#### Scenario: Solid dice body is visible
- **WHEN** the full-scene reference visual acceptance screenshot is inspected
- **THEN** each central dice has a visible solid body, rounded edges, top face, front face, side face, and darker side shading

#### Scenario: Transparent shell does not obscure the body
- **WHEN** edge or rim glow is enabled
- **THEN** the glow does not cover the entire dice as a semi-transparent outer cube and does not make the body appear hollow

### Requirement: Dice faces match the reference visual language
The reference star dice view SHALL show readable top-face values and front-face star emblems for the central dice. Face markers MUST remain readable after Bloom, Glow, lighting, and material changes.

#### Scenario: Top values are readable
- **WHEN** the full-scene screenshot shows the six central dice
- **THEN** the top values read as `4, 3, 3, 4, 1, 6` and remain high contrast against their dice bodies

#### Scenario: Front star emblems are present
- **WHEN** the front faces of the central dice are visible
- **THEN** each front face includes a star or compass-like emblem comparable to the reference image rather than a placeholder plus sign

### Requirement: Dice placement and contact must match the table
The reference star dice view SHALL make the dice appear settled on the astrology table. Each dice MUST have visible contact grounding through shadow, reflection, or darkened contact area.

#### Scenario: Dice do not float
- **WHEN** the full-scene screenshot is inspected
- **THEN** every central dice visually contacts the table plane and has a contact shadow or equivalent grounding cue

#### Scenario: Dice row follows the reference composition
- **WHEN** the full-scene screenshot is inspected
- **THEN** the six central dice form a horizontal row centered on the star table, with spacing and scale close to the reference image

### Requirement: Star table and UI composition match the reference frame
The reference star dice view SHALL preserve the reference composition: left score panel, top relic/tool panel, central deep-blue astrology table, bottom action panel, blue-gold borders, and Chinese UI text.

#### Scenario: Main regions are visible
- **WHEN** the full-scene screenshot is generated
- **THEN** the left score panel, top inventory panel, central table, central dice row, bottom action panel, and selected counter are all visible without incoherent overlap

#### Scenario: UI text remains Chinese
- **WHEN** debug or player-visible UI text appears in the reference visual screenshot
- **THEN** it uses Chinese text and does not expose internal English IDs

### Requirement: Lighting and rendering serve the reference match
The visual stack SHALL use lighting, environment, reflection, contact shadow, tonemap, Glow, and Bloom to improve similarity to the reference image. Rendering changes MUST preserve dice face readability.

#### Scenario: Lighting improves depth
- **WHEN** the before/after screenshots are compared
- **THEN** the after screenshot shows stronger dice volume, side shading, blue-gold separation, and local highlights than the baseline

#### Scenario: Bloom does not wash out markers
- **WHEN** Bloom or Glow is enabled
- **THEN** top values, front emblems, and Chinese UI text remain readable

### Requirement: Visual report records acceptance status
The visual acceptance report SHALL record run_id, screenshot paths, rendering feature snapshot, reference gap checklist status, engineering completion status, visual acceptance status, and unresolved gaps.

#### Scenario: Report distinguishes unresolved visual gaps
- **WHEN** the visual run is complete but some reference-image gaps remain
- **THEN** the report lists those gaps under unresolved items instead of silently marking the visual target complete

#### Scenario: Final report is ready for human review
- **WHEN** the task is ready for final response
- **THEN** the report includes enough local paths and screenshot evidence for the user to inspect the visual result without rerunning commands
