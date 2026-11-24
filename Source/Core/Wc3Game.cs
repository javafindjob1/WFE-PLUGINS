using System.Diagnostics;

namespace War3DeathSettlement.Core;

public enum AttachState
{
    NoProcess,
    OpenFailed,
    NoGameModule,
    UnsupportedVersion,
    NotInGame,
    Ready
}

/// <summary>连接参数：一般不用给；平台的进程名/版本号不标准时才需要。</summary>
public sealed record AttachOptions(int? Pid = null, string? ExtraProcessNames = null, string? ForceVersion = null);

/// <summary>
/// 一次“连接游戏”的结果 + 会话对象。
/// 连接方式刻意做成 War3Trainer 那样：不需要注入、不需要装插件、不需要改游戏目录，
/// 只是找到正在运行的 war3 进程，读它的内存。
/// </summary>
public sealed class Wc3Game : IDisposable
{
    public RemoteProcess Mem { get; private init; } = null!;
    public Wc3VersionInfo Version { get; private init; } = null!;
    public ModuleInfo GameDll { get; private init; } = null!;
    public ulong GameDllBase => GameDll.Base;

    public uint Ctx { get; private set; }          // *(base + UnitListRva)
    public uint ThisGame { get; private set; }     // *(base + ThisGameRva)
    /// <summary>当前地图的稳定会话键：ctx + ThisGame，游戏换图时变化。</summary>
    public string SessionId => Ctx != 0 && ThisGame != 0 ? $"{Ctx:X8}-{ThisGame:X8}" : "";
    public uint GameMemory { get; private set; }   // *(ThisGame + 0x0C)
    public int PlayerCount { get; private set; }

    public AttachState State { get; private set; }
    public string Message { get; private set; } = "";
    public DateTime AttachedAt { get; } = DateTime.Now;
    /// <summary>某个候选进程打开时因 ERROR_ACCESS_DENIED(5) 被拒时的 PID；没有则为 null。界面据此提示并给出提权按钮。</summary>
    public int? AccessDeniedPid { get; private init; }

    private Wc3Game() { }

    // ------------------------------------------------------------------
    // 连接
    // ------------------------------------------------------------------
    /// <summary>
    /// 找出“像魔兽”的进程（任一命中即可）：
    ///   (a) 进程名像魔兽（ProcessMatch.LooksLikeGame，含命令行额外指定的名字）；
    ///   (b) 进程加载了 game.dll（Toolhelp32 枚举模块，读不到就跳过、不抛）；
    ///   (c) 主窗口标题含 Warcraft III / Frozen Throne / 魔兽（读不到就跳过）。
    /// 排序：优先“加载了 game.dll 且路径像魔兽”的候选，其次“加载了 game.dll”，
    /// 再“进程名像魔兽”，最后“窗口标题像魔兽”。Attach 会逐个尝试，成功后即返回。
    /// 模块枚举（几百个进程，挺贵）做了节流：非扫描轮复用上一次的 game.dll 命中缓存；
    /// 扫描间隔压到 ~1.2s，保证“游戏起来后 ≤3 秒自动连上”（自动连接每 1.5s 试一次）。
    /// </summary>
    public static List<Process> FindCandidates(string? extraNames = null)
    {
        var extra = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        if (!string.IsNullOrWhiteSpace(extraNames))
            foreach (var n in extraNames.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries))
                extra.Add(n.Trim());

        bool sweep = DateTime.UtcNow - _lastModuleSweep >= TimeSpan.FromMilliseconds(1200);
        if (sweep)
        {
            _lastModuleSweep = DateTime.UtcNow;
            _sweepHits.Clear();
        }

        var scored = new List<(Process Proc, int Priority)>();
        var byId = new Dictionary<int, Process>();
        var added = new HashSet<int>();

