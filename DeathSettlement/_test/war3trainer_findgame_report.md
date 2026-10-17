# War3Trainer.exe「怎么找到 / 校验魔兽进程」逆向报告

> 分析对象：`C:\3rd\war5-jass\jass_plugin\War3Trainer.exe`
> （62,952 字节，.NET 2.0 WinForms，`AssemblyName = War3Trainer, Version=1.0.0.0`，入口 `War3Trainer.Program::Main`）
> 性质：**只读逆向**。没有运行过该 exe，没有写过游戏内存。IL 全部由反射读取 `MethodBody.GetILAsByteArray()` 得到。
> 日期：本次会话

---

## 0. 材料与方法（可复现）

| 材料 | 说明 |
|---|---|
| `_tools\wt_il.txt` | 早先导出：`GameContext::GetGameOffset/GetGameAddress`、`War3Common::*`、`GameTrainer` 迭代器（**带原始字节 hex 列**） |
| `_tools\wt_il2.txt` | 早先导出：`GameContext::GetProcessInfo/GetModuleInfo/FindGameRunning` 等 + **全量字符串字面量索引** |
| `_tools\wt_introspect.ps1` / `.txt` | 早先导出：`War3Trainer.GameContext` 等类型的字段/方法签名清单 |
| **`_tools\wt_il3.ps1` / `_tools\wt_il3.txt`（本次新增）** | 把该程序集**全部 30 个类型、全部方法**的 IL 一次导出（8,815 行，UTF-8）。`FrmMain` 的 IL 原先没导出，本报告主要引用它 |
| **`_tools\wt_pinvoke.ps1` / `_tools\wt_pinvoke.txt`（本次新增）** | `NativeMethods` 的 DllImport 签名/CharSet/EntryPoint、程序集引用、入口点 |
| `选区内存定位2.md` §2 | 已有结论，本报告与其一致（版本表 13 行、`_moduleAddress = ProcessModule.BaseAddress`） |
| `DeathSettlement\Core\Wc3Game.cs` 等 | 我们自己的实现，用于第 3、4 节对比 |

复现命令（Windows PowerShell 5.1 即可，不需要 ILSpy）：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "_tools\wt_il3.ps1"  > "_tools\wt_il3.txt"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "_tools\wt_pinvoke.ps1"
```

下文的 `wt_il3.txt:NNNN` 一律指 `_tools\wt_il3.txt` 的**行号**（该文件每行一条 IL 指令，格式 `偏移: 助记符 操作数`）。

程序集引用（`wt_pinvoke.txt:13-17`）确认它是 **.NET 2.0** 程序（`mscorlib 2.0.0.0`、`System.Windows.Forms 2.0.0.0`、`System 2.0.0.0`、`System.Drawing 2.0.0.0`、`Microsoft.VisualBasic 8.0.0.0`），所以所有 BCL 行为按 .NET Framework 2.0 语义理解。

---

## 1. 结论摘要

1. **搜索入口是 `War3Trainer.FrmMain::FindGame()`**，它**不在定时器里**，也**不是上电自动触发**——它有两条触发路径：
   * 工具栏按钮「查找游戏」（`cmdScanGame.Click`）；
   * 窗体 `Load` 事件（`FrmMain_Load`）——**只有这一条算“上电自动触发”，且整个程序只跑一次**。
   * **全程序没有任何 `Timer` / `Tick` / 轮询线程 / `Process.HasExited` 检查。** 30 个类型里没有任何 timer 字段，也没有 `newobj System.Windows.Forms.Timer`。
2. **进程名只有两个字符串**：`"war3"` 和 `"dzwar3"`；模块名只有 `"game.dll"`。用的是 `System.Diagnostics.Process.GetProcessesByName(string)`，**不是** `GetProcesses()` 自己比名字。
3. **匹配方式**：比较 `Process.ProcessName`（BCL 语义：不含 `.exe`、大小写不敏感）→ 再进进程里按**模块基名**（`GetModuleBaseName`）比对 `ToLower() == "game.dll"`。**从不比较 `MainModule.FileName`**。
4. **进程→模块→版本**：`GameContext::.ctor` 依次调 `GetProcessInfo`（取 `Process.Id`）→ `GetModuleInfo`（用自己写的 `War3Trainer.WindowsApi.ProcessModule` 枚举模块取 `game.dll` 的 `BaseAddress` 和 `FileName`，用 `FileVersionInfo.FileVersion` 取版本，`.Replace(", ", ".")` 归一化）→ `GetGameAddress`（13 项版本字典 + `switch(13)`，未命中就 `throw UnkonwnGameVersionExpection`）→ `GetGameOffset`（第二次同样的 13 项字典 + `switch(13)`）。
5. **多进程**：**只取 `Process[0]`**，`war3` 有命中就**完全不试** `dzwar3`；`Process[0]` 失败也不会去试 `Process[1]`。换进程 = 必须用户再点一次「查找游戏」。
6. **`labGameScanState` 只在 6 个 `Report*` 方法里被赋值**（外加设计器初始化），而这 6 个方法全部只由「按按钮 / 点刷新 / 展开功能树」驱动。**游戏退出后它不会自动变回「游戏未运行」——那个「检测到游戏（PID x），游戏版本：y（支持）」会一直挂在那里，直到用户再点一次「查找游戏」。**
7. **失败路径**已逐条定位（见 §2.7）。特别地：**「请以管理员身份运行」跟 OpenProcess 无关**——它来自窗体 Load 时 `Process.EnterDebugMode()`（开启 SeDebugPrivilege）抛异常，且是 `catch {}` 全捕获，**不是** catch `Win32Exception`。
8. **“它找得到、我们会漏掉”的答案是：按“进程名”这一维度：不存在**（它的名单是我们的子集）。但在名字之后的链路上，有 **3 处真实的“它报成功、我们报失败/找不到”**（版本串来源、`File.Exists` 硬门槛、“找到了但没进图”算不算成功），另有 **1 处能力缺口**（陌生进程名的自动路径）。详见 §3、§4。

---

## 2. 逐条证据（IL 原文）

### 2.1 搜索入口：谁负责「查找游戏」

**入口方法：`War3Trainer.FrmMain::FindGame()`**（`wt_il3.txt:1167`）。

**触发路径 A —— 工具栏按钮**（`wt_il3.txt:2096-2102`）：

```
---- IL: War3Trainer.FrmMain::cmdScanGame_Click(Object sender, EventArgs e) ----
  maxstack=8 locals=
  0000: nop
  0001: ldarg.0
  0002: call         M:FrmMain::FindGame      ; ← 按钮只干这一件事
  0007: nop
  0008: ret
```

按钮的绑定在设计器里（`wt_il3.txt:3098-3109`）：

```
  0398: ldarg.0
  0399: ldfld        F:FrmMain::cmdScanGame
  039E: ldstr        "查找游戏"
  03A3: callvirt     M:ToolStripItem::set_Text
  03A8: nop
  03A9: ldarg.0
  03AA: ldfld        F:FrmMain::cmdScanGame
  03AF: ldarg.0
  03B0: ldftn        M:FrmMain::cmdScanGame_Click
  03B6: newobj       M:EventHandler::.ctor
  03BB: callvirt     M:ToolStripItem::add_Click   ; ← cmdScanGame.Click += cmdScanGame_Click
```

**触发路径 B —— 窗体 Load（唯一的“自动”路径，只跑一次）**（`wt_il3.txt:1146-1165`）：

```
---- IL: War3Trainer.FrmMain::FrmMain_Load(Object sender, EventArgs e) ----
  maxstack=1 locals=
  0000: nop
  0001: nop
  0002: call         M:Process::EnterDebugMode    ; try { Process.EnterDebugMode(); }
  0007: nop
  0008: nop
  0009: leave.s      IL_0016
  000B: pop                                        ; catch { }  ← 无类型过滤（Exception）
  000C: nop
  000D: ldarg.0
  000E: call         M:FrmMain::ReportEnterDebugFailure
  0013: nop
  0014: leave.s      IL_001E
  0016: nop
  0017: ldarg.0
  0018: call         M:FrmMain::FindGame           ; ← 自动查找，紧随其后
  001D: nop
  001E: nop
  001F: ret
```

Load 的绑定（`wt_il3.txt:3906-3910`）：

```
  0D37: ldftn        M:FrmMain::FrmMain_Load
  0D3D: newobj       M:EventHandler::.ctor
  0D42: call         M:Form::add_Load
