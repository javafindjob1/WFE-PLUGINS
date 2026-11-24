using System.Diagnostics;

namespace War3DeathSettlement.Core;

/// <summary>一个被我们认出并持续跟踪的单位实例。</summary>
public sealed class ScannedUnit
{
    public uint Addr { get; init; }                 // CUnit*
    public string TypeCode { get; set; } = "";
    public uint HpIndex { get; set; }
    public float Hp { get; set; }
    public float HpMax { get; set; }
    public float Mp { get; set; }
    public float MpMax { get; set; }
    public float X { get; set; }
    public float Y { get; set; }
    /// <summary>
    /// 护甲：CUnit+0xE0 是 **float**（YDWE UnitState.cpp 的 UNIT_STATE_ARMOR 把 4 字节
    /// 原样返回给 JASS 的 real 返回值，并没有 jass::to_real；真机 E06V 原始位模式
    /// 0x430DADBB = 141.679）。读不到 / 不在 -100~1000 时是 NaN（属性表显示 ?）。
    /// </summary>
    public float Armor { get; set; }
    public int OwnerSlot { get; set; } = -1;
    public string FoundBy { get; set; } = "";
    /// <summary>
    /// 置信度（用来排除“长得像但其实不是”的内存）：生命链 +2，虚表在 game.dll +2，
    /// 魔法索引 +1，坐标合理 +1，头部能找到 CPlayer* +1。
    /// </summary>
    public int Confidence { get; set; }

    /// <summary>+0x00 是不是 game.dll 映像里的虚表指针（真 CUnit 的标志）。</summary>
    public bool VtableOk { get; set; }

    public float HpPercent => HpMax > 0f ? Math.Clamp(Hp / HpMax, 0f, 1f) : 0f;
    public override string ToString() => $"{TypeCode}@0x{Addr:X8} {Hp:0.#}/{HpMax:0.#}";
}

/// <summary>一次扫描的统计/诊断（无界面模式 / 诊断报告展示）。</summary>
public sealed class ScanStats
{
    public int Known;
    public int Refreshed;
    public int FromHandleTable;
    public int FromSelection;
    public uint HandleTable;
    public string HandleTableName = "";
    public int HandleSlots, HandleValid;
    public int SelectedUnits;
    public long ElapsedMs;
    public string Mode = "";
    public List<string> Notes { get; } = new();

    /// <summary>HP 超过上限（1e9）被拒绝的候选累计数；&gt;0 说明可能有“大 HP 真单位”被挡（前 5 条见日志）。</summary>
    public int HpRejected;
}

/// <summary>
/// 单位发现与读取。
///
/// 两条发现路径（互为补充，全部只读）：
///   ① 句柄表  —— ctx+0xF4 的句柄管理器里的对象槽（War3Trainer/ydbase 同源）
///   ② 选区链  —— 已实测验证过的 CSelection 链（只覆盖“当前选中的单位”）
/// 另外，伤害钩子事件里看到的来源/触发单位指针会作为“已知锚点”补进账本（RegisterHookAnchor），
/// 让没被选中过的单位也能被跟踪/结算。
///
/// 读取路径统一走 War3Trainer 的字段偏移：
///   HP = *(CUnit+0xA0) → 游戏内存表[索引] + 0x78（当前）/ +0x84（最大）
///   护甲 = *(CUnit+0xE0) → **按 float 读**。依据 YDWE（yd_jass_api/UnitState.cpp，
///          UNIT_STATE_ARMOR）虽然写的是 <c>return *(uint32_t*)(unit_object + 0xE0);</c>，
///          但该函数返回 JASS 的 real（float），这里没有 to_real —— 等于把 4 字节
///          位模式原样透传，所以字段实际是 float。真机 E06V：0x430DADBB = 141.679。
///          按 int32 读会得到 1124969915 并被判越界，正好读反。
/// </summary>
public sealed class UnitScanner
{
    private const int UnitHeaderSize = 0x200;

    /// <summary>
    /// “最大 HP”上限。**不要按普通对战图（几千血）来猜**：
    /// 魔兽地图可以有千万级 HP —— 星之真神 H02N 实测 5.48M，
    /// 旧上限 5,000,000 把它当成假单位丢掉，整局 270 次受击却没有死亡结算。
    /// 现在放宽到 1e9，仍然挡掉明显是垃圾数据的浮点数。
    /// </summary>
    private const float MaxPlausibleHp = 1_000_000_000f;

