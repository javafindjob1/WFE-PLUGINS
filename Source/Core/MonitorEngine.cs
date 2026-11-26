using System.Diagnostics;
using System.Globalization;
using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>界面用的单位行（不可变快照）。</summary>
public sealed class UnitView
{
    public uint Addr { get; init; }
    public string TypeCode { get; init; } = "";
    /// <summary>单位名（优先钩子事件带回来的名字，再退回插件日志的类型码→名字表；没有就是空）。</summary>
    public string Name { get; init; } = "";
    public string Owner { get; init; } = "?";
    /// <summary>拥有者玩家号（0 基；-1 = 没解析出来）。阵营判定（盟友/敌人/中立）用它。</summary>
    public int OwnerSlot { get; init; } = -1;
    public float Hp { get; init; }
    public float HpMax { get; init; }
    public float HpPercent { get; init; }
    /// <summary>护甲值（CUnit+0xE0，float，YDWE UNIT_STATE_ARMOR 位透传；读不到/不可信时为 NaN）。</summary>
    public float Armor { get; init; } = float.NaN;
    public double Taken { get; init; }
    public int Hits { get; init; }
    public double Dps { get; init; }
    public string State { get; init; } = "";
    public float X { get; init; }
    public float Y { get; init; }
    public string Found { get; init; } = "";
    /// <summary>首次发现（进账本）时间；存活行用它算“存活秒”。</summary>
    public DateTime FirstSeen { get; init; }
    /// <summary>首次受击时间（战斗期起点）。</summary>
    public DateTime? FirstHit { get; init; }
    /// <summary>最后一次受击时间（存活行用它算“战斗秒”、详情页显示）。</summary>
    public DateTime? LastHit { get; init; }
    /// <summary>第几条命（地址复用后递增，用来区分同一地址的不同实例）。</summary>
    public int InstanceIndex { get; init; } = 1;
    /// <summary>最大单次掉血（本软件按血量差观测到的）。</summary>
    public double MaxHit { get; init; }
    /// <summary>1 秒窗口内最大承伤（与死亡结算同口径）。</summary>
    public double Peak1s { get; init; }
    /// <summary>同类型合并后包含的实例数（1 = 只有一个）。</summary>
    public int Count { get; init; } = 1;
    /// <summary>本局是否参与过伤害事件（做过 victim 或 source）。战场单位只显示这类单位。</summary>
    public bool Participated { get; init; }
    /// <summary>
    /// 这个地址上的实例是不是镜像/幻象（ddh v23 的 IsUnitIllusion；旧 DLL 不置位）。
    /// 只按实例生效：同类型码的原单位不能继承镜像位的名字后缀/过滤例外。
    /// </summary>
    public bool IsIllusion { get; init; }
}

/// <summary>一次扫描后的完整快照（引擎线程生产、界面线程消费，避免并发访问内部字典）。</summary>
public sealed class Snapshot
{
    public DateTime At { get; init; }
    public IReadOnlyList<UnitView> Units { get; init; } = Array.Empty<UnitView>();
    /// <summary>未按类型合并的原始单位（属性轮询按这些地址发，保证同类型每个实例都有机会被探到 Aloc/属性）。</summary>
    public IReadOnlyList<UnitView> RawUnits { get; init; } = Array.Empty<UnitView>();
    /// <summary>本局参与过伤害事件的地址（victim/source）。战场单位只保留这些地址。</summary>
    public IReadOnlySet<uint> DamageUnitAddrs { get; init; } = new HashSet<uint>();
    /// <summary>产生这份快照时的游戏进程号；0 = 未连接。界面据此丢弃过期快照。</summary>
    public int Pid { get; init; }
    /// <summary>
    /// 结算列表：**永远按 <see cref="SettlementOrder"/> 降序**（DiedAt 新的在前，同时间按实例号/地址）。
    /// UI 不要假设“新结算一定在末尾/一定比现有行新”——致命事件补建、无来源补挂都可能更早。
    /// </summary>
    public IReadOnlyList<Settlement> Settlements { get; init; } = Array.Empty<Settlement>();
    public ScanStats Stats { get; init; } = new();
    public string Status { get; init; } = "";
    public bool Ready { get; init; }
    /// <summary>找到候选进程但 OpenProcess 被 ERROR_ACCESS_DENIED 拒绝时的 PID；没有则为 null。</summary>
    public int? AccessDeniedPid { get; init; }
}

/// <summary>
/// 后台监视引擎：一个线程循环“扫描 → 记账 → 出快照”，界面只读快照。
/// </summary>
public sealed class MonitorEngine : IDisposable
{
    private Thread? _thread;
    private volatile bool _stop;
    private readonly object _gate = new();
    private long _mapGeneration;
    /// <summary>地图/局代次：同进程内换图时递增，用于让界面丢弃上一局的数据。</summary>
    public long MapGeneration => Interlocked.Read(ref _mapGeneration);
    private uint _lastGameMemory;
    private uint _pendingGameMemory;      // 去抖：候选的新 gameMemory
    private int _pendingGameMemoryHits;   // 连续命中的轮数
    private ulong _lastGameIdentity;      // (Ctx, ThisGame) 组合 —— 换图/重开局才变
    private ulong _pendingGameIdentity;
    private int _pendingGameIdentityHits;
    private DateTime _lastMapReset = DateTime.MinValue;
    private int _lastSettlementCount = -1;
    private IReadOnlyList<Settlement> _settlementSnapshot = Array.Empty<Settlement>();
    /// <summary>结算列表被“摘掉”过（蝗虫/按名字忽略）→ 即使条数没变也要重算快照，避免界面还留着已忽略的那条。</summary>
    private bool _settlementSnapshotDirty;
    /// <summary>“无来源结算”过滤：限流日志计数 + 按对象引用去重（同一结算只记一次）。</summary>
    private int _noSourceLogged;
    private readonly HashSet<Settlement> _loggedNoSource = new();
    /// <summary>“按名字忽略马甲单位”的限流日志计数（最多 10 条）。</summary>
    private int _ignoredNameLogged;

    /// <summary>按类型码记住出现过的单位（含已消失/死亡）：战场单位按类型合并显示时用它保留。</summary>
    private readonly Dictionary<string, UnitView> _retainedTypes = new(StringComparer.OrdinalIgnoreCase);

    public Wc3Game? Game { get; private set; }
    public UnitScanner? Scanner { get; private set; }
    public DamageTracker Tracker { get; private set; } = new();
    public Snapshot Current { get; private set; } = new();
    public bool Running => _thread is { IsAlive: true };

    /// <summary>自动连接：后台每秒找一次 war3 进程，找到就自动挂上（不用点按钮）。</summary>
    public bool AutoAttach { get; set; } = true;
    /// <summary>连接参数（指定 PID / 额外进程名 / 强制版本）。</summary>
    public AttachOptions AttachOptions { get; set; } = new();
    public TimeSpan AutoAttachInterval { get; set; } = TimeSpan.FromSeconds(1.5);
    private DateTime _lastAutoAttach = DateTime.MinValue;
    private DateTime _lastAliveCheck = DateTime.MinValue;

    /// <summary>轮询间隔（毫秒）。越小越精确，代价是 CPU。</summary>
    public int IntervalMs { get; set; } = 50;
    /// <summary>发现单位的路径开关（排障/自测用；默认全开）。</summary>
    public bool EnableHandleTable { get; set; } = true;
    public bool EnableSelection { get; set; } = true;

    public long ScanCount { get; private set; }

    // ---- 可选的“游戏内插件日志”增强：补上伤害来源/攻击类型 ----
    /// <summary>是否读游戏内插件日志（插件在跑时才有意义）。</summary>
    public bool ReadPluginLog { get; set; } = true;

    // ---- 侵入式伤害事件（注入 ddh.dll 挂钩引擎伤害函数）----
    /// <summary>是否启用侵入式伤害事件。</summary>
    public bool HookEnabled { get; set; }
    /// <summary>false = 不打开共享内存，只读 ddh 的 SQLite 明细（默认）。</summary>
    public bool HookSharedMemory { get; set; }
    public string HookDllPath { get; set; } = "hook\\ddh.dll";
    public string HookInjectorPath { get; set; } = "hook\\ddh_inject.exe";

    /// <summary>
    /// 注入被完整性级别（MIC）拦下：游戏比本进程高时，OpenProcess 申请
    /// <c>VM_WRITE|CREATE_THREAD</c> 必然 <c>ERROR_ACCESS_DENIED(5)</c>。
    /// <para>
    /// 注意这和"权限不足读不到"是两件事：**读数只需要 VM_READ，跨级别也能读**，
    /// 所以界面会显示"已连接"却注入不进去 —— 这条旗标专门用来解释这种状态。
    /// </para>
    /// </summary>
    public bool HookBlockedByIntegrity { get; private set; }

    /// <summary>被拦下时的简短说明（界面横幅用），形如"游戏 管理员（High） / 本程序 普通（Medium）"。</summary>
    public string HookIntegrityHint { get; private set; } = "";

    /// <summary>已经就哪个 PID 报过"被 IL 拦下"，避免 50ms 一轮疯狂刷日志。</summary>
    private int _hookIlBlockedPid = -1;

    /// <summary>插件日志路径（默认 WFE 的 Libraries 目录）。</summary>
    public string PluginLogPath { get; set; } =
        @"C:\3rd\wc3gamesearcher\WFE\Application\Libraries\UDamageWatcher.log";
    public PluginLogReader? PluginLog { get; private set; }
    /// <summary>已经出了结算、但还没从插件日志里补到来源的那些（等日志写出来再补）。</summary>
    private readonly List<Settlement> _awaitingAttribution = new();
    private DateTime _lastPluginPoll = DateTime.MinValue;

