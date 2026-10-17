namespace War3DeathSettlement.Core;

/// <summary>
/// 伤害记账 + 死亡结算。
///
/// 数据来源是【轮询到的生命值变化】：
///   掉血 → 记一笔伤害；回血 → 记一笔治疗；
///   生命从 &gt;0 变 ≤0 → 该单位死亡 → 立即生成“死亡结算”；
///   单位突然读不到且生命还 &gt;0 → 说明它被销毁/移出游戏 → 生成“消失结算”。
///
/// 这层完全不碰进程内存（只吃 Scanner 的结果），所以可以单独用假数据自检。
/// </summary>
public sealed class DamageTracker
{
    private readonly UnitScanner? _scanner;
    private readonly Dictionary<uint, UnitTrack> _tracks = new();
    /// <summary>生命对象索引 → 账本。用它当“单位身份”：地址可能变，生命对象不会。</summary>
    private readonly Dictionary<uint, UnitTrack> _byHpIndex = new();

    public DamageTracker(UnitScanner? scanner = null) => _scanner = scanner;

    public IReadOnlyDictionary<uint, UnitTrack> Tracks => _tracks;
    public List<Settlement> Settlements { get; } = new();
    public int InstanceCount => _tracks.Count;

    /// <summary>小于这个掉血量当作浮点噪声，不记（默认 0.1）。</summary>
    public double MinDamage { get; set; } = 0.1;
    /// <summary>连续多久没再看到该单位，就认为它已消失（默认 2.5 秒，抗一次读失败）。</summary>
    public TimeSpan GoneGrace { get; set; } = TimeSpan.FromSeconds(2.5);
    /// <summary>只记这么多条结算（超了丢最旧）。</summary>
    public int MaxSettlements { get; set; } = 20000;

    /// <summary>产生一条结算时触发（在记账线程上）。</summary>
    public event Action<Settlement>? Settled;

    public UnitTrack? GetTrack(uint addr) => _tracks.TryGetValue(addr, out var t) ? t : null;

    /// <summary>把旧的结算历史搬过来（换局/重连时保留整场会话的记录，新账本照样从零开始）。</summary>
    public void SeedHistory(IEnumerable<Settlement> previous)
    {
        Settlements.AddRange(previous);
        while (Settlements.Count > MaxSettlements) Settlements.RemoveAt(0);
    }

    public void Clear()
    {
        _tracks.Clear();
        _byHpIndex.Clear();
        Settlements.Clear();
    }

    /// <summary>彻底忘掉这个单位（连生命对象索引映射一起清掉）。</summary>
    private void Forget(UnitTrack t)
    {
        if (t.HpIndex != 0 && _byHpIndex.TryGetValue(t.HpIndex, out var cur) && ReferenceEquals(cur, t))
            _byHpIndex.Remove(t.HpIndex);
        _tracks.Remove(t.Addr);
    }

