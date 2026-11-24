# Vue Desktop

主界面使用 Vue 3，桌面容器使用 WinForms + WebView2。旧 WinForms 页面保留作回滚参考，
正式发布由 `War3DeathSettlement.Desktop.csproj` 生成单文件
`War3DeathSettlement.exe`。

## 职责划分

- Vue：死亡结算、伤害事件、战场单位、搜索、分页、历史抽屉、连接状态与桌面工具栏。
- C#：连接 War3、运行 `MonitorEngine`、读取 ddh SQLite、启动游戏内 WebHost。
- WebView2：承载内嵌的 Vue 静态资源，并通过 `postMessage` 与 C# 双向通信。

## 构建

```powershell
cd <DeathSettlement>
.\tools\build_vue_desktop.ps1
```

脚本会：

1. 构建 `web`。
2. 发布自包含、单文件的 `publish_vue\War3DeathSettlement.exe`。
3. 将新 exe 复制到正式目录 `publish\War3DeathSettlement.exe`。
4. 同步游戏内 Vue 资源到 WFE `Application\Libraries`。

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
