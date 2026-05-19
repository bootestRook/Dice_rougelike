# 原生骰子物理依赖

## godot-cpp

- 来源：https://github.com/godotengine/godot-cpp
- 接入方式：`third_party/godot-cpp` git submodule
- 许可证：MIT License
- 用途：构建 Godot 4 GDExtension 绑定层。

## LLVM-MinGW

- 来源：https://github.com/mstorsjo/llvm-mingw
- 本机安装位置：`%LOCALAPPDATA%/CodexTools/llvm-mingw-20260505-ucrt-x86_64`
- 许可证：LLVM / MinGW-w64 相关开源许可证，随工具链发行包提供。
- 用途：在 Windows 上编译 `addons/physics_dice_solver` 的原生动态库。

LLVM-MinGW 只作为本机编译工具使用，不提交到项目仓库。
