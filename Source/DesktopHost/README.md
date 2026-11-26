# Vue Desktop

主界面使用 Vue 3，桌面容器使用 WinForms + WebView2。旧 WinForms 页面保留作回滚参考，
正式发布由 `War3DeathSettlement.Desktop.csproj` 生成单文件
`War3DeathSettlement.exe`。

## 职责划分

- Vue：死亡结算、伤害事件、战场单位、搜索、分页、历史抽屉、连接状态与桌面工具栏。
- C#：读取 ddh 写入的 SQLite，不扫描游戏内存、不打开共享内存、不注入游戏。
- WebView2：承载内嵌的 Vue 静态资源，并通过 `postMessage` 与 C# 双向通信。

## 构建

```powershell
cd <DeathSettlement>
.\tools\package_release.ps1
```

脚本会：

1. 安装前端依赖并构建 `web`。
2. 重新编译 `Native\UDamageWatcher.dll`。
3. 发布自包含、单文件的桌面程序。
4. 将发布包写入仓库根目录 `..\release\`。

## 桌面命令

Vue 发送：

```json
{ "type": "dss-command", "action": "find-game" }
```

当前支持：

- `find-game`
- `history-list`
- `history-load`
- `resume-live`
- `open-logs`
- `open-settings`

Vue 静态资源嵌入 exe，不依赖同目录网页文件。WebView2 Runtime 仍需系统已安装。

## WFE 采集 + 桌面查看

发布包中运行所需文件：

```text
Desktop\
  War3DeathSettlement.exe
Game\
  WFE-Libraries\
    UDamageWatcher.dll
```

运行顺序：

1. 通过 WFE 启动魔兽并进入地图，由 WFE 加载 `Game\WFE-Libraries\UDamageWatcher.dll`。
2. 运行 `Desktop\War3DeathSettlement.exe`。
3. 桌面程序只读取 ddh 写入的 SQLite，不注入游戏，也不请求 CUnit 属性。
