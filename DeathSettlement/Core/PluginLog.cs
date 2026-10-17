using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace War3DeathSettlement.Core;

/// <summary>插件日志里“按攻击/远程/攻击类型/伤害类型”的一行。</summary>
public sealed record PluginJoint(int Attack, int Ranged, int AttackType, int DamageType,
    int Count, double Damage, double DamageAfter, double Percent);

/// <summary>插件日志里“按来源单位”的一行（谁打的、打了多少、占多少）。</summary>
public sealed record PluginSource(string Name, string Code, uint Handle,
    int Count, double Damage, double DamageAfter, double Percent)
{
    /// <summary>类型码必须是 4 个字符（自检用）。</summary>
    public bool SourceCodeOk() => Code.Length == 4;
}

/// <summary>游戏内插件（UDamageWatcher）写出的一条结算。</summary>
public sealed class PluginSettlement
{
    public DateTime Time { get; init; }
    public string Name { get; init; } = "";
    public string Code { get; init; } = "";
    public uint Handle { get; init; }
    public bool IsDeath { get; init; } = true;
    public int Events { get; init; }
    public double Total { get; init; }
    public List<PluginJoint> Joints { get; } = new();
    public List<PluginSource> Sources { get; } = new();

    /// <summary>这条插件结算是不是已经被某个外部结算“认领”了。</summary>
    public bool Claimed { get; set; }

    public override string ToString() =>
        $"[{Time:HH:mm:ss}] {Name}({Code} #{Handle:X8}) {(IsDeath ? "死亡结算" : "当前统计")} " +
        $"{Events} 次 / {Total:0.#}，来源 {Sources.Count} 个";
}

/// <summary>
/// 读取游戏内插件 <c>UDamageWatcher.log</c>，把它写出的「死亡结算（含伤害来源/攻击类型）」解析出来。
///
/// 为什么要它：本软件是**纯外部只读**，只能按血量差算伤害，拿不到“谁打的、什么攻击类型”。
/// 而游戏内插件正好把这些写进了日志。于是做成“可选增强”：
///   插件在跑 → 结算里补上来源占比；插件没跑 → 一切照旧，只是没有来源那一块。
/// 这一步只读文本文件，仍然不注入、不写游戏内存。
/// </summary>
public sealed class PluginLogReader
{
    private static readonly Regex TimePrefix =
        new(@"^\[(?<t>\d{1,2}:\d{2}:\d{2}\.\d{1,3})\]\s?(?<rest>.*)$", RegexOptions.Compiled);

    private static readonly Regex HeaderRe = new(
        @"^统计\s+(?<name>.+?)\s+\((?<code>[0-9A-Za-z_!]{4})\s+#(?<handle>[0-9A-Fa-f]{1,8})\)\s*(?<kind>死亡结算|当前统计)\s*[:：]\s*次数=(?<n>\d+)\s+总计=(?<total>[0-9.]+)",
        RegexOptions.Compiled);

    private static readonly Regex JointRe = new(
        @"^\s*(?<atk>\d)/(?<rng>\d)/(?<atype>\d+)/(?<dtype>\d+):\s*(?<n>\d+)\s*次\s*/\s*(?<dmg>[0-9.]+)\s+(?<after>[0-9.]+)\s*\((?<pct>[0-9.]+)%\)",
        RegexOptions.Compiled);

    private static readonly Regex SourceRe = new(
        @"^(?<name>.+?)\s+\((?<code>[0-9A-Za-z_!]{4})\s+#(?<handle>[0-9A-Fa-f]{1,8})\):\s*(?<n>\d+)\s*次\s*/\s*(?<dmg>[0-9.]+)\s+(?<after>[0-9.]+)\s*\((?<pct>[0-9.]+)%\)",
        RegexOptions.Compiled);

    private const string SourceSectionMarker = "按来源单位类型";

    /// <summary>选区行里的 `类型=XXXXXXXX 名字="…"`。</summary>
    private static readonly Regex HexNameRe = new(
        @"类型=(?<hex>[0-9A-Fa-f]{8})\s+名字=""(?<name>[^""]*)""", RegexOptions.Compiled);

    private readonly string _path;
    private long _offset;

    /// <summary>
    /// 从日志里顺手攒出来的「类型码 → 单位名」表。
    /// 两个来源：① 结算表头 `统计 星之真神 (H02N #…)`；② 选区行 `类型=4830324E 名字="星之真神"`。
    /// 有了它，界面上显示的就是你那张图里的中文单位名，而不是光秃秃的 H02N。
    /// </summary>
    public Dictionary<string, string> CodeToName { get; } = new(StringComparer.OrdinalIgnoreCase);

    /// <summary>查名字；没有就返回空串。</summary>
    public string NameOf(string? code)
    {
        if (string.IsNullOrEmpty(code)) return "";
        return CodeToName.TryGetValue(code, out var n) ? n : "";
    }