    /// <summary>吃一轮扫描结果，更新账本并结算。</summary>
    public void Update(IReadOnlyDictionary<uint, ScannedUnit> scan, DateTime now)
    {
        // ---- 1. 在扫描结果里的单位 --------------------------------------
        foreach (var kv in scan)
        {
            var u = kv.Value;
            if (!_tracks.TryGetValue(u.Addr, out var t))
            {
                // 地址没见过，但生命对象见过 → 就是同一个单位换了地址（复活/对象搬迁/候选漂移），
                // 跟着它继续记账，而不是当成新单位（否则会多出一条莫名其妙的结算）。
                if (u.HpIndex != 0 && _byHpIndex.TryGetValue(u.HpIndex, out var same) && !same.Gone)
                {
                    uint oldAddr = same.Addr;
                    _tracks.Remove(oldAddr);
                    same.Addr = u.Addr;
                    _tracks[u.Addr] = same;
                    t = same;
                    Log.Write($"单位（{same.TypeCode} 生命对象 {u.HpIndex}）地址 0x{oldAddr:X8} → 0x{u.Addr:X8}，按同一个单位继续记账");
                }
                else
                {
                    t = new UnitTrack { Addr = u.Addr };
                    t.ResetForNewInstance(now, u);
                    _tracks[u.Addr] = t;
                    if (u.HpIndex != 0) _byHpIndex[u.HpIndex] = t;
                    continue;
                }
            }

            if (t.Gone)
            {
                // 已经结算过的实例。尸体还留在地图上（血 ≤ 0）就继续忽略；
                // 血回到正数（复活/重建），或者地址被新单位复用（满血）→ 当作新的一条命。
                if (u.Hp > 0f) t.ResetForNewInstance(now, u);
                else t.LastSeen = now;
                continue;
            }

            // 同一地址换了类型码 → 认为旧单位已被销毁、这是新单位的实例
            if (!string.Equals(t.TypeCode, u.TypeCode, StringComparison.Ordinal))
            {
                if (t.HpIndex != 0 && _byHpIndex.TryGetValue(t.HpIndex, out var me) && ReferenceEquals(me, t))
                    _byHpIndex.Remove(t.HpIndex);
                t.ResetForNewInstance(now, u);
                if (t.HpIndex != 0) _byHpIndex[t.HpIndex] = t;
                continue;
            }

            // 死亡后血量回到正数 → 复活 / 重生 → 开新账
            // （掉到 0/负 之后又回到接近满血，更可能是“重生”而不是被治疗 —— 治疗一般不会恰好回满）
            if (t.Dead && u.Hp > 0f)
            {
                t.ResetForNewInstance(now, u);
                continue;
            }
            if (t.LastHp <= 0f && u.Hp > 0f && u.HpMax > 0f && u.Hp >= u.HpMax * 0.99f)
            {
                Log.Write($"单位 0x{u.Addr:X8}（{u.TypeCode}）血量从 0 直接回到满血 {u.Hp:0.#} —— 按“重生”开新账");
                t.ResetForNewInstance(now, u);
                continue;
            }

            double delta = t.LastHp - u.Hp;
            if (delta > MinDamage)
            {
                bool fatal = t.LastHp > 0f && u.Hp <= 0f;
                var ev = new DamageEvent { Time = now, Amount = delta, HpAfter = u.Hp, Fatal = fatal };
                t.Events.Add(ev);
                t.TotalDamage += delta;
                if (delta > t.MaxHit) t.MaxHit = delta;
                if (delta < t.MinHit) t.MinHit = delta;
                t.FirstHit ??= now;
                t.LastHit = now;

                if (fatal)
                {
                    t.Dead = true;
                    Settle(t, now, "死亡");
                    continue;
                }
            }
            else if (delta < -MinDamage)
            {
                t.TotalHeal += -delta;
            }

            t.LastSeen = now;
            t.LastHp = u.Hp;
            t.LastHpMax = u.HpMax;
            t.OwnerSlot = u.OwnerSlot;
            t.X = u.X;
            t.Y = u.Y;
        }

        // ---- 2. 扫描结果里没了的单位：确认真没了再结算 ----------------
        List<uint>? missing = null;
        List<uint>? purge = null;
        foreach (var kv in _tracks)
        {
            if (kv.Value.Gone)
            {
                // 已结算的实例：地图早就没它了（比如尸体烂掉）就回收，避免账本无限膨胀
                if (now - kv.Value.LastSeen > TimeSpan.FromMinutes(10)) (purge ??= new List<uint>()).Add(kv.Key);
                continue;
            }
            if (scan.ContainsKey(kv.Key)) continue;
            if (now - kv.Value.LastSeen < GoneGrace) continue;
            (missing ??= new List<uint>()).Add(kv.Key);
        }

        if (purge != null)
            foreach (uint a in purge)
                if (_tracks.TryGetValue(a, out var pt)) Forget(pt);

        if (missing == null) return;

        // 大面积同时“消失”（超过一半、且不止一两个）通常是地图结束/退游戏/重开局，
        // 不是被打死 —— 这种情况只丢账，不出结算，免得刷一堆假的“消失”。
        int liveTracks = _tracks.Count - (_tracks.Values.Count(t => t.Gone));
        if (missing.Count >= 3 && liveTracks > 0 && missing.Count * 2 > liveTracks)
        {
            Log.Warn($"检测到 {missing.Count}/{liveTracks} 个单位同时消失 —— 按“地图结束/退游戏”处理，不生成结算");
            foreach (uint a in missing)
                if (_tracks.TryGetValue(a, out var mt)) Forget(mt);
            return;
        }

        foreach (uint addr in missing)
        {
            var t = _tracks[addr];

            // 最后再读一次：能读到就说明只是这一轮没枚举到
            if (_scanner != null && _scanner.TryReadUnit(addr, out var last, t.TypeCode))
            {
                if (last.Hp > 0f)
                {
                    t.LastSeen = now;
                    t.LastHp = last.Hp;
                    t.LastHpMax = last.HpMax;
                    continue;
                }
                t.Dead = true;
                Settle(t, now, "死亡");
                continue;
            }

            // 读不到了：血还 >0 说明是被销毁/移出游戏（不是被打死）
            Settle(t, now, t.LastHp > 0f ? "消失" : "死亡");
        }
    }

    private void Settle(UnitTrack t, DateTime now, string kind)
    {
        double minHit = t.MinHit < double.MaxValue ? t.MinHit : 0;
        var s = new Settlement
        {
            Addr = t.Addr,
            TypeCode = t.TypeCode,
            OwnerSlot = t.OwnerSlot,
            InstanceIndex = t.InstanceIndex,
            DiedAt = now,
            FirstSeen = t.FirstSeen,
            FirstHit = t.FirstHit,
            LastHit = t.LastHit,
            HitCount = t.Events.Count,
            TotalDamage = t.TotalDamage,
            TotalHeal = t.TotalHeal,
            MaxHit = t.MaxHit,
            MinHit = minHit,
            HpMax = t.StartHpMax,
            X = t.X,
            Y = t.Y,
            Kind = kind,
            Events = t.Events.ToArray(),
            Peak1s = Peak(t.Events, 1.0),
            HpAtFirstSeen = t.HpAtFirstSeen,
        };

        // 保留这条 track（标记 Gone）：尸体还留在地图上时不能重复结算；
        // 10 分钟没再见到会自动回收（见 Update 里的 purge）。
        // 生命对象索引的映射要摘掉：以后再有单位占用同一个索引，那就是新的账本。
        t.Gone = true;
        if (t.HpIndex != 0 && _byHpIndex.TryGetValue(t.HpIndex, out var owner) && ReferenceEquals(owner, t))
            _byHpIndex.Remove(t.HpIndex);

        Settlements.Add(s);
        while (Settlements.Count > MaxSettlements) Settlements.RemoveAt(0);
        try { Settled?.Invoke(s); } catch { }
    }

    /// <summary>窗口内最大承伤（默认 1 秒内的伤害合计），也就是“最惨的一秒”。</summary>
    private static double Peak(IReadOnlyList<DamageEvent> events, double windowSeconds)
    {
        if (events.Count == 0) return 0;
        double best = 0;
        int j = 0;
        double sum = 0;
        for (int i = 0; i < events.Count; i++)
        {
            sum += events[i].Amount;
            while (j <= i && (events[i].Time - events[j].Time).TotalSeconds > windowSeconds)
            {
                sum -= events[j].Amount;
                j++;
            }
            if (sum > best) best = sum;
        }
        return best;
    }
}
