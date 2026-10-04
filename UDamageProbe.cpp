//==============================================================================
// UDamageProbe.cpp —— 魔兽争霸 III 游戏端插件 DLL（探针版 / 只记录，不显示）
//==============================================================================
//
// 【本阶段目标】
//   以最小风险验证一件事：我们能不能挂到 JAPI 已有的"伤害虚表槽"上，
//   把每一次伤害事件的**原始数字**写进日志。本版本不做任何显示、不改伤害值、
//   不改游戏业务数据；唯一的内存写入是把两个函数指针替换掉
//   （JAPI 自己也是这么做的）。
//
// 【挂接链条】（全部由 dumpbin 复核，见同目录《探针说明.md》）
//   JAPI 初始化时执行：
//       replace_pointer( *(uint32_t*)(J+0x928D4), J+0x1F830 )
//   也就是把"对象 attach 函数"换成 JAPI 自己的 ObjectAttach。
//   以后游戏每次创建伤害对象都会调用它；JAPI 的 ObjectAttach 又把该对象
//   虚表槽 [vtbl+0x128] 换成 JAPI 的伤害中继 J+0x1F770，
//   并把原方法存进 J+0x928B8。
//
//   我们的做法：
//     1) 把 *(J+0x928D4) 指向的 attach 换成 OurAttach（保留 JAPI 的 ObjectAttach）
//     2) OurAttach 先原样调用 JAPI 的 ObjectAttach（JAPI 行为 100% 不变）
//     3) 对象取 **ecx**（JAPI 自己就是 mov edi,ecx; mov eax,[edi]），
//        把 [obj->vtbl + 0x128] 从 J+0x1F770 换成 OurDamageHandler，
//        保存被换下来的 J+0x1F770
//     4) OurDamageHandler 每次调用都记一行（含 chg 字段），然后尾调 J+0x1F770
//
// 【安全原则】
//   * 任何一步校验不过 -> 只写日志，绝不替换、绝不崩溃
//   * 所有可疑内存读取都套 __try/__except
//   * attach 会被多个对象/多次地图调用 -> 用虚表地址去重
//   * 挂接失败的最坏后果：游戏照常跑，只是日志里少几行
//
// 【编译】
//   cl /nologo /utf-8 /LD /O2 /MT /EHsc /Fe:UDamageProbe.dll /Fo:... UDamageProbe.cpp
//      /link /SUBSYSTEM:WINDOWS
//   可选宏：/DPROBE_VERBOSE=1 —— 额外 dump 伤害事件记录的原始 dword。
//
// 源文件 UTF-8 保存；日志按系统 ANSI(GBK) 写出，记事本可直接看。
//==============================================================================

// 本插件故意使用 fopen/_snprintf 这类"不安全"函数：
// 它们不抛异常、不依赖 CRT 全局状态，在游戏进程里最稳。关掉 C4996 噪音。
#define _CRT_SECURE_NO_WARNINGS 1

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>

// PROBE_VERBOSE 默认关闭；编译时加 /DPROBE_VERBOSE=1 打开
#ifndef PROBE_VERBOSE
#define PROBE_VERBOSE 0
#endif

//------------------------------------------------------------------------------
// 0. JAPI (yd_jass_api.dll) 内部偏移 —— 全部来自 dumpbin /disasm 复核
//------------------------------------------------------------------------------
static const uint32_t JAPI_OFF_OBJECT_ATTACH   = 0x1F830; // JAPI 的 attach（我们替换它）
static const uint32_t JAPI_OFF_DAMAGE_RELAY    = 0x1F770; // JAPI 的虚表伤害中继
static const uint32_t JAPI_OFF_ORIG_DAMAGE_VT  = 0x928B8; // JAPI: 被它换下来的原虚表方法
static const uint32_t JAPI_OFF_ATTACH_PTR_SLOT = 0x928D4; // *(uint32_t*) -> attach 函数地址
static const uint32_t JAPI_OFF_EVENT_KEY       = 0x928D0; // 当前伤害事件键（0 = 没有）
static const uint32_t JAPI_OFF_TABLE_BASE      = 0x928C4; // 哈希表基址
static const uint32_t JAPI_OFF_TABLE_SIZE      = 0x928C8; // 哈希表大小（2 的幂）
static const uint32_t JAPI_OFF_KEY_BASE        = 0x928CC; // 基准键