    // ---- 侵入式伤害事件（ddh.dll 注入 + 共享内存读取）----
    private readonly DamageHook _hook = new();
    private readonly List<DamageHook.HookEvent> _hookEvents = new();
    /// <summary>保护 _hookEvents 的读写：监视线程在 PumpHook 里写，界面线程通过 HookEvents 读快照。</summary>
    private readonly object _hookEventsLock = new();
    /// <summary>钩子事件里带回来的 类型码→名字 缓存（结算/存活行优先用它，没有插件日志也能显示名字）。</summary>
    private readonly Dictionary<string, string> _hookNames = new();
    /// <summary>
    /// 单位地址 → **英雄称谓**（ddh v12 属性响应里的 Title；见 <see cref="UnitAttrResponse.TitleText"/>）。
    /// 只给表头搜索用（称谓不占表格列）：死亡结算按「单位名」搜、伤害事件按「触发单位/伤害来源」搜时，
    /// 名字没命中就再看这里 —— 输入英雄称谓（如“安东”）也能筛出对应行。
    /// 称谓是单位的静态属性（战斗期不会变），所以**属性缓存 TTL 到期也不删**，只在本局结束/换局时整体清空。
    /// 地址复用：索引里连**学称谓时那个单位的类型码**一起记，搜索时用行/事件自己的类型码校验
    /// （与蝗虫过滤“地址 + 类型码”同口径）—— 地址被别的单位复用后不会拿旧称谓误匹配。
    /// 线程安全：界面线程轮询响应时写、界面/监视线程搜索/存历史时读（<see cref="_titleGate"/>）。
    /// </summary>
    private readonly Dictionary<uint, (string Title, string TypeCode)> _titles = new();
    /// <summary>保护 <see cref="_titles"/>（界面线程记 ddh 属性响应，监视线程换局清空/存历史读取）。</summary>
    private readonly object _titleGate = new();
    /// <summary>“称谓索引”日志限流（最多写 10 条，证明 ddh 的 Title 真的收到了、能按称谓搜）。</summary>
    private int _titleLogged;
    /// <summary>钩子事件里带“蝗虫 Aloc 标记”的目标单位地址 → 最近一次事件的 VictimLocust（马甲不进结算/不显示）。</summary>
    private readonly Dictionary<uint, bool> _locustVictims = new();
    /// <summary>本局参与过伤害事件的单位地址（victim/source）。战场单位只显示这些地址；换局清空。</summary>
    private readonly HashSet<uint> _damageUnitAddrs = new();
    /// <summary>
    /// 钩子事件里带“蝗虫 Aloc 标记”的目标单位**类型码**（马甲不进结算/不显示）。
    /// **不是写死的类型码表**：只在 ddh 实测 `GetUnitAbilityLevel(handle, 'Aloc') > 0` 的事件里学习到，
    /// 用来在结算地址与事件 victim 地址不一致时兜底匹配（YDWE 同口径：Aloc &lt;= 0 = 普通单位）。
    /// 比较用 OrdinalIgnoreCase（只认 4 字符，绝不做子串匹配）。
    /// </summary>
    private readonly HashSet<string> _locustCodes = new(StringComparer.OrdinalIgnoreCase);
    /// <summary>“跳过蝗虫马甲结算”的限流日志计数（最多 10 条）。</summary>
    private int _locustLogged;
    /// <summary>收到 ddh 的 Aloc 标记事件时，按 victim 去重记日志（最多 10 个；证明 flags bit0 真的传到了 C#）。</summary>
    private readonly HashSet<uint> _locustEventLogged = new();
    /// <summary>
    /// ddh v14 属性响应里带 Aloc 位的单位（地址 → 类型码）；只用于【战场单位】过滤。
    /// 与事件学的 <see cref="_locustVictims"/> 分开：事件口径继续服务结算过滤，
    /// 属性口径不改变死亡结算/伤害事件的既有逻辑。只增不删，换局整体清空；
    /// 地址复用时用类型码校验（不同码不认旧标记）。
    /// </summary>
    private readonly Dictionary<uint, string> _attrLocustAddrs = new();
    /// <summary>
    /// ddh 属性响应里确认过 IsUnitIllusion 的实例：地址 → 学到的类型码。
    /// **只增不删**：某轮拿不到句柄时不会置位，不能把已知镜像又当回普通单位；
    /// 地址被别的类型码复用后由类型码校验自然失效。换局整体清空。
    /// 只影响【战场单位】/历史的镜像名与 Aloc 例外，不改变死亡结算过滤。
    /// </summary>
    private readonly Dictionary<uint, string> _attrIllusionAddrs = new();
    /// <summary>保护 <see cref="_attrLocustAddrs"/>（界面线程写属性响应、监视线程读快照）。</summary>
    private readonly object _attrLocustGate = new();
    /// <summary>ddh 直读 CUnit+0x58 带回的「单位地址 → 玩家槽位(0 基)」。</summary>
    private readonly Dictionary<uint, int> _hookOwners = new();
    /// <summary>
    /// 战斗中按地址累积的单位属性（护甲 / 普攻伤害与间隔 / 技能）。
    /// 单位死后内存读不到，但这里保留最后一次记录，死亡结算和右键属性表直接用。
    /// </summary>
    private readonly UnitCombatStatsCache _combatStats = new();
    /// <summary>第一条带 owner 的事件是否已记录「玩家号来源」诊断（native / 退回 OwnerResolver）。</summary>
    private bool _ownerSourceLogged;
    /// <summary>玩家表诊断（ctx / localPid / players[]）每局只写一次。</summary>
    private bool _diagPlayerTableLogged;
    private bool _hookTried;
    /// <summary>检测到“进程里已有 ddh”时记下 pid：只接管共享内存，不再注入。</summary>
    private int _attachExistingPid = -1;
    private DateTime _lastHookPoll = DateTime.MinValue;
    private bool _dbReadErrorLogged;
    private uint _lastHookSeq;
    /// <summary>本局开始时间（Unix ms）：读 ddh 明细库时过滤掉上一张图的旧行。</summary>
    private long _dbSinceWallMs;
    /// <summary>事件历史容量（超过才丢最旧，丢弃量与新增量同阶、均摊 O(1)）；只在第一次触发时记一条日志。</summary>
    internal const int HookEventCapacity = 100000;
    private bool _hookCapLogged;

    private string _ignoreUnitNames = Settings.DefaultIgnoreUnitNames;
    private string[] _ignoreKeywords = UnitNameFilter.Parse(Settings.DefaultIgnoreUnitNames);

    /// <summary>
    /// 手动按名字忽略的单位（可选，默认空）：名字包含任一关键字就不进死亡结算（也不进历史 settlements / 分组统计）；
    /// 逗号/分号分隔。注意：这是用户自定义名单，**不参与马甲判定** ——
    /// 马甲只看 Aloc（ddh 对每个伤害目标实测 `GetUnitAbilityLevel(handle, 'Aloc') > 0`，与 YDWE 同口径）。
    /// ini: ignore_unit_names，环境变量 DSS_IGNORE_UNIT_NAMES 可覆盖。
    /// </summary>
    public string IgnoreUnitNames
    {
        get => _ignoreUnitNames;
        set
        {
            _ignoreUnitNames = value ?? "";
            _ignoreKeywords = UnitNameFilter.Parse(_ignoreUnitNames);
        }
    }

    /// <summary>允许重新尝试注入（界面上开关钩子时调用）。</summary>
    public void ResetHookAttempt()
    {
        _hookTried = false;
        _attachExistingPid = -1;
        HookAttached = false;
        HookStatus = HookEnabled ? "准备注入…" : "未启用";
        try { _hook.Dispose(); } catch { }
    }

    /// <summary>钩子是否已挂上（注入成功且 ddh.dll 报告 hookOk）。</summary>
    public bool HookAttached { get; private set; }
    /// <summary>钩子状态说明（给界面/日志看）。</summary>
    public string HookStatus { get; private set; } = "未启用";
    /// <summary>
    /// 最近的引擎伤害事件（新的在后面，最多 100000 条；超过才丢最旧，见 PumpHook）。
    /// 返回**线程安全快照**：监视线程在别处改 _hookEvents 时，界面线程枚举快照不会抛
    /// “Collection was modified”（真机崩溃的直接原因）。
    /// </summary>
    public IReadOnlyList<DamageHook.HookEvent> HookEvents
    {
        get { lock (_hookEventsLock) return _hookEvents.ToArray(); }
    }
    public int HookEventCount { get; private set; }

    // ------------------------------------------------------------------
    // v10：单位属性请求 / 响应（【战场单位】页）。共享内存读写在 DamageHook 里加锁，
    // 界面线程（写请求/读响应）和监视线程（读事件）可以同时用，不会撞 view。
    // ------------------------------------------------------------------
    /// <summary>ddh.dll 的共享内存协议版本（0 = 还没连上）。</summary>
    public uint HookVersion => _hook.Version;

    /// <summary>这个 ddh 支持单位属性请求（v12 起，96 槽）。老 DLL / 没注入时界面属性列显示 ?。</summary>
    public bool HookAttrSupported => _hook.IsOpen && _hook.AttrSupported;

    /// <summary>本地玩家号（0 基；没连上/读不到 = -1）。盟友/敌人判定用。</summary>
    public int LocalPlayerIndex
    {
        get
        {
            try
            {
                /* ddh v27 用 JASS GetLocalPlayer→GetPlayerId 实测，优先于 ctx+0x28 的猜测。 */
                int hooked = _hook.LocalPid;
                if (hooked >= 0 && hooked < 24) return hooked;
                int p = Game?.LocalPlayerIndex ?? -1;
                return p >= 0 && p < 24 ? p : -1;
            }
            catch { return -1; }
        }
    }

    /// <summary>v21：ddh 从游戏里算出的“本地玩家结盟掩码”（bit i = 玩家 i 与本地玩家结盟）；0 = 老 DLL/未算出。</summary>
    public uint AllyMask => _hook.IsOpen ? _hook.AllyMask : 0;

    /// <summary>把本页要看的单位地址写进 ddh 请求槽（最多 96 个；调用方用 UnitAttrPoller 轮询覆盖全部单位）。</summary>
    public bool RequestUnitAttrs(IReadOnlyList<uint> addrs) =>
        _hook.IsOpen && _hook.RequestUnitAttrs(addrs);

    /// <summary>
    /// 取回 ddh 已完成的一轮属性响应（还没完成返回空列表）。
    /// 顺手把响应里的 **称谓（Title）** 记进地址索引（<see cref="TryGetTitle"/>），
    /// 供死亡结算/伤害事件的“按称谓搜索”使用（界面与无界面模式都走这里）。
    /// </summary>
    public List<UnitAttrResponse> PollUnitAttrs()
    {
        if (!_hook.IsOpen) return new List<UnitAttrResponse>();
        var responses = _hook.PollUnitAttrs();
        /* v22 及更早把 ILLUSION 和 LOCUST_CHECKED 都写成 0x00200000：
           旧 DLL 的镜像位不可信，直接清掉，避免给所有做过 Aloc 判定的单位加“（镜像）”。 */
        if (_hook.Version < 23 && responses.Count > 0)
        {
            for (int i = 0; i < responses.Count; i++)
            {
                if (!responses[i].Has(UnitAttrWire.FlagIllusion)) continue;
                responses[i] = responses[i] with
                {
                    Flags = responses[i].Flags & ~UnitAttrWire.FlagIllusion
                };
            }
        }
        RememberAttrTitles(responses);
        RememberAttrLocusts(responses);
        return responses;
    }

    /// <summary>
    /// 记下属性响应里带 Aloc 位（蝗虫）的单位：地址 → 类型码，只用于【战场单位】过滤。
    /// **只增不删**：ddh 某轮没拿到句柄/技能等级时不置位，不能因此把已知蝗虫又放回列表；
    /// 地址被别的类型码复用后由类型码校验自然失效。换局时整体清空。
    /// </summary>
    internal void RememberAttrLocusts(IEnumerable<UnitAttrResponse>? responses)
    {
        if (responses == null) return;
        foreach (var r in responses)
        {
            if (r.Addr == 0) continue;
            string code = r.HasTypeCode ? r.TypeCode : "";
            lock (_attrLocustGate)
            {
                /* 镜像位是“实例级”的：镜像一律显示（即使带 Aloc），名字加“（镜像）”；
                   非镜像的 Aloc 仍然隐藏。 */
                if (r.IsIllusion) _attrIllusionAddrs[r.Addr] = code;

                if (r.IsLocust)
                {
                    _attrLocustAddrs[r.Addr] = code;
                }
                else if (r.LocustChecked)
                {
                    /* 地址被新单位复用：这一轮明确查到不是 Aloc，就撤掉旧结论。
                       没置 LOCUST_CHECKED 的响应不能当负结论（可能只是没查成）。 */
                    _attrLocustAddrs.Remove(r.Addr);
                }
            }
        }
    }

