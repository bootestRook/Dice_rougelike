## Context

当前仓库已经有两条相关视觉链路：

- `dice-material-visuals` 规格约束青铜、黄金、水晶等材质流水线的贴图、PBR 参数、导入设置和暗场可读性。
- `tests_or_debug/visual_acceptance/shader_light/` 已经提供 shader/light 视觉验收 runner，支持固定分辨率、case JSON、run_id 水印、manifest 和 latest 清理。

本次目标不是推翻已有管线，而是继续复刻参考图中的星盘战斗画面：深蓝星盘台面、彩色发光圆角骰、清晰面值、金色 UI 边线和可读的局部高光。当前最大差距集中在四层：

- 骰子材质模型过于单体，`repro_glow_dice.gdshader` 同时承担底色、边线、面内细节、发光和高光，难以独立调目标图中的漆面/宝石质感。
- 光照已有多光源，但缺少目标图那种大面积柔光、桌面反弹、金色边线补光、局部 glint 小高光和明确反射参考。
- 渲染环境已有 Glow、SSAO 和 tonemap，但缺少可验收的反射、接触阴影、后处理分层和整张战斗 UI 构图级 case。
- 当前视觉验收 case 关注 shader/table/light 局部，尚未覆盖“战斗画面整体是否接近参考图”。

## Goals / Non-Goals

**Goals:**

- 将目标视觉拆成材质、灯光、渲染、场景构图、验收五个独立工作面。
- 让骰子视觉可以分别调节骰体底色、边缘发光、面值/符号、局部高光、选择态和阴影。
- 为星盘台面和骰子提供更接近目标图的柔光、反弹光、边缘光、反射与接触阴影。
- 把新的 visual acceptance 扩展到整张战斗/GM 视觉复刻图，避免只看局部材质 PASS。
- 保持所有新增调试可见文本中文，并继续遵守不引入版权不明资源、不改战斗规则的项目口径。

**Non-Goals:**

- 不实现血量、敌人攻击、锁定操作、卡牌/能量等战斗规则变化。
- 不把骰面材质重新作为正式常规骰面槽位。
- 不引入 C#、第三方运行时框架、外部字体或版权不明素材。
- 不大规模手写复杂 `.tscn`；复杂场景和验收场景继续优先由 builder/patch 脚本生成。
- 不要求一次达到最终商业美术，只要求建立可持续迭代与可验收的复刻管线。

## Decisions

### 1. 新能力独立于 `dice-material-visuals`

`dice-material-visuals` 继续约束材质生产管线，尤其是青铜/黄金/水晶贴图与 PBR。新能力 `star-dice-visual-repro` 专注目标战斗画面的复刻质量，包括 repro shader、星盘台面、灯光、渲染和整图验收。

替代方案是修改 `dice-material-visuals`。该方案会把通用材质生产和特定参考图复刻混在一起，后续归档时规格边界不清晰。

### 2. 骰子材质拆为多层，而不是继续堆单个 shader

实现时优先把骰子视觉拆为：

- 骰体底层：负责基色、粗糙度、金属/非金属、微表面变化。
- 边缘/角高光层：负责 rim、bevel glint、发光描边。
- 面值/符号层：负责数字、星纹、面饰/印记可视标记，避免依赖底材质噪声。
- 状态层：负责选择、可结算、禁用等战斗态，不污染骰体材质。
- 阴影/接触层：负责台面接触影和投射感。

替代方案是继续在 `repro_glow_dice.gdshader` 中叠更多公式。它短期快，但每个效果互相牵连，复刻参考图时难以判断问题来自材质、光照还是后处理。

### 3. 灯光使用命名 rig 和可验收角色

新增或调整灯光时必须具备清晰角色，而不是只按能量堆亮度。建议角色为：柔光顶光/主光、冷蓝桌面反弹光、暖金边缘 kicker、局部 glint 小灯、低强度环境光和反射参考。

替代方案是只提高 ambient 或 emission。该方案会让画面变平，目标图中强烈的蓝金层次和骰子立体感会丢失。

### 4. 渲染能力优先使用 Godot 内置 Forward+ 功能

优先评估和使用 `WorldEnvironment`、Glow/Bloom、SSAO、ReflectionProbe/环境反射、Contact Shadow 或可控软阴影、透明/贴花层。若某功能在 headless 或目标平台不可用，必须提供结构化 fallback，并在验收报告里说明。

替代方案是引入外部后处理或素材包。该项目当前约束不适合引入第三方运行时或版权不明资源。

### 5. Visual acceptance 扩展为局部 case + 整图 case

保留已有 `dice_shader_basic`、`table_shader_basic`、`light_effect_basic`，新增面向目标图的整图 case，例如 `battle_star_dice_repro_full`。整图 case 应固定分辨率、相机、骰子面值、材质 palette、UI 遮挡层和 manifest 元数据。

替代方案是只保存人工截图。该方案容易拿错图、漏掉 run_id，也不利于回归对比。

## Risks / Trade-offs

- 拆多层后节点和材质数量增加 → 用 builder 脚本稳定生成，并通过 smoke test 检查节点名、材质路径和层开关。
- 反射和 Bloom 增强可能拖慢低端设备 → 先限制在 GM/视觉验收场景，正式战斗接入前记录开关和成本。
- Label3D/贴花层可能与透明材质出现深度排序问题 → 优先在独立 case 中验证多角度可读性，必要时使用 depth prepass 或固定 surface offset。
- 整图验收仍然无法自动判断“像不像” → 自动化先保证截图来源、构图、亮度、遮挡、节点和资源有效；审美差距保留人工对齐报告。
- Godot 图形环境退出时可能出现渲染资源释放警告 → 记录为 runner 风险，不把退出警告误判为截图内容失败；若影响退出码再单独修。

## Migration Plan

1. 先补 visual acceptance 整图 case 和报告结构，锁住当前基线。
2. 拆分骰子材质表现层，保留旧 `repro_*` 材质作为回退或对照。
3. 调整星盘台面材质、反射参考和接触阴影。
4. 增加命名灯光 rig，并在 GM 视口与复刻场景中共享配置或 builder 常量。
5. 接入渲染能力和 fallback，复跑局部 case、整图 case、GM 灯光测试、材质测试和主场景启动检查。
6. 若整图观感倒退，优先回退 builder 生成的资源和灯光参数，保留新增验收 case 作为下一轮基线。

## Open Questions

- 面值/符号层最终采用 `Label3D`、MeshText、Decal 还是专用贴花网格，需要在实现 spike 中比较清晰度和深度排序。
- ReflectionProbe 是否只放在 GM 复刻场景，还是也接入正式战斗 3D 舞台，需要结合性能和画面收益确认。
- 整图验收是否需要后续加入像素统计阈值，例如骰子亮度范围、蓝金占比、UI 遮挡比例，目前先以 manifest 与人工比对为主。
