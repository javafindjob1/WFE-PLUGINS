/* ===========================================================================
   ddh：把伤害明细写进 SQLite（sqlite3 静态编进 ddh.dll）
   ---------------------------------------------------------------------------
   · 伤害钩子只填共享事件环，绝不做文件/数据库 I/O；
   · 后台线程每 250ms 读取共享环，一个事务批量 INSERT；
   · 库文件：%LOCALAPPDATA%\War3DeathSettlement\ddh\ddh-events.db
   · 对局主键使用 ctx + 游戏状态对象 ID，不使用进程 PID；
   · 表结构固定，C# 端按同一套列名只读。
   =========================================================================== */
#include "sqlite/sqlite3.h"
#include "ddh_settle_registry.h"

typedef int  (__cdecl *pfn_sqlite3_open_v2)(const char*, sqlite3**, int, const char*);
typedef int  (__cdecl *pfn_sqlite3_close)(sqlite3*);
typedef int  (__cdecl *pfn_sqlite3_exec)(sqlite3*, const char*, void*, void*, char**);
typedef int  (__cdecl *pfn_sqlite3_prepare_v2)(sqlite3*, const char*, int, sqlite3_stmt**, const char**);
typedef int  (__cdecl *pfn_sqlite3_bind_int64)(sqlite3_stmt*, int, long long);
typedef int  (__cdecl *pfn_sqlite3_bind_double)(sqlite3_stmt*, int, double);
typedef int  (__cdecl *pfn_sqlite3_bind_text)(sqlite3_stmt*, int, const char*, int, void (__cdecl *)(void*));
typedef int  (__cdecl *pfn_sqlite3_step)(sqlite3_stmt*);
typedef int  (__cdecl *pfn_sqlite3_reset)(sqlite3_stmt*);
typedef int  (__cdecl *pfn_sqlite3_clear_bindings)(sqlite3_stmt*);
typedef int  (__cdecl *pfn_sqlite3_finalize)(sqlite3_stmt*);
typedef int  (__cdecl *pfn_sqlite3_column_int)(sqlite3_stmt*, int);
typedef const char* (__cdecl *pfn_sqlite3_errmsg)(sqlite3*);

#define DDH_SQLITE_OK   0
#define DDH_SQLITE_ROW  100
#define DDH_SQLITE_DONE 101
#define DDH_SQLITE_TRANSIENT SQLITE_TRANSIENT

static HMODULE g_dbDll = NULL;
static pfn_sqlite3_open_v2       g_sqlOpen = NULL;
static pfn_sqlite3_close          g_sqlClose = NULL;
static pfn_sqlite3_exec           g_sqlExec = NULL;
static pfn_sqlite3_prepare_v2     g_sqlPrepare = NULL;
static pfn_sqlite3_bind_int64     g_sqlBindI64 = NULL;
static pfn_sqlite3_bind_double    g_sqlBindDouble = NULL;
static pfn_sqlite3_bind_text      g_sqlBindText = NULL;
static pfn_sqlite3_step           g_sqlStep = NULL;
static pfn_sqlite3_reset          g_sqlReset = NULL;
static pfn_sqlite3_clear_bindings g_sqlClear = NULL;
static pfn_sqlite3_finalize       g_sqlFinalize = NULL;
static pfn_sqlite3_column_int     g_sqlColumnInt = NULL;
static pfn_sqlite3_errmsg         g_sqlErrmsg = NULL;

static sqlite3*      g_db = NULL;
static sqlite3_stmt* g_dbStmt = NULL;
static sqlite3_stmt* g_dbSettleStmt = NULL;
static sqlite3_stmt* g_dbUnitStmt = NULL;
static sqlite3_stmt* g_dbSessionStmt = NULL;
static int           g_dbDisabled = 0;
static int           g_dbReady = 0;
static int           g_dbFailedLogged = 0;
static DWORD         g_dbRetryAt = 0;
static char          g_dbActiveSession[24] = { 0 };

static void LogLine(const char* fmt, ...);
static const char* DdhCodeText(uint32_t code);

struct DdhDbRow
{
    uint32_t seq;
    uint32_t tickMs;
    uint64_t wallMs;
    uint32_t victim;
    uint32_t victimCode;
    uint32_t source;
    uint32_t sourceCode;
    int32_t  victimOwner;
    int32_t  sourceOwner;
    float    amount;
    float    engineDamage;
    float    finalDamage;
    float    actual;
    float    hpBefore;
    float    hpAfter;
    uint32_t hpValid;
    uint32_t attackType;
    uint32_t damageMask;
    uint32_t isPhysical;
    uint32_t flag;
    uint32_t depth;
    uint32_t finalFlags;
    char     victimName[64];
    char     sourceName[64];
    char     sessionId[24];
};

#define DDH_DB_MAX_SESSIONS 50
static volatile LONG g_dbThreadStarted = 0;

typedef struct DdhDbSessionKey
{
    uint32_t ctx;
    uint32_t game;
    char     id[24];
} DdhDbSessionKey;

static void DdhDbMarkSessionActive(const char* sessionId)
{
    if (!sessionId || !sessionId[0]) return;
    strncpy_s(g_dbActiveSession, sizeof(g_dbActiveSession), sessionId, _TRUNCATE);
}

