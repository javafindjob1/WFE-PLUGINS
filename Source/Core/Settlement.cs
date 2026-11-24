using System.Globalization;
using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>一次“掉血”记录（由两次轮询的生命差得到）。</summary>
public sealed class DamageEvent
{
    public DateTime Time { get; init; }
    public double Amount { get; init; }
    public double HpAfter { get; init; }
    public bool Fatal { get; init; }
}

/// <summary>一个单位实例的生命周期账本。</summary>
public sealed class UnitTrack
{
    public uint Addr { get; set; }
    /// <summary>生命对象索引 —— 它才是“这个单位是谁”的稳定身份（地址可能会变）。</summary>
    public uint HpIndex { get; set; }
    public string TypeCode { get; set; } = "";
    public int OwnerSlot { get; set; } = -1;

    public DateTime FirstSeen { get; set; }
    public DateTime LastSeen { get; set; }
    public float LastHp { get; set; }
    public float LastHpMax { get; set; }
    public float StartHpMax { get; set; }
    /// <summary>我们第一次看到它时的血量（用于说明“接管前的掉血没算进来”）。</summary>
    public float HpAtFirstSeen { get; set; }
    public float X { get; set; }
    public float Y { get; set; }

    public readonly List<DamageEvent> Events = new();
    public double TotalDamage { get; set; }
    public double TotalHeal { get; set; }
    public double MaxHit { get; set; }
    public double MinHit { get; set; } = double.MaxValue;
    public DateTime? FirstHit { get; set; }
    public DateTime? LastHit { get; set; }
    public bool Dead { get; set; }
    public bool Gone { get; set; }
    /// <summary>第几条命（ResetForNewInstance 里自增；第一条命 = 1）。</summary>
    public int InstanceIndex { get; set; }

    public TimeSpan CombatSpan => (FirstHit.HasValue && LastHit.HasValue) ? LastHit.Value - FirstHit.Value : TimeSpan.Zero;

    public void ResetForNewInstance(DateTime now, ScannedUnit u)
    {
        InstanceIndex++;
        Addr = u.Addr;
        HpIndex = u.HpIndex;
        TypeCode = u.TypeCode;
        OwnerSlot = u.OwnerSlot;
        FirstSeen = LastSeen = now;
        LastHp = u.Hp;
        LastHpMax = u.HpMax;
        StartHpMax = u.HpMax;
        HpAtFirstSeen = u.Hp;
        Events.Clear();
        TotalDamage = TotalHeal = MaxHit = 0;
        MinHit = double.MaxValue;
        FirstHit = LastHit = null;
        Dead = Gone = false;
    }
}

/// <summary>
/// 死亡结算：一个单位死亡（或消失）时，把它这一条命的受伤账一次性算清。
/// 口径与游戏内插件 UDamageWatcher 的“死亡结算”一致：次数 + 总伤害 + 单次统计 + 每秒受伤。
/// 差别：纯外部只读拿不到“伤害来源单位 / 攻击类型 / 伤害类型”，那三样需要游戏内钩子。
/// </summary>
public sealed class Settlement
{
    public uint Addr { get; init; }
    public string TypeCode { get; init; } = "";
    /// <summary>拥有者槽位（0 基）。结算生成后可能被钩子事件带回的 native 玩家号覆盖，因此需要可写。</summary>
    public int OwnerSlot { get; set; } = -1;
    public int InstanceIndex { get; init; } = 1;
    public DateTime DiedAt { get; init; }
    public DateTime FirstSeen { get; set; }
    public DateTime? FirstHit { get; init; }
    public DateTime? LastHit { get; init; }
    public int HitCount { get; set; }
    public double TotalDamage { get; set; }
    public double TotalHeal { get; init; }
    public double MaxHit { get; set; }
    public double MinHit { get; set; }
    public double HpMax { get; init; }
    /// <summary>本软件第一次看到它时的血量（&lt; HpMax 说明接管前的掉血没算进明细）。</summary>
    public float HpAtFirstSeen { get; init; }
    /// <summary>1 秒窗口内最大承伤（“最惨的一秒”）。</summary>
    public double Peak1s { get; set; }
    public float X { get; init; }
    public float Y { get; init; }
    /// <summary>死亡 = 血量归零；消失 = 单位被销毁/移出游戏（读不到生命）。</summary>
    public string Kind { get; set; } = "死亡";
    public IReadOnlyList<DamageEvent> Events { get; init; } = Array.Empty<DamageEvent>();

