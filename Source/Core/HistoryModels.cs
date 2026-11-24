namespace War3DeathSettlement.Core;

/// <summary>ddh 当前游戏状态会话的历史视图。C# 不保存、不迁移、不兼容旧历史库。</summary>
public sealed class HistoryDocument
{
    public string SessionId { get; set; } = "";
    public DateTimeOffset StartedAt { get; set; }
    public DateTimeOffset EndedAt { get; set; }
    public string MapName { get; set; } = "";
    public int UnitCount { get; set; }
    public int EventsTotal { get; set; }
    public bool Truncated { get; set; }
    public List<HistorySettlement> Settlements { get; set; } = new();
    public List<HistoryEvent> Events { get; set; } = new();
    public List<HistoryUnit> Units { get; set; } = new();
}

public sealed class HistoryUnit
{
    public uint Addr { get; set; }
    public string TypeCode { get; set; } = "";
    public string Name { get; set; } = "";
    public string Title { get; set; } = "";
    public int OwnerSlot { get; set; } = -1;
    public double? AttackRange { get; set; }
    public double? DamageMin { get; set; }
    public double? DamageMax { get; set; }
    public double? AttackSpeed { get; set; }
    public double? AttackInterval { get; set; }
    public double? Armor { get; set; }
    public double? MoveSpeed { get; set; }
    public double? SightDay { get; set; }
    public double? SightNight { get; set; }
    public double? AcquireRange { get; set; }
    public double? Strength { get; set; }
    public double? Agility { get; set; }
    public double? Intelligence { get; set; }
    public bool Dead { get; set; }
    public bool IsIllusion { get; set; }

    public string DisplayName
    {
        get
        {
            string name = Name ?? "";
            if (!IsIllusion ||
                name.Contains("（镜像）", StringComparison.Ordinal) ||
                name.Contains("(镜像)", StringComparison.Ordinal))
                return name;
            return name + "（镜像）";
        }
    }
}

public sealed class HistorySettlement
{
    public DateTime DiedAt { get; set; }
    public DateTime FirstSeen { get; set; }
    public string UnitName { get => _unitName; set => _unitName = Wc3Text.Clean(value); }
    private string _unitName = "";
    public string Title { get => _title; set => _title = Wc3Text.Clean(value); }
    private string _title = "";
    public string TypeCode { get; set; } = "";
    public uint Addr { get; set; }
    public int OwnerSlot { get; set; } = -1;
    public string Kind { get; set; } = "死亡";
    public int InstanceIndex { get; set; } = 1;
    public int HitCount { get; set; }
    public double TotalDamage { get; set; }
    public double MaxHit { get; set; }
    public long FirstTick { get; set; }
    public long LastTick { get; set; }
    public double MinHit { get; set; }
    public double Peak1s { get; set; }
    public double Dps { get; set; }
    public double LifetimeSeconds { get; set; }
    public double CombatSeconds { get; set; }
    public double HpMax { get; set; }
    public float HpAtFirstSeen { get; set; }
    public float Armor { get; set; } = float.NaN;
    public int AttackHits { get; set; }
    public double AttackMin { get; set; }
    public double AttackMax { get; set; }
    public double AttackSum { get; set; }
    public double AttackInterval { get; set; }
    public string Skills { get; set; } = "";
    public double TotalHeal { get; set; }
    public float X { get; set; }
    public float Y { get; set; }
    public double HookDamageScale { get; set; } = 1.0;
    public string HookMatchNote { get; set; } = "";
    public List<HistorySource> Sources { get; set; } = new();
    public List<HistoryCombo> Combos { get; set; } = new();
}

public sealed class HistorySource
{
    public string Source { get => _source; set => _source = Wc3Text.Clean(value); }
    private string _source = "";
    public int Count { get; set; }
    public double Damage { get; set; }
    public double Engine { get; set; }
    public bool EngineValid { get; set; }
    public double Effective { get; set; }
    public bool EffectiveValid { get; set; }
    public double NetDrop { get; set; }
    public bool NetValid { get; set; }
    public double Percent { get; set; }

    public HookBreakdown.SourceRow ToSourceRow() =>
        new(Source, Count, Damage, Engine, EngineValid, Effective, EffectiveValid, NetDrop, NetValid, Percent);
}

