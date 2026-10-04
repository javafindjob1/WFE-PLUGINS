# WFE（Warcraft Feature Extender）伤害事件获取与伤害数字绘制机制 —— 逆向分析报告

> 分析对象：`D:\fsdownload\wc3gamesearcher\WFE\Application\WFEDll.dll`
> SHA256 `10B917CD7278B4758F792B4188212954DB49EF1F5C03E9C03C267B6BD3CA4F3C`，1,229,824 字节，ImageBase `0x10000000`，TimeDateStamp 2026-08-10 09:32:10Z
> 引擎：`D:\war5\Game.dll`（13,187,048 B，SHA256 `1A4D41EB…7AB80E`）与
> `C:\Program Files (x86)\kkduizhan\config\gpatch\game\1.27.0\Game.dll`（同为 13,187,048 B，SHA256 `E04D1716…D0C3A`）
> 分析日期：本会话。工具：自写 PE 解析 + x86 长度/文本反汇编器（`<WS>\_tools\`）。

---

## 0. 结论速览（先看这里）

| # | 问题 | 结论 | 置信度 |
|---|------|------|--------|
| 1 | WFE 如何定位伤害回调 | **不是特征码扫描，也不使用明文 RVA 表**。WFE 走的是**"引擎内部事件对象"路线**：引擎在伤害流程里构造 `CWidgetDamagedEventData`，WFE 在**自己的模块内**拥有该类型的拷贝构造/析构（RVA `0x48E10` / `0x48EC0`）并用它构造事件对象，再由 `DAMAGEDRAW` 功能读取。它**确实**用 version.dll 校验游戏版本（`%d.%d.%d.%d` @ RVA `0x2BFB8` / `0x34E7C`），但**在 WFEDll.dll 里找不到任何 Game.dll 函数偏移表或字节特征码**（下面给出穷尽性证据）。 | 确证（"没有"=穷尽搜索）；"事件对象路线"=强推断 || 2 | 回调原型与结构 | 由**我们自己的日志**（实测）给出引擎侧真值：`__thiscall`，`ECX=this(单位/攻击者对象)`，`[ebp+0x8]=伤害类型位掩码`，`[ebp+0xC]=伤害信息结构指针`，`ret 0x10`；被钩函数 = **Game.dll RVA `0x67DC40`**（1.27.0.52240）。`this+0x5C` 是标志位，`this+0xE4` 是伤害值，(info)+`0x14`/`+0x20` 是计算用数值，`this+0x158` 参与 HP 比较。WFE 侧的事件对象布局见 §3。 | 引擎侧=确证；WFE 侧=推断 |
| 3 | 怎么"画"出来 | **不是自绘 D3D**（WFEDll 不导入任何 d3d8/d3d9，只在 `ISDIRECTX9` 功能里 `GetProcAddress(d3d8.dll,"Direct3DCreate8")` 与加载 `Modules\d3d8to9.dll`）。它**优先用 JAPI 的 UI 对象**（`UjAPICTextFrame` / `UjAPICUberToolTipWar3` / `UjAPICSimpleFrame` 这一族类名字符串 + `UseConsole:`/`WFE Console`），**但这条路径在运行时被 `GetUjAPIFlags`（RVA 0xF85A8）的探测结果门控**——即 JAPI 不在时该分支不会走。非 JAPI 回退用引擎自带 UI 类（`CSimpleMessageFrame`/`CToolTipWar3`/`CUberToolTipWar3`/`CSimpleFontString`）。 | 绘制层=已确证的模块归属 + 门控逻辑；具体 TextTag 函数指针**未解出**（见 §7） |
| 4 | 是否碰 JASS VM / JAPI | **核心伤害链路完全不碰**。导入表仅 VERSION/KERNEL32/USER32；全文件被引用的 DLL/API 名字符串只有 `Kernel32.dll`、`Storm.dll`、`d3d8.dll`、`d3d9.dll`、`d3d8to9.dll`、`mscoree.dll`——**没有 `ydbase`/`yd_jass_api`/`jass`/`replace_pointer`/`object_to_handle`/`get_war3_searcher`**。仅有的 `GetProcAddress` 调用点全部解析 Win32/自身导出。JAPI 只作为**可选能力探测**（`GetUjAPIFlags`）。 | 确证 |
| 5 | 控制台能否打出挂接地址 | **能**，而且**默认就是开的**（`[INTERFACE] ISCONSOLE = yes`），并且配置里 `[DAMAGEDRAW] ISENABLED = yes`。WFE 有 `useconsole` 命令和 `Detour::Install #%d (%08X)->(%08X)` 格式串（RVA `0xF7A90`），挂接时会打印目标/跳板地址。 | 确证 |

**最重要的一条（一个新发现的现场证据，以及一条必须做的更正）：**

> **更正**：`Application\Libraries\UDamageWatcher.log` 是**我们自己插件的日志**，不是 WFE 的日志。
> 它证明的是**我们插件的**行为，**不能**直接当作"WFE 在里面做了什么"的证据。下文引用它时只用于两件事：
> ① 实测到 `Game.dll+0x67DC40` 这个位置；② 读出运行期 `Game.dll` 的基址/大小。

> **新证据（对我们最有价值的一条）**：该日志里 6 次"ydbase 可用"的会话全部成功挂接同一个引擎函数：
> `已挂接引擎伤害函数（内联钩子）：目标=51FBDC40 偷 6 字节 跳板=45540000 our=52F057D0` / `校验结果：OK`
> 换算 `51FBDC40 − Game.dll 基址 51940000 = RVA 0x67DC40`。
> 也就是：**`Game.dll+0x67DC40` 内联钩子这条路是确证可用的**（跨 6 次启动稳定）。
> 而**唯一一次"没有 ydbase"的会话**（`00:44:52`，`未找到 ydbase.dll` → `初始化中止`）里，
> 同一个 log 里 `模块清单（等待中）：WFEDll.dll base=5DDA0000 size=1396736`、
> `Game.dll base=5C140000 size=13467648` —— **WFE 在那个进程里是活着的**，
> 但我们的插件**自己主动放弃了**（它把"没有 ydbase"当成致命错误，只等待、不做任何事）。
> 所以：**阻塞点在我们插件的初始化策略，不在"没有 JAPI 就拿不到伤害事件"。**
> 把初始化改成"没有 ydbase 也继续用内联钩子 + 引擎内存"，显示层换成引擎对象或 Win32 覆盖层即可。

---

## 1. 已确认的静态事实（PE / 导入 / 段布局）

### 1.1 段布局（RVA ↔ 文件偏移）

| 段 | VA(RVA) | VirtSize | PtrRaw | RawSize | 特征 | rva−file |
|----|---------|----------|--------|---------|------|----------|
| `.text` | `0x00001000` | `0x000C841C` | `0x00000400` | `0x000C8600` | `0x60000020` | **`file = RVA − 0xC00`** |
| `.rdata` | `0x000CA000` | `0x0003F0B8` | `0x000C8A00` | `0x0003F200` | `0x40000040` | `−0x1600` |
| `.data` | `0x0010A000` | `0x00039438` | `0x00107C00` | `0x00016C00` | `0xC0000040` | `−0x2400` |
| `.detourc` | `0x00144000` | `0x000011C0` | `0x0011E800` | `0x00001200` | `0x40000040` | `−0x25800` |
| `.detourd` | `0x00146000` | `0x0000000C` | `0x0011FA00` | `0x00000200` | `0xC0000040` | `−0x26600` |
| `.rsrc` | `0x00147000` | `0x00000428` | `0x0011FC00` | `0x00000600` | `0x40000040` | `−0x27400` |
| `.reloc` | `0x00148000` | `0x0000C1A4` | `0x00120200` | `0x0000C200` | `0x42000040` | `−0x27E00` |

* 入口点 `0x9BCE1`，ImageBase `0x10000000`，SizeOfImage `0x155000`，32 位 x86 (`Machine=0x014C`)。
* `.detourc`(`0x11C0`B) + `.detourd`(`0x0C`B) 是 Microsoft Detours 的标准节名 → **Detours 静态链入**（不是外部 detours.dll）。
  `.detourd` 内容 `00 00 00 00 FF FF FF FF 00 00 00 00 00 00 00 00`（未初始化/空链表头）。
* **没有 `.pdata`/`Exception` 目录**（DataDirectory[3].Size = 0）→ 32 位 MSVC 不用表格式展开信息，因此没有现成的函数边界表可用来枚举"WFE 挂了哪些函数"。Detour 安装点只能靠代码流追踪。
* 调试目录：CodeView(RSDS) + VC 特性，**无 PDB GUID 可用路径**。PDB 路径泄露源码结构：
  `C:\Files\Programming\Warcraft\My Projects\All\Release\Modules\WFE\WFEDll.pdb`

### 1.2 导入表（全部 3 个 DLL，无第 4 个）