    internal bool IsAttrLocust(uint addr, string? typeCode)
    {
        if (addr == 0) return false;
        lock (_attrLocustGate)
        {
            if (!_attrLocustAddrs.TryGetValue(addr, out string? code)) return false;
            // 记录里没有类型码时不校验；行自己的类型码为空时也不校验（信息不足，不误杀）。
            if (code.Length == 0 || string.IsNullOrEmpty(typeCode)) return true;
            return string.Equals(code, typeCode, StringComparison.OrdinalIgnoreCase);
        }
    }

    /// <summary>属性响应里确认过“这个地址是镜像/幻象”（用类型码校验地址复用）。</summary>
    internal bool IsAttrIllusion(uint addr, string? typeCode)
    {
        if (addr == 0) return false;
        lock (_attrLocustGate)
        {
            if (!_attrIllusionAddrs.TryGetValue(addr, out string? code)) return false;
            if (code.Length == 0 || string.IsNullOrEmpty(typeCode)) return true;
            return string.Equals(code, typeCode, StringComparison.OrdinalIgnoreCase);
        }
    }

    /// <summary>【战场单位】/历史是否应隐藏：这个地址带 Aloc 且不是镜像才隐藏。
    /// 镜像无论是否带 Aloc 都显示（名字加“（镜像）”）；非镜像 Aloc 一律隐藏。</summary>
    internal bool IsUnitHiddenByLocust(uint addr, string? typeCode)
    {
        if (IsAttrIllusion(addr, typeCode)) return false;
        return IsAttrLocust(addr, typeCode);
    }

    /// <summary>
    /// 记下属性响应里的称谓（addr → Title + 学到的类型码）。**只增不删**：
    /// 属性缓存 TTL 到期后 ddh 会回 flags=0 的槽（没有 Title），这种响应不能把已知称谓覆盖成空；
    /// 只有本局结束/换局（<see cref="ClearHistoryCore"/>）才整体清空。
    /// 同地址学到新称谓（同一局内地址被另一个英雄复用）时以最新为准。
    /// </summary>
    internal void RememberAttrTitles(IEnumerable<UnitAttrResponse>? responses)
    {
        if (responses == null) return;
        lock (_titleGate)
        {
            foreach (var r in responses)
            {
                if (r.Addr == 0 || !r.HasTitle) continue;   // 没给称谓位/称谓为空：保留上一次学到的
                _titles[r.Addr] = (r.TitleText, r.HasTypeCode ? r.TypeCode : "");
                if (_titleLogged < 10)
                {
                    _titleLogged++;
                    Log.Write($"称谓索引：0x{r.Addr:X8} {(r.HasTypeCode ? r.TypeCode : "?")} → “{r.TitleText}”" +
                              $"（按称谓搜索用；本局已索引 {_titles.Count} 个）");
                }
            }
        }
    }

    /// <summary>
    /// 按单位地址取英雄称谓（没有 / 从没被属性请求覆盖过 → false，调用方的搜索自然只按名字匹配）。
    /// 只读索引，任何时候调用都安全。
    /// </summary>
    public bool TryGetTitle(uint addr, out string title) => TryGetTitle(addr, null, out title);

    /// <summary>
    /// 按单位地址取英雄称谓，并用**这个行/事件自己的类型码**校验地址有没有被别的单位复用。
    /// typeCode 为空（名字/类型码都不知道）时不做校验；索引里没记到类型码时也不校验（老数据）。
    /// 地址已换成别的类型码 → false（绝不拿旧称谓去匹配新单位）。
    /// </summary>
    public bool TryGetTitle(uint addr, string? typeCode, out string title)
    {
        if (addr != 0)
        {
            lock (_titleGate)
            {
                if (_titles.TryGetValue(addr, out var found) && found.Title.Length > 0)
                {
                    bool codeKnown = !string.IsNullOrEmpty(typeCode) && found.TypeCode.Length > 0;
                    if (!codeKnown || string.Equals(found.TypeCode, typeCode, StringComparison.OrdinalIgnoreCase))
                    {
                        title = found.Title;
                        return true;
                    }
                }
            }
        }
        title = "";
        return false;
    }

    /// <summary>清空称谓索引（换局/换进程/清空历史时调用；调用方需持有 <see cref="_gate"/> 或自行保证顺序）。</summary>
    internal void ClearTitleIndex()
    {
        lock (_titleGate)
        {
            _titles.Clear();
            _titleLogged = 0;
        }
    }

    /// <summary>本局已索引到多少个称谓（诊断/自检用）。</summary>
    public int TitleCount
    {
        get { lock (_titleGate) return _titles.Count; }
    }


    /// <summary>插件日志里累计解析出的结算条数（诊断用）。</summary>
    public int PluginSettlementsSeen => PluginLog?.ParsedTotal ?? 0;
    /// <summary>通过插件日志补上来源的外部结算条数（CSV/无界面模式仍会用到）。</summary>
    public int AttributedCount { get; private set; }

    /// <summary>钩子事件里攒到的「类型码→名字」表条数（界面判断结算名字是否变化、要不要重建表格用）。</summary>
    public int HookNameCount => _hookNames.Count;

    /// <summary>
    /// 类型码 → 单位名：钩子事件带回来的名字（_hookNames）优先，退回插件日志的「类型码 → 名字」表；
    /// 都没有返回空串（界面层再退显示类型码）。只在监视线程上调用。
    /// </summary>
    private string NameOf(string? typeCode)
    {
        if (string.IsNullOrEmpty(typeCode)) return "";
        if (_hookNames.TryGetValue(typeCode, out var hookName) && hookName.Length > 0) return hookName;
        return PluginLog?.NameOf(typeCode) ?? "";
    }

    /// <summary>单位拥有者显示：优先事件里的 CUnit+0x58 槽位，没有才用扫描快照中的槽位。</summary>
    private string OwnerText(uint addr, int scannedSlot)
        => _hookOwners.TryGetValue(addr, out var owner) && owner >= 0
            ? UnitEvents.FormatPlayer(owner)
            : UnitEvents.FormatPlayer(scannedSlot);

    public event Action? Changed;

    public MonitorEngine()
    {
    }

    // ------------------------------------------------------------------
    /// <summary>手动连接一次（界面上【查找游戏】按钮）。</summary>
    public bool Attach(out string message)
    {
        Stop();
        bool ok = TryAttachOnce(out message);
        Start();
        return ok;
    }

    /// <summary>连接一次，不启停线程（供后台自动连接复用）。</summary>
    private bool TryAttachOnce(out string message)
    {
        var g = Wc3Game.Attach(AttachOptions);
        message = g.Message;
        if (!g.IsReady)
        {
            int? deniedPid = g.AccessDeniedPid;
            g.Dispose();
            lock (_gate)
            {
                if (Game == null)
                {
                    // 已经断开（war3 退出）时**不要把界面清空**：自动重连会反复走到这里，
                    // 旧快照里的结算要一直保留到真正连上新游戏（连接成功分支才 ClearHistoryCore）。
                    var prev = Current;
                    Current = new Snapshot
                    {
                        At = DateTime.Now,
                        Status = message,
                        Ready = false,
                        AccessDeniedPid = deniedPid,
                        Units = prev.Units,
                RawUnits = prev.RawUnits,
                Pid = prev.Pid,
                        Settlements = prev.Settlements,
                        Stats = prev.Stats,
                    };
                }
            }
            Changed?.Invoke();
            return false;
        }

        lock (_gate)
        {
            ClearHistoryCore(resetHook: true);   // 新进程/新局：历史不串到新局（需求 A/B）
            Game?.Dispose();
            Game = g;
            Scanner = new UnitScanner(g)
            {
                EnableHandleTable = EnableHandleTable,
                EnableSelection = EnableSelection
            };
            Tracker = new DamageTracker(Scanner);
            Tracker.Settled += OnSettled;
            Current = new Snapshot { At = DateTime.Now, Status = "已连接，等待进入地图…", Ready = false };
        }
        Log.Write("已清空历史（连接新进程/新局）");
        Log.Write("连接成功：" + message);
        // 连上就记一笔两边的完整性级别："读得到但注入不进去"全靠这个判断，
        // 以后看日志一眼就能分清是 IL 挡的、还是 DACL/别的拦的。
        try
        {
            IntegrityLevel selfIl = Integrity.Self;
            IntegrityLevel gameIl = Integrity.OfProcess(g.Mem.Pid, out int ilErr);
            string extra = gameIl == IntegrityLevel.Unknown
                ? $"（读不出来，err={ilErr}）"
                : Integrity.CanInject(gameIl) ? "" : "（游戏更高：只读照常，注入 ddh.dll 需以管理员身份重启）";
            Log.Write($"完整性级别：本程序 {Integrity.Name(selfIl)}，游戏 {Integrity.Name(gameIl)}{extra}");
        }
        catch { }

        // 第三道锁：DACL / 属主。启用 SeDebugPrivilege 后，内核访问检查会放过 DACL 拒绝，
        // 于是"平台/服务以别的身份拉起的游戏"也能打开；但它**不绕过完整性级别**，
        // 跨 IL 的 VM_WRITE 拒绝它治不了 —— 两种情况在下面的注入预检里分开报。
        try
        {
            string? sd = Privilege.EnableSeDebugTracked();
            Log.Write("SeDebugPrivilege：" + (sd == null ? "已启用" : "不可用 —— " + sd));
        }
        catch { }
        Changed?.Invoke();
        return true;
    }

    public void Start()
    {
        if (Running) return;
        _stop = false;
        _thread = new Thread(Loop) { IsBackground = true, Name = "dss-monitor" };
        _thread.Start();
    }

    public void Stop()
    {
        _stop = true;
        var t = _thread;
        if (t is { IsAlive: true }) t.Join(1500);
        _thread = null;
    }

    /// <summary>暂停/继续（暂停时不扫描，但仍保留已记录的账）。</summary>
    public bool Paused { get; set; }

    /// <summary>
    /// 清空全部会话历史：单位账本、结算列表、钩子事件环、名字表、蝗虫标记、过滤日志计数、
    /// 待归因队列、去抖/换图状态、钩子注入状态，并立刻发布一个空快照（状态文字保留）。
    /// 注意：**断开/退出时不要调用它** —— 旧快照要保留到连上新一局；
    /// 现在界面【查找游戏】也不再预先调用，只有连接成功分支（新进程/新局）才清空。
    /// </summary>
    public void ClearHistory()
    {
        lock (_gate)
        {
            ClearHistoryCore(resetHook: true);
            Current = new Snapshot
            {
                At = DateTime.Now,
                Status = Current.Status,
                Ready = false,
                Units = Array.Empty<UnitView>(),
                RawUnits = Array.Empty<UnitView>(),
                Pid = 0,
                Settlements = Array.Empty<Settlement>(),
                Stats = new ScanStats(),
            };
        }
        Log.Write("已清空历史（查找/连接触发）");
        Changed?.Invoke();
    }

