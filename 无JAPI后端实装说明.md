# 无 JAPI/ydbase 后端（native 引擎直连）—— 实装说明

> 目标：在**平台联机那种完全没有 ydbase/JAPI 的进程**里，让伤害监视插件照样工作：
> 初始化 → 钩住引擎伤害函数 → 完整写日志 → **把伤害明细/回执/统计显示到屏幕上**。
>
> **本轮范围**：`backend` 三态 + native 引擎直连（取伤害事件 + 取名字 + **上屏显示**）。
> 聊天命令仍然不做（定位 `InGameChatWhat` 依赖 ydbase 搜索器）。
>
> 改动文件：`UDamageWatcherHook.cpp`（唯一一个源码文件，UTF-8 无 BOM）。
> 自检文件 `UDamageWatcherSmoke.cpp` **未改**（原断言与措辞全部保留）。
> 逆向依据：`无JAPI模式逆向.md` + 本轮对真实 `Game.dll` 的逐字节复核（§4 有两处重要更正）。

---

## 1. 配置：`backend`

```ini
backend=auto        ; auto(0,**当前默认**) | native(2) | japi(1)   —— 也可写 ydbase(=japi)
```

| 取值 | 语义 |
|---|---|
| `auto`（默认，=0） | 进程里有 `ydbase.dll` → **走原来的 JAPI 路径，一字不变**；没有 → **不再中止**，改走 native |
| `japi`（=1） | 强制原 JAPI 路径；缺 ydbase 时**按原来的方式中止**（日志措辞保留） |
| `native`（=2） | 强制引擎直连：**不等 ydbase、不碰 ydbase**，直接连 `Game.dll`（装了 ydbase 也走 native） |

* `LoadConfig()` 同时接受字符串与数字；非法值回退 `auto` 并写日志；配置日志行含 `backend=%d`。
* ini 模板（`WriteDefaultIni()`）里加了完整说明段 + `backend=auto`（模板仍转 ANSI/GBK 后落盘）；
  **结构体默认值也是 `0`(auto)** —— ini 缺失时用的是结构体默认值（不是刚生成的那份文件），两处必须一致。
* **v1.3.3 起显示规则**：有 JAPI（ydbase 可用）→ 消息区显示；没有 JAPI（native）→ **一律不显示，只写日志**。
  所以默认必须是 `auto`：强写 `native` 等于"永远不显示"。

---

## 2. 新增/修改的函数清单

### 2.1 native 后端基座（源文件 §4.1）

| 函数 | 作用 |
|---|---|
| `Wc3Peek / Wc3PeekU32` | 安全读（`Readable` + `__try`），失败返回 0 |
| `Wc3RealValue(uint32_t)` | JASS real 作为**参数**时（= 指向 float 的句柄）解引用 + 合理性过滤。⚠ 返回值不是这个形态，见 §3.9 |
| `Wc3GameBase()` | 取 `Game.dll` 基址（`GetModuleHandleA` → 快照 + `_stricmp` 兜底），首次写一行日志（含大小/路径） |
| `Wc3TextRange()` | 解析 PE 段表取 `.text` 的 `[起始, 大小]` |
| `Wc3MatchComboB()` | 组合特征码（26 字节含 4 通配，位于 `序言+0x85`）带通配比较 |
| `Wc3FindDamageFunc()` | 扫 16 字节序言定位引擎伤害函数，**要求唯一命中**（0 或 >1 → 返回 0，什么都不动） |
| `Wc3NativeByName()` | 遍历 native 名表 A（RVA `0x1E9A50`，stride 20，校验 `E8/68/BA/B9`，跳过 `0x70A0C0` 桩）按名字取实现 |
| `Wc3LogResolved / Wc3CheckRvaTarget / Wc3ResolveNative` | 解析 + **可读 + 非桩 + 首 3 字节序言轻校验**；每行日志含"基址 + RVA + 期望 RVA + 序言 + 校验结论" |
| `Wc3PrepareNatives()` | 启动时把 **12 个** native/辅助全部解析并逐行写日志 |
| `Wc3OnGameThread()` | 判断当前是否游戏线程（字符串表只能在游戏线程动） |
| ~~`Wc3MakeStringId()`~~ | **已删除（v1.3.2）**：显示不需要造 id（TextTag 的 S 要对象指针，见 §3.4）；RVA `0x1DA520` 仅留作逆向记录 |
| `Wc3MakeStringIdCached()` | 上面那个 + **256 条线性缓存**（字符串表只增不减，同一文本只造一次 id）+ 全局硬上限 `kStrIdHardCap=100000` |
| `Wc3StringById()` | **字符串 id → char\***（RVA `0x1C2870`，`__thiscall`(ecx=ctx, [esp+4]=id)，`ret 4`） |
| `Wc3StringTableSelfTest()` | 一次性自检：造一个 id 再反查回来，一致才算"可以上屏"；不一致就本局只写日志 |
| `Wc3GetLocalPlayer / Wc3GetPlayerId / Wc3GetOwningPlayer / Wc3IsPlayerAlly / Wc3GetUnitStateValue` | 引擎 native 直调（`__cdecl`），全部 `__try` + 失败返回 0 |
| `Wc3HandleToUnit()` | JASS `Hunit` → `CUnit*`（RVA `0x1D1550`） |
| `Wc3UnitTypeCode()` | **零调用**直读 `CUnit*+0x30`（= `GetUnitTypeId` 的全部实现），失败才走 native |
| `Wc3HandleMgrFromCtx / Wc3Obj2HCall / Wc3Obj2HMem / Wc3ObjectToHandle` | `ctx` → 句柄管理器（纯内存 `*(ctx+0x1C)` / 引擎访问器 `0x1C3200`）× 两条路线（引擎转换器 `0x2651D0` / 纯内存扫表），首次用**回程校验**自动定型 |
| `ObjToHandle()` | **统一分派**：`g_nativeMode` → native，否则 → ydbase 的 `g_object_to_handle` |

### 2.2 `DoInitializeNative()`（§9.5，紧接 `DoInitialize` 之前）