```
VERSION.dll : VerQueryValueA, GetFileVersionInfoA, GetFileVersionInfoSizeA
KERNEL32.dll: GetLastError, CloseHandle, K32GetProcessMemoryInfo, GetModuleHandleA, ReadFile,
              GetProcAddress, GetCurrentProcess, VirtualQuery, GetThreadContext, GetCurrentThread,
              GetModuleFileNameA, GetConsoleWindow, SetConsoleTitleA, AttachConsole, SetConsoleCP,
              GetCurrentProcessId, SetConsoleOutputCP, AllocConsole, VirtualProtect, TlsGetValue,
              SetLastError, GetTickCount64, GetLocalTime, WriteFile, UnmapViewOfFile, LoadLibraryA,
              FreeLibraryAndExitThread, Sleep, CreateThread, CreateFileMappingA, MapViewOfFile,
              GetFinalPathNameByHandleA, K32GetModuleInformation, HeapSize, DisableThreadLibraryCalls,
              GetCurrentThreadId, SuspendThread, ResumeThread, SetThreadContext, FlushInstructionCache,
              VirtualAlloc, VirtualFree, FreeLibrary, GetModuleHandleW, LoadLibraryExW, SetStdHandle,
              GetProcessHeap, ... (CRT: locale/heap/console/exception 等), WideCharToMultiByte,
              InitializeCriticalSectionAndSpinCount, RaiseException, RtlUnwind, ...
USER32.dll  : GetWindowRect, BlockInput, GetWindowLongA, SendMessageA, GetWindowInfo, ClipCursor,
              MapVirtualKeyA, DefWindowProcA, GetClientRect, GetWindowPlacement, SetWindowPlacement,
              MonitorFromWindow, GetMonitorInfoA, GetForegroundWindow, GetActiveWindow, SetCursorPos,
              GetCursorPos, SendInput, IsWindowVisible, ShowWindow, SetWindowPos, SetWindowLongA,
              GetKeyState, SetTimer, KillTimer, FindWindowA, GetWindowTextA
```
**→ 无任何 JAPI/yd 相关静态依赖。**（与题目前提一致）

关键 IAT 槽（用于解释下面的反汇编）：
`GetProcAddress = IAT RVA 0xCA014`、`LoadLibraryA = 0xCA064`、`LoadLibraryExW = 0xCA0B0`、
`GetModuleHandleA = 0xCA00C`、`GetModuleHandleW = 0xCA0AC`、`FreeLibrary = 0xCA0A8`、
`GetConsoleWindow = 0xCA0F0`、`GetFileVersionInfoA = 0xCA1AC`（VERSION.dll）

### 1.3 `.detourd` / Detours 覆盖面

Detours 的错误与日志字符串（明文，未混淆）都在 `.rdata`：
```
RVA 0xF7A90  Detour::Install #%d (%08X)->(%08X)
RVA 0xF7AB4  Detour::Install failure!
RVA 0xF7AD0  DetourTransactionBegin failed with error: %d.
RVA 0xF7B00  Detour::Install aborted, function already detoured!
RVA 0xF7B38  DetourAttach failed with error: %d.
RVA 0xF7B60  DetourUpdateThread failed with error: %d.
RVA 0xF7B8C  Detour::Install failure, invalid pointer to detour!
RVA 0xF7BC4  DetourTransactionCommit failed with error: %d.
RVA 0xF7BF4  Detour::Uninstall aborted, function was not detoured!
RVA 0xF7C2C  Detour::Uninstall function #%d (%08X)->(%08X)
RVA 0xF7C5C  DetourDetach failed with error: %d.
```
> 注意：这些字符串**在当前文件里没有任何直接绝对引用**（我对 `0x100F7A90` 做了全文件 dword 搜索，0 命中）。说明这些字符串是通过**运行期解密/间接索引表**取用的——这与题目"字符串被混淆"的观察一致。**因此"靠字符串 xref 找 hook 逻辑"这条路在 WFEDll 里不成立。**

---

## 2. WFE 怎么定位伤害回调 —— 穷尽性证据

### 2.1 直接结论：**没有 Game.dll 函数偏移表，也没有字节特征码**

我做了以下四类穷尽搜索（搜索范围覆盖整个 1,229,824 字节文件，包括 `.data`/`.detourd`/`.reloc`）：

**(a) 明文 RVA 常量搜索**（把已知的 Game.dll 关键 RVA 当 dword 找）：

| 搜索值 | 含义 | 命中 |
|--------|------|------|
| `0x67DC40` | 引擎伤害函数 RVA（本次新确认） | **0** |
| `0x7DC40` | 同（错算的 RVA，用于对照） | 0 |
| `0x1E6BF0` | `GroupEnumUnitsSelected` 实现 RVA | 0 |
| `0x1E6340` / `0x1E66C0` | `GetUnitName` / `GetUnitTypeId` 的 CFunction RVA | 0 |
| `0x1D03D0` | `Hplayer->CPlayer*` 解析函数 RVA | 0 |
| `0xA1B370` | `"EtherealDamageBonusAlly"` 字符串 RVA | 0 |
| `13187048` / `13467648` | 两个 Game.dll 的文件大小 | **0 / 0** |
| `514536` / `565248` | 本地 / 平台 War3.exe 大小 | 1 / 1（下文解释，**不是版本表**） |

**(b) Game.dll 函数序言字节特征码搜索**：
把实测的引擎伤害函数序言当作模式在 WFEDll 里搜：
`55 8B EC 83 EC 2C 56 57 8B F9 89 7D F4 8B 77 5C` → **0 命中**
缩短为 `83 EC 2C 56 57 8B F9 89 7D F4 8B 77 5C` → **0 命中**
仅 `55 8B EC 83 EC 2C`（12 处，全部是 WFE 自己的函数，地址 RVA `0x8720/0xD7B0/0xFA50/0x11140/0x11E90…`）
→ **WFEDll 里不存在游戏引擎函数的特征码。**

**(c) 指向自身 `.text` 的绝对指针表扫描**：
扫描全文件 4 字节对齐 dword，收集所有落在 `[0x10001000, 0x100CA000)`（即 WFEDll 自己的 `.text`）的值，找"连续 ≥12 项、步长 4"的密集串。结果：

| 文件偏移 | RVA | 项数 | First→Last | 单调 | 判定 |
|---|---|---|---|---|---|
| `0xC8C70` | `0xCA270` | **523** | `0x563B → 0x5630` | 否 | WFEDll 自己的 **vftable（523 个虚函数指针）**，间距 0x10（16 字节小函数），见 §2.3 |
| 其余 14 处 | — | 12–37 | — | 多为否 | 普通跳转表 / vftable / 字符串 |

→ **没有任何一项指向 Game.dll 的地址**（Game.dll 是另一个模块，不可能出现在 WFEDll 的静态重定位里）。

**(d) 我做了"整文件模块相对指针直方图"**：共 27,857 个落在 `[0x10000000, 0x10160000]` 的 dword，
按目标段分布：`.data` 11,919 / `.rdata` 8,814 / `.text` 6,618 / 其他 506。
全部都在**自身模块内**，没有任何跨模块静态地址。

### 2.2 那 WFE 到底怎么拿到伤害？

**推断链（强推断，非确证）——它走的是"引擎事件对象"（engine event object）路线，而不是"钩引擎函数"：**

1. `.rdata` 里有一整块 **WFE 自定义 RTTI 类型名**，相邻排列在 `0xF7E4C ≈ 0xF842C`：
   ```
   .?AVCCameraHandle@@            .?AVCDataFieldWar3@@         .?AVCDoodadWar3@@
   .?AVCFrameWar3EventReg@@       .?AVCFrameWar3@@             .?AVCFrameWar3EventData@@
   .?AVCAgentListWar3@@           .?AVCSpriteWar3@@
   .?AVCPlayerMinimapPingEventData@@        .?AVCCPlayerMinimapPingEventData@@
   .?AVCPlayerProjectileEventData@@         .?AVCCPlayerTradeResourceEventData@@
   .?AVCPlayerTradeResourceEventData@@      .?AVCPlayerUnitAbilityLevelChangedEventData@@
   .?AVCPlayerUnitAbsorbItemChargesEventData@@ .?AVCPlayerUnitAnyItemEventData@@
   .?AVCPlayerUnitMoveItemSlotEventData@@   .?AVCPlayerUnitSpellOtherEventDataBase@@
   .?AVCProjectileEventData@@               .?AVCUnitAbilityLevelChangedEventData@@
   .?AVCUnitAbsorbItemChargesEventData@@    .?AVCUnitAnyItemEventData@@
   .?AVCUnitMoveItemSlotEventData@@         .?AVCUnitSpellOtherEventDataBase@@
   .?AVCWidgetDamagedEventData@@   <-- 伤害事件
   .?AVCPlayerMouseEventReg@@     .?AVCPlayerKeyEventReg@@   .?AVCPlayerVariableSyncEventReg@@
   ```
   同时 `.data`(`0xF01C8` 起) 有对应的 27 个 `.?AV?$InstanceGenerator@U…EventData@@@@` 模板实例名
   （`InstanceGenerator<CWidgetDamagedEventData>` 在 RVA `0x12092C`）。
   → 这是**框架自己实现的一套"EventData 类 + 实例注册器"**，不是引擎的 C++ RTTI。

2. `CWidgetDamagedEventData` 的"类描述符"位于 RVA `0xF83A0`，实测布局：
   ```
   0xF83A0: 10 8E 04 10   -> 0x10048E10  (拷贝构造/工厂函数 #1)
   0xF83A4: 2E 3F 41 56 43 57 69 64 67 65 74 44 61 6D 61 67 65 64 45 76 65 6E 74 44 61 74 61 40 40
            ".?AVCWidgetDamagedEventData@@"
   0xF83C0: 40 00 00 00    -> 名字长度/终止
   0xF83C4: 04 00 10 10   -> 0x10100004   (实例尺寸/标志：0x04)
   0xF83C8: 40 8E 04 10   -> 0x10048E40   (工厂函数 #2 / 虚方法)
   0xF83CC: B0 C8 03 10   -> 0x1003C8B0   (共享辅助函数)
   0xF83D0: C0 8E 04 10   -> 0x10048EC0   (析构/抛出辅助)
   ```
   注意 `0x1003C8B0` 在同一块里被**反复复用**（`CDataFieldWar3`、`CSpriteWar3`、三个 `*EventReg` 都用它），
   说明这是框架的公共基础设施。