    /// <summary>
    /// 清空核心状态（调用方需自行持有 <see cref="_gate"/> 锁）。
    /// resetHook=true 时把钩子注入状态一起复位（换进程/重连要重新注入 ddh.dll）；
    /// 同一进程内换图/重开局传 false（ddh 还在老进程里，别重复注入）。
    /// </summary>
    private void ClearHistoryCore(bool resetHook)
    {
        Tracker.Clear();
        Scanner?.Reset();
        // 【战场单位】里的“已死亡/已消失类型”是按类型码跨轮保留的（见 Publish 的 _retainedTypes）：
        // 它只属于当前这一局。换进程/换图时如果不在这里清，新一局的快照会把这些旧类型原样补回来
        // （显示成“死亡”行），看起来就是“伤害明细、死亡结算都清了，战场单位没清”。
        // 清空时机与账本/结算完全一致：都在连接新局、重开局、清空历史这一个入口。
        _retainedTypes.Clear();
        lock (_hookEventsLock) _hookEvents.Clear();
        HookEventCount = 0;
        _hookNames.Clear();
        ClearTitleIndex();   // 称谓索引只在同一局内有效：换局/换进程后地址会复用，必须整体清空
        _locustVictims.Clear();
        _locustCodes.Clear();
        _damageUnitAddrs.Clear();
        _locustLogged = 0;
        _locustEventLogged.Clear();
        lock (_attrLocustGate) _attrLocustAddrs.Clear();
        lock (_attrLocustGate) _attrIllusionAddrs.Clear();
        _hookOwners.Clear();
        _combatStats.Clear();   // 换局/换进程：地址复用后旧属性不能串到新单位
        _ownerSourceLogged = false;
        _diagPlayerTableLogged = false;
        _awaitingAttribution.Clear();
        _hookCapLogged = false;
        _noSourceLogged = 0;
        _loggedNoSource.Clear();
        _ignoredNameLogged = 0;
        _settlementSnapshotDirty = false;
        _lastSettlementCount = -1;
        _settlementSnapshot = Array.Empty<Settlement>();

        if (resetHook)
        {
            _lastHookSeq = 0;
            _dbSinceWallMs = HookSharedMemory
                ? DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()
                : 0;
            _hookTried = false;
            _attachExistingPid = -1;
            HookAttached = false;
            HookStatus = HookEnabled ? "准备注入…" : "未启用";
            _hookIlBlockedPid = -1;
            HookBlockedByIntegrity = false;
            HookIntegrityHint = "";
            try { _hook.Dispose(); } catch { }
        }

        // 换图/换进程后身份与去抖状态都要复位，避免拿旧局的 ctx/ThisGame 做对比
        _pendingGameIdentity = 0;
        _pendingGameIdentityHits = 0;
        _lastGameIdentity = 0;
        _pendingGameMemory = 0;
        _pendingGameMemoryHits = 0;
        _lastGameMemory = 0;
        _lastMapReset = DateTime.MinValue;

    }

    // ------------------------------------------------------------------
    private void Loop()
    {
        var sw = new Stopwatch();
        while (!_stop)
        {
            try
            {
                Wc3Game? g;
                UnitScanner? sc;
                lock (_gate) { g = Game; sc = Scanner; }

                if (g == null || sc == null)
                {
                    // 没连上 → 自动找游戏（默认开启，每 1.5 秒试一次）
                    if (AutoAttach && DateTime.UtcNow - _lastAutoAttach >= AutoAttachInterval)
                    {
                        _lastAutoAttach = DateTime.UtcNow;
                        if (TryAttachOnce(out string msg)) Log.Write("自动连接成功：" + msg);
                        lock (_gate) { g = Game; sc = Scanner; }
                    }
                    else if (!AutoAttach)
                    {
                        lock (_gate)
                        {
                            Current = new Snapshot { At = DateTime.Now, Status = "未连接（自动连接已关闭，点【查找游戏】）", Ready = false };
                        }
                    }

                    if (g == null || sc == null)
                    {
                        PumpPluginLog();   // 没连上游戏也照读插件日志：名字表/来源先备好，诊断里也看得见
                        Thread.Sleep(300);
                        continue;
                    }
                }

                if (Paused)
                {
                    Thread.Sleep(120);
                    continue;
                }

                // 进程是否还活着：每秒查一次就够；进程没了就直接断开，
                // 绝不在“读不到内存”的情况下生成结算（否则退游戏会刷一堆假的“消失”）。
                if (DateTime.UtcNow - _lastAliveCheck > TimeSpan.FromSeconds(1))
                {
                    _lastAliveCheck = DateTime.UtcNow;
                    if (!IsProcessAlive(g))
                    {
                        HandleGameGone("已退出，等待新游戏…（当前结算保留；连上新游戏后清空）");
                        Thread.Sleep(400);
                        continue;
                    }
                }

                // 每次扫描前重读三个全局（换图/重开局后地址内容会变）
                // 顺带：区域表（VirtualQueryEx 的结果）要定期重抓 —— 引擎进图/扩容时会**新分配**
                // 内存（生命表就搬过家），只靠 attach 时那一次快照，新堆区永远看不见。
                g.Mem.RefreshRegionsIfStale(TimeSpan.FromSeconds(5));
                g.RefreshWithUnits(CollectAnchors(sc));

                // 真机一次定位：连接/进图后写一行玩家表诊断（ctx / localPid / players[]）。
                if (g.IsReady && !_diagPlayerTableLogged)
                {
                    _diagPlayerTableLogged = true;
                    var players = g.ReadPlayerObjects();
                    Log.Write($"玩家表诊断：ctx=0x{g.Ctx:X8} localPid={g.LocalPlayerIndex} players=[{string.Join(",", players.Select(p => "0x" + p.ToString("X8")))}]");
                }

                // 换图/重开局检测：**必须去抖**，而且要认准“身份”而不是生命表基址。
                //
                // 历史教训：
                //  ① 以前“gameMemory 一变就当成换图、把扫描器/账本全清掉”，结果某些会话
                //    （平台主菜单/载入中）gameMemory 每 1.5 秒变一次 → 永远清零 → 一个单位都认不出来。
                //  ② 现在知道生命表**会在同一局里搬家**（引擎扩容/回收，表基址换到新分配的内存）。
                //    那种情况只换表、不换局，账本绝不能清 —— 否则死亡结算会莫名其妙丢数据。
                // 所以身份用 (ctx, ThisGame) 这两个“整局不变”的全局来判。
                if (g.IsReady)
                {
                    ulong identity = ((ulong)g.Ctx << 32) | g.ThisGame;

                    if (identity != _pendingGameIdentity)
                    {
                        _pendingGameIdentity = identity;
                        _pendingGameIdentityHits = 1;
                    }
                    else
                    {
                        _pendingGameIdentityHits++;
                    }

                    bool stable = _pendingGameIdentityHits >= 3;
                    if (stable && _lastGameIdentity != 0 && identity != _lastGameIdentity &&
                        DateTime.UtcNow - _lastMapReset > TimeSpan.FromSeconds(10))
                    {
                        _lastMapReset = DateTime.UtcNow;
                        _mapGeneration++;
                        Log.Write($"检测到地图重载/重开局（ctx/ThisGame 变了：0x{_lastGameIdentity >> 32:X8}/0x{(uint)_lastGameIdentity:X8}" +
                                  $" → 0x{g.Ctx:X8}/0x{g.ThisGame:X8}，已连续 {_pendingGameIdentityHits} 轮稳定），账本清零");
                        lock (_gate) { ClearHistoryCore(resetHook: false); }
                    }
                    if (stable) _lastGameIdentity = identity;

                    // 同一局里生命表搬家：只记一条日志，别的什么都不做。
                    if (g.GameMemory != 0 && g.GameMemory != _pendingGameMemory) { _pendingGameMemory = g.GameMemory; _pendingGameMemoryHits = 1; }
                    else if (g.GameMemory != 0) _pendingGameMemoryHits++;

                    if (_pendingGameMemoryHits == 3 && _lastGameMemory != 0 && g.GameMemory != _lastGameMemory)
                        Log.Write($"生命表基址变更：0x{_lastGameMemory:X8} → 0x{g.GameMemory:X8}" +
                                  "（同一局内引擎扩容/搬表，账本保留）");
                    if (_pendingGameMemoryHits >= 3) _lastGameMemory = g.GameMemory;
                }

                sw.Restart();
                sc.EnableHandleTable = EnableHandleTable;
                sc.EnableSelection = EnableSelection;
                var stats = sc.Scan();
                var now = DateTime.Now;
                Tracker.Update(sc.Known, now);
                // 扫描到的单位顺手把护甲记进战斗属性缓存：这里读到的是“活着的时候”的值，
                // 等它死了单位对象没了，右键属性表还能显示最后一次记录。
                foreach (var u in sc.Known.Values)
                    _combatStats.GetOrCreate(u.Addr).ObserveArmor(u.Armor);
                sw.Stop();
                ScanCount++;
                stats.ElapsedMs = sw.ElapsedMilliseconds;

                PumpPluginLog();
                int hookCountBefore = HookEventCount;
                PumpHook(g, sc);
                // 致命一击的钩子事件往往比“扫描到 HP=0”慢半拍：结算已经建好、当时没有来源，
                // 这批事件一到就回头补挂一次，否则这条结算会一直被“无来源”过滤掉、看起来像没结算。
                if (HookEventCount != hookCountBefore) RetryLateHookAttach();

                Publish(g, sc, stats);
            }
            catch (Exception ex)
            {
                Log.Error("监视循环异常：" + ex);
                Thread.Sleep(500);
            }

            int wait = Math.Clamp(IntervalMs, 10, 5000);
            int slept = 0;
            while (slept < wait && !_stop) { Thread.Sleep(5); slept += 5; }
        }
    }

    /// <summary>
    /// 用来“验证生命表”的真实单位锚点：选区链选中的单位 + 钩子事件里的 victim/source
    /// （钩子覆盖全场，样本多）+ 已经认下来的单位。
    /// 表基址不对时，拿这些真单位去反推/验证候选表，比“数几项像生命对象”可靠得多。
    /// </summary>
    private List<uint> CollectAnchors(UnitScanner sc)
    {
        var list = new List<uint>(24);
        void Add(uint u)
        {
            if (u < 0x10000 || u >= 0x80000000) return;
            if (list.Count >= 24 || list.Contains(u)) return;
            list.Add(u);
        }

        foreach (var u in sc.SelectionCandidates) Add(u);

        // 钩子里最近发生的伤害事件：受害者/来源都是引擎给的真单位指针。
        // 加锁读：UI 线程可能正通过“清除伤害明细/查找游戏”清空 _hookEvents，别边枚举边被改。
        lock (_hookEventsLock)
        {
            for (int i = _hookEvents.Count - 1; i >= 0 && list.Count < 24; i--)
            {
                Add(_hookEvents[i].Victim);
                Add(_hookEvents[i].Source);
            }
        }

        foreach (var u in sc.Known.Keys)
        {
            if (list.Count >= 24) break;
            Add(u);
        }
        return list;
    }

    private static bool IsProcessAlive(Wc3Game g)    {
        try { return !System.Diagnostics.Process.GetProcessById(g.Mem.Pid).HasExited; }
        catch { return false; }
    }

