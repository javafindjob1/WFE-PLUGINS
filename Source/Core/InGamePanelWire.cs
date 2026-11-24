using System.Buffers.Binary;
using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>面板里的一行：颜色（0xAARRGGBB）+ 文本（UTF-8，单行，不带内联 |c 样式码）。</summary>
public sealed record PanelLine(uint Color, string Text);

/// <summary>
/// ddh v17 的“游戏内阵亡面板 / 英雄查询 / 来源头像”协议（与 <c>_test/hook/ddh.cpp</c> 的
/// <c>DdhPanelBlock</c> / <c>DdhHeroBlock</c> / <c>DdhIconBlock</c> 逐字节对应；v16→v17 只追加 IconBlock）。
///
/// <code>
/// DdhShared = DdhHeader(64) + DdhEvent ev[512] + DdhAttrBlock(20360)
///           + DdhPanelBlock(4952) @141256
///           + DdhHeroBlock(400)  @146208
///           + DdhIconBlock(48)   @146608
///
/// DdhPanelBlock：
///   +0  u32 seq            C# 每次新内容 +1（最后写）
///   +4  u32 appliedSeq     ddh 拷出内容后写
///   +8  u32 flags          bit0=显示，bit1=隐藏，bit2=背景，bit3=默认收起，
///                          bits8..15=收起行数（0=ddh 默认 6）
///   +12 u32 ttlMs
///   +16 u32 lineCount      1..20
///   +20 u32 anchor         0..8
///   +24 f32 x              +28 f32 y
///   +32 f32 lineHeight     +36 f32 fontHeight
///   +40 char fontName[32]
///   +72 Line lines[20]     Line = { u32 color; char text[240]; }（244 字节）
///
/// DdhHeroBlock：
///   +0  u32 seq  +4 u32 appliedSeq  +8 u32 count  +12 pad
///   +16  Req req[16]  { u32 addr; u32 rawcode; }        （8 字节/项）
///   +144 Res res[16]  { u32 addr; u32 rawcode; i32 isHero; u32 pad; }（16 字节/项）
///
/// DdhIconBlock（v17）：
///   +0 u32 seq  +4 u32 appliedSeq  +8 u32 count  +12 pad
///   +16 Slot slots[4] { u32 lineIndex; u32 rawcode; }（8 字节/项）
/// </code>
///
/// C# 只负责组“已经排好版的行”；ddh 只负责把每行变成一个引擎 CTextFrame。
/// </summary>
public static class InGamePanelWire
{
    public const int MaxLines = 20;
    public const int LineTextBytes = 240;      // 含结尾 NUL
    public const int FontNameBytes = 32;
    public const int HeroSlots = 16;

    public const int PanelBlockSize = 4952;
    public const int HeroBlockSize = 400;
    public const int IconBlockSize = 80;
    public const int MaxIcons = 4;

    public const uint FlagShow = 0x1;
    public const uint FlagHide = 0x2;
    /// <summary>v16：显示深色背景。</summary>
    public const uint FlagBackground = 0x4;
    /// <summary>v16：默认收起。</summary>
    public const uint FlagStartCollapsed = 0x8;
    /// <summary>v16：收起时显示的行数在 flags bit8..15（0 = ddh 默认 6）。</summary>
    public const int CollapsedLinesShift = 8;
    public const uint CollapsedLinesMask = 0xFF;

    /// <summary>承伤图表模式（flags bit4）：lines 区前 8 字节换成 ChartReq{magic, victim}。</summary>
    public const uint FlagChart = 0x10;
    public const uint ChartMagic = 0x31544843;   // 'CHT1'
    public const int OffsetChartMagic = OffsetLines;        // 72
    public const int OffsetChartVictim = OffsetLines + 4;   // 76

    /// <summary>ddh 是否支持 v16 的背景/收起（面板块布局仍与 v15 相同）。</summary>
    public static bool StyleSupported(uint version) => version >= 16;

    /// <summary>ddh 是否支持 v17 的伤害来源头像块。</summary>
    public static bool IconSupported(uint version) => version >= 17;

    // ---- PanelBlock 字段偏移 ----
    public const int OffsetSeq = 0;
    public const int OffsetAppliedSeq = 4;
    public const int OffsetFlags = 8;
    public const int OffsetTtlMs = 12;
    public const int OffsetLineCount = 16;
    public const int OffsetAnchor = 20;
    public const int OffsetX = 24;
    public const int OffsetY = 28;
    public const int OffsetLineHeight = 32;
    public const int OffsetFontHeight = 36;
    public const int OffsetFontName = 40;
    public const int OffsetLines = 72;

