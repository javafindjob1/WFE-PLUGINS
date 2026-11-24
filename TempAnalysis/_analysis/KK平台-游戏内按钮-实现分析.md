# KK 平台“游戏内按钮”是怎么做的（REA 静态+日志证据）与我们的做法

日期：2026-11-14
目标：搞清楚 KK 对战平台游戏内那排按钮（商城 / 设置 等）的实现方式，再决定死亡结算
怎么在游戏界面上加一个自己的按钮。

---

## 0. 结论（先看这个）

| 问题 | 结论 | 证据类型 |
| --- | --- | --- |
| 按钮是谁画的 | **平台注入到 `war3.exe` 里的 `War3Plugin.dll`**，不是地图、不是 yd_jass_api | 观测（平台自己的游戏内日志） |
| 用什么画的 | **Dear ImGui 1.92.2（静态编译进 DLL）+ 自己写的 OpenGL 渲染**，覆盖在游戏画面上 | 观测（DLL 内字符串/导入表） |
| 输入怎么拿 | ImGui 的 `imgui_impl_win32` 后端（子类化游戏窗口过程） | 观测（DLL 内字符串） |
| 按钮数据哪来 | 平台主程序（`Platform.exe`）通过 socket + 共享内存发给插件（`war3dll.log` 里的 `share_memory` / `War3Communication` / `nethook`） | 观测（日志模块名）+ 推断（具体协议未逆） |
| **我们要不要照抄** | **不照抄**。死亡结算已经有 ddh 的“引擎帧”通道（CBackdropFrame/CTextFrame + 窗口过程命中测试），加按钮用这条就够了：不用 hook 渲染、不用管 GL/D3D、不用担心分辨率和 UI 缩放 | 设计选择（见 §4） |

一句话：**KK 是“在游戏进程里再开一个 ImGui 图层”；我们是“直接用游戏自己的 UI 帧”。**
两条路都能做出“游戏界面上的按钮”，但后者对我们这种已经注入 ddh、已经有帧代码的库来说
成本低一个数量级。

---

## 1. 目标身份

| 文件 | 说明 | SHA-256 |
| --- | --- | --- |
| `C:\Program Files (x86)\kkduizhan\plugins\Game\War3Plugin.dll` | 平台注入游戏进程的插件（2,629,592 字节，PE32 x86） | `c869ea4cc55e23ded1ddd51a0ad24bf3c5b8ca164340ffe913a971907621b120` |
| `C:\Program Files (x86)\kkduizhan\plugins\game\GameHelper.dll` | 47,064 字节，另有用途（本次只做了资源/字符串比对） | `da2257af6f2d886b3829dbfb938b8ffa522cbcd4740c370a883c156d7c870185` |
| `C:\3rd\war5\dz_w3_plugin.dll` | 573,432 字节，`dz_w3_plugin.ini` 里存 `[DzAPI]` 的离线存档值 —— 这是**单机 DzAPI 模拟器**，不是游戏内 UI | `c790ab9c67b980d767571b86e438e76e16316c700843286b3b4baea30d07b23f` |

> 一开始怀疑的 `dz_w3_plugin.dll` 不是界面实现：它的字符串是一整套 `ADDRESS_*` / `FUNCTION_*`
> 的 game.dll 函数表（给 DzAPI 单机跑用的），没有 ImGui、没有 OPENGL32 导入。

---

## 2. 观测证据

### 2.1 平台自己的游戏内日志（最硬的证据）

路径：`C:\Program Files (x86)\kkduizhan\log\<启动时间>\war3\<pid>\war3dll.log`

```
I ... [Logger:76] Logger Inited. C:\Program Files (x86)\kkduizhan\plugins\Game\War3Plugin.dll, ...
I ... [war3dzapi:2090] InitializeJAPI()
I ... [war3jass:982] InitUseWideScreen:true
I ... [war3hook_widget:900] wh(900), err
I ... [widget:65] up(65), opengl=4.6.0 NVIDIA 537.70      <-- widget.cpp 直接问 OpenGL 版本
I ... [widget:69] up(69), max=32768
I ... [war3hook_widget:842] wh(842), err
```

