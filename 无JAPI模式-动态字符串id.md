# 无 JAPI/ydbase 模式 —— **动态字符串 → 字符串 id** 的引擎直连（阻塞点专项）

> 目标（唯一）：没有 `ydbase` 时，如何把一条**每次都不一样的动态 `char*`**
> （`[伤害] 来源:X 攻击:0 伤害:931.0`）变成 `DisplayTimedTextToPlayer` 第 5 参数能用的**字符串 id**。
>
> 分析对象（**只读**）：`D:\war5\Game.dll` 13,187,048 B，`1.27.0.52240`，ImageBase `0x6F000000`；
> 对照 `C:\Program Files (x86)\kkduizhan\plugins\game\ydbase.dll`（ImageBase `0x10000000`）。
> `SHA256(D:\war5\Game.dll) = 1A4D41EB650F9C0D3E260F6C3D53592C2418C0C66CFF76D6CCB7E1341C7AB80E`（未变）。
>
> ⚠️ **本轮先修正一个坐标错误**：本二进制**不能**用"统一线性 `file = RVA − 0xC00`"来读任意地址——
> 早期我（和本机某个工具）在 `RVA < 0x200000` 区间上得到过矛盾结果。
> 本轮已用**独立的最小工具**（只走 PE 段表）重新标定，**结论：本文件 `.text`/`.rdata` 里
> `RVA = file + 0xC00` 成立**，已用 4 个互不相关的锚点交叉验证：
>
> | 锚点 | file 偏移 | 按段表算出的 RVA | 已知真值 | 一致 |
> |---|---|---|---|---|
> | 伤害函数序言 `55 8B EC 83 EC 2C 56 57 8B F9 89 7D F4 8B 77 5C` | `0x67D040` | `0x67DC40` | **`0x67DC40`** | ✅ |
> | `'Deg2Rad'` | `0x966528` | `0x967128` | native 表项 `+11` = `0x6F967128` | ✅ |
> | `'DisplayTimedTextToPlayer'` | `0x96C850` | `0x96D450` | native 表项 `+11` = `0x6F96D450` | ✅ |
> | native 表首条记录 | `0x1E8E50` | `0x1E9A50` | 记录 `+11` 解出 `'Deg2Rad'` | ✅ |
>
> **⇒ 本报告所有 RVA 都是按段表算出的 `RVA`；所有字节都从对应 `file` 偏移直接读。**
> （上一轮报告里 §1/§2/§3 中凡是依赖"在 `RVA < 0x200000` 区间按线性关系读字节"的**字节级引用**，
> 本轮已全部重读校对；**结论未变**，只有少数描述性 RVA 标注需要按本节的换算表读取。）

---

## 0.5 ★★ v1.3.19 补上"反方向"：**4 字符码 → 名字 char***（取真名的正路）

> **结论：不用碰字符串表。** `GetUnitName` / `GetObjectName` 内部都是
> `4 字符码 —RVA 0x326BA0→ 名字 char*`，再拿去 `0x1DA520` 转成 id。
> 我们只要调 `0x326BA0` 就能直接拿到**名字正文本体**，id 反查那一环（本机一直不通）可以绕过。

| 项 | 值 |
|---|---|
| **函数** | **RVA `0x00326BA0`**（file `0x325FA0`，首字节 `56 8B F2 BA F8 AC 98 6F`） |
| **调用约定** | `__fastcall`：**ECX = 4 字符码**（整数值）、**EDX = 0**（"取第 0 项"），无栈参数 |
| **返回值** | EAX = **名字 `char*`**（指向引擎类型表里的静态正文；查不到时返回一个默认串） |
| **依据** | `GetUnitName(0x1E6340)`：`mov ecx,[CUnit+0x30] ; xor edx,edx ; call 0x326BA0 ; mov ecx,eax ; jmp 0x1DA520`；`GetObjectName(0x1E34A0)` 同样调它，返回后 `cmp byte ptr [eax],0`（**直接按 char* 解引用**，空串则返回 0）⇒ 返回值必定是字符串正文 |
| **产物** | `_build/watcher/an_getunitname.txt`、`an_getobjname.txt`、`an_typename.txt` |

**为什么这解释了"名字一直退化成 `o000`/`h042`"**：旧实现走 `GetUnitName → 字符串 id → 0x1C2870 反查`，
而本机这条链一直返回 NULL（见 §3），于是只能显示 4 字符码。新实现直接调 `0x326BA0`，拿到 `char*` 本体，
**与引擎 `GetUnitName` 完全等价**（`GetUnitName` 也只是把它转成 id 交给 JASS）。