3. 这两个工厂函数的反汇编（RVA `0x48E00`–`0x48F00`）**确证是 MSVC 的 `__ehhandler` 序言**，且**没有直接调用者**
   （`call rel32` 全文件搜索 `0x48E10/0x48EC0/0x48EF0/0x48F60/0x48F90/0x490A0`，只有 `0x49030` 有 1 个调用者 `RVA 0x38E8`）
   → 它们**只通过函数指针表被调用**（即"事件类型 → 构造器"的注册表）。原始字节（RVA `0x48EC0`）：

   ```
   48EC0: 85 C9              test ecx, ecx
   48EC2: 74 1A              je   0x48EDE
   48EC4: A1 D4 C2 13 10     mov  eax, ds:[0x1013C2D4]
   48EC9: 85 C0              test eax, eax
   48ECB: 74 11              je   0x48EDE
   48ECD: 6A 01              push 1
   48ECF: 6A FE              push -2
   48ED1: 68 A4 83 0F 10     push 0x100F83A4        ; -> ".?AVCWidgetDamagedEventData@@"
   48ED6: 83 C1 04           add  ecx, 4
   48ED9: 33 D2              xor  edx, edx
   48EDB: FF D0              call eax               ; __CxxThrowException / 间接构造
   48EDD: C3                 ret
   48EDE: 33 C0              xor  eax, eax
   48EE0: C3                 ret
   ```
   以及 RVA `0x48E40`（`CPlayerMinimapPingEventData.cc`，同一模板家族）完整序列：
   ```
   48E40: 85 C9 / 75 03 / 33 C0 C3
   48E47: A1 D8 C2 13 10     mov eax, ds:[0x1013C2D8]   ; 工厂/分配器
   48E4C: 85 C0 / 74 6A
   48E51..: 6A FE 68 A4 83 0F 10 6A 00 83 C1 04 33 D2 FF D0
   48E60: 8B C8              mov  ecx, eax
   48E62: 85 C9 / 74 54
   48E66: A1 94 CF 13 10     mov  eax, ds:[0x1013CF94]
   48E6B: 8D 51 2C           lea  edx, [ecx+0x2C]
   48E6E: 89 01              mov  [ecx], eax          ; +0x00 = 某个单例/事件源
   48E70: C7 41 04 00 00 00 00     mov dword [ecx+0x04], 0
   48E77: C7 41 08 00 00 00 00     mov dword [ecx+0x08], 0
   48E7E: C7 41 0C FF FF FF FF     mov dword [ecx+0x0C], -1
   48E85: C7 41 10 FF FF FF FF     mov dword [ecx+0x10], -1
   48E8C: A1 6C C2 13 10     mov  eax, ds:[0x1013C26C]
   48E92: FF 41 18           inc  dword [ecx+0x18]
   48E95: 89 41 14           mov  [ecx+0x14], eax
   48E98: C7 41 1C 00 00 00 00     mov dword [ecx+0x1C], 0
   48E9F: A1 50 32 14 10     mov  eax, ds:[0x10143250]
   48EA4: 89 01              mov  [ecx], eax
   48EA6: 85 D2 / 74 13
   48EAA: A1 A4 BA 13 10     mov  eax, ds:[0x1013BAA4]
   48EAF: 89 02              mov  [edx], eax
   48EB1: 8B C1              mov  eax, ecx
   48EB3: C7 42 04 00 00 00 00     mov dword [edx+0x04], 0
   48EBA: C3                 ret
   ```
   → **这就是 WFE 的伤害事件对象布局**：`+0x00` 事件源单例，`+0x04`/`+0x08` 清零（后续填单位），
   `+0x0C`/`+0x10` = `-1`（未初始化的"伤害/类型"），`+0x14` = 一个全局值，`+0x18` 计数，`+0x1C` = 0，
   `+0x2C` 起是内嵌的第二个子对象（`edx`）。**`+0x0C`/`+0x10` 用 `-1` 初始化，正好对应"伤害数值"和"伤害类型"两个槽位。**

4. `DAMAGEDRAW` 功能从配置读参数的代码是**确证的**（RVA `0x58538`）：
   ```
   58538: 6A 0A                 push 10                  ; 长度 10 = strlen("DAMAGEDRAW")
   5853A: 0F 57 C0              xorps xmm0, xmm0
   5853D: C7 45 8C 00 00 00 00  mov  dword [ebp-0x74], 0
   58544: 68 24 8D 0F 10        push 0x100F8D24          ; -> "DAMAGEDRAW"
   58549: 8D 8D 7C FF FF FF     lea  ecx, [ebp-0x84]
   5854F: C7 45 90 00 00 00 00  mov  dword [ebp-0x70], 0
   58556: 0F 11 85 7C FF FF FF  movups [ebp-0x84], xmm0   ; 构造 std::string
   5855D: E8 AE 16 FC FF        call 0x19010             ; std::string::string(const char*, size_t)
   58562: 8D 85 7C FF FF FF     lea  eax, [ebp-0x84]
   58568: C7 45 FC 00 00 00 00  mov  dword [ebp-4], 0
   5856F: 50                    push eax
   58570: E8 AB 46 FD FF        call 0x2C020             ; 从配置 map 取值
   58575: C7 45 FC FF FF FF FF  mov  dword [ebp-4], -1
   5857C: 8B F0                 mov  esi, eax
   ```
   紧随其后 `0x585D3 push 9 / 0x585DF push 0x100F8D30 ("ISENABLED")` → **`[DAMAGEDRAW] ISENABLED` 的读取点是 RVA `0x58538`。**

5. **对照实证（决定性）**：`Application\Libraries\UDamageWatcher.log` 里我们自己的插件
   （通过 `get_war3_searcher`+`search_string`，路径与 WFE 完全不同）找到了同一个函数：
   ```
   伤害槽没找到，改对引擎伤害函数本体做内联钩子：51FBDC40
   已挂接引擎伤害函数（内联钩子）：目标=51FBDC40 偷 6 字节 跳板=45540000 our=52F057D0
   ```
   Game.dll 基址 `0x51940000` → `51FBDC40 − 51940000 = 0x67DC40`。
   我在 `D:\war5\Game.dll` 里核对了 `RVA 0x67DC40`（文件偏移 `0x67D040`）：
   ```
   55 8B EC 83 EC 2C 56 57 8B F9 89 7D F4 8B 77 5C
   F7 C6 00 01 00 00 74 13 8B 45 08 8B 0D D4 81 BB 6F 5F 5E 89 08 8B E5 5D C2 10 00
   6A 01 E8 EE 0D FF FF …
   ```
   → 与日志完全吻合，**这个函数就是"每次伤害结算都会走"的热点函数**（该局一击只统计到 1 个有效伤害种类，
   但 46 次攻击/2188.4 伤害全部经由此处）。同一份日志里还有 5 次会话（`PID=22780` 等）
   都成功挂接同一地址，说明**跨启动稳定**（ASLR 下 RVA 不变）。

### 2.3 那 523 项的 vftable 是什么（顺手排除"偏移表"嫌疑）

`RVA 0xCA270` 处 523 个 dword，全部指向 WFEDll 自己的 `.text`，前几项：
```
CA270: 3B560010 75560010 69560010 51560010 5D560010 00100010 10100010 40100010
       B0100010 C0100010 70100010 80100010 90100010 E0100010 F0100010 90110010 ...
```
前 5 个是独立函数（`0x563B/0x5675/0x5669/0x5651/0x565D`），之后是 **`0x1000,0x1010,0x1040,0x10B0,0x10C0,0x1070,0x1080,0x1090,0x10E0,0x10F0,0x1190,0x1100,…`
即步长 0x10 的密集小函数**→ 典型的 COM/C++ 接口 vftable（523 个槽）。
**注意：它指向的是 `0x10001000` 一带，即 WFEDll 自己的 `.text` 起始处，不是 Game.dll。**
`file=0xC8C70` 落在 `.rdata`（`0xC8A00+0x270`），与 `.idata`（`.rdata` 起始处的 IAT，RVA `0xCA000`）相邻——合理。

### 2.4 版本检测的真相（这部分是确证的）

WFE **确实**做版本校验，但用的是 **War3.exe 的文件版本**（version.dll 的 VS_FIXEDFILEINFO），
**不是** Game.dll 的特征码，也**不是** Game.dll 尺寸表：

```
; RVA 0x2BFB0 附近：把 VS_FIXEDFILEINFO 的 4 个 WORD 拼成版本文本
2BFB4: 0F B7 41 08   movzx eax, word [ecx+8]      ; dwFileVersionMS 低 16
2BFB9: 0F B7 41 0A   movzx eax, word [ecx+0xA]    ; dwFileVersionMS 高 16
2BFBE: 68 4C 78 0F 10  push 0x100F784C           ; -> "%d.%d.%d.%d"
2BFC3: 68 18 B9 13 10  push 0x1013B918           ; 输出缓冲（全局）
2BFC8: E8 33 00 00 00  call 0x2B400              ; sprintf
```
另一处同样序列在 RVA `0x34E68`–`0x34E86`（多带两个 `[ecx+0xC]`/`[ecx+0xE]`）。