```

**没有定时器 / 没有轮询线程**（否定证据）：

* `FrmMain` 的全部字段（`wt_il3.txt:19-45`）里没有任何 `Timer`/`Thread`/`BackgroundWorker` 字段，只有 `labGameScanState`、`cmdScanGame`、`viewFunctions` 等控件 + `_currentGameContext` + `_mainTrainer`。
* 全类型清单（`wt_il3.txt:5-172`）30 个类型中没有 `System.Windows.Forms.Timer` 相关字段。
* 对整份 IL 做 `Timer|Tick|Interval|Elapsed|Thread|WaitFor` 检索，只命中：
  * `ProcessAccessFlags::CreateThread`（枚举常量，`wt_il3.txt:154`）；
  * 迭代器状态机里的 `Thread::get_CurrentThread` / `<>l__initialThreadId`（`wt_il3.txt:4944-4947`、`5171-5173`、`5178-5181`、`5406-5408`）——那是 C# `yield return` 编译产物的线程亲和性检查，不是扫描线程。
* `Program::Main`（`wt_il3.txt:6865-6876`）只有 `EnableVisualStyles` / `SetCompatibleTextRenderingDefault` / `new FrmMain()` / `Application.Run`：

```
---- IL: War3Trainer.Program::Main() ----
  0001: call         M:Application::EnableVisualStyles
  0008: call         M:Application::SetCompatibleTextRenderingDefault
  000E: newobj       M:FrmMain::.ctor
  0013: call         M:Application::Run
```

* 唯一可能“自动重复”的地方是 `GameTrainer::GetFunctionList` / `GetAddressList` 的 `yield return` 迭代器——那是**取数据**用的，不是查进程。

> **结论**：`FindGame` 只由「按钮」和「窗体 Load」触发，**没有任何 `Timer`/`Tick`/循环**。

---

### 2.2 进程名列表：它拿哪些字符串去匹配

`FindGame` 正文（`wt_il3.txt:1167-1217`，只摘前段）：

```
---- IL: War3Trainer.FrmMain::FindGame() ----
  maxstack=3 locals=0:Boolean 1:UnkonwnGameVersionExpection 2:BadProcessIdException 3:Exception 4:Boolean
  0001: ldc.i4.0
  0002: stloc.0                                  ; bool success = false;
  0004: ldarg.0
  0005: ldstr        "war3"                      ; ← 字面量 #1
  000A: ldstr        "game.dll"                  ; ← 字面量 #2
  000F: call         M:GameContext::FindGameRunning
  0014: stfld        F:FrmMain::_currentGameContext
  0019: ldarg.0
  001A: ldfld        F:FrmMain::_currentGameContext
  001F: ldnull
  0020: ceq
  0022: ldc.i4.0
  0023: ceq
  0025: stloc.s      V4
  0027: ldloc.s      V4
  0029: brtrue.s     IL_0042                      ; if (_currentGameContext == null)
  002B: nop
  002C: ldarg.0
  002D: ldstr        "dzwar3"                    ; ← 字面量 #3（只在 war3 找不到时才用）
  0032: ldstr        "game.dll"                  ; ← 字面量 #2（复用）
  0037: call         M:GameContext::FindGameRunning
  003C: stfld        F:FrmMain::_currentGameContext
```

`FindGame` 里出现的 `ldstr` 全集（字符串索引 `wt_il3.txt:8733-8735` 与 `wt_il2.txt:1654-1656` 双重确认）：

| 出处 | 字面量 | 用途 |
|---|---|---|
| `FrmMain::FindGame` | `"war3"` | 进程名（第一优先） |
| `FrmMain::FindGame` | `"game.dll"` | **模块名**（不是进程名） |
| `FrmMain::FindGame` | `"dzwar3"` | 进程名（仅当 `war3` 命中数为 0 时才尝试） |

**用的是 `Process.GetProcessesByName`，不是 `GetProcesses()`**（`wt_il3.txt:4161-4189`，`wt_il2.txt:58-85`）：

```
---- IL: War3Trainer.GameContext::FindGameRunning(String processName, String moduleName) ----
  maxstack=2 locals=0:Process[] 1:GameContext 2:Boolean
  0001: ldarg.0
  0002: call         M:Process::GetProcessesByName    ; ← BCL：按进程名过滤
  0007: stloc.0                                        ; Process[] ps = Process.GetProcessesByName(processName);
  0008: ldloc.0
  0009: ldlen
  000A: conv.i4
  000B: ldc.i4.0
  000C: cgt                                            ; ps.Length > 0 ?
  000E: ldc.i4.0
  000F: ceq
  0011: stloc.2
  0012: ldloc.2
  0013: brtrue.s     IL_0022
  0015: nop
  0016: ldloc.0
  0017: ldc.i4.0
  0018: ldelem.ref                                     ; ps[0]   ← 注意：只取下标 0
  0019: ldarg.1
  001A: newobj       M:GameContext::.ctor              ; new GameContext(ps[0], moduleName)
  001F: stloc.1
  0020: br.s         IL_0026
  0022: ldnull
  0023: stloc.1                                         ; return null
  0024: br.s         IL_0026
  0026: ldloc.1
  0027: ret
```

> 注意：`ldarg.0` 在 IL 0001 处出现，是因为 `FindGameRunning` 是**实例方法**（`this` 就是 `GameContext` 类型的实例）；它并没有用到 `this`，所以用 `GameContext.FindGameRunning(...)` 也能调（签名 `GameContext FindGameRunning(String processName, String moduleName)` 见 `_tools\wt_introspect.txt:113`）。

> **“进程名字面量”只有 2 个字符串：`war3`、`dzwar3`。** 没有 `Warcraft III`、没有 `Frozen Throne`、没有 `war3.exe`。
> 另外全程序集里也没有任何 `GetProcesses()`（无参）调用——`GetProcessesByName` 是唯一入口。

---

### 2.3 匹配方式：比 `ProcessName` / 比文件路径 / 比模块

| 比什么 | 用了没有 | 证据 |
|---|---|---|
| `Process.ProcessName` | **用** | `wt_il3.txt:4165` `Process::GetProcessesByName`（BCL 内部就是比 `ProcessName`，含大小写不敏感、输入名带 `.exe` 会被剥掉） |
| `Process.MainModule.FileName` | **没用** | 全 IL 无 `Process::get_MainModule` 调用 |
| 进程里有没有某个模块 | **用** | `GameContext::GetModuleInfo` → `new ProcessModule(ProcessId, "game.dll")`（见 §2.4） |

模块匹配的细节在 `War3Trainer.WindowsApi.ProcessModule::.ctor(Int32 processId, String moduleNamePattern)`（`wt_il3.txt:8462-8559`，这是**自己写的类**，不是 `System.Diagnostics.ProcessModule`；字段见 `wt_il3.txt:167-170`：`ModuleHandle / BaseAddress / FileName`）：

```
---- IL: War3Trainer.WindowsApi.ProcessModule::.ctor(Int32 processId, String moduleNamePattern) ----
  maxstack=3 locals=0:SafeProcessHandle 1:IntPtr[] 2:IntPtr 3:String 4:Boolean 5:IntPtr[] 6:Int32
  0008: ldc.i4       2035711                    ; 0x1F0FFF = PROCESS_ALL_ACCESS
  000D: ldc.i4.0
  000E: ldarg.1
  000F: call         M:NativeMethods::OpenProcess
  0014: stloc.0                                  ; h = OpenProcess(ALL_ACCESS, false, pid);
  0017: callvirt     M:SafeHandle::get_IsInvalid
  001C: ldc.i4.0
  001D: ceq
  001F: stloc.s      V4
  0023: brtrue.s     IL_002C
  0025: ldarg.1
  0026: newobj       M:BadProcessIdException::.ctor   ; ← 打不开 → throw BadProcessIdException(pid)
  002B: throw
  002C: ldloc.0
  002D: call         M:ProcessModule::GetProcessModulesHandle
  0032: stloc.1                                  ; IntPtr[] mods = GetProcessModulesHandle(h);
  ...
  003C: ldloc.s      V5
  0040: ldelema      T:IntPtr
  0045: ldobj        T:IntPtr
  004A: stloc.2                                  ; foreach (IntPtr mh in mods)
  004C: ldloc.0
  004D: ldloc.2
  004E: call         M:ProcessModule::GetModuleName       ; GetModuleBaseName(h, mh, ...) → 基名
  0053: stloc.3
  0054: ldloc.3
  0055: callvirt     M:String::ToLower                    ; 左边 ToLower()
  005A: ldarg.2
  005B: callvirt     M:String::ToLower                    ; 右边 ToLower()
  0060: call         M:String::op_Equality                ; ==   ← 全等，不是 Contains
  0065: ldc.i4.0
  0066: ceq
  0068: stloc.s      V4
  006C: brtrue.s     IL_0092
  006E: nop
  006F: ldarg.0
  0070: ldloc.2
  0071: stfld        F:ProcessModule::ModuleHandle      ; 命中即填三个字段
  0076: ldarg.0
  0077: ldloc.0
  0078: ldloc.2
  0079: call         M:ProcessModule::GetModuleBaseAddress
  007E: stfld        F:ProcessModule::BaseAddress
  0083: ldarg.0
  0084: ldloc.0
  0085: ldloc.2
  0086: call         M:ProcessModule::GetModuleFileName  ; GetModuleFileNameEx → 全路径
  008B: stfld        F:ProcessModule::FileName
  0090: leave.s      IL_00C8                        ; 命中就结束循环
  ...
  00BD: ldstr        "Module not found"
  00C2: newobj       M:InvalidOperationException::.ctor   ; ← 遍历完没命中 → throw
  00C7: throw