`DoInitialize` 里早分支调用后 `return`；**下面那一大段 ydbase 逻辑一行未动**。

流程：`Wc3GameBase` → 读 **ctx** 并写日志（`*(Game.dll+0xBE4238)`，非 0 才算可用）→
`Wc3PrepareNatives`（12 行日志）→ `Wc3FindDamageFunc`（唯一命中）→
`InstallDetour(target, &OurDamageFunc, (void**)&g_original_damage)` → `g_nativeMode = 1` →
模式/聊天(跳过)/热键。任何一步失败 = 写日志 + `安全退出`，不动游戏内存。

> **跳板先于补丁就绪**：`InstallDetour` 在打补丁**之前**写 `*outTramp`，所以这里把
> `g_original_damage` 的地址直接当 `outTramp` 传进去（32 位 `LONG` 与 32 位指针同为 4 字节）。
> 引擎刚跳进 `OurDamageFunc` 时 `ORIG_DAMAGE` 已经可用 ⇒ **不存在"钩子已挂、原函数为空"的窗口**。
> 失败时把 `g_nativeMode` 复位为 0。

### 2.3 新增：取名字正文的统一入口

| 函数 | 作用 |
|---|---|
| `UnitNameText(handle)` | 单位名正文：JAPI 走 `g_call("GetUnitName")`，native 直调引擎 `0x1E6340`（返回字符串 id）→ `JassStringToCStr` → 引擎字符串表反查。首字节 `<0x20` 视为失败（防 id 空间不对时出乱码） |
| `PlayerNameText(player)` | 玩家名正文：同上，native 用 `0x1E3D40` |

### 2.4 修改的既有函数（**全部是"加 native 分支"，JAPI 模式行为不变**）

相对备份 `_build\backup\20260928-084119\UDamageWatcherHook.cpp`，被替换掉的原有行共 64 行，
没有一处落在 `DoInitialize` 的 "取 ydbase 导出 → 伤害槽定位 → 挂接" 那一整段里：

| 位置 | 改动 | JAPI 模式下等价性 |
|---|---|---|
| `ShowMessage()` | **B 计划（v1.3）**：两个后端都改走 **TextTag 飘字**（新增 `ShowMessageAt(单位锚点, 文本)`）。native 分支 = `Wc3StringTableSelfTest()` → `Wc3MakeStringIdCached` → `CreateTextTag`/`SetTextTagText`/`SetTextTagPosUnit`/`SetTextTagVelocity`/`Color`/`Lifespan`/`Fadepoint`/`Permanent`/`Visibility` 整族（RVA 见 §3.3）；JAPI 分支 = `g_call("CreateTextTag"…)`。任何失败降级为只写日志。**消息区的 DTTTP 实现已整体删除** | JAPI 下也改成飘字（不再往消息区发） |
| `GetLocalPlayerHandle()` / `GetUnitStateSafe()`（读血量）/ `GetUnitTypeKey()` | 各加 native 分派 | 原样 |
| `GetUnitTypeCode()` / `GetUnitLabel()` | 类型码统一走 `GetUnitTypeKey()`；名字统一走 `UnitNameText()` | **同一个调用**，返回值一致 |
| 全部 `g_object_to_handle(...)` 调用点（伤害目标/来源、`ValidateUnitArray`、`ValidateUnitObject`、`LocateSelectionField`×2、`GetSelectedUnitHandleByMemory`） | 改为 `ObjToHandle(...)`；两处 `if (!g_object_to_handle ...)` 守卫加 `&& !g_nativeMode` | 原样 |
| `DetectGameTextEncoding()` | 改走 `PlayerNameText`/`UnitNameText`（JAPI 下就是原来那两次 `g_call`）；**native 下也做真实编码判定**了 | 原样 |
| `JassStringToCStr()` | 加 native 分支（走引擎字符串表 `0x1C2870`） | 原样 |
| `HasLocust()` / `IsRelatedToLocalPlayer()` / `UnitCamp()` / `LocalPlayerId()` / `CountHumanPlayers()` | 加 native 分派或"不滤/判不出来"的明确分支 | 原样 |
| `GetSelectedUnitHandle()`（建组枚举） | native 下明确不用建组枚举，只走纯内存读 | 原样 |
| `wantEventLog` | 加 `g_nativeMode ||`（native 下**无条件**逐条写 `D`/`DN` 行） | 原样 |
| `OurDamageFunc` 快照 | `snap.amount` 在 native 下按【float 位模式】用 `Wc3RealBits`（v1.3.12+；结构体字段不是指针）；目标/来源句柄走 `ObjToHandle`；加 native 专属 `DN` 行 | JAPI 下走原来那支 |
| `g_gameThreadId` 的声明 | 从 §7.8 前移到 §4.1（native 字符串表助手要用它） | 纯移动，语义不变 |
| 配置日志行 / 版本行 / ini 模板 | 加 `backend=%d`；v1.2；加 backend 说明段 | 多字段/多注释 |
| **v1.3（B 计划）**：`ShowMessage` 拆成 `ShowMessageAt(锚点, 文本)` + `Wc3EmitTextTag`（折行）+ `Wc3EmitOneTag`（单段）；新增 `Wc3PrepareTextTagNatives`/`Wc3TtResolve`/`TagAnchorPick`/`Wc3TagRememberUnit`/`Wc3SplitText`/`Wc3WrapSelfTest`；伤害明细与统计结算改为**带锚点**显示 | 见上表第一行与 §3.3 | JAPI 下同样改成飘字 |
| `DllMain`（`DLL_PROCESS_DETACH`） | 加 native 内联钩子还原（把偷走的序言从跳板抄回） | 分支不成立 → 原样 |
| `DoInitialize` 的 `if (!g_ydbase)` 块 | `auto` → 转 native；`japi` → 保留原中止措辞 | `japi` 下只多半句提示 |

---

## 3. native 模式下的行为与限制（**本轮已更新**）