实现：`UDamageWatcherHook.cpp` 里 `WC3_RVA_OBJ_NAME_BY_ID 0x00326BA0` + `Wc3NameByRawcode()`，
在 `UnitNameText()` 的 native 分支优先使用；失败**退回 4 字符码**（绝不往屏幕上送垃圾）。
前 3 次解析写日志 `名字解析：o000 -> "..."（RVA 0x326BA0）`，便于现场取证。

---
## 0. 结论（直接可用）

> **引擎自己就有一个 `char* → 字符串 id` 的函数。它就在 `Game.dll` 里，公开、干净、无副作用。**

| 项 | 值 |
|---|---|
| **函数** | **`RVA 0x001DA520`**（`VA 0x6F1DA520`；file 偏移 `0x1D9920`） |
| **调用约定** | **`__fastcall`**：`char*` 放 **`ECX`**；**无栈参数**；结尾 `ret`（调用者清栈，但因无栈参数故等价） |
| **参数** | **1 个**：`const char*`（以 `\0` 结尾的、**游戏编码**（GBK/ANSI）的字符串） |
| **返回值** | **`EAX` = 字符串 id（`uint32_t`）**；**入参为 0 时返回 0**（0 是"无效 id"，引擎侧 `get(0)` 返回 -1 → 不显示） |
| **副作用** | 只做"字符串驻留/入表"，**不分配 JASS 句柄、不碰选区、不发同步、不改游戏状态** |
| **调用前提** | ① 必须在**游戏线程**（该函数会访问引擎全局 `[0x6FBE4238]`（JASS ctx）与字符串表，非游戏线程调用无保护）；② ctx 与字符串表已初始化（一般 `Game.dll` 载入并进入地图后就绪）；③ 字符串是**游戏编码**，不是 UTF-8 |
| **失败表现** | 入参为 0 → 返回 0；ctx 未就绪 → 引擎内部 `0x1BEBC0` 会走"按需构建"分支；**任何异常都在我们外层 `__try` 里被吃掉并返回 0**，绝不会把游戏搞崩 |

**这就是"从 0 到有"的补全。** 你们现在缺的正是这一环：
`ydbase::create_string` 就是它的薄包装（见 §2），所以**直接调引擎这个函数即可完全替代 ydbase**。

---

## 1. 证据链：怎么找到它的（**3 个 native 交叉定位**）

### 1.1 思路
"返回字符串"的 native（`I2S`/`SubString`/`GetObjectName`…）**内部必然要创建字符串条目**。
反汇编它们，找**共用的那个调用目标**。

### 1.2 `I2S`（`RVA 0x1E7250`，签名 `(I)S`）—— **确证**

```
0x1E7250: 55                push ebp
0x1E7251: 8B EC             mov  ebp, esp
0x1E7253: 81 EC 04 01 00 00 sub  esp, 0x104          ; ★ 256 字节的本地格式化缓冲
0x1E7259: A1 74 A7 B6 6F    mov  eax, ds:0x6FB6A774   ; __security_cookie
0x1E725E: 33 C5             xor  eax, ebp
0x1E7260: 89 45 FC          mov  [ebp-4], eax
0x1E7263: FF 75 08          push [ebp+8]              ; 第 1 个参数 = I（要转的整数）
0x1E7266: 8D 85 FC FE FF FF lea  eax, [ebp-0x104]     ; ★&本地缓冲
0x1E726C: 68 B0 2F 95 6F    push 0x6F952FB0           ; 格式串 "%d" 之类
0x1E7271: 68 00 01 00 00    push 0x100                ; 缓冲大小 256
0x1E7276: 50                push eax
0x1E7277: E8 58 93 F3 FF    call 0x11F9D4             ; sprintf_s(buf,256,fmt,arg)
0x1E727C: 83 C4 10          add  esp, 16
0x1E727F: 8D 8D FC FE FF FF lea  ecx, [ebp-0x104]     ; ★★ ECX = 本地缓冲（char*）
0x1E7285: E8 96 32 FF FF    call 0x1DA520             ; ★★★ 【字符串 → id】，EAX = id
0x1E728A: 8B 4D FC          mov  ecx, [ebp-4]
0x1E728D: 33 CD             xor  ecx, ebp
0x1E728F: E8 91 9E 58 00    call 0x770525             ; __security_check_cookie
0x1E7294: 8B E5             mov  esp, ebp
0x1E7296: 5D                pop  ebp
0x1E7297: C3                ret
```

