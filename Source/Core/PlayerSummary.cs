using System.Runtime.InteropServices;

namespace War3DeathSettlement.Core;

/// <summary>按玩家汇总的一行。</summary>
public sealed record PlayerSummaryRow(
    int OwnerSlot,
    int Settlements,
    int Deaths,
    int Gone,
    double TotalDamage,
    double AvgPerSettlement,
    double WorstPeak1s,
    double MaxHit,
    int KindCount,
    DateTime LastDiedAt)
{
    public string OwnerText => UnitEvents.FormatPlayer(OwnerSlot);
}

/// <summary>
/// “按玩家统计”的汇总逻辑（纯函数，放在 Core 里是为了能离线自检；
/// 界面只负责把结果画到表格里）。
/// </summary>
public static class PlayerSummary
{
    public static List<PlayerSummaryRow> Build(IEnumerable<Settlement> settlements)
    {
        var agg = new Dictionary<int, Acc>();
        foreach (var s in settlements)
        {
            if (!agg.TryGetValue(s.OwnerSlot, out var a)) agg[s.OwnerSlot] = a = new Acc();
            a.Settlements++;
            if (s.Kind == "死亡") a.Deaths++; else a.Gone++;
            a.Total += s.TotalDamage;
            if (s.Peak1s > a.WorstPeak) a.WorstPeak = s.Peak1s;
            if (s.MaxHit > a.MaxHit) a.MaxHit = s.MaxHit;
            a.Kinds.Add(s.TypeCode);
            if (s.DiedAt > a.Last) a.Last = s.DiedAt;
        }

        return agg
            .OrderByDescending(kv => kv.Value.Total)
            .ThenBy(kv => kv.Key)
            .Select(kv => new PlayerSummaryRow(
                kv.Key,
                kv.Value.Settlements,
                kv.Value.Deaths,
                kv.Value.Gone,
                kv.Value.Total,
                kv.Value.Settlements > 0 ? kv.Value.Total / kv.Value.Settlements : 0,
                kv.Value.WorstPeak,
                kv.Value.MaxHit,
                kv.Value.Kinds.Count,
                kv.Value.Last))
            .ToList();
    }

    private sealed class Acc
    {
        public int Settlements, Deaths, Gone;
        public double Total, WorstPeak, MaxHit;
        public readonly HashSet<string> Kinds = new(StringComparer.Ordinal);
        public DateTime Last;
    }
}

/// <summary>
/// 进程名匹配规则（“像不像魔兽”）。抽出来是为了能自检：
/// 平台的魔兽进程名五花八门，但也不该把记事本当成游戏列出来。
/// </summary>
public static class ProcessMatch
{
    /// <summary>
    /// 名字属于"本程序 / 同族工具"而不是游戏。
    /// <para>
    /// 它们的名字里也带 <c>war3</c>（War3DeathSettlement、War3Trainer），
    /// 光靠 <see cref="LooksLikeGame"/> 的子串规则会被当成游戏；更糟的是本程序窗口标题里
    /// 还有"魔兽"二字，连 <see cref="LooksLikeGameTitle"/> 也会命中 —— 结果就是启动时
    /// 把自己的 PID 报成"找不到 game.dll 模块（可能不是魔兽进程）"。
    /// </para>
    /// </summary>
    public static bool IsOwnTool(string? processName)
    {
        if (string.IsNullOrWhiteSpace(processName)) return false;
        string n = processName.ToLowerInvariant();
        return n.Contains("deathsettlement") || n.Contains("war3trainer");
    }

    public static bool LooksLikeGame(string processName)
    {
        if (string.IsNullOrWhiteSpace(processName)) return false;
        if (IsOwnTool(processName)) return false;
        string n = processName.ToLowerInvariant();
        return n.Contains("war3") || n.Contains("warcraft") || n.Contains("frozen") ||
               n.Contains("dzwar") || n == "game" || processName.Contains('魔');
    }

