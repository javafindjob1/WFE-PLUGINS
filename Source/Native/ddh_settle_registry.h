#pragma once

#include <stdint.h>
#include <string.h>
#include <vector>

struct DdhDbSettleAcc
{
    uint32_t victim;
    uint32_t code;
    int32_t  owner;
    char     name[64];
    double   total;
    double   maxHit;
    uint32_t hits;
    uint32_t firstTick;
    uint32_t lastTick;
    uint32_t fatalSource;
    uint32_t fatalCode;
    char     fatalName[64];
    double   fatalDmg;
};

/*
 * One accumulator per observed victim life.  The registry never evicts an
 * active victim to make room for another one; entries are removed after a
 * fatal settlement is written or when the game session changes.
 *
 * Only the SQLite worker thread is expected to call these methods.
 */
class DdhDbSettleRegistry
{
public:
    DdhDbSettleAcc* Ensure(uint32_t victim, uint32_t code, int32_t owner, const char* name)
    {
        for (size_t i = 0; i < items_.size(); ++i)
        {
            DdhDbSettleAcc& a = items_[i];
            if (a.victim != victim) continue;

            /* An address can be reused for another unit type.  Never merge
               totals from two different lives merely because the pointer
               happens to match. */
            if (a.code != code)
            {
                memset(&a, 0, sizeof(a));
                a.victim = victim;
                a.code = code;
                a.owner = owner;
                CopyName(a.name, sizeof(a.name), name);
            }
            return &a;
        }

        DdhDbSettleAcc a;
        memset(&a, 0, sizeof(a));
        a.victim = victim;
        a.code = code;
        a.owner = owner;
        CopyName(a.name, sizeof(a.name), name);
        items_.push_back(a);
        return &items_.back();
    }

    bool Remove(uint32_t victim)
    {
        for (size_t i = 0; i < items_.size(); ++i)
        {
            if (items_[i].victim != victim) continue;
            items_[i] = items_.back();
            items_.pop_back();
            return true;
        }
        return false;
    }

    void Clear()
    {
        std::vector<DdhDbSettleAcc>().swap(items_);
    }

    size_t Size() const
    {
        return items_.size();
    }

private:
    static void CopyName(char* dst, size_t cap, const char* src)
    {
        if (!dst || cap == 0) return;
        if (!src)
        {
            dst[0] = 0;
            return;
        }
        size_t n = 0;
        while (n + 1 < cap && src[n]) ++n;
        memcpy(dst, src, n);
        dst[n] = 0;
    }

    std::vector<DdhDbSettleAcc> items_;
};