    /// <summary>HP 超上限的拒绝诊断最多写几条日志（再多就只计数，避免刷屏）。</summary>
    private const int HpRejectLogLimit = 5;

    private readonly Wc3Game _g;
    private readonly Dictionary<uint, ScannedUnit> _known = new();

    /// <summary>
    /// 选区链里给出的**原始单位指针**（不管有没有通过单位校验）。
    /// 用途：给生命表基址验证/诊断提供“真实单位”锚点。
    /// </summary>
    public IReadOnlyList<uint> SelectionCandidates => _selectionCandidates;
    private readonly List<uint> _selectionCandidates = new();
    private bool _ownerDiagLogged;
    /// <summary>HP 超过上限被拒绝的候选累计数（自上次 Reset 起；诊断大 HP 单位被误杀用）。</summary>
    private int _hpRejected;
    /// <summary>HP 超上限拒绝日志已经写了几条（最多 <see cref="HpRejectLogLimit"/> 条）。</summary>
    private int _hpRejectLogged;

    /// <summary>护甲诊断日志最多写几条（前 3 次读取，便于真机确认 +0xE0 的原始 int 位模式与实际值）。</summary>
    private const int ArmorLogLimit = 3;
    /// <summary>护甲诊断日志已经写了几条。</summary>
    private int _armorLogged;

    public UnitScanner(Wc3Game game) => _g = game;

    public IReadOnlyDictionary<uint, ScannedUnit> Known => _known;
    public ScanStats LastStats { get; } = new();

    /// <summary>HP 超过上限被拒绝的候选累计数（自上次 Reset 起）。0 = 没有“大 HP 真单位”被挡。</summary>
    public int HpRejected => _hpRejected;

    /// <summary>是否用句柄表发现单位（排障时可关掉，只靠选区链/钩子锚点）。</summary>
    public bool EnableHandleTable { get; set; } = true;
    /// <summary>是否用选区链发现单位。</summary>
    public bool EnableSelection { get; set; } = true;

    /// <summary>最低置信度（低于它的候选当成“长得像的内存”丢掉；选区链发现的单位受信任、不受限）。</summary>
    public int MinConfidence { get; set; } = 3;

    private HashSet<uint> _playerSet = new();
    /// <summary>“连续出现几轮了”的临时计数（稳定性过滤用）。</summary>
    private readonly Dictionary<uint, int> _pending = new();

    /// <summary>CUnit 拥有者槽位，固定为 +0x58。</summary>
    public int OwnerOffset
    {
        get => _g.OwnerOffset;
        private set => _g.OwnerOffset = value;
    }
    /// <summary>玩家对象数组（用于把单位映射到玩家）。</summary>
    public uint[] Players { get; private set; } = new uint[16];

    // ---- 字段偏移（默认取 War3Trainer 的那一套；若实机对不上会自动校准） ----
    public uint HpIndexOffset { get; private set; } = Wc3UnitOffset.HpIndex;
    public uint MpIndexOffset { get; private set; } = Wc3UnitOffset.MpIndex;
    public uint PositionIndexOffset { get; private set; } = Wc3UnitOffset.PositionIndex;
    public uint StateCurOffset { get; private set; } = Wc3UnitOffset.StateCur;
    public uint StateMaxOffset { get; private set; } = Wc3UnitOffset.StateMax;