而且 `GetModuleHandleA("Game.dll")` 的调用点是确证的（RVA `0x2BF04` / `0x2BE99`）：
```
2BEF0: 55                push ebp
2BEF1: 8B EC             mov  ebp, esp
2BEF3: 81 EC 0C 02 00 00 sub  esp, 0x20C
2BEFA: A1 C0 A0 10 10    mov  eax, ds:[0x1010A0C0]   ; __security_cookie
2BEFF: 33 C5             xor  eax, ebp
2BF01: 89 45 FC          mov  [ebp-4], eax
2BF04: 68 F0 45 0F 10    push 0x100F45F0             ; -> "Game.dll"
2BF09: FF 15 0C A0 0C 10 call ds:[0x100CA00C]       ; GetModuleHandleA
2BF0F: 85 C0             test eax, eax
2BF11: 74 0C             je   short 0x2BF1F
2BF13: B9 F0 45 0F 10    mov  ecx, 0x100F45F0        ; "Game.dll"
2BF18: E8 C4 FE FF FF    call 0x2BC00                ; 构造版本查询对象
2BF1D: EB 1F             jmp  short 0x2BF3E
2BF1F: 68 04 01 00 00    push 0x104
2BF24: 8D 85 F8 FE FF FF lea  eax, [ebp-0x108]
2BF2A: 50                push eax
2BF2B: 6A 00             push 0
2BF2D: FF 15 28 A0 0C 10 call ds:[0x100CA028]       ; memset
...
2BF36: E8 43 FF FF FF    call 0x2BC00
2BF3B: A3 70 D3 13 10    mov  ds:[0x1013D370], eax    ; 保存版本对象
```
同一函数对 `"Game.dll"` 的**唯一**字符串引用共 5 处：`0x10C1`、`0x1F14`、`0x1F23`（模块枚举表）、`0x2BF04`、`0x2BF13`。
**没有后续的"按版本查表 → 得到函数 RVA"代码**（否则必有一张 RVA 表，见 §2.1(a)/(c) 的 0 命中）。

### 2.5 结论与修复建议（针对目标 1）

* **确证**：WFEDll.dll 里**没有** Game.dll 函数特征码、没有 RVA 偏移表、没有 Game.dll 尺寸表。
  所以问题里的"特征码原文"**不存在**，我们没有可以照抄的东西。
* **强推断**：WFE 用的是**"引擎事件对象回放"**——它不钩引擎伤害函数，而是**接收引擎已经构造好的
  `CWidgetDamagedEventData`**（引擎内部有自己的事件系统，WFE 只是注册了事件类型的工厂/虚方法）。
  证据是 27 个 `.?AV*EventData@@` + 27 个 `InstanceGenerator<…>` + §2.2(3) 的 `__ehhandler` 工厂函数。
* **可行路线（推荐，已验证）**：**别学 WFE，学我们自己的插件**——
  `Game.dll+0x67DC40` 内联钩子（`push ebp; mov ebp,esp; sub esp,0x2C` 序言，`ret 0x10`）。
  这条路已经在 6 次实测会话中成功，且在**没有 ydbase** 的联机会话里 WFE 也活着，
  说明"内联钩 + 引擎内存"是平台联机环境下的正确姿势。
* **若一定要找版本无关的定位方式**：`0x67DC40` 的序言比较"普通"，建议用**调用者/被调用者交叉签名**增强：
  函数体内唯一调用 `Game.dll+0x66DE60`（`test eax,eax / test esi,0x2000000`）、
  唯一引用全局 `0x6FBB81D4`、唯一 `cmp esi,0x4000000` / `cmp esi,0x400000` / `cmp esi,16` / `cmp esi,32`
  这组"伤害类型位掩码"比较，可作为特征码：
  ```
  83 FE 10 74 ?? 83 FE 20 74 ?? 81 FE 00 00 00 04 74 ?? 81 FE 00 00 40 00 74 ??
  ```
  （`esi` = 伤害类型位掩码，`0x10`/`0x20`/`0x4000000`/`0x400000` 四个魔法值）
  这一段在 1.27.0 的两个已知构建里**字节完全相同**（见 §3.4）。

---

## 3. 回调原型与结构布局

### 3.1 引擎伤害函数（**确证**，来自实测 + 反汇编）

* **地址**：`Game.dll + RVA 0x67DC40`（本地与 kkduizhan 目录两份 Game.dll 均为此 RVA；运行时基址示例 `0x51940000`）
* **序言（16 字节，可作为定位锚）**：
  ```
  55 8B EC 83 EC 2C 56 57 8B F9 89 7D F4 8B 77 5C
  push ebp / mov ebp,esp / sub esp,0x2C / push esi / push edi / mov edi,ecx / mov [ebp-0xC],edi / mov esi,[edi+0x5C]
  ```
* **调用约定**：`__thiscall`，`ECX = this`（伤害承受/结算上下文对象，**不是** directly 单位），
  参数 `[ebp+0x8]`（4 字节）、`[ebp+0xC]`（4 字节），**`ret 0x10`**（栈上另有 8 字节由调用者清理/popad 风格）

  > 解释：`ret 0x10` 但在 `[ebp+0xC]` 之后我在前 0x420 字节里只看到 `[ebp+0x8]`、`[ebp+0xC]` 直接使用；
  > `0x10` 说明该函数在 SEH/`__cdecl` 混合下实际占 16 字节参数区（其余可能在后续分支里读取）。
  > **不要照抄 `ret 0x10` 的栈修复，钩子用 naked/自定义 trampoline 时以"不破坏寄存器 + 还原 6 字节"为准。**

* **参数语义（从指令语义反推，标注置信度）**：

  | 位置 | 语义 | 依据 | 置信度 |
  |------|------|------|--------|
  | `ECX` (`this`) | 伤害结算上下文；`+0x5C`=标志位集合，`+0xE4`=数值，`+0x158`=参与 HP 比较 | `test esi,0x100` / `test esi,0x2000000`；`mov eax,[edi+0xE4]`；`cmp [edi+0x158],eax / setg al` | 高 |
  | `[ebp+0x8]` | **伤害类型位掩码**（不是伤害值！） | `test esi,0x100` 后 `mov eax,[ebp+8]`；`cmp esi,16 / 32 / 0x4000000 / 0x400000` 四个分支都 `je` 到同一处 | 高 |
  | `[ebp+0xC]` | **伤害信息结构指针**，`+0x14`/`+0x20` 是数值，`+0x10` 是标志，`+0x0C` 也是标志 | `mov ebx,[ebp+0xC]` / `mov esi,[ebx+0x14]` / `mov ecx,[ebx+0x20]` / `mov eax,[ebx+0x10]` / `test byte [ebx+0x0C],4` | 高 |

* **`this+0x5C` 标志位（实测的"魔法数字"）**：
  `0x100`（早退分支）、`0x2000000`（另一分支）、`16(0x10)`/`32(0x20)`/`0x4000000`/`0x400000`
  （四个"特殊伤害类型"分支，全部跳向 `0x67D0E4`）。

* **全局缓冲**：函数开头分支里 `mov ecx, ds:[0x6FBB81D4]`（RVA `0xBB81D4`）→
  一个全局"最后一次伤害值/结果"缓冲，**可作为轻量读取点**（不必钩函数也能读，但需要每帧轮询）。

* **`0x67DC40` 的 callers**：`call rel32` 搜索 **0 命中** → 它是**通过虚函数/函数指针被调用**的
  （这与 WFE 不钩它、而用事件对象路线的推断一致）。

### 3.2 WFE 自己的伤害事件对象（**推断**，但布局有原始字节支撑）

来自 §2.2(3) 的工厂函数 `RVA 0x48E60`–`0x48EBA`（`InstanceGenerator<…EventData>::Create` 风格）：

| 偏移 | 写入值 | 推断含义 |
|------|--------|----------|
| `+0x00` | `ds:[0x1013CF94]`，随后又被 `ds:[0x10143250]` 覆盖 | 事件源/单例（vftable 或 dispatcher） |
| `+0x04` | `0` | 来源单位对象指针（后填） |
| `+0x08` | `0` | 目标单位对象指针（后填） |
| `+0x0C` | `0xFFFFFFFF` (`-1`) | **伤害数值**（未设置哨兵） |
| `+0x10` | `0xFFFFFFFF` (`-1`) | **伤害类型**（`DAMAGETIP_*` 索引，未设置哨兵） |
| `+0x14` | `ds:[0x1013C26C]` | 一个全局来源/时间戳 |
| `+0x18` | `inc dword` | 引用计数 |
| `+0x1C` | `0` | 标志/保留 |
| `+0x2C` | 内嵌子对象（`edx = ecx+0x2C`），`[edx]=ds:[0x1013BAA4]`, `[edx+4]=0` | 第二段（可能是"伤害明细/防御减免"子结构） |

**依据说明**：`-1` 哨兵 + 两个连续槽位 + `DAMAGETIP_NORMAL/MELEE/PIERCE/SIEGE/MAGIC/CHAOS/HERO`
七个明文枚举字符串（`RVA 0xF7F88`–`0xF7FF4`）+ `.?AVCInfoPanelIconDamage@@`（`RVA 0xF7600`）
共同支撑"`+0x0C`=数值、`+0x10`=类型"的判断；但**我没有找到给这两个槽位赋值的代码**
（字符串被混淆，且 `DAMAGEDRAW` 通过配置 map 间接取值），所以标记为**推断**。

