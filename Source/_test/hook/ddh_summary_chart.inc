/* In-game native damage summary chart.
   This module is called only from DDH_WM_DAMAGE_DEFERRED, after the damage hook
   has returned. It creates local CTextFrame/CBackdropFrame objects only. */

#define DDH_SUMMARY_CHART_SECONDS 10
#define DDH_SUMMARY_CHART_TYPES   4
#define DDH_SUMMARY_CHART_MAX_SRC 8
#define DDH_SUMMARY_CHART_MAX_SEG 16
#define DDH_SUMMARY_CHART_BAR_MAX 104
#define DDH_SUMMARY_CHART_TEXT_MAX 64
#define DDH_SUMMARY_CHART_TIMER 0xDDF1u
#define DDH_UI_LAYOUT_SUB 0xB4u

typedef uint32_t (__fastcall *fn_ddh_summary_getgame_t)(uint32_t, uint32_t);
typedef uint32_t (__fastcall *fn_ddh_summary_create_text_t)(uint32_t, uint32_t, uint32_t);
typedef uint32_t (__fastcall *fn_ddh_summary_create_backdrop_t)(uint32_t, uint32_t, uint32_t);
typedef void (__fastcall *fn_ddh_summary_set_font_t)(void*, void*, const char*, float, uint32_t);
typedef void (__fastcall *fn_ddh_summary_set_fontflags_t)(void*, void*, uint32_t);
typedef void (__fastcall *fn_ddh_summary_set_text_t)(void*, void*, const char*);
typedef void (__fastcall *fn_ddh_summary_set_color_t)(void*, void*, const uint32_t*);
typedef void (__fastcall *fn_ddh_summary_setpoint_t)(void*, void*, uint32_t, uint32_t, uint32_t, float, float, uint32_t);
typedef void (__fastcall *fn_ddh_summary_setbackdrop_t)(void*, void*, const char*, uint32_t, uint32_t, const char*, uint32_t);

static uint32_t g_ddhSummaryGetGame = 0;
static uint32_t g_ddhSummaryCreateText = 0;
static uint32_t g_ddhSummaryCreateBackdrop = 0;
static uint32_t g_ddhSummarySetFont = 0;
static uint32_t g_ddhSummarySetFontFlags = 0;
static uint32_t g_ddhSummarySetText = 0;
static uint32_t g_ddhSummarySetColor = 0;
static uint32_t g_ddhSummarySetPoint = 0;
static uint32_t g_ddhSummarySetBackdrop = 0;
static volatile LONG g_ddhSummaryUiInit = 0;

struct DdhSummaryChartSeg
{
    uint8_t type;
    uint8_t src;
    uint16_t pad;
    float amount;
};

struct DdhSummaryChartSrc
{
    uint32_t addr;
    uint32_t code;
    float total;
    char label[64];
};

static struct
{
    int valid;
    uint32_t victim;
    uint32_t victimCode;
    uint32_t endTick;
    uint32_t endGameSec;
    int gameClockValid;
    uint32_t fatalSource;
    uint32_t fatalCode;
    char fatalName[64];
    float total[DDH_SUMMARY_CHART_SECONDS];
    float maxTotal;
    int sourceCount;
    DdhSummaryChartSrc source[DDH_SUMMARY_CHART_MAX_SRC];
    int segCount[DDH_SUMMARY_CHART_SECONDS];
    DdhSummaryChartSeg seg[DDH_SUMMARY_CHART_SECONDS][DDH_SUMMARY_CHART_MAX_SEG];
} g_ddhSummaryChart;

static uint32_t g_ddhSummaryUi = 0;
static uint32_t g_ddhSummaryBg = 0;
static uint32_t g_ddhSummaryBars[DDH_SUMMARY_CHART_BAR_MAX];
static char g_ddhSummaryBarTex[DDH_SUMMARY_CHART_BAR_MAX][64];
static uint32_t g_ddhSummaryTexts[DDH_SUMMARY_CHART_TEXT_MAX];
static uint32_t g_ddhSummaryIcons[12];
static char g_ddhSummaryIconTex[12][DDH_UNIT_ICON_CAP];
static float g_ddhSummaryWantX = 0.60f;
static float g_ddhSummaryWantY = -0.10f;
static float g_ddhSummaryX = 0.455f;
static float g_ddhSummaryY = -0.10f;
static float g_ddhSummaryW = 0.34f;
static float g_ddhSummaryH = 0.32f;
static float g_ddhSummaryFont = 0.0135f;
static volatile LONG g_ddhSummaryCollapsed = 1;
static volatile LONG g_ddhSummaryShown = 0;
static volatile LONG g_ddhSummaryHideAt = 0;
static volatile LONG g_ddhSummaryLogCount = 0;

static int DdhSummaryEntryOk(uint32_t fn)
{
    if (fn < 0x10000u) return 0;
    uint8_t b[4] = { 0 };
    __try { for (int i = 0; i < 4; ++i) b[i] = *(const uint8_t*)(uintptr_t)(fn + (uint32_t)i); }
    __except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
    return (b[0] == 0x55 && b[1] == 0x8B && b[2] == 0xEC) ||
           (b[0] == 0x83 && b[1] == 0xE9) ||
           (b[0] == 0x6A && b[1] == 0xFF) ||
           b[0] == 0xE9;
}

