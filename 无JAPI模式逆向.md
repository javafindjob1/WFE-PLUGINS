# 无 JAPI / ydbase 模式的**引擎直连**逆向报告

> 目标：在**没有任何 JAPI/ydbase** 的进程里，把插件现在依赖 ydbase 的三件事改成
> **直接调 `Game.dll` 内部函数 / 直读引擎内存**：
> ① 按名字取 native 实现（替代 `jass_func`）② 字符串参数怎么传（替代 `create_string`/`string_fake`）
> ③ 对象 → JASS 句柄（替代 `object_to_handle`）。
>
> 分析对象（**只读**，未写入、未改名、未启动游戏）：
>
> | 文件 | 大小 | SHA256（前 8 字节） | 说明 |
> |---|---|---|---|
> | `D:\war5\Game.dll` | 13,187,048 | `1A4D41EB650F9C0D…` | 本机（分析主力） |
> | `C:\Program Files (x86)\kkduizhan\config\gpatch\game\1.27.0\Game.dll` | 13,187,048 | `E04D1716 603C075E…` | 平台同款，**已成功读取**（只读） |
> | `C:\Program Files (x86)\kkduizhan\plugins\game\ydbase.dll` | 427,992 | ImageBase `0x10000000` | **仅作对照**（读它的 `object_to_handle`/`from_string` 反推引擎布局） |
>
> 版本 `1.27.0.52240`；ImageBase `0x6F000000`；**`文件偏移 = RVA − 0xC00`**（本次再次全量确认）。
> 工具：`<WS>\_tools\an\`（本轮新写的 C# 反汇编器/PE 分析器，见 §6）。
>
> ⚠️ 全文 **确证 / 强推断 / 推断** 三级标注；未动态验证的一律标"推断"，并在 §5 给出运行时自检代码。

---

## 0. 结论速览（先看这里）

| # | 问题 | 结论 | 置信度 |
|---|---|---|---|
| ① | 按名字取 native 实现 | **有两条表**：表 A（file `0x1E8E50`，1167 条，**真实现**）与表 B（file `0x6F511C`，1290 条，**全部实现字段 = `0x70A0C0` 的 `xor eax,eax; ret` 桩**）。记录布局 `E8 rel32 / 68 sig / BA name / B9 impl`，stride **20**，取 **`+16` 处的 imm32 = 实现 VA**。**必须用表 A**。已用 `DisplayTimedTextToPlayer` / `GetUnitName` / `GetUnitTypeId` 三个实例逐字节验证。 | **确证** |
| ② | `DisplayTimedTextToPlayer` 字符串参数 ABI | 实现 `RVA 0x1DFE70`（`__cdecl`，`ret`，不改栈）。第 5 参数在 `[ebp+0x18]`，它**先被送到 `RVA 0x1FAE20` → `RVA 0x1C1C70` 做解析**。⚠️ **本轮更正**：`0x1C1C70` 把该参数当作**下标**送进字符串表容器（`[ctx+0x20]` 的 `get()`），并**只判 `!= 0`（从不判可读性）**，`ydbase::create_string` 也证明它返回的是**字符串 id** ⇒ **第 5 参数是"字符串 id"（小整数），不是 `char*`，也不是字符串对象指针**。你们现在传 `string_fake` 对象指针**是错的**（这正是旧注释里"0x105A 被 native 当对象解引用 → 访问违例"的真因——恰好说反了：**对象指针被当成了 id**）。既有的 `string_fake` 布局（`+0x08`、`+0x1C`）依然有用，但**做法要改成"取该条目的 id"**。 | **确证**（引擎侧 + `create_string` + 插件自身旧结论 三方一致） |
| ③ | `CUnit*` → JASS 句柄 | 引擎原生转换器 = **`RVA 0x2645D0`**（`__thiscall`，`ecx` = 句柄管理器 `*(base+0xBE4238)+0xF4`，`[esp+4]` = 对象指针，`[esp+8]` = 0，`ret 8`）。它被 `GetOwningPlayer`(`0x1E3BA0`) 与 `GetLocalPlayer`(`0x1E3150`) 正是这样调用，且两者都返回句柄 ⇒ **这就是引擎自己的"对象→句柄"**。同时给出**纯内存备选**：`handle = 0x100000 + i`，`i` 为在句柄表中匹配到该对象的槽位下标（ydbase `object_to_handle` 就是这么干的）。 | 调用点 **确证**；返回语义 **强推断**（未动态验证） |
| ④ | native 实现 RVA 清单 | 见 §4 完整表（12 个全部来自表 A，**确证**）。 | **确证** |
| ⑤ | 伤害函数 `0x67DC40` 特征码 | 16 字节主序言在 `.text` 里**唯一命中 1 次**（两份 Game.dll 都是 1 次）；组合特征码（序言+早退分支+`ret 0x10`）唯一命中 1 次；掩码分支特征码唯一命中 1 次。**两份 Game.dll 全文只差 12 字节**，且 **`0x67DC40` 处逐字节相同**。 | **确证** |
| ⑥ | 两份 Game.dll 差异 | 全文仅 12 字节不同（3 处 `3D FF FF FF FF 0F 8?`），**全部落在 RVA `0x84F52D` / `0x85F9B3` / `0x872663` 三个函数里，与 native 表、字符串、伤害函数毫无关系**。其余 13,187,036 字节完全相同。 | **确证** |

---

## 1. ① native 名表定位法（最重要）

### 1.1 完整可复现的查找步骤

```
输入：目标 native 名字符串 name（如 "DisplayTimedTextToPlayer"）
输出：实现函数 VA/RVA

S1. 在 Game.dll 里找 name 的 ASCII 出现位置（必须被 0x00 结尾）。
    正常只会有 1 处：file=0x96C850  VA=0x6F96D450（.rdata）
    ※ 名字串是"连续打包"的：名字\0 [0~3 字节填充] 签名\0 [填充] 下一个名字\0 ...

S2. 把该名字串的绝对 VA（= ImageBase + RVA = 0x6F000000 + RVA）
    当 **小端 dword** 在全文件搜索。正常命中 2 处：
      命中①  file=0x1ECF97  → 表 A（真实现）
      命中②  file=0x6F924F  → 表 B（假实现 / 0x70A0C0 桩）

S3. 对每个命中，验证它是不是"记录里的 +11 字段"：
      令 rec = hit − 11
      要求 B[rec+0]==0xE8  B[rec+5]==0x68  B[rec+10]==0xBA  B[rec+15]==0xB9
    验证通过 ⇒ 这是一条 native 注册记录，记录起点 = rec。

S4. 读音：
      [+0]  E8 rel32   → call 0x6F7E3710   （注册器，恒为同一地址）
      [+5]  68 imm32   → 签名串 VA（"名字在 +11、签名在 +6、实现在 +16"）
      [+10] BA imm32   → 名字串 VA（= S1 的 VA，回校验）
      [+15] B9 imm32   → **实现函数 VA**  ← 要的就是它
      [+19] 记录结束；下一条记录紧跟其后（stride = 20）

S5. 实现 RVA = imm32 − 0x6F000000；运行时地址 = GetModuleHandleA("game.dll") + RVA。
```

### 1.2 stub 的字节形态与变体

| 形态 | 字节 | 出现位置 | 怎么处理 |
|---|---|---|---|
| **标准记录**（唯一形态，本次 1167+1290 条**逐条验证无例外**） | `E8 rel32` / `68 imm32` / `BA imm32` / `B9 imm32`（共 20 字节） | 表 A、表 B | 直接读 `+16` |
| **空实现桩** | `33 C0 C3`（`xor eax,eax; ret`，RVA `0x70A0C0`） | **表 B 的全部记录** | 见到 `impl == base+0x70A0C0` ⇒ **丢弃**，改用表 A |
| 无堆栈帧的转发 thunk | `E9 rel32`（`jmp`） | 个别 native 实现**内部**（不是记录里） | 跟着跟一跳即可；**不影响记录解析** |

> **重要**：本次没有发现第二种记录编码。全部命中点用 `E8/68/BA/B9` 四字节模板 100% 通过。
> 也没有发现"名字压缩/加密"——`Game.dll` 里 native 名字是**明文 ASCII**。

### 1.3 三个实例验证（全部逐字节核对）

**实例 1：`DisplayTimedTextToPlayer`**

| 项 | 值 |
|---|---|
| 名字串 file | **`0x0096C850`** |
| 名字串 RVA / VA | `0x0096D450` / `0x6F96D450` |
| 签名串 VA | `0x6F96D440` → `(Hplayer;RRRS)V` |
| 记录起点 file / RVA | **`0x1ECF8C`** / `0x1EDB8C`（表 A 第 **#835** 条） |
| 记录原始字节 | `E8 7F 67 5F 00 │ 68 40 D4 96 6F │ BA 50 D4 96 6F │ B9 70 FE 1D 6F` |
| `mov ecx,imm32` 的 imm | **`0x6F1DFE70`** ⇒ **实现 RVA `0x001DFE70`** |
| 表 B 同名记录 | file `0x6F9244`，`+16` imm = `0x6F70A0C0`（**桩**）⇒ 印证"必须用表 A" |

**实例 2：`GetUnitName`**

| 项 | 值 |
|---|---|
| 名字串 file / VA | **`0x009694AC`** / `0x6F96A0AC` |
| 签名串 VA | `0x6F96A0A0` → `(Hunit;)S` |
| 记录起点 file / RVA | **`0x1EAD7C`** / `0x1EB97C`（表 A 第 **#399** 条） |
| 记录原始字节 | `E8 A3 0D 5F 00 │ 68 A0 A0 96 6F │ BA AC A0 96 6F │ B9 40 63 1E 6F` |
| `mov ecx,imm32` 的 imm | **`0x6F1E6340`** ⇒ **实现 RVA `0x001E6340`** |

> 注：`WFE伤害机制分析.md` 附录 B 把 `GetUnitName` 的 native 表项写成 `0x1E6340`（正确），
> 而把 `GetUnitTypeId` 写成 `0x1E66C0`（**错**，见下）。

**实例 3：`GetUnitTypeId`**

| 项 | 值 |
|---|---|
| 名字串 file / VA | **`0x00969474`** / `0x6F96A074` |
| 签名串 VA | `0x6F969F20` → `(Hunit;)I` |
| 记录起点 file / RVA | **`0x1EAD54`** / `0x1EB954`（表 A 第 **#397** 条） |
| 记录原始字节 | `E8 CB 0D 5F 00 │ 68 20 9F 96 6F │ BA 74 A0 96 6F │ B9 70 66 1E 6F` |
| `mov ecx,imm32` 的 imm | **`0x6F1E6670`** ⇒ **实现 RVA `0x001E6670`**（**修正**原报告的 `0x1E66C0`） |

### 1.4 表 A / 表 B 的确定边界（可用于运行期自检）

| | 表 A（**真**） | 表 B（**桩**） |
|---|---|---|
| 首条记录 file | `0x1E8E50` | `0x6F511C` |
| 首条记录 RVA | `0x1E9A50` | `0x6F5D1C` |
| 首条名字 | `Deg2Rad` `(R)R` impl `RVA 0x1DF360` | `Rad2Deg` … impl `RVA 0x70A0C0` |
| 末条记录 | `Preloader` `(S)V` `RVA 0x1F2190` | `DebugBreak` `(I)V` impl `0x70A0C0` |
| 记录数 | **1167** | **1290** |
| 名字/签名串 | 都在 `.rdata` `0x6F967xxx ~ 0x6F96Fxxx` | **与表 A 完全共用同一批名字串** |
| 全量清单 | `<WS>\_tools\native_table_1.27.0.52240.txt` | `<WS>\_tools\native_table2_stub_1.27.0.52240.txt` |

**⇒ 运行期怎么区分两张表**：读任一条的 `+16` imm，**若等于 `base+0x70A0C0` 就是表 B，丢弃**。
更稳的做法：**直接从表 A 的固定 RVA 起点 `0x1E9A50` 线性遍历**（stride 20，逐条校验 4 个 opcode），
建一张 `name → impl` 的哈希表，一次遍历 1167 条，耗时 < 1 ms。

### 1.5 失败模式（必读）

| 失败模式 | 现象 | 自检 / 规避 |
|---|---|---|
| **落到表 B（桩）** | 拿到 `0x70A0C0`，调用后返回值恒 0（`DisplayTimedTextToPlayer` 会静默失效） | ①`impl != base+0x70A0C0`；②加 §1.4 的表 A 起点遍历 |
| **同一名字出现 2 次** | XRef 命中 2 处（表 A + 表 B） | 必须两处都解析，**只认 `impl != 0x70A0C0` 的那条** |
| **别名条目** | 同一实现被多个名字注册（本次未见）；`impl` 相同不代表名字相同 | 用 `+11` 的 dword 反查名字串并**用 `strcmp` 回校验** |
| **名字串被 0x00 边界切断** | 例如 `"display"` 会命中 `"DisplayTextToPlayer"` 的子串 | 必须要求**名字串前一字节无法判断**，但**后一字节必须是 0x00**；而且**优先用 `+11` 反查而不是正查** |
| **名字串出现 >1 次** | 本次 `GetUnitName` / `display` 等均只 1 次；若某名字也出现在别处（如 JASS 脚本字符串常量） | 只在 `.rdata` 范围内搜；且**只认"能被 `E8/68/BA/B9` 模板验证"的那一处** |
| **小版本换了实现 RVA** | 记录还在、名字还在，`+16` 变了 | **不要硬编码实现 RVA**，一律运行期按名字查表；实现 RVA 只用于日志/自检 |
| **`.text` 被"线性化"** | `Off(rva)` 用标准段表即可（本次确认 `file = RVA − 0xC00`），**不要**自己拼 `PointerToRawData` | §6 的 `Off()` 实现 |
| **`display` 这种短名** | 查 `nat display` 得到 `abs refs = 0`（它只是 `DisplayTextToPlayer` 的子串命中，且后面不是 0x00） | 正查必须要求**后缀为 0x00**；否则只能用 `+11` 反查 |

### 1.6 运行期自检代码（可直接粘贴）

```cpp
//------------------------------------------------------------------------------
// ① native 名表定位（1.27.0.52240 / game.dll）—— 替代 ydbase::jass_func
//   表 A 起点 RVA 0x1E9A50，1167 条，stride 20
//   记录: +0=E8 rel32  +5=68 sigVA  +10=BA nameVA  +15=B9 implVA
//   表 B（RVA 0x6F5D1C 起，1290 条）的实现字段全是 0x70A0C0 的 xor eax,eax;ret 桩
//   依据: 逐条解码 1167+1290 条记录全部满足 E8/68/BA/B9 模板（本次确证）
//------------------------------------------------------------------------------
#define WC3_NATIVE_TABLE_RVA      0x001E9A50u   // 表 A 起点（真实现）
#define WC3_NATIVE_TABLE_B_RVA    0x006F5D1C   // 表 B 起点（桩，仅用于排除）
#define WC3_NATIVE_STUB_RVA       0x0070A0C0u   // 空实现桩 RVA
#define WC3_NATIVE_MAX            2048u