static const uint32_t VTBL_DAMAGE_SLOT_OFF     = 0x128;   // 虚表里的伤害槽偏移

// 伤害事件记录 rec = *(uint32_t*)(entry+4) 的字段
//   rec+0x00  uint8   是否物理伤害
//   rec+0x01  uint8   "是否已被处理/冻结" 标志（JAPI 中继会清零）
//   rec+0x0C  uint32  bit0 = 是否远程, bit8 = 是否攻击
//   rec+0x10  uint32  DXGetUnitState(unit, UNIT_STATE_LIFE) 快照
//   info = *(uint32_t*)(rec+4)
//   info+0x14 uint32  伤害类型位掩码  (log2 -> 类型号)
//   info+0x18 uint32  攻击类型位掩码  (log2 -> 类型号)
//   info+0x1C uint32  武器类型位掩码  (log2 -> 类型号)
//   info+0x20 uint32  武器类型原始值
static const uint32_t REC_OFF_PHYSICAL  = 0x00;
static const uint32_t REC_OFF_FLAGS     = 0x0C;
static const uint32_t REC_OFF_LIFE      = 0x10;
static const uint32_t INFO_OFF_DMG_TYPE = 0x14;
static const uint32_t INFO_OFF_ATK_TYPE = 0x18;
static const uint32_t INFO_OFF_WEP_TYPE = 0x1C;
static const uint32_t INFO_OFF_WEP_RAW  = 0x20;

// 日志上限（防止长时间游戏把磁盘写爆）
static const int PROBE_MAX_LOG_LINES = 200000;

// 初始化状态：0=未开始 1=进行中/已完成
static volatile LONG g_initState = 0;
static volatile LONG g_initDone  = 0;

//------------------------------------------------------------------------------
// 1. 全局状态
//------------------------------------------------------------------------------
static HMODULE  g_hSelf = NULL;
static char     g_dllDir[MAX_PATH] = { 0 };   // 本 DLL 所在目录（日志只写这里）
static char     g_logPath[MAX_PATH] = { 0 };
static CRITICAL_SECTION g_logLock;
static volatile LONG g_logLockReady = 0;
static volatile LONG g_logLines     = 0;

static uint32_t g_japiBase = 0;               // J := GetModuleHandleA("yd_jass_api.dll")
static uint32_t g_ydbase   = 0;

// replace_pointer 函数指针（ydbase 导出，__cdecl）
typedef uint32_t (__cdecl *fn_replace_pointer_t)(uint32_t target_addr, uint32_t new_value);
static fn_replace_pointer_t g_replace_pointer = NULL;

// 原 attach = JAPI 的 ObjectAttach。签名复核定论：__fastcall，末尾 ret 10h => 4 个栈参数
typedef void (__fastcall *fn_attach_t)(void* ecx, void* edx,
                                       uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4);
static fn_attach_t g_old_attach = NULL;

// 原伤害中继 = JAPI 的 0x1F770。__fastcall，末尾 ret 8 => 2 个栈参数
typedef void (__fastcall *fn_damage_t)(void* self, void* edx, uint32_t a1, uint32_t a2);
// 用 volatile LONG 存放，方便用 InterlockedCompareExchange 保证多线程下只写一次
static volatile LONG g_old_damage = 0;
#define OLD_DAMAGE_FN ((fn_damage_t)(uintptr_t)g_old_damage)

// 去重：已处理过的对象虚表地址（每种单位类型一份，数量很少）
static const LONG MAX_VT_SEEN = 256;
static uint32_t   g_vtSeen[MAX_VT_SEEN];
static volatile LONG g_vtSeenCount  = 0;
static volatile LONG g_damageCalls  = 0;   // 进入中继的次数
static volatile LONG g_damageHooked = 0;   // 成功替换虚表槽的次数

