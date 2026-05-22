## 1. Baseline and Diagnostics

- [x] 1.1 Record current bronze and gold preview behavior in bright, neutral, and dark modes using existing preview shots and GM viewport observations.
- [x] 1.2 Add a small diagnostic helper or test path that reports albedo hue/luminance, ORM metallic/roughness ranges, bronze patina coverage, normal map range, and import settings for dice material textures.
- [x] 1.3 Confirm iron dice remains the visual stability baseline because it uses the simple fallback material path.

## 2. Texture and PBR Generation

- [x] 2.1 Adjust `GenerateDiceMaterialTextures.py` bronze parameters so patina is localized to edges, scratches, or gated noise rather than broad primary face regions.
- [x] 2.2 Adjust `GenerateDiceMaterialTextures.py` gold parameters so metallic remains high but is not uniformly maximum across the texture.
- [x] 2.3 Tune gold roughness/albedo/emission so dark faces remain warm and readable without making the material look self-lit or plastic.
- [x] 2.4 Tune bronze roughness/albedo/emission so dark faces remain old-bronze readable while preserving local oxidation.
- [x] 2.5 Regenerate bronze and gold texture sets and preview shot images through the deterministic texture generator.

## 3. Godot Material and Import Settings

- [x] 3.1 Update the Godot material builder so bronze and gold material resources use the tuned PBR values and keep normal, ORM, emission, and height maps connected.
- [x] 3.2 Normalize dice texture import settings so normal textures import as normal maps with expected orientation.
- [x] 3.3 Normalize 3D dice surface texture import settings so mipmaps are enabled for material textures.
- [x] 3.4 Ensure ORM, height, and flow-mask imports remain data textures and preserve the ORM channel contract.
- [x] 3.5 Rebuild Godot material resources and preview scenes with `BuildDiceMaterialPipeline.gd`.

## 4. Lighting and Preview Environment

- [x] 4.1 Adjust GM physics dice viewport lighting or reflection environment so gold and bronze metal faces remain readable during idle, roll, and selection states.
- [x] 4.2 Adjust material preview scenes so bright, neutral, and dark modes exercise metal readability without overpowering iron, glass, or crystal looks.
- [x] 4.3 Decide whether `WorldEnvironment`/Sky/radiance is sufficient or whether a `ReflectionProbe` is needed; implement the smallest stable option.
- [x] 4.4 Verify iron dice retains its current readable steel-gray look after lighting changes.

## 5. Automated Regression Coverage

- [x] 5.1 Extend `DebugDiceMaterialPipelineSmokeTest.gd` or add a focused Debug test for import settings, mipmap presence, normal map configuration, and ORM channel sanity.
- [x] 5.2 Add automated thresholds for gold metallic extremes and dark-preview readability.
- [x] 5.3 Add automated thresholds for bronze patina coverage and dark-preview readability.
- [x] 5.4 Extend `DebugGmDiceLightingSmokeTest.gd` or add a focused GM visual smoke test so metal viewport lighting regressions produce clear FAIL output.
- [x] 5.5 Update `MATERIAL_PIPELINE.md` with the metal dice visual acceptance rules and rerun commands.

## 6. Validation

- [x] 6.1 Run `python tools\scene_builders\GenerateDiceMaterialTextures.py`.
- [x] 6.2 Run Godot headless material rebuild with `tools\scene_builders\BuildDiceMaterialPipeline.gd`.
- [x] 6.3 Run `DebugDiceMaterialPipelineSmokeTest.gd`.
- [x] 6.4 Run `DebugGmDiceLightingSmokeTest.gd`.
- [x] 6.5 Run `DebugGmDiceEditSmokeTest.gd`.
- [x] 6.6 Run the main scene startup check with `--headless --path . --quit-after 3`.
- [x] 6.7 Manually inspect the bronze and gold preview scenes in a graphical Godot session when available and record any remaining visual concerns.