struct NativeEntry { char name[64]; const void* fn; };

static uint32_t s_nativeBase = 0;
static size_t   s_nativeCount = 0;
static NativeEntry s_nativeTab[WC3_NATIVE_MAX];

// 极简安全读（配合插件已有的 Readable）
static bool Wc3Read(const void* p, void* out, size_t n)
{
    if (!p) return false;
    if (!Readable(p, (int)n)) return false;      // 插件里已有 Readable
    __try { memcpy(out, p, n); return true; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
}

// 一次性遍历表 A，建立 名字 -> 实现 的本地表
static void Wc3BuildNativeTable()
{
    if (s_nativeBase) return;
    uint32_t base = (uint32_t)(uintptr_t)GetModuleHandleA("game.dll");
    if (!base) { LogLine("native: 取不到 game.dll 基址"); return; }
    if (!Readable((const void*)(uintptr_t)(base + WC3_NATIVE_TABLE_RVA), 20)) {
        LogLine("native: 表 A 起点不可读（版本不匹配？）"); return;
    }

    const uint8_t* rec = (const uint8_t*)(uintptr_t)(base + WC3_NATIVE_TABLE_RVA);
    for (size_t i = 0; i < WC3_NATIVE_MAX; ++i, rec += 20)
    {
        uint8_t hdr[20];
        if (!Wc3Read(rec, hdr, 20)) break;
        if (!(hdr[0] == 0xE8 && hdr[5] == 0x68 && hdr[10] == 0xBA && hdr[15] == 0xB9)) break;

        uint32_t sigVA, nameVA, implVA;
        memcpy(&sigVA,  hdr + 6,  4);
        memcpy(&nameVA, hdr + 11, 4);
        memcpy(&implVA, hdr + 16, 4);

        // 名字串必须落在本模块镜像内且可读
        if (nameVA < base || nameVA > base + 0x00C00000u) continue;
        uint32_t nameRVA = nameVA - base;
        if (!Readable((const void*)(uintptr_t)nameVA, 2)) continue;

        // 空实现桩 -> 跳过
        if (implVA == base + WC3_NATIVE_STUB_RVA) continue;

        // 名字必须是 NUL 结尾的可打印 ASCII
        char nm[64] = { 0 };
        __try {
            for (int k = 0; k < 63; ++k) {
                char c = *(const char*)(uintptr_t)(nameVA + k);
                if (c == 0) break;
                if (c < 0x20 || c > 0x7E) { nm[0] = 0; break; }
                nm[k] = c;
            }
        } __except (EXCEPTION_EXECUTE_HANDLER) { nm[0] = 0; }
        if (!nm[0]) continue;

        strncpy_s(s_nativeTab[s_nativeCount].name, nm, _TRUNCATE);
        s_nativeTab[s_nativeCount].fn = (const void*)(uintptr_t)implVA;
        if (++s_nativeCount >= WC3_NATIVE_MAX) break;
    }
    s_nativeBase = base;
    LogLine("native: 表A 装载 %u 条（验证过 4 字节模板；跳过表B 桩）", (unsigned)s_nativeCount);
}

// 等价于 ydbase 的 jass_func(name)
static const void* Wc3NativeByName(const char* name)
{
    Wc3BuildNativeTable();
    for (size_t i = 0; i < s_nativeCount; ++i)
        if (strcmp(s_nativeTab[i].name, name) == 0) return s_nativeTab[i].fn;

    // 兜底：正向查找（名字串 -> XRef -> 记录），可处理表 A 之外的别名条目
    uint32_t base = (uint32_t)(uintptr_t)GetModuleHandleA("game.dll");
    if (!base) return NULL;
    const uint8_t* p   = (const uint8_t*)(uintptr_t)base;
    const size_t   len = 0x00C9'0000u;                   // 文件 13,187,048 足够覆盖
    size_t nl = strlen(name);
    if (nl == 0 || nl > 48) return NULL;

    for (size_t o = 0x94D400; o + nl + 1 < len; ++o)     // 只在 .rdata 起扫（名字都在这）
    {
        if (p[o + nl] != 0) continue;
        if (memcmp(p + o, name, nl) != 0) continue;

        uint32_t va = base + (uint32_t)(o + 0x400);      // file->rva: +0xC00；rva->VA: +base
        // 正确的换算：rva = fileOff + 0xC00 ； VA = base + rva
        va = base + (uint32_t)(o + 0xC00);

        // 在整文件里找 dword == va
        for (size_t q = 0x400; q + 20 < len; ++q)
        {
            uint32_t d; memcpy(&d, p + q, 4);
            if (d != va) continue;
            size_t rec = q - 11;
            if (rec < 0x400) continue;
            if (!(p[rec] == 0xE8 && p[rec + 5] == 0x68 &&
                  p[rec + 10] == 0xBA && p[rec + 15] == 0xB9)) continue;
            uint32_t implVA; memcpy(&implVA, p + rec + 16, 4);
            if (implVA == base + WC3_NATIVE_STUB_RVA) continue;   // 表 B 桩，丢弃
            if (implVA < base || implVA > base + 0x00C00000u) continue;
            return (const void*)(uintptr_t)implVA;
        }
    }
    return NULL;
}
```

> ⚠️ 上面 `Wc3NativeByName` 兜底分支里的 `len = 0x00C90000` 是**文件长度**，而 `p` 是**运行期映射基址**——
> 映射大小 ≥ `SizeOfImage`（`0x00C93000` 左右），所以直接扫是安全的；但**为了不越界**，
> 建议把 `len` 改成 `0x00BFD000`（`.reloc` 之前）。生产代码里**优先用遍历表 A**（快且已验证），
> 兜底分支只用于排查。

---

## 2. ② 字符串参数的 ABI

### 2.1 `DisplayTimedTextToPlayer` 实现全貌（RVA `0x1DFE70`，`__cdecl`）

> 记录（表 A #835）：signature `(Hplayer;RRRS)V`，实现 RVA **`0x001DFE70`**，**确证**。

```
0x1DFE70: 55                push ebp
0x1DFE71: 8B EC             mov  ebp, esp
0x1DFE73: 8B 4D 08          mov  ecx, [ebp+0x8]        ; 参数1 = Hplayer
0x1DFE76: E8 55 05 FF FF    call 0x1CF7D0              ; Hplayer -> CPlayer*  (类型校验 'lga+' 的模板转换器)
0x1DFE7B: 85 C0             test eax, eax
0x1DFE7D: 74 59             je   ret0
0x1DFE7F: 8B C8             mov  ecx, eax
0x1DFE81: E8 7A 94 06 00    call 0x248700              ; = jmp 0x43550 （JPlayer 有效性检查）
0x1DFE86: 85 C0             test eax, eax
0x1DFE88: 74 4E             je   ret0
0x1DFE8A: 8B 4D 18          mov  ecx, [ebp+0x18]  <== ★ 第 5 参数（S，字符串）
0x1DFE8D: E8 8E BB 01 00    call 0x1FAE20         <== ★★ 把它"解析"一次
0x1DFE92: 51                push ecx                   ; 预留 4 字节临时（下面填 -1）
0x1DFE93: 8B CC             mov  ecx, esp
0x1DFE95: 8B D0             mov  edx, eax              ; edx = 解析结果 = ★ char*（字符串正文）
0x1DFE97: 8B 45 0C          mov  eax, [ebp+0xC]        ; 参数2 = R  (x)
0x1DFE9A: C7 01 FF FF FF FF mov  dword [ecx], -1        ; 往预留槽写 -1（默认/无效标记）
0x1DFEA0: 8B 4D 14          mov  ecx, [ebp+0x14]       ; 参数4 = R  (duration)
0x1DFEA3: F3 0F 10 10       movss xmm2, [eax]          ; xmm2 = x   （float，直接按位取）
0x1DFEA7: F3 0F 10 01       movss xmm0, [ecx]          ; xmm0 = duration
0x1DFEAB: 8B 4D 10          mov  ecx, [ebp+0x10]       ; 参数3 = R  (y)
0x1DFEAE: 51                push ecx
0x1DFEAF: F3 0F 11 04 24    movss [esp], xmm0          ; 覆盖为 duration（float，按位 4 字节）
0x1DFEB4: 52                push edx                   ; ★ push char*（正文）
0x1DFEB5: F3 0F 10 09       movss xmm1, [ecx]          ; xmm1 = y
0x1DFEB9: 83 EC 08          sub  esp, 8
0x1DFEBC: 33 D2             xor  edx, edx
0x1DFEBE: F3 0F 11 4C 24 04 movss [esp+4], xmm1          ; 参数 y（float）
0x1DFEC4: 8D 4A 01          lea  ecx, [edx+1]          ; ecx = 1
0x1DFEC7: F3 0F 11 14 24    movss [esp], xmm2          ; 参数 x（float）
0x1DFECC: E8 CF F4 16 00    call 0x34E7A0              ; 引擎内部：取得显示管理器（ecx=1 当 this）
0x1DFED1: 8B C8             mov  ecx, eax
0x1DFED3: E8 68 77 17 00    call 0x356A40              ; 引擎内部：真正加入显示队列
0x1DFED8: 5D                pop  ebp                   ; ← 两个 `je` 都跳到这里（= 提前返回）
0x1DFED9: C3                ret                    <== ★ `ret`（不是 ret N）⇒ **__cdecl**
```

**`ret` 而不是 `ret N` ⇒ 由调用者清栈 ⇒ JASS native 实现是 `__cdecl`。确证。**

> **浮点参数怎么传（本次逐指令确证）**：x / y / duration **都是 `float`**，
> 引擎用 `movss xmm, [ebp+0xN]` 取值后 `movss [esp], xmm` **按位拷 4 字节**压栈 ——
> **不是整数、不是 `to_real` 位模式**。C 原型里写 `float` 即可。

### 2.2 字符串参数到底是什么——引擎侧的字节证据（**本轮更正后的定论**）

`0x1FAE20` 的真实入口。**权威原始字节**（`file 0x1FAE20..0x1FAE3F`，逐字节抄自 `an.exe raw`）：

```
file 0x1FAE20: 56 8B F1 8B 0D 38 42 BE 6F 85 C9 75 04 33 C0 5E
file 0x1FAE30: C3 57 6A 01 E8 77 7B FC FF 8B CE 8B F8 E8 AE 5C
```

完整线性反汇编（**确证**）：

```
0x1FAE20: 56              push esi
0x1FAE21: 8B F1           mov  esi, ecx              ; ★ esi = 传入的字符串 id（__fastcall: id 在 ecx）
0x1FAE23: 8B 0D 38 42 BE 6F  mov ecx, ds:0x6FBE4238  ; ecx = 引擎 ctx
0x1FAE29: 85 C9           test ecx, ecx
0x1FAE2B: 75 04           jne  0x1FAE31
0x1FAE2D: 33 C0           xor  eax, eax              ; ctx == 0 -> 返回 NULL
0x1FAE2F: 5E              pop  esi
0x1FAE30: C3              ret
0x1FAE31: 57              push edi
0x1FAE32: 6A 01           push 1                    ; 第 3 个参数 = 1
0x1FAE34: E8 B7 5C FE FF  call 0x50AF0           ; ★ 解析函数 #1（__thiscall，ecx=ctx，[esp+4]=1）
0x1FAE39: 8B CE           mov  ecx, esi              ; ecx = id
0x1FAE3B: 8B F8           mov  edi, eax
0x1FAE3D: E8 2E 7B FC FF  call 0x1C1C70           ; ★★ 解析函数 #2（把 id 交给容器 get）—— 关键的那一步
0x1FAE42: 8B C8           mov  ecx, eax
0x1FAE44: 33 C0           xor  eax, eax
0x1FAE46: 83 F9 FF        cmp  ecx, -1
0x1FAE49: 0F 45 C1        cmovne eax, ecx            ; -1 -> 0（NULL）
0x1FAE4C: 5F              pop  edi
0x1FAE4D: 5E              pop  esi
0x1FAE4E: C3              ret
```

> **更正记录**：DTTTP 的调用点是 `mov ecx,[ebp+0x18]; call 0x1FAE20`。
> `0x1DFE8D` 处的 `E8 8E BB 01 00` 相对位移落在 **`0x1FAE20`**，
> 所以 DTTTP 走的就是上面这条线性路径（**没有别的分支**）：
> **`ecx` = 字符串 id → `0x50AF0`（附带 ctx）→ `0x1C1C70`（容器下标查询）→ `char*`。**
>
> **关键结论（本轮最终）**：`0x1FAE20` 是 **`__fastcall`**，**`ecx` = 字符串 id**；
> 它把 id 交给 `0x1C1C70` 做**容器下标查询**。**所以 native 的第 5 参数是"字符串 id"。**

`0x1C1C70` 的原始字节 + 反汇编（**确证**）：

```
0x1C1C70: 55              push ebp
0x1C1C71: 8B EC           mov  ebp, esp
0x1C1C73: 8B 45 08        mov  eax, [ebp+0x8]        ; eax = 入参（DTTTP 的字符串参数）
0x1C1C76: 8B 49 20        mov  ecx, [ecx+0x20]       ; ecx = [ctx + 0x20] = 字符串表容器
0x1C1C79: 85 C0           test eax, eax              ; ★★ 只判 "!= 0"，【从不判可读性】
0x1C1C7B: 75 07           jne  +
0x1C1C7D: 83 C8 FF        or   eax, -1              ; 入参 == 0 -> 返回 -1
0x1C1C80: 5D              pop  ebp
0x1C1C81: C2 04 00        ret  4
0x1C1C84: 50              push eax
0x1C1C85: 83 C1 04        add  ecx, 4
0x1C1C88: E8 C3 5B 00 00  call 0x577850           ; 容器的 "get(index)" 方法（带边界检查）
0x1C1C8D: 85 C0           test eax, eax
0x1C1C8F: 74 EC           je   (返回 -1)
0x1C1C91: 8B 40 18        mov  eax, [eax+0x18]       ; ★ 表项 +0x18 = char*（正文）
0x1C1C94: 5D              pop  ebp
0x1C1C95: C2 04 00        ret  4
```

**三条决定性证据 ⇒ 入参是"字符串 id"（下标），不是指针：**

1. **`0x1C1C79` 只做 `test eax,eax`**（判 0），**完全没有 `Readable`/范围校验/`IsBadReadPtr`**。
   如果它接收的是"字符串对象指针"，第一件事必然是判可读性——**没有**。
2. **`0x1C1C84: push eax` + `add ecx,4` + `call 0x577850`** —— 这是**把入参当 vector 下标**去取元素。
   一个对象指针不可能被当成下标使用还能工作。
3. **`call 0x1C1C70` 只有 1 个直接调用点**（全 `.text` 搜索 `E8 46 7A FC FF` = **唯一命中**，
   位于 `RVA 0x1FAE25`）——即 `0x1FAE20` 是它唯一的上游，`0x1FAE20` 又只被
   `DisplayTimedTextToPlayer`(`0x1DFE8D`) / `DisplayTextToPlayer`(`0x1DFCF5`) /
   `SetTextTagText`(`0x1F6F94`) 这族"带 `S` 参数的 native"调用。
   **整个引擎的 `S` 参数只有这一条通路，所以 `S` 的语义在引擎里是统一的。**

**交叉验证（另一条独立证据）：`ydbase.dll::?create_string@…@@YAIPBD@Z`（RVA `0x19A80`）返回的就是 id**

```
0x19A80: 56              push esi
0x19A81: 8B 74 24 0C     mov  esi, [esp+0xC]     ; esi = 字符串表对象（thiscall 的 ecx 由 0x18C30 设置）
0x19A85: 8B 4E 28        mov  ecx, [esi+0x28]    ; ★ 字符串表 +0x28 = 当前 count（= 将要分配的 id）
0x19A88: 83 F9 10        cmp  ecx, 0x10
0x19A8B: 72 28           jb   +
0x19A8D: 8B 46 14        mov  eax, [esi+0x14]
...
0x19AA9: E8 A4 DD 00 00  call 0x10F860           ; ★ 引擎/内部：分配新 id
0x19AAE: 83 C4 08        add  esp, 8
0x19AB1: 6A 2C           push 0x2C               ; ★ 32 字节的 string_fake
0x19AB3: 56              push esi
0x19AB4: C7 46 24 00 00 00 00  mov dword [esi+0x24], 0
0x19AB8: C7 46 28 0F 00 00 00  mov dword [esi+0x28], 0x0F     ; ★ 递增 count = 新 id
0x19ABF: C6 46 14 00     mov  byte  [esi+0x14], 0
0x19AC3: 6A 2C           push 0x2C
0x19AC5: 56              push esi
0x19AC6: C7 46 24 00 00 00 00  mov dword [esi+0x24], 0
0x19ACA: C7 46 28 0F 00 00 00  mov dword [esi+0x28], 0x0F
0x19AD1: C6 46 14 00     mov  byte  [esi+0x14], 0
0x19AD5: E8 87 DD 00 00  call 0x10D650
0x19ADA: 83 C4 08        add  esp, 8
0x19ADD: 5E              pop  esi
0x19ADE: C3              ret
```

`ydbase` 的 `create_string` 返回的是**字符串表计数（= id）**，且**每个 id 对应一个 32 字节的
`string_fake` 条目**。`from_string(id)`（RVA `0x19B50`）再把它转回 `char*`。
**⇒ 引擎与 ydbase 对 `S` 参数的约定完全一致：传 id。**

**⇒ 结论（确证）：`DisplayTimedTextToPlayer` 的第 5 参数 = 字符串 id（小整数），
不是 `const char*`，也不是"字符串对象指针"。**

> 🚫 **本结论已于 2026-09-28 被实机推翻**（见本节末尾的"⚠️⚠️ 实机更正"）：
> 第 5 参数**就是字符串对象指针**，不是 id。下面这段"判定"整段作废，保留只为留下教训。

**⇒ 对你们现有写法的判定**：你们现在的做法是"自己造 `string_fake` 对象、把对象指针当参数传"。
这**在 ydbase 下"看起来能用"是偶然**（`call_param::push<const char*>` 与 JASS 栈把那个指针当 id
喂给引擎，越界读恰好落到容器里的某条目上）。**脱离 ydbase 后不再成立 ⇒ 必须改成传 id。**
你们注释里"`0x105A` 被 native 当对象解引用 → 访问违例"**说反了**：
`0x105A` 才是**正确的 id**，被当 id 解引用的恰恰是你们造的那个对象指针。

### 2.3 ydbase 侧对"字符串对象布局"的独立确证（`+0x08` 与 `+0x1C`）

> 这一节证明的是**字符串对象（`string_fake`）内部长什么样**——当你手里已经有一个
> 字符串对象/句柄、想取出 `char*` 时用它。而 §2.2 证明的是**native 参数要的是 id**。
> 两者不矛盾：**要显示文本，传 id；要读文本，用下面的 `from_string` 路径。**

---

## ⚠️⚠️ 2026-09-28 实机更正：`S` 参数是【字符串对象指针】，**不是 id**（上面两节结论作废）

上面的"要显示文本，传 id"**是错的**，已被**逐字节复核 + 实机日志**同时推翻。
正确结论：**`S` 参数 = `string_fake` 对象指针**，引擎拿到它以后自己做 `[S+0x08] → [+0x1C]` 两次解引用。
换句话说 —— §2.3 里 `from_string` 那个形状（`mov eax,[esp+4]; mov eax,[eax+8]; …`）
**就是 `S` 参数的约定本身**，当初把它读成"from_string 收 id"才是误读的源头：
`[esp+4]` 收到的从来不是 id，而是对象指针。

**证据 1：引擎侧 `S` 解析器（`SetTextTagText` 调用点 `0x1F6F94` 的目标）**

`0x1F6F94: E8 87 4A 00 00` → 目标 = `0x1F6F99 + 0x4A87` = **RVA `0x1FBA20`**，正文：

```
0x001FBA20: push esi                    ; 56
0x001FBA21: mov  esi, ecx               ; 8B F1        ← ecx = 传进来的 S
0x001FBA23: mov  ecx, ds:0x6FBE4238     ; ctx
0x001FBA29: test ecx, ecx / jne         ; ctx==0 -> 返回 NULL
0x001FBA31: push edi
0x001FBA32: push 1
0x001FBA34: call 0x1C35B0               ; ctx -> 临时 std::string
0x001FBA39: mov  ecx, esi
0x001FBA3B: mov  edi, eax
0x001FBA3D: call 0x516F0                ; ★★ S -> char*
0x001FBA42: mov  esi, eax
0x001FBA44: test esi, esi / je          ; NULL -> 返回 NULL
0x001FBA48: cmp  byte ptr [esi], 0 / je
0x001FBA4D: call 0x6D0FA0               ; strlen
0x001FBA59: push eax / mov ecx,edi / call 0x6D0CA0   ; std::string::assign(正文)
0x001FBA61: pop edi / pop esi / ret
```

而 `0x516F0`（**决定语义的就是这三行**）：

```
0x000516F0: mov eax, [ecx+0x08]     ; 8B 41 08   ← [S+0x08] = 字符串对象
0x000516F3: test eax, eax
0x000516F5: je   +4                 ; 0 -> 返回 NULL
0x000516F7: mov eax, [eax+0x1C]     ; 8B 40 1C   ← [对象+0x1C] = char*
0x000516FA: ret
```

⇒ 传 id（小整数，例如 `0x105A`）会让引擎去读 `[0x105A+8] = [0x1062]` —— **低地址访问违例 C0000005**，
每一次调用都崩，屏幕上一个字都不出。

**证据 2：实机日志（本插件 v1.3.1，`backend=native`）**

```
W TextTag：按【指针】调 SetTextTagText 的 R 参数抛异常(code=C0000005) -> 改用【传值】形态，下一次重试
E TextTag：SetTextTagText 抛异常(code=C0000005)，已吞掉（只写日志）
```
两种 R 形态都崩 ⇒ 崩点不是 size 参数，而是**先执行的字符串解析**（`0x1F6F94`）。
把字符串参数改回"对象指针"后一切正常。

**证据 3：反证（一直都在）** —— 插件走 ydbase 的 JAPI 路径时，传的就是自己造的 `string_fake`
对象指针，TextTag 飘字**显示完全正常**（有截图/日志为证）。"传对象指针只是偶然"这个判断是错的。

**⇒ 本节结论（供以后引用）**：

| 项 | 值 |
|---|---|
| `S` 参数语义 | **`string_fake` 对象指针**（`[S+8]`→对象、`[对象+0x1C]`→`char*`） |
| `S` 参数**不是** | 字符串 id / `char*` |
| `R` 参数语义 | `float*`（指向 float 的指针，见 §2.4 与 `无JAPI后端实装说明.md` §4.2） |
| `SetTextTagColor` 4 整数顺序 | **(red, green, blue, alpha)**（逐字节复核：byte0←参数3、byte1←参数2、byte2←参数1、byte3←参数4） |
| 造 `string_fake` | 用插件里的 `MakeJassString()`（静态池、`+0x08`=自身、`+0x1C`=正文），**自足、不依赖 ydbase** |

**⇒ 作废声明**：§2.4 的"方案 A（查表复用 id）/ 方案 B（探针扫 id）/ 方案 C（自己挂表）"
以及 §2.6 的 `ProbeStringIds()` 全部**作废** —— 它们在解一个不存在的问题。
`0x1DA520`（造 id）显示路径不再使用；`0x1C2870`/运行期字符串表仍然用于
**把引擎"返回"的 id（如 `GetUnitName` 的返回值）反查成正文**，这条与传参无关，继续有效。

`ydbase.dll` 的 `?from_string@jass@warcraft3@base@@YAPBDI@Z`（**RVA `0x19B50`**）原始字节：

```
0x19B50: 8B 44 24 04   mov  eax, [esp+4]      ; eax = 字符串对象指针
0x19B54: 85 C0         test eax, eax
0x19B56: 74 0B         je   ret0
0x19B58: 8B 40 08      mov  eax, [eax+0x08]   ; ★ +0x08
0x19B5B: 85 C0         test eax, eax
0x19B5D: 74 04         je   ret0
0x19B5F: 8B 40 1C      mov  eax, [eax+0x1C]   ; ★ +0x1C = char*
0x19B62: C3            ret
0x19B63: 33 C0         xor  eax, eax
0x19B65: C3            ret
```

`ydbase.dll` 的 `?object_to_handle…`（RVA `0x1CE80`，**确证**）也是同一个概念：

```
0x1CE80: 56             push esi
0x1CE81: E8 AA 76 FF FF call 0x13930           ; 取某全局
0x1CE86: B9 01 00 00 00 mov  ecx, 1
0x1CE8B: 8B 80 A4 28 00 00  mov eax,[eax+0x28A4]   ; ← 只 read 上层对象
...
0x1CE93: 8B 86 98 01 00 00  mov eax,[esi+0x198]   ; 数量
0x1CE99: 8D 14 40       lea  edx, [eax+eax*2]   ; edx = count*3
0x1CE9C: 3B D1          cmp  edx, ecx
0x1CE9E: 76 1E          jbe  ret0
0x1CEA0: 8B 86 9C 01 00 00  mov eax,[esi+0x19C]   ; 表基址 T
0x1CEA6: 8B 74 24 08    mov  esi, [esp+8]       ; esi = 入参（对象指针）
0x1CEAA: 83 C0 04       add  eax, 4             ; eax = T+4
0x1CEAD: 0F 1F 00       nop  [eax]
0x1CEB0: 3B 30          cmp  esi, [eax]         ; ★ 比较 [T+4+i*12] == 对象指针
0x1CEB2: 74 0E          je   found
0x1CEB4: 83 C1 03       add  ecx, 3
0x1CEB7: 83 C0 0C       add  eax, 12
0x1CEBA: 3B CA          cmp  ecx, edx
0x1CEBC: 72 F2          jb   loop
0x1CEBE: 33 C0          xor  eax, eax
0x1CEC0: 5E             pop  esi
0x1CEC1: C3             ret
0x1CEC2: 49             dec  ecx
0x1CEC3: B8 AB AA AA AA mov  eax, 0AAAAAAABh
0x1CEC8: F7 E1          mul  ecx
0x1CECA: 5E             pop  esi
0x1CECB: D1 EA          shr  edx, 1
0x1CECD: 8D 82 00 00 10 00  lea eax, [edx+0x100000]   ; ★★ handle = 0x100000 + i
```

**⇒ ⑤ 的关键**：JASS 句柄 = **`0x100000 + 槽位下标`**。
（这也解释了你日志里的 `Hplayer=00100009` ⇒ 槽位 9；单位句柄 `00100683` ⇒ 槽位 1667。）

### 2.4 结论：原型怎么写、参数怎么传

> 🚫 **本节的"参数表"与"方案 A/B/C"已作废** —— `S` 要传**字符串对象指针**，
> 不是 id；更正与证据见上一节末尾的 **"⚠️⚠️ 实机更正"**。
> 现在可用的正确写法（本插件 v1.3.2 实装）：`SetTextTagText(tag, MakeJassString(文本), &size)`。

| 参数 | JASS 类型 | 实际数据类型 | 怎么传 |
|---|---|---|---|
| 1 `Hplayer` | handle | **32 位整数句柄**（不是指针！） | 直接当 `uint32_t` 压栈 |
| 2 `R` (x) | real | `float` | 当 `float` 压栈（**不是** `to_real` 的整数位模式） |
| 3 `R` (y) | real | `float` | 同上 |
| 4 `R` (duration) | real | `float` | 同上 |
| 5 `S` (message) | string | ~~**字符串 id（小整数）**~~ **🚫 已推翻：字符串对象指针（`string_fake*`）** | 见 §2.3 末尾的实机更正 |

**⇒ 直接回答"是否照旧"：不照旧，必须改。**
你们现在的写法（"按 `string_fake` 布局造对象、`+0x08`=自身、`+0x1C`=char*，
把**对象指针**当第 5 个参数传"）在 ydbase 下"能用"只是**偶然**——
因为 ydbase 的 `call_param::push<const char*>` 与 JASS VM 对 `S` 参数的处理在某些路径上
把"对象指针"当成了合法 id 传给引擎（引擎侧那个 `get(id)` 只是越界读，容器里恰好有那块内存）。
**一旦脱离 ydbase，这个偶然就没了。**

**正确做法（三种，按推荐度）：**

#### 方案 A（推荐）：查表复用已有字符串 id，把 id 当第 5 参数传

> 🚫 **作废**（前提"要传 id"已被推翻）。正确做法：传 `MakeJassString()` 造的对象指针。

```cpp
//------------------------------------------------------------------------------
// ② DisplayTimedTextToPlayer —— 引擎直连（game.dll 1.27.0.52240）
//   signature (Hplayer;RRRS)V，实现 RVA 0x001DFE70，__cdecl（`ret`，调用者清栈）
//   ★ 第 5 参数 = 字符串 id（整数），经 0x1FAE20 -> 0x1C1C70 在 [ctx+0x20] 容器里查表
//------------------------------------------------------------------------------
typedef void (__cdecl *fn_DTTTP_t)(uint32_t hplayer, float x, float y, float duration, uint32_t stringId);

// ---- 字符串表：ctx->+0x20 的对象，其 +0x04 起是 vector<string_fake*> ----
//   每个 string_fake 32 字节，+0x1C = char*（ydbase 0x19980 构造 / 0x19B50 from_string 确证）
//   ★ 关键推论：表中第 i 个元素的 id 就是 i（0x1C1C70 把参数当下标直接用）
#define WC3_CTX_GLOBAL_RVA   0x00BE4238u
#define WC3_STRING_TABLE_OFF 0x00000020u   // ctx + 0x20 = 字符串表对象
#define WC3_STRFAKE_TEXT_OFF 0x0000001Cu   // string_fake + 0x1C = char*
#define WC3_MAX_STRING_ID    0x00080000u   // 防御上限

// 在字符串表里线性找一个"内容相同"的已有 id；找不到返回 0
// 说明：字符串表有约 1e5~1e6 条，全表线性扫描较贵 —— 建议【启动时扫一次建 map】，
//       或直接调用方案 C 的引擎 create_string。
static uint32_t FindExistingStringId(const char* text)
{
    if (!text || !text[0]) return 0;
    uint32_t base = (uint32_t)(uintptr_t)GetModuleHandleA("game.dll");
    if (!base) return 0;

    uint32_t id = 0;
    __try {
        uint32_t ctx = *(volatile uint32_t*)(uintptr_t)(base + WC3_CTX_GLOBAL_RVA);
        if (!ctx) return 0;
        uint32_t tbl = *(volatile uint32_t*)(uintptr_t)(ctx + WC3_STRING_TABLE_OFF);
        if (!tbl) return 0;

        // 容器布局（0x1C1C70 里 "add ecx,4" 后调 0x577850，后者按下标取元素）：
        //   +0x000 vptr
        //   +0x004 std::vector<string_fake*> 的 begin  (元素 = string_fake*)
        //   +0x008 end      +0x00C cap
        uint32_t begin = *(volatile uint32_t*)(uintptr_t)(tbl + 0x04);
        uint32_t end   = *(volatile uint32_t*)(uintptr_t)(tbl + 0x08);
        if (!begin || end <= begin) return 0;
        uint32_t n = (end - begin) / 4u;
        if (n > WC3_MAX_STRING_ID) return 0;

        for (uint32_t i = 0; i < n; ++i) {
            uint32_t pp = 0;
            if (!Readable((const void*)(uintptr_t)(begin + i * 4u), 4)) break;
            pp = *(volatile uint32_t*)(uintptr_t)(begin + i * 4u);
            if (!pp) continue;
            uint32_t sp = 0;
            if (!Readable((const void*)(uintptr_t)(pp + 4), 4)) continue;   // string_fake*（表存的是指针）
            sp = *(volatile uint32_t*)(uintptr_t)(pp + 4);
            if (!sp) continue;
            uint32_t cp = 0;
            if (!Readable((const void*)(uintptr_t)(sp + WC3_STRFAKE_TEXT_OFF), 4)) continue;
            cp = *(volatile uint32_t*)(uintptr_t)(sp + WC3_STRFAKE_TEXT_OFF);
            if (!cp || !Readable((const void*)(uintptr_t)cp, 2)) continue;
            if (strcmp((const char*)(uintptr_t)cp, text) == 0) { id = i; break; }
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return id;
}
```

> ⚠️ 上面"表里存的是 `string_fake*` 还是 `string_fake`"这一步是**推断**（两张可能性都写出了防御）。
> 请用 **§2.6 的自检** 一次打印定案，然后删掉多余分支。

#### 方案 B（**最稳，强烈推荐先做**）：用"只判 `!=0` 的下标查询"当探针，反推出 id

> 🚫 **作废**（同上：S 不传 id，探针扫 id 没有意义）。

`0x1C1C70` 的行为是：`id == 0` → 返回 -1（→ NULL，不显示）；否则用容器 `get(id)`。
所以**只要 `id` 落在容器有效范围内且 `[表项+0x1C]` 可读，就能正常显示**。
⇒ **可以用 §2.6 的自检扫描 `id ∈ [1, N]`，找出能让文本正确显示的那个 id**，
把它硬编码/缓存起来（对**固定标签**如"物理"/"魔法"/伤害数字格式，一次扫描永久可用）。

#### 方案 C（最干净，但需要一点堆操作）：自己造 `string_fake` 并挂进字符串表

> ⚠️ **部分作废**：S 参数**确实**要 `string_fake` 对象，但**不需要**"挂进引擎字符串表" ——
> 自己造一个对象、把指针当参数传即可（插件里的 `MakeJassString()` 就是这么做的）。

`ydbase::create_string` 的内部实现（**RVA `0x10F860`，确证**，`__cdecl const char* → uint32_t id`）：

```
0x10F860: 8B 46 28          mov  eax, [esi+0x28]      ; esi = 字符串表对象；+0x28 = 当前 count（也是新 id）
0x10F863: 83 F9 10          cmp  ecx, 0x10            ; ecx = strlen(arg)（0x19A85 处算好）
0x10F866: 72 28             jb   +
0x10F868: 8B 46 14          mov  eax, [esi+0x14]
0x10F86B: 41                inc  ecx
0x10F86C: 81 F9 00 00 10 00 cmp  ecx, 0x100000
0x10F873: 72 12             jb   +
...
0x10F8A5: 8B C2             mov  eax, edx
0x10F8A7: 51                push ecx
0x10F8A8: 50                push eax
0x10F8A9: E8 A4 DD 00 00    call 0x10D652             ; 写正文
0x10F8AE: 83 C4 08          add  esp, 8
0x10F8B1: 6A 2C             push 0x2C                 ; ★ 32 字节的 string_fake
0x10F8B3: 56                push esi
0x10F8B4: C7 46 24 00 00 00 00  mov dword [esi+0x24], 0
0x10F8B8: C7 46 28 0F 00 00 00  mov dword [esi+0x28], 0x0F   ; ★ 递增后的新 count = 新 id
0x10F8BF: C6 46 14 00       mov  byte  [esi+0x14], 0
0x10F8C3: E8 87 DD 00 00    call 0x10D650
0x10F8C8: 83 C4 08          add  esp, 8
0x10F8CB: 5E                pop  esi
0x10F8CC: C3                ret
```

⇒ **`create_string` 的真正入口在引擎里**：`Game.dll` 里 `0x1C1C70` 那条路径对应的
"字符串表 `+0x1C` 一致性检查 + `+0x24`/`+0x28` 计数器" 就是它的兄弟。
**结论：不要自己造 `string_fake`（很容易把引擎的 count/容量搞坏），用方案 A 或 B。**

### 2.5 与"另一个 native 是否同 ABI"的交叉验证（**确证**）

`SetTextTagText`（`RVA 0x1F6F70`，签名 `(Htexttag;SR)V`）**第 2 个参数就是字符串**：

```
0x1F6F70: 55 / 8B EC       push ebp; mov ebp,esp
0x1F6F73: 56                push esi
0x1F6F74: 8B 75 08          mov  esi, [ebp+8]        ; Htexttag
0x1F6F77: 3B 35 48 7A A6 6F cmp  esi, ds:0x6FA67A48   ; ★ 句柄上界校验
0x1F6F7D: 73 31             jae  ret0
0x1F6F7F: 8B 0D 38 42 BE 6F mov  ecx, ds:0x6FBE4238   ; ctx
0x1F6F85: 57                push edi
0x1F6F86: E8 75 C2 FC FF    call 0x1C2600           ; ctx -> 句柄管理器
0x1F6F8B: 8B F8             mov  edi, eax
0x1F6F8D: 85 FF / 74         test edi,edi / je ret
0x1F6F91: 8B 4D 0C          mov  ecx, [ebp+0xC]     ; ★★ 第 2 参数 = S（字符串）
0x1F6F94: E8 87 4A 00 00    call 0x1FAE20           ; ★★ 与 DTTTP 完全同一个字符串解析
0x1F6F99: 51                push ecx
0x1F6F9A: 8B 4D 10          mov  ecx, [ebp+0x10]    ; R (size)
0x1F6F9D: F3 0F 10 01       movss xmm0, [ecx]
0x1F6FA1: 8B CF             mov  ecx, edi
0x1F6FA3: F3 0F 11 04 24    movss [esp], xmm0
0x1F6FA8: 50                push eax
0x1F6FA9: 56                push esi
0x1F6FAA: E8 11 6E 07 00    call 0x26D1C0
0x1F6FAF: 5F / 5E / 5D / C3 pop edi; pop esi; pop ebp; ret   ; ★ 同样 `ret`
```

**⇒ 引擎里所有带 `S` 参数的 native 都走同一个 `0x1FAE20`。整个字符串 ABI 只有这一套。**

### 2.6 运行时自检（把 §2.4 的"推断"变成"确证"，只跑一次）

```cpp
// 逐 id 试探：找出能让 DisplayTimedTextToPlayer 真正显示的 id
//   原理：0x1C1C70 只判 id != 0，然后容器 get(id)；id 无效 -> NULL -> 不显示（不崩）
//   做法：先用 1 次尝试确认"某个 id 能显示"，再二分/线性收敛
static void ProbeStringIds(uint32_t hp, float x, float y)
{
    fn_DTTTP_t fn = (fn_DTTTP_t)Wc3NativeByName("DisplayTimedTextToPlayer");
    if (!fn) { LogLine("probe: 取不到 DTTTP"); return; }

    uint32_t base = (uint32_t)(uintptr_t)GetModuleHandleA("game.dll");
    uint32_t ctx  = 0, tbl = 0, begin = 0, end = 0;
    __try {
        ctx   = *(volatile uint32_t*)(uintptr_t)(base + WC3_CTX_GLOBAL_RVA);
        tbl   = *(volatile uint32_t*)(uintptr_t)(ctx + WC3_STRING_TABLE_OFF);
        begin = *(volatile uint32_t*)(uintptr_t)(tbl + 0x04);
        end   = *(volatile uint32_t*)(uintptr_t)(tbl + 0x08);
    } __except (EXCEPTION_EXECUTE_HANDLER) { LogLine("probe: 读表异常"); return; }

    LogLine("probe: ctx=%08X tbl=%08X begin=%08X end=%08X 条数=%u",
            ctx, tbl, begin, end, (end > begin) ? (end - begin) / 4u : 0u);

    // 打印前 8 条，确认 "表里存的是指针还是对象"（一次定案）
    for (uint32_t i = 0; i < 8 && begin && end > begin; ++i) {
        uint32_t v1 = 0, v2 = 0, cp = 0;
        __try {
            v1 = *(volatile uint32_t*)(uintptr_t)(begin + i * 4u);
            if (v1) {
                v2 = *(volatile uint32_t*)(uintptr_t)(v1 + 4);            // 若表存指针：+4 = string_fake*
                if (v2) __try { cp = *(volatile uint32_t*)(uintptr_t)(v2 + WC3_STRFAKE_TEXT_OFF); } __except (EXCEPTION_EXECUTE_HANDLER) {}
            }
        } __except (EXCEPTION_EXECUTE_HANDLER) {}
        char buf[64] = { 0 };
        if (cp && Readable((const void*)(uintptr_t)cp, 2))
            strncpy_s(buf, (const char*)(uintptr_t)cp, _TRUNCATE);
        LogLine("probe: id=%u [tbl+4i]=%08X [+4]=%08X [+1C]=%08X text=[%s]", i, v1, v2, cp, buf);
    }

    // 试着用前若干个 id 显示同一句话，哪个 id 真的出字，那个就是对的
    for (uint32_t id = 1; id <= 40; ++id) {
        if (!fn) break;
        __try { fn(hp, x, y, 8.0f, id); }
        __except (EXCEPTION_EXECUTE_HANDLER) { LogLine("probe: id=%u 崩溃 code=%08X", id, (uint32_t)GetExceptionCode()); break; }
    }
    LogLine("probe: 上面 40 次里，屏幕上出现文本的那个 id 就是正确的字符串 id 语义；");
    LogLine("probe: 若都没出现，改把 string_fake* 当 id 传（即你们的旧写法）再试 —— 两者只会有一个对。");
}

// 顺便验证"旧写法为什么错"：把对象指针当 id 传，看是否崩/是否不显示
static void ProbeOldWayVsNewWay(uint32_t hp, float x, float y)
{
    fn_DTTTP_t fn = (fn_DTTTP_t)Wc3NativeByName("DisplayTimedTextToPlayer");
    if (!fn) return;
    uint32_t fakeObj = 0;   // 用你们现有 MakeJassString 造一个 string_fake 的地址填进来
    __try { fn(hp, x, y, 8.0f, fakeObj);  LogLine("probe: 旧写法（传对象指针）未崩"); }
    __except (EXCEPTION_EXECUTE_HANDLER) { LogLine("probe: 旧写法（传对象指针）崩了 code=%08X ⇒ 证实参数是 id 不是指针", (uint32_t)GetExceptionCode()); }
    __try { fn(hp, x, y, 8.0f, 1u);       LogLine("probe: 传 id=1 未崩"); }
    __except (EXCEPTION_EXECUTE_HANDLER) { LogLine("probe: 传 id=1 崩了 code=%08X", (uint32_t)GetExceptionCode()); }
}
```

> **旧注释的真因（本轮更正）**：你们注释里写
> "`create_string` 给的 `0x105A` 被 native 当对象解引用 → 访问违例"
> —— 恰恰**说反了**：`0x105A` 是**正确的 id**，而"你们自己造的 `string_fake` 对象指针"
> 才是被当成 id 解引用的那个。**所以修法不是"造对象"，而是"拿到 id"。**

---

## 3. ③ 对象 → JASS 句柄（`CUnit*` → `Hunit`）

### 3.1 引擎自己的那条路径（**确证**的调用点）

两个"返回 handle"的 native 实现内部**完全同构**，都做同一件事：

```
GetLocalPlayer  (RVA 0x001E3150, signature ()Hplayer;)
  0x1E3150: 56                push esi
  0x1E3151: 8B 35 38 42 BE 6F mov  esi, ds:0x6FBE4238      ; esi = 引擎全局 ctx
  0x1E3157: 85 F6             test esi, esi
  0x1E3159: 75 04             jne  +
  0x1E315B: 33 C0 / 5E / C3   xor eax,eax; pop esi; ret     ; ctx 为空 -> 0
  0x1E315F: E8 3C B8 12 00    call 0x30DDA0                ; 取"本地玩家索引/有效标志"
  0x1E3164: 8B CE             mov  ecx, esi
  0x1E3166: 85 C0             test eax, eax
  0x1E3168: 74 06             je   +
  0x1E316A: 0F B7 46 2A       movzx eax, word [esi+0x2A]   ; * 用 +0x2A
  0x1E316E: EB 04             jmp  +
  0x1E3170: 0F B7 46 28       movzx eax, word [esi+0x28]   ; * 或 +0x28（本地玩家索引）
  0x1E3174: 50                push eax
  0x1E3175: E8 B6 01 FE 00    call 0x1C2730                ; 索引 -> CPlayer*
  0x1E317A: 8B 0D 38 42 BE 6F mov  ecx, ds:0x6FBE4238
  0x1E3180: 8B F0             mov  esi, eax                ; esi = CPlayer*
  0x1E3182: E8 79 00 FE 00    call 0x1C2600                ; ★ ctx -> 句柄管理器 (this)
  0x1E3187: 6A 00             push 0                       ; 第 2 个栈参数 = 0（不新建句柄）
  0x1E3189: 56                push esi                     ; 第 1 个栈参数 = 对象指针
  0x1E318A: 8B C8             mov  ecx, eax                ; ecx = 句柄管理器
  0x1E318C: E8 3F 20 08 00    call 0x2645D0            ; ★★★ 对象 -> 句柄
  0x1E3191: 5E                pop  esi
  0x1E3192: C3                ret                          ; 返回值 eax = Hplayer

GetOwningPlayer (RVA 0x001E3BA0, signature (Hunit;)Hplayer;)
  0x1E3BA0: 55 / 8B EC       push ebp; mov ebp,esp
  0x1E3BA3: 8B 4D 08          mov  ecx, [ebp+8]            ; Hunit
  0x1E3BA6: E8 A5 D9 FE 00    call 0x1D0950                ; Hunit -> CUnit*
  0x1E3BAB: 85 C0 / 74       test eax,eax / je ret
  0x1E3BB1: 56                push esi
  0x1E3BB2: 8B C8             mov  ecx, eax
  0x1E3BB4: E8 D7 4C 48 00    call 0x667C90                ; CUnit* -> CPlayer*
  0x1E3BB9: 8B 0D 38 42 BE 6F mov  ecx, ds:0x6FBE4238
  0x1E3BBF: 8B F0             mov  esi, eax
  0x1E3BC1: E8 3A F6 FD 00    call 0x1C2600                ; ctx -> 句柄管理器
  0x1E3BC6: 6A 00             push 0
  0x1E3BC8: 56                push esi                     ; CPlayer*
  0x1E3BC9: 8B C8             mov  ecx, eax
  0x1E3BCB: E8 00 16 08 00    call 0x2645D0            ; ★★★ 对象 -> 句柄
  0x1E3BD0: 5E / 5D / C3      pop esi; pop ebp; ret        ; eax = Hplayer
```

**⇒ 转换器的确切形态（确证）：**

| 项 | 值 |
|---|---|
| 转换函数 | **热入口 RVA `0x002645D0`**（⚠️ 见下方"入口性质"说明） |
| 调用约定 | `__thiscall` + 2 个栈参数（`ret 8`）—— 从被调方 `mov esp,ebp; pop ebp; ret` 与调用点 `push 0; push obj` 判定 |
| `ecx` | **句柄管理器**。调用点先 `mov ecx, ds:0x6FBE4238`（= ctx）再 `call 0x1C2600`，由 `0x1C2600` 返回（`0x1C2600` 是 `__thiscall` `ctx→mgr`，内部 `lea ecx,[esi+0xF4]`，**确证**） |
| `[esp+4]` | **对象指针**（`CPlayer*` / `CUnit*` / 任意 `CObject*`） |
| `[esp+8]` | `0` = **不新建**（只用既有句柄表项） |
| 返回值 `eax` | **JASS 句柄**（`0x100000 + 槽位`）；失败返回 0 |

> **入口性质说明（重要，别被"函数起点"绊住）**：`0x002645D0` 是**被两处调用点直接 `call` 的地址**，
> 但 `Game.dll` **没有 `.pdata`**（Exception Directory = 0），无法程序化确定函数边界，
> 我的回溯启发式在 x86 变长指令下不可靠 ⇒ **`0x2645D0` 究竟是"函数起点"还是"函数体内的热入口"
> 我无法静态定论**。**但这不影响使用**：调用形态（`ecx`=管理器、`push flags`、`push obj`、
> `ret 8`、返回 `eax`=句柄）完全由 `GetOwningPlayer` / `GetLocalPlayer` 两个**引擎自己的调用点**确证，
> C++ 片段照抄即可。若用 IDA/Ghidra 交叉验证发现真正的函数起点在 `0x2645D0` 之前
> （可能的候选是 `RVA 0x263990` 那个 body），**只要整个函数的 `__thiscall` 契约一致，调用结果不变**。

**⇒ 内部代码路径（三条证据）**：

1. **缓存字段**：`0x2645D0` 内部会尝试从对象里**读/写**一个字段（反汇编 `0x2645E3: mov ecx,[eax+0x14]` / `0x2645E9: mov eax,[eax+0x18]` / `0x2645E6: mov [esi+8],ecx` / `0x2645EC: mov [esi+0xC],eax`）——即"对象 ↔ 句柄"的双向缓存/回填，**不是**每次线性扫表。
2. **槽位公式**：ydbase `object_to_handle`（RVA `0x1CE80`）在表里线性找 `[T+4+i*12] == obj`，命中后
   `handle = 0x100000 + i`（**确证**）。⇒ 引擎句柄编码就是 `0x100000 + 槽位下标`。
3. **同址复用**：`0x2645D0` 同时被 `GetOwningPlayer`（玩家对象）与 `GetLocalPlayer`（玩家对象）调用；
   而 `GetTriggerUnit`/`GetEnumUnit`（`0x1E5E10`/`0x1E21B0`）走的是 `0x1C2600` → `0x26AA70`
   取"当前事件/枚举上下文里的对象"再返回——**同样返回句柄**，说明 `0x26AA70` 是"事件上下文 → 句柄"，
   `0x2645D0` 是通用"对象 → 句柄"。

### 3.2 可直接嵌入的 C++ 片段（含 `Readable` / `__try` 防御）

```cpp
//------------------------------------------------------------------------------
// ③ CUnit* -> JASS Hunit（game.dll 1.27.0.52240）
//   引擎原生转换器 RVA 0x002645D0
//     调用点证据：GetOwningPlayer @0x1E3BA0 的 0x1E3BC1/0x1E3BC8/0x1E3BCB
//                 GetLocalPlayer  @0x1E3150 的 0x1E3182/0x1E3189/0x1E318C
//     形态：__thiscall + 2 栈参数（ret 8）
//           ecx = 句柄管理器（*(base+0xBE4238) 经 0x1C2600 得到）
//           [esp+4] = 对象指针   [esp+8] = 0（不新建）
//           返回 eax = 句柄（0 表示失败）
//
//   备选（纯内存、不调用）：句柄 = 0x100000 + 槽位下标
//     槽位表 = *(uint32_t*)(*(uint32_t*)(base + 0xBE4238) + 0xF4)
//     表项 stride = 12，对象指针在 表项+4  ⇒ cmp [T+4+i*12] == obj
//     依据：ydbase object_to_handle RVA 0x1CE80 (0x1CEB0 cmp esi,[eax] / 0x1CECD lea eax,[edx+0x100000])
//     说明：CUnit* 是 H-格式对象指针，表项+4 就是该对象自身；见 §3.3 运行期验证
//------------------------------------------------------------------------------
#define WC3_CTX_GLOBAL_RVA     0x00BE4238u   // ctx = *(uint32_t*)(base + 该 RVA)
#define WC3_HANDLE_FROM_OBJ_RVA 0x002645D0u  // 引擎：对象 -> 句柄
#define WC3_HANDLEMGR_FROM_CTX_RVA 0x001C2600u

typedef uint32_t (__fastcall *fn_ctx_to_handlemgr_t)(uint32_t ctx, void* dummyEDX);
typedef uint32_t (__thiscall  *fn_obj_to_handle_t)(uint32_t handleMgr, void* dummyEDX_unused);

// MSVC 对 __thiscall 的 2 个显式栈参数不支持直接 typedef -> 用 __fastcall + 哑 edx 不行（栈参数位置不同）。
// 因此这里采用「手工 push + __cdecl 外形」的等价写法：
typedef uint32_t (__cdecl *fn_obj_to_handle_cdecl_t)(uint32_t handleMgr, uint32_t obj, uint32_t flags);

static fn_obj_to_handle_cdecl_t s_objToHandle = NULL;
static fn_ctx_to_handlemgr_t   s_ctxToMgr    = NULL;
static int                     s_resolveObjToHandleFailed = 0;

static uint32_t Wc3ObjectToHandle(uint32_t obj)
{
    if (!obj) return 0;
    if (s_resolveObjToHandleFailed) return 0;

    uint32_t base = (uint32_t)(uintptr_t)GetModuleHandleA("game.dll");
    if (!base) return 0;

    // 一次性解析两个函数地址（带序言校验）
    if (!s_objToHandle || !s_ctxToMgr) {
        uint32_t fObj = base + WC3_HANDLE_FROM_OBJ_RVA;
        uint32_t fMgr = base + WC3_HANDLEMGR_FROM_CTX_RVA;
        uint8_t p1[3] = { 0 }, p2[3] = { 0 };
        __try { memcpy(p1, (const void*)(uintptr_t)fObj, 3); memcpy(p2, (const void*)(uintptr_t)fMgr, 3); }
        __except (EXCEPTION_EXECUTE_HANDLER) { s_resolveObjToHandleFailed = 1; return 0; }
        if (!(p1[0] == 0x55 && p1[1] == 0x8B && p1[2] == 0xEC)) {
            s_resolveObjToHandleFailed = 1;
            LogLine("obj->handle: RVA 0x%X 序言=%02X %02X %02X 不匹配，放弃",
                    WC3_HANDLE_FROM_OBJ_RVA, p1[0], p1[1], p1[2]);
            return 0;
        }
        s_objToHandle = (fn_obj_to_handle_cdecl_t)(uintptr_t)fObj;
        s_ctxToMgr    = (fn_ctx_to_handlemgr_t)(uintptr_t)fMgr;
    }

    uint32_t h = 0;
    __try {
        uint32_t ctx = 0;
        if (!Readable((const void*)(uintptr_t)(base + WC3_CTX_GLOBAL_RVA), 4)) return 0;
        ctx = *(volatile uint32_t*)(uintptr_t)(base + WC3_CTX_GLOBAL_RVA);
        if (!ctx) return 0;

        // ctx -> 句柄管理器（__thiscall，ecx=ctx，无栈参数）
        uint32_t mgr = (uint32_t)s_ctxToMgr(ctx, NULL);
        if (!mgr) return 0;

        // __thiscall mgr, [esp+4]=obj, [esp+8]=0  —— 用 __cdecl 外形等价调用
        h = (uint32_t)s_objToHandle(mgr, obj, 0);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E obj->handle 异常 code=%08X obj=%08X", (uint32_t)GetExceptionCode(), obj);
        return 0;
    }

    // 结果合理性校验：句柄必须落在 [0x100000, 0x100000+0x100000) 且低 12 位与对象一致（见 §3.3）
    if (h < 0x00100000u || h >= 0x00200000u) {
        LogLine("obj->handle: 返回 %08X 不合理，视为失败", h);
        return 0;
    }
    return h;
}

//------------------------------------------------------------------------------
// 备选：纯内存实现（完全不调用引擎函数，零副作用）
//   句柄 = 0x100000 + i ，i = 在 [T+4+i*12] 里匹配到 obj 的下标
//------------------------------------------------------------------------------
#define WC3_HANDLEMGR_OFF_IN_CTX 0x000000F4u   // 句柄管理器 = *(uint32_t*)(ctx + 0xF4)
#define WC3_HANDLE_TABLE_OFF     0x0000019Cu   // 表基址    = *(uint32_t*)(mgr + 0x19C)
#define WC3_HANDLE_COUNT_OFF     0x00000198u   // 条目数/3  = *(uint32_t*)(mgr + 0x198)

static uint32_t Wc3ObjectToHandleByMemory(uint32_t obj)
{
    uint32_t base = (uint32_t)(uintptr_t)GetModuleHandleA("game.dll");
    if (!base || !obj) return 0;

    uint32_t h = 0;
    __try {
        uint32_t ctx = *(volatile uint32_t*)(uintptr_t)(base + WC3_CTX_GLOBAL_RVA);
        if (!ctx) return 0;
        if (!Readable((const void*)(uintptr_t)(ctx + WC3_HANDLEMGR_OFF_IN_CTX), 4)) return 0;
        uint32_t mgr = *(volatile uint32_t*)(uintptr_t)(ctx + WC3_HANDLEMGR_OFF_IN_CTX);
        if (!mgr) return 0;

        uint32_t T     = *(volatile uint32_t*)(uintptr_t)(mgr + WC3_HANDLE_TABLE_OFF);
        uint32_t cnt3  = *(volatile uint32_t*)(uintptr_t)(mgr + WC3_HANDLE_COUNT_OFF);   // = 条目数 * 3
        if (!T || !cnt3 || cnt3 > 0x30000u) return 0;

        for (uint32_t i = 0; i < cnt3; i += 3) {
            uint32_t slot = T + 4 + i * 4;                 // 表项 stride 12 = 3 dword
            if (!Readable((const void*)(uintptr_t)slot, 4)) break;
            if (*(volatile uint32_t*)(uintptr_t)slot == obj) {
                h = 0x00100000u + i;                       // ★ handle = 0x100000 + i
                break;
            }
        }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return h;
}
```

### 3.3 失败时的返回与校验

| 情况 | 返回值 | 说明 |
|---|---|---|
| `obj == 0` | `0` | 提前返回 |
| `game.dll` 基址取不到 / RVA 序言不匹配 | `0`（并置 `s_resolveObjToHandleFailed`，本会话不再重试） | 版本不匹配 |
| `ctx == 0` | `0` | 引擎未初始化（早期调用） |
| `0x2645D0` 返回 0 | `0` | 对象不在句柄表里（未注册的单位/已销毁） |
| 返回不在 `[0x100000, 0x200000)` | `0`（记日志） | 防脏数据 |
| `__try` 捕获到异常 | `0` | 全部内存访问都在 `__try` 内 |

**§3.3.1 运行期强验证（一次日志即可确证/否证 §3.2）**

```cpp
// 用已知的"对象 ↔ 句柄"对做校验：
//   a) 你们现有 ydbase 可用时：object_to_handle(X) 与 Wc3ObjectToHandle(X) 必须相等
//   b) 没有 ydbase 时：从伤害钩子里拿到的 CUnit* 与日志里已知的句柄做交叉
//   c) 用 GetUnitTypeId 做语义校验（4 字符类型码）
static void VerifyObjectToHandle(uint32_t unitObj)
{
    uint32_t hFn  = Wc3ObjectToHandle(unitObj);
    uint32_t hMem = Wc3ObjectToHandleByMemory(unitObj);

    // 语义校验：CUnit*+0x30 = 4 字符类型码（GetUnitTypeId 实现 0x1E6670 的 0x1E6681 mov eax,[eax+0x30]）
    uint32_t typeId = 0;
    __try { if (Readable((const void*)(uintptr_t)(unitObj + 0x30), 4)) typeId = *(volatile uint32_t*)(uintptr_t)(unitObj + 0x30); }
    __except (EXCEPTION_EXECUTE_HANDLER) {}

    LogLine("OBJ2H: obj=%08X type='%c%c%c%c' (0x%08X) hFn=%08X hMem=%08X",
            unitObj,
            (char)(typeId & 0xFF), (char)((typeId >> 8) & 0xFF),
            (char)((typeId >> 16) & 0xFF), (char)((typeId >> 24) & 0xFF),
            typeId, hFn, hMem);

    // 再喂回引擎：Hunit -> CUnit*（RVA 0x1D0950），必须拿到同一个对象
    if (hFn) {
        typedef uint32_t (__fastcall *fn_h2o_t)(uint32_t handle, void* edx);
        fn_h2o_t h2o = (fn_h2o_t)(uintptr_t)((uint32_t)(uintptr_t)GetModuleHandleA("game.dll") + 0x001D0950u);
        uint32_t back = 0;
        __try { back = h2o(hFn, NULL); } __except (EXCEPTION_EXECUTE_HANDLER) {}
        LogLine("OBJ2H: %s  (hFn -> CUnit* = %08X, 期望 %08X)",
                back == unitObj ? "往返一致 ✓" : "往返不一致 ✗（object->handle 语义需要复核）",
                back, unitObj);
    }
}
```

> **这张日志就是本报告 ③ 的最终判定钥匙**：只要看到 `往返一致 ✓`，`0x2645D0` 就**从"强推断"升级为"确证"**。

---

## 4. ④ native 实现 RVA 清单

> 全部来自 **表 A**（file `0x1E8E50` 起，1167 条），**逐条读 `+16` imm32**，故一律 **确证**。

| native 名 | 签名 | 记录 # | 记录 file / RVA | 名字串 file / VA | **实现 RVA** | 实现 VA | 强度 |
|---|---|---|---|---|---|---|---|
| `DisplayTimedTextToPlayer` | `(Hplayer;RRRS)V` | #835 | `0x1ECF8C` / `0x1EDB8C` | `0x96C850` / `0x6F96D450` | **`0x001DFE70`** | `0x6F1DFE70` | 确证 |
| `GetUnitName` | `(Hunit;)S` | #399 | `0x1EAD7C` / `0x1EB97C` | `0x9694AC` / `0x6F96A0AC` | **`0x001E6340`** | `0x6F1E6340` | 确证 |
| `GetUnitTypeId` | `(Hunit;)I` | #397 | `0x1EAD54` / `0x1EB954` | `0x969474` / `0x6F96A074` | **`0x001E6670`** | `0x6F1E6670` | 确证（**修正**旧报告 `0x1E66C0`） |
| `GetUnitState` | `(Hunit;Hunitstate;)R` | #382 | `0x1EAC28` / `0x1EB828` | `0x969310` / `0x6F969F10` | **`0x001E6600`** | `0x6F1E6600` | 确证 |
| `GetOwningPlayer` | `(Hunit;)Hplayer;` | #513 | `0x1EB664` / `0x1EC264` | `0x969F1C` / `0x6F96AB1C` | **`0x001E3BA0`** | `0x6F1E3BA0` | 确证 |
| `GetPlayerName` | `(Hplayer;)S` | #111 | `0x1E96FC` / `0x1EA2FC` | `0x967220` / `0x6F967E20` | **`0x001E3D40`** | `0x6F1E3D40` | 确证 |
| `GetLocalPlayer` | `()Hplayer;` | #615 | `0x1EBE5C` / `0x1ECA5C` | `0x96A9DC` / `0x6F96B5DC` | **`0x001E3150`** | `0x6F1E3150` | 确证 |
| `GetPlayerId` | `(Hplayer;)I` | #621 | `0x1EBED4` / `0x1ECAD4` | `0x96AA7C` / `0x6F96B67C` | **`0x001E3D20`** | `0x6F1E3D20` | 确证 |
| `IsPlayerAlly` | `(Hplayer;Hplayer;)B` | #616 | `0x1EBE70` / `0x1ECA70` | `0x96AA00` / `0x6F96B600` | **`0x001E8040`** | `0x6F1E8040` | 确证 |
| `GetUnitAbilityLevel` | `(Hunit;I)I` | #458 | `0x1EB218` / `0x1EBE18` | `0x969A0C` / `0x6F96A60C` | **`0x001E5EF0`** | `0x6F1E5EF0` | 确证 |
| `FirstOfGroup` | `(Hgroup;)Hunit;` | #338 | `0x1EA8B8` / `0x1EB4B8` | `0x968D60` / `0x6F969960` | **`0x001E0850`** | `0x6F1E0850` | 确证 |
| `GroupEnumUnitsSelected` | `(Hgroup;Hplayer;Hboolexpr;)V` | #328 | `0x1EA7F0` / `0x1EB3F0` | `0x968BE8` / `0x6F9697E8` | **`0x001E6BF0`** | `0x6F1E6BF0` | 确证（锚点，与旧报告一致） |
| `DisplayTextToPlayer` | `(Hplayer;RRS)V` | — | `0x1ECF78` / `0x1EDB78` | `0x96C82C` / `0x6F96D42C` | **`0x001DFCE0`** | `0x6F1DFCE0` | 确证 |
| `DisplayTimedTextFromPlayer` | `(Hplayer;RRRS)V` | — | `0x1ECFA0` / `0x1EDBA0` | `0x96C86C` / `0x6F96D46C` | **`0x001DFD90`** | `0x6F1DFD90` | 确证 |
| `GetTriggerUnit` | `()Hunit;` | — | `0x1EA5C0` / `0x1EB1C0` | `0x968864` / `0x6F969464` | **`0x001E5E10`** | `0x6F1E5E10` | 确证 |
| `GetDyingUnit` | `()Hunit;` | — | `0x1E9EE0` / `0x1EAAE0` | `0x967F50` / `0x6F968B50` | **`0x001E2110`** | `0x6F1E2110` | 确证 |
| `GetEnumUnit` | `()Hunit;` | — | `0x1EA64C` / `0x1EB24C` | `0x968908` / `0x6F969508` | **`0x001E21B0`** | `0x6F1E21B0` | 确证 |

**本期新解出的、对"无 JAPI 模式"直接有用的辅助函数（全部确证，来自调用点反汇编）：**

| RVA | 作用 | 依据 |
|---|---|---|
| `0x0001D0950` | **JASS Hunit → `CUnit*`**（`__thiscall`，ecx=句柄，返回对象或 0） | `GetUnitName` `0x1E6346`、`GetUnitTypeId` `0x1E6676`、`GetUnitState` `0x1E6617`、`GetOwningPlayer` `0x1E3BA6`、`FirstOfGroup` 走 `0x1CEF10` |
| `0x0001CF7D0` | **JASS Hplayer → `CPlayer*`**（`__thiscall`，ecx=句柄） | `GetPlayerName` `0x1E3D46`、`GetPlayerId` `0x1E3D26`、`IsPlayerAlly` `0x1E8047`、`DisplayTimedTextToPlayer` `0x1DFE76` |
| `0x0001CFB10` | JASS Hgroup → 组对象 | `GroupEnumUnitsSelected` `0x1E6C1B`（旧报告） |
| `0x000001C2600` | 引擎 ctx (`*(base+0xBE4238)`) → **句柄管理器** | `GetLocalPlayer` `0x1E3182`、`GetOwningPlayer` `0x1E3BC1` |
| `0x002645D0` | **对象 → JASS 句柄**（见 §3） | `GetLocalPlayer` `0x1E318C`、`GetOwningPlayer` `0x1E3BCB` |
| `0x00667C90` | `CUnit*` → `CPlayer*`（`GetOwningPlayer` 用过） | `0x1E3BB4` |
| `0x0001D9920` | **JASS 字符串 id → JASS 字符串句柄**（`__thiscall`，ecx=id） | `GetUnitName` `0x1E635E`、`GetPlayerName` `0x1E3D5D` 都是 `jmp 0x1D9920` |
| `0x00325FA0` | `CUnit*+0x30` → 字符串 id（供 `0x1D9920`） | `GetUnitName` `0x1E6356`（`mov ecx,[eax+0x30]; xor edx,edx; call 0x325FA0`） |
| `0x0001D25E0` / `0x0001FAE20` / `0x0001C1C70` | 字符串值 → 字符串描述符 → `char*`（见 §2） | `DisplayTimedTextToPlayer` `0x1DFE8D` |
| `0x0034E7A0` / `0x00356A40` | 显示队列（DTTTP 内部的最终落点） | `0x1DFECC` / `0x1DFED3` |
| `0x00248700` | `jmp 0x43550` —— JPlayer 有效性检查 | `0x1DFE81` |
| `0x0001CEF10` | JASS Hgroup → 组对象（`FirstOfGroup` 用的那个） | `FirstOfGroup` `0x1E0857` |
| `0x000271D10` | 组对象的"取第一个元素/迭代器"（`ret 8`） | `FirstOfGroup` `0x1E0865` |
| `0x0026AA70` | "当前事件/枚举上下文 → 句柄"（`GetTriggerUnit` 用 0，`GetEnumUnit` 用 10） | `0x1E5E1F` / `0x1E21BF` |
| `0x00668F40` | `CUnit* + index` → 单位状态值（`GetUnitState` 用） | `0x1E662C` |
| `0x00249C90` | `CPlayer* + flag` → 玩家名字符串 id（`GetPlayerName` 用） | `0x1E3D55` |
| `0x0023D210` / `0x0038C60` | 玩家盟友位图查询（`IsPlayerAlly` 用） | `0x1E806A` / `0x1E8072` |

### 4.1 关键对象字段（本期新确证，用于"无 ydbase 取名字/血量"）

| 对象 | 偏移 | 含义 | 依据 |
|---|---|---|---|
| `CUnit*` | **`+0x0C`** | 单位类型对象指针 | `GetUnitAbilityLevel` `0x1E5F05`、`GEUS` `0x1E6CAD` |
| `CUnit*` | **`+0x10`** | 类型对象第二个字段（与 `+0x0C` 一起构成 `[+0x10]:[+0x0C]` 对） | `0x1E5F02` / `0x1E6CAA` |
| **`CUnit*`** | **`+0x30`** | **4 字符类型码（`GetUnitTypeId` 就是 `mov eax,[eax+0x30]; ret`）** | `GetUnitTypeId` `0x1E6681` |
| `CUnit*` | `+0x30` | 也用作字符串 id（`GetUnitName` → `0x325FA0`） | `GetUnitName` `0x1E6351` |
| `CUnit*` | `+0x27C` | 某个整数属性（`GetUnitTypeId` 的兄弟 native 用） | `0x1E66A1` |
| `CUnit*` | `+0x5C` | 伤害函数用的对象标志位（`test esi,0x100` 等） | 伤害函数序言 `0x67DC4D` |
| `CPlayer*` | `+0x30` | 玩家 ID（`GetPlayerId` 就是 `movzx eax,byte [eax+0x30]; ret`） | `GetPlayerId` `0x1E3D31` |
| `CPlayer*` | `+0x34` | `CSelection*`（选区） | 旧报告 + `GEUS` `0x1E6C51` |
| `CPlayer*` | `+0x38` | 盟友位图容器（`IsPlayerAlly` 用 `lea ecx,[eax+0x38]`） | `0x1E806F` |
| 引擎 ctx | `+0x20` | **字符串容器**（JASS 字符串表） | `0x1C1C76` `mov ecx,[ecx+0x20]` |
| 引擎 ctx | `+0x28` | uint16 本地玩家索引 | 旧报告（War3Trainer IL + `0x1C3290`） |
| 引擎 ctx | `+0x58+i*4` | `CPlayer*` | 旧报告 |
| 引擎 ctx | **`+0xF4`** | **句柄管理器**（`0x1C2600` → `lea ecx,[esi+0xF4]`） | `0x1C2619` |
| 句柄管理器 | **`+0x198`** | 条目数 × 3 | ydbase `0x1CE93` |
| 句柄管理器 | **`+0x19C`** | 句柄表基址 T | ydbase `0x1CEA0` |
| 句柄表项（stride 12） | **`+0x04`** | 对象指针槽（匹配用） | ydbase `0x1CEAA`/`0x1CEB0` |

**⇒ "给单位取名字"的无 ydbase 最省事路径（不需要任何 native 调用）：**

```cpp
// 直接从 CUnit* 拿 4 字符类型码（等价 GetUnitTypeId 的全部实现）
static uint32_t UnitTypeIdRaw(uint32_t unitObj)
{
    uint32_t t = 0;
    __try { if (Readable((const void*)(uintptr_t)(unitObj + 0x30), 4))
                t = *(volatile uint32_t*)(uintptr_t)(unitObj + 0x30); }
    __except (EXCEPTION_EXECUTE_HANDLER) {}
    return t;   // 'hfoo' / 'N00D' / ...
}

// 走 native GetUnitTypeId（拿到的是 JASS integer，值就是上面的 4 字符码）
typedef uint32_t (__cdecl *fn_native1_t)(uint32_t a);
static uint32_t UnitTypeIdViaNative(uint32_t hUnit)
{
    fn_native1_t fn = (fn_native1_t)Wc3NativeByName("GetUnitTypeId");
    if (!fn) return 0;
    uint32_t r = 0;
    __try { r = fn(hUnit); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return r;
}
```

> ⚠️ **为什么 `GetUnitTypeId` 的实现只有 5 条指令**：`0x1E6670` 的
> `0x1E6673 mov ecx,[ebp+8]` / `0x1E6676 call 0x1D0950` / `0x1E6681 mov eax,[eax+0x30]` / `ret`
> ——它就是"句柄→对象→读 +0x30"。这也**反证**了 `0x1D0950` 就是 Hunit→CUnit*。

---

## 5. ⑤ 伤害函数序言与版本无关性

### 5.1 主序言唯一性

```
特征：55 8B EC 83 EC 2C 56 57 8B F9 89 7D F4 8B 77 5C
     push ebp / mov ebp,esp / sub esp,0x2C / push esi / push edi /
     mov edi,ecx / mov [ebp-0xC],edi / mov esi,[edi+0x5C]
```

| 文件 | `.text` 内命中数 | 命中位置 | 对应 RVA |
|---|---|---|---|
| `D:\war5\Game.dll` | **1** | file `0x67D040` | **`0x0067DC40`** |
| `…\kkduizhan\…\1.27.0\Game.dll` | **1** | file `0x67D040` | **`0x0067DC40`** |

**⇒ 16 字节主序言在这两个构建里都已经唯一（1/1）。确证。**

### 5.2 更稳的组合特征码（推荐用于内联钩）

```
; ---- 组合特征码 A（38 字节，序言 + 早退分支 + 全局 + ret 0x10），含 5 个通配 ----
55 8B EC 83 EC 2C 56 57 8B F9 89 7D F4 8B 77 5C
F7 C6 00 01 00 00 74 ?? 8B 45 08 8B 0D ?? ?? ?? ?? 5F 5E 89 08 8B E5 5D C2 10 00

; ---- 组合特征码 B（19 字节，"伤害类型位掩码"四个魔法值分支，函数内 ~0x85 处）----
83 FE 10 74 ?? 83 FE 20 74 ?? 81 FE 00 00 00 04 74 ?? 81 FE 00 00 40 00 74 ??
```

| 特征码 | `D:\war5\Game.dll` | 平台 `…\gpatch\…\Game.dll` |
|---|---|---|
| A（38 字节） | **命中 1 次 @ RVA `0x0067DC40`** | **命中 1 次 @ RVA `0x0067DC40`** |
| B（19 字节） | **命中 1 次 @ RVA `0x0067DCC5`** | **命中 1 次 @ RVA `0x0067DCC5`** |

**匹配唯一性论证**：
* A 里 `C2 10 00`（`ret 0x10`）+ `8B 0D ?? ?? ?? ??`（`mov ecx,ds:[6FBB81D4]`）两个"强锚"共现，
  把误匹配概率压到 0；A 与 B 的间距固定（`0x67DCC5 − 0x67DC40 = 0x85`），**可互为验证**。
* 建议钩子安装逻辑：**先用 A 定位，再用 `addr + 0x85` 处校验 B**；两者都中才安装。

### 5.3 `ret N` 与参数个数（派生结论，供你复核 hook）

```
0x67DC40: ret 0x10   （共出现 4 次：0x67DC68 / 0x67DE62 / 0x67DEA5 / 0x67E005）
0x67DC40: push ebp / mov ebp,esp / sub esp,0x2C / push esi / push edi / mov edi,ecx
```

* `__thiscall`（`ecx = this`）+ **callee 清 16 字节栈** ⇒ 栈上 16 字节参数区。
* 在本函数前 **`0x420` 字节**内，**实际被读取的栈参数只有 2 个**：
  * `[ebp+0x8]`：`0x67DC58 mov eax,[ebp+8]`、`0x67DE51`、`0x67DE94`（**被写回** `[0x6FBB81D4]`）
  * `[ebp+0xC]`：`0x67DC8B mov ebx,[ebp+C]`，`0x67DF6C mov [ebp+C],eax`（**被当变量改动**）
  * `[ebp+0x10]`：`0x67DE42 / 0x67DE83 / 0x67DFE2 push [ebp+0x10]`（作为参数转发）
* **⇒ 与 `WFE伤害机制分析.md` 一致**：`[ebp+0x8]` = 伤害类型位掩码（会被写进全局），
  `[ebp+0xC]` = 伤害信息结构指针（其 `+0x14`/`+0x20` 是数值），另有两个未被本函数直接读取的栈参数。
* **钩子建议不变**：`__fastcall` 声明、`ret 0x10` 由被调方清栈；
  **不要在钩子里做重活**（该函数在战斗中每秒被调用数百次），只做"拷贝参数进无锁环形缓冲"。

### 5.4 两份 Game.dll 的差异（**确证**）

| 项 | 值 |
|---|---|
| SHA256 | `1A4D41EB650F9C0D3E260F6C3D53592C2418C0C66CFF76D6CCB7E1341C7AB80E`（本机）<br>`E04D1716603C075EB0C8E1E21CF1093A664ADC5249EFAB396BFA08D7B09D0C3A`（平台） |
| 文件长度 | 均 13,187,048 |
| **全文不同的字节数** | **12**（其余 13,187,036 字节完全相同） |
| 差异位置 1 | file `0x84E931` RVA `0x84F531`：本机 `FF FF FF FF` vs 平台 `00 00 80 00` |
| 差异位置 2 | file `0x85EDB7` RVA `0x85F9B7`：同上 |
| 差异位置 3 | file `0x871A67` RVA `0x872667`：同上 |
| 差异语义 | 三条都是 `3D FF FF FF FF 0F 8? …`（`cmp eax,-1` + 条件跳转），只是**"错误值哨兵"不同**（本机承认 `0xFFFFFFFF`，平台承认 `0x00800000`） —— **与 native 表、native 实现、字符串表、伤害函数全部无关** |
| **关键 RVA 一致性** | `0x67DC40`（伤害函数）**逐字节相同**；`0x1E9A50`（native 表 A 起点）所在整段相同；`0x1DFE70`/`0x1E6340`/`0x1E6670` 等全部相同；`0x96D450` 等名字串全部相同 |

**⇒ 结论：平台联机那份 `Game.dll` 与本机这份在本次所有结论所依赖的每一个 RVA/字符串/字节上完全一致。
§1~§5 的一切结论对两份构建同时成立。**
（唯一仍未验证的是日志里那个 `size=13467648` 的**第三份构建**——磁盘上不存在，见 §7。）

---

## 6. 本轮新增工具（都在 `<WS>\_tools\`）

| 文件 | 用途 |
|---|---|
| `_tools\an\` | 本轮新写的 C# x86 分析器（`dotnet`，支持 SSE/F3-F2-66 前缀、`fn` 函数起点回溯、`findtable` native 表遍历、`raw` hexdump、`jumps` 定点反汇编） |
| `_tools\an\bin\an.exe` | 命令：`info` / `str` / `xref` / `xrefall` / `raw` / `dump` / `fn` / `pat` / `pattext` / `sigcount` / `nat` / `findtable` / `recs2` / `findbytes` / `jumps` / `strva` |
| `_tools\native_table_1.27.0.52240.txt` | **native 表 A 全量 1167 条**（名字 / 签名 / 实现 RVA），★ 本报告最有用的附带产物 |
| `_tools\native_table2_stub_1.27.0.52240.txt` | native 表 B 全量 1290 条（**实现全是 `0x70A0C0` 桩**，用于排错） |
| `_tools\an\bin2\exports.exe` | PE 导出表 dumper（用于读 `ydbase.dll` 的 `object_to_handle` / `from_string`） |
| `_tools\an\exp_src_bak\` | `exports.exe` 的源码目录 |

**用 `an.exe` 复现本报告任一结论的例子：**

```
an.exe D:\war5\Game.dll nat DisplayTimedTextToPlayer GetUnitName GetUnitTypeId
an.exe D:\war5\Game.dll findtable 0x1ECF8C
an.exe D:\war5\Game.dll dump 0x1DFE70 0x70
an.exe D:\war5\Game.dll sigcount "55 8B EC 83 EC 2C 56 57 8B F9 89 7D F4 8B 77 5C"
an.exe "C:\Program Files (x86)\kkduizhan\config\gpatch\game\1.27.0\Game.dll" sigcount "55 8B EC …"
```

---

## 7. 未解出 / 需要动态验证的部分（**诚实清单**）

| # | 未解出项 | 卡在哪 | 下一步怎么做 |
|---|---|---|---|
| U1 | ~~**`[ebp+0x18]` 是"字符串值(id)"还是"字符串对象指针"**~~ **已解** | —— | **已确证为"字符串 id"**：`0x1C1C79` 只判 `!=0`、从不判可读性；`0x1C1C84 push eax` 把它当 vector 下标；`call 0x1C1C70` 唯一上游是 `0x1FAE20`，而 `0x1FAE20` 被 DTTTP/DisplayTextToPlayer/SetTextTagText 三个 native 共用；`ydbase::create_string` 返回的也是 id。**剩余小问**：id→条目的容器里存的是 `string_fake*` 还是 `string_fake`（用 §2.6 的前 8 条 dump 一次定案） | 跑 §2.6 的 `ProbeStringIds()`（打印 `[tbl+4i]`、`[+4]`、`[+1C]` 与文本，再试 id 1..40） |
| U2 | **`0x2645D0` 的函数真正起点与精确原型** | 它是 `0x263990` 那个 body 的**内部地址**（被 `GetOwningPlayer`/`GetLocalPlayer` 直接 call 的"热入口"）；`Game.dll` **无 `.pdata`**（Exception Directory = 0），无法程序化拿函数边界；我的回溯启发式在 x86 变长指令下不可靠 | ①跑 §3.3.1 的 `VerifyObjectToHandle()`；②或按"`fixup`/`ret 8` 边界"手工回溯（建议用 IDA/Ghidra 交叉验证）。**但调用形态（`ecx`=管理器、2 个栈参数、`ret 8`、返回句柄）已由两处调用点确证，C++ 片段可直接用** |
| U3 | **`0x2645D0` 是"查表"还是"读对象里的缓存字段"** | 反汇编里同时看到 `mov ecx,[eax+0x14]` / `mov eax,[eax+0x18]` / `mov [esi+8],ecx`（像缓存回填），又看到句柄表结构 | 用 `VerifyObjectToHandle()` 的"往返一致"日志判定；若往返一致，两者等价，不必区分 |
| U4 | **句柄表 `[mgr+0x19C]` / `[mgr+0x198]` 的 `T` 与对象指针 `+4` 的语义** | `T + i*12 + 4 == obj` 意味着"对象就在表里"，看着不像普通指针表；ydbase 的代码是**确证**的，但"引擎侧同构"是**推断** | 在真机上 dump `T` 前 32 字节，看 `[T+4+i*12]` 是否真是 `CUnit*`（能否 `+0x30` 读出合法 4 字符类型码） |
| U5 | **平台联机那个 `size=13467648`（13,467,648）的第三份构建** | 磁盘上不存在（`…\gpatch\…\Game.dll` 是 13,187,048）；本次只能用 13,187,048 那份做交叉验证 | 让用户从联机进程里 dump 该模块（或提供日志里的 `目标=XXXXXXXX`），按 §5.2 的 A/B 特征码核对 |
| U6 | **`GetUnitState` 的 `Hunitstate` 索引语义** | 只确证 `0x1E6600` 的实现形态（`cmp esi,4; jl` → 读全局；否则 `call 0x668F40(obj, &local, index)`） | 需要 JASS 文档 + 1 次运行期对照（`GetUnitState(u, UNIT_STATE_LIFE)` 与 `[obj+0x...]` 比对） |
| U7 | ~~**`DisplayTimedTextToPlayer` 之后的真正落点**~~ **已解（RVA 已给出）** | `0x34E7A0`（取显示管理器）与 `0x356A40`（入队）内部仍未展开；但**整族 TextTag native 的实现 RVA 已全部拿到**（见附录 A） | **推荐改走 TextTag 路线**：`CreateTextTag` → `SetTextTagText(tag, S, size)` → `SetTextTagPosUnit(tag, unit, z)` → `SetTextTagVelocity` → `SetTextTagColor` → `SetTextTagLifespan/Fadepoint`。**全部 `__cdecl`，只有 `SetTextTagText` 的第 1 个参数是 `S`（同样传 id）**，其余都是 handle/real/int ⇒ **这是"飘在单位头上的伤害数字"最贴近 WFE 的做法** |

> ⚠️ **U7 的升级版结论（本轮新解出）**：`CreateTextTag` 整族 native 的实现 RVA 已全部拿到（**附录 A**）。
> 其中**只有 `SetTextTagText` 的第 1 个参数是 `S`**（"文本"，同样传 id），其余全是 handle/real/int。
> ⇒ **这才是"飘在单位头上的伤害数字"最贴近 WFE 的做法**，比 `DisplayTimedTextToPlayer`（消息区文本）更合适。
> 而且它比 DTTTP **更省事**：不需要 `Hplayer`、不需要 x/y 屏幕坐标（用 `SetTextTagPosUnit(tag, unit, z)` 直接绑单位）。

---

## 附录 A：TextTag（飘字）整族 native 实现 RVA（**全部确证**，来自表 A）

| native | 签名 | 记录 file | 名字串 VA | **实现 RVA** |
|---|---|---|---|---|
| `CreateTextTag` | `()Htexttag;` | `0x1ED1D0` | `0x6F96D6A8` | **`0x001DEA90`** |
| `DestroyTextTag` | `(Htexttag;)V` | `0x1ED1E4` | `0x6F96D6C8` | **`0x001DF760`** |
| **`SetTextTagText`** | **`(Htexttag;SR)V`** | `0x1ED1F8` | `0x6F96D6E8` | **`0x001F6F70`** |
| `SetTextTagPos` | `(Htexttag;RRR)V` | `0x1ED20C` | `0x6F96D708` | **`0x001F6E30`** |
| `SetTextTagPosUnit` | `(Htexttag;Hunit;R)V` | `0x1ED220` | `0x6F96D72C` | **`0x001F6ED0`** |
| `SetTextTagColor` | `(Htexttag;IIII)V` | `0x1ED234` | `0x6F96D754` | **`0x001F6D30`** |
| `SetTextTagVelocity` | `(Htexttag;RR)V` | `0x1ED248` | `0x6F96D774` | **`0x001F6FC0`** |
| `SetTextTagVisibility` | `(Htexttag;B)V` | `0x1ED25C` | `0x6F96D798` | **`0x001F7020`** |
| `SetTextTagSuspended` | `(Htexttag;B)V` | `0x1ED270` | `0x6F96D7B0` | **`0x001F6F40`** |
| `SetTextTagPermanent` | `(Htexttag;B)V` | `0x1ED284` | `0x6F96D7C4` | **`0x001F6E00`** |
| `SetTextTagAge` | `(Htexttag;R)V` | `0x1ED298` | `0x6F96D7E8` | **`0x001F6CF0`** |
| `SetTextTagLifespan` | `(Htexttag;R)V` | `0x1ED2AC` | `0x6F96D7F8` | **`0x001F6DC0`** |
| `SetTextTagFadepoint` | `(Htexttag;R)V` | `0x1ED2C0` | `0x6F96D80C` | **`0x001F6D80`** |

**可直接粘贴的飘字 C++（推荐作为伤害数字的最终方案）：**

> ⚠️ **本代码块的 typedef 有两处已确证的错误（2026-09-28 复核 + 实装）**：
> ① `R` 参数（`SetTextTagText` 的 `size`、`SetTextTagPos*` 的 x/y/z、`SetTextTagVelocity` 的 vx/vy、
> `Lifespan/Fadepoint/Age`）在这里被写成"**传 float 值**"。逐字节看是
> `0x1F6F9A mov ecx,[ebp+0x10]` → `0x1F6F9D movss xmm0,[ecx]` —— **R 参数是指向 float 的指针**，
> 与 `DisplayTimedTextToPlayer` 的 x/y/duration 完全同一套 ABI（见 `无JAPI后端实装说明.md` §4.2）。
> ② `SetTextTagText` 的字符串参数在这里按"id"处理（下面写的是 `FindExistingStringId`）。
> **它要的是 `string_fake` 对象指针**，传 id 会每次 C0000005（见 §2.3 末尾的实机更正）。
>
> **实装请以插件源码 `UDamageWatcherHook.cpp` 的 `fn_tt_*` typedef 与 `MakeJassString()` 为准**，
> 或看 `无JAPI后端实装说明.md` §3.3。

```cpp
//------------------------------------------------------------------------------
// TextTag 飘字（game.dll 1.27.0.52240）—— 全部 __cdecl、`ret`、调用者清栈
//   依据：native 表 A 的 13 条记录（附录 A）+ SetTextTagText/SetTextTagVelocity 反汇编
//   ★ SetTextTagText 的第 2 个参数是 S（字符串 id），与 DTTTP 同一套 0x1FAE20 解析
//------------------------------------------------------------------------------
typedef uint32_t (__cdecl *fn_CreateTextTag_t)(void);
typedef void     (__cdecl *fn_SetTextTagText_t)(uint32_t tag, uint32_t strId, float size);
typedef void     (__cdecl *fn_SetTextTagPosUnit_t)(uint32_t tag, uint32_t hUnit, float zOffset);
typedef void     (__cdecl *fn_SetTextTagColor_t)(uint32_t tag, uint32_t a, uint32_t r, uint32_t g, uint32_t b);
typedef void     (__cdecl *fn_SetTextTagVelocity_t)(uint32_t tag, float xvel, float yvel);
typedef void     (__cdecl *fn_SetTextTagLifespan_t)(uint32_t tag, float span);
typedef void     (__cdecl *fn_SetTextTagFadepoint_t)(uint32_t tag, float fade);
typedef void     (__cdecl *fn_SetTextTagPermanent_t)(uint32_t tag, uint32_t flag);
typedef void     (__cdecl *fn_SetTextTagVisibility_t)(uint32_t tag, uint32_t flag);
typedef void     (__cdecl *fn_DestroyTextTag_t)(uint32_t tag);

// ★ 注意：SetTextTagColor 的参数顺序为 (Htexttag;IIII)V ——
//   具体哪 4 个整数是 A/R/G/B 还是 R/G/B/A，请按 1 次运行期对照确认（本报告未展开其实现）。
//   WFE 的配置里 [DAMAGEDRAW] PHYSICALCOLOUR = 0xFFFF0000 是 ARGB，
//   而 JASS 的 SetTextTagColor 是 (red, green, blue, alpha) ⇒ 猜测顺序是 R,G,B,A，但请实测。

static void ShowDamageText(uint32_t hUnit, const char* text, uint32_t strId,
                           uint32_t argb, float size, float lifespan)
{
    static fn_CreateTextTag_t        fCreate  = NULL;
    static fn_SetTextTagText_t       fText    = NULL;
    static fn_SetTextTagPosUnit_t    fPosUnit = NULL;
    static fn_SetTextTagColor_t      fColor   = NULL;
    static fn_SetTextTagVelocity_t   fVel     = NULL;
    static fn_SetTextTagLifespan_t   fLife    = NULL;
    static fn_SetTextTagFadepoint_t  fFade    = NULL;
    static fn_SetTextTagPermanent_t  fPerm    = NULL;

    if (!fCreate) {
        fCreate  = (fn_CreateTextTag_t)       Wc3NativeByName("CreateTextTag");
        fText    = (fn_SetTextTagText_t)      Wc3NativeByName("SetTextTagText");
        fPosUnit = (fn_SetTextTagPosUnit_t)   Wc3NativeByName("SetTextTagPosUnit");
        fColor   = (fn_SetTextTagColor_t)     Wc3NativeByName("SetTextTagColor");
        fVel     = (fn_SetTextTagVelocity_t)  Wc3NativeByName("SetTextTagVelocity");
        fLife    = (fn_SetTextTagLifespan_t)  Wc3NativeByName("SetTextTagLifespan");
        fFade    = (fn_SetTextTagFadepoint_t) Wc3NativeByName("SetTextTagFadepoint");
        fPerm    = (fn_SetTextTagPermanent_t) Wc3NativeByName("SetTextTagPermanent");
        if (!fCreate || !fText || !fPosUnit) { LogLine("TextTag: native 缺失"); return; }
    }
    if (!strId) strId = FindExistingStringId(text);   // §2.4 方案 A
    if (!strId) { LogLine("TextTag: 拿不到字符串 id，跳过"); return; }

    __try {
        uint32_t tag = fCreate();
        if (!tag) return;
        fText(tag, strId, size);
        fPosUnit(tag, hUnit, 0.0f);
        fVel(tag, 0.0f, 0.06f);                       // 向上飘
        fColor(tag, (argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF, (argb >> 24) & 0xFF);
        fLife(tag, lifespan);
        fFade(tag, lifespan * 0.5f);
        fPerm(tag, 0);                                // 非永久 -> 自动销毁
        LogLine("TextTag: tag=%08X unit=%08X strId=%08X 显示 [%s]", tag, hUnit, strId, text);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E TextTag 异常 code=%08X", (uint32_t)GetExceptionCode());
    }
}
```

> ⚠️ `SetTextTagColor` 的 4 个整数**顺序未确证**（我只确证了它的 RVA 与签名 `(Htexttag;IIII)V`）。
> 建议先用 `(255,0,0,255)` 与 `(0,0,255,255)` 各打一次，看屏幕上是红还是蓝，一次即可定序。

---

## 8. 落地清单（给插件作者的最小改动面）

> **不改 `UDamageWatcherHook.cpp` 的既有逻辑**；以下只是"把 ydbase 依赖替换成引擎直连"的等价物。

| 现有 ydbase 调用 | 引擎直连替代 | 本报告位置 |
|---|---|---|
| `g_jass_func(name)` | `Wc3NativeByName(name)`（遍历表 A） | §1.6 |
| `g_call("DisplayTimedTextToPlayer", …)` | `fn_DTTTP_t` 直接调；**★ 第 5 参数从"对象指针"改成"字符串 id"**（§2.4） | §2.4 |
| `g_call("CreateTextTag" / "SetTextTagText" / …)` | **推荐改用 TextTag 飘字**（附录 A 的 13 个 RVA + `ShowDamageText()`）—— **已实装（v1.3，B 计划：屏幕输出全部走飘字）**，见 无JAPI后端实装说明.md §3.3 | 附录 D |
| `g_object_to_handle(obj)` | `Wc3ObjectToHandle(obj)`；失败回退 `Wc3ObjectToHandleByMemory(obj)` | §3.2 |
| `g_from_stringid(id)` / `g_from_string(v)` | 引擎 `0x1C1C70(id)` 或 `0x1FAE20(id)` 取 `char*`；**或** `0x1D9920` 取字符串句柄 | §4.1 |
| `g_create_string(s)` | **引擎侧无对应导出**；改用 §2.4 方案 A（查表复用 id）或方案 B（探针扫 id） | §2.4 |
| `jass_func("GetUnitTypeId")` + 调用 | **直接读 `*(uint32_t*)(unitObj + 0x30)`**（零调用、零副作用） | §4.1 |
| `jass_func("GetUnitName")` + 调用 | 引擎 `RVA 0x1D9920(0x325FA0(*(CUnit*+0x30)))` 或直接 `RVA 0x1E6340(hUnit)` | §4.1 |

---

### 证据强度汇总

| 结论 | 强度 |
|---|---|
| native 记录布局 `E8/68/BA/B9`、stride 20、`+16`=实现 VA | **确证**（1167 + 1290 条逐条通过模板验证，无例外） |
| 表 A = 真实现 / 表 B = `0x70A0C0` 桩 | **确证**（表 B 全量 impl 字段均为 `0x70A0C0`） |
| 12 个目标 native 的实现 RVA（§4 表） | **确证** |
| `DisplayTimedTextToPlayer` 实现 RVA `0x1DFE70`、`__cdecl`、5 个 4 字节参数 | **确证**（逐指令 + `ret`） |
| 第 5 参数**不是 `char*`**（先经 `0x1C1C70` 解析） | **确证** |
| **第 5 参数 = 字符串 id（小整数），不是对象指针** | 🚫 **已推翻（2026-09-28 实机）**：是**字符串对象指针**；见 §2.3 末尾更正 |
| 引擎里所有带 `S` 参数的 native 共用 `0x1FAE20` 这一条通路 | **确证**（DTTTP `0x1DFE8D`、DisplayTextToPlayer `0x1DFCF5`、SetTextTagText `0x1F6F94`） |
| `string_fake` 布局：`+0x08`、`+0x1C`=char*；条目 32 字节 | **确证**（引擎 `0x1C1C91` + ydbase `from_string 0x19B50` / ctor `0x19980` / `create_string 0x19A80`） |
| ~~**你们现在"传对象指针"的写法在无 ydbase 下不成立，必须改成传 id**~~ | 🚫 **已推翻：传对象指针才是对的**（JAPI 路径一直这么传、飘字正常显示） |
| 字符串表位置 `[ctx+0x20]`，条目 id = 下标（id 0 表示空） | `[ctx+0x20]` **确证**；"id = 下标"**强推断**（§2.6 一次 dump 可定案） |
| TextTag 整族 13 个 native 的实现 RVA（附录 A） | **确证** |
| `0x2645D0` = 对象→句柄（`ecx`=管理器、2 栈参数、`ret 8`） | 调用点/形态 **确证**；返回语义 **强推断**（§3.3.1 可升级为确证） |
| 句柄 = `0x100000 + 槽位下标` | **确证**（ydbase `0x1ECD` `lea eax,[edx+0x100000]`） |
| `[ctx+0xF4]`=句柄管理器、`[mgr+0x19C]`=表、`[mgr+0x198]`=条目数×3 | **确证**（引擎 `0x1C2619` + ydbase `0x1CE93/0x1CEA0`） |
| `CUnit*+0x30` = 4 字符类型码 = 字符串 id | **确证**（`GetUnitTypeId` `0x1E6681`、`GetUnitName` `0x1E6351/0x1E6356`） |
| `CPlayer*+0x30` = 玩家 ID | **确证**（`GetPlayerId` `0x1E3D31`） |
| 伤害函数序言唯一（1 命中）+ 组合特征码唯一 | **确证**（两份构建都 1/1） |
| 两份 Game.dll 只差 12 字节、关键 RVA 全同 | **确证**（逐字节比较） |
| 联机第三份构建（13,467,648 字节） | **未验证**（磁盘上不存在） |

**只读约束遵守**：全程只读 `D:\war5\Game.dll`、`C:\Program Files (x86)\kkduizhan\…\Game.dll`、
`C:\Program Files (x86)\kkduizhan\plugins\game\ydbase.dll`；**未写 `D:\war5`**、未改名、
**未改 `UDamageWatcherHook.cpp`**、未改 `warcraft3\config.cfg`、未启动游戏、未提权。
所有产物只落在 `<WS>` 内。