    /// <summary>
    /// 游戏内插件日志给出的“谁打的、什么攻击类型”（可选）。
    /// 插件没在跑、或没记录这个单位时是 null —— 那时只有本软件按血量差算出来的数字。
    /// </summary>
    public PluginAttribution? Attribution { get; set; }

    /// <summary>
    /// 侵入式钩子采到的「这条结算的分组伤害」（来源/是否攻击/是否远程/攻击类型/伤害类型）。
    /// 为 null 表示这次没有钩子数据（没开钩子，或者这条结算期间没采到事件）。
    /// </summary>
    public IReadOnlyList<HookBreakdown.Row>? HookRows { get; set; }

    /// <summary>【伤害构成】页用的**来源汇总**行（一行 = 一个伤害来源）。</summary>
    public IReadOnlyList<HookBreakdown.SourceRow>? HookSources { get; set; }

    /// <summary>【伤害构成】页用的组合行（来源 × 是否攻击 × 是否远程 × 攻击类型 × 伤害类型）。</summary>
    public IReadOnlyList<HookBreakdown.Combination>? HookCombos { get; set; }

    /// <summary>
    /// 致命一击的钩子事件（血从 &gt;0 到 ≤0 的最后一条）；游戏内阵亡面板用它显示
    /// “谁打死的、多少伤害、普攻/技能、攻击/伤害类型”。没有钩子数据时为 null。
    /// </summary>
    public DamageHook.HookEvent? FatalHookEvent { get; set; }

    /// <summary>折算系数：实际掉血 / 引擎伤害（用于"伤害 → 实际伤害"）。</summary>
    public double HookDamageScale { get; set; } = 1.0;

    /// <summary>钩子事件是怎么匹配到这条结算上的（精确 / 按类型码兜底）。</summary>
    public string HookMatchNote { get; set; } = "";

    /// <summary>
    /// 单位名（优先钩子事件带回来的名字，再退回插件日志的「类型码 → 名字」表；可能为空，界面层空则退显示类型码）。
    /// 写入时统一去掉 |cXXXXXX|r 样式码：名字要进表格/历史库/CSV，留着颜色码只会让界面变脏。
    /// </summary>
    public string UnitName
    {
        get => _unitName;
        set => _unitName = Wc3Text.Clean(value);
    }
    private string _unitName = "";

    // ---- 战斗中提前记录的“单位属性”（不是死亡/右键时才去读）----
    // 由 MonitorEngine 的处理伤害事件/扫描时持续累积，死亡结算时直接从缓存拷进来；
    // 单位死了以后内存读不到，但这里仍保留最后一次记录，右键属性表照样能显示。

    /// <summary>最后一次观测到的护甲（CUnit+0xE0，float；YDWE UNIT_STATE_ARMOR 位透传）；没读到过就是 NaN（属性表显示 ?）。</summary>
    public float Armor { get; set; } = float.NaN;

    /// <summary>本局观测到的普攻次数（该单位作为伤害来源且 IsAttack=1）。</summary>
    public int AttackHits { get; set; }

    /// <summary>普攻单次伤害的最小 / 最大 / 总和（用于属性表显示 最小~最大/均值）。</summary>
    public double AttackMin { get; set; }
    public double AttackMax { get; set; }
    public double AttackSum { get; set; }

    /// <summary>普攻间隔中位数（秒）；不足 2 个间隔时为 0（属性表显示 ?）。</summary>
    public double AttackInterval { get; set; }

    /// <summary>战斗中记录到的技能（外部只读模式目前只能从钩子 Flags 识别 Aloc/蝗虫）。</summary>
    public string Skills { get; set; } = "";

