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
    public float Armor { get; set; }
    public int OwnerSlot { get; set; } = -1;
    public string FoundBy { get; set; } = "";
    /// <summary>
    /// 置信度（深度扫描用来排除“长得像但其实不是”的内存）：生命链 +2，魔法索引 +1，
    /// 坐标合理 +1，头部能找到 CPlayer* +1。
    /// </summary>
    public int Confidence { get; set; }

    /// <summary>+0x00 是不是 game.dll 映像里的虚表指针（真 CUnit 的标志）。</summary>
    public bool VtableOk { get; set; }

    public float HpPercent => HpMax > 0f ? Math.Clamp(Hp / HpMax, 0f, 1f) : 0f;
    public override string ToString() => $"{TypeCode}@0x{Addr:X8} {Hp:0.#}/{HpMax:0.#}";
}

/// <summary>一次扫描的统计/诊断（界面上“诊断”页直接展示）。</summary>
public sealed class ScanStats
{
    public int Known;
    public int Refreshed;
    public int FromHandleTable;
    public int FromSelection;
    public int FromDeep;
    public uint HandleTable;
    public string HandleTableName = "";
    public int HandleSlots, HandleValid;
    public int SelectedUnits;
    public long ElapsedMs;
    public int DeepMb;
    public string Mode = "";
    public List<string> Notes { get; } = new();

    // ---- 深度扫描“漏斗”（用来远程定位：到底是哪一道关卡把单位刷掉了） ----
    /// <summary>类型码特征命中数（像 CUnit 的位置）。</summary>
    public int SigHits;
    /// <summary>其中：生命索引字段是合理数值的。</summary>
    public int SigWithHpIndex;
    /// <summary>其中：能通过生命索引查到游戏内存表、且对象可读的。</summary>
    public int SigStateReadable;
    /// <summary>其中：对象里那两个数字确实像（当前HP，最大HP）的 —— 也等于“被接受为单位”的数量。</summary>
    public int SigPlausibleHp;
    /// <summary>0 个单位都没认出来时，留几个候选地址给诊断用（人工看头部字节）。</summary>
    public List<uint> SigSamples { get; } = new();

    // ---- 深度扫描的“降噪”统计 ----
    /// <summary>生命链过了、但置信度不够被丢掉的候选数。</summary>
    public int DeepDroppedLowConf;
    /// <summary>深度扫描里“+0x00 不是 game.dll 虚表”被丢掉的候选数。</summary>
    public int DeepDroppedNoVtable;
    /// <summary>同一个生命对象被多个候选认领、只保留最高分后丢掉的数量。</summary>
    public int DeepDroppedDuplicate;
}

/// <summary>
/// 单位发现与读取。
///
/// 三条发现路径（按代价从低到高，互为补充）：
///   ① 句柄表      —— ctx+0xF4 的句柄管理器里的对象槽（War3Trainer/ydbase 同源，未在本机实测）
///   ② 选区链      —— 已实测验证过的 CSelection 链（只覆盖“当前选中的单位”）
///   ③ 全堆深度扫描 —— 在私有堆里按“4 字符类型码 + 合法生命链”的特征找 CUnit（最慢、但最全，
///                     也是本软件在“纯外部只读”约束下能拿到全部单位的兜底手段）
///
/// 读取路径统一走 War3Trainer 的字段偏移：
///   HP = *(CUnit+0xA0) → 游戏内存表[索引] + 0x78（当前）/ +0x84（最大）
/// </summary>
public sealed class UnitScanner
{
    private const int UnitHeaderSize = 0x200;
    private const int ChunkSize = 1 << 20;              // 深度扫描分块 1MB
    // 注意：这两个量必须是无符号/长整型 —— 2400<<20 超过 int.MaxValue，
    // 写成 int 会溢出成负数，深度扫描就会“一个字节都不扫”（自测里踩过一次）。
    private const ulong MaxDeepRegionBytes = 1200UL << 20;   // 单区域上限 1.2GB（有的版本整个对象堆就是一大块）
    private const long  MaxDeepTotalBytes  = 2400L << 20;    // 一次深度扫描总预算

