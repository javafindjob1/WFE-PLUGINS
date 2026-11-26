using System.Diagnostics;
using System.Globalization;
using System.IO.MemoryMappedFiles;
using System.Runtime.InteropServices;

namespace War3DeathSettlement.Core;

/// <summary>
/// 侵入式伤害事件的“外面那一半”：
///   * 用 <c>ddh_inject.exe</c> 把 <c>ddh.dll</c> 注入游戏（DLL 里挂 game.dll+0x67DC40 的钩子）；
///   * 通过命名共享内存 <c>Local\DdhRing_&lt;pid&gt;</c> 把事件读出来。
///
/// 结构体布局必须和 ddh.cpp 里的 <c>#pragma pack(1)</c> 完全一致。
/// 事件里带的是**引擎给的真值**：来源单位对象、是否攻击、是否远程、攻击类型、伤害类型、伤害值。
/// </summary>
public sealed class DamageHook : IDisposable
{
    public const uint Magic = 0x31484444;   // "DDH1"
    public const int MaxEvents = 512;

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    private struct Header
    {
        public uint Magic;
        public uint Version;
        public uint Pid;
        public uint Capacity;
        public uint Count;
        public uint HookOk;
        public uint SlotCount;
        public uint GameDllBase;
        public uint HookRva;
        public uint SelfTest;
        public uint LastTick;
        public uint R0, R1, R2, R3, R4;
    }

    /// <summary>v8 及以前的基础段：13 个 4 字节字段 + 两个 32 字节名字（与 ddh.cpp 的 pack(1) 对齐，116 字节）。</summary>
    private const int RecordBaseSizeV8 = 13 * 4 + 32 + 32;

    /// <summary>v9 的基础段：13 个 4 字节字段 + 两个 64 字节名字（180 字节；总记录 236 字节）。</summary>
    private const int RecordBaseSizeV9 = 13 * 4 + 64 + 64;

    /// <summary>名字字段宽度：v8 及以前 32 字节，v9 起 64 字节。</summary>
    private const int NameFieldV8 = 32;
    private const int NameFieldV9 = 64;

    /// <summary>v3 追加的 5 个 4 字节：hpBefore / hpAfter / actual / hpValid / depth。</summary>
    private const int RecordV3Extra = 5 * 4;

    /// <summary>v4 追加的 2 个 4 字节：engineDamage / engineValid（引擎伤害）。</summary>
    private const int RecordV4Extra = 2 * 4;

    /// <summary>
    /// v5 的 2 个 4 字节槽。v20 起 ddh 把这两个槽**改作"最终伤害"**用（布局不变、长度不变）：
    /// engineLast → finalDamage（原函数退出时 `*out` 的值），engineCalls → finalFlags
    /// （bit0 = 可信，bit1 = 与引擎值不同 = 地图改过）。所以 v20 的记录里这两个字段
    /// 要按 FinalDamage / FinalFlags 解读，见 HookEvent.IsV20。
    /// </summary>
    private const int RecordV5Extra = 2 * 4;

    /// <summary>v6 追加的 2 个 4 字节：setDamage / setCalls（SetEventDamage 最后一次设的值 + 调用次数）。</summary>
    private const int RecordV6Extra = 2 * 4;

    /// <summary>v7 追加的 1 个 4 字节：flags（bit0 = 目标带蝗虫 Aloc，马甲单位不进死亡结算；YDWE 同口径：Aloc &lt;= 0 = 普通单位）。</summary>
    private const int RecordV7Extra = 1 * 4;

    /// <summary>v8 追加的 2 个 4 字节：victimOwner / sourceOwner（源/目标所属玩家号，0 基；-1 = 未知）。</summary>
    private const int RecordV8Extra = 2 * 4;

    /// <summary>按 ddh.dll 报的版本决定每条记录多长（旧 DLL 也能正常读）。</summary>
    private int _recordSize = RecordBaseSizeV8;

    /// <summary>当前 DLL 版本对应的基础段长度和名字字段宽度（v9 名字占 64 字节，偏移跟着变）。</summary>
    private int _recordBaseSize = RecordBaseSizeV8;
    private int _nameSize = NameFieldV8;

    /// <summary>
    /// 伤害类型掩码 → 类型号（自检/界面共用的唯一实现）。
    /// 与 YDWE `EventDamageData.cpp::damage_type()` 完全一致：返回 bit 下标（高 bit 优先）。
    /// </summary>
    public static int MaskToType(uint mask) =>
        mask == 0 ? -1 : 31 - System.Numerics.BitOperations.LeadingZeroCount(mask);