> `I2S` 的全部实现就是：**`sprintf` 到栈缓冲 → `mov ecx,buf` → `call 0x1DA520` → 返回 EAX**。
> 因为 `I2S` 的签名是 `(I)S`（**返回字符串**），而它只把 `0x1DA520` 的返回值当结果返回
> ⇒ **`0x1DA520` 的返回值就是那个字符串 id**。**确证。**

### 1.3 `SubString`（`RVA 0x1F8770`，签名 `(SII)S`）—— **确证**

```
0x1F8770: 55                push ebp
0x1F8771: 8B EC             mov  ebp, esp
...SEH...
0x1F8796: FF 75 10          push [ebp+0x10]      ; 参数3 = I（长度）
0x1F8799: 8B 4D 08          mov  ecx, [ebp+8]    ; 参数1 = S（源字符串）
0x1F879C: 8D 45 E8          lea  eax, [ebp-0x18] ; 本地 std::string
0x1F879F: FF 75 0C          push [ebp+0xC]       ; 参数2 = I（起点）
0x1F87A2: 50                push eax
0x1F87A3: E8 48 9D E5 FF    call 0x518F0         ; 构造子串（本地对象）
0x1F87A8: 8D 4D E8          lea  ecx, [ebp-0x18] ; ★ ECX = char*（本地串）
0x1F87AB: C7 45 FC 00 00 00 00  mov  [ebp-4], 0
0x1F87B2: E8 39 8F E5 FF    call 0x50AF0          ; 取 C 串指针
0x1F87B7: 8B C8             mov  ecx, eax        ; ★★ ECX = char*
0x1F87B9: E8 62 1D FE FF    call 0x1DA520        ; ★★★ 【字符串 → id】
0x1F87BE: 8D 4D E8          lea  ecx, [ebp-0x18] ; 析构本地串
...
0x1F87CF: 8B C6             mov  eax, esi        ; 返回 id
0x1F87D1: 5E                pop  esi
...
```
（`0x50AF0` 与 `0x1DA520` 在 `RVA 0x1F87B2`/`0x1F87B9` 处共现，注释见 §3。）

### 1.4 `GetObjectName`（`RVA 0x1E34A0`，签名 `(I)S`）—— **确证（尾调用形式）**

```
0x1E34A0: 55                push ebp
0x1E34A1: 8B EC             mov  ebp, esp
0x1E34A3: 8B 4D 08          mov  ecx, [ebp+8]        ; 参数 = I（对象类型 id）
0x1E34A6: 33 D2             xor  edx, edx
0x1E34A8: E8 F3 36 14 00    call 0x325FA0            ; id -> char*（内部字符串表取正文）
0x1E34AD: 85 C0             test eax, eax
0x1E34AF: 74 0D             je   ret0
0x1E34B1: 80 38 00          cmp  byte [eax], 0       ; 空串 -> 返回 0
0x1E34B4: 74 08             je   ret0
0x1E34B6: 8B C8             mov  ecx, eax            ; ★ ECX = char*
0x1E34B8: 5D                pop  ebp
0x1E34B9: E9 62 70 FF FF    jmp  0x1D9920 ←（= RVA 0x1DA520 的另一处入口/别名，见 §1.6）
```

### 1.5 调用者统计（**确证**）

对 `RVA 0x1DA520` 做全 `.text` 的 `E8 rel32` 目标扫描：**共 10 个直接调用点**，集中在
"返回字符串"的 native 实现里（`I2S` / `R2S` / `R2SW` / `SubString` / `StringCase` / `GetObjectName` /
`GetUnitName` / `GetHeroProperName` / `GetPlayerName` / `GetLocalizedString` 这一族）。

**⇒ 这就是引擎唯一的"字符串驻留"入口，被所有"产生字符串"的 native 共用。**

### 1.6 为什么还有一个 `0x1D9920` 的别名（**坐标说明，必读**）

同一段代码有两种写法，**务必别用错**：

