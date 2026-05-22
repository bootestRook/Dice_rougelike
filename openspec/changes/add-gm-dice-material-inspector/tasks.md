## 1. Main Menu GM Entry

- [x] 1.1 Add a right-top floating `GM` button to the main menu runtime UI.
- [x] 1.2 Add a collapsible GM function list under the floating button.
- [x] 1.3 Add the Chinese `骰子材质检查` action to the GM function list.
- [x] 1.4 Wire `骰子材质检查` to open the new material inspector screen.
- [x] 1.5 Ensure the floating GM entry is only created on the main menu and is cleared when entering run or GM tool views.

## 2. Material Data and Preview Reuse

- [x] 2.1 Add or extract a shared GM dice material resolver so resource materials and programmatic fallback materials are resolved consistently.
- [x] 2.2 Build a material list from `GmDiceDefinition.get_material_options()`.
- [x] 2.3 Include material ID, Chinese name, resource path when available, and programmatic fallback marker when no `.tres` exists.
- [x] 2.4 Ensure visible UI labels use Chinese material names and do not expose internal IDs.

## 3. Material Cabinet Screen

- [x] 3.1 Add `scenes/debug/GmDiceMaterialInspectorScreen.tscn` with a lightweight scripted root.
- [x] 3.2 Implement `scripts/ui/debug/GmDiceMaterialInspectorScreen.gd` to build the screen layout at runtime.
- [x] 3.3 Add a scrollable cabinet grid that creates one stable material card per material option.
- [x] 3.4 Render each card with a fixed-angle dice preview, Chinese material name, and click target.
- [x] 3.5 Add a back button that returns to the main menu without changing run state.

## 4. Single-Dice Inspector Popup

- [x] 4.1 Implement an in-game draggable inspector popup opened from a material card.
- [x] 4.2 Show the selected material Chinese name in the popup title.
- [x] 4.3 Render the selected material on a single rounded D6 preview.
- [x] 4.4 Add close behavior that removes only the popup and keeps the cabinet open.
- [x] 4.5 Add stable node names for popup title, close button, preview viewport, and selected material state.

## 5. View and Lighting Controls

- [x] 5.1 Add drag-to-rotate support inside the popup preview viewport.
- [x] 5.2 Add mouse-wheel zoom support inside the popup preview viewport.
- [x] 5.3 Add `重置视角`, `自动旋转`, and `显示点数` controls.
- [x] 5.4 Add lighting controls for main light intensity, main light direction, ambient light intensity, and fill light intensity.
- [x] 5.5 Add bright, neutral, and dark lighting presets that affect only the current popup preview.
- [x] 5.6 Ensure view and lighting changes do not write material, scene, or environment resources.

## 6. Automation and Tests

- [x] 6.1 Add a Debug smoke test for the main menu GM entry and `骰子材质检查` action.
- [x] 6.2 Add a Debug smoke test that opens the material inspector and verifies all GM material options are present.
- [x] 6.3 Add a Debug smoke test that opens a material popup and verifies draggable/closable/control nodes exist.
- [x] 6.4 Add checks that visible material labels are Chinese and do not expose forbidden internal UI text.
- [x] 6.5 Run relevant existing GM material tests: `DebugDiceMaterialPipelineSmokeTest.gd`, `DebugGmDiceLightingSmokeTest.gd`, and `DebugGmDiceEditSmokeTest.gd`.
- [x] 6.6 Run main scene startup check with headless Godot.