读到的东西：

1. 注入的是 **`War3Plugin.dll`**（日志第一行自己写了路径）。
2. 里面有一组源文件模块：`war3hook.cpp`、`war3hook_widget.cpp`、`widget.cpp`、
   `war3dzapi.cpp`、`war3jass.cpp`、`war3skin.cpp`、`messagehook.cpp`、`nethook.cpp`、
   `loadlib.cpp`、`share_memory.cpp`。
3. **`widget.cpp` 在初始化时查询 OpenGL 版本**（`up({}), opengl={}`）——说明游戏内控件
   是画在 GL 上的，不是游戏自己的 UI 帧。

### 2.2 DLL 内字符串（静态）

同一份 `War3Plugin.dll` 里能直接读到：

```
Dear ImGui 1.92.2 WIP (19211)
imgui.ini
imgui_log.txt
imgui_impl_win32
imgui_impl_dx9
Empty label e.g. Button("") == same ID as parent widget/node. Use Button("##xx") instead!
E:\gitlab-runner-kk\builds\...\Client\Platform\Game\War3Plugin\GameUI\widget.cpp
E:\gitlab-runner-kk\builds\...\Client\Platform\Game\War3Plugin\war3\war3hook_widget.cpp
up({}), opengl={}
up({}), max={}
```

以及一批 JAPI native 名：`DzWidgetSetMinimapIcon`、`DzWidgetSetMinimapIconEnable`、
`DzSetWidgetSpriteScale` 等（地图侧 `lua_tree/lib/japi.lua` 里对应的就是这批）。

### 2.3 导入表（静态）

`War3Plugin.dll` 的导入（PE32，ImageBase `0x10000000`）：

```
OPENGL32.dll:
  glEnable, glBindTexture, glGetIntegerv, glGetError, glTexSubImage2D,
  glTexImage2D, glIsEnabled, glDeleteTextures, glGetString, wglGetProcAddress
```

再结合节表里的 `.detourc` / `.detourd`（Microsoft Detours 的代码/数据节），可以确认它是
**用 Detours 挂 API、自己建 GL 纹理（字体图集/图标）并绘制** 的形态。

### 2.4 REA 静态分析（Ghidra）

- `open_binary` + 自定义 `rea function` 快照分析（`_analysis/war3plugin.snap`）。
- 抽查函数 `FUN_1019c960`（地址 `0x1019c960`）：就是 **ImGui 上下文初始化**
  （里面写 `imgui.ini` / `imgui_log.txt` 指针、`DisplaySize` 等默认值），
  证明 ImGui 是**静态链进这个 DLL**，不是外挂 exe。
- `rea xrefs` 对 `up({}), opengl={}`（`0x1021de68`）返回空：这些 fmt 字符串是经
  `{fmt}` 的编译期字符串表/偏移访问的，Ghidra 没建直接引用；**所以“按钮创建点”
  没有靠 xref 逐级追到**（见 §5 未完成项）。

---

## 3. KK 的按钮到底怎么工作（综合判断）

```
Platform.exe (Qt)
   │  socket + 共享内存（share_memory / War3Communication / nethook）
   ▼
war3.exe 进程内 War3Plugin.dll
   ├─ Detours 挂 win32 消息 / GL
   ├─ widget.cpp：ImGui context、GL 后端（glTexImage2D 上传字体图集/图标）
   ├─ war3hook_widget.cpp：跟游戏 UI 打交道（取控件、算坐标、置顶）
   ├─ imgui_impl_win32：子类化游戏窗口过程 → 鼠标/键盘进 ImGui
   └─ 画出来的商城/设置按钮 = ImGui::Button / 图片按钮（在 ImGui 窗口里排版）
```

要点：**这套按钮和游戏引擎完全无关**，是“在游戏窗口上再盖一层”。好处是排版自由、
可以做网页级别的界面；代价是要自己 hook 渲染与输入，且要处理 GL/D3D、分辨率、DPI、
全屏独占等一堆问题（所以它才需要 `up({}), opengl={}` 探测和 `imgui_impl_dx9` 备用后端）。

---

