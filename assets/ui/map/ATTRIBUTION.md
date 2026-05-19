# 地图界面占位资源

本目录下的 `*_placeholder.png` 为项目内部创建的临时占位资源，用于接通地图背景板、地图板、路径、节点、按钮、移动骰展示和玩家标记的资源替换链路。节点占位包括起点、普通战斗、精英战斗、首领战、商店、铸骰坊、奖励、惩罚、奇遇、休整。

许可证：项目内部占位资源，后续可由正式美术直接替换对应文件或资源配置。

`node_*_generated.png` 与 `source/generated_node_icon_sheet_20260519.png` 为 ChatGPT 图像生成预览切图，已由用户在 2026-05-19 确认用于当前地图节点占位。用途：项目内部占位与后续美术迭代；后续可直接替换对应节点图片或调整 `MapStageArtConfig.tres`。
`node_rest_generated.png` 基于已确认的 `node_event_generated.png` 节点边框与底牌风格做项目内部临时补图，仅用于替换“休整”节点占位；后续正式美术可直接替换该图片或调整 `MapStageArtConfig.tres`。

`map_board_generated.png` 为当前地图阶段用的项目内部背景板占位资源，用于接通地图底板 / 路径底图的资源替换链路；后续正式地图背景板可直接替换该图片或调整 `MapStageArtConfig.tres`。

`map.png` 为用户在 2026-05-19 提供的当前地图底板资源，已接入 `MapStageArtConfig.tres` 的地图板纹理。