static bool DdhSummaryInitUi(void)
{
    if (InterlockedCompareExchange(&g_ddhSummaryUiInit, 1, 0) != 0)
        return g_ddhSummaryGetGame != 0;
    if (!g_modBase) return false;

    g_ddhSummaryGetGame = g_modBase + 0x34F3A0u;
    g_ddhSummaryCreateText = g_modBase + 0x0A9560u;
    g_ddhSummaryCreateBackdrop = g_modBase + 0x08E700u;
    g_ddhSummarySetFont = g_modBase + 0x09CE60u;
    g_ddhSummarySetFontFlags = g_modBase + 0x0A93E0u;
    g_ddhSummarySetText = g_modBase + 0x0AA130u;
    g_ddhSummarySetColor = g_modBase + 0x0AA210u;
    g_ddhSummarySetPoint = g_modBase + 0x0BD8A0u;
    g_ddhSummarySetBackdrop = g_modBase + 0x0A62A0u;

    if (!DdhSummaryEntryOk(g_ddhSummaryGetGame) ||
        !DdhSummaryEntryOk(g_ddhSummaryCreateText) ||
        !DdhSummaryEntryOk(g_ddhSummaryCreateBackdrop) ||
        !DdhSummaryEntryOk(g_ddhSummarySetFont) ||
        !DdhSummaryEntryOk(g_ddhSummarySetFontFlags) ||
        !DdhSummaryEntryOk(g_ddhSummarySetText) ||
        !DdhSummaryEntryOk(g_ddhSummarySetColor) ||
        !DdhSummaryEntryOk(g_ddhSummarySetPoint) ||
        !DdhSummaryEntryOk(g_ddhSummarySetBackdrop))
    {
        LogLine("阵亡总结：game.dll UI 入口不匹配，改用文本兜底");
        return false;
    }
    return true;
}

static uint32_t DdhSummaryGetUi(void)
{
    if (!g_ddhSummaryGetGame) return 0;
    uint32_t ui = 0;
    __try { ui = ((fn_ddh_summary_getgame_t)(uintptr_t)g_ddhSummaryGetGame)(0, 0); }
    __except (EXCEPTION_EXECUTE_HANDLER) { ui = 0; }
    return (ui >= 0x10000u && ui <= 0x7FFFFFFFu) ? ui : 0;
}

static void DdhSummaryFrameShow(uint32_t frame, int show)
{
    if (!frame) return;
    void** vt = NULL;
    __try { vt = *(void***)(uintptr_t)frame; } __except (EXCEPTION_EXECUTE_HANDLER) { vt = NULL; }
    if (!vt) return;
    void* fn = NULL;
    __try { fn = vt[(show ? 0xD4 : 0xD0) / 4]; }
    __except (EXCEPTION_EXECUTE_HANDLER) { fn = NULL; }
    if (fn)
    {
        __try { ((void (__fastcall*)(void*, void*))fn)((void*)(uintptr_t)frame, 0); }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
    }
}

static void DdhSummaryHideFrames(void)
{
    if (g_ddhSummaryBg) DdhSummaryFrameShow(g_ddhSummaryBg, 0);
    for (int i = 0; i < DDH_SUMMARY_CHART_BAR_MAX; ++i)
        if (g_ddhSummaryBars[i]) DdhSummaryFrameShow(g_ddhSummaryBars[i], 0);
    for (int i = 0; i < DDH_SUMMARY_CHART_TEXT_MAX; ++i)
        if (g_ddhSummaryTexts[i]) DdhSummaryFrameShow(g_ddhSummaryTexts[i], 0);
    for (int i = 0; i < 12; ++i)
        if (g_ddhSummaryIcons[i]) DdhSummaryFrameShow(g_ddhSummaryIcons[i], 0);
}

static void DdhSummaryResetFrames(uint32_t ui)
{
    if (g_ddhSummaryUi == ui && g_ddhSummaryUi) return;
    g_ddhSummaryUi = ui;
    g_ddhSummaryBg = 0;
    memset(g_ddhSummaryBars, 0, sizeof(g_ddhSummaryBars));
    memset(g_ddhSummaryBarTex, 0, sizeof(g_ddhSummaryBarTex));
    memset(g_ddhSummaryTexts, 0, sizeof(g_ddhSummaryTexts));
    memset(g_ddhSummaryIcons, 0, sizeof(g_ddhSummaryIcons));
    memset(g_ddhSummaryIconTex, 0, sizeof(g_ddhSummaryIconTex));
}

