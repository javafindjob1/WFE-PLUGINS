using System.Runtime.InteropServices;
using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>
/// 游戏编码（GBK / 代码页 936）解码。
///
/// 为什么要自己写：**.NET 5+ 默认不带代码页 936**，`Encoding.GetEncoding(936)` 会抛
/// “No data is available for encoding 936”，而补这个能力要装 NuGet 包
/// `System.Text.Encoding.CodePages`（本机没外网，装不了）。
/// 于是直接调 Win32 `MultiByteToWideChar(936, ...)` —— 本机就是中文 Windows，一定可用，
/// 而且和游戏/插件的编码完全一致。
/// </summary>
internal static class Gbk
{
    private const uint CP_GBK = 936;

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern int MultiByteToWideChar(uint codePage, uint dwFlags,
        byte[] lpMultiByteStr, int cbMultiByte, [Out] char[]? lpWideCharStr, int cchWideChar);

    /// <summary>能不能用（非中文系统可能没有 936，那就退化成 Latin1，只影响中文显示）。</summary>
    public static bool Available { get; private set; } = true;

    public static string Decode(byte[] bytes, int offset, int count)
    {
        if (bytes == null || count <= 0) return "";
        if (offset < 0) offset = 0;
        if (offset + count > bytes.Length) count = bytes.Length - offset;
        if (count <= 0) return "";

        var slice = new byte[count];
        Buffer.BlockCopy(bytes, offset, slice, 0, count);

        if (Available)
        {
            try
            {
                int need = MultiByteToWideChar(CP_GBK, 0, slice, count, null, 0);
                if (need > 0)
                {
                    var chars = new char[need];
                    int got = MultiByteToWideChar(CP_GBK, 0, slice, count, chars, need);
                    if (got > 0) return new string(chars, 0, got);
                }
                Available = false;   // 第一次失败就不再试
            }
            catch { Available = false; }
        }

        return Encoding.Latin1.GetString(slice);
    }

    public static string Decode(byte[] bytes) => Decode(bytes, 0, bytes?.Length ?? 0);

    /// <summary>
    /// 名字解码（统一入口）。引擎 0x326BA0 拿到的名字正文是 **UTF-8**（真机截图里的乱码
    /// 就是 UTF-8 字节被按 GBK 解了，或者名字字段把汉字截成了半个），老版本/某些路径可能
    /// 还是 GBK。做法是**三个候选打分**，不再“严格 UTF-8 一失败就 GBK”：
    ///   1) 严格 UTF-8（合法就直接用，引擎名字本来就是 UTF-8）；
    ///   2) UTF-8 替换解码（非法处变 U+FFFD，统计坏字符）；
    ///   3) GBK 解码（统计 U+FFFD / 控制字符 / 明显像错解的符号）。
    /// 选坏字符最少的；**坏字符一样多时优先 UTF-8**（截断的 UTF-8 通常只坏末尾 1 个字节，
    /// 而 GBK 会把同一段字节解成一片“合法但不像名字”的汉字+€ 之类的符号）。
    /// 最后统一走 CleanName（去掉 U+FFFD、Trim、全控制字符 → 空串）。
    /// </summary>
    public static string DecodeName(byte[] bytes, int offset, int count)
    {
        if (bytes == null || count <= 0) return "";
        if (offset < 0) offset = 0;
        if (offset + count > bytes.Length) count = bytes.Length - offset;
        if (count <= 0) return "";

        var slice = new byte[count];
        Buffer.BlockCopy(bytes, offset, slice, 0, count);

        // 1) 严格 UTF-8：UTF8Encoding(false, true) 遇到非法序列直接抛异常，不会产出 U+FFFD，
        //    所以“抛异常 = 不是 UTF-8”，干净利落。
        try
        {
            string s = CleanName(Utf8Strict.GetString(slice));
            if (s.Length > 0) return s;
        }
        catch (DecoderFallbackException) { }
        catch (ArgumentException) { }

        // 2) 宽容 UTF-8：非法字节变 U+FFFD，保留已经解出来的完整汉字。
        string utf8Loose = Utf8Loose.GetString(slice);

        // 2.5) 典型的“名字字段被截断”：整段只有末尾 1~3 字节是半个 UTF-8 汉字，
        //      前面全是合法 UTF-8。这种情况直接按 UTF-8 替换解码，不参与 GBK 打分 ——
        //      否则 CP936 可能把末尾那 2 个字节拼成一个“合法”汉字，坏字符数为 0，
        //      反而把截断的 UTF-8 误判成 GBK（旧的 32 字节字段就是这样出乱码的）。
        if (IsUtf8TruncatedAtEnd(slice))
            return CleanName(utf8Loose);

        // 3) GBK（Decode 内部已含 GBK→Latin1 的降级）。
        string gbk = Decode(slice);

        int badUtf8 = CountBad(utf8Loose);
        int badGbk = CountBad(gbk);

        // 坏字符一样多 → 优先 UTF-8（<= 而不是 <）。
        string chosen = badUtf8 <= badGbk ? utf8Loose : gbk;
        return CleanName(chosen);
    }

