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
.\tools\package_release.ps1
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

## 不依赖 WFE 独立运行

发布包中桌面独立运行所需文件：

```text
Desktop\
  War3DeathSettlement.exe
  hook\
    ddh.dll
    ddh_inject.exe
Game\
  ddh_web\
```

运行顺序：

1. 不使用 WFE，正常启动魔兽并进入地图。
2. 以管理员身份运行 `Desktop\War3DeathSettlement.exe`。
3. 桌面程序会自动连接游戏、调用 `hook\ddh_inject.exe` 注入 `hook\ddh.dll`，
   并从发布包的 `Game\ddh_web` 启动页面宿主。

这种方式不读取 WFE 附加库目录，也不需要 WFE 进程。游戏进程是管理员权限时，
桌面程序必须同样以管理员权限运行。
