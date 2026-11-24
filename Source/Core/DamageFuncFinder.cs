using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>
/// 在**运行中**的 game.dll 里定位引擎伤害函数。
///
/// 为什么不能写死 RVA：本仓库核对 0x67DC40 用的是磁盘上那份 13,187,048 字节的 Game.dll；
/// 但实机（平台联机/观战）加载的模块是 **13,467,648 字节**（`大小 13152KB`）——
/// 平台在内存里改过镜像，RVA 可能整体偏移，写死就会挂错地方。
///
/// 特征（来自 `WFE伤害机制分析.md` §3.2/§3.5，已在 1.27.0.52240 上验证过）：
///   * 函数开头：`55 8B EC 83 EC 2C 56 57 8B F9`
///     （push ebp; mov ebp,esp; sub esp,0x2C; push esi; push edi; mov edi,ecx）
///   * 函数体内 ~0x200 字节内**同时**出现两个立即数：`0x04000000` 和 `0x00400000`
///     （伤害类型掩码分支的 4 个魔法值里的两个，唯一性很高）
/// 两个条件同时满足才算，误报率很低。
/// </summary>
public static class DamageFuncFinder
{
    /// <summary>已知的 1.27.0.52240（磁盘版）RVA，先试它。</summary>
    public const uint KnownRva = 0x67DC40;

    private static readonly byte[] Prologue =
        { 0x55, 0x8B, 0xEC, 0x83, 0xEC, 0x2C, 0x56, 0x57, 0x8B, 0xF9 };

    /// <summary>候选伤害函数的 RVA 列表（第一个通常就是对的那个）。</summary>
    public static List<uint> Candidates(Wc3Game g, int max = 8, int window = 0x300)
    {
        var found = new List<uint>();
        if (g.GameDllBase == 0 || g.GameDllImageSize == 0) return found;

        // 先看写死的那个 RVA 对不对（开头字节一致就优先返回它）
        var head = g.Mem.ReadBytes(g.GameDllBase + KnownRva, Prologue.Length);
        if (head != null && head.Length == Prologue.Length && Matches(head, 0))
        {
            found.Add(KnownRva);
            return found;
        }

        ulong size = Math.Min(g.GameDllImageSize, 0x0200_0000UL);
        const int Chunk = 1 << 20;
        for (ulong off = 0; off < size; off += Chunk)
        {
            int len = (int)Math.Min((ulong)Chunk, size - off);
            var buf = g.Mem.ReadBytes(g.GameDllBase + off, len);
            if (buf == null || buf.Length < Prologue.Length + window) continue;

            for (int i = 0; i + Prologue.Length + 8 < buf.Length; i++)
            {
                if (!Matches(buf, i)) continue;
                if (!HasImm(buf, i, window, 0x04000000)) continue;
                if (!HasImm(buf, i, window, 0x00400000)) continue;
                uint rva = (uint)(off + (ulong)i);
                if (!found.Contains(rva)) found.Add(rva);
                if (found.Count >= max) return found;
            }
        }
        return found;
    }

    private static bool Matches(byte[] buf, int at)
    {
        for (int k = 0; k < Prologue.Length; k++)
            if (buf[at + k] != Prologue[k]) return false;
        return true;
    }

    /// <summary>窗口内是否出现某个 4 字节立即数（小端原始字节）。</summary>
    private static bool HasImm(byte[] buf, int at, int window, uint imm)
    {
        byte b0 = (byte)(imm & 0xFF), b1 = (byte)((imm >> 8) & 0xFF),
             b2 = (byte)((imm >> 16) & 0xFF), b3 = (byte)((imm >> 24) & 0xFF);
        int end = Math.Min(buf.Length - 4, at + window);
        for (int i = at; i < end; i++)
            if (buf[i] == b0 && buf[i + 1] == b1 && buf[i + 2] == b2 && buf[i + 3] == b3)
                return true;
        return false;
    }

    /// <summary>给诊断报告用的一段说明。</summary>
    public static string Describe(Wc3Game g)
    {
        var sb = new StringBuilder();
        var cands = Candidates(g);
        sb.AppendLine($"  已知 RVA 0x{KnownRva:X} 处的开头字节：" +
                      (g.Mem.ReadBytes(g.GameDllBase + KnownRva, 10) is { Length: 10 } h
                          ? string.Join(" ", h.Select(b => b.ToString("X2")))
                          : "读不到"));
        if (cands.Count == 0)
        {
            sb.AppendLine("  ⇒ 按特征扫不到伤害函数（可能这个构建改得更彻底）。");
        }
        else
        {
            sb.AppendLine($"  ⇒ 找到 {cands.Count} 个候选（伤害函数通常是最小 RVA 那个）：");
            foreach (var r in cands.Take(6))
                sb.AppendLine($"     RVA 0x{r:X}　（game.dll+0x{r:X} = 0x{g.GameDllBase + r:X8}）");
        }
        return sb.ToString();
    }
}