    private readonly Wc3Game _g;
    private readonly Dictionary<uint, ScannedUnit> _known = new();
    private readonly List<MemRegion> _hotRegions = new();
    private DateTime _lastOwnerWarn = DateTime.MinValue;
    private DateTime _lastDeep = DateTime.MinValue;
    private DateTime _lastFullDeep = DateTime.MinValue;

    public UnitScanner(Wc3Game game) => _g = game;

    public IReadOnlyDictionary<uint, ScannedUnit> Known => _known;
    public ScanStats LastStats { get; } = new();

    /// <summary>深度扫描间隔（发现新单位）。设为 Zero 表示只在需要时手工扫。</summary>
    public TimeSpan DeepInterval { get; set; } = TimeSpan.FromSeconds(8);
    public bool EnableDeepScan { get; set; } = true;

    /// <summary>是否用句柄表发现单位（排障时可关掉，只靠深度扫描）。</summary>
    public bool EnableHandleTable { get; set; } = true;
    /// <summary>是否用选区链发现单位。</summary>
    public bool EnableSelection { get; set; } = true;

    /// <summary>深度扫描的最低置信度（低于它的候选当成“长得像的内存”丢掉）。</summary>
    public int MinDeepConfidence { get; set; } = 3;

    private HashSet<uint> _playerSet = new();
    /// <summary>“连续出现几轮了”的临时计数（稳定性过滤用）。</summary>
    private readonly Dictionary<uint, int> _pending = new();

    /// <summary>自动发现的“拥有者”字段偏移（在 CUnit 里的位置）。</summary>
    public int OwnerOffset { get; private set; } = -1;
    /// <summary>玩家对象数组（用于把单位映射到玩家）。</summary>
    public uint[] Players { get; private set; } = new uint[16];

    // ---- 字段偏移（默认取 War3Trainer 的那一套；若实机对不上会自动校准） ----
    public uint HpIndexOffset { get; private set; } = Wc3UnitOffset.HpIndex;
    public uint MpIndexOffset { get; private set; } = Wc3UnitOffset.MpIndex;
    public uint PositionIndexOffset { get; private set; } = Wc3UnitOffset.PositionIndex;
    public uint StateCurOffset { get; private set; } = Wc3UnitOffset.StateCur;
    public uint StateMaxOffset { get; private set; } = Wc3UnitOffset.StateMax;
    /// <summary>校准说明（空 = 用的是默认偏移）。</summary>
    public string CalibrationInfo { get; private set; } = "";
    private bool _calibrationTried;