    private void HandleGameGone(string why)
    {
        lock (_gate)
        {
            if (Game == null) return;
            try { Game.Dispose(); } catch { }
            Game = null;
            Scanner = null;
            // **游戏退出不要清空界面上的内容**：把最后一次快照里的单位/结算原样带过来，
            // 只把状态改成“已退出”。（以前这里 new 一个空快照 → 表格立刻被清空。）
            var prev = Current;
            Current = new Snapshot
            {
                At = DateTime.Now,
                Status = why,
                Ready = false,
                Units = prev.Units,
                Settlements = prev.Settlements,
                Stats = prev.Stats,
            };
        }
        Log.Warn(why);
        Changed?.Invoke();
    }

    /// <summary>
    /// 清除伤害明细：清掉钩子事件 + 每条结算里由钩子派生的构成/来源，
    /// 这样“伤害构成”的汇总也跟着一起清（结算行本身保留）。
    /// </summary>
    public void ClearHookDetails()
    {
        lock (_gate)
        {
            lock (_hookEventsLock) _hookEvents.Clear();
            HookEventCount = 0;
            _combatStats.Clear();   // 明细都清了，属性记录也不再沿用
            foreach (var s in Tracker.Settlements)
            {
                s.HookRows = null;
                s.HookCombos = null;
                s.HookSources = null;
                s.HookMatchNote = "";
                s.HookDamageScale = 1.0;
            }
            Current = new Snapshot
            {
                At = DateTime.Now,
                Status = Current.Status,
                Ready = Current.Ready,
                Units = Current.Units,
                Settlements = Current.Settlements,
                Stats = Current.Stats,
            };
        }
        Log.Write("已清除伤害明细（事件 + 汇总结算）");
    }

    private void Publish(Wc3Game g, UnitScanner sc, ScanStats stats)
    {
        // 先保留扫描器的**全部实例**：属性轮询要靠这些地址学 Aloc / IsUnitIllusion。
        // 不能在过滤后用 units 当 RawUnits —— 那样同类型只剩一个代表，镜像永远学不到镜像位。
        var allUnits = new List<UnitView>(sc.Known.Count);
        foreach (var u in sc.Known.Values)
        {
            var t = Tracker.GetTrack(u.Addr);
            double dps = 0;
            if (t is { FirstHit: not null, LastHit: not null })
            {
                double sec = Math.Max(0.5, (DateTime.Now - t.FirstHit.Value).TotalSeconds);
                dps = t.TotalDamage / sec;
            }
            allUnits.Add(new UnitView
            {
                Addr = u.Addr,
                TypeCode = u.TypeCode,
                Name = NameOf(u.TypeCode),
                Owner = OwnerText(u.Addr, u.OwnerSlot),
                OwnerSlot = u.OwnerSlot,
                Hp = u.Hp,
                HpMax = u.HpMax,
                HpPercent = u.HpPercent,
                Armor = u.Armor,
                Taken = t?.TotalDamage ?? 0,
                Hits = t?.Events.Count ?? 0,
                Dps = dps,
                State = u.Hp <= 0 ? "死亡" : "存活",
                X = u.X,
                Y = u.Y,
                Found = u.FoundBy,
                FirstSeen = t?.FirstSeen ?? DateTime.MinValue,
                FirstHit = t?.FirstHit,
                LastHit = t?.LastHit,
                InstanceIndex = t?.InstanceIndex ?? 1,
                MaxHit = t?.MaxHit ?? 0,
                Peak1s = (t != null && t.Events.Count > 0) ? DamageTracker.Peak(t.Events, 1.0) : 0,
                IsIllusion = IsAttrIllusion(u.Addr, u.TypeCode),
                Participated = _damageUnitAddrs.Contains(u.Addr),
            });
        }

        /* 战场单位只保留本局参与过伤害事件的地址（victim/source）。
           属性轮询也用这份过滤后的 RawUnits，没参战的单位不再学习/显示。 */
        var rawUnits = allUnits.Where(u => u.Participated).ToList();

        /* 蝗虫默认隐藏；镜像实例无论是否带 Aloc 都保留。
           同一类型出现过镜像时，原单位也保留一行：否则 locust=1 的原单位会先被过滤，
           列表里只剩“（镜像）”，看起来像幻象覆盖了本体。 */
        var illusionCodes = new HashSet<string>(
            rawUnits.Where(u => u.IsIllusion).Select(u => u.TypeCode)
                .Concat(_retainedTypes.Values.Where(u => u.IsIllusion).Select(u => u.TypeCode)),
            StringComparer.OrdinalIgnoreCase);
        var units = rawUnits
            .Where(u => UnitDisplayPolicy.ShouldDisplay(
                IsUnitHiddenByLocust(u.Addr, u.TypeCode),
                u.IsIllusion,
                illusionCodes.Contains(u.TypeCode)))
            .ToList();

        // 同类型 + 同镜像位只显示一行：镜像与原单位分开合并（伤害/次数累加，最大单次/峰值取最大），
        // 并且“消失/死亡过的类型”继续保留在列表里（状态标死亡），不会从表格里消失。
        {
            var merged = new List<UnitView>();
            foreach (var grp in units.GroupBy(UnitTypeKey, StringComparer.OrdinalIgnoreCase))
            {
                var list = grp.ToList();
                var rep = list.OrderByDescending(x => x.Taken).First();
                var one = new UnitView
                {
                    Addr = rep.Addr,
                    TypeCode = rep.TypeCode,
                    Name = rep.Name,
                    Owner = rep.Owner,
                    OwnerSlot = rep.OwnerSlot,
                    Hp = list.Sum(x => x.Hp),
                    HpMax = list.Sum(x => x.HpMax),
                    HpPercent = list.Max(x => x.HpPercent),
                    Armor = rep.Armor,
                    Taken = list.Sum(x => x.Taken),
                    Hits = list.Sum(x => x.Hits),
                    Dps = list.Sum(x => x.Dps),
                    State = list.Any(x => x.Hp > 0) ? "存活" : "死亡",
                    X = rep.X, Y = rep.Y, Found = rep.Found,
                    FirstSeen = list.Min(x => x.FirstSeen),
                    FirstHit = list.Where(x => x.FirstHit != null).Min(x => x.FirstHit),
                    LastHit = list.Where(x => x.LastHit != null).Max(x => x.LastHit),
                    InstanceIndex = rep.InstanceIndex,
                    MaxHit = list.Max(x => x.MaxHit),
                    Peak1s = list.Max(x => x.Peak1s),
                    Count = list.Count,
                    IsIllusion = rep.IsIllusion,
                    Participated = list.Any(x => x.Participated),
                };
                merged.Add(one);
                _retainedTypes[UnitTypeKey(one)] = one;
            }

            // 属性晚到后重新应用同一规则，避免已学到的蝗虫继续留在死亡保留表。
            foreach (var key in _retainedTypes.Keys.ToList())
            {
                var old = _retainedTypes[key];
                if (UnitDisplayPolicy.ShouldDisplay(
                        IsUnitHiddenByLocust(old.Addr, old.TypeCode),
                        old.IsIllusion,
                        illusionCodes.Contains(old.TypeCode))) continue;
                _retainedTypes.Remove(key);
            }

            // 本轮没出现、但之前出现过的类型：保留最后一条（状态死亡）
            foreach (var kv in _retainedTypes)
            {
                if (merged.Any(m => string.Equals(UnitTypeKey(m), kv.Key, StringComparison.OrdinalIgnoreCase))) continue;
                var old = kv.Value;
                merged.Add(new UnitView
                {
                    Addr = old.Addr, TypeCode = old.TypeCode, Name = old.Name,
                    Owner = old.Owner, OwnerSlot = old.OwnerSlot,
                    Hp = 0, HpMax = old.HpMax, HpPercent = 0, Armor = old.Armor,
                    Taken = old.Taken, Hits = old.Hits, Dps = old.Dps,
                    State = "死亡", X = old.X, Y = old.Y, Found = old.Found,
                    FirstSeen = old.FirstSeen, FirstHit = old.FirstHit, LastHit = old.LastHit,
                    InstanceIndex = old.InstanceIndex, MaxHit = old.MaxHit, Peak1s = old.Peak1s,
                    Count = old.Count, IsIllusion = old.IsIllusion,
                    Participated = old.Participated,
                });
            }
            units = merged;
        }

        /* 保留表可能带出上一轮没参战的类型；最终再收一次，只留参与过伤害的。 */
        units = units.Where(u => u.Participated).ToList();
        units.Sort((a, b) => b.Taken.CompareTo(a.Taken));

        // 每轮都更新（取本局峰值）：退游戏那一帧可能已经扫不到单位了，但历史文件仍要有真实单位数。

        // 名字可能比结算晚一步才知道（钩子事件 / 插件日志后写出来）→ 回头把还没名字的结算补上。
        // 界面层用 s.UnitName（空就退显示类型码），所以这里补完名字后界面要能感知到名字变化。
        // 补完名字后再按用户的 ignore_unit_names 手动名单过滤一次（可选功能，不是马甲判定）。
        for (int i = Tracker.Settlements.Count - 1; i >= 0; i--)
        {
            var s = Tracker.Settlements[i];
            if (s.UnitName.Length == 0) s.UnitName = NameOf(s.TypeCode);
            // 结算后才到的普攻事件也要算进去（伤害事件→缓存的顺序每轮都可能晚一拍）。
            ApplyCombatStats(s);
            // 补偿过滤：结算时地址可能还没记上 / 后来才变成马甲，这里再按“地址/类型码/属性”摘一次。
            if (IsLocustForSettlement(s.Addr, s.TypeCode, out bool locustAddr, out bool locustCode, out bool locustAttr))
            {
                RemoveLocustSettlement(s, locustAddr, locustCode, locustAttr);
                continue;
            }
            if (!IsIgnoredByName(s)) continue;
            RemoveSettlement(s);
        }

        lock (_gate)
        {
            // 结算快照在「条数变了」或「摘掉过结算」时重算一次（过滤见 FilterNoSource）。
            // 重算时就在这里按唯一口径排好（DiedAt 降序 → InstanceIndex → Addr）：
            // 账本追加顺序不再是显示顺序 —— 补建结算（SynthesizeHookDeaths）可能是更早的时间，
            // 如果让界面自己猜“新的一定在后面”，就会把旧时间插到新行上面（用户截图里的乱序）。
            if (Tracker.Settlements.Count != _lastSettlementCount || _settlementSnapshotDirty)
            {
                _lastSettlementCount = Tracker.Settlements.Count;
                _settlementSnapshotDirty = false;
                _settlementSnapshot = SettlementOrder.SortDescending(FilterNoSource(Tracker.Settlements));
            }
            Current = new Snapshot
            {
                At = DateTime.Now,
                Units = units,
            RawUnits = rawUnits,
            DamageUnitAddrs = new HashSet<uint>(_damageUnitAddrs),
            Pid = Game?.Mem.Pid ?? 0,
                Settlements = _settlementSnapshot,
                Stats = stats,
                Ready = true,
                Status = units.Count == 0
                    ? g.Message + "　（还没发现单位：确认已经进入地图；若一直为 0，请点【生成诊断报告】把报告发我）"
                    : g.Message,
            };
        }
        Changed?.Invoke();
    }