## 4. 我们的做法（已实现，v28）

死亡结算不是平台，**没有权利也没有必要**去 hook 渲染层。ddh 已经有一套经过实机验证的
“引擎帧”通道（`CBackdropFrame` + `CTextFrame`，默认 MasterFont，坐标是 WC3 的
0.8×0.6 UI 空间），阵亡总结面板、承伤图表、单位头像都是这么画的。加一个按钮直接复用它：

| 项 | KK | 我们（ddh v28） |
| --- | --- | --- |
| 绘制 | ImGui + OpenGL/D3D9 覆盖层 | 引擎 `CBackdropFrame` + `CTextFrame` |
| 输入 | `imgui_impl_win32` 子类化窗口过程 | 已有的 `DdhGameWndProc` 命中测试（和面板同一套） |
| 位置 | 平台算 | 左上菜单栏下方，UI 坐标 `(0.008, -0.040)`，`0.064 × 0.021` |
| 显示条件 | 一直 | **只在进图后**（能读到地图名）；主菜单/载入不显示 |
| 点击 | 平台业务 | 唤出/收起“阵亡总结”（复用 `~` 的 `DdhDoToggleVisible()`） |
| 关闭 | — | 环境变量 `DDH_NO_BUTTON=1` |

实现位置（`_test/hook/ddh.cpp`，v28）：

- `DdhButtonEnsure()`：建帧/贴图/字体/SetPoint，跟着当前 `CGameUI` 走（换图自动重建，
  主菜单↔游戏来回切只做显隐、不重建，避免漏帧）；
- `DdhButtonHitTest()` / `DdhButtonClick()`：命中优先用帧实际矩形（`layout+0x174..0x180`），
  读不到时按归一化坐标兜底；
- 窗口过程：`WM_LBUTTONDOWN/UP/DBLCLK` 先判按钮（按下变白、松手恢复金色），命中就吞掉，
  不会顺手选中地面；
- `DdhPanelTick()` 每 500ms 调一次 `DdhButtonEnsure()`（热键线程投递，始终在游戏线程动帧）；
- 没有结算数据时点按钮：面板弹一条“本局还没有阵亡记录”，4 秒后自动消失。

---

## 5. 未完成 / 边界

1. **没有把 KK 的“按钮创建点”逐条逆出来**（ImGui::Button 调用、每个按钮的 label/图标
   资源、点击后的业务分支）。原因：字符串是 `{fmt}` 表访问，`rea xrefs` 无引用；
   `War3Plugin.dll` 2.6MB，全量函数级追踪成本高。
   已足够支撑“架构层面的模仿”，但**不足以逐个复刻它的视觉**。
2. 商城/设置的具体文案不在 DLL 里（没有 UTF-8/UTF-16/GBK 的“商城/设置”），
   推测是平台下发的数据/图片（未验证）。
3. 我们的按钮是**游戏内帧**，理论上会被“隐藏界面”（`DzFrameHideInterface` 之类）或
   某些改 UI 的地图影响；KK 的覆盖层不受影响。这在实战里是否出现，需要实机看。
4. 实机验证还没做（本文实现只过了编译）：见 `README.md` §1.2 的验证步骤。

---

## 6. 复现用脚本

`_analysis/` 下（都是只读分析，不改目标）：

| 脚本 | 用途 |
| --- | --- |
| `pe_probe.py` | PE 节表/入口/导出、字符串 VA、capstone 线性 xref 扫描 |
| `pe_imports.py` | 导入表按 DLL 分组（本项目用来确认 OPENGL32 导入） |
| `ptr_scan.py` | 找指向某 VA 的 32 位指针并打印上下文 dword |
| `scan_words.py` | 按 UTF-8 / UTF-16LE / GBK 扫中文标签 |
| `mpq_list.py` / `mpq_extract.py` | 看平台 patch MPQ 里有没有自定义 FDF/BLP（结论：`Patch127.mpq` 是暴雪 1.27 官方补丁，不是 KK 的 UI） |
| `war3plugin.snap` | REA/Ghidra 分析快照（`rea function ... --snapshot` 复用它，省 4 分钟导入） |
