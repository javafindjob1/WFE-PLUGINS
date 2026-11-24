//----------------------------------------------------------------------------
// fake_game_dll.cpp -- self-test helper only: a fake game.dll (x86).
//
// Purpose: create a 32-bit process whose memory layout matches the externally
// readable part of Warcraft III 1.27, so War3DeathSettlement can be verified
// end-to-end without the real game:
//
//   game.dll + 0xBE4238 -> ctx (fake)
//   game.dll + 0xBE40A8 -> ThisGame (fake) -> +0x0C -> game memory table
//                                                  (8-byte entries, pointer at +4)
//   CUnit + 0x30 = 4-char type code
//   CUnit + 0xA0 = life index  (FAKE_LAYOUT=weird moves it to +0xA4 to test
//                               the tool's automatic offset calibration)
//   CUnit + 0x1C = owner (CPlayer*, tests the owner-field auto discovery)
//
// Environment knobs (all optional):
//   FAKE_LAYOUT=weird   use different field offsets (tests auto calibration)
//   FAKE_UNITS=N        spawn N units (default 12; up to 2000) -- scale/perf test
//   FAKE_HEAP_MB=M      allocate M MB of scattered heap junk (default 0) so the
//                       deep scan has to chew through a realistic heap
//   FAKE_DECOY=1        sprinkle ASCII "type code"-looking runs into the junk
//                       (tests the false-positive filters)
//   FAKE_NO_JASS=1      do NOT install the fake JASS native table / handle chain
//                       (verifies "map without JAPI => attribute columns show ?")
//
// NOTE: this file is NOT part of the shipped software; it only lives in _test.
//----------------------------------------------------------------------------

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vector>

// 12 MB of BSS: makes RVAs 0xBE40A8 / 0xBE4238 exist inside the module image,
// exactly like the real game.dll globals the tool reads.
char g_pad[0x00C00000];

static const unsigned kThisGameRva = 0x00BE40A8u;
static const unsigned kCtxRva      = 0x00BE4238u;

struct Layout { unsigned hpIndex, stateCur, stateMax; };
static Layout g_layout = { 0xA0u, 0x78u, 0x84u };

static int g_unitCount = 12;
static int g_slots = 64;

static std::vector<unsigned char*> g_unit;
static std::vector<unsigned char*> g_state;
static std::vector<unsigned char*> g_relaunch;
static std::vector<char>          g_code;          // 5 bytes per unit
static std::vector<unsigned char*> g_heapJunk;     // kept alive on purpose
static volatile LONG g_stop = 0;
static volatile LONG g_pause = 0;   // 搬家时暂停 tick 线程，避免它往已释放的旧表上写
static unsigned char* g_entries = 0;
static unsigned char* g_table = 0;
static unsigned char* g_thisGame = 0;   // fake ThisGame object (late-move thread rewrites +0x0C)
static unsigned char* g_reserve = 0;    // 64MB 预留区：初始只 commit 第一块，搬家时再 commit 远处一块

static void w32(void* p, unsigned v)  { *(unsigned*)p = v; }
static void w16(void* p, unsigned v)  { *(unsigned short*)p = (unsigned short)v; }
static void wf (void* p, float v)     { *(float*)p = v; }

// 真实魔兽把 4CC 当 dword 存 —— 内存里的字节顺序和显示顺序**相反**。
// 所以靶子也必须反着写，否则就把“类型码读反”这个 bug 掩盖掉了（踩过）。
static void WriteTypeCode(void* dst, const char* code)
{
    char rev[4] = { code[3], code[2], code[1], code[0] };
    memcpy(dst, rev, 4);
}

//----------------------------------------------------------------------------
// Minimal fake JASS ("JAPI") layer -- only for the end-to-end self-test.
//
// ddh.dll v10 解析单位属性时会用到下面这几个真实 game.dll 里的固定偏移，所以假
// game.dll 必须把它们补上，否则“假 JASS”就只能测到 invalid 分支：
//   0x1D1550  __fastcall(ecx=handle)        -> CUnit*      （句柄回程校验）
//   0x1E6600  __cdecl(handle, state)        -> float 位模式（GetUnitState，state 0 = 生命）
//   0x4EFB0   __fastcall(ecx=index)         -> JASS 实例；+0x18 是 native 表
//   0x1C2870  __thiscall(ecx=ctx, [esp+4]=id)-> char*       （字符串 id → 正文，英雄称谓用）
//   0x326BA0  __fastcall(ecx=code, edx=0)   -> char*        （4 字符码 → 单位名）
// native 表格式与 1.27 一致：表 +0x1C = 桶数组，+0x24 = mask；桶每项 12 字节，+8 = 节点；
// 节点 0x20 字节：+0x04 hash、+0x0C next、+0x18 key(名字)、+0x1C func。
// 这些桩都写在 g_pad（12MB BSS）里，运行时临时改成 RWX（跟 0x67DC40 的伤害函数同款）。
// FAKE_NO_JASS=1 时整块都不装 —— 用来验证“地图没有 JAPI 时属性列显示 ?”。
//----------------------------------------------------------------------------
static unsigned char* g_base      = 0;     // game.dll 基址
static unsigned char* g_jassInst  = 0;     // 假 JASS 实例
static unsigned char* g_jassBuck  = 0;     // native 哈希桶（64 桶 × 12 字节）
static unsigned char* g_jassNodes = 0;     // native 节点（64 × 0x20）
static int            g_jassNodeCount = 0;

static unsigned HashRead4(const unsigned char* p)
{
    return (unsigned)p[0] | ((unsigned)p[1] << 8) | ((unsigned)p[2] << 16) | ((unsigned)p[3] << 24);
}

/* 与 ddh.cpp::Wc3StringHash 逐字节一致（大写化 + '/'→'\\' + Bob Jenkins 混合）：
   哈希对不上，ddh 就永远找不到这个 native。 */
