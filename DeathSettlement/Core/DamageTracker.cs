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

    public void Clear()
    {
        _tracks.Clear();
        Settlements.Clear();
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
                t = new UnitTrack { Addr = u.Addr };
                t.ResetForNewInstance(now, u);
                _tracks[u.Addr] = t;
                continue;
            }

            if (t.Gone) continue;

            // 同一地址换了类型码 → 认为旧单位已被销毁、这是新单位的实例
            if (!string.Equals(t.TypeCode, u.TypeCode, StringComparison.Ordinal))
            {
                t.ResetForNewInstance(now, u);
                continue;
            }

            // 死亡后血量回到正数 → 复活 / 重生 → 开新账
            if (t.Dead && u.Hp > 0f)
            {
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
        foreach (var kv in _tracks)
        {
            if (kv.Value.Gone || scan.ContainsKey(kv.Key)) continue;
            if (now - kv.Value.LastSeen < GoneGrace) continue;
            (missing ??= new List<uint>()).Add(kv.Key);
        }
        if (missing == null) return;

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
        };

        t.Gone = true;
        _tracks.Remove(t.Addr);

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