// 去噪：同一个伤害事件会被中继调用多次，用"生命值快照"识别新事件
static volatile LONG g_noEventLines = 0;

//------------------------------------------------------------------------------
// 2. 日志：fopen("ab") + fprintf + fclose，一把 CRITICAL_SECTION
//------------------------------------------------------------------------------
static void LogLine(const char* fmt, ...)
{
    if (!g_logPath[0]) return;

    char body[1024];
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf(body, sizeof(body) - 1, fmt, ap);
    body[sizeof(body) - 1] = 0;
    va_end(ap);

    if (InterlockedIncrement(&g_logLines) > PROBE_MAX_LOG_LINES) {
        if (g_logLines == PROBE_MAX_LOG_LINES + 1 && g_logLockReady) {
            EnterCriticalSection(&g_logLock);
            FILE* f = fopen(g_logPath, "ab");
            if (f) { fputs("[probe] 日志行数达到上限，后续记录被丢弃\r\n", f); fclose(f); }
            LeaveCriticalSection(&g_logLock);
        }
        return;
    }

    if (!g_logLockReady) return;
    EnterCriticalSection(&g_logLock);
    FILE* f = fopen(g_logPath, "ab");
    if (f) {
        SYSTEMTIME st;
        GetLocalTime(&st);
        fprintf(f, "[%02d:%02d:%02d.%03d] %s\r\n",
                st.wHour, st.wMinute, st.wSecond, st.wMilliseconds, body);
        fclose(f);
    }
    LeaveCriticalSection(&g_logLock);
}

// 指针是否可读。自己实现（VirtualQuery），比 IsBadReadPtr 可靠
static int Readable(const void* p, size_t n)
{
    if (!p) return 0;
    if ((uint32_t)(uintptr_t)p < 0x10000) return 0;
    MEMORY_BASIC_INFORMATION mbi;
    if (VirtualQuery(p, &mbi, sizeof(mbi)) != sizeof(mbi)) return 0;
    if (mbi.State != MEM_COMMIT) return 0;
    if (mbi.Protect & (PAGE_NOACCESS | PAGE_GUARD)) return 0;
    const uint8_t* end       = (const uint8_t*)p + n;
    const uint8_t* regionEnd = (const uint8_t*)mbi.BaseAddress + mbi.RegionSize;
    return end <= regionEnd;
}

//------------------------------------------------------------------------------
// 3. 当前伤害事件记录解析
//------------------------------------------------------------------------------
struct EventInfo {
    int      ok;          // 是否成功解析出 rec
    uint32_t key;
    uint32_t tableSize;
    uint32_t index;
    uint32_t entry;
    uint32_t rec;
    uint32_t info;
    uint32_t physical;    // rec+0x00
    uint32_t flags;       // rec+0x0C
    uint32_t life;        // rec+0x10
    uint32_t dmgTypeMask; // info+0x14
    uint32_t atkTypeMask; // info+0x18
    uint32_t wepTypeMask; // info+0x1C
    uint32_t wepTypeRaw;  // info+0x20
#if PROBE_VERBOSE
    uint32_t rawRec[4];
    uint32_t rawInfo[4];
#endif
};

// 掩码 -> 类型号（就是 log2；mask=0 时返回 0，与 JAPI 实现一致）
static uint32_t MaskToIndex(uint32_t mask)
{
    uint32_t r = 0;
    while (mask) { ++r; mask >>= 1; }
    return r ? r - 1 : 0;
}

