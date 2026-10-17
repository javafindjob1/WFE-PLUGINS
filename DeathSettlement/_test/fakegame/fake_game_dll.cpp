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
static unsigned char* g_entries = 0;
static unsigned char* g_table = 0;

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

static const char* kCodes[12] = {
    "hfoo", "opeo", "ogre", "uske", "Hpal", "n000",
    "ewsp", "hkni", "hrif", "ugar", "ncpn", "nfsp"
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
    g_entries               = (unsigned char*)calloc(g_slots, 8);
    g_table                 = (unsigned char*)calloc(g_slots, 12);

    if (!ctx || !player0 || !sel || !node || !thisGame || !mgr || !g_entries || !g_table)
    {
        printf("[fake] alloc failed\n");
        return 2;
    }

    w32(base + kCtxRva, (unsigned)(uintptr_t)ctx);
    w32(base + kThisGameRva, (unsigned)(uintptr_t)thisGame);
    w32(thisGame + 0x0C, (unsigned)(uintptr_t)g_entries);
    w32(thisGame + 0x1C, (unsigned)g_slots);   // 容量（引擎在 RVA 0x374CD3 也是这样判上限的）

    w16(ctx + 0x28, 0);
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

    w32(node + 8, (unsigned)(uintptr_t)g_unit[0]);
    w32(node + 0, 0);

    printf("[fake] ctx=0x%08X thisGame=0x%08X entries=0x%08X table=0x%08X player0=0x%08X\n",
           (unsigned)(uintptr_t)ctx, (unsigned)(uintptr_t)thisGame,
           (unsigned)(uintptr_t)g_entries, (unsigned)(uintptr_t)g_table,
           (unsigned)(uintptr_t)player0);
    printf("[fake] base=0x%08X  wrote RVA slots: 0x%08X / 0x%08X\n",
           (unsigned)(uintptr_t)base, kCtxRva, kThisGameRva);
    fflush(stdout);

    CreateThread(0, 0, TickThread, 0, 0, NULL);
    return 0;
}

BOOL APIENTRY DllMain(HMODULE, DWORD, LPVOID) { return TRUE; }