    /// <summary>
    /// 这条结算是“致命钩子事件补建”的（单位没被扫描到、账本里没有它）。
    /// 之后扫描账本如果补出同一次死亡，会优先用正常结算并删掉这条补建的。
    /// </summary>
    public bool SyntheticHookDeath { get; set; }

    /// <summary>列表里显示的伤害来源：钩子分组里的 [来源] 前两个，没有就空。</summary>
    public string HookSourceSummary
    {
        get
        {
            if (HookRows is not { Count: > 0 }) return "";
            var rows = HookRows.Where(r => r.Dimension == "钩子-来源").Take(2).ToList();
            return rows.Count == 0 ? "" : string.Join("、", rows.Select(r => $"{r.Key} {r.Percent:0.#}%"));
        }
    }

    /// <summary>“名字(码)”或只有“码”。</summary>
    public string DisplayName => UnitName.Length > 0 ? $"{UnitName}({TypeCode})" : TypeCode;

    public double LifetimeSeconds => Math.Max(0, (DiedAt - FirstSeen).TotalSeconds);
    public double CombatSeconds => (FirstHit.HasValue && LastHit.HasValue)
        ? Math.Max(0, (LastHit.Value - FirstHit.Value).TotalSeconds) : 0;
    public double AvgHit => HitCount > 0 ? TotalDamage / HitCount : 0;
    /// <summary>
    /// 秒伤。分母按“最少 1 秒”算：只挨了一刀就死的单位，战斗时长≈0，
    /// 直接相除会算出 8000 这种吓人的数字（看着像 bug）。
    /// </summary>
    public double DpsCombat => TotalDamage / Math.Max(1.0, CombatSeconds);
    public double MinHitSafe => HitCount > 0 && MinHit < double.MaxValue ? MinHit : 0;

    public string OwnerText => UnitEvents.FormatPlayer(OwnerSlot);

    /// <summary>标题行：`[结算] 类型码 死亡结算 N 次 / 总伤害`（对齐游戏内插件的中文样式）。</summary>
    public string TitleLine() =>
        $"[结算] {DisplayName} ({OwnerText}) {Kind}结算 {HitCount} 次 / {TotalDamage:0.00}";

    public IEnumerable<string> DetailLines()
    {
        if (UnitName.Length > 0) yield return $"  单位：{UnitName}（类型码 {TypeCode}）";
        yield return $"  存活 {LifetimeSeconds:0.0} 秒（首次发现 → {Kind}）" +
                     (CombatSeconds > 0 ? $"，战斗 {CombatSeconds:0.0} 秒（首次受击 → 最后一次受击）" : "");
        yield return $"  最大生命 {HpMax:0.#}，秒伤(战斗期，不足 1 秒按 1 秒计) {DpsCombat:0.00}";
        yield return $"  单次伤害：最大 {MaxHit:0.00} / 最小 {MinHitSafe:0.00} / 平均 {AvgHit:0.00}";
        yield return $"  最惨的 1 秒：{Peak1s:0.00}";
        if (HpAtFirstSeen < HpMax - 0.5)
            yield return $"  接管时血量 {HpAtFirstSeen:0.#}/{HpMax:0.#}（本软件接管前的掉血未计入上面的数字）";
        yield return $"  受击 {HitCount} 次，期间治疗 {TotalHeal:0.00}";
        if (Math.Abs(X) > 0.01f || Math.Abs(Y) > 0.01f)
            yield return $"  结算坐标 ({X:0.#}, {Y:0.#})";

        // ---- 侵入式钩子的分组（引擎真值：来源/是否攻击/是否远程/攻击类型/伤害类型）----
        if (HookRows is { Count: > 0 })
        {
            double rawTotal = HookRows.Where(r => r.Dimension == "钩子-是否攻击").Sum(r => r.Damage);
            yield return $"  伤害构成（引擎钩子口径，原始合计 {rawTotal:0.00}；" +
                         "原始伤害 = 结构体 +0x10 / 引擎伤害 = GetEventDamage 首值（第一次返回值） / 地图伤害 = 生效值（含末值；改过用改后，否则末值，抓不到退血差）/ 净掉血 = 血差 / 占比 = 净掉血 ÷ Σ净掉血（无血量数据时退回原始伤害）" +
                         (HookMatchNote.Length > 0 ? $"；{HookMatchNote}" : "") + "）：";
            foreach (var dim in new[] { "钩子-来源", "钩子-是否攻击", "钩子-是否远程", "钩子-攻击类型", "钩子-伤害类型" })
            {
                var rows = HookRows.Where(r => r.Dimension == dim).ToList();
                if (rows.Count == 0) continue;
                yield return $"    [{dim.Replace("钩子-", "")}] " + string.Join("；", rows.Select(r => r.ToString()));
            }
            var combos = HookRows.Where(r => r.Dimension == "钩子-组合").ToList();
            if (combos.Count > 0)
            {
                yield return "    [组合明细] 来源/攻击类型/伤害类型/是否攻击(0/1)/是否远程(0/1)：";
                foreach (var r in combos.Take(10)) yield return "      " + r;
            }
        }
        else
        {
            yield return "  伤害构成（引擎钩子）：这条结算没有钩子数据（钩子未开 / 这段没采到事件）";
        }

        // ---- 自己统计的分组（只用我们观测到的每一笔掉血，不需要插件）----
        var self = SelfBreakdown.ForSettlement(this);
        if (self.Count > 0)
        {
            yield return "  伤害构成（本软件自己统计，插件无关）：";
            foreach (var dim in new[] { "自己-单次伤害档位", "自己-受击秒" })
            {
                var rows = self.Where(r => r.Dimension == dim).ToList();
                if (rows.Count == 0) continue;
                yield return $"    [{dim.Replace("自己-", "")}] " + string.Join("；", rows.Select(r => r.ToString()));
            }
        }
    }