### 3.1 现在做得到的
* **被 WFE / 平台 JAPI 抢先挂钩时的链式挂钩（v1.3.10）**：WFE 的伤害数字系统会先把引擎伤害函数
  入口改成 `E9 rel32`（跳到 `WFEDll.dll+0x584C0`），我们靠入口序言定位就会 0 命中。
  现在改为：用**唯一的尾部序言**（`func+6` 起 10 字节）认出函数 → **钩 WFE 的处理函数**（而不是硬改入口）
  → 跳板执行它的头几字节再交回它。`native_chain=1` 默认开；连尾部序言都命中不了才安全退出。
  另外：若跳转目标是**我们自己**（DLL 被两个加载器注入两次），只写日志、不再挂钩。
* **无 ydbase 也能初始化 + 挂钩**：解析 PE、扫序言定位 `Game.dll+0x67DC40`、
  内联挂钩（偷 6 字节 `55 8B EC 83 EC 2C`，跳板回原函数），`ORIG_DAMAGE` 从跳板取。
* **每一笔伤害都完整写日志**（v1.3.3 起分两档）：
  * `debug=0`（默认）：每笔写一行 `H 来源:… 目标:… 拥有者:… 攻击:… 远程:… 攻击类型:… 伤害类型:… 伤害:… 武器:… 生命:…`；
  * `debug=1`：另加原有 `D ...` 原始字段行与 native 专属 `DN native=1 ...` 行。
  * 触发条件：**开启明细（`mode != 3`）就逐条写**（用户规则③）；`log_events=1` / `log_only=1` 可强制。
* **上屏**：v1.3.3 起 native 默认不显示（只写日志）；**v1.3.8 起可用 ini 的 `native_show=1`
  让 native 也上屏** —— 引擎直连 `DisplayTimedTextToPlayer`(RVA `0x1DFE70`)，
  参数形态与 JAPI 路径一致（玩家传值、x/y/duration 传 `float*`、字符串传 `MakeJassString` 造的
  `string_fake` 对象指针）。也就是说"没有 JAPI 就没有消息区"并不成立。
* **单位名 / 玩家名可用**（本轮新增）：`GetUnitName`(`0x1E6340`) / `GetPlayerName`(`0x1E3D40`)
  返回字符串 id → 引擎字符串表反查成 `char*`（原样拼接，不再转码），所以日志与屏幕里显示的是**真名字**，
  不再退化成 `uske`/`#句柄`。
* **文本编码判定照做**：`DetectGameTextEncoding` 在 native 下用 native 取到的玩家名/单位名投票，
  所以中文标签（`labels=1`）在 native 下同样可用；判不出来仍自动退回 ASCII。
* 热键（Ctrl+Alt+0/1/2/3/R/T/Q/S）照旧；`Ctrl+Alt+R` 走**纯内存读选区**
  （不建组、不调选区 native、不分配句柄），native 下也能工作。

### 3.3 ★ B 计划：屏幕输出全部改走 TextTag（飘字）族（v1.3）—— **已于 v1.3.3 废弃**

> 🚫 **本节描述的"飘字显示"已在 v1.3.3 整体删除**（用户反馈观感差、且要求"有 JAPI 才显示、没 JAPI 不显示"）。
> 现在：**有 JAPI → 消息区 `DisplayTimedTextToPlayer`；没有 JAPI → 完全不显示，只写日志**。
> 本节与 §3.4 保留下来只作**逆向记录**（TextTag 整族 RVA、ABI、S 参数形态），代码里已经没有这些调用。

**决策**：显示通道从"消息区 `DisplayTimedTextToPlayer`"整体换成引擎的 **TextTag（飘字）**，
native 与 JAPI 两个后端共用同一套语义。理由：TextTag 才是引擎自己的"浮在单位头上的字"
（WFE 那类伤害数字的做法），且整族 RVA 已在 `无JAPI模式逆向.md` **附录 A** 全部确证。

**用到的 13 个 native（名字都进 native 表 A，RVA 只作兜底/对照）**：

| native | 本文用到的调用形态 | RVA |
|---|---|---|
| `CreateTextTag` | `()Htexttag` | `0x001DEA90` |
| `DestroyTextTag` | `(Htexttag;)V`（异常收尾时兜底销毁） | `0x001DF760` |
| `SetTextTagText` | `(tag, 字符串对象指针, &size)` ★ 整族唯一带 `S` 的；**S = `string_fake*`，不是 id** | `0x001F6F70` |
| `SetTextTagPosUnit` | `(tag, Hunit, &zOffset)` ★ 飘字绑单位 | `0x001F6ED0` |
| `SetTextTagVelocity` | `(tag, &vx, &vy)` 上飘 | `0x001F6FC0` |
| `SetTextTagColor` | `(tag, 255,255,255,255)` 白色底；颜色由正文里的 `\|cffRRGGBB` 带 | `0x001F6D30` |
| `SetTextTagLifespan` / `SetTextTagFadepoint` | `(tag, &秒)` 到点自动销毁 | `0x001F6DC0` / `0x001F6D80` |
| `SetTextTagPermanent` | `(tag, 0)` = 非永久（**必须**，否则飘字永不消失） | `0x001F6E00` |
| `SetTextTagVisibility` | `(tag, 1)` | `0x001F7020` |
| `SetTextTagPos` / `SetTextTagAge` / `SetTextTagSuspended` | 已解析、当前未用（留给"不绑单位"的场景） | `0x001F6E30` / `0x001F6CF0` / `0x001F6F40` |

**★★ R 参数 = 指向 float 的指针**（与 DTTTP 同一套 ABI，逐字节确证：
`0x1F6F9A mov ecx,[ebp+0x10]` → `0x1F6F9D movss xmm0,[ecx]`）。
`无JAPI模式逆向.md` 附录 D 里那份可粘贴代码把 R 写成"传值"，**是错的**，照抄一条都显示不出来。
本实现按"指针"调，并留了一道**运行期 ABI 自证**：第一次调用若抛异常，就自动翻成"传值"形态
并写一行 `W TextTag：按【指针】调 R 参数抛异常…`（两种构建都能活）。

