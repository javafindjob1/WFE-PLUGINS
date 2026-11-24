using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>
/// 实机诊断：把“连接 → 全局 → 句柄表 → 选区链 → 游戏内存表 → 单位发现”的每一步结果都打出来。
/// 全程只读，不改游戏任何内存。
///
/// 两种用法：
///   1) 命令行：War3DeathSettlement.exe --probe
///   2) 界面里点【生成诊断报告】按钮（已连接的游戏直接复用，不会重复挂载）
/// 报告写到 exe 同目录 logs\probe-*.txt。
/// </summary>
public static class Probe
{
    public static int Run(CliOptions opt)
    {
        var sb = new StringBuilder();
        void W(string s = "")
        {
            sb.AppendLine(s);
            try { Console.WriteLine(s); } catch { }
        }

        W("=== War3DeathSettlement 实机诊断 " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===");
        W("说明：全部为只读内存访问（OpenProcess + ReadProcessMemory），不注入、不写内存。");
        if (opt.Pid is int pid) W($"目标：指定 PID {pid}");
        if (opt.ForceVersion != null) W($"强制版本：{opt.ForceVersion}");
        W("");

        W("---- 1. 候选进程 ----");
        var cands = Wc3Game.FindCandidates(opt.Name);
        if (cands.Count == 0) W("  （没有找到 war3 / game.dll / dzwar3 进程）");
        foreach (var p in cands)
        {
            string path;
            try { path = p.MainModule?.FileName ?? ""; } catch { path = "(无权限读取路径)"; }
            W($"  PID {p.Id,-6} {p.ProcessName,-16} {path}");
        }
        W("");

        // ---- 1.2 完整性级别（能不能注入，只看这个）----
        // 只读路径只需 VM_READ，跨级别也能读；注入要 VM_WRITE|CREATE_THREAD，低级别申请会 err=5。
        W("---- 1.2 完整性级别（注入能否成功） ----");
        {
            IntegrityLevel selfIl = Integrity.Self;
            // 先尝试启用 SeDebugPrivilege：它治 DACL/属主，治不了跨 IL —— 结果本身也是证据。
            string? sd = Privilege.EnableSeDebugTracked();
            W($"  SeDebugPrivilege：{(sd == null ? "已启用" : "不可用（" + sd + "）")}");
            W($"  本程序：{Integrity.Name(selfIl)}   （PID {Environment.ProcessId}）");
            if (cands.Count == 0) W("  （无候选进程）");
            foreach (var p in cands)
            {
                IntegrityLevel il = Integrity.OfProcess(p.Id, out int ilErr);
                string verdict;
                if (il == IntegrityLevel.Unknown)
                {
                    verdict = $"读不出（err={ilErr}）";
                    if (ilErr == 5 && Privilege.DebugState == "已启用")
                        verdict += "：SeDebug 已启用仍被拒 → 受保护进程 / 跨会话";
                }
                else
                {
                    verdict = Integrity.CanInject(il) ? "可注入" : "不可注入（需要以管理员身份重启）";
                }
                W($"  PID {p.Id,-6} {p.ProcessName,-16} {Integrity.Name(il),-18} {verdict}");
            }
        }
        W("");

        // ---- 1.5 全部进程（专治“War3Trainer 看得到、我们看不到”这种问题） ----
        W("---- 1.5 进程盘点（我们到底能不能看到魔兽） ----");
        {
            int total = 0, withGame = 0, unknownMods = 0, nameLike = 0;
            foreach (var p in System.Diagnostics.Process.GetProcesses())
            {
                total++;
                try
                {
                    string dll = "", ver = "";
                    bool unknown = false;
                    try
                    {
                        foreach (System.Diagnostics.ProcessModule m in p.Modules)
                        {
                            if (!string.Equals(m.ModuleName, "game.dll", StringComparison.OrdinalIgnoreCase)) continue;
                            dll = "0x" + m.BaseAddress.ToInt64().ToString("X8");
                            try
                            {
                                var fv = System.Diagnostics.FileVersionInfo.GetVersionInfo(m.FileName);
                                ver = (!string.IsNullOrWhiteSpace(fv.ProductVersion) ? fv.ProductVersion : fv.FileVersion) ?? "";
                            }
                            catch { }
                            break;
                        }
                    }
                    catch { if (p.Id > 4) { unknown = true; unknownMods++; } }

                    bool nameish = ProcessMatch.LooksLikeGame(p.ProcessName);
                    if (nameish) nameLike++;
                    if (dll.Length == 0 && !nameish && !unknown) continue;

                    if (dll.Length > 0) withGame++;
                    W($"  PID {p.Id,-6} {p.ProcessName,-24} game.dll={(dll.Length > 0 ? dll : (unknown ? "读不到(权限?)" : "没有")),-14}" +
                      $"版本={ver,-20}{(nameish ? " 名字像魔兽" : "")}");
                }
                catch { /* 进程已退出 */ }
            }
            W($"  合计 {total} 个进程：加载了 game.dll 的 {withGame} 个，名字像魔兽的 {nameLike} 个，模块列表读不到的 {unknownMods} 个");
            if (withGame == 0 && nameLike == 0)
                W("  ⇒ 此刻没有魔兽进程（或它叫了完全不相干的名字且我们没权限看它的模块）。" +
                  "War3Trainer 那种“检测到游戏(旧PID)”可能是它记住了上一次的结果 —— 它不会自动重新校验。");
        }
        W("");

        W("---- 2. 连接 ----");
        using var game = Wc3Game.Attach(opt.ToAttach());
        W("  状态: " + game.State);
        W("  消息: " + game.Message);
        if (!game.IsReady)
        {
            W("");
            W("（没连上/还没进地图：以上即为全部可用信息。若提示权限不足，请以管理员身份运行本软件。）");
            return Flush(sb);
        }

        Report(game, W, opt);
        W("=== 诊断结束 ===");
        return Flush(sb);
    }

    /// <summary>对已经连接好的会话生成报告（界面复用此方法）。</summary>
    public static string ReportForGame(Wc3Game game)
    {
        var sb = new StringBuilder();
        void W(string s = "") => sb.AppendLine(s);
        W("=== War3DeathSettlement 界面诊断 " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===");
        W("");
        Report(game, W);
        W("=== 诊断结束 ===");
        string text = sb.ToString();
        string path = WriteReport(text);
        return path;
    }

    // ==================================================================
    private static void Report(Wc3Game game, Action<string> W, CliOptions? opt = null)
    {
        W("  game.dll 基址: 0x" + ((uint)game.GameDllBase).ToString("X8") +
          $"  大小 {game.GameDll.Size / 1024}KB  路径 {game.GameDll.Path}");
        W("  版本: " + game.Version.Version);
        W("  ThisGameRva=0x" + game.Version.ThisGameRva.ToString("X8") +
          "  UnitListRva=0x" + game.Version.UnitListRva.ToString("X8"));
        W("");
        W("---- 3. 全局对象 ----");
        W($"  ctx        = 0x{game.Ctx:X8}");
        W($"  ThisGame   = 0x{game.ThisGame:X8}");
        W($"  GameMemory = 0x{game.GameMemory:X8}");
        W($"  生命表偏移：{(game.TableRootIsCtx ? "ctx" : "ThisGame")}+0x{game.TableOffset:X}" +
          (game.TableOffset == 0x0C ? "（默认值）" : "（**自校准过**）") +
          $"　打分（前若干项能解析成生命对象的个数，≥3 才算好）= {game.TableScore}");
        W($"  游戏内存表容量（ThisGame+0x1C，引擎自己也这么判）= {game.GameMemoryCapacity}" +
          (game.CapacityIsSane ? "（可信，会用它卡索引上限）" : "（不可信，不卡上限）"));
        W("  本地玩家索引 = " + game.LocalPlayerIndex);
        var players = game.ReadPlayerObjects();
        for (int i = 0; i < players.Length; i++)
            if (players[i] != 0) W($"  CPlayer[{i}] = 0x{players[i]:X8}");
        W("");

        var scanner = new UnitScanner(game)
        {
            EnableHandleTable = opt?.NoHandleTable != true,
            EnableSelection = opt?.NoSelection != true
        };

        // ---- 句柄表 ----
        W("---- 4. 句柄表候选（ctx+0xF4 句柄管理器） ----");
        foreach (var (name, table) in scanner.HandleTableCandidates())
        {
            if (table == 0) { W($"  {name,-18} = 0x00000000（空）"); continue; }
            bool readable = game.Mem.IsReadable(table, 12);
            var reg = game.Mem.RegionOf(table);
            W($"  {name,-18} = 0x{table:X8}  可读={readable}" +
              (reg.HasValue ? $"  区域 0x{reg.Value.Base:X8}+0x{reg.Value.Size:X} type=0x{reg.Value.Type:X} prot=0x{reg.Value.Protect:X}" : ""));
            if (!readable) continue;

            int slots = (int)Math.Min(4096, (long)((reg!.Value.End - table) / 12));
            var buf = game.Mem.ReadBytes(table, slots * 12);
            if (buf == null) { W("    读取失败"); continue; }
            int nonZero = 0, valid = 0, sample = 0;
            for (int i = 0; i < buf.Length / 12; i++)
            {
                uint obj = BitConverter.ToUInt32(buf, i * 12 + 4);
                if (obj == 0) continue;
                nonZero++;
                if (!scanner.TryReadUnit(obj, out var u, null)) continue;
                valid++;
                if (sample < 8)
                {
                    W($"    槽 {i,6} obj=0x{obj:X8} 类型={u.TypeCode} HP={u.Hp:0.#}/{u.HpMax:0.#}");
                    sample++;
                }
            }
            W($"    前 {buf.Length / 12} 槽：非空 {nonZero}，像单位 {valid}");
        }
        W("");

        // ---- 选区链 ----
        W("---- 5. 选区链（本仓库已实机验证过的路径，可作锚点） ----");
        foreach (uint player in players)
        {
            if (player == 0) continue;
            uint sel = game.Mem.U32((ulong)player + 0x34);
            if (sel == 0) continue;
            W($"  CPlayer 0x{player:X8} → sel 0x{sel:X8}");
            foreach (var (firstOff, countOff, tag) in new[] { (0x1F0u, 0x1F8u, "sel+0x1F0"), (0x08u, 0x10u, "sel+0x08") })
            {
                uint first = game.Mem.U32((ulong)sel + firstOff);
                uint count = game.Mem.U32((ulong)sel + countOff);
                W($"    {tag}: first=0x{first:X8} count={count}");
                uint node = first;
                for (uint i = 0; i < count && node != 0 && i < 32; i++)
                {
                    uint unit = game.Mem.U32((ulong)node + 8);
                    bool ok = scanner.TryReadUnit(unit, out var u, null);
                    W($"      节点 0x{node:X8} → 单位 0x{unit:X8} " +
                      (ok ? $"类型={u.TypeCode} HP={u.Hp:0.#}/{u.HpMax:0.#}" : "（不像单位）"));
                    node = game.Mem.U32((ulong)node);
                }
            }
        }
        W("");

        // ---- 游戏内存表 ----
        W("---- 6. 游戏内存表（ThisGame+0x0C；单位的生命就存在这里） ----");
        {
            var rs = game.Mem.RegionStats();
            W($"  区域表：抓取于 {rs.At:HH:mm:ss}，可读区域 {rs.Count} 个，共 {rs.Bytes / 1024.0 / 1024.0:0.#} MB；" +
              $"因“区域表过期”而补判可读 {game.Mem.StaleRegionHits} 次");
            W($"  当前用的表：0x{game.GameMemory:X8}（来源：{(game.TableSource.Length > 0 ? game.TableSource : "?")}）");
            W("  ThisGame+0x0C 采样（间隔 60ms × 5）：");
            int mapped = 0, rawOnly = 0;
            for (int k = 0; k < 5; k++)
            {
                uint v = game.Mem.U32((ulong)game.ThisGame + 0x0C);
                bool inMap = v != 0 && game.Mem.IsReadableInMap(v, 64);
                bool raw = !inMap && game.Mem.RawReadable(v, 64);
                if (inMap) mapped++;
                if (raw) rawOnly++;
                W($"    #{k} 0x{v:X8}  区域表里{(inMap ? "有" : "没有")}　直接读 4 字节 = {(inMap || raw ? "成功" : "失败")}" +
                  (raw ? "　⇒ **区域表过期**（这块是进图/扩容后才分配的）" : ""));
                if (k < 4) Thread.Sleep(60);
            }
            W($"  → 5 次里 {mapped} 次在区域表里，{rawOnly} 次只是区域表过期（数据其实读得到）");
            uint gm = game.GameMemory;
            var reg = game.Mem.RegionOf(gm);
            W($"  表基址 = 0x{gm:X8}" +
              (reg.HasValue
                  ? $"　所在区域 0x{reg.Value.Base:X8}-0x{reg.Value.End:X8}" +
                    $"（{(reg.Value.Type == Native.MEM_PRIVATE ? "私有" : reg.Value.Type == Native.MEM_MAPPED ? "映射" : "其它")}，" +
                    $"保护 0x{reg.Value.Protect:X}）"
                  : "　（这块地址读不到区域信息）"));

            int slots = reg.HasValue ? (int)Math.Min(8192, (long)((reg.Value.End - gm) / 8)) : 0;
            var buf = slots > 0 ? game.Mem.ReadBytes(gm, slots * 8) : null;
            if (buf == null)
            {
                // 一次读整段失败时，改成 4KB 一页地读，把能读的都读出来 —— 表可能只提交了一部分
                W("  整段读取失败，改用 4KB 分页重试…");
                var parts = new List<byte>();
                for (int off = 0; off < slots * 8 && parts.Count < 8192 * 8; off += 4096)
                {
                    var chunk = game.Mem.ReadBytes(gm + (ulong)off, Math.Min(4096, slots * 8 - off));
                    if (chunk == null || chunk.Length == 0) break;
                    parts.AddRange(chunk);
                }
                if (parts.Count > 0) { buf = parts.ToArray(); W($"  分页读到 {buf.Length} 字节"); }
            }

            if (buf == null || buf.Length < 8)
            {
                W("  读取失败：表基址指向的内容读不出来");
                W("  ⇒ 常见原因：此刻不在“地图里”（平台主菜单/载入中），这个字段还是个临时指针；");
                W("    或者这个平台构建里 +0x0C 不是表基址。请进图后再生成一次报告对比。");
            }
            else
            {
                int nz = 0, plausible = 0, sample = 0;
                for (int i = 0; i < buf.Length / 8; i++)
                {
                    uint obj = BitConverter.ToUInt32(buf, i * 8 + 4);
                    if (obj == 0) continue;
                    nz++;
                    if (!game.Mem.IsReadable(obj, 0x90)) continue;
                    var b = game.Mem.ReadBytes(obj, 0x90);
                    if (b == null) continue;
                    float cur = BitConverter.ToSingle(b, 0x78), max = BitConverter.ToSingle(b, 0x84);
                    if (max > 0.05f && max < 5_000_000f && cur >= -1000f && cur <= max * 1.01f + 1f)
                    {
                        plausible++;
                        if (sample < 8) { W($"    索引 {i,6} obj=0x{obj:X8} 当前={cur:0.#} 最大={max:0.#}"); sample++; }
                    }
                }
                W($"  前 {buf.Length / 8} 项：非空 {nz}，像‘生命状态’对象 {plausible}");
                if (plausible == 0)
                    W("  ⇒ 一项都不像生命对象：要么此刻不在图里，要么 +0x0C 不是表基址（进图后再对比一次即可确认）");
            }

            // ---- 6.1 候选表打分：拿“真单位”当证据 ----
            var anchors = new List<uint>();
            foreach (uint player in players)
            {
                if (player == 0) continue;
                uint sel = game.Mem.U32((ulong)player + 0x34);
                if (sel == 0) continue;
                foreach (var (firstOff, countOff) in new[] { (0x1F0u, 0x1F8u), (0x08u, 0x10u) })
                {
                    uint first = game.Mem.U32((ulong)sel + firstOff);
                    uint count = game.Mem.U32((ulong)sel + countOff);
                    uint node = first;
                    for (uint i = 0; i < count && node != 0 && i < 32; i++)
                    {
                        uint unit = game.Mem.U32((ulong)node + 8);
                        if (unit >= 0x10000 && !anchors.Contains(unit)) anchors.Add(unit);
                        node = game.Mem.U32((ulong)node);
                    }
                }
            }
            W($"  候选表打分（真单位锚点 {anchors.Count} 个：选区链；表打分 = 前 128 项里像生命对象的个数）：");
            var cands = new List<(string Name, uint Base)>();
            void AddCand(string name, uint b)
            {
                if (b < 0x10000 || cands.Any(c => c.Base == b)) return;
                cands.Add((name, b));
            }
            AddCand("ThisGame+0x0C（引擎默认）", game.Mem.U32((ulong)game.ThisGame + 0x0C));
            AddCand($"{(game.TableRootIsCtx ? "ctx" : "ThisGame")}+0x{game.TableOffset:X}（当前用的）", game.GameMemory);
            for (uint off = 0; off <= 0x40; off += 4)
                AddCand($"ThisGame+0x{off:X}", game.Mem.U32((ulong)game.ThisGame + off));
            for (uint off = 0; off <= 0x40; off += 4)
                AddCand($"ctx+0x{off:X}", game.Mem.U32((ulong)game.Ctx + off));

            foreach (var (name, b) in cands)
            {
                int hits = game.ScoreTableWithUnits(b, anchors);
                int score = game.ScoreTable(b);
                bool readable = game.Mem.IsReadable(b, 64);
                string mark = hits >= 1 && score >= 1 ? "  ← 像真表" : "";
                W($"    {name,-34} 0x{b:X8}  可读={(readable ? "是" : "否")}  单位命中 {hits}/{anchors.Count}  表打分 {score}{mark}");
            }

            // ---- 6.2 引擎自己怎么读这张表（顺便看平台有没有在内存里改代码） ----
            W("");
            W("---- 6.2 引擎自己的读表代码（确认偏移 / 有没有被平台在内存里改过） ----");
            ReportEngineCode(game, W);
        }
        W("");

        // ---- 伤害函数定位（侵入式钩子用；这里只读扫描，不注入）----
        W("---- 7. 引擎伤害函数定位（给侵入式钩子用） ----");
        try { W(DamageFuncFinder.Describe(game).TrimEnd()); }
        catch (Exception ex) { W("  定位失败：" + ex.Message); }
        W("");

        // ---- 单位发现（句柄表 + 选区链；钩子事件另作锚点）----
        W("---- 8. 单位发现（句柄表 + 选区链；钩子事件另作锚点） ----");
        var stats = scanner.Scan();
        // 新单位要“连续几轮都出现”才会被正式收下（稳定性过滤），所以单次扫描可能什么都看不到。
        // 这里多扫几轮，让过滤条件满足之后再出报告。
        for (int i = 0; i < 3 && stats.Known == 0; i++)
        {
            W($"  （第 {i + 2} 轮扫描：稳定性过滤需要连续几轮，稍等）");
            Thread.Sleep(150);
            stats = scanner.Scan();
        }
        W($"  用时 {stats.ElapsedMs} ms，发现单位 {stats.Known} 个（模式={stats.Mode}）");
        W("  当前使用的字段偏移：生命索引 0x" + scanner.HpIndexOffset.ToString("X") +
          "，当前HP 0x" + scanner.StateCurOffset.ToString("X") +
          "，最大HP 0x" + scanner.StateMaxOffset.ToString("X") +
          "，拥有者 " + (scanner.OwnerOffset >= 0 ? "0x" + scanner.OwnerOffset.ToString("X") : "未发现"));
        foreach (var n in stats.Notes) W("   · " + n);

        var list = scanner.Known.Values.OrderBy(u => u.TypeCode, StringComparer.Ordinal).ToList();
        W($"  单位清单（最多列 60 个，共 {list.Count}）：");
        foreach (var u in list.Take(60))
            W($"    0x{u.Addr:X8} 类型={u.TypeCode,-6} HP={u.Hp,8:0.#}/{u.HpMax,-8:0.#} " +
              $"坐标=({u.X,7:0.#},{u.Y,7:0.#}) 拥有者={UnitEvents.FormatPlayer(u.OwnerSlot)} 来源={u.FoundBy}");
        W($"  拥有者槽位字段偏移：0x{scanner.OwnerOffset:X}（CUnit+0x58 直读）");

        foreach (var u in list.Take(2))
        {
            var hdr = game.Mem.ReadBytes(u.Addr, 0x200);
            if (hdr == null) continue;
            W($"  0x{u.Addr:X8} 头部 0x00-0x40：");
            W("    " + BitConverter.ToString(hdr, 0, 0x40).Replace("-", " "));
            W("     0x90-0xE8：");
            W("    " + BitConverter.ToString(hdr, 0x90, 0x58).Replace("-", " "));
        }
    }

    // ==================================================================
    // 6.2 引擎自己的读表代码：确认 (容量偏移, 表偏移)，并检查平台有没有在内存里改代码
    // ==================================================================
    private static (uint Va, uint Size, uint Raw) TextSection(byte[] file)
    {
        try
        {
            int peo = BitConverter.ToInt32(file, 0x3C);
            int nsec = BitConverter.ToUInt16(file, peo + 6);
            int optSize = BitConverter.ToUInt16(file, peo + 20);
            int secOff = peo + 24 + optSize;
            for (int i = 0; i < nsec; i++)
            {
                string name = Encoding.ASCII.GetString(file, secOff + i * 40, 8).TrimEnd('\0');
                if (name != ".text") continue;
                uint vs = BitConverter.ToUInt32(file, secOff + i * 40 + 8);
                uint va = BitConverter.ToUInt32(file, secOff + i * 40 + 12);
                uint pr = BitConverter.ToUInt32(file, secOff + i * 40 + 20);
                return (va, vs, pr);
            }
        }
        catch { }
        return (0, 0, 0);
    }

    /// <summary>
    /// 从“引擎自己的代码”里读出 (容量偏移, 表偏移)：
    ///   A1 &lt;ThisGame&gt;         mov eax, ds:[ThisGame]
    ///   3B 48 xx            cmp ecx, [eax+xx]      ← 容量
    ///   7x xx               jae ...
    ///   8B 40 yy            mov eax, [eax+yy]      ← 表基址
    /// 顺便把内存里的 .text 和磁盘文件逐字节比一遍：平台若在内存里打补丁，这里会露出来。
    /// </summary>
    private static void ReportEngineCode(Wc3Game g, Action<string> W)
    {
        byte[]? file = null;
        try { file = File.ReadAllBytes(g.GameDll.Path); } catch (Exception ex) { W("  （读不到 game.dll 文件：" + ex.Message + "）"); }

        var (tva, tsize, traw) = file != null ? TextSection(file) : (0u, 0u, 0u);
        if (tsize == 0) { tva = 0x1000; tsize = 0x94CE9A; traw = tva + 0x300; }   // 1.27 常量兜底

        var liveText = new List<byte>(1 << 20);
        for (uint off = 0; off < tsize; off += 1 << 20)
        {
            int n = (int)Math.Min(1u << 20, tsize - off);
            var b = g.Mem.ReadBytes(g.GameDllBase + tva + off, n);
            if (b == null) break;
            liveText.AddRange(b);
            if (b.Length < n) break;
        }
        W($"  game.dll .text：内存里读到 {liveText.Count / 1024}KB（文件里 {tsize / 1024}KB）");

        // ---- 6.2.1 逐字节比对：平台有没有在内存里改代码 ----
        if (file != null && traw > 0 && liveText.Count > 0)
        {
            int n = (int)Math.Min((uint)liveText.Count, Math.Min(tsize, (uint)file.Length - traw));
            int diff = 0; var firsts = new List<int>();
            for (int i = 0; i < n; i++)
            {
                if (liveText[i] == file[traw + i]) continue;
                diff++;
                if (firsts.Count < 6) firsts.Add(i);
            }
            W($"  .text 比对：{n / 1024}KB 里有 {diff} 字节不同" +
              (diff == 0 ? "（内存 = 磁盘，平台没有在内存里改代码）"
                         : "（**不一样！** 前几处 RVA：" + string.Join(", ", firsts.Select(x => "0x" + (tva + x).ToString("X"))) + "）"));
        }

        // ---- 6.2.2 从指令里反推偏移 ----
        foreach (var (name, rootVa) in new[]
                 {
                     ("ThisGame", (uint)(g.GameDllBase + g.Version.ThisGameRva)),
                     ("ctx", (uint)(g.GameDllBase + g.Version.UnitListRva))
                 })
        {
            var stats = new Dictionary<(byte Cap, byte Tbl), int>();
            for (int i = 0; i + 16 < liveText.Count; i++)
            {
                if (liveText[i] != 0xA1) continue;
                if (BitConverter.ToUInt32(System.Runtime.InteropServices.CollectionsMarshal.AsSpan(liveText).Slice(i + 1, 4)) != rootVa) continue;
                // 往后 0..12 字节里找 3B 4x cap
                for (int k = 5; k <= 12 && i + k + 8 < liveText.Count; k++)
                {
                    if (liveText[i + k] != 0x3B) continue;
                    byte m = liveText[i + k + 1];
                    if (m < 0x48 || m > 0x4F) continue;
                    byte cap = liveText[i + k + 2];
                    int j = i + k + 3;
                    if (j + 4 >= liveText.Count) break;
                    if ((liveText[j] & 0xF0) != 0x70) break;             // jcc
                    if (liveText[j + 2] != 0x8B) break;                  // mov
                    byte m2 = liveText[j + 3];
                    if (m2 < 0x40 || m2 > 0x47) break;
                    byte tbl = liveText[j + 4];
                    stats.TryGetValue((cap, tbl), out int c);
                    stats[(cap, tbl)] = c + 1;
                    break;
                }
            }

            if (stats.Count == 0)
            {
                W($"  {name}：在 .text 里没找到“读表”的指令序列（可能这个构建的代码布局不同）");
                continue;
            }
            W($"  {name}：从指令里读出来的 (容量偏移, 表偏移) 候选：");
            foreach (var kv in stats.OrderByDescending(x => x.Value).Take(4))
            {
                uint capV = g.Mem.U32((ulong)(g.ThisGame + kv.Key.Cap));
                uint tblV = g.Mem.U32((ulong)(g.ThisGame + kv.Key.Tbl));
                W($"    (0x{kv.Key.Cap:X2}, 0x{kv.Key.Tbl:X2}) × {kv.Value,3} 处" +
                  $"　→ 容量={capV}　表=0x{tblV:X8}（可读={(g.Mem.IsReadable(tblV, 64) ? "是" : "否")}，表打分={g.ScoreTable(tblV)}）");
            }
        }

        // ---- 6.2.3 这一处固定代码的原始字节（跨版本比对用） ----
        const uint SiteRva = 0x374CD3;
        var site = g.Mem.ReadBytes(g.GameDllBase + SiteRva, 16);
        byte[]? siteDisk = null;
        if (file != null && traw > 0 && (long)traw + SiteRva - tva + 16 <= file.Length)
            siteDisk = file[(int)(traw + SiteRva - tva)..(int)(traw + SiteRva - tva + 16)];
        string Hex(byte[]? b) => b == null ? "(读不到)" : BitConverter.ToString(b).Replace("-", " ");
        W($"  RVA 0x{SiteRva:X} 内存：{Hex(site)}");
        W($"  RVA 0x{SiteRva:X} 磁盘：{Hex(siteDisk)}");
    }

    // ==================================================================
    private static int Flush(StringBuilder sb)
    {
        string path = WriteReport(sb.ToString());
        try { Console.WriteLine("报告已写入: " + path); } catch { }   // 控制台保留绝对路径，方便复制
        Log.Write("诊断报告: " + Log.Relative(path));
        return 0;
    }

    private static string WriteReport(string text)
    {
        try
        {
            string dir = Path.Combine(AppContext.BaseDirectory, "logs");
            Directory.CreateDirectory(dir);
            string path = Path.Combine(dir, $"probe-{DateTime.Now:yyyyMMdd-HHmmss}.txt");
            File.WriteAllText(path, text, new UTF8Encoding(true));
            return path;
        }
        catch (Exception ex)
        {
            Log.Warn("写诊断报告失败：" + ex.Message);
            return "(写入失败)";
        }
    }
}


