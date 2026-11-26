/* In-game native damage summary chart.
   This module is called only from DDH_WM_DAMAGE_DEFERRED, after the damage hook
   has returned. It creates local CTextFrame/CBackdropFrame objects only. */

#define DDH_SUMMARY_CHART_SECONDS 10
#define DDH_SUMMARY_CHART_TYPES   4
#define DDH_SUMMARY_CHART_MAX_SRC 8
#define DDH_SUMMARY_CHART_MAX_SEG 16
#define DDH_SUMMARY_CHART_BAR_MAX 64
#define DDH_SUMMARY_CHART_TEXT_MAX 40
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
};

static struct
{
    int valid;
    uint32_t victim;
    uint32_t endTick;
    uint32_t fatalSource;
    uint32_t fatalCode;
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
static float g_ddhSummaryX = 0.455f;
static float g_ddhSummaryY = -0.10f;
static float g_ddhSummaryW = 0.34f;
static float g_ddhSummaryH = 0.32f;
static float g_ddhSummaryFont = 0.0135f;
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
}

static void DdhSummaryResetFrames(uint32_t ui)
{
    if (g_ddhSummaryUi == ui && g_ddhSummaryUi) return;
    g_ddhSummaryUi = ui;
    g_ddhSummaryBg = 0;
    memset(g_ddhSummaryBars, 0, sizeof(g_ddhSummaryBars));
    memset(g_ddhSummaryBarTex, 0, sizeof(g_ddhSummaryBarTex));
    memset(g_ddhSummaryTexts, 0, sizeof(g_ddhSummaryTexts));
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

static int DdhSummaryChartSource(uint32_t addr, uint32_t code)
{
    for (int i = 0; i < g_ddhSummaryChart.sourceCount; ++i)
        if (code ? g_ddhSummaryChart.source[i].code == code
                 : g_ddhSummaryChart.source[i].addr == addr)
            return i;
    if (g_ddhSummaryChart.sourceCount >= DDH_SUMMARY_CHART_MAX_SRC) return -1;
    int i = g_ddhSummaryChart.sourceCount++;
    g_ddhSummaryChart.source[i].addr = addr;
    g_ddhSummaryChart.source[i].code = code;
    g_ddhSummaryChart.source[i].total = 0.0f;
    return i;
}

static void DdhSummaryChartAdd(int bucket, int type, uint32_t addr, uint32_t code, float amount)
{
    if (bucket < 0 || bucket >= DDH_SUMMARY_CHART_SECONDS) return;
    int source = DdhSummaryChartSource(addr, code);
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

    for (uint32_t k = 0; k < scan; ++k)
    {
        const uint32_t seq = count - k;
        const DdhEvent* e = &g_shm->ev[(seq - 1u) % cap];
        if (e->seq != seq || e->victim != victim) continue;
        if (e->hpValid && e->hpBefore > 0.0f && e->hpAfter <= 0.0f &&
            !g_ddhSummaryChart.fatalCode)
        {
            g_ddhSummaryChart.fatalSource = e->source;
            g_ddhSummaryChart.fatalCode = e->sourceCode;
        }
        const uint32_t age = endTick - e->tickMs;
        if (age >= DDH_SUMMARY_CHART_SECONDS * 1000u) continue;
        const int bucket = DDH_SUMMARY_CHART_SECONDS - 1 - (int)(age / 1000u);
        if (!(e->finalFlags & 1u) || e->finalDamage <= 0.01f) continue;

        const float effective = e->finalDamage;
        DdhSummaryChartAdd(bucket, DdhSummaryChartKind(e),
                           e->source, e->sourceCode, effective);
        if (e->hpValid && e->actual > effective + 0.01f)
            DdhSummaryChartAdd(bucket, 3, e->source, e->sourceCode,
                               e->actual - effective);
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
    float typeTotal[DDH_SUMMARY_CHART_TYPES] = { 0, 0, 0, 0 };
    float sourceType[DDH_SUMMARY_CHART_MAX_SRC][DDH_SUMMARY_CHART_TYPES];
    float sourceTotal[DDH_SUMMARY_CHART_MAX_SRC] = { 0 };
    memset(sourceType, 0, sizeof(sourceType));

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

    for (int b = 0; b < DDH_SUMMARY_CHART_SECONDS; ++b)
    {
        for (int i = 0; i < g_ddhSummaryChart.segCount[b]; ++i)
        {
            const int type = g_ddhSummaryChart.seg[b][i].type;
            const int source = g_ddhSummaryChart.seg[b][i].src;
            const float amount = g_ddhSummaryChart.seg[b][i].amount;
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

    DdhSummaryText(0, "阵亡总结", g_ddhSummaryX + 0.035f, g_ddhSummaryY,
                   g_ddhSummaryFont * 1.08f, 0xFFF0E0C0u);
    DdhSummaryFormatAmount(buffer, sizeof(buffer), grand);
    {
        char total[96] = { 0 };
        DdhSprintf(total, sizeof(total), "总伤害 %s", buffer);
        DdhSummaryText(23, total, g_ddhSummaryX + 0.238f, g_ddhSummaryY,
                       g_ddhSummaryFont * 0.92f, 0xFFFFD080u);
    }
    DdhSummaryText(38, ">>>",
                   g_ddhSummaryX + g_ddhSummaryW - 0.030f,
                   g_ddhSummaryY - 0.003f,
                   g_ddhSummaryFont * 0.85f, 0xFFFFD080u);

    for (int t = 0; t < DDH_SUMMARY_CHART_TYPES; ++t)
    {
        const float rowY = g_ddhSummaryY - 0.042f - (float)t * 0.028f;
        DdhSummaryText(1 + t, typeNames[t], g_ddhSummaryX + 0.004f, rowY + 0.0012f,
                       g_ddhSummaryFont * 0.9f, typeColors[t]);
        if (typeTotal[t] > 0.01f)
        {
            float width = typeTotal[t] / (typeMax > 0.01f ? typeMax : 1.0f) * 0.085f;
            if (width < 0.004f) width = 0.004f;
            DdhSummarySetBar(20 + t, typeBars[t],
                             g_ddhSummaryX + 0.040f, rowY,
                             g_ddhSummaryX + 0.040f + width, rowY - 0.012f);
        }
        const float pct = grand > 0.01f ? typeTotal[t] * 100.0f / grand : 0.0f;
        DdhSprintf(buffer, sizeof(buffer), "%.0f%%", (double)pct);
        DdhSummaryText(5 + t, buffer, g_ddhSummaryX + 0.134f, rowY + 0.0003f,
                       g_ddhSummaryFont * 0.78f, 0xFFE0E0E0u);
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
    for (int k = 0; k < 4 && k < sourceCount; ++k)
    {
        const int source = order[k];
        const float rowY = g_ddhSummaryY - 0.042f - (float)k * 0.028f;
        DdhCodeText(g_ddhSummaryChart.source[source].code, buffer, sizeof(buffer));
        DdhSummaryText(9 + k, buffer, g_ddhSummaryX + 0.212f, rowY + 0.0012f,
                       g_ddhSummaryFont * 0.65f, 0xFFD8D8D8u);
        float cursor = g_ddhSummaryX + 0.230f;
        for (int t = 0; t < DDH_SUMMARY_CHART_TYPES; ++t)
        {
            if (sourceType[source][t] <= 0.01f) continue;
            float width = sourceType[source][t] / (sourceMax > 0.01f ? sourceMax : 1.0f) * 0.055f;
            if (width < 0.003f) width = 0.003f;
            DdhSummarySetBar(30 + k * DDH_SUMMARY_CHART_TYPES + t, typeBars[t],
                             cursor, rowY, cursor + width, rowY - 0.012f);
            cursor += width;
        }
        const float pct = grand > 0.01f ? sourceTotal[source] * 100.0f / grand : 0.0f;
        DdhSprintf(buffer, sizeof(buffer), "%.0f%%", (double)pct);
        DdhSummaryText(14 + k, buffer, g_ddhSummaryX + 0.298f, rowY + 0.0003f,
                       g_ddhSummaryFont * 0.75f, 0xFFE0E0E0u);
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
            DdhSummarySetBar(i, "UI\\Widgets\\Glues\\LoadingBar\\Loading-BarFill.blp",
                             x0, base + height, x0 + barWidth, base);
        DdhSummaryFormatAmount(buffer, sizeof(buffer), amount);
        if (amount > 0.01f)
            DdhSummaryText(18 + i, buffer, x0 - 0.002f, base + height + 0.006f,
                           g_ddhSummaryFont * 0.52f, 0xFFFFD080u);
        const uint32_t age = (g_ddhSummaryChart.endTick - i * 1000u) / 1000u;
        DdhSprintf(buffer, sizeof(buffer), "%02u:%02u", age / 60u, age % 60u);
        DdhSummaryText(28 + i, buffer, x0 + 0.003f, base - g_ddhSummaryFont * 1.05f,
                       g_ddhSummaryFont * 0.62f, 0xFFB0B0B0u);
    }
}

static bool DdhSummaryChartShow(uint32_t victim)
{
    if (!DdhSummaryInitUi()) return false;
    if (!DdhSummaryChartBuild(victim)) return false;
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