**锚点**：TextTag 必须绑一个单位，而引擎没有"取摄像机世界坐标"的 native（`SetTextTagPos`
要的是世界坐标），所以按优先级挑：
① 调用方显式给的单位（伤害明细 = 受伤单位；统计结算 = 被记账的单位）→
② 最近一次伤害事件的单位（`Wc3TagRememberUnit`）→
③ 当前选中单位（复用选区纯内存读，失败带 3 秒冷却，避免每行都刷日志）→
④ 正在记账的单位。
四个都取不到时**只写日志**（`W TextTag：还没有可用锚点…`），绝不猜坐标乱飘。

**连发堆叠**：一行 = 一个飘字（TextTag 不认 `|n`）；同一轮（1.2 秒内）连发的多行按
`tt_stack` 逐行往上叠，超过 `tt_max_lines` 的只进日志（防 AOE 刷屏）。

**长行折行**：一行超过 `tt_wrap` 个显示列（中文算 2 列）就自动折成下一段、每段一个飘字
（伤害明细那种 80+ 列的长行会折成 2~3 段，否则会横穿屏幕）。折行时颜色码不计列数，
跨段的颜色会重新插到新段开头并在段尾补 `|r`。这段逻辑在启动时由 `Wc3WrapSelfTest()` 自证
（所有段的可见字符拼接必须与原串逐字节相同、每段列数不超限），日志写一行
`TextTag wraptest: OK n=5 wrap=42`；自检程序会断言这一行。

**新增 ini 键**：`tt_lifespan`(2.0) / `tt_size`(0.024) / `tt_velocity`(0.045) / `tt_stack`(90.0) /
`tt_max_lines`(24) / `tt_wrap`(42)，越界值会被兜回默认（配置日志里会打印最终生效值）。

**v1.3.1：屏幕精简、日志补全**。按用户要求，伤害明细的飘字**只显示数字**：
`是否攻击/是否远程/攻击类型/伤害类型 伤害值`（例 `1/0/5/4 154.7`），
不再拼来源名/目标名/武器/生命（那些信息在单位就在眼前的飘字里是冗余，还会把一行撑到 80+ 列）。
对应地：
* `show_hp` / `show_weapon` / `show_owner` 默认改为 **0**，语义变成"往数字后面**追加**"（可选回旧观感）；
* 日志新增 **`H` 行**（`来源名(句柄) 目标名(句柄) 拥有者 攻击/远程/攻击类型/伤害类型/伤害/武器/生命`），
  与 `D`（引擎原始字段）、`DN`（native 结构头 8 个 dword）合起来 = **每一笔伤害的完整记录**，
  不受屏幕精简影响；`H` 行同样在 `wantEventLog` 里（native 下无条件）；
* 日志行数上限由固定 20 万改成 ini 的 `log_max_lines`，**默认 0 = 不设上限**（"日志保留完整的"）。

**v1.3.1 续：统计块同样压短**。`PrintTrackSummary` 的屏幕部分改成
`[统计] 名(码) 死|当前 次数/总伤害` + `  a/r/at/dt 次数 伤害 占比%` + `  来自 名(码) 次数 伤害 占比%`，
删掉那两行 40~60 列的说明文字（"联合统计 攻击/远程/攻击类型/伤害类型 -> …"、"按来源单位类型 …"），
使每个飘字都短到**不会触发折行**；被删掉的中文标签版**原样保留在日志**里
（`统计 …（联合统计 攻击/远程/攻击类型/伤害类型）` / `%d/%d/%d/%d: n 次 / dmg (pct%)` /
`按来源单位类型（伤害占比）：…`）。「无记录」提示也压成 `[统计] 无记录`。

**怎么判"到底飘没飘"**：日志里前 3 次成功会写
`TextTag：unit=… str=<字符串对象指针> z=… 文本=…`（JAPI 下是 `TextTag(JAPI)：…`）；
失败会写 `W/E TextTag：…`。屏幕上没字但日志有 `TextTag：unit=` ⇒ 是显示层的问题（字号/位置/单位句柄）；
日志里全是 `E TextTag：SetTextTagText 抛异常(C0000005)` ⇒ 字符串参数形态不对（见 §3.4）。

### 3.4 ★★ v1.3.2 关键修正：`S` 参数是【字符串对象指针】，不是 id

**症状**：`backend=native` 时屏幕上一个字都没出，日志每笔都有
`E TextTag：SetTextTagText 抛异常(code=C0000005)`（JAPI 路径同一份代码却正常显示）。

**根因**：本文件早先按 `无JAPI模式逆向.md` §2.4 的结论，把 TextTag 的字符串参数当成
"字符串 id"（用 `Wc3MakeStringIdCached` 造出来）传进去。但引擎侧 `S` 的解析（RVA `0x516F0`）是：

```
0x516F0: mov eax,[ecx+0x08]   ; [S+0x08] = 字符串对象
0x516F3: test eax,eax / je    ; 0 -> NULL
0x516F7: mov eax,[eax+0x1C]   ; [对象+0x1C] = char*
0x516FA: ret
```

⇒ `S` 要的是 **`string_fake` 对象指针**；传 id（小整数）会让引擎去读 `[id+8]` ⇒ **C0000005**。

**修法**：native 分支改成 `const uint32_t sObj = MakeJassString(text);` 再
`SetTextTagText(tag, sObj, &size)` —— 与 JAPI 路径**同一套字符串对象**（`MakeJassString` 是
自足的静态池：`+0x08`=自身、`+0x1C`=正文，不依赖 ydbase）。
`Wc3MakeStringId*` / `Wc3StringTableSelfTest()` 已整体删除（显示路径不再需要造 id）；
`0x1DA520` 的 RVA 只留作逆向记录。

**顺带确证的另外三条 ABI**（都以同一份 `Game.dll` 逐字节复核）：

| native | 确证内容 |
|---|---|
| `SetTextTagPosUnit` | 第 2 参数是 **Hunit 句柄**，内部直接 `call 0x1D1550`（Hunit→CUnit*）；第 3 参数 `float*` |
| `SetTextTagVelocity` | vx / vy **都是 `float*`**（`movss xmm1,[ecx]` / `movss xmm0,[ecx]`） |
| `SetTextTagColor` | 4 个整数顺序 = **(red, green, blue, alpha)**（打包字节：byte0←参数3、byte1←参数2、byte2←参数1、byte3←参数4）；传白色时顺序无关，所以插件现在传 `255,255,255,255` |
| `SetTextTagPermanent` | 只改 tag 对象 `+0x30` 的 **bit3**（`or/and …, 8`），**不动** lifespan（`+0x1C`）⇒ 与 Lifespan 的调用先后无关 |