    // ==================================================================
    // 主入口
    // ==================================================================
    public ScanStats Scan()
    {
        var st = LastStats;
        st.Notes.Clear();
        st.FromHandleTable = st.FromSelection = st.Refreshed = st.SelectedUnits = 0;
        st.HandleTable = 0; st.HandleTableName = ""; st.HandleSlots = st.HandleValid = 0; st.Mode = "";
        st.HpRejected = _hpRejected;
        if (st.HpRejected > 0)
            st.Notes.Add($"HP 范围拒绝：累计 {st.HpRejected} 个候选超过上限 {MaxPlausibleHp:0}" +
                         $"（前 {Math.Min(_hpRejectLogged, HpRejectLogLimit)} 条已写日志）");
        var sw = Stopwatch.StartNew();

        if (!_g.IsReady)
        {
            st.Known = 0;
            st.ElapsedMs = sw.ElapsedMilliseconds;
            return st;
        }

        Players = _g.ReadPlayerObjects();
        _playerSet = new HashSet<uint>(Players.Where(p => p != 0));

        var found = new Dictionary<uint, ScannedUnit>();

        // ① 快速刷新：已知单位（一次读 0x200 头 + 一次读状态块）
        foreach (var kv in _known)
        {
            if (TryReadUnit(kv.Key, out var u, keepTypeCode: kv.Value.TypeCode))
            {
                u.FoundBy = kv.Value.FoundBy;
                found[kv.Key] = u;
                st.Refreshed++;
            }
        }

        // ② 句柄表（便宜，能一次拿到成百上千个对象）
        if (EnableHandleTable) TryHandleTable(found, st);
        else st.Notes.Add("句柄表：已按参数关闭");

        // ③ 选区链（实测可用的锚点；也用来校准“什么才算一个单位”）
        if (EnableSelection) ScanSelection(found, st);
        else st.Notes.Add("选区链：已按参数关闭");

        // 合并进 known（保留首次发现时间等元数据由 DamageTracker 负责）
        SanitizeFound(found, st);

        // 稳定性过滤：非选区链发现的新单位，要连续两轮都出现才真正开始跟踪。
        // 原因：句柄表/钩子锚点偶尔会“凑巧”认出别的内存，只闪一次的那些直接滤掉，
        // 免得它们在账本里生出一条莫名其妙的结算。
        {
            var seenThisScan = new HashSet<uint>(found.Keys);
            foreach (var kv in found.ToList())
            {
                uint a = kv.Key;
                if (_known.ContainsKey(a)) { _pending.Remove(a); continue; }
                if (kv.Value.FoundBy.StartsWith("选区", StringComparison.Ordinal)) { _pending.Remove(a); continue; }

                // 真单位在 CUnit+0x58 有玩家槽位；读不到就说明这地址不像正常单位。
                // 只在拥有者偏移已经发现之后才用这条规则，免得还没发现时把全场滤空。
                if (OwnerOffset >= 0 && kv.Value.OwnerSlot < 0) { found.Remove(a); continue; }

                int n = _pending.TryGetValue(a, out int c) ? c + 1 : 1;
                _pending[a] = n;
                if (n < 3) found.Remove(a);   // 连续 3 轮都出现才开始跟
            }
            foreach (var a in _pending.Keys.ToList())
                if (!seenThisScan.Contains(a)) _pending.Remove(a);
        }

        foreach (var kv in found)
        {
            _known[kv.Key] = kv.Value;
        }

        // 长时间读不到的单位，从“存活表”里剔除（DamageTracker 会把它当成“消失/销毁”处理）
        var stale = _known.Where(kv => !found.ContainsKey(kv.Key)).Select(kv => kv.Key).ToList();
        foreach (var a in stale) _known.Remove(a);

        st.Known = _known.Count;
        st.Mode = st.FromHandleTable > 0
            ? (st.FromSelection > 0 ? "句柄表+选区" : "句柄表+缓存")
            : (st.FromSelection > 0 ? "选区+缓存" : "缓存");
        st.ElapsedMs = sw.ElapsedMilliseconds;

        if (OwnerOffset >= 0)
        {
            ApplyOwners(found);

            // 拥有者偏移是“发现之后才知道”的：回头把之前收下的、读不出拥有者的非选区单位剔掉。
            // 这些基本就是“长得像单位的内存”，留着会生出莫名其妙的结算。
            foreach (var a in _known.Keys.ToList())
            {
                var u = _known[a];
                if (u.FoundBy.StartsWith("选区", StringComparison.Ordinal)) continue;
                if (u.OwnerSlot < 0)
                {
                    _known.Remove(a);
                    _pending.Remove(a);
                }
            }
        }

        LogOwnerDiagnostics();

        return st;
    }

    /// <summary>
    /// 拥有者诊断：只写前 8 个单位的 raw +0x58 与槽位解释。每局只写一次。
    /// </summary>
    private void LogOwnerDiagnostics()
    {
        if (_ownerDiagLogged || _known.Count == 0) return;
        _ownerDiagLogged = true;

        foreach (var u in _known.Values.Take(8))
        {
            uint rawOwner = _g.Mem.U32((ulong)u.Addr + Wc3UnitOffset.Owner);
            _ = OwnerResolver.Interpret(rawOwner, Players, out string interp);
            Log.Write($"拥有者诊断：addr=0x{u.Addr:X8} raw58={rawOwner} 解释={interp}");
        }
    }

