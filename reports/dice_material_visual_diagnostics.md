# Dice Material Visual Diagnostics

## Baseline

- Iron dice is the stable visual baseline because it uses the simple `StandardMaterial3D` fallback path in `GmDiceCtrl.gd`, not the atlas/ORM material pipeline.
- Gold dice uses the pipeline mesh and `gold_dice.tres`; the previous ORM map was effectively full-metallic across the atlas, which made dark faces dependent on scene reflection.
- Bronze dice uses the pipeline mesh and `bronze_dice.tres`; the previous albedo had broad green patina regions that could occupy primary visible faces.
- Gold and crystal imports previously had missing mipmaps, and gold/crystal normal imports were not consistently marked as normal maps.

## Diagnostic Entry Point

Run:

```powershell
python tools\scene_builders\AnalyzeDiceMaterialVisuals.py
```

The report prints albedo luminance, bronze greenish coverage, ORM metallic/roughness statistics, normal ranges, key `.import` values, and preview-shot luminance.

## Post-Fix Snapshot

- Gold ORM: metallic mean is about `0.913`, and `metal>=.98` is `0.000`; it is still metal, but no longer full-frame maximum.
- Gold roughness mean is about `0.557`, keeping highlights broader and less jumpy.
- Gold dark preview luminance is about `0.121`; the dark face keeps a warm gold/brown hue.
- Bronze ORM: roughness mean is about `0.701`, metallic mean is about `0.812`.
- Bronze dark preview luminance is about `0.083`; the dark face keeps an old-bronze/brown hue.
- Bronze greenish coverage is currently below the diagnostic threshold and no longer forms large face-filling blocks.
- Material texture imports now enable mipmaps; bronze/gold/crystal normal textures import as normal maps.

Manual inspection was performed against the regenerated preview shot images in this workspace. A full interactive Godot editor inspection is still useful for final art tuning, but no blocking visual issue remains in the generated preview shots.