static DdhDbSessionKey DdhDbCurrentSession(void)
{
    DdhDbSessionKey k;
    memset(&k, 0, sizeof(k));
    if (g_modBase)
    {
        __try { k.ctx = *(const uint32_t*)(uintptr_t)(g_modBase + 0x00BE4238u); }
        __except (EXCEPTION_EXECUTE_HANDLER) { k.ctx = 0; }
        __try { k.game = *(const uint32_t*)(uintptr_t)(g_modBase + 0x00BE40A8u); }
        __except (EXCEPTION_EXECUTE_HANDLER) { k.game = 0; }
    }
    DdhSprintf(k.id, sizeof(k.id), "%08X-%08X", k.ctx, k.game);
    return k;
}

static int DdhDbEnabled(void)
{
    return 1;
}

static void DdhDbBuildPath(char* out, size_t cap)
{
    if (!out || !cap) return;
    char base[MAX_PATH] = { 0 };
    DWORD n = GetEnvironmentVariableA("LOCALAPPDATA", base, sizeof(base));
    if (n == 0 || !base[0])
        GetTempPathA((DWORD)sizeof(base), base);
    char dir[MAX_PATH] = { 0 };
    DdhSprintf(dir, sizeof(dir), "%s\\War3DeathSettlement", base);
    CreateDirectoryA(dir, NULL);
    DdhSprintf(dir, sizeof(dir), "%s\\War3DeathSettlement\\ddh", base);
    CreateDirectoryA(dir, NULL);
    DdhSprintf(out, cap, "%s\\War3DeathSettlement\\ddh\\ddh-events.db", base);
}

static int DdhDbLoad(void)
{
    /* 静态链接：sqlite3.c 已编进 ddh.dll，不再 LoadLibrary("winsqlite3.dll")。 */
    g_sqlOpen       = (pfn_sqlite3_open_v2)&sqlite3_open_v2;
    g_sqlClose      = (pfn_sqlite3_close)&sqlite3_close;
    g_sqlExec       = (pfn_sqlite3_exec)&sqlite3_exec;
    g_sqlPrepare    = (pfn_sqlite3_prepare_v2)&sqlite3_prepare_v2;
    g_sqlBindI64    = (pfn_sqlite3_bind_int64)&sqlite3_bind_int64;
    g_sqlBindDouble = (pfn_sqlite3_bind_double)&sqlite3_bind_double;
    g_sqlBindText   = (pfn_sqlite3_bind_text)&sqlite3_bind_text;
    g_sqlStep       = (pfn_sqlite3_step)&sqlite3_step;
    g_sqlReset      = (pfn_sqlite3_reset)&sqlite3_reset;
    g_sqlClear      = (pfn_sqlite3_clear_bindings)&sqlite3_clear_bindings;
    g_sqlFinalize   = (pfn_sqlite3_finalize)&sqlite3_finalize;
    g_sqlColumnInt  = (pfn_sqlite3_column_int)&sqlite3_column_int;
    g_sqlErrmsg     = (pfn_sqlite3_errmsg)&sqlite3_errmsg;
    return 1;
}

