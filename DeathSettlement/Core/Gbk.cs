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
