//----------------------------------------------------------------------------
// hooktest.cpp -- 在**同一个进程里**验证挂钩机制（不需要注入、不需要游戏）
//
// 验证的东西和 ddh.dll 里一模一样：
//   1) 目标函数开头是 55 8B EC 83 EC 2C（push ebp; mov ebp,esp; sub esp,0x2C）
//   2) 偷走 6 字节 → 写 E9 rel32 + 90
//   3) 跳板重放这 6 字节再跳回 target+6
//   4) 入口裸桩：pushad/pushfd 保存现场 → 按正确偏移取 this/a2/info/phys/src
//      → 调 recorder → 恢复现场 → jmp 跳板
//   5) 原函数返回值得以保留（我们只是“插一脚”，不改变语义）
//----------------------------------------------------------------------------

#include <windows.h>
#include <stdio.h>
#include <string.h>

static volatile LONG g_calls = 0;
static unsigned g_seenThis = 0, g_seenA2 = 0, g_seenInfo = 0, g_seenPhys = 0, g_seenSrc = 0;
static unsigned g_seenAmount = 0, g_seenFlag = 0, g_seenAttack = 0, g_seenMask = 0, g_seenSrc2 = 0;

static unsigned char* g_target = NULL;
static unsigned char* g_tramp = NULL;
static unsigned char  g_saved[8];

/* 与 ddh.dll 完全相同的函数形态（naked 保证字节一模一样） */
extern "C" void __cdecl HookRecord(unsigned self, unsigned a2, unsigned info, unsigned phys, unsigned src);

static void __declspec(naked) HookEntry(void)
{
    __asm
    {
        pushad
        pushfd
        mov  eax, [esp + 0x34]      /* src */
        mov  ebx, [esp + 0x30]      /* phys */
        mov  edx, [esp + 0x2C]      /* info */
        mov  esi, [esp + 0x28]      /* a2 */
        mov  ecx, [esp + 0x1C]      /* this */
        push eax
        push ebx
        push edx
        push esi
        push ecx
        call HookRecord
        add  esp, 20
        popfd
        popad
        jmp  [g_tramp]
    }
}

void __cdecl HookRecord(unsigned self, unsigned a2, unsigned info, unsigned phys, unsigned src)
{
    InterlockedIncrement(&g_calls);
    g_seenThis = self; g_seenA2 = a2; g_seenInfo = info; g_seenPhys = phys; g_seenSrc = src;
    if (info > 0x10000)
    {
        const unsigned* p = (const unsigned*)info;
        g_seenSrc2 = p[0];
        g_seenFlag = p[3];
        g_seenAmount = p[4];
        g_seenMask = p[5];
        g_seenAttack = p[8];
    }
}


static unsigned __declspec(naked) __fastcall TargetFnRaw(unsigned self, unsigned, unsigned a2, unsigned* info, unsigned phys, unsigned src)
{
    __asm
    {
        push ebp
        mov  ebp, esp
        sub  esp, 0x2C
        push esi
        push edi
        mov  edi, ecx
        mov  eax, [ebp + 0x0C]
        mov  eax, [eax + 0x10]
        add  eax, [ebp + 0x08]
        add  eax, [ebp + 0x10]
        add  eax, [ebp + 0x14]
        add  eax, ecx
        pop  edi
        pop  esi
        mov  esp, ebp
        pop  ebp
        ret  0x10
    }
}

typedef unsigned (__fastcall *Fn)(unsigned, unsigned, unsigned, unsigned*, unsigned, unsigned);

static bool Install(unsigned char* at)
{
    const unsigned char prologue[6] = { 0x55, 0x8B, 0xEC, 0x83, 0xEC, 0x2C };
    if (memcmp(at, prologue, 6) != 0)
    {
        printf("[test] 目标函数 prologue 不对: %02X %02X %02X %02X %02X %02X\n",
               at[0], at[1], at[2], at[3], at[4], at[5]);
        return false;
    }

    g_target = at;
    g_tramp = (unsigned char*)VirtualAlloc(NULL, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
    if (!g_tramp) return false;

    memcpy(g_tramp, prologue, 6);
    unsigned char* p = g_tramp + 6;
    p[0] = 0xE9;
    int rel = (int)((at + 6) - (p + 5));
    memcpy(p + 1, &rel, 4);

    memcpy(g_saved, at, 6);
    DWORD old = 0;
    if (!VirtualProtect(at, 16, PAGE_EXECUTE_READWRITE, &old)) return false;
    at[0] = 0xE9;
    int rel2 = (int)((unsigned char*)&HookEntry - (at + 5));
    memcpy(at + 1, &rel2, 4);
    at[5] = 0x90;
    FlushInstructionCache(GetCurrentProcess(), at, 6);
    VirtualProtect(at, 16, old, &old);
    return true;
}

int main()
{
    Fn fn = (Fn)(void*)TargetFnRaw;

    unsigned info[9] = { 0 };
    info[0] = 0x11223344;   /* source */
    info[3] = 0x101;        /* flag */
    float amount = 1234.5f;
    memcpy(&info[4], &amount, 4);
    info[5] = 1u << 5;      /* damage mask → log2-1 = 4 */
    info[8] = 3;            /* attack type */

    unsigned self = 0x1000, a2 = 7, phys = 1, src = 0;

    unsigned before = fn(self, 0, a2, info, phys, src);
    printf("[test] 未挂钩: 返回 0x%X（期望 0x%X）\n", before, self + 1234 /*≈*/ + a2 + phys + src);

    if (!Install((unsigned char*)TargetFnRaw)) { printf("[test] 挂钩失败\n"); return 1; }

    unsigned after = fn(self, 0, a2, info, phys, src);
    printf("[test] 已挂钩: 返回 0x%X（应与未挂钩一致）  recorder 调用次数=%ld\n", after, g_calls);
    printf("[test] recorder 收到: this=0x%X a2=%u info=0x%X phys=%u src=%u\n",
           g_seenThis, g_seenA2, g_seenInfo, g_seenPhys, g_seenSrc);
    printf("[test] info 解析: source=0x%X flag=0x%X amount=%.1f mask=0x%X atype=%u\n",
           g_seenSrc2, g_seenFlag, *(float*)&g_seenAmount, g_seenMask, g_seenAttack);

    bool ok = (after == before) && (g_calls == 1) && (g_seenThis == self) && (g_seenA2 == a2)
              && (g_seenPhys == phys) && (g_seenSrc2 == info[0]) && (g_seenFlag == info[3])
              && (g_seenMask == info[5]) && (g_seenAttack == info[8]);

    printf("[test] 结果: %s\n", ok ? "PASS" : "FAIL");
    return ok ? 0 : 2;
}
