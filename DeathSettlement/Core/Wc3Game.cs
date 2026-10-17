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
    public uint GameMemory { get; private set; }   // *(ThisGame + 0x0C)
    public int PlayerCount { get; private set; }

    public AttachState State { get; private set; }
    public string Message { get; private set; } = "";
    public DateTime AttachedAt { get; } = DateTime.Now;

    private Wc3Game() { }

    // ------------------------------------------------------------------
    // 连接
    // ------------------------------------------------------------------
    private static readonly string[] ProcessNames = { "war3", "War3", "game.dll", "dzwar3", "Warcraft III", "Frozen Throne" };

    /// <summary>
    /// 找出正在运行的魔兽进程。
    /// 第一层按进程名找（和 War3Trainer 的 FrmMain::FindGame 同思路）；
    /// 一个都没找到时再来一层兜底：**看谁加载了 game.dll**。
    /// 为什么需要兜底：有些平台是用自己的宿主 exe 起的魔兽，进程名里根本没有 war3/warcraft，
    /// 这时按名字必然找不到（War3Trainer 这种情况也会失败）；但 game.dll 是藏不住的判据。
    /// 注意：宿主进程若是管理员权限，普通权限下连模块表都读不到，那就只能靠用户手动选进程。
    /// </summary>
    public static List<Process> FindCandidates(string? extraNames = null)
    {
        var names = new List<string>(ProcessNames);
        if (!string.IsNullOrWhiteSpace(extraNames))
            foreach (var n in extraNames.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries))
                names.Add(n.Trim());

        var result = new List<Process>();
        foreach (var p in Process.GetProcesses())
        {
            try
            {
                foreach (var n in names)
                {
                    if (string.Equals(p.ProcessName, n, StringComparison.OrdinalIgnoreCase))
                    {
                        result.Add(p);
                        break;
                    }
                }
            }
            catch { /* 进程可能已退出 */ }
        }

        if (result.Count == 0)
        {
            // 兜底扫描要遍历所有进程的模块表（几百个进程，挺贵），所以最多 15 秒做一次，
            // 中间复用上次的命中 PID —— 免得“没开游戏”时每 1.5 秒扫一遍全机器。
            if (DateTime.UtcNow - _lastModuleSweep > TimeSpan.FromSeconds(15))
            {
                _lastModuleSweep = DateTime.UtcNow;
                _sweepHits.Clear();
                foreach (var p in Process.GetProcesses())
                {
                    try
                    {
                        foreach (ProcessModule m in p.Modules)
                        {
                            if (string.Equals(m.ModuleName, "game.dll", StringComparison.OrdinalIgnoreCase))
                            {
                                _sweepHits.Add(p.Id);
                                break;
                            }
                        }
                    }
                    catch { /* 读不到模块表（权限不足/已退出）就跳过 */ }
                }
                if (_sweepHits.Count > 0)
                    Log.Write($"按进程名没找到魔兽，但按“加载了 game.dll”兜底找到了 {_sweepHits.Count} 个 PID：" +
                              string.Join(", ", _sweepHits));
            }

            foreach (var pid in _sweepHits)
            {
                try { result.Add(Process.GetProcessById(pid)); } catch { /* 已经退出了 */ }
            }
        }

        return result;
    }

    private static DateTime _lastModuleSweep = DateTime.MinValue;
    private static readonly List<int> _sweepHits = new();

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
                pidNote = $"取进程 {wantPid} 失败：{ex.GetType().Name}: {ex.Message}（若是权限问题，请【以管理员身份重启】）";
            }
        }

        // 无论有没有 PID，都把“按名字找到的”一并作为候选：
        // 这样手动选过一次进程之后，游戏重开（PID 变了）也能靠进程名自动连上。
        foreach (var p in FindCandidates(options.ExtraProcessNames))
            if (!candidates.Any(c => c.Id == p.Id)) candidates.Add(p);

        if (candidates.Count == 0)
        {
            string tried = string.Join(" / ", ProcessNames);
            if (!string.IsNullOrWhiteSpace(options.ExtraProcessNames)) tried += " / " + options.ExtraProcessNames;
            return new Wc3Game
            {
                State = AttachState.NoProcess,
                Message = (pidNote.Length > 0 ? pidNote + "；" : "") +
                          $"按进程名也没找到魔兽（找过：{tried}）—— 先启动游戏；" +
                          "启动后点【选择进程…】，列表里绿色那一行（加载了 game.dll 的）就是魔兽。"
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
        Wc3Game? bestNotReady = null;   // 进程/模块/版本都对、但还没进地图的那个会话（保留它，别当“没找到”）
        foreach (var proc in candidates)
        {
            RemoteProcess? rp = null;
            try
            {
                rp = RemoteProcess.TryOpen(proc.Id, out string err);
                if (rp == null) { lastError = $"PID {proc.Id} {proc.ProcessName}: {err}"; continue; }

                var gameDll = rp.FindModule("game.dll");
                if (gameDll == null)
                {
                    lastError = $"PID {proc.Id} {proc.ProcessName}: 找不到 game.dll 模块（可能不是魔兽进程）";
                    rp.Dispose();
                    continue;
                }

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

        return new Wc3Game
        {
            State = lastError.Length > 0 ? lastState : AttachState.NoProcess,
            Message = lastError.Length > 0 ? lastError : "没有可用的魔兽进程。"
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
        GameMemory = ThisGame != 0 ? Mem.U32(ThisGame + 0x0C) : 0;
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
                      "常见原因：游戏以管理员权限运行而本软件没有（点【以管理员身份重启】），或进程刚要退出。";
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

    /// <summary>game.dll 映像大小（用来判断 +0x00 的虚表指针是不是落在 game.dll 里）。</summary>
    public ulong GameDllImageSize { get; private set; }

    /// <summary>游戏内存表的容量（ThisGame+0x1C）；0 表示读不到，就不做上限校验。</summary>
    public uint GameMemoryCapacity { get; private set; }

    /// <summary>容量值是否可信（用来决定要不要卡索引上限）。</summary>
    public bool CapacityIsSane => GameMemoryCapacity >= 0x100 && GameMemoryCapacity <= 0x0040_0000;

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