static unsigned FakeWc3Hash(const char* str)
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
    unsigned A = 0x9E3779B9u, B = 0x9E3779B9u, C = 0u;
    if (rem >= 12)
    {
        size_t step = rem / 12;
        do
        {
            A += HashRead4(p + 0); B += HashRead4(p + 4); C += HashRead4(p + 8);
            A = (C >> 13) ^ (A - B - C); B = (A << 8)  ^ (B - C - A); C = (B >> 13) ^ (C - A - B);
            A = (C >> 12) ^ (A - B - C); B = (A << 16) ^ (B - C - A); C = (B >> 5)  ^ (C - A - B);
            A = (C >> 3)  ^ (A - B - C); B = (A << 10) ^ (B - C - A); C = (B >> 15) ^ (C - A - B);
            p += 12; rem -= 12;
        } while (--step != 0);
    }
    C = C + (unsigned)len;
    switch (rem)
    {
        case 11: C += (unsigned)p[10] << 24;
        case 10: C += (unsigned)p[9]  << 16;
        case 9:  C += (unsigned)p[8]  << 8;
        case 8:  B += (unsigned)p[7]  << 24;
        case 7:  B += (unsigned)p[6]  << 16;
        case 6:  B += (unsigned)p[5]  << 8;
        case 5:  B += (unsigned)p[4];
        case 4:  A += (unsigned)p[3]  << 24;
        case 3:  A += (unsigned)p[2]  << 16;
        case 2:  A += (unsigned)p[1]  << 8;
        case 1:  A += (unsigned)p[0];
            break;
        default: break;
    }
    A = (C >> 13) ^ (A - B - C); B = (A << 8)  ^ (B - C - A); C = (B >> 13) ^ (C - A - B);
    A = (C >> 12) ^ (A - B - C); B = (A << 16) ^ (B - C - A); C = (B >> 5)  ^ (C - A - B);
    A = (C >> 3)  ^ (A - B - C); B = (A << 10) ^ (B - C - A); C = (B >> 15) ^ (C - A - B);
    return C;
}

static unsigned BitsF(float f) { unsigned u; memcpy(&u, &f, 4); return u; }

/* 句柄 → 单位下标（假句柄 = 0x100000 + 下标；与 ddh 的 HpObj2HMem 口径一致） */
static int FakeUnitIndex(unsigned h)
{
    if (h < 0x100000u) return -1;
    unsigned k = h - 0x100000u;
    return (k < (unsigned)g_unitCount) ? (int)k : -1;
}

/* 类型码第一个字符大写 = 英雄（魔兽约定） */
static bool FakeIsHero(int idx)
{
    if (idx < 0 || idx >= g_unitCount || !g_unit[idx]) return false;
    unsigned code = 0;
    __try { code = *(unsigned*)(uintptr_t)(g_unit[idx] + 0x30); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return false; }
    char first = (char)((code >> 24) & 0xFF);   // 内存里反序存
    return first >= 'A' && first <= 'Z';
}

/* 4 字符码 → 单位名（UTF-8；引擎 0x326BA0 也是 UTF-8 正文） */
static const char* FakeCodeToNameC(unsigned code)
{
    char cd[5];
    cd[0] = (char)((code >> 24) & 0xFF);
    cd[1] = (char)((code >> 16) & 0xFF);
    cd[2] = (char)((code >> 8)  & 0xFF);
    cd[3] = (char)(code & 0xFF);
    cd[4] = 0;
    static const struct { const char* code; const char* name; } kN[] =
    {
        { "hfoo", "\xE6\xAD\xA5\xE5\x85\xB5" },
        { "opeo", "\xE5\x86\x9C\xE6\xB0\x91" },
        { "ogre", "\xE9\xA3\x9F\xE4\xBA\xBA\xE9\xAD\x94" },
        { "uske", "\xE9\xAA\xB7\xE9\xAB\x85\xE6\x88\x98\xE5\xA3\xAB" },
        { "Hpal", "\xE5\x9C\xA3\xE9\xAA\x91\xE5\xA3\xAB" },
        { "n000", "\xE8\x8B\xA6\xE5\xB7\xA5" },
        { "ewsp", "\xE5\xA5\xB3\xE5\xB7\xAB" },
        { "Hmkg", "\xE5\xB1\xB1\xE4\xB8\x98\xE4\xB9\x8B\xE7\x8E\x8B" },
        { "hrif", "\xE7\x81\xAB\xE6\x9E\xAA\xE6\x89\x8B" },
        { "ugar", "\xE5\x92\x95\xE5\x99\x9C" },
        { "ncpn", "\xE5\x8D\x8A\xE4\xBA\xBA\xE9\xA9\xAC" },
        { "nfsp", "\xE7\xB2\xBE\xE7\x81\xB5\xE9\xBE\x99" },
    };
    for (int i = 0; i < (int)(sizeof(kN) / sizeof(kN[0])); i++)
        if (strcmp(cd, kN[i].code) == 0) return kN[i].name;
    return 0;
}