### 3.2 限制与保守设计
* **聊天命令仍然不可用**：定位 `InGameChatWhat` 依赖 ydbase 的搜索器，native 下跳过挂接并写日志
  （启动时一行说明）。`@0/@1/@2/@3/@名字/@?/@!` 都不生效；热键不受影响。
* **字符串对象用静态池**：`MakeJassString()` 在 64 个槽位里轮转（每槽 768 字节正文）。
  引擎在 `SetTextTagText` 内部就把正文**拷贝**进自己的 `std::string`（§3.4 证据里有
  `std::string::assign`），所以槽位被复用不会影响已建好的飘字。
* **只在游戏线程动引擎对象**：`Wc3OnGameThread()` 把关。伤害钩子本来就在游戏线程；
  热键是"回投到游戏窗口 → 游戏线程"。若窗口没找到（极少数情况）回退到热键线程执行，
  这时 native 显示会被拒绝（写一行 W 日志），只写日志、不崩。
* **失败一律降级，不影响伤害**：造不出字符串对象/TextTag native 缺失/任一调用抛异常
  → 只写日志（前几条会带上句柄便于排查，之后不再刷屏）。
* **无 JAPI 时也没有"名字退路"**了：`UnitNameText` 失败时才退回 4 字符类型码 / `#句柄`。
* **版本**：native 目前只支持 1.27.0.52240 那一代 `Game.dll`（靠固定 RVA + 序言唯一定位）。
  版本不符时表现为"序言命中 0 次 → 安全退出"，不会误挂。
* **仍未在真机验证**的点（下一阶段）：`object→handle` 定型、`GetUnitState` 的 real 解引用、
  以及**屏幕上实际出字**。这三处都写了明确的自证日志，取不到时只会"少显示"，不会崩。

---

## 3.9 ★★ v1.3.13 实机纠错：`GetUnitState` 的返回值是 **float 位模式**，不是 real 句柄

真机日志（WFE 注入、native 后端）里 **304 条 `H` 行全部是 `生命:0.0/0.0`、`拥有者:?`**，
且 18 次死亡结算**每一次都是 `次数=1`**（`开始记录` 与 `死亡结算` 同一毫秒）——顺着这条线反汇编
`Game.dll RVA 0x1E6600`（`GetUnitState`，反汇编存 `_build/watcher/an_gus2.txt`）：

```
0x1E6604: mov esi,[ebp+0xC]      ; esi = unitstate（0..3 = LIFE/MAXLIFE/MANA/MAXMANA）
0x1E6607: cmp esi,4  /  jl 0x1E6614
0x1E6614: mov ecx,[ebp+8]        ; hunit
0x1E6617: call 0x1D0950          ; Hunit -> CUnit*
0x1E662C: call 0x668F40          ; CUnit::GetState(state, &out)  -> 返回 float*
0x1E6632: mov eax,[eax]          ; ★★ 解引用：返回值 = float 的【位模式】（在 EAX 里）
```

**结论（与"real 作为参数 = `float*`"并不矛盾）**：

| 位置 | 形态 |
|---|---|
| JASS real 作为**参数**传进 native | `float*`（引擎内部 `movss xmm,[eax]` 解引用，见 §4.2） |
| native **返回**一个 real | EAX = **float 位模式**（本函数 `mov eax,[eax]` 就是证据；ydbase 的 `to_real` 也正是恒等） |
| 伤害结构体里的 `amount` 字段 | 同样是 float 位模式（v1.3.12 已用 `Wc3RealBits` 修好） |

**旧实现的错**：`Wc3GetUnitStateValue` 把返回值当 real 句柄用 `Wc3RealValue`（解引用指针）读
→ 位模式当地址 → 读不到 → **恒返回 `0.0f`**。后果不只是日志难看：

1. `H` 行 `生命:0.0/0.0`、`拥有者:?`、名字退化成类型码；
2. **致命**：`TrackOnDamage` 的死亡判定是 `hp <= 0.0f` → **每一笔伤害都被判成"打死了"**
   ⇒ 记录在第一次受伤时就结算（`次数=1`）、该单位被标 `dead`
   ⇒ 之后每一笔伤害都走进"尸体继续挨打：不记账"分支被丢掉
   ⇒ 玩家看到的现象就是**"死亡结算只统计到一次伤害"**（与 `track_min_damage` 无关，它只是第二层巧合）。

**修正（v1.3.13）**：改用 `Wc3RealBits(r)`；并加一道防御——
`GetUnitState(MAXLIFE) <= 0` 时认为"生命不可用"，**不做死亡判定**（只记账 + 写一行日志），
这样以后任何版本/ABI 再错也不会把整场统计判成"一直死"。


---

## 4. ★ 重要更正（对真实 `Game.dll` 逐字节复核得出）

### 4.1 `无JAPI模式逆向.md` 里"辅助函数"的地址是**文件偏移**，不是 RVA

该报告自己说明 `文件偏移 = RVA − 0xC00`，但 §4 的辅助函数表填的是文件偏移：