    /// <summary>一条伤害事件（已解码）。</summary>
    public sealed record HookEvent(
        uint Seq, DateTime At, uint Victim, string VictimCode, uint Source, string SourceCode,
        double Amount, bool IsAttack, bool IsRanged, int AttackType, int DamageType, bool IsPhysical,
        string VictimName = "", string SourceName = "", uint DamageMask = 0, uint WeaponType = 0,
        double HpBefore = 0, double HpAfter = 0, double Actual = 0, bool HpValid = false, int Depth = 1,
        double EngineDamage = 0, bool EngineValid = false, double EngineLast = 0, int EngineCalls = 0,
        double SetDamage = 0, int SetCalls = 0, uint Flags = 0,
        int VictimOwner = -1, int SourceOwner = -1, bool IsV20 = false)
    {
        /// <summary>
        /// 触发单位 / 伤害来源的**英雄称谓**（与单位名称合并显示，也参与表头搜索）。
        /// 实时事件这里是空串 —— 搜索时按地址去 MonitorEngine 的称谓索引查；
        /// 历史库回放时由 event.victim_title / source_title 带回来（老库没有这两列 → 空串，只按名字匹配）。
        /// </summary>
        public string VictimTitle { get; init; } = "";
        public string SourceTitle { get; init; } = "";

        /// <summary>
        /// 掩码是不是“单个 2 的幂”。不是的话（比如 0x18 这种多类型组合），
        /// 引擎那套 log2(mask)-1 的换算本身就没有意义 —— 这时候类型号显示成“?”。
        /// </summary>
        public bool MaskIsSingleBit => DamageMask != 0 && (DamageMask & (DamageMask - 1)) == 0;

        /// <summary>伤害类型的显示：按 YDWE 口径的数字；多 bit 掩码时加注原始掩码。</summary>
        public string DamageTypeText =>
            DamageType < 0 ? "?"
                           : (MaskIsSingleBit ? DamageType.ToString() : $"{DamageType}(多类型0x{DamageMask:X})");

        /// <summary>显示用的名字：优先游戏里查到的名字，没有就用类型码。名字里的 |cXXXXXX|r 样式码一律去掉。</summary>
        public string SourceText => SourceName.Length > 0
            ? $"{Wc3Text.Clean(SourceName)}({SourceCode})"
            : (SourceCode.Length > 0 ? SourceCode : "0x" + Source.ToString("X8"));
        public string VictimText => VictimName.Length > 0
            ? $"{Wc3Text.Clean(VictimName)}({VictimCode})"
            : (VictimCode.Length > 0 ? VictimCode : "0x" + Victim.ToString("X8"));

        /// <summary>
        /// 末值是否可信：地图调用过 GetEventDamage（取次 &gt; 0）且末值是正数。
        /// v20 起同一个槽装的是"最终伤害"，本属性对 v20 仍成立（finalFlags 非 0 即有效），
        /// 需要区分语义时用 <see cref="FinalValid"/>。
        /// </summary>
        public bool EngineLastValid => EngineCalls > 0 && EngineLast > 0.005;

        /// <summary>
        /// v20：**最终伤害** —— 原函数退出时调用方 `*out` 的值，也就是 WFE 画伤害数字时读的
        /// 那块内存。它 = 引擎算完的值 + 地图 SetEventDamage 的改写（主路径由 0x67DC40 末尾重算）。
        /// v20 的 ddh 把这块数据放在原来的 engineLast 槽里（记录长度不变）。
        /// </summary>
        public double FinalDamage => IsV20 ? EngineLast : 0;

        /// <summary>v20：最终伤害的标志位（bit0 = 出口值和引擎值读取成功，bit1 = 地图改过）。</summary>
        public uint FinalFlags => IsV20 ? unchecked((uint)EngineCalls) : 0u;

        /// <summary>v20：最终伤害可信（出口值和引擎值读取成功；不要求本次实际掉血）。</summary>
        public bool FinalValid => IsV20 && (FinalFlags & 1u) != 0;

        /// <summary>v20：地图用 SetEventDamage 改过这次伤害（最终值 ≠ 引擎值，且不是溢出钳制）。</summary>
        public bool FinalOverridden => IsV20 && (FinalFlags & 2u) != 0;

        /// <summary>
        /// v20：最终值被"剩余血量"钳制 —— 击杀溢出。
        /// 引擎在落地前会把伤害钳到目标当前生命（0x67F340 的 `min(*out, 当前生命)`），
        /// 所以击杀那一刀的 `*out` 等于**前血**，不是地图改写值。这种行不能算倍数，
        /// 否则会显示成 0.57× 之类的"假减伤"。
        /// </summary>
        public bool FinalClamped => IsV20 && (FinalFlags & 4u) != 0;

        /// <summary>
        /// 引擎伤害：取 GetEventDamage 的**首值**（第一次调用返回的值，地图还没改）；
        /// 取次 &gt; 0 且首值有效才显示，否则 ?。单值显示，不用箭头。
        /// </summary>
        public string EngineText => EngineValueValid ? EngineValue.ToString("0.00") : "?";

        /// <summary>引擎伤害的数值 = 首值（GetEventDamage 第一次返回值）。</summary>
        public double EngineValue => EngineDamage;

        /// <summary>
        /// 引擎伤害是否可显示：
        ///   * 取次 &gt; 0 —— 地图真的调过 GetEventDamage，值是首值；
        ///   * 取次 = 0 —— 地图没读，ddh 在伤害函数出口回读了 info+0x10
        ///     （引擎把护甲/加成之后的实际伤害写回那里；真机与地图读数逐条吻合）。
        /// </summary>
        public bool EngineValueValid => EngineValid;

        /// <summary>这个引擎伤害是不是地图自己读出来的（false = ddh 出口回读）。v20 恒为 false。</summary>
        public bool EngineReadByMap => !IsV20 && EngineCalls > 0;

        /// <summary>净掉血（血差，本层净值）；没读到就显示 ?。</summary>
        public string NetDropText => HpValid ? Actual.ToString("0.00") : "?";

        /// <summary>地图是否用 SetEventDamage 改过这次伤害（设次 > 0 即有效，设 0.00 也算设过）。</summary>
        public bool SetValid => SetCalls > 0;

        /// <summary>
        /// 目标是否带蝗虫 Aloc（马甲单位）：bit0 = 1。
        /// 唯一来源是 ddh 实测 `GetUnitAbilityLevel(handle, 'Aloc') > 0`（与 YDWE 同口径），
        /// 不按单位名/类型码写死。马甲不进死亡结算、也不进伤害构成汇总。
        /// </summary>
        public bool VictimLocust => (Flags & 1) != 0;

        /// <summary>伤害事件写入时实测的触发单位镜像状态（unit_flags bit1）。</summary>
        public const uint FlagVictimIllusion = 1u << 1;

        /// <summary>伤害事件写入时实测的伤害来源镜像状态（unit_flags bit2）。</summary>
        public const uint FlagSourceIllusion = 1u << 2;

        /// <summary>触发单位是否为英雄（unit_flags bit3）。</summary>
        public const uint FlagVictimHero = 1u << 3;

        /// <summary>伤害来源是否为英雄（unit_flags bit4）。</summary>
        public const uint FlagSourceHero = 1u << 4;

        /// <summary>伤害来源是否带 Aloc（unit_flags bit5）。</summary>
        public const uint FlagSourceLocust = 1u << 5;

        public bool VictimIllusion => (Flags & FlagVictimIllusion) != 0;
        public bool SourceIllusion => (Flags & FlagSourceIllusion) != 0;
        public bool VictimHero => (Flags & FlagVictimHero) != 0;
        public bool SourceHero => (Flags & FlagSourceHero) != 0;
        public bool SourceLocust => (Flags & FlagSourceLocust) != 0;

        /// <summary>触发单位所属玩家（事件里的 native 玩家号，1 基显示；拿不到显示 ?）。</summary>
        public string VictimOwnerText => UnitEvents.FormatPlayer(VictimOwner);

        /// <summary>伤害来源所属玩家（事件里的 native 玩家号，1 基显示；拿不到显示 ?）。</summary>
        public string SourceOwnerText => UnitEvents.FormatPlayer(SourceOwner);

        /// <summary>
        /// 生效伤害（地图伤害，含末值）：
        ///   * v20：用**最终伤害**（出口 `*out`）—— 这就是引擎真正扣下去的那个数，
        ///     引擎值与地图改写已经合成在一起；没测到才退回血差。
        ///   * v19 及以前：地图 SetEventDamage 改过就用改后的值；没改过用引擎末值；
        ///     末值也抓不到就退回血差。
        /// </summary>
        public double EffectiveDamage
        {
            get
            {
                if (IsV20) return FinalValid ? FinalDamage : Actual;
                return SetValid ? SetDamage : (EngineLastValid ? EngineLast : Actual);
            }
        }

        /// <summary>生效值是否可信（地图改过 / 引擎末值 / 血量差 三种口径任一有效即可）。</summary>
        public bool EffectiveValid => IsV20 ? (FinalValid || HpValid) : (SetValid || EngineLastValid || HpValid);

        /// <summary>净掉血 = 血差（本层净值，嵌套扣内层）。</summary>
        public double NetDrop => Actual;

        /// <summary>血差大于生效值 = 额外伤害（一般没有）。</summary>
        public double ExtraDamage => (EffectiveValid && HpValid) ? Math.Max(0, Actual - EffectiveDamage) : 0;

        /// <summary>地图伤害（生效值）的显示文本；没测到显示 ?。</summary>
        public string EffectiveText => EffectiveValid ? EffectiveDamage.ToString("0.00") : "?";

        /// <summary>
        /// 倍数 = 地图伤害 ÷ 引擎伤害。
        /// v20 只要最终伤害可信就显示，包含 1× 和击杀时受剩余血量钳制产生的比值。
        /// </summary>
        public double MapRate
        {
            get
            {
                if (!EngineValid || EngineDamage <= 0.005) return 0;
                // v20：最终伤害可信时统一按“地图伤害 ÷ 引擎伤害”显示。
                // 击杀钳制也保留真实比值，便于和 WFE 看到的最终数字对照。
                if (IsV20) return FinalValid ? EffectiveDamage / EngineDamage : 0;
                if (EngineCalls <= 0 && !SetValid) return 0;
                return EffectiveDamage / EngineDamage;
            }
        }

        /// <summary>
        /// “本层前血 → 本层后血”。两个都是伤害函数入口/退出时**真实读到**的血（两位小数）。
        /// 不再用 前血 − 净掉血 合成后血；嵌套时外层的前血/后血就是它那一层进出函数时的实测读数。
        /// </summary>
        public string HpText => HpValid ? $"{HpBefore:0.00}→{HpAfter:0.00}" : "";

        /// <summary>本次事件在嵌套里的层号（1 = 最外层）。</summary>
        public string DepthText => Depth > 1 ? Depth.ToString() : "1";

        /// <summary>实际 / 伤害 的倍数（1 = 地图没动；2 = 增伤一倍；0.5 = 减伤一半）。</summary>
        public double ActualRate => HpValid && Amount > 0.01 ? Actual / Amount : 0;

        public override string ToString() =>
            $"{At:HH:mm:ss.fff} {SourceText}→{VictimText} 原始={Amount:0.00} 引擎={EngineText} 地图={EffectiveText}" +
            (FinalClamped ? "（溢出）" : "") +
            $" 净掉血={NetDropText}" +
            (MapRate > 0 ? $" 倍数={MapRate:0.##}×" : "") +
            (HpValid ? $"（本层血 {HpBefore:0.00}→{HpAfter:0.00}，第 {Depth} 层）" : "") +
            $" 攻击={(IsAttack ? 1 : 0)} 远程={(IsRanged ? 1 : 0)} 攻{AttackType} 伤{DamageTypeText}";
    }