    // ==================================================================
    // ① 句柄表
    // ==================================================================
    /// <summary>
    /// 收尾清理。三条发现路径合起来之后，同一个单位仍可能被认出好几次
    /// （假候选凑巧也指向同一个生命对象 —— 真单位的状态对象是“一人一个”的）。
    /// 规则：① 同一个生命对象只留一个（选区链 &gt; 置信度高的）；
    ///       ② 置信度低于门槛的候选丢掉（有可信单位时才这么做，避免门槛不合适时把全场清空）。
    /// </summary>
    private void SanitizeFound(Dictionary<uint, ScannedUnit> found, ScanStats st)
    {
        if (found.Count <= 1) return;

        static bool Trusted(ScannedUnit u) => u.FoundBy.StartsWith("选区", StringComparison.Ordinal);
        static int Rank(ScannedUnit u) => (Trusted(u) ? 100 : 0) + u.Confidence;

        int droppedDup = 0, droppedLow = 0;

        // ① 按生命对象去重
        var byHp = new Dictionary<uint, ScannedUnit>(found.Count);
        foreach (var u in found.Values)
        {
            if (!byHp.TryGetValue(u.HpIndex, out var cur)) { byHp[u.HpIndex] = u; continue; }
            if (Rank(u) > Rank(cur)) { byHp[u.HpIndex] = u; }
            droppedDup++;
        }

        // ② 置信度过滤
        bool anyStrong = byHp.Values.Any(u => Trusted(u) || u.Confidence >= MinConfidence);
        var keep = new List<ScannedUnit>(byHp.Count);
        foreach (var u in byHp.Values)
        {
            if (anyStrong && !Trusted(u) && u.Confidence < MinConfidence) { droppedLow++; continue; }
            keep.Add(u);
        }

        if (droppedDup == 0 && droppedLow == 0) return;

        var keepAddrs = new HashSet<uint>(keep.Select(u => u.Addr));
        foreach (var addr in found.Keys.ToList())
            if (!keepAddrs.Contains(addr)) found.Remove(addr);

        if (droppedDup > 0) st.Notes.Add($"去重：同一个生命对象被认出多次，丢掉 {droppedDup} 个多余候选");
        if (droppedLow > 0) st.Notes.Add($"置信度过滤：丢掉 {droppedLow} 个低置信度候选");
    }

    /// <summary>句柄表候选（诊断用：把每个候选地址都报出来，方便对照实机）。</summary>
    public IEnumerable<(string Name, uint Table)> HandleTableCandidates()
    {
        uint ctx = _g.Ctx;
        uint mgr = ctx + 0xF4;                      // ctx 里的句柄管理器子对象（RVA 0x1C2600 的 lea ecx,[esi+0xF4]）
        yield return ("mgr+0x19C", _g.Mem.U32(mgr + 0x19C));
        yield return ("mgr+0x198", _g.Mem.U32(mgr + 0x198));
        uint t = _g.Mem.U32(ctx + 0xF4);
        yield return ("ctx+0xF4", t);
        if (t != 0)
        {
            yield return ("[ctx+0xF4]+0x19C", _g.Mem.U32(t + 0x19C));
            yield return ("[ctx+0xF4]+0x198", _g.Mem.U32(t + 0x198));
        }
    }

    private void TryHandleTable(Dictionary<uint, ScannedUnit> found, ScanStats st)
    {
        int best = -1;
        foreach (var (name, table) in HandleTableCandidates())
        {
            if (table == 0 || !_g.Mem.IsReadable(table, 12)) continue;
            var reg = _g.Mem.RegionOf(table);
            if (reg == null) continue;

            long maxSlots = Math.Min((long)(reg.Value.End - table) / 12, 0x80000);
            int bytes = (int)Math.Min(maxSlots * 12, 8 << 20);
            var buf = _g.Mem.ReadBytes(table, bytes);
            if (buf == null || buf.Length < 12) continue;

            int slots = buf.Length / 12;
            int valid = 0;
            for (int i = 0; i < slots; i++)
            {
                uint obj = BitConverter.ToUInt32(buf, i * 12 + 4);
                if (obj == 0 || found.ContainsKey(obj)) continue;
                if (!TryReadUnit(obj, out var u, keepTypeCode: null)) continue;
                valid++;
                u.FoundBy = "句柄表";
                found[obj] = u;
            }

            st.Notes.Add($"句柄表候选 {name}=0x{table:X8}：槽位 {slots}，合法单位 {valid}");
            if (valid > best) { best = valid; st.HandleTable = table; st.HandleTableName = name; st.HandleSlots = slots; st.HandleValid = valid; }
        }
        if (best < 0) st.Notes.Add("句柄表：所有候选地址都无效（改由选区链/钩子事件发现单位）");
        st.FromHandleTable = found.Values.Count(v => v.FoundBy == "句柄表");
    }

