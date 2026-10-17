using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>
/// 实机诊断：把“连接 → 全局 → 句柄表 → 选区链 → 游戏内存表 → 深度扫描”的每一步结果都打出来。
/// 全程只读，不改游戏任何内存。
///
/// 两种用法：
///   1) 命令行：War3DeathSettlement.exe --probe [--deep]
///   2) 界面里点【生成诊断报告】按钮（已连接的游戏直接复用，不会重复挂载）
/// 报告写到 exe 同目录 logs\probe-*.txt。
/// </summary>
public static class Probe
{
    public static int Run(CliOptions opt)
    {
        bool deep = opt.Deep;
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

        Report(game, deep, W, opt);
        W("=== 诊断结束 ===");
        return Flush(sb);
    }

    /// <summary>对已经连接好的会话生成报告（界面复用此方法）。</summary>
    public static string ReportForGame(Wc3Game game, bool deep)
    {
        var sb = new StringBuilder();
        void W(string s = "") => sb.AppendLine(s);
        W("=== War3DeathSettlement 界面诊断 " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===");
        W("");
        Report(game, deep, W);
        W("=== 诊断结束 ===");
        string text = sb.ToString();
        string path = WriteReport(text);
        return path;
    }

    // ==================================================================
    private static void Report(Wc3Game game, bool deep, Action<string> W, CliOptions? opt = null)
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
            uint gm = game.GameMemory;
            var reg = game.Mem.RegionOf(gm);
            int slots = reg.HasValue ? (int)Math.Min(8192, (long)((reg.Value.End - gm) / 8)) : 0;
            var buf = slots > 0 ? game.Mem.ReadBytes(gm, slots * 8) : null;
            if (buf == null) W("  读取失败");
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
            }
        }
        W("");

        // ---- 深度扫描 ----
        W("---- 7. 全堆深度扫描（找 CUnit：4 字符类型码 + 生命链自洽） ----");
        if (!deep) W("  （未开启：加 --deep 或点界面按钮才会跑；跑一次约 1~3 秒）");
        else
        {
            var stats = scanner.Scan(forceDeep: true);
            // 新单位要“连续几轮都出现”才会被正式收下（稳定性过滤），所以单次扫描可能什么都看不到。
            // 这里多扫几轮，让过滤条件满足之后再出报告。
            for (int i = 0; i < 3 && stats.Known == 0; i++)
            {
                W($"  （第 {i + 2} 轮扫描：稳定性过滤需要连续几轮，稍等）");
                Thread.Sleep(150);
                stats = scanner.Scan(forceDeep: true);
            }
            W($"  用时 {stats.ElapsedMs} ms，扫描 {stats.DeepMb} MB，发现单位 {stats.Known} 个");
            W("  当前使用的字段偏移：生命索引 0x" + scanner.HpIndexOffset.ToString("X") +
              "，当前HP 0x" + scanner.StateCurOffset.ToString("X") +
              "，最大HP 0x" + scanner.StateMaxOffset.ToString("X") +
              "，拥有者 " + (scanner.OwnerOffset >= 0 ? "0x" + scanner.OwnerOffset.ToString("X") : "未发现"));
            if (scanner.CalibrationInfo.Length > 0) W("  " + scanner.CalibrationInfo);
            foreach (var n in stats.Notes) W("   · " + n);

            // 一个单位都没认出来 → 把“漏斗样本”的原始头部打出来，人工也能看出布局哪里不对
            if (stats.Known == 0 && stats.SigSamples.Count > 0)
            {
                W("  一个单位都没认下来。下面是几个“类型码像单位、但生命链没通过”的候选，看它们的头部字节：");
                foreach (var cand in stats.SigSamples)
                {
                    var hdr = game.Mem.ReadBytes(cand, 0x200);
                    if (hdr == null) { W($"    0x{cand:X8} 读不到"); continue; }
                    int t = (int)Wc3UnitOffset.TypeCode;
                    string tc = "" + (char)hdr[t] + (char)hdr[t + 1] + (char)hdr[t + 2] + (char)hdr[t + 3];
                    uint hpIdx = BitConverter.ToUInt32(hdr, (int)scanner.HpIndexOffset);
                    uint posIdx = BitConverter.ToUInt32(hdr, (int)scanner.PositionIndexOffset);
                    uint mpIdx = BitConverter.ToUInt32(hdr, (int)scanner.MpIndexOffset);
                    W($"    0x{cand:X8} 类型码='{tc}' 生命索引@0x{scanner.HpIndexOffset:X}={hpIdx} " +
                      $"魔法索引@0x{scanner.MpIndexOffset:X}={mpIdx} 坐标索引@0x{scanner.PositionIndexOffset:X}={posIdx}");
                    W("      0x00-0x40: " + BitConverter.ToString(hdr, 0, 0x40).Replace("-", " "));
                    W("      0x80-0xC8: " + BitConverter.ToString(hdr, 0x80, 0x48).Replace("-", " "));
                    W("      0x160-0x1A0: " + BitConverter.ToString(hdr, 0x160, 0x40).Replace("-", " "));

                    uint st1 = game.GameMemoryLookup(hpIdx);
                    W($"      → 表[{hpIdx}] = 0x{st1:X8}" +
                      (st1 != 0 && game.Mem.IsReadable(st1, 0x100)
                          ? "，对象 +0x78/+0x84 = " +
                            $"{game.Mem.F32((ulong)st1 + 0x78):0.###}/{game.Mem.F32((ulong)st1 + 0x84):0.###}"
                          : "（不可读）"));
                }
            }
            var list = scanner.Known.Values.OrderBy(u => u.TypeCode, StringComparer.Ordinal).ToList();
            W($"  单位清单（最多列 60 个，共 {list.Count}）：");
            foreach (var u in list.Take(60))
                W($"    0x{u.Addr:X8} 类型={u.TypeCode,-6} HP={u.Hp,8:0.#}/{u.HpMax,-8:0.#} " +
                  $"坐标=({u.X,7:0.#},{u.Y,7:0.#}) 拥有者={(u.OwnerSlot >= 0 ? "P" + (u.OwnerSlot + 1) : "?")} 来源={u.FoundBy}");
            W($"  自发现的拥有者字段偏移：{(scanner.OwnerOffset >= 0 ? "0x" + scanner.OwnerOffset.ToString("X") : "未发现")}");

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
    }

    // ==================================================================
    private static int Flush(StringBuilder sb)
    {
        string path = WriteReport(sb.ToString());
        try { Console.WriteLine("报告已写入: " + path); } catch { }
        Log.Write("诊断报告: " + path);
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