    private MemoryMappedFile? _mmf;
    private MemoryMappedViewAccessor? _view;
    private uint _lastSeq;

    /// <summary>共享内存访问锁：界面线程写属性请求 / 监视线程读事件，两边不能同时碰 view。</summary>
    private readonly object _io = new();
    /// <summary>
    /// v10 属性块在共享内存里的绝对偏移 = 头(64) + 事件 ring(512 × 每条记录字节数)。
    /// 0 = 这个 ddh 没有属性块（版本 &lt; 10），整块跳过。
    /// </summary>
    private long _attrBlockOffset;
    /// <summary>本轮请求序号（每次 <see cref="RequestUnitAttrs"/> +1）。</summary>
    private uint _attrRequestSeq;
    /// <summary>已经解析过的完成序号，避免同一轮响应被重复收。</summary>
    private uint _attrParsedSeq;
    /// <summary>最后一次写请求槽时的 TickCount（超时后允许重发，防 ddh 没处理时永久卡住）。</summary>
    private uint _attrRequestTick;
    /// <summary>“属性回读”诊断日志已写过几条（只写前 5 条，避免刷屏）。</summary>
    private int _attrDiagCount;
    /// <summary>最近一次属性请求 / 读取的错误（不抛异常，只记录）。</summary>
    public string LastAttrError { get; private set; } = "";

