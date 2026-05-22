## 1. Baseline and Acceptance Gate

- [x] 1.1 Record the current failed visual result as the new baseline, including run_id, screenshot path, manifest path, and a short note that the previous result was not visually accepted.
- [x] 1.2 Create or update a reference gap checklist report that names the visible targets from the reference image: solid dice body, three visible faces, top values, front star emblems, side shading, glowing borders, contact shadow, star table, blue-gold UI, and bottom action bar.
- [x] 1.3 Extend the visual acceptance report schema so it records `engineering_status`, `visual_acceptance_status`, unresolved gaps, before screenshot path, after screenshot path, and before/after comparison image path.
- [x] 1.4 Ensure the final report cannot present the work as visually accepted unless the before/after screenshot has been shown in the Codex conversation and a human acceptance result is recorded.
- [x] 1.5 Add or update smoke coverage for the report contract so missing screenshots, missing gap checklist, or missing visual acceptance status fails clearly.

## 2. Solid Rounded Dice Body

- [x] 2.1 Inspect the current dice visual stack and document why the full-size transparent `EdgeRimGlowLayer` makes the dice look hollow.
- [x] 2.2 Replace the whole-dice transparent rim shell with bounded edge/corner highlight geometry or material logic that does not cover the entire body.
- [x] 2.3 Tune the dice body materials so the central dice read as opaque or near-opaque solid glossy objects, not semi-transparent boxes.
- [x] 2.4 Ensure each central dice shows a top face, front face, and side face from the reference camera angle.
- [x] 2.5 Add side-face darkening and bevel highlights so the dice have physical depth comparable to the reference image.
- [x] 2.6 Keep selection, disabled, scored, and other battle state overlays outside the body material layer.
- [x] 2.7 Add structural tests or snapshots that fail if the visual stack reintroduces a full-body transparent rim shell.
- [x] 2.8 Refine the temporary hard edge blocks into inset rounded bevel rails and matched corner caps, with before/after screenshot comparison recorded.

## 3. Dice Face Markers

- [x] 3.1 Replace the front-face placeholder plus sign with a star or compass-like emblem comparable to the reference image.
- [x] 3.2 Ensure the top-face values in the full-scene case read as `4, 3, 3, 4, 1, 6`.
- [x] 3.3 Add top-face inset border or panel treatment so digits sit on a clear face plane rather than floating loosely.
- [x] 3.4 Add front-face panel/border treatment so the emblem is framed like the reference dice.
- [x] 3.5 Verify face labels and emblems remain readable after Glow, Bloom, side shading, and camera perspective are applied.
- [x] 3.6 Add or update visual texture tests that check top values, front emblem nodes/resources, and marker layer separation.

## 4. Table, Composition, and UI Frame

- [x] 4.1 Tune the full-scene camera, dice row scale, and dice spacing so the dice sit in the same central band as the reference image.
- [x] 4.2 Improve the star table presentation so the deep-blue disc, gold rings, radial lines, star points, and center compass remain visible behind the dice.
- [x] 4.3 Ensure the dice appear grounded on the table using contact shadow, reflection, or darkened contact cues.
- [ ] 4.4 Align the visual acceptance overlay with the reference frame: left score panel, top relic/tool panel, bottom action panel, selected counter, and blue-gold border hierarchy. (paused: UI scope reverted per user request on 2026-05-22)
- [x] 4.5 Verify all visible UI/debug text in the full-scene screenshot is Chinese and does not expose internal English IDs.
- [ ] 4.6 Add or update composition smoke tests that fail on missing major regions or incoherent overlap. (paused: UI region checks reverted per user request on 2026-05-22; dice/scene structural checks remain)

## 5. Lighting and Rendering

- [x] 5.1 Retune the named light rig so it creates visible dice volume, side shading, local highlights, blue table bounce, and warm gold edge accents.
- [x] 5.2 Tune reflection/environment support so glossy dice and table highlights improve reference similarity without washing out the scene.
- [x] 5.3 Tune SSAO/contact shadow and fallback shadow layers so dice no longer appear to float.
- [x] 5.4 Tune Glow/Bloom and tonemap so edge highlights bloom while top digits, front emblems, and Chinese UI text remain readable.
- [x] 5.5 Record the enabled rendering features and fallback state in the visual acceptance manifest.

## 6. Visual Iteration Loop

- [x] 6.1 Run the builder or patch scripts to regenerate deterministic visual resources and scenes.
- [x] 6.2 Capture the before screenshot before each major visual surface is changed.
- [x] 6.3 Capture the after screenshot immediately after each major surface is changed.
- [x] 6.4 Generate a before/after comparison image for the current round and save it under `reports/`.
- [x] 6.5 Update the reference gap checklist with `improved`, `unchanged`, `regressed`, or `blocked` for every visible target.
- [x] 6.6 Show the before/after comparison image in the Codex conversation before reporting task completion.
- [x] 6.7 If the screenshot does not visibly approach the reference image, mark visual acceptance as not accepted and keep unresolved items in the report.

## 7. Verification

- [x] 7.1 Run `DebugShaderLightAcceptanceSmokeTest.gd`.
- [x] 7.2 Run the full shader/light visual acceptance runner for the full-scene reference case and record the run_id.
- [x] 7.3 Run `DebugGmDiceLightingSmokeTest.gd`.
- [x] 7.4 Run `DebugGmDiceVisualTextureSmokeTest.gd`.
- [x] 7.5 Run `DebugDiceMaterialPipelineSmokeTest.gd`.
- [x] 7.6 Run relevant battle UI smoke tests, including `DebugBattleDiceInputSmokeTest.gd` and `DebugBattleSmokeTest.gd`.
- [x] 7.7 Run the main scene startup check with headless Godot.
- [x] 7.8 Finalize the report with modified files, engineering test results, visual acceptance status, unresolved gaps, and before/after screenshots.


- [ ] 7.9 Human visual acceptance: review the before/after comparison in the Codex conversation and set visual_acceptance_status to accepted or not_accepted.