    public const int LineStride = 244;
    public const int LineOffsetColor = 0;
    public const int LineOffsetText = 4;

    // ---- HeroBlock 字段偏移 ----
    public const int OffsetHeroSeq = 0;
    public const int OffsetHeroAppliedSeq = 4;
    public const int OffsetHeroCount = 8;
    public const int OffsetHeroReq = 16;
    public const int OffsetHeroRes = 144;
    public const int HeroReqStride = 8;
    public const int HeroResStride = 16;

    // ---- v17 IconBlock 字段偏移 ----
    public const int OffsetIconBlock = 146608;
    public const int OffsetIconSeq = 0;
    public const int OffsetIconAppliedSeq = 4;
    public const int OffsetIconCount = 8;
    public const int OffsetIconSlots = 16;
    public const int IconSlotStride = 16;
    public const int IconSlotLineIndex = 0;
    public const int IconSlotRawCode = 4;
    public const int IconSlotSourceAddr = 8;

    /// <summary>与 ddh 真机日志/结构体断言一致：任何一项改错，自检立即失败。</summary>
    public static bool LayoutMatchesDdh =>
        PanelBlockSize == 4952 && HeroBlockSize == 400 &&
        MaxLines == 20 && LineTextBytes == 240 && FontNameBytes == 32 && HeroSlots == 16 &&
        OffsetSeq == 0 && OffsetAppliedSeq == 4 && OffsetFlags == 8 && OffsetTtlMs == 12 &&
        OffsetLineCount == 16 && OffsetAnchor == 20 && OffsetX == 24 && OffsetY == 28 &&
        OffsetLineHeight == 32 && OffsetFontHeight == 36 && OffsetFontName == 40 && OffsetLines == 72 &&
        LineStride == 244 && LineOffsetColor == 0 && LineOffsetText == 4 &&
        OffsetHeroSeq == 0 && OffsetHeroAppliedSeq == 4 && OffsetHeroCount == 8 &&
        OffsetHeroReq == 16 && OffsetHeroRes == 144 && HeroReqStride == 8 && HeroResStride == 16 &&
        IconBlockSize == 80 && MaxIcons == 4 && OffsetIconBlock == 146608 &&
        OffsetIconSeq == 0 && OffsetIconAppliedSeq == 4 && OffsetIconCount == 8 &&
        OffsetIconSlots == 16 && IconSlotStride == 16 &&
        IconSlotLineIndex == 0 && IconSlotRawCode == 4 &&
        64 + 512 * 236 == 120896 && 120896 + 20360 == 141256 &&
        141256 + PanelBlockSize == 146208 &&
        146608 + IconBlockSize == 146688;

    /// <summary>把类型码（显示顺序，如 "Hpal"）打成 JASS 顺序的 integer：'Hpal' = 0x4870616C。</summary>
    public static uint ToJassRawCode(string? typeCode)
    {
        if (string.IsNullOrEmpty(typeCode) || typeCode.Length < 4) return 0;
        return ((uint)(byte)typeCode[0] << 24) |
               ((uint)(byte)typeCode[1] << 16) |
               ((uint)(byte)typeCode[2] << 8) |
               (byte)typeCode[3];
    }

    /// <summary>按 UTF-8 字节安全截断（不切坏汉字），超长时末尾补 “…”。</summary>
    public static string TruncateUtf8(string? text, int maxBytes)
    {
        text ??= "";
        if (maxBytes <= 0) return "";
        if (Encoding.UTF8.GetByteCount(text) <= maxBytes) return text;

        var sb = new StringBuilder();
        int bytes = 0;
        foreach (char ch in text)
        {
            int b = Encoding.UTF8.GetByteCount(ch.ToString());
            if (bytes + b + 3 > maxBytes) break;   // 留 3 字节给 “…”
            sb.Append(ch);
            bytes += b;
        }
        sb.Append('…');
        return sb.ToString();
    }

    /// <summary>估算显示宽度：CJK/全角算 2，其它算 1（用于行宽控制，不是精确像素）。</summary>
    public static int DisplayWidth(string? text)
    {
        if (string.IsNullOrEmpty(text)) return 0;
        int w = 0;
        foreach (char ch in text)
        {
            if (ch == '\t') { w += 4; continue; }
            uint c = ch;
            w += (c >= 0x1100 && (c <= 0x115F || c == 0x2329 || c == 0x232A ||
                                  (c >= 0x2E80 && c <= 0xA4CF) ||
                                  (c >= 0xAC00 && c <= 0xD7A3) ||
                                  (c >= 0xF900 && c <= 0xFAFF) ||
                                  (c >= 0xFE30 && c <= 0xFE4F) ||
                                  (c >= 0xFF00 && c <= 0xFF60) ||
                                  (c >= 0xFFE0 && c <= 0xFFE6))) ? 2 : 1;
        }
        return w;
    }