static int DdhDbOpen(void)
{
    if (g_db && g_dbStmt) return 1;
    if (!DdhDbLoad()) return 0;
    if (g_dbRetryAt && GetTickCount() < g_dbRetryAt) return 0;

    char path[MAX_PATH] = { 0 };
    DdhDbBuildPath(path, sizeof(path));

    sqlite3* db = NULL;
    if (g_sqlOpen(path, &db, 2 | 4 | 0x10000, NULL) != DDH_SQLITE_OK || !db)
    {
        if (db) g_sqlClose(db);
        g_dbRetryAt = GetTickCount() + 30000;
        if (!g_dbFailedLogged) { g_dbFailedLogged = 1; LogLine("SQLite：打开失败 %s", path); }
        return 0;
    }

    const char* schema =
        "PRAGMA journal_mode=WAL;"
        "PRAGMA synchronous=NORMAL;"
        "CREATE TABLE IF NOT EXISTS game_events("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "session_id TEXT NOT NULL,"
        "seq INTEGER NOT NULL,"
        "wall_ms INTEGER NOT NULL,"
        "tick_ms INTEGER NOT NULL,"
        "victim INTEGER NOT NULL,"
        "victim_code TEXT NOT NULL,"
        "victim_name TEXT NOT NULL,"
        "victim_owner INTEGER NOT NULL,"
        "source INTEGER NOT NULL,"
        "source_code TEXT NOT NULL,"
        "source_name TEXT NOT NULL,"
        "source_owner INTEGER NOT NULL,"
        "amount REAL NOT NULL,"
        "engine REAL NOT NULL,"
        "final REAL NOT NULL,"
        "actual REAL NOT NULL,"
        "hp_before REAL NOT NULL,"
        "hp_after REAL NOT NULL,"
        "hp_valid INTEGER NOT NULL,"
        "attack_type INTEGER NOT NULL,"
        "damage_mask INTEGER NOT NULL,"
        "is_physical INTEGER NOT NULL,"
        "flag INTEGER NOT NULL,"
        "depth INTEGER NOT NULL,"
        "final_flags INTEGER NOT NULL,"
        "unit_flags INTEGER NOT NULL,"
        "UNIQUE(session_id,seq)"
        ");"
        "CREATE INDEX IF NOT EXISTS idx_game_events_victim ON game_events(victim);"
        "CREATE TABLE IF NOT EXISTS game_settlements("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "session_id TEXT NOT NULL,"
        "seq INTEGER NOT NULL,"
        "wall_ms INTEGER NOT NULL,"
        "victim INTEGER NOT NULL,"
        "victim_code TEXT NOT NULL,"
        "victim_name TEXT NOT NULL,"
        "victim_owner INTEGER NOT NULL,"
        "total_damage REAL NOT NULL,"
        "hits INTEGER NOT NULL,"
        "max_hit REAL NOT NULL,"
        "fatal_source INTEGER NOT NULL,"
        "fatal_source_code TEXT NOT NULL,"
        "fatal_source_name TEXT NOT NULL,"
        "fatal_damage REAL NOT NULL,"
        "first_tick INTEGER NOT NULL,"
        "last_tick INTEGER NOT NULL"
        ",UNIQUE(session_id,seq)"
        ");"
        "CREATE INDEX IF NOT EXISTS idx_game_settlements_session_wall "
        "ON game_settlements(session_id,wall_ms DESC,seq DESC);"
        "CREATE TABLE IF NOT EXISTS game_units("
        "session_id TEXT NOT NULL,"
        "addr INTEGER NOT NULL,"
        "type_code TEXT NOT NULL,"
        "name TEXT NOT NULL,"
        "title TEXT NOT NULL,"
        "owner_slot INTEGER NOT NULL,"
        "attack_range REAL NOT NULL,"
        "damage_min REAL NOT NULL,"
        "damage_max REAL NOT NULL,"
        "attack_interval REAL NOT NULL,"
        "armor REAL NOT NULL,"
        "move_speed REAL NOT NULL,"
        "sight_day REAL NOT NULL,"
        "sight_night REAL NOT NULL,"
        "acquire_range REAL NOT NULL,"
        "strength REAL NOT NULL,"
        "agility REAL NOT NULL,"
        "intelligence REAL NOT NULL,"
        "hero INTEGER NOT NULL,"
        "illusion INTEGER NOT NULL,"
        "dead INTEGER NOT NULL,"
        "locust INTEGER NOT NULL,"
        "attack_speed REAL NOT NULL,"
        "PRIMARY KEY(session_id,addr)"
        ");"
        /* 同会话、同类型、同镜像状态只保留最近写入的一个实例。 */
        "DELETE FROM game_units WHERE rowid NOT IN ("
        "SELECT MAX(rowid) FROM game_units "
        "GROUP BY session_id, type_code COLLATE NOCASE, illusion"
        ");"
        "CREATE UNIQUE INDEX IF NOT EXISTS idx_game_units_identity "
        "ON game_units(session_id, type_code COLLATE NOCASE, illusion);"
        "CREATE TABLE IF NOT EXISTS game_sessions("
        "session_id TEXT PRIMARY KEY,"
        "ctx INTEGER NOT NULL,"
        "game_state INTEGER NOT NULL,"
        "map_name TEXT NOT NULL,"
        "started_ms INTEGER NOT NULL,"
        "updated_ms INTEGER NOT NULL"
        ");"
        "PRAGMA user_version=7;";

    char* err = NULL;
    g_sqlExec(db, schema, NULL, NULL, &err);
    if (err) { g_sqlExec(db, "ROLLBACK;", NULL, NULL, NULL); }

    /* 清掉旧版本产生的空会话：只有实际事件/单位/结算才进入历史列表。 */
    g_sqlExec(db,
        "DELETE FROM game_sessions WHERE session_id NOT IN ("
        "SELECT session_id FROM game_events "
        "UNION SELECT session_id FROM game_units "
        "UNION SELECT session_id FROM game_settlements);",
        NULL, NULL, NULL);

    const char* sql =
        "INSERT OR REPLACE INTO game_events("
        "seq,wall_ms,tick_ms,victim,victim_code,victim_name,victim_owner,"
        "source,source_code,source_name,source_owner,"
        "amount,engine,final,actual,hp_before,hp_after,hp_valid,"
        "attack_type,damage_mask,is_physical,flag,depth,final_flags,unit_flags,session_id"
        ") VALUES(?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16,?17,?18,?19,?20,?21,?22,?23,?24,?25,?26);";

    sqlite3_stmt* st = NULL;
    if (g_sqlPrepare(db, sql, -1, &st, NULL) != DDH_SQLITE_OK || !st)
    {
        g_sqlClose(db);
        g_dbRetryAt = GetTickCount() + 30000;
        if (!g_dbFailedLogged) { g_dbFailedLogged = 1; LogLine("SQLite：建表/预编译失败，伤害明细不落库"); }
        return 0;
    }

    g_db = db;
    g_dbStmt = st;
    const char* settleSql =
        "INSERT OR REPLACE INTO game_settlements("
        "seq,wall_ms,victim,victim_code,victim_name,victim_owner,"
        "total_damage,hits,max_hit,fatal_source,fatal_source_code,fatal_source_name,"
        "fatal_damage,first_tick,last_tick,session_id"
        ") VALUES(?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16);";
    sqlite3_stmt* settleStmt = NULL;
    if (g_sqlPrepare(db, settleSql, -1, &settleStmt, NULL) == DDH_SQLITE_OK)
        g_dbSettleStmt = settleStmt;
    const char* unitSql =
        "INSERT OR REPLACE INTO game_units("
        "session_id,addr,type_code,name,title,owner_slot,attack_range,damage_min,damage_max,"
        "attack_interval,armor,move_speed,sight_day,sight_night,acquire_range,"
        "strength,agility,intelligence,hero,illusion,dead,locust,attack_speed"
        ") VALUES(?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16,?17,?18,?19,?20,?21,?22,?23);";
    sqlite3_stmt* unitStmt = NULL;
    if (g_sqlPrepare(db, unitSql, -1, &unitStmt, NULL) == DDH_SQLITE_OK)
        g_dbUnitStmt = unitStmt;
    sqlite3_stmt* sessionStmt = NULL;
    if (g_sqlPrepare(db,
            "INSERT INTO game_sessions(session_id,ctx,game_state,map_name,started_ms,updated_ms) "
            "VALUES(?1,?2,?3,?4,?5,?6) "
            "ON CONFLICT(session_id) DO UPDATE SET ctx=excluded.ctx,game_state=excluded.game_state,"
            "map_name=excluded.map_name,updated_ms=excluded.updated_ms;",
            -1, &sessionStmt, NULL) == DDH_SQLITE_OK)
        g_dbSessionStmt = sessionStmt;
    g_dbReady = 1;
    LogLine("SQLite：伤害明细库已打开 %s", path);
    return 1;
}

