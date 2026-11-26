//----------------------------------------------------------------------------
// ddh.cpp -- Damage Event Hook (32-bit DLL, injected into war3.exe)
//
// 目标：把引擎的伤害函�?game.dll+0x67DC40 的入口改�?6 字节的跳转补丁（jmp + NOP），
//       跳到我们自己�?__fastcall 替换函数 DdhDamageFunc；函数里先记前血 �?自己 call
//       原函数（跳板）→ 返回后立刻记后血 �?算本层掉血，返回值原样带回（�?UDamageWatcherHook.cpp 同款）�?
//
// 契约（来自本仓库 `伤害监视说明.md` §2，已源码 + 二进制双向复核）�?
//   uint32_t __fastcall DdhDamageFunc(uint32_t _this /*ecx=受伤单位*/,
//                                     uint32_t _edx,
//                                     uint32_t a2,        /* �? 调用方的 out（float*），出口写最终伤�?*/
//                                     war3_event_damage_data* info,
//                                     uint32_t is_physical,
//                                     uint32_t source_unit);   // ret 10h
//   v20 起，引擎伤害 / 最终伤�?/ 净掉血全部由这一个钩子的"出口三读"给出�?
//     出口 info+0x10 = 引擎算完的值（护甲/攻防类型/加成之后�?
//     出口 *a2       = 最终落地值（含地�?SetEventDamage 的改写；WFE 读的就是它）
//     前后血�?       = 净掉血
//   struct war3_event_damage_data {
//       uint32 source_unit;  // +0x00  来源单位【对象指针�?
//       uint32 weapon_type;  // +0x04
//       uint32 unk2;         // +0x08
//       uint32 flag;         // +0x0C  bit0=是否远程, bit8=是否攻击
//       uint32 amount;       // +0x10  伤害值（jass real �?�?float 解释�?
//       uint32 damage_type;  // +0x14  伤害类型位掩码（log2 - 1 = 类型号）
//       uint32 unk6, unk7;   // +0x18/+0x1C
//       uint32 attack_type;  // +0x20  攻击类型
//   };
//
// 原函数开头（`WFE伤害机制分析.md` §3.4 实机字节）：
//   55 8B EC 83 EC 2C 56 57 8B F9  �?push ebp; mov ebp,esp; sub esp,0x2C; push esi; push edi; mov edi,ecx
// �?6 字节正好�?3 条完整指令，所以搬走它们是安全的�?
//
// 事件通过**命名共享内存**交给外面�?64 位主程序（不写盘、不做文�?IO）�?
//----------------------------------------------------------------------------

#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <float.h>
#include <math.h>
#include <stdarg.h>

/* v9：热键（RegisterHotKey/GetMessage）和找游戏窗口（FindWindow）要�?user32�?
   build_hook.ps1 不额外传 lib，所以在这里�?pragma 带上�?*/
#pragma comment(lib, "user32.lib")

/* 统一�?_snprintf_s + _TRUNCATE 组装字符串，取代 sprintf_s 及各�?_s 变体�?
   缓冲区不够时只“截断”，绝不调无效参数处理器�?
   为什么：UCRT �?sprintf_s 在“放不下”时�?_invoke_watson �?__fastfail(FAST_FAIL_INVALID_ARG)�?
   宿主进程（war3.exe）当�?0xC0000409 崩掉 —�?2026-10-31 20:22:52 真机就是这么崩的�?
   长中文名 “……【辅助单位�?e009)�?被写�?64 字节的“名�?�?”标签�?*/
#define DdhSprintf(buf, cap, ...) _snprintf_s((buf), (cap), _TRUNCATE, __VA_ARGS__)

#define DDH_MAGIC     0x31484444u   /* "DDH1" */
/* v20：三个口径全部改�?0x67DC40 单个钩子�?出口三读"给出，不再挂 GetEventDamage / SetEventDamage�?
   v20 的记录在 v8 之后追加 8 字节：finalDamage(float) + finalFlags(uint32)�?
     引擎伤害 = 原函数退出时�?info+0x10（护�?攻防类型/加成之后，事件改写不回写它）
     最终伤�?= 原函数退出时�?*out�? 调用�?out 指针，也就是 WFE 读的那个数）
     净掉血   = 前后血差（不变�?
   �?JASS native 钩子保留，但默认关闭；要诊断"地图读了几次/改了几次"就设
   环境变量 DDH_NATIVE_DAMAGE_HOOKS=1�?*/
#define DDH_VERSION   38
#define DDH_MAX_EVENTS 512
#define DDH_MAXDEPTH  16      /* 伤害事件最大嵌套层数（地图�?DOT/追加伤害会套进来�?*/

static HWND g_gameWnd = NULL;

/* �?C# 端一一对应，pack(1) */
#pragma pack(push,1)
struct DdhHeader
{
    uint32_t magic;
    uint32_t version;
    uint32_t pid;
    uint32_t capacity;      /* 环容量（事件数） */
    uint32_t count;         /* 已写事件总数（递增�?*/
    uint32_t hookOk;        /* 1 = 挂钩成功 */
    uint32_t slotCount;     /* 打过�?vtbl 槽位数（备用方案用） */
    uint32_t gameDllBase;
    uint32_t hookRva;
    uint32_t selfTest;      /* 1 = 注入成功但还没看到伤害事�?*/
    uint32_t lastTick;
    uint32_t reserved[5];
};

struct DdhEvent
{
    uint32_t seq;
    uint32_t tickMs;
    uint32_t victim;        /* 受伤单位对象指针 */
    uint32_t victimCode;    /* +0x30 �?4 字节，原样（不翻转，外面统一处理�?*/
    uint32_t source;        /* info+0x00 来源单位对象指针 */
    uint32_t sourceCode;
    float    amount;        /* info+0x10 */
    uint32_t flag;          /* info+0x0C */
    uint32_t attackType;    /* info+0x20 */
    uint32_t damageMask;    /* info+0x14 */
    uint32_t weaponType;    /* info+0x04 */
    uint32_t isPhysical;
    uint32_t stackSource;   /* 栈参�?source_unit（这个构建里通常 0�?*/
    /* 名字字段：引擎原名是 **UTF-8** 字节串，0 结尾（真机日�?hex=E9 9B AA = 雪狼）�?
       v9 起各 64 字节（v8 �?32 字节会从汉字中间截断：末尾剩 E4 BD，C# 严格 UTF-8
       解不开、回退 GBK 就成了「鎶…鑳…」乱码）。写名字一律走 DdhUtf8SafeCopy：最�?
       63 字节 + NUL；截断点落在多字节字符中间时回退到该字符起始，绝不写半个汉字�?*/
    char     victimName[64];
    char     sourceName[64];
    /* ---- v3：血量（进程内直接读 CUnit 的生命链，不调任�?JASS�?---- */
    float    hpBefore;      /* 进入伤害函数时的血（地图触发还没跑�?*/
    float    hpAfter;       /* 原函数返回之后（地图增伤/减伤已经跑完�?*/
    float    actual;        /* 本层自己的掉血 = (hpBefore-hpAfter) - 内层子效果，下限 0 */
    uint32_t hpValid;       /* 1 = 前后血都读到了，actual 可信 */
    uint32_t depth;         /* 嵌套层号，从 1 开�?*/
    /* ---- v4：引擎伤害（地图第一次调�?GetEventDamage() 时的返回值） ---- */
    float    engineDamage;
    uint32_t engineValid;   /* 1 = 这次事件地图确实问过 GetEventDamage */
    /* ---- v20：原 v5 的两个槽（engineLast / engineCalls）改�?最终伤�?�?----
       �?布局一个字节都没变（还�?236 字节），只是语义换了�?
       来源 = `*a2`（调用方 out 指针，原函数 [ebp+8]）。它就是 WFE 读来画伤�?
       数字的那块内存：引擎�?+ 地图 SetEventDamage 的改写�?
       finalFlags�?
         bit0 = 1 �?本次确实掉了血（own > 0），值可�?
         bit1 = 1 �?与引擎值不�?�?地图改过伤害
         bit2 = 1 �?�?剩余血�?钳制（击杀溢出�?out = 前血，不是地图改伤害�?
       只在真掉血时才�?bit0：无�?[unit+0x5C]&0x100、免�?[+0x158]/[+0x15C]>0�?
       flags&4 这些早退分支根本不计算，直接把上一跳残留在 game+0xBB81D4 的值抄�?
       *out；那种情况下 own = 0，一律不认，避免把旧数字当成这次的地图伤害�?
       （�?DLL �?engineLast/engineCalls 语义�?v20 取消：默认不再挂
         GetEventDamage，C# 端同时按 v20 改读法。） */
    float    finalDamage;   /* �?engineLast 的槽 */
    uint32_t finalFlags;    /* �?engineCalls 的槽 */
    /* ---- v6：SetEventDamage 最后一次设的�?+ 调用次数（地图改伤害�?---
       设过 0.00 也算设过（设�?0 即有效），没设过�?0/0�?*/
    float    setDamage;
    uint32_t setCalls;
    /* ---- v7：目标单位蝗虫（马甲）标�?---- */
    uint32_t flags;         /* bit0 = 目标带蝗�?Aloc（马甲，不进死亡结算�?*/
    /* ---- v8：victimOwner/sourceOwner = CUnit+0x58 player slot (-1 = unknown) ---- */
    int32_t  victimOwner;
    int32_t  sourceOwner;
};
#pragma pack(pop)

#define DDH_EVENT_FLAG_VICTIM_ILLUSION (1u << 1)
#define DDH_EVENT_FLAG_SOURCE_ILLUSION (1u << 2)
#define DDH_EVENT_FLAG_VICTIM_HERO     (1u << 3)
#define DDH_EVENT_FLAG_SOURCE_HERO     (1u << 4)
#define DDH_EVENT_FLAG_SOURCE_LOCUST   (1u << 5)

/* 进程内事件环：不再创建命名共享内存。 */
struct DdhShared
{
    DdhHeader hdr;
    DdhEvent  ev[DDH_MAX_EVENTS];
};
#define DDH_SHM_SIZE ((uint32_t)sizeof(DdhShared))
typedef char DdhRingSizeIs120896[(sizeof(DdhShared) == 120896u) ? 1 : -1];
static DdhShared      g_localRing;
static DdhShared*     g_shm = &g_localRing;
extern uint32_t       g_modBase;
static HANDLE         g_instanceMutex = NULL;
static bool           g_duplicateInstance = false;
/* 事件完成标记：入口先清 0，出口字段全部补完后置 1。
   写库线程只认这个标记，不靠事件年龄猜。 */
static volatile LONG  g_evReady[DDH_MAX_EVENTS];
static bool DdhReadMapName(char* out, size_t cap);
static size_t DdhUtf8SafeCopy(char* dst, size_t cap, const char* src, size_t maxBytes);
static bool DdhCachedTitleByCode(uint32_t code, char* out, size_t cap);
#include "ddh_sqlite.inc"
static HMODULE        g_self = NULL;

extern "C" int DdhGetCurrentSessionId(char* out, int capacity)
{
    if (!out || capacity <= 0) return 0;
    DdhDbSessionKey session = DdhDbCurrentSession();
    if (session.ctx == 0 && session.game == 0)
    {
        out[0] = 0;
        return 0;
    }
    strncpy_s(out, (size_t)capacity, session.id, _TRUNCATE);
    return 1;
}

static uint8_t*       g_hookAt = NULL;      /* game.dll + 0x67DC40 */
static uint8_t*       g_tramp = NULL;       /* 搬走的前 6 字节 + jmp 回去 */
static const uint32_t HOOK_RVA = 0x67DC40;
static uint8_t        g_saved[8];
static bool           g_hooked = false;
static uint32_t       g_foundRva = 0;
static char           g_hookLastError[192] = { 0 };
static char           g_hookKnownBytes[96] = { 0 };

/* ---- v3：嵌套层次的状态（伤害只在游戏线程上发生，用栈式数组即可） ---- */
static volatile LONG  g_depth = 0;                    /* 当前嵌套深度�? = 不在伤害函数里） */
static uint32_t       g_slot[DDH_MAXDEPTH];            /* 本层事件在环里的下标 */
static uint32_t       g_seq[DDH_MAXDEPTH];             /* 本层事件序号（防环覆盖写错行�?*/
static uint32_t       g_levelTick[DDH_MAXDEPTH];       /* 本层入口时间（防 SEH 展开把深度漏掉） */
static uint32_t       g_hpCount = 0;                   /* 成功读到前后血的事件数（诊断用�?*/

/* ---- v13：子伤害�?*调用�?*累计，且只扣同一个目标（victim�?---
   旧版每层只有一�?g_childSum：多目标 AoE 时，内层打别人（典韦/步兵）的掉血
   也被扣到本层头上 —�?外层打张飞掉 28.13，显示成 1.87；正确是 22.50�?
   现在每进一次伤害函数压一帧，退帧时�?
       own = (hpBefore - hpAfter) - childSumSameVictim
   childSumSameVictim 只累计“victim 地址与本帧相同”的子帧退帧时上报�?gross
   （hpBefore - hpAfter）；不同目标的子帧只记自己的事件，不扣本帧�?
   帧栈�?= 事件层深 DDH_MAXDEPTH；越界由 DdhDamageFunc �?d > DDH_MAXDEPTH
   的旧退化分支兜住（只提示一次日志）�?*/
typedef struct DdhFrame
{
    uint32_t victim;              /* 本帧目标单位地址（CUnit*�?*/
    uint32_t depth;               /* 1 基层号（= level + 1，与事件 depth 字段同义�?*/
    uint32_t hpOk;                /* 前血是否读到�? = 没测到，本帧不算 own�?*/
    uint32_t active;              /* 帧是否还在栈上（退帧后�?0，防误用�?*/
    float    hpBefore;            /* 进入伤害函数时读到的血 */
    float    hpAfter;             /* 原函数返回后读到的血 */
    float    childSumSameVictim;  /* 已退栈、victim 与本帧相同的子帧 gross 合计 */
    uint32_t childCountSame;      /* 同目标子帧笔数（日志用） */
} DdhFrame;
static DdhFrame       g_frames[DDH_MAXDEPTH];          /* 帧栈：下�?= 层号 */
static volatile LONG  g_nestedLogCount = 0;            /* “嵌套扣减”日志只写前 3 �?*/
static volatile LONG  g_depthOverflowLogged = 0;       /* 栈深溢出只提示一�?*/

/* ---- 原伤害函数跳板：�?UDamageWatcherHook.cpp �?ORIG_DAMAGE 同款 ----
   安装时把 0x67DC40 �?6 字节搬进可执行内�?+ E9 跳回，跳板地址存这里；
   DdhDamageFunc �?call 这个跳板 = 跑原函数体，原函数结�?ret 0x10 回到我们�?*/
typedef uint32_t (__fastcall *fn_damage_t)(uint32_t _this, uint32_t _edx, uint32_t a2,
                                           void* info, uint32_t is_physical, uint32_t source_unit);
static volatile LONG  g_original_damage = 0;


/* ---- v4：引擎伤害（GetEventDamage 首次调用�?---- */
static uint32_t g_engineCap[DDH_MAXDEPTH];            /* 每层第一次抓到的引擎伤害（float 位模式） */
static uint32_t g_engineFirstSet[DDH_MAXDEPTH];       /* 每层首次值是否已抓到�? 也是合法值，不能�?0 当哨兵） */
static uint32_t g_engineLast[DDH_MAXDEPTH];           /* 每层**最后一�?*抓到的�?*/
static uint32_t g_engineCalls[DDH_MAXDEPTH];          /* 每层 GetEventDamage 被调用了几次 */
static volatile LONG g_gedTries = 0;
static volatile LONG g_gedHooked = 0;
static uint32_t g_realGetEventDamage = 0;
/* ---- SetEventDamage（地图改伤害�?--- */
static uint32_t g_setCap[DDH_MAXDEPTH];            /* 每层**最后一�?* SetEventDamage 设的值（float 位模式） */
static uint32_t g_setSet[DDH_MAXDEPTH];            /* 每层是否设过�? 也是合法 SetEventDamage(0)，不能拿 0 当哨兵） */
static uint32_t g_setCalls[DDH_MAXDEPTH];          /* 每层 SetEventDamage 被调用了几次 */
static volatile LONG g_sedTries = 0;
static volatile LONG g_sedHooked = 0;
static uint32_t g_realSetEventDamage = 0;
/* v20：JASS native 钩子（GetEventDamage / SetEventDamage）默�?*不再安装**�?
   0x67DC40 �?出口三读"已经能同时给�?引擎伤害（出�?info+0x10）�?
   最终伤害（出口 *out）和 净掉血（前后血差），不需要再去遍�?JASS 哈希表�?
   也不用赌 JAPI 在进图前是否就绪（那正是老实现最脆弱的一环）�?
   只有想诊�?地图读了几次、改了几�?时才用环境变量打开�?
       set DDH_NATIVE_DAMAGE_HOOKS=1 */
static int g_nativeHooks = -1;                        /* -1 = 还没读环境变�?*/
static bool NativeDamageHooksOn(void)
{
    if (g_nativeHooks < 0)
    {
        char v[16] = { 0 };
        const DWORD n = GetEnvironmentVariableA("DDH_NATIVE_DAMAGE_HOOKS", v, (DWORD)sizeof(v));
        const char c = (n > 0 && (size_t)n < sizeof(v)) ? v[0] : '\0';
        g_nativeHooks = (c == '1' || c == 'y' || c == 'Y') ? 1 : 0;
    }
    return g_nativeHooks != 0;
}
static LARGE_INTEGER g_qpcFreq;                       /* 伤害函数耗时（诊断用�?*/
static LARGE_INTEGER g_qpcStart[DDH_MAXDEPTH];
static volatile LONG g_hpLogCount = 0;
static bool           g_namesEnabled = true;   /* 查单位名（失败会自动退回类型码�?*/

static int            g_logEnabled = 0;   /* 1 = 写日志（发布包默认关闭，放 ddh_log.on 打开） */
static char           g_logPath[MAX_PATH];

static void LogLine(const char* fmt, ...);

static void LogLine(const char* fmt, ...)
{
    if (!g_logEnabled) return;
    if (g_logPath[0] == 0) return;
    /* 用 CreateFile 显式带 FILE_SHARE_READ|WRITE：外部工具可在游戏运行时读取日志，
       否则 fopen 的独占句柄会让 PowerShell 读不到（之前就是这个问题）。 */
    HANDLE h = CreateFileA(g_logPath, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE,
                           NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h == INVALID_HANDLE_VALUE) return;

    char buf[2048];
    SYSTEMTIME st; GetLocalTime(&st);
    int n = _snprintf_s(buf, sizeof(buf), _TRUNCATE, "[%02d:%02d:%02d.%03d] ",
                        st.wHour, st.wMinute, st.wSecond, st.wMilliseconds);
    if (n < 0) n = 0;
    va_list ap; va_start(ap, fmt);
    int m = _vsnprintf_s(buf + n, sizeof(buf) - n, _TRUNCATE, fmt, ap);
    va_end(ap);
    if (m < 0) m = 0;
    n += m;
    if (n < (int)sizeof(buf) - 2) { buf[n++] = '\r'; buf[n++] = '\n'; }

    DWORD written = 0;
    WriteFile(h, buf, (DWORD)n, &written, NULL);
    CloseHandle(h);
}


/* ---- v13：帧栈压�?/ 退栈（子伤害只扣同一个目标）----
   Push：进入伤害函数、读到前血之后调用；Push 会把该层的帧状态整个重置�?
   Pop ：原函数返回、读到后血之后调用，做三件事：
     �?own = (hpBefore - hpAfter) - childSumSameVictim（只减同目标子帧）；
     �?把本�?gross 加到父帧�?childSumSameVictim�?*仅当父帧 victim == 本帧 victim**�?
     �?返回“本帧是否测到血”（事件 hpValid/actual 用）�?
   fallback 保留旧语义：本帧读不到血时用引擎伤害估一个交给父帧，避免父帧 over-count�?
   它同样只在“父�?victim == 本帧 victim”时才加�?*/
static DdhFrame* DdhFramePush(uint32_t level, uint32_t victim, float hpBefore, uint32_t hpOk)
{
    if (level >= DDH_MAXDEPTH) return NULL;      /* 栈上限保护：绝不越界�?*/
    DdhFrame* f = &g_frames[level];
    f->victim             = victim;
    f->depth              = level + 1;
    f->hpOk               = hpOk ? 1u : 0u;
    f->active             = 1u;
    f->hpBefore           = hpBefore;
    f->hpAfter            = 0.0f;
    f->childSumSameVictim = 0.0f;
    f->childCountSame     = 0;
    return f;
}

static bool DdhFramePop(DdhFrame* f, uint32_t rowOk, float hpAfter, uint32_t hpAfterOk,
                        float fallback, float* outGross, float* outOwn)
{
    float gross = 0.0f, own = 0.0f;
    bool measured = false;

    if (f && f->active && rowOk && f->hpOk && hpAfterOk && f->hpBefore > 0.0f)
    {
        gross = f->hpBefore - hpAfter;             /* 本帧整段掉血（含更深的同目标子帧�?*/
        if (gross < 0.0f) gross = 0.0f;
        own = gross - f->childSumSameVictim;       /* 自己�?= 整段 - 同目标子�?*/
        if (own < 0.0f) own = 0.0f;
        f->hpAfter = hpAfter;
        measured = true;
    }

    /* 报给父帧：正常用整段 gross；本帧读不到血时退回引擎伤害估一个（旧语义）�?
       关键：只有父�?victim 与本帧相同时才扣 —�?多目�?AoE 里打典韦/步兵�?
       子事件不会把张飞（父帧）�?net 扣掉�?*/
    float toParent = measured ? gross : (fallback > 0.0f ? fallback : 0.0f);
    if (f && f->active && f->depth > 1 && toParent > 0.0f)
    {
        DdhFrame* parent = &g_frames[f->depth - 2];
        if (parent->active && parent->victim == f->victim)
        {
            parent->childSumSameVictim += toParent;
            parent->childCountSame++;
        }
    }
    if (f) f->active = 0;

    /* �?3 次“有同目标子伤害”的事件留一行，方便真机核对父帧净掉血 */
    if (measured && f->childCountSame > 0 &&
        InterlockedIncrement(&g_nestedLogCount) <= 3)
    {
        LogLine("嵌套扣减：父=0x%08X 子合计=%.2f（同目标 %u 笔）own=%.2f",
                f->victim, f->childSumSameVictim, f->childCountSame, own);
    }

    if (outGross) *outGross = gross;
    if (outOwn)   *outOwn   = own;
    return measured;
}

/* 读一个单位对象的 4 字符类型码（+0x30 的原�?4 字节）�?
   注意：内存里�?*反序**存的（显示时才翻转），这里保持原样交出去，由外面统一翻转�?*/