    public string MapName { get; private set; } = "";
    public bool HookOk { get; private set; }
    public uint GameDllBase { get; private set; }
    /// <summary>ddh.dll 的共享内存协议版本（3 起带 hpBefore/hpAfter/actual；9 起名字各 64 字节）。</summary>
    public uint Version { get; private set; }
    /// <summary>按 DLL 版本算出的每条记录字节数（v8 = 172，v9 = 236；自检/日志用）。</summary>
    public int RecordSize => _recordSize;
    /// <summary>名字字段宽度（v8 及以前 32，v9 起 64）。</summary>
    public int NameFieldSize => _nameSize;
    /// <summary>这个 DLL 会不会采“实际伤害”（v3 且它自己声明开了血量采集）。</summary>
    public bool HpSupported { get; private set; }
    /// <summary>ddh.dll 实际挂钩的 RVA（它会按特征扫描，可能不是 0x67DC40）。</summary>
    public uint HookRva { get; private set; }
    /// <summary>v21：本地玩家视角的结盟掩码（bit i = 玩家 i 与本地玩家结盟）。0 = 老 DLL / 未算出来。</summary>
    public uint AllyMask { get; private set; }
    /// <summary>v27：ddh 用 JASS GetLocalPlayer→GetPlayerId 实测的本地玩家号（0 基；-1 = 未知）。</summary>
    public int LocalPid { get; private set; } = -1;
    public uint TotalEvents { get; private set; }
    public int Dropped { get; private set; }
    public string LastError { get; private set; } = "";
    public bool IsOpen => _view != null;