static uint32_t g_dbRingSeq = 0;

static DdhDbSettleRegistry g_dbSettle;
static char          g_dbSettleSession[24] = { 0 };

static DdhDbSettleAcc* DdhDbSettleGet(uint32_t victim, uint32_t code, int32_t owner, const char* name)
{
    DdhDbSessionKey session = DdhDbCurrentSession();
    if (strcmp(g_dbSettleSession, session.id) != 0)
    {
        g_dbSettle.Clear();
        strncpy_s(g_dbSettleSession, sizeof(g_dbSettleSession), session.id, _TRUNCATE);
    }
    return g_dbSettle.Ensure(victim, code, owner, name);
}

static void DdhDbSettleInsert(DdhDbSettleAcc* a, uint32_t seq, uint64_t wallMs)
{
    if (!a || !g_dbSettleStmt) return;
    char vcode[8] = { 0 }, scode[8] = { 0 };
    strncpy_s(vcode, sizeof(vcode), DdhCodeText(a->code), _TRUNCATE);
    strncpy_s(scode, sizeof(scode), DdhCodeText(a->fatalCode), _TRUNCATE);
    g_sqlReset(g_dbSettleStmt);
    g_sqlClear(g_dbSettleStmt);
    g_sqlBindI64(g_dbSettleStmt, 1, (long long)seq);
    g_sqlBindI64(g_dbSettleStmt, 2, (long long)wallMs);
    g_sqlBindI64(g_dbSettleStmt, 3, (long long)a->victim);
    g_sqlBindText(g_dbSettleStmt, 4, vcode, -1, DDH_SQLITE_TRANSIENT);
    g_sqlBindText(g_dbSettleStmt, 5, a->name, -1, DDH_SQLITE_TRANSIENT);
    g_sqlBindI64(g_dbSettleStmt, 6, (long long)a->owner);
    g_sqlBindDouble(g_dbSettleStmt, 7, a->total);
    g_sqlBindI64(g_dbSettleStmt, 8, (long long)a->hits);
    g_sqlBindDouble(g_dbSettleStmt, 9, a->maxHit);
    g_sqlBindI64(g_dbSettleStmt, 10, (long long)a->fatalSource);
    g_sqlBindText(g_dbSettleStmt, 11, scode, -1, DDH_SQLITE_TRANSIENT);
    g_sqlBindText(g_dbSettleStmt, 12, a->fatalName, -1, DDH_SQLITE_TRANSIENT);
    g_sqlBindDouble(g_dbSettleStmt, 13, a->fatalDmg);
    g_sqlBindI64(g_dbSettleStmt, 14, (long long)a->firstTick);
    g_sqlBindI64(g_dbSettleStmt, 15, (long long)a->lastTick);
    DdhDbSessionKey session = DdhDbCurrentSession();
    g_sqlBindText(g_dbSettleStmt, 16, session.id, -1, DDH_SQLITE_TRANSIENT);
    g_sqlStep(g_dbSettleStmt);
}