    // ==================================================================
    // 主入口
    // ==================================================================
    public ScanStats Scan(bool forceDeep = false)
    {
        var st = LastStats;
        st.Notes.Clear();
        st.FromHandleTable = st.FromSelection = st.FromDeep = st.Refreshed = st.DeepMb = st.SelectedUnits = 0;
        st.HandleTable = 0; st.HandleTableName = ""; st.HandleSlots = st.HandleValid = 0; st.Mode = "";
        st.SigHits = st.SigWithHpIndex = st.SigStateReadable = st.SigPlausibleHp = 0;
        st.DeepDroppedLowConf = st.DeepDroppedDuplicate = 0;
        st.SigSamples.Clear();
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

        // ④ 深度扫描（定期，兜底发现全部单位）
        bool wantDeep = forceDeep || (EnableDeepScan && DeepInterval > TimeSpan.Zero &&
                                      DateTime.UtcNow - _lastDeep >= DeepInterval);
        if (wantDeep)
        {
            DeepScan(found, st);
            _lastDeep = DateTime.UtcNow;

            // 深度扫描没认下任何一个“够可信”的单位？可能是这一版的类内偏移不一样
            // → 自动校准一次，然后按新偏移重扫。
            bool anyStrong = found.Values.Any(v => v.FoundBy == "深度扫描" && v.Confidence >= MinDeepConfidence);
            if (!anyStrong && !_calibrationTried)
            {
                _calibrationTried = true;
                foreach (var a in found.Where(kv => kv.Value.FoundBy == "深度扫描").Select(kv => kv.Key).ToList())
                    found.Remove(a);
                if (Calibrate(st))
                {
                    // 校准后必须【重新全区扫描】：上一次失败时没有任何区域被标记成热区，
                    // 如果只扫热区就会一个字节都不扫（自测里踩过）。
                    _hotRegions.Clear();
                    _lastFullDeep = DateTime.MinValue;
                    DeepScan(found, st);
                }
            }
        }

        // 合并进 known（保留首次发现时间等元数据由 DamageTracker 负责）
        SanitizeFound(found, st);

        // 稳定性过滤：非选区链发现的新单位，要连续两轮都出现才真正开始跟踪。
        // 原因：深度扫描/句柄表偶尔会“凑巧”认出别的内存，只闪一次的那些直接滤掉，
        // 免得它们在账本里生出一条莫名其妙的结算。
        {
            var seenThisScan = new HashSet<uint>(found.Keys);
            foreach (var kv in found.ToList())
            {
                uint a = kv.Key;
                if (_known.ContainsKey(a)) { _pending.Remove(a); continue; }
                if (kv.Value.FoundBy.StartsWith("选区", StringComparison.Ordinal)) { _pending.Remove(a); continue; }

                // 真单位一定有“拥有者”（我们已经自发现过那个字段偏移了，读不到就说明这地址不是单位）。
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
        st.Mode = st.FromDeep > 0 ? "深层扫描" : st.FromHandleTable > 0 ? "句柄表+缓存" : "缓存";
        st.ElapsedMs = sw.ElapsedMilliseconds;

        if (OwnerOffset < 0 && _known.Count > 0) DiscoverOwnerOffset();
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

        return st;
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
        bool anyStrong = byHp.Values.Any(u => Trusted(u) || u.Confidence >= MinDeepConfidence);
        var keep = new List<ScannedUnit>(byHp.Count);
        foreach (var u in byHp.Values)
        {
            if (anyStrong && !Trusted(u) && u.Confidence < MinDeepConfidence) { droppedLow++; continue; }
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
        if (best < 0) st.Notes.Add("句柄表：所有候选地址都无效（改由深度扫描发现单位）");
        st.FromHandleTable = found.Values.Count(v => v.FoundBy == "句柄表");
    }

    // ==================================================================
    // ② 选区链（已实测：sel+0x1F0 / sel+0x08 两组）
    // ==================================================================
    private void ScanSelection(Dictionary<uint, ScannedUnit> found, ScanStats st)
    {
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

    // ==================================================================
    // ③ 全堆深度扫描
    // ==================================================================
    private void DeepScan(Dictionary<uint, ScannedUnit> found, ScanStats st)
    {
        var regions = new List<MemRegion>();
        regions.AddRange(_hotRegions);
        bool full = DateTime.UtcNow - _lastFullDeep > TimeSpan.FromSeconds(60);
        if (full)
        {
            foreach (var r in _g.Mem.Regions)
            {
                if (!IsDeepCandidate(r) || regions.Contains(r)) continue;
                regions.Add(r);
            }
        }

        long budget = MaxDeepTotalBytes;
        foreach (var r in regions)
        {
            if (budget <= 0) break;
            if (!IsDeepCandidate(r)) continue;

            ulong pos = r.Base;
            while (pos < r.End && budget > 0)
            {
                int len = (int)Math.Min((ulong)ChunkSize, r.End - pos);
                var buf = _g.Mem.ReadBytes(pos, len);
                if (buf == null || buf.Length == 0) break;
                budget -= buf.Length;
                st.DeepMb += buf.Length >> 20;
                int hits = ScanBufferForUnits(buf, pos, found, st);
                if (hits > 0 && !_hotRegions.Contains(r)) _hotRegions.Add(r);
                pos += (ulong)buf.Length;
            }
        }
        if (full) _lastFullDeep = DateTime.UtcNow;

        // ---- 降噪：深度扫描靠“特征”找单位，难免扫到“长得像”的内存（比如堆里的字符串 + 一个凑巧的索引）。
        //      两条规则：① 同一个生命对象只能被一个单位认领（真单位的状态对象是独占的），
        //                ② 置信度太低的丢掉（真单位除了生命链，通常还能过坐标/拥有者/魔法）。
        var deepUnits = found.Values.Where(v => v.FoundBy == "深度扫描").ToList();
        if (deepUnits.Count > 0)
        {
            var byHp = new Dictionary<uint, ScannedUnit>();
            foreach (var u in deepUnits)
            {
                if (!byHp.TryGetValue(u.HpIndex, out var cur) || u.Confidence > cur.Confidence)
                {
                    if (cur != null) st.DeepDroppedDuplicate++;
                    byHp[u.HpIndex] = u;
                }
                else st.DeepDroppedDuplicate++;
            }

            var survivors = byHp.Values.ToList();
            var strong = survivors.Where(x => x.Confidence >= MinDeepConfidence).ToList();
            if (strong.Count > 0)
            {
                survivors = strong;
            }
            else
            {
                // 宁可一个都不认，也不要把“长得像的内存”当成单位显示给用户：
                // 报告里会带上候选样本，我拿到诊断报告就能对齐偏移。
                st.DeepDroppedLowConf += survivors.Count;
                st.Notes.Add($"深度扫描：{survivors.Count} 个候选的置信度都 < {MinDeepConfidence}" +
                             $"（最高 {survivors.Max(x => x.Confidence)}）—— 全部丢弃，等校准/改偏移");
                survivors = new List<ScannedUnit>();
            }

            foreach (var u in deepUnits)
                if (!survivors.Contains(u)) { found.Remove(u.Addr); if (u.Confidence < MinDeepConfidence) st.DeepDroppedLowConf++; }
        }

        st.FromDeep = found.Values.Count(v => v.FoundBy == "深度扫描");
        st.Notes.Add($"深度扫描：块 {st.DeepMb} MB，命中 {st.FromDeep} 个，热区 {_hotRegions.Count} 个");
        st.Notes.Add($"漏斗：类型码特征 {st.SigHits} → 生命索引合理 {st.SigWithHpIndex} → " +
                     $"状态对象可读 {st.SigStateReadable} → HP 像样 {st.SigPlausibleHp}（= 认下来的单位数）");
        if (st.DeepDroppedDuplicate > 0 || st.DeepDroppedLowConf > 0)
            st.Notes.Add($"降噪：同一生命对象重复 {st.DeepDroppedDuplicate} 个、置信度不足 {st.DeepDroppedLowConf} 个、" +
                          $"虚表不像 game.dll 的 {st.DeepDroppedNoVtable} 个（已丢弃）");
    }

    private static bool IsDeepCandidate(MemRegion r)
    {
        // 只扫“数据堆”：私有堆 + 映射区（有些版本的对象池是 MEM_MAPPED）。
        // 不扫 MEM_IMAGE（那是 game.dll 的代码/只读段，里面只有类型码字符串，不可能是对象）。
        if (r.Type != Native.MEM_PRIVATE && r.Type != Native.MEM_MAPPED) return false;
        if (r.Size < 0x1000) return false;
        if (r.Size > MaxDeepRegionBytes) return false;
        uint p = r.Protect;
        return (p & (Native.PAGE_READWRITE | Native.PAGE_WRITECOPY)) != 0;
    }

    /// <summary>
    /// 在缓冲里找“像 CUnit 的地方”：类型码特征在 +0x30，且整条生命链自洽。
    /// 只做特征预筛（便宜），真正判定交给 TryReadUnit。
    /// 同时统计“漏斗”（特征命中 → 索引合理 → 状态可读 → HP 像样），
    /// 一个单位都没认出来时这份漏斗就是排障的第一手证据。
    /// </summary>
    private int ScanBufferForUnits(byte[] buf, ulong baseAddr, Dictionary<uint, ScannedUnit> found, ScanStats st)
    {
        int hits = 0;
        bool diagnose = found.Count == 0;      // 一个都还没认出来 → 顺手把失败原因分门别类
        int classifyBudget = diagnose ? 600 : 0;

        int limit = buf.Length - UnitHeaderSize - 4;
        for (int i = 0; i <= limit; i += 4)
        {
            int t = i + (int)Wc3UnitOffset.TypeCode;
            if (!IsTypeCodeBytes(buf[t], buf[t + 1], buf[t + 2], buf[t + 3])) continue;

            uint cand = (uint)(baseAddr + (ulong)i);
            if (found.ContainsKey(cand)) continue;
            st.SigHits++;

            if (!TryReadUnit(cand, out var u, keepTypeCode: null))
            {
                if (classifyBudget > 0)
                {
                    classifyBudget--;
                    ClassifyCandidate(cand, st);
                    if (st.SigSamples.Count < 6) st.SigSamples.Add(cand);
                }
                continue;
            }

            // 深度扫描是"猜"的：必须过虚表这一关，否则堆里到处是"类型码 + 生命链自洽"的巧合
            if (!u.VtableOk) { st.DeepDroppedNoVtable++; continue; }
            u.FoundBy = "深度扫描";
            found[cand] = u;
            hits++;
        }
        return hits;
    }

    /// <summary>给一个“类型码像单位、但整条生命链没过”的候选分类，用于诊断漏斗。</summary>
    private void ClassifyCandidate(uint cand, ScanStats st)
    {
        var hdr = _g.Mem.ReadBytes(cand, UnitHeaderSize);
        if (hdr == null || hdr.Length < UnitHeaderSize) return;

        uint hpIdx = BitConverter.ToUInt32(hdr, (int)HpIndexOffset);
        if (hpIdx == 0 || hpIdx > 0x0020_0000u) return;
        if (_g.CapacityIsSane && hpIdx >= _g.GameMemoryCapacity) return;
        st.SigWithHpIndex++;

        uint state = _g.GameMemoryLookup(hpIdx);
        if (state == 0 || !_g.Mem.IsReadable(state, 0x100)) return;
        st.SigStateReadable++;

        var stBuf = _g.Mem.ReadBytes(state, 0x100);
        if (stBuf == null || stBuf.Length < 0x100) return;
        float cur = BitConverter.ToSingle(stBuf, (int)StateCurOffset);
        float max = BitConverter.ToSingle(stBuf, (int)StateMaxOffset);
        if (PlausibleHp(cur, max)) st.SigPlausibleHp++;
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

    /// <summary>“这对数字像不像（当前HP，最大HP）”。</summary>
    private static bool PlausibleHp(float cur, float max)
    {
        if (float.IsNaN(cur) || float.IsNaN(max) || float.IsInfinity(cur) || float.IsInfinity(max)) return false;
        if (!(max > 0.05f && max < 5_000_000f)) return false;
        if (!(cur > -10_000f && cur <= max * 1.01f + 1f)) return false;
        return true;
    }

    // ==================================================================
    // 偏移自校准：万一这一版的类内偏移和 War3Trainer 那套不一样，
    // 就靠“类型码签名找到的候选单位 + 游戏内存表”反推正确偏移。
    // ==================================================================
    /// <summary>只按“4 字符类型码”特征收集候选（不做生命链校验）。</summary>
    private List<uint> CollectSignatureCandidates(int max, out int scannedMb)
    {
        scannedMb = 0;
        var list = new List<uint>();
        var regions = new List<MemRegion>(_hotRegions);
        foreach (var r in _g.Mem.Regions)
            if (IsDeepCandidate(r) && !regions.Contains(r)) regions.Add(r);

        long budget = MaxDeepTotalBytes;
        foreach (var r in regions)
        {
            if (list.Count >= max || budget <= 0) break;
            ulong pos = r.Base;
            while (pos < r.End && list.Count < max && budget > 0)
            {
                int len = (int)Math.Min((ulong)ChunkSize, r.End - pos);
                var buf = _g.Mem.ReadBytes(pos, len);
                if (buf == null || buf.Length == 0) break;
                budget -= buf.Length;
                scannedMb += buf.Length >> 20;
                int limit = buf.Length - UnitHeaderSize - 4;
                for (int i = 0; i <= limit; i += 4)
                {
                    int t = i + (int)Wc3UnitOffset.TypeCode;
                    if (!IsTypeCodeBytes(buf[t], buf[t + 1], buf[t + 2], buf[t + 3])) continue;
                    list.Add((uint)(pos + (ulong)i));
                    if (list.Count >= max) break;
                }
                pos += (ulong)buf.Length;
            }
        }
        return list;
    }

    /// <summary>
    /// 校准 CUnit 里的字段偏移：对每个候选单位，在 0x40~0x200 里找“能查到游戏内存表、且对象里有像 HP 的一对数字”的字段。
    /// 多个单位投票一致才采用。
    /// </summary>
    public bool Calibrate(ScanStats? st = null)
    {
        // 候选要尽量多：真实的单位可能排在一堆“长得像”的内存后面，候选截断太狠就会漏掉它们。
        var cands = CollectSignatureCandidates(6000, out int scannedMb);
        if (cands.Count < 3)
        {
            CalibrationInfo = $"签名候选只有 {cands.Count} 个（扫了 {scannedMb}MB），无法校准";
            Log.Warn(CalibrationInfo);
            st?.Notes.Add(CalibrationInfo);
            return false;
        }

        // 投票：键 = (字段偏移, 当前HP在对象里的偏移)，值 = 这些候选各自指向的【不同】状态对象集合。
        // 为什么要“不同对象数”而不是“票数”：真单位的生命索引各自指向自己的状态对象（一人一个），
        // 而凑巧命中的假候选往往几十个都指向同一个对象 —— 用“不同对象数”当分数才能把两者分开。
        //
        // 还要挡掉“当前HP恒为 0”的退化解：对象里 cur 和 max 的关系是 max = cur + 12，
        // 所以 (真cur-12, 真cur) 也能凑出一个合法但没意义的解（那个“cur”其实是空数据）。
        // 真实单位里总有一部分是活的（cur > 0），退化解则人人都是 0。
        var pairStats = new Dictionary<(uint Off, uint Cur), (HashSet<uint> Objects, int CurPositive)>();
        var offCandidates = new HashSet<uint>();

        foreach (var c in cands)
        {
            var hdr = _g.Mem.ReadBytes(c, UnitHeaderSize);
            if (hdr == null || hdr.Length < UnitHeaderSize) continue;
            offCandidates.Add(c);

            for (uint off = 0x40; off + 4 <= UnitHeaderSize; off += 4)
            {
                uint idx = BitConverter.ToUInt32(hdr, (int)off);
                if (idx == 0 || idx > 0x0010_0000u) continue;
                if (_g.CapacityIsSane && idx >= _g.GameMemoryCapacity) continue;

                uint obj = _g.GameMemoryLookup(idx);
                if (obj == 0 || !_g.Mem.IsReadable(obj, 0x100)) continue;

                var b = _g.Mem.ReadBytes(obj, 0x100);
                if (b == null || b.Length < 0x100) continue;

                for (uint k = 0; k + 16 <= 0x100; k += 4)
                {
                    float cur = BitConverter.ToSingle(b, (int)k);
                    float max = BitConverter.ToSingle(b, (int)(k + 12));
                    if (!PlausibleHp(cur, max)) continue;

                    // 注意：这里【不能】找到一个就 break —— 同一个对象里往往有多个“看着合法”的
                    // (cur,max) 组合（比如 cur=0,max=真cur 也能过），必须全都投出来，
                    // 再交给“不同对象数 + 有多少个是活的”去排序。
                    if (!pairStats.TryGetValue((off, k), out var stat))
                        pairStats[(off, k)] = stat = (new HashSet<uint>(), 0);
                    stat.Objects.Add(obj);
                    if (cur > 0.05f) stat.CurPositive++;
                    pairStats[(off, k)] = stat;
                }
            }
        }

        if (pairStats.Count == 0)
        {
            CalibrationInfo = $"校准失败：{cands.Count} 个候选里没有任何字段能映射到生命对象";
            Log.Warn(CalibrationInfo);
            st?.Notes.Add(CalibrationInfo);
            return false;
        }

        var ranked = pairStats.OrderByDescending(kv => kv.Value.Objects.Count).ToList();
        string top3 = string.Join("；", ranked.Take(3).Select(kv =>
            $"0x{kv.Key.Off:X}/0x{kv.Key.Cur:X}→{kv.Value.Objects.Count}对象/活{kv.Value.CurPositive}"));

        // 只考虑“不是全员 cur=0”的解；同分时优先靠近默认偏移的那个字段
        // （生命索引在 0xA0 附近，魔法索引在 0xC0 附近，两者的对象里都有像 HP 的一对数，
        //  所以同分时必须往默认值那边靠，否则可能把“魔法”当成“生命”）。
        var viable = ranked
            .Where(kv => kv.Value.CurPositive >= Math.Max(1, kv.Value.Objects.Count / 3))
            .OrderByDescending(kv => kv.Value.Objects.Count)
            .ThenBy(kv => Math.Abs((int)kv.Key.Off - (int)Wc3UnitOffset.HpIndex))
            .ThenByDescending(kv => kv.Value.CurPositive)
            .ToList();
        if (viable.Count == 0)
        {
            CalibrationInfo = $"校准失败：所有解都是“当前HP 恒为 0”的退化解。候选：{top3}";
            Log.Warn(CalibrationInfo);
            st?.Notes.Add(CalibrationInfo);
            return false;
        }

        var best = viable[0];
        int distinct = best.Value.Objects.Count;
        int need = Math.Max(3, Math.Min(8, offCandidates.Count / 20));
        if (distinct < need)
        {
            CalibrationInfo = $"校准票数不足：最高只有 {distinct} 个不同的生命对象（需要 {need}）。候选：{top3}";
            Log.Warn(CalibrationInfo);
            st?.Notes.Add(CalibrationInfo);
            return false;
        }

        HpIndexOffset = best.Key.Off;
        StateCurOffset = best.Key.Cur;
        StateMaxOffset = best.Key.Cur + 12;
        CalibrationInfo = $"已自动校准：生命索引 = CUnit+0x{HpIndexOffset:X}，当前HP = 对象+0x{StateCurOffset:X}，" +
                          $"最大HP = 对象+0x{StateMaxOffset:X}（{distinct} 个互不相同的生命对象，其中 {best.Value.CurPositive} 个是活的）。" +
                          $"候选排行：{top3}";
        Log.Write(CalibrationInfo);
        st?.Notes.Add(CalibrationInfo);
        return true;
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
        if (_g.CapacityIsSane && hpIdx >= _g.GameMemoryCapacity) return false;

        uint state = _g.GameMemoryLookup(hpIdx);
        if (state == 0 || !_g.Mem.IsReadable(state, 0x100)) return false;

        var stBuf = _g.Mem.ReadBytes(state, 0x100);
        if (stBuf == null || stBuf.Length < 0x90) return false;

        float hp = BitConverter.ToSingle(stBuf, (int)StateCurOffset);
        float max = BitConverter.ToSingle(stBuf, (int)StateMaxOffset);
        if (!PlausibleHp(hp, max)) return false;

        u.TypeCode = tc;
        u.HpIndex = hpIdx;
        u.Hp = hp;
        u.HpMax = max;
        u.Armor = BitConverter.ToSingle(hdr, (int)Wc3UnitOffset.ArmorAmount);

        int score = 2;   // 生命链过关 = 2 分（真实单位至少还有下面的 1 分）

        // vtable：真 CUnit 的 +0x00 是 game.dll 里的虚表指针（实机头部 04 A7 99 7C，
        // 而 game.dll 基址 0x7BF50000 ⇒ 0x7C99A704 正落在 game.dll 映像内）。
        // 这条几乎是免费的，但能一票筛掉海量“凑巧像单位”的堆内存 —— 实机上
        // 深度扫描曾一次给出 2513 个重复 + 1266 个低置信度候选，就是缺这一条。
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

        // 拥有者：已知偏移就按偏移读，否则在头部里找任意一个 CPlayer*（+1 分，也顺便当校验）
        if (OwnerOffset >= 0 && OwnerOffset + 4 <= hdr.Length)
        {
            uint owner = BitConverter.ToUInt32(hdr, OwnerOffset);
            int slot = Array.IndexOf(Players, owner);
            u.OwnerSlot = owner != 0 ? slot : -1;
            if (slot >= 0) score++;
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

    // ==================================================================
    // 拥有者字段自发现：在单位头里找“指向某个 CPlayer* 的字段”
    // ==================================================================
    private void DiscoverOwnerOffset()
    {
        var votes = new Dictionary<int, int>();
        int examined = 0;
        foreach (var unit in _known.Values.Take(24))
        {
            var hdr = _g.Mem.ReadBytes(unit.Addr, 0x800);
            if (hdr == null || hdr.Length < 0x800) continue;
            examined++;

            // 取【最小】的那个命中偏移：单位自己的字段一定排在“隔壁对象”的字段之前。
            // （早先要求“整段只有 1 个命中”，结果单位挨着单位时，读 0x800 会读进下一个单位，
            //   于是每个单位都有 2 个命中 → 投票恒为空，拥有者永远发现不了。500 单位自测里踩到。）
            int hit = -1;
            for (int off = 0; off + 4 <= hdr.Length; off += 4)
            {
                uint v = BitConverter.ToUInt32(hdr, off);
                if (v == 0) continue;
                if (Array.IndexOf(Players, v) >= 0) { hit = off; break; }
            }
            if (hit >= 0) votes[hit] = votes.GetValueOrDefault(hit) + 1;
        }

        var best = votes.OrderByDescending(kv => kv.Value).FirstOrDefault();
        if (best.Value >= Math.Max(2, examined / 2) && best.Value > 0)
        {
            OwnerOffset = best.Key;
            Log.Write($"拥有者字段自发现：CUnit+0x{OwnerOffset:X}（{best.Value}/{examined} 个单位一致）");
        }
        else
        {
            // 节流：这条以前每轮扫描都刷，能在 1 分钟里刷出几十 KB，把有用的日志埋掉
            if (DateTime.UtcNow - _lastOwnerWarn > TimeSpan.FromSeconds(60))
            {
                _lastOwnerWarn = DateTime.UtcNow;
                Log.Warn($"拥有者字段自发现失败（候选 {votes.Count} 个，最多 {best.Value}/{examined}）—— 归属显示为 ?（这条每 60 秒最多提示一次）");
            }
        }
    }

    private void ApplyOwners(Dictionary<uint, ScannedUnit> found)
    {
        foreach (var kv in found)
        {
            var hdr = _g.Mem.ReadBytes((ulong)kv.Key + (ulong)OwnerOffset, 4);
            if (hdr == null || hdr.Length < 4) continue;
            uint owner = BitConverter.ToUInt32(hdr, 0);
            int slot = owner != 0 ? Array.IndexOf(Players, owner) : -1;
            kv.Value.OwnerSlot = slot;
        }
    }

    /// <summary>清空已知单位（换图/重开时用）。</summary>
    public void Reset()
    {
        _known.Clear();
        _hotRegions.Clear();
        OwnerOffset = -1;
        _lastDeep = DateTime.MinValue;
        _lastFullDeep = DateTime.MinValue;
        _calibrationTried = false;   // 偏移校准结果保留（换图不影响类内布局）
    }
}





