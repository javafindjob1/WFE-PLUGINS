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
    public string OwnerText => OwnerSlot >= 0 ? "玩家 " + (OwnerSlot + 1) : "?（没读到拥有者）";
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
    public static bool LooksLikeGame(string processName)
    {
        if (string.IsNullOrWhiteSpace(processName)) return false;
        string n = processName.ToLowerInvariant();
        return n.Contains("war3") || n.Contains("warcraft") || n.Contains("frozen") ||
               n.Contains("dzwar") || n == "game" || processName.Contains('魔');
    }
}