```

要点：

* 名字取自 **`GetModuleBaseName`**（只有基名，如 `Game.dll`），不是 `GetModuleFileNameEx`；`GetModuleBaseName` 的 P/Invoke 是 `CharSet=Auto`（`wt_pinvoke.txt:9`），即走 `GetModuleBaseNameW`。
* 比较是 **`ToLower()` 之后 `String.op_Equality`（全等）**，所以：
  * **大小写不敏感**（两边都 `ToLower`）；
  * 后缀必须**正好是 `.dll`**，`game.dll`（对）vs `game.dll.bak` / `game_dll` / `Game.dll.exe`（都不对）；
  * 不含空格的名字也照样成立（`Warcraft III` 这种带空格的**进程名**它压根不试）。
* `GetModuleBaseName`/`GetModuleFileNameEx` 都用 **`new StringBuilder(256)`** 固定容量（`wt_il3.txt:8384`、`8412`），超过 256 字符的路径会被截断——这一点和我们的实现是同一量级，不构成差异。

**模块枚举的 64/32 位处理**（`wt_il3.txt:8291-8379`）：

```
---- IL: War3Trainer.WindowsApi.ProcessModule::GetProcessModulesHandle(SafeProcessHandle processHandle) ----
  0001: nop
  0002: ldarg.0
  0003: call         M:ProcessModule::GetProcessModulesHandle64     ; try { return ...64(...); }
  0008: stloc.0
  0009: leave.s      IL_0016
  000B: pop
  000C: nop
  000D: ldarg.0
  000E: call         M:ProcessModule::GetProcessModulesHandle32     ; catch { return ...32(...); }
```

`...Handle64`（`wt_il3.txt:8309-8344`）用 `EnumProcessModulesEx(h, buf, cb, out needed, 3)`，其中 `3 = LIST_MODULES_ALL`（常量见 `wt_il3.txt:145`）；**两次调用，第一次 `cb=0` 只为拿 `needed`**：

```
  000F: ldc.i4.3                                     ; LIST_MODULES_ALL
  0010: call         M:NativeMethods::EnumProcessModulesEx
  0015: pop                                          ; ← 返回值被丢弃！
  0016: ldloc.0
  0017: call         M:IntPtr::get_Size
  001C: div
  001D: newarr       T:IntPtr                        ; new IntPtr[needed / sizeof(IntPtr)]
  0023: ldarg.0
  0024: ldloc.1
  0025: ldloc.1
  0026: ldlen
  0027: conv.i4
  0028: call         M:IntPtr::get_Size
  002D: mul
  002E: ldloca.s     V0
  0030: ldc.i4.3
  0031: call         M:NativeMethods::EnumProcessModulesEx
  0036: pop                                          ; ← 返回值又被丢弃
```

`...Handle32`（`wt_il3.txt:8346-8379`）是同一套，只是换成 `EnumProcessModules`（没有 `LIST_MODULES_ALL`）。`EnumProcessModules(Ex)` 的 P/Invoke 是 `SetLastError=False`（`wt_pinvoke.txt:6-7`）。

> **由此得到一个重要的失败语义**：如果 `EnumProcessModulesEx` 因权限失败，返回值被 `pop` 丢掉、`needed` 保持 0 → 模块数组长度为 0 → 直接抛 `InvalidOperationException("Module not found")`。
> 也就是说，**War3Trainer 分不清“没权限看模块”和“这个进程里真的没有 game.dll”**，两种情况都报“发生未知错误：Module not found”。

---

### 2.4 进程 → 模块 → 版本

**调用顺序 `GameContext::.ctor`（`wt_il3.txt:4673-4695`）**：

```
---- IL: War3Trainer.GameContext::.ctor(Process gameProcess, String moduleName) ----
  0001: call         M:Object::.ctor
  0009: ldarg.1
  000A: call         M:GameContext::GetProcessInfo     ; this.GetProcessInfo(gameProcess);
  0011: ldarg.1
  0012: ldarg.2
  0013: call         M:GameContext::GetModuleInfo      ; this.GetModuleInfo(gameProcess, moduleName);
  001A: call         M:GameContext::GetGameAddress      ; this.GetGameAddress();   ← 版本不在表里就抛
  0021: call         M:GameContext::GetGameOffset       ; this.GetGameOffset();
  0028: ret
```

**`GetProcessInfo`（`wt_il3.txt:4191-4208`）**——只取 PID，异常被包成 `InvalidOperationException`（实际上 `Process.Id` 不会抛，是死代码）：

```
---- IL: War3Trainer.GameContext::GetProcessInfo(Process gameProcess) ----
  0002: ldarg.0
  0003: ldarg.1
  0004: callvirt     M:Process::get_Id
  0009: call         M:GameContext::set_ProcessId
  0010: leave.s      IL_001F
  0012: pop
  0014: ldstr        "Failed to fetch process Id"
  0019: newobj       M:InvalidOperationException::.ctor
  001E: throw
```

**`GetModuleInfo`（`wt_il3.txt:4210-4250`）**——模块名、版本、基址都在这里：

```
---- IL: War3Trainer.GameContext::GetModuleInfo(Process gameProcess, String moduleName) ----
  maxstack=4 locals=0:ProcessModule 1:String 2:FileVersionInfo 3:String 4:Boolean
  0002: call         M:GameContext::get_ProcessId
  0007: ldarg.2
  0008: newobj       M:ProcessModule::.ctor      ; pm = new War3Trainer.WindowsApi.ProcessModule(ProcessId, "game.dll")
  000D: stloc.0
  000E: ldloc.0
  000F: ldfld        F:ProcessModule::FileName    ; string path = pm.FileName;   ← GetModuleFileNameEx 的全路径
  0014: stloc.1
  0015: ldloc.1
  0016: call         M:FileVersionInfo::GetVersionInfo
  001B: stloc.2                                    ; FileVersionInfo fvi = FileVersionInfo.GetVersionInfo(path);
  001C: ldloc.2
  001D: callvirt     M:FileVersionInfo::get_FileVersion   ; string ver = fvi.FileVersion;   ← 只用 FileVersion
  0022: stloc.3
  0023: ldloc.3
  0024: ldnull
  0025: ceq
  0027: ldc.i4.0
  0028: ceq
  002A: stloc.s      V4
  002E: brtrue.s     IL_003B
  0030: ldstr        "Bad file version"
  0035: newobj       M:InvalidOperationException::.ctor    ; if (ver == null) throw
  003A: throw
  003B: ldarg.0
  003C: ldloc.3
  003D: ldstr        ", "                                ; ← 归一化规则
  0042: ldstr        "."
  0047: callvirt     M:String::Replace                   ; ver.Replace(", ", ".")
  004C: call         M:GameContext::set_ProcessVersion    ; ProcessVersion = ver.Replace(", ", ".");
  0052: ldarg.0
  0053: ldloc.0
  0054: ldfld        F:ProcessModule::BaseAddress
  0059: call         M:IntPtr::op_Explicit
  005E: stfld        F:GameContext::_moduleAddress        ; _moduleAddress = (uint)pm.BaseAddress;