    // ==================================================================
    // ② 选区链（已实测：sel+0x1F0 / sel+0x08 两组）
    // ==================================================================
    private void ScanSelection(Dictionary<uint, ScannedUnit> found, ScanStats st)
    {
        _selectionCandidates.Clear();
        foreach (uint player in Players)
        {
            if (player == 0) continue;
            uint sel = _g.Mem.U32((ulong)player + 0x34);
            if (sel == 0 || !_g.Mem.IsReadable(sel, 0x200)) continue;

            foreach (var (firstOff, countOff, tag) in new[] { (0x1F0u, 0x1F8u, "sel+0x1F0"), (0x08u, 0x10u, "sel+0x08") })
            {
                uint first = _g.Mem.U32((ulong)sel + firstOff);
                uint count = _g.Mem.U32((ulong)sel + countOff);
                if (first == 0 || count == 0 || count > 256) continue;

                uint node = first;
                for (uint i = 0; i < count && node != 0; i++)
                {
                    if (!_g.Mem.IsReadable(node, 0x10)) break;
                    uint unit = _g.Mem.U32((ulong)node + 0x08);
                    // 记下**原始**单位指针（哪怕它没通过校验）—— 生命表基址验证/诊断要用它当真实单位锚点
                    if (unit != 0 && !_selectionCandidates.Contains(unit) && _selectionCandidates.Count < 64)
                        _selectionCandidates.Add(unit);
                    if (unit != 0 && !found.ContainsKey(unit) && TryReadUnit(unit, out var u, keepTypeCode: null))
                    {
                        u.FoundBy = "选区(" + tag + ")";
                        found[unit] = u;
                        st.SelectedUnits++;
                    }
                    node = _g.Mem.U32((ulong)node + 0x00);
                }
                if (st.SelectedUnits > 0) return;
            }
        }
        st.FromSelection = found.Values.Count(v => v.FoundBy.StartsWith("选区", StringComparison.Ordinal));
    }

    private static bool IsTypeCodeBytes(byte a, byte b, byte c, byte d)
    {
        if (!IsAlnum(a) || !IsAlnum(b) || !IsAlnum(c) || !IsAlnum(d)) return false;
        // 至少一个英文字母（纯数字/纯符号多半是数据而不是类型码）
        return IsAlpha(a) || IsAlpha(b) || IsAlpha(c) || IsAlpha(d);
    }

    /// <summary>
    /// 4 字符类型码 → 显示用的字符串。**必须反过来读**：魔兽把 4CC 当 dword 存，
    /// 于是内存里的字节顺序与显示顺序相反。
    /// 实机证据：你机器上那个被 War3Trainer 显示为 `E04J` 的单位，
    /// 内存 `+0x30` 处是 `4A 34 30 45`（= "J40E"）；插件日志里的 `H02N / E04G / U00Q`
    /// 也都是“反过来”的那种写法（日志里 `类型=4830324E 名字="星之真神"` → 显示 H02N）。
    /// 反了的话不仅界面难看，还会导致**插件日志按类型码匹配不上**（来源/中文名全丢）。
    /// </summary>
    public static string TypeCodeFromBytes(byte a, byte b, byte c, byte d)
        => new string(new[] { (char)d, (char)c, (char)b, (char)a });

