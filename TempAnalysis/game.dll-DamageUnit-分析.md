# game.dll 内部伤害函数（0x6F67DC40）执行流程

> 目标：`C:\3rd\war5\game.dll`，War3 `1.27.0.52240`
> SHA-256：`1a4d41eb650f9c0d3e260f6c3d53592c2418c0c66cff76d6ccb7e1341c7ab80e`
> ImageBase `0x6F000000`，函数地址均为 VA。

> 方法说明：先用 REA 的 Ghidra 12.1.4 打开，13 MB 的 `game.dll` 默认全量分析在请求窗口内没有跑完（多次超时），
> 因此改用「PE 头解析 + Capstone 线性反汇编 + 直接调用/数据引用扫描」对同一份 artifact 做静态分析。
> 文中 `【观测】` 为指令级事实，`【推断】` 为语义判断，`【未知】` 为未解析部分。

---

## 0. 函数身份

`0x6F67DC40` 就是这张地图/YDWE 体系里 hook 的「伤害入口」（`game.dll+0x67DC40`）：

- `【观测】` 序言 `55 8B EC 83 EC 2C 56 57 8B F9`（`push ebp; mov ebp,esp; sub esp,0x2C; push esi; push edi; mov edi,ecx`）
- `【观测】` 结尾 `ret 0x10`：4 个栈参数；`ecx` = 受击单位（后文 `edi`）
- `【观测】` 栈参数：`[ebp+8]` = `out`（float*，最终伤害写回这里）、`[ebp+0xC]` = 伤害信息结构体 `info`、`[ebp+0x10]` / `[ebp+0x14]` = 另外两个标志/来源参数
- `【观测】` `info` 布局（与 ddh 的 `war3_event_damage_data` 一致）：`+0x00` 来源单位、`+0x04` 武器类型、`+0x0C` 标志（bit0 远程 / bit8 攻击）、`+0x10` 伤害值、`+0x14` 伤害类型掩码、`+0x20` 攻击类型
- `【观测】` 该地址在整个文件里只出现一次数据引用（`0x6FA4A824`，`.rdata` 的函数指针表），**没有 E8 直接调用** → 通过表/虚调用分发，所以找不到普通调用者

---

## 1. 入口早退（0x6F67DC40 – 0x6F67DD60）

```
esi = [unit+0x5C]
if (esi & 0x100) { *out = g_damage; return; }        // 无敌/不可选中类标志
call 0x6F66EA60(1)                                    // 单位状态查询
if (esi & 0x02000000) flag = 1 else flag = [unit+0xE4]
...
if (vtbl[+0x11C](unit) != 0) { *out = g_damage; return; }
if ([unit+0x15C] > 0 && flag) { *out = g_damage; return; }
if ([unit+0x158] > 0)         { *out = g_damage; return; }
```

`【推断】` `[unit+0x5C]&0x100` = 无敌/免疫位；`[unit+0x158]`、`[unit+0x15C]` 是两类免疫/吸收计数（与 ddh 文档里的"免疫字段"一致）。
早退分支不做任何计算，把全局暂存值 `0x6FBB81D4` 直接抄进 `*out`（这也是 ddh 说的"上一跳残值"）。

---

## 2. 收集伤害修正器（0x6F67DD77 – 0x6F67DF5E）

`【观测】` 遍历 `[unit+0x1DC]` 处的链表/哈希（与 0x6F64CC20 同一套结构）：

- 对每个节点调用 `vtbl[+0xF8]` 取"修正器类别"（0/1..9）
- 类别 1 → 立刻 `vtbl[+0xFC](info)` 应用
- 其他类别 → 在 9 位掩码里置位（`1 << class`），保存到 `[ebp-4]`

随后（0x6F67DEB4）按位 1..9 再遍历一遍链表，对命中的类别调用 `vtbl[+0xFC](info)`。
`【推断】` 这是"按类别分组的伤害修正"（例如抗性/减伤/易伤/护盾类行为），具体每个类别的语义取决于节点实现。

---

## 3. 数值计算（0x6F67DF61 – 0x6F67E126）

`【观测】` 以 `info+0x10` 为起点，逐级乘算，并通过 `0x6F6971C0` 写回 `info+0x10`（同时写 `info+0x18`）：

```asm
; 0x6F6971C0: 写回函数
call 0x6F0527E0
mov  [ebx+0x10], eax      ; info->amount = 结果
mov  [ebx+0x18], eax      ; info+0x18 = 同一值
```