        foreach (var p in Process.GetProcesses())
        {
            // 绝不把自己当候选：本程序名里含 "war3"、窗口标题里含"魔兽"，两条匹配规则都会命中，
            // 结果就是启动时把自己列成候选，再报一句 "PID <自己> 找不到 game.dll 模块"。
            if (p.Id == Environment.ProcessId) continue;
            byId[p.Id] = p;
            // 读不到进程名（权限/已退出）也不丢：保留 PID，靠 game.dll / 窗口标题兜底匹配。
            // 这正是“按进程名也没找到”的根因 —— 以前 ProcessName 抛异常就 continue 把进程丢了。
            string name = "";
            try { name = p.ProcessName; } catch { }

            // 同族工具（另一个本程序实例、War3Trainer）也别当候选：它们名字含 war3、
            // 标题含"魔兽"，名字规则和标题规则都会误命中。
            if (ProcessMatch.IsOwnTool(name)) continue;

            string dllPath = "";
            bool loadsDll = false;
            if (sweep)
            {
                // Toolhelp32 枚举模块找 game.dll；读不到（权限/已退出）返回 false，绝不抛。
                try { loadsDll = ProcessMatch.TryGetGameDll(p.Id, out dllPath); } catch { }
                if (loadsDll) _sweepHits.Add((p.Id, dllPath));
            }

            bool titleMatch = false;
            try { titleMatch = ProcessMatch.LooksLikeGameTitle(p.MainWindowTitle); } catch { }

            bool pathLike = ProcessMatch.LooksLikeGamePath(dllPath);
            if (!pathLike)
            {
                try { pathLike = ProcessMatch.LooksLikeGamePath(p.MainModule?.FileName); } catch { }
            }

            int priority = ProcessMatch.ScoreCandidate(name, loadsDll, pathLike, titleMatch, extra);
            if (priority < 0) continue;

            scored.Add((p, priority));
            added.Add(p.Id);
        }

        // 非扫描轮：用上次缓存里的“加载了 game.dll”命中补齐候选（游戏可能刚起来）。
        if (!sweep)
        {
            foreach (var (pid, dllPath) in _sweepHits)
            {
                if (added.Contains(pid)) continue;
                Process? p = byId.TryGetValue(pid, out var cached) ? cached : GetProcessByIdSafe(pid);
                if (p == null) continue;
                bool pathLike = ProcessMatch.LooksLikeGamePath(dllPath);
                scored.Add((p, pathLike ? 0 : 1));
                added.Add(pid);
            }
        }