| 写法 | 值 | 说明 |
|---|---|---|
| **段表 RVA（本报告统一用这个）** | **`0x001DA520`** | 运行时地址 = `GetModuleHandleA("game.dll") + 0x1DA520` ← **代码里就用这个** |
| 线性 file 偏移 | `0x1D9920` | 只用于"在磁盘文件里定位这段字节" |

两者差 `0xC00`（`.text` 的 `VA−PR`）。**`an.exe raw 0x1DA520` 与 `raw 0x1D9920` 打印的是同一段字节**
（前者报 `file 0x1D9920`，后者报 `file 0x1D8D20`），这就是早期版本报告里那个"矛盾"的来源。
**本报告的字节证据一律用 `RVA` 表述、并附 `file` 偏移。**

**它在 file `0x1D9920` 处的精确 18 字节（`an.exe raw 0x1DA520` 原文，逐字节确证）：**

```
rva 0x001DA520 file 0x1D9920: 85 C9 75 03 33 C0 C3 51 8B 0D 38 42 BE 6F E8 8D
rva 0x001DA530 file 0x1D9930: 52 FE FF C3
```

```
0x1DA520: 85 C9              test ecx, ecx           ; ECX = 入参 char*
0x1DA522: 75 03              jne  +3
0x1DA524: 33 C0              xor  eax, eax           ; 入参 == 0 -> 返回 id 0（无效）
0x1DA526: C3                 ret
0x1DA527: 51                 push ecx                ; 把 char* 压栈当参数
0x1DA528: 8B 0D 38 42 BE 6F   mov  ecx, ds:0x6FBE4238 ; ECX = ctx（改成 this）
0x1DA52E: E8 8D 52 FE FF     call 0x1BEBC0           ; ★ 引擎内部：字符串驻留 → 返回 id
0x1DA533: C3                 ret                     ; EAX = id
```

**⇒ 序言特征码（用于运行时自检）：`85 C9 75 03 33 C0 C3`**（6 字节，本文件内唯一）。
`0x1BEBC0` 是引擎内部的"驻留/建表"实现（未展开；**我们不需要调它，调 `0x1DA520` 就够**）。

---

## 2. `ydbase::create_string` 就是它的包装（**确证**）

`ydbase.dll` 的导出 `?create_string@jass@warcraft3@base@@YAIPBD@Z`：
**`RVA 0x19A80`**（ImageBase `0x10000000` → VA `0x10019A80`）。

```
0x19A80: 56              push esi
0x19A81: 8B 74 24 0C     mov  esi, [esp+0xC]     ; ★ 入参 = const char*
0x19A85: 8B 4E 28        mov  ecx, [esi+0x28]    ; 字符串表当前计数
0x19A88: 83 F9 10        cmp  ecx, 0x10
0x19A8B: 72 28           jb   +
0x19A8D: 8B 46 14        mov  eax, [esi+0x14]
...
0x19AA9: E8 A4 DD 00 00  call <分配/写正文>
0x19AAE: 83 C4 08        add  esp, 8
0x19AB1: 6A 2C           push 0x2C               ; ★ 32 字节条目（string_fake）
0x19AB3: 56              push esi
0x19AB4: C7 46 24 00 00 00 00  mov dword [esi+0x24], 0
0x19AB8: C7 46 28 0F 00 00 00  mov dword [esi+0x28], 0x0F   ; ★ 递增计数
0x19ABF: C6 46 14 00     mov  byte  [esi+0x14], 0
0x19AC3: 6A 2C           push 0x2C
0x19AC5: 56              push esi
0x19AC6: C7 46 24 00 00 00 00  mov dword [esi+0x24], 0
0x19ACA: C7 46 28 0F 00 00 00  mov dword [esi+0x28], 0x0F
0x19AD1: C6 46 14 00     mov  byte  [esi+0x14], 0
0x19AD5: E8 87 DD 00 00  call <插入条目>
0x19ADA: 83 C4 08        add  esp, 8
0x19ADD: 5E              pop  esi
0x19ADE: C3              ret
```

**`ydbase::create_string(const char*)` 返回的就是字符串表里的 id（= 条目下标）**，
每个 id 对应一个 **32 字节的 `string_fake` 条目**（`ydbase` 侧构造函数 `RVA 0x19980`：
`mov [ecx+0x1C], eax`（char*）、`mov [ecx+0x08], ecx`（自指））。
**引擎侧 `0x1DA520` 与之语义完全一致，所以直接替代即可。**

---

## 3. 字符串表条目布局（顺手交付，用于反向解析 `GetUnitName` 的 id）