    /// <summary>注入器把 DLL 塞进目标进程（需要和目标同权限，游戏是管理员就要以管理员运行本软件）。</summary>
    public static (bool ok, string message) Inject(int pid, string injectorPath, string dllPath, int timeoutMs = 8000)
    {
        if (!File.Exists(injectorPath)) return (false, $"找不到注入器：{injectorPath}");
        if (!File.Exists(dllPath)) return (false, $"找不到 ddh.dll：{dllPath}");
        try
        {
            var psi = new ProcessStartInfo(injectorPath)
            {
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true
            };
            psi.ArgumentList.Add(pid.ToString(CultureInfo.InvariantCulture));
            psi.ArgumentList.Add(dllPath);
            using var p = Process.Start(psi)!;
            string outText = p.StandardOutput.ReadToEnd();
            string errText = p.StandardError.ReadToEnd();
            if (!p.WaitForExit(timeoutMs)) { try { p.Kill(true); } catch { } return (false, "注入器超时"); }
            string text = (outText + errText).Trim();
            return (p.ExitCode == 0, text.Length > 0 ? text : $"注入器退出码 {p.ExitCode}");
        }
        catch (Exception ex) { return (false, "注入失败：" + ex.Message); }
    }

    /// <summary>打开（或等待）共享内存。</summary>
    public bool Open(int pid, int waitMs = 5000)
    {
        MapName = $@"Local\DdhRing_{pid}";
        LocalPid = -1;
        AllyMask = 0;
        var sw = Stopwatch.StartNew();
        while (sw.ElapsedMilliseconds < waitMs)
        {
            try
            {
                _mmf = MemoryMappedFile.OpenExisting(MapName, MemoryMappedFileRights.ReadWrite);
                _view = _mmf.CreateViewAccessor(0, 0, MemoryMappedFileAccess.ReadWrite);
                var h = ReadHeader();
                if (h.Magic == Magic)
                {
                    HookOk = h.HookOk != 0;
                    GameDllBase = h.GameDllBase;
                    HookRva = h.HookRva;
                    TotalEvents = h.Count;
                    Version = h.Version;
                    AllyMask = h.Version >= 21 ? h.R1 : 0;
                    LocalPid = DecodeLocalPid(h.Version, h.R3);
                    HpSupported = h.Version >= 3 && h.R0 != 0;
                    // v9 起名字各 64 字节；老 DLL 保持 32 字节。基础段和记录长度一起跟着版本走。
                    _nameSize = h.Version >= 9 ? NameFieldV9 : NameFieldV8;
                    _recordBaseSize = h.Version >= 9 ? RecordBaseSizeV9 : RecordBaseSizeV8;
                    _recordSize = _recordBaseSize
                                + (h.Version >= 3 ? RecordV3Extra : 0)
                                + (h.Version >= 4 ? RecordV4Extra : 0)
                                + (h.Version >= 5 ? RecordV5Extra : 0)
                                + (h.Version >= 6 ? RecordV6Extra : 0)
                                + (h.Version >= 7 ? RecordV7Extra : 0)
                                + (h.Version >= 8 ? RecordV8Extra : 0);
                    // v12/v13：属性块紧跟在事件 ring 之后（头 + 512 条记录）；v10/v11 是 64 槽布局，
                    // 与 v12/v13 的 96 槽不兼容，老 DLL 整块跳过（界面显示 ?，绝不误读成乱值）。
                    // v13 只改视野语义（+177 sightDay = 当前有效视野），布局与 v12 完全一致。
                    _attrBlockOffset = h.Version >= 12
                        ? Marshal.SizeOf<Header>() + (long)MaxEvents * _recordSize
                        : 0;
                    if (_attrBlockOffset > 0)
                    {
                        // 真机对照：ddh v12 日志“块偏移=120896…响应槽偏移=392，单元 208 字节，块长 20360”。
                        // 这里把 C# 实际用的偏移写一行，和 ddh 对不上时一眼就能看见。
                        Log.Write($"属性块：偏移={_attrBlockOffset} 响应槽={UnitAttrWire.ResponseOffset} " +
                                  $"单元={UnitAttrWire.EntrySize} 块长={UnitAttrWire.BlockSize}" +
                                  $"（C# 布局，ddh v{h.Version}）");
                        // 关键：接着 ddh 当前的 requestSeq / doneSeq 继续编号。若 C# 重启而 ddh
                        // 还活着，从 1 重新开始会被 ddh 当成“旧序号”忽略（doneSeq 永远不前进）。
                        uint curReq = _view.ReadUInt32(_attrBlockOffset);
                        uint curDone = _view.ReadUInt32(_attrBlockOffset + 4);
                        _attrRequestSeq = curReq;
                        _attrParsedSeq = curDone;
                        // doneSeq 不可能比 requestSeq 新；真出现就按“已消费到 request”处理，防倒序。
                        if (unchecked((int)(curDone - curReq)) > 0) _attrParsedSeq = curReq;
                        _attrRequestTick = unchecked((uint)Environment.TickCount);
                        if (curReq != 0 || curDone != 0)
                            Log.Write($"属性块：接续 ddh 当前 requestSeq={curReq} doneSeq={curDone}" +
                                      $"（重启 C# 不会卡在旧序号）");
                    }

                    _lastSeq = h.Count;      // 从当前开始，只取注入之后的新事件
                    return true;
                }
                LastError = "共享内存魔数不对";
                Dispose();
                return false;
            }
            catch (FileNotFoundException) { Thread.Sleep(150); }
            catch (Exception ex) { LastError = ex.Message; Thread.Sleep(150); }
        }
        LastError = LastError.Length > 0 ? LastError : "等待 ddh.dll 的共享内存超时";
        return false;
    }