    private static bool IsAlnum(byte b) => (b >= '0' && b <= '9') || (b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z') || b == '_';
    private static bool IsAlpha(byte b) => (b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z');

    /// <summary>
    /// “这对数字像不像（当前HP，最大HP）”。
    /// 上限是 <see cref="MaxPlausibleHp"/>（1e9）：魔兽地图可以有千万级 HP，
    /// 星之真神 H02N 实测 5.48M，旧上限 5,000,000 把它当假单位误杀（整局没结算）。
    /// 其余校验保留：NaN/Inf 一律拒绝；当前 HP 不能超过最大 HP 的 1% 容差 +1。
    /// internal 是给 --selftest 直接断言的（同一程序集）。
    /// </summary>
    internal static bool PlausibleHp(float cur, float max)
    {
        if (float.IsNaN(cur) || float.IsNaN(max) || float.IsInfinity(cur) || float.IsInfinity(max)) return false;
        if (!(max > 0.05f && max < MaxPlausibleHp)) return false;
        if (!(cur > -10_000f && cur <= max * 1.01f + 1f)) return false;
        return true;
    }

    /// <summary>
    /// 只诊断“最大 HP 大到超上限”的拒绝（NaN/0/负值之类的垃圾数据不写日志，免得前 5 条被噪声占满）。
    /// 这样以后哪张图再把真单位做成 1e9 以上，日志里能一眼看到地址/类型码/血量。
    /// </summary>
    private void RejectHpAboveLimit(uint unit, string typeCode, float cur, float max)
    {
        _hpRejected++;
        if (_hpRejectLogged >= HpRejectLogLimit) return;
        _hpRejectLogged++;
        Log.Warn($"单位被 HP 范围拒绝：addr=0x{unit:X8} code={typeCode} cur={cur:F1} max={max:F1}（上限 {MaxPlausibleHp:0}）");
    }

    // ==================================================================
    // 单位校验 / 读取
    // ==================================================================
    /// <summary>
    /// 读一个 CUnit 并做自洽性校验。校验全过才算“真的是个单位”。
    /// keepTypeCode 传 null 表示重新读类型码。
    /// </summary>
    public bool TryReadUnit(uint unit, out ScannedUnit u, string? keepTypeCode)
    {
        u = new ScannedUnit { Addr = unit };
        if (unit == 0 || (unit & 3) != 0) return false;
        if (unit < 0x00010000 || unit >= 0x80000000) return false;
        if (!_g.Mem.IsReadable(unit, UnitHeaderSize)) return false;

        var hdr = _g.Mem.ReadBytes(unit, UnitHeaderSize);
        if (hdr == null || hdr.Length < UnitHeaderSize) return false;

        string tc = keepTypeCode ?? "";
        if (tc.Length != 4)
        {
            int t = (int)Wc3UnitOffset.TypeCode;
            if (!IsTypeCodeBytes(hdr[t], hdr[t + 1], hdr[t + 2], hdr[t + 3])) return false;
            tc = TypeCodeFromBytes(hdr[t], hdr[t + 1], hdr[t + 2], hdr[t + 3]);
        }

        uint hpIdx = BitConverter.ToUInt32(hdr, (int)HpIndexOffset);
        if (hpIdx == 0 || hpIdx > 0x0020_0000u) return false;
        // 引擎自己也是这么判的（真实 game.dll RVA 0x374CD3：cmp ecx,[ThisGame+0x1C] / jae 跳过）。
        // 读得到容量时按它卡上限，能挡掉一大批“凑巧像单位”的内存。
        // 注意：ThisGame+0x1C 我只在真实 game.dll 里看到“拿它当索引上界比较”这一条指令，
        // 它的确切语义是**推断**。实机出现过“容量=230246 把所有真实索引都卡掉 → 一个单位都认不出”，
        // 所以这里只在“离谱到不可能”时才放弃，平时不卡。
        if (_g.CapacityIsSane && hpIdx > _g.GameMemoryCapacity * 8u) return false;

        uint state = _g.GameMemoryLookup(hpIdx);
        if (state == 0 || !_g.Mem.IsReadable(state, 0x100)) return false;

        var stBuf = _g.Mem.ReadBytes(state, 0x100);
        if (stBuf == null || stBuf.Length < 0x90) return false;

        float hp = BitConverter.ToSingle(stBuf, (int)StateCurOffset);
        float max = BitConverter.ToSingle(stBuf, (int)StateMaxOffset);
        if (!PlausibleHp(hp, max))
        {
            // 只有“最大 HP 大到超过上限”才进拒绝诊断；NaN/负数等垃圾数据不占前 5 条日志名额。
            if (!float.IsNaN(max) && !float.IsInfinity(max) && max >= MaxPlausibleHp)
                RejectHpAboveLimit(unit, tc, hp, max);
            return false;
        }

        u.TypeCode = tc;
        u.HpIndex = hpIdx;
        u.Hp = hp;
        u.HpMax = max;
        u.Armor = ReadArmor(unit, hdr);

        int score = 2;   // 生命链过关 = 2 分（真实单位至少还有下面的 1 分）

        // vtable：真 CUnit 的 +0x00 是 game.dll 里的虚表指针（实机头部 04 A7 99 7C，
        // 而 game.dll 基址 0x7BF50000 ⇒ 0x7C99A704 正落在 game.dll 映像内）。
        // 这条几乎是免费的，但能一票筛掉海量“凑巧像单位”的堆内存 —— 实机上
        // 堆里“类型码 + 生命链自洽”的巧合曾一次给出上千个假候选，就是缺这一条。
        uint vt = BitConverter.ToUInt32(hdr, 0);
        if (_g.GameDllBase != 0 && vt >= _g.GameDllBase && vt < _g.GameDllBase + _g.GameDllImageSize)
        {
            u.VtableOk = true;
            score += 2;
        }

        // 蓝（读不到不影响判定；读到 +1 分）
        uint mpIdx = BitConverter.ToUInt32(hdr, (int)MpIndexOffset);
        if (mpIdx != 0 && mpIdx <= 0x0020_0000u)
        {
            uint ms = _g.GameMemoryLookup(mpIdx);
            if (ms != 0 && _g.Mem.IsReadable(ms, 0x90))
            {
                var mb = _g.Mem.ReadBytes(ms, 0x90);
                if (mb != null && mb.Length >= 0x88)
                {
                    u.Mp = BitConverter.ToSingle(mb, (int)StateCurOffset);
                    u.MpMax = BitConverter.ToSingle(mb, (int)StateMaxOffset);
                    score++;
                }
            }
        }

        // 坐标（读不到不影响判定；坐标合理 +1 分）
        uint posIdx = BitConverter.ToUInt32(hdr, (int)PositionIndexOffset);
        if (posIdx != 0 && posIdx <= 0x0020_0000u)
        {
            uint ps = _g.GameMemoryLookup(posIdx);
            if (ps != 0 && _g.Mem.IsReadable(ps, 0x90))
            {
                var pb = _g.Mem.ReadBytes(ps, 0x90);
                if (pb != null && pb.Length >= 0x80)
                {
                    float x = BitConverter.ToSingle(pb, (int)Wc3UnitOffset.PosX);
                    float y = BitConverter.ToSingle(pb, (int)Wc3UnitOffset.PosY);
                    if (!float.IsNaN(x) && !float.IsNaN(y) && Math.Abs(x) < 200000f && Math.Abs(y) < 200000f)
                    {
                        u.X = x; u.Y = y;
                        score++;
                    }
                }
            }
        }

        // 拥有者：统一直读 CUnit+0x58。死亡结算、伤害事件和存活行共用同一结果。
        u.OwnerSlot = OwnerResolver.Resolve(_g, unit, Players, OwnerOffset, out _, out _);
        if (u.OwnerSlot >= 0)
        {
            score++;
        }
        else if (_playerSet.Count > 0)
        {
            for (int off = 0; off + 4 <= hdr.Length; off += 4)
            {
                uint v = BitConverter.ToUInt32(hdr, off);
                if (v != 0 && _playerSet.Contains(v)) { score++; break; }
            }
        }

        u.Confidence = score;
        return true;
    }

    /// <summary>
    /// 读 CUnit+0xE0 的护甲，并按 YDWE 口径做合理性校验（-100~1000 之外 = 读不到 → NaN）。
    ///
    /// **为什么是 float**：YDWE <c>yd_jass_api/UnitState.cpp</c> 的 UNIT_STATE_ARMOR 分支是
    /// <c>return *(uint32_t*)(unit_object + 0xE0);</c>，但函数返回类型就是 JASS 的 real，
    /// 这里**没有** <c>jass::to_real</c>（ARMOR_TYPE 才有）—— 等于把位模式原样透传给 real。
    /// 真机 E06V 的 +0xE0 字节是 <c>BB AD 0D 43</c>（0x430DADBB），按 float = 141.679；
    /// 按 int 读则是 1124969915，越界。两种解释里选“像护甲”的那个（见 TryDecodeArmor）。
    /// </summary>
    private float ReadArmor(uint unit, byte[] hdr)
    {
        bool ok = TryDecodeArmor(hdr, out int raw, out float armor);
        if (!ok) armor = float.NaN;

        if (_armorLogged < ArmorLogLimit)
        {
            _armorLogged++;
            Log.Write($"护甲：addr=0x{unit:X8} +0xE0 int={raw} → {UnitStats.ArmorText(armor)}" +
                      (ok ? "" : "（越界，按读不到处理）"));
        }
        return armor;
    }

    /// <summary>
    /// 从单位头里解 CUnit+0xE0：优先按 **float** 解释（真机口径），
    /// 只有当 float 不是“正常数”时才退回 int32（兼容旧假设/其它版本）。
    ///
    /// 判定依据：int 0~1000 的位模式作 float 全是 0 或 1e-42 量级的**次正规数**；
    /// 真正的护甲（如 141.679）是正规数。因此：
    ///   · 0x430DADBB → 141.679（float，采用）；
    ///   · 0C 00 00 00 → float 1.68e-44（次正规，跳过）→ int 12（采用）；
    ///   · 5000（0x00001388）→ float 1.4e-42（跳过）→ int 越界 → 无效。
    /// 只接受 -100~1000（<see cref="UnitPropMath.ArmorMin"/>~<see cref="UnitPropMath.ArmorMax"/>，
    /// 与 ddh / <see cref="UnitPropMath.MemoryFlags"/> 同一套边界）。
    /// internal 是给 --selftest 直接断言的（同一程序集）。
    /// </summary>
    internal static bool TryDecodeArmor(byte[] hdr, out int raw, out float armor)
    {
        raw = 0;
        armor = float.NaN;

        int off = (int)Wc3UnitOffset.ArmorAmount;
        if (hdr == null || hdr.Length < off + sizeof(int)) return false;

        raw = BitConverter.ToInt32(hdr, off);

        // ① 真机口径：+0xE0 是 float（YDWE 对 real 返回值做位透传）。
        float asFloat = BitConverter.ToSingle(hdr, off);
        if (IsPlausibleFloat(asFloat) &&
            UnitPropMath.Fits(asFloat, UnitPropMath.ArmorMin, UnitPropMath.ArmorMax))
        {
            armor = asFloat;
            return true;
        }

        // ② 兼容：若某个版本真的存 int32 护甲，则 int 值同样是 -100~1000。
        if (UnitPropMath.Fits(raw, UnitPropMath.ArmorMin, UnitPropMath.ArmorMax))
        {
            armor = raw;
            return true;
        }

        return false;
    }

    /// <summary>
    /// 这个 float 位模式像不像“真正的护甲值”：排除 NaN/±Inf/次正规数。
    /// int 0~1000 的字节按 float 解出来是 0 或次正规数（1e-42 量级），必须让位给 int 解释；
    /// 0.0 允许（护甲真的可以是 0）。
    /// </summary>
    private static bool IsPlausibleFloat(float f)
    {
        if (float.IsNaN(f) || float.IsInfinity(f)) return false;
        if (f == 0f) return true;
        int bits = BitConverter.SingleToInt32Bits(f);
        return (bits & 0x7F800000) != 0;   // 指数位非 0 = 正规数
    }

    private void ApplyOwners(Dictionary<uint, ScannedUnit> found)
    {
        foreach (var kv in found)
            kv.Value.OwnerSlot = OwnerResolver.Resolve(_g, kv.Key, Players, OwnerOffset, out _, out _);
    }

    /// <summary>
    /// 把钩子事件里的单位对象指针当“已知锚点”补进账本（发现来源 = 钩子事件）。
    /// 只在读得到（类型码/生命链/HP 全部合法）时补；读不到（已死亡/已失效）就跳过。
    /// 不影响现有选中/扫描/去重逻辑：只是往 Known 里多喂一个真实单位，让没被选中过的单位也能被跟踪/结算。
    /// </summary>
    public void RegisterHookAnchor(uint unit)
    {
        if (unit == 0 || _known.ContainsKey(unit)) return;
        if (!TryReadUnit(unit, out var u, keepTypeCode: null)) return;
        u.FoundBy = "钩子事件";
        _known[unit] = u;
    }

    /// <summary>清空已知单位（换图/重开时用）。</summary>
    public void Reset()
    {
        _known.Clear();
        OwnerOffset = (int)Wc3UnitOffset.Owner;
        _ownerDiagLogged = false;
        _hpRejected = 0;
        _hpRejectLogged = 0;
        _armorLogged = 0;
    }

    /// <summary>从已知单位里移除一个地址（调用方负责屏蔽它不被重新发现）。</summary>
    public void Forget(uint addr) => _known.Remove(addr);
}