// 读取当前伤害事件记录。全程 __try/__except；失败返回 ok=0，绝不抛。
static void ReadEventInfo(EventInfo* out)
{
    memset(out, 0, sizeof(*out));

    __try {
        if (!g_japiBase) return;

        uint32_t key = *(volatile uint32_t*)(g_japiBase + JAPI_OFF_EVENT_KEY);
        if (key == 0) return;                       // 当前没有伤害事件
        out->key = key;

        uint32_t table = *(volatile uint32_t*)(g_japiBase + JAPI_OFF_TABLE_BASE);
        uint32_t size  = *(volatile uint32_t*)(g_japiBase + JAPI_OFF_TABLE_SIZE);
        uint32_t kbase = *(volatile uint32_t*)(g_japiBase + JAPI_OFF_KEY_BASE);

        if (size == 0) return;
        if (size & (size - 1)) return;              // 必须是 2 的幂
        if (size > (1u << 24)) return;              // 明显不合理

        uint32_t index = (key + kbase - 1) & (size - 1);
        out->tableSize = size;
        out->index     = index;

        if (!Readable((const void*)(uintptr_t)table, 4)) return;
        if (!Readable((const void*)(uintptr_t)(table + index * 4), 4)) return;
        uint32_t entry = *(volatile uint32_t*)(uintptr_t)(table + index * 4);
        if (!Readable((const void*)(uintptr_t)entry, 8)) return;
        out->entry = entry;

        uint32_t rec = *(volatile uint32_t*)(uintptr_t)(entry + 4);
        if (!Readable((const void*)(uintptr_t)rec, 0x14)) return;
        out->rec = rec;

        out->physical = *(volatile uint8_t*)(uintptr_t)(rec + REC_OFF_PHYSICAL);
        out->flags    = *(volatile uint32_t*)(uintptr_t)(rec + REC_OFF_FLAGS);
        out->life     = *(volatile uint32_t*)(uintptr_t)(rec + REC_OFF_LIFE);

        uint32_t info = *(volatile uint32_t*)(uintptr_t)(rec + 4);
        if (!Readable((const void*)(uintptr_t)info, 0x24)) return;
        out->info = info;

        out->dmgTypeMask = *(volatile uint32_t*)(uintptr_t)(info + INFO_OFF_DMG_TYPE);
        out->atkTypeMask = *(volatile uint32_t*)(uintptr_t)(info + INFO_OFF_ATK_TYPE);
        out->wepTypeMask = *(volatile uint32_t*)(uintptr_t)(info + INFO_OFF_WEP_TYPE);
        out->wepTypeRaw  = *(volatile uint32_t*)(uintptr_t)(info + INFO_OFF_WEP_RAW);

#if PROBE_VERBOSE
        memcpy(out->rawRec,  (const void*)(uintptr_t)rec,  16);
        memcpy(out->rawInfo, (const void*)(uintptr_t)info, 16);
#endif

        out->ok = 1;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        out->ok = 0;
    }
}

