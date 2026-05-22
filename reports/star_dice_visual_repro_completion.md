# 星盘骰子视觉复刻落地记录

## 最终视觉验收

- 变更：`improve-star-dice-visual-repro`
- 运行编号：`20260522_124756`
- 状态：`valid`
- 用例：`dice_shader_basic`, `table_shader_basic`, `light_effect_basic`, `battle_star_dice_repro_full`
- 整图最新截图：`res://tests_or_debug/tmp_report/visual_acceptance/shader_light/latest/full_scene_repro/battle_star_dice_repro_full/battle_star_dice_repro_full_main.png`
- 改前 / 改后对比图：`res://reports/star_dice_visual_repro_before_after.png`

## 渲染特性快照

- 渲染器：`forward_plus`
- WorldEnvironment：存在
- ReflectionProbe 数量：`1`
- Glow：已启用
- SSAO：已启用
- Tonemap 模式：`3`
- 环境光强度：`0.42`
- fallback：构图 overlay 与接触影层均存在

## Renderer 清理警告

视觉验收运行状态为 `valid`，退出码为 `0`，但 Godot 在进程退出释放渲染资源时输出了清理警告，包括 `PagedAllocator`、`RID allocations` 和 `ObjectDB instances leaked at exit`。

这些警告发生在截图、manifest 写入和 latest 图片注册全部完成之后。它们应按 runner / runtime 清理问题记录，不作为视觉验收内容失败。