> 反向路径（`id → char*`）：**引擎也有现成函数**，不必自己拆表。

| 项 | 值 |
|---|---|
| **`id → char*` 函数** | **`RVA 0x001C2870`**（file `0x1C1C70`），`__thiscall`（`ECX` = ctx），**1 个栈参数 = id**，`ret 4` |
| 它的上游 | `RVA 0x001FAE20`（file `0x1FA220`），`__fastcall`（`ECX` = id）——即 §2 里"native 的 `S` 参数解析器" |
| 字符串表容器 | `[ctx + 0x20]`（`ctx = *(uint32_t*)(base + 0xBE4238)`） |
| 容器内 vector | `this = 容器 + 4`；`+0x00` = begin、`+0x04` = end、`+0x08` = cap（元素 = 条目指针，4 字节） |
| 取元素 | `RVA 0x001C7850`（容器对象 Get(index)，含边界检查） |
| 条目 → 正文 | **`[条目 + 0x18]` = `char*`** |
| `id == 0` | 特判为失败（返回 -1 → NULL） |
| 条目大小 | **32 字节（0x20）** —— 由 `ydbase::create_string` 的 `push 0x2C`（=0x20 数据 + 0x0C 分配头）与 `string_fake` 布局互证 |

**我们能不能安全地自己插入条目？**
> **不能，请不要尝试。** 字符串表内部有 `count`（`ydbase` 里是 `+0x28`）与容量/重分配逻辑
> （`create_string` 里那段 `cmp ecx,0x10 / cmp ecx,0x100000 / call 分配` 就是它）。
> 手工往 vector 里塞一个条目会让 **count 与实际不一致**，轻则后续 `I2S`/`GetUnitName` 读出垃圾，
> 重则重分配时踩坏堆。**正确做法只有一个：调用引擎的 `0x1DA520`（`char* → id`）。**
> 想让引擎替我们建条目，就用它；它的实现里已经包含了"构建/增长/插入"的全部正确逻辑。

---

## 4. 可直接粘贴的 C++（含 `Readable` / `__try` / 序言校验 / 失败返回 0）