static void DdhDbFlushRing(void)
{
    if (!g_shm || g_dbDisabled) return;
    if (!DdhDbOpen()) return;

    uint32_t cap = g_shm->hdr.capacity;
    if (!cap || cap > DDH_MAX_EVENTS) cap = DDH_MAX_EVENTS;
    const uint32_t total = g_shm->hdr.count;
    if (total < g_dbRingSeq) g_dbRingSeq = 0;
    uint32_t start = g_dbRingSeq + 1;
    if (total >= start && (total - start + 1) > cap)
        start = total - cap + 1;
    if (start > total) return;

    if (g_sqlExec(g_db, "BEGIN IMMEDIATE;", NULL, NULL, NULL) != DDH_SQLITE_OK)
        return;

    int ok = 1;
    char activitySession[24] = { 0 };
    for (uint32_t seq = start; seq <= total && ok; seq++)
    {
        const DdhEvent* e = &g_shm->ev[(seq - 1) % cap];
        if (e->seq != seq) { g_dbRingSeq = seq; continue; }
        /* 出口字段还没补完（ready=0）就不写，也不推进 seq。 */
        if (!g_evReady[(seq - 1) % cap]) break;

        DdhDbRow r;
        memset(&r, 0, sizeof(r));
        r.seq = e->seq;
        r.tickMs = e->tickMs;
        {
            FILETIME ft;
            GetSystemTimeAsFileTime(&ft);
            ULARGE_INTEGER u;
            u.LowPart = ft.dwLowDateTime;
            u.HighPart = ft.dwHighDateTime;
            uint64_t wallNow = u.QuadPart / 10000ULL - 11644473600000ULL;
            /* 用事件自己的 tick 回推发生时间；不能用写库时刻，否则一批事件会挤在同一毫秒。 */
            r.wallMs = (int64_t)wallNow - (int64_t)(uint32_t)(GetTickCount() - e->tickMs);
        }
        r.victim = e->victim;
        r.victimCode = e->victimCode;
        r.source = e->source;
        r.sourceCode = e->sourceCode;
        r.victimOwner = e->victimOwner;
        r.sourceOwner = e->sourceOwner;
        r.amount = e->amount;
        r.engineDamage = e->engineDamage;
        r.finalDamage = e->finalDamage;
        r.actual = e->actual;
        r.hpBefore = e->hpBefore;
        r.hpAfter = e->hpAfter;
        r.hpValid = e->hpValid;
        r.attackType = e->attackType;
        r.damageMask = e->damageMask;
        r.isPhysical = e->isPhysical;
        r.flag = e->flag;
        r.depth = e->depth;
        r.finalFlags = e->finalFlags;
        strncpy_s(r.victimName, sizeof(r.victimName), e->victimName, _TRUNCATE);
        strncpy_s(r.sourceName, sizeof(r.sourceName), e->sourceName, _TRUNCATE);
        DdhDbSessionKey session = DdhDbCurrentSession();
        strncpy_s(r.sessionId, sizeof(r.sessionId), session.id, _TRUNCATE);

        char vcode[8] = { 0 }, scode[8] = { 0 };
        strncpy_s(vcode, sizeof(vcode), DdhCodeText(r.victimCode), _TRUNCATE);
        strncpy_s(scode, sizeof(scode), DdhCodeText(r.sourceCode), _TRUNCATE);

        g_sqlReset(g_dbStmt);
        g_sqlClear(g_dbStmt);
        g_sqlBindI64(g_dbStmt, 1, (long long)r.seq);
        g_sqlBindI64(g_dbStmt, 2, (long long)r.wallMs);
        g_sqlBindI64(g_dbStmt, 3, (long long)r.tickMs);
        g_sqlBindI64(g_dbStmt, 4, (long long)r.victim);
        g_sqlBindText(g_dbStmt, 5, vcode, -1, DDH_SQLITE_TRANSIENT);
        g_sqlBindText(g_dbStmt, 6, r.victimName, -1, DDH_SQLITE_TRANSIENT);
        g_sqlBindI64(g_dbStmt, 7, (long long)r.victimOwner);
        g_sqlBindI64(g_dbStmt, 8, (long long)r.source);
        g_sqlBindText(g_dbStmt, 9, scode, -1, DDH_SQLITE_TRANSIENT);
        g_sqlBindText(g_dbStmt, 10, r.sourceName, -1, DDH_SQLITE_TRANSIENT);
        g_sqlBindI64(g_dbStmt, 11, (long long)r.sourceOwner);
        g_sqlBindDouble(g_dbStmt, 12, (double)r.amount);
        g_sqlBindDouble(g_dbStmt, 13, (double)r.engineDamage);
        g_sqlBindDouble(g_dbStmt, 14, (double)r.finalDamage);
        g_sqlBindDouble(g_dbStmt, 15, (double)r.actual);
        g_sqlBindDouble(g_dbStmt, 16, (double)r.hpBefore);
        g_sqlBindDouble(g_dbStmt, 17, (double)r.hpAfter);
        g_sqlBindI64(g_dbStmt, 18, (long long)r.hpValid);
        g_sqlBindI64(g_dbStmt, 19, (long long)r.attackType);
        g_sqlBindI64(g_dbStmt, 20, (long long)r.damageMask);
        g_sqlBindI64(g_dbStmt, 21, (long long)r.isPhysical);
        g_sqlBindI64(g_dbStmt, 22, (long long)r.flag);
        g_sqlBindI64(g_dbStmt, 23, (long long)r.depth);
        g_sqlBindI64(g_dbStmt, 24, (long long)r.finalFlags);
        g_sqlBindI64(g_dbStmt, 25, (long long)e->flags);
        g_sqlBindText(g_dbStmt, 26, r.sessionId, -1, DDH_SQLITE_TRANSIENT);

        if (g_sqlStep(g_dbStmt) != DDH_SQLITE_DONE) ok = 0;
        else strncpy_s(activitySession, sizeof(activitySession), r.sessionId, _TRUNCATE);

        if (ok && e->hpValid && e->victim)
        {
            DdhDbSettleAcc* a = DdhDbSettleGet(e->victim, e->victimCode, e->victimOwner, e->victimName);
            if (a)
            {
                if (e->actual > 0.005)
                {
                    a->total += (double)e->actual;
                    a->hits++;
                    if ((double)e->actual > a->maxHit) a->maxHit = (double)e->actual;
                    if (a->firstTick == 0) a->firstTick = e->tickMs;
                    a->lastTick = e->tickMs;
                }
                if (e->hpBefore > 0.0f && e->hpAfter <= 0.0f)
                {
                    a->fatalSource = e->source;
                    a->fatalCode = e->sourceCode;
                    a->fatalDmg = (double)e->actual;
                    strncpy_s(a->fatalName, sizeof(a->fatalName), e->sourceName, _TRUNCATE);
                    DdhDbSettleInsert(a, e->seq, r.wallMs);
                    g_dbSettle.Remove(a->victim);
                }
            }
        }
        g_dbRingSeq = seq;
    }

    if (ok) {
        g_sqlExec(g_db, "COMMIT;", NULL, NULL, NULL);
        DdhDbMarkSessionActive(activitySession);
    }
    else    g_sqlExec(g_db, "ROLLBACK;", NULL, NULL, NULL);
    MemoryBarrier();
}