| 报告里的值 | 真实 RVA | 复核方式（本轮） |
|---|---|---|
| `0x001D0950`（`Hunit → CUnit*`） | **`0x001D1550`** | `0x1D0950` 处是 `74 36`（函数体内部的 `jz`）；`0x1D1550` 处 `55 8B EC 6A FF 68 …`（带 SEH 的标准函数序言），全 `.text` **191** 处 `call 0x1D1550`（`GetUnitTypeId/GetUnitName/GetUnitState/GetOwningPlayer` 的调用点全部命中） |
| `0x001C2600`（`ctx → 句柄管理器`） | **`0x001C3200`** | `0x1C3200` 处 `83 79 1C 00 56 8D 71 1C …`（正文就是 `mov eax,[ecx+0x1C]`），**338** 处 `call`；`GetLocalPlayer 0x1E3182`、`GetOwningPlayer 0x1E3BC1` 都调它 |
| `0x002645D0`（`对象 → 句柄`） | **`0x002651D0`** | `0x2651D0` 处 `55 8B EC 51 53 8B 5D 08`，**147** 处 `call`；函数内 `C2 08 00`（`ret 8`）与 `05 00 00 10 00`（`add eax,0x100000`）都对得上 |
| `0x0001D9920`（`字符串 id → 字符串句柄`） | **`0x001DA520`** | 就是本轮的"造字符串 id"；`0x1D9920` 处是 `E5 FF 50 8B …`（函数体内部），`0x1DA520` 处 `85 C9 75 03 33 C0 C3 …`（父代理给的就是这个正确值） |
| `0x0001C1C70`（`id → char*`） | **`0x001C2870`** | `0x1C2870` 处 `55 8B EC 8B 45 08 8B 49 20 … C2 04 00`（`ret 4`）、正文 `mov eax,[eax+0x18]`，7 处 `call`，其中一处就在 `0x1FAE24`（DTTTP 的 S 参数解析链） |
| `0x0001FAE20`（S 参数解析） | `0x001FBA20`（仅记录，未使用） | `0x1FAE20` 处是函数体尾部（`33 C9 83 F8 FF 5E 0F 44 C1 5D C3`） |

**危害**：按报告原值调用会跳进函数体中间 —— `0x1D0950` 是 `74 36`（条件跳转），
被当函数入口调用会破坏调用者栈，不是"取不到"而是**可能直接崩游戏**。
所以本文件里这些 RVA 全部用**真值**，并且强制带**首 3 字节序言轻校验**
（`55 8B EC` / `55 8B EC` / `83 79 1C` / `85 C9 75`），这类错误以后会被日志当场挡下。

顺手修正的两处同源错误：
* 纯内存路线的句柄下标：ydbase 里指针按 12 递增、计数器按 3 递增、最后再 `÷3`，
  所以 `handle = 0x100000 + k`（表项序号），**不是** `0x100000 + i`（字节步进）；
* `ctx → 管理器` 是 `*(ctx+0x1C)`（访问器 `0x1C3200` 的返回），不是报告写的 `ctx+0xF4`。

### 4.2 ★★ `DisplayTimedTextToPlayer` 的 x / y / duration 是**指向 float 的指针**

范围更新里写的是"传真 float"，但逐字节看 `0x1DFE70` 的实现**并非如此**：

```
0x1DFE97: 8B 45 0C        mov  eax,[ebp+0x0C]     ; 参数2 (x) —— 取到的是个【指针】
0x1DFEA3: F3 0F 10 10     movss xmm2,[eax]        ; ★ 再解引用才拿到 float
0x1DFEA7: F3 0F 10 01     movss xmm0,[ecx]        ; 参数4 (duration)：ecx 来自 [ebp+0x14]
0x1DFEB5: F3 0F 10 09     movss xmm1,[ecx]        ; 参数3 (y)：ecx 来自 [ebp+0x10]
```

所以正确原型是 `(uint32 hplayer, const float* x, const float* y, const float* dur, uint32 strId)`。
**传值会让引擎去解引用那个位模式**：`x = 0.0f` 的位模式就是 `NULL` ⇒ `movss xmm,[0]`
⇒ 访问违例（我们外层 `__try` 会吞掉，表现为"一条都不显示"＋`E native 显示：调用抛异常`）。
这也和 JASS 的 real 传参约定（传 `&jreal`）以及本文件 `Wc3RealValue`（real = 指向 float 的句柄）
完全自洽：**整个引擎里 R 参数 = float\***。

**独立工具复核**（`_tools\an\bin\an.exe D:\war5\Game.dll dump 0x1DFE70 0x60`，与本文件的字节解读一致；
`mov r0, ebp+0xC` = `mov eax,[ebp+0xC]`，`sse10 xmm2, eax` = `movss xmm2,[eax]`）：

```
0x001DFE8A: mov r1, ebp+0x18        ; 第 5 参数 = 字符串 id
0x001DFE8D: call 0x1FAE20           ; id -> char*（本文件用 0x1C2870 那条更直接的路径）
0x001DFE95: mov r2, eax             ; edx = char*
0x001DFE97: mov r0, ebp+0xC         ; ★ eax = 【参数2 的指针】
0x001DFEA0: mov r1, ebp+0x14        ; ★ ecx = 【参数4 的指针】
0x001DFEA3: sse10 xmm2, eax         ; ★★ movss xmm2,[eax] —— 解引用！x 是 float*
0x001DFEA7: sse10 xmm0, ecx         ; ★★ duration 同理
0x001DFEAB: mov r1, ebp+0x10        ; ★ y 的指针
0x001DFEB5: sse10 xmm1, ecx         ; ★★ movss xmm1,[ecx]
```

> ⚠️ 并行的另一份专项报告 `无JAPI模式-动态字符串id.md` 的示例代码里写的是
> `typedef void (__cdecl *fn_DTTTP_t)(uint32_t, float, float, float, uint32_t)`（传真 float）。
> **那个原型是错的**（同上逐字节证据）：照它写会一条都显示不出来。
> 该报告的其它结论（`0x1DA520` 造 id、`0x1C2870` 反查、必须游戏线程、缓存/限流）
> 与本实现一致，本文件已采纳。

### 4.3 其余 RVA 复核结论（可直接使用，均为**真 RVA**）
`0x67DC40`（伤害函数，16 字节序言在 `.text` 内**唯一命中**）、`0x1E9A50`（名表 A 起点，1167 条后模板校验自然中断）、
`0x1DFE70`（DTTTP）、`0x1DA520`（造 id）、`0x1C2870`（id→char\*），
以及 6 个 native 实现 `0x1E3150 / 0x1E3D20 / 0x1E3BA0 / 0x1E8040 / 0x1E6600 / 0x1E6670`
（后 6 个运行期**按名字查表**得到，日志里逐个与期望 RVA 对上了）。