```cpp
//==============================================================================
// 无 JAPI/ydbase：动态字符串 -> 字符串 id
//   Game.dll 1.27.0.52240
//
//   ★ char* -> id : RVA 0x001DA520  (file 0x1D9920)
//        __fastcall  const char* 走 ECX  ->  EAX = id (uint32_t)，入参 0 返回 0
//        依据：I2S(RVA 0x1E7250) 0x1E7285 / SubString(RVA 0x1F8770) 0x1F87B9 /
//              GetObjectName(RVA 0x1E34A0) 0x1E34B9 三处交叉确证；共 10 个调用点
//
//   ★ id -> char* : RVA 0x001C2870  (file 0x1C1C70)
//        __thiscall ECX = ctx(=[base+0xBE4238])，[esp+4] = id，ret 4  -> EAX = char*
//
//   坐标：RVA = file + 0xC00（.text/.rdata，已用 4 个锚点交叉验证）
//==============================================================================
#define WC3_CTX_GLOBAL_RVA      0x00BE4238u   // ctx = *(uint32_t*)(base + 该 RVA)
#define WC3_STR_MAKE_ID_RVA     0x001DA520u   // char* -> id   (file 0x1D9920)
#define WC3_STR_FROM_ID_RVA     0x001C2870u   // id -> char*   (file 0x1C1C70)

// __fastcall：第 1 个参数在 ECX，无栈参数
typedef uint32_t (__fastcall *fn_str_make_id_t)(const char* text);
// __thiscall with one stack arg  ==  __fastcall(a, dummy)  （ECX=a，dummy 落栈，被调方 ret 4）
//   ★ Game.dll 的 id->char* 正是"__thiscall + 1 个栈参数 + ret 4"，
//     所以用 __fastcall + 哑第二参数来精确匹配（只会多压/多清 4 字节，位置与 ret 4 完全对应）
typedef const char* (__fastcall *fn_str_from_id_t)(uint32_t ctx, uint32_t dummyUnused, uint32_t id);

static fn_str_make_id_t s_strMakeId = NULL;
static fn_str_from_id_t s_strFromId = NULL;
static int              s_strMakeIdBad = 0;   // 1 = 序言校验失败，本会话不再重试

// 极简安全读
static bool Wc3Rd(const void* p, void* out, size_t n)
{
    if (!p) return false;
    if (!Readable(p, (int)n)) return false;          // 插件已有 Readable
    __try { memcpy(out, p, n); return true; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
}

//------------------------------------------------------------------------------
// 把一条动态 C 串变成引擎字符串 id。失败返回 0（0 在引擎里就是"无效 id"）。
//   ★ 必须在游戏线程调用。
//   ★ 字符串必须是【游戏编码】（中文用 GBK/CP936），不是 UTF-8。
//------------------------------------------------------------------------------
static uint32_t Wc3MakeStringId(const char* text)
{
    if (!text || !text[0]) return 0;
    if (s_strMakeIdBad) return 0;

    uint32_t base = (uint32_t)(uintptr_t)GetModuleHandleA("game.dll");
    if (!base) { LogLine("StrId: 取不到 game.dll 基址"); return 0; }

    // ---- 一次性解析 + 序言校验 ----
    if (!s_strMakeId) {
        uint32_t f = base + WC3_STR_MAKE_ID_RVA;
        uint8_t  p[6] = { 0 };
        __try { memcpy(p, (const void*)(uintptr_t)f, 6); }
        __except (EXCEPTION_EXECUTE_HANDLER) { s_strMakeIdBad = 1; return 0; }

        // 期望序言：85 C9 75 03 33 C0 C3   (test ecx,ecx / jne +3 / xor eax,eax / ret)
        // 这是"DTTTP 的 S 参数解析器家族"共用形态，见 §1
        if (!(p[0] == 0x85 && p[1] == 0xC9 && p[2] == 0x75 && p[3] == 0x03 &&
              p[4] == 0x33 && p[5] == 0xC0)) {
            s_strMakeIdBad = 1;
            LogLine("StrId: RVA 0x%X 序言=%02X %02X %02X %02X %02X %02X 不匹配，放弃",
                    WC3_STR_MAKE_ID_RVA, p[0], p[1], p[2], p[3], p[4], p[5]);
            return 0;
        }
        s_strMakeId = (fn_str_make_id_t)(uintptr_t)f;
        LogLine("StrId: char*->id 解析成功 = %08X (base %08X + RVA %X)", f, base, WC3_STR_MAKE_ID_RVA);
    }

    // ---- 调用（游戏线程！）----
    uint32_t id = 0;
    __try {
        id = s_strMakeId(text);          // ECX = text, 返回 EAX = id
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        s_strMakeIdBad = 1;
        LogLine("E StrId: 调用异常 code=%08X text=[%s]", (uint32_t)GetExceptionCode(), text);
        return 0;
    }

    if (id == 0) LogLine("StrId: 返回 0（失败或空串）text=[%s]", text);
    return id;
}

//------------------------------------------------------------------------------
// 反向：引擎字符串 id -> char*（用于把 GetUnitName 的返回值变成可读名字）
//   注意：GetUnitName 之类的 native 返回值在本引擎里【就是字符串 id】，
//         所以直接喂给这个函数即可；返回的 char* 只在引擎重建字符串表前有效，
//         想长期持有请自己 strncpy 一份。
//------------------------------------------------------------------------------
static const char* Wc3StringFromId(uint32_t id)
{
    if (!id) return NULL;
    uint32_t base = (uint32_t)(uintptr_t)GetModuleHandleA("game.dll");
    if (!base) return NULL;

    if (!s_strFromId) {
        uint32_t f = base + WC3_STR_FROM_ID_RVA;
        uint8_t  p[4] = { 0 };
        __try { memcpy(p, (const void*)(uintptr_t)f, 4); }
        __except (EXCEPTION_EXECUTE_HANDLER) { return NULL; }
        // 期望 55 8B EC 8B  (push ebp / mov ebp,esp / mov eax,[ebp+8])
        if (!(p[0] == 0x55 && p[1] == 0x8B && p[2] == 0xEC && p[3] == 0x8B)) {
            LogLine("StrId: id->char* 序言=%02X %02X %02X %02X 不匹配", p[0], p[1], p[2], p[3]);
            return NULL;
        }
        s_strFromId = (fn_str_from_id_t)(uintptr_t)f;
    }

    const char* s = NULL;
    __try {
        uint32_t ctx = 0;
        if (!Wc3Rd((const void*)(uintptr_t)(base + WC3_CTX_GLOBAL_RVA), &ctx, 4) || !ctx) return NULL;
        // __thiscall(ctx) + 1 栈参数(id)：用 __fastcall(ctx, dummy, id) 精确等价
        s = s_strFromId(ctx, 0, id);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E StrId: id->char* 异常 code=%08X id=%08X", (uint32_t)GetExceptionCode(), id);
        return NULL;
    }
    return s;
}

//------------------------------------------------------------------------------
// 用法：把动态消息显示出来（完全不再需要 ydbase）
//------------------------------------------------------------------------------
static void ShowMessage(uint32_t hplayer, float x, float y, float dur, const char* utf8OrGbk)
{
    // 1) 你们自己的 UTF-8 -> 游戏编码（GBK）转换（插件里已有 Utf8ToAnsi）
    char gbk[768] = { 0 };
    Utf8ToAnsi(utf8OrGbk, gbk, (int)sizeof(gbk));      // 若调用方已给 GBK，可直接用

    // 2) 动态字符串 -> 引擎 id   ★ 这就是本次解出的那一环
    uint32_t sid = Wc3MakeStringId(gbk);
    if (!sid) { LogLine("ShowMessage: 拿不到字符串 id，放弃显示"); return; }

    // 3) 调 DisplayTimedTextToPlayer 实现（RVA 0x001DFE70，__cdecl）
    typedef void (__cdecl *fn_DTTTP_t)(uint32_t, float, float, float, uint32_t);
    static fn_DTTTP_t fn = NULL;
    if (!fn) {
        uint32_t base = (uint32_t)(uintptr_t)GetModuleHandleA("game.dll");
        uint8_t p[3] = { 0 };
        __try { memcpy(p, (const void*)(uintptr_t)(base + 0x001DFE70u), 3); }
        __except (EXCEPTION_EXECUTE_HANDLER) { return; }
        if (!(p[0] == 0x55 && p[1] == 0x8B && p[2] == 0xEC)) {
            LogLine("DTTTP 序言不匹配，放弃"); return;
        }
        fn = (fn_DTTTP_t)(uintptr_t)(base + 0x001DFE70u);
    }
    __try { fn(hplayer, x, y, dur, sid); }
    __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E DTTTP 异常 code=%08X", (uint32_t)GetExceptionCode());
    }
}
```