```

**版本串归一化规则（逐字）**：

* 取 `FileVersionInfo.FileVersion`（**不是 `ProductVersion`**，**不是** `FileMajorPart` 拼装）；
* `null` → `throw new InvalidOperationException("Bad file version")`；
* 唯一的替换：**`", "`（逗号+空格）→ `"."`**。就这么一步。
  * `"1, 27, 0, 52240"` → `"1.27.0.52240"` ✔
  * `"1,27,0,52240"`（无空格）→ **不会**被替换 → 查表失败 ✘
  * `"1.27.0.52240 (f7ba2a3)"` → **不会**被处理 → 查表失败 ✘
* 从没做过去空格、去括号、只留数字等操作。
* 版本串的来源是**磁盘上的文件**（`pm.FileName` 是 `GetModuleFileNameEx` 给的路径，`FileVersionInfo.GetVersionInfo` 会去打开这个文件读 VS_VERSION_INFO）。

字节级对照：我们的 `Wc3Versions.Normalize`（`DeathSettlement\Core\Wc3Versions.cs:71-86`）比它**宽**（截断 `(`、去所有空白、`, → .`、只留数字与点），所以这一环我们不会漏，反而更不容易漏。

**13 个版本表的比较逻辑**（`GetGameAddress`，`wt_il3.txt:4252-4553`；同一份内容在 `wt_il.txt:6-120` 带 hex 列也有）：

```
---- IL: War3Trainer.GameContext::GetGameAddress() ----
  maxstack=4 locals=0:String 1:Int32
  0002: call         M:GameContext::get_ProcessVersion
  0007: stloc.0                                    ; string v = ProcessVersion;
  0008: ldloc.0
  0009: brfalse      IL_0381                       ; if (v == null) goto THROW
  000E: volatile.
  0010: ldsfld       F:<PrivateImplementationDetails>{...}::$$method0x6000022-1
  0015: brtrue       IL_00C8                       ; if (cache == null) { ...构字典... }
  001A: ldc.i4.s     13
  001C: newobj       M:Dictionary`2::.ctor
  0021: dup
  0022: ldstr        "1.20.4.6074"                 ; 索引 0
  0027: ldc.i4.0
  0028: call         M:Dictionary`2::Add
  ...（13 条，索引 0..12）...
  00B5: ldstr        "1.27.0.52240"                ; 索引 12
  00BA: ldc.i4.s     12
  00BC: call         M:Dictionary`2::Add
  00C3: stsfld       F:<...>::$$method0x6000022-1  ; 缓存写回
  00C8: volatile.
  00CA: ldsfld       F:<...>::$$method0x6000022-1
  00CF: ldloc.0
  00D0: ldloca.s     V1
  00D2: call         M:Dictionary`2::TryGetValue    ; cache.TryGetValue(v, out int idx)
  00D7: brfalse      IL_0381                       ; 不在表里 → goto THROW
  00DC: ldloc.1
  00DD: switch       (13) IL_011B IL_0159 IL_0197 IL_01D5 IL_0213 IL_0251 IL_0251 IL_0251 IL_0251 IL_028F IL_02CD IL_030B IL_0346
  0116: br           IL_0381
  ...
  0346: ldarg.0                                    ; case 12 = 1.27.0.52240
  0347: ldarg.0
  0348: ldfld        F:GameContext::_moduleAddress
  034D: ldc.i4       12468392                     ; 0x00BE40A8
  0352: add
  0353: call         M:GameContext::set_ThisGameAddress
  0359: ldarg.0
  035A: ldarg.0
  035B: ldfld        F:GameContext::_moduleAddress
  0360: ldc.i4       12468792                     ; 0x00BE4238
  0365: add
  0366: call         M:GameContext::set_UnitListAddress
  036C: ldarg.0
  036D: ldarg.0
  036E: ldfld        F:GameContext::_moduleAddress
  0373: ldc.i4       6157344                      ; 0x005DF420
  0378: add
  0379: call         M:GameContext::set_MoveSpeedAddress
  ...
  0381: ldarg.0
  0382: call         M:GameContext::get_ProcessId
  0387: ldarg.0
  0388: call         M:GameContext::get_ProcessVersion
  038D: newobj       M:UnkonwnGameVersionExpection::.ctor   ; throw new UnkonwnGameVersionExpection(pid, ver)
  0392: throw
  0393: ret
```

13 个版本串（`wt_il3.txt:4263-4316`，与 `选区内存定位2.md` §2.2 表一致）：

```
1.20.4.6074 → 0     1.21.0.6263 → 1     1.21.1.6300 → 2     1.22.0.6328 → 3
1.23.0.6352 → 4     1.24.0.6372 → 5     1.24.1.6374 → 6     1.24.2.6378 → 7
1.24.3.6384 → 8     1.24.4.6387 → 9     1.25.1.6397 → 10    1.26.0.6401 → 11
1.27.0.52240 → 12
```

`switch(13)` 的落点：`0,1,2,3,4` 各自独立；**`5,6,7,8` 共用 `IL_0251`**（1.24.0/1.24.1/1.24.2/1.24.3 的 ThisGame/UnitList/MoveSpeed 三地址相同）；`9,10,11,12` 各自独立。

`GetGameOffset`（`wt_il3.txt:4556` 起）是**第二份一模一样的 13 项字典**（缓存字段叫 `$$method0x6000023-1`，见 `wt_il.txt:2-5`、`:14`、`:71`），`switch(13)` 的落点是 **`0..7 → IL_0118`、`8..12 → IL_014A`**：

```
  0118: AttackAttributesOffset = 484 (0x1E4); HeroAttributesOffset = 492 (0x1EC)
        ItemsListOffset = 500 (0x1F4);        MoveSpeedOffset = 472 (0x1D8)
  014A: AttackAttributesOffset = 488 (0x1E8); HeroAttributesOffset = 496 (0x1F0)
        ItemsListOffset = 504 (0x1F8);        MoveSpeedOffset = 476 (0x1DC)
  017C: ldc.i4.0
  017D: ldstr        "Impossible to run to here"
  0182: call         M:Debug::Assert            ; 版本为 null / 查不到时只 Debug.Assert，不抛
```

（我们 `Wc3VersionTable` 的 `AttackOff/HeroOff` 两列与这条规则**逐行吻合**：1.20.4~1.24.2 = 0x1E4/0x1EC；1.24.3~1.27 = 0x1E8/0x1F0。我们**没存** `ItemsListOffset` 和 `MoveSpeedOffset` 两列——目前用不到，属可补的完整性缺口。）

> **重要更正**（防止后人误读）：`<PrivateImplementationDetails>` 里那个 **52 字节 = 13 × int32 的 RVA 表**（`wt_il.txt:4-5`：`0, 400, 5136, 9888, 14624, 19376, 24112, 28864, 33616, 38352, 43104, 47840, 52592`）**不是版本表**。
> 它被 `War3Trainer.CashNode::CreateChildren()` 用 `ldtoken` + `RuntimeHelpers.InitializeArray` 装进 `UInt32[13]`（`wt_il3.txt:1033-1037`），再作为**玩家槽位基址偏移表**用：`i` 从 1 循环到 12（`wt_il3.txt:1039-1040`、`:1124-1131`），标签是 `"P" + i`，
> `金 = base + off[i]`、`木 = base + off[i] + 0x80`、`最大人口 = base + off[i] + 0x180`、`当前人口 = base + off[i] + 0x200`（`wt_il3.txt:1046-1117`），其中 `base = ReadFromGameMemory(..., 1) & 0xFFFF0000`（`wt_il3.txt:1006-1009`）。数组第 0 项（值 0）没有被用到。**与「查找进程」无关。**

---

### 2.5 换进程 / 多进程

**只取 `Process[0]`**（`wt_il3.txt:4176-4184`，见 §2.2 的完整 IL）：

```
  0016: ldloc.0
  0017: ldc.i4.0
  0018: ldelem.ref        ; ps[0]
  001A: newobj M:GameContext::.ctor
```

所以，同时开着两个 `war3.exe` 时：

* `ps.Length = 2 > 0` → 只构造 `new GameContext(ps[0], "game.dll")`；
* **`ps[1]` 永远不会被尝试**；
* 如果 `ps[0]` 里没有 `game.dll` → `ProcessModule::.ctor` 抛 `InvalidOperationException("Module not found")` → `FindGame` 落进 `catch (Exception)` → `ReportUnknownFailure`，**并且不会退回去试 `ps[1]`**。

**`dzwar3` 只在 `war3` 的命中数为 0 时才会被尝试**（`wt_il3.txt:1179-1192`，条件是 `_currentGameContext == null`）。`war3` 有命中但失败了（版本不支持 / 打不开 / 没 game.dll）时，`FindGame` 直接进 catch，**不会**再去试 `dzwar3`。

**换进程的唯一办法**：用户再点一次「查找游戏」。`FindGame` 内部没有任何「重试 / 遍历候选 / 记住上次 PID」的逻辑。

---

### 2.6 状态刷新：`labGameScanState` 「检测到游戏（PID）/游戏未运行」

**(a) 所有给 `labGameScanState.Text` 赋值的地方，就这 7 处**（穷举：全 IL 里字段 `labGameScanState` 只出现 12 次 = 1 次声明 + 1 次 `stfld` + 10 次 `ldfld`，其中只有 7 次 `ldfld` 后面跟着写 `Text`）：

| # | 位置 | 赋值 | 触发条件 |
|---|---|---|---|
| 1 | `wt_il3.txt:3059-3061`（`InitializeComponent` IL 偏移 `031A`/`0325`） | `= "游戏未运行"` | **设计器初始化**（窗体构造时一次） |
| 2 | `wt_il3.txt:1909-1911`（`ReportEnterDebugFailure`） | `= "请以管理员身份运行"` | `FrmMain_Load` 里 `Process.EnterDebugMode()` 抛异常 |
| 3 | `wt_il3.txt:1919-1921`（`ReportNoGameFoundFailure`） | `= "游戏未运行，运行游戏后单击“查找游戏”"` | `FindGame` 两次名字查找都返回 null |
| 4 | `wt_il3.txt:1929-1933`（`ReportUnknownFailure`） | `= "发生未知错误：" + msg` | `FindGame` catch `Exception`；或 `cmdGetAllObjects_Click`/`viewFunctions_BeforeSelect` 里其它异常 |
| 5 | `wt_il3.txt:1941-1946`（`ReportProcessIdFailure`） | `= "错误的进程ID：" + pid` | 捕获 `BadProcessIdException` |
| 6 | `wt_il3.txt:1954-1981`（`ReportVersionFailure`） | `= "检测到游戏（" + pid + "），但版本（" + ver + "）不被支持"` | 捕获 `UnkonwnGameVersionExpection` |
| 7 | `wt_il3.txt:1989-2016`（`ReportVersionOk`） | `= "检测到游戏（" + pid + "），游戏版本：" + ver + "（支持）"` | `FindGame` 成功 |

对照：`labGameScanState` 的**唯一** `stfld`（写字段本身）在 `wt_il3.txt:2820-2822`，是设计器 `this.labGameScanState = new ToolStripLabel()`；其余 10 次出现都是 `ldfld` + 后续 `callvirt ToolStripItem::set_Text`。

字段声明（`wt_il3.txt:30`）：`field inst labGameScanState : ToolStripLabel`。

**(b) 触发上述 7 处的全部调用点**（`grep "M:FrmMain::Report"` 的结果，共 10 条 call）：

```
wt_il3.txt:1157   000E: call M:FrmMain::ReportEnterDebugFailure     ← FrmMain_Load
wt_il3.txt:1209   0069: call M:FrmMain::ReportVersionOk             ← FindGame（成功分支）
wt_il3.txt:1220   007D: call M:FrmMain::ReportNoGameFoundFailure    ← FindGame（找不到）
wt_il3.txt:1235   009D: call M:FrmMain::ReportVersionFailure        ← FindGame catch(UnkonwnGameVersionExpection)
wt_il3.txt:1247   00B6: call M:FrmMain::ReportProcessIdFailure      ← FindGame catch(BadProcessIdException)
wt_il3.txt:1259   00CF: call M:FrmMain::ReportUnknownFailure        ← FindGame catch(Exception)
wt_il3.txt:2089   0015: call M:FrmMain::ReportProcessIdFailure      ← cmdGetAllObjects_Click（点「刷新」）
wt_il3.txt:2149   0052: call M:FrmMain::ReportProcessIdFailure      ← cmdModify_Click（点「修改」）
wt_il3.txt:2233   009D: call M:FrmMain::ReportProcessIdFailure      ← viewFunctions_BeforeSelect（点左侧功能树）
wt_il3.txt:2773   00D2: call M:FrmMain::ReportProcessIdFailure      ← menuDebug1_Click（菜单「内部-ReadFromGameMemory」）
```

**(c) 结论（IL 上可判定）**

> **游戏退出后，`labGameScanState` 不会自动改回「游戏未运行」。**
>
> 理由（三条互相独立的否定证据）：
> 1. **没有任何定时器 / 后台线程去查进程**（§2.1 的否定证据）；
> 2. `labGameScanState.Text` 的全部写点集中在 7 处，其中 6 处都在 `Report*` 里，而 `Report*` 只被「窗体 Load」和 4 个**用户点击事件**调用（上面 10 条 call 清单）；
> 3. 全程序没有 `Process.HasExited`、没有 `Process.Exited` 事件订阅、没有任何「监控循环」。
>
> **唯一会让标签变掉的情况**是：游戏退出后，用户去点「刷新」/「修改」/展开左侧功能树/点调试菜单——那时旧的 `_currentGameContext` 还是上一次的 PID，`new ProcessMemory(旧PID)` 的 `OpenProcess` 失败 → `throw BadProcessIdException(旧PID)`（`wt_il3.txt:8260-8289`）→ 落到 `ReportProcessIdFailure` → 标签变成「错误的进程ID：旧PID」。
> 注意这**不是自动的**，而且文案也不是「游戏未运行」。
>
> 顺带一提：`_currentGameContext` 在 `FindGame` 的 3 个 catch 分支里会被置 `null`（`wt_il3.txt:1229`、`1243`、`1255`：`stfld F:FrmMain::_currentGameContext` + 前面的 `ldnull`），但**进程退出本身不会触发这件事**。

**对照我们**：`DeathSettlement\Core\MonitorEngine.cs:231-240`（每秒 `IsProcessAlive`）→ `:292-304`（`HandleGameGone` 清空 `Game`/`Scanner` 并更新状态文案），`:198-206`（`AutoAttach` 每 1.5 秒自动重连一次）。**我们是自动的，它完全不是。**

---

### 2.7 失败路径：三个（其实是四个）Report 的触发条件

`FindGame` 的异常处理结构（`wt_il3.txt:1225-1262`；局部变量表在 `:1168`：`0:Boolean 1:UnkonwnGameVersionExpection 2:BadProcessIdException 3:Exception 4:Boolean`）：

```
  0087: stloc.1                                   ; catch (UnkonwnGameVersionExpection e)
  0089: ldarg.0
  008A: ldnull
  008B: stfld        F:FrmMain::_currentGameContext      ; _currentGameContext = null;
  0090: ldarg.0
  0091: ldloc.1
  0092: callvirt     M:UnkonwnGameVersionExpection::get_ProcessId
  0097: ldloc.1
  0098: callvirt     M:UnkonwnGameVersionExpection::get_GameVersion
  009D: call         M:FrmMain::ReportVersionFailure
  00A6: stloc.2                                   ; catch (BadProcessIdException e)
  00A8: ldarg.0
  00A9: ldnull
  00AA: stfld        F:FrmMain::_currentGameContext
  00AF: ldarg.0
  00B0: ldloc.2
  00B1: callvirt     M:BadProcessIdException::get_ProcessId
  00B6: call         M:FrmMain::ReportProcessIdFailure
  00BF: stloc.3                                   ; catch (Exception e)   ← 兜底，无过滤
  00C1: ldarg.0
  00C2: ldnull
  00C3: stfld        F:FrmMain::_currentGameContext
  00C8: ldarg.0
  00C9: ldloc.3
  00CA: callvirt     M:Exception::get_Message
  00CF: call         M:FrmMain::ReportUnknownFailure
```

#### (1) `ReportNoGameFoundFailure`（`wt_il3.txt:1915-1923`）
文案：`"游戏未运行，运行游戏后单击“查找游戏”"`
**触发条件**：`FindGame` 走完两条名字查找后 `_currentGameContext == null`，即
`Process.GetProcessesByName("war3")` 与 `GetProcessesByName("dzwar3")` **都返回长度 0 的数组**（`wt_il3.txt:1218-1221`）：
```
  007B: nop
  007C: ldarg.0
  007D: call         M:FrmMain::ReportNoGameFoundFailure
```
**注意**：这条只在「按名字连一个进程都没找到」时出现。**如果找到了进程但模块/版本有问题，走的是另外两条**（这正是把它和下面区分开的关键）。

#### (2) `ReportVersionFailure`（`wt_il3.txt:1950-1983`）
文案：`"检测到游戏（" + pid + "），但版本（" + ver + "）不被支持"`
**触发条件**：`catch (UnkonwnGameVersionExpection)`，而这个异常**只在一处被构造**：`GameContext::GetGameAddress` 的 `IL_0381`（`wt_il3.txt:4548-4553`）：
```
  0381: ldarg.0
  0382: call         M:GameContext::get_ProcessId
  0387: ldarg.0
  0388: call         M:GameContext::get_ProcessVersion
  038D: newobj       M:UnkonwnGameVersionExpection::.ctor
  0392: throw
```
到达 `IL_0381` 只有三条路：`ProcessVersion == null`（`:0009 brfalse`）、`TryGetValue` 返回 false（`:00D7 brfalse`）、`switch` 越界（`:0116 br`，13 个索引不可能越界）。
→ **实际语义：`FileVersionInfo.FileVersion` 经 `Replace(", ", ".")` 之后不在那 13 个版本串里。**
（`"Bad file version"` 那条走的是 `GetModuleInfo` 里的 `InvalidOperationException`，会落到下面的 (3)，不会到这里。）

#### (3) `ReportProcessIdFailure`（`wt_il3.txt:1937-1948`）
文案：`"错误的进程ID：" + pid`
**触发条件**：`catch (BadProcessIdException)`。这个异常在**两处**被构造，都是 `OpenProcess` 失败：
* `War3Trainer.WindowsApi.ProcessModule::.ctor`（`wt_il3.txt:8481-8483`）：
```
  001F: stloc.s      V4
  0021: ldloc.s      V4
  0023: brtrue.s     IL_002C
  0025: ldarg.1
  0026: newobj       M:BadProcessIdException::.ctor
  002B: throw
```
* `War3Trainer.WindowsApi.ProcessMemory::.ctor`（`wt_il3.txt:8260-8289`），同样是 `OpenProcess(0x1F0FFF)` 后用 `SafeHandle.IsInvalid` 判：
```
  0010: ldc.i4       2035711
  001C: call         M:NativeMethods::OpenProcess
  0021: stfld        F:ProcessMemory::_processHandle
  0027: ldfld        F:ProcessMemory::_processHandle
  002C: callvirt     M:SafeHandle::get_IsInvalid
  0036: brtrue.s     IL_0044
  0038: ldarg.0
  0039: ldfld        F:ProcessMemory::_processId
  003E: newobj       M:BadProcessIdException::.ctor
  0043: throw
```
**关键点**：`OpenProcess` 请求的是 **`0x1F0FFF` = `PROCESS_ALL_ACCESS`**（写内存的修改器要这个）。所以游戏以管理员权限跑、本程序不是管理员时，这里就是 `ERROR_ACCESS_DENIED` → 「错误的进程ID：xxxx」。
除 `FindGame` 外还有 4 个调用点（点「刷新」/「修改」/展开功能树/调试菜单），见 §2.6(b)。

#### (4) `ReportUnknownFailure`（`wt_il3.txt:1925-1935`）
文案：`"发生未知错误：" + message`
**触发条件**：`catch (Exception)` 兜底。实际会走到这里的典型异常：
* `InvalidOperationException("Module not found")`（`wt_il3.txt:8555-8557`）——进程在、但没有 `game.dll` 模块，**或模块枚举因权限失败被当成 0 个模块**（见 §2.3 末尾）；
* `InvalidOperationException("Bad file version")`（`wt_il3.txt:4235-4237`）——`FileVersionInfo.FileVersion` 为 `null`（例如 `game.dll` 是平台改造版、没有版本资源）；
* `InvalidOperationException("Failed to fetch process Id")`（`wt_il3.txt:4204-4206`，实际不可达）；
* `Win32Exception` 等其它。

#### (5) 「请以管理员身份运行」到底怎么判定的 —— **不是 OpenProcess，也不是 catch Win32Exception**

`ReportEnterDebugFailure`（`wt_il3.txt:1905-1913`）：
```
---- IL: War3Trainer.FrmMain::ReportEnterDebugFailure() ----
  0001: ldarg.0
  0002: ldfld        F:FrmMain::labGameScanState
  0007: ldstr        "请以管理员身份运行"
  000C: callvirt     M:ToolStripItem::set_Text
  0012: ret
```
它**只有一个调用点**：`FrmMain_Load` 的 `IL_000B`（`wt_il3.txt:1157`），那里是：
```
  0002: call         M:Process::EnterDebugMode
  0009: leave.s      IL_0016
  000B: pop                                  ; ← catch 子句，无异常类型过滤 = catch { }
  000E: call         M:FrmMain::ReportEnterDebugFailure
```
> 所以：**判定方式是 `Process.EnterDebugMode()`（开启 SeDebugPrivilege）抛任何异常** —— 是 `catch {}` 全捕获，**不是** `catch (Win32Exception)`，**也不是** OpenProcess 的失败。
> 又因为 `FrmMain_Load` 紧接着第 7 条指令就调 `FindGame`（`:0018`），而 `FindGame` 无论成功失败都必定会写一次 `labGameScanState.Text`（成功 → `ReportVersionOk`；失败 → 另外三条 `Report*`），所以「请以管理员身份运行」在启动时**会被立刻覆盖**，用户几乎看不到它。这算一个 UI 顺序上的小瑕疵（正确的做法是把它作为**额外的**提示，而不是抢占同一个标签）。

---

### 2.8 与既有文档的交叉验证

| 结论 | 本报告 | 交叉来源 |
|---|---|---|
| 13 版本串与 RVA | 一致（`wt_il3.txt:4263-4316`、`4326-4547`；`wt_il.txt:14-120`） | `选区内存定位2.md` §2.2 表（`:130-144`）、`DeathSettlement\Core\Wc3VersionTable.cs:17-30` |
| `_moduleAddress = ProcessModule.BaseAddress`（= game.dll 基址） | 一致（`wt_il3.txt:4245-4249`） | `选区内存定位2.md:125` |
| 版本串来自 `FileVersionInfo.FileVersion`，去掉千分位逗号 | 一致，并补全为「只替换 `", "` → `"."`，别的一律不处理」 | `选区内存定位2.md:126` |
| 版本表分两份（`GetGameAddress` / `GetGameOffset`），索引序完全相同 | 一致 | `选区内存定位2.md:128`、`wt_il.txt:1-5` |
| 1.27 三地址 `0xBE40A8 / 0xBE4238 / 0x5DF420` | 一致 | `选区内存定位2.md:146-152`、`伤害监视说明.md:563` |
| 进程查找方式 | **本报告新增**：`GetProcessesByName` + 只取 `[0]`；`war3`→`dzwar3` 两段式 | 无既有文档记载 |

---

## 3. 与我们的实现（`DeathSettlement\Core\Wc3Game.cs` 等）的差异清单

对照对象：

* `DeathSettlement\Core\Wc3Game.cs:44` 名字表、`:47-71` `FindCandidates`、`:74-176` `Attach`、`:178-187` `ReadModuleVersion`
* `DeathSettlement\Core\RemoteProcess.cs:62-99` `TryOpen`、`:101-174` `LoadModules`、`:176-177` `FindModule`
* `DeathSettlement\Core\Wc3Versions.cs:56-86` `TryGet` / `Normalize`
* `DeathSettlement\Ui\ProcessPickerForm.cs:102-172` 模块判据的进程列表
* `DeathSettlement\Core\Probe.cs:44-85` 全进程盘点

| # | 维度 | War3Trainer | 我们 | 谁更强 |
|---|---|---|---|---|
| D1 | 进程名字面量 | `war3`、`dzwar3`（+模块 `game.dll`） | `war3 / War3 / game.dll / dzwar3 / Warcraft III / Frozen Throne` + `ExtraProcessNames`（用户选过的名字会记住，`MainForm.cs:357-366`） | **我们（严格超集）** |
| D2 | 名字匹配 API | `Process.GetProcessesByName(name)` | `Process.GetProcesses()` + `string.Equals(p.ProcessName, n, OrdinalIgnoreCase)` | 等价（都是比 `ProcessName`、都不含 `.exe`、都忽略大小写）；`ProcessName` 带空格两者都不受影响 |
| D3 | 多进程 | **只取 `ps[0]`**，失败不试 `ps[1]` | `Attach` 遍历**全部**候选（`Wc3Game.cs:125`） | **我们** |
| D4 | `war3` 失败后是否试 `dzwar3` | **不试**（只有长度为 0 才试） | 全部候选一视同仁 | **我们** |
| D5 | 硬判据 | 必须有 `game.dll` 模块 | 必须有 `game.dll` 模块（`RemoteProcess.cs:176-177`） | 相同 |
| D6 | 模块名匹配 | `GetModuleBaseName` → `ToLower()` 全等 | Toolhelp `szModule` / `ProcessModule.ModuleName` → `OrdinalIgnoreCase` 全等 | 相同 |
| D7 | 模块枚举 | `OpenProcess(0x1F0FFF)` + `EnumProcessModulesEx(LIST_MODULES_ALL)`，失败退化 `EnumProcessModules`；**失败后 `needed=0` → 报 “Module not found”** | `OpenProcess(VM_READ\|QUERY_INFO)`（再退 `…\|QUERY_LIMITED`）+ Toolhelp `TH32CS_SNAPMODULE\|SNAPMODULE32` → 退 `.NET Process.Modules` → 退「主模块」 | **我们**（三级回退 + 需要更少权限） |
| D8 | 64/32 位 | `LIST_MODULES_ALL`（好），但**退化路径 `EnumProcessModules` 不保证列出 WOW64 目标的 32 位模块**，且失败静默 | Toolhelp 带 `SNAPMODULE32`；`IsWow64Process` 有记录 | **我们 / 至少不弱** |
| D9 | 版本字段 | **只用 `FileVersionInfo.FileVersion`** | **优先 `ProductVersion`**，为空才退 `FileVersion`（`Wc3Game.cs:184`） | **它**（见 G1） |
| D10 | 版本串归一化 | 只 `Replace(", ", ".")` | 截断 `(`、去所有空白、`, → .`、只留数字与点 | **我们** |
| D11 | 读版本的路径 | `GetModuleFileNameEx` 的路径，直接 `GetVersionInfo` | 先 `File.Exists(path)`，不通过就返回 null（`Wc3Game.cs:180`） | **它**（见 G2） |
| D12 | 13 版本表 | 13 项，含 ThisGame/UnitList/MoveSpeed/AttackOff/HeroOff/ItemsOff/MoveSpeedOff | 同样 13 项，**少了 ItemsOff 与 MoveSpeedOff 两列**（`Wc3VersionTable.cs:13`） | 相同版本集合；列数少 2（当前用不到） |
| D13 | 「找到」的判定 | **进程 + game.dll + 版本在表里 = 成功**（不管有没有进地图） | 还要 `Refresh()` 读得到引擎全局且非 0 → 才 `Ready`（`Wc3Game.cs:190-226`） | **它**（见 G3） |
| D14 | 进程退出后的状态 | **永不自动更新**，标签永远挂着旧 PID | 每秒探活 → 自动断开 + 每 1.5 秒自动重连（`MonitorEngine.cs:231-240`、`:198-206`） | **我们** |
| D15 | 陌生进程名（平台宿主） | 找不到（名字表更窄） | **自动路径**找不到；但 `ProcessPickerForm` 能按模块列出并让用户点（`:111-149`），选过一次后名字会被记住 | 我们多了「手动补救」，自动路径一样缺（见 G4） |

---

## 4. 「它会找到、我们会漏掉」的具体情形

### 先给判定结论

* **按「进程名」这一维度：不存在。** War3Trainer 的名字集合 `{war3, dzwar3}` 是我们 `{war3, War3, game.dll, dzwar3, Warcraft III, Frozen Throne}` 的**子集**，而且两边都用同一套 BCL 语义比 `ProcessName`（忽略大小写、不含 `.exe`、带空格的名字照样是全等比较）。所以不存在「它按名字命中、我们按名字不命中」的进程。
* **在名字之后的链路上，有 3 处真实的「它报成功 / 我们报失败」，还有 1 处双方都漏但我们可以补的能力缺口。**

### G1（真·它会成功我们失败）：版本串取值不同 —— 我们优先 `ProductVersion`，它只用 `FileVersion`

* 它：`FileVersionInfo.GetVersionInfo(pm.FileName).FileVersion`（`wt_il3.txt:4224-4225`）。
* 我们：`!string.IsNullOrWhiteSpace(fv.ProductVersion) ? fv.ProductVersion : fv.FileVersion`（`Wc3Game.cs:184`）。
* **失败场景**：某个平台改造版 `game.dll` 的 VS_VERSION_INFO 里 `FileVersion = "1, 27, 0, 52240"`（→ `1.27.0.52240`，它命中）、而 `ProductVersion = "1.27.0"` 或 `"1.27.0.52240 (build 7)"`（→ 我们的 `Normalize` 得到 `1.27.0` 或 `1.27.0.522407`，都不在 13 表里）。此时**它会连上，我们报 `UnsupportedVersion`**。
* 相关的**第二个**失败场景：我们的 `Normalize` 会**在第一个 `(` 处截断**（`Wc3Versions.cs:76`）。若 `ProductVersion = "Warcraft III (1.27.0.52240)"`，我们得到空串 `""`，直接失败；而它的 `FileVersion` 正常。
* 顺带：`DeathSettlement\_test\probe_live_003409.txt:9` 已经出现过 `版本（）不被支持` 的空串形态（假 game.dll 没有版本资源），说明**空/异常版本串在真机上真的会发生**。

### G2（真·它会成功我们失败）：我们对版本文件加了 `File.Exists` 硬门槛

* 它：直接 `FileVersionInfo.GetVersionInfo(path)`，没有存在性检查。
* 我们：`if (string.IsNullOrEmpty(path) || !File.Exists(path)) return null;`（`Wc3Game.cs:180`）。
* **失败场景**：`game.dll` 的路径超过 `MAX_PATH`（Toolhelp `MODULEENTRY32W.szExePath` 是固定 260 字符缓冲；我们的 `ModuleInfo.Path` 直接来自它，`RemoteProcess.cs:117`），或路径是符号链接 / `\\?\` 形式 / 一时不可 stat 的网络盘。此时 `File.Exists` 为 false → 我们返回 null → 退到 `ReadModuleVersion(rp.MainModulePath)`（即 `war3.exe` 的版本）。若 `war3.exe` 的版本资源与 `game.dll` 不同（平台改造版很常见：exe 被换成平台壳），我们就会报「版本不被支持」，而它用 `GetModuleFileNameEx` + `GetVersionInfo` 一样受 256 截断限制——**但它的 `GetVersionInfo` 不需要先 `File.Exists` 成功**，某些情况下 `GetVersionInfo`（走 `GetFileVersionInfoSize`）能拿到而我们被 `File.Exists` 卡住。

### G3（语义差：它报「检测到游戏/版本支持」，我们报失败）

* 它只要拿到「进程 + game.dll + 版本在表里」就算成功，立刻 `ReportVersionOk` + `GetAllObject`（`wt_il3.txt:1202-1215`），**不检查有没有进地图**。
* 我们 `Attach` 必须 `g.Refresh()` 得到 `Ready` 才返回（`Wc3Game.cs:158-163`）。**在主菜单（还没进图）时**，我们会 `continue` 到下一个候选，最后返回一个 `NotInGame` 的失败对象。
* 用户在「刚开游戏、还没进图」这一刻点「查找游戏」：它显示「检测到游戏（PID x），游戏版本：1.27.0.52240（支持）」；我们显示「已连接 PID x，但读不到引擎全局…」或「…游戏还没进地图」。**这不是「找不到进程」，但会被用户读成「它找到了、你没找到」。**
* 附带 bug：这条路径上 `rp` **没有 Dispose**（`Wc3Game.cs:158-163`，只有 `Ready` 才 return，非 Ready 时既没 return 也没释放），每次自动重连漏一个句柄。

### G4（双方都漏，但我们可以补的能力缺口）：进程名完全不相关的宿主进程

* 场景：平台用注入/宿主方式跑魔兽，进程名是 `Platform.exe` / `W3Launcher.exe` / `11Platform.exe` 之类，名字里没有 `war3`/`warcraft`/`frozen`/`dzwar`，但进程里加载了 `game.dll`。
* 它：`GetProcessesByName("war3")` 与 `("dzwar3")` 都返回 0 → 报「游戏未运行」。**漏。**
* 我们**自动路径**：`FindCandidates` 名字表也全不中 → `Attach` 直接返回 `NoProcess`（`Wc3Game.cs:98-109`）。**也漏。**
* 我们**手动路径**：`ProcessPickerForm` 已经在按「进程里有没有 `game.dll`」列进程（`ProcessPickerForm.cs:123-149`，绿色行），且扫过一次之后进程名会被记进 `ExtraProcessNames`（`MainForm.cs:357-366`），以后自动也能连。
* **所以缺口只在「自动路径没有复用这个已经存在的能力」**，而不是「我们做不到」。
* 顺带：`ProcessMatch.LooksLikeGame`（`PlayerSummary.cs:72-78`，用 `Contains` 宽匹配）比 `Wc3Game` 的精确名字表**宽**，但**只有 Picker/Probe 用它，`Wc3Game.FindCandidates` 不用**——这是一处内部不一致，会让人误以为自动路径也认 `war3cn`、`WarcraftIII`（无空格）、`魔兽` 这类名字。

### 其它被问到、但**不构成**「它赢」的点

| 提问中的假设 | 实际情况 |
|---|---|
| 权限受限导致我们读不到模块表 | 它请求的是 `PROCESS_ALL_ACCESS`（`wt_il3.txt:8468`），**要求比我们高**；我们还有 `QUERY_LIMITED_INFORMATION` 退化 + Toolhelp 回退。**同一权限条件下我们更容易成功。** 真正的问题在 G3 的「同一句话术」上：它的权限失败报「错误的进程ID」，我们报「找不到 game.dll（可能不是魔兽进程）」，措辞不如它直观 |
| 64/32 位差异 | 它用 `LIST_MODULES_ALL` 是对的，但**退化路径 `EnumProcessModules` 在 64 位宿主读 WOW64 目标时不保证列出 32 位模块**，而且失败被 `pop` 丢掉；我们用 Toolhelp + `TH32CS_SNAPMODULE32`。**我们不弱。** |
| `ProcessName` 带空格 | 两边都用 `ProcessName` 全等比较；我们的表里本来就有 `Warcraft III` / `Frozen Throne` 两个带空格的项，它的表里一个带空格的都没有。**我们更强。** |
| 多个同名进程 | 它只取 `[0]`；我们遍历全部。**我们更强。** |
| 进程名列表 | 我们是严格超集。**我们更强。** |
| 游戏退出后的状态 | 它永不自动更新（§2.6）；我们每秒探活 + 自动重连。**我们更强。** |

---

## 5. 建议补丁（具体到文件、函数、改法）

> 约束遵守：以下**只是建议文本**，本报告没有改动任何 `.cs`。

### P1【高优先，修 G1】`DeathSettlement\Core\Wc3Game.cs` → `ReadModuleVersion`

现状（`:178-187`）：把 `ProductVersion` 当唯一首选，失败就整体判「版本不支持」。

改成「候选链 + 命中优先」：

```csharp
/// <summary>把 game.dll 里所有可能的版本串都拿出来，逐个去 13 版本表里试。</summary>
private static bool TryResolveVersion(string? path, out Wc3VersionInfo ver, out string raw)
{
    ver = null!; raw = "";
    if (string.IsNullOrEmpty(path)) return false;
    FileVersionInfo fvi;
    try { fvi = FileVersionInfo.GetVersionInfo(path); }   // 不再前置 File.Exists
    catch { return false; }

    // 顺序照 War3Trainer（FileVersion 优先），再补 ProductVersion 与四段拼装
    var cands = new List<string?>();
    void Add(string? s) { if (!string.IsNullOrWhiteSpace(s) && !cands.Contains(s)) cands.Add(s); }
    Add(fvi.FileVersion);
    Add(fvi.ProductVersion);
    Add($"{fvi.FileMajorPart}.{fvi.FileMinorPart}.{fvi.FileBuildPart}.{fvi.FilePrivatePart}");

    foreach (var c in cands)
        if (Wc3Versions.TryGet(c, out ver)) { raw = c!; return true; }

    raw = cands.FirstOrDefault() ?? "";   // 都不中：把第一个非空的拿去做报错文案
    return false;
}
```

调用侧（`Wc3Game.cs:148`）同时**对 `gameDll.Path` 和 `Mem.MainModulePath` 各试一遍候选链**，任一命中即用：

```csharp
if (!TryResolveVersion(gameDll.Path, out var ver, out string raw1) &&
    !TryResolveVersion(rp.MainModulePath, out ver, out string raw2))
{
    lastError = $"检测到游戏（PID {proc.Id}），但版本（game.dll={raw1}；exe={raw2}）不被支持。" +
                "可用 --force-version 1.27.0.52240 指定。";
    ...
}
```

> 顺带把报错文案里**原始的两个串都带上**（现在只带一个 `versionRaw`，遇到 `ProductVersion="1.27.0"` / `FileVersion="1.27.0.52240"` 时用户完全看不出问题在哪）。

### P2【高优先，修 G4】`DeathSettlement\Core\Wc3Game.cs` → 新增模块兜底扫描，并在 `FindCandidates` / `Attach` 里用上

把 `Probe.cs:44-85` 与 `ProcessPickerForm.cs:111-149` 里那段「遍历所有进程、找 `game.dll`」抽成公共方法（建议放 `RemoteProcess.cs` 或新文件 `ProcessScan.cs`）：

```csharp
/// <summary>全进程扫描：谁的模块表里有 game.dll 谁就是魔兽（含 32 位模块）。
/// 返回的列表中，ModuleUnknown=true 表示「模块表读不到（权限？）」，不代表没有。</summary>
public static List<(int Pid, string Name, string? GameDllPath, bool ModuleUnknown)>
    ScanForGameDll(Func<int,bool>? pidFilter = null) { ... }
```

然后 `FindCandidates` 增加一个参数（默认 false，**只在名字命中数为 0 时才做**，避免每 1.5 秒一次的全量枚举）：

```csharp
public static List<Process> FindCandidates(string? extraNames = null, bool moduleFallback = false)
{
    ... // 先走精确名字表（快）
    if (result.Count == 0 && moduleFallback)
    {
        foreach (var hit in ProcessScan.ScanForGameDll())
            try { result.Add(Process.GetProcessById(hit.Pid)); } catch { }
        if (result.Count > 0)
            Log.Write("名字表没命中，但按 game.dll 模块兜底找到了：" +
                      string.Join(", ", result.Select(p => $"{p.Id}:{p.ProcessName}")));
    }
    return result;
}
```

调用侧：`Wc3Game.Attach` 里 `FindCandidates(options.ExtraProcessNames, moduleFallback: true)`（`Wc3Game.cs:95`），或者在 `candidates.Count == 0` 的那条分支里补一次。可选强化：把兜底扫到的进程名 `Append` 进 `Settings.LastProcessName`，下次直接命中（和 Picker 现在的行为一致）。

### P3【中优先，修 G3 + 句柄泄漏】`Wc3Game.Attach` 的“最接近成功”会话

```csharp
Wc3Game? bestNotReady = null;
...
var g = new Wc3Game { Mem = rp, Version = ver, GameDll = gameDll };
g.Refresh();
if (g.State == AttachState.Ready) { bestNotReady?.Dispose(); return g; }
if (bestNotReady == null) bestNotReady = g;   // 保留「进程/game.dll/版本都对，只是没进图」
else g.Dispose();
lastError = g.Message; lastState = g.State;
...
return bestNotReady ?? new Wc3Game { State = ..., Message = ... };
```

这样「进程在、game.dll 在、版本支持、只是没进地图」时，UI 能显示「已连接 PID x（版本 y），但游戏还没进地图」，与它 `ReportVersionOk` 的语义对齐；同时也修掉现在每次自动重连漏一个 `RemoteProcess` 句柄的问题。

### P4【中优先，消内部不一致】统一 `ProcessMatch.LooksLikeGame` 与 `Wc3Game.ProcessNames`

`ProcessMatch.LooksLikeGame`（`PlayerSummary.cs:72-78`）比 `Wc3Game.ProcessNames` 宽。两个选择：

* **推荐**：让 `FindCandidates` 在精确表之外，把 `LooksLikeGame` 命中的进程也**先**作为候选（便宜），**但打开后仍以「模块表里有 `game.dll`」为硬判据**（现有的 `rp.FindModule("game.dll")` 已经是硬判据，不用改）。这样 `war3cn`、`WarcraftIII`、`魔兽` 之类会被试一遍，误判成本只是一次 `OpenProcess` + 一次模块枚举。
* 或者反过来：把 `ProcessNames` 与 `LooksLikeGame` 的规则都收敛到同一个 `ProcessMatch` 里，避免两处规则漂移。

再顺手加进一个真实常见的名字：`Warcraft III`（已有）、`WarcraftIII`、`war3cn`、`魔兽争霸`、`W3Champions`。但**别只靠名字**——P2 的模块兜底才是根治。

### P5【低优先】`RemoteProcess.TryOpen` 的前置名字依赖

`RemoteProcess.cs:66-67` 先 `Process.GetProcessById(pid).ProcessName`，失败就 `return null`。建议改成**先 `OpenProcess`，名字取不到就用 `"?"`**，避免在竞态/受保护进程上因为「取不到名字」而放弃一个本来能打开的进程。

### P6【低优先，完整性】`Wc3VersionTable` 补齐两列

IL 里 `GetGameOffset` 还给每行 `ItemsListOffset`（0x1F4 / 0x1F8）和 `MoveSpeedOffset`（0x1D8 / 0x1DC），我们的 `Rows` 少了这两列（`Wc3VersionTable.cs:13-31`）。当前没用到，但补上以后要与 War3Trainer 逐行对分（物品列表 / 移动速度）时就不用再翻 IL：

```
索引 0..7  → ItemsListOffset = 0x1F4, MoveSpeedOffset = 0x1D8
索引 8..12 → ItemsListOffset = 0x1F8, MoveSpeedOffset = 0x1DC
```

### P7【低优先，可观测性】把「模块枚举失败」和「真的没 game.dll」分开报

War3Trainer 二者都报 `Module not found`（§2.3）。我们的 `RemoteProcess.LoadModules` 已经有 `ModuleUnknown` 的概念（在 `ProcessPickerForm` 里用），但 `Wc3Game.Attach` 的报错把二者混成「找不到 game.dll 模块（可能不是魔兽进程）」（`Wc3Game.cs:136`）。建议在 `RemoteProcess` 上暴露一个 `ModulesEnumerationFailed` 标志，`Attach` 据此给两种文案：
* 「读不到该进程的模块表（权限不足？）→ 请【以管理员身份重启】」
* 「该进程里确实没有 game.dll → 大概率不是魔兽进程」

---

## 6. 未决 / 未验证

1. `ProcessName` 与 `GetProcessesByName` 的等价性按 .NET Framework 2.0 的 BCL 语义判定（源路径不可见，只能按 BCL 契约）。若某平台把进程名伪造成与文件名不同（例如通过 `NtSetInformationProcess` 改 `ImageFileName`），两边都依赖 BCL 的同一处实现，差异不会出现。
2. `FileVersionInfo.FileVersion` 与 `ProductVersion` 在**真实平台改造版 `game.dll`** 上是否真的不同，本机没有该样本（`C:\3rd\war5\game.dll` 是 1.27.0.52240 官方 build，两个字段一致）。G1 属于**推理出的风险**，不是现场复现。
3. 真机上没有同时跑过 War3Trainer 与我们的程序做 A/B（按约束没有运行那个 exe）。
4. 没有验证过「宿主进程名完全不含 war3/warcraft」的真实平台样本；G4 属能力缺口分析。