static uint32_t SafeCode(uint32_t obj)
{
    if (obj < 0x10000 || obj > 0x7FFFFFFF) return 0;
    __try { return *(const uint32_t*)(uintptr_t)(obj + 0x30); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

static uint32_t SafeU32(uint32_t obj, uint32_t off)
{
    if (obj < 0x10000 || obj > 0x7FFFFFFF) return 0;
    __try { return *(const uint32_t*)(uintptr_t)(obj + off); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

/* ---------------------------------------------------------------------------
   前后血只使用 GetUnitState(handle, UNIT_STATE_LIFE)：
       CUnit* -> handle
       GetUnitState = game.dll + 0x1E6600
       state 0 = 当前生命（float 位模式）
   失败时直接返回 false，不切换到 CUnit 生命表内存链。
   --------------------------------------------------------------------------- */
#define DDH_RVA_CTX_GLOBAL         0x00BE4238u  /* ctx = *(game.dll + RVA) */
#define DDH_RVA_OBJ_TO_HANDLE      0x002651D0u  /* __fastcall(mgr,0,obj,0) -> 句柄 */
#define DDH_RVA_HANDLE_TO_UNIT     0x001D1550u  /* __fastcall(handle,0) -> CUnit* */
#define DDH_RVA_HANDLEMGR_FROM_CTX 0x001C3200u  /* __fastcall(ctx,0) -> 句柄管理�?*/
#define DDH_RVA_GET_UNIT_STATE     0x001E6600u  /* __cdecl(handle,state) -> float bits */
#define DDH_OFF_CTX_HANDLEMGR      0x0000001Cu  /* ctx+0x1C = 句柄管理器指�?*/
#define DDH_OFF_MGR_COUNT          0x00000198u  /* mgr+0x198 = 条目�?3 */
#define DDH_OFF_MGR_TABLE          0x0000019Cu  /* mgr+0x19C = 句柄表基址 */
#define DDH_HANDLE_BASE            0x00100000u
#define DDH_HANDLE_LIMIT           0x00200000u


uint32_t g_modBase = 0;                        /* game.dll 基址（InstallHook 时填�?*/
static uint32_t g_imageSize = 0;               /* game.dll 映像大小（PE SizeOfImage；协�?v13 视野 RVA 校验用） */

/* ---- GetUnitState 读血的定型状态（对齐插件 g_nativeMgrWhich/g_nativeUseMemory�?--- */
static int           g_hpMgrWhich  = -1;   /* -1=未定 0=纯内�?(ctx+0x1C) 1=引擎访问�?x1C3200 2=放弃 */
static int           g_hpUseMemory = 0;    /* 0=调用 0x2651D0 1=纯内存扫描（定型后与口径绑定缓存�?*/
static volatile LONG g_hpObj2HTries = 0;   /* 四种组合都失败的累计次数（最�?16 次） */
static volatile LONG g_hpTypeFailLogged = 0; /* “定型失败”日志只写一�?*/
static volatile LONG g_hpSrcLogCount = 0;  /* “血量来源”日志只写前 3 �?*/


static int PeekU32(uint32_t addr, uint32_t* out);   /* 实现在本文件后面（JASS 哈希那段�?*/

typedef uint32_t (__fastcall* fn_hp_handle_to_unit)(uint32_t handle, void* unused);
typedef uint32_t (__fastcall* fn_hp_obj_to_handle)(uint32_t mgr, void* unused, uint32_t obj, uint32_t unused2);
typedef uint32_t (__fastcall* fn_hp_mgr_from_ctx)(uint32_t ctx, void* unused);
typedef uint32_t (__cdecl*    fn_hp_get_unit_state)(uint32_t handle, uint32_t state);

static uint32_t g_natHandleToUnit = 0;
static uint32_t g_natObjToHandle  = 0;
static uint32_t g_natMgrFromCtx   = 0;
static uint32_t g_natGetUnitState = 0;

/* �?RVA 解析一个引擎函数并做序言校验（可�?+ 非空实现 + 可�?3 字节序言），失败返回 0，由上层按读不到处理 */
static uint32_t HpResolve(uint32_t rva, const uint8_t* pro3)
{
    if (!g_modBase) return 0;
    const uint32_t addr = g_modBase + rva;
    uint32_t head = 0;
    if (!PeekU32(addr, &head)) return 0;
    const uint8_t* p = (const uint8_t*)&head;
    if (p[0] == 0x33 && p[1] == 0xC0 && p[2] == 0xC3) return 0;  /* xor eax,eax; ret 空实�?*/
    if (pro3 && (p[0] != pro3[0] || p[1] != pro3[1] || p[2] != pro3[2])) return 0;
    return addr;
}

static const uint8_t kPro3HandleToUnit[3] = { 0x55, 0x8B, 0xEC };  /* push ebp; mov ebp,esp */
static const uint8_t kPro3ObjToHandle[3]  = { 0x55, 0x8B, 0xEC };
static const uint8_t kPro3MgrFromCtx[3]   = { 0x83, 0x79, 0x1C };  /* cmp dword [ecx+0x1C],0 */
static const uint8_t kPro3GetUnitState[3] = { 0x55, 0x8B, 0xEC };

/* 句柄管理器两种口径：口径0 = 纯内�?*(ctx+0x1C)；口�? = 引擎访问�?0x1C3200(ctx) */
static uint32_t HpMgrFromCtx(uint32_t ctx, int which)
{
    if (!ctx) return 0;
    if (which == 0)
    {
        uint32_t v = 0;
        return PeekU32(ctx + DDH_OFF_CTX_HANDLEMGR, &v) ? v : 0;
    }
    if (!g_natMgrFromCtx)
        g_natMgrFromCtx = HpResolve(DDH_RVA_HANDLEMGR_FROM_CTX, kPro3MgrFromCtx);
    if (!g_natMgrFromCtx) return 0;
    uint32_t mgr = 0;
    __try { mgr = ((fn_hp_mgr_from_ctx)(uintptr_t)g_natMgrFromCtx)(ctx, NULL); }
    __except (EXCEPTION_EXECUTE_HANDLER) { mgr = 0; }
    return mgr;
}

/* JASS Hunit -> CUnit*，回程校验用，__fastcall ecx=handle */
static uint32_t HpHandleToUnit(uint32_t handle)
{
    if (!handle) return 0;
    if (!g_natHandleToUnit)
        g_natHandleToUnit = HpResolve(DDH_RVA_HANDLE_TO_UNIT, kPro3HandleToUnit);
    if (!g_natHandleToUnit) return 0;
    uint32_t obj = 0;
    __try { obj = ((fn_hp_handle_to_unit)(uintptr_t)g_natHandleToUnit)(handle, NULL); }
    __except (EXCEPTION_EXECUTE_HANDLER) { obj = 0; }
    return obj;
}

/* 对象 -> JASS 句柄（调用法，__fastcall ecx=mgr，栈�?obj，与插件同款�?*/
static uint32_t HpObj2HCall(uint32_t mgr, uint32_t obj)
{
    if (!mgr || !obj) return 0;
    if (!g_natObjToHandle)
        g_natObjToHandle = HpResolve(DDH_RVA_OBJ_TO_HANDLE, kPro3ObjToHandle);
    if (!g_natObjToHandle) return 0;
    uint32_t h = 0;
    __try {
        h = ((fn_hp_obj_to_handle)(uintptr_t)g_natObjToHandle)(mgr, NULL, obj, 0);
    } __except (EXCEPTION_EXECUTE_HANDLER) { h = 0; }
    return (h >= DDH_HANDLE_BASE && h < DDH_HANDLE_LIMIT) ? h : 0;
}

/* 对象 -> JASS 句柄（内存扫法，与插�?Wc3Obj2HMem 同款）：
   T=*(mgr+0x19C)，cnt=*(mgr+0x198)，for (i=0,k=0; i<min(cnt,0x9000); i+=3,++k)
   �?*(u32*)(T+4+i*4)==obj �?handle=0x100000+k�?*/
static uint32_t HpObj2HMem(uint32_t mgr, uint32_t obj)
{
    if (!mgr || !obj) return 0;
    uint32_t T = 0, cnt3 = 0;
    if (!PeekU32(mgr + DDH_OFF_MGR_TABLE, &T)) return 0;
    if (!PeekU32(mgr + DDH_OFF_MGR_COUNT, &cnt3)) return 0;
    if (!T || !cnt3 || cnt3 > 0x30000u) return 0;
    const uint32_t limit = (cnt3 < 0x9000u) ? cnt3 : 0x9000u;  /* 伤害回调里别做长扫描 */
    uint32_t h = 0;
    __try {
        for (uint32_t i = 0, k = 0; i < limit; i += 3, ++k)
            if (*(const uint32_t*)(uintptr_t)(T + 4u + i * 4u) == obj) { h = DDH_HANDLE_BASE + k; break; }
    } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return h;
}

/* 对象 -> JASS 句柄（定型入口）：调用法/内存扫法 × 两种管理器口径，四种组合都用
   句柄回程校验�?x1D1550(handle)==obj）挑第一个通过者并定型缓存，之后直接走缓存路线�?
   四种组合都失败：日志写一次，之后仍可重试但最�?16 次，限次后返�?0，由 ReadUnitHp 转内存回退�?*/
static uint32_t HpObjToHandle(uint32_t obj)
{
    if (!obj) return 0;
    if (g_hpMgrWhich == 2) return 0;               /* 已判定用不了，直接返�?0 */
    if (!g_modBase) return 0;

    uint32_t ctx = 0;
    if (!PeekU32(g_modBase + DDH_RVA_CTX_GLOBAL, &ctx) || !ctx) return 0;

    /* 已定型：直接走既定路线（每次伤害只花一次调用，不再做四种尝�?回程校验�?*/
    if (g_hpMgrWhich >= 0)
    {
        const uint32_t mgr = HpMgrFromCtx(ctx, g_hpMgrWhich);
        if (!mgr) return 0;
        uint32_t h = g_hpUseMemory ? HpObj2HMem(mgr, obj) : HpObj2HCall(mgr, obj);
        if (h && HpHandleToUnit(h) == obj) return h;
        /* 定型的路径也可能在句柄表搬动/对象复用时拿到邻近单位：
           回程校验 handle->CUnit 必须等于本次 obj，否则换另一条路径再试，仍不对就返回 0，
           让上层按“没测到”处理，绝不把邻近单位的技能算到本对象头上。 */
        h = g_hpUseMemory ? HpObj2HCall(mgr, obj) : HpObj2HMem(mgr, obj);
        if (h && HpHandleToUnit(h) == obj) return h;
        return 0;
    }

    /* 首次定型：调用法/内存扫法 × 两种管理器口径，全部用句柄回程校验验证后定型 */
    for (int mem = 0; mem <= 1; ++mem)
    {
        for (int which = 0; which <= 1; ++which)
        {
            const uint32_t mgr = HpMgrFromCtx(ctx, which);
            if (!mgr) continue;
            const uint32_t h = mem ? HpObj2HMem(mgr, obj) : HpObj2HCall(mgr, obj);
            if (!h) continue;
            const uint32_t back = HpHandleToUnit(h);
            if (back == obj)
            {
                g_hpUseMemory = mem;
                g_hpMgrWhich  = which;
                LogLine("native obj->handle 定型：路径=%s 管理器口径=%s 首次 obj=%08X -> handle=%08X（回程校验一致）",
                        mem ? "纯内存扫描" : "调用 0x2651D0",
                        which ? "引擎访问�?x1C3200" : "纯内存*(ctx+0x1C)", obj, h);
                return h;
            }
        }
    }

    /* 四种组合都没通过回程校验：日志写一次，之后仍可重试但限次，限次后永久返�?0 */
    if (InterlockedExchange(&g_hpTypeFailLogged, 1) == 0)
        LogLine("native obj->handle 定型失败：四种组合回程校验都没过，后续走内存回退（两条都失败才显示 ?）");
    const LONG tries = InterlockedIncrement(&g_hpObj2HTries);
    if (tries >= 16)
        g_hpMgrWhich = 2;
    return 0;
}

/* GetUnitState: RVA 0x1E6600, state 0 = UNIT_STATE_LIFE. */
static bool HpGetUnitState(uint32_t handle, float* hpOut)
{
    if (!handle) return false;
    if (!g_natGetUnitState)
        g_natGetUnitState = HpResolve(DDH_RVA_GET_UNIT_STATE, kPro3GetUnitState);
    if (!g_natGetUnitState) return false;

    uint32_t bits = 0;
    __try { bits = ((fn_hp_get_unit_state)(uintptr_t)g_natGetUnitState)(handle, 0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }

    float hp = 0.0f;
    memcpy(&hp, &bits, 4);
    if (!(hp > -1.0e6f && hp < 1.0e9f)) return false;
    *hpOut = hp;
    return true;
}
/* 读血入口：只走 GetUnitState(handle, UNIT_STATE_LIFE)；失败直接返回 false（界面显示 ?）。 */
static bool ReadUnitHp(uint32_t unit, float* hpOut)
{
    if (unit < 0x10000 || unit > 0x7FFFFFFF || !hpOut) return false;
    const uint32_t handle = HpObjToHandle(unit);
    if (!handle || !HpGetUnitState(handle, hpOut)) return false;
    if (InterlockedIncrement(&g_hpSrcLogCount) <= 3)
    {
        LogLine("血量来源：GetUnitState unit=0x%08X handle=0x%08X hp=%.3f",
                unit, handle, (double)*hpOut);
    }
    return true;
}
/* ---------------------------------------------------------------------------
   引擎伤害 = 地图第一次调�?GetEventDamage() 的返回值（地图增伤/减伤之前）�?
   做法�?UDamageWatcherHook.cpp 完全一致：遍历 JASS native 函数哈希表，�?
   "GetEventDamage" 节点�?func_address_ 换成我们的函数，先调原实现、再抄返回值�?
     get_instance(5)        = game.dll RVA 0x4EFB0（__fastcall，ecx=index�?
     native 哈希�?         = instance + 0x18，buckets(+0x1C) / mask(+0x24)，每�?12 字节
     节点                   = +0x0C prev_ / +0x04 hash / +0x18 key(名字) / +0x1C func
   只有第一次调用被记录（之后地图可�?SetEventDamage 改过值）�?
   全程 __try 保护；JASS 没就�?找不到节点就什么都不做（界面上显示 ?）�?
--------------------------------------------------------------------------- */
static uint32_t HashRead4(const unsigned char* p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static uint32_t Wc3StringHash(const char* str)
{
    char buf[0x400];
    size_t len = 0;
    while (str[len] != '\0' && len < 0x3FF)
    {
        char c = str[len];
        if (c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
        else if (c == '/') c = '\\';
        buf[len++] = c;
    }
    const unsigned char* p = (const unsigned char*)buf;
    size_t rem = len;
    uint32_t A = 0x9E3779B9u, B = 0x9E3779B9u, C = 0u;
    if (rem >= 12)
    {
        size_t step = rem / 12;
        do
        {
            A += HashRead4(p + 0);
            B += HashRead4(p + 4);
            C += HashRead4(p + 8);
            A = (C >> 13) ^ (A - B - C); B = (A << 8)  ^ (B - C - A); C = (B >> 13) ^ (C - A - B);
            A = (C >> 12) ^ (A - B - C); B = (A << 16) ^ (B - C - A); C = (B >> 5)  ^ (C - A - B);
            A = (C >> 3)  ^ (A - B - C); B = (A << 10) ^ (B - C - A); C = (B >> 15) ^ (C - A - B);
            p += 12; rem -= 12;
        } while (--step != 0);
    }
    C = C + (uint32_t)len;
    switch (rem)
    {
        case 11: C += (uint32_t)p[10] << 24;
        case 10: C += (uint32_t)p[9]  << 16;
        case 9:  C += (uint32_t)p[8]  << 8;
        case 8:  B += (uint32_t)p[7]  << 24;
        case 7:  B += (uint32_t)p[6]  << 16;
        case 6:  B += (uint32_t)p[5]  << 8;
        case 5:  B += (uint32_t)p[4];
        case 4:  A += (uint32_t)p[3]  << 24;
        case 3:  A += (uint32_t)p[2]  << 16;
        case 2:  A += (uint32_t)p[1]  << 8;
        case 1:  A += (uint32_t)p[0];
            break;
        default: break;
    }
    A = (C >> 13) ^ (A - B - C); B = (A << 8)  ^ (B - C - A); C = (B >> 13) ^ (C - A - B);
    A = (C >> 12) ^ (A - B - C); B = (A << 16) ^ (B - C - A); C = (B >> 5)  ^ (C - A - B);
    A = (C >> 3)  ^ (A - B - C); B = (A << 10) ^ (B - C - A); C = (B >> 15) ^ (C - A - B);
    return C;
}

static int PeekU32(uint32_t addr, uint32_t* out)
{
    if (addr < 0x10000) return 0;
    __try { *out = *(const uint32_t*)(uintptr_t)addr; return 1; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
}

static uint32_t __cdecl OurFakeGetEventDamage(void);

/* 读当前地图名：ctx->mapInfo+4 的 CString -> 字符指针。
   只在 ddh 写库线程调用，不碰伤害钩子。 */
static bool DdhReadMapName(char* out, size_t cap)
{
    if (!out || cap < 2 || !g_modBase) return false;
    out[0] = 0;
    uint32_t ctx = 0, mapInfo = 0, data = 0, chars = 0;
    if (!PeekU32(g_modBase + 0x00BE4238u, &ctx) || !ctx) return false;
    if (!PeekU32(ctx + 0x30u, &mapInfo) || !mapInfo) return false;
    const uint32_t cstr = mapInfo + 4u;
    if (!PeekU32(cstr + 8u, &data) || !data) return false;
    if (!PeekU32(data + 0x1Cu, &chars) || !chars)
    {
        /* CString 相邻布局兜底 */
        static const uint32_t offs[4] = { 8u, 0u, 4u, 12u };
        for (int i = 0; i < 4; i++)
            if (PeekU32(data + offs[i], &chars) && chars) break;
    }
    if (!chars) return false;

    char raw[260] = { 0 };
    SIZE_T got = 0;
    if (!ReadProcessMemory(GetCurrentProcess(), (LPCVOID)(uintptr_t)chars, raw, sizeof(raw) - 1, &got) || got < 2)
        return false;
    raw[sizeof(raw) - 1] = 0;
    int len = 0;
    while (len < (int)got && raw[len] && len < 200) len++;
    if (len < 2) return false;

    wchar_t wide[260] = { 0 };
    /* 引擎里有的版本给 UTF-8，有的给 GBK：先按 UTF-8 严格校验，能过就原样用。 */
    bool utf8 = true;
    for (int i = 0; i < len; )
    {
        unsigned char c = (unsigned char)raw[i];
        int need = c < 0x80 ? 0 : (c & 0xE0) == 0xC0 ? 1 : (c & 0xF0) == 0xE0 ? 2 : (c & 0xF8) == 0xF0 ? 3 : -1;
        if (need < 0 || i + need >= len) { utf8 = false; break; }
        for (int k = 1; k <= need; k++)
            if (((unsigned char)raw[i + k] & 0xC0) != 0x80) { utf8 = false; break; }
        if (!utf8) break;
        i += need + 1;
    }
    if (utf8)
    {
        size_t n = (size_t)len < cap - 1 ? (size_t)len : cap - 1;
        memcpy(out, raw, n);
        out[n] = 0;
        return n >= 2;
    }

    int wlen = MultiByteToWideChar(936, 0, raw, len, wide, 259);
    if (wlen <= 0) wlen = MultiByteToWideChar(CP_UTF8, 0, raw, len, wide, 259);
    if (wlen <= 0) return false;
    wide[wlen] = 0;
    int n = WideCharToMultiByte(CP_UTF8, 0, wide, wlen, out, (int)cap - 1, NULL, NULL);
    if (n <= 0) return false;
    out[n] = 0;
    return true;
}

/* 地图每次�?GetEventDamage：先拿引擎真值，再抄一份（只抄第一次） */
static uint32_t __cdecl OurFakeGetEventDamage(void)
{
    uint32_t r = 0;
    if (g_realGetEventDamage)
    {
        __try { r = ((uint32_t (__cdecl*)(void))(uintptr_t)g_realGetEventDamage)(); }
        __except (EXCEPTION_EXECUTE_HANDLER) { r = 0; }
    }
    const LONG d = g_depth;                       /* 1 �?*/
    if (d >= 1 && d <= DDH_MAXDEPTH)
    {
        float f;
        memcpy(&f, &r, 4);
        if (f > -1.0e12f && f < 1.0e12f)
        {
            if (!g_engineFirstSet[d - 1]) { g_engineCap[d - 1] = r; g_engineFirstSet[d - 1] = 1; }  /* 首次 = 增伤�?*/
            g_engineLast[d - 1] = r;                                                               /* 末次 = 地图改完之后 */
            InterlockedIncrement((volatile LONG*)&g_engineCalls[d - 1]);
        }
    }
    return r;
}

/* 懒安装：每次伤害事件试一次，最�?64 次（进图�?JASS 实例可能还没好） */
static void TryHookGetEventDamage(void)
{
    if (g_gedHooked) return;
    if (InterlockedIncrement(&g_gedTries) > 16) return;      /* 进图�?VM 可能没好；试 16 次就放弃 */
    if (!g_modBase) return;

    __try
    {
        typedef uint32_t (__fastcall* fn_gi_t)(uint32_t);
        uint32_t inst = ((fn_gi_t)(uintptr_t)(g_modBase + 0x004EFB0u))(5);
        if (inst < 0x10000) return;

        const uint32_t tbl = inst + 0x18u;
        uint32_t buckets = 0, mask = 0;
        if (!PeekU32(tbl + 0x1Cu, &buckets) || !PeekU32(tbl + 0x24u, &mask)) return;
        if (!buckets || mask == 0xFFFFFFFFu) return;

        const uint32_t hash = Wc3StringHash("GetEventDamage");
        const uint32_t entry = buckets + (hash & mask) * 12u;
        uint32_t node = 0;
        if (!PeekU32(entry + 8u, &node)) return;

        int guard = 0;
        while (node > 0x10000u && guard++ < 64)
        {
            uint32_t h = 0, key = 0;
            PeekU32(node + 0x04u, &h);
            PeekU32(node + 0x18u, &key);
            if (h == hash && key > 0x10000u && key < 0x7FFFFFFFu)
            {
                char name[64] = { 0 };
                __try
                {
                    for (int i = 0; i < 63; i++) { name[i] = *(const char*)(uintptr_t)(key + i); if (!name[i]) break; }
                }
                __except (EXCEPTION_EXECUTE_HANDLER) { name[0] = 0; }

                if (_stricmp(name, "GetEventDamage") == 0)
                {
                    uint32_t cur = 0;
                    if (!PeekU32(node + 0x1Cu, &cur)) return;
                    if (cur == (uint32_t)(uintptr_t)&OurFakeGetEventDamage) { g_gedHooked = 1; return; }
                    g_realGetEventDamage = cur;
                    uint32_t* func = (uint32_t*)(uintptr_t)(node + 0x1Cu);
                    DWORD oldProt = 0;
                    if (VirtualProtect(func, 4, PAGE_READWRITE, &oldProt))
                    {
                        *func = (uint32_t)(uintptr_t)&OurFakeGetEventDamage;
                        VirtualProtect(func, 4, oldProt, &oldProt);
                        g_gedHooked = 1;
                        LogLine("引擎伤害采集：GetEventDamage 钩子已挂（节点 %08X，原实现 %08X）", node, cur);
                    }
                    else LogLine("引擎伤害采集：VirtualProtect 失败 err=%lu", GetLastError());
                    return;
                }
            }
            uint32_t prev = 0;
            if (!PeekU32(node + 0x0Cu, &prev)) return;
            node = prev;
        }
        LogLine("引擎伤害采集：没找到 GetEventDamage 节点（hash=%08X mask=%08X buckets=%08X）", hash, mask, buckets);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        /* JASS 还没就绪�?get_instance 会踩�?—�?只记�?3 次，别刷�?*/
        if (g_gedTries <= 3) LogLine("引擎伤害采集：装钩子时异常 code=%08X", GetExceptionCode());
    }
}

/* ---------------------------------------------------------------------------
   地图伤害 = SetEventDamage 最后一次设置的值�?
   做法�?GetEventDamage 完全一致：遍历 JASS native 哈希表，�?"SetEventDamage"
   节点�?func_address_�?0x1C）换成我们的函数，先抄参数、再原样调原实现�?
   调用约定（依据仓库《无JAPI后端实装说明.md》�?.2 与《伤害监视说�?md》�? 实测）：
     魔兽 native �?real 参数 = **指向 float 的指�?*（JASS VM 传它自己 real 槽的地址），
     不是 float 位模式本�?—�?DisplayTimedTextToPlayer �?x/y/dur 反汇编里都是
     `mov eax,[ebp+0xC] ; movss xmm,[eax]`（先取指针、再解引用）�?
     GetEventDamage 无参数、返回值才�?float 位模式（eax 直传），二者不要混�?
     所�?SetEventDamage 的签名是 void __cdecl (float*)，实�?= 指向 4 字节 float 的指针�?
     全部 __try 保护；JASS 没就�?找不到节点就什么都不做（优雅退化）�?
---------------------------------------------------------------------------- */
static void __cdecl OurFakeSetEventDamage(float* damage);

static void __cdecl OurFakeSetEventDamage(float* damage)
{
    /* 先记录（只记本层、只记合理值），再原样调原函数 —�?绝不吞掉调用 */
    const LONG d = g_depth;                       /* 1 �?*/
    if (d >= 1 && d <= DDH_MAXDEPTH && damage)
    {
        float v = 0.0f;
        int ok = 0;
        __try { v = *damage; ok = 1; }
        __except (EXCEPTION_EXECUTE_HANDLER) { ok = 0; }
        if (ok && v > -1.0e12f && v < 1.0e12f)
        {
            const uint32_t lv = (uint32_t)(d - 1);

            /* �?SetEventDamage、从�?GetEventDamage 的图（Dota 就是这种）：
               在地�?*第一�?*改伤害之前，先把“引擎值”抄下来 —�?此刻还在事件里、值还没被改，
               GetEventDamage 拿到的就是“地图若读会读到的首值”。抄到之后照常让地图改�?
               这里不增�?g_engineCalls（取次仍如实反映“地图没读过”）�?*/
            if (!g_engineFirstSet[lv] && g_realGetEventDamage)
            {
                uint32_t r0 = 0;
                __try { r0 = ((uint32_t (__cdecl*)(void))(uintptr_t)g_realGetEventDamage)(); }
                __except (EXCEPTION_EXECUTE_HANDLER) { r0 = 0; }

                float f0 = 0.0f;
                memcpy(&f0, &r0, 4);
                if (f0 > 0.005f && f0 < 1.0e9f)      /* 0 多半是“还没算/拿不到”，别拿它冒�?*/
                {
                    g_engineCap[lv]      = r0;
                    g_engineFirstSet[lv] = 1;
                }
            }

            uint32_t bits = 0;
            memcpy(&bits, &v, 4);
            g_setCap[d - 1] = bits;                                        /* 末次 = 地图最后改成的�?*/
            g_setSet[d - 1] = 1;                                           /* 0 也是合法值，用独立标�?*/
            InterlockedIncrement((volatile LONG*)&g_setCalls[d - 1]);
        }
    }
    if (g_realSetEventDamage)
    {
        __try { ((void (__cdecl*)(float*))(uintptr_t)g_realSetEventDamage)(damage); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
    }
}

/* 懒安装：每次伤害事件试一次，最�?16 次（进图�?JASS 实例可能还没好） */
static void TryHookSetEventDamage(void)
{
    if (g_sedHooked) return;
    const LONG sedTries = InterlockedIncrement(&g_sedTries);
    if (sedTries > 64)      /* 进图�?VM 可能没好；给�?64 次，且失败原因要看得�?*/
    {
        if (sedTries == 65)
            LogLine("引擎伤害采集：SetEventDamage 放弃安装（试了 64 次都没成功；失败原因见上面 SetEventDamage 安装失败 行）");
        return;
    }
    if (!g_modBase) return;

    __try
    {
        typedef uint32_t (__fastcall* fn_gi_t)(uint32_t);
        uint32_t inst = ((fn_gi_t)(uintptr_t)(g_modBase + 0x004EFB0u))(5);
        if (inst < 0x10000)
        {
            if (sedTries <= 3)
                LogLine("引擎伤害采集：SetEventDamage 安装失败（JASS 实例还没好 inst=%08X，第 %d 次）", inst, (int)sedTries);
            return;
        }

        const uint32_t tbl = inst + 0x18u;
        uint32_t buckets = 0, mask = 0;
        if (!PeekU32(tbl + 0x1Cu, &buckets) || !PeekU32(tbl + 0x24u, &mask))
        {
            if (sedTries <= 3)
                LogLine("引擎伤害采集：SetEventDamage 安装失败（native 表读不到 tbl=%08X，第 %d 次）", tbl, (int)sedTries);
            return;
        }
        if (!buckets || mask == 0xFFFFFFFFu)
        {
            if (sedTries <= 3)
                LogLine("引擎伤害采集：SetEventDamage 安装失败（buckets=%08X mask=%08X，第 %d 次）", buckets, mask, (int)sedTries);
            return;
        }

        const uint32_t hash = Wc3StringHash("SetEventDamage");
        const uint32_t entry = buckets + (hash & mask) * 12u;
        uint32_t node = 0;
        if (!PeekU32(entry + 8u, &node)) return;

        int guard = 0;
        while (node > 0x10000u && guard++ < 64)
        {
            uint32_t h = 0, key = 0;
            PeekU32(node + 0x04u, &h);
            PeekU32(node + 0x18u, &key);
            if (h == hash && key > 0x10000u && key < 0x7FFFFFFFu)
            {
                char name[64] = { 0 };
                __try
                {
                    for (int i = 0; i < 63; i++) { name[i] = *(const char*)(uintptr_t)(key + i); if (!name[i]) break; }
                }
                __except (EXCEPTION_EXECUTE_HANDLER) { name[0] = 0; }

                if (_stricmp(name, "SetEventDamage") == 0)
                {
                    uint32_t cur = 0;
                    if (!PeekU32(node + 0x1Cu, &cur)) return;
                    if (cur == (uint32_t)(uintptr_t)&OurFakeSetEventDamage) { g_sedHooked = 1; return; }
                    g_realSetEventDamage = cur;
                    uint32_t* func = (uint32_t*)(uintptr_t)(node + 0x1Cu);
                    DWORD oldProt = 0;
                    if (VirtualProtect(func, 4, PAGE_READWRITE, &oldProt))
                    {
                        *func = (uint32_t)(uintptr_t)&OurFakeSetEventDamage;
                        VirtualProtect(func, 4, oldProt, &oldProt);
                        g_sedHooked = 1;
                        LogLine("引擎伤害采集：SetEventDamage 钩子已挂（节点 %08X，原实现 %08X）", node, cur);
                    }
                    else LogLine("引擎伤害采集：VirtualProtect(SetEventDamage) 失败 err=%lu", GetLastError());
                    return;
                }
            }
            uint32_t prev = 0;
            if (!PeekU32(node + 0x0Cu, &prev)) return;
            node = prev;
        }
        LogLine("引擎伤害采集：没找到 SetEventDamage 节点（hash=%08X mask=%08X buckets=%08X）", hash, mask, buckets);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        /* JASS 还没就绪�?get_instance 会踩�?—�?只记�?3 次，别刷�?*/
        if (g_sedTries <= 3) LogLine("引擎伤害采集：SetEventDamage 装钩子时异常 code=%08X", GetExceptionCode());
    }
}

static int DdhIsHeroCode(uint32_t code);
static int DdhIsHeroCode(uint32_t code)
{
    if (!code) return 0;
    const char c = (char)((code >> 24) & 0xFF);
    return (c >= 'A' && c <= 'Z') ? 1 : 0;
}

/* ---- 真正的“记录一次伤害�?--- */
/* ---------------------------------------------------------------------------
   单位名解析（在游戏进程里直接问引擎要，不依赖任何插件）�?
   两级降级链，全部 __try、失败静默退下一级：
     �?主路�?x326BA0(code, 0) 直接返回【名字正�?char*】（插件 UDamageWatcherHook.cpp 实测结论），
        用插件同款校验（可读�? 结尾、无控制字符/0x7F、长�?1..63）；
     �?次选：JASS native GetUnitName（FindNativeFunc 动态定位，�?RVA 0x1E6340）—�?
        它内部就�?call 0x326BA0 再转【字符串 id】，返回值是 id 不是 char*�?
        本机反查不通，所以只留返回值做诊断、不再当 char* 读；
     �?都拿不到就退�?4 字符类型码（C# 端退回码）�?
   结果�?类型码→名字 缓存（每个码只解析一次）；失败也只记一次日志，别刷屏�?
--------------------------------------------------------------------------- */
struct NameCacheEntry { uint32_t code; char name[64]; };
static NameCacheEntry g_nameCache[128];
static int  g_nameCacheCount = 0;
static volatile LONG g_nameFailLogged = 0;    /* “名字解析失败”日志总上限，防刷�?*/

/* GetUnitName native 函数地址的懒解析缓存（最多找 16 次，进图�?JASS VM 可能没好�?*/
typedef const char* (__fastcall *fn_326BA0)(uint32_t code, uint32_t edxZero);

/* �?JASS native 哈希表里按名字找函数地址（与 TryHookGetEventDamage 同一套遍历）�?
   返回 0 表示没找�?没就绪。全�?__try 包着�?*/
static uint32_t FindNativeFunc(const char* name)
{
    if (!name || !g_modBase) return 0;
    uint32_t fn = 0;
    __try
    {
        typedef uint32_t (__fastcall* fn_gi_t)(uint32_t);
        uint32_t inst = ((fn_gi_t)(uintptr_t)(g_modBase + 0x004EFB0u))(5);
        if (inst < 0x10000) return 0;

        const uint32_t tbl = inst + 0x18u;
        uint32_t buckets = 0, mask = 0;
        if (!PeekU32(tbl + 0x1Cu, &buckets) || !PeekU32(tbl + 0x24u, &mask)) return 0;
        if (!buckets || mask == 0xFFFFFFFFu) return 0;

        const uint32_t hash = Wc3StringHash(name);
        const uint32_t entry = buckets + (hash & mask) * 12u;
        uint32_t node = 0;
        if (!PeekU32(entry + 8u, &node)) return 0;

        int guard = 0;
        while (node > 0x10000u && guard++ < 64)
        {
            uint32_t h = 0, key = 0;
            PeekU32(node + 0x04u, &h);
            PeekU32(node + 0x18u, &key);
            if (h == hash && key > 0x10000u && key < 0x7FFFFFFFu)
            {
                char nm[64] = { 0 };
                __try
                {
                    for (int i = 0; i < 63; i++) { nm[i] = *(const char*)(uintptr_t)(key + i); if (!nm[i]) break; }
                }
                __except (EXCEPTION_EXECUTE_HANDLER) { nm[0] = 0; }

                if (_stricmp(nm, name) == 0)
                {
                    uint32_t cur = 0;
                    if (PeekU32(node + 0x1Cu, &cur)) fn = cur;
                    return fn;
                }
            }
            uint32_t prev = 0;
            if (!PeekU32(node + 0x0Cu, &prev)) return 0;
            node = prev;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { fn = 0; }
    return fn;
}

/* 0x326BA0�? 字符�?-> 名字正文 char*（插�?UDamageWatcherHook.cpp L1123-1175 实测结论）�?
   序言 56 8B F2 = push esi; mov esi,edx。真 game.dll 0x326BA0 = 56 8B F2 BA F8 AC 98 6F ... */
/* GetUnitAbilityLevel native：按名字�?JASS native 表里找（�?GetUnitName 同一�?FindNativeFunc）�?
   最多找 16 次（进图�?JASS VM 可能没好）；找到记一条，16 次后还没找到也只记一条�?*/
/* 直接按逆向结果查技能等级：
   game.dll RVA 0x46F440 = 单位对象上的“按 ID 找技能”，返回技能对象；等级在 +0x50（0 基）。
   不经过 handle，避免 GetUnitAbilityLevel 前两道校验失败。 */
static int DdhAbilityLevelByObj(uint32_t obj, uint32_t abilityId)
{
    HMODULE gd = GetModuleHandleA("game.dll");
    if (!gd) gd = GetModuleHandleA("Game.dll");
    if (!gd || !obj) return -1;
    const uint32_t fn = (uint32_t)(uintptr_t)gd + 0x46F440u;
    typedef void* (__fastcall *fn_find_ability_t)(void* thisPtr, void* dummy, uint32_t id, int a3, int a4, int a5, int a6);
    void* abil = NULL;
    __try { abil = ((fn_find_ability_t)(uintptr_t)fn)((void*)(uintptr_t)obj, NULL, abilityId, 0, 1, 1, 1); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return -1; }
    if (!abil) return 0;
    int level = 0;
    __try { level = *(const int*)((const char*)abil + 0x50) + 1; }
    __except (EXCEPTION_EXECUTE_HANDLER) { return -1; }
    return level;
}

/* Resolve CUnit+0x1DC and follow ability-node+0x24.
   Ability ID is stored at node+0x34. Returns 1=found, 0=not found, -1=failed. */
static int DdhAbilityInUnitList(uint32_t obj, uint32_t abilityId)
{
    if (!g_modBase || g_imageSize <= 0x00044150u) return -1;
    if (obj < 0x10000u || obj > 0x7FFFFFFFu) return -1;

    typedef uint32_t (__fastcall* fn_resolve_ref_t)(const uint32_t*, uint32_t);
    const fn_resolve_ref_t resolve =
        (fn_resolve_ref_t)(uintptr_t)(g_modBase + 0x00044150u);
    const uint32_t swapped =
        ((abilityId & 0x000000FFu) << 24) |
        ((abilityId & 0x0000FF00u) << 8) |
        ((abilityId & 0x00FF0000u) >> 8) |
        ((abilityId & 0xFF000000u) >> 24);

    __try
    {
        uint32_t node = resolve((const uint32_t*)(uintptr_t)(obj + 0x1DCu), 0);
        for (int i = 0; i < 512 && node; ++i)
        {
            if (node < 0x10000u || node > 0x7FFFFFFFu) return -1;
            const uint32_t id = *(const uint32_t*)(uintptr_t)(node + 0x34u);
            if (id == abilityId || id == swapped) return 1;

            const uint32_t next =
                resolve((const uint32_t*)(uintptr_t)(node + 0x24u), 0);
            if (next == node) break;
            node = next;
        }
        return 0;
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        return -1;
    }
}

/* IsUnitIllusion reads bit 30 of CUnit+0x5C. Return 1/0, or -1 if unreadable. */
static int DdhUnitIllusionStateByObj(uint32_t obj)
{
    if (obj < 0x10000u || obj > 0x7FFFFFFFu) return -1;
    uint32_t flags = 0;
    __try { flags = *(const uint32_t*)(uintptr_t)(obj + 0x5Cu); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return -1; }
    return (flags & 0x40000000u) ? 1 : 0;
}


/* 通过 ydbase 的 jass_func(name) 拿 func_value*，再取 +0x10（ydbase 反编译结论）得到真函数地址。
   ydbase 没加载时返回 0。 */
/* 一次性探针：Game.dll 是否导出 WAR3API_GetTypeMemoryAddressByTypeId（平台插件就是调它取类型对象）。 */
/* War3Trainer 的选区链：module+BE4238 → unitList → a2 → player → +0x34 selection → +0x1F0 链表 → +8 单位指针 */
static uint32_t DdhSelectedUnitPtr(void)
{
    uint32_t list = 0, player = 0, sel = 0, head = 0;
    __try { list = *(const uint32_t*)(uintptr_t)(g_modBase + 0xBE4238u); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    if (list < 0x10000u) return 0;
    uint16_t a2 = 0;
    __try { a2 = *(const uint16_t*)(uintptr_t)(list + 0x28); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    __try { player = *(const uint32_t*)(uintptr_t)(list + 0x58 + 4u * a2); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    if (player < 0x10000u) return 0;
    __try { sel = *(const uint32_t*)(uintptr_t)(player + 0x34); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    if (sel < 0x10000u) return 0;
    __try { head = *(const uint32_t*)(uintptr_t)(sel + 0x1F0); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    if (head < 0x10000u) return 0;
    uint32_t unit = 0;
    __try { unit = *(const uint32_t*)(uintptr_t)(head + 8); } __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return unit;
}

/* 'Aloc'（蝗虫技能）�?dword：字�?A,l,o,c = 0x41 0x6C 0x6F 0x63�?
   内存按小端存�?dword 0x636F6C41。GetUnitAbilityLevel(handle, 0x636F6C41) > 0 = 马甲�?
   判定口径�?YDWE 一致（YDWE-master/Development/Component/ui/ydwe/jass/YDWETriggerEvent.j:47�?
   GetUnitAbilityLevel(GetFilterUnit(), 'Aloc') <= 0 是普通单位，> 0 才是马甲/蝗虫单位）�?
   只按技能判定，不按名字/类型码写死�?*/
#define DDH_ABILITY_ALOC   0x636F6C41u

static const char* DdhCodeText(uint32_t code)
{
    static char buf[8];
    buf[0] = (char)((code >> 24) & 0xFF);
    buf[1] = (char)((code >> 16) & 0xFF);
    buf[2] = (char)((code >> 8) & 0xFF);
    buf[3] = (char)(code & 0xFF);
    buf[4] = 0;
    for (int i = 0; i < 4; ++i) if (buf[i] < 32 || buf[i] > 126) buf[i] = '?';
    return buf;
}

/* 内存扫 Aloc：单位结构里技能项含 4 字节技能码，找到 0x636F6C41 即蝗虫。
   不依赖 JASS native（实测 native 调不出结果），也不依赖类型数据字段名。 */
/* 判断一个 dword 是不是 Aloc 的两种字节序 */
static bool DdhIsAlocDword(uint32_t v) { return v == 0x636F6C41u || v == 0x416C6F63u; }

/* 在 [base, base+len) 里找 Aloc（4 字节步长）。返回偏移，找不到返回 -1。 */
static int32_t DdhScanAloc(uint32_t base, uint32_t len, uint32_t* reads)
{
    if (!base || base < 0x10000 || base > 0x7FFFFFFF) return -1;
    for (uint32_t off = 0; off < len; off += 4)
    {
        uint32_t v = 0;
        __try { v = *(const uint32_t*)(uintptr_t)(base + off); }
        __except (EXCEPTION_EXECUTE_HANDLER) { return -1; }
        if (reads) ++*reads;
        if (DdhIsAlocDword(v)) return (int32_t)off;
    }
    return -1;
}

/* 全方位找 Aloc：本体 0x8000 → 一级指针子块 0x2000 → 二级指针子块 0x1000，
   外加 ASCII "Aloc"。返回 true 并给出从哪里命中（path 文本），不依赖 native/类型数据。 */
static bool DdhReadF32(uint32_t addr, float* out)
{
    if (!out) return false;
    float v = 0.0f;
    __try { v = *(const float*)(uintptr_t)addr; } __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
    if (!(v == v) || v > 1e9f || v < -1e9f) return false;
    *out = v;
    return true;
}

static bool DdhMemHasAlocDeep(uint32_t obj, char* path, size_t cap, uint32_t* readsOut)
{
    if (path && cap) path[0] = 0;
    uint32_t reads = 0;
    if (!obj || obj < 0x10000 || obj > 0x7FFFFFFF) return false;

    int32_t off = DdhScanAloc(obj, 0x8000, &reads);
    if (off >= 0)
    {
        if (path && cap) _snprintf_s(path, cap, _TRUNCATE, "本体+0x%X", (unsigned)off);
        if (readsOut) *readsOut = reads;
        return true;
    }

    /* 一级指针 */
    uint32_t firstPt[64]; int firstCount = 0;
    for (uint32_t o = 0; o < 0x800 && firstCount < 64; o += 4)
    {
        uint32_t p = 0;
        __try { p = *(const uint32_t*)(uintptr_t)(obj + o); }
        __except (EXCEPTION_EXECUTE_HANDLER) { break; }
        if (p < 0x10000 || p > 0x7FFFFFFF || p == obj) continue;
        firstPt[firstCount++] = p;
    }
    for (int i = 0; i < firstCount; ++i)
    {
        int32_t o2 = DdhScanAloc(firstPt[i], 0x2000, &reads);
        if (o2 >= 0)
        {
            if (path && cap) _snprintf_s(path, cap, _TRUNCATE, "ptr[%d]->+0x%X", i, (unsigned)o2);
            if (readsOut) *readsOut = reads;
            return true;
        }
    }

    /* 二级指针（技能链表：节点->next） */
    for (int i = 0; i < firstCount; ++i)
    {
        for (uint32_t o = 0; o < 0x200; o += 4)
        {
            uint32_t q = 0;
            __try { q = *(const uint32_t*)(uintptr_t)(firstPt[i] + o); }
            __except (EXCEPTION_EXECUTE_HANDLER) { break; }
            if (q < 0x10000 || q > 0x7FFFFFFF) continue;
            int32_t o3 = DdhScanAloc(q, 0x1000, &reads);
            if (o3 >= 0)
            {
                if (path && cap) _snprintf_s(path, cap, _TRUNCATE, "ptr[%d]->[+0x%X]->+0x%X", i, (unsigned)o, (unsigned)o3);
                if (readsOut) *readsOut = reads;
                return true;
            }
        }
    }

    if (readsOut) *readsOut = reads;
    return false;
}






/* 蝗虫判定诊断日志限流：前 5 次无条件写（�?level<=0 / handle==0）�?*/
static volatile LONG g_locustLogCount = 0;

/* ---- v21：蝗虫类型码缓存 ----
   句柄拿不到（尸体 / 刚创�?/ 句柄表暂时失效）时无法调 GetUnitAbilityLevel�?
   但同一类型码只要有任何一只被实测�?Aloc，就整类按蝗虫处�?—�?C# 的【战场单位】用它过滤�?
   只缓存类型码（不按名�?地址写死），口径仍是 Aloc�?*/
static uint32_t      g_alocCodes[256];
static volatile LONG g_alocCodeCount = 0;

static bool DdhAlocCodeKnown(uint32_t code)
{
    const LONG n = g_alocCodeCount;
    for (LONG i = 0; i < n && i < 256; i++)
        if (g_alocCodes[i] == code) return true;
    return false;
}

static void DdhAlocCodeRemember(uint32_t code)
{
    if (!code || DdhAlocCodeKnown(code)) return;
    const LONG idx = InterlockedIncrement(&g_alocCodeCount) - 1;
    if (idx < 256) g_alocCodes[idx] = code;
}

/* DdhCodeText 定义在后面（类型�?-> 可读文本）；RecordDamage 里先用，补前置声明�?*/
static void DdhCodeText(uint32_t code, char* out, size_t cap);

/* ---- 单位所属玩家号：CUnit+0x58 直接保存 0 基玩家槽位。
   GetOwningPlayer 的 vtable+0xEC 实现也是 mov eax,[ecx+0x58]。 ---- */
static uint32_t g_natGetPlayerId = 0;
static volatile LONG g_gpidTries = 0;

static volatile LONG g_ownerLogCount = 0;

static uint32_t GetPlayerIdNative(void)
{
    if (g_natGetPlayerId) return g_natGetPlayerId;
    if (InterlockedIncrement(&g_gpidTries) > 16) return 0;
    g_natGetPlayerId = FindNativeFunc("GetPlayerId");
    if (g_natGetPlayerId)
        LogLine("v8：GetPlayerId native 已定位 0x%08X", g_natGetPlayerId);
    return g_natGetPlayerId;
}

/* obj(CUnit*) -> owner slot (0-based), no handle/JASS/fallback. */
static int32_t ResolveOwnerPid(uint32_t obj)
{
    if (obj < 0x10000 || obj > 0x7FFFFFFF) return -1;
    uint32_t owner = 0;
    __try { owner = *(const uint32_t*)(uintptr_t)(obj + 0x58u); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return -1; }
    return owner < 24u ? (int32_t)owner : -1;
}

/* ---- v21：玩家结盟掩码（本地玩家视角�?---
   �?i �?= 玩家 i�? 基）是否与本地玩家结盟（含本地玩家自己）�?
   JASS 原生：GetLocalPlayer() / Player(index) / IsPlayerAlly(a,b)，都�?__cdecl�?
   只在游戏线程（属性填�?/ 伤害钩子）调用；整局只算成功一次，失败最多重�?64 次�?
   写进 hdr.reserved[1]，C# 只在 hdr.version >= 21 时读�?*/
static uint32_t      g_allyMask = 0;
static int           g_localPlayerId = -1;   /* v27：GetPlayerId(GetLocalPlayer())，给 C# 用 */
static volatile LONG g_allyMaskTries = 0;
static volatile LONG g_allyMaskDone = 0;
static uint32_t      g_natPlayer = 0;
static uint32_t      g_natLocalPlayer = 0;
static uint32_t      g_natIsPlayerAlly = 0;

static uint32_t DdhPlayerNative(void)
{
    if (!g_natPlayer) g_natPlayer = FindNativeFunc("Player");
    return g_natPlayer;
}
static uint32_t DdhLocalPlayerNative(void)
{
    if (!g_natLocalPlayer) g_natLocalPlayer = FindNativeFunc("GetLocalPlayer");
    return g_natLocalPlayer;
}
static uint32_t DdhIsPlayerAllyNative(void)
{
    if (!g_natIsPlayerAlly) g_natIsPlayerAlly = FindNativeFunc("IsPlayerAlly");
    return g_natIsPlayerAlly;
}

static void DdhComputeAllyMask(void)
{
    if (g_allyMaskDone || !g_shm) return;
    if (InterlockedIncrement(&g_allyMaskTries) > 64) return;

    const uint32_t fnPlayer = DdhPlayerNative();
    const uint32_t fnLocal = DdhLocalPlayerNative();
    const uint32_t fnAlly = DdhIsPlayerAllyNative();
    if (!fnPlayer || !fnLocal) return;

    uint32_t local = 0;
    __try { local = ((uint32_t (__cdecl*)(void))(uintptr_t)fnLocal)(); }
    __except (EXCEPTION_EXECUTE_HANDLER) { local = 0; }
    if (!local) return;

    /* 先解析本地玩家号：即使 IsPlayerAlly 不可用，也要把真实玩家号给 C#。
       这个函数只在游戏线程（属性填充）调用，不在伤害钩子里调 JASS。 */
    uint32_t localId = 0xFFFFFFFFu;
    const uint32_t gpid = GetPlayerIdNative();
    if (gpid)
    {
        __try { localId = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)gpid)(local); }
        __except (EXCEPTION_EXECUTE_HANDLER) { localId = 0xFFFFFFFFu; }
        if (localId < 24)
        {
            g_localPlayerId = (int)localId;
            g_shm->hdr.reserved[3] = localId + 1u;
        }
    }
    if (!fnAlly)
    {
        LogLine("v27：本地玩家 = %d（IsPlayerAlly 不可用，暂不算结盟掩码）", g_localPlayerId);
        return;
    }

    uint32_t mask = 0;
    for (int i = 0; i < 24; i++)
    {
        uint32_t h = 0;
        __try { h = ((uint32_t (__cdecl*)(int))(uintptr_t)fnPlayer)(i); }
        __except (EXCEPTION_EXECUTE_HANDLER) { h = 0; }
        if (!h) continue;
        int ally = 0;
        __try { ally = ((int (__cdecl*)(uint32_t, uint32_t))(uintptr_t)fnAlly)(local, h); }
        __except (EXCEPTION_EXECUTE_HANDLER) { ally = 0; }
        if (ally) mask |= (1u << i);
    }

    /* 本地玩家自己那一位置 1（有些地�?IsPlayerAlly(p,p) 返回 false�?*/
    if (localId < 24) mask |= (1u << (int)localId);

    g_allyMask = mask;
    g_shm->hdr.reserved[1] = mask;   /* reserved[0] �?hpSupported；[1] 留给 v21 结盟掩码 */
    InterlockedExchange(&g_allyMaskDone, 1);
    LogLine("v21：结盟掩码 = 0x%06X（本地玩家 %d；Player/GetLocalPlayer/IsPlayerAlly 已定位=%d/%d/%d）",
            mask, (localId < 24) ? (int)localId : -1, fnPlayer ? 1 : 0, fnLocal ? 1 : 0, fnAlly ? 1 : 0);
}

static volatile LONG g_nameOkLogged = 0;    /* “名字解析成功”日志总上�?*/

/* 安全地把一段内存按字节读进 buf（最�?n 字节），返回实际读到的字节数�?
   全程 __try；读不动就停，返回已读到的部分�?*/
static int SafeHexDump(uint32_t addr, int n, unsigned char* buf)
{
    if (addr < 0x10000 || n <= 0) return 0;
    int got = 0;
    __try
    {
        const unsigned char* p = (const unsigned char*)(uintptr_t)addr;
        for (int i = 0; i < n; i++) { buf[i] = p[i]; got = i + 1; }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { /* got 停在已读到的部分 */ }
    return got;
}

/* �?n 个字节格式化�?"AA BB CC ..."（大写、空格分隔），out 已清空�?*/
static void FormatHex(const unsigned char* buf, int n, char* out, size_t outSize)
{
    out[0] = 0;
    if (!buf || n <= 0) return;
    static const char hexc[] = "0123456789ABCDEF";
    size_t pos = 0;
    for (int i = 0; i < n && pos + 3 < outSize; i++)
    {
        out[pos++] = hexc[buf[i] >> 4];
        out[pos++] = hexc[buf[i] & 15];
        out[pos++] = ' ';
    }
    if (pos > 0) pos--;
    out[pos] = 0;
}

/* UTF-8 安全截断（v9）：�?src 最�?maxBytes 个字节复制到 dst（容�?cap），
   绝不把多字节字符切成两半�?
     · �?maxBytes 字节落在字符中间（后一字节是续字节 10xxxxxx）→ 回退到该字符
       起始处，整个字符都不写；
     · 源串本身就以半个字符结尾（NUL 前缺续字节）�?同样丢掉末尾残缺字符�?
   返回实际写入字节数（不含结尾 NUL）�?*/
static size_t DdhUtf8SafeCopy(char* dst, size_t cap, const char* src, size_t maxBytes)
{
    if (!dst || cap == 0) return 0;
    dst[0] = 0;
    if (!src || !src[0] || maxBytes == 0) return 0;
    if (maxBytes > cap - 1) maxBytes = cap - 1;

    size_t n = 0;
    while (n < maxBytes && src[n]) n++;

    if (src[n] && ((unsigned char)src[n] & 0xC0) == 0x80)
    {
        /* 截断点后面还有续字节 �?切在字符中间，退到该字符首字节（不写它） */
        while (n > 0 && ((unsigned char)src[n] & 0xC0) == 0x80) n--;
    }
    else
    {
        /* 源串自己结尾不完整时，也把末尾那个残缺字符去�?*/
        size_t start = n;
        while (start > 0 && ((unsigned char)src[start - 1] & 0xC0) == 0x80) start--;
        if (start > 0)
        {
            const unsigned char lead = (unsigned char)src[start - 1];
            size_t need = 1;
            if ((lead & 0xE0) == 0xC0) need = 2;
            else if ((lead & 0xF0) == 0xE0) need = 3;
            else if ((lead & 0xF8) == 0xF0) need = 4;
            if (start - 1 + need > n) n = start - 1;
        }
    }

    memcpy(dst, src, n);
    dst[n] = 0;
    return n;
}

/* 名字原样校验：p 必须可读�? 结尾、无控制字符/0x7F、长�?1..63�?
   拷出时走 DdhUtf8SafeCopy，长度不够也从完整字符边界截断�?
   全在 __try 里，读坏/校验不过返回 false�?*/
static bool ValidateNameText(uint32_t addr, char* out, size_t outSize)
{
    out[0] = 0;
    if (addr < 0x10000 || addr > 0x7FFFFFFF || outSize < 2) return false;
    __try
    {
        const unsigned char* p = (const unsigned char*)(uintptr_t)addr;
        if (!p[0]) return false;
        if (p[0] < 0x20) return false;
        int n = 0;
        for (; n < 64; ++n)
        {
            const unsigned char c = p[n];
            if (!c) break;
            if (c < 0x20 || c == 0x7F) return false;
        }
        if (n == 0 || n >= 64) return false;   /* 空串/没结�?-> 放弃 */
        const int copy = n < (int)outSize - 1 ? n : (int)outSize - 1;
        DdhUtf8SafeCopy(out, outSize, (const char*)p, (size_t)copy);
        return true;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { out[0] = 0; return false; }
}

/* ---- v24 诊断�?x326BA0 只取表里�?[0] 项，取不到就返回空串/0�?
   这里直接把注册表对象取出来（0x327020(desc, key=code)），�?count �?array[0..7]
   到底是什么，用来判断 Dota 自定义单位码到底是“表不存在”“表存在但名字为空”，
   还是“名字在别的槽位”。只在前几次失败时记录�?*/
#define DDH_RVA_REGISTRY_GET   0x00327020u
static const uint8_t kPro3RegistryGet[3] = { 0x55, 0x8B, 0xEC };
static uint32_t g_natRegistryGet = 0;

static uint32_t ResolveRegistryGet(void)
{
    if (g_natRegistryGet) return g_natRegistryGet;
    g_natRegistryGet = HpResolve(DDH_RVA_REGISTRY_GET, kPro3RegistryGet);
    if (g_natRegistryGet)
        LogLine("名字表探针：0x327020 已定位（0x%08X）", g_natRegistryGet);
    return g_natRegistryGet;
}

static void DdhNameTableProbe(uint32_t code)
{
    const uint32_t fn = ResolveRegistryGet();
    if (!fn || !g_modBase) return;
    const uint32_t desc = (uint32_t)(uintptr_t)((const uint8_t*)g_modBase + 0x98ACF8u);
    __try
    {
        const uint32_t obj = ((uint32_t(__fastcall*)(uint32_t, uint32_t))(uintptr_t)fn)(code, desc);
        if (!obj) { LogLine("名字表探针：code=0x%08X 注册表返回 0", code); return; }
        const int count = *(const int*)(obj + 0x28);
        const uint32_t* arr = *(const uint32_t* const*)(obj + 0x2C);
        LogLine("名字表探针：code=0x%08X obj=%08X count=%d arr=%08X",
                code, obj, count, (unsigned)(uintptr_t)arr);
        for (int i = 0; i < count && i < 8; ++i)
        {
            if (!arr) break;
            const uint32_t p = arr[i];
            char buf[64] = { 0 };
            const bool ok = p && ValidateNameText(p, buf, sizeof(buf)) && buf[0];
            LogLine("名字表探针[%d] ptr=%08X%s%s", i, p, ok ? " name=" : "", ok ? buf : "");
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("名字表探针：code=0x%08X 异常 0x%08X", code, (unsigned)GetExceptionCode());
    }
}

/* v25：直接查【类型码 �?名字表】并取第一个非空槽位�?
   �?0x326BA0 走同一个注册表（desc=g_modBase+0x98ACF8），但不依赖它那个返�?0 的实现�?*/
static bool DdhNameFromTypeTable(uint32_t code, char* out, size_t outSize)
{
    if (out) out[0] = 0;
    if (!code || !out || outSize < 2) return false;
    const uint32_t fn = ResolveRegistryGet();
    if (!fn || !g_modBase) return false;
    const uint32_t desc = (uint32_t)(uintptr_t)((const uint8_t*)g_modBase + 0x98ACF8u);
    __try
    {
        const uint32_t obj = ((uint32_t(__fastcall*)(uint32_t, uint32_t))(uintptr_t)fn)(code, desc);
        if (!obj) return false;
        const int count = *(const int*)(obj + 0x28);
        const uint32_t* arr = *(const uint32_t* const*)(obj + 0x2C);
        if (!arr || count <= 0) return false;
        for (int i = 0; i < count && i < 16; ++i)
        {
            const uint32_t p = arr[i];
            if (p && ValidateNameText(p, out, outSize) && out[0]) return true;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        if (out) out[0] = 0;
    }
    return false;
}

static void ResolveName(uint32_t obj, uint32_t code, char* out, size_t outSize)
{
    (void)obj;
    out[0] = 0;
    if (!code || g_modBase == 0) return;

    for (int i = 0; i < g_nameCacheCount; i++)
    {
        if (g_nameCache[i].code == code && g_nameCache[i].name[0])
        {
            DdhUtf8SafeCopy(out, outSize, g_nameCache[i].name, outSize - 1);
            return;
        }
    }

    char tmp[64] = { 0 };
    if (!DdhNameFromTypeTable(code, tmp, sizeof(tmp)) || !tmp[0])
    {
        const LONG n = InterlockedIncrement(&g_nameFailLogged);
        if (n <= 3)
            LogLine("类型码名称表解析失败：code=0x%08X", code);
        return;
    }

    DdhUtf8SafeCopy(out, outSize, tmp, outSize - 1);
    if (g_nameCacheCount < 128)
    {
        g_nameCache[g_nameCacheCount].code = code;
        DdhUtf8SafeCopy(g_nameCache[g_nameCacheCount].name, sizeof(g_nameCache[0].name), tmp, sizeof(g_nameCache[0].name) - 1);
        g_nameCacheCount++;
    }
    else
    {
        /* 缓存满了：覆盖最后一个槽位（只缓存成功结果） */
        g_nameCache[127].code = code;
        DdhUtf8SafeCopy(g_nameCache[127].name, sizeof(g_nameCache[0].name), tmp, sizeof(g_nameCache[0].name) - 1);
    }

    const LONG n = InterlockedIncrement(&g_nameOkLogged);
    if (n <= 5)
        LogLine("类型码名称表解析成功：code=0x%08X 名字=%s", code, tmp);
}

struct DdhTitleCacheEntry
{
    uint32_t code;
    uint32_t valid;
    char     title[64];
};

static DdhTitleCacheEntry g_ddhTitleCache[128];
static uint32_t           g_ddhTitleCacheCount = 0;

static bool DdhCachedTitleByCode(uint32_t code, char* out, size_t cap)
{
    if (!out || cap < 2) return false;
    out[0] = 0;
    if (!code) return false;

    for (uint32_t i = 0; i < g_ddhTitleCacheCount; ++i)
    {
        const DdhTitleCacheEntry* e = &g_ddhTitleCache[i];
        if (e->code != code || !e->valid || !e->title[0]) continue;
        DdhUtf8SafeCopy(out, cap, e->title, cap - 1);
        return out[0] != 0;
    }
    return false;
}

static bool DdhCaptureTitleByObject(uint32_t obj, uint32_t code)
{
    if (!code || obj < 0x10000u || obj > 0x7FFFFFFFu) return false;
    for (uint32_t i = 0; i < g_ddhTitleCacheCount; ++i)
    {
        const DdhTitleCacheEntry* e = &g_ddhTitleCache[i];
        if (e->code != code || !e->valid) continue;
        return e->title[0] != 0;
    }

    if (!g_modBase || g_imageSize <= 0x0050B550u) return false;
    uint32_t typeData = 0;
    __try { typeData = *(const uint32_t*)(uintptr_t)(obj + 0x1F0u); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
    if (typeData < 0x10000u || typeData > 0x7FFFFFFFu) return false;

    char text[0x100] = { 0 };
    typedef void (__thiscall* fn_proper_name_t)(void*, char*, uint32_t);
    const fn_proper_name_t fn =
        (fn_proper_name_t)(uintptr_t)(g_modBase + 0x0050B550u);
    __try { fn((void*)(uintptr_t)typeData, text, (uint32_t)sizeof(text)); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }

    DdhTitleCacheEntry* slot = NULL;
    if (g_ddhTitleCacheCount < 128)
        slot = &g_ddhTitleCache[g_ddhTitleCacheCount++];
    else
        slot = &g_ddhTitleCache[127];
    memset(slot, 0, sizeof(*slot));
    slot->code = code;
    slot->valid = 1;

    if (!text[0] || strcmp(text, "The Unknown Hero") == 0)
        return false;   /* Valid response: this type has no proper name. */

    DdhUtf8SafeCopy(slot->title, sizeof(slot->title), text, sizeof(slot->title) - 1);
    return slot->title[0] != 0;
}

#define DDH_META_QUEUE_CAP 64
struct DdhPendingMeta
{
    uint32_t seq;
};

static DdhPendingMeta g_pendingMeta[DDH_META_QUEUE_CAP];
static uint32_t      g_pendingMetaCount = 0;

static void DdhQueuePendingMeta(uint32_t seq)
{
    if (g_pendingMetaCount >= DDH_META_QUEUE_CAP) return;
    DdhPendingMeta* m = &g_pendingMeta[g_pendingMetaCount++];
    m->seq = seq;
}

static void DdhMarkPendingReadyWithoutEngine(void)
{
    if (!g_shm) { g_pendingMetaCount = 0; return; }
    for (uint32_t i = 0; i < g_pendingMetaCount; ++i)
    {
        const DdhPendingMeta* m = &g_pendingMeta[i];
        const uint32_t slot = (m->seq - 1) % DDH_MAX_EVENTS;
        if (g_shm->ev[slot].seq == m->seq)
            InterlockedExchange(&g_evReady[slot], 1);
    }
    g_pendingMetaCount = 0;
}

static void DdhCompletePendingEvents(void)
{
    if (!g_shm) { g_pendingMetaCount = 0; return; }

    const uint32_t count = g_pendingMetaCount;
    g_pendingMetaCount = 0;
    for (uint32_t i = 0; i < count; ++i)
    {
        const DdhPendingMeta* m = &g_pendingMeta[i];
        const uint32_t slot = (m->seq - 1) % DDH_MAX_EVENTS;
        DdhEvent* e = &g_shm->ev[slot];
        if (e->seq != m->seq) continue;

        __try { DdhDbUpdateEventUnits(e); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("延迟单位缓存失败：seq=%u exception=%08X",
                    m->seq, (unsigned)GetExceptionCode());
        }

        InterlockedExchange(&g_evReady[slot], 1);
    }
}

static uint32_t RecordDamage(uint32_t victim, uint32_t infoPtr, uint32_t isPhysical,
                             uint32_t stackSource, uint32_t depth, uint32_t hpOk, float hpBefore,
                             uint32_t* outSeq)
{
    if (!g_shm) return 0;

    uint32_t source = 0, flag = 0, amountBits = 0, attackType = 0, mask = 0, weapon = 0;
    if (infoPtr > 0x10000 && infoPtr < 0x7FFFFFFF)
    {
        __try
        {
            const uint32_t* p = (const uint32_t*)(uintptr_t)infoPtr;
            source     = p[0];              /* +0x00 */
            weapon     = p[1];              /* +0x04 */
            flag       = p[3];              /* +0x0C */
            amountBits = p[4];              /* +0x10 */
            mask       = p[5];              /* +0x14 */
            attackType = p[8];              /* +0x20 */
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    }

    uint32_t seq = InterlockedIncrement((volatile LONG*)&g_shm->hdr.count);
    uint32_t slot = (seq - 1) % DDH_MAX_EVENTS;
    DdhEvent* e = &g_shm->ev[slot];
    InterlockedExchange(&g_evReady[slot], 0);
    e->seq        = seq;
    e->tickMs     = GetTickCount();
    e->victim     = victim;
    e->victimCode = SafeCode(victim);
    e->source     = source;
    e->sourceCode = SafeCode(source);
    /* Capture names while both CUnit objects are still valid. The type code is read
       from CUnit+0x30 and the result is cached by type code. */
    if (e->victimCode)
    {
        ResolveName(victim, e->victimCode, e->victimName, sizeof(e->victimName));
        if (!e->victimName[0])
            DdhCodeText(e->victimCode, e->victimName, sizeof(e->victimName));
    }
    if (e->sourceCode)
    {
        ResolveName(source, e->sourceCode, e->sourceName, sizeof(e->sourceName));
        if (!e->sourceName[0])
            DdhCodeText(e->sourceCode, e->sourceName, sizeof(e->sourceName));
    }
    DdhCaptureTitleByObject(victim, e->victimCode);
    if (source)
        DdhCaptureTitleByObject(source, e->sourceCode);
    e->victimOwner = ResolveOwnerPid(victim);
    e->sourceOwner = ResolveOwnerPid(source);
    memcpy(&e->amount, &amountBits, 4);
    e->flag       = flag;
    e->attackType = attackType;
    e->damageMask = mask;
    e->weaponType = weapon;
    e->isPhysical = isPhysical;
    e->stackSource = stackSource;
    /* v3：先�?enter 侧的血；after 由返回跳板补 */
    e->hpBefore   = hpBefore;
    e->hpAfter    = 0.0f;
    e->actual     = 0.0f;
    e->hpValid    = 0;
    e->depth      = depth;
    e->engineDamage = 0.0f;
    e->engineValid  = 0;
    e->setDamage    = 0.0f;
    e->setCalls     = 0;
    /* v20：出口三读的最终伤害，�?DdhDamageFunc 在原函数返回后补 */
    e->finalDamage  = 0.0f;
    e->finalFlags   = 0;
    /* owner slots are filled from CUnit+0x58 after the damage callback. */
    /* Event slots are reused by the 512-entry ring. Always start from zero so
       illusion bits from a previous event cannot survive in this slot. */
    e->flags = 0;
    if (DdhIsHeroCode(e->victimCode))
        e->flags |= DDH_EVENT_FLAG_VICTIM_HERO;
    if (DdhIsHeroCode(e->sourceCode))
        e->flags |= DDH_EVENT_FLAG_SOURCE_HERO;
    if (DdhUnitIllusionStateByObj(victim) > 0)
        e->flags |= DDH_EVENT_FLAG_VICTIM_ILLUSION;
    if (source && DdhUnitIllusionStateByObj(source) > 0)
        e->flags |= DDH_EVENT_FLAG_SOURCE_ILLUSION;
    DdhQueuePendingMeta(seq);
    g_shm->hdr.lastTick = e->tickMs;
    MemoryBarrier();
    if (outSeq) *outSeq = seq;
    return slot;
}

/* ===========================================================================
   v9：热键（Ctrl+Alt+R / S / Q�? 记录单位 + 死亡结算广播
   ---------------------------------------------------------------------------
   线程模型（和插件 UDamageWatcherHook.cpp 的“热键线�?-> 游戏线程执行”同思路）：
      * 热键线程 DdhHotkeyThreadProc 只做三件事：RegisterHotKey、GetMessage�?
        把待办标志位�?1，然�?PostMessage 给游戏窗口。不读游戏内存、不调引擎函数�?
      * v12（用户反馈“按了热键要等挨打才出提示，延迟不可接受”）：动�?*立刻**�?
        游戏线程执行 —�?子类化游戏窗口（SetWindowLongPtrW），热键线程
        PostMessage(WM_APP+0xDD)，游戏窗口过程里当场�?DdhProcessPending()�?
        以前只把待办挂在“下一次伤害事件”上，所以没伤害就一直不响应�?
      * 死亡结算仍然�?DdhProcessDeferred() 在【最外层】伤害函数退出后发�?—�?
        那条必须在引擎扣血过程之外跑，跟热键无关�?
      * 伤害事件路径里也保留一�?DdhProcessPending()：窗口没找到 / PostMessage 失败
        时退化成旧行为，不至于完全没反应�?
      * 热键线程第一次被拉起也是�?DdhDamageFunc 里（进图后才可能有伤害）�?
        不在 DllMain �?CreateThread，避免加载器锁期间起线程�?

   选区链（�?C# �?Core/Probe.cs、Core/Wc3Game.cs 完全一致，照抄偏移）：
     ctx    = *(game.dll + 0xBE4238)
     pid    = *(u16*)(ctx + 0x28)                  本地玩家�?
     player = *(u32*)(ctx + 0x58 + 4*pid)          本地玩家对象
     sel    = *(u32*)(player + 0x34)               选区容器
     node   = *(u32*)(sel + 0x1F0)                 首个选中节点（备用链 sel + 0x08�?
     unit   = *(u32*)(node + 8)                    单位对象
   每一跳都先做地址区间检查，整段再包 __try/__except；取不到只写日志�?

   消息口径（v11：聊天里**只发来源占比**，主段按用户要求不再显示）：
     死亡结算   �?【伤害】雪�?0.0% 狼人20.0%
     Ctrl+Alt+Q �?【当前伤害】雪�?0.0% 狼人20.0%
      占比 = 该来源净掉血 ÷ Σ净掉血（Σ净�?0 时退回原始伤害口径，与主界面一致）
   名字/时间/受击次数/净掉血/最大单�?只留在界面和日志里（日志会原样打整条消息）�?
   Ctrl+Alt+R / S 的反馈只在本机消息区（【已选中】�?/ 【已取消】…），不进公共聊天�?
   =========================================================================== */

/* ---- 热键 ID：外部测试脚�?PostThreadMessage(WM_HOTKEY, 这个 id) 也能触发 ---- */
#define DDH_HK_ID_R   0xD0D1u
#define DDH_HK_ID_S   0xD0D2u
#define DDH_HK_ID_Q   0xD0D3u
#ifndef MOD_NOREPEAT
#define MOD_NOREPEAT  0x4000u
#endif

/* ---- 直投聊天（无框直投）用到�?6 �?game.dll �?RVA ----
   与插�?v1.4.1/v1.4.21 的“直投聊天”完全相同（那边已实机验证过整套）：
     0x34F3A0  get_unit(idx,0)        __fastcall(0,0)，[obj+0x3FC] = 聊天 UI 对象
     0x392060  clear_chat(obj, idx)   __thiscall
     0x3B2DE0  set_recipient(obj,sel) __thiscall�?=全部 1=盟友 2=观察�?
     0x3B3B80  SetText(obj, utf8)     __thiscall
     0x14D670  get_game_wnd(idx)      __fastcall(0,0) -> HWND
     0x153710  游戏窗口过程(hwnd,msg,wp,lp)
   为什么主路用这套、而不是直接调 InGameChatWhat�?x355CF0）：
     InGameChatWhat 只是“把一行聊天画到聊天区”的显示函数，本地调用只在本机可见�?
     不会发给其他玩家；插件仓库《WFE喊话机制与聊天管线逆向.md》�? 实测也证�?
     本地玩家自己发的消息根本不经过投递器 0x562E0。真正能让别人看到的�?
     “把文本塞进游戏聊天输入�?+ 让游戏自己的窗口过程收到一次回车”，
     也就是下面这套已经实机跑通的直投法�?*/
#define DDH_RVA_CHAT_GET_UNIT   0x34F3A0u
#define DDH_RVA_CHAT_CLEARCHAT  0x392060u
#define DDH_RVA_CHAT_SETRECIP   0x3B2DE0u
#define DDH_RVA_CHAT_SETTEXT    0x3B3B80u
#define DDH_RVA_CHAT_GAMEWND    0x14D670u
#define DDH_RVA_CHAT_GAMEPROC   0x153710u
#define DDH_OFF_CHAT_UI         0x3FCu

typedef uint32_t (__fastcall *fn_ddh_getunit_t)(uint32_t, uint32_t);
typedef void     (__fastcall *fn_ddh_thiscall1_t)(void* self, void* edx_dummy, uint32_t a);
typedef uint32_t (__fastcall *fn_ddh_getwnd_t)(uint32_t, uint32_t);
typedef intptr_t (__fastcall *fn_ddh_wndproc_t)(void* hwnd, uint32_t msg, uintptr_t wp, intptr_t lp);
typedef void     (__fastcall *fn_ddh_settext_t)(void* self, void* edx_dummy, const char* utf8);

static uint32_t       g_ddhChatGetUnit  = 0;
static uint32_t       g_ddhChatClear    = 0;
static uint32_t       g_ddhChatSetRecip = 0;
static uint32_t       g_ddhChatSetText  = 0;
static uint32_t       g_ddhChatGetWnd   = 0;
static uint32_t       g_ddhChatWndProc  = 0;
static volatile LONG  g_ddhChatInitDone = 0;
static int            g_ddhChatOk       = 0;   /* 1 = 6 个地址序言全部通过 */

/* ---- 热键线程状态（热键线程只写“待办”这 3 个标志，其余都归游戏线程�?---- */
static volatile LONG  g_ddhHkStarted   = 0;
static volatile LONG  g_ddhHkStop      = 0;
static DWORD          g_ddhHkThreadId  = 0;
static HANDLE         g_ddhHkThread    = NULL;
static volatile LONG  g_ddhPendR       = 0;
static volatile LONG  g_ddhPendS       = 0;
static volatile LONG  g_ddhPendQ       = 0;
static volatile LONG  g_ddhAutoSend    = 1;    /* 默认开；S 切换 */
static volatile LONG  g_ddhHkPressLogged  = 0;
static volatile LONG  g_ddhHkActionLogged = 0;
static volatile LONG  g_ddhHkFailLogged   = 0;
static volatile LONG  g_ddhHkToggleLogged = 0;
static volatile LONG  g_ddhHkQueryLogged  = 0;
static volatile LONG  g_ddhHkPanelLogged  = 0;

/* v17：鼠标整块点击面板展开/收起（不再有快捷键）。命中矩形是归一化坐标�?*/
static volatile LONG  g_ddhPanelClickOk   = 0;
static volatile LONG  g_ddhPanelMouseDown = 0;
static float          g_ddhPanelHitL = 0.0f;
static float          g_ddhPanelHitT = 0.0f;
static float          g_ddhPanelHitW = 0.0f;
static float          g_ddhPanelHitH = 0.0f;
static volatile LONG  g_ddhPanelLastToggle = 0;
static volatile LONG  g_ddhPanelClickLogged = 0;
static volatile LONG  g_ddhMouseMsgLogged = 0;
static volatile LONG  g_ddhPanelFrameRectOk = 0;
static float          g_ddhPanelFrameL = 0.0f;
static float          g_ddhPanelFrameT = 0.0f;
static float          g_ddhPanelFrameR = 0.0f;
static float          g_ddhPanelFrameB = 0.0f;

/* v28：游戏内【死亡结算】按钮（常驻小按钮，点一下打开/关闭结算页）。
   几何同样是 UI 坐标（0.8 x 0.6），左上锚点、y 向下为负。 */
#define DDH_BTN_X       0.008f
#define DDH_BTN_Y       (-0.040f)
#define DDH_BTN_W       0.064f
#define DDH_BTN_H       0.021f
static uint32_t        g_ddhBtnUi       = 0;
static uint32_t        g_ddhBtnBg       = 0;
static uint32_t        g_ddhBtnText     = 0;
static volatile LONG   g_ddhBtnReady    = 0;
static volatile LONG   g_ddhBtnMouseDown = 0;
static volatile LONG   g_ddhBtnRectOk   = 0;
static float           g_ddhBtnL = 0.0f, g_ddhBtnT = 0.0f, g_ddhBtnR = 0.0f, g_ddhBtnB = 0.0f;
static volatile LONG   g_ddhBtnLogged   = 0;
static volatile LONG   g_ddhBtnClickLogged = 0;
static volatile LONG   g_ddhBtnLastGameCheck = 0;
static volatile LONG   g_ddhBtnInGame   = 0;
static int             g_ddhBtnDisabled = 0;
static int             g_ddhBtnEnvRead  = 0;
static uint32_t        g_ddhHiddenCursorUi = 0;
static uint32_t        g_ddhHiddenCursorFrame = 0;
static int             g_ddhCursorOver = 0;
static volatile LONG   g_ddhCursorLogged = 0;
static uint32_t        g_ddhHtmlFrame = 0;
static uint32_t        g_ddhHtmlUi = 0;
static int             g_ddhHtmlShown = 0;
static int             g_ddhHtmlFailed = 0;
static volatile LONG   g_ddhHtmlLogged = 0;
static uint32_t        g_ddhCursorRaisedUi = 0;
static uint32_t        g_ddhCursorRaisedFrame = 0;
static int32_t         g_ddhCursorRaisedLevel = 0;

/* ---- 记录单位 + 它自己的统计（只在游戏线程读写，不需要锁�?---- */
#define DDH_SRC_MAX 32

struct DdhSrcStat
{
    uint32_t source;    /* 来源单位对象指针（码相同就合并，指针只留第一个） */
    uint32_t code;      /* 来源类型�?*/
    uint32_t hits;
    float    maxHit;
    double   raw, engine, map, net;
    char     label[96]; /* 第一次见到它时查好的“名�?�?”——发送时不再碰可能已释放的指�?*/
};

struct DdhTrack
{
    uint32_t   unit;        /* 0 = 还没记录单位 */
    uint32_t   code;
    uint32_t   hits;
    uint32_t   startMs;
    uint32_t   srcCount;
    uint32_t   dead;        /* 1 = 已经广播过死亡，等它复活再重新统�?*/
    float      maxHit;
    double     raw, engine, map, net;
    char       label[96];   /* �?R 时查好的“名�?�?�?*/
    DdhSrcStat src[DDH_SRC_MAX];
};

static DdhTrack g_ddhTrack;

/* ---- 全局“每个受击单位”的累计：Q 在没有记录单位时发它�?Top5 ---- */
#define DDH_GLOBAL_MAX 128

struct DdhVictimStat
{
    uint32_t unit;
    uint32_t code;
    uint32_t hits;
    float    maxHit;
    double   net, raw;
    char     label[96]; /* 第一次见到它时查好的“名�?�?�?*/
};

static DdhVictimStat g_ddhGlobal[DDH_GLOBAL_MAX];
static int           g_ddhGlobalCount = 0;

/* ---- 待发送的结算（游戏线程内填写、游戏线程内发送） ---- */
static char          g_ddhDeferText[768];
static volatile LONG g_ddhDeferKind   = 0;     /* 1 = 有一条死亡结算等着�?*/
static volatile LONG g_ddhSendOkCount = 0;
static volatile LONG g_ddhSendFailCnt = 0;
static volatile LONG g_ddhSendSkipLogged = 0;
static volatile LONG g_ddhMsgLogCount  = 0;   /* “组好的消息”日志限流（�?60 条） */

/* ---- 兜底显示（DisplayTimedTextToPlayer）的状�?---- */
static uint32_t      g_ddhNatDtttp      = 0;
static uint32_t      g_ddhNatPlayer     = 0;
static uint32_t      g_ddhNatGetPlayers = 0;
static volatile LONG g_ddhDtttpTries    = 0;
static volatile LONG g_ddhPlayerTries   = 0;
static volatile LONG g_ddhPlayersTries  = 0;
static volatile LONG g_ddhDtttpFailLogged = 0;

/* ---------------------------------------------------------------------------
   几个小工�?
   --------------------------------------------------------------------------- */

/* 4 字节类型�?-> 可读文本。内存里是反序存的（�?SafeCode 注释），
   所以按 dword 的高字节到低字节打印就是显示顺序�?hfoo"/"opeo"…）�?*/
static void DdhCodeText(uint32_t code, char* out, size_t cap)
{
    if (!out || cap < 5) { if (out && cap) out[0] = 0; return; }
    out[0] = (char)((code >> 24) & 0xFF);
    out[1] = (char)((code >> 16) & 0xFF);
    out[2] = (char)((code >>  8) & 0xFF);
    out[3] = (char)((code      ) & 0xFF);
    for (int i = 0; i < 4; i++)
        if ((unsigned char)out[i] < 0x20 || (unsigned char)out[i] > 0x7E) out[i] = '.';
    out[4] = 0;
}

/* v11：消息里不再带时间（主段已去掉），函数留着备用 */
static void DdhFormatHms(char* out, size_t cap)
{
    SYSTEMTIME st;
    GetLocalTime(&st);
    DdhSprintf(out, cap, "%02d:%02d:%02d", (int)st.wHour, (int)st.wMinute, (int)st.wSecond);
}

static void DdhTruncateUtf8(char* s, size_t cap, size_t maxBytes);   /* 定义在后�?*/

/* �?“名�?类型�?�?拼进固定大小�?out�?*不越界、不切坏 UTF-8、不触发无效参数**�?
   名字先按 UTF-8 边界截到“放得下 �?�?�?+ 结束符”的长度，再�?_snprintf_s(...,_TRUNCATE)�?
   （sprintf_s 放不下会 _invoke_watson �?__fastfail(0xC0000409)：真�?2026-10-31 20:22:52
     就是长名�?“……【辅助单位�?e009)�?写进 64 字节标签把游戏带走的。） */
static void DdhCleanName(const char* src, char* out, size_t cap)
{
    if (!out || cap < 2) return;
    out[0] = 0;
    if (!src) return;
    size_t o = 0;
    for (size_t i = 0; src[i] && o + 1 < cap; )
    {
        if (src[i] == '|' && (src[i + 1] == 'c' || src[i + 1] == 'C'))
        {
            int j = 2;
            bool hex = true;
            for (; j < 10; j++)
            {
                const char c = src[i + j];
                if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')))
                { hex = false; break; }
            }
            if (hex) { i += 10; continue; }
        }
        if (src[i] == '|' && (src[i + 1] == 'r' || src[i + 1] == 'R'))
        {
            i += 2;
            continue;
        }
        out[o++] = src[i++];
    }
    out[o] = 0;
}

static void DdhComposeLabel(const char* name, const char* codeTxt, char* out, size_t cap)
{
    if (!out || cap < 2) { if (out && cap) out[0] = 0; return; }
    out[0] = 0;

    const bool hasName = (name && name[0]);
    const bool hasCode = (codeTxt && codeTxt[0]);

    if (hasName && hasCode)
    {
        char fitted[128] = { 0 };
        strncpy_s(fitted, sizeof(fitted), name, _TRUNCATE);
        const size_t reserve = strlen(codeTxt) + 3;          /* '(' + �?+ ')' + 结束�?*/
        const size_t room    = (cap > reserve + 1) ? cap - reserve : 1;
        DdhTruncateUtf8(fitted, sizeof(fitted), room);        /* �?UTF-8 边界截断并补 “…�?*/
        DdhSprintf(out, cap, "%s(%s)", fitted, codeTxt);
    }
    else if (hasName) DdhSprintf(out, cap, "%s", name);
    else if (hasCode) DdhSprintf(out, cap, "%s", codeTxt);
    else              DdhSprintf(out, cap, "?");
}

/* 单位显示名：优先引擎查到的名字，查不到退回类型码，再不行退回对象指针�?
   ResolveName 内部有“类型码→名字”缓存与日志限流；这里在游戏线程调用�?*/
static void DdhUnitLabel(uint32_t unit, uint32_t code, char* out, size_t cap)
{
    if (!out || cap < 2) return;
    out[0] = 0;
    char name[96] = { 0 };
    char codeTxt[8] = { 0 };
    if (code) DdhCodeText(code, codeTxt, sizeof(codeTxt));

    if (unit >= 0x10000u && unit <= 0x7FFFFFFFu)
        ResolveName(unit, code, name, sizeof(name));

    /* 引擎名字带 |cAARRGGBB / |r 颜色码，面板/聊天里要清掉 */
    if (name[0])
    {
        char clean[96];
        DdhCleanName(name, clean, sizeof(clean));
        strcpy_s(name, sizeof(name), clean);
    }

    if (!name[0] && !codeTxt[0] && unit)
    {
        DdhSprintf(out, cap, "0x%08X", unit);
        return;
    }
    DdhComposeLabel(name, codeTxt, out, cap);
}

/* Damage hooks must not call engine/JASS name resolvers. Use only the cache
   already populated by deferred attribute requests, otherwise the type code. */
static void DdhUnitLabelSafe(uint32_t, uint32_t code, char* out, size_t cap)
{
    if (!out || cap < 2) return;
    out[0] = 0;
    if (code)
    {
        for (int i = 0; i < g_nameCacheCount; i++)
        {
            if (g_nameCache[i].code == code && g_nameCache[i].name[0])
            {
                DdhUtf8SafeCopy(out, cap, g_nameCache[i].name, cap - 1);
                return;
            }
        }
        DdhCodeText(code, out, cap);
        return;
    }
    strcpy_s(out, cap, "?");
}

/* 发送时用的标签：优先用早就查好的缓存，绝不再去碰可能已经释放的单位指针 */
static void DdhLabelOf(const char* label, uint32_t code, uint32_t unit, char* out, size_t cap)
{
    if (label && label[0]) { strncpy_s(out, cap, label, _TRUNCATE); return; }
    char codeTxt[8] = { 0 };
    if (code) DdhCodeText(code, codeTxt, sizeof(codeTxt));
    if (codeTxt[0])      DdhSprintf(out, cap, "%s", codeTxt);
    else if (unit)       DdhSprintf(out, cap, "0x%08X", unit);
    else                 DdhSprintf(out, cap, "?");
}

/* 追加�?0 结尾的字符串（自动截断，不会越界�?*/
static void DdhAppendFmt(char* dst, size_t cap, const char* fmt, ...)
{
    const size_t used = strlen(dst);
    if (used + 1 >= cap) return;
    va_list ap;
    va_start(ap, fmt);
    _vsnprintf_s(dst + used, cap - used, _TRUNCATE, fmt, ap);
    va_end(ap);
}

/* 地图伤害（生效值）：与 C# �?HookEvent.EffectiveDamage 同口�?*/
static double DdhEventEffective(const DdhEvent* e)
{
    /* v20：最终值（出口 *out）优�?—�?它就是引擎真正扣下去的那个数，且已含地图改写�?
       bit0 只在"确实掉了血"时才置位，所以这里不用再�?>0.005�?*/
    if (e->finalFlags & 1u) return (double)e->finalDamage;
    if (e->setCalls > 0) return (double)e->setDamage;
    return e->hpValid ? (double)e->actual : 0.0;
}

/* ---------------------------------------------------------------------------
   v10/v11 文本拼装：修“名字乱码”，消息只发来源占比（主段不发了�?
   ---------------------------------------------------------------------------
   编码事实（真机日�?ddh-17256.log 实证）：
     · 引擎 0x326BA0 返回的单位名**本身就是 UTF-8 字节**
       （“雪狼�?= E9 9B AA E7 8B BC，“梦幻伯爵�?= E6 A2 A6 E5 B9 BB E4 BC AF E7 88 B5）；
       ResolveName 只是把这些字节原样拷�?victimName/sourceName，没有转码�?
     · 本文件自己的中文标签�?GBK 字面量（源码本身�?GBK）�?
   所以一条消息天然是“两种编码混排”，**绝不能整段再�?GBK 转一�?* —�?
   那等于把已经�?UTF-8 的名字又�?GBK 解一遍，聊天里就成了“妖”加怪符号那种乱码�?
   组消息的规矩（本文件所有发出去的消息都走这套）�?
     �?中文标签：GBK 字面�?�?UTF-8 ................ DdhAppendLabel
     �?单位�? ：原始字节直接拼、不再转�?.......... DdhAppendUnitName
     �?名字里若没有合法 UTF-8（例�?GBK 名字的孤立高位字节），只�?*这个名字**
        整体�?GBK→UTF-8 转一次当回退，并在日志里写明本条走了哪条路�?
   --------------------------------------------------------------------------- */

/* 一条聊天消息的 UTF-8 字节上限。旧�?240 太短，字段一多就被截成“…来…�?
   （真机那条就是被截断的），放�?420 够放完整【伤害】段�?*/
#define DDH_MSG_MAX_BYTES   420
/* 【伤害】段默认列几个来源（按净掉血占比降序�?*/
#define DDH_SHARE_TOP       3

/* 本条消息里的名字走了哪条路（每次组消息前清零，发送时写进日志�?*/
static int  g_msgNameRawUtf8     = 0;    /* �?合法 UTF-8 �?原字节拼�?*/
static int  g_msgNameGbkFallback = 0;    /* �?非法 UTF-8 �?整体�?GBK 转一�?*/
static volatile LONG g_msgNameFallbackLogged = 0;

/* 一段字节是不是合法 UTF-8：拒绝孤立续字节 0x80~0xBF�?xF8~0xFF、过长编码�?
   代理区、超 0x10FFFF。空串按“不合法”返回（调用方当“没名字”处理）�?*/
static bool DdhUtf8Valid(const char* s)
{
    if (!s || !s[0]) return false;
    const unsigned char* p = (const unsigned char*)s;
    const int n = (int)strlen(s);
    for (int i = 0; i < n; )
    {
        const unsigned char c = p[i];
        int need = 0;
        uint32_t cp = 0;
        if (c < 0x80) { i++; continue; }
        else if ((c & 0xE0) == 0xC0) { need = 1; cp = (uint32_t)(c & 0x1F); }
        else if ((c & 0xF0) == 0xE0) { need = 2; cp = (uint32_t)(c & 0x0F); }
        else if ((c & 0xF8) == 0xF0) { need = 3; cp = (uint32_t)(c & 0x07); }
        else return false;                                  /* 0x80~0xBF 孤立 / 0xF8~0xFF */
        if (i + need >= n) return false;                    /* 尾巴被截�?*/
        for (int k = 1; k <= need; k++)
        {
            if ((p[i + k] & 0xC0) != 0x80) return false;
            cp = (cp << 6) | (uint32_t)(p[i + k] & 0x3F);
        }
        if ((need == 1 && cp < 0x80u) || (need == 2 && cp < 0x800u) ||
            (need == 3 && cp < 0x10000u)) return false;      /* 过长编码 */
        if (cp >= 0xD800u && cp <= 0xDFFFu) return false;    /* 代理�?*/
        if (cp > 0x10FFFFu) return false;
        i += need + 1;
    }
    return true;
}

/* GBK -> UTF-8：给“本文件的中文标签”和“名字不�?UTF-8 时的回退”用�?
   转换失败就按原字节拷贝（宁可乱码也不丢字），返回 false�?*/
static bool DdhGbkToUtf8(const char* src, char* dst, size_t cap)
{
    if (!dst || cap < 2) return false;
    dst[0] = 0;
    if (!src || !src[0]) return true;

    const int need = MultiByteToWideChar(936, 0, src, -1, NULL, 0);
    if (need <= 0) { strncpy_s(dst, cap, src, _TRUNCATE); return false; }

    wchar_t* w = (wchar_t*)malloc((size_t)need * sizeof(wchar_t));
    if (!w) { strncpy_s(dst, cap, src, _TRUNCATE); return false; }

    bool ok = false;
    if (MultiByteToWideChar(936, 0, src, -1, w, need) > 0)
        ok = WideCharToMultiByte(CP_UTF8, 0, w, -1, dst, (int)cap, NULL, NULL) > 0;
    free(w);

    if (!ok) { strncpy_s(dst, cap, src, _TRUNCATE); return false; }
    return true;
}

/* UTF-8 -> GBK�?*只给写日志用**（日志文件是 GBK，直接写 UTF-8 在记事本里是乱码）�?*/
static bool DdhUtf8ToGbk(const char* src, char* dst, size_t cap)
{
    if (!dst || cap < 2) return false;
    dst[0] = 0;
    if (!src || !src[0]) return true;

    const int need = MultiByteToWideChar(CP_UTF8, 0, src, -1, NULL, 0);
    if (need <= 0) return false;

    wchar_t* w = (wchar_t*)malloc((size_t)need * sizeof(wchar_t));
    if (!w) return false;

    bool ok = false;
    if (MultiByteToWideChar(CP_UTF8, 0, src, -1, w, need) > 0)
        ok = WideCharToMultiByte(936, 0, w, -1, dst, (int)cap, NULL, NULL) > 0;
    free(w);

    if (!ok) dst[0] = 0;
    return ok;
}

/* 追加一�?ASCII 或已确认�?UTF-8 的字节（越界自动截断，永�?0 结尾�?*/
static void DdhAppendRaw(char* dst, size_t cap, const char* s)
{
    if (!dst || cap < 2 || !s || !s[0]) return;
    const size_t used = strlen(dst);
    if (used + 1 >= cap) return;
    size_t room = cap - used - 1;                 /* 留一个字节给 NUL */
    size_t n = strlen(s);
    if (n > room) n = room;
    if (n == 0) return;
    memcpy(dst + used, s, n);
    dst[used + n] = 0;
}

/* 追加中文标签：源码本身就�?UTF-8（ddh.cpp 已统一 UTF-8 编码），原样拼即可�?
   （老版本源码是 GBK，那时才需�?GBK→UTF-8；现在再转一次反而会变乱码。） */
static void DdhAppendLabel(char* dst, size_t cap, const char* labelUtf8)
{
    if (!dst || cap < 2 || !labelUtf8 || !labelUtf8[0]) return;
    DdhAppendRaw(dst, cap, labelUtf8);
}

/* 追加单位名：**引擎给的原字节直接拼**（它就是 UTF-8，再转一次才会乱）�?
   只有不是合法 UTF-8 时才退回“整个名字按 GBK→UTF-8 转一次”，并记日志说明走了哪条路�?*/
static void DdhAppendUnitName(char* dst, size_t cap, const char* raw)
{
    if (!dst || cap < 2 || !raw || !raw[0]) return;

    if (DdhUtf8Valid(raw))                        /* �?真机就是这条路：原样�?*/
    {
        g_msgNameRawUtf8++;
        DdhAppendRaw(dst, cap, raw);
        return;
    }

    char utf8[256] = { 0 };
    if (DdhGbkToUtf8(raw, utf8, sizeof(utf8)) && utf8[0] && DdhUtf8Valid(utf8))
    {
        g_msgNameGbkFallback++;
        const LONG n = InterlockedIncrement(&g_msgNameFallbackLogged);
        if (n <= 5)
        {
            char hex[96] = { 0 };
            int nb = (int)strlen(raw);
            if (nb > 24) nb = 24;
            FormatHex((const unsigned char*)raw, nb, hex, sizeof(hex));
            LogLine("消息编码：单位名不是合法 UTF-8，本条按 GBK→UTF-8 回退（原字节 hex=%s）", hex);
        }
        DdhAppendRaw(dst, cap, utf8);
        return;
    }

    /* 两条路都不通：按原字节拼，不丢内容、不�?*/
    g_msgNameGbkFallback++;
    DdhAppendRaw(dst, cap, raw);
}

/* 硬截断到 maxBytes 字节：不切坏汉字，末尾补 “…”（UTF-8 = E2 80 A6）�?
   cap 是缓冲区总容量；maxBytes 会被夹到 cap-1 以内�?*/
static void DdhTruncateUtf8(char* s, size_t cap, size_t maxBytes)
{
    if (!s || cap < 2) return;
    if (maxBytes + 1 > cap) maxBytes = cap - 1;
    if (strlen(s) <= maxBytes) return;

    size_t cut = maxBytes > 3 ? maxBytes - 3 : maxBytes;   /* �?3 字节给尾�?“…�?*/
    while (cut > 0 && ((unsigned char)s[cut] & 0xC0) == 0x80) cut--;   /* 别切在汉字中�?*/
    s[cut] = 0;
    if (maxBytes >= cut + 3)
    {
        memcpy(s + cut, "\xE2\x80\xA6", 3);
        s[cut + 3] = 0;
    }
}

/* "雪狼(hfoo)" -> "雪狼"：【伤害】段里只要名字（或类型码），不带类型码后缀�?*/
static void DdhStripCodeSuffix(const char* label, char* out, size_t cap)
{
    if (!out || cap < 2) return;
    out[0] = 0;
    if (!label || !label[0]) return;

    const size_t n = strlen(label);
    if (n >= 7 && label[n - 1] == ')')
    {
        const char* lp = strrchr(label, '(');
        if (lp && (size_t)(label + n - 1 - lp) == 5)       /* "(XXXX)" 正好 6 个字�?*/
        {
            size_t keep = (size_t)(lp - label);
            if (keep > cap - 1) keep = cap - 1;
            memcpy(out, label, keep);
            out[keep] = 0;
            return;
        }
    }
    strncpy_s(out, cap, label, _TRUNCATE);
}

/* ---------------------------------------------------------------------------
   消息（死亡结�?/ Ctrl+Alt+Q 实时统计�?
   --------------------------------------------------------------------------- */

/* ---------------------------------------------------------------------------
   【伤害】段：来�?Top N（默�?3），�?*净掉血占比**降序，每�?“名字或类型�?+ 一位小数百分比”�?
   ---------------------------------------------------------------------------
   口径与主界面（C# Core/HookBreakdown.cs �?PercentOf）完全一致：
     占比 = 该来源净掉血 ÷ 整条 Σ净掉血�?
     Σ净掉血 <= 0（这条结算没有可信血量）时退回“原始伤害”口径，免得整段�?0%�?
   只拼“项”的部分（不含【伤害】标签），项之间一个空格�?
   返回写进去的项数�? = 没有可显示的来源，调用方就别打【伤害】段了）�?*/
static int DdhBuildShareItems(const DdhSrcStat* src, uint32_t n, double totalNet, double totalRaw,
                              int maxItems, char* out, size_t outCap)
{
    if (!out || outCap < 2) return 0;
    out[0] = 0;
    if (!src || n == 0 || maxItems <= 0) return 0;
    if (n > DDH_SRC_MAX) n = DDH_SRC_MAX;

    const bool   useNet = totalNet > 0.01;
    const double denom  = useNet ? totalNet : totalRaw;
    if (!(denom > 0.01)) return 0;

    /* 按占比口径排序（净掉血优先；Σ净�?0 时按原始伤害�?*/
    int idx[DDH_SRC_MAX];
    for (uint32_t i = 0; i < n; i++) idx[i] = (int)i;
    for (uint32_t i = 0; i < n; i++)
    {
        for (uint32_t j = i + 1; j < n; j++)
        {
            const double a = useNet ? src[idx[j]].net : src[idx[j]].raw;
            const double b = useNet ? src[idx[i]].net : src[idx[i]].raw;
            if (a > b) { const int t = idx[i]; idx[i] = idx[j]; idx[j] = t; }
        }
    }

    int used = 0;
    for (uint32_t k = 0; k < n && used < maxItems; k++)
    {
        const DdhSrcStat* s = &src[idx[k]];
        const double v = useNet ? s->net : s->raw;
        if (v <= 0.01) continue;                       /* 0% 的来源不浪费聊天长度 */
        double pct = v * 100.0 / denom;
        pct = floor(pct * 10.0 + 0.5) / 10.0;          /* 四舍五入�?0.1 */
        if (pct < 0.1) pct = 0.1;                      /* 有伤害就别显示成 0.0% */
        if (pct > 100.0) pct = 100.0;

        char label[96]    = { 0 };
        char nameOnly[96] = { 0 };
        char num[16]      = { 0 };
        DdhLabelOf(s->label, s->code, s->source, label, sizeof(label));
        DdhStripCodeSuffix(label, nameOnly, sizeof(nameOnly));
        DdhSprintf(num, sizeof(num), "%.1f%%", pct);

        if (used) DdhAppendRaw(out, outCap, " ");
        DdhAppendUnitName(out, outCap, nameOnly);      /* 名字：引擎原字节直接�?*/
        DdhAppendRaw(out, outCap, num);
        used++;
    }
    return used;
}

/* 组一条“来源占比”文本（死亡结算 �?Ctrl+Alt+Q 共用同一套拼法）�?
     isDeath=1 �?【伤害】雪�?0.0% 狼人20.0%          �?死亡结算就发这一条，不再带主�?
     isDeath=0 �?【当前伤害】雪�?0.0% 狼人20.0%      �?Ctrl+Alt+Q
   按用户要求，主段（【死亡结算】名�?时间 受击N�?净X 最大Y�?*不再�?*�?
   名字/时间/重击数字只留在界面和日志里，聊天里只有来源占比�?
   没有来源（还没打中过 / 读不到伤害）时返回空串，由调用方决定发不发�?
   截断策略（DDH_MSG_MAX_BYTES = 420 UTF-8 字节）：
     先砍靠后的来源（3 �?2 �?1）→ 最后才�?420 硬截断并在末尾补 “…”（不切坏汉字）�?*/
static void DdhBuildTrackText(char* out, size_t cap, int isDeath)
{
    if (!out || cap < 2) return;
    out[0] = 0;

    int maxSrc = (int)g_ddhTrack.srcCount;
    if (maxSrc > DDH_SHARE_TOP) maxSrc = DDH_SHARE_TOP;

    char items[320] = { 0 };
    char tmp[512]   = { 0 };
    for (int src = maxSrc; src >= 1; src--)
    {
        /* 每试一版都重算“名字走了哪条路”，让日志里的数字只反映最终这一�?*/
        g_msgNameRawUtf8 = 0;
        g_msgNameGbkFallback = 0;

        const int used = DdhBuildShareItems(g_ddhTrack.src, g_ddhTrack.srcCount,
                                            g_ddhTrack.net, g_ddhTrack.raw,
                                            src, items, sizeof(items));
        if (used <= 0) { tmp[0] = 0; continue; }

        tmp[0] = 0;
        DdhAppendLabel(tmp, sizeof(tmp), isDeath ? "【伤害】" : "【当前伤害】");
        DdhAppendRaw(tmp, sizeof(tmp), items);
        if (strlen(tmp) <= DDH_MSG_MAX_BYTES)
        {
            strncpy_s(out, cap, tmp, _TRUNCATE);
            return;
        }
    }

    /* �?1 个来源都放不下（名字特别长）：硬截断 + “…�?*/
    if (tmp[0])
    {
        DdhTruncateUtf8(tmp, sizeof(tmp), DDH_MSG_MAX_BYTES);
        strncpy_s(out, cap, tmp, _TRUNCATE);
    }
}

static double DdhVictimKey(const DdhVictimStat* v)
{
    return v->net > 0.01 ? v->net : v->raw;
}

/* 没有记录单位�?Q 用的全局 Top5 受击单位（同样是 UTF-8：中文标签转、名字原样拼�?*/
static void DdhBuildGlobalTop5(char* out, size_t cap)
{
    if (!out || cap < 2) return;
    out[0] = 0;
    g_msgNameRawUtf8 = 0;
    g_msgNameGbkFallback = 0;

    int idx[DDH_GLOBAL_MAX];
    int n = 0;
    for (int i = 0; i < g_ddhGlobalCount; i++)
        if (g_ddhGlobal[i].hits > 0) idx[n++] = i;

    for (int i = 0; i < n; i++)
    {
        for (int j = i + 1; j < n; j++)
        {
            if (DdhVictimKey(&g_ddhGlobal[idx[j]]) > DdhVictimKey(&g_ddhGlobal[idx[i]]))
            { const int t = idx[i]; idx[i] = idx[j]; idx[j] = t; }
        }
    }

    DdhAppendLabel(out, cap, "【全局Top5受击】");
    if (n == 0)
    {
        DdhAppendLabel(out, cap, "还没统计到任何伤害事件（先打起来再按 Q）");
        return;
    }

    const int top = n < 5 ? n : 5;
    for (int k = 0; k < top; k++)
    {
        const DdhVictimStat* v = &g_ddhGlobal[idx[k]];
        char label[96] = { 0 };
        char num[48]   = { 0 };
        DdhLabelOf(v->label, v->code, v->unit, label, sizeof(label));
        DdhSprintf(num, sizeof(num), " %.2f/%u", DdhVictimKey(v), (unsigned)v->hits);
        DdhAppendRaw(out, cap, " ");
        DdhAppendUnitName(out, cap, label);
        DdhAppendRaw(out, cap, num);
        DdhAppendLabel(out, cap, "膵");
    }

    /* 同一�?420 字节上限（这里只硬截断，不逐级降级�?*/
    DdhTruncateUtf8(out, cap, DDH_MSG_MAX_BYTES);
}

/* ---------------------------------------------------------------------------
   广播：直投聊天（游戏自己的输入框 + 回车），失败再退兜底
   --------------------------------------------------------------------------- */

/* 判断一个入口像不像插件里验证过的那些函数：
   55 8B EC（标准序言�? 83 E9（sub ecx,0�? 6A FF（push -1 �?SEH 序言），
   或者被别的插件挂钩后的 E9（跳转目标可执行即算合法 —�?插件实机日志证实
   WFE �?0x153710 改成�?E9，照样能正常调）�?*/
static bool DdhChatEntryOk(uint32_t fn)
{
    if (fn < 0x10000u) return false;
    uint8_t b[6] = { 0 };
    __try
    {
        for (int i = 0; i < 6; i++) b[i] = *(const uint8_t*)(uintptr_t)(fn + (uint32_t)i);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }

    if ((b[0] == 0x55 && b[1] == 0x8B && b[2] == 0xEC) ||
        (b[0] == 0x83 && b[1] == 0xE9) ||
        (b[0] == 0x6A && b[1] == 0xFF))
        return true;

    if (b[0] == 0xE9)
    {
        uint32_t tgt = 0;
        __try { tgt = fn + 5u + *(const int32_t*)(uintptr_t)(fn + 1u); }
        __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery((LPCVOID)(uintptr_t)tgt, &mbi, sizeof(mbi)) &&
            mbi.State == MEM_COMMIT &&
            (mbi.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ |
                            PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY)))
            return true;
    }
    return false;
}

/* 懒校�?6 个地址。只在游戏线程调用（DdhDeliverText 里）�?*/
static void DdhInitChatDirect(void)
{
    if (InterlockedCompareExchange(&g_ddhChatInitDone, 1, 0) != 0) return;
    if (!g_modBase)
    {
        LogLine("结算广播：没有 game.dll 基址，直投聊天不可用");
        return;
    }

    struct Item { uint32_t rva; const char* name; uint32_t* slot; };
    Item items[6] = {
        { DDH_RVA_CHAT_GET_UNIT,  "get_unit",      &g_ddhChatGetUnit  },
        { DDH_RVA_CHAT_CLEARCHAT, "clear_chat",    &g_ddhChatClear    },
        { DDH_RVA_CHAT_SETRECIP,  "set_recipient", &g_ddhChatSetRecip },
        { DDH_RVA_CHAT_SETTEXT,   "SetText",       &g_ddhChatSetText  },
        { DDH_RVA_CHAT_GAMEWND,   "get_game_wnd",  &g_ddhChatGetWnd   },
        { DDH_RVA_CHAT_GAMEPROC,  "game_wndproc",  &g_ddhChatWndProc  },
    };

    for (int i = 0; i < 6; i++)
    {
        const uint32_t fn = g_modBase + items[i].rva;
        if (!DdhChatEntryOk(fn))
        {
            uint8_t b[4] = { 0 };
            __try { for (int k = 0; k < 4; k++) b[k] = *(const uint8_t*)(uintptr_t)(fn + (uint32_t)k); }
            __except (EXCEPTION_EXECUTE_HANDLER) { b[0] = 0; }
            LogLine("结算广播：直投聊天不可用 —�?%s(Game.dll+0x%X) 入口 %02X %02X %02X %02X 不符"
                    "（Game.dll 版本不匹配/被别的插件改过），只能用兜底显示（仅本机可见）",
                    items[i].name, items[i].rva, b[0], b[1], b[2], b[3]);
            return;
        }
    }

    for (int i = 0; i < 6; i++) *items[i].slot = g_modBase + items[i].rva;
    g_ddhChatOk = 1;
    LogLine("结算广播：直投聊天已就绪（6 个地址序言全部通过；收件人=全部；由游戏自己发送）");
}

/* 直投：取聊天 UI 对象 -> clear_chat / set_recipient(全部) -> SetText(UTF-8)
   -> 让游戏窗口过程收到一次回车。成功返�?1�?*/
static int DdhChatDirectSend(const char* utf8, char* why, size_t whyCap)
{
    if (!g_ddhChatOk)
    {
        DdhSprintf(why, whyCap, "直投聊天地址未就绪（见上一条日志）");
        return 0;
    }

    int ok = 0;
    __try
    {
        const uint32_t obj = ((fn_ddh_getunit_t)(uintptr_t)g_ddhChatGetUnit)(1, 0);
        uint32_t ui = 0;
        if (obj >= 0x10000u && obj <= 0x7FFFFFFFu)
            ui = *(const uint32_t*)(uintptr_t)(obj + DDH_OFF_CHAT_UI);

        HWND hwnd = (HWND)(uintptr_t)((fn_ddh_getwnd_t)(uintptr_t)g_ddhChatGetWnd)(0, 0);
        if (!hwnd) hwnd = FindWindowA("Warcraft III", NULL);
        if (!hwnd) hwnd = FindWindowA(NULL, "Warcraft III");

        if (!ui || !hwnd)
        {
            DdhSprintf(why, whyCap, "拿不到聊天 UI 对象(%08X)或游戏窗口(%p)", ui, (void*)hwnd);
            ok = 0;
        }
        else
        {
            ((fn_ddh_thiscall1_t)(uintptr_t)g_ddhChatClear)((void*)(uintptr_t)ui, NULL, 0);
            ((fn_ddh_thiscall1_t)(uintptr_t)g_ddhChatClear)((void*)(uintptr_t)ui, NULL, 1);
            ((fn_ddh_thiscall1_t)(uintptr_t)g_ddhChatSetRecip)((void*)(uintptr_t)ui, NULL, 0);
            ((fn_ddh_settext_t)(uintptr_t)g_ddhChatSetText)((void*)(uintptr_t)ui, NULL, utf8);
            ((fn_ddh_wndproc_t)(uintptr_t)g_ddhChatWndProc)((void*)hwnd, WM_KEYDOWN, (uintptr_t)VK_RETURN, 0);
            ((fn_ddh_wndproc_t)(uintptr_t)g_ddhChatWndProc)((void*)hwnd, WM_KEYUP,   (uintptr_t)VK_RETURN, 0);
            ok = 1;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        DdhSprintf(why, whyCap, "调用直投聊天异常 code=%08X", (unsigned)GetExceptionCode());
        ok = 0;
    }
    return ok;
}

/* ---------------------------------------------------------------------------
   兜底显示：DisplayTimedTextToPlayer（native 表按名字找）
   JASS native 的字符串参数要的�?YDWE string_fake 形态的【对象指针�?
   �?0x08 指向自身�?0x1C �?char* 正文），不是字符�?id —�?照插�?
   MakeJassString 的做法造一个常驻对象；传裸 char* 会让引擎解引用小整数而崩�?
   --------------------------------------------------------------------------- */
struct DdhFakeString { uint32_t m[8]; };
static DdhFakeString g_ddhStrObj[16];
static char          g_ddhStrBuf[16][512];
static unsigned      g_ddhStrIdx = 0;

static uint32_t DdhMakeJassString(const char* text)
{
    const unsigned i = g_ddhStrIdx++ % 16u;
    strncpy_s(g_ddhStrBuf[i], sizeof(g_ddhStrBuf[i]), text ? text : "", _TRUNCATE);
    memset(g_ddhStrObj[i].m, 0, sizeof(g_ddhStrObj[i].m));
    g_ddhStrObj[i].m[2] = (uint32_t)(uintptr_t)&g_ddhStrObj[i].m[0];   /* +0x08 指向自身 */
    g_ddhStrObj[i].m[7] = (uint32_t)(uintptr_t)g_ddhStrBuf[i];         /* +0x1C 正文 */
    return (uint32_t)(uintptr_t)&g_ddhStrObj[i];
}

static uint32_t DdhGetDtttp(void)
{
    if (g_ddhNatDtttp) return g_ddhNatDtttp;
    if (InterlockedIncrement(&g_ddhDtttpTries) > 16) return 0;
    g_ddhNatDtttp = FindNativeFunc("DisplayTimedTextToPlayer");
    if (g_ddhNatDtttp)
        LogLine("结算兜底：DisplayTimedTextToPlayer native 已定位（0x%08X）", g_ddhNatDtttp);
    else if (InterlockedIncrement(&g_ddhDtttpFailLogged) <= 3)
        LogLine("结算兜底：native 表里暂时找不到 DisplayTimedTextToPlayer（没有 JASS/还没进图），本次只能用日志");
    return g_ddhNatDtttp;
}

static uint32_t DdhGetPlayerNative(void)
{
    if (g_ddhNatPlayer) return g_ddhNatPlayer;
    if (InterlockedIncrement(&g_ddhPlayerTries) > 16) return 0;
    g_ddhNatPlayer = FindNativeFunc("Player");
    if (g_ddhNatPlayer)
        LogLine("结算兜底：Player native 已定位（0x%08X）", g_ddhNatPlayer);
    return g_ddhNatPlayer;
}

static uint32_t DdhGetPlayersNative(void)
{
    if (g_ddhNatGetPlayers) return g_ddhNatGetPlayers;
    if (InterlockedIncrement(&g_ddhPlayersTries) > 16) return 0;
    g_ddhNatGetPlayers = FindNativeFunc("GetPlayers");
    if (g_ddhNatGetPlayers)
        LogLine("结算兜底：GetPlayers native 已定位（0x%08X）", g_ddhNatGetPlayers);
    return g_ddhNatGetPlayers;
}

/* 发给每个玩家句柄（拿不到句柄就传 0）。返回成功调用的次数�? = 不可用�?
   注意：DisplayTimedTextToPlayer 是【本地显示】函数，即使传别人的句柄也不会上别人的屏�?
   所以日志里必须写明“仅本机可见”�?*/
static int DdhShowLocalText(const char* utf8)
{
    const uint32_t dt = DdhGetDtttp();
    if (!dt) return 0;

    const uint32_t s = DdhMakeJassString(utf8);
    if (!s) return 0;

    float x = 0.0f, y = 0.0f, dur = 10.0f;
    int shown = 0;

    __try
    {
        const uint32_t pn = DdhGetPlayerNative();

        int total = 12;
        const uint32_t gp = DdhGetPlayersNative();
        if (gp)
        {
            int t = 0;
            __try { t = (int)((uint32_t (__cdecl*)(void))(uintptr_t)gp)(); }
            __except (EXCEPTION_EXECUTE_HANDLER) { t = 0; }
            if (t > 0 && t <= 24) total = t;
        }

        if (!pn)
        {
            ((void (__cdecl*)(uint32_t, const float*, const float*, const float*, uint32_t))(uintptr_t)dt)
                (0, &x, &y, &dur, s);
            shown = 1;
        }
        else
        {
            uint32_t seen[24];
            for (int i = 0; i < total; i++)
            {
                uint32_t h = 0;
                __try { h = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)pn)((uint32_t)i); }
                __except (EXCEPTION_EXECUTE_HANDLER) { h = 0; }

                if (!h) continue;
                bool dup = false;
                for (int k = 0; k < shown; k++) if (seen[k] == h) { dup = true; break; }
                if (dup) continue;

                ((void (__cdecl*)(uint32_t, const float*, const float*, const float*, uint32_t))(uintptr_t)dt)
                    (h, &x, &y, &dur, s);
                seen[shown++] = h;
            }
            if (shown == 0)
            {
                ((void (__cdecl*)(uint32_t, const float*, const float*, const float*, uint32_t))(uintptr_t)dt)
                    (0, &x, &y, &dur, s);
                shown = 1;
            }
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("结算广播失败：兜底显示抛异常 code=%08X", (unsigned)GetExceptionCode());
        shown = 0;
    }
    return shown;
}

/* ---------------------------------------------------------------------------
   本机提示（热键反馈）：只调一�?DisplayTimedTextToPlayer，别的玩家看不到�?
   v11：Ctrl+Alt+R 选中 / Ctrl+Alt+S 开关都在这里给一句提示�?
   为什么不�?DdhDeliverText：那条路�?*直投公共聊天**（收件人=全部），
   热键反馈要是也广播出去，等于每按一�?R 就跟全房间喊一声，太吵�?
   --------------------------------------------------------------------------- */
static volatile LONG g_toastLogCount = 0;

static void DdhToast(const char* utf8)
{
    if (!utf8 || !utf8[0]) return;

    if (InterlockedIncrement(&g_toastLogCount) <= 20)
    {
        LogLine("热键提示（仅本机）：%s", utf8);
    }

    const uint32_t dt = DdhGetDtttp();
    if (!dt)
    {
        /* 屏幕提示不可用（native 还没就绪）：只留日志，绝不影响统�?*/
        return;
    }

    const uint32_t s = DdhMakeJassString(utf8);
    if (!s) return;

    /* 尽量只发给本机玩家：ctx+0x28 是本地玩家号�? 基），拿不到就传 0 */
    uint32_t player = 0;
    const uint32_t pn = DdhGetPlayerNative();
    if (pn && g_modBase)
    {
        const uint32_t ctx = SafeU32(g_modBase, DDH_RVA_CTX_GLOBAL);
        if (ctx >= 0x10000u && ctx <= 0x7FFFFFFFu)
        {
            const uint32_t pid = SafeU32(ctx, 0x28u) & 0xFFFFu;
            if (pid < 24u)
            {
                __try { player = ((uint32_t (__cdecl*)(uint32_t))(uintptr_t)pn)(pid); }
                __except (EXCEPTION_EXECUTE_HANDLER) { player = 0; }
            }
        }
    }

    float x = 0.0f, y = 0.05f, dur = 6.0f;
    __try
    {
        ((void (__cdecl*)(uint32_t, const float*, const float*, const float*, uint32_t))(uintptr_t)dt)
            (player, &x, &y, &dur, s);
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("热键提示：上屏抛异常 code=%08X（已吞掉，不影响统计）", (unsigned)GetExceptionCode());
    }
}

/* 发送一�?*已经�?UTF-8** 的消息：先直投广播，失败再兜底本机显示。只在游戏线程调用�?
   v10：这里不再做“整�?GBK→UTF-8”（那正是名字乱码的根源）——中文标签在组消息时
   已经转成 UTF-8，单位名是引擎给的原字节，见 DdhAppendLabel / DdhAppendUnitName�?*/
static void DdhDeliverText(const char* textUtf8)
{
    if (!textUtf8 || !textUtf8[0]) return;

    char utf8[1024] = { 0 };
    strncpy_s(utf8, sizeof(utf8), textUtf8, _TRUNCATE);

    /* 最后一道保险：超过 420 字节就按 UTF-8 边界截断并补 “…”（调用方理应已降级过） */
    DdhTruncateUtf8(utf8, sizeof(utf8), DDH_MSG_MAX_BYTES);
    const unsigned len = (unsigned)strlen(utf8);

    /* 把“组好的消息”写进日志（日志也是 UTF-8，直接写，肉眼就能核对）�?
       顺带写下本条名字走的是哪条路（原�?UTF-8 几个 / GBK 回退几个）�?*/
    if (InterlockedIncrement(&g_ddhMsgLogCount) <= 60)
    {
        LogLine("结算广播：消息（UTF-8 %u 字节；名字 原样UTF-8 %d 个 / GBK回退 %d 个）=%s",
                len, g_msgNameRawUtf8, g_msgNameGbkFallback, utf8);
    }

    DdhInitChatDirect();

    char why[192] = { 0 };
    if (DdhChatDirectSend(utf8, why, sizeof(why)))
    {
        if (InterlockedIncrement(&g_ddhSendOkCount) <= 100)
            LogLine("结算广播：已发送（长度 %u）", len);
        return;
    }

    if (InterlockedIncrement(&g_ddhSendFailCnt) <= 3)
        LogLine("结算广播失败：兜底显示抛异常 code=%08X", why);

    const int shown = DdhShowLocalText(utf8);
    if (shown > 0)
    {
        if (InterlockedIncrement(&g_ddhSendOkCount) <= 100)
            LogLine("结算广播：已发送（长度 %u，兜底本机显示 %d 个玩家句柄；仅本机可见）", len, shown);
    }
    else if (g_ddhSendFailCnt <= 3)
    {
        LogLine("结算广播失败：直投与兜底都不可用（长度 %u，本次不发；统计与日志不受影响）", len);
    }
}

/* ---------------------------------------------------------------------------
   统计：全局受击�?+ 记录单位
   --------------------------------------------------------------------------- */
static void DdhGlobalAdd(const DdhEvent* e)
{
    /* 只统计“真读到血差”的事件：单位死后假伤害不再刷次�?*/
    if (!e->hpValid) return;

    int idx = -1;
    for (int i = 0; i < g_ddhGlobalCount; i++)
        if (g_ddhGlobal[i].unit == e->victim) { idx = i; break; }

    if (idx < 0)
    {
        if (g_ddhGlobalCount >= DDH_GLOBAL_MAX) return;
        idx = g_ddhGlobalCount++;
        g_ddhGlobal[idx].unit   = e->victim;
        g_ddhGlobal[idx].code   = e->victimCode;
        g_ddhGlobal[idx].hits   = 0;
        g_ddhGlobal[idx].maxHit = 0.0f;
        g_ddhGlobal[idx].net    = 0.0;
        g_ddhGlobal[idx].raw    = 0.0;
        DdhUnitLabelSafe(e->victim, e->victimCode, g_ddhGlobal[idx].label, sizeof(g_ddhGlobal[idx].label));
    }

    DdhVictimStat* v = &g_ddhGlobal[idx];
    v->hits++;
    v->net += (double)e->actual;
    v->raw += (double)e->amount;
    if (e->actual > v->maxHit) v->maxHit = e->actual;
}

static void DdhTrackEvent(const DdhEvent* e)
{
    DdhGlobalAdd(e);

    if (!e->victim || e->victim != g_ddhTrack.unit) return;

    if (g_ddhTrack.dead)
    {
        /* 已经广播过死亡：等它复活（后血回到 > 0）再重新开一份统�?*/
        if (e->hpValid && e->hpAfter > 0.0f)
        {
            const uint32_t unit = e->victim;
            const uint32_t code = e->victimCode;
            memset(&g_ddhTrack, 0, sizeof(g_ddhTrack));
            g_ddhTrack.unit    = unit;
            g_ddhTrack.code    = code;
            g_ddhTrack.startMs = GetTickCount();
            DdhUnitLabelSafe(unit, code, g_ddhTrack.label, sizeof(g_ddhTrack.label));
            LogLine("热键：记录单位复活（0x%08X），统计已重置，继续跟踪", unit);
        }
        return;
    }

    const double eff = DdhEventEffective(e);
    const double net = e->hpValid ? (double)e->actual : 0.0;
    const double hit = e->hpValid ? net : eff;

    g_ddhTrack.hits++;
    g_ddhTrack.raw += (double)e->amount;
    if (e->engineValid) g_ddhTrack.engine += (double)e->engineDamage;
    g_ddhTrack.map += eff;
    g_ddhTrack.net += net;
    if (hit > (double)g_ddhTrack.maxHit) g_ddhTrack.maxHit = (float)hit;

    /* 来源累计：按类型码合并（同码不同单位算一条，显示按“名�?�?”）；没码就按指针分 */
    const uint32_t key = e->sourceCode ? e->sourceCode : e->source;
    DdhSrcStat* s = NULL;
    for (uint32_t i = 0; i < g_ddhTrack.srcCount; i++)
    {
        const DdhSrcStat* cur = &g_ddhTrack.src[i];
        const uint32_t curKey = cur->code ? cur->code : cur->source;
        if (curKey == key) { s = &g_ddhTrack.src[i]; break; }
    }
    if (!s && g_ddhTrack.srcCount < DDH_SRC_MAX)
    {
        s = &g_ddhTrack.src[g_ddhTrack.srcCount++];
        s->source  = e->source;
        s->code    = e->sourceCode;
        s->hits    = 0;
        s->maxHit  = 0.0f;
        s->raw     = 0.0;
        s->engine  = 0.0;
        s->map     = 0.0;
        s->net     = 0.0;
        DdhUnitLabelSafe(e->source, e->sourceCode, s->label, sizeof(s->label));
    }
    if (s)
    {
        s->hits++;
        s->raw += (double)e->amount;
        if (e->engineValid) s->engine += (double)e->engineDamage;
        s->map += eff;
        s->net += net;
        if (hit > (double)s->maxHit) s->maxHit = (float)hit;
    }

    /* 死亡：后血 <= 0 且本层前血 > 0（hpValid 就是这么定义的）。只排一次，发送在
       最外层伤害函数退出后（DdhProcessDeferred），避免在引擎扣血过程中调聊天函数�?
       v11：消息只发【伤害】来源占比（主段按用户要求不再发）。没有来源构成就干脆不发�?
       别在公共聊天里刷一条空消息�?*/
    if (e->hpValid && e->hpAfter <= 0.0f)
    {
        g_ddhTrack.dead = 1;
        DdhBuildTrackText(g_ddhDeferText, sizeof(g_ddhDeferText), 1);
        if (g_ddhDeferText[0])
        {
            g_ddhDeferKind = 1;
            LogLine("热键：记录单位 0x%08X 死亡（后血 %.2f），【伤害】已排队（本层伤害函数退出后发送）",
                    e->victim, (double)e->hpAfter);
        }
        else
        {
            LogLine("热键：记录单位当前血量 %.2f（开始累计它的受击）",
                    e->victim, (double)e->hpAfter);
        }
    }
}

/* v12：热键动作要**立刻**在游戏线程执�?—�?窗口消息通道（实现见 DdhProcessPending 之后�?*/
static int  DdhEnsureGameWnd(void);
static void DdhPostHotkeyToGame(void);

/* ---------------------------------------------------------------------------
   热键线程：只注册热键、收 WM_HOTKEY、置待办标志位，并立�?PostMessage 给游戏窗�?
   --------------------------------------------------------------------------- */
static DWORD WINAPI DdhHotkeyThreadProc(LPVOID)
{
    g_ddhHkThreadId = GetCurrentThreadId();

    const UINT mod = MOD_CONTROL | MOD_ALT | MOD_NOREPEAT;
    const BOOL rR = RegisterHotKey(NULL, DDH_HK_ID_R, mod, 'R');
    const BOOL rS = RegisterHotKey(NULL, DDH_HK_ID_S, mod, 'S');
    const BOOL rQ = RegisterHotKey(NULL, DDH_HK_ID_Q, mod, 'Q');

    LogLine("热键：线程已启动 tid=%lu，Ctrl+Alt+R=%s S=%s Q=%s（注册失败一般是被别的软件占用）",
            (unsigned long)g_ddhHkThreadId,
            rR ? "成功" : "失败", rS ? "成功" : "失败", rQ ? "成功" : "失败");

    if (!rR && !rS && !rQ)
    {
        LogLine("热键：三个组合键一个都没注册上，本次热键不可用（伤害钩子/统计不受影响）");
        /* �?return：仍要托管游戏窗口，面板 TTL tick / 属性投递还要靠这条线程�?*/
    }

    /* v12：先把游戏窗口挂上，之后每个热键都能立刻在游戏线程执行（毫秒级，不等伤害事件�?*/
    if (!DdhEnsureGameWnd())
        LogLine("热键：暂时没找到游戏窗口，动作会退化为“下一次伤害事件时处理”（有延迟）");

    /* v10：用 MsgWaitForMultipleObjects(100ms) 取代阻塞�?GetMessage —�?既收热键�?
       又每 100ms 看一眼“C# 有没有新的属性请求”，有就投给游戏窗口�?
       不引入额外线程，热键行为一个字节没变�?*/
    bool quit = false;
    while (!quit && InterlockedCompareExchange(&g_ddhHkStop, 0, 0) == 0)
    {
        const DWORD wait = MsgWaitForMultipleObjects(0, NULL, FALSE, 100, QS_ALLINPUT);
        if (wait == WAIT_OBJECT_0)
        {
            MSG msg;
            while (PeekMessageA(&msg, NULL, 0, 0, PM_REMOVE))
            {
                if (msg.message == WM_QUIT) { quit = true; break; }

                if (msg.message == WM_HOTKEY)
                {
                    /* 注意：WM_HOTKEY �?wParam 是【注册时给的 id】，不是按键码；
                       按键字母�?id 反查（以前这里直�?(char)wParam，日志里打出来是乱码）�?*/
                    char keyName = '?';
                    switch ((uint32_t)msg.wParam)
                    {
                    case DDH_HK_ID_R: InterlockedExchange(&g_ddhPendR, 1); keyName = 'R'; break;
                    case DDH_HK_ID_S: InterlockedExchange(&g_ddhPendS, 1); keyName = 'S'; break;
                    case DDH_HK_ID_Q: InterlockedExchange(&g_ddhPendQ, 1); keyName = 'Q'; break;
                    default: break;
                    }
                    /* 热键按下本身记一条（限流），真机排查“热键到底有没有被系统发给游戏”用 */
                    if (InterlockedIncrement(&g_ddhHkPressLogged) <= 30)
                        LogLine("热键：收到 Ctrl+Alt+%c（立刻投给游戏线程执行）", keyName);

                    /* v12：立刻让游戏线程执行，不再等下一次伤害事件�?
                       窗口不可用时待办标志已经置位，仍会走旧的伤害事件路径兜底�?*/
                    if (keyName != '?') DdhPostHotkeyToGame();
                }

                TranslateMessage(&msg);
                DispatchMessageA(&msg);
            }
        }
    }

    UnregisterHotKey(NULL, DDH_HK_ID_R);
    UnregisterHotKey(NULL, DDH_HK_ID_S);
    UnregisterHotKey(NULL, DDH_HK_ID_Q);
    LogLine("热键：线程退出（tid=%lu）", (unsigned long)g_ddhHkThreadId);
    return 0;
}

/* 第一次进伤害函数（游戏已经跑起来、DLL 也不在加载器锁里）时把热键线程拉起来 */
static void DdhEnsureHotkeyThread(void)
{
    if (InterlockedCompareExchange(&g_ddhHkStarted, 1, 0) != 0) return;

    LogLine("热键：游戏线程 tid=%lu，启动热键线程（Ctrl+Alt+R 记录选中单位 / S 自动发送 / Q 看统计）",
            (unsigned long)GetCurrentThreadId());

    g_ddhHkThread = CreateThread(NULL, 0, DdhHotkeyThreadProc, NULL, 0, NULL);
    if (!g_ddhHkThread)
        LogLine("热键：CreateThread 失败 err=%lu（本次热键不可用，伤害钩子不受影响）", GetLastError());
}

/* 读选区链。usedAlt 回传是否走了备用�?sel+0x08�?
   全程 __try；任何一跳不合法都返�?0，由调用方写日志�?*/
static uint32_t DdhReadSelection(int* usedAlt)
{
    if (usedAlt) *usedAlt = 0;
    if (!g_modBase) return 0;

    uint32_t unit = 0;
    __try
    {
        const uint32_t ctx = SafeU32(g_modBase, DDH_RVA_CTX_GLOBAL);
        if (ctx < 0x10000u || ctx > 0x7FFFFFFFu) return 0;

        const uint32_t pid = SafeU32(ctx, 0x28u) & 0xFFFFu;
        if (pid >= 24u) return 0;

        const uint32_t player = SafeU32(ctx, 0x58u + 4u * pid);
        if (player < 0x10000u || player > 0x7FFFFFFFu) return 0;

        const uint32_t sel = SafeU32(player, 0x34u);
        if (sel < 0x10000u || sel > 0x7FFFFFFFu) return 0;

        uint32_t node = SafeU32(sel, 0x1F0u);
        if (node >= 0x10000u && node <= 0x7FFFFFFFu)
        {
            unit = SafeU32(node, 8u);
            if (unit >= 0x10000u && unit <= 0x7FFFFFFFu) return unit;
        }

        node = SafeU32(sel, 0x08u);
        if (node >= 0x10000u && node <= 0x7FFFFFFFu)
        {
            unit = SafeU32(node, 8u);
            if (unit >= 0x10000u && unit <= 0x7FFFFFFFu)
            {
                if (usedAlt) *usedAlt = 1;
                return unit;
            }
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        unit = 0;
    }
    return unit;
}

/* ---- R：记录当前选中的单位（统计清零，之后一直跟它） ----
   v11：选中/选不中都�?*本机消息�?*给一句提示（DdhToast，只本机可见，不进公共聊天）�?*/
static void DdhDoRecord(void)
{
    int usedAlt = 0;
    const uint32_t unit = DdhReadSelection(&usedAlt);
    if (!unit)
    {
        if (InterlockedIncrement(&g_ddhHkFailLogged) <= 10)
            LogLine("热键：Ctrl+Alt+R 没取到选中单位（选区链为空：先左键点一个单位再按）");

        char msg[256] = { 0 };
        DdhAppendLabel(msg, sizeof(msg), "【未选中】先左键点一个单位，再按 Ctrl+Alt+R");
        DdhToast(msg);
        return;
    }

    const uint32_t code = SafeCode(unit);
    const uint32_t oldUnit = g_ddhTrack.unit;
    const uint32_t oldHits = g_ddhTrack.hits;

    memset(&g_ddhTrack, 0, sizeof(g_ddhTrack));
    g_ddhTrack.unit    = unit;
    g_ddhTrack.code    = code;
    g_ddhTrack.startMs = GetTickCount();

    char label[96] = { 0 };
    DdhUnitLabel(unit, code, label, sizeof(label));
    strncpy_s(g_ddhTrack.label, sizeof(g_ddhTrack.label), label, _TRUNCATE);

    if (InterlockedIncrement(&g_ddhHkActionLogged) <= 40)
        LogLine("热键：Ctrl+Alt+R 已记录 %s 0x%08X（%s链；%s）",
                label, unit,
                usedAlt ? "备用 sel+0x08" : "sel+0x1F0",
                oldUnit ? "旧的记录已替换、统计清零" : "新记录");

    /* 本机消息区提示（名字按原字节拼，别再转码�?*/
    {
        char msg[256] = { 0 };
        DdhAppendLabel(msg, sizeof(msg), "【已选中】");
        DdhAppendUnitName(msg, sizeof(msg), label);
        DdhToast(msg);
    }

    float hp = 0.0f;
    if (ReadUnitHp(unit, &hp))
    {
        if (hp <= 0.0f)
            LogLine("热键：记录单位当前血量 %.2f（已死亡/空壳），统计要等它复活后才有数据", (double)hp);
        else
            LogLine("热键：记录单位当前血量 %.2f（开始累计它的受击）", (double)hp);
    }
    else
    {
        LogLine("热键：记录单位当前血量读不到（句柄管理器/引擎访问器都没通过），统计可能全 0");
    }

    if (oldUnit && oldUnit != unit && oldHits > 0)
        LogLine("热键：上一个记录单位 0x%08X 的 %u 次受击统计已丢弃", oldUnit, (unsigned)oldHits);
}

/* ---- S：自动发送开关（统计照旧，只是不再发�?----
   v11：开/关都在本机消息区提示一句（只本机可见，不进公共聊天）�?*/
static void DdhDoToggle(void)
{
    const LONG cur = InterlockedCompareExchange(&g_ddhAutoSend, 0, 0);
    const LONG now = cur ? 0 : 1;
    InterlockedExchange(&g_ddhAutoSend, now);

    if (InterlockedIncrement(&g_ddhHkToggleLogged) <= 40)
        LogLine("热键：自动发送=%s（统计照常，%s）", now ? "开" : "关", now ? "死亡时会发结算" : "死亡时不再发");

    char msg[256] = { 0 };
    if (now) DdhAppendLabel(msg, sizeof(msg), "【已开启】死亡结算会自动发送");
    else     DdhAppendLabel(msg, sizeof(msg), "【已取消】死亡结算不再自动发送");
    DdhToast(msg);
}

/* ---- Q：立即发一条当前来源占比（【当前伤害】…） ---- */
static void DdhDoQuery(void)
{
    char text[768] = { 0 };
    g_msgNameRawUtf8 = 0;
    g_msgNameGbkFallback = 0;
    if (g_ddhTrack.unit)
    {
        DdhBuildTrackText(text, sizeof(text), 0);
        /* 刚记上还没打中过：给一句短的，别让 Q 看起来像没反�?*/
        if (!text[0]) DdhAppendLabel(text, sizeof(text), "【当前伤害】暂无");
    }
    else
    {
        DdhBuildGlobalTop5(text, sizeof(text));
    }

    if (!text[0])
    {
        LogLine("Q 统计：没有可发的统计（既没有记录单位，也还没统计到伤害）");
        return;
    }

    if (InterlockedIncrement(&g_ddhHkQueryLogged) <= 40)
    {
        LogLine("Q 统计：%s", text);
    }

    DdhDeliverText(text);
}

/* 待办热键（只在游戏线程调用） */
static void DdhProcessPending(void)
{
    if (InterlockedExchange(&g_ddhPendR, 0)) DdhDoRecord();
    if (InterlockedExchange(&g_ddhPendS, 0)) DdhDoToggle();
    if (InterlockedExchange(&g_ddhPendQ, 0)) DdhDoQuery();
}

/* ---------------------------------------------------------------------------
   v12：热�?-> 游戏线程 的“窗口消息通道�?
   ---------------------------------------------------------------------------
   为什么要有它：热键动作必须调引擎（读选区内存、ResolveName、DisplayTimedTextToPlayer�?
   直投聊天），这些都只能在游戏线程上跑；而热键是注册在一个独立线程上的�?
   以前只能借“下一次伤害事件”当执行�?—�?没人挨打就一直不响应（用户反馈的延迟）�?
   现在照插�?UDamageWatcherHook.cpp 的同款做法：
     · 热键线程 PostMessage(游戏窗口, WM_APP+0xDD)�?
     · 窗口过程被我们子类化（SetWindowLongPtrW），消息就在**游戏线程**的消息循环里
       派发，当场执�?DdhProcessPending() —�?按完即出提示（毫秒级）�?
   · 游戏切分辨率/全屏/重开窗口时会把窗口过程改回去 �?每次投递前校验并自动重挂�?
   · DLL 卸载（DllMain DETACH）必须把窗口过程还回去，否则窗口还指着已卸载的代码�?
   --------------------------------------------------------------------------- */
#define DDH_WM_HOTKEY (WM_APP + 0xDD)
/* v10：属性请求通道。热键线程每 100ms 看一眼请求序号，有新请求就投这条消息�?
   游戏窗口过程在游戏线程里当场处理（和热键同一条通道，绝不跨线程�?JASS）�?*/
#define DDH_WM_DAMAGE_DEFERRED (WM_APP + 0xE5)
static void DdhProcessDeferred(void);

static WNDPROC g_prevWndProc = NULL;
static volatile LONG g_wndLogCount = 0;
static volatile LONG g_wndCand     = 0;   /* 上次枚举到几个“本进程的可见窗口”（诊断用） */
static char    g_wndClass[64] = { 0 };    /* 选中的窗口类名（诊断用） */
static char    g_wndTitle[96] = { 0 };    /* 选中的窗口标题（诊断用） */
static int     g_wndUnicode  = 0;         /* 1 = 这个窗口�?Unicode（W 版）�? = ANSI（A 版） */

struct DdhWndPick { int score; long area; };

/* 枚举本进程可见窗口挑游戏窗口。规则（真机踩过的坑都写在这）：
     · 跳过 conhost 的控制台窗口（ConsoleWindowClass）—�?它的窗口过程改不�?
       （SetWindowLongPtr 返回 0 + err=5），早期版本就是挑中它才“挂不上窗口”；
     · 优先 类名 == "Warcraft III"（真魔兽）；其次标题里带 Warcraft/魔兽�?
     · 同档里取面积最大的（全屏时就是游戏窗口）�?*/
static BOOL CALLBACK DdhEnumWndProc(HWND hwnd, LPARAM lp)
{
    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    if (pid != GetCurrentProcessId() || !IsWindowVisible(hwnd)) return TRUE;
    InterlockedIncrement(&g_wndCand);

    char cls[64] = { 0 };
    char title[128] = { 0 };
    GetClassNameA(hwnd, cls, sizeof(cls));
    GetWindowTextA(hwnd, title, sizeof(title));
    if (_stricmp(cls, "ConsoleWindowClass") == 0) return TRUE;

    RECT r = { 0, 0, 0, 0 };
    if (!GetWindowRect(hwnd, &r)) return TRUE;
    const long area = (long)(r.right - r.left) * (long)(r.bottom - r.top);

    int score = 0;
    if (_stricmp(cls, "Warcraft III") == 0)             score = 3;
    else if (strstr(title, "Warcraft") || strstr(title, "魔兽")) score = 2;

    DdhWndPick* pick = (DdhWndPick*)lp;
    if (score > pick->score || (score == pick->score && area > pick->area))
    {
        pick->score = score;
        pick->area  = area;
        g_gameWnd   = hwnd;
        strncpy_s(g_wndClass, sizeof(g_wndClass), cls, _TRUNCATE);
        strncpy_s(g_wndTitle, sizeof(g_wndTitle), title, _TRUNCATE);
    }
    return TRUE;
}

static LRESULT CALLBACK DdhGameWndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
{
    if (msg == DDH_WM_DAMAGE_DEFERRED)
    {
        __try { DdhProcessDeferred(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("Damage deferred processing failed: %08X", (unsigned)GetExceptionCode());
        }
        return 0;
    }

    if (msg == DDH_WM_HOTKEY)
    {
        /* 这个回调就在游戏线程上，引擎调用是安全的（和插件 OnHotkeyGameThread 同款�?*/
        __try { DdhProcessPending(); }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("热键：处理待办异常 code=%08X（已吞掉，不影响伤害钩子）", (unsigned)GetExceptionCode());
        }
        return 0;
    }

    /* 其它消息一律原样转给游戏自己的窗口过程，绝不吞�?
       注意 A/W 必须配对：魔�?1.27 的窗口是 ANSI 类（RegisterClassA），�?CallWindowProcW
       转发会把 WM_CHAR / WM_SETTEXT 之类�?Unicode 解释，轻则聊天输入错乱、重则崩游戏�?*/
    if (g_prevWndProc)
        return g_wndUnicode ? CallWindowProcW(g_prevWndProc, hwnd, msg, wp, lp)
                            : CallWindowProcA(g_prevWndProc, hwnd, msg, wp, lp);
    return g_wndUnicode ? DefWindowProcW(hwnd, msg, wp, lp)
                        : DefWindowProcA(hwnd, msg, wp, lp);
}

/* 找到（或重新找到）游戏窗口并挂上我们的窗口过程。返�?1 = 可用�?*/
static int DdhEnsureGameWnd(void)
{
    if (g_gameWnd && IsWindow(g_gameWnd))
    {
        if (g_prevWndProc &&
            GetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC) != (LONG_PTR)DdhGameWndProc)
        {
            /* 游戏自己把窗口过程改回去了（切分辨率/全屏/重开窗口）→ 重新挂上 */
            g_wndUnicode = IsWindowUnicode(g_gameWnd) ? 1 : 0;
            g_prevWndProc = g_wndUnicode
                ? (WNDPROC)SetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)DdhGameWndProc)
                : (WNDPROC)SetWindowLongPtrA(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)DdhGameWndProc);
            if (InterlockedIncrement(&g_wndLogCount) <= 8)
                LogLine("热键：窗口过程被游戏改回，已重新挂上（窗口 %p）", (void*)g_gameWnd);
        }
        return g_prevWndProc ? 1 : 0;
    }

    g_gameWnd = NULL;
    g_prevWndProc = NULL;
    g_wndCand = 0;
    DdhWndPick pick;
    pick.score = -1;          /* -1 保证第一个候选（哪�?score=0）一定被选中 */
    pick.area  = -1;
    EnumWindows(DdhEnumWndProc, (LPARAM)&pick);
    if (!g_gameWnd)
    {
        if (InterlockedIncrement(&g_wndLogCount) <= 8)
            LogLine("热键：没找到可挂的游戏窗口（本进程可见窗口 %d 个，最后一个 %s「%s」；控制台窗口会被跳过）",
                    (int)g_wndCand, g_wndClass, g_wndTitle);
        return 0;
    }

    g_wndUnicode = IsWindowUnicode(g_gameWnd) ? 1 : 0;
    g_prevWndProc = g_wndUnicode
        ? (WNDPROC)SetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)DdhGameWndProc)
        : (WNDPROC)SetWindowLongPtrA(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)DdhGameWndProc);
    if (!g_prevWndProc)
    {
        if (InterlockedIncrement(&g_wndLogCount) <= 8)
            LogLine("热键：SetWindowLongPtrW 失败（窗口 %p 类=%s「%s」err=%lu），热键只能等伤害事件",
                    (void*)g_gameWnd, g_wndClass, g_wndTitle, GetLastError());
        g_gameWnd = NULL;
        return 0;
    }

    if (InterlockedIncrement(&g_wndLogCount) <= 8)
        LogLine("热键：已挂到游戏窗口 %p（类=%s「%s」，%s 版），动作会立刻在游戏线程执行（不再等伤害事件）",
                (void*)g_gameWnd, g_wndClass, g_wndTitle, g_wndUnicode ? "Unicode/W" : "ANSI/A");
    return 1;
}

/* 热键线程用：把“该处理待办了”立刻投给游戏线程；失败就退回旧的伤害事件路径�?*/
static void DdhPostHotkeyToGame(void)
{
    if (!DdhEnsureGameWnd())
    {
        if (InterlockedIncrement(&g_wndLogCount) <= 8)
            LogLine("热键：没找到游戏窗口，本次动作退化为“下一次伤害事件时处理”（有延迟）");
        return;
    }
    if (!PostMessageW(g_gameWnd, DDH_WM_HOTKEY, 0, 0))
    {
        if (InterlockedIncrement(&g_wndLogCount) <= 8)
            LogLine("热键：PostMessage 失败 err=%lu（退回伤害事件处理，有延迟）", GetLastError());
    }
}

/* DLL 卸载时把窗口过程还回去；游戏还活着的窗口不还，就会“跳到已卸载的模块”崩溃�?*/
static void DdhRestoreGameWnd(void)
{
    if (g_gameWnd && g_prevWndProc && IsWindow(g_gameWnd) &&
        GetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC) == (LONG_PTR)DdhGameWndProc)
    {
        if (g_wndUnicode) SetWindowLongPtrW(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)g_prevWndProc);
        else              SetWindowLongPtrA(g_gameWnd, GWLP_WNDPROC, (LONG_PTR)g_prevWndProc);
        LogLine("热键：窗口过程已还原（DLL 卸载）");
    }
    g_gameWnd = NULL;
    g_prevWndProc = NULL;
}

/* 最外层伤害函数退出后执行：先发排队中的死亡结算，再处理热键待办�?
   全程 __try —�?任何一步抛异常都只写日志，绝不影响伤害钩子本身�?*/
static void DdhProcessDeferred(void)
{
    DdhCompletePendingEvents();

    __try
    {
        if (InterlockedExchange(&g_ddhDeferKind, 0) != 0)
        {
            if (InterlockedCompareExchange(&g_ddhAutoSend, 0, 0) == 0)
            {
                if (InterlockedIncrement(&g_ddhSendSkipLogged) <= 10)
                    LogLine("结算广播：自动发送=关，本次不发送（长度 %u；统计仍在继续）",
                            (unsigned)strlen(g_ddhDeferText));
            }
            else
            {
                DdhDeliverText(g_ddhDeferText);
            }
            g_ddhDeferText[0] = 0;
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("结算广播失败：处理待发结算异常 code=%08X（已吞掉）", (unsigned)GetExceptionCode());
    }

    __try
    {
        DdhProcessPending();
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("热键：处理待办异常 code=%08X（已吞掉，不影响伤害钩子）", (unsigned)GetExceptionCode());
    }

}

/* ===========================================================================
   v28：游戏内【死亡结算】按钮
   ---------------------------------------------------------------------------
   参考 KK 平台游戏内按钮的形态（常驻屏幕上的小按钮，点一下就开面板），但实现
   不跟它一样去 hook 渲染层：KK 是 ImGui 覆盖层（War3Plugin.dll 自带 imgui+
   opengl32），我们直接用引擎自己的帧（CBackdropFrame + CTextFrame）——
   不用管图形后端、分辨率或 UI 缩放，也不会和引擎抢输入。

   · 位置：左上菜单栏下方（UI 坐标 0.8 x 0.6，左上锚点）
   · 显示：只在“进图后”显示（主菜单/载入界面不显示）
   · 点击：面板没开 -> 打开死亡结算页；已开 -> 收起
           还没有任何结算数据时 -> 弹一条提示，告诉用户打完一仗再来
   · 关闭：环境变量 DDH_NO_BUTTON=1（调试用）
   =========================================================================== */
/* ===========================================================================
   DDH_ENGINE_PROBE —�?探针：地图不�?GetEventDamage 时，能不能自己拿到“引擎伤害”？
   ---------------------------------------------------------------------------
   背景�?026-11-01）：GetEventDamage 的实现就�?`mov eax,[eax+0x30]; ret`
   （game.dll+0x1E21D0 �?0x1E5D70 取当前事件对�?�?+0x30 就是“引擎伤害”）�?
   所以这个值本身一直存在，缺的只是**采样时机**：引擎在伤害函数内部、护甲算�?
   之后才写 +0x30，而我们的钩子在函数入口；等原函数返回，事件对象已经出栈�?

   本探针不改任何统计，只在每次伤害事件�?*入口**�?*出口**各调一�?
   GetEventDamage 的原实现（地址在手、__try 保护），把结果和“地图真读到的首值�?
   （g_engineCap/g_engineFirstSet）和“原始伤害”（info+0x10）摆在同一行日志里�?
     · 入口就相�?    �?现有钩子直接补，不用加新钩子（最省事）；
     · 出口才相�?    �?也能用；
     · 两边都不�?    �?另找采样点（钩“写 +0x30”的指令 / 钩触发器派发）�?

   开关（默认关，两种都认）：
     · 环境变量 DDH_ENGINE_PROBE=1�?
     · 或�?ddh.dll/日志同目录放一个空文件 ddh_engineprobe.on
       （启动器不继承环境变量时用这个）�?
   日志形如�?
     引擎探针[12] depth=1 原始=548.00 入口+0x30=438.40 出口+0x30=438.40 地图首�?438.40 取次=44
   =========================================================================== */
static int            g_engineProbe       = 0;    /* 0=未定�?1=开 -1=�?*/
static volatile LONG  g_engineProbeLogged = 0;
static volatile LONG  g_engineProbeNoCall = 0;
static uint32_t       g_probeEntryOk[DDH_MAXDEPTH];
static float          g_probeEntryVal[DDH_MAXDEPTH];
static uint32_t       g_probeInfo[DDH_MAXDEPTH];      /* 本层伤害结构�?info 指针（出口时用来 dump 字段�?*/

/* 文件开关：日志目录下的 ddh_engineprobe.on。 */
static int DdhEngineProbeFlagFile(void)
{
    char dir[MAX_PATH] = { 0 };
    if (g_logPath[0]) strncpy_s(dir, sizeof(dir), g_logPath, _TRUNCATE);
    char* slash = strrchr(dir, '\\');
    if (!slash) slash = strrchr(dir, '/');
    if (slash) slash[1] = 0;
    else dir[0] = 0;
    char path[MAX_PATH] = { 0 };
    DdhSprintf(path, sizeof(path), "%sddh_engineprobe.on", dir);
    const DWORD attr = GetFileAttributesA(path);
    return attr != INVALID_FILE_ATTRIBUTES && !(attr & FILE_ATTRIBUTE_DIRECTORY);
}

static int DdhEngineProbeOn(void)
{
    if (g_engineProbe != 0) return g_engineProbe > 0;

    int on = 0;
    char buf[32] = { 0 };
    const DWORD n = GetEnvironmentVariableA("DDH_ENGINE_PROBE", buf, (DWORD)sizeof(buf));
    if (n > 0 && n < (DWORD)sizeof(buf))
        on = !(_stricmp(buf, "0") == 0 || _stricmp(buf, "false") == 0 ||
               _stricmp(buf, "no") == 0 || _stricmp(buf, "off") == 0);
    else
        on = DdhEngineProbeFlagFile() ? 1 : 0;

    g_engineProbe = on ? 1 : -1;
    if (on)
        LogLine("引擎探针：已开启（%s）——每次伤害只多读两次内存，不改统计；"
                "日志形如“引擎探针[n] depth=.. 原始=.. 入口+0x30=.. 出口+0x30=.. 地图首值=.. 取次=..”",
                (n > 0 && n < (DWORD)sizeof(buf)) ? "DDH_ENGINE_PROBE" : "ddh_engineprobe.on");
    return on;
}

/* 调一�?GetEventDamage 的原实现�? 读当前事件对�?+0x30）。读不到/不在事件�?ok=0�?*/
static void DdhEngineProbeSample(uint32_t* ok, float* val)
{
    if (ok) *ok = 0;
    if (val) *val = 0.0f;
    if (!g_realGetEventDamage) return;

    uint32_t r = 0;
    __try { r = ((uint32_t (__cdecl*)(void))(uintptr_t)g_realGetEventDamage)(); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return; }

    float f = 0.0f;
    memcpy(&f, &r, 4);
    if (!(f > -1.0e12f && f < 1.0e12f)) return;
    if (ok) *ok = 1;
    if (val) *val = f;
}

/* 取“当�?JASS 事件对象”指针：�?GetEventDamage 的实现里把访问器地址抠出�?
   �?x1E21D0 �?+0x0C 处是 `E8 rel32` �?0x1E5D70），比写�?RVA 稳一点�?
   不在事件�?取不到就返回 0�?*/
static uint32_t DdhEngineEventObj(void)
{
    if (!g_realGetEventDamage) return 0;
    const uint8_t* p = (const uint8_t*)(uintptr_t)g_realGetEventDamage;
    if (p[0x0C] != 0xE8) return 0;

    int32_t rel = 0;
    memcpy(&rel, p + 0x0D, 4);
    const uint32_t fn = (uint32_t)(uintptr_t)(p + 0x11) + (uint32_t)rel;

    uint32_t obj = 0;
    __try { obj = ((uint32_t (__cdecl*)(void))(uintptr_t)fn)(); }
    __except (EXCEPTION_EXECUTE_HANDLER) { obj = 0; }
    if (obj < 0x10000u || obj > 0x7FFFFFFFu) return 0;
    return obj;
}

static void DdhEngineProbeEntry(uint32_t level, uint32_t infoPtr)
{
    if (level >= DDH_MAXDEPTH) return;
    g_probeInfo[level]     = infoPtr;
    g_probeEntryOk[level]  = 0;
    g_probeEntryVal[level] = 0.0f;

    /* 只在“还会写日志”的�?220 条事件里采样：探针最怕的是对每一发伤害都去调
       引擎访问器（一局几万次），那样出事也说不清是谁弄的�?*/
    if (InterlockedCompareExchange(&g_engineProbeLogged, 0, 0) < 220)
        DdhEngineProbeSample(&g_probeEntryOk[level], &g_probeEntryVal[level]);
}

static void DdhEngineProbeExit(uint32_t level, const DdhEvent* e, uint32_t seq)
{
    if (level >= DDH_MAXDEPTH) return;

    /* 先算“这条要不要记”，不记就直接走 —�?采样本身就是要额外调引擎函数，越少越�?*/
    const uint32_t calls = (uint32_t)g_engineCalls[level];
    const LONG total = InterlockedIncrement(&g_engineProbeLogged);
    bool want = (total <= 80);
    if (!want && calls == 0 && InterlockedIncrement(&g_engineProbeNoCall) <= 40) want = true;
    if (!want || total > 160) return;

    uint32_t ok = 0;
    float v = 0.0f;
    DdhEngineProbeSample(&ok, &v);

    float raw = 0.0f;
    if (e && e->seq == seq) raw = e->amount;

    char ent[24] = { 0 }, ext[24] = { 0 }, mapFirst[24] = { 0 };
    if (g_probeEntryOk[level]) DdhSprintf(ent, sizeof(ent), "%.2f", (double)g_probeEntryVal[level]);
    else                       strcpy_s(ent, sizeof(ent), "?");
    if (ok)                    DdhSprintf(ext, sizeof(ext), "%.2f", (double)v);
    else                       strcpy_s(ext, sizeof(ext), "?");
    if (g_engineFirstSet[level])
    {
        float f = 0.0f;
        memcpy(&f, &g_engineCap[level], 4);
        DdhSprintf(mapFirst, sizeof(mapFirst), "%.2f", (double)f);
    }
    else strcpy_s(mapFirst, sizeof(mapFirst), "?");

    /* info 结构体出口快照：看“护甲后的引擎伤害”有没有被引擎写回某个字�?
       （有 �?不用再加 hook；没�?�?只能在事件派发期间另开采样点） */
    char dump[160] = { 0 };
    char hit[24] = { 0 };
    const uint32_t ip = g_probeInfo[level];
    uint32_t d[10] = { 0 };
    bool dumpOk = false;
    if (ip > 0x10000 && ip < 0x7FFFFFFF)
    {
        __try
        {
            const uint32_t* p = (const uint32_t*)(uintptr_t)ip;
            for (int i = 0; i < 10; i++) d[i] = p[i];
            dumpOk = true;
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { dumpOk = false; }
    }
    if (dumpOk)
    {
        DdhSprintf(dump, sizeof(dump), "%08X %08X %08X %08X %08X %08X %08X %08X %08X %08X",
                   d[0], d[1], d[2], d[3], d[4], d[5], d[6], d[7], d[8], d[9]);
        if (g_engineFirstSet[level])
        {
            float mv = 0.0f;
            memcpy(&mv, &g_engineCap[level], 4);
            for (int i = 0; i < 10; i++)
            {
                float f = 0.0f;
                memcpy(&f, &d[i], 4);
                if (d[i] != 0 && fabs((double)f - (double)mv) <= 0.011)
                {
                    DdhSprintf(hit, sizeof(hit), "+0x%02X", i * 4);
                    break;
                }
            }
        }
        if (!hit[0]) strcpy_s(hit, sizeof(hit), g_engineFirstSet[level] ? "膵" : "?");
    }
    else
    {
        strcpy_s(dump, sizeof(dump), "?");
        strcpy_s(hit, sizeof(hit), "?");
    }

    char objTxt[24] = { 0 };
    const uint32_t eobj = DdhEngineEventObj();
    if (eobj)
    {
        float ov = 0.0f;
        __try { memcpy(&ov, (const void*)(uintptr_t)(eobj + 0x30), 4); }
        __except (EXCEPTION_EXECUTE_HANDLER) { ov = 0.0f; }
        DdhSprintf(objTxt, sizeof(objTxt), "%.2f", (double)ov);
    }
    else strcpy_s(objTxt, sizeof(objTxt), "无对象");

    LogLine("引擎探针[%ld] depth=%u 原始=%.2f 入口+0x30=%s 出口+0x30=%s 对象+0x30=%s 地图首值=%s 取次=%u 命中=%s 结构=%s",
            (long)total, level + 1, (double)raw, ent, ext, objTxt, mapFirst, (unsigned)calls, hit, dump);
}
/* ---- 替换函数：与 UDamageWatcherHook.cpp �?OurDamageFunc 同款 ----
   安装时把 0x67DC40 �?6 字节改成 jmp 到这里（__fastcall：ecx=_this, edx=_edx,
   栈上 4 个参�?a2/info/is_physical/source_unit）。函数里�?
     �?深度 +1、本层状态清零；�?懒挂 GetEventDamage/SetEventDamage�?
     �?读前血；④ RecordDamage 写事件（原始伤害 info+0x10 原样保留）；
     �?自己 call 原函数（跳板 �?原函数体 �?ret 0x10 回到这里），返回值原样带回；
     �?读后血、算 gross/own、补 hpAfter/actual/hpValid、给同目标父帧累计；
     �?写引擎伤�?设定值、诊断日志；�?记录单位的统�?死亡排队（v9）；
     �?深度 -1，回到最外层时处理热键待办和待发结算（v9）；�?return retval�?
   收尾�?ret 0x10（callee �?4 个栈参），与引擎原函数一致，�?build 后的反汇编校验�?*/
static uint32_t __fastcall DdhDamageFunc(uint32_t _this, uint32_t _edx, uint32_t a2,
                                         void* info, uint32_t is_physical, uint32_t source_unit)
{
    /* v9：第一次进伤害函数时把热键线程拉起来（此时游戏已就绪，也不在加载器锁里�?*/

    /* 深度 +1；超过上限就不加（否则收尾的深度 -1 会对不上，深度永久泄漏）�?
       这一层仍然要跑原函数、把返回值原样带回去 —�?只是不再单独�?after�?*/
    LONG d = InterlockedIncrement(&g_depth);
    if (d > DDH_MAXDEPTH)
    {
        InterlockedDecrement(&g_depth);
        if (InterlockedIncrement(&g_depthOverflowLogged) == 1)
            LogLine("嵌套溢出：深度超过 %u 层，已退化为不记账（本进程只提示这一次）",
                    (uint32_t)DDH_MAXDEPTH);
        RecordDamage(_this, (uint32_t)(uintptr_t)info, is_physical, source_unit,
                     (uint32_t)DDH_MAXDEPTH + 1, 0, 0.0f, NULL);
        InterlockedExchange(&g_evReady[g_shm ? (((g_shm->hdr.count - 1) % DDH_MAX_EVENTS)) : 0], 1);
        uint32_t rv = 0;
        if (g_original_damage)
        {
            __try { rv = ((fn_damage_t)(uintptr_t)g_original_damage)(_this, _edx, a2, info, is_physical, source_unit); }
            __except (EXCEPTION_EXECUTE_HANDLER) { rv = 0; }
        }
        return rv;
    }

    uint32_t level = (uint32_t)(d - 1);
    const uint32_t now = GetTickCount();

    /* 防漏：SEH 展开/异常会让某一层永远不返回，深度会一路涨上去�?
       父层入口距今超过 2 �?�?认为之前那几层已经丢了，重新�?0 算�?*/
    if (level > 0 && (now - g_levelTick[level - 1]) > 2000)
    {
        InterlockedExchange(&g_depth, 1);
        level = 0;
    }

    /* 每层状态清零（引擎伤害/设定�?子层累计/前血等） */
    g_engineCap[level] = 0;
    g_engineFirstSet[level] = 0;
    g_engineLast[level] = 0;
    g_engineCalls[level] = 0;
    g_setCap[level] = 0;
    g_setSet[level] = 0;
    g_setCalls[level] = 0;

    if (NativeDamageHooksOn())        /* v20：默认不挂，出口三读就够 */
    {
        TryHookGetEventDamage();      /* 只在诊断模式下拿"地图读了几次" */
        TryHookSetEventDamage();      /* 只在诊断模式下拿"地图改了几次" */
    }
    /* 探针（默认关）：入口先采一次“引擎伤害”，出口再采一次，和地图首值对�?*/
    if (DdhEngineProbeOn()) DdhEngineProbeEntry(level, (uint32_t)(uintptr_t)info);

    float hp = 0.0f;
    const bool ok = ReadUnitHp(_this, &hp);

    uint32_t seq = 0;
    g_slot[level] = RecordDamage(_this, (uint32_t)(uintptr_t)info, is_physical, source_unit,
                                 level + 1, ok ? 1u : 0u, hp, &seq);
    g_seq[level] = seq;
    /* v13：压�?—�?本帧�?victim / 前血 / 同目标子帧累计起点都记在帧里 */
    DdhFrame* frame    = DdhFramePush(level, _this, hp, ok ? 1u : 0u);
    g_levelTick[level] = now;
    QueryPerformanceCounter(&g_qpcStart[level]);

    /* 自己 call 原函数（跳板 �?原函数体 �?ret 0x10 回到这里）。返回值原样带回�?*/
    uint32_t retval = 0;
    if (g_original_damage)
    {
        __try
        {
            retval = ((fn_damage_t)(uintptr_t)g_original_damage)(_this, _edx, a2, info, is_physical, source_unit);
        }
        __except (EXCEPTION_EXECUTE_HANDLER)
        {
            LogLine("E 原伤害函数抛出异常，已吞掉（code=%08X）", (uint32_t)GetExceptionCode());
            retval = 0;
        }
    }

    /* ---- v20：出口三读（全部来自这一个钩子）---------------------------------
       �?引擎伤害 = 出口 info+0x10。护�?0x6F64FBF0 / 攻防类型 0x6F64D7F0 /
          攻击类型�?0x6FBEC34C 的结果都�?0x6F6971C0 原地写回 info+0x10
          （`mov [ebx+0x10],eax`），所以出口值就是引擎算完的数。伤害事�?
          （id 0x80234）在乘算**之后**才发，地�?SetEventDamage 只改 *out /
          game+0xBB81D4，不回写 info+0x10 —�?这就�?引擎�?地图�?能分开的原因�?
       �?最终伤�?= 出口 *a2。a2 是调用方�?out 指针（原函数 [ebp+8]），也就�?
          WFE 读来画伤害数字的那块内存�? 个出口里 4 个抄 game+0xBB81D4，主路径
          按主管道重算，两者都已含地图改写�?
       �?净掉血 = 前后血差（下面 DdhFramePop 算，口径不变）�?*/
    float    exitEngine   = 0.0f;
    uint32_t exitEngineOk = 0;
    float    finalRaw     = 0.0f;
    uint32_t finalReadOk  = 0;
    {
        const uint32_t ip = (uint32_t)(uintptr_t)info;
        if (ip > 0x10000u && ip < 0x7FFFFFFFu)
        {
            __try
            {
                memcpy(&exitEngine, (const void*)(uintptr_t)(ip + 0x10u), 4);
                exitEngineOk = 1;
            }
            __except (EXCEPTION_EXECUTE_HANDLER) { exitEngineOk = 0; }
            if (exitEngineOk && !(exitEngine > -1.0e12f && exitEngine < 1.0e12f))
            {
                exitEngine = 0.0f;
                exitEngineOk = 0;
            }
        }
        const uint32_t op = a2;                       /* 调用�?out（float*�?*/
        if (op > 0x10000u && op < 0x7FFFFFFFu)
        {
            __try
            {
                memcpy(&finalRaw, (const void*)(uintptr_t)op, 4);
                finalReadOk = 1;
            }
            __except (EXCEPTION_EXECUTE_HANDLER) { finalReadOk = 0; }
            if (finalReadOk && !(finalRaw > -1.0e12f && finalRaw < 1.0e12f))
            {
                finalRaw = 0.0f;
                finalReadOk = 0;
            }
        }
    }

    /* 读后血：就�?call 返回后的第一件事（和插件同款时机�?*/
    float hpAfter = 0.0f;
    const bool hpAfterOk = ReadUnitHp(_this, &hpAfter);

    DdhEvent* e = NULL;
    if (g_shm) e = &g_shm->ev[g_slot[level] % DDH_MAX_EVENTS];

    /* 引擎伤害：默认由下面�?出口 info+0x10"给；开�?DDH_NATIVE_DAMAGE_HOOKS
       并且地图真读�?GetEventDamage 时，用钩子抓到的首值（两者相等，钩子那份还能
       顺带�?取次"）。没抓到�?engineValid=0 �?界面显示 ? */
    if (e && e->seq == g_seq[level])
    {
        float eng = 0.0f;
        uint32_t engOk = g_engineFirstSet[level] ? 1u : 0u;   /* 首值可能是合法�?0.0，所以看标志�?*/
        if (engOk)
        {
            memcpy(&eng, &g_engineCap[level], 4);
            if (!(eng > -1.0e12f && eng < 1.0e12f)) { eng = 0.0f; engOk = 0; }
        }
        e->engineDamage = eng;
        e->engineValid  = engOk;
        float setVal = 0.0f;
        if (g_setSet[level])
        {
            memcpy(&setVal, &g_setCap[level], 4);
            if (!(setVal > -1.0e12f && setVal < 1.0e12f)) setVal = 0.0f;
        }
        e->setDamage = setVal;
        e->setCalls  = (uint32_t)g_setCalls[level];
    }

    /* v20：引擎伤�?= 出口 info+0x10（见上面"出口三读"①）�?
       老实现要求三道闸门（没读�?/ 没改�?/ 来源匹配）才肯用回读值，是因为当�?
       只有�?地图完全不碰伤害事件"时才敢断定出口值等�?GetEventDamage。现�?
       从这里能看清：事件改写根本不回写 info+0x10，所以出口�?*永远**是引擎值，
       地图改没改都不影响。真机两例仍然吻合：
         原始 5.00  �?出口 info+0x10 = 4.46（地图读�?4.46；护�?2 = 10.71% 减伤�?
         原始 16.00 �?出口 info+0x10 = 14.29（地图读�?14.29，同一护甲�?
       只有打开�?DDH_NATIVE_DAMAGE_HOOKS 且地图真读过 GetEventDamage 时，
       才优先用钩子抓到的首值（两者本就相等，钩子那份还能顺带�?取次"）�?*/
    if (e && e->seq == g_seq[level] && !g_engineFirstSet[level] && exitEngineOk && e->source)
    {
        if (exitEngine > 0.005f && exitEngine < 1.0e9f)
        {
            e->engineDamage = exitEngine;
            e->engineValid  = 1;
            /* engineCalls 的槽 v20 已改�?finalFlags，这里不再写 */
        }
    }

    /* 前血 <= 0 说明这一刻目标已经死�?读的是空�?—�?这种�?�?”没有意义，按“没测到”处理，
       界面显示 ?，不要拿 0 冒充“实际伤害”�?
       v13：own 交给帧栈算（整段 - 同目标子帧合计），退帧时顺手�?gross 报给同目标父帧�?*/
    float gross = 0.0f, own = 0.0f;
    const float fallback = (e && e->engineValid && e->engineDamage > 0.0f)
                           ? (float)e->engineDamage : 0.0f;
    const bool measured = DdhFramePop(frame, (e && e->seq == g_seq[level]) ? 1u : 0u,
                                      hpAfter, hpAfterOk ? 1u : 0u, fallback, &gross, &own);
    if (!measured)
    {
        LogLine("HP失败: level=%u seq=%u eSeq=%u slot=%u hpOk=%u rowOk=%u afterOk=%u before=%.2f after=%.2f victim=0x%08X",
                level, g_seq[level], e ? e->seq : 0u, g_slot[level],
                frame ? frame->hpOk : 0u,
                (e && e->seq == g_seq[level]) ? 1u : 0u,
                hpAfterOk ? 1u : 0u, hp, hpAfter, _this);
    }
    /* 探针（默认关）：出口再采一次，日志里和入口�?/ 地图首值并排对�?*/
    if (g_engineProbe > 0) DdhEngineProbeExit(level, e, g_seq[level]);
    if (e)
    {
        if (measured)
        {
            /* 前血/后血都在，actual = 本帧自己的净掉血（已经扣掉同目标子帧�?*/
            e->hpAfter = hpAfter;
            e->actual  = own;
            e->hpValid = 1;
            InterlockedIncrement((volatile LONG*)&g_hpCount);
        }
        else
        {
            e->hpValid = 0;
            e->hpAfter  = 0.0f;
            e->actual   = 0.0f;
        }
    }

    /* ---- v20：最终伤�?= 出口 *out�?出口三读"②）---------------------------
       这就�?WFE 画伤害数字时读的那块内存，含地图 SetEventDamage 的改写�?
       只在**确实掉了血**（本�?own > 0.005）时才认�?
         无敌 [unit+0x5C]&0x100、免�?[unit+0x158]/[+0x15C]>0、flags&4 这些早退
         分支根本不计算，直接把上一跳残留在 game+0xBB81D4 的值抄�?*out；那种情�?
         �?own = 0，这里一律不认，避免把旧数字当成这次的地图伤害�?
       finalFlags bit0 = 可信，bit1 = 与引擎值不同（= 地图改过伤害）�?*/
    if (e && e->seq == g_seq[level])
    {
        const bool finalOk = finalReadOk && e->engineValid;
        /* 溢出钳制：引擎在落地前会把伤害钳�?目标剩余血�?
           �?x6F67F340 �?`min(*out, vtbl[0x12c]())`，那一路读的就是当前生命）�?
           所以击杀那一刀 *out = 前血，而不是地图改写值。真机实测：
             引擎 387.12 / 前血 219.52 �?地图 219.52、净掉血 219.52
             引擎 170.29 / 前血  79.82 �?地图  79.82、净掉血  79.82
           这种行如果按"最�?�?引擎"去算倍数会得�?0.57×/0.47×，看着像地图减伤，
           其实是溢出。所以单独置 bit2，并且这种情况下不置 bit1（不算地图改过）�?*/
        bool clamped = false;
        if (finalOk && frame && frame->hpBefore > 0.0f && finalRaw < e->engineDamage - 0.005f)
        {
            float dh = finalRaw - frame->hpBefore;
            if (dh < 0.0f) dh = -dh;
            clamped = dh <= 0.02f;
        }
        float d = finalRaw - e->engineDamage;
        if (d < 0.0f) d = -d;
        const bool over = finalOk && !clamped && d > 0.005f;
        e->finalDamage = finalOk ? finalRaw : 0.0f;
        e->finalFlags  = (finalOk ? 1u : 0u) | (over ? 2u : 0u) | (clamped ? 4u : 0u);
    }

    /* ---- 诊断：地图伤�?�?引擎伤害时记一行（带伤害函数耗时�?--- */
    if (e)
    {
        float diff = e->actual - e->engineDamage;
        if (diff < 0.0f) diff = -diff;
        if (e->hpValid && e->engineValid && diff > 0.05f &&
            InterlockedIncrement(&g_hpLogCount) <= 300)
        {
            LARGE_INTEGER qpcNow;
            QueryPerformanceCounter(&qpcNow);
            double us = (g_qpcFreq.QuadPart > 0)
                ? (double)(qpcNow.QuadPart - g_qpcStart[level].QuadPart) * 1000000.0 / (double)g_qpcFreq.QuadPart
                : 0.0;
            float setVal = 0.0f;
            if (g_setSet[level])
            {
                memcpy(&setVal, &g_setCap[level], 4);
                if (!(setVal > -1.0e12f && setVal < 1.0e12f)) setVal = 0.0f;
            }
            LogLine("HP差 depth=%u 原始=%.2f 引擎=%.2f 最终=%.2f 改过=%u 取次=%u 设定=%.2f 设次=%u 前血=%.3f 后血=%.3f 整段=%.2f 本层=%.2f 子层=%.2f 耗时=%.0fus",
                    e->depth, e->amount, e->engineDamage, e->finalDamage,
                    (uint32_t)((e->finalFlags >> 1) & 1u), (uint32_t)g_engineCalls[level],
                    setVal, (uint32_t)g_setCalls[level],
                    frame->hpBefore, hpAfter, gross, own, frame->childSumSameVictim, us);
        }
    }

    /* v9：如果这一层的事件还是我们刚才写的那条（没被环覆盖），拿它更新记录单位�?
       统计；目标后血 <= 0 时把死亡结算排到“本层退出后”再发�?*/
    if (e && e->seq == g_seq[level])
    {
        /* Metadata was captured at event start while both CUnit objects were alive. */
        DdhTrackEvent(e);
    }

    MemoryBarrier();

    /* 深度 -1；回�?0 说明最外层伤害函数要返回了 —�?这时才处理热键待办和待发结算�?
       避免在引擎扣血过程中调游戏自己的聊�?显示函数�?*/
    const LONG left = InterlockedDecrement(&g_depth);
    if (left == 0)
    {
        /* Keep all JASS/UI work out of the engine damage call stack. */
        if (!g_gameWnd || !IsWindow(g_gameWnd) ||
            !PostMessageA(g_gameWnd, DDH_WM_DAMAGE_DEFERRED, 0, 0))
            DdhMarkPendingReadyWithoutEngine();
    }

    return retval;
}

/* 跳板 = 被搬走的�?6 字节 + E9 跳回原函数体�?x67DC40+6）�?
   DdhDamageFunc �?call 这个跳板，原函数结尾 ret 0x10 时回到我们�?*/

static const int STEAL = 6;

static bool MakeTrampoline(uint8_t* at, uint8_t* tramp)
{
    /* 55 8B EC 83 EC 2C : push ebp; mov ebp,esp; sub esp,0x2C */
    const uint8_t stolen[STEAL] = { 0x55, 0x8B, 0xEC, 0x83, 0xEC, 0x2C };
    if (memcmp(at, stolen, STEAL) != 0) return false;

    memcpy(tramp, stolen, STEAL);
    uint8_t* p = tramp + STEAL;
    p[0] = 0xE9;
    int32_t rel = (int32_t)((at + STEAL) - (p + 5));
    memcpy(p + 1, &rel, 4);
    return true;
}

/* ---------------------------------------------------------------------------
   在已经加载的 game.dll 里找伤害函数。写�?RVA 不够用：平台联机/观战加载的是
   13,467,648 字节的镜像（磁盘那份�?13,187,048），镜像被改过，RVA 可能整体偏移�?
   特征（来自仓�?`WFE伤害机制分析.md`�?.27.0.52240 上验证过）：
     开�?55 8B EC 83 EC 2C 56 57 8B F9，且函数�?~0x300 内同时出�?
     立即�?0x04000000 �?0x00400000（伤害类型掩码分支的魔法值）�?
--------------------------------------------------------------------------- */
static void DdhFormatHexBytes(char* out, size_t cap, const uint8_t* data, size_t count)
{
    if (!out || cap == 0) return;
    out[0] = 0;
    size_t used = 0;
    for (size_t i = 0; i < count && used + 4 < cap; ++i)
    {
        const int n = DdhSprintf(out + used, cap - used, "%02X ", data[i]);
        if (n <= 0) break;
        used += (size_t)n;
    }
}

/* Some platform/plugin damage hooks replace the function entry with jmp.
   Their detour library keeps a trampoline containing the original six-byte
   prologue followed by a jump back to entry+6. Hooking that trampoline lets
   ddh observe the same calls without overwriting the other plugin's entry. */
static uint8_t* FindExistingDamageTrampoline(uint8_t* gameBase)
{
    static const uint8_t pro[STEAL] = { 0x55, 0x8B, 0xEC, 0x83, 0xEC, 0x2C };
    uint8_t* expectedReturn = gameBase + HOOK_RVA + STEAL;

    uintptr_t address = 0x10000;
    const uintptr_t limit = 0x7FFF0000u;
    while (address < limit)
    {
        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery((LPCVOID)address, &mbi, sizeof(mbi)) == 0)
        {
            address += 0x1000;
            continue;
        }

        uintptr_t regionBase = (uintptr_t)mbi.BaseAddress;
        uintptr_t regionEnd = regionBase + mbi.RegionSize;
        if (regionEnd <= regionBase) break;

        const DWORD prot = mbi.Protect & 0xFFu;
        const bool readableExecutable =
            mbi.State == MEM_COMMIT &&
            !(mbi.Protect & (PAGE_GUARD | PAGE_NOACCESS)) &&
            (prot == PAGE_EXECUTE || prot == PAGE_EXECUTE_READ ||
             prot == PAGE_EXECUTE_READWRITE || prot == PAGE_EXECUTE_WRITECOPY);
        if (readableExecutable && mbi.RegionSize > STEAL + 5)
        {
            __try
            {
                const uint8_t* begin = (const uint8_t*)regionBase;
                const uint8_t* end = (const uint8_t*)regionEnd;
                for (const uint8_t* p = begin; p + STEAL + 5 <= end; ++p)
                {
                    if (memcmp(p, pro, STEAL) != 0 || p[STEAL] != 0xE9) continue;
                    int32_t rel = 0;
                    memcpy(&rel, p + STEAL + 1, sizeof(rel));
                    const uint8_t* target = p + STEAL + 5 + rel;
                    if (target != expectedReturn) continue;
                    LogLine("检测到已有伤害钩子的原始跳板：%p（原入口 0x%08X）",
                            (const void*)p, (unsigned)(uintptr_t)(gameBase + HOOK_RVA));
                    return (uint8_t*)p;
                }
            }
            __except (EXCEPTION_EXECUTE_HANDLER) { }
        }
        address = regionEnd;
    }
    return NULL;
}

static bool MatchPrologue(const uint8_t* p)
{
    static const uint8_t pro[10] = { 0x55, 0x8B, 0xEC, 0x83, 0xEC, 0x2C, 0x56, 0x57, 0x8B, 0xF9 };
    return memcmp(p, pro, 10) == 0;
}

static bool HasImm(const uint8_t* p, size_t window, uint32_t imm)
{
    for (size_t i = 0; i + 4 <= window; i++)
    {
        uint32_t v; memcpy(&v, p + i, 4);
        if (v == imm) return true;
    }
    return false;
}

static uint8_t* FindDamageFunc(uint8_t* base, size_t imageSize)
{
    /* 1) 先看已知 RVA 对不�?*/
    uint8_t* known = base + HOOK_RVA;
    if (MatchPrologue(known)) { LogLine("伤害函数就在已知 RVA 0x%X", HOOK_RVA); return known; }
    DdhFormatHexBytes(g_hookKnownBytes, sizeof(g_hookKnownBytes), known, 16);
    LogLine("已知 RVA 0x%X 开头不是预期字节（%02X %02X %02X %02X %02X %02X %02X %02X %02X %02X），改特征扫描",
            HOOK_RVA, known[0], known[1], known[2], known[3], known[4], known[5], known[6], known[7], known[8], known[9]);

    /* 2) 已被其它插件挂钩时，优先串接它保存的原始跳板。 */
    uint8_t* existingTrampoline = FindExistingDamageTrampoline(base);
    if (existingTrampoline) return existingTrampoline;

    /* 3) 特征扫描 */
    const size_t window = 0x300;
    size_t limit = imageSize > 10 + window ? imageSize - 10 - window : 0;
    for (size_t i = 0; i < limit; i++)
    {
        if (!MatchPrologue(base + i)) continue;
        const uint8_t* p = base + i;
        if (!HasImm(p, window, 0x04000000u)) continue;
        if (!HasImm(p, window, 0x00400000u)) continue;
        LogLine("特征扫描命中：RVA 0x%X", (unsigned)i);
        return base + i;
    }
    LogLine("特征扫描也没找到伤害函数 —— 这个构建和已知版本差异太大");
    return NULL;
}

static bool InstallHook()
{
    if (g_hooked) return true;
    if (GetFileAttributesA("C:\\launch\\ddh_disable_damage_hook.flag") != INVALID_FILE_ATTRIBUTES)
    {
        LogLine("Damage hook disabled by C:\\launch\\ddh_disable_damage_hook.flag");
        strncpy_s(g_hookLastError, sizeof(g_hookLastError),
                  "disabled by C:\\launch\\ddh_disable_damage_hook.flag", _TRUNCATE);
        return false;
    }

    HMODULE game = NULL;
    for (int i = 0; i < 60 && !game; i++) { game = GetModuleHandleA("game.dll"); if (!game) Sleep(100); }
    if (!game)
    {
        LogLine("找不到 game.dll（游戏还没起来？）");
        strncpy_s(g_hookLastError, sizeof(g_hookLastError), "game.dll not loaded", _TRUNCATE);
        return false;
    }

    size_t imageSize = 0;
    bool validPe = false;
    {
        IMAGE_DOS_HEADER* dos = (IMAGE_DOS_HEADER*)game;
        IMAGE_NT_HEADERS32* nt = (IMAGE_NT_HEADERS32*)((uint8_t*)game + dos->e_lfanew);
        if (dos->e_magic == IMAGE_DOS_SIGNATURE && nt->Signature == IMAGE_NT_SIGNATURE)
        {
            imageSize = nt->OptionalHeader.SizeOfImage;
            validPe = imageSize > HOOK_RVA + 16;
        }
    }
    if (!validPe)
    {
        strncpy_s(g_hookLastError, sizeof(g_hookLastError), "invalid game.dll PE image", _TRUNCATE);
        return false;
    }
    g_modBase = (uint32_t)(uintptr_t)game;
    g_imageSize = (uint32_t)imageSize;   /* 协议 v13：视�?RVA 越界校验用（PE SizeOfImage�?*/
    LogLine("game.dll base=0x%08X 映像大小=0x%X", (unsigned)(uintptr_t)game, (unsigned)imageSize);

    g_hookAt = FindDamageFunc((uint8_t*)game, imageSize);
    if (!g_hookAt)
    {
        strncpy_s(g_hookLastError, sizeof(g_hookLastError),
                  "damage function signature not found", _TRUNCATE);
        return false;
    }
    {
        const uintptr_t gameAddress = (uintptr_t)game;
        const uintptr_t targetAddress = (uintptr_t)g_hookAt;
        g_foundRva = targetAddress >= gameAddress && targetAddress < gameAddress + imageSize
            ? (uint32_t)(targetAddress - gameAddress)
            : HOOK_RVA;
    }
    const bool hookedExistingTrampoline =
        (uintptr_t)g_hookAt < (uintptr_t)game ||
        (uintptr_t)g_hookAt >= (uintptr_t)game + imageSize;
    LogLine("挂钩目标：RVA 0x%X（地址 0x%08X；已有跳板=%d）",
            g_foundRva, (unsigned)(uintptr_t)g_hookAt,
            hookedExistingTrampoline ? 1 : 0);

    /* 新挂载方式：入口直接 jmp �?DdhDamageFunc（__fastcall，收�?ret 0x10），
       函数里先记前血 �?call 原函数（跳板）→ 返回后立刻记后血 �?算本层掉血�?
       不再改栈上返回地址，也就不再需要“函数体里有没有 ret 0x10”这道门禁�?*/
    LogLine("实际伤害采集：开（call 原函数后读血，与插件同款）");

    g_tramp = (uint8_t*)VirtualAlloc(NULL, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!g_tramp)
    {
        LogLine("VirtualAlloc(tramp) 失败 %lu", GetLastError());
        DdhSprintf(g_hookLastError, sizeof(g_hookLastError),
                   "VirtualAlloc failed: %lu", GetLastError());
        return false;
    }

    memcpy(g_saved, g_hookAt, 8);
    if (!MakeTrampoline(g_hookAt, g_tramp))
    {
        LogLine("函数开头不是预期的 55 8B EC 83 EC 2C（实际 %02X %02X %02X %02X %02X %02X）—— 不挂钩",
                g_saved[0], g_saved[1], g_saved[2], g_saved[3], g_saved[4], g_saved[5]);
        VirtualFree(g_tramp, 0, MEM_RELEASE);
        g_tramp = NULL;
        strncpy_s(g_hookLastError, sizeof(g_hookLastError),
                  "damage function prologue changed", _TRUNCATE);
        return false;
    }

    DWORD old = 0;
    if (!VirtualProtect(g_hookAt, 16, PAGE_EXECUTE_READWRITE, &old))
    {
        LogLine("VirtualProtect 失败 %lu", GetLastError());
        DdhSprintf(g_hookLastError, sizeof(g_hookLastError),
                   "VirtualProtect failed: %lu", GetLastError());
        VirtualFree(g_tramp, 0, MEM_RELEASE);
        g_tramp = NULL;
        return false;
    }

    /* 先把跳板地址填进 g_original_damage：DdhDamageFunc �?call �?= 跑原函数体�?
       （跳�?= 搬走�?6 字节 + E9 跳回 0x67DC40+6，原函数结尾 ret 0x10 回到我们�?*/
    g_original_damage = (LONG)(uintptr_t)g_tramp;

    /* E9 rel32 + NOP �?DdhDamageFunc（共 6 字节，正好盖�?3 条完整指令） */
    g_hookAt[0] = 0xE9;
    int32_t rel = (int32_t)((uint8_t*)&DdhDamageFunc - (g_hookAt + 5));
    memcpy(g_hookAt + 1, &rel, 4);
    g_hookAt[5] = 0x90;
    FlushInstructionCache(GetCurrentProcess(), g_hookAt, 8);
    VirtualProtect(g_hookAt, 16, old, &old);
    g_hooked = true;
    strncpy_s(g_hookLastError, sizeof(g_hookLastError), "hook installed", _TRUNCATE);
    LogLine("挂钩成功：0x%08X 前 6 字节已改成 jmp DdhDamageFunc（rel=0x%X，跳板=0x%08X）",
            (unsigned)(uintptr_t)g_hookAt, rel, (unsigned)(uintptr_t)g_tramp);
    return true;
}

static bool DdhDamageHookDisabledByFlag()
{
    return GetFileAttributesA("C:\\launch\\ddh_disable_damage_hook.flag") != INVALID_FILE_ATTRIBUTES;
}

static void DdhWriteHookStatus(uint32_t attempt, bool ok)
{
    char base[MAX_PATH] = { 0 };
    if (GetEnvironmentVariableA("LOCALAPPDATA", base, (DWORD)sizeof(base)) == 0 || !base[0])
        GetTempPathA((DWORD)sizeof(base), base);

    char dir[MAX_PATH] = { 0 };
    DdhSprintf(dir, sizeof(dir), "%s\\War3DeathSettlement", base);
    CreateDirectoryA(dir, NULL);
    DdhSprintf(dir, sizeof(dir), "%s\\War3DeathSettlement\\logs", base);
    CreateDirectoryA(dir, NULL);

    char path[MAX_PATH] = { 0 };
    DdhSprintf(path, sizeof(path), "%s\\ddh-hook-%lu.log", dir, GetCurrentProcessId());
    FILE* f = NULL;
    if (fopen_s(&f, path, "w") != 0 || !f) return;
    fprintf(f, "pid=%lu\nattempt=%lu\nok=%d\nlast_error=%s\ngame_dll_base=0x%08X\nhook_rva=0x%X\nknown_rva_bytes=%s\n",
            GetCurrentProcessId(), attempt, ok ? 1 : 0, g_hookLastError,
            (unsigned)g_modBase, g_foundRva, g_hookKnownBytes);
    fclose(f);
}

static DWORD WINAPI DdhHookInstallThread(LPVOID)
{
    uint32_t attempt = 0;
    for (;;)
    {
        ++attempt;
        if (g_shm) g_shm->hdr.reserved[4] = attempt;
        if (InstallHook())
        {
            if (g_shm)
            {
                g_shm->hdr.reserved[0] = 1u;
                g_shm->hdr.hookOk = 1;
                g_shm->hdr.gameDllBase = g_modBase;
                g_shm->hdr.hookRva = g_foundRva;
                MemoryBarrier();
            }
            DdhWriteHookStatus(attempt, true);
            LogLine("伤害钩子：第 %lu 次尝试安装成功", attempt);
            return 0;
        }
        if (attempt <= 3 || (attempt % 20) == 0)
            DdhWriteHookStatus(attempt, false);
        const DWORD retryDelay = attempt <= 3 ? 500 : (attempt <= 10 ? 1000 : 5000);
        Sleep(retryDelay);
    }
}

/* 删除超过 days 天的 ddh 日志（统一日志目录用） */
static void DdhCleanupOldLogs(const char* dir, int days)
{
    char pattern[MAX_PATH] = { 0 };
    DdhSprintf(pattern, sizeof(pattern), "%s\\ddh-*.log", dir);
    WIN32_FIND_DATAA fd;
    HANDLE h = FindFirstFileA(pattern, &fd);
    if (h == INVALID_HANDLE_VALUE) return;
    const ULONGLONG now = (ULONGLONG)time(NULL);
    do
    {
        if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) continue;
        ULONGLONG mt = ((ULONGLONG)fd.ftLastWriteTime.dwHighDateTime << 32) | fd.ftLastWriteTime.dwLowDateTime;
        mt = mt / 10000000ULL - 11644473600ULL;
        if (mt + (ULONGLONG)days * 86400ULL < now)
        {
            char full[MAX_PATH] = { 0 };
            DdhSprintf(full, sizeof(full), "%s\\%s", dir, fd.cFileName);
            DeleteFileA(full);
        }
    } while (FindNextFileA(h, &fd));
    FindClose(h);
}

static void SetupShared()
{
    DWORD pid = GetCurrentProcessId();
    /* 日志放哪：① �?ddh.dll 同目录（最常见、肯定可写、也最好找�?
                 �?C:\ddh-<pid>.log（老版本位置，兼容既有说明/习惯�?
                 �?%TEMP%\ddh-<pid>.log（兜底）
       选第一�?*真的能写**的。注意别只写�?C:\：普通权限的游戏写不了根目录�?
       以前就是静默失败 �?日志凭空消失�?*/
    {
        char dllPath[MAX_PATH] = { 0 };
        if (g_self && GetModuleFileNameA(g_self, dllPath, MAX_PATH) > 0)
        {
            char* slash = strrchr(dllPath, '\\');
            if (slash) { slash[1] = 0; strcat_s(dllPath, "ddh_log.on"); g_logEnabled = (GetFileAttributesA(dllPath) != INVALID_FILE_ATTRIBUTES) ? 1 : 0; }
        }
    }

    bool logOk = false;
    if (!g_logEnabled) { g_logPath[0] = 0; logOk = true; }   /* 发布包：不建日志文件 */
    /* 统一日志目录：%LOCALAPPDATA%\War3DeathSettlement\logs（C# 前端同目录） */
    {
        char appdata[MAX_PATH] = { 0 };
        if (GetEnvironmentVariableA("LOCALAPPDATA", appdata, MAX_PATH) > 0)
        {
            char dir[MAX_PATH] = { 0 };
            DdhSprintf(dir, sizeof(dir), "%s\\War3DeathSettlement", appdata);
            CreateDirectoryA(dir, NULL);
            DdhSprintf(dir, sizeof(dir), "%s\\War3DeathSettlement\\logs", appdata);
            CreateDirectoryA(dir, NULL);
            DdhSprintf(g_logPath, sizeof(g_logPath), "%s\\ddh-%lu.log", dir, pid);
            FILE* t = NULL;
            if (fopen_s(&t, g_logPath, "a") == 0 && t) { fclose(t); logOk = true; }
            if (logOk) DdhCleanupOldLogs(dir, 2);
        }
    }
    if (!logOk)
    {
        DdhSprintf(g_logPath, sizeof(g_logPath), "C:\\ddh-%lu.log", pid);
        FILE* t = NULL;
        if (fopen_s(&t, g_logPath, "a") == 0 && t) { fclose(t); logOk = true; }
    }
    if (!logOk)
    {
        char tmp[MAX_PATH] = { 0 };
        if (GetTempPathA(sizeof(tmp), tmp) > 0)
        {
            DdhSprintf(g_logPath, sizeof(g_logPath), "%sddh-%lu.log", tmp, pid);
            FILE* t = NULL;
            if (fopen_s(&t, g_logPath, "a") == 0 && t) { fclose(t); logOk = true; }
        }
    }

    QueryPerformanceFrequency(&g_qpcFreq);
    g_shm = &g_localRing;
    memset(g_shm, 0, sizeof(DdhShared));
    g_shm->hdr.magic = DDH_MAGIC;
    g_shm->hdr.version = DDH_VERSION;
    g_shm->hdr.pid = pid;
    g_shm->hdr.capacity = DDH_MAX_EVENTS;
    g_shm->hdr.hookRva = HOOK_RVA;
    g_shm->hdr.selfTest = 1;
    g_shm->hdr.reserved[0] = 0;        /* v3：先占位，InstallHook 确认能力后再�?1 */
    LogLine("进程内事件环就绪（%u 字节，不创建共享内存）", DDH_SHM_SIZE);
    LogLine("ddh 版本 v%d：事件记录 %u 字节/条，名字字段各 %u 字节（UTF-8 安全截断，最多 63 字节+NUL）",
            DDH_VERSION, (unsigned)sizeof(DdhEvent), (unsigned)sizeof(((DdhEvent*)0)->victimName));
    LogLine("ddh 协议 v38：仅进程内伤害事件环（%u 头 + %u 事件 = %u 字节），不再包含属性块",
            (unsigned)sizeof(DdhHeader), (unsigned)(DDH_MAX_EVENTS * sizeof(DdhEvent)),
            (unsigned)sizeof(DdhShared));
}

/* 面板预览/头像测试可能在“第一次受伤”之前就发出；不能等伤害事件才启动热键线程�?
   DllMain 里不能直接做引擎操作，起一个短线程等窗口就绪后再启动消息线程�?*/
/* ---- v21：kkapi_local_plugin.dll �?RequestExtraStringData ----
   静态证据（Ghidra 12.1.4，kkapi_local_plugin.dll sha256 ab19b961…）�?
   注册函数 0x10059A80 用一�?{名字,签名,函数指针} 三元组表把所�?native 注册�?JASS�?
       RequestExtraIntegerData (IHplayer;SSBIII)I -> 0x1005A110
       RequestExtraBooleanData (IHplayer;SSBIII)B -> 0x1005A350
       RequestExtraStringData  (IHplayer;SSBIII)S -> 0x1005A290   <-- �?hook 目标
       RequestExtraRealData    (IHplayer;SSBIII)R
   �?RVA 0x5A290 就是 RequestExtraStringData 本体，不是猜的�?
   0x5A290 反编译结构：�?{opcode=0xE, id, player, str1, str2, bool, i1, i2, i3} 装进局�?
   结构体，调用 0x10029C60(singleton, &req, 4)，成功时返回它填好的那个串指针——也就是
   key 由平台侧给出，只能运行期抓返回值�?

   真正签名�?8 个参数（v20 �?7 参数版本是错的）�?
       (int id, Hplayer, S, S, bool, int, int, int) -> const char*
   JASS �?S 不是 char*，而是一个句柄：h->[8] -> obj，obj+0x1C 才是 char*�?*/
typedef const char* (__cdecl* fn_kk_req_t)(
    int id, void* player, void* s1, void* s2, int flag, int a, int b, int c);
static volatile LONG g_kkHookDone = 0;
static volatile LONG g_kkLogged = 0;
static volatile LONG g_kkCallLogged = 0;
static uint8_t* g_kkTramp = NULL;
static fn_kk_req_t g_kkTrampFn = NULL;

/* JASS 字符串句�?-> char*；结构非�?为空时返�?NULL，全�?__try 保护�?*/
static const char* DdhJassStr(const void* h)
{
    __try
    {
        if (!h) return NULL;
        const uint8_t* inner = *(const uint8_t* const*)((const uint8_t*)h + 8);
        if (!inner) return NULL;
        const char* s = *(const char* const*)(inner + 0x1C);
        if (!s) return NULL;
        /* 只接受可读的短串，避免把野指针当字符�?*/
        return s;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { return NULL; }
}

static const char* __cdecl DdhKkRequestExtraString(
    int id, void* player, void* s1, void* s2, int flag, int a, int b, int c)
{
    const char* ret = g_kkTrampFn ? g_kkTrampFn(id, player, s1, s2, flag, a, b, c) : NULL;
    __try
    {
        const char* p1 = DdhJassStr(s1);
        const char* p2 = DdhJassStr(s2);
        if (InterlockedIncrement(&g_kkCallLogged) <= 40)
        {
            char b1[80] = { 0 };
            char b2[80] = { 0 };
            char br[128] = { 0 };
            if (p1) strncpy_s(b1, sizeof(b1), p1, _TRUNCATE);
            if (p2) strncpy_s(b2, sizeof(b2), p2, _TRUNCATE);
            if (ret) strncpy_s(br, sizeof(br), ret, _TRUNCATE);
            LogLine("JAPI req[%ld] id=%d flag=%d a=%d b=%d c=%d s1=\"%s\" s2=\"%s\" ret=\"%s\"",
                    (long)g_kkCallLogged, id, flag, a, b, c, b1, b2, br);
        }
        if ((p1 && (strstr(p1, "secretKey") || strstr(p1, "Key"))) ||
            (p2 && (strstr(p2, "secretKey") || strstr(p2, "Key"))))
        {
            if (InterlockedIncrement(&g_kkLogged) <= 8)
                LogLine("JAPI KEY：s1=\"%s\" s2=\"%s\" ret=\"%s\"",
                        p1 ? p1 : "", p2 ? p2 : "", ret ? ret : "(null)");
        }
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    return ret;
}

static void DdhTryInstallKkHook(void)
{
    if (InterlockedCompareExchange(&g_kkHookDone, 0, 0) != 0) return;
    HMODULE m = GetModuleHandleA("kkapi_local_plugin.dll");
    if (!m) return;
    uint8_t* fn = (uint8_t*)m + 0x5A290u;
    __try
    {
        if (!(fn[0] == 0x83 && fn[1] == 0xEC && fn[2] == 0x2C))
        {
            LogLine("JAPI KEY hook：函数入口不匹配（%02X %02X %02X），跳过", fn[0], fn[1], fn[2]);
            InterlockedExchange(&g_kkHookDone, 1);
            return;
        }
        g_kkTramp = (uint8_t*)VirtualAlloc(NULL, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
        if (!g_kkTramp) return;
        memcpy(g_kkTramp, fn, 7);                 /* sub esp,2c + mov eax,[esp+30] */
        uint8_t* p = g_kkTramp + 7;
        p[0] = 0xE9;
        *(int32_t*)(p + 1) = (int32_t)((fn + 7) - (p + 5));
        g_kkTrampFn = (fn_kk_req_t)(uintptr_t)g_kkTramp;

        DWORD old = 0;
        if (!VirtualProtect(fn, 7, PAGE_EXECUTE_READWRITE, &old)) return;
        uint8_t patch[7] = { 0xE9, 0, 0, 0, 0, 0x90, 0x90 };
        *(int32_t*)(patch + 1) = (int32_t)((uint8_t*)&DdhKkRequestExtraString - (fn + 5));
        memcpy(fn, patch, sizeof(patch));
        VirtualProtect(fn, 7, old, &old);
        FlushInstructionCache(GetCurrentProcess(), fn, 7);
        InterlockedExchange(&g_kkHookDone, 1);
        LogLine("JAPI KEY hook：已按 DDH_JAPI_KEY=0 关闭");
    }
    __except (EXCEPTION_EXECUTE_HANDLER)
    {
        LogLine("JAPI KEY hook：安装异常 code=0x%08X", (unsigned)GetExceptionCode());
        InterlockedExchange(&g_kkHookDone, 1);
    }
}

/* ---- v23：运行期 key 候选扫描（文件触发，诊断用�?---
   平台�?JAPI 不在 kkapi_local_plugin.dll 里（平台�?War3Plugin.dll，且注册时不带函数指针）�?
   所以改走“从进程内存里找 key”这条路：地图脚本拿�?key 后它作为 Lua 字符串常驻堆里�?
   触发方式：在 ddh 日志同目录放一�?ddh_scan.flag；本线程发现后扫一遍并输出
   keys-<pid>.txt（每行一�?16..24 字节可打�?ASCII 串），再�?flag 删掉�?
   外部�?ts_main 的密文做 XOR 自校验，即可挑出真正�?key�?*/
static void DdhScanKeysOnce(void)
{
    char dir[MAX_PATH] = { 0 };
    strncpy_s(dir, sizeof(dir), g_logPath, _TRUNCATE);
    char* slash = strrchr(dir, '\\');
    if (!slash) return;
    slash[1] = 0;

    char out[MAX_PATH];
    DdhSprintf(out, sizeof(out), "%skeys-%lu.txt", dir, (unsigned long)GetCurrentProcessId());
    FILE* f = NULL;
    if (fopen_s(&f, out, "w") != 0 || !f) { LogLine("key扫描：无法写 %s", out); return; }

    SYSTEM_INFO si;
    GetSystemInfo(&si);
    const uint8_t* p = (const uint8_t*)si.lpMinimumApplicationAddress;
    const uint8_t* end = (const uint8_t*)si.lpMaximumApplicationAddress;
    long written = 0;
    long regions = 0;

    while (p < end && written < 200000)
    {
        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery(p, &mbi, sizeof(mbi)) != sizeof(mbi)) break;
        const uint8_t* base = (const uint8_t*)mbi.BaseAddress;
        SIZE_T size = mbi.RegionSize;
        if (size == 0) break;

        bool readable = (mbi.State == MEM_COMMIT) &&
                        !(mbi.Protect & PAGE_GUARD) &&
                        !(mbi.Protect & PAGE_NOACCESS) &&
                        (mbi.Protect & (PAGE_READONLY | PAGE_READWRITE | PAGE_WRITECOPY |
                                        PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY));
        if (readable)
        {
            ++regions;
            __try
            {
                const uint8_t* q = base;
                const uint8_t* qe = base + size;
                while (q < qe)
                {
                    uint8_t c = *q;
                    if (c >= 0x20 && c < 0x7F)
                    {
                        const uint8_t* s = q;
                        while (q < qe && *q >= 0x20 && *q < 0x7F) ++q;
                        size_t len = (size_t)(q - s);
                        if (len >= 16 && len <= 24)
                        {
                            fwrite(s, 1, len, f);
                            fputc('\n', f);
                            if (++written >= 200000) break;
                        }
                        continue;
                    }
                    ++q;
                }
            }
            __except (EXCEPTION_EXECUTE_HANDLER) { }
        }
        p = base + size;
    }

    fclose(f);
    LogLine("key扫描：完成，%ld 个候选串、%ld 个可读区 -> %s", written, regions, out);
}

static DWORD WINAPI DdhScanWatchThread(LPVOID)
{
    char dir[MAX_PATH] = { 0 };
    strncpy_s(dir, sizeof(dir), g_logPath, _TRUNCATE);
    char* slash = strrchr(dir, '\\');
    if (!slash) return 0;
    slash[1] = 0;
    char flag[MAX_PATH];
    DdhSprintf(flag, sizeof(flag), "%sddh_scan.flag", dir);
    for (;;)
    {
        Sleep(2000);
        if (GetFileAttributesA(flag) == INVALID_FILE_ATTRIBUTES) continue;
        LogLine("key扫描：收到触发文件，开始扫描本进程内存");
        DeleteFileA(flag);
        DdhScanKeysOnce();
    }
    return 0;
}

static DWORD WINAPI DdhStartupThread(LPVOID)
{
    Sleep(200);
    DdhDbStart();
    DdhEnsureHotkeyThread();
    /* v22：默认开启（只读日志、原样透传，风险极低）。要关掉就设 DDH_JAPI_KEY=0�?*/
    char jk[8] = { 0 };
    if (GetEnvironmentVariableA("DDH_JAPI_KEY", jk, (DWORD)sizeof(jk)) == 0 || jk[0] != '1')
    {
        LogLine("JAPI KEY hook disabled by default; set DDH_JAPI_KEY=1 for diagnostics");
        return 0;
    }
    LogLine("JAPI KEY hook enabled for diagnostics");
    /* �?JAPI 插件加载；key 在地图脚本初始化时读取，必须赶在它之前�?*/
    for (int i = 0; i < 2400 && InterlockedCompareExchange(&g_kkHookDone, 0, 0) == 0; ++i)
    {
        DdhTryInstallKkHook();
        if (InterlockedCompareExchange(&g_kkHookDone, 0, 0) != 0) break;
        Sleep(50);
    }
    if (InterlockedCompareExchange(&g_kkHookDone, 0, 0) == 0)
        LogLine("JAPI KEY hook：等待超时（120s），kkapi_local_plugin.dll 始终未加载");
    return 0;
}

/* Keep the original three-second bootstrap delay now that the full hook is
   linked directly into ddh.dll. This lets WFE finish enumerating additional
   libraries before the local event ring and game.dll patching begin. */
static DWORD WINAPI DdhCoreAttachThread(LPVOID)
{
    Sleep(3000);
    SetupShared();
    if (g_shm)
    {
        g_shm->hdr.gameDllBase = 0;
        g_shm->hdr.hookOk = 0;
        g_shm->hdr.reserved[0] = 0;
        g_shm->hdr.reserved[4] = 0;
        if (DdhDamageHookDisabledByFlag())
        {
            strncpy_s(g_hookLastError, sizeof(g_hookLastError),
                      "disabled by C:\\launch\\ddh_disable_damage_hook.flag", _TRUNCATE);
            DdhWriteHookStatus(0, false);
        }
        else
        {
            HANDLE hookThread = CreateThread(NULL, 0, DdhHookInstallThread, NULL, 0, NULL);
            if (hookThread) CloseHandle(hookThread);
        }
        HANDLE startupThread = CreateThread(NULL, 0, DdhStartupThread, NULL, 0, NULL);
        if (startupThread) CloseHandle(startupThread);
        HANDLE scanThread = CreateThread(NULL, 0, DdhScanWatchThread, NULL, 0, NULL);
        if (scanThread) CloseHandle(scanThread);
    }
    return 0;
}

BOOL APIENTRY DllMain(HMODULE mod, DWORD reason, LPVOID)
{
    if (reason == DLL_PROCESS_ATTACH)
    {
        g_self = mod;
        DisableThreadLibraryCalls(mod);

        char mutexName[96] = { 0 };
        DdhSprintf(mutexName, sizeof(mutexName),
                   "Local\\War3DeathSettlement.ddh.instance.%lu", GetCurrentProcessId());
        SetLastError(ERROR_SUCCESS);
        g_instanceMutex = CreateMutexA(NULL, FALSE, mutexName);
        if (g_instanceMutex && GetLastError() == ERROR_ALREADY_EXISTS)
        {
            CloseHandle(g_instanceMutex);
            g_instanceMutex = NULL;
            g_duplicateInstance = true;
            return TRUE;
        }

        HANDLE thread = CreateThread(NULL, 0, DdhCoreAttachThread, NULL, 0, NULL);
        if (thread) CloseHandle(thread);
    }
    else if (reason == DLL_PROCESS_DETACH)
    {
        /* v9：先让热键线程退出并注销热键（否则组合键会一直粘在本进程上） */
        if (InterlockedCompareExchange(&g_ddhHkStarted, 0, 0) != 0)
        {
            InterlockedExchange(&g_ddhHkStop, 1);
            if (g_ddhHkThreadId) PostThreadMessageA(g_ddhHkThreadId, WM_QUIT, 0, 0);
            if (g_ddhHkThread)
            {
                WaitForSingleObject(g_ddhHkThread, 300);
                CloseHandle(g_ddhHkThread);
                g_ddhHkThread = NULL;
            }
        }

        /* v12：先还原窗口过程（否则窗口还指着我们的代码，卸载后再有任何消息就崩） */
        DdhRestoreGameWnd();

        /* 卸钩：把原来�?6 字节写回�?*/
        if (g_hooked && g_hookAt)
        {
            DWORD old = 0;
            if (VirtualProtect(g_hookAt, 8, PAGE_EXECUTE_READWRITE, &old))
            {
                memcpy(g_hookAt, g_saved, STEAL);
                FlushInstructionCache(GetCurrentProcess(), g_hookAt, 8);
                VirtualProtect(g_hookAt, 16, old, &old);
                LogLine("已卸钩");
            }
        }
        g_shm = &g_localRing;
        if (g_instanceMutex) { CloseHandle(g_instanceMutex); g_instanceMutex = NULL; }
    }
    return TRUE;
}
#ifdef DDH_MSG_TEST
/* ===========================================================================
   消息编码 / 格式自检（只�?`cl /DDDH_MSG_TEST ddh.cpp` 这种临时构建才编进来�?
   build_hook.ps1 不定�?DDH_MSG_TEST，所以发布用�?ddh.dll �?*没有**这一段）�?
   ---------------------------------------------------------------------------
   断言用的都是真机日志里的真实字节：名字“雪狼�?= E9 9B AA E7 8B BC�?
   跑法：msgtest.exe �?退出码 0 = 全过，非 0 = 失败条数；明细同时写 _msgtest_result.txt�?
   =========================================================================== */
static int   g_testFail = 0;
static FILE* g_testFile = NULL;

/* 期望�?UTF-8 前缀（真机字节，不是源码里的 GBK 字面量） */
static const char kSharePrefix[] = "\xE3\x80\x90\xE4\xBC\xA4\xE5\xAE\xB3\xE3\x80\x91";                              /* 【伤害�?*/
static const char kLivePrefix[]  = "\xE3\x80\x90\xE5\xBD\x93\xE5\x89\x8D\xE4\xBC\xA4\xE5\xAE\xB3\xE3\x80\x91";      /* 【当前伤害�?*/
static const char kPickPrefix[]  = "\xE3\x80\x90\xE5\xB7\xB2\xE9\x80\x89\xE4\xB8\xAD\xE3\x80\x91";                  /* 【已选中�?*/
static const char kOffPrefix[]   = "\xE3\x80\x90\xE5\xB7\xB2\xE5\x8F\x96\xE6\xB6\x88\xE3\x80\x91";                  /* 【已取消�?*/
static const char kOnPrefix[]    = "\xE3\x80\x90\xE5\xB7\xB2\xE5\xBC\x80\xE5\x90\xAF\xE3\x80\x91";                  /* 【已开启�?*/

static void DdhTestOut(const char* fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    if (g_testFile) vfprintf(g_testFile, fmt, ap);
    va_end(ap);
    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
}

static void DdhTestCheck(bool ok, const char* what)
{
    DdhTestOut("[%s] %s\n", ok ? "PASS" : "FAIL", what);
    if (!ok) g_testFail++;
}

/* 打印一�?UTF-8 文本：hex（前 120 字节�? GBK 回显（GBK 才能在控制台/GBK 文件里看懂） */
static void DdhTestDump(const char* tag, const char* s)
{
    char hex[768] = { 0 };
    int n = (int)strlen(s);
    if (n > 120) n = 120;
    FormatHex((const unsigned char*)s, n, hex, sizeof(hex));
    DdhTestOut("  %s 长度=%u hex=%s\n", tag, (unsigned)strlen(s), hex);
    DdhTestOut("  %s 文本=%s\n", tag, s);
}

/* 造一份“记录单�?+ 两个来源�?0.0% / 20.0%）”的统计 */
static void DdhTestMakeTrack(double net0, double net1, double raw0, double raw1)
{
    memset(&g_ddhTrack, 0, sizeof(g_ddhTrack));
    g_ddhTrack.unit = 0x12345000u;
    g_ddhTrack.code = 0x6870666Fu;                        /* hfoo（内存里反序，这里不影响�?*/
    strcpy_s(g_ddhTrack.label, sizeof(g_ddhTrack.label), "\xE9\x9B\xAA\xE7\x8B\xBC(hfoo)");
    g_ddhTrack.hits   = 9;
    g_ddhTrack.raw    = 589.00;
    g_ddhTrack.engine = 328.80;
    g_ddhTrack.map    = 328.80;
    g_ddhTrack.net    = 304.34;
    g_ddhTrack.maxHit = 37.40f;
    g_ddhTrack.srcCount = 2;
    g_ddhTrack.src[0].source = 0x22220000u;
    g_ddhTrack.src[0].code   = 0x6870666Fu;
    strcpy_s(g_ddhTrack.src[0].label, sizeof(g_ddhTrack.src[0].label), "\xE9\x9B\xAA\xE7\x8B\xBC(hfoo)");
    g_ddhTrack.src[0].net = net0;
    g_ddhTrack.src[0].raw = raw0;
    g_ddhTrack.src[1].source = 0x33330000u;
    g_ddhTrack.src[1].code   = 0x6C777268u;
    strcpy_s(g_ddhTrack.src[1].label, sizeof(g_ddhTrack.src[1].label), "\xE7\x8B\xBC\xE4\xBA\xBA(hwol)");
    g_ddhTrack.src[1].net = net1;
    g_ddhTrack.src[1].raw = raw1;
}

static int DdhMsgSelfTest(void)
{
    const char* outPath = getenv("DDH_MSG_TEST_OUT");
    g_testFile = fopen((outPath && outPath[0]) ? outPath : "_msgtest_result.txt", "wb");

    char msg[1024] = { 0 };

    /* ---- 1) 死亡结算：只发【伤害】，主段不出�?---- */
    DdhTestOut("== 1) 死亡结算：只发【伤害】（名字 UTF-8 = E9 9B AA E7 8B BC 雪狼�?=\n");
    DdhTestMakeTrack(243.472, 60.868, 471.20, 117.80);     /* 304.34 �?80.0% / 20.0% */
    DdhBuildTrackText(msg, sizeof(msg), 1);
    DdhTestDump("死亡结算", msg);
    DdhTestCheck(DdhUtf8Valid(msg), "输出整体是合�?UTF-8");
    DdhTestCheck(strncmp(msg, kSharePrefix, sizeof(kSharePrefix) - 1) == 0,
                 "以【伤害】开头（不再有【死亡结算】主段）");
    DdhTestCheck(strstr(msg, "\xE9\x9B\xAA\xE7\x8B\xBC") != NULL,
                 "名字“雪狼”的原字�?E9 9B AA E7 8B BC 原样出现（没有被再转一次）");
    DdhTestCheck(strstr(msg, "\xE5\xA6\x96") == NULL,
                 "不含双转码乱�?E5 A6 96（旧版就是这么坏的）");
    DdhTestCheck(strstr(msg, "\xE9\x9B\xAA\xE7\x8B\xBC" "80.0%") != NULL,
                 "含“雪�?0.0%”（名字直接接一位小数的占比�?);
    DdhTestCheck(strstr(msg, "\xE7\x8B\xBC\xE4\xBA\xBA" "20.0%") != NULL, "含“狼�?0.0%�?);
    DdhTestCheck(strstr(msg, "hfoo") == NULL && strstr(msg, "hwol") == NULL,
                 "不含类型码后缀（来源项只要名字/码）");
    DdhTestCheck(strstr(msg, "\xE5\x8F\x97") == NULL && strstr(msg, "\xE5\x87\x80") == NULL &&
                 strstr(msg, "\xE6\x9C\x80") == NULL && strstr(msg, ":") == NULL,
                 "不含 受击/净/最�?时间（主段已按要求去掉）");
    DdhTestCheck(strlen(msg) <= DDH_MSG_MAX_BYTES, "长度没超�?420 字节");
    DdhTestCheck(g_msgNameRawUtf8 == 2 && g_msgNameGbkFallback == 0,
                 "本条 2 个来源名字全部走“原�?UTF-8”那条路");

    /* ---- 2) Ctrl+Alt+Q：标题改成【当前伤害�?---- */
    DdhTestOut("\n== 2) Ctrl+Alt+Q：【当前伤害�? 同样的占�?==\n");
    DdhBuildTrackText(msg, sizeof(msg), 0);
    DdhTestDump("当前伤害", msg);
    DdhTestCheck(DdhUtf8Valid(msg), "实时统计是合�?UTF-8");
    DdhTestCheck(strncmp(msg, kLivePrefix, sizeof(kLivePrefix) - 1) == 0, "以【当前伤害】开�?);
    DdhTestCheck(strstr(msg, "\xE9\x9B\xAA\xE7\x8B\xBC" "80.0%") != NULL &&
                 strstr(msg, "\xE7\x8B\xBC\xE4\xBA\xBA" "20.0%") != NULL, "同样�?80.0% / 20.0%");

    /* ---- 3) 【伤害】段自身：Top N 截断（先砍靠后的来源�?--- */
    DdhTestOut("\n== 3) 【伤害】段：Top N 截断 ==\n");
    char items[320] = { 0 };
    int used = DdhBuildShareItems(g_ddhTrack.src, g_ddhTrack.srcCount,
                                  g_ddhTrack.net, g_ddhTrack.raw, 1, items, sizeof(items));
    DdhTestDump("Top1", items);
    DdhTestCheck(used == 1, "只留 1 项时返回 1");
    DdhTestCheck(DdhUtf8Valid(items), "Top1 是合�?UTF-8");
    DdhTestCheck(strstr(items, "\xE9\x9B\xAA\xE7\x8B\xBC" "80.0%") != NULL, "Top1 = 雪狼80.0%（留占比最大的�?);

    /* ---- 4) GBK 名字回退：D1 A9 C0 C7（GBK 的“雪狼”）---- */
    DdhTestOut("\n== 4) GBK 名字回退：D1 A9 C0 C7（GBK 的雪狼）==\n");
    memset(&g_ddhTrack, 0, sizeof(g_ddhTrack));
    g_ddhTrack.unit = 0x12345000u;
    g_ddhTrack.raw  = 10.0;
    g_ddhTrack.net  = 10.0;
    g_ddhTrack.srcCount = 1;
    g_ddhTrack.src[0].source = 0x22220000u;
    strcpy_s(g_ddhTrack.src[0].label, sizeof(g_ddhTrack.src[0].label), "\xD1\xA9\xC0\xC7(hfoo)");
    g_ddhTrack.src[0].net = 10.0;
    g_ddhTrack.src[0].raw = 10.0;
    DdhBuildTrackText(msg, sizeof(msg), 1);
    DdhTestDump("GBK名字", msg);
    DdhTestCheck(DdhUtf8Valid(msg), "回退后整体仍是合�?UTF-8");
    DdhTestCheck(strstr(msg, "\xE9\x9B\xAA\xE7\x8B\xBC") != NULL,
                 "GBK 名字 D1 A9 C0 C7 被转�?UTF-8 的“雪狼”（E9 9B AA E7 8B BC�?);
    DdhTestCheck(g_msgNameGbkFallback == 1 && g_msgNameRawUtf8 == 0, "本条走的�?GBK 回退那条�?);

    /* ---- 5) R 选中 / S 开�?的本机提示文�?---- */
    DdhTestOut("\n== 5) Ctrl+Alt+R / S 的本机提�?==\n");
    char toast[256] = { 0 };
    DdhAppendLabel(toast, sizeof(toast), "【已选中�?);
    DdhAppendUnitName(toast, sizeof(toast), "\xE9\x9B\xAA\xE7\x8B\xBC(hfoo)");
    DdhTestDump("已选中", toast);
    DdhTestCheck(DdhUtf8Valid(toast), "【已选中】提示是合法 UTF-8");
    DdhTestCheck(strncmp(toast, kPickPrefix, sizeof(kPickPrefix) - 1) == 0, "以【已选中】开�?);
    DdhTestCheck(strstr(toast, "\xE9\x9B\xAA\xE7\x8B\xBC") != NULL, "【已选中】里带名字“雪狼�?);

    char off[256] = { 0 };
    char on[256]  = { 0 };
    DdhAppendLabel(off, sizeof(off), "【已取消】死亡结算不再自动发�?);
    DdhAppendLabel(on,  sizeof(on),  "【已开启】死亡结算会自动发�?);
    DdhTestDump("已取�?, off);
    DdhTestCheck(DdhUtf8Valid(off) && strncmp(off, kOffPrefix, sizeof(kOffPrefix) - 1) == 0,
                 "【已取消】提示正�?);
    DdhTestCheck(DdhUtf8Valid(on) && strncmp(on, kOnPrefix, sizeof(kOnPrefix) - 1) == 0,
                 "【已开启】提示正�?);

    /* ---- 6) 硬截断：420 字节、末尾“…”、不切坏汉字 ---- */
    DdhTestOut("\n== 6) 硬截断：<=420 字节、末尾“…”、不切坏汉字 ==\n");
    char longText[1024] = { 0 };
    for (int i = 0; i < 200; i++) memcpy(longText + i * 3, "\xE9\x9B\xAA", 3);   /* 200 个“雪�? 600 字节 */
    DdhTruncateUtf8(longText, sizeof(longText), DDH_MSG_MAX_BYTES);
    const size_t longLen = strlen(longText);
    char tail[4] = { 0 };
    char tailHex[32] = { 0 };
    if (longLen >= 3) memcpy(tail, longText + longLen - 3, 3);
    FormatHex((const unsigned char*)tail, 3, tailHex, sizeof(tailHex));
    DdhTestOut("  截断后长�?%u 末尾3字节=%s（应�?E2 80 A6）\n", (unsigned)longLen, tailHex);
    DdhTestCheck(longLen <= DDH_MSG_MAX_BYTES, "截断�?<= 420 字节");
    DdhTestCheck(DdhUtf8Valid(longText), "截断后仍是合�?UTF-8（没切出半个汉字�?);
    DdhTestCheck(memcmp(tail, "\xE2\x80\xA6", 3) == 0, "末尾补了“…”（E2 80 A6�?);
    DdhTestCheck(longLen == DDH_MSG_MAX_BYTES, "截断正好用满 420 字节");

    /* ---- 7) 占比格式：一位小�?/ 0.1% 下限 / 100.0% 上限 ---- */
    DdhTestOut("\n== 7) share format: one decimal / 0.1%% floor / 100.0%% cap ==\n");
    DdhSrcStat bs[2];
    memset(bs, 0, sizeof(bs));
    char bshare[320] = { 0 };
    strcpy_s(bs[0].label, sizeof(bs[0].label), "\xE9\x9B\xAA\xE7\x8B\xBC(hfoo)");   /* 雪狼 */
    strcpy_s(bs[1].label, sizeof(bs[1].label), "\xE7\x8B\xBC\xE4\xBA\xBA(hwol)");   /* 狼人 */
    bs[0].net = 100.0; bs[1].net = 0.02;
    DdhBuildShareItems(bs, 2, 100.02, 100.02, DDH_SHARE_TOP, bshare, sizeof(bshare));
    DdhTestDump("边界占比", bshare);
    DdhTestCheck(strstr(bshare, "100.0%") != NULL, "99.98% 四舍五入�?100.0%（上限）");
    DdhTestCheck(strstr(bshare, "0.1%") != NULL, "0.02% 抬到 0.1% 下限（不显示 0.0%�?);
    DdhTestCheck(strstr(bshare, " 0.0%") == NULL, "没有 0.0% 这种写法�?00.0% 是上限，不算�?);
    bs[0].net = 31.13; bs[1].net = 68.87;
    DdhBuildShareItems(bs, 2, 100.0, 100.0, DDH_SHARE_TOP, bshare, sizeof(bshare));
    DdhTestDump("一位小�?, bshare);
    DdhTestCheck(strstr(bshare, "31.1%") != NULL && strstr(bshare, "68.9%") != NULL,
                 "31.13�?1.1% / 68.87�?8.9%（四舍五入到 0.1�?);
    DdhTestCheck(strstr(bshare, "31%") == NULL, "不再出现整数写法 31%");

    /* 8) 长名字标签：64/96 字节都装不下时只能“安全截断�?
          真机 2026-10-31 20:22:52 崩在 sprintf_s 的无效参数上�?
          长中文名 “……【辅助单位�?e009)�?写进 64 字节标签 �?_invoke_watson �?0xC0000409�?*/
    {
        char longName[160] = { 0 };
        for (int i = 0; i < 24; i++) strcat_s(longName, sizeof(longName), "\xE6\x88\x98");
        char lab64[64] = { 0 };
        DdhComposeLabel(longName, "e009", lab64, sizeof(lab64));
        DdhTestDump("长名字→64 字节标签", lab64);
        DdhTestCheck(strlen(lab64) < sizeof(lab64), "长名字→64 字节标签不越�?);
        DdhTestCheck(DdhUtf8Valid(lab64), "长名字→64 字节标签仍是合法 UTF-8");
        DdhTestCheck(lab64[0] && lab64[strlen(lab64) - 1] == ')', "长名字截断后仍保�?�?�?�?后缀");
        DdhTestCheck(strstr(lab64, "(e009") != NULL, "后缀�?(e009");

        char lab96[96] = { 0 };
        DdhComposeLabel(longName, "e009", lab96, sizeof(lab96));
        DdhTestCheck(strlen(lab96) < sizeof(lab96) && DdhUtf8Valid(lab96), "长名字→96 字节标签同样安全");
        DdhTestCheck(strlen(lab96) > strlen(lab64), "96 字节�?64 字节装得下更多名�?);

        char lab8[8] = { 0 };
        DdhComposeLabel(longName, "e009", lab8, sizeof(lab8));
        DdhTestCheck(DdhUtf8Valid(lab8) && strlen(lab8) < sizeof(lab8), "极小缓冲(8 字节)也安�?);

        char labNone[8] = { 0 };
        DdhComposeLabel("", "", labNone, sizeof(labNone));
        DdhTestCheck(strcmp(labNone, "?") == 0, "没名字也没码时写 ?");
    }

    DdhTestOut("\n%s（失�?%d 项）\n", g_testFail == 0 ? "== 自检通过 ==" : "== 自检失败 ==", g_testFail);
    return g_testFail;
}

int main(void)
{
    const int fails = DdhMsgSelfTest();
    if (g_testFile) { fclose(g_testFile); g_testFile = NULL; }
    return fails == 0 ? 0 : (fails > 100 ? 100 : fails);
}
#endif /* DDH_MSG_TEST */
#ifdef DDH_CHILDSUM_TEST
/* ===========================================================================
   v13 子伤害记账自检（只�?`cl /DDH_CHILDSUM_TEST ddh.cpp` 这种临时构建才编进来�?
   build_hook.ps1 不定�?DDH_CHILDSUM_TEST，发布用�?ddh.dll �?*没有**这一段）�?
   ---------------------------------------------------------------------------
   直接驱动 DdhFramePush / DdhFramePop，覆盖真机上的多目标 AoE�?
     父帧打张�?A�?01.20 �?73.07（整�?28.13�?
     内层子帧：A 5.63 / 典韦 B 5.63 / 步兵 C 7.50 / 步兵 C 7.50（子合计 26.26�?
   旧版�?26.26 全扣到父�?�?own=1.87；正确只扣同目标�?5.63 �?own=22.50�?
   跑法：childsumtest.exe �?退出码 0 = 全过，非 0 = 失败条数；明细同时写
         _childsum_result.txt，嵌套扣减日志写 _childsum_test.log�?
   =========================================================================== */
static int   g_csFail = 0;
static FILE* g_csFile = NULL;

static void CsOut(const char* fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    if (g_csFile) vfprintf(g_csFile, fmt, ap);
    va_end(ap);
    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
}

static void CsCheck(bool ok, const char* what)
{
    CsOut("[%s] %s\n", ok ? "PASS" : "FAIL", what);
    if (!ok) g_csFail++;
}

static void CsNear(float got, float want, const char* what)
{
    char buf[512];
    const bool ok = (got - want) <= 0.01f && (want - got) <= 0.01f;
    DdhSprintf(buf, sizeof(buf), "%s（实�?%.2f，期�?%.2f ±0.01�?, what, got, want);
    CsCheck(ok, buf);
}

#define CS_A 0xA0001000u
#define CS_B 0xB0002000u
#define CS_C 0xC0003000u

/* 压一个子帧、按给定掉血退栈，返回子帧自己�?own */
static float CsChild(uint32_t level, uint32_t victim, float hp0, float dmg)
{
    DdhFrame* c = DdhFramePush(level, victim, hp0, 1);
    float g = 0.0f, o = 0.0f;
    DdhFramePop(c, 1, hp0 - dmg, 1, 0.0f, &g, &o);
    return o;
}

static int DdhChildSumSelfTest(void)
{
    const char* outPath = getenv("DDH_CHILDSUM_TEST_OUT");
    g_csFile = fopen((outPath && outPath[0]) ? outPath : "_childsum_result.txt", "wb");
    strcpy_s(g_logPath, sizeof(g_logPath), "_childsum_test.log");
    remove(g_logPath);
    g_nestedLogCount = 0;

    /* ---- 1) 多目�?AoE：父 A 28.13，子 A 5.63 / B 5.63 / C 7.50 / C 7.50 ---- */
    CsOut("== 1) 多目�?AoE：父=张飞A 101.20�?3.07�?8.13），内层 A 5.63 / 典韦B 5.63 / 步兵C 7.50 ×2 ==\n");
    memset(g_frames, 0, sizeof(g_frames));
    DdhFrame* p = DdhFramePush(0, CS_A, 101.20f, 1);
    CsCheck(p != NULL && p->depth == 1, "父帧压栈成功（depth=1�?);
    const float ownA  = CsChild(1, CS_A, 50.00f, 5.63f);
    const float ownB  = CsChild(1, CS_B, 50.00f, 5.63f);
    const float ownC1 = CsChild(1, CS_C, 50.00f, 7.50f);
    const float ownC2 = CsChild(1, CS_C, 50.00f, 7.50f);
    CsCheck(p->childCountSame == 1, "父帧只收�?1 笔同目标子帧（A�?);
    CsNear(p->childSumSameVictim, 5.63f, "父帧同目标子合计（B/C 不扣父帧�?);
    float gross = 0.0f, own = 0.0f;
    const bool measured = DdhFramePop(p, 1, 73.07f, 1, 0.0f, &gross, &own);
    CsCheck(measured, "父帧前后血有效，own 可测");
    CsOut("  父帧�?01.20�?3.07 整段=%.2f 同目标子合计=%.2f�?u 笔） own=%.2f\n",
          gross, p->childSumSameVictim, p->childCountSame, own);
    CsNear(gross, 28.13f, "父帧整段 gross");
    CsNear(own, 22.50f, "父帧 own（旧版按 26.26 扣会错成 1.87�?);
    CsNear(ownA, 5.63f, "子帧 A �?own");
    CsNear(ownB, 5.63f, "子帧 B（典韦）�?own");
    CsNear(ownC1, 7.50f, "子帧 C �?1 笔的 own");
    CsNear(ownC2, 7.50f, "子帧 C �?2 笔的 own");

    /* ---- 2) 再嵌一层：孙帧�?A 1.00（在子帧 A �?5.63 内） ---- */
    CsOut("\n== 2) 再嵌一层：孙帧�?A 1.00（在子帧 A �?5.63 内）==\n");
    memset(g_frames, 0, sizeof(g_frames));
    p = DdhFramePush(0, CS_A, 101.20f, 1);
    DdhFrame* childA = DdhFramePush(1, CS_A, 50.00f, 1);
    DdhFrame* grand  = DdhFramePush(2, CS_A, 30.00f, 1);
    float gGrand = 0.0f, oGrand = 0.0f;
    DdhFramePop(grand, 1, 29.00f, 1, 0.0f, &gGrand, &oGrand);
    CsNear(gGrand, 1.00f, "孙帧整段 gross");
    CsNear(oGrand, 1.00f, "孙帧 own");
    CsNear(childA->childSumSameVictim, 1.00f, "子帧 A 收到孙帧 1.00（同目标�?);
    float gChild = 0.0f, oChild = 0.0f;
    DdhFramePop(childA, 1, 44.37f, 1, 0.0f, &gChild, &oChild);
    CsNear(gChild, 5.63f, "子帧 A 整段（含孙帧 1.00�?);
    CsNear(oChild, 4.63f, "子帧 A own = 5.63 - 1.00");
    CsChild(1, CS_B, 50.00f, 5.63f);
    CsChild(1, CS_C, 50.00f, 7.50f);
    CsChild(1, CS_C, 50.00f, 7.50f);
    CsNear(p->childSumSameVictim, 5.63f, "父帧同目标子合计仍是 5.63（孙帧不重复扣）");
    DdhFramePop(p, 1, 73.07f, 1, 0.0f, &gross, &own);
    CsNear(own, 22.50f, "父帧 own �?= 22.50（扣减已包含孙帧�?1.00�?);

    /* ---- 3) 只有异目标子帧：父帧一分不�?---- */
    CsOut("\n== 3) 只有异目标子帧：父帧 own 不被�?==\n");
    memset(g_frames, 0, sizeof(g_frames));
    p = DdhFramePush(0, CS_A, 101.20f, 1);
    CsChild(1, CS_B, 50.00f, 5.63f);
    CsChild(1, CS_C, 50.00f, 7.50f);
    CsChild(1, CS_C, 50.00f, 7.50f);
    CsCheck(p->childCountSame == 0, "异目标子帧不记入父帧");
    DdhFramePop(p, 1, 73.07f, 1, 0.0f, &gross, &own);
    CsNear(own, 28.13f, "父帧 own = 整段 28.13（没有同目标子帧可扣�?);

    /* ---- 4) 栈上限保�?---- */
    CsOut("\n== 4) 栈上限保护（帧栈�?= DDH_MAXDEPTH = %u�?=\n", (unsigned)DDH_MAXDEPTH);
    CsCheck(DdhFramePush(DDH_MAXDEPTH, CS_A, 1.0f, 1) == NULL, "越界层压栈返�?NULL（不越界写）");
    float gSafe = 1.0f, oSafe = 1.0f;
    CsCheck(!DdhFramePop(NULL, 1, 0.0f, 1, 0.0f, &gSafe, &oSafe) && gSafe == 0.0f && oSafe == 0.0f,
            "�?越界帧退栈安全（不崩、输出清零）");

    /* ---- 5) 嵌套扣减日志 ---- */
    CsOut("\n== 5) 嵌套扣减日志（前 3 次）==\n");
    FILE* lf = NULL;
    char logText[4096] = { 0 };
    bool logOk = false;
    if (fopen_s(&lf, g_logPath, "rb") == 0 && lf)
    {
        size_t n = fread(logText, 1, sizeof(logText) - 1, lf);
        logText[n] = 0;
        fclose(lf);
        logOk = true;
    }
    CsCheck(logOk, "能读到嵌套扣减日志文�?);
    CsCheck(strstr(logText, "own=22.50") != NULL, "日志�?own=22.50（父帧扣减后的净掉血�?);
    CsCheck(strstr(logText, "0xA0001000") != NULL, "日志含父帧地址 0xA0001000");
    CsOut("  日志内容（GBK）：\n%s\n", logText);

    CsOut("\n%s（失�?%d 项）\n", g_csFail == 0 ? "== 自检通过 ==" : "== 自检失败 ==", g_csFail);
    return g_csFail;
}

int main(void)
{
    const int fails = DdhChildSumSelfTest();
    if (g_csFile) { fclose(g_csFile); g_csFile = NULL; }
    return fails == 0 ? 0 : (fails > 100 ? 100 : fails);
}
#endif /* DDH_CHILDSUM_TEST */

#ifdef DDH_NAMETEST
/* ===========================================================================
   v9 名字截断自检（只�?`cl /DDDH_NAMETEST ddh.cpp` 的临时验证用，build_hook.ps1
   不定义这个宏，发�?ddh.dll 里没有这一段）�?
   验证 DdhUtf8SafeCopy�?9/63 字节切在汉字中间时回退到完整字符边界，
   源串自己以半个汉字结尾时也丢掉残字符�?
   =========================================================================== */
static int g_ntFail = 0;
static void NtCheck(bool ok, const char* what)
{
    printf("[%s] %s\n", ok ? "PASS" : "FAIL", what);
    if (!ok) g_ntFail++;
}

int main(void)
{
    char out[64] = { 0 };
    char text[128] = { 0 };
    for (int i = 0; i < 20; i++) memcpy(text + i * 3, "\xE9\x9B\xAA", 3);   /* 20 个雪 = 60 字节 */
    memcpy(text + 60, "ab", 2);
    memcpy(text + 62, "\xE9\x9B\xAA", 3);                                   /* 再一个雪 = 65 字节 */

    size_t n29 = DdhUtf8SafeCopy(out, sizeof(out), text, 29);
    NtCheck(n29 == 27, "29 边界回退�?27 字节�? 个完整汉字）");
    NtCheck(DdhUtf8Valid(out), "29 边界输出是合�?UTF-8");

    size_t n63 = DdhUtf8SafeCopy(out, sizeof(out), text, 63);
    NtCheck(n63 == 62, "63 边界回退�?62 字节�?0 汉字 + ab�?);
    NtCheck(DdhUtf8Valid(out), "63 边界输出是合�?UTF-8");

    const char* half = "bbbb\xE6\x8A\x80\xE4\xBD";   /* 末尾「位」只有前 2 字节 */
    size_t nh = DdhUtf8SafeCopy(out, sizeof(out), half, 63);
    NtCheck(nh == 7 && strcmp(out, "bbbb\xE6\x8A\x80") == 0, "源串末尾半个汉字被丢掉（bbbb技�?);
    NtCheck(DdhUtf8Valid(out), "源串截断输出是合�?UTF-8");

    printf("== %s（失�?%d 项）==\n", g_ntFail == 0 ? "NAMETEST PASS" : "NAMETEST FAIL", g_ntFail);
    return g_ntFail;
}
#endif /* DDH_NAMETEST */