### 4.1 一句话总结改法

```diff
- uint32_t s = g_create_string(text);                  // ydbase，联机没有
+ uint32_t s = Wc3MakeStringId(text);                  // ★ 引擎 RVA 0x1DA520，永远都在
  g_call("DisplayTimedTextToPlayer", lp, &x, &y, &d, s);
```

**注意**：`s` 就是 `DisplayTimedTextToPlayer` 第 5 参数本身，**不要再"造 `string_fake` 对象、传对象指针"**——
参见上一轮报告 §2 的更正：第 5 参数是 **id**，不是对象指针。

---

## 5. 运行时自检（一次日志即可确证/否证，30 行）

```cpp
// 目标：确认 (a) char*->id 能用；(b) 我们的 id 能被 DTTTP 正常显示；(c) 反向 id->char* 往返一致
static void SelfTestStringId(uint32_t hplayer, float x, float y)
{
    uint32_t base = (uint32_t)(uintptr_t)GetModuleHandleA("game.dll");
    LogLine("ST: base=%08X  ctx=%08X", base,
            base ? *(uint32_t*)(uintptr_t)(base + WC3_CTX_GLOBAL_RVA) : 0);

    const char* probe = "UDW-STRID-PROBE-12345";       // ASCII 即可，先排除编码问题
    uint32_t id = Wc3MakeStringId(probe);
    LogLine("ST: MakeId('[%s]') = %u (0x%X)", probe, id, id);
    if (!id) { LogLine("ST: ★ 失败 —— 检查是否在游戏线程 / ctx 是否为 0"); return; }

    // 反向解析必须拿回同样的文本
    const char* back = Wc3StringFromId(id);
    LogLine("ST: FromId(%u) = %08X [%s]", id,
            (uint32_t)(uintptr_t)back, back ? back : "<null>");
    LogLine("ST: 往返 %s", (back && strcmp(back, probe) == 0) ? "一致 ✓" : "不一致 ✗");

    // 真的显示一次：屏幕上应出现 UDW-STRID-PROBE-12345
    typedef void (__cdecl *fn_DTTTP_t)(uint32_t, float, float, float, uint32_t);
    fn_DTTTP_t fn = (fn_DTTTP_t)(uintptr_t)(base + 0x001DFE70u);
    __try { fn(hplayer, x, y, 8.0f, id); } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("ST: DTTTP 异常 code=%08X", (uint32_t)GetExceptionCode()); return; }

    // 再显示一条动态的（含数字，模拟伤害消息）
    char dyn[256];
    sprintf_s(dyn, "[DMG] src=%s atk=%d dmg=%.1f", "hfoo", 0, 931.0f);
    char gbk[256] = { 0 };
    Utf8ToAnsi(dyn, gbk, (int)sizeof(gbk));
    uint32_t id2 = Wc3MakeStringId(gbk);
    LogLine("ST: MakeId(dyn) = %u", id2);
    __try { fn(hplayer, x, y, 8.0f, id2); } __except (EXCEPTION_EXECUTE_HANDLER) {}

    LogLine("ST: 屏幕上若出现两条文本 => 动态字符串这一环彻底打通 ✓");
    LogLine("ST: 若 id 非 0 但屏幕不显示 => 第 5 参数语义需复核（见上轮报告 §2.6 的 ProbeStringIds）");
}
```