#define DDH_DB_EVENT_UNIT_CAP 2048

struct DdhDbEventUnit
{
    char     sessionId[24];
    uint32_t code;
    uint32_t addr;
    uint32_t version;
    int32_t  owner;
    bool     illusion;
    bool     hero;
    bool     locust;
    bool     dirty;
    uint32_t combatFlags;
    float    attackRange;
    float    damageMin;
    float    damageMax;
    float    armor;
    float    attackInterval;
    float    attackSpeed;
    char     typeCode[5];
    char     name[64];
    char     title[64];
};

static DdhDbEventUnit g_dbEventUnits[DDH_DB_EVENT_UNIT_CAP];
static uint32_t       g_dbEventUnitCount = 0;
static char           g_dbEventUnitSession[24] = { 0 };
static volatile LONG  g_dbEventUnitErrLogCount = 0;
static SRWLOCK        g_dbEventUnitLock = SRWLOCK_INIT;

static void DdhDbResetEventUnitCache(const char* sessionId)
{
    memset(g_dbEventUnits, 0, sizeof(g_dbEventUnits));
    g_dbEventUnitCount = 0;
    strncpy_s(g_dbEventUnitSession, sizeof(g_dbEventUnitSession),
              sessionId ? sessionId : "", _TRUNCATE);
}

static DdhDbEventUnit* DdhDbFindEventUnit(uint32_t code, bool illusion)
{
    for (uint32_t i = 0; i < g_dbEventUnitCount; ++i)
    {
        DdhDbEventUnit* u = &g_dbEventUnits[i];
        if (u->code == code && u->illusion == illusion) return u;
    }
    if (g_dbEventUnitCount >= DDH_DB_EVENT_UNIT_CAP)
    {
        if (InterlockedIncrement(&g_dbEventUnitErrLogCount) <= 32)
            LogLine("事件单位缓存已满：code=0x%08X mirror=%d", code, illusion ? 1 : 0);
        return NULL;
    }

    DdhDbEventUnit* u = &g_dbEventUnits[g_dbEventUnitCount++];
    memset(u, 0, sizeof(*u));
    strncpy_s(u->sessionId, sizeof(u->sessionId), g_dbEventUnitSession, _TRUNCATE);
    u->code = code;
    u->illusion = illusion;
    u->owner = -1;
    return u;
}

static void DdhDbMergeEventUnit(const char* sessionId, const DdhEvent* e, bool source)
{
    uint32_t addr = source ? e->source : e->victim;
    uint32_t code = source ? e->sourceCode : e->victimCode;
    if (!addr || !code) return;

    if (strcmp(g_dbEventUnitSession, sessionId) != 0)
        DdhDbResetEventUnitCache(sessionId);

    const bool illusion = source
        ? (e->flags & DDH_EVENT_FLAG_SOURCE_ILLUSION) != 0
        : (e->flags & DDH_EVENT_FLAG_VICTIM_ILLUSION) != 0;
    DdhDbEventUnit* u = DdhDbFindEventUnit(code, illusion);
    if (!u) return;

    u->addr = addr;
    u->owner = source ? e->sourceOwner : e->victimOwner;
    u->hero |= source
        ? (e->flags & DDH_EVENT_FLAG_SOURCE_HERO) != 0
        : (e->flags & DDH_EVENT_FLAG_VICTIM_HERO) != 0;
    u->locust |= source
        ? (e->flags & DDH_EVENT_FLAG_SOURCE_LOCUST) != 0
        : (e->flags & 1u) != 0;

    const DdhUnitCombatSnapshot* combat = source ? &e->sourceCombat : &e->victimCombat;
    u->combatFlags |= combat->flags;
    if (combat->flags & DDH_COMBAT_RANGE)        u->attackRange = combat->attackRange;
    if (combat->flags & DDH_COMBAT_DAMAGE)
    {
        u->damageMin = combat->damageMin;
        u->damageMax = combat->damageMax;
    }
    if (combat->flags & DDH_COMBAT_ARMOR)        u->armor = combat->armor;
    if (combat->flags & DDH_COMBAT_INTERVAL)     u->attackInterval = combat->attackInterval;
    if (combat->flags & DDH_COMBAT_ATTACK_SPEED) u->attackSpeed = combat->attackSpeed;

    char typeCode[5] = { 0 };
    for (int i = 0; i < 4; ++i)
    {
        char c = (char)((code >> ((3 - i) * 8)) & 0xFFu);
        typeCode[i] = (c >= 0x20 && c <= 0x7E) ? c : '?';
    }
    DdhUtf8SafeCopy(u->typeCode, sizeof(u->typeCode), typeCode, sizeof(u->typeCode) - 1);

    const char* name = source ? e->sourceName : e->victimName;
    if (name && name[0])
        DdhUtf8SafeCopy(u->name, sizeof(u->name), name, sizeof(u->name) - 1);

    char title[64] = { 0 };
    if (DdhCachedTitleByCode(code, title, sizeof(title)) && title[0])
        DdhUtf8SafeCopy(u->title, sizeof(u->title), title, sizeof(u->title) - 1);

    ++u->version;
    u->dirty = true;
}