    private void Remember(string? code, string? name)
    {
        if (string.IsNullOrEmpty(code) || code.Length != 4 || string.IsNullOrWhiteSpace(name)) return;
        name = name.Trim();
        if (name.Length == 0 || string.Equals(name, code, StringComparison.OrdinalIgnoreCase)) return;
        CodeToName[code] = name;
    }

    /// <summary>选区行里的 `类型=XXXXXXXX`：十六进制按内存顺序拆开正好是那 4 个字符。</summary>
    private static string CodeFromHex(string hex)
    {
        if (hex.Length != 8) return "";
        var chars = new char[4];
        for (int i = 0; i < 4; i++)
        {
            if (!byte.TryParse(hex.Substring(i * 2, 2), NumberStyles.HexNumber, CultureInfo.InvariantCulture, out byte b))
                return "";
            chars[i] = (char)b;
        }
        return new string(chars);
    }

    /// <summary>最近解析出来的插件结算（新的在后面），最多保留 <see cref="MaxEntries"/> 条。</summary>
    public List<PluginSettlement> Entries { get; } = new();
    public int MaxEntries { get; set; } = 2000;

    /// <summary>累计解析出的结算条数（诊断用）。</summary>
    public int ParsedTotal { get; private set; }
    public string LastError { get; private set; } = "";

    public PluginLogReader(string path, bool fromStart = false)
    {
        _path = path;
        if (!fromStart)
        {
            try { if (File.Exists(path)) _offset = new FileInfo(path).Length; } catch { _offset = 0; }
        }
    }

    public string Path => _path;
    public bool Exists { get { try { return File.Exists(_path); } catch { return false; } } }