//------------------------------------------------------------------------------
// 4. 我们的伤害中继（替换 J+0x1F770）
//    签名必须与 J+0x1F770 完全一致：ecx/edx 传参 + ret 8（两个栈参数）
//------------------------------------------------------------------------------
static void __fastcall OurDamageHandler(void* self, void* edxarg, uint32_t a1, uint32_t a2)
{
    LONG n = InterlockedIncrement(&g_damageCalls);

    // ① 先抄下最原始的四个参数（本轮最有价值的数据）
    const uint32_t v_self = (uint32_t)(uintptr_t)self;
    const uint32_t v_edx  = (uint32_t)(uintptr_t)edxarg;
    const uint32_t v_a1   = a1;
    const uint32_t v_a2   = a2;

    // ② 读当前伤害事件记录
    EventInfo ev;
    ReadEventInfo(&ev);

    // ③ 每次调用都写一行（本阶段就是要看清"一次伤害事件里中继被调用几次、
    //    每次参数怎么变"），并额外给出 chg 字段：
    //      chg=1 -> rec / life / flags 三者中至少有一个与上一条日志不同
    //               （通常代表"这是一个新的伤害事件"）
    //      chg=0 -> 三者与上一条完全相同（通常是同一个事件的后续调用）
    //    另外 ev.ok 为假时用 noev 计数表示"读不到事件记录"。
    static uint32_t lastRec  = 0;
    static uint32_t lastLife = 0;
    static uint32_t lastFlag = 0;
    static LONG     lastNoEv = 0;

    uint32_t chg = 0;
    if (ev.ok) {
        chg = (ev.rec != lastRec || ev.life != lastLife || ev.flags != lastFlag) ? 1u : 0u;
        lastRec = ev.rec; lastLife = ev.life; lastFlag = ev.flags;
    } else {
        lastNoEv = InterlockedIncrement(&g_noEventLines);
    }

    // ④ 组一行日志（只做栈上格式化，不分配内存）
    char line[768];
    int  off = 0;
    off += _snprintf(line + off, sizeof(line) - (size_t)off,
        "D #%ld chg=%u self=%08X edx=%08X a1=%08X a2=%08X",
        n, chg, v_self, v_edx, v_a1, v_a2);

    if (ev.ok) {
        off += _snprintf(line + off, sizeof(line) - (size_t)off,
            " | key=%08X size=%u idx=%u entry=%08X rec=%08X info=%08X",
            ev.key, ev.tableSize, ev.index, ev.entry, ev.rec, ev.info);
        off += _snprintf(line + off, sizeof(line) - (size_t)off,
            " phys=%u atk=%u rng=%u life=%08X",
            ev.physical, (ev.flags >> 8) & 1u, ev.flags & 1u, ev.life);
        off += _snprintf(line + off, sizeof(line) - (size_t)off,
            " dmgmask=%08X dmg=%u atkmask=%08X atk=%u wepmask=%08X wep=%u wepraw=%u",
            ev.dmgTypeMask, MaskToIndex(ev.dmgTypeMask),
            ev.atkTypeMask, MaskToIndex(ev.atkTypeMask),
            ev.wepTypeMask, MaskToIndex(ev.wepTypeMask),
            ev.wepTypeRaw);
#if PROBE_VERBOSE
        off += _snprintf(line + off, sizeof(line) - (size_t)off,
            " | rec[%08X %08X %08X %08X] info[%08X %08X %08X %08X]",
            ev.rawRec[0], ev.rawRec[1], ev.rawRec[2], ev.rawRec[3],
            ev.rawInfo[0], ev.rawInfo[1], ev.rawInfo[2], ev.rawInfo[3]);
#endif
    } else {
        off += _snprintf(line + off, sizeof(line) - (size_t)off,
            " | event=<none or unreadable> noev=%ld", lastNoEv);
    }
    line[sizeof(line) - 1] = 0;
    LogLine("%s", line);

    // ⑤ 必须尾调原中继（JAPI 的 0x1F770），保证 JAPI 行为完全不受影响
    if (OLD_DAMAGE_FN) {
        __try {
            OLD_DAMAGE_FN(self, edxarg, a1, a2);
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            LogLine("E 原伤害中继抛出异常，已吞掉（code=%08X）",
                    (uint32_t)GetExceptionCode());
        }
    }
}