static uint32_t DdhSummaryBarFrame(int slot)
{
    if (slot < 0 || slot >= DDH_SUMMARY_CHART_BAR_MAX) return 0;
    if (g_ddhSummaryBars[slot]) return g_ddhSummaryBars[slot];
    uint32_t frame = 0;
    __try
    {
        frame = ((fn_ddh_summary_create_backdrop_t)(uintptr_t)g_ddhSummaryCreateBackdrop)
            (g_ddhSummaryUi, 0, 0);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { frame = 0; }
    if (!frame) return 0;
    g_ddhSummaryBars[slot] = frame;
    g_ddhSummaryBarTex[slot][0] = 0;
    DdhSummaryFrameShow(frame, 0);
    return frame;
}

static void DdhSummarySetRect(uint32_t frame, float x0, float y0, float x1, float y1)
{
    if (!frame) return;
    const uint32_t layout = frame + DDH_UI_LAYOUT_SUB;
    const uint32_t relative = g_ddhSummaryUi + DDH_UI_LAYOUT_SUB;
    __try
    {
        ((fn_ddh_summary_setpoint_t)(uintptr_t)g_ddhSummarySetPoint)
            ((void*)(uintptr_t)layout, 0, 0u, relative, 0u, x0, y0, 1u);
        ((fn_ddh_summary_setpoint_t)(uintptr_t)g_ddhSummarySetPoint)
            ((void*)(uintptr_t)layout, 0, 8u, relative, 0u, x1, y1, 1u);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
}

static void DdhSummarySetBar(int slot, const char* texture,
                             float x0, float y0, float x1, float y1)
{
    uint32_t frame = DdhSummaryBarFrame(slot);
    if (!frame) return;
    if (_stricmp(g_ddhSummaryBarTex[slot], texture) != 0)
    {
        __try
        {
            ((fn_ddh_summary_setbackdrop_t)(uintptr_t)g_ddhSummarySetBackdrop)
                ((void*)(uintptr_t)frame, 0, texture, 0u, 0u, NULL, 1u);
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        strncpy_s(g_ddhSummaryBarTex[slot], sizeof(g_ddhSummaryBarTex[slot]), texture, _TRUNCATE);
    }
    DdhSummarySetRect(frame, x0, y0, x1, y1);
    DdhSummaryFrameShow(frame, 1);
}

static uint32_t DdhSummaryTextFrame(int slot)
{
    if (slot < 0 || slot >= DDH_SUMMARY_CHART_TEXT_MAX) return 0;
    if (g_ddhSummaryTexts[slot]) return g_ddhSummaryTexts[slot];
    uint32_t frame = 0;
    __try
    {
        frame = ((fn_ddh_summary_create_text_t)(uintptr_t)g_ddhSummaryCreateText)
            (g_ddhSummaryUi, 0, 0);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { frame = 0; }
    if (!frame) return 0;
    g_ddhSummaryTexts[slot] = frame;
    __try
    {
        uint32_t* q = (uint32_t*)(uintptr_t)frame;
        q[0x0C / 4] |= q[0x10 / 4] | 2u;
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    DdhSummaryFrameShow(frame, 0);
    return frame;
}

static void DdhSummaryText(int slot, const char* text, float x, float y,
                           float height, uint32_t color)
{
    uint32_t frame = DdhSummaryTextFrame(slot);
    if (!frame) return;
    uint32_t argb = color;
    __try { ((fn_ddh_summary_set_font_t)(uintptr_t)g_ddhSummarySetFont)
        ((void*)(uintptr_t)frame, 0, "MasterFont", height, 0u); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    __try { ((fn_ddh_summary_set_fontflags_t)(uintptr_t)g_ddhSummarySetFontFlags)
        ((void*)(uintptr_t)frame, 0, 0x3008u); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    __try { ((fn_ddh_summary_set_color_t)(uintptr_t)g_ddhSummarySetColor)
        ((void*)(uintptr_t)frame, 0, &argb); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    __try { ((fn_ddh_summary_set_text_t)(uintptr_t)g_ddhSummarySetText)
        ((void*)(uintptr_t)frame, 0, text); }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    const uint32_t layout = frame + DDH_UI_LAYOUT_SUB;
    const uint32_t relative = g_ddhSummaryUi + DDH_UI_LAYOUT_SUB;
    __try
    {
        ((fn_ddh_summary_setpoint_t)(uintptr_t)g_ddhSummarySetPoint)
            ((void*)(uintptr_t)layout, 0, 0u, relative, 0u, x, y, 1u);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { }
    DdhSummaryFrameShow(frame, 1);
}

static float DdhSummaryTextWidth(const char* text, float height)
{
    if (!text || !text[0] || !(height > 0.0f)) return 0.0f;
    float units = 0.0f;
    const size_t length = strlen(text);
    for (size_t i = 0; i < length; ++i)
    {
        const unsigned char c = (unsigned char)text[i];
        if (c < 0x80)
        {
            units += (c == ' ') ? 0.30f : 0.58f;
        }
        else if ((c & 0xE0u) == 0xC0u)
        {
            units += 0.85f;
            if (i + 1 < length) ++i;
        }
        else if ((c & 0xF0u) == 0xE0u)
        {
            units += 1.0f;
            if (i + 1 < length) ++i;
            if (i + 1 < length) ++i;
        }
        else if ((c & 0xF8u) == 0xF0u)
        {
            units += 1.0f;
            if (i + 1 < length) ++i;
            if (i + 1 < length) ++i;
            if (i + 1 < length) ++i;
        }
        else
        {
            units += 0.70f;
        }
    }
    return units * height;
}

static void DdhSummaryTextRightTo(int slot, const char* text, float rightX, float y,
                                  float height, uint32_t color)
{
    const float width = DdhSummaryTextWidth(text, height);
    DdhSummaryText(slot, text, rightX - width - 0.003f, y, height, color);
}

static uint32_t DdhSummaryIconFrame(int slot)
{
    if (slot < 0 || slot >= 12) return 0;
    if (g_ddhSummaryIcons[slot]) return g_ddhSummaryIcons[slot];
    uint32_t frame = 0;
    __try
    {
        frame = ((fn_ddh_summary_create_backdrop_t)(uintptr_t)g_ddhSummaryCreateBackdrop)
            (g_ddhSummaryUi, 0, 0);
    }
    __except (EXCEPTION_EXECUTE_HANDLER) { frame = 0; }
    if (!frame) return 0;
    g_ddhSummaryIcons[slot] = frame;
    g_ddhSummaryIconTex[slot][0] = 0;
    DdhSummaryFrameShow(frame, 0);
    return frame;
}

static void DdhSummaryIcon(int slot, uint32_t code,
                           float x, float yTop, float width, float height)
{
    char path[DDH_UNIT_ICON_CAP] = { 0 };
    if (!DdhUnitTypeIconPath(code, path, sizeof(path))) return;
    uint32_t frame = DdhSummaryIconFrame(slot);
    if (!frame) return;
    if (_stricmp(g_ddhSummaryIconTex[slot], path) != 0)
    {
        __try
        {
            ((fn_ddh_summary_setbackdrop_t)(uintptr_t)g_ddhSummarySetBackdrop)
                ((void*)(uintptr_t)frame, 0, path, 0u, 0u, NULL, 1u);
        }
        __except (EXCEPTION_EXECUTE_HANDLER) { }
        strncpy_s(g_ddhSummaryIconTex[slot], sizeof(g_ddhSummaryIconTex[slot]),
                  path, _TRUNCATE);
    }
    DdhSummarySetRect(frame, x, yTop, x + width, yTop - height);
    DdhSummaryFrameShow(frame, 1);
}

static int DdhSummaryChartKind(const DdhEvent* e)
{
    uint32_t mask = e->damageMask;
    int damageType = -1;
    if (mask)
    {
        int bit = 0;
        while (bit < 31 && (mask & (1u << bit)) == 0) ++bit;
        damageType = bit;
    }
    if (e->attackType != 0 && damageType != 4) return 2;
    if (damageType == 4) return 0;
    return 1;
}

static int DdhSummaryChartSource(uint32_t addr, uint32_t code, const char* label)
{
    for (int i = 0; i < g_ddhSummaryChart.sourceCount; ++i)
        if (code ? g_ddhSummaryChart.source[i].code == code
                 : g_ddhSummaryChart.source[i].addr == addr)
        {
            if (!g_ddhSummaryChart.source[i].label[0] && label && label[0])
                DdhUtf8SafeCopy(g_ddhSummaryChart.source[i].label,
                                sizeof(g_ddhSummaryChart.source[i].label),
                                label,
                                sizeof(g_ddhSummaryChart.source[i].label) - 1);
            return i;
        }
    if (g_ddhSummaryChart.sourceCount >= DDH_SUMMARY_CHART_MAX_SRC) return -1;
    int i = g_ddhSummaryChart.sourceCount++;
    g_ddhSummaryChart.source[i].addr = addr;
    g_ddhSummaryChart.source[i].code = code;
    g_ddhSummaryChart.source[i].total = 0.0f;
    if (label && label[0])
        DdhUtf8SafeCopy(g_ddhSummaryChart.source[i].label,
                        sizeof(g_ddhSummaryChart.source[i].label),
                        label,
                        sizeof(g_ddhSummaryChart.source[i].label) - 1);
    return i;
}

static void DdhSummaryChartAdd(int bucket, int type, uint32_t addr, uint32_t code,
                               float amount, const char* label)
{
    if (bucket < 0 || bucket >= DDH_SUMMARY_CHART_SECONDS) return;
    int source = DdhSummaryChartSource(addr, code, label);
    if (source < 0) return;
    g_ddhSummaryChart.source[source].total += amount;
    g_ddhSummaryChart.total[bucket] += amount;

    int count = g_ddhSummaryChart.segCount[bucket];
    for (int i = 0; i < count; ++i)
    {
        DdhSummaryChartSeg* segment = &g_ddhSummaryChart.seg[bucket][i];
        if (segment->type == (uint8_t)type && segment->src == (uint8_t)source)
        {
            segment->amount += amount;
            return;
        }
    }
    if (count >= DDH_SUMMARY_CHART_MAX_SEG) return;
    DdhSummaryChartSeg* segment = &g_ddhSummaryChart.seg[bucket][count];
    segment->type = (uint8_t)type;
    segment->src = (uint8_t)source;
    segment->pad = 0;
    segment->amount = amount;
    g_ddhSummaryChart.segCount[bucket] = count + 1;
}

static int DdhSummaryChartBuild(uint32_t victim)
{
    memset(&g_ddhSummaryChart, 0, sizeof(g_ddhSummaryChart));
    if (!g_shm || !victim) return 0;

    uint32_t endTick = 0;
    const uint32_t count = g_shm->hdr.count;
    const uint32_t cap = g_shm->hdr.capacity ? g_shm->hdr.capacity : DDH_MAX_EVENTS;
    const uint32_t scan = count < cap ? count : cap;
    for (uint32_t k = 0; k < scan; ++k)
    {
        const uint32_t seq = count - k;
        const DdhEvent* e = &g_shm->ev[(seq - 1u) % cap];
        if (e->seq == seq && e->victim == victim) { endTick = e->tickMs; break; }
    }
    if (!endTick) return 0;
    g_ddhSummaryChart.victim = victim;
    g_ddhSummaryChart.endTick = endTick;
    {
        const uint32_t startTick =
            (uint32_t)InterlockedCompareExchange(&g_ddhGameClockStart, 0, 0);
        const int32_t elapsedMs = startTick
            ? (int32_t)(endTick - startTick) : -1;
        g_ddhSummaryChart.gameClockValid =
            elapsedMs >= 0 && elapsedMs < 7 * 24 * 60 * 60 * 1000;
        g_ddhSummaryChart.endGameSec = g_ddhSummaryChart.gameClockValid
            ? (uint32_t)elapsedMs / 1000u : 0u;
    }

    for (uint32_t k = 0; k < scan; ++k)
    {
        const uint32_t seq = count - k;
        const DdhEvent* e = &g_shm->ev[(seq - 1u) % cap];
        if (e->seq != seq || e->victim != victim) continue;
        if (!g_ddhSummaryChart.victimCode) g_ddhSummaryChart.victimCode = e->victimCode;
        if (e->hpValid && e->hpBefore > 0.0f && e->hpAfter <= 0.0f &&
            !g_ddhSummaryChart.fatalCode)
        {
            g_ddhSummaryChart.fatalSource = e->source;
            g_ddhSummaryChart.fatalCode = e->sourceCode;
            if (e->sourceName[0])
                DdhUtf8SafeCopy(g_ddhSummaryChart.fatalName,
                                sizeof(g_ddhSummaryChart.fatalName),
                                e->sourceName,
                                sizeof(g_ddhSummaryChart.fatalName) - 1);
        }
        const uint32_t age = endTick - e->tickMs;
        if (age >= DDH_SUMMARY_CHART_SECONDS * 1000u) continue;
        const int bucket = DDH_SUMMARY_CHART_SECONDS - 1 - (int)(age / 1000u);
        if (!(e->finalFlags & 1u) || e->finalDamage <= 0.01f) continue;

        const float effective = e->finalDamage;
        DdhSummaryChartAdd(bucket, DdhSummaryChartKind(e),
                           e->source, e->sourceCode, effective, e->sourceName);
        if (e->hpValid && e->actual > effective + 0.01f)
            DdhSummaryChartAdd(bucket, 3, e->source, e->sourceCode,
                               e->actual - effective, e->sourceName);
    }

    for (int i = 0; i < DDH_SUMMARY_CHART_SECONDS; ++i)
        if (g_ddhSummaryChart.total[i] > g_ddhSummaryChart.maxTotal)
            g_ddhSummaryChart.maxTotal = g_ddhSummaryChart.total[i];
    for (int b = 0; b < DDH_SUMMARY_CHART_SECONDS; ++b)
    {
        for (int i = 1; i < g_ddhSummaryChart.segCount[b]; ++i)
        {
            DdhSummaryChartSeg value = g_ddhSummaryChart.seg[b][i];
            int j = i - 1;
            while (j >= 0 && g_ddhSummaryChart.seg[b][j].amount < value.amount)
            {
                g_ddhSummaryChart.seg[b][j + 1] = g_ddhSummaryChart.seg[b][j];
                --j;
            }
            g_ddhSummaryChart.seg[b][j + 1] = value;
        }
    }
    g_ddhSummaryChart.valid = g_ddhSummaryChart.maxTotal > 0.01f ? 1 : 0;
    return 1;
}

static void DdhSummaryFormatAmount(char* out, size_t cap, float value)
{
    if (value >= 100000000.0f)
        DdhSprintf(out, cap, "%.2f亿", (double)(value / 100000000.0f));
    else if (value >= 10000.0f)
        DdhSprintf(out, cap, "%.1f万", (double)(value / 10000.0f));
    else
        DdhSprintf(out, cap, "%.0f", (double)value);
}

static void DdhSummaryKillerText(char* out, size_t cap)
{
    if (!out || cap == 0) return;
    out[0] = 0;
    char name[64] = { 0 };
    const char* source = g_ddhSummaryChart.fatalName;
    if (!source[0] && g_ddhSummaryChart.fatalCode)
        source = DdhCodeText(g_ddhSummaryChart.fatalCode);
    if (!source || !source[0]) source = "未知来源";
    DdhUtf8SafeCopy(name, sizeof(name), source, 30);
    DdhSprintf(out, cap, "击杀者 · %s", name);
}

static void DdhSummaryGameClockText(uint32_t gameSec, char* out, size_t cap)
{
    if (!out || cap == 0) return;
    out[0] = 0;
    if (!g_ddhSummaryChart.gameClockValid)
    {
        strncpy_s(out, cap, "--:--", _TRUNCATE);
        return;
    }
    DdhSprintf(out, cap, "%02u:%02u",
               gameSec / 60u, gameSec % 60u);
}

static void DdhSummaryWindowText(char* out, size_t cap)
{
    if (!out || cap == 0) return;
    char start[24] = { 0 };
    char end[24] = { 0 };
    const uint32_t startSec = g_ddhSummaryChart.endGameSec > 9u
        ? g_ddhSummaryChart.endGameSec - 9u : 0u;
    DdhSummaryGameClockText(
        startSec, start, sizeof(start));
    DdhSummaryGameClockText(
        g_ddhSummaryChart.endGameSec, end, sizeof(end));
    DdhSprintf(out, cap, "%s–%s", start, end);
}

static void DdhSummaryApplyLayout(void)
{
    const float fullW = 0.34f;
    const float fullH = 0.32f;
    g_ddhSummaryCollapsed = g_ddhSummaryCollapsed ? 1 : 0;
    g_ddhSummaryW = g_ddhSummaryCollapsed ? 0.082f : fullW;
    g_ddhSummaryH = g_ddhSummaryCollapsed ? 0.085f : fullH;
    float x = g_ddhSummaryCollapsed
        ? g_ddhSummaryWantX + fullW - g_ddhSummaryW
        : g_ddhSummaryWantX;
    float y = g_ddhSummaryWantY;
    if (x < 0.005f) x = 0.005f;
    if (x + g_ddhSummaryW > 0.795f) x = 0.795f - g_ddhSummaryW;
    if (y > -0.005f) y = -0.005f;
    if (y - g_ddhSummaryH < -0.595f) y = -0.595f + g_ddhSummaryH;
    g_ddhSummaryX = x;
    g_ddhSummaryY = y;
}

static void DdhSummaryChartRenderCollapsed(void)
{
    static const char* typeBars[DDH_SUMMARY_CHART_TYPES] = {
        "ReplaceableTextures\\TeamColor\\TeamColor00.blp",
        "ReplaceableTextures\\TeamColor\\TeamColor01.blp",
        "ReplaceableTextures\\TeamColor\\TeamColor08.blp",
        "ReplaceableTextures\\TeamColor\\TeamColor03.blp"
    };
    float totals[DDH_SUMMARY_CHART_TYPES] = { 0, 0, 0, 0 };
    float grand = 0.0f;
    for (int b = 0; b < DDH_SUMMARY_CHART_SECONDS; ++b)
    {
        for (int i = 0; i < g_ddhSummaryChart.segCount[b]; ++i)
        {
            const int type = g_ddhSummaryChart.seg[b][i].type;
            totals[type] += g_ddhSummaryChart.seg[b][i].amount;
            grand += g_ddhSummaryChart.seg[b][i].amount;
        }
    }

    DdhSummaryIcon(10, g_ddhSummaryChart.fatalCode,
        g_ddhSummaryX + 0.018f, g_ddhSummaryY - 0.008f, 0.046f, 0.061f);

    const float left = g_ddhSummaryX + 0.008f;
    const float right = g_ddhSummaryX + g_ddhSummaryW - 0.008f;
    const float width = right > left ? right - left : 0.0f;
    const float y0 = g_ddhSummaryY - 0.075f;
    const float y1 = g_ddhSummaryY - 0.082f;
    float cursor = left;
    const float denominator = grand > 0.01f ? grand : 1.0f;
    for (int t = 0; t < DDH_SUMMARY_CHART_TYPES; ++t)
    {
        if (totals[t] <= 0.01f) continue;
        float segment = totals[t] / denominator * width;
        if (segment < 0.002f) segment = 0.002f;
        DdhSummarySetBar(40 + t, typeBars[t], cursor, y0, cursor + segment, y1);
        cursor += segment;
    }
}

static void DdhSummaryChartRender(void)
{
    static const char* typeNames[DDH_SUMMARY_CHART_TYPES] = { "物理", "法术", "纯粹", "移除" };
    static const uint32_t typeColors[DDH_SUMMARY_CHART_TYPES] = {
        0xFFFF7070u, 0xFF70B0FFu, 0xFFFFFFFFu, 0xFFC080FFu
    };
    static const char* typeBars[DDH_SUMMARY_CHART_TYPES] = {
        "ReplaceableTextures\\TeamColor\\TeamColor00.blp",
        "ReplaceableTextures\\TeamColor\\TeamColor01.blp",
        "ReplaceableTextures\\TeamColor\\TeamColor08.blp",
        "ReplaceableTextures\\TeamColor\\TeamColor03.blp"
    };
    char buffer[96];
    char killer[96] = { 0 };
    char window[96] = { 0 };
    float typeTotal[DDH_SUMMARY_CHART_TYPES] = { 0, 0, 0, 0 };
    float bucketType[DDH_SUMMARY_CHART_SECONDS][DDH_SUMMARY_CHART_TYPES];
    float sourceType[DDH_SUMMARY_CHART_MAX_SRC][DDH_SUMMARY_CHART_TYPES];
    float sourceTotal[DDH_SUMMARY_CHART_MAX_SRC] = { 0 };
    memset(bucketType, 0, sizeof(bucketType));
    memset(sourceType, 0, sizeof(sourceType));
    DdhSummaryApplyLayout();

    uint32_t ui = DdhSummaryGetUi();
    if (!ui) return;
    if (g_ddhSummaryUi == ui)
        DdhSummaryHideFrames();
    else
        DdhSummaryResetFrames(ui);

    if (!g_ddhSummaryBg)
    {
        __try { g_ddhSummaryBg = ((fn_ddh_summary_create_backdrop_t)(uintptr_t)g_ddhSummaryCreateBackdrop)(ui, 0, 0); }
        __except (EXCEPTION_EXECUTE_HANDLER) { g_ddhSummaryBg = 0; }
        if (g_ddhSummaryBg)
        {
            __try
            {
                ((fn_ddh_summary_setbackdrop_t)(uintptr_t)g_ddhSummarySetBackdrop)
                    ((void*)(uintptr_t)g_ddhSummaryBg, 0,
                     "UI\\widgets\\BattleNet\\bnet-tooltip-background.blp", 0u, 0u,
                     "UI\\widgets\\BattleNet\\bnet-tooltip-border.blp", 1u);
            }
            __except (EXCEPTION_EXECUTE_HANDLER) { }
        }
    }
    DdhSummarySetRect(g_ddhSummaryBg,
                      g_ddhSummaryX - 0.012f, g_ddhSummaryY + 0.012f,
                      g_ddhSummaryX + g_ddhSummaryW, g_ddhSummaryY - g_ddhSummaryH);
    DdhSummaryFrameShow(g_ddhSummaryBg, 1);
    if (g_ddhSummaryCollapsed)
    {
        DdhSummaryChartRenderCollapsed();
        return;
    }

    for (int b = 0; b < DDH_SUMMARY_CHART_SECONDS; ++b)
    {
        for (int i = 0; i < g_ddhSummaryChart.segCount[b]; ++i)
        {
            const int type = g_ddhSummaryChart.seg[b][i].type;
            const int source = g_ddhSummaryChart.seg[b][i].src;
            const float amount = g_ddhSummaryChart.seg[b][i].amount;
            bucketType[b][type] += amount;
            typeTotal[type] += amount;
            sourceType[source][type] += amount;
            sourceTotal[source] += amount;
        }
    }

    float grand = 0.0f, typeMax = 0.0f, sourceMax = 0.0f;
    for (int b = 0; b < DDH_SUMMARY_CHART_SECONDS; ++b) grand += g_ddhSummaryChart.total[b];
    for (int t = 0; t < DDH_SUMMARY_CHART_TYPES; ++t)
        if (typeTotal[t] > typeMax) typeMax = typeTotal[t];
    for (int s = 0; s < g_ddhSummaryChart.sourceCount; ++s)
        if (sourceTotal[s] > sourceMax) sourceMax = sourceTotal[s];
    DdhSummaryKillerText(killer, sizeof(killer));
    DdhSummaryWindowText(window, sizeof(window));

    DdhSummaryIcon(10, g_ddhSummaryChart.fatalCode,
        g_ddhSummaryX + 0.005f, g_ddhSummaryY + 0.001f, 0.026f, 0.032f);
    DdhSummaryText(0, "阵亡总结", g_ddhSummaryX + 0.035f, g_ddhSummaryY,
                   g_ddhSummaryFont * 1.02f, 0xFFF0E0C0u);
    DdhSummaryText(1, killer, g_ddhSummaryX + 0.035f,
                   g_ddhSummaryY - 0.017f, g_ddhSummaryFont * 0.52f,
                   0xFFD0D0D0u);
    DdhSummaryText(3, window, g_ddhSummaryX + 0.248f,
                   g_ddhSummaryY - 0.002f, g_ddhSummaryFont * 0.46f,
                   0xFFA8A8A8u);
    DdhSummaryText(4, ">>>",
                   g_ddhSummaryX + g_ddhSummaryW - 0.030f,
                   g_ddhSummaryY - 0.003f,
                   g_ddhSummaryFont * 0.85f, 0xFFFFD080u);

    DdhSummaryText(5, "伤害类型", g_ddhSummaryX + 0.008f,
                   g_ddhSummaryY - 0.037f, g_ddhSummaryFont * 0.78f,
                   0xFFE8E8E8u);
    DdhSummaryText(6, "英雄伤害", g_ddhSummaryX + 0.196f,
                   g_ddhSummaryY - 0.037f, g_ddhSummaryFont * 0.78f,
                   0xFFE8E8E8u);

    for (int t = 0; t < DDH_SUMMARY_CHART_TYPES; ++t)
    {
        const float rowY = g_ddhSummaryY - 0.055f - (float)t * 0.0168f;
        DdhSummaryFormatAmount(buffer, sizeof(buffer), typeTotal[t]);
        DdhSummaryTextRightTo(10 + t, buffer, g_ddhSummaryX + 0.060f,
                              rowY + 0.0008f, g_ddhSummaryFont * 0.62f,
                              0xFFD8D8D8u);
        DdhSummarySetBar(60 + t, "Textures\\Black32.blp",
                         g_ddhSummaryX + 0.060f, rowY + 0.001f,
                         g_ddhSummaryX + 0.125f, rowY - 0.010f);
        if (typeTotal[t] > 0.01f)
        {
            float width = typeTotal[t] / (typeMax > 0.01f ? typeMax : 1.0f) * 0.065f;
            if (width < 0.003f) width = 0.003f;
            DdhSummarySetBar(20 + t, typeBars[t],
                             g_ddhSummaryX + 0.060f, rowY + 0.001f,
                             g_ddhSummaryX + 0.060f + width, rowY - 0.010f);
        }
        DdhSummaryText(14 + t, typeNames[t], g_ddhSummaryX + 0.064f, rowY + 0.0008f,
                       g_ddhSummaryFont * 0.66f, typeColors[t]);
    }

    {
        const float totalY = g_ddhSummaryY - 0.125f;
        DdhSummaryFormatAmount(buffer, sizeof(buffer), grand);
        DdhSummaryTextRightTo(2, buffer, g_ddhSummaryX + 0.060f, totalY,
                              g_ddhSummaryFont * 0.66f, 0xFFF0D080u);
        DdhSummaryText(7, "总伤害", g_ddhSummaryX + 0.064f, totalY,
                       g_ddhSummaryFont * 0.66f, 0xFFF0E0C0u);
    }

    int order[DDH_SUMMARY_CHART_MAX_SRC];
    int sourceCount = 0;
    for (int s = 0; s < g_ddhSummaryChart.sourceCount; ++s) order[sourceCount++] = s;
    for (int i = 1; i < sourceCount; ++i)
    {
        int value = order[i], j = i - 1;
        while (j >= 0 && sourceTotal[order[j]] < sourceTotal[value])
        {
            order[j + 1] = order[j];
            --j;
        }
        order[j + 1] = value;
    }
    const int mainSourceCount = sourceCount > 7 ? 6 : sourceCount;
    for (int k = 0; k < mainSourceCount; ++k)
    {
        const int source = order[k];
        const float rowY = g_ddhSummaryY - 0.055f - (float)k * 0.0148f;
        DdhSummaryIcon(k, g_ddhSummaryChart.source[source].code,
                       g_ddhSummaryX + 0.193f, rowY + 0.001f,
                       0.011f, 0.013f);
        DdhSummaryFormatAmount(buffer, sizeof(buffer), sourceTotal[source]);
        DdhSummaryTextRightTo(20 + k, buffer, g_ddhSummaryX + 0.242f,
                              rowY + 0.0008f, g_ddhSummaryFont * 0.62f,
                              0xFFD8D8D8u);
        float cursor = g_ddhSummaryX + 0.242f;
        const float totalWidth = sourceTotal[source] / (sourceMax > 0.01f ? sourceMax : 1.0f) * 0.073f;
        const float sourceDenominator = sourceTotal[source] > 0.01f
            ? sourceTotal[source] : 1.0f;
        for (int t = 0; t < DDH_SUMMARY_CHART_TYPES; ++t)
        {
            if (sourceType[source][t] <= 0.01f) continue;
            float width = sourceType[source][t] / sourceDenominator * totalWidth;
            if (width < 0.002f) width = 0.002f;
            DdhSummarySetBar(30 + k * DDH_SUMMARY_CHART_TYPES + t, typeBars[t],
                             cursor, rowY + 0.001f, cursor + width, rowY - 0.009f);
            cursor += width;
        }
    }

    if (sourceCount > mainSourceCount)
    {
        const float rowY = g_ddhSummaryY - 0.055f - (float)mainSourceCount * 0.0148f;
        float otherTotal = 0.0f;
        float otherType[DDH_SUMMARY_CHART_TYPES] = { 0, 0, 0, 0 };
        for (int i = mainSourceCount; i < sourceCount; ++i)
        {
            const int source = order[i];
            otherTotal += sourceTotal[source];
            for (int t = 0; t < DDH_SUMMARY_CHART_TYPES; ++t)
                otherType[t] += sourceType[source][t];
        }
        DdhSummaryText(26, "其他", g_ddhSummaryX + 0.193f, rowY + 0.0008f,
                       g_ddhSummaryFont * 0.58f, 0xFFB8B8B8u);
        DdhSummaryFormatAmount(buffer, sizeof(buffer), otherTotal);
        DdhSummaryTextRightTo(27, buffer, g_ddhSummaryX + 0.242f,
                              rowY + 0.0008f, g_ddhSummaryFont * 0.62f,
                              0xFFD8D8D8u);
        float cursor = g_ddhSummaryX + 0.242f;
        const float totalWidth = otherTotal / (sourceMax > 0.01f ? sourceMax : 1.0f) * 0.073f;
        const float denominator = otherTotal > 0.01f ? otherTotal : 1.0f;
        for (int t = 0; t < DDH_SUMMARY_CHART_TYPES; ++t)
        {
            if (otherType[t] <= 0.01f) continue;
            float width = otherType[t] / denominator * totalWidth;
            if (width < 0.002f) width = 0.002f;
            DdhSummarySetBar(54 + t, typeBars[t],
                             cursor, rowY + 0.001f, cursor + width, rowY - 0.009f);
            cursor += width;
        }
    }

    const float base = g_ddhSummaryY - 0.262f;
    const float top = g_ddhSummaryY - 0.196f;
    const float maxHeight = top - base;
    const float barWidth = 0.024f;
    const float gap = 0.0092f;
    const float startX = g_ddhSummaryX + 0.004f;
    const float maximum = g_ddhSummaryChart.maxTotal > 0.01f ? g_ddhSummaryChart.maxTotal : 1.0f;
    for (int i = 0; i < DDH_SUMMARY_CHART_SECONDS; ++i)
    {
        const float amount = g_ddhSummaryChart.total[i];
        const float height = amount / maximum * maxHeight;
        const float x0 = startX + (float)i * (barWidth + gap);
        if (amount > 0.01f)
        {
            const float denominator = amount > 0.01f ? amount : 1.0f;
            float cursorY = base;
            for (int t = 0; t < DDH_SUMMARY_CHART_TYPES; ++t)
            {
                if (bucketType[i][t] <= 0.01f) continue;
                const float segmentHeight = bucketType[i][t] / denominator * height;
                if (segmentHeight <= 0.0f) continue;
                DdhSummarySetBar(
                    64 + i * DDH_SUMMARY_CHART_TYPES + t, typeBars[t],
                    x0, cursorY + segmentHeight, x0 + barWidth, cursorY);
                cursorY += segmentHeight;
            }
        }
        DdhSummaryFormatAmount(buffer, sizeof(buffer), amount);
        if (amount > 0.01f)
            DdhSummaryText(40 + i, buffer, x0 - 0.002f, base + height + 0.006f,
                           g_ddhSummaryFont * 0.52f, 0xFFFFD080u);
        const uint32_t secondsAgo =
            (uint32_t)(DDH_SUMMARY_CHART_SECONDS - 1 - i);
        const uint32_t labelSec = g_ddhSummaryChart.endGameSec > secondsAgo
            ? g_ddhSummaryChart.endGameSec - secondsAgo : 0u;
        DdhSummaryGameClockText(labelSec, buffer, sizeof(buffer));
        DdhSummaryText(50 + i, buffer, x0 + 0.003f, base - g_ddhSummaryFont * 1.05f,
                       g_ddhSummaryFont * 0.62f, 0xFFB0B0B0u);
    }
}

static bool DdhSummaryChartShow(uint32_t victim)
{
    if (!DdhSummaryInitUi()) return false;
    if (!DdhSummaryChartBuild(victim)) return false;
    InterlockedExchange(&g_ddhSummaryCollapsed, 1);
    DdhSummaryChartRender();
    InterlockedExchange(&g_ddhSummaryShown, 1);
    InterlockedExchange(&g_ddhSummaryHideAt, (LONG)(GetTickCount() + 20000u));
    if (g_gameWnd) SetTimer(g_gameWnd, DDH_SUMMARY_CHART_TIMER, 500u, NULL);
    if (InterlockedIncrement(&g_ddhSummaryLogCount) <= 10)
        LogLine("阵亡总结：原生面板已显示（victim=0x%08X，10 秒总伤 %.0f，来源 %d）",
                victim, (double)g_ddhSummaryChart.maxTotal,
                g_ddhSummaryChart.sourceCount);
    return true;
}

static bool DdhSummaryChartClick(int px, int py)
{
    if (!InterlockedCompareExchange(&g_ddhSummaryShown, 0, 0)) return false;
    RECT rc = { 0 };
    if (!g_gameWnd || !GetClientRect(g_gameWnd, &rc)) return false;
    const int cw = rc.right - rc.left;
    const int ch = rc.bottom - rc.top;
    if (cw <= 0 || ch <= 0) return false;

    /* Warcraft UI coordinates span 0..0.8 horizontally and 0..-0.6 vertically,
       while the client area has arbitrary pixel dimensions. */
    const float u = (float)px / ((float)cw * 1.25f);
    const float v = -(float)py * 0.6f / (float)ch;
    const bool collapsed = g_ddhSummaryCollapsed != 0;
    const float l = collapsed ? g_ddhSummaryX - 0.012f
                              : g_ddhSummaryX + g_ddhSummaryW - 0.042f;
    const float r = g_ddhSummaryX + g_ddhSummaryW + 0.002f;
    const float t = g_ddhSummaryY + 0.014f;
    const float b = g_ddhSummaryY - g_ddhSummaryH - (collapsed ? 0.002f : 0.014f);
    if (u < l || u > r || v > t || v < b) return false;

    InterlockedExchange(&g_ddhSummaryCollapsed,
                        g_ddhSummaryCollapsed ? 0 : 1);
    DdhSummaryChartRender();
    InterlockedExchange(&g_ddhSummaryHideAt, (LONG)(GetTickCount() + 20000u));
    LogLine("阵亡总结：已切换为%s", g_ddhSummaryCollapsed ? "缩版" : "展开");
    return true;
}

static void DdhSummaryChartHide(void);

static bool DdhSummaryChartToggleVisible(void)
{
    if (InterlockedCompareExchange(&g_ddhSummaryShown, 0, 0))
    {
        DdhSummaryChartHide();
        return true;
    }
    if (!g_ddhSummaryChart.valid)
        return false;
    DdhSummaryChartRender();
    InterlockedExchange(&g_ddhSummaryShown, 1);
    InterlockedExchange(&g_ddhSummaryHideAt, (LONG)(GetTickCount() + 20000u));
    if (g_gameWnd) SetTimer(g_gameWnd, DDH_SUMMARY_CHART_TIMER, 500u, NULL);
    LogLine("阵亡总结：按 ~ 重新显示");
    return true;
}

static void DdhSummaryChartHide(void)
{
    if (!InterlockedExchange(&g_ddhSummaryShown, 0)) return;
    const uint32_t ui = DdhSummaryGetUi();
    if (ui && ui == g_ddhSummaryUi)
        DdhSummaryHideFrames();
    else
        DdhSummaryResetFrames(0);
    InterlockedExchange(&g_ddhSummaryHideAt, 0);
    if (g_gameWnd) KillTimer(g_gameWnd, DDH_SUMMARY_CHART_TIMER);
}

static void DdhSummaryChartTick(void)
{
    const LONG hideAt = InterlockedCompareExchange(&g_ddhSummaryHideAt, 0, 0);
    if (hideAt && (LONG)GetTickCount() >= hideAt)
        DdhSummaryChartHide();
}