    private Header ReadHeader()
    {
        var h = new Header();
        if (_view != null) _view.Read(0, out h);
        return h;
    }

    /// <summary>取新事件（最多 max 条）。</summary>
    public List<HookEvent> Poll(int max = 200)
    {
        lock (_io) return PollLocked(max);
    }

    private List<HookEvent> PollLocked(int max)
    {
        var list = new List<HookEvent>();
        if (_view == null) return list;

        var h = ReadHeader();
        HookOk = h.HookOk != 0;
        TotalEvents = h.Count;
        if (h.HookRva != 0) HookRva = h.HookRva;
        if (h.Version >= 21) AllyMask = h.R1;
        int lp = DecodeLocalPid(h.Version, h.R3);
        if (lp >= 0) LocalPid = lp;

        uint from = Math.Max(_lastSeq, h.Count >= MaxEvents ? h.Count - MaxEvents + 1 : 1);
        int headerSize = Marshal.SizeOf<Header>();
        int recordSize = _recordSize;

        var buf = new byte[recordSize];
        for (uint seq = from; seq <= h.Count && list.Count < max; seq++)
        {
            uint slot = (seq - 1) % MaxEvents;
            _view.ReadArray(headerSize + (long)slot * recordSize, buf, 0, recordSize);
            _lastSeq = seq;                        // 无论成败都推进，避免重复读同一条
            if (BitConverter.ToUInt32(buf, 0) != seq) continue;   // 被覆盖了（读太慢）
            list.Add(Decode(buf));
        }
        return list;
    }