    /// <summary>主窗口标题像魔兽（平台版魔兽的进程名可能不相干，但窗口标题藏不住）。</summary>
    public static bool LooksLikeGameTitle(string? title)
    {
        if (string.IsNullOrWhiteSpace(title)) return false;
        return title.Contains("Warcraft III", StringComparison.OrdinalIgnoreCase) ||
               title.Contains("Frozen Throne", StringComparison.OrdinalIgnoreCase) ||
               // 只认"魔兽争霸"，不认单独的"魔兽"：
               // 实测踩过 —— 记事本打开 魔兽启动器\...\dss.log 时，标题里带"魔兽"，
               // 整个编辑器就被当成游戏候选了。
               title.Contains("魔兽争霸");
    }

    /// <summary>路径（game.dll 或主模块路径）像魔兽：用来把“加载了 game.dll 且路径像魔兽”的候选排最前。</summary>
    public static bool LooksLikeGamePath(string? path)
    {
        if (string.IsNullOrWhiteSpace(path)) return false;
        return path.Contains("Warcraft III", StringComparison.OrdinalIgnoreCase) ||
               path.Contains("Frozen Throne", StringComparison.OrdinalIgnoreCase) ||
               path.Contains("魔兽");
    }

    /// <summary>版本串是否落在 1.24~1.27（本项目实测支持的稳定区间）。</summary>
    public static bool IsSupportedVersionRange(string? version)
    {
        if (string.IsNullOrWhiteSpace(version)) return false;
        string n = Wc3Versions.Normalize(version);
        string[] parts = n.Split('.');
        if (parts.Length < 2 || !int.TryParse(parts[0], out int maj) || !int.TryParse(parts[1], out int min))
            return false;
        int v = maj * 1000 + min;
        return v >= 1024 && v <= 1027;
    }

    /// <summary>这个进程是否加载了 game.dll（用 Toolhelp32 枚举模块）。</summary>
    public static bool LoadsGameDll(int pid) => TryGetGameDll(pid, out _);

    /// <summary>
    /// 用 Toolhelp32 枚举目标进程的模块，找 game.dll。
    /// 拿不到模块列表（权限不足 / 进程已退出）时返回 false，绝不抛异常 —— 调用方据此跳过。
    /// </summary>
    public static bool TryGetGameDll(int pid, out string path)
    {
        path = "";
        IntPtr snap = Native.CreateToolhelp32Snapshot(Native.TH32CS_SNAPMODULE | Native.TH32CS_SNAPMODULE32, (uint)pid);
        if (snap == IntPtr.Zero || snap == new IntPtr(-1)) return false;
        try
        {
            var me = new Native.MODULEENTRY32W { dwSize = (uint)Marshal.SizeOf<Native.MODULEENTRY32W>() };
            if (!Native.Module32FirstW(snap, ref me)) return false;
            do
            {
                if (string.Equals(me.szModule, "game.dll", StringComparison.OrdinalIgnoreCase))
                {
                    path = me.szExePath ?? "";
                    return true;
                }
                me.dwSize = (uint)Marshal.SizeOf<Native.MODULEENTRY32W>();
            } while (Native.Module32NextW(snap, ref me));
        }
        finally { Native.CloseHandle(snap); }
        return false;
    }

    /// <summary>
    /// 候选评分（纯函数，可自检）：越小越优先；-1 = 不是候选。
    /// 任一名中即保留：加载 game.dll 且路径像 &gt; 加载 game.dll &gt; 进程名像 &gt; 窗口标题像。
    /// 进程名读不到传空串、模块/标题读不到传 false —— 都不影响“保留 PID 用于匹配”。
    /// </summary>
    public static int ScoreCandidate(string? processName, bool loadsDll, bool pathLike, bool titleMatch,
        ISet<string>? extraNames = null)
    {
        string name = processName ?? "";
        bool nameMatch = LooksLikeGame(name) || (extraNames != null && extraNames.Contains(name));
        if (loadsDll && pathLike) return 0;
        if (loadsDll) return 1;
        if (nameMatch) return 2;
        if (titleMatch) return 3;
        return -1;
    }
}