//------------------------------------------------------------------------------
// 5. 我们的 attach（替换 JAPI 的 ObjectAttach）
//
// 签名复核定论：__fastcall，末尾 ret 10h => ecx/edx + 4 个栈参数。
//
// 【对象在 ecx，不在栈上】—— 这条是被实机日志纠正过来的，硬证据：
//     1001F836: 8B F9              mov edi,ecx        ; edi = 对象
//     1001F83C: 8B 07              mov eax,[edi]      ; eax = *(uint32_t*)对象 = 虚表
//     1001F83E: 05 28 01 00 00     add eax,128h       ; 槽地址 = 虚表 + 0x128
//     1001F843: 81 38 70 F7 01 10  cmp [eax],1001F770h
// JAPI 自己就是用 ecx 当对象的。实机日志也印证：ecx=1E68CE84（堆地址），
// 而 4 个栈参数里 a4=00000000。
//
// 栈偏移推导（入口 esp 记为 E）：
//     E+04 = arg1, E+08 = arg2, E+0C = arg3, E+10 = arg4
//     sub esp,14h + push ebp/esi/edi = 0x14 + 0xC = 0x20  => E-0x20
//     => 函数体内 arg1=[esp+24h], arg2=[esp+28h], arg3=[esp+2Ch], arg4=[esp+30h]
//   JAPI 的 `1001F870: mov ebp,[esp+28h]` 取的是 **arg2**（一个 16 字节值的首字段，
//   不是对象）；`1001F865: cmp [esp+2Ch],0` 看的是 **arg3**（被 setne 转成 0/1
//   存进事件记录）。两者都原样记在日志里，供后续判读。
//------------------------------------------------------------------------------
static void __fastcall OurAttach(void* ecx_in, void* edx_in,
                                 uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4)
{
    const uint32_t v_ecx = (uint32_t)(uintptr_t)ecx_in;
    const uint32_t v_edx = (uint32_t)(uintptr_t)edx_in;

    // ① 先让 JAPI 做完它原本的事（替换虚表槽 + 建事件记录）
    if (g_old_attach) {
        __try {
            g_old_attach(ecx_in, edx_in, a1, a2, a3, a4);
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            LogLine("E 原 attach 抛出异常，已吞掉（code=%08X）",
                    (uint32_t)GetExceptionCode());
        }
    }

    LogLine("A attach ecx=%08X edx=%08X a1=%08X a2=%08X a3=%08X a4=%08X",
            v_ecx, v_edx, a1, a2, a3, a4);

    // ② 对象 = ecx（见上面的 dumpbin 证据）
    const uint32_t obj = v_ecx;
    if (!Readable((const void*)(uintptr_t)obj, 4)) {
        LogLine("A 对象指针 ecx=%08X 不可读，跳过（结构可能与预期不同）", obj);
        return;
    }

    const uint32_t vt = *(volatile uint32_t*)(uintptr_t)obj;
    if (!Readable((const void*)(uintptr_t)vt, VTBL_DAMAGE_SLOT_OFF + 4)) {
        LogLine("A 虚表 %08X 不可读，跳过（obj=%08X）", vt, obj);
        return;
    }

    // ③ 幂等：同一虚表只处理一次
    const LONG seen = g_vtSeenCount;
    for (LONG i = 0; i < seen && i < MAX_VT_SEEN; ++i) {
        if (g_vtSeen[i] == vt) {
            LogLine("A 虚表 %08X 已处理过，跳过（obj=%08X）", vt, obj);
            return;
        }
    }
    if (seen < MAX_VT_SEEN) g_vtSeen[InterlockedIncrement(&g_vtSeenCount) - 1] = vt;

    const uint32_t slot2 = vt + VTBL_DAMAGE_SLOT_OFF;
    const uint32_t cur   = *(volatile uint32_t*)(uintptr_t)slot2;
    const uint32_t relay = g_japiBase + JAPI_OFF_DAMAGE_RELAY;

    if (cur != relay) {
        LogLine("A 虚表槽 %08X 当前值 %08X != JAPI 中继 %08X，不替换（只记录，obj=%08X）",
                slot2, cur, relay, obj);
        return;
    }

    if (!g_replace_pointer) {
        LogLine("A replace_pointer 不可用，无法替换虚表槽");
        return;
    }

    // ④ 替换虚表槽，并保存被换下来的 J+0x1F770，供中继尾调
    __try {
        const uint32_t old = g_replace_pointer(slot2, (uint32_t)(uintptr_t)&OurDamageHandler);
        // 用 CAS 保证多线程下 g_old_damage 只会被写成同一个值
        const LONG prev = InterlockedCompareExchange(&g_old_damage, (LONG)old, 0);
        if (prev != 0 && (uint32_t)prev != old) {
            LogLine("A 注意：不同虚表返回的原中继地址不同（%08X vs %08X）",
                    (uint32_t)prev, old);
        }
        InterlockedIncrement(&g_damageHooked);
        LogLine("A 已挂接伤害中继 obj=%08X vt=%08X slot=%08X old=%08X our=%08X hookN=%ld",
                obj, vt, slot2, old, (uint32_t)(uintptr_t)&OurDamageHandler,
                g_damageHooked);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("E 替换虚表槽时异常（code=%08X）", (uint32_t)GetExceptionCode());
    }
}