    public string ToText()
    {
        var sb = new StringBuilder();
        sb.AppendLine(TitleLine());
        foreach (var l in DetailLines()) sb.AppendLine(l);
        if (Events.Count > 0)
        {
            sb.AppendLine("  明细（时间 / 伤害 / 剩余生命）：");
            foreach (var e in Events)
                sb.AppendLine($"    {e.Time:HH:mm:ss.fff}  -{e.Amount:0.#}  剩 {e.HpAfter:0.#}{(e.Fatal ? "  ← 致命" : "")}");
        }
        return sb.ToString();
    }

    public static string CsvHeader =>
        "时间,单位名,类型码,拥有者,结局,实例,受击次数,总伤害,最大单次,最小单次,平均单次,最惨1秒,最大生命,接管时HP,存活秒,战斗秒,秒伤,治疗量,X,Y,来源摘要,伤害构成,钩子伤害构成";

    public string ToCsvRow()
    {
        var c = CultureInfo.InvariantCulture;
        return string.Join(",",
            DiedAt.ToString("yyyy-MM-dd HH:mm:ss.fff", c),
            UnitName.Replace(',', '，'),
            TypeCode,
            OwnerSlot >= 0 ? (OwnerSlot + 1).ToString(c) : "",
            Kind,
            InstanceIndex.ToString(c),
            HitCount.ToString(c),
            TotalDamage.ToString("0.##", c),
            MaxHit.ToString("0.##", c),
            MinHitSafe.ToString("0.##", c),
            AvgHit.ToString("0.##", c),
            Peak1s.ToString("0.##", c),
            HpMax.ToString("0.##", c),
            HpAtFirstSeen.ToString("0.##", c),
            LifetimeSeconds.ToString("0.0", c),
            CombatSeconds.ToString("0.0", c),
            DpsCombat.ToString("0.#", c),
            TotalHeal.ToString("0.##", c),
            X.ToString("0.#", c),
            Y.ToString("0.#", c),
            Attribution == null ? "" : Attribution.SourceSummary().Replace(',', '，'),
            Attribution == null ? "" : Attribution.BreakdownSummary().Replace(',', '，'),
            HookBreakdown.Summary(HookRows ?? Array.Empty<HookBreakdown.Row>()).Replace(',', '，'));
    }
}