1. **物理护甲**（仅当伤害类型掩码 == `0x10`）`【观测】`
   ```
   eax = [unit+0xE0]                 ; 护甲值
   call 0x6F64FBF0(&mult, &armor)    ; 护甲 → 伤害系数
   if (mult != 1.0) 0x6F0528B0(damage, mult) → 0x6F6971C0(info, &result)
   ```
   护甲函数两种分支：
   - 护甲 ≥ 0：`call 0x6F02A4B0(0x6F951B14, 0x6FA4AB40, 0)` 从 GameData 取系数，再 `0x6F0527E0 / 0x6F0529D0 / 0x6F052AF0` 做浮点运算
   - 护甲 < 0：`call 0x6F052F30` 取整、`cmovg 0x14`（封顶 20）、查表 `0x6FBEC2F8[armor]`
     `【推断】` 这张 21 项表就是负甲曲线 `2 - 0.94^(-armor)` 的预计算表

2. **攻击类型 × 护甲类型表** `【观测】`
   ```
   call 0x6F64D7F0(&mult, attackType, armorType)
   if (mult != 1.0) 0x6F6971C0(info, &mult)
   ```
   `0x6F64D7F0` 是**初始化 + 查表**函数：首次调用时用 `0x6F02A4B0` 从 GameData 读 7×8 个系数，写到 `0x6FBEC328` 起的一片 .data（`0x6FBEC34C` 是其中一项）。

3. **攻击类型附加系数** `【观测】`
   ```
   if ([unit+0x158] > 0) {
       mult = 0x6FBEC34C[attackType];       ; 同一张表的另一段
       if (mult != 1.0) 0x6F6971C0(info, &mult)
   }
   ```

4. **其它修正** `【观测】` 0x6F67E0C1 起：`call 0x6F04EFB0(0xD)`、检查 `[eax+0x10]` 标志位、比较来源 `[+0x268]`、可能再乘 `0x6FBB8248` 处的系数。
   `【推断】` 这一段是"伤害上限/百分比修正/特殊状态"一类，未逐一确认。

---

## 4. 事件 + 钳制（0x6F67F340）

`0x6F67F340` 被本函数调用两次（0x6F67DFEF、0x6F67E126），内部顺序：

```asm
push [edi]              ; info->source
push &g_damage          ; 待结算伤害
call 0x6F65E010         ; ① 触发事件
...
cmp  [ebp+0xC], 0 / cmp [edi], 0   ; 无来源/无标志 → 跳过
call vtbl[+0x12C]       ; ② 取当前生命（返回 float*）
comiss damage, life
; 取 min(damage, life) 存到 [ebp+0xC]
call 0x6F64CC20         ; ③ 通知来源单位的伤害行为
```

**① 事件 0x80234** `【观测】` `0x6F65E010` 构造事件对象并 `push 0x80234` → `0x6F0566D0`（事件表查找）→ `0x6F65D6E0(unit, 0x80234, evt)` 派发。
`【推断】` `0x80234` 就是脚本的 `EVENT_UNIT_DAMAGED`；`GetEventDamage` 读 `info+0x10`，`SetEventDamage` 改的就是这里传进去的待结算值。
**关键点：事件在 `min` 钳制之前触发**，所以地图能在事件里改数。

**② 溢出钳制** `【观测】` 用 `vtbl[+0x12C]`（取生命）与伤害比较，取较小值。
这就是"击杀溢出"的来源：`min(1250, 550) = 550`。

**③ 通知来源行为** `【观测】` `0x6F64CC20` 遍历 `[source+0x1DC]` 链表，对每个节点 `call vtbl[+0x170](victim, info, &min)`。
`【推断】` 这是"造成伤害后"的被动回调（吸血、荆棘、法球、伤害反馈一类）。

---

## 5. 落地（0x6F67E1A3 – 0x6F67E217）

```asm
mov eax,[ebp+0x14] ; ...
call 0x6F206680
mov eax,[ebp+0xC]          ; 伤害
xor eax,0x80000000         ; 取负（IEEE 符号位）
push &[ebp+0x14]
mov [ebp+0x14],eax
lea ecx,[ebp-0x28]
mov eax,[edi]
push ecx
mov ecx,edi
call vtbl[+0x128]          ; ← 改血接口（推测）
mov ecx,[eax]
xor ecx,0x80000000         ; 再取负回正
...
mov [out], ecx             ; 写回 *out
```

