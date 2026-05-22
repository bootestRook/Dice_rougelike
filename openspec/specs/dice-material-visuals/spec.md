# dice-material-visuals Specification

## Purpose
Defines visual acceptance rules for generated dice materials, especially bronze and gold metal dice readability, texture import stability, and GM viewport lighting support.
## Requirements
### Requirement: Metal dice remain readable across light modes
The dice material pipeline SHALL keep bronze and gold dice visually readable in bright, neutral, and dark preview modes. Dark faces MUST retain recognizable material color and MUST NOT collapse into near-black blocks.

#### Scenario: Gold dark preview stays gold
- **WHEN** the gold dice dark preview is generated or inspected
- **THEN** the visible dark face retains a warm gold/brown hue and remains distinguishable from the background and floor shadow

#### Scenario: Bronze dark preview stays bronze
- **WHEN** the bronze dice dark preview is generated or inspected
- **THEN** the visible dark face retains an old bronze/brown hue with only localized patina and remains distinguishable from the background and floor shadow

### Requirement: Metallic PBR maps are bounded for stable dice visuals
The generated ORM maps for bronze and gold dice SHALL use bounded metallic and roughness ranges that support stable highlights and readable dark faces in the project preview scenes.

#### Scenario: Gold metallic map is not full-frame maximum
- **WHEN** the gold ORM texture is analyzed
- **THEN** the metallic channel is high enough to read as metal but is not uniformly locked to maximum value across the full texture

#### Scenario: Bronze roughness and metallic map support aged metal
- **WHEN** the bronze ORM texture is analyzed
- **THEN** the roughness and metallic channels represent aged bronze with local variation and do not create large unstable high-gloss regions

### Requirement: Bronze patina is localized
The bronze albedo texture SHALL keep copper-green patina localized to edges, scratches, or gated noise regions. Patina MUST NOT cover large continuous areas of primary visible faces.

#### Scenario: Bronze albedo avoids large green blocks
- **WHEN** the bronze albedo texture or preview shot is inspected
- **THEN** green patina appears as localized weathering instead of broad face-filling patches

### Requirement: Dice material imports use stable texture settings
Generated dice material textures SHALL have consistent Godot import settings appropriate to their channel type. Normal maps MUST be imported as normal maps, color textures MUST remain color textures, and data textures such as ORM, height, and flow masks MUST avoid unintended color correction.

#### Scenario: Normal maps import as normal maps
- **WHEN** bronze, gold, or crystal normal texture import files are inspected
- **THEN** each normal texture is configured as a normal map with the expected normal orientation

#### Scenario: Material textures have mipmaps for 3D sampling
- **WHEN** bronze, gold, or crystal dice material texture import files are inspected
- **THEN** textures used on 3D dice surfaces generate mipmaps unless the file is a deliberately excluded preview-only image

#### Scenario: ORM textures preserve channel packing
- **WHEN** bronze, gold, or crystal ORM import files are inspected
- **THEN** red remains ambient occlusion, green remains roughness, blue remains metallic, and the texture is not processed as a normal map

### Requirement: GM dice viewport supports metal materials
The GM physics dice viewport SHALL provide lighting and reflection context that supports metal dice materials without overpowering existing iron, glass, and crystal materials.

#### Scenario: Gold dice remains readable in GM viewport
- **WHEN** a GM dice instance uses the gold pipeline material
- **THEN** the dice remains readable while idle, rolling, and selected, without large black faces or flickering high-contrast bands

#### Scenario: Existing iron dice remains stable
- **WHEN** the GM viewport lighting is adjusted for bronze and gold
- **THEN** iron dice still retains its current readable steel-gray look and is not washed out

### Requirement: Visual regression checks cover material quality
The debug test suite SHALL include automated checks that can fail when metal dice resources are structurally valid but visually unstable.

#### Scenario: Material pipeline detects invalid import settings
- **WHEN** a generated normal texture is not imported as a normal map or lacks required mipmaps
- **THEN** the material pipeline debug test reports FAIL with a specific reason

#### Scenario: Material pipeline detects excessive patina or metallic extremes
- **WHEN** bronze patina coverage or gold metallic extremes exceed the accepted visual thresholds
- **THEN** the material pipeline debug test reports FAIL with a specific reason

#### Scenario: Required validation commands remain runnable
- **WHEN** the material visual fix is complete
- **THEN** the material pipeline smoke test, GM lighting smoke test, GM dice edit smoke test, and main scene startup check all run successfully