static void DdhDbUpdateEventUnits(const DdhEvent* e)
{
    if (!e) return;
    DdhDbSessionKey session = DdhDbCurrentSession();
    if (!session.id[0]) return;

    AcquireSRWLockExclusive(&g_dbEventUnitLock);
    DdhDbMergeEventUnit(session.id, e, false);
    DdhDbMergeEventUnit(session.id, e, true);
    ReleaseSRWLockExclusive(&g_dbEventUnitLock);
}

struct DdhDbEventUnitBatchEntry
{
    uint32_t index;
    uint32_t version;
    DdhDbEventUnit unit;
};

static void DdhDbWriteEventUnits(void)
{
    if (!g_dbUnitStmt) return;

    DdhDbEventUnitBatchEntry batch[64];
    uint32_t n = 0;
    AcquireSRWLockExclusive(&g_dbEventUnitLock);
    for (uint32_t i = 0; i < g_dbEventUnitCount && n < 64; ++i)
    {
        if (!g_dbEventUnits[i].dirty) continue;
        DdhDbEventUnitBatchEntry* b = &batch[n++];
        b->index = i;
        b->version = g_dbEventUnits[i].version;
        b->unit = g_dbEventUnits[i];
    }
    ReleaseSRWLockExclusive(&g_dbEventUnitLock);
    if (!n) return;

    int beginRc = g_sqlExec(g_db, "BEGIN IMMEDIATE;", NULL, NULL, NULL);
    if (beginRc != DDH_SQLITE_OK)
    {
        if (InterlockedIncrement(&g_dbEventUnitErrLogCount) <= 32)
            LogLine("事件单位写库 BEGIN 失败：rc=%d err=%s",
                    beginRc, g_sqlErrmsg ? g_sqlErrmsg(g_db) : "?");
        return;
    }

    int ok = 1;
    char activitySession[24] = { 0 };
    for (uint32_t i = 0; i < n; ++i)
    {
        const DdhDbEventUnit* u = &batch[i].unit;
        g_sqlReset(g_dbUnitStmt);
        g_sqlClear(g_dbUnitStmt);
        g_sqlBindText(g_dbUnitStmt, 1, u->sessionId, -1, DDH_SQLITE_TRANSIENT);
        g_sqlBindI64(g_dbUnitStmt, 2, (long long)u->addr);
        g_sqlBindText(g_dbUnitStmt, 3, u->typeCode, -1, DDH_SQLITE_TRANSIENT);
        g_sqlBindText(g_dbUnitStmt, 4, u->name, -1, DDH_SQLITE_TRANSIENT);
        g_sqlBindText(g_dbUnitStmt, 5, u->title, -1, DDH_SQLITE_TRANSIENT);
        g_sqlBindI64(g_dbUnitStmt, 6, (long long)u->owner);
        g_sqlBindDouble(g_dbUnitStmt, 7, u->attackRange);
        g_sqlBindDouble(g_dbUnitStmt, 8, u->damageMin);
        g_sqlBindDouble(g_dbUnitStmt, 9, u->damageMax);
        g_sqlBindDouble(g_dbUnitStmt, 10, u->attackInterval);
        g_sqlBindDouble(g_dbUnitStmt, 11, u->armor);
        g_sqlBindDouble(g_dbUnitStmt, 12, 0.0);  /* CUnit property scan removed */
        g_sqlBindDouble(g_dbUnitStmt, 13, 0.0);  /* sightDay */
        g_sqlBindDouble(g_dbUnitStmt, 14, 0.0);  /* sightNight */
        g_sqlBindDouble(g_dbUnitStmt, 15, 0.0);  /* acquireRange */
        g_sqlBindDouble(g_dbUnitStmt, 16, 0.0);  /* strength */
        g_sqlBindDouble(g_dbUnitStmt, 17, 0.0);  /* agility */
        g_sqlBindDouble(g_dbUnitStmt, 18, 0.0);  /* intelligence */
        g_sqlBindI64(g_dbUnitStmt, 19, u->hero ? 1 : 0);
        g_sqlBindI64(g_dbUnitStmt, 20, u->illusion ? 1 : 0);
        g_sqlBindI64(g_dbUnitStmt, 21, 0);
        g_sqlBindI64(g_dbUnitStmt, 22, u->locust ? 1 : 0);
        g_sqlBindDouble(g_dbUnitStmt, 23, u->attackSpeed);
        if (g_sqlStep(g_dbUnitStmt) != DDH_SQLITE_DONE)
        {
            ok = 0;
            if (InterlockedIncrement(&g_dbEventUnitErrLogCount) <= 32)
                LogLine("事件单位写库失败：addr=0x%08X code=%s name=\"%s\" err=%s",
                        u->addr, u->typeCode, u->name,
                        g_sqlErrmsg ? g_sqlErrmsg(g_db) : "?");
            break;
        }
        strncpy_s(activitySession, sizeof(activitySession), u->sessionId, _TRUNCATE);
    }

    if (ok)
    {
        if (g_sqlExec(g_db, "COMMIT;", NULL, NULL, NULL) != DDH_SQLITE_OK)
        {
            ok = 0;
            g_sqlExec(g_db, "ROLLBACK;", NULL, NULL, NULL);
        }
    }
    else
    {
        g_sqlExec(g_db, "ROLLBACK;", NULL, NULL, NULL);
    }

    if (ok)
    {
        AcquireSRWLockExclusive(&g_dbEventUnitLock);
        for (uint32_t i = 0; i < n; ++i)
        {
            uint32_t index = batch[i].index;
            if (index >= g_dbEventUnitCount) continue;
            DdhDbEventUnit* current = &g_dbEventUnits[index];
            if (current->code == batch[i].unit.code &&
                current->illusion == batch[i].unit.illusion &&
                strcmp(current->sessionId, batch[i].unit.sessionId) == 0 &&
                current->version == batch[i].version)
            {
                current->dirty = false;
            }
        }
        ReleaseSRWLockExclusive(&g_dbEventUnitLock);
        DdhDbMarkSessionActive(activitySession);
    }
}