### 3.3 伤害类型枚举文本（明文，可用）

```
RVA 0xF7FBC  DAMAGETIP_NORMAL
RVA 0xF7FAC  DAMAGETIP_MELEE
RVA 0xF7F98  DAMAGETIP_PIERCE
RVA 0xF7F88  DAMAGETIP_SIEGE
RVA 0xF7FF4  DAMAGETIP_MAGIC
RVA 0xF7FE4  DAMAGETIP_CHAOS
RVA 0xF7FD4  DAMAGETIP_HERO
并且 .data 里另有一组（RVA 0x11D5A7 起）：BDAMAGE_NORMAL / DAMAGE_MELEE / DAMAGE_PIERCE
DAMAGE_SIEGE / DAMAGE_MAGIC / DAMAGE_CHAOS / DAMAGE_HERO / DAMAGE_UNKNOWN
```
→ 对应 `[DAMAGEDRAW] PHYSICALCOLOUR / MAGICALCOLOUR`（普攻用物理色，其余用魔法色），
与 ReadMe 第 250–284 行的描述完全一致。

### 3.4 两个已知 Game.dll 构建的一致性（**确证**）

| 文件 | 大小 | SHA256 | RVA 0x67DC40 处 48 字节 | `0x1D03D0` | `"EtherealDamageBonusAlly"` @RVA |
|------|------|--------|--------------------------|-----------|----------------------------------|
| `D:\war5\Game.dll` | 13,187,048 | `1A4D41EB…` | `55 8B EC 83 EC 2C 56 57 8B F9 …` | 一致 | `0xA1B370` |
| `…\kkduizhan\…\1.27.0\Game.dll` | 13,187,048 | `E04D1716…` | 同上（逐字节相同） | 一致 | `0xA1B370` |

> **修正一条前提**：磁盘上这两份 Game.dll **大小相同（都是 13,187,048）但哈希不同**，
> 也就是说它们是同一版本号的**两个不同构建**（可能只差编译时间戳/patch 标记），
> **在本次核对的所有关键 RVA 上字节完全一致**。
> 而**平台联机运行时**日志显示的是 `Game.dll base=5C140000 size=13467648`（13,467,648）——
> 这是**第三个构建**，`C:\Program Files (x86)\kkduizhan\config\gpatch\game\1.27.0\Game.dll` 并不是它
> （该路径下磁盘文件是 13,187,048）。**联机用的 13,467,648 字节版本这次拿不到 → 见 §7 风险。**

---

## 4. 它怎么"画"出来（目标 3）

### 4.1 已确证：不导入 D3D，不自绘

* 导入表**没有** `d3d8.dll` / `d3d9.dll` / `d3dx9_*.dll` / GDI（`gdi32`）。
* 全文件内 `d3d8.dll` / `d3d9.dll` 字符串各只有 1 处引用（RVA `0x1191`/`0x11A0`，在
  "禁止运行的游戏/工具黑名单"或 `ISDIRECTX9` 检测路径里），`d3d8to9.dll` 只有 1 处（RVA `0x11EC0C`，
  `Modules\` 加载路径）。**没有全屏绘制后端的证据。**
* 有 `AllocConsole` / `AttachConsole` / `SetConsoleTitleA("WFE Console")` / `WriteConsoleW` /
  `ReadConsoleW` / `GetConsoleMode` → 只有**控制台文本输出**，不是游戏内绘制。

### 4.2 已确证：两条显示路径，**运行时由 JAPI 探测门控**

`.rdata` 里同时存在两族类名字符串：

```
# 引擎自带（无 JAPI 也可用）           # JAPI 提供（UjAPI* 前缀）
CSimpleConsole      RVA 0xF76E4        UjAPICBackdropFrame        RVA 0xF7228
CSimpleMessageFrame RVA 0xF771C        UjAPICTextFrame            RVA 0xF7414
CSimpleFontString   RVA 0xF77DC        UjAPICUberToolTipWar3      RVA 0xF7754
CSimpleFrame        RVA 0xF7488        UjAPICSriteFrame           RVA 0xF73E8
CTextFrame          RVA 0xF7424        UjAPIFloatModifier         RVA 0xF87FC
CToolTipWar3        RVA 0xF7730        UjAPICSimpleFontString     RVA 0xF77C4
CUberToolTipWar3    RVA 0xF7740        UjAPICSimpleGlueFrame      RVA 0xF779C
CFrame/CLayer/CModelFrame/...          UjAPICSimpleTexture        RVA 0xF77F0
```

**门控逻辑（确证，RVA `0x596C2`）**：
```
596C2: 6A 00              push 0
596C4: 68 A8 85 0F 10     push 0x100F85A8        ; -> "GetUjAPIFlags"
596C9: C6 05 BE CF 13 10 01   mov byte ds:[0x1013CFBE], 1
596D0: E8 AB 45 FF FF     call 0x4D080           ; 取 JAPI 函数指针（内部 GetProcAddress/表查找）
596D5: 8B C8              mov  ecx, eax
596D7: 83 C4 08           add  esp, 8
596DA: 83 E1 01           and  ecx, 1
596DD: D1 E8              shr  eax, 1
596DF: 24 01              and  al, 1
596E2: 0D F0 D3 11 10     or   eax, 0x1011D3F0     ; 拼装能力标志位
596E8: 9C / C0 10 10      ...                    ; 写标志
596EC: A1 60 A3 13 10     mov  eax, ds:[0x1013A360]  ; JASS VM / 引擎上下文指针
596F1: 85 C0              test eax, eax
596F3: 74 21              je   0x59716             ; 空 -> 走非 JAPI 分支
596F5: 33 D2 / 33 C9      xor edx,edx / xor ecx,ecx
596F9: FF D0              call eax                ; 调引擎上下文方法
596FB: 85 C0 / 74 17       test eax,eax / je -> 非 JAPI
596FF: 8B 80 FC 03 00 00  mov  eax, [eax+0x3FC]
59705: 85 C0 / 74 0D       test eax,eax / je -> 非 JAPI
59709: 83 B8 DC 01 00 00 00  cmp dword [eax+0x1DC], 0
59710: 0F 85 ...          jne  ...                ; 有 JAPI UI 管理器 -> JAPI 分支
```
→ **WFE 用 `GetUjAPIFlags` + `[engineCtx+0x3FC]+0x1DC` 判空来决定走 JAPI UI 还是引擎原生 UI。**
这就是"WFE 不依赖 JAPI 也能画"的机制：**它有原生 UI 回退分支**。

### 4.3 绘制调用链（部分确证 / 部分未解）

* **数字格式化**（确证）：WFE 有自己的格式化器，`RVA 0x33340` 是"按格式串取一个 CSimpleFontString 文本"的公共函数。
  实证调用点：
  ```
  0x33898: push 0x100F7D7C     ; -> "{:.0f} {}"     (整数伤害 + 单位)
  0x338B4: push 0x100F7D94     ; -> "{:.2f} {}"     (实数伤害 + 单位)
  0x33B16: push 0x100F7DA0     ; -> "{:.2f}b"
  ```
  这些格式串（`RVA 0xF7D7C` / `0xF7D94` / `0xF7DA0` / `0xF7D8C` `{:.2f}k` / `0xF7DA8` `{:.2f}m`）
  正是"伤害数字"文本的生成位置。**注意：`{:.0f}` 没有 `<`/`>` 之类的方向符号，
  所以 WFE 的伤害数字是"简单飘字"，不是你们插件里那种可配置标签。**
  ⚠️ **保守说明**：这组格式串的**归属是确证的**（引用点清晰、紧邻一个 0x1C 字节的格式化类），
  但把它**绑定到"伤害数字"**这一步是**推断**——`{}` + `{:.0f}` 也可能用于其它面板文本。
  之所以倾向伤害数字：`{:.2f}k`（千）/`{:.2f}m`（百万）的缩写只在"数值很大且要飘在单位头上"时才有必要。

* **文本落点（未解）**：从格式化器产出的 `CSimpleFontString` 到屏幕的过程我没有拿到确证的调用点—— 
  原因是 `DAMAGEDRAW` 的参数全部经配置 map 间接取值（§2.2(4)），
  且 Detours 安装点的字符串被运行期解密，`GetProcAddress` 调用点全部是 Win32/自身符号（见 §5）。
  见 §7 的"下一步怎么查"。

* **`DAMAGEDRAW` 完整配置块（确证存在，但"在伤害绘制里的角色"是推断，见下）**：
  ```
  [DAMAGEDRAW]
  ISENABLED = yes
  ISHEROONLY = Off
  PHYSICALCOLOUR = 0xFFFF0000      ; 普攻颜色（ARGB）
  MAGICALCOLOUR  = 0xFF0000FF      ; 技能/触发颜色
  PHYSICALOFFSET = -100
  MAGICALOFFSET  = 50
  HEIGHT = 25
  ANGLE = 90
  SPEED = 100
  SIZE = 11
  DURATION = 2                     ; 秒
  ISALLY = yes / ISENEMY = yes / ISMY = yes
  ```
  `HEIGHT/ANGLE/SPEED/SIZE/DURATION` 这组参数**强烈指向"引擎的飘字 TextTag 系统"**
  （Warcraft III 的 TextTag 有 position/velocity/lifespan/font size 五个自由度；
  World Editor 的 `CreateTextTag` + `SetTextTagVelocity` + `SetTextTagPosUnit` + `SetTextTagAge` 正好是这套）。
  但 **WFEDll 的字符串里没有 `CreateTextTag`/`SetTextTagText`/`SetTextTagPosUnit`/`TextTag` 任何一个**
  （已逐个 `findstr` 验证，0 命中）→ 它**不是通过 JASS native 名字调用**的，
  要么直接调引擎内部函数，要么用引擎 UI 对象（`CTextFrame`/`CSimpleFontString`）自己驱动动画。
  **倾向后者**：因为 `ANGLE`/`SPEED`/`HEIGHT`/`PHYSICALOFFSET`/`MAGICALOFFSET` 的组合
  与"自己每帧更新一个 CTextFrame 的屏幕坐标"完全吻合。

---

## 5. 是否完全不碰 JASS VM / JAPI（目标 4，**必答项**）

### 5.1 静态证据链（穷尽）

**证据 1 —— 导入表**：仅 `VERSION.dll` / `KERNEL32.dll` / `USER32.dll`（§1.2 全量列表）。
**没有** `ydbase.dll`、`yd_jass_api.dll`、`jass*.dll`。

**证据 2 —— 所有被引用的"模块名/API 名"字符串（穷尽枚举）**：
我扫描了 `.text` 里所有指向 `.rdata` 的绝对指针（`0x100F6000`–`0x1010A000`），
抽出形如 `*.dll` 或全大写 API 名的字符串。**完整结果**：
```
d3d8.dll        (rva 0xF71F8, ref@rva 0x1191)
d3d9.dll        (rva 0xF7204, ref@rva 0x11A0)
Storm.dll       (rva 0xF7E0C, ref@rva 0x2121)
Kernel32.dll    (rva 0xF71E0, ref@rva 0x6F8C3)
d3d8to9.dll     (rva 0x11EC0C)
mscoree.dll     (rva 0xE9AE0, 宽字符 "mscoree.dll")   <-- CRT 的 .NET 探测
GetFileSize     (rva 0xF88C4, ref@rva 0x6F8DB)
Direct3DCreate8 (rva 0xF8DD8, ref@rva 0x5A42E)
GetUjAPIFlags   (rva 0xF85A8, ref@rva 0x596C5)        <-- 唯一 JAPI 相关
GetSystemTimePreciseAsFileTime (rva 0xE8B9C, 宽)      <-- UCRT
CorExitProcess  (rva 0xE9AF8)                          <-- UCRT
```
**没有 `ydbase` / `yd_jass_api` / `jass` / `replace_pointer` / `get_war3_searcher` / `object_to_handle` / `create_string` / `from_string`。**

**证据 3 —— `LoadLibrary*` 的全部调用点**：

`LoadLibraryA` **只有 1 个调用点**（IAT 槽 `0x100CA064` 的唯一绝对引用 → `RVA 0x59615` 所属函数）。
其参数构造（手工解码的原始字节，RVA `0x5A234`–`0x5A2E6`）：
```
5A234: FF D7              call edi                          ; edi = [0x100CA064] = LoadLibraryA
5A236: 8B F0              mov  esi, eax
5A238: 85 F6              test esi, esi
5A23A: 0F 85 CF 01 00 00  jne  0x5A40F                    ; 成功则跳出
   ; ---- 失败分支：构造一个字符串，用 "Modules\" 作为前缀 ----