    public static string DecodeName(byte[] bytes) => DecodeName(bytes, 0, bytes?.Length ?? 0);

    /// <summary>严格 UTF-8（非法抛异常）与宽容 UTF-8（非法处替换成 U+FFFD）的共用实例。</summary>
    private static readonly UTF8Encoding Utf8Strict = new(false, true);
    private static readonly UTF8Encoding Utf8Loose = new(false, false);

    /// <summary>
    /// 这段字节是不是“合法 UTF-8 前缀 + 末尾半个字符”（名字字段被硬截断的典型形态）。
    /// 只认末尾 1~3 个续字节、且前面每一段都完整；不是这种形态就返回 false，交给打分。
    /// </summary>
    private static bool IsUtf8TruncatedAtEnd(byte[] b)
    {
        int i = 0;
        while (i < b.Length)
        {
            byte c = b[i];
            if (c < 0x80) { i++; continue; }

            int need;
            if ((c & 0xE0) == 0xC0) need = 1;        // 2 字节
            else if ((c & 0xF0) == 0xE0) need = 2;   // 3 字节
            else if ((c & 0xF8) == 0xF0) need = 3;   // 4 字节
            else return false;

            if (i + need >= b.Length)
            {
                // 末尾不够一个完整字符：剩下的必须全是续字节（0 个也算，比如只截到首字节）。
                for (int k = i + 1; k < b.Length; k++)
                    if ((b[k] & 0xC0) != 0x80) return false;
                return true;
            }
            for (int k = 1; k <= need; k++)
                if ((b[i + k] & 0xC0) != 0x80) return false;
            i += need + 1;
        }
        return false;
    }

    /// <summary>
    /// 数一个候选里有多少“坏字符”：
    ///   · U+FFFD 替换符；
    ///   · 控制字符（换行/Tab 之外的不可打印字符）；
    ///   · 明显像“GBK 错解”的符号（货币符号、箭头、制表符、几何图形、私用区等）。
    /// 单位名正常只会有中文/英文/数字/常见标点；这些符号落进来基本就是解错了。
    /// </summary>
    private static int CountBad(string s)
    {
        int bad = 0;
        foreach (char c in s)
        {
            if (c == '\uFFFD' || char.IsControl(c) || LooksLikeMisdecode(c)) bad++;
        }
        return bad;
    }

    private static bool LooksLikeMisdecode(char c) =>
        (c >= '\u20A0' && c <= '\u20CF') ||   // 货币符号（CP936 把 0x80 解成 €）
        (c >= '\u2100' && c <= '\u214F') ||   // 类字母符号
        (c >= '\u2190' && c <= '\u21FF') ||   // 箭头
        (c >= '\u2500' && c <= '\u257F') ||   // 制表符
        (c >= '\u25A0' && c <= '\u25FF') ||   // 几何图形
        (c >= '\u2600' && c <= '\u27BF') ||   // 杂项符号/装饰
        (c >= '\uE000' && c <= '\uF8FF') ||   // 私用区
        char.IsSurrogate(c);

    private static string CleanName(string s)
    {
        if (string.IsNullOrEmpty(s)) return "";
        // 截断的 UTF-8 会在末尾留一个 U+FFFD；前面的完整汉字是好的，去掉替换符而不是整串丢弃。
        s = s.Replace("\uFFFD", "").Trim();
        if (s.Length == 0) return "";
        bool anyVisible = false;
        foreach (char c in s)
            if (!char.IsControl(c)) { anyVisible = true; break; }
        return anyVisible ? s : "";
    }

    /// <summary>GBK 编码（写回配置之类用不到，保留给自检/以后用）。</summary>
    public static byte[] Encode(string text)
    {
        if (string.IsNullOrEmpty(text)) return Array.Empty<byte>();
        foreach (var enc in new[] { "GBK", "gb2312", "GB18030" })
        {
            try { return Encoding.GetEncoding(enc).GetBytes(text); } catch { }
        }
        return Encoding.Latin1.GetBytes(text);
    }
}