public sealed class HistoryCombo
{
    public string Source { get => _source; set => _source = Wc3Text.Clean(value); }
    private string _source = "";
    public string IsAttack { get; set; } = "0";
    public string IsRanged { get; set; } = "0";
    public string AttackType { get; set; } = "";
    public string DamageType { get; set; } = "";
    public int Count { get; set; }
    public double Damage { get; set; }
    public double Engine { get; set; }
    public bool EngineValid { get; set; }
    public double Effective { get; set; }
    public bool EffectiveValid { get; set; }
    public double NetDrop { get; set; }
    public bool NetValid { get; set; }
    public double Percent { get; set; }

    public HookBreakdown.Combination ToCombination() =>
        new(Source, IsAttack, IsRanged, AttackType, DamageType, Count, Damage, Engine, EngineValid,
            Effective, EffectiveValid, NetDrop, NetValid, Percent);
}

public sealed class HistoryEvent
{
    public uint Seq { get; set; }
    public DateTime At { get; set; }
    public long TickMs { get; set; }
    public uint Victim { get; set; }
    public string VictimCode { get; set; } = "";
    public string VictimName { get => _victimName; set => _victimName = Wc3Text.Clean(value); }
    private string _victimName = "";
    public string VictimTitle { get => _victimTitle; set => _victimTitle = Wc3Text.Clean(value); }
    private string _victimTitle = "";
    public uint Source { get; set; }
    public string SourceCode { get; set; } = "";
    public string SourceName { get => _sourceName; set => _sourceName = Wc3Text.Clean(value); }
    private string _sourceName = "";
    public string SourceTitle { get => _sourceTitle; set => _sourceTitle = Wc3Text.Clean(value); }
    private string _sourceTitle = "";
    public double Amount { get; set; }
    public bool IsAttack { get; set; }
    public bool IsRanged { get; set; }
    public int AttackType { get; set; }
    public int DamageType { get; set; }
    public bool IsPhysical { get; set; }
    public uint DamageMask { get; set; }
    public uint WeaponType { get; set; }
    public double HpBefore { get; set; }
    public double HpAfter { get; set; }
    public double Actual { get; set; }
    public bool HpValid { get; set; }
    public int Depth { get; set; } = 1;
    public double EngineDamage { get; set; }
    public bool EngineValid { get; set; }
    public double EngineLast { get; set; }
    public int EngineCalls { get; set; }
    public bool IsV20 { get; set; }
    public double SetDamage { get; set; }
    public int SetCalls { get; set; }
    public uint Flags { get; set; }
    public int VictimOwner { get; set; } = -1;
    public int SourceOwner { get; set; } = -1;
    public bool VictimIllusion => (Flags & DamageHook.HookEvent.FlagVictimIllusion) != 0;
    public bool SourceIllusion => (Flags & DamageHook.HookEvent.FlagSourceIllusion) != 0;

    public DamageHook.HookEvent ToHookEvent() => new(
        Seq, At, Victim, VictimCode, Source, SourceCode, Amount,
        IsAttack, IsRanged, AttackType, DamageType, IsPhysical,
        VictimName, SourceName, DamageMask, WeaponType,
        HpBefore, HpAfter, Actual, HpValid, Depth,
        EngineDamage, EngineValid, EngineLast, EngineCalls,
        SetDamage, SetCalls, Flags, VictimOwner, SourceOwner, IsV20)
    {
        VictimTitle = VictimTitle,
        SourceTitle = SourceTitle,
    };
}

public sealed class HistoryFileInfo
{
    public string SessionId { get; set; } = "";
    public string Path { get; set; } = "";
    public string FileName { get; set; } = "";
    public DateTimeOffset StartedAt { get; set; }
    public DateTimeOffset EndedAt { get; set; }
    public string MapName { get; set; } = "";
    public int SettlementCount { get; set; }
    public double TotalDamage { get; set; }
    public int EventCount { get; set; }
    public int UnitCount { get; set; }
    public bool Truncated { get; set; }
    public bool Broken { get; set; }
    public string Error { get; set; } = "";
    public TimeSpan Duration => EndedAt > StartedAt ? EndedAt - StartedAt : TimeSpan.Zero;
}