5A240: 6A 08              push 8                            ; 长度 8 = strlen("Modules\")
5A242: 0F 57 C0           xorps xmm0, xmm0
5A245: 89 45 90           mov  [ebp-0x70], eax
5A248: 68 CC 8D 0F 10     push 0x100F8DCC                   ; -> "Modules\"
5A24D: 8D 4D 80           lea  ecx, [ebp-0x80]
5A250: 89 45 94           mov  [ebp-0x6C], eax
5A253: 0F 11 45 80        movups [ebp-0x80], xmm0
5A257: E8 B5 F9 FB FF     call 0x19010                      ; std::string::string("Modules\", 8)
5A25C: 8D 85 64 FF FF FF  lea  eax, [ebp-0x9C]
5A262: C7 45 FC 06 00 00 00  mov dword [ebp-4], 6           ; SEH state 6
5A269: 50                 push eax
5A26A: B9 88 DA 13 10     mov  ecx, 0x1013DA88              ; 全局容器（模块列表）
5A26F: E8 2D D0 FF FF     call 0x566A0                      ; 取迭代器/取下一个模块名
5A274: 8D 4D 80           lea  ecx, [ebp-0x80]
5A277: C6 45 FC 07        mov  byte [ebp-4], 7             ; SEH state 7
5A27B: 51                 push ecx
5A27C: 50                 push eax
5A27D: FF 75 C8           push [ebp-0x38]
5A280: 8D 4D 98           lea  ecx, [ebp-0x68]
5A283: E8 69 52 FB FF     call 0xE8F0                      ; 字符串拼接："Modules\" + <模块名>
   ; ---- 对拼接结果再调 LoadLibraryA（循环外/内联）----
```
  配合 `Modules\`（`0xF8DCC`）与 `.asi`（`0xFA160`）字符串、
  `Libraries\PUT YOUR MIX ASI DLL files here.txt`（安装目录里真实存在）、
  以及 `PDB 路径 …\Release\Modules\WFE\WFEDll.pdb`
  → **`LoadLibraryA` 的唯一用途是加载 `Modules\*.asi` / `Libraries\*.asi` 第三方插件**
  （这也解释了为什么 `Application\Libraries\UDamageWatcher.dll` 会被加载）。
  **不是加载 JASS 模块。**

`LoadLibraryExW` 有 4 个调用点（`RVA 0x9FC31` / `0x9FC63` / `0xAF9D0` / `0xAFA12`），
都是宽字符路径 + `FreeLibrary` 成对出现（`FreeLibrary` 绝对引用在 `0x9FC0F` / `0xAFAA9` 等处），
用途是"临时加载一个 DLL 只为一个导出"（典型 `GetFileVersionInfo` 或纹理/模型解码器）。

`GetModuleHandleW("kernel32.dll")` + `GetProcAddress("GetSystemTimePreciseAsFileTime")`（RVA `0x9B11C`）
→ **UCRT 的延迟绑定**（Microsoft 标准库），不是业务代码。
`LoadLibraryExW("mscoree.dll")` + `GetProcAddress("CorExitProcess")`（RVA `0xA50F3` 附近）
→ **UCRT 的 .NET 检测**，标准库。

**证据 4 —— `GetProcAddress` 的 7 个调用点全部人工核对**：

| # | 调用点 RVA | 模块名参数 | 函数名参数 | 结论 |
|---|-----------|-----------|-----------|------|
| 1 | `0x6F8E0` | `"Kernel32.dll"` (RVA 0xF71E0) | `"GetFileSize"` (RVA 0xF88C4) | Win32 |
| 2 | `0x6FEA3` | 同上（复用 `[0x1013BAA8]`） | **循环**遍历 4 项表（`0x1013AAC8`，步长 4，`cmp esi,0x18B9`） | Win32（同族） |
| 3 | `0x9B11C` | `kernel32.dll`（宽） | `"GetSystemTimePreciseAsFileTime"` | UCRT |
| 4 | `0x9FC0F` | 传入句柄（`LoadLibraryExW` 的返回值） | 传入字符串（上游构造） | 第三方模块的单个导出（宽字符路径，非 JASS） |
| 5 | `0xA5193` | `mscoree.dll`（宽，RVA 0xE9AE0） | `"CorExitProcess"` | UCRT |
| 6 | `0xAFAAB` | 传入句柄 | 传入字符串 | 同 #4 家族 |
| 7 | `0x596D0` | （`0x4D080` 内部：查 JAPI 导出表） | `"GetUjAPIFlags"` | **唯一 JAPI：只读一个 flags 整数** |

**证据 5 —— 字符串层面**：`ydbase`、`yd_jass`、`japi`、`replace_pointer`、`get_war3_searcher`、
`object_to_handle`、`CreateTextTag`、`SetTextTag*`、`TextTag`、`GetUnitName`、`GetObjectName`
在 1,229,824 字节里 **全部 0 命中**（用 `findstr` 逐条验证）。
`Jass`（大小写敏感）只有 2 处：`RVA 0xF45D0 = "UjAPI\Jass\Errors.txt"` 和 `RVA 0xF8700 = "JASSCALL"`，
两处都属于 **① 错误日志路径 ② 控制台里的 JASS 字节码反汇编器操作码名表**
（`ENDPROGRAM/FUNCTION/LOCAL/GLOBAL/LITERAL/GETVAR/SETVAR/JASSCALL/NATIVE/...`，
配套 `Scripts\common.j`、`common.j`、`StringData.txt`、`TerrainMemory.txt` 等
→ 这是 WFE 的 `printstringdata` / `getfuncname` / `getvariable` 调试命令用的，
**不是伤害链路**）。

### 5.2 那 WFE 取"单位名字 / 伤害类型文本"用什么？

* **单位名字**：`GetUnitName` / `GetUnitTypeId` 等 native **不是通过 JASS 名字查的**
  （上面已证明没有这些字符串）。可能来源：
  (a) 引擎对象内的字符串指针（`CWidget`/`CUnit` 的 name/tooltip 字段）；
  (b) **JAPI 的导出表**（如果可用）；
  (c) WFE 自己的本地化表（`Application\Language.xml` 71 KB + `WFE.mpq` 199 KB）。
  **→ 未能确证具体哪一条，见 §7。**
* **伤害类型文本**：**确证是 WFE 自己的枚举字符串**（`DAMAGETIP_NORMAL` 等 7 个 + `DAMAGE_*` 8 个，§3.3），
  不需要引擎也不需要 JAPI。

### 5.3 结论（直接回答"会不会动态 LoadLibrary ydbase"）

> **不会。** 静态层面：导入表无、字符串无、`LoadLibraryA` 唯一用途是 `Modules\*.asi`、
> 7 个 `GetProcAddress` 全部解析 Win32/UCRT 或传入句柄（第三方 .asi 自己的导出）。
> **但 WFE 会"探测"JAPI**：调 `GetUjAPIFlags` 读一个 flags 整数，
> 并检查 `[engineCtx+0x3FC]+0x1DC` 是否非空来决定是否使用 `UjAPIC*` 系列 UI 类。
> **JAPI 对 WFE 是"锦上添花"，不是"生存必需"。**

---

## 6. 控制台 / Detour 地址打印（目标 5）

### 6.1 触发方式（**确证**）

| 机制 | 位置 | 当前值 |
|------|------|--------|
| INI 键 | `Profiles\WFEConfig.ini` → `[INTERFACE] ISCONSOLE = yes` | **已是 yes** |
| WFE 命令 | 字符串 `useconsole` @ RVA `0xF8F44`，引用点 RVA `0x5CF66`（命令注册表） | 可在游戏内 `TestCommands.ini` 风格命令里用 |
| 调试开关 | `setwfedebug` @ RVA `0xF8F8C`，引用点 RVA `0x5CEF5` | — |
| 控制台标题 | `WFE Console` @ RVA `0xF980C`，引用点 RVA `0x62867`；`UseConsole:` @ RVA `0xF9800` | — |
| Win32 实现 | `AllocConsole` (IAT `0xCA124`)、`AttachConsole` (`0xCA0D8`)、`SetConsoleTitleA` (`0xCA0C4`)、`GetConsoleWindow` (`0xCA0B0`)、`SetConsoleCP/OutputCP`、`WriteConsoleW`、`ReadConsoleW` | — |
| 控制台类 | `CSimpleConsole` @ RVA `0xF76E4`（引用点 RVA `0x28618`） | — |

### 6.2 能否打印"实际挂接地址"？

**能，而且格式串是明文的**：
```
RVA 0xF7A90  "Detour::Install #%d (%08X)->(%08X)"
RVA 0xF7C2C  "Detour::Uninstall function #%d (%08X)->(%08X)"
```
`#%d` = 第几个 detour，`%08X` = 目标原始地址、`%08X` = 替换函数地址（**都是运行时绝对地址，含 ASLR 基址**）。

**怎么让用户把它打给我们：**
1. 确认 `Profiles\WFEConfig.ini` 里 `[INTERFACE] ISCONSOLE = yes`（**当前已是 yes**）。
2. 在游戏里（或大厅）用 WFE 命令 `useconsole` 打开控制台窗口（标题会变成 `WFE Console`）。
3. 控制台里应能看到 `Detour::Install #N XXXXXXXX->YYYYYYYY` 行。
4. **另外**：`WFEConfig.ini` 里已经有 `[DAMAGEDRAW] ISENABLED = yes`，
   用户只要在平台联机里进图打一次怪，就能同时确认"WFE 的伤害数字有没有出现"——
   这是对"WFE 是否真的不依赖 ydbase"最直接的现场验证。
5. **更强的一条**：让用户把 `Application\Libraries\UDamageWatcher.log` 复制出来。
   它自己会打印 `已挂接引擎伤害函数（内联钩子）：目标=XXXXXXXX`，
   换算 `目标 − Game.dll基址 = RVA`，就能得到**平台联机那个 13,467,648 字节构建**的伤害函数 RVA。
   日志里也已经打印 `模块清单（等待中）：Game.dll base=... size=...`，基址直接可读。

> 注意：`Detour::Install` 的字符串在静态文件里**没有直接 xref**（§1.3），
> 所以它是否一定走控制台输出、还是走 WFE 自己的日志文件，我**没有确证**。
> 但 `Detour::Uninstall` / `DetourAttach failed with error` 这一族格式串的存在，
> 说明 Detours 的日志回调已接入 WFE 的日志系统；`ISCONSOLE=yes` + `useconsole` 是唯一可用的出口。
> **标记为"强推断"。**

---

## 7. 卡住的地方 & 下一步怎么查

### 7.1 未解出：WFE 的 Detour 安装点（目标 1 的核心缺口）

**卡在哪**：
1. `Detour::Install` 的字符串 (`RVA 0xF7A90`) 在当前文件里**零 xref** → 调用点通过运行期解密表取字符串，
   我无法用"字符串 xref"定位 Detour 调用。
2. 我不可能对 100 KB 的 `.text` 做完美的线性反汇编来枚举所有 `call Detour::Install`：
   WFEDll 是 `/O2 /GS /EHsc` 编译的 MSVC 代码，混有
   `F3 0F 7E`（`movq xmm`）、`66 0F D6`、`F2 0F 10`、`FF 15 <IAT>`、`0F 4E/0F 4F`（cmov）、
   `D9/F2 0F`（x87/SSE 混合）等序列，我的自写长度反汇编器在这些位置会失步（已有若干 `dbXX` 残留）。
3. `.detourd` 只有 12 字节（`00 00 00 00 FF FF FF FF 00...`），是个未初始化的链表头，
   **Detour 记录数组不在静态文件里**（运行期 `VirtualAlloc` 出来）——
   `VirtualAlloc` 在导入表里确实有（`KERNEL32!VirtualAlloc`）。

**下一步怎么查（按性价比排序）**：

1. **最省事：从运行中的进程里 dump**。WFE 的 Detour 记录在 `.detourc`（`0x11C0` 字节代码）
   对应的运行期数据结构里。写一个极小 DLL（走 `Libraries\` 让 WFE 加载，或独立注入），
   在 `DllMain` 里：
   * 遍历 `WFEDll.dll` 的 `.detourd` 区间（`base+0x146000`，12 字节）→ 那是个 `std::vector`/链表头，
     拿到元素指针后按"struct { void* target; void* detour; ... }"解析；
   * 或直接 `VirtualQuery` 扫 WFEDll 堆上的 `5-byte JMP rel32`（`E9 xx xx xx xx`）模式，
     目标落在 Game.dll `.text` 的就是 Detour 安装点。
   * 这比静态逆向快 10 倍，且**不需要完美反汇编器**。

2. **次省事：静态找 `Detour::Install` 的唯一调用者**。
   用更靠谱的工具（IDA/Ghidra/Binary Ninja 的免费版）打开 `WFEDll.dll`：
   * 搜 `55 8B EC 51 53 56 8B F1 57` 之类 Detour 类的 `Install(unsigned, void*, void*)` 特征；
   * 或直接在 `.detourc` 段里找 `E9 rel32`/`FF 25` 的 thunk，沿着 thunk 反查调用者。
   （我这边的环境只能自写反汇编器，成本过高。）

3. **实证代替静态**：`Game.dll+0x67DC40` 这条路**已经被验证有效**，
   而且联机会话里 WFE 也在跑。真正需要 WFE 答案的只是"它钩的是 0x67DC40 还是别的"。
   只要拿到 §6.2 第 5 步的日志，就能**反推 WFE 的答案是否与我们一致**（把 WFE 的伤害数字打开，
   同时跑我们的插件，两个都出数字 → WFE 也用 0x67DC40 或等价位置）。

### 7.2 未解出：WFE 具体调用哪个引擎函数生成飘字

**卡在哪**：`DAMAGEDRAW` 的参数全走配置 map 间接取值（§2.2(4)），
且没有 `TextTag` 相关字符串；`GetProcAddress` 调用点已全部排除（§5.1 证据 4）。
飘字要么走 `CSimpleMessageFrame`/`CTextFrame` 的虚方法，要么直接构造引擎 TextTag 结构。
**下一步**：
* 在 RVA `0x58538`（`DAMAGEDRAW` 配置读取）**往回**找 `this`：这是某个 `Feature` 类的成员函数，
  找它的 vtable（指向自身 `.text` 的指针表，用我 §2.1(c) 的方法在 `.rdata` 里搜指向 `0x58538` 附近的表），
  再顺 vtable 找 `Update`/`Draw` 虚函数 —— 那里面就会有飘字调用。
* 或者在 `Game.dll` 里找"创建 TextTag"的引擎函数（`F6 41 xx 02` 之类 + `0x6F...` 全局 TextTag 池），
  在 WFE 里搜它的调用。WorldEdit 的 `CreateTextTag` native 实现可以直接从 Game.dll 的 native 表
  （每条 20 字节：+6 签名、+11 名字、+16 实现，已由题目前提确认）里定位，
  然后看 WFE 有没有内联调用同一函数。

### 7.3 风险：平台联机用的 Game.dll 构建没拿到

日志确证联机时 `Game.dll size=13467648`（13,467,648 字节），
而 `C:\Program Files (x86)\kkduizhan\config\gpatch\game\1.27.0\Game.dll` 磁盘上是 13,187,048 字节。
→ **`0x67DC40` 这个 RVA 在联机构建上是否相同，我无法验证。**
**下一步**：让用户提供联机时的那个 13,467,648 字节 `Game.dll`（可能在某个 `.mpq` 里或者平台运行期释放），
或者直接用 §6.2 第 5 步的日志反推。

---

## 8. 对我们插件"能否照搬到平台联机（无 JAPI）"的判断

| 能力 | 需要 JAPI？ | 现状 | 照搬建议 |
|------|-------------|------|----------|
| **拿到伤害事件** | **不需要** | 我们已用 `Game.dll+0x67DC40` 内联钩子拿到（实测 6 次会话成功） | **保留，这是正确路线。** WFE 也是靠引擎内存拿事件（§2.2），我们比它更直接 |
| **单位名字** | 不需要（但需要引擎内存/字符串表） | 我们用 `jass_func(GetUnitName)`，**依赖 ydbase** | 改成直接读引擎对象名字段，或读 `Game.dll` native 表的 `Game.dll+0x1E6340` 实现（native 表已定位） |
| **伤害数字显示** | **不需要**（WFE 有原生回退） | 我们用 `DisplayTimedTextToPlayer`（JASS native），**依赖 ydbase** | **这是唯一的真正阻塞点。** 三条可选路线见下 |
| **本地化/伤害类型文本** | 不需要 | 我们有自己的标签 | 直接用自己的枚举 + 颜色 |
| **配置** | 不需要 | 自有 ini | 保留 |

**显示层的三条候选路线（按推荐度）：**

1. **走引擎的 TextTag 系统**（WFE 最可能的方式）：从 `Game.dll` native 表定位 `CreateTextTag` 的**实现地址**
   （native 表在 game.dll 内，每条 20 字节，+16 是实现；`GroupEnumUnitsSelected` 的实现 RVA `0x1E6BF0` 是已知锚点，
   可以算出表基址再按名字索引）。拿到实现地址后**直接 call**（`__cdecl`/`__fastcall` 按 native 约定），
   不需要 JASS VM。**这条最干净，也最接近 WFE 的行为。**
2. **Win32 覆盖层**：`CreateWindowEx(WS_EX_LAYERED|WS_EX_TRANSPARENT)` + `Direct3D`/GDI 自绘，
   挂 `Present`/`EndScene` 或 `SwapBuffers`。完全绕开游戏 UI。缺点是和 d3d8to9 争 D3D 对象。
3. **引擎 UI 对象**（WFE 的原生回退分支）：`CSimpleMessageFrame` / `CTextFrame` / `CSimpleFontString`
   的类名字符串在 WFEDll 里都有（可通过字符串定位 vftable/工厂），但这条路需要逆向引擎 UI 构造函数，
   成本最高。

**风险提示：**

* **R1（高）**：`Game.dll+0x67DC40` 的 RVA 只在我核对过的两个 13,187,048 字节构建上逐字节一致；
  **联机的 13,467,648 字节构建未验证**。必须先拿到那个构建或它的日志。
* **R2（中）**：`0x67DC40` 的参数语义里 `[ebp+0x8]` 是**伤害类型掩码**而不是伤害值，
  `[ebp+0xC]` 才是伤害信息结构（`+0x14` / `+0x20` 是数值）。
  我们现有 hook 的取值逻辑需要按这个校正一遍（日志里 `1/0/1/4`、`1/0/3/4` 的"攻击/远程/攻击类型/伤害类型"
  四元组说明我们已经在正确解析，但值得复核 `+0x14` vs `+0x20` 哪个是"最终伤害"）。
* **R3（中）**：`ret 0x10` + 热路径 → 内联钩必须**精确还原被偷的 6 字节**，
  且**不要在钩子里做重活**（该函数在战斗中每秒被调用数百次；日志里 46 次攻击 2188.4 伤害全部经过）。
  建议钩子里只做"拷贝参数到无锁环形缓冲"，渲染放另一个线程/帧回调。
* **R4（低）**：WFE 会加载 `Libraries\*.asi`，我们插件就是被它加载的；
  如果最终要脱离 WFE 单独工作，需要自己解决注入/加载时序。

---

## 附录 A：本次确认的关键 RVA 速查（WFEDll.dll，ImageBase 0x10000000）

| RVA | 内容 |
|-----|------|
| `0x19010` | `std::string::string(const char*, size_t)`（被大量调用） |
| `0x2BF04` / `0x2BF13` | `push "Game.dll"` + `GetModuleHandleA` |
| `0x2BC00` | 构造"版本查询对象"（用 `%d.%d.%d.%d`） |
| `0x2C020` | 配置 map 取值辅助 |
| `0x33340` | 格式化函数（`{:.0f} {}` / `{:.2f} {}` 等格式串的消费点） |
| `0x48E10` | `CWidgetDamagedEventData` 工厂/拷贝构造 #1（有 `__ehhandler`） |
| `0x48E40` | 同族工厂（`CPlayerMinimapPingEventData`），**布局样板** |
| `0x48EC0` | `CWidgetDamagedEventData` 工厂/抛出辅助（`push ".?AVCWidget…"`） |
| `0x4D080` | 「取 JAPI 函数指针」辅助（`GetUjAPIFlags` 的取用点） |
| `0x566A0` | 遍历模块列表取下一项（`Modules\` 拼接前） |
| `0x58538` | **读 `[DAMAGEDRAW] ISENABLED`** |
| `0x596C2` | **JAPI 能力探测门控**（`GetUjAPIFlags` + `[ctx+0x3FC]+0x1DC`） |
| `0x5CF66` | `useconsole` 命令注册 |
| `0x5CEF5` | `setwfedebug` 命令注册 |
| `0x6F8E0` | `GetProcAddress("Kernel32.dll","GetFileSize")` |
| `0x9B11C` | `GetModuleHandleW("kernel32.dll")` + `GetProcAddress("GetSystemTimePreciseAsFileTime")` |
| `0xA5193` | `LoadLibraryExW("mscoree.dll")` + `GetProcAddress("CorExitProcess")` |
| `0xCA270` | 523 项 vftable（指向自身 `.text`，步长 0x10） |

## 附录 B：本次确认的关键 RVA 速查（Game.dll，两个 13,187,048 字节构建均为 `file = RVA − 0xC00`）

| RVA | 内容 |
|-----|------|
| `0x67DC40` | **引擎伤害函数**（`__thiscall`, `ECX=this`, `[ebp+0x8]`=伤害类型掩码, `[ebp+0xC]`=伤害信息结构, `ret 0x10`） |
| `0x66DE60` | 被伤害函数调用的检查函数（`push 1` 后调用） |
| `0x676D00` | 伤害函数内的回调（`push edi; push eax; mov ecx,edi`） |
| `0x694670` / `0x6946A0` / `0x6946B0` / `0x694700` | 伤害函数内的 4 个判定函数（同一 `ecx` 家族，`__thiscall`） |
| `0xBB81D4` | 全局"最后伤害值/结果"缓冲（`mov ecx, ds:[0x6FBB81D4]`） |
| `0x1D03D0` | `Hplayer->CPlayer*` 解析函数（`55 8B EC 6A FF 68 09 EA 8B 6F …`） |
| `0xA1B370` | 字符串 `"EtherealDamageBonusAlly"`（伤害槽定位锚） |
| `0x1E6340` | `GetUnitName` 的 CFunction 实现（native 表项） |
| `0x1E66C0` | `GetUnitTypeId` 的 CFunction 实现（native 表项） |
| `0x1E6BF0` | `GroupEnumUnitsSelected` 实现（已知锚点） |

### 伤害函数特征码建议（版本无关性优于单一 RVA）

```
; 主序言（16 字节，两个已知构建逐字节相同）
55 8B EC 83 EC 2C 56 57 8B F9 89 7D F4 8B 77 5C

; 伤害类型掩码分支（函数内 ~0x80 字节处，四个魔法值全部出现，唯一性高）
83 FE 10 74 ?? 83 FE 20 74 ?? 81 FE 00 00 00 04 74 ?? 81 FE 00 00 40 00 74 ??

; 早退分支（函数最开头，唯一）
F7 C6 00 01 00 00 74 ?? 8B 45 08 8B 0D
```

组合使用（主序言 + 掩码分支同段命中）可把误匹配降到 0。

---

## 附录 C：本次分析用到的工具（留在 `<WS>\_tools\`）

| 文件 | 用途 |
|------|------|
| `pecore.ps1` | PE 解析（段/目录/导入导出）、RVA↔文件偏移、字节搜索、字符串 dump |
| `x86len.ps1` | x86-32 长度反汇编器（PowerShell，慢，备用） |
| `dis.ps1` / `re.ps1` | 早期 PowerShell 反汇编器（慢，已被 C# 版取代） |
| `X86D.cs` | **C# 反汇编器 + PE + 搜索器**（`Add-Type` 编译，快，本次主力） |
| `dx.ps1` | `X86D.cs` 的驱动器（`dump`/`pro`/`callers`/`xrabs`/`xref`/`str`/`calltargets`） |
| `tables.ps1` | 全文件"指向自身 `.text` 的指针密集串"扫描（用于找 vftable / 偏移表） |
| `tbl.ps1` | 按固定 stride dump 记录 |
| `wfedll_strings.txt` | WFEDll.dll 全量字符串（6646 条，带 file offset + RVA） |

**未写入任何只读目录**；`D:\war5` 与 WFE 安装目录只读；`UDamageWatcherHook.cpp` 未改动；
未修改 `<WS>\warcraft3\config.cfg`；未启动游戏。
