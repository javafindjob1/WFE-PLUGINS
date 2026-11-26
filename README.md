# 魔兽死亡结算目录说明

本目录把正式项目材料和临时逆向分析材料分开存放。

## Source

正式源码和构建目录，日常开发、编译、测试和发布都在这里进行。

| 路径 | 内容 |
| --- | --- |
| `Source/Core` | 伤害采集、内存读取、结算、SQLite 与游戏内面板核心代码 |
| `Source/Ui` | WinForms 桌面界面 |
| `Source/DesktopHost` | Vue 桌面宿主 |
| `Source/WebHost` | SQLite 快照读取、分页和页面数据服务 |
| `Source/web` | Vue 3 页面源码和资源 |
| `Source/_test` | 自动化测试、假魔兽靶子和验证脚本 |
| `Source/tools` | 构建、部署、安装和发布打包脚本 |
| `Source/bin`、`Source/obj` | 本地构建输出 |
| `Source/publish`、`Source/publish_vue`、`Source/release` | 运行发布物和历史发布包 |
| `Source/Program.cs`、`Source/War3DeathSettlement.csproj` | 主程序入口和项目文件 |

构建命令：

```powershell
cd Source
dotnet build -c Release
```

详细功能和开发说明见 `Source/README.md`。

## TempAnalysis

临时逆向、地图提取和排查材料，不参与正式构建和发布。

| 路径 | 内容 |
| --- | --- |
| `TempAnalysis/_analysis` | 逆向分析中间数据、Ghidra 工程和扫描结果 |
| `TempAnalysis/_map_tj`、`TempAnalysis/_map_xf` | 地图提取数据 |
| `TempAnalysis/lua_scan`、`TempAnalysis/lua_tree`、`TempAnalysis/pylibs` | Lua 扫描、提取结果和分析依赖 |
| `TempAnalysis/_design` | 临时界面设计稿 |
| `TempAnalysis/*.py`、`TempAnalysis/*.lua` | 反汇编、MPQ、指针和符号分析脚本 |
| `TempAnalysis/*分析*.md`、探测文本和 `.obj` | 分析报告、探测快照和中间产物 |

## 根目录文档

| 文件 | 用途 |
| --- | --- |
| `需求文档.md` | 产品需求、验收口径和目录规范 |
| `问题.md` | 问题、排查过程和解决方案 |
| `AGENTS.md` | 项目开发约束 |

临时分析结果确认不再需要后，可以直接清理 `TempAnalysis`，不会影响 `Source` 的编译和发布。