//------------------------------------------------------------------------------
// 6. 初始化
//------------------------------------------------------------------------------
static void InitLogPath(HMODULE hSelf)
{
    char mod[MAX_PATH] = { 0 };
    GetModuleFileNameA(hSelf, mod, MAX_PATH);

    strncpy_s(g_dllDir, MAX_PATH, mod, _TRUNCATE);
    char* slash = strrchr(g_dllDir, '\\');
    if (slash) *slash = 0; else g_dllDir[0] = 0;

    _snprintf_s(g_logPath, MAX_PATH, _TRUNCATE,
                "%s\\UDamageProbe.log", g_dllDir);
}

static void DoInitialize(void)
{
    if (!g_logLockReady) return;

    LogLine("================================================================");
    LogLine("UDamageProbe 探针版 v1.0   PROBE_VERBOSE=%d", (int)PROBE_VERBOSE);
    LogLine("本 DLL  : %s", g_dllDir);
    LogLine("日志文件: %s", g_logPath);
    LogLine("自身模块: %08X   PID=%lu", (uint32_t)(uintptr_t)g_hSelf, GetCurrentProcessId());
    LogLine("JAPI 预期: attach=J+%X  中继=J+%X  原虚表槽保存=J+%X",
            JAPI_OFF_OBJECT_ATTACH, JAPI_OFF_DAMAGE_RELAY, JAPI_OFF_ORIG_DAMAGE_VT);

    // ---- 等待依赖模块 + attach 槽就绪（默认最多 60 秒）----
    DWORD waitMs = 60000;
    {
        char buf[32] = { 0 };
        DWORD n = GetEnvironmentVariableA("UDMAGE_PROBE_WAIT_MS", buf, sizeof(buf));
        if (n > 0 && n < sizeof(buf)) {
            long v = atol(buf);
            if (v >= 0 && v <= 600000) waitMs = (DWORD)v;
        }
    }

    const DWORD step = 500;
    DWORD waited = 0;
    int japiLogged = 0, ydbaseLogged = 0;

    for (;;) {
        if (!g_japiBase) {
            g_japiBase = (uint32_t)(uintptr_t)GetModuleHandleA("yd_jass_api.dll");
            if (g_japiBase && !japiLogged) {
                japiLogged = 1;
                LogLine("已找到 yd_jass_api.dll，基址 J=%08X", g_japiBase);
            }
        }
        if (!g_ydbase) {
            g_ydbase = (uint32_t)(uintptr_t)GetModuleHandleA("ydbase.dll");
            if (g_ydbase && !ydbaseLogged) {
                ydbaseLogged = 1;
                LogLine("已找到 ydbase.dll，基址 %08X", g_ydbase);
            }
        }
        if (g_japiBase && g_ydbase) {
            uint32_t slot = 0;
            __try {
                slot = *(volatile uint32_t*)(uintptr_t)(g_japiBase + JAPI_OFF_ATTACH_PTR_SLOT);
            } __except (EXCEPTION_EXECUTE_HANDLER) {
                slot = 0;
            }
            if (slot != 0) break;
        }
        if (waited >= waitMs) break;
        Sleep(step);
        waited += step;
    }

    // ---- 结果判定 ----
    if (!g_japiBase || !g_ydbase) {
        LogLine("初始化中止：未找到 %s%s，安全退出（游戏不受影响）",
                g_japiBase ? "" : "yd_jass_api.dll ",
                g_ydbase   ? "" : "ydbase.dll");
        LogLine("提示：本探针必须和 yd_jass_api.dll 在同一进程（即通过启动器进游戏）才会生效。");
        LogLine("================================================================");
        InterlockedExchange(&g_initDone, 1);
        return;
    }

    // ---- 取 replace_pointer ----
    g_replace_pointer = (fn_replace_pointer_t)(uintptr_t)GetProcAddress(
        (HMODULE)(uintptr_t)g_ydbase, "?replace_pointer@hook@base@@YAIII@Z");
    if (!g_replace_pointer) {
        LogLine("初始化中止：ydbase.dll 里找不到 ?replace_pointer@hook@base@@YAIII@Z，安全退出");
        LogLine("================================================================");
        InterlockedExchange(&g_initDone, 1);
        return;
    }
    LogLine("replace_pointer = %08X", (uint32_t)(uintptr_t)g_replace_pointer);

    // ---- 校验 attach 槽 ----
    uint32_t slot = 0, cur = 0;
    __try {
        slot = *(volatile uint32_t*)(uintptr_t)(g_japiBase + JAPI_OFF_ATTACH_PTR_SLOT);
        cur  = slot ? *(volatile uint32_t*)(uintptr_t)slot : 0;
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        LogLine("初始化中止：读取 J+%X 时异常，安全退出", JAPI_OFF_ATTACH_PTR_SLOT);
        LogLine("================================================================");
        InterlockedExchange(&g_initDone, 1);
        return;
    }

    const uint32_t expect = g_japiBase + JAPI_OFF_OBJECT_ATTACH;
    LogLine("校验 J+%X -> 槽指针=%08X，*槽=%08X，期望值=%08X",
            JAPI_OFF_ATTACH_PTR_SLOT, slot, cur, expect);

    if (cur != expect) {
        LogLine("初始化中止：attach 槽内容与预期不符（JAPI 版本不匹配？），不做任何替换");
        LogLine("================================================================");
        InterlockedExchange(&g_initDone, 1);
        return;
    }

    // ---- 替换 attach ----
    __try {
        const uint32_t old = g_replace_pointer(slot, (uint32_t)(uintptr_t)&OurAttach);
        g_old_attach = (fn_attach_t)(uintptr_t)old;
        LogLine("已挂接 attach：old=%08X（期望 %08X）  our=%08X",
                old, expect, (uint32_t)(uintptr_t)&OurAttach);
        LogLine("校验结果：%s", (old == expect) ? "OK" : "警告：返回的原地址与预期不同！");
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        g_old_attach = NULL;
        LogLine("初始化中止：替换 attach 时异常（code=%08X），未完成挂接",
                (uint32_t)GetExceptionCode());
    }

    LogLine("初始化完成。请进入游戏并让单位受到一次伤害。");
    LogLine("日志各列含义见 plugin\\探针说明.md");
    LogLine("================================================================");
    InterlockedExchange(&g_initDone, 1);
}

