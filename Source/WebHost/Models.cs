namespace DdhWebHost;

internal sealed class SettlementSnapshot
{
    public int SchemaVersion { get; set; } = 1;
    public string GeneratedAt { get; set; } = "";
    public int Pid { get; set; }
    public string SessionId { get; set; } = "";
    public string MapName { get; set; } = "";
    public string SessionUpdatedAt { get; set; } = "";
    public long SessionRevision { get; set; }
    public string DatabasePath { get; set; } = "";
    public string Backend { get; set; } = "SQLite";
    public string Message { get; set; } = "";
    public long EventRevision { get; set; }
    public SnapshotCounts Counts { get; set; } = new();
    public List<SettlementRow> Settlements { get; set; } = new();
    public List<DamageEventRow> Events { get; set; } = new();
    public List<UnitRow> Units { get; set; } = new();
    public DesktopState? Desktop { get; set; }
}

internal sealed class DesktopState
{
    public string Mode { get; set; } = "live";
    public string AppVersion { get; set; } = "";
    public string BuildTime { get; set; } = "";
    public bool Connected { get; set; }
    public bool Ready { get; set; }
    public bool AutoAttach { get; set; }
    public int Pid { get; set; }
    public string SessionId { get; set; } = "";
    public string GameVersion { get; set; } = "";
    public string Status { get; set; } = "";
    public string HookStatus { get; set; } = "";
    public bool HookAttached { get; set; }
    public string SelfIntegrity { get; set; } = "";
    public string GameIntegrity { get; set; } = "";
    public long ScanCount { get; set; }
    public string DatabasePath { get; set; } = "";
    public string SourceLabel { get; set; } = "实时数据";
}

internal sealed class SnapshotCounts
{
    public int Settlements { get; set; }
    public int Events { get; set; }
    public int Units { get; set; }
}

internal sealed class SettlementRow
{
    public int Pid { get; set; }
    public long Seq { get; set; }
    public long WallMs { get; set; }
    public string DiedAt { get; set; } = "";
    public uint Victim { get; set; }
    public string VictimCode { get; set; } = "";
    public string VictimName { get; set; } = "";
    public int VictimOwner { get; set; } = -1;
    public string Kind { get; set; } = "死亡";
    public int InstanceIndex { get; set; } = 1;
    public double TotalDamage { get; set; }
    public int Hits { get; set; }
    public double MaxHit { get; set; }
    public double Peak1s { get; set; }
    public double Dps { get; set; }
    public double LifetimeSeconds { get; set; }
    public double CombatSeconds { get; set; }
    public uint FatalSource { get; set; }
    public string FatalSourceCode { get; set; } = "";
    public string FatalSourceName { get; set; } = "";
    public double FatalDamage { get; set; }
    public long FirstTick { get; set; }
    public long LastTick { get; set; }
}

internal sealed class SettlementPage
{
    public int SchemaVersion { get; set; } = 1;
    public string Type { get; set; } = "settlement-page";
    public long RequestId { get; set; }
    public string SessionId { get; set; } = "";
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int Total { get; set; }
    public string Error { get; set; } = "";
    public List<SettlementRow> Rows { get; set; } = new();
}

internal sealed class DamageEventRow
{
    public long Seq { get; set; }
    public long WallMs { get; set; }
    public string Time { get; set; } = "";
    public uint Victim { get; set; }
    public string VictimCode { get; set; } = "";
    public string VictimName { get; set; } = "";
    public int VictimOwner { get; set; } = -1;
    public bool VictimIllusion { get; set; }
    public bool VictimHero { get; set; }
    public uint Source { get; set; }
    public string SourceCode { get; set; } = "";
    public string SourceName { get; set; } = "";
    public int SourceOwner { get; set; } = -1;
    public bool SourceIllusion { get; set; }
    public bool SourceHero { get; set; }
    public double Amount { get; set; }
    public double Engine { get; set; }
    public double Final { get; set; }
    public double Actual { get; set; }
    public bool EngineValid { get; set; }
    public uint FinalFlags { get; set; }
    public bool FinalValid { get; set; }
    public double Effective { get; set; }
    public bool EffectiveValid { get; set; }
    public double Rate { get; set; }
    public double HpBefore { get; set; }
    public double HpAfter { get; set; }
    public bool HpValid { get; set; }
    public int AttackType { get; set; }
    public uint DamageMask { get; set; }
    public int DamageType { get; set; } = -1;
    public bool IsPhysical { get; set; }
    public bool IsAttack { get; set; }
    public bool IsRanged { get; set; }
    public int Depth { get; set; } = 1;
    public uint UnitFlags { get; set; }
}

internal sealed class UnitRow
{
    public uint Addr { get; set; }
    public string TypeCode { get; set; } = "";
    public string Name { get; set; } = "";
    public string Title { get; set; } = "";
    public int OwnerSlot { get; set; } = -1;
    public double AttackRange { get; set; }
    public double DamageMin { get; set; }
    public double DamageMax { get; set; }
    public double AttackInterval { get; set; }
    public double AttackSpeed { get; set; }
    public double Armor { get; set; }
    public double MoveSpeed { get; set; }
    public double SightDay { get; set; }
    public double SightNight { get; set; }
    public double AcquireRange { get; set; }
    public double Strength { get; set; }
    public double Agility { get; set; }
    public double Intelligence { get; set; }
    public bool Hero { get; set; }
    public bool Illusion { get; set; }
    public bool Locust { get; set; }
    public bool Dead { get; set; }
}

internal sealed class EventPage
{
    public int SchemaVersion { get; set; } = 1;
    public string Type { get; set; } = "event-page";
    public long RequestId { get; set; }
    public string SessionId { get; set; } = "";
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int Total { get; set; }
    public long EventRevision { get; set; }
    public string Error { get; set; } = "";
    public List<DamageEventRow> Rows { get; set; } = new();
}

internal sealed class SettlementDetail
{
    public int SchemaVersion { get; set; } = 1;
    public string Type { get; set; } = "settlement-detail";
    public long RequestId { get; set; }
    public string SessionId { get; set; } = "";
    public long Seq { get; set; }
    public uint Victim { get; set; }
    public int EventCount { get; set; }
    public string Error { get; set; } = "";
    public List<BreakdownRow> Rows { get; set; } = new();
}

internal sealed class BreakdownRow
{
    public string Source { get; set; } = "";
    public string IsAttack { get; set; } = "";
    public string IsRanged { get; set; } = "";
    public string AttackType { get; set; } = "";
    public string DamageType { get; set; } = "";
    public int Count { get; set; }
    public double Raw { get; set; }
    public double Engine { get; set; }
    public bool EngineValid { get; set; }
    public double Effective { get; set; }
    public bool EffectiveValid { get; set; }
    public double Net { get; set; }
    public bool NetValid { get; set; }
    public double Percent { get; set; }
    public bool Summary { get; set; }
}