    private HookEvent Decode(byte[] b)
    {
        uint seq = BitConverter.ToUInt32(b, 0);
        uint tick = BitConverter.ToUInt32(b, 4);
        uint victim = BitConverter.ToUInt32(b, 8);
        uint victimCode = BitConverter.ToUInt32(b, 12);
        uint source = BitConverter.ToUInt32(b, 16);
        uint sourceCode = BitConverter.ToUInt32(b, 20);
        float amount = BitConverter.ToSingle(b, 24);
        uint flag = BitConverter.ToUInt32(b, 28);
        uint attackType = BitConverter.ToUInt32(b, 32);
        uint mask = BitConverter.ToUInt32(b, 36);
        uint physical = BitConverter.ToUInt32(b, 44);

        bool ranged = (flag & 1) != 0;
        bool attack = (flag & 0x100) != 0;
        // 伤害类型换算：**照 YDWE 的源码**（YDWE-master\...\yd_jass_api\EventDamageData.cpp:79-89）
        //     uint32_t n = 0; for (; v; v >>= 1) ++n;  return n - 1;
        // 对 v = 1<<k：循环跑 k+1 次 → 返回 k（bit 下标），**没有“再减 1”**。
        // 我们原来写成 log2(mask)-1，于是 0x10 被报成 3 —— 就是你说的“不存在的伤害类型”，它本该是 4。
        // 多 bit 掩码时 YDWE 取的是最高那一位（floor(log2)），我们照做，显示上加注原始掩码。
        int dtype = MaskToType(mask);

        // v9 名字各 64 字节（victimName 在 +52，sourceName 在 +52+64）；v8 及以前各 32 字节。
        string victimName = ReadName(b, 52, _nameSize);
        string sourceName = ReadName(b, 52 + _nameSize, _nameSize);

        // v3 追加的五项（旧 DLL 没有这一段，保持默认值）
        int baseSize = _recordBaseSize;
        double hpBefore = 0, hpAfter = 0, actual = 0;
        bool hpValid = false;
        int depth = 1;
        if (b.Length >= baseSize + RecordV3Extra)
        {
            hpBefore = BitConverter.ToSingle(b, baseSize + 0);
            hpAfter = BitConverter.ToSingle(b, baseSize + 4);
            actual = BitConverter.ToSingle(b, baseSize + 8);
            hpValid = BitConverter.ToUInt32(b, baseSize + 12) != 0;
            depth = (int)BitConverter.ToUInt32(b, baseSize + 16);
            if (depth <= 0) depth = 1;
        }

        double engineDmg = 0;
        bool engineValid = false;
        if (b.Length >= baseSize + RecordV3Extra + RecordV4Extra)
        {
            engineDmg = BitConverter.ToSingle(b, baseSize + RecordV3Extra + 0);
            engineValid = BitConverter.ToUInt32(b, baseSize + RecordV3Extra + 4) != 0;
        }
        double engineLast = 0;
        int engineCalls = 0;
        if (b.Length >= baseSize + RecordV3Extra + RecordV4Extra + RecordV5Extra)
        {
            // v20：这两个槽装的是 finalDamage / finalFlags（布局与长度都没变），
            // 原样读进 EngineLast / EngineCalls，再由 HookEvent.FinalDamage / FinalFlags 解释。
            engineLast = BitConverter.ToSingle(b, baseSize + RecordV3Extra + RecordV4Extra + 0);
            engineCalls = (int)BitConverter.ToUInt32(b, baseSize + RecordV3Extra + RecordV4Extra + 4);
        }
        double setDamage = 0;
        int setCalls = 0;
        if (b.Length >= baseSize + RecordV3Extra + RecordV4Extra + RecordV5Extra + RecordV6Extra)
        {
            setDamage = BitConverter.ToSingle(b, baseSize + RecordV3Extra + RecordV4Extra + RecordV5Extra + 0);
            setCalls = (int)BitConverter.ToUInt32(b, baseSize + RecordV3Extra + RecordV4Extra + RecordV5Extra + 4);
        }

        // v7 追加的 flags（bit0 = 目标带蝗虫 Aloc）
        uint flags = 0;
        if (b.Length >= baseSize + RecordV3Extra + RecordV4Extra + RecordV5Extra + RecordV6Extra + RecordV7Extra)
        {
            flags = BitConverter.ToUInt32(b, baseSize + RecordV3Extra + RecordV4Extra + RecordV5Extra + RecordV6Extra);
        }

        // v8 追加的 victimOwner / sourceOwner（0 基玩家号，-1 = 未知）
        int ownerOff = baseSize + RecordV3Extra + RecordV4Extra + RecordV5Extra + RecordV6Extra + RecordV7Extra;
        int victimOwner = -1, sourceOwner = -1;
        if (b.Length >= ownerOff + RecordV8Extra)
        {
            victimOwner = BitConverter.ToInt32(b, ownerOff);
            sourceOwner = BitConverter.ToInt32(b, ownerOff + 4);
        }

        return new HookEvent(
            seq,
            DateTime.Now.AddMilliseconds(-(int)(GetTickCount() - tick)),
            victim, Flip(victimCode), source, Flip(sourceCode),
            amount, attack, ranged, (int)attackType, dtype, physical != 0,
            victimName, sourceName, mask, BitConverter.ToUInt32(b, 40),
            hpBefore, hpAfter, actual, hpValid, depth,
            engineDmg, engineValid, engineLast, engineCalls,
            setDamage, setCalls, flags, victimOwner, sourceOwner, Version >= 20);
    }

    /// <summary>
    /// 从固定长度名字字段里读一个名字（0 结尾，最多 nameSize 字节）。统一走 Gbk.DecodeName
    /// （严格 UTF-8 / 替换 UTF-8 / GBK 打分择优），再去掉 |cXXXXXX|r 样式码。
    /// </summary>
    private static string ReadName(byte[] b, int off, int nameSize)
    {
        int n = 0;
        while (n < nameSize && off + n < b.Length && b[off + n] != 0) n++;
        if (n == 0) return "";
        return Wc3Text.Clean(Gbk.DecodeName(b, off, n));
    }

    /// <summary>内存在 +0x30 是**反序**的 4 字节（和我们从外部读的时候同一个坑）。</summary>
    private static string Flip(uint raw)
    {
        if (raw == 0) return "";
        var b = BitConverter.GetBytes(raw);
        var chars = new char[4];
        for (int i = 0; i < 4; i++)
        {
            char c = (char)b[3 - i];
            if (c < 0x20 || c > 0x7E) return "";
            chars[i] = c;
        }
        return new string(chars);
    }

    // ==================================================================
    // v10：单位属性请求 / 响应（【战场单位】页）
    // ==================================================================
    /// <summary>v27：header.reserved[3] = 本地玩家号 + 1（0 = 未知）。</summary>
    private static int DecodeLocalPid(uint version, uint r3) =>
        version >= 27 && r3 > 0 && r3 <= 24 ? (int)r3 - 1 : -1;