// 真正干活的初始化线程体
static DWORD WINAPI InitThreadProc(LPVOID)
{
    InitLogPath(g_hSelf);
    DoInitialize();
    return 0;
}

// 兜底线程：Initialize() 没被调用时，3 秒后自己补一次
static DWORD WINAPI FallbackThread(LPVOID)
{
    for (int i = 0; i < 30; ++i) {
        if (g_initDone) return 0;
        Sleep(100);
    }
    if (InterlockedCompareExchange(&g_initState, 1, 0) == 0) {
        InitLogPath(g_hSelf);
        DoInitialize();
    }
    return 0;
}

//------------------------------------------------------------------------------
// 7. 导出
//------------------------------------------------------------------------------
extern "C" __declspec(dllexport) const char* __cdecl PluginName(void)
{
    return "UDamageProbe";
}

extern "C" __declspec(dllexport) void __cdecl Initialize(void)
{
    if (InterlockedCompareExchange(&g_initState, 1, 0) != 0) return;  // 幂等

    // 初始化内部最多等 60 秒，放到后台线程，避免卡住调用方的加载流程
    HANDLE h = CreateThread(NULL, 0, InitThreadProc, NULL, 0, NULL);
    if (h) CloseHandle(h);
}

//------------------------------------------------------------------------------
// 8. DllMain
//------------------------------------------------------------------------------
BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID)
{
    if (reason == DLL_PROCESS_ATTACH) {
        g_hSelf = hModule;
        DisableThreadLibraryCalls(hModule);
        InitLogPath(hModule);

        InitializeCriticalSection(&g_logLock);
        InterlockedExchange(&g_logLockReady, 1);

        HANDLE t = CreateThread(NULL, 0, FallbackThread, NULL, 0, NULL);
        if (t) CloseHandle(t);
    }
    return TRUE;
}
