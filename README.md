# War3DeathSettlement

魔兽争霸本地伤害采集、死亡结算和伤害复盘工具。

项目使用 WFE 注入原生采集模块 `UDamageWatcher.dll`，由采集模块记录逐笔伤害并写入本机
SQLite；桌面程序只读取 SQLite，提供死亡结算、伤害事件、战场单位和历史会话。

## 目录结构

| 路径 | 用途 |
| --- | --- |
| `Source/` | 正式源码、构建工具和项目说明 |
| `Source/Native/` | 游戏内原生采集模块和伤害钩子 |
| `Source/DesktopHost/` | 单文件桌面程序 |
| `Source/web/` | Vue 3 页面源码 |
| `Source/tools/` | 部署、安装和发布脚本 |
| `TempAnalysis/` | 逆向、探针、截图、提取数据和一次性验证产物 |
| `release/` | 构建生成的发布包，不纳入 Git |
| `需求文档.md` | 产品需求、数据口径和验收标准 |
| `问题.md` | 问题记录、排查过程和解决方案 |
| `AGENTS.md` | 项目开发约定 |

`Source` 只放正式源码；分析、排查和验证产物统一放入 `TempAnalysis`。

## 构建与发布

构建机需要：

- .NET 10 SDK
- Node.js 和 npm
- Visual Studio C++ Build Tools 与 Windows SDK

从源码目录执行：

```powershell
cd Source
powershell -ExecutionPolicy Bypass -File tools\package_release.ps1
```

脚本会：

1. 安装前端依赖并构建 Vue 页面。
2. 从 `Source/Native` 重新编译 `UDamageWatcher.dll`。
3. 发布 .NET 10 自包含、单文件桌面程序。
4. 将完整发布包写入仓库根目录 `release/`。

最终用户不需要安装 .NET，但桌面页面需要 Microsoft Edge WebView2 Runtime。

## 使用方式

1. 完全退出 WFE 和魔兽。
2. 使用发布包中的 `install_release.cmd` 安装更新。
3. 重启 WFE，并通过 WFE 启动魔兽、进入地图。
4. 运行 `Desktop\War3DeathSettlement.exe` 查看本机 SQLite 数据。

更新 `UDamageWatcher.dll` 后必须完整重启 WFE，不能只重启魔兽。

## 文档

- 完整架构、数据口径、开发与排障说明：[Source/README.md](Source/README.md)
- 产品需求和验收标准：[需求文档.md](需求文档.md)
- 历史问题和解决方案：[问题.md](问题.md)
- 开发与目录约定：[AGENTS.md](AGENTS.md)