    /// <summary>增量读新内容并解析；返回这次新增了几条结算。</summary>
    public int Poll()
    {
        int added = 0;
        try
        {
            // 最多 8 轮 × 每轮 4MB：第一次会把已有日志整段读掉（通常几十 KB），
            // 之后每轮基本就是“没有新内容，直接返回”。
            for (int round = 0; round < 8; round++)
            {
                if (!File.Exists(_path)) break;
                var fi = new FileInfo(_path);
                if (fi.Length < _offset) _offset = 0;          // 文件被截断/重建（换局）
                if (fi.Length == _offset) break;

                using var fs = new FileStream(_path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
                fs.Seek(_offset, SeekOrigin.Begin);
                int len = (int)Math.Min(fi.Length - _offset, 4 << 20);
                var buf = new byte[len];
                int read = fs.Read(buf, 0, len);
                _offset += read;
                if (read <= 0) break;

                string text = Gbk.Decode(buf, 0, read);
                int lastNl = text.LastIndexOf('\n');
                if (lastNl < 0)
                {
                    _offset -= read;                            // 半行，等下次
                    break;
                }
                int consumed = Gbk.Encode(text[..(lastNl + 1)]).Length;
                _offset = _offset - read + consumed;

                int before = Entries.Count;
                Parse(text[..(lastNl + 1)], fi.LastWriteTime);
                added += Entries.Count - before;

                if (_offset >= fi.Length) break;
            }
        }
        catch (Exception ex)
        {
            LastError = ex.Message;
        }
        return added;
    }

    /// <summary>自检用：看看一行到底被哪个模式命中（排障用，正式流程不调用）。</summary>
    public static string DebugMatch(string line)
    {
        var tm = TimePrefix.Match(line);
        if (!tm.Success) return "时间前缀不匹配";
        string body = tm.Groups["rest"].Value;
        return $"body='{body}' time=OK header={HeaderRe.IsMatch(body)} " +
               $"joint={JointRe.IsMatch(body)} source={SourceRe.IsMatch(body)} " +
               $"marker={body.Contains(SourceSectionMarker, StringComparison.Ordinal)}";
    }

    /// <summary>解析一段日志文本（自测直接调它）。dateHint 用来补全“只有时分秒”的时间戳。</summary>
    public void Parse(string text, DateTime dateHint)
    {
        PluginSettlement? cur = null;
        bool inSources = false;
        DateTime lastWhen = dateHint;

        void Close()
        {
            if (cur != null && (cur.Sources.Count > 0 || cur.Joints.Count > 0))
            {
                Entries.Add(cur);
                ParsedTotal++;
                while (Entries.Count > MaxEntries) Entries.RemoveAt(0);
            }
            cur = null;
            inSources = false;
        }

        foreach (var raw in text.Split('\n'))
        {
            var line = raw.TrimEnd('\r');
            if (line.Length == 0) continue;

            var tm = TimePrefix.Match(line);
            DateTime when = dateHint;
            string body = line;
            if (tm.Success)
            {
                if (TimeSpan.TryParse(tm.Groups["t"].Value, CultureInfo.InvariantCulture, out var ts))
                    when = dateHint.Date + ts;
                body = tm.Groups["rest"].Value;
            }

            // 时间跳了一大截（>3 秒）说明上一块已经结束了 —— 不要靠“这行不认识”来判断，
            // 因为日志里会夹别的行（例如“死亡结算：准备投递”），早先那样写会把刚开头的块直接扔掉。
            if (cur != null && (when - lastWhen) > TimeSpan.FromSeconds(3)) Close();
            lastWhen = when;

            // 顺手收「类型码 → 单位名」：表头 / 选区行
            var hexm = HexNameRe.Match(body);
            if (hexm.Success)
            {
                string c = CodeFromHex(hexm.Groups["hex"].Value);
                if (c.Length == 4) Remember(c, hexm.Groups["name"].Value);
            }

            var hm = HeaderRe.Match(body);
            if (hm.Success)
            {
                Close();
                cur = new PluginSettlement
                {
                    Time = when,
                    Name = hm.Groups["name"].Value.Trim(),
                    Code = hm.Groups["code"].Value,
                    Handle = uint.TryParse(hm.Groups["handle"].Value, NumberStyles.HexNumber, CultureInfo.InvariantCulture, out uint h) ? h : 0,
                    IsDeath = hm.Groups["kind"].Value == "死亡结算",
                    Events = int.TryParse(hm.Groups["n"].Value, out int n) ? n : 0,
                    Total = double.TryParse(hm.Groups["total"].Value, NumberStyles.Float, CultureInfo.InvariantCulture, out double tot) ? tot : 0
                };
                Remember(cur.Code, cur.Name);
                continue;
            }

            if (cur == null) continue;   // 不属于任何已知块的普通日志行，跳过（不要因此结束当前块）

            if (body.Contains(SourceSectionMarker, StringComparison.Ordinal))
            {
                inSources = true;
                continue;
            }

            var sm = SourceRe.Match(body);
            if (sm.Success && inSources)
            {
                cur.Sources.Add(new PluginSource(
                    sm.Groups["name"].Value.Trim(),
                    sm.Groups["code"].Value,
                    uint.TryParse(sm.Groups["handle"].Value, NumberStyles.HexNumber, CultureInfo.InvariantCulture, out uint sh) ? sh : 0,
                    int.TryParse(sm.Groups["n"].Value, out int sc) ? sc : 0,
                    ParseDouble(sm.Groups["dmg"].Value),
                    ParseDouble(sm.Groups["after"].Value),
                    ParseDouble(sm.Groups["pct"].Value)));
                continue;
            }

            var jm = JointRe.Match(body);
            if (jm.Success && !inSources)
            {
                cur.Joints.Add(new PluginJoint(
                    int.TryParse(jm.Groups["atk"].Value, out int a) ? a : 0,
                    int.TryParse(jm.Groups["rng"].Value, out int r) ? r : 0,
                    int.TryParse(jm.Groups["atype"].Value, out int at) ? at : 0,
                    int.TryParse(jm.Groups["dtype"].Value, out int dt) ? dt : 0,
                    int.TryParse(jm.Groups["n"].Value, out int jc) ? jc : 0,
                    ParseDouble(jm.Groups["dmg"].Value),
                    ParseDouble(jm.Groups["after"].Value),
                    ParseDouble(jm.Groups["pct"].Value)));
                continue;
            }
            // 其它行忽略：块由“下一个表头 / 时间跳变 / 文本结束”来收尾
        }

        Close();
    }

    private static double ParseDouble(string s) =>
        double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out double v) ? v : 0;

    /// <summary>
    /// 给一个外部结算找它对应的插件结算：类型码相同、时间最接近、且还没被认领过。
    /// 找不到返回 null（插件没在跑 / 没记录这个单位 / 时间差太远）。
    /// </summary>
    public PluginSettlement? Match(string typeCode, DateTime diedAt, TimeSpan window)
    {
        PluginSettlement? best = null;
        TimeSpan bestDelta = TimeSpan.MaxValue;

        foreach (var e in Entries)
        {
            if (e.Claimed) continue;
            if (!string.Equals(e.Code, typeCode, StringComparison.OrdinalIgnoreCase)) continue;
            var delta = (e.Time - diedAt).Duration();
            if (delta > window || delta >= bestDelta) continue;
            best = e;
            bestDelta = delta;
        }

        if (best != null) best.Claimed = true;
        return best;
    }
}

/// <summary>挂在外部结算上的“游戏内插件来源数据”。</summary>
public sealed class PluginAttribution
{
    public string Name { get; init; } = "";
    public string Code { get; init; } = "";
    public uint Handle { get; init; }
    public int Events { get; init; }
    public double Total { get; init; }
    public IReadOnlyList<PluginSource> Sources { get; init; } = Array.Empty<PluginSource>();
    public IReadOnlyList<PluginJoint> Joints { get; init; } = Array.Empty<PluginJoint>();