    /// <summary>
    /// 面板单行整形：去掉换行/控制字符，按显示宽度 + UTF-8 字节双上限截断，末尾补 “…”；
    /// 返回的字符串一定 &lt; <see cref="LineTextBytes"/> 字节（可安全放进 text[240]）。
    /// </summary>
    public static string FitLine(string? text, int maxColumns = 48)
    {
        string s = (text ?? "").Replace("\r", " ").Replace("\n", " ").Trim();
        var sb = new StringBuilder();
        int cols = 0;
        const int maxBytes = LineTextBytes - 1;   // 留 NUL
        foreach (char ch in s)
        {
            if (char.IsControl(ch)) continue;
            int w = DisplayWidth(ch.ToString());
            int b = Encoding.UTF8.GetByteCount(ch.ToString());
            if (cols + w > maxColumns || Encoding.UTF8.GetByteCount(sb.ToString()) + b + 3 > maxBytes)
            {
                sb.Append('…');
                break;
            }
            sb.Append(ch);
            cols += w;
        }
        string result = sb.ToString();
        // 双保险：极端情况下再按纯字节截一次。
        while (Encoding.UTF8.GetByteCount(result) > maxBytes && result.Length > 0)
            result = result[..^1];
        return result;
    }

    /// <summary>组一块“显示面板”。行数超上限会截断；空文本用单个空格占位。</summary>
    public static byte[] BuildPanelBlock(
        int seq, IReadOnlyList<PanelLine>? lines, uint ttlMs, uint anchor,
        float x, float y, float lineHeight, float fontHeight, string? fontName,
        bool background = true, bool startCollapsed = false, int collapsedLines = 3)
    {
        var buf = new byte[PanelBlockSize];
        int count = lines?.Count ?? 0;
        if (count < 1) count = 1;
        if (count > MaxLines) count = MaxLines;
        int cl = Math.Clamp(collapsedLines, 1, 3);

        uint flags = FlagShow;
        if (background) flags |= FlagBackground;
        if (startCollapsed) flags |= FlagStartCollapsed;
        flags |= ((uint)cl & CollapsedLinesMask) << CollapsedLinesShift;

        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetSeq), unchecked((uint)seq));
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetAppliedSeq), 0);
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetFlags), flags);
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetTtlMs), ttlMs);
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetLineCount), (uint)count);
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetAnchor), anchor);
        BinaryPrimitives.WriteSingleLittleEndian(buf.AsSpan(OffsetX), x);
        BinaryPrimitives.WriteSingleLittleEndian(buf.AsSpan(OffsetY), y);
        BinaryPrimitives.WriteSingleLittleEndian(buf.AsSpan(OffsetLineHeight), lineHeight);
        BinaryPrimitives.WriteSingleLittleEndian(buf.AsSpan(OffsetFontHeight), fontHeight);
        WriteUtf8Z(buf, OffsetFontName, FontNameBytes, string.IsNullOrWhiteSpace(fontName) ? "MasterFont" : fontName, FontNameBytes - 1);

        for (int i = 0; i < count; i++)
        {
            int lineOff = OffsetLines + i * LineStride;
            PanelLine line = i < (lines?.Count ?? 0) ? lines![i] : new PanelLine(0xFFFFFFFFu, " ");
            BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(lineOff + LineOffsetColor), line.Color);
            string text = FitLine(line.Text);
            if (text.Length == 0) text = " ";
            WriteUtf8Z(buf, lineOff + LineOffsetText, LineTextBytes, text, LineTextBytes - 1);
        }
        return buf;
    }

    /// <summary>组一块 v17 头像块：lineIndex + rawcode，最多 4 项。</summary>
    public static byte[] BuildIconBlock(int seq, IReadOnlyList<InGamePanel.PanelIcon>? icons)
    {
        var buf = new byte[IconBlockSize];
        int count = icons?.Count ?? 0;
        if (count > MaxIcons) count = MaxIcons;
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetIconSeq), unchecked((uint)seq));
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetIconAppliedSeq), 0);
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetIconCount), (uint)count);
        for (int i = 0; i < count; i++)
        {
            int off = OffsetIconSlots + i * IconSlotStride;
            int lineIndex = Math.Clamp(icons![i].LineIndex, 0, MaxLines - 1);
            BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(off + IconSlotLineIndex), (uint)lineIndex);
            BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(off + IconSlotRawCode), icons[i].RawCode);
            BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(off + IconSlotSourceAddr), icons[i].SourceAddr);
        }
        return buf;
    }

    /// <summary>
    /// 组一块“承伤图表请求”（v24 flags bit4）：不发文本行，lines 区前 8 字节换成
    /// <c>ChartReq { magic='CHT1'; victim; }</c>；5 秒分桶/四类归类/来源分段由 ddh 从自己的
    /// 事件环算，C# 只负责告诉它“谁的死亡”。
    /// </summary>
    public static byte[] BuildChartBlock(
        int seq, uint victimAddr, uint ttlMs, uint anchor, float x, float y,
        string? fontName, bool background = true)
    {
        var buf = new byte[PanelBlockSize];
        uint flags = FlagShow | FlagChart;
        if (background) flags |= FlagBackground;

        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetSeq), unchecked((uint)seq));
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetAppliedSeq), 0);
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetFlags), flags);
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetTtlMs), ttlMs);
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetLineCount), 0);
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetAnchor), anchor);
        BinaryPrimitives.WriteSingleLittleEndian(buf.AsSpan(OffsetX), x);
        BinaryPrimitives.WriteSingleLittleEndian(buf.AsSpan(OffsetY), y);
        BinaryPrimitives.WriteSingleLittleEndian(buf.AsSpan(OffsetLineHeight), 0.0175f);
        BinaryPrimitives.WriteSingleLittleEndian(buf.AsSpan(OffsetFontHeight), 0.0135f);
        WriteUtf8Z(buf, OffsetFontName, FontNameBytes,
                   string.IsNullOrWhiteSpace(fontName) ? "MasterFont" : fontName, FontNameBytes - 1);

        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetChartMagic), ChartMagic);
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetChartVictim), victimAddr);
        return buf;
    }

    /// <summary>组一块“隐藏面板”（只写 seq/flags，文本不读）。</summary>
    public static byte[] BuildHidePanelBlock(int seq)
    {
        var buf = new byte[PanelBlockSize];
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetSeq), unchecked((uint)seq));
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetFlags), FlagHide);
        return buf;
    }

    /// <summary>组一块英雄查询请求（最多 16 项；rawcode 用 <see cref="ToJassRawCode"/>）。</summary>
    public static byte[] BuildHeroRequestBlock(int seq, IReadOnlyList<(uint Addr, uint RawCode)>? items)
    {
        var buf = new byte[HeroBlockSize];
        int count = items?.Count ?? 0;
        if (count > HeroSlots) count = HeroSlots;
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetHeroSeq), unchecked((uint)seq));
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetHeroAppliedSeq), 0);
        BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(OffsetHeroCount), (uint)count);
        for (int i = 0; i < count; i++)
        {
            int off = OffsetHeroReq + i * HeroReqStride;
            BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(off), items![i].Addr);
            BinaryPrimitives.WriteUInt32LittleEndian(buf.AsSpan(off + 4), items[i].RawCode);
        }
        return buf;
    }

    /// <summary>从一个完整的 HeroBlock 里取回结果（按 addr/rawcode 匹配；isHero = 1/0/-1）。</summary>
    public static List<(uint Addr, uint RawCode, int IsHero, int IsIllusion)> ParseHeroResults(ReadOnlySpan<byte> block)
    {
        var list = new List<(uint, uint, int, int)>(HeroSlots);
        if (block.Length < HeroBlockSize) return list;
        int count = (int)BinaryPrimitives.ReadUInt32LittleEndian(block[OffsetHeroCount..]);
        if (count < 0) count = 0;
        if (count > HeroSlots) count = HeroSlots;
        for (int i = 0; i < count; i++)
        {
            int off = OffsetHeroRes + i * HeroResStride;
            uint addr = BinaryPrimitives.ReadUInt32LittleEndian(block[off..]);
            uint raw = BinaryPrimitives.ReadUInt32LittleEndian(block[(off + 4)..]);
            int isHero = BinaryPrimitives.ReadInt32LittleEndian(block[(off + 8)..]);
            int isIllusion = BinaryPrimitives.ReadInt32LittleEndian(block[(off + 12)..]);
            list.Add((addr, raw, isHero, isIllusion));
        }
        return list;
    }

    private static void WriteUtf8Z(byte[] buf, int offset, int capacity, string text, int maxBytes)
    {
        string fit = TruncateUtf8(text, Math.Min(maxBytes, capacity - 1));
        byte[] bytes = Encoding.UTF8.GetBytes(fit);
        int n = Math.Min(bytes.Length, capacity - 1);
        Array.Copy(bytes, 0, buf, offset, n);
        buf[offset + n] = 0;
    }
}

