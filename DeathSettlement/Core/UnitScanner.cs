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
    private const int MaxDeepRegionBytes = 384 << 20;   // 单区域超过 384MB 跳过（地图资源堆，没有单位）
    private const int MaxDeepTotalBytes = 1600 << 20;   // 一次深度扫描总预算

    private readonly Wc3Game _g;
    private readonly Dictionary<uint, ScannedUnit> _known = new();
    private readonly List<MemRegion> _hotRegions = new();
    private DateTime _lastDeep = DateTime.MinValue;
    private DateTime _lastFullDeep = DateTime.MinValue;

    public UnitScanner(Wc3Game game) => _g = game;

    public IReadOnlyDictionary<uint, ScannedUnit> Known => _known;
    public ScanStats LastStats { get; } = new();

    /// <summary>深度扫描间隔（发现新单位）。设为 Zero 表示只在需要时手工扫。</summary>
    public TimeSpan DeepInterval { get; set; } = TimeSpan.FromSeconds(8);
    public bool EnableDeepScan { get; set; } = true;

    /// <summary>自动发现的“拥有者”字段偏移（在 CUnit 里的位置）。</summary>
    public int OwnerOffset { get; private set; } = -1;
    /// <summary>玩家对象数组（用于把单位映射到玩家）。</summary>
    public uint[] Players { get; private set; } = new uint[16];

    // ==================================================================
    // 主入口
    // ==================================================================
    public ScanStats Scan(bool forceDeep = false)
    {
        var st = LastStats;
        st.Notes.Clear();
        st.FromHandleTable = st.FromSelection = st.FromDeep = st.Refreshed = st.DeepMb = st.SelectedUnits = 0;
        st.HandleTable = 0; st.HandleTableName = ""; st.HandleSlots = st.HandleValid = 0; st.Mode = "";
        var sw = Stopwatch.StartNew();

        if (!_g.IsReady)
        {
            st.Known = 0;
            st.ElapsedMs = sw.ElapsedMilliseconds;
            return st;
        }

        Players = _g.ReadPlayerObjects();

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
        TryHandleTable(found, st);

        // ③ 选区链（实测可用的锚点；也用来校准“什么才算一个单位”）
        ScanSelection(found, st);

        // ④ 深度扫描（定期，兜底发现全部单位）
        bool wantDeep = forceDeep || (EnableDeepScan && DeepInterval > TimeSpan.Zero &&
                                      DateTime.UtcNow - _lastDeep >= DeepInterval);
        if (wantDeep)
        {
            DeepScan(found, st);
            _lastDeep = DateTime.UtcNow;
        }

        // 合并进 known（保留首次发现时间等元数据由 DamageTracker 负责）
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
        if (OwnerOffset >= 0) ApplyOwners(found);

        return st;
    }

    // ==================================================================
    // ① 句柄表
    // ==================================================================
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
                int hits = ScanBufferForUnits(buf, pos, found);
                if (hits > 0 && !_hotRegions.Contains(r)) _hotRegions.Add(r);
                pos += (ulong)buf.Length;
            }
        }
        if (full) _lastFullDeep = DateTime.UtcNow;
        st.FromDeep = found.Values.Count(v => v.FoundBy == "深度扫描");
        st.Notes.Add($"深度扫描：块 {st.DeepMb} MB，命中 {st.FromDeep} 个，热区 {_hotRegions.Count} 个");
    }

    private static bool IsDeepCandidate(MemRegion r)
    {
        if (r.Type != Native.MEM_PRIVATE) return false;
        if (r.Size < 0x1000) return false;
        if (r.Size > MaxDeepRegionBytes) return false;
        uint p = r.Protect;
        return (p & (Native.PAGE_READWRITE | Native.PAGE_WRITECOPY)) != 0;
    }

    /// <summary>
    /// 在缓冲里找“像 CUnit 的地方”：类型码特征在 +0x30，且整条生命链自洽。
    /// 只做特征预筛（便宜），真正判定交给 TryReadUnit。
    /// </summary>
    private int ScanBufferForUnits(byte[] buf, ulong baseAddr, Dictionary<uint, ScannedUnit> found)
    {
        int hits = 0;
        int limit = buf.Length - UnitHeaderSize - 4;
        for (int i = 0; i <= limit; i += 4)
        {
            int t = i + (int)Wc3UnitOffset.TypeCode;
            if (!IsTypeCodeBytes(buf[t], buf[t + 1], buf[t + 2], buf[t + 3])) continue;

            uint cand = (uint)(baseAddr + (ulong)i);
            if (found.ContainsKey(cand)) continue;
            if (!TryReadUnit(cand, out var u, keepTypeCode: null)) continue;

            u.FoundBy = "深度扫描";
            found[cand] = u;
            hits++;
        }
        return hits;
    }

    private static bool IsTypeCodeBytes(byte a, byte b, byte c, byte d)
    {
        if (!IsAlnum(a) || !IsAlnum(b) || !IsAlnum(c) || !IsAlnum(d)) return false;
        // 至少一个英文字母（纯数字/纯符号多半是数据而不是类型码）
        return IsAlpha(a) || IsAlpha(b) || IsAlpha(c) || IsAlpha(d);
    }

    private static bool IsAlnum(byte b) => (b >= '0' && b <= '9') || (b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z') || b == '_';
    private static bool IsAlpha(byte b) => (b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z');

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
            tc = "" + (char)hdr[t] + (char)hdr[t + 1] + (char)hdr[t + 2] + (char)hdr[t + 3];
        }

        uint hpIdx = BitConverter.ToUInt32(hdr, (int)Wc3UnitOffset.HpIndex);
        if (hpIdx == 0 || hpIdx > 0x0020_0000u) return false;

        uint state = _g.GameMemoryLookup(hpIdx);
        if (state == 0 || !_g.Mem.IsReadable(state, 0x100)) return false;

        var stBuf = _g.Mem.ReadBytes(state, 0x100);
        if (stBuf == null || stBuf.Length < 0x90) return false;

        float hp = BitConverter.ToSingle(stBuf, (int)Wc3UnitOffset.StateCur);
        float max = BitConverter.ToSingle(stBuf, (int)Wc3UnitOffset.StateMax);
        if (float.IsNaN(hp) || float.IsNaN(max) || float.IsInfinity(hp) || float.IsInfinity(max)) return false;
        if (!(max > 0.05f && max < 5_000_000f)) return false;
        if (!(hp > -10_000f && hp <= max * 1.01f + 1f)) return false;

        u.TypeCode = tc;
        u.HpIndex = hpIdx;
        u.Hp = hp;
        u.HpMax = max;
        u.Armor = BitConverter.ToSingle(hdr, (int)Wc3UnitOffset.ArmorAmount);

        // 蓝（读不到不影响判定）
        uint mpIdx = BitConverter.ToUInt32(hdr, (int)Wc3UnitOffset.MpIndex);
        if (mpIdx != 0 && mpIdx <= 0x0020_0000u)
        {
            uint ms = _g.GameMemoryLookup(mpIdx);
            if (ms != 0 && _g.Mem.IsReadable(ms, 0x90))
            {
                var mb = _g.Mem.ReadBytes(ms, 0x90);
                if (mb != null && mb.Length >= 0x88)
                {
                    u.Mp = BitConverter.ToSingle(mb, (int)Wc3UnitOffset.StateCur);
                    u.MpMax = BitConverter.ToSingle(mb, (int)Wc3UnitOffset.StateMax);
                }
            }
        }

        // 坐标（读不到不影响判定）
        uint posIdx = BitConverter.ToUInt32(hdr, (int)Wc3UnitOffset.PositionIndex);
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
                    }
                }
            }
        }

        if (OwnerOffset >= 0 && OwnerOffset + 4 <= hdr.Length)
        {
            uint owner = BitConverter.ToUInt32(hdr, OwnerOffset);
            int slot = Array.IndexOf(Players, owner);
            u.OwnerSlot = owner != 0 ? slot : -1;
        }

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
            var hits = new List<int>();
            for (int off = 0; off + 4 <= hdr.Length; off += 4)
            {
                uint v = BitConverter.ToUInt32(hdr, off);
                if (v == 0) continue;
                if (Array.IndexOf(Players, v) >= 0) hits.Add(off);
            }
            if (hits.Count == 1) votes[hits[0]] = votes.GetValueOrDefault(hits[0]) + 1;
        }

        var best = votes.OrderByDescending(kv => kv.Value).FirstOrDefault();
        if (best.Value >= Math.Max(2, examined / 2) && best.Value > 0)
        {
            OwnerOffset = best.Key;
            Log.Write($"拥有者字段自发现：CUnit+0x{OwnerOffset:X}（{best.Value}/{examined} 个单位一致）");
        }
        else
        {
            Log.Warn($"拥有者字段自发现失败（候选 {votes.Count} 个，最多 {best.Value}/{examined}）—— 归属显示为 ?");
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
    }
}
