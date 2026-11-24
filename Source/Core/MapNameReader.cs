using System.Diagnostics;

namespace War3DeathSettlement.Core;

/// <summary>
/// 从游戏进程里读“当前地图名”。
///
/// 1.27 的 <c>SetMapName</c> native（game.dll RVA 0x1F5F20）是：
///   <code>ctx = [game.dll + 0xBE4238]</code>（即 <see cref="Wc3Game.Ctx"/>）
///   <code>mapInfo = [ctx + 0x30]</code>
///   <code>CString mapName = mapInfo + 0x04</code>
/// CString 是暴雪自己的引用计数字符串：<c>[CString + 8]</c> = 数据块，数据块 <c>+8</c> = 字符。
/// 这里按这个链去读；同时兼容几种相邻布局（字符在数据块 +0/+4/+8/+12），
/// 只接受“像地图名”的字符串（可打印、2~80 字、无控制字符/乱码），读不到就返回空串。
///
/// 读不到时退回游戏窗口标题：只有标题不是“Warcraft III / 魔兽争霸”本身时才用。
/// </summary>
public static class MapNameReader
{
    private const uint CtxMapInfoOffset = 0x30;   // SetMapName：mov ecx,[esi+0x30]
    private const uint MapNameFieldOffset = 0x04; // SetMapName：add ecx,4

    /// <summary>返回当前地图名；读不到返回 ""（界面显示“—”）。</summary>
    public static string TryRead(Wc3Game game)
    {
        string name = TryReadFromMemory(game);
        if (name.Length > 0) return name;
        return TryReadFromWindowTitle(game);
    }

    private static string TryReadFromMemory(Wc3Game game)
    {
        try
        {
            uint ctx = game.Ctx;
            if (ctx == 0) return "";
            var mem = game.Mem;
            if (!mem.ReadU32((ulong)ctx + CtxMapInfoOffset, out uint mapInfo) || mapInfo == 0) return "";
            ulong cstr = (ulong)mapInfo + MapNameFieldOffset;
            if (!mem.IsReadable(cstr, 0x10)) return "";

            // CString: [+8] → 数据块；数据块 +0x1C → 字符指针
            // （game.dll 的 CString::GetString：mov eax,[ecx+8]; mov eax,[eax+0x1C]）。
            // 再兼容几种旧布局作兜底，第一个通过校验的胜出。
            if (mem.ReadU32(cstr + 8, out uint data) && data != 0)
            {
                if (mem.ReadU32((ulong)data + 0x1C, out uint chars) && chars != 0)
                {
                    string s = ReadAt(mem, chars);
                    if (s.Length > 0) return s;
                }
                foreach (uint charOffset in new uint[] { 8, 0, 4, 12 })
                {
                    string s = ReadAt(mem, (ulong)data + charOffset);
                    if (s.Length > 0) return s;
                }
            }

            foreach (uint fieldOffset in new uint[] { 0, 4 })
            {
                if (!mem.ReadU32(cstr + fieldOffset, out uint other) || other == 0) continue;
                if (mem.ReadU32((ulong)other + 0x1C, out uint chars2) && chars2 != 0)
                {
                    string s = ReadAt(mem, chars2);
                    if (s.Length > 0) return s;
                }
            }
        }
        catch { }
        return "";
    }

    private static string ReadAt(RemoteProcess mem, ulong addr)
    {
        if (!mem.IsReadable(addr, 4)) return "";
        var buf = new byte[260];
        int got = mem.ReadBytes(addr, buf, 0, buf.Length);
        if (got < 2) return "";

        int len = Array.IndexOf(buf, (byte)0, 0, got);
        if (len < 0) len = got;
        if (len < 2) return "";

        // 只接受可打印字节（UTF-8 中文的高字节也算可见）。
        for (int i = 0; i < len; i++)
        {
            byte b = buf[i];
            if (b < 0x20 && b != (byte)'\t') return "";
            if (b == 0x7F) return "";
        }

        string s = Gbk.DecodeName(buf, 0, len);
        s = Wc3Text.Clean(s).Trim();
        if (!LooksLikeMapName(s)) return "";
        return s;
    }

    /// <summary>过滤掉明显不是地图名的字符串（源码文件名、乱码、控制字符等）。</summary>
    public static bool LooksLikeMapName(string s)
    {
        if (string.IsNullOrWhiteSpace(s)) return false;
        s = s.Trim();
        if (s.Length is < 2 or > 80) return false;
        if (s.Contains('\uFFFD')) return false;
        if (s.EndsWith(".cpp", StringComparison.OrdinalIgnoreCase) ||
            s.EndsWith(".hpp", StringComparison.OrdinalIgnoreCase) ||
            s.EndsWith(".h", StringComparison.OrdinalIgnoreCase) ||
            s.EndsWith(".c", StringComparison.OrdinalIgnoreCase) ||
            s.EndsWith(".obj", StringComparison.OrdinalIgnoreCase))
            return false;
        foreach (char c in s)
            if (char.IsControl(c)) return false;
        return true;
    }

    /// <summary>窗口标题兜底：只去掉“Warcraft III / 魔兽争霸”前缀，剩下的才当地图名。</summary>
    private static string TryReadFromWindowTitle(Wc3Game game)
    {
        try
        {
            using var p = Process.GetProcessById(game.Mem.Pid);
            string t = (p.MainWindowTitle ?? "").Trim();
            if (t.Length == 0) return "";

            const string en = "Warcraft III";
            if (t.StartsWith(en, StringComparison.OrdinalIgnoreCase))
                t = t[en.Length..].Trim(' ', '-', ':', '：');
            else
            {
                int dash = t.IndexOf('-');
                if (dash >= 0 && t[..dash].Contains("魔兽")) t = t[(dash + 1)..].Trim();
            }

            t = Wc3Text.Clean(t).Trim();
            if (t.Length is < 2 or > 80) return "";
            if (t.Contains("Frozen Throne", StringComparison.OrdinalIgnoreCase)) return "";
            if (t.Contains("Warcraft", StringComparison.OrdinalIgnoreCase)) return "";
            foreach (char c in t)
                if (char.IsControl(c)) return "";
            return t;
        }
        catch { return ""; }
    }
}