    /// <summary>战场单位合并/保留键：类型码 + 实例级镜像位（镜像不能和同类型原单位合并）。</summary>
    private static string UnitTypeKey(UnitView u) =>
        u.TypeCode + "|" + (u.IsIllusion ? "I" : "0");

    /// <summary>一条结算算不算“有来源”：只看钩子分组有没有来源（插件日志来源不再参与界面显示）。</summary>
    private static bool HasSource(Settlement s)
        => s.HookSources is { Count: > 0 };

    /// <summary>
    /// 过滤「无来源结算」：钩子没有来源 = 自然消亡（例如 e06l 这类单位到点自己消失），
    /// 不进结算列表、也不进分组统计。底层 Tracker.Settlements 仍保留它们（等名字补全用），
    /// 只在这里产出界面快照时摘掉。限流日志最多 10 条。
    /// </summary>
    private List<Settlement> FilterNoSource(IEnumerable<Settlement> all)
    {
        var kept = new List<Settlement>();
        foreach (var s in all)
        {
            if (HasSource(s)) { kept.Add(s); continue; }
            if (_loggedNoSource.Add(s) && _noSourceLogged < 10)
            {
                _noSourceLogged++;
                Log.Write($"跳过无来源结算：{s.TypeCode} 0x{s.Addr:X8}（钩子没有来源）");
            }
        }
        return kept;
    }

    /// <summary>
    /// 用于名字匹配的名字：优先单位名；名字还不知道时退回类型码
    /// （假魔兽/插件没装时名字就是类型码；真实马甲的名字通常由钩子事件带回）。
    /// 仅用于用户自定义的 ignore_unit_names 名单，不参与马甲判定。
    /// </summary>
    private static string NameForFilter(Settlement s) => s.UnitName.Length > 0 ? s.UnitName : s.TypeCode;

    /// <summary>这条结算是不是命中用户自定义的名字忽略名单（ini ignore_unit_names / DSS_IGNORE_UNIT_NAMES）。</summary>
    private bool IsIgnoredByName(Settlement s) => UnitNameFilter.Hits(NameForFilter(s), _ignoreKeywords);

    /// <summary>把命中的结算从账本/待归因队列里摘掉，并记限流日志（最多 10 条）。</summary>
    private void RemoveSettlement(Settlement s)
    {
        Tracker.Settlements.Remove(s);
        _awaitingAttribution.Remove(s);
        _settlementSnapshotDirty = true;
        if (_ignoredNameLogged >= 10) return;
        _ignoredNameLogged++;
        Log.Write($"跳过手动忽略单位：{NameForFilter(s)}({s.TypeCode}) 0x{s.Addr:X8}（命中 ignore_unit_names）");
    }

    /// <summary>
    /// 类型码是否命中“蝗虫马甲”集合：只认 4 字符类型码，完全相等或大小写不敏感相等
    /// （集合本身用 OrdinalIgnoreCase）；**不做子串匹配**。
    /// 集合里的码全部来自 ddh 实测 Aloc&gt;0 的事件（不是预先写死的类型码表）。
    /// </summary>
    internal static bool LocustCodeHit(string? typeCode, IReadOnlySet<string> codes)
        => !string.IsNullOrEmpty(typeCode) && typeCode.Length == 4 && codes.Contains(typeCode);

    /// <summary>
    /// 结算/单位是否算蝗虫马甲：**地址命中 或 类型码命中** 都算。
    /// 地址会随单位对象重建而变（真机日志里的“按类型码 e04T 兜底匹配”），所以类型码也要认。
    /// byAddr/byCode 回传命中来源，日志里能看出是地址没对上、靠类型码救回来的。
    /// </summary>
    internal static bool LocustHit(uint addr, string? typeCode,
        IReadOnlyDictionary<uint, bool> victims, IReadOnlySet<string> codes,
        out bool byAddr, out bool byCode)
    {
        byAddr = addr != 0 && victims.TryGetValue(addr, out bool v) && v;
        /* type-code Aloc cache: address is reused, type code is the identity */
        byCode = LocustCodeHit(typeCode, codes);
        return byAddr || byCode;
    }

    private bool IsLocust(uint addr, string? typeCode, out bool byAddr, out bool byCode)
        => LocustHit(addr, typeCode, _locustVictims, _locustCodes, out byAddr, out byCode);

    /// <summary>
    /// 死亡结算用：事件/类型码命中 **或** ddh 属性响应里这个地址实测带 Aloc，都算。
    /// 死亡结算不做镜像例外 —— 用户要求 Aloc 一律不统计。
    /// </summary>
    private bool IsLocustForSettlement(uint addr, string? typeCode,
        out bool byAddr, out bool byCode, out bool byAttr)
    {
        byAttr = IsAttrLocust(addr, typeCode);
        return IsLocust(addr, typeCode, out byAddr, out byCode) || byAttr;
    }

    private static string LocustReason(bool byAddr, bool byCode, bool byAttr)
    {
        var parts = new List<string>(3);
        if (byAddr) parts.Add("地址");
        if (byCode) parts.Add("类型码");
        if (byAttr) parts.Add("属性");
        return parts.Count == 0 ? "命中" : string.Join("+", parts) + "命中";
    }

    /// <summary>
    /// 用致命钩子事件给“账本里从没有过”的单位补一条死亡结算。
    /// 典型：一击秒杀的低血单位、召唤物、刚进图还没被扫描到的单位——扫描看不到死亡过程，
    /// DamageTracker 没有“上一帧血量”就不会结算；事件里有 HP 前后值和来源，足够补出来。
    /// 同一地址/同一时间已存在结算（含补建）时跳过，避免重复。
    /// </summary>
    private void SynthesizeHookDeaths(IReadOnlyList<DamageHook.HookEvent> fresh)
    {
        foreach (var e in fresh)
        {
            if (e.VictimLocust) continue;   // Aloc 马甲按规则不进结算
            if (IsLocustForSettlement(e.Victim, e.VictimCode, out _, out _, out _)) continue;

            var s = HookDeath.FromLethalEvent(e, NameOf(e.VictimCode));
            if (s == null) continue;

            bool duplicate = false;
            foreach (var other in Tracker.Settlements)
            {
                if (other.Addr != s.Addr) continue;
                if (Math.Abs((other.DiedAt - s.DiedAt).TotalSeconds) <= 2.0) { duplicate = true; break; }
            }
            if (duplicate) continue;

            Tracker.Settlements.Add(s);
            _settlementSnapshotDirty = true;
            Log.Write($"钩子补建死亡结算：{s.DisplayName} 0x{s.Addr:X8}（HP {e.HpBefore:0.#}→0，账本里没有这个单位）");
            OnSettled(s);   // 复用名字/来源匹配/分组统计的完整流程
        }
    }

    /// <summary>把战斗中记录到的属性（护甲 / 普攻伤害与间隔 / Aloc）拷进这条死亡结算。</summary>
    private void ApplyCombatStats(Settlement s)
    {
        if (s.Addr == 0) return;
        if (_combatStats.TryGet(s.Addr, out var stats)) stats.ApplyTo(s);
    }

    /// <summary>
    /// 结算刚建立时如果还没轮询到致命事件（HookSources 为空），会先被 FilterNoSource 藏起来；
    /// 新一批钩子事件到达后在这里补挂，挂上就把快照标脏，让列表重新把这条结算显示出来。
    /// 只重试结算后 10 秒内的（再晚基本是本来就没有来源的“自然消失”，不必反复扫事件表）。
    /// </summary>
    private void RetryLateHookAttach()
    {
        if (Tracker.Settlements.Count == 0) return;
        var now = DateTime.Now;
        bool any = false;
        foreach (var s in Tracker.Settlements)
        {
            if (s.HookSources is { Count: > 0 }) continue;
            if ((now - s.DiedAt).TotalSeconds > 10) continue;
            if (AttachHookRows(s)) any = true;
        }
        if (any) _settlementSnapshotDirty = true;
    }

    /// <summary>把蝗虫马甲结算从账本/待归因队列里摘掉，并记限流日志（最多 10 条）。</summary>
    private void RemoveLocustSettlement(Settlement s, bool byAddr, bool byCode, bool byAttr)
    {
        Tracker.Settlements.Remove(s);
        _awaitingAttribution.Remove(s);
        _settlementSnapshotDirty = true;
        if (_locustLogged >= 10) return;
        _locustLogged++;
        string name = s.UnitName.Length > 0 ? s.UnitName : "(名字未知)";
        Log.Write($"跳过蝗虫马甲结算：{name}({s.TypeCode}) 0x{s.Addr:X8}（{LocustReason(byAddr, byCode, byAttr)}）");
    }

    private void OnSettled(Settlement s)
    {
        // 同一次死亡如果之前用“致命钩子事件”补建过，正常扫描结算来了就处理掉，避免一条死亡出现两条：
        //   · 正常结算有伤害（真的账本死亡）→ 删掉补建的那条，用正常结算；
        //   · 正常结算是 0 伤害的“尸体消失”（补建之后账本才第一次看到 0 血尸体）→ 丢掉空的，保留补建的死亡。
        if (!s.SyntheticHookDeath)
        {
            Settlement? synthetic = null;
            foreach (var other in Tracker.Settlements)
            {
                if (ReferenceEquals(other, s) || !other.SyntheticHookDeath) continue;
                if (other.Addr != s.Addr) continue;
                synthetic = other;
                break;
            }
            if (synthetic != null)
            {
                if (s.HitCount == 0 || s.TotalDamage <= 0.005)
                {
                    Tracker.Settlements.Remove(s);
                    _settlementSnapshotDirty = true;
                    Log.Write($"忽略补建后的空尸体结算：{s.TypeCode} 0x{s.Addr:X8}（保留钩子补建的那条死亡）");
                    return;
                }
                if (Math.Abs((synthetic.DiedAt - s.DiedAt).TotalSeconds) <= 2.0)
                {
                    if (s.Kind == "消失") s.Kind = "死亡";   // 钩子已经看到血 0，这其实是死亡
                    Tracker.Settlements.Remove(synthetic);
                    _settlementSnapshotDirty = true;
                    Log.Write($"替换补建结算：{s.TypeCode} 0x{s.Addr:X8}（正常扫描结算已到，删掉钩子补建的那条）");
                }
            }
        }

        // 名字先补：蝗虫/名字过滤的日志都要能写“名字(码)”，也避免名字晚到时漏过滤。
        if (s.UnitName.Length == 0) s.UnitName = NameOf(s.TypeCode);

        // 战斗中已经记录好的护甲/普攻/技能，直接拷进这条结算（不是死亡时再去读内存）。
        ApplyCombatStats(s);

        // 蝗虫马甲（地图内部假单位）不进死亡结算：地址/类型码/属性任一口径命中都算。
        if (IsLocustForSettlement(s.Addr, s.TypeCode, out bool byAddr, out bool byCode, out bool byAttr))
        {
            RemoveLocustSettlement(s, byAddr, byCode, byAttr);
            return;
        }

        // 用户自定义的名字忽略名单（可选，默认空）：与马甲判定无关，命中才摘掉。
        if (IsIgnoredByName(s))
        {
            RemoveSettlement(s);
            return;
        }

        // 拥有者：优先使用事件里的 CUnit+0x58 槽位，没有才用扫描快照中的槽位
        if (_hookOwners.TryGetValue(s.Addr, out var hookOwner) && hookOwner >= 0)
            s.OwnerSlot = hookOwner;

        // 侵入式钩子：把**这个单位**在它存活期间受到的伤害事件挑出来，做成分组统计。
        // 注意：致命一击的事件可能比“扫描到 HP=0”晚 100~200ms 才被轮询到，
        // 所以这里匹配不到时不要紧——每轮的结算维护循环会再调一次 AttachHookRows()。
        AttachHookRows(s);

        Log.Write("死亡结算：" + s.TitleLine().Trim());

        // 先挂到“等来源”队列：插件日志通常是同一瞬间写出来的，稍后补上
        if (ReadPluginLog) _awaitingAttribution.Add(s);

    }