    // ------------------------------------------------------------------
    // 分组统计：是否攻击 / 是否远程 / 攻击类型 / 伤害类型（用户要求的口径）
    // 插件日志里每一行就是"这四种属性的一个组合 + 笔数 + 伤害"
    // （形如 `1/0/3/4: 2 次 / 60.0 60.0 (50.0%)`），所以我们能做精确分组。
    // ------------------------------------------------------------------

    /// <summary>一个分组：维度、分组名、笔数、原始伤害、结算后伤害、占比。</summary>
    public sealed record DamageGroup(string Dimension, string Key, int Count, double Damage, double DamageAfter, double Percent)
    {
        public override string ToString() =>
            $"{Key}: {Count} 笔 / {DamageAfter:0.#}" + (Percent > 0 ? $" ({Percent:0.#}%)" : "");
    }

    private List<DamageGroup>? _groups;

    /// <summary>全部分组（4 个维度），按维度顺序、伤害从大到小。</summary>
    public IReadOnlyList<DamageGroup> Groups => _groups ??= BuildGroups();

    public IEnumerable<DamageGroup> GroupsOf(string dimension) =>
        Groups.Where(g => g.Dimension == dimension);

    /// <summary>把"是否攻击/是否远程/攻击类型/伤害类型 各自 + 组合"都算出来。</summary>
    private List<DamageGroup> BuildGroups()
    {
        var list = new List<DamageGroup>();
        if (Joints.Count == 0) return list;

        double total = Joints.Sum(j => j.DamageAfter);
        if (total <= 0) total = Joints.Sum(j => j.Damage);
        if (total <= 0) total = 1;

        void Add(string dim, Func<PluginJoint, string> keyOf)
        {
            foreach (var g in Joints.GroupBy(keyOf))
            {
                double dmg = g.Sum(x => x.Damage);
                double after = g.Sum(x => x.DamageAfter);
                list.Add(new DamageGroup(dim, g.Key, g.Sum(x => x.Count), dmg, after, 100.0 * after / total));
            }
        }

        Add("是否攻击", j => j.Attack != 0 ? "攻击" : "非攻击");
        Add("是否远程", j => j.Ranged != 0 ? "远程" : "近战");
        Add("攻击类型", j => DamageTypeNames.Attack(j.AttackType));
        Add("伤害类型", j => DamageTypeNames.Damage(j.DamageType));
        Add("组合明细", j => $"{DamageTypeNames.Attack(j.AttackType)}/{DamageTypeNames.Damage(j.DamageType)}" +
                             $"/{(j.Attack != 0 ? "攻击" : "非攻击")}/{(j.Ranged != 0 ? "远程" : "近战")}");

        // 组合明细放在最后，其余维度按伤害从大到小
        return list
            .OrderBy(g => DimensionOrder(g.Dimension))
            .ThenByDescending(g => g.DamageAfter)
            .ToList();
    }

    private static int DimensionOrder(string d) => d switch
    {
        "是否攻击" => 0,
        "是否远程" => 1,
        "攻击类型" => 2,
        "伤害类型" => 3,
        _ => 4
    };

    /// <summary>一行式摘要（CSV 用）：攻击:1200(80%)；非攻击:300(20%)|近战:...|攻城:...|火焰:...</summary>
    public string BreakdownSummary()
    {
        if (Joints.Count == 0) return "";
        var sb = new StringBuilder();
        foreach (var dim in new[] { "是否攻击", "是否远程", "攻击类型", "伤害类型" })
        {
            var gs = GroupsOf(dim).ToList();
            if (gs.Count == 0) continue;
            if (sb.Length > 0) sb.Append('|');
            sb.Append(string.Join("；", gs.Select(g => $"{g.Key}:{g.DamageAfter:0.#}({g.Percent:0.#}%)")));
        }
        return sb.ToString();
    }

    public static PluginAttribution From(PluginSettlement s) => new()
    {
        Name = s.Name,
        Code = s.Code,
        Handle = s.Handle,
        Events = s.Events,
        Total = s.Total,
        Sources = s.Sources.ToArray(),
        Joints = s.Joints.ToArray()
    };

    /// <summary>“龙翼守卫(H038) 50.3%、黑暗司教(E04G) 25.2% …”这样一行，方便塞进表格/CSV。</summary>
    public string SourceSummary(int max = 3)
    {
        var top = Sources.OrderByDescending(s => s.DamageAfter).Take(max)
            .Select(s => $"{s.Name}({s.Code}) {s.Percent:0.#}%");
        string head = string.Join("、", top);
        return Sources.Count > max ? head + $" 等 {Sources.Count} 个来源" : head;
    }
}