/* 英雄称谓（UTF-8）：只有英雄码才有 */
static const char* FakeHeroTitle(int idx)
{
    if (idx < 0 || idx >= g_unitCount || !g_unit[idx]) return 0;
    unsigned code = 0;
    __try { code = *(unsigned*)(uintptr_t)(g_unit[idx] + 0x30); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    char cd[5];
    cd[0] = (char)((code >> 24) & 0xFF);
    cd[1] = (char)((code >> 16) & 0xFF);
    cd[2] = (char)((code >> 8)  & 0xFF);
    cd[3] = (char)(code & 0xFF);
    cd[4] = 0;
    static const struct { const char* code; const char* title; } kT[] =
    {
        { "Hpal", "\xE4\xB9\x8C\xE7\x91\x9F\xE5\xB0\x94" },
        { "Hmkg", "\xE7\xA9\x86\xE6\x8B\x89\xE4\xB8\x81" },
    };
    for (int i = 0; i < (int)(sizeof(kT) / sizeof(kT[0])); i++)
        if (strcmp(cd, kT[i].code) == 0) return kT[i].title;
    return 0;
}

/* ---- 固定偏移上的四个桩会调过来的 C 实现 ---- */
static unsigned FakeHandleToUnitC(unsigned h)
{
    int i = FakeUnitIndex(h);
    return (i < 0 || !g_unit[i]) ? 0u : (unsigned)(uintptr_t)g_unit[i];
}

static unsigned __cdecl FakeGetUnitStateC(unsigned h, unsigned state)
{
    int i = FakeUnitIndex(h);
    if (i < 0 || state != 0 || !g_state[i]) return 0;
    float hp = 0.0f;
    __try { hp = *(float*)(uintptr_t)(g_state[i] + g_layout.stateCur); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return BitsF(hp);
}

static const char* FakeStringByIdC(unsigned id)
{
    if (id == 0x6000u) return "ProperNameTest";     /* Propernames 桩：字符串 id 形态 */
    if (id < 0x5000u || id >= 0x5000u + (unsigned)g_unitCount) return 0;
    return FakeHeroTitle((int)(id - 0x5000u));
}

/* ---- 属性 native：返回固定但按单位下标变化的合理值（real 用 EAX 位模式，与引擎一致） ---- */
static unsigned __cdecl FakeNatHeroProperName(unsigned h, unsigned)
{
    int i = FakeUnitIndex(h);
    if (i < 0) return 0;
    return FakeIsHero(i) ? (0x5000u + (unsigned)i) : 0u;   // 非英雄返回 0
}
static unsigned __cdecl FakeNatAttackRange(unsigned h, unsigned)
{
    int i = FakeUnitIndex(h);
    return BitsF(i < 0 ? 0.0f : 128.0f + (float)(i % 4) * 32.0f);
}
static unsigned __cdecl FakeNatDamageMin(unsigned h, unsigned)
{
    int i = FakeUnitIndex(h);
    return BitsF(i < 0 ? 0.0f : 10.0f + (float)i * 2.0f);
}
static unsigned __cdecl FakeNatDamageMax(unsigned h, unsigned)
{
    int i = FakeUnitIndex(h);
    return BitsF(i < 0 ? 0.0f : 15.0f + (float)i * 2.0f + (float)(i % 5));
}
static unsigned __cdecl FakeNatAttackCooldown(unsigned h, unsigned)
{
    int i = FakeUnitIndex(h);
    return BitsF(i < 0 ? 0.0f : 1.0f + (float)(i % 5) * 0.15f);
}
static unsigned __cdecl FakeNatArmor(unsigned h, unsigned)
{
    int i = FakeUnitIndex(h);
    return BitsF(i < 0 ? 0.0f : 1.0f + (float)(i % 7));
}
static unsigned __cdecl FakeNatMoveSpeed(unsigned h, unsigned)
{
    int i = FakeUnitIndex(h);
    return BitsF(i < 0 ? 0.0f : 220.0f + (float)(i % 6) * 30.0f);
}
static unsigned __cdecl FakeNatSightRange(unsigned h, unsigned night)
{
    int i = FakeUnitIndex(h);
    return BitsF(i < 0 ? 0.0f : 1400.0f + (float)(i % 3) * 100.0f + (night ? 200.0f : 0.0f));
}
static unsigned __cdecl FakeNatAcquireRange(unsigned h, unsigned)
{
    int i = FakeUnitIndex(h);
    return BitsF(i < 0 ? 0.0f : 500.0f + (float)(i % 4) * 50.0f);
}
static unsigned __cdecl FakeNatStrength(unsigned h, unsigned)
{
    int i = FakeUnitIndex(h);
    return (i >= 0 && FakeIsHero(i)) ? BitsF(15.0f + (float)(i % 10)) : 0u;
}
static unsigned __cdecl FakeNatAgility(unsigned h, unsigned)
{
    int i = FakeUnitIndex(h);
    return (i >= 0 && FakeIsHero(i)) ? BitsF(12.0f + (float)(i % 8)) : 0u;
}
static unsigned __cdecl FakeNatIntelligence(unsigned h, unsigned)
{
    int i = FakeUnitIndex(h);
    return (i >= 0 && FakeIsHero(i)) ? BitsF(17.0f + (float)(i % 9)) : 0u;
}
static unsigned __cdecl FakeNatUserData(unsigned h, unsigned)
{
    int i = FakeUnitIndex(h);
    return i < 0 ? 0u : (unsigned)(1000 + i);
}

/* ---- 真机日志里的“错 native”诱饵 ----
   它们的名字更短 / 关键字更像，旧版“名字最短优先”的自动匹配必然先挑到：
     GetGameSpeed    -> 移速（返回 0，界面就显示 0）
     GetRandomInt    -> 智力（词元 "Int" 命中）
     GetItemUserData -> 单位附加值
     UnitShareVision -> 视野（vision 命中）
   新版必须靠“精确名单优先 + 排除名单”全部躲开。 */
static unsigned __cdecl FakeNatGameSpeed(unsigned, unsigned)    { return 0u; }          /* 故意返回 0 */
static unsigned __cdecl FakeNatRandomInt(unsigned, unsigned)    { return 42u; }
static unsigned __cdecl FakeNatTurnSpeed(unsigned, unsigned)    { return BitsF(0.6f); }
static unsigned __cdecl FakeNatItemUserData(unsigned, unsigned) { return 7777u; }
static unsigned __cdecl FakeNatShareVision(unsigned, unsigned)  { return 1u; }

/* ---- 单位类型基础数据（ddh 新协议）：ddh 会用 JASS 类型码而不是 handle 调这几个 ---- */
/* JASS string 实参：传进来的是 string_fake 对象指针（[obj+0x08] -> 对象，
   对象 +0x1C -> char*），与引擎 from_string 完全一致。ddh 用 DdhMakeJassString 造
   这个对象；传裸 char* 在这里解不到（真机上更会直接崩）—— 这就是“native 已定位但
   取回 0/空”的原因。 */
static const char* FakeJassStringToC(unsigned s)
{
    if (!s) return 0;
    unsigned obj = 0;
    __try { obj = *(unsigned*)(uintptr_t)(s + 0x08); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    if (obj < 0x10000u) return 0;
    const char* p = 0;
    __try { p = *(const char**)(uintptr_t)(obj + 0x1Cu); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return p;
}

static unsigned __cdecl FakeNatTypeDataString(unsigned typeId, unsigned fieldStr)
{
    const char* field = FakeJassStringToC(fieldStr);
    if (!typeId || !field) return 0;
    if (strcmp(field, "Propernames") == 0) return 0;   /* TEST VARIANT (temp build only): force GetHeroProperName fallback so titles differ per unit */   /* 字符串 id 形态 */
    return 0;
}
static int __cdecl FakeNatTypeDataInt(unsigned typeId, unsigned fieldStr)
{
    const char* field = FakeJassStringToC(fieldStr);
    if (!typeId || !field) return 0;
    if (strcmp(field, "spd") == 0) return 350;
    if (strcmp(field, "sight") == 0) return 1500;
    if (strcmp(field, "nsight") == 0) return 900;
    if (strcmp(field, "def") == 0) return 7;
    if (strcmp(field, "points") == 0) return 1234;
    return 0;
}
static unsigned __cdecl FakeNatTypeDataReal(unsigned typeId, unsigned fieldStr)
{
    const char* field = FakeJassStringToC(fieldStr);
    return (typeId && field) ? BitsF(350.0f) : 0u;
}

/* ---- 往 g_pad 里写桩代码（RWX） ---- */
static void FakeWriteStub(unsigned rva, const unsigned char* code, int len)
{
    unsigned char* p = g_base + rva;
    DWORD old = 0;
    if (!VirtualProtect(p, 64, PAGE_EXECUTE_READWRITE, &old))
    {
        printf("[fake] jass: VirtualProtect(rva 0x%X) failed err=%lu\n", rva, GetLastError());
        return;
    }
    memcpy(p, code, len);
    FlushInstructionCache(GetCurrentProcess(), p, (SIZE_T)len);
}

static void FakeInstallJassStubs(void)
{
    // 0x1D1550: __fastcall(ecx=handle) -> CUnit*；序言必须是 55 8B EC（ddh 会校验）
    {
        unsigned char code[] = { 0x55,0x8B,0xEC, 0x51, 0xE8,0,0,0,0, 0x83,0xC4,0x04, 0x5D, 0xC3 };
        int rel = (int)((unsigned char*)&FakeHandleToUnitC - (g_base + 0x1D1550 + 9));
        memcpy(code + 5, &rel, 4);
        FakeWriteStub(0x1D1550, code, sizeof(code));
    }
    // 0x1E6600: __cdecl(handle, state) -> float 位模式（GetUnitState）
    {
        unsigned char code[] = { 0x55,0x8B,0xEC, 0xFF,0x75,0x0C, 0xFF,0x75,0x08, 0xE8,0,0,0,0,
                                 0x83,0xC4,0x08, 0x5D, 0xC3 };
        int rel = (int)((unsigned char*)&FakeGetUnitStateC - (g_base + 0x1E6600 + 14));
        memcpy(code + 10, &rel, 4);
        FakeWriteStub(0x1E6600, code, sizeof(code));
    }
    // 0x1C2870: __thiscall(ecx=ctx, [esp+4]=id) -> char*；ret 4
    {
        unsigned char code[] = { 0x55,0x8B,0xEC, 0xFF,0x75,0x08, 0xE8,0,0,0,0,
                                 0x83,0xC4,0x04, 0x5D, 0xC2,0x04,0x00 };
        int rel = (int)((unsigned char*)&FakeStringByIdC - (g_base + 0x1C2870 + 11));
        memcpy(code + 7, &rel, 4);
        FakeWriteStub(0x1C2870, code, sizeof(code));
    }
    // 0x326BA0: __fastcall(ecx=code, edx=0) -> char*；前 3 字节必须是 56 8B F2（ddh 校验）
    {
        unsigned char code[] = { 0x56,0x8B,0xF2, 0x55,0x8B,0xEC, 0x51, 0xE8,0,0,0,0,
                                 0x83,0xC4,0x04, 0x5D, 0x5E, 0xC3 };
        int rel = (int)((unsigned char*)&FakeCodeToNameC - (g_base + 0x326BA0 + 12));
        memcpy(code + 8, &rel, 4);
        FakeWriteStub(0x326BA0, code, sizeof(code));
    }
    // 0x4EFB0: get_instance(5) -> JASS 实例（ddh 的 FindNativeFunc 从这里进）
    {
        unsigned char code[] = { 0xB8,0,0,0,0, 0xC3 };
        unsigned inst = (unsigned)(uintptr_t)g_jassInst;
        memcpy(code + 1, &inst, 4);
        FakeWriteStub(0x4EFB0, code, sizeof(code));
    }
}

static void FakeRegisterNative(const char* name, unsigned fn)
{
    if (!g_jassBuck || !g_jassNodes || g_jassNodeCount >= 64) return;
    const unsigned hash = FakeWc3Hash(name);
    unsigned char* node = g_jassNodes + (size_t)g_jassNodeCount * 0x20;
    g_jassNodeCount++;
    *(unsigned*)(node + 0x04) = hash;
    *(unsigned*)(node + 0x18) = (unsigned)(uintptr_t)name;
    *(unsigned*)(node + 0x1C) = fn;
    unsigned char* entry = g_jassBuck + (size_t)(hash & 63u) * 12u;
    *(unsigned*)(node + 0x0C) = *(unsigned*)(entry + 8);    // next = 旧链头
    *(unsigned*)(entry + 8) = (unsigned)(uintptr_t)node;    // 链头 = 本节点
}

static void FakeJassInit(unsigned char* ctx, unsigned char* mgr)
{
    g_jassInst  = (unsigned char*)calloc(1, 0x100);
    g_jassBuck  = (unsigned char*)calloc(64, 12);
    g_jassNodes = (unsigned char*)calloc(64, 0x20);
    if (!g_jassInst || !g_jassBuck || !g_jassNodes)
    {
        printf("[fake] jass: alloc failed\n");
        return;
    }

    // 实例 +0x18 是 native 表：表 +0x1C = 桶，+0x24 = mask（ddh::FindNativeFunc 的读法）
    *(unsigned*)(g_jassInst + 0x18 + 0x1C) = (unsigned)(uintptr_t)g_jassBuck;
    *(unsigned*)(g_jassInst + 0x18 + 0x24) = 63u;

    FakeRegisterNative("GetHeroProperName",   (unsigned)(uintptr_t)&FakeNatHeroProperName);
    FakeRegisterNative("GetUnitAttackRange",  (unsigned)(uintptr_t)&FakeNatAttackRange);
    FakeRegisterNative("GetUnitDamageMin",    (unsigned)(uintptr_t)&FakeNatDamageMin);
    FakeRegisterNative("GetUnitDamageMax",    (unsigned)(uintptr_t)&FakeNatDamageMax);
    FakeRegisterNative("GetUnitAttackCooldown",(unsigned)(uintptr_t)&FakeNatAttackCooldown);
    FakeRegisterNative("GetUnitArmor",        (unsigned)(uintptr_t)&FakeNatArmor);
    FakeRegisterNative("GetUnitMoveSpeed",    (unsigned)(uintptr_t)&FakeNatMoveSpeed);
    FakeRegisterNative("GetUnitSightRange",   (unsigned)(uintptr_t)&FakeNatSightRange);
    FakeRegisterNative("GetUnitAcquireRange", (unsigned)(uintptr_t)&FakeNatAcquireRange);
    FakeRegisterNative("GetUnitStrength",     (unsigned)(uintptr_t)&FakeNatStrength);
    FakeRegisterNative("GetUnitAgility",      (unsigned)(uintptr_t)&FakeNatAgility);
    FakeRegisterNative("GetUnitIntelligence", (unsigned)(uintptr_t)&FakeNatIntelligence);
    FakeRegisterNative("GetUnitUserData",     (unsigned)(uintptr_t)&FakeNatUserData);
    /* 诱饵 native（旧版自动匹配会挑中，新版必须全部排除） */
    FakeRegisterNative("GetGameSpeed",        (unsigned)(uintptr_t)&FakeNatGameSpeed);
    FakeRegisterNative("GetRandomInt",        (unsigned)(uintptr_t)&FakeNatRandomInt);
    FakeRegisterNative("GetUnitTurnSpeed",    (unsigned)(uintptr_t)&FakeNatTurnSpeed);
    FakeRegisterNative("GetItemUserData",     (unsigned)(uintptr_t)&FakeNatItemUserData);
    FakeRegisterNative("UnitShareVision",     (unsigned)(uintptr_t)&FakeNatShareVision);
    FakeRegisterNative("DzAPI_UnitType_GetUnitTypeDataString",
                       (unsigned)(uintptr_t)&FakeNatTypeDataString);
    FakeRegisterNative("DzAPI_UnitType_GetUnitTypeDataInt",
                       (unsigned)(uintptr_t)&FakeNatTypeDataInt);
    FakeRegisterNative("DzAPI_UnitType_GetUnitTypeDataReal",
                       (unsigned)(uintptr_t)&FakeNatTypeDataReal);

    FakeInstallJassStubs();

    // 句柄链：ddh 的 HpObj2HMem 扫 mgr+0x19C 的表（12 字节一项，+4 = 对象），
    // 句柄 = 0x100000 + 下标；mgr+0x198 是“条目数 * 3”（与真机同口径）。
    w32(ctx + 0x1C, (unsigned)(uintptr_t)mgr);
    w32(mgr + 0x198, 3u * (unsigned)g_slots);

    printf("[fake] jass: instance=0x%08X buckets=0x%08X natives=%d "
           "(stubs @0x1D1550/0x1E6600/0x1C2870/0x326BA0/0x4EFB0)\n",
           (unsigned)(uintptr_t)g_jassInst, (unsigned)(uintptr_t)g_jassBuck, g_jassNodeCount);
    fflush(stdout);
}


//----------------------------------------------------------------------------
// 假的“引擎伤害函数”：放在 RVA 0x67DC40，开头字节与真实 game.dll 一致
//   55 8B EC 83 EC 2C 56 57 8B F9  (push ebp; mov ebp,esp; sub esp,0x2C; push esi; push edi; mov edi,ecx)
// 这样 ddh.dll 的挂钩（偷 6 字节 + jmp）能在靶子上被完整验证。
// 调用约定：__fastcall，ecx=受伤单位，其余走栈，结尾 ret 0x10。
//----------------------------------------------------------------------------
struct FakeDamageInfo
{
    unsigned source;     // +0x00 来源单位对象指针
    unsigned weapon;     // +0x04
    unsigned unk2;       // +0x08
    unsigned flag;       // +0x0C bit0=远程 bit8=攻击
    unsigned amountBits; // +0x10 float 位
    unsigned mask;       // +0x14 伤害类型掩码
    unsigned unk6;       // +0x18
    unsigned unk7;       // +0x1C
    unsigned attackType; // +0x20
};

typedef unsigned (__fastcall *FakeDamageFn)(unsigned self, unsigned edx, unsigned a2,
                                            FakeDamageInfo* info, unsigned phys, unsigned src);

static FakeDamageFn g_fakeDamage = 0;

static float g_amp = 1.0f;                     /* FAKE_AMP：地图增伤/减伤倍数（100 = 不增不减） */
static void (__cdecl* g_applyFn)(unsigned victim, FakeDamageInfo* info) = 0;

// 真正“把血扣掉”。ddh.dll 会在伤害函数返回后重新读血，
// 所以这里扣多少，界面上“实际”就是多少；g_amp != 1 时就能看到“伤害 != 实际”。
static void __cdecl FakeApplyDamage(unsigned victim, FakeDamageInfo* info)
{
    if (!victim || !info) return;
    float amount = 0.0f;
    memcpy(&amount, &info->amountBits, 4);
    if (!(amount > 0.0f)) return;

    unsigned idx = 0, obj = 0;
    __try { idx = *(unsigned*)(uintptr_t)(victim + g_layout.hpIndex); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return; }
    if (idx == 0 || idx >= (unsigned)g_slots) return;
    __try { obj = *(unsigned*)(uintptr_t)(g_entries + (size_t)idx * 8 + 4); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return; }
    if (!obj) return;

    __try
    {
        float hp = *(float*)(uintptr_t)(obj + g_layout.stateCur);
        hp -= amount * g_amp;
        if (hp < 0.0f) hp = 0.0f;
        *(float*)(uintptr_t)(obj + g_layout.stateCur) = hp;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
}

static void InstallFakeDamageFunc(void)
{
    // 用模块基址算，别假设 pad 的 RVA 固定
    unsigned char* base = (unsigned char*)GetModuleHandleA("game.dll");
    if (!base) base = (unsigned char*)&g_pad[0];
    unsigned char* p = base + 0x67DC40;
    printf("[fake] game.dll base=%p  pad rva=0x%X\n", base, (unsigned)((char*)&g_pad[0] - (char*)base));
    DWORD old = 0;
    if (!VirtualProtect(p, 4096, PAGE_EXECUTE_READWRITE, &old)) return;

    // 前 6 字节必须是 55 8B EC 83 EC 2C（ddh 的跳板只搬这 6 字节，后面的 56 57 8B F9 也照抄）
    unsigned char code[36] = {
        0x55, 0x8B, 0xEC, 0x83, 0xEC, 0x2C,   // push ebp; mov ebp,esp; sub esp,0x2C  ← ddh 偷走的就是这 6 字节
        0x56, 0x57, 0x8B, 0xF9,               // push esi; push edi; mov edi,ecx
        0xFF, 0x75, 0x0C,                     // push dword ptr [ebp+0Ch]   ; info
        0x57,                                 // push edi                   ; victim
        0xFF, 0x15, 0, 0, 0, 0,               // call dword ptr [&g_applyFn]（地址下面填）
        0x83, 0xC4, 0x08,                     // add esp, 8
        0xB8, 0x01, 0x00, 0x00, 0x00,         // mov eax, 1
        0x5F, 0x5E,                           // pop edi; pop esi
        0x8B, 0xE5,                           // mov esp, ebp
        0x5D,                                 // pop ebp
        0xC2, 0x10, 0x00                      // ret 0x10
    };
    const uintptr_t slot = (uintptr_t)&g_applyFn;
    memcpy(code + 16, &slot, 4);

    g_applyFn = FakeApplyDamage;
    memcpy(p, code, sizeof(code));
    // 注意：**不能**把保护恢复成原值（这里是 .bss，原来是 PAGE_READWRITE，
    // 恢复回去就不可执行了 → 一调用就 DEP 崩）。保持 RWX。
    FlushInstructionCache(GetCurrentProcess(), p, sizeof(code));
    g_fakeDamage = (FakeDamageFn)p;
    printf("[fake] damage func installed at %p (rva 0x67DC40), amp=%.2f, 会真的扣血\n", p, g_amp);
}

// 每 400ms 造一次“伤害事件”：随机受害者/来源 + 各种攻击/伤害类型
static DWORD WINAPI FakeDamageThread(LPVOID)
{
    for (;;)
    {
        Sleep(400);
        if (!g_fakeDamage || g_unitCount <= 0) continue;
        int vi = rand() % g_unitCount;
        int si = rand() % g_unitCount;
        FakeDamageInfo info;
        memset(&info, 0, sizeof(info));
        info.source = (unsigned)(uintptr_t)g_unit[si];
        info.weapon = 1;
        info.flag = (rand() % 2) ? 0x101u : 0x100u;      // bit8=攻击, bit0=是否远程
        float amount = 20.0f + (float)(rand() % 9000) / 10.0f;
        memcpy(&info.amountBits, &amount, 4);
        int dtype = 1 + rand() % 14;
        info.mask = 1u << dtype;                          // YDWE 口径：bit 下标 = dtype
        info.attackType = 1 + rand() % 6;
        g_fakeDamage((unsigned)(uintptr_t)g_unit[vi], 0, 0, &info, 1, 0);
    }
    return 0;
}
static const char* kCodes[12] = {
    "hfoo", "opeo", "ogre", "uske", "Hpal", "n000",
    "ewsp", "Hmkg", "hrif", "ugar", "ncpn", "nfsp"   // 第二个英雄码（山丘之王）用来验证“称谓”两行
};

static int EnvInt(const char* name, int def, int lo, int hi)
{
    char buf[64] = { 0 };
    if (GetEnvironmentVariableA(name, buf, sizeof(buf)) == 0) return def;
    int v = atoi(buf);
    if (v < lo) v = lo;
    if (v > hi) v = hi;
    return v;
}

static void SpawnUnit(int i, int codeIndex)
{
    unsigned char* state = (unsigned char*)calloc(1, 0x200);
    unsigned char* relaunch = (unsigned char*)calloc(1, 0x200);
    unsigned char* unit = (unsigned char*)calloc(1, 0x400);
    if (!state || !relaunch || !unit) return;

    float maxHp = (float)(120 + (i % 40) * 40);
    wf(state + g_layout.stateCur, maxHp);
    wf(state + g_layout.stateMax, maxHp);
    wf(relaunch + 0x78, (float)((i % 64) * 256));
    wf(relaunch + 0x7C, (float)((i % 64) * 128));

    unsigned stateIdx = 1 + (unsigned)i;
    unsigned posIdx = 1 + (unsigned)g_unitCount + (unsigned)i;
    w32(g_entries + stateIdx * 8 + 4, (unsigned)(uintptr_t)state);
    w32(g_entries + posIdx * 8 + 4, (unsigned)(uintptr_t)relaunch);

    WriteTypeCode(unit + 0x30, kCodes[codeIndex % 12]);
    // 真 CUnit 的 +0x00 是 game.dll 里的虚表指针；靶子用自己模块里的地址来模拟
    w32(unit + 0x00, (unsigned)(uintptr_t)&g_pad[0x1000]);   // FAKE_VTABLE
    w32(unit + g_layout.hpIndex, stateIdx);
    w32(unit + 0xC0, stateIdx);
    w32(unit + 0x16C, posIdx);
    if (g_table) w32(g_table + (unsigned)i * 12 + 4, (unsigned)(uintptr_t)unit);

    g_unit[i] = unit;
    g_state[i] = state;
    g_relaunch[i] = relaunch;
    WriteTypeCode(&g_code[(size_t)i * 5], kCodes[codeIndex % 12]);
    g_code[(size_t)i * 5 + 4] = 0;

    if (i < 12)
    {
        printf("[fake] spawn unit %d code=%s hp=%.1f unit=0x%08X state=0x%08X\n",
               i, &g_code[(size_t)i * 5], maxHp, (unsigned)(uintptr_t)unit, (unsigned)(uintptr_t)state);
        fflush(stdout);
    }
}

static DWORD WINAPI TickThread(LPVOID)
{
    Sleep(1500);   // give the tool time to attach
    for (int tick = 0; !InterlockedCompareExchange(&g_stop, 0, 0); tick++)
    {
        Sleep(80);
        if (InterlockedCompareExchange(&g_pause, 0, 0)) continue;
        if (EnvInt("FAKE_IMMORTAL", 0, 0, 1) != 0) continue;   // 测“认不认得出单位”，别让它们死掉
        for (int i = 0; i < g_unitCount; i++)
        {
            if (!g_unit[i] || !g_state[i]) continue;
            float hp = *(float*)(g_state[i] + g_layout.stateCur);
            if (hp <= 0.0f) continue;

            float dmg = (float)(5 + rand() % 26);
            hp -= dmg;
            if (hp <= 0.0f) hp = 0.0f;
            wf(g_state[i] + g_layout.stateCur, hp);

            if (hp <= 0.0f)
            {
                printf("[fake] unit %d (%s) DIED\n", i, &g_code[(size_t)i * 5]);
                fflush(stdout);
                // Recycle after a while; clear BOTH tables first (a real engine never
                // leaves a stale pointer to a freed state object behind).
                // FAKE_NO_RESPAWN=1：只死不复生，用来测“生命表搬家”时不受回收路径干扰。
                if (EnvInt("FAKE_NO_RESPAWN", 0, 0, 1) != 0) continue;
                Sleep(2000);
                if (g_table) w32(g_table + (unsigned)i * 12 + 4, 0);
                if (g_entries)
                {
                    w32(g_entries + (unsigned)(1 + i) * 8 + 4, 0);
                    w32(g_entries + (unsigned)(1 + g_unitCount + i) * 8 + 4, 0);
                }
                if (g_unit[i]) free(g_unit[i]);
                if (g_state[i]) free(g_state[i]);
                if (g_relaunch[i]) free(g_relaunch[i]);
                g_unit[i] = g_state[i] = g_relaunch[i] = 0;
                SpawnUnit(i, (i + tick / 3 + 1) % 12);
                printf("[fake] unit %d respawned as %s\n", i, &g_code[(size_t)i * 5]);
                fflush(stdout);
            }
        }
    }
    return 0;
}

//----------------------------------------------------------------------------
// Heap junk: a big, scattered, mostly-random heap so the deep scan has to walk
// something realistic. With FAKE_DECOY=1 it also contains ASCII runs that look
// like 4-char type codes, to exercise the false-positive filters.
//----------------------------------------------------------------------------
static void BuildHeapJunk(int megabytes, bool decoys)
{
    if (megabytes <= 0) return;
    int blocks = megabytes * 1024 / 64;          // 64 KB blocks
    unsigned seed = 0x12345678u;
    for (int b = 0; b < blocks; b++)
    {
        unsigned char* p = (unsigned char*)malloc(64 * 1024);
        if (!p) break;
        for (int i = 0; i < 64 * 1024; i++)
        {
            seed = seed * 1664525u + 1013904223u;
            p[i] = (unsigned char)(seed >> 24);
        }
        if (decoys && (b % 3) == 0)
        {
            // every decoy block gets a few "type code"-looking runs at random offsets
            for (int k = 0; k < 8; k++)
            {
                int off = (int)((seed >> 8) % (64 * 1024 - 64)) & ~3;
                const char* t = kCodes[(seed >> 16) % 12];
                WriteTypeCode(p + off, t);
            }
        }
        g_heapJunk.push_back(p);
    }
    printf("[fake] heap junk: %d blocks (%d MB), decoys=%d\n", (int)g_heapJunk.size(), megabytes, decoys ? 1 : 0);
    fflush(stdout);
}

//----------------------------------------------------------------------------
// FAKE_LATE_MS=N：装好之后第 N 毫秒，把生命表搬到一块**新分配**的内存里
// （模拟真实引擎进图/扩容时重排生命表）。旧表整块释放掉，于是：
//   * ThisGame+0x0C 指向一块“attach 之后才出现”的新区域；
//   * 软件缓存的区域表里没有它 → 旧代码会把它判成“未映射/不可读”，
//     接着去挑一个像表的垃圾地址，全场单位判死。
// 这正是实机 15:02~15:13 那几次的复现。
//----------------------------------------------------------------------------
static DWORD WINAPI LateMoveThread(LPVOID param)
{
    int ms = (int)(INT_PTR)param;
    InterlockedExchange(&g_pause, 1);
    if (ms > 0) Sleep((DWORD)ms);

    size_t bytes = (size_t)g_slots * 8;
    unsigned char* fresh = (unsigned char*)VirtualAlloc(g_reserve + 0x01000000, bytes, MEM_COMMIT, PAGE_READWRITE);
    if (!fresh) { printf("[fake] late move: VirtualAlloc failed\n"); InterlockedExchange(&g_pause, 0); fflush(stdout); return 0; }
    Sleep(2500);   // 等 tick 线程从死亡路径里的 Sleep(2000) 醒过来并走到 pause 检查点，再动表
    memcpy(fresh, g_entries, bytes);
    unsigned char* old = g_entries;
    g_entries = fresh;
    if (g_thisGame) w32(g_thisGame + 0x0C, (unsigned)(uintptr_t)fresh);
    if (old) VirtualFree(old, bytes, MEM_DECOMMIT);   // dwSize 必须给！给 0 会把整段预留区都 decommit 掉（连新表一起）
    InterlockedExchange(&g_pause, 0);
    printf("[fake] late move: entries 0x%08X -> 0x%08X (%u KB), old decommitted\n",
           (unsigned)(uintptr_t)old, (unsigned)(uintptr_t)fresh, (unsigned)(bytes / 1024));
    fflush(stdout);
    return 0;
}

extern "C" __declspec(dllexport) void fake_stop(void)
{
    InterlockedExchange(&g_stop, 1);
}

extern "C" __declspec(dllexport) int fake_start(void)
{
    // Touch both ends of the pad so the linker cannot drop it: the module image
    // must actually contain (and commit) RVAs 0xBE40A8 / 0xBE4238.
    g_pad[0] = 1;
    g_pad[sizeof(g_pad) - 1] = 1;

    char env[64] = { 0 };
    if (GetEnvironmentVariableA("FAKE_LAYOUT", env, sizeof(env)) > 0 &&
        _stricmp(env, "weird") == 0)
    {
        g_layout.hpIndex = 0xA4u;
        g_layout.stateCur = 0x68u;
        g_layout.stateMax = 0x74u;   // still max = cur + 12
        printf("[fake] using WEIRD layout: hpIndex=0x%X cur=0x%X max=0x%X\n",
               g_layout.hpIndex, g_layout.stateCur, g_layout.stateMax);
    }
    else
    {
        printf("[fake] using standard (War3Trainer) layout\n");
    }

    g_unitCount = EnvInt("FAKE_UNITS", 12, 1, 2000);
    g_slots = g_unitCount * 4 + 64;
    g_unit.assign(g_unitCount, (unsigned char*)0);
    g_state.assign(g_unitCount, (unsigned char*)0);
    g_relaunch.assign(g_unitCount, (unsigned char*)0);
    g_code.assign((size_t)g_unitCount * 5, 0);
    printf("[fake] units=%d slots=%d\n", g_unitCount, g_slots);

    unsigned char* base = (unsigned char*)GetModuleHandleA("game.dll");
    if (!base)
    {
        printf("[fake] GetModuleHandle(game.dll) failed\n");
        return 1;
    }
    g_base = base;

    {
        unsigned padRva = (unsigned)((unsigned char*)g_pad - base);
        printf("[fake] pad rva=0x%08X size=0x%X  covers 0x%08X=%d 0x%08X=%d\n",
               padRva, (unsigned)sizeof(g_pad),
               kCtxRva, (kCtxRva >= padRva && kCtxRva < padRva + sizeof(g_pad)) ? 1 : 0,
               kThisGameRva, (kThisGameRva >= padRva && kThisGameRva < padRva + sizeof(g_pad)) ? 1 : 0);
        MEMORY_BASIC_INFORMATION mbi;
        if (VirtualQuery(base + kCtxRva, &mbi, sizeof(mbi)) == 0 ||
            mbi.State != MEM_COMMIT ||
            (mbi.Protect & (PAGE_READWRITE | PAGE_WRITECOPY | PAGE_EXECUTE_READWRITE)) == 0)
        {
            printf("[fake] FATAL: RVA 0x%08X is not writable committed memory\n", kCtxRva);
            return 3;
        }
    }

    BuildHeapJunk(EnvInt("FAKE_HEAP_MB", 0, 0, 2048), EnvInt("FAKE_DECOY", 0, 0, 1) != 0);

    unsigned char* ctx      = (unsigned char*)calloc(1, 0x800);
    unsigned char* player0  = (unsigned char*)calloc(1, 0x200);
    unsigned char* sel      = (unsigned char*)calloc(1, 0x400);
    unsigned char* node     = (unsigned char*)calloc(1, 0x20);
    unsigned char* thisGame = (unsigned char*)calloc(1, 0x100);
    unsigned char* mgr      = (unsigned char*)calloc(1, 0x800);
    // MAPNAME: ctx+0x30 -> mapInfo, mapInfo+0x04 = CString (+8 -> data, data+8 -> chars)
    unsigned char* mapInfo     = (unsigned char*)calloc(1, 0x100);
    unsigned char* mapNameData = (unsigned char*)calloc(1, 0x100);
    // 表用 VirtualAlloc 分配：这样 FAKE_LATE_MS 搬家时能整块 MEM_RELEASE 掉，
    // 旧表变成“真的读不到”，才能复现“区域表快照过期”。
    // 表放在一块 64MB 的【预留区】里：初始只 commit 第一块。
    // 搬家时去 commit 远处的一块 —— 那地址在 attach 时还是 MEM_RESERVE（不可读），
    // 所以软件的“区域表快照”里一定没有它，正好复现“新分配的表被判成未映射”。
    g_reserve               = (unsigned char*)VirtualAlloc(0, 64u * 1024u * 1024u, MEM_RESERVE, PAGE_NOACCESS);
    g_entries               = g_reserve ? (unsigned char*)VirtualAlloc(g_reserve, (size_t)g_slots * 8, MEM_COMMIT, PAGE_READWRITE) : 0;
    g_table                 = (unsigned char*)calloc(g_slots, 12);

    if (!ctx || !player0 || !sel || !node || !thisGame || !mgr || !g_entries || !g_table || !mapInfo || !mapNameData)
    {
        printf("[fake] alloc failed\n");
        return 2;
    }

    w32(base + kCtxRva, (unsigned)(uintptr_t)ctx);
    w32(base + kThisGameRva, (unsigned)(uintptr_t)thisGame);
    w32(thisGame + 0x0C, (unsigned)(uintptr_t)g_entries);
    g_thisGame = thisGame;
    w32(thisGame + 0x1C, (unsigned)g_slots);   // 容量（引擎在 RVA 0x374CD3 也是这样判上限的）

    w16(ctx + 0x28, 0);
    w32(ctx + 0x30, (unsigned)(uintptr_t)mapInfo);
    w32(mapInfo + 0x04 + 0x08, (unsigned)(uintptr_t)mapNameData);
    w32(mapNameData + 0x04, 1);
    w32(mapNameData + 0x1C, (unsigned)(uintptr_t)(mapNameData + 0x40));
    memcpy(mapNameData + 0x40, "Fake Map - Ice Throne", sizeof("Fake Map - Ice Throne"));
    w32(ctx + 0x58 + 0, (unsigned)(uintptr_t)player0);
    w32(ctx + 0xF4 + 0x19C, (unsigned)(uintptr_t)g_table);
    w32(ctx + 0xF4, (unsigned)(uintptr_t)mgr);
    w32(mgr + 0x19C, (unsigned)(uintptr_t)g_table);

    w32(player0 + 0x34, (unsigned)(uintptr_t)sel);
    w32(sel + 0x1F0, (unsigned)(uintptr_t)node);
    w32(sel + 0x1F8, 1);

    for (int i = 0; i < g_unitCount; i++) SpawnUnit(i, i);

    // owner field: every unit carries the same CPlayer* at +0x1C
    for (int i = 0; i < g_unitCount; i++)
        if (g_unit[i]) w32(g_unit[i] + 0x1C, (unsigned)(uintptr_t)player0);

    // 假 JASS（native 表 + 句柄链 + 字符串表）：验证 ddh v10 的属性解析全链路。
    // FAKE_NO_JASS=1 时整块不装 —— 属性列会全部是 ?（“地图没有 JAPI”同款行为）。
    if (EnvInt("FAKE_NO_JASS", 0, 0, 1) != 0)
        printf("[fake] FAKE_NO_JASS=1 -> fake JASS native table not installed\n");
    else
        FakeJassInit(ctx, mgr);

    w32(node + 8, (unsigned)(uintptr_t)g_unit[0]);
    w32(node + 0, 0);

    g_amp = (float)EnvInt("FAKE_AMP", 100, 1, 1000) / 100.0f;   // 200 = 地图增伤 2 倍
    if (EnvInt("FAKE_NO_DAMAGE", 0, 0, 1) == 0)
    {
        InstallFakeDamageFunc();
        if (g_fakeDamage) { HANDLE th = CreateThread(0, 0, FakeDamageThread, 0, 0, 0); if (th) CloseHandle(th); }
    }
    else
    {
        printf("[fake] FAKE_NO_DAMAGE=1 -> fake damage function not installed\n");
    }

    printf("[fake] ctx=0x%08X thisGame=0x%08X entries=0x%08X table=0x%08X player0=0x%08X\n",
           (unsigned)(uintptr_t)ctx, (unsigned)(uintptr_t)thisGame,
           (unsigned)(uintptr_t)g_entries, (unsigned)(uintptr_t)g_table,
           (unsigned)(uintptr_t)player0);
    printf("[fake] base=0x%08X  wrote RVA slots: 0x%08X / 0x%08X\n",
           (unsigned)(uintptr_t)base, kCtxRva, kThisGameRva);
    fflush(stdout);

    CreateThread(0, 0, TickThread, 0, 0, NULL);

    {
        int lateMs = EnvInt("FAKE_LATE_MS", 0, 0, 600000);
        if (lateMs > 0)
        {
            HANDLE lt = CreateThread(0, 0, LateMoveThread, (LPVOID)(INT_PTR)lateMs, 0, 0);
            if (lt) CloseHandle(lt);
            printf("[fake] late table move scheduled in %d ms\n", lateMs);
            fflush(stdout);
        }
    }
    return 0;
}

BOOL APIENTRY DllMain(HMODULE, DWORD, LPVOID) { return TRUE; }



