## Why

上一轮 `improve-star-dice-visual-repro` 建立了视觉验收管线，但最终截图与参考图差距仍然很大：改动主要停留在轻微光效和参数变化，骰子仍像半透明空壳，缺少参考图中的实体圆角、顶面数字、前脸星徽、侧面厚度、接触阴影和蓝金 UI 层次。现在需要重新设置一轮更硬的变更，把“视觉达到参考图方向”作为完成条件，而不是只把“有节点、有灯、有截图、有测试”视为完成。

## What Changes

- 建立新的 `reference-star-dice-visual-match` 能力，约束参考图级星盘战斗画面的视觉复刻标准、截图对比流程、人工验收门槛和失败处理。
- 将视觉完成定义拆为“工程完成”和“视觉接受”：OpenSpec 任务完成前必须生成并在 Codex 对话展示改动前后截图，且关键差距必须肉眼可见地改善。
- 以骰子为第一优先级重做复刻目标：实体圆角骰体、三面可见、顶面大数字、前脸星徽、发光边框、侧面暗部、接触阴影和材质差异必须达到参考图方向。
- 重新约束灯光和渲染：灯光不再只作为微调项，而要服务于骰子实体感、台面反射、蓝金层次和数字可读性。
- 扩展视觉验收报告：必须记录参考图差距清单、每轮截图、人工判断、未达标项，以及是否允许进入下一轮。
- 不改变战斗规则、算分规则、奖励规则、骰面数据模型或玩家操作流程。

## Capabilities

### New Capabilities
- `reference-star-dice-visual-match`: 约束星盘战斗参考图级视觉复刻，包括硬性视觉门槛、截图对比、人工验收、骰子实体表现、台面/UI/灯光/渲染对齐和完成定义。

### Modified Capabilities
<!-- No archived existing capability is modified in this change. The previous unarchived `improve-star-dice-visual-repro` output is treated as implementation context, not as a spec-level modification. -->

## Impact

- 影响视觉复刻文档与流程：`docs/visual_acceptance_workflow.md`、`AGENTS.md` 中视觉截图规则、OpenSpec 完成报告格式。
- 影响视觉验收工具与报告：`tests_or_debug/visual_acceptance/shader_light/`、`tests_or_debug/tmp_report/visual_acceptance/`、`reports/`。
- 影响骰子视觉相关脚本和资源：`tools/scene_builders/BuildGmDiceVisualRepro.gd`、`scripts/ui/debug/gm_dice_port/GmDiceCtrl.gd`、`GmDiceMaterialResolver.gd`、`assets/models/dice/`、`assets/materials/dice/`、`assets/shaders/dice/`。
- 影响星盘舞台、灯光和渲染环境：`assets/models/stage/star_astrology_disc.tscn`、`assets/materials/stage/`、`assets/environments/`、GM/战斗 3D 视口。
- 不引入版权不明外部资源、不批量生成正式美术、不引入 C# 或第三方运行时框架。
