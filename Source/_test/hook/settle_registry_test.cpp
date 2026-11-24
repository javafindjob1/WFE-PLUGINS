#include <stdio.h>
#include <stdint.h>

#include "ddh_settle_registry.h"

static int g_failures = 0;

static void Check(bool ok, const char* what)
{
    printf("[%s] %s\n", ok ? "PASS" : "FAIL", what);
    if (!ok) ++g_failures;
}

int main(void)
{
    DdhDbSettleRegistry registry;
    const uint32_t victim = 0x31A0F654u;

    DdhDbSettleAcc* target = registry.Ensure(victim, 0x45303336u, 0, "target");
    Check(target != NULL, "create target accumulator");
    if (!target) return 1;

    target->total = 47047.101;
    target->hits = 11;
    target->firstTick = 5193968;
    target->lastTick = 5199406;

    for (uint32_t i = 0; i < 4096; ++i)
    {
        uint32_t other = 0x40000000u + i * 64u;
        registry.Ensure(other, 0x6E666774u, (int32_t)(i % 8), "other");
    }

    target = registry.Ensure(victim, 0x45303336u, 0, "target");
    Check(target != NULL, "target survives more than 64 active victims");
    Check(target && target->hits == 11 && target->firstTick == 5193968 &&
          target->lastTick == 5199406 && target->total > 47047.100,
          "target total/hits and first/last tick are preserved");
    Check(registry.Size() == 4097, "dynamic registry does not overwrite active victims");

    Check(registry.Remove(victim), "remove target after fatal settlement");
    target = registry.Ensure(victim, 0x45303336u, 0, "target");
    Check(target && target->hits == 0 && target->firstTick == 0,
          "reused address starts a fresh accumulator");

    target->hits = 3;
    target->firstTick = 9000;
    target = registry.Ensure(victim, 0x48464F4Fu, 1, "replacement");
    Check(target && target->hits == 0 && target->firstTick == 0 &&
          target->code == 0x48464F4Fu,
          "different type code resets a reused address");

    printf("\n%s (failures=%d)\n",
           g_failures == 0 ? "== settlement registry test passed ==" :
                             "== settlement registry test failed ==",
           g_failures);
    return g_failures == 0 ? 0 : (g_failures > 100 ? 100 : g_failures);
}