---

## 5. 怎么在单机验证 native 路径

1. `UDamageWatcher.ini` 里的 `backend` 现在默认是 **`auto`**（有 ydbase 走 JAPI/能显示，没有则转 native）。
   **想强制验证 native 路径**就把它写成 `native`（装了 ydbase 也走引擎直连，并且不再等 ydbase）——
   注意此时**屏幕上一律不显示**，只能看日志。
   > ⚠️ **代价**：`backend=native` 时不加载 ydbase，所以**聊天命令 `@0/@1/@2/@3/@名字/@?/@!` 全部不可用**
   > （定位 `InGameChatWhat` 需要 ydbase 的搜索器）。改用热键 `Ctrl+Alt+数字/R/Q/S`，功能完全一样
   > 且不会把命令广播给别人。
2. 进图打一次怪，看 `UDamageWatcher.log`：
   * `backend=native：强制走引擎直连（跳过 ydbase 等待与 JAPI 路径）`；
   * `native: ctx = *(Game.dll + 0xBE4238) = XXXXXXXX（非 0，字符串表/句柄转换可用）` ← **必须非 0**；
   * `native 解析：…`（TextTag 整族 + 其它 native）每行都要 `校验=OK`；
   * `native: 引擎伤害函数 = XXXXXXXX（Game.dll + 0x67DC40，序言命中唯一 √）`；
   * `已挂接引擎伤害函数（native 内联钩子）：目标=… 偷 6 字节 跳板=…`；
   * 每笔伤害三行：`D ...` + `DN native=1 ...` + `H 来源:… 目标:… 拥有者:… 攻击:… 伤害:… 武器:… 生命:…`；
   * 首次显示：`TextTag：unit=… str=… z=… 文本=…`（前 3 条），屏幕上应出现同样的飘字；
     若看到 `E TextTag：SetTextTagText 抛异常(C0000005)` ⇒ 字符串参数形态不对（见 §3.4）；
   * 取到名字时：`T 字符串 v=… 走 native 引擎表 -> …`（前 4 条）；
   * 句柄/血量：`native obj->handle 定型：…（回程校验一致 √）`、`native GetUnitState(…, 0) = real … -> …`。
3. 屏幕上看不到、但日志有 `W TextTag：…` ⇒ 按 §3.3 与 `伤害监视说明.md` §9.14 的三道关卡排查
   （最常见：ctx=0／字符串自检不过／不在游戏线程／没有单位锚点）。
4. 回归 JAPI 路径：`backend=auto`（有 ydbase 时）或 `japi`。

---

## 6. 编译 / 自检 / 端到端证据

编译（`_build\watcher\cl_n1.cmd`，GBK + CRLF，`> 日志 2>&1` 后 `cmd /c`）：

```
UDamageWatcherHook.cpp
  正在创建库 ...\UDamageWatcher.lib 和对象 ...\UDamageWatcher.exp
CL_EXIT=0                    ← 0 错误 0 警告（/W3）
```

自检（`run_smoke_n1.cmd` → `UDamageWatcherSmoke.exe <dll>`）：

```
backend=auto 且进程里没有 ydbase.dll：改用 native 模式（引擎直连 Game.dll）
native: 未找到 Game.dll（game.dll）模块 —— 本进程里没有游戏，native 路径不可用
初始化中止：未找到 Game.dll（native 模式需要它），安全退出（游戏不受影响）
RESULT: PASS
SMOKE_EXIT=0
```

（`未找到` / `安全退出` / `ydbase.dll` / `enable=` / `UDamageWatcherHook` 五条断言全满足；`UDamageWatcherSmoke.cpp` 一字未改。）

### 6.1 `backend=native` / `backend=japi` 强制分支（无 Game.dll 的宿主）

```
-- _selftest\m_native\UDamageWatcher.log --
backend=native：强制走引擎直连（跳过 ydbase 等待与 JAPI 路径）   ← 没有等 ydbase
初始化中止：未找到 Game.dll（native 模式需要它），安全退出（游戏不受影响）

-- _selftest\m_japi\UDamageWatcher.log --
未找到 ydbase.dll（等到超时，共 1 秒）
初始化中止：未找到 ydbase.dll，安全退出（游戏不受影响）          ← 原措辞保留
```

### 6.2 端到端：把真实 `Game.dll` 映射进测试进程

用 32 位 Windows PowerShell 做宿主：`LoadLibraryExW("D:\war5\Game.dll", 0, LOAD_LIBRARY_DONT_RESOLVE_DLL_REFERENCES)`
（只映射、不跑 DllMain、不解析导入、**不写游戏目录**），再加载插件 DLL 并调 `Initialize()`。
脚本 `_build\watcher\e2e_native.ps1`；日志 `_selftest\m_auto2\UDamageWatcher.log`（`backend=auto`，无 ydbase）
与 `_selftest\m_native2\UDamageWatcher.log`（`backend=native`）。

