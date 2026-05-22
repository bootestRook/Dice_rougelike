## 1. Baseline and Visual Acceptance

- [x] 1.1 Review the latest target reference, current `shader_light` acceptance images, and `reports/dice_material_visual_diagnostics.md`; record the initial visual gap summary in a local report.
- [x] 1.2 Add a full-scene reproduction visual acceptance case for the star dice battle composition with fixed resolution, camera, dice values, material palette, seed, and watermark metadata.
- [x] 1.3 Extend the visual acceptance runner or case config so the new full-scene case is manifest-registered and stale latest PNGs still invalidate the run.
- [x] 1.4 Add or update a smoke test that verifies the full-scene case JSON, camera marker, output path, and manifest registration contract.
- [x] 1.5 Run the existing local cases and the new full-scene case once to capture the baseline before visual changes.

## 2. Dice Material Layering

- [x] 2.1 Inspect `repro_glow_dice.gdshader`, `GmDiceCtrl.gd`, and `GmDiceMaterialResolver.gd` to decide the minimal layer split without changing battle rules.
- [x] 2.2 Add a deterministic builder or helper path for layered star dice materials while preserving existing `repro_*` materials as fallback or comparison resources.
- [x] 2.3 Split dice body controls from edge/rim glow controls so base color, roughness, metallic/specular, rim power, and edge emission can be tuned independently.
- [x] 2.4 Move visible face value/symbol presentation into a separate marker layer or verified Label3D/mesh/decal layer with stable offsets and readable outline.
- [x] 2.5 Keep selection, disabled, scored, and other battle state visuals outside the body material layer.
- [x] 2.6 Add snapshot/test coverage that verifies body, edge/rim, face marker, state overlay, and contact shadow responsibilities are separately present.

## 3. Stage and Table Presentation

- [x] 3.1 Inspect `star_astrology_disc.tscn`, stage materials, and generated stage textures for current radial/star/gold-line coverage.
- [x] 3.2 Improve the star table material or builder output so the deep-blue disc, radial structure, star details, and gold/blue accents remain visible from the battle camera.
- [x] 3.3 Add or tune contact shadow/shadow-catcher presentation so settled dice visibly sit on the table instead of floating.
- [x] 3.4 Verify table shader acceptance captures textured stage detail without separate stale geometry or UI-obscured key areas.

## 4. Lighting Rig

- [x] 4.1 Define named light roles for soft key/top light, cool table bounce, warm gold edge kicker, local glint highlights, ambient, and reflection reference.
- [x] 4.2 Update the GM visual reproduction scene builder and `GmDiceViewport.gd` so light roles have stable names and bounded energy/range/specular values.
- [x] 4.3 Tune lights against the target reference so dice retain blue-gold depth while face values remain readable.
- [x] 4.4 Extend `DebugGmDiceLightingSmokeTest.gd` or a focused visual test to verify required light roles and snapshot exposure.

## 5. Rendering Features and Fallbacks

- [x] 5.1 Evaluate Godot Forward+ options for reflection context, ReflectionProbe or environment reflection, SSAO, contact shadow, transparent marker layers, and Glow/Bloom separation.
- [x] 5.2 Add reflection/environment support to the visual reproduction scene with a documented fallback for headless or unsupported renderer contexts.
- [x] 5.3 Tune Glow/Bloom and tonemap so highlights bloom but Chinese UI text and dice face values do not wash out.
- [x] 5.4 Add a diagnostic snapshot or report section that records which rendering features are enabled for the acceptance run.

## 6. Battle Stage Integration

- [x] 6.1 Apply the improved visual stack to `BattleDiceStage3D` through existing GM dice viewport/material resolver boundaries.
- [x] 6.2 Ensure UI still only forwards operations and does not gain scoring, reward, or dice-rule logic.
- [x] 6.3 Verify the battle composition keeps dice, table, bottom action panel, and side UI readable without incoherent overlap.
- [x] 6.4 Confirm all new or changed debug/player-visible labels are Chinese and do not expose internal English material IDs.

## 7. Verification

- [x] 7.1 Run `DebugShaderLightAcceptanceSmokeTest.gd`.
- [x] 7.2 Run the full shader/light visual acceptance runner and record the run_id in the completion report.
- [x] 7.3 Run `DebugGmDiceLightingSmokeTest.gd`.
- [x] 7.4 Run `DebugGmDiceVisualTextureSmokeTest.gd`.
- [x] 7.5 Run `DebugDiceMaterialPipelineSmokeTest.gd`.
- [x] 7.6 Run relevant battle UI smoke tests, including `DebugBattleDiceInputSmokeTest.gd` and any full battle layout capture tests touched by the change.
- [x] 7.7 Run the main scene startup check with headless Godot.
- [x] 7.8 Document any Godot renderer cleanup warnings separately from visual acceptance content failures.