    /// <summary>
    /// 把该单位存活期间的钩子事件匹配进结算（来源 Σ 行 + 组合行）。
    /// 返回 true = 这次真的补上了（调用方可以据此让“无来源过滤”重算快照）。
    /// 结算刚建立时可能还没有致命事件（钩子轮询比扫描慢一拍），后面每轮会重试。
    /// </summary>
    private bool AttachHookRows(Settlement s)
    {
        if (s.HookSources is { Count: > 0 }) return true;
        if (HookEventCount <= 0) return false;

        var from = HookGroupingStart(s.SyntheticHookDeath, s.FirstSeen, s.DiedAt);
        var to = s.DiedAt.AddSeconds(2);          // 致命那一击可能刚好落在结算之后一点
        var m = HookMatcher.Select(HookEvents, s.Addr, s.TypeCode, from, to);
        if (m.Events.Count == 0) return false;

        Func<string, string>? nameOf = PluginLog != null ? PluginLog.NameOf : null;
        double engineTotal = m.Events.Sum(e => e.Amount);

        // 折算系数：表里的"伤害 → 实际伤害"两列要用它。
        //   优先用**钩子自己采到的每笔实际伤害**（ddh v3：伤害函数返回后重新读血），
        //   它比"结算级 观测掉血/引擎伤害"精确得多；旧 DLL 没有这段才退回结算级折算。
        double scale = 1.0;
        double hookActual = m.Events.Where(e => e.HpValid).Sum(e => e.Actual);
        double hookEngine = m.Events.Where(e => e.HpValid).Sum(e => e.Amount);
        if (hookEngine > 0.01 && m.Events.Any(e => e.HpValid)) scale = hookActual / hookEngine;
        else if (engineTotal > 0.01 && s.TotalDamage > 0.01) scale = s.TotalDamage / engineTotal;

        if (s.SyntheticHookDeath && m.Events.Count > 0)
        {
            var ordered = m.Events.OrderBy(e => e.At).ToList();
            double Value(DamageHook.HookEvent e) =>
                e.HpValid ? Math.Max(0, e.Actual) : Math.Max(0, e.Amount * scale);
            s.FirstSeen = ordered[0].At;
            s.HitCount = ordered.Count;
            s.TotalDamage = ordered.Sum(Value);
            s.MaxHit = ordered.Max(Value);
            s.MinHit = ordered.Min(Value);
            s.Peak1s = PeakHook1s(ordered, scale);
        }
        s.HookDamageScale = scale;

        string SourceLabelOf(DamageHook.HookEvent e)
        {
            string name = e.SourceName.Length > 0
                ? e.SourceName
                : (nameOf?.Invoke(e.SourceCode) ?? "");
            string title = TryGetTitle(e.Source, e.SourceCode, out string t) ? t : e.SourceTitle;
            return Wc3Text.UnitIdentity(name, title, e.SourceCode);
        }

        s.HookRows = HookBreakdown.Build(m.Events, nameOf, scale: scale,
                                          isIllusionOf: IsAttrIllusion,
                                          sourceLabelOf: SourceLabelOf);
        s.HookCombos = HookBreakdown.Combinations(m.Events, nameOf, scale,
                                                   isIllusionOf: IsAttrIllusion,
                                                   sourceLabelOf: SourceLabelOf);
        s.HookSources = HookBreakdown.Sources(m.Events, scale,
                                               isIllusionOf: IsAttrIllusion,
                                               sourceLabelOf: SourceLabelOf);
        // 致命一击：血从 >0 到 ≤0 的最后一条；找不到就退最后一条（面板显示“致命一击”行用）。
        s.FatalHookEvent = m.Events.LastOrDefault(e => e.HpValid && e.HpAfter <= 0.05)
                           ?? m.Events.LastOrDefault();
        s.HookMatchNote = m.Note;
        Log.Write($"结算带上钩子分组：{s.TypeCode} 0x{s.Addr:X8} 共 {m.Events.Count} 笔 / 引擎 {engineTotal:0.#} / 观测 {s.TotalDamage:0.#}" +
                  $"（折算 ×{scale:0.###}{(m.Events.Any(e => e.HpValid) ? "，来自钩子逐笔实际伤害" : "")}，{m.Note}）");
        return true;
    }

    /// <summary>补建结算必须回溯本局全部事件；正常结算从首次见到前一秒开始。</summary>
    internal static DateTime HookGroupingStart(bool synthetic, DateTime firstSeen, DateTime diedAt) =>
        synthetic
            ? DateTime.MinValue
            : (firstSeen != default ? firstSeen.AddSeconds(-1) : diedAt.AddMinutes(-5));

    private static double PeakHook1s(IReadOnlyList<DamageHook.HookEvent> events, double scale)
    {
        double sum = 0, peak = 0;
        int left = 0;
        for (int right = 0; right < events.Count; right++)
        {
            var e = events[right];
            sum += e.HpValid ? Math.Max(0, e.Actual) : Math.Max(0, e.Amount * scale);
            while ((e.At - events[left].At).TotalSeconds > 1.0)
            {
                var old = events[left++];
                sum -= old.HpValid ? Math.Max(0, old.Actual) : Math.Max(0, old.Amount * scale);
            }
            if (sum > peak) peak = sum;
        }
        return peak;
    }

    /// <summary>这个进程里是否已经有 ddh：共享内存能打开，或模块列表里有 ddh.dll（WFE/ASI 预加载）。</summary>
    private bool DdhAlreadyPresent(int pid)
    {
        if (_hook.IsOpen) return true;
        if (_hook.Open(pid)) return true;
        try
        {
            using var p = System.Diagnostics.Process.GetProcessById(pid);
            foreach (System.Diagnostics.ProcessModule m in p.Modules)
                if (string.Equals(m.ModuleName, "ddh.dll", StringComparison.OrdinalIgnoreCase)) return true;
        }
        catch { }
        return false;
    }

    /// <summary>
    /// 接管已有 ddh：只打开共享内存，不注入。共享内存还没就绪就保持 pending，下个循环再试。
    /// </summary>
    private void AdoptExistingHook(Wc3Game g)
    {
        _attachExistingPid = g.Mem.Pid;
        if (!_hook.IsOpen && !_hook.Open(g.Mem.Pid))
        {
            if (HookStatus != "检测到已有 ddh，等待共享内存…")
            {
                HookStatus = "检测到已有 ddh，等待共享内存…";
                Log.Write("hook：检测到 ddh.dll 已由 WFE/ASI 加载，等待共享内存就绪（不会重复注入）");
            }
            return;
        }
        if (_hookTried) return;
        _hookTried = true;
        HookAttached = _hook.HookOk;
        HookStatus = HookAttached
            ? $"已挂钩（接管 WFE/ASI 已加载的 ddh，未重复注入；RVA 0x{_hook.HookRva:X}）"
            : "检测到现有 ddh，但 DLL 报告挂钩失败";
        Log.Write("hook：检测到已有 ddh（WFE/ASI 预加载），跳过注入，直接接管共享内存");
        Log.Write($"hook：ddh 协议 v{_hook.Version}，每条记录 {_hook.RecordSize} 字节，名字字段 {_hook.NameFieldSize} 字节");
        if (_hook.HpSupported) Log.Write("hook：本 DLL 会采集“实际伤害”（伤害函数返回后重新读血）");
        Log.Write("hook 状态：" + HookStatus);
    }