/* 明细库只保留最近 DDH_DB_MAX_SESSIONS 个游戏状态会话。 */
static void DdhDbPruneOldSessions(void)
{
    char sql[1024] = { 0 };
    DdhSprintf(sql, sizeof(sql),
        "DELETE FROM game_events WHERE session_id NOT IN "
        "(SELECT session_id FROM game_sessions ORDER BY updated_ms DESC LIMIT %d);"
        "DELETE FROM game_settlements WHERE session_id NOT IN "
        "(SELECT session_id FROM game_sessions ORDER BY updated_ms DESC LIMIT %d);"
        "DELETE FROM game_units WHERE session_id NOT IN "
        "(SELECT session_id FROM game_sessions ORDER BY updated_ms DESC LIMIT %d);"
        "DELETE FROM game_sessions WHERE session_id NOT IN "
        "(SELECT session_id FROM game_sessions ORDER BY updated_ms DESC LIMIT %d);",
        DDH_DB_MAX_SESSIONS, DDH_DB_MAX_SESSIONS, DDH_DB_MAX_SESSIONS, DDH_DB_MAX_SESSIONS);
    g_sqlExec(g_db, sql, NULL, NULL, NULL);
}

static void DdhDbWriteSession(void)
{
    if (!g_dbSessionStmt || !g_dbActiveSession[0]) return;

    static DWORD lastTry = 0;
    static char lastSession[24] = { 0 };
    const DWORD now = GetTickCount();
    const int newSession = strcmp(lastSession, g_dbActiveSession) != 0;
    if (!newSession && lastTry && (now - lastTry) < 5000) return;

    char sessionId[24] = { 0 };
    strncpy_s(sessionId, sizeof(sessionId), g_dbActiveSession, _TRUNCATE);

    uint32_t ctx = 0, game = 0;
    sscanf_s(sessionId, "%08X-%08X", &ctx, &game);

    char name[128] = { 0 };
    DdhDbSessionKey current = DdhDbCurrentSession();
    if (strcmp(current.id, sessionId) == 0 && !DdhReadMapName(name, sizeof(name)))
        name[0] = 0;

    g_sqlReset(g_dbSessionStmt);
    g_sqlClear(g_dbSessionStmt);
    /* updated_ms 必须是 Unix 毫秒（不是 GetTickCount）：换进程/重启后才能按时间排序并删最旧。 */
    FILETIME ft;
    GetSystemTimeAsFileTime(&ft);
    ULARGE_INTEGER u;
    u.LowPart = ft.dwLowDateTime;
    u.HighPart = ft.dwHighDateTime;
    uint64_t wallMs = u.QuadPart / 10000ULL - 11644473600000ULL;
    g_sqlBindText(g_dbSessionStmt, 1, sessionId, -1, DDH_SQLITE_TRANSIENT);
    g_sqlBindI64(g_dbSessionStmt, 2, (long long)ctx);
    g_sqlBindI64(g_dbSessionStmt, 3, (long long)game);
    g_sqlBindText(g_dbSessionStmt, 4, name, -1, DDH_SQLITE_TRANSIENT);
    g_sqlBindI64(g_dbSessionStmt, 5, (long long)wallMs);
    g_sqlBindI64(g_dbSessionStmt, 6, (long long)wallMs);
    if (g_sqlStep(g_dbSessionStmt) != DDH_SQLITE_DONE) return;

    lastTry = now;
    strncpy_s(lastSession, sizeof(lastSession), sessionId, _TRUNCATE);
    g_dbActiveSession[0] = 0;

    /* 每个新 session 写入后清理一次；同一进程连续换图也能执行保留策略。 */
    static char prunedSession[24] = { 0 };
    if (strcmp(prunedSession, sessionId) != 0)
    {
        strncpy_s(prunedSession, sizeof(prunedSession), sessionId, _TRUNCATE);
        DdhDbPruneOldSessions();
    }
}

static DWORD WINAPI DdhDbThreadProc(LPVOID)
{
    for (;;)
    {
        Sleep(250);
        __try { DdhDbFlushRing(); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        __try { DdhDbWriteEventUnits(); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        __try { DdhDbWriteSession(); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
    }
    return 0;
}

static void DdhDbStart(void)
{
    if (!DdhDbEnabled()) return;
    if (InterlockedCompareExchange(&g_dbThreadStarted, 1, 0) != 0) return;
    CreateThread(NULL, 0, DdhDbThreadProc, NULL, 0, NULL);
}