```
-- m_auto2（backend=auto，无 ydbase）--
未找到 ydbase.dll（等到超时，共 1 秒）
backend=auto 且进程里没有 ydbase.dll：改用 native 模式（引擎直连 Game.dll）
---- native 后端（无 ydbase / 引擎直连 Game.dll）----
native 模式：显示走引擎直连（造字符串 id RVA 0x1DA520 + DTTTP RVA 0x1DFE70），聊天命令仍不可用（需要 ydbase 搜索器），热键照旧
native: Game.dll 基址=688B0000 文件大小=13187048 路径=D:\war5\Game.dll
native: ctx = *(Game.dll + 0xBE4238) = 00000000（0 —— 地图还没起来或版本不符，取名字/上屏会退化成只写日志）
native 解析：GetLocalPlayer         = 68A93150（base 688B0000 + RVA 0x1E3150；期望 0x1E3150 一致；来源=名表A；序言 56 8B 35 38）校验=OK
native 解析：GetPlayerId            = 68A93D20（base 688B0000 + RVA 0x1E3D20；期望 0x1E3D20 一致；来源=名表A；序言 55 8B EC 8B）校验=OK
native 解析：GetOwningPlayer        = 68A93BA0（base 688B0000 + RVA 0x1E3BA0；期望 0x1E3BA0 一致；来源=名表A；序言 55 8B EC 8B）校验=OK
native 解析：IsPlayerAlly           = 68A98040（base 688B0000 + RVA 0x1E8040；期望 0x1E8040 一致；来源=名表A；序言 55 8B EC 8B）校验=OK
native 解析：GetUnitState           = 68A96600（base 688B0000 + RVA 0x1E6600；期望 0x1E6600 一致；来源=名表A；序言 55 8B EC 56）校验=OK
native 解析：GetUnitTypeId          = 68A96670（base 688B0000 + RVA 0x1E6670；期望 0x1E6670 一致；来源=名表A；序言 55 8B EC 8B）校验=OK
native 解析：DisplayTimedTextToPlayer = 68A8FE70（base 688B0000 + RVA 0x1DFE70；期望 0x1DFE70 一致；来源=名表A；序言 55 8B EC 8B）校验=OK
native 解析：GetUnitName            = 68A96340（base 688B0000 + RVA 0x1E6340；期望 0x1E6340 一致；来源=名表A；序言 55 8B EC 8B）校验=OK
native 解析：GetPlayerName          = 68A93D40（base 688B0000 + RVA 0x1E3D40；期望 0x1E3D40 一致；来源=名表A；序言 55 8B EC 8B）校验=OK
native 解析：make_string_id         = 68A8A520（base 688B0000 + RVA 0x1DA520；期望 0x1DA520 一致；来源=RVA兜底；序言 85 C9 75 03）校验=OK
native 解析：string_by_id           = 68A72870（base 688B0000 + RVA 0x1C2870；期望 0x1C2870 一致；来源=RVA兜底；序言 55 8B EC 8B）校验=OK
native 解析：Hunit->CUnit*          = 68A81550（base 688B0000 + RVA 0x1D1550；期望 0x1D1550 一致；来源=RVA兜底；序言 55 8B EC 6A）校验=OK
native 解析：obj->handle            = 68B151D0（base 688B0000 + RVA 0x2651D0；期望 0x2651D0 一致；来源=RVA兜底；序言 55 8B EC 51）校验=OK
native 解析：ctx->handlemgr         = 68A73200（base 688B0000 + RVA 0x1C3200；期望 0x1C3200 一致；来源=RVA兜底；序言 83 79 1C 00）校验=OK
native: .text = 688B1000 大小 = 9752218 字节，开始扫 16 字节序言
native: 引擎伤害函数 = 68F2DC40（Game.dll + 0x67DC40，序言命中唯一 √）
native: 组合特征码复核（Game.dll + 0x67DCC5）通过 √
已挂接引擎伤害函数（native 内联钩子）：目标=68F2DC40 偷 6 字节 跳板=07980000 our=6CC05FD0
校验结果：OK
聊天命令：native 模式跳过挂接（定位 InGameChatWhat 需要 ydbase 的搜索器），聊天命令本次不可用；热键照旧启用
热键：已启用（Ctrl+Alt+0/1/2/3 切显示模式，R/T 记录选中单位，Q 看统计，S 立刻结算），pick=0…
初始化完成（native 模式）。进游戏打一次怪即可看到日志。
```

注意：
* `Game.dll` 被映射到**非首选基址** `0x688B0000`（首选 `0x6F000000`），所有 `基址+RVA` 换算与序言扫描依然正确 ⇒ ASLR 写法正确。
* 16 字节序言在真实 `.text`（9,752,218 字节）里**唯一命中**，组合特征码复核通过。
* `InstallDetour` 在真实序言上偷到的正是预期的 6 字节（`55 8B EC 83 EC 2C`）。
* 该宿主里 `ctx = 0`（引擎没被 war3.exe 驱动起来），所以**上屏那一步无法在这个宿主里验证**；
  引擎真的调用伤害函数、屏幕上真的出字，必须在游戏里验证（本阶段按要求**没有启动游戏**）。

### 6.3 产物（两处 DLL + 构建产物）

```
<WS>\_build\watcher\UDamageWatcher.dll
<WS>\warcraft3\UDamageWatcher.dll
D:\fsdownload\wc3gamesearcher\WFE\Application\Libraries\UDamageWatcher.dll
SHA256(三处相同) = 3181F49FA97319684D1B36199BECEC3BC37910C1C99BAB9BED40F38A350EFB91
（216,064 字节；两处目标都没被占用，复制成功）
```

---

## 7. 还没做的部分（下一阶段清单）

1. **聊天命令**：native 下没有 `InGameChatWhat` 的定位手段（要自己按特征码找，属下一阶段）。
   现在完全不挂，只有热键可用（`@0/@1/@2/@3/@名字/@?/@!` 无效）。
2. **真机验证**（本阶段无游戏进程，只有静态 + 宿主级证据）：
   ① 屏幕上是否真的出字（`native 显示自检` + `native 显示：…` 两条日志能直接判定）；
   ② `object→handle` 定型（`native obj->handle 定型：…（回程校验一致 √）`）；
   ③ `GetUnitState` 的 real 解引用（`native GetUnitState(…, 0) = real … -> …` 打印的数值是否等于真实血量）；
   ④ 单位名/玩家名反查（`T 字符串 … 走 native 引擎表` 的文本是否正确）。
   这四项都有明确的自证日志，任一项不成立只会"少显示"，不会崩。
3. **TextTag 飘字**（比 DTTTP 更贴近 WFE 的"飘在单位头上的伤害数字"）：报告附录 A 的 13 个 RVA 已确证，
   且 `SetTextTagText` 的字符串参数也是 id ⇒ 现在有了 `Wc3MakeStringId` 就可以直接做，属下一步增强。
4. **多版本**：目前只认 1.27.0.52240 一代（固定 RVA + 唯一序言）；不匹配时安全退出。
5. `UDamageWatcherSmoke.cpp` 未新增断言（它只能在无 Game.dll 的宿主里跑）；
   本轮新增证据来自 `_build\watcher\e2e_native.ps1` 等 `_build` 下的临时测试宿主（不是插件的一部分）。