`【推断】` `vtbl[+0x128]` 接收 `-damage`，返回"实际生效的增量"（再取负回正），即 `actual = min(damage, life)` 的落地调用；具体实现取决于单位对象的 vtable，静态未解析。
`【观测】` 之后清理 `[unit+0x5C]` 的 `0x2000` 位、复位 `[unit+0x250]`/`[unit+0x254]`，最后 `*out = 最终伤害`。

---

## 6. 与你的工具列对应

| 你的列 | 对应位置 | 说明 |
|---|---|---|
| 原始伤害 | 入口 `info+0x10` | 护甲/类型计算前 |
| 引擎伤害 | 出口 `info+0x10` | 护甲、类型表、加成之后；`SetEventDamage` **不回写**它 |
| 地图伤害 | 出口 `*out` | 含 `SetEventDamage` 改写与 `min(伤害, 当前血)` 钳制 |
| 净掉血 | `hpAfter - hpBefore` | 真实扣血（也受 0 血下限钳制） |

事件 0x80234 在钳制前派发，所以"地图改伤害 → 钳制 → 落地"这个顺序成立。

---

## 7. 未决 / 限制

- `【未知】` Ghidra 全量分析超时，没有拿到反编译 C；以上为指令级阅读，函数边界靠 `ret`/`int3` 与调用图推断。
- `【未知】` `0x6FBB81D4`、`0x6FBB81D8`、`0x6FBEC328` 等都在 BSS，运行时由初始化代码填充，静态文件里为 0，因此常量语义（0.0 / 1.0 / 系数表）只能按用法推断。
- `【未知】` `vtbl[+0x128]`（改血）、`vtbl[+0x12C]`（取血）、`vtbl[+0x170]`（伤害回调）的具体实现依赖对象 vtable，未定位到 CUnit 的 vtable 基址。
- `【未知】` 0x6F67E0C1 那段"额外修正"的语义未确认。

## 8. 对上一问（550 vs 1250）的补充

按本流程：事件先触发 → 若地图把待结算值改成 0 → `min(0, 当前血)=0` → 落地 0，血量不应变化。
而截图里 `前血 550 → 后 0` 说明那一刀的血是引擎在函数内扣掉的（`min(1250, 550)=550`），
即**地图的 `EXSetEventDamage(0)` 没有作用到这次结算的待结算值**（或作用到了另一个字段）。
可用 `DDH_NATIVE_DAMAGE_HOOKS=1` 观察该次 `SetEventDamage` 的设值/次数来确认。

## 9. 能不能在钳制前读 `*out`

**不能。** `*out` 是输出参数，函数在出口才写它（`0x6F67F3A4` 之前的多个 `mov [eax], ecx`、`0x6F67E212` 的 `mov [eax], ecx`）。
钳制发生在 `0x6F67F340` 内部，那时 `*out` 里还是调用方传进来的旧值（多数情况是上一跳残留）。

**待结算伤害在别处**：`0x6F67F340` 的第一个栈参数 `[ebp+8]` 是一个 `float*`，指向本次待结算值；
主路径（`0x6F67DE47`、`0x6F67DFEA`）传的是全局 `0x6FBB81D4`（`g_damage`），
另一条路径（`0x6F67E123`）传的是外层函数的栈上局部。

`【观测】` 钳制是**非破坏性**的：`0x6F67F340` 只在 `0x6F67F38C`/`0x6F67F396` 把 `min` 结果写进自己的局部 `[ebp+0xC]`，
**没有回写** `[ebp+8]` 指向的那个 float。所以事件返回后，那个变量里仍是“地图改写后、未钳制”的值。

因此有三种取法：

| 方案 | 位置 | 说明 |
|---|---|---|
| A. 出口读 `g_damage` | 出口读 `*(float*)(base+0xBB81D4)`，与 `*out` 比较 | 最简单；若 `pre > final + 0.005` 即被钳制，`pre` 就是钳制前地图伤害 |
| B. 事件返回点探针 | hook `0x6F65E010` 出口，读它的 `arg2` 指向的 float | 最准（任何路径都覆盖），事件刚跑完、地图改写已生效、尚未钳制 |
| C. 恢复 native `SetEventDamage` hook | v19 那套 | 直接记录地图设的值，但拿不到“引擎值→地图值”的合成结果 |

注意：`g_damage` 是全局暂存，同帧多段伤害/嵌套时会被覆盖；A 方案要在出口立即读，不能跨事件缓存。