    /// <summary>
    /// 侵入式伤害事件：第一次连上游戏时把 ddh.dll 注入进去（挂 game.dll+0x67DC40 的钩子），
    /// 之后每次循环从共享内存里读新事件。注入失败不影响主功能（只是没有引擎级归因）。
    /// 如果游戏进程里已经有 ddh（WFE/ASI 在启动时加载），只接管共享内存，不再重复注入。
    /// </summary>
    private void PumpHook(Wc3Game g, UnitScanner sc)
    {
        if (!HookEnabled)
        {
            if (HookStatus != "未启用（ini 里 hook_enable=1 打开）")
            {
                HookStatus = "未启用（ini 里 hook_enable=1 打开）";
                Log.Write("hook：" + HookStatus);
            }
            return;
        }
        if (!g.IsReady) return;

        /* 不走共享内存：只读 ddh 写的 SQLite 明细（ddh v22）。 */
        if (!HookSharedMemory && !_hookTried)
        {
            _hookTried = true;
            HookAttached = false;
            HookStatus = "SQLite 明细（不走共享内存）";
            Log.Write("hook：已禁用共享内存，伤害明细改读 " + DdhEventDb.FixedPath +
                      "（session " + g.SessionId + "）");
        }

        // 已经确认“这个进程有现成 ddh”，但共享内存还没就绪：每次循环重试打开，绝不注入。
        if (_attachExistingPid == g.Mem.Pid && !_hook.IsOpen)
        {
            AdoptExistingHook(g);
            if (!_hook.IsOpen) return;
        }

        if (!_hookTried)
        {
            // WFE/ASI 在游戏启动时就把 ddh.dll 加载了 → 不能再注入第二个实例（两条钩子/两套 seq 会写坏同一个环）。
            if (DdhAlreadyPresent(g.Mem.Pid))
            {
                AdoptExistingHook(g);
                return;
            }

            // ---- 预检：先比完整性级别，再决定要不要真去注入 ----
            // 跨 IL 的写权限是内核直接拒的（err=5），硬着头皮注入只会白跑一趟、还要等 8 秒超时，
            // 而且注入器退回的"OpenProcess 失败: 5"对用户毫无解释力。
            IntegrityLevel gameIl = Integrity.OfProcess(g.Mem.Pid, out int ilErr);
            // 两种情况都算"权限墙"：
            //  ① 读到了 IL，但游戏更高 → 内核直接拒绝 VM_WRITE/CREATE_THREAD；
            //  ② 连 QUERY_LIMITED 都失败且 err=5 → 目标是管理员/其他用户/受保护进程跑的，
            //     这种情况多半连只读都成问题（界面会另有"权限不足"横幅），更别说注入。
            bool blocked = gameIl == IntegrityLevel.Unknown
                ? ilErr == 5
                : !Integrity.CanInject(gameIl);
            if (blocked)
            {
                if (_hookIlBlockedPid != g.Mem.Pid)
                {
                    _hookIlBlockedPid = g.Mem.Pid;
                    HookBlockedByIntegrity = true;

                    // 三种"打不开"必须分开说，否则用户只能瞎猜：
                    //  A. 读到了 IL，游戏更高        → 完整性级别：提权才管用，SeDebug 帮不上
                    //  B. 连查询都 err=5、SeDebug 没有 → 没提权，DACL 就把我们挡在门外
                    //  C. 连查询都 err=5、SeDebug 已启用 → 仍然打不开：受保护进程 / 跨会话 / 跨用户
                    string cause;
                    if (gameIl != IntegrityLevel.Unknown)
                    {
                        cause = Integrity.Diff(Integrity.Self, gameIl) +
                                "，跨完整性级别（提权才管用，SeDebugPrivilege 帮不上）";
                        HookIntegrityHint = Integrity.Diff(Integrity.Self, gameIl);
                    }
                    else if (Privilege.DebugState == "已启用")
                    {
                        cause = "游戏拒绝访问（err=5），SeDebugPrivilege 已启用仍打不开"
                              + "（可能是受保护进程，或跨会话/跨用户运行）";
                        HookIntegrityHint = "游戏拒绝访问（err=5，SeDebug 已启用）";
                    }
                    else
                    {
                        cause = "游戏拒绝访问（err=5），当前没有 SeDebugPrivilege"
                              + "（多半是平台/服务以更高权限拉起，需要以管理员身份重启）";
                        HookIntegrityHint = "游戏拒绝访问（err=5）";
                    }

                    HookStatus = "注入被拦下：" + cause;
                    Log.Write("hook：" + HookStatus);
                }
                return;   // 故意不置 _hookTried：换进程/提权重启后还要再试
            }

            _hookTried = true;
            string dll = Path.IsPathRooted(HookDllPath) ? HookDllPath : Path.Combine(AppContext.BaseDirectory, HookDllPath);
            string inj = Path.IsPathRooted(HookInjectorPath) ? HookInjectorPath : Path.Combine(AppContext.BaseDirectory, HookInjectorPath);
            var r = DamageHook.Inject(g.Mem.Pid, inj, dll);
            Log.Write($"hook 注入：{(r.ok ? "成功" : "失败")} —— {r.message}");
            if (r.ok && _hook.Open(g.Mem.Pid))
            {
                HookAttached = _hook.HookOk;
                HookStatus = HookAttached ? $"已挂钩（game.dll 基址 0x{_hook.GameDllBase:X8}，实际 RVA 0x{_hook.HookRva:X}）" : "注入成功但 DLL 报告挂钩失败";
                Log.Write($"hook：ddh 协议 v{_hook.Version}，每条记录 {_hook.RecordSize} 字节，名字字段 {_hook.NameFieldSize} 字节");
                // ddh 自己的日志：默认就写在 ddh.dll 同目录（ddh-<PID>.log），写不了才退 C:\ 根目录 / %TEMP%
                try
                {
                    string dir = Path.GetDirectoryName(dll) ?? "";
                    // 日志里用相对 exe 目录的路径（hook\ddh-1234.log）；控制台/报告另有绝对路径。
                    Log.Write($"hook 日志：{Log.Relative(Path.Combine(dir, $"ddh-{g.Mem.Pid}.log"))}");
                }
                catch { }
                if (_hook.HpSupported) Log.Write("hook：本 DLL 会采集“实际伤害”（伤害函数返回后重新读血）");
            }
            else HookStatus = "注入失败：" + (r.ok ? _hook.LastError : r.message);
            Log.Write("hook 状态：" + HookStatus);
            return;
        }

        List<DamageHook.HookEvent> fresh;
        if (_hook.IsOpen)
        {
            if (DateTime.UtcNow - _lastHookPoll < TimeSpan.FromMilliseconds(200)) return;
            _lastHookPoll = DateTime.UtcNow;
            fresh = _hook.Poll();
        }
        else
        {
            /* 共享内存没打开（旧 ddh / 只加载了 ddh 的写库模式）：改读 ddh 自己写的 SQLite 明细。 */
            if (DateTime.UtcNow - _lastHookPoll < TimeSpan.FromMilliseconds(400)) return;
            _lastHookPoll = DateTime.UtcNow;
            fresh = DdhEventDb.ReadAfter(g.SessionId, _lastHookSeq, 512, out string dbErr, _dbSinceWallMs);
            if (dbErr.Length > 0)
            {
                if (!_dbReadErrorLogged)
                {
                    _dbReadErrorLogged = true;
                    Log.Warn("ddh 明细库读取失败：" + dbErr + "（路径 " + DdhEventDb.FixedPath +
                             "，session " + g.SessionId + "）");
                }
                return;
            }
        }
        if (fresh.Count == 0) return;

        // 去重：共享内存是环，读指针没推进时会重复读到同一条（之前日志里一条事件刷了 3~4 次）
        fresh = fresh.Where(e => e.Seq > _lastHookSeq).ToList();
        if (fresh.Count == 0) return;
        _lastHookSeq = fresh[^1].Seq;

        // 伤害事件一到就累计“普攻伤害 / 攻击间隔 / Aloc 技能”，不要等死亡结算或右键时才统计。
        // 这样单位死了、事件后续被顶掉，属性表仍然有它活着时的记录。
        foreach (var e in fresh.OrderBy(e => e.At))
        {
            if (e.Victim != 0) _damageUnitAddrs.Add(e.Victim);
            if (e.Source != 0) _damageUnitAddrs.Add(e.Source);
            if (e.Source != 0) _combatStats.GetOrCreate(e.Source).ObserveAttack(e);
            if (e.Victim != 0 && e.VictimLocust) _combatStats.GetOrCreate(e.Victim).ObserveLocust(true);
        }

        // 游戏里没查到名字（那条引擎链在你这个构建上可能不同）→ 退回插件日志的名字表
        if (PluginLog != null)
        {
            fresh = fresh.Select(e => e with
            {
                SourceName = e.SourceName.Length > 0 ? e.SourceName : PluginLog.NameOf(e.SourceCode),
                VictimName = e.VictimName.Length > 0 ? e.VictimName : PluginLog.NameOf(e.VictimCode)
            }).ToList();
        }

        // 事件里带回来的名字缓存进 类型码→名字 表，供结算/存活行显示（插件没装也能显示名字）
        foreach (var e in fresh)
        {
            if (e.SourceName.Length > 0 && e.SourceCode.Length > 0) _hookNames[e.SourceCode] = e.SourceName;
            if (e.VictimName.Length > 0 && e.VictimCode.Length > 0) _hookNames[e.VictimCode] = e.VictimName;
        }

        // 蝗虫马甲：地址 + 类型码两套都记。
        //   判定来源只有 ddh 的 flags bit0（`GetUnitAbilityLevel(handle, 'Aloc') > 0`，与 YDWE 同口径：
        //   YDWE 的 YDWETriggerEvent.j 用 `<= 0` 判普通单位）；不按名字/写死的类型码判马甲。
        //   地址：Aloc 是永久属性，但地址可能复用 → 跟着最近一次事件更新（非蝗虫事件撤掉地址标记）；
        //   类型码：结算里的单位对象地址可能和钩子事件里的 victim 不一致（真机日志的“按类型码兜底匹配”），
        //          所以额外记一份**实测到 Aloc** 的类型码，结算时按“地址 或 类型码”过滤。
        foreach (var e in fresh)
        {
            if (e.Victim == 0) continue;
            if (e.VictimLocust)
            {
                _locustVictims[e.Victim] = true;
                if (!string.IsNullOrEmpty(e.VictimCode) && e.VictimCode.Length == 4)
                    _locustCodes.Add(e.VictimCode);
                if (_locustEventLogged.Count < 10 && _locustEventLogged.Add(e.Victim))
                    Log.Write($"蝗虫(Aloc)事件：victim=0x{e.Victim:X8} code={e.VictimCode}（flags bit0=1，已记地址+类型码）");
            }
            else
            {
                _locustVictims.Remove(e.Victim);   // 地址被新单位复用 / 已不带 Aloc
            }
        }

        // 把事件里的 CUnit+0x58 玩家槽位记成「地址 → 玩家号」，给死亡结算和存活行回填
        foreach (var e in fresh)
        {
            if (e.Victim != 0 && e.VictimOwner >= 0) _hookOwners[e.Victim] = e.VictimOwner;
            if (e.Source != 0 && e.SourceOwner >= 0) _hookOwners[e.Source] = e.SourceOwner;
        }

        // 第一条带 owner 的事件 → 记一次「玩家号来源」诊断（native / 退回 OwnerResolver）
        if (!_ownerSourceLogged)
        {
            _ownerSourceLogged = true;
            bool native = fresh.Any(e => e.VictimOwner >= 0 || e.SourceOwner >= 0);
            Log.Write(native ? "玩家号来源：事件(native)" : "玩家号来源：退回 OwnerResolver");
        }

        HookEventCount += fresh.Count;
        lock (_hookEventsLock)
        {
            _hookEvents.AddRange(fresh);
            int over = _hookEvents.Count - HookEventCapacity;
            if (over > 0)
            {
                _hookEvents.RemoveRange(0, over);
                if (!_hookCapLogged)
                {
                    _hookCapLogged = true;
                    Log.Write($"事件历史已达上限，丢弃最旧 {over} 条");
                }
            }
        }

        // 钩子事件里的源/目标单位指针 → 当“已知锚点”补进单位账本（没被选中的单位也能被跟踪/结算）
        foreach (var e in fresh)
        {
            sc.RegisterHookAnchor(e.Victim);
            sc.RegisterHookAnchor(e.Source);
        }

        // 兜底：账本里从没见过这个单位，但事件已经看到它 血>0 → 0（一击死/召唤物/刚进图）。
        // 这种单位扫描抓不到“上一帧血量”，DamageTracker 不会结算；用事件本身补一条死亡结算。
        SynthesizeHookDeaths(fresh);

        foreach (var e in fresh.Take(20)) Log.Write("伤害事件：" + e);
    }

    /// <summary>
    /// 每秒读一次游戏内插件日志，把新解析出来的结算“认领”给对应的外部结算
    /// （按类型码 + 时间就近匹配）。这样纯外部模式也能显示“谁打的、什么攻击类型”。
    /// </summary>
    private void PumpPluginLog()
    {
        if (!ReadPluginLog) return;
        if (DateTime.UtcNow - _lastPluginPoll < TimeSpan.FromSeconds(1)) return;
        _lastPluginPoll = DateTime.UtcNow;

        PluginLog ??= new PluginLogReader(PluginLogPath, fromStart: true);
        PluginLog.Poll();

        if (_awaitingAttribution.Count == 0) return;

        var window = TimeSpan.FromSeconds(20);
        for (int i = _awaitingAttribution.Count - 1; i >= 0; i--)
        {
            var s = _awaitingAttribution[i];
            var m = PluginLog.Match(s.TypeCode, s.DiedAt, window);
            if (m != null)
            {
                s.Attribution = PluginAttribution.From(m);
                AttributedCount++;
                _awaitingAttribution.RemoveAt(i);
                Log.Write($"结算补上来源：{s.TypeCode} ← 插件 {m.Name}({m.Code}) 来源 {m.Sources.Count} 个");
            }
            else if (DateTime.Now - s.DiedAt > TimeSpan.FromSeconds(60))
            {
                _awaitingAttribution.RemoveAt(i);   // 等太久了，放弃
            }
        }
    }

    public void Dispose() => Stop();
}