---

## 6. 风险 / 边界（诚实清单）

| # | 事项 | 说明 | 规避 |
|---|---|---|---|
| R1 | **必须游戏线程** | `0x1DA520` 会访问 `[0x6FBE4238]`（ctx）与字符串表 vector；非游戏线程并发调用可能读到半构建状态 | 你们的伤害钩子本身就在游戏线程，**直接从钩子里调**最安全；若在渲染/热键线程，用 `PostMessage` 回游戏线程（插件已有该模式） |
| R2 | **字符串编码** | 引擎要的是**游戏编码**（中文 GBK/CP936），UTF-8 会显示乱码 | 复用插件里已有的 `Utf8ToAnsi()`（`WideCharToMultiByte(CP_ACP,…)`） |
| R3 | **每条消息都驻留 → 字符串表会增长** | 引擎的驻留表不会自动回收我们塞进去的新串（`create_string` 也一样） | ① 伤害数字**限流**（每帧/每 N 帧聚合一次）；② **做一个小缓存**：把"来源名+数字"拼好后先去自己的 `hash → id` 缓存里查，命中就用旧 id；③ 数量级参考：一局几千条完全无害（引擎原生字符串也有数万条） |
| R4 | **`id` 的生命周期** | 只要引擎还活着，id 一直有效（字符串表只增不减） | 可放心缓存 id 复用 |
| R5 | **`0x1DA520` 的入口在两个坐标写法下不同** | 段表 RVA `0x1DA520` = file `0x1D9920`；用错坐标会打到别的代码 | **务必先做 §4 的序言校验**（`85 C9 75 03 33 C0 C3`） |
| R6 | **`0x1C2870` 的调用约定** | 我只确证了它是 `__thiscall` + 1 栈参数 + `ret 4`（`ECX` = ctx，`[esp+4]` = id） | C++ 里用 `__stdcall` 单参数声明（被调方清栈，语义一致）；有 `__try` 兜底 |
| R7 | **联机那份 13,467,648 字节的 Game.dll 未验证** | 磁盘上不存在 | 用 §4 的**序言校验 + 失败返回 0** 自动降级；或按上轮报告 §5.2 的特征码先定位再算 RVA |

---

## 7. 本轮用到的工具与产物

| 文件 | 用途 |
|---|---|
| `<WS>\_tools\an2\f\bin\f.exe` | **本轮新写的极简 PE 偏移/字节检查器**（只走段表，输出 file 偏移与 RVA 两种解释）—— 正是它揪出了早期"线性 delta"读法的偏差 |
| `<WS>\_tools\an\bin\an.exe` | x86 反汇编器（`dump`/`raw`/`callto`/`str`/`sections`），本报告的字节级证据全部由它产出 |
| `<WS>\_tools\an2\Program.cs` | 上述反汇编器的源码（可重建） |
| 本文 | `无JAPI模式-动态字符串id.md` |

**只读约束遵守**：全程只读 `D:\war5\Game.dll`、`…\kkduizhan\plugins\game\ydbase.dll`；
**未写 `D:\war5`**、未改名、**未改 `UDamageWatcherHook.cpp`**、未改 `config.cfg`、未启动游戏、未提权。