    /// <summary>这个 ddh 支持属性请求（协议版本 &gt;= 12，且共享内存已打开）。v10/v11 是 64 槽旧布局。</summary>
    public bool AttrSupported => _view != null && _attrBlockOffset > 0 && Version >= 12;

    /// <summary>属性块在共享内存里的绝对偏移（自检/日志用；0 = 老 DLL 没有这一块）。</summary>
    public long AttrBlockOffset => _attrBlockOffset;

    /// <summary>
    /// 把本页要看的单位地址写进 ddh 的 96 个请求槽，并把 requestSeq +1（最后写，保证 ddh 看到的
    /// 请求槽是完整的）。ddh 在游戏线程解析完才把 doneSeq 写成同一个值，见 <see cref="PollUnitAttrs"/>。
    /// 返回 false 表示这个 ddh 不支持（版本 &lt; 12）或共享内存读写失败 —— 界面照常显示 ?。
    /// </summary>
    public bool RequestUnitAttrs(IReadOnlyList<uint> addrs)
    {
        if (!AttrSupported) return false;
        lock (_io)
        {
            try
            {
                // 上一轮还没被 PollUnitAttrs 消费时不要再写新序号：ddh 的响应槽只有一份，
                // GUI 每轮“先请求再轮询”会把上一轮覆盖掉，导致 doneSeq 永远追不上 requestSeq。
                // 5 秒没回才允许重发（ddh 没在游戏线程时不会永久卡死）。
                uint now = unchecked((uint)Environment.TickCount);
                if (_attrRequestSeq != _attrParsedSeq &&
                    unchecked(now - _attrRequestTick) < 5000)
                    return false;

                int n = addrs == null ? 0 : Math.Min(addrs.Count, UnitAttrWire.SlotCount);
                for (int i = 0; i < UnitAttrWire.SlotCount; i++)
                {
                    uint addr = i < n ? addrs![i] : 0u;
                    _view!.Write(_attrBlockOffset + UnitAttrWire.RequestOffset + i * 4, addr);
                }
                Thread.MemoryBarrier();
                uint seq = _attrRequestSeq + 1;
                if (seq == 0) seq = 1;
                _attrRequestSeq = seq;
                _attrRequestTick = now;
                _view!.Write(_attrBlockOffset, seq);
                return true;
            }
            catch (Exception ex) { LastAttrError = ex.Message; return false; }
        }
    }

    /// <summary>
    /// 取回一轮已完成的属性响应：doneSeq 必须等于我们最后写的 requestSeq（ddh 处理完才写），
    /// 且同一轮只解析一次。返回空列表 = 还没好 / 不支持（界面继续用上一轮缓存）。
    /// </summary>
    public List<UnitAttrResponse> PollUnitAttrs()
    {
        var list = new List<UnitAttrResponse>();
        if (!AttrSupported || _attrRequestSeq == 0) return list;
        lock (_io)
        {
            try
            {
                Thread.MemoryBarrier();
                uint done = _view!.ReadUInt32(_attrBlockOffset + 4);
                // 不再要求 done == 当前 requestSeq：GUI 先写新请求再轮询时，上一轮的 done
                // 天生比当前 requestSeq 小 1；旧逻辑会把它当成“没完成”永远丢掉。
                if (!UnitAttrWire.ShouldConsumeResponse(done, _attrParsedSeq, _attrRequestSeq))
                    return list;

                var buf = new byte[UnitAttrWire.SlotCount * UnitAttrWire.EntrySize];
                _view.ReadArray(_attrBlockOffset + UnitAttrWire.ResponseOffset, buf, 0, buf.Length);
                list.AddRange(UnitAttrWire.DecodeAll(buf));
                _attrParsedSeq = done;

                // 诊断：前 5 条把“C# 解析出来的值”写进日志，和 ddh 的 `ATTR unit` 行对照
                // （速/主动/力敏智/白天夜晚视野/蝗虫位都是 ddh 日志里的真值；这里若显示 ? 就是解析/标志位没对上）。
                foreach (var r in list)
                {
                    if (_attrDiagCount >= 5) break;
                    _attrDiagCount++;
                    Log.Write($"属性回读：addr=0x{r.Addr:X8} 速={r.MoveSpeedText} " +
                              $"主动={r.AcquireRangeText} " +
                              $"力/敏/智={r.StrengthText}/{r.AgilityText}/{r.IntelligenceText} " +
                              $"白天/夜晚视野={r.SightDayText}/{r.SightNightText} 蝗虫={r.IsLocust} " +
                              $"flags=0x{r.Flags:X8}（C# 解析）");
                }
            }
            catch (Exception ex) { LastAttrError = ex.Message; }
        }
        return list;
    }

    [DllImport("kernel32.dll")]
    private static extern uint GetTickCount();

    public void Dispose()
    {
        _view?.Dispose(); _view = null;
        _mmf?.Dispose(); _mmf = null;
    }
}