        return scored
            .OrderBy(s => s.Priority)
            .ThenBy(s => s.Proc.Id)
            .Select(s => s.Proc)
            .ToList();
    }

    private static Process? GetProcessByIdSafe(int pid)
    {
        try { return Process.GetProcessById(pid); }
        catch { return null; }
    }

    /// <summary>读进程名失败（权限/已退出）时返回 “?”，绝不抛 —— 错误文案里只当装饰。</summary>
    private static string SafeName(Process p)
    {
        try { return p.ProcessName; }
        catch { return "?"; }
    }

    private static DateTime _lastModuleSweep = DateTime.MinValue;
    private static readonly List<(int Pid, string DllPath)> _sweepHits = new();

    /// <summary>尝试连接；无论成功失败都返回带诊断信息的对象（失败时 State 说明原因）。</summary>
    public static Wc3Game Attach(AttachOptions? options = null)
    {
        options ??= new AttachOptions();

        List<Process> candidates = new();
        string pidNote = "";
        if (options.Pid is int wantPid)
        {
            try { candidates.Add(Process.GetProcessById(wantPid)); }
            catch (ArgumentException)
            {
                pidNote = $"进程 {wantPid} 现在不存在（游戏已退出，或它换了 PID —— 每次启动游戏 PID 都会变）";
            }
            catch (Exception ex)
            {
                pidNote = $"取进程 {wantPid} 失败：{ex.GetType().Name}: {ex.Message}（若是权限问题，请以管理员身份运行本软件）";
            }
        }

        // 无论有没有 PID，都把“按名字找到的”一并作为候选：
        // 这样手动选过一次进程之后，游戏重开（PID 变了）也能靠进程名自动连上。
        foreach (var p in FindCandidates(options.ExtraProcessNames))
            if (!candidates.Any(c => c.Id == p.Id)) candidates.Add(p);

        if (candidates.Count == 0)
        {
            return new Wc3Game
            {
                State = AttachState.NoProcess,
                Message = (pidNote.Length > 0 ? pidNote + "；" : "") +
                          "没找到魔兽进程（按进程名 / 加载 game.dll / 窗口标题都没匹配到）—— 先启动游戏；" +
                          "启动后如果还是找不到，就点【以管理员身份重启】（或命令行加 --pid <进程号>）。"
            };
        }

        // 强制版本：直接照这张表用，不再读 game.dll 的版本号
        Wc3VersionInfo? forced = null;
        if (!string.IsNullOrWhiteSpace(options.ForceVersion))
        {
            if (Wc3Versions.TryGet(options.ForceVersion, out var fv)) forced = fv;
            else return new Wc3Game
            {
                State = AttachState.UnsupportedVersion,
                Message = $"指定的版本（{options.ForceVersion}）不在支持列表里：{string.Join(", ", Wc3Versions.SupportedVersions)}"
            };
        }

        string lastError = "";
        AttachState lastState = AttachState.NoProcess;
        int? accessDeniedPid = null;
        bool anyGameDll = false;        // 有没有任何一个候选真的加载了 game.dll
        Wc3Game? bestNotReady = null;   // 进程/模块/版本都对、但还没进地图的那个会话（保留它，别当“没找到”）
        foreach (var proc in candidates)
        {
            RemoteProcess? rp = null;
            try
            {
                rp = RemoteProcess.TryOpen(proc.Id, out string err, out int errCode);
                if (rp == null)
                {
                    lastError = $"PID {proc.Id} {SafeName(proc)}: {err}";
                    if (errCode == 5) accessDeniedPid ??= proc.Id;
                    continue;
                }

                var gameDll = rp.FindModule("game.dll");
                if (gameDll == null)
                {
                    lastError = $"PID {proc.Id} {SafeName(proc)}: 找不到 game.dll 模块（可能不是魔兽进程）";
                    rp.Dispose();
                    continue;
                }
                anyGameDll = true;

                Wc3VersionInfo ver;
                if (forced != null)
                {
                    ver = forced;
                }
                else
                {
                    // 一个模块可能有好几个“版本串”，而且可能和 War3Trainer 用的不是同一个字段：
                    // 它只用 FileVersion，我们以前优先 ProductVersion —— 平台改造过的 game.dll
                    // 这两个字段可能不一致（例如 ProductVersion="1.27.0"、FileVersion="1, 27, 0, 52240"），
                    // 于是它认、我们不认。现在两条路径 + 四种串都试一遍。
                    ver = null!;
                    string tried = "";
                    foreach (var pth in new[] { gameDll.Path, rp.MainModulePath })
                    {
                        if (string.IsNullOrWhiteSpace(pth)) continue;
                        foreach (var cand in ReadModuleVersions(pth))
                        {
                            if (Wc3Versions.TryGet(cand, out ver!)) break;
                            tried += (tried.Length > 0 ? " / " : "") + cand;
                        }
                        if (ver != null) break;
                    }

                    if (ver == null)
                    {
                        lastError = $"检测到游戏（PID {proc.Id}），但版本（{tried}）不在支持列表里。" +
                                    "可用 --force-version 1.27.0.52240 强制指定。";
                        rp.Dispose();
                        continue;
                    }
                }

                var g = new Wc3Game { Mem = rp, Version = ver, GameDll = gameDll };
                g.Refresh();
                if (g.State == AttachState.Ready) return g;

                // 进程+game.dll+版本都对，只是还没进地图 —— 这算“连上了但没进图”，
                // 不能当成“没找到游戏”（War3Trainer 在这种情况下就报成功）。
                // 保留这个会话（句柄不能漏），继续找下一个候选进程。
                lastError = g.Message;
                lastState = g.State;
                if (bestNotReady != null) bestNotReady.Dispose();
                bestNotReady = g;
            }
            catch (Exception ex)
            {
                lastError = "连接异常：" + ex.Message;
                rp?.Dispose();
            }
        }

        if (bestNotReady != null) return bestNotReady;

        // 有候选被 ERROR_ACCESS_DENIED 拒过：这条信息比"最后一个候选没有 game.dll"重要得多，
        // 必须优先报出来。否则界面会显示 notepad++/别的进程的名字（它只是恰好排在最后），
        // 而真正的问题（魔兽被权限挡住）一个字都看不到。
        if (accessDeniedPid is int deniedPid)
        {
            return new Wc3Game
            {
                State = AttachState.NoProcess,
                Message = $"找到魔兽（PID {deniedPid}）但权限不足（OpenProcess err=5）—— " +
                          "点【以管理员身份重启】（游戏由平台/服务以更高权限拉起时，普通权限连读都读不到）。",
                AccessDeniedPid = accessDeniedPid
            };
        }

        // 一个 game.dll 都没找到：说明候选只是"名字/标题像"，不是"魔兽被权限挡住"。
        // 这时候别把 lastError（"PID 123 找不到 game.dll 模块"）当错误抛给界面 ——
        // 那会让人以为程序坏了，实际只是游戏还没启动。红色横幅留给真正的权限问题。
        if (!anyGameDll && accessDeniedPid == null)
        {
            return new Wc3Game
            {
                State = AttachState.NoProcess,
                Message = (pidNote.Length > 0 ? pidNote + "；" : "") +
                          "游戏未运行（没找到加载 game.dll 的进程）—— 启动游戏后会自动连上；" +
                          "启动后仍找不到就点【以管理员身份重启】（游戏由平台/服务拉起时普通权限读不到）。"
            };
        }

        return new Wc3Game
        {
            State = lastError.Length > 0 ? lastState : AttachState.NoProcess,
            Message = lastError.Length > 0 ? lastError : "没有可用的魔兽进程。",
            AccessDeniedPid = accessDeniedPid
        };
    }

    /// <summary>
    /// 一个模块的“候选版本串”，从最可信到最兜底：
    /// FileVersion（War3Trainer 用的）→ ProductVersion → FileX.X.X.X 拼装 → ProductX.X.X.X 拼装。
    /// 故意**不用 File.Exists 先判**：模块路径可能超 260 字符或被特殊 DACL 挡住，
    /// 这时 File.Exists 返回 false 会让我们白白放弃一个本来读得到的版本信息。
    /// </summary>
    private static List<string> ReadModuleVersions(string? path)
    {
        var list = new List<string>();
        if (string.IsNullOrWhiteSpace(path)) return list;
        try
        {
            var fv = FileVersionInfo.GetVersionInfo(path!);
            void Add(string? s)
            {
                if (string.IsNullOrWhiteSpace(s)) return;
                s = s.Trim();
                if (s.Length > 0 && !list.Contains(s)) list.Add(s);
            }
            Add(fv.FileVersion);
            Add(fv.ProductVersion);
            if (fv.FileMajorPart > 0) Add($"{fv.FileMajorPart}.{fv.FileMinorPart}.{fv.FileBuildPart}.{fv.FilePrivatePart}");
            if (fv.ProductMajorPart > 0) Add($"{fv.ProductMajorPart}.{fv.ProductMinorPart}.{fv.ProductBuildPart}.{fv.ProductPrivatePart}");
        }
        catch { }
        return list;
    }

    [Obsolete("改用 ReadModuleVersions（多候选）")]
    private static string? ReadModuleVersion(string? path)
    {
        try
        {
            var fv = FileVersionInfo.GetVersionInfo(path!);
            return !string.IsNullOrWhiteSpace(fv.ProductVersion) ? fv.ProductVersion : fv.FileVersion;
        }
        catch { return null; }
    }

    /// <summary>
    /// 这个地址是不是落在某个已加载模块的**映像**里（.text/.rdata 那些）。
    /// 生命表、单位对象、状态对象都在**私有堆**上；实机出现过把 game.dll 的 .rdata 当成表、
    /// “凑巧”解析出 3 个假生命对象的情况（15:07 报告里的 0x799C2174），所以必须排除。
    /// </summary>
    public bool IsImageAddress(uint addr)
    {
        if (addr == 0) return false;
        var reg = Mem.RegionOf(addr);
        if (reg.HasValue && reg.Value.Type == Native.MEM_IMAGE) return true;
        // 再兜一层：显式按 game.dll 映像范围判
        return GameDllBase != 0 && GameDllImageSize != 0 &&
               addr >= GameDllBase && addr < GameDllBase + GameDllImageSize;
    }

    /// <summary>
    /// 给一个“候选表基址”打分：数前 entries 项里有多少个能解析成“像生命状态”的对象
    /// （对象 +0x78/+0x84 是像样的 当前HP/最大HP）。够 3 个就提前返回，省时间。
    /// </summary>
    public int ScoreTable(uint tableBase, int entries = 128)
    {
        if (tableBase == 0 || !Mem.IsReadable(tableBase, 64)) return 0;
        if (IsImageAddress(tableBase)) return 0;      // 表不可能在模块映像里
        int score = 0;
        for (int i = 0; i < entries; i++)
        {
            uint obj = Mem.U32((ulong)tableBase + (ulong)(i * 8 + 4));
            if (obj < 0x10000) continue;
            if (IsImageAddress(obj)) continue;         // 状态对象也不可能在映像里
            if (!Mem.IsReadable(obj, 0x90)) continue;
            var b = Mem.ReadBytes(obj, 0x90);
            if (b == null || b.Length < 0x88) continue;
            float cur = BitConverter.ToSingle(b, 0x78), max = BitConverter.ToSingle(b, 0x84);
            if (max > 0.05f && max < 5_000_000f && cur >= -1000f && cur <= max * 1.01f + 1f)
            {
                if (++score >= 3) return score;
            }
        }
        return score;
    }

    /// <summary>
    /// 在 ThisGame 里**自己找**生命表的偏移：逐个 4 字节候选当表基址去打分，取分最高的那个。
    /// 适用场景：平台改过的 game.dll 把表挪了位置 / 换图后旧偏移失效（实机 15:02 那次就是这样：
    /// ThisGame+0x0C 读到 0x34E90010 完全没映射，所有单位都被判“不像单位”）。
    /// </summary>
    /// <summary>
    /// 用**真实单位**验证一个候选表：读单位的生命索引（+0xA0），看表里那一项是不是像样的生命对象。
    /// 这比“数几项像 HP”强得多 —— 单位地址是选区链给的，几乎不会错。
    /// </summary>
    public int ScoreTableWithUnits(uint tableBase, IReadOnlyList<uint>? units)
    {
        if (units == null || units.Count == 0) return 0;
        if (tableBase == 0 || IsImageAddress(tableBase)) return 0;
        int hits = 0;
        foreach (var u in units.Take(12))
        {
            if (u == 0 || IsImageAddress(u)) continue;
            if (!Mem.IsReadable((ulong)u + 0xA0, 4)) continue;
            uint idx = Mem.U32((ulong)u + 0xA0);
            if (idx == 0 || idx > 0x0020_0000u) continue;
            uint obj = Mem.U32((ulong)tableBase + (ulong)(idx * 8 + 4));
            if (obj < 0x10000 || IsImageAddress(obj)) continue;
            if (!Mem.IsReadable(obj, 0x90)) continue;

            // **必须像生命对象**，不能只是“读得到”：实机出现过“随便一个候选表 + 一个真单位
            // 恰好能读出个可读指针”，校准就当成合格解了。HP 那一对浮点数几乎伪造不出来。
            var b = Mem.ReadBytes(obj, 0x90);
            if (b == null || b.Length < 0x88) continue;
            float cur = BitConverter.ToSingle(b, 0x78), max = BitConverter.ToSingle(b, 0x84);
            if (!PlausibleHpPair(cur, max)) continue;
            hits++;
        }
        return hits;
    }

    private static bool PlausibleHpPair(float cur, float max)
    {
        if (float.IsNaN(cur) || float.IsNaN(max) || float.IsInfinity(cur) || float.IsInfinity(max)) return false;
        if (!(max > 0.05f && max < 5_000_000f)) return false;
        if (!(cur > -10_000f && cur <= max * 1.01f + 1f)) return false;
        return true;
    }

    public bool RederiveTableOffset(IReadOnlyList<uint>? knownUnits = null)
    {
        foreach (var (name, root) in new[] { ("ThisGame", ThisGame), ("ctx", Ctx) })
        {
            if (root == 0) continue;
            uint bestOff = 0, bestBase = 0;
            int best = 0, bestUnitHits = 0, bestScore = 0;
            for (uint off = 0; off <= 0x400; off += 4)
            {
                uint p = Mem.U32(root + off);
                if (p < 0x10000) continue;

                int unitHits = ScoreTableWithUnits(p, knownUnits);   // 用真实单位验证（最硬）
                int s = ScoreTable(p);
                int total = unitHits * 10 + s;
                if (total > best) { best = total; bestOff = off; bestBase = p; bestUnitHits = unitHits; bestScore = s; }
                if (bestUnitHits >= 2) break;          // 两个真单位都命中，可以收工
            }
            // 验收门槛（吃过亏）：只有 1 个“命中”而表本身一项都不像生命对象，那是凑巧，不能认。
            bool good = bestUnitHits >= 2 || (bestUnitHits >= 1 && bestScore >= 1) || (bestUnitHits == 0 && bestScore >= 5);
            if (best <= 0 || !good) continue;

            TableOffset = bestOff;
            TableRootIsCtx = name == "ctx";
            GameMemory = bestBase;
            GameMemoryLastGood = bestBase;
            GameMemoryCapacity = Mem.U32(ThisGame + 0x1C);
            TableSource = $"{name}+0x{bestOff:X}（自校准）";
            Log.Write($"生命表偏移自校准：{name}+0x{bestOff:X} → 0x{bestBase:X8}" +
                      $"（真实单位命中 {bestUnitHits} 个，普通打分 {bestScore}）");
            return true;
        }
        return false;
    }

    /// <summary>带“已知真实单位”的刷新：表偏移不对时，用这些单位反推表基址。</summary>
    public void RefreshWithUnits(IReadOnlyList<uint>? knownUnits)
    {
        _knownUnits = knownUnits;
        Refresh();
    }

    private IReadOnlyList<uint>? _knownUnits;

    /// <summary>重新读取三个全局（地图载入/换图后数值会变）。</summary>
    public void Refresh()
    {
        // game.dll 映像范围（判断 CUnit+0x00 的虚表指针是否落在游戏模块里）。
        // 用模块的**映像**大小（Toolhelp modBaseSize / ModuleMemorySize），不是文件大小。
        if (GameDllImageSize == 0)
            GameDllImageSize = GameDll != null && GameDll.Size > 0 ? GameDll.Size : 0x0100_0000UL;

        // 注意：要区分“读失败”和“读到 0”。以前一律当成 0（= 还没进地图），
        // 万一是权限不足/进程刚退出，提示就会误导人（自测靶子时踩到过）。
        bool okCtx = Mem.ReadU32(GameDllBase + Version.UnitListRva, out uint ctx);
        bool okThis = Mem.ReadU32(GameDllBase + Version.ThisGameRva, out uint thisGame);
        Ctx = ctx;
        ThisGame = thisGame;

        // ThisGame+0x0C 在实机里**不稳定**：同一局里它会在一串“看着像指针、其实没映射”的值之间跳
        // （实测 0x4C550010 这种 —— 报告里 §6“读取失败/这块地址读不到区域信息”就是它）。
        // 一旦跳坏，所有单位的生命链全断 → 一个单位都认不出；而下一次它又好了。
        // 处理：① 值不可用时回退到“上一个确实能用的表基址”；② 只有可用时才更新缓存。
        // ThisGame+0x0C 在实机里“看起来不稳定”，其实大多不是它抖，而是**区域表快照过期**：
        // 引擎在进图/扩容时会把生命表搬到新分配的内存，而 IsReadable() 查的是 attach 时的
        // VirtualQueryEx 快照 —— 明明读得到却被判“未映射”，于是真表被丢掉、校准去挑垃圾地址。
        // RemoteProcess.IsReadable 现在会“刷新区域表 + 直接读 4 字节实测”，这里按它给的结论走。
        //
        // 顺序：**默认偏移优先**（ThisGame+0x0C 就是引擎自己在 RVA 0x374CD3 用的那条路），
        // 只有默认偏移确实读不出来时才用自校准出来的偏移。
        uint gm = 0;
        TableSource = "";
        uint defaultBase = ThisGame != 0 ? Mem.U32(ThisGame + 0x0C) : 0;
        if (defaultBase != 0 && Mem.IsReadable(defaultBase, 64))
        {
            gm = defaultBase;
            TableOffset = 0x0C;
            TableRootIsCtx = false;
            TableSource = "ThisGame+0x0C（引擎默认）";
        }
        else
        {
            uint root = TableRootIsCtx && Ctx != 0 ? Ctx : ThisGame;
            uint alt = root != 0 ? Mem.U32(root + TableOffset) : 0;
            if (alt != 0 && Mem.IsReadable(alt, 64))
            {
                gm = alt;
                TableSource = $"{(TableRootIsCtx ? "ctx" : "ThisGame")}+0x{TableOffset:X}（自校准）";
            }
        }

        bool gmOk = gm != 0;
        if (!gmOk && GameMemoryLastGood != 0 && Mem.IsReadable(GameMemoryLastGood, 64))
        {
            gm = GameMemoryLastGood;
            gmOk = true;
            TableSource = "上一次可用（缓存）";
        }
        GameMemory = gm;

        // 兜底：表读不出来、或者读出来完全不像生命表 → 自己在 ThisGame 里重新找偏移。
        // 注意**必须节流**：Refresh 每 50ms 调一次，如果每轮都打分（最多 128 项 × 2 次读）
        // 一秒钟能打出上万次 ReadProcessMemory，把 CPU 和游戏都拖慢。
        bool check = !gmOk
                     || gm != _lastScoredTable
                     || DateTime.UtcNow - _lastTableScore > TimeSpan.FromSeconds(3);
        if (check)
        {
            _lastTableScore = DateTime.UtcNow;
            _lastScoredTable = gm;
            int score = ScoreTable(GameMemory);
            TableScore = score;

            if (score == 0 && DateTime.UtcNow - _lastTableRederive > TimeSpan.FromSeconds(5))
            {
                _lastTableRederive = DateTime.UtcNow;
                RederiveTableOffset(_knownUnits);   // 自己找偏移（优先用真实单位反推）
                TableScore = ScoreTable(GameMemory);
            }
            if (TableScore > 0) GameMemoryLastGood = GameMemory;
        }
        // 游戏内存表的槽位上限。依据：真实 game.dll RVA 0x374CD3 的引擎自身代码
        //    mov eax, ds:[6FBE40A8]   ; ThisGame
        //    cmp ecx, [eax+0x1C]      ; 索引 >= 这个值就跳过
        //    mov eax, [eax+0x0C]      ; 表基址
        //    cmp dword ptr [eax+ecx*8], 0FFFFFFFEh   ; 8 字节一项
        // → 顺便说明“8 字节 stride / 指针在 +4 / 容量在 ThisGame+0x1C”都成立。
        GameMemoryCapacity = ThisGame != 0 ? Mem.U32(ThisGame + 0x1C) : 0;

        if (!okCtx || !okThis)
        {
            State = AttachState.NotInGame;
            Message = $"已连接 PID {Mem.Pid}，但读不到引擎全局（game.dll+0x{Version.UnitListRva:X} / +{Version.ThisGameRva:X}）——" +
                      "常见原因：游戏以管理员权限运行而本软件没有（请以管理员身份运行本软件），或进程刚要退出。";
            return;
        }

        if (Ctx == 0 || ThisGame == 0 || GameMemory == 0)
        {
            State = AttachState.NotInGame;
            Message = $"已连接 PID {Mem.Pid}（{Version.Version}），但游戏还没进地图" +
                      $"（ctx=0x{Ctx:X8} thisGame=0x{ThisGame:X8} gameMemory=0x{GameMemory:X8}）。";
            return;
        }

        PlayerCount = ReadPlayerObjects().Count(p => p != 0);
        State = AttachState.Ready;
        Message = $"已连接 PID {Mem.Pid}，game.dll 基址 0x{GameDllBase:X8}，版本 {Version.Version}";
    }

    /// <summary>
    /// 生命表在 ThisGame 里的偏移。默认 0x0C（磁盘版 game.dll 里看到的就是这个），
    /// 但平台改过的镜像可能不是 —— 所以允许在不匹配时自己找。见 RederiveTableOffset()。
    /// </summary>
    public uint TableOffset { get; private set; } = 0x0C;

    /// <summary>自校准后表是不是挂在 ctx 上（而不是 ThisGame）。</summary>
    public bool TableRootIsCtx { get; private set; }

    /// <summary>这张表是怎么定位出来的（诊断报告/日志用）。</summary>
    public string TableSource { get; private set; } = "";
    private DateTime _lastTableRederive = DateTime.MinValue;
    private DateTime _lastTableScore = DateTime.MinValue;
    private uint _lastScoredTable;

    /// <summary>最近一次给生命表打分的结果（表里前若干项能解析成生命对象的个数）。</summary>
    public int TableScore { get; private set; }

    /// <summary>上一次读到、且确实可用的生命表基址（ThisGame+0x0C 会抖，用它兜底）。</summary>
    public uint GameMemoryLastGood { get; private set; }

    /// <summary>game.dll 映像大小（用来判断 +0x00 的虚表指针是不是落在 game.dll 里）。</summary>
    public ulong GameDllImageSize { get; private set; }

    /// <summary>游戏内存表的容量（ThisGame+0x1C）；0 表示读不到，就不做上限校验。</summary>
    public uint GameMemoryCapacity { get; private set; }

    /// <summary>容量值是否可信（用来决定要不要卡索引上限）。</summary>
    public bool CapacityIsSane => GameMemoryCapacity >= 0x100 && GameMemoryCapacity <= 0x0040_0000;

    /// <summary>
    /// 单位“拥有者”槽位字段在 CUnit 内的固定偏移（0x58）。
    /// UnitScanner 发现后写回这里，让伤害事件页（UnitOwnerResolver）共用同一个结果，
    /// 避免一个地方修好、另一个地方还是 ?。
    /// </summary>
    public int OwnerOffset { get; set; } = (int)Wc3UnitOffset.Owner;

    public bool IsReady => State == AttachState.Ready;

    // ------------------------------------------------------------------
    // 全局结构读取
    // ------------------------------------------------------------------

    /// <summary>玩家对象数组：ctx + 0x58 + i*4（依据 选区内存定位2.md §1.1，War3Trainer 同级偏移）。</summary>
    public uint[] ReadPlayerObjects(int slots = 16)
    {
        var arr = new uint[slots];
        for (int i = 0; i < slots; i++)
        {
            uint p = Mem.U32(Ctx + 0x58u + (uint)(i * 4));
            if (p != 0 && Mem.IsReadable(p, 0x40)) arr[i] = p;
        }
        return arr;
    }

    /// <summary>本地玩家索引（ctx+0x28，uint16）。</summary>
    public ushort LocalPlayerIndex => Mem.ReadU16(Ctx + 0x28, out ushort v) ? v : (ushort)0xFFFF;

    /// <summary>
    /// 游戏内存表：[索引] → 对象指针。
    /// 依据 War3Trainer War3Common::ReadFromGameMemory IL： *(gameMemory + index*8 + 4)
    /// </summary>
    public uint GameMemoryLookup(uint index)
    {
        if (GameMemory == 0) return 0;
        ulong addr = (ulong)GameMemory + (ulong)index * 8UL + 4UL;
        return Mem.U32(addr);
    }

    /// <summary>读单位当前/最大生命；任一环节失败返回 false。</summary>
    public bool TryReadHp(uint unit, out float hp, out float maxHp)
    {
        hp = maxHp = 0f;
        if (!Mem.ReadU32((ulong)unit + Wc3UnitOffset.HpIndex, out uint idx) || idx == 0) return false;
        if (idx > 0x00FF_FFFFu) return false;
        uint state = GameMemoryLookup(idx);
        if (state == 0) return false;
        if (!Mem.ReadF32((ulong)state + Wc3UnitOffset.StateCur, out hp)) return false;
        if (!Mem.ReadF32((ulong)state + Wc3UnitOffset.StateMax, out maxHp)) return false;
        return true;
    }

    public bool TryReadHpIndex(uint unit, out uint idx)
    {
        idx = 0;
        return Mem.ReadU32((ulong)unit + Wc3UnitOffset.HpIndex, out idx) && idx != 0 && idx < 0x00FF_FFFFu;
    }

    public bool TryReadPosition(uint unit, out float x, out float y)
    {
        x = y = 0f;
        if (!Mem.ReadU32((ulong)unit + Wc3UnitOffset.PositionIndex, out uint idx) || idx == 0) return false;
        uint obj = GameMemoryLookup(idx);
        if (obj == 0) return false;
        if (!Mem.ReadF32((ulong)obj + Wc3UnitOffset.PosX, out x)) return false;
        if (!Mem.ReadF32((ulong)obj + Wc3UnitOffset.PosY, out y)) return false;
        return true;
    }

    public string ReadUnitTypeCode(uint unit) => Mem.ReadTypeCode((ulong)unit + Wc3UnitOffset.TypeCode);

    public void Dispose() => Mem?.Dispose();
}



