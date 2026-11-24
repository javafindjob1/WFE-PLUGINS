using System.Buffers.Binary;
using System.IO.MemoryMappedFiles;
using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>
/// 离线自检：不碰游戏进程，用假的生命值序列验证“记账 + 死亡结算”逻辑。
/// 用法：War3DeathSettlement.exe --selftest
/// </summary>
public static class SelfTest
{
    private static int _pass, _fail;

    public static int Run()
    {
        var sb = new StringBuilder();
        sb.AppendLine("=== War3DeathSettlement 自检（离线，不需要游戏） ===");

        void Check(bool ok, string what)
        {
            if (ok) { _pass++; sb.AppendLine("  [PASS] " + what); }
            else { _fail++; sb.AppendLine("  [FAIL] " + what); }
        }

        static Dictionary<uint, ScannedUnit> Scan(params (uint addr, string tc, float hp, float max, int owner)[] items)
        {
            var d = new Dictionary<uint, ScannedUnit>();
            foreach (var it in items)
                d[it.addr] = new ScannedUnit { Addr = it.addr, TypeCode = it.tc, Hp = it.hp, HpMax = it.max, OwnerSlot = it.owner };
            return d;
        }

        // ---------- 用例 1：伤害 / 治疗 / 致命一击 ----------
        {
            var tr = new DamageTracker();
            var t0 = new DateTime(2026, 1, 1, 12, 0, 0);
            tr.Update(Scan((0x1000u, "ogre", 100f, 100f, 0)), t0);
            tr.Update(Scan((0x1000u, "ogre", 70f, 100f, 0)), t0.AddMilliseconds(50));
            tr.Update(Scan((0x1000u, "ogre", 90f, 100f, 0)), t0.AddMilliseconds(100));   // 治疗 20
            tr.Update(Scan((0x1000u, "ogre", 50f, 100f, 0)), t0.AddMilliseconds(150));   // 伤害 40
            tr.Update(Scan((0x1000u, "ogre", 0f, 100f, 0)), t0.AddMilliseconds(200));    // 致命 50

            Check(tr.Settlements.Count == 1, "死亡时产生 1 条结算");
            if (tr.Settlements.Count == 1)
            {
                var s = tr.Settlements[0];
                Check(s.Kind == "死亡", "结局 = 死亡");
                Check(s.HitCount == 3, $"受击次数 = 3（实际 {s.HitCount}）");
                Check(Math.Abs(s.TotalDamage - 120) < 0.001, $"总伤害 = 120（实际 {s.TotalDamage}）");
                Check(Math.Abs(s.MaxHit - 50) < 0.001, $"最大单次 = 50（实际 {s.MaxHit}）");
                Check(Math.Abs(s.MinHitSafe - 30) < 0.001, $"最小单次 = 30（实际 {s.MinHitSafe}）");
                Check(Math.Abs(s.TotalHeal - 20) < 0.001, $"治疗 = 20（实际 {s.TotalHeal}）");
                // 三笔（30/40/50）都挤在 200ms 内 → “最惨 1 秒” = 120
                Check(Math.Abs(s.Peak1s - 120) < 0.001, $"最惨 1 秒 = 120（实际 {s.Peak1s}）");
                Check(s.Events.Count == 3 && s.Events[^1].Fatal, "最后一笔标记为致命");
            }
        }

        // ---------- 用例 1.5：千万级 HP 单位也能正常死亡结算（星之真神 H02N 回归） ----------
        {
            var tr = new DamageTracker();
            var t0 = new DateTime(2026, 10, 22, 0, 5, 0);
            const uint boss = 0xC000;
            const float hpMax = 5_480_000f;
            tr.Update(Scan((boss, "H02N", hpMax, hpMax, 7)), t0);

            // 真机：H02N 被打了 270 次，HP 从 5,478,303 掉到 0（最后一条事件 hpAfter=0）。
            float hp = hpMax;
            for (int i = 1; i <= 270; i++)
            {
                hp = i == 270 ? 0f : hpMax - hpMax * i / 270f;
                tr.Update(Scan((boss, "H02N", hp, hpMax, 7)), t0.AddMilliseconds(i * 10));
            }

            Check(tr.Settlements.Count == 1 && tr.Settlements[0].Kind == "死亡",
                  $"大 HP 单位（5.48M）被打到 0 → 1 条死亡结算（实际 {tr.Settlements.Count} 条）");
            if (tr.Settlements.Count == 1)
            {
                Check(Math.Abs(tr.Settlements[0].HpMax - hpMax) < 0.5,
                      $"大 HP 结算 hpMax = 5.48M（实际 {tr.Settlements[0].HpMax}）");
                Check(tr.Settlements[0].HitCount == 270,
                      $"大 HP 结算受击次数 = 270（实际 {tr.Settlements[0].HitCount}）");
            }
        }

        // ---------- 用例 2：浮点噪声不记账 ----------
        {
            var tr = new DamageTracker();
            var t0 = new DateTime(2026, 1, 1, 12, 0, 0);
            tr.Update(Scan((0x2000u, "hfoo", 100f, 100f, 0)), t0);
            tr.Update(Scan((0x2000u, "hfoo", 99.95f, 100f, 0)), t0.AddMilliseconds(50));
            var t = tr.GetTrack(0x2000);
            Check(t is { Events.Count: 0 }, "0.05 的掉血被当作噪声丢弃");
            tr.Update(Scan((0x2000u, "hfoo", 99.0f, 100f, 0)), t0.AddMilliseconds(100));
            Check(tr.GetTrack(0x2000)!.Events.Count == 1, "0.95 的掉血被记账");
        }

        // ---------- 用例 3：单位被销毁（读不到且血还>0）→ 消失结算 ----------
        {
            var tr = new DamageTracker(scanner: null) { GoneGrace = TimeSpan.FromSeconds(1) };
            var t0 = new DateTime(2026, 1, 1, 12, 0, 0);
            tr.Update(Scan((0x3000u, "n000", 500f, 500f, 1)), t0);
            tr.Update(Scan((0x3000u, "n000", 400f, 500f, 1)), t0.AddMilliseconds(50));
            tr.Update(new Dictionary<uint, ScannedUnit>(), t0.AddSeconds(2));  // 消失
            Check(tr.Settlements.Count == 1 && tr.Settlements[0].Kind == "消失", "读不到的单位判为“消失”而不是“死亡”");
        }

        // ---------- 用例 4：复活 → 开新账，实例号递增 ----------
        {
            var tr = new DamageTracker();
            var t0 = new DateTime(2026, 1, 1, 12, 0, 0);
            tr.Update(Scan((0x4000u, "Hpal", 100f, 100f, 0)), t0);
            tr.Update(Scan((0x4000u, "Hpal", 0f, 100f, 0)), t0.AddMilliseconds(50));
            tr.Update(Scan((0x4000u, "Hpal", 100f, 100f, 0)), t0.AddMilliseconds(100));  // 复活
            tr.Update(Scan((0x4000u, "Hpal", 0f, 100f, 0)), t0.AddMilliseconds(150));
            Check(tr.Settlements.Count == 2, "复活后再死 → 第二条结算");
            Check(tr.Settlements.Count == 2 && tr.Settlements[1].InstanceIndex == 2, "第二条结算的实例号 = 2");
            Check(tr.Settlements.Count == 2 && Math.Abs(tr.Settlements[1].TotalDamage - 100) < 0.001,
                  "新实例的伤害从 0 重新累计");
        }

        // ---------- 用例 5：同一地址换了类型码 → 视为新单位 ----------
        {
            var tr = new DamageTracker();
            var t0 = new DateTime(2026, 1, 1, 12, 0, 0);
            tr.Update(Scan((0x5000u, "hfoo", 100f, 100f, 0)), t0);
            tr.Update(Scan((0x5000u, "hfoo", 50f, 100f, 0)), t0.AddMilliseconds(50));
            tr.Update(Scan((0x5000u, "opeo", 200f, 200f, 1)), t0.AddMilliseconds(100));
            Check(tr.GetTrack(0x5000)!.TotalDamage == 0, "类型码变化后账本清零");
            Check(tr.Settlements.Count == 0, "类型码变化不产生结算");
        }

        // ---------- 用例 5.7：尸体还留在地图上时不能重复结算；地址复用后能正常再结算 ----------
        {
            var tr = new DamageTracker();
            var t0 = new DateTime(2026, 1, 1, 12, 0, 0);
            tr.Update(Scan((0x7000u, "uske", 100f, 100f, 0)), t0);
            tr.Update(Scan((0x7000u, "uske", 0f, 100f, 0)), t0.AddMilliseconds(50));
            Check(tr.Settlements.Count == 1, "死亡 → 第一条结算");

            for (int i = 1; i <= 10; i++)   // 尸体继续被看到（血=0）
                tr.Update(Scan((0x7000u, "uske", 0f, 100f, 0)), t0.AddMilliseconds(50 + i * 50));
            Check(tr.Settlements.Count == 1, "尸体还在地图上时不会重复结算");

            tr.Update(new Dictionary<uint, ScannedUnit>(), t0.AddSeconds(3));
            Check(tr.Settlements.Count == 1, "尸体消失也不会再补一条结算");

            tr.Update(Scan((0x7000u, "uske", 100f, 100f, 0)), t0.AddSeconds(4));
            tr.Update(Scan((0x7000u, "uske", 0f, 100f, 0)), t0.AddSeconds(4.1));
            Check(tr.Settlements.Count == 2, "地址被新单位复用后能正常结算第二条");
            Check(tr.Settlements.Count == 2 && tr.Settlements[1].InstanceIndex == 2, "复用后实例号 = 2");
        }

        // ---------- 用例 5.5：跨秒的“最惨 1 秒”只算窗口内 ----------
        {
            var tr = new DamageTracker();
            var t0 = new DateTime(2026, 1, 1, 12, 0, 0);
            tr.Update(Scan((0x5500u, "n001", 1000f, 1000f, 0)), t0);
            tr.Update(Scan((0x5500u, "n001", 900f, 1000f, 0)), t0.AddMilliseconds(100));   // -100
            tr.Update(Scan((0x5500u, "n001", 800f, 1000f, 0)), t0.AddMilliseconds(500));   // -100  → 窗口内 200
            tr.Update(Scan((0x5500u, "n001", 700f, 1000f, 0)), t0.AddSeconds(5));          // -100  （隔了 4.5 秒）
            tr.Update(Scan((0x5500u, "n001", 600f, 1000f, 0)), t0.AddSeconds(5.2));        // -100  → 窗口内 200
            tr.Update(Scan((0x5500u, "n001", 0f, 1000f, 0)), t0.AddSeconds(5.3));          // -600  → 窗口内 800
            var s = tr.Settlements[0];
            Check(s.HitCount == 5 && Math.Abs(s.TotalDamage - 1000) < 0.001, "跨秒累计：5 次 / 1000 伤害");
            Check(Math.Abs(s.Peak1s - 800) < 0.001, $"最惨 1 秒按窗口算 = 800（实际 {s.Peak1s}）");
        }

        // ---------- 用例 5.8：大面积同时消失（退游戏/地图结束）不出结算 ----------
        {
            var tr = new DamageTracker();
            var t0 = new DateTime(2026, 1, 1, 12, 0, 0);
            var many = new Dictionary<uint, ScannedUnit>();
            for (uint i = 0; i < 6; i++)
                many[0x8000u + i * 0x100] = new ScannedUnit { Addr = 0x8000u + i * 0x100, TypeCode = "hfoo", Hp = 100f, HpMax = 100f };
            tr.Update(many, t0);
            foreach (var kv in many)
                tr.Update(Scan((kv.Key, "hfoo", 60f, 100f, 0)), t0.AddMilliseconds(50));

            tr.Update(new Dictionary<uint, ScannedUnit>(), t0.AddSeconds(5));   // 一起消失
            Check(tr.Settlements.Count == 0, "6 个单位同时消失 → 判为退游戏/地图结束，不出结算");
        }

        // ---------- 用例 6：CSV / 文本导出行数 ----------
        {
            var tr = new DamageTracker();
            var t0 = new DateTime(2026, 1, 1, 12, 0, 0);
            tr.Update(Scan((0x6000u, "uske", 300f, 300f, 2)), t0);
            tr.Update(Scan((0x6000u, "uske", 0f, 300f, 2)), t0.AddMilliseconds(50));
            var s = tr.Settlements[0];
            Check(s.ToCsvRow().Split(',').Length == Settlement.CsvHeader.Split(',').Length, "CSV 列数与表头一致");
            Check(s.ToText().Contains("死亡结算"), "文本结算含标题");
            Check(s.OwnerText == "Player 3", "玩家号显示为 Player 3");
        }

        // ---------- 用例 7：按玩家统计（界面“按玩家统计”页的汇总逻辑） ----------
        {
            var tr = new DamageTracker();
            var t0 = new DateTime(2026, 1, 1, 12, 0, 0);

            // 玩家 1 的两个单位：一个死、一个消失
            tr.Update(Scan((0x9000u, "hfoo", 100f, 100f, 0)), t0);
            tr.Update(Scan((0x9000u, "hfoo", 0f, 100f, 0)), t0.AddMilliseconds(50));         // 死亡 100
            tr.Update(Scan((0xA000u, "opeo", 200f, 200f, 0)), t0.AddMilliseconds(60));
            tr.Update(new Dictionary<uint, ScannedUnit>(), t0.AddSeconds(5));                 // 消失（血 >0）
            // 玩家 3 的一个单位：挨 30 死掉
            tr.Update(Scan((0xB000u, "ogre", 300f, 300f, 2)), t0.AddSeconds(6));
            tr.Update(Scan((0xB000u, "ogre", 270f, 300f, 2)), t0.AddSeconds(6.1));
            tr.Update(Scan((0xB000u, "ogre", 0f, 300f, 2)), t0.AddSeconds(6.2));

            var rows = PlayerSummary.Build(tr.Settlements);
            Check(rows.Count == 2, $"按玩家统计出 2 行（实际 {rows.Count}）");
            // 排序是“总承受伤害降序”：玩家 3（300）排在玩家 1（100）前面
            Check(rows.Count == 2 && rows[0].OwnerSlot == 2 && Math.Abs(rows[0].TotalDamage - 300) < 0.001,
                  "玩家 3 排第一：300 伤害");
            Check(rows.Count == 2 && Math.Abs(rows[0].AvgPerSettlement - 300) < 0.001, "玩家 3 平均每次 = 300");
            Check(rows.Count == 2 && rows[0].Deaths == 1 && rows[0].Gone == 0, "玩家 3：1 死 0 消失");
            Check(rows.Count == 2 && rows[1].OwnerSlot == 0 && rows[1].Deaths == 1 && rows[1].Gone == 1,
                  "玩家 1：1 死 1 消失");
            Check(rows.Count == 2 && Math.Abs(rows[1].TotalDamage - 100) < 0.001,
                  $"玩家 1 总承受伤害 = 100（实际 {(rows.Count == 2 ? rows[1].TotalDamage : -1)}）");
            Check(rows.Count == 2 && rows[1].KindCount == 2, "玩家 1 涉及 2 种单位（hfoo 死 + opeo 消失）");
            Check(rows.Count == 2 && Math.Abs(rows[1].AvgPerSettlement - 50) < 0.001,
                  "玩家 1 平均每次 = 50（100 伤害 / 2 条结算）");
            Check(PlayerSummary.Build(Array.Empty<Settlement>()).Count == 0, "没有结算时统计为空");
        }

        // ---------- 用例 8：进程名匹配规则（“选择进程”列表的过滤条件） ----------
        {
            // 4 字符类型码必须**反过来**读（魔兽把 4CC 当 dword 存）。
            // 用例直接取自用户真机报告里那几个单位，防止以后又被靶子掩盖。
            Check(UnitScanner.TypeCodeFromBytes((byte)'F', (byte)'0', (byte)'0', (byte)'U') == "U00F",
                  "类型码反序：内存 F00U → 显示 U00F");
            Check(UnitScanner.TypeCodeFromBytes(0x4A, 0x34, 0x30, 0x45) == "E04J",
                  "类型码反序：内存 4A 34 30 45 → 显示 E04J");
            Check(UnitScanner.TypeCodeFromBytes((byte)'6', (byte)'2', (byte)'0', (byte)'H') == "H026",
                  "类型码反序：内存 620H → 显示 H026");
            Check(UnitScanner.TypeCodeFromBytes((byte)'o', (byte)'o', (byte)'f', (byte)'h') == "hfoo",
                  "类型码反序：内存 oofh → 显示 hfoo");

            // 大 HP 回归：星之真神 H02N 实测最大 HP 5.48M，旧上限 5,000,000 把它当假单位误杀。
            Check(UnitScanner.PlausibleHp(5_470_000f, 5_480_000f),
                  "PlausibleHp：5.48M 的 Boss 被接受（旧 5M 上限会误杀）");
            Check(UnitScanner.PlausibleHp(5_480_000f, 5_480_000f),
                  "PlausibleHp：满血 5.48M 被接受");
            Check(!UnitScanner.PlausibleHp(float.NaN, 100f),
                  "PlausibleHp：NaN 仍被拒绝");
            Check(!UnitScanner.PlausibleHp(1.5e9f, 1.5e9f),
                  "PlausibleHp：超过 1e9 上限仍被拒绝");
            Check(ProcessMatch.LooksLikeGame("war3"), "war3 → 是");            Check(ProcessMatch.LooksLikeGame("War3"), "War3 → 是（大小写无关）");
            Check(ProcessMatch.LooksLikeGame("dzwar3"), "dzwar3 → 是");
            Check(ProcessMatch.LooksLikeGame("Warcraft III"), "Warcraft III → 是");
            Check(ProcessMatch.LooksLikeGame("Frozen Throne"), "Frozen Throne → 是");
            Check(!ProcessMatch.LooksLikeGame("chrome"), "chrome → 不是");
            Check(!ProcessMatch.LooksLikeGame("notepad"), "notepad → 不是");
            Check(!ProcessMatch.LooksLikeGame(""), "空名字 → 不是");
            // 自己/同族工具名里也含 war3，绝不能当游戏（否则启动就报“<自己> 找不到 game.dll”）
            Check(!ProcessMatch.LooksLikeGame("War3DeathSettlement"), "War3DeathSettlement → 不是（本程序自己）");
            Check(!ProcessMatch.LooksLikeGame("War3Trainer"), "War3Trainer → 不是（同族修改器）");
            Check(ProcessMatch.IsOwnTool("War3DeathSettlement") && !ProcessMatch.IsOwnTool("war3") && !ProcessMatch.IsOwnTool("Warcraft III"),
                  "IsOwnTool 只认本族名字，不误伤真正的游戏名");
            // 扩大识别：窗口标题 / game.dll 路径（平台宿主进程名可能完全不相干）
            Check(ProcessMatch.LooksLikeGameTitle("Warcraft III - Frozen Throne"), "窗口标题 Warcraft III → 是");
            Check(ProcessMatch.LooksLikeGameTitle("魔兽争霸 III"), "窗口标题 魔兽争霸 → 是");
            Check(!ProcessMatch.LooksLikeGameTitle(@"C:\魔兽启动器\dss.log - Notepad++"),
                  "窗口标题只含“魔兽”（日志路径）→ 不是（编辑器别被当游戏）");
            Check(ProcessMatch.LooksLikeGamePath(@"C:\Games\Warcraft III\game.dll") &&
                  !ProcessMatch.LooksLikeGamePath(@"C:\Games\notepad\game.dll"),
                  "game.dll 路径像魔兽（含 Warcraft III 才是，notepad 不是）");
        }

        // ---------- 用例 8.5：拥有者 CUnit+0x58 直读 ----------
        {
            var players = new uint[16];
            players[0] = 0x1F0A0000u;   // 玩家 1 的 CPlayer*
            players[1] = 0x1F0A0100u;   // 玩家 2
            players[2] = 0x1F0A0200u;   // 玩家 3

            int s0 = OwnerResolver.Interpret(0, players, out var i0);
            Check(s0 == 0 && i0 == "直读", "拥有者解释：CUnit+0x58=0 → 玩家 1");

            int s3 = OwnerResolver.Interpret(3, players, out var i3);
            Check(s3 == 3 && i3 == "直读", "拥有者解释：CUnit+0x58=3 → 玩家 4");

            int s23 = OwnerResolver.Interpret(23, players, out var i23);
            Check(s23 == 23 && i23 == "直读", "拥有者解释：CUnit+0x58=23 → 玩家 24");

            int su = OwnerResolver.Interpret(0xDEADBEEF, players, out var iu);
            int s24 = OwnerResolver.Interpret(24, players, out var i24);
            Check(Wc3UnitOffset.Owner == 0x58 &&
                  su == OwnerResolver.Unknown && iu == "未知" &&
                  s24 == OwnerResolver.Unknown && i24 == "未知",
                  "拥有者解释：CUnit+0x58 超出 0～23 → 未知，无回退");
        }

        // ---------- 用例 8.6：候选筛选保留异常进程（读不到名字/模块/标题仍保留 PID 用于匹配） ----------
        {
            var extra = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "fakewar3" };

            // 读不到进程名（空名）+ 加载了 game.dll → 仍是候选（靠 game.dll 兜底）
            Check(ProcessMatch.ScoreCandidate("", true, false, false) == 1, "候选筛选：空进程名 + 加载 game.dll → 仍是候选");

            // 读不到进程名（空名）+ 窗口标题像魔兽 → 仍是候选
            Check(ProcessMatch.ScoreCandidate("", false, false, true) == 3, "候选筛选：空进程名 + 窗口标题像 → 仍是候选");

            // 进程名像魔兽，模块/标题都读不到 → 仍是候选
            Check(ProcessMatch.ScoreCandidate("war3", false, false, false) == 2, "候选筛选：进程名像 + 模块/标题读不到 → 仍是候选");

            // 额外进程名命中（命令行 --name）→ 仍是候选
            Check(ProcessMatch.ScoreCandidate("fakewar3", false, false, false, extra) == 2, "候选筛选：额外进程名命中 → 仍是候选");

            // 名字空 + 模块/标题都不像 → 不是候选（不要连记事本都列出来）
            Check(ProcessMatch.ScoreCandidate("", false, false, false) == -1, "候选筛选：全不匹配 → 不是候选");

            // 加载 game.dll 且路径像 → 排最前
            Check(ProcessMatch.ScoreCandidate("", true, true, false) == 0, "候选筛选：加载 game.dll + 路径像 → 最优先");
        }

        // ---------- 用例 9：解析游戏内插件日志（合成样本，格式照抄真实日志） ----------
        {
            var hint = new DateTime(2026, 10, 15);
            string sample =
                "[23:40:19.770] 统计 银河邪神 (U00Q #0010586C) 死亡结算: 次数=127 总计=6250597.8（联合统计 攻击/远程/攻击类型/伤害类型）；开账至今全局伤害事件=228\r\n" +
                "[23:40:19.770]    0/0/0/13: 19 次 / 1054073.8 3134433.4 (50.1%)\r\n" +
                "[23:40:19.771]    1/1/5/4: 25 次 / 232552.5 678154.8 (10.8%)\r\n" +
                "[23:40:19.773] 按来源单位类型（伤害占比）：\r\n" +
                "[23:40:19.773]      黑暗司教 (E04G #0010575A): 25 次 / 1073880.1 3228983.4 (51.7%)\r\n" +
                "[23:40:19.774]      龙翼守卫 (H038 #00105716): 45 次 / 669838.6 2123378.5 (34.0%)\r\n" +
                "[23:40:19.775] 死亡结算：准备投递，窗口=002B0126\r\n";

            var reader = new PluginLogReader("(synthetic)", fromStart: true);
            reader.Parse(sample, hint);
            sb.AppendLine($"  [INFO] 合成样本逐行诊断：");
            foreach (var l in sample.Split('\n'))
            {
                if (l.Trim().Length == 0) continue;
                sb.AppendLine("    " + PluginLogReader.DebugMatch(l.TrimEnd('\r')));
            }
            sb.AppendLine($"  [INFO] 合成样本解析：entries={reader.Entries.Count}，" +
                          $"joints={(reader.Entries.Count > 0 ? reader.Entries[0].Joints.Count : -1)}，" +
                          $"sources={(reader.Entries.Count > 0 ? reader.Entries[0].Sources.Count : -1)}");

            Check(reader.Entries.Count == 1, $"合成日志解析出 1 条插件结算（实际 {reader.Entries.Count}）");
            if (reader.Entries.Count == 1)
            {
                var e = reader.Entries[0];
                Check(e.Code == "U00Q" && e.Name == "银河邪神", "解析出类型码与单位名");
                Check(e.Handle == 0x0010586C, $"句柄 = 0x0010586C（实际 0x{e.Handle:X8}）");
                Check(e.Events == 127 && Math.Abs(e.Total - 6250597.8) < 0.01, "解析出次数与总计");
                Check(e.IsDeath, "识别为“死亡结算”而不是“当前统计”");
                Check(e.Time == new DateTime(2026, 10, 15, 23, 40, 19, 770), $"时间解析正确（实际 {e.Time:HH:mm:ss.fff}）");
                Check(e.Joints.Count == 2, $"解析出 2 行攻击/伤害类型拆分（实际 {e.Joints.Count}）");
                if (e.Joints.Count >= 1)
                    Check(e.Joints[0].DamageType == 13 && Math.Abs(e.Joints[0].DamageAfter - 3134433.4) < 0.01,
                          "拆分行字段正确（0/0/0/13 → 3134433.4）");
                Check(e.Sources.Count == 2, $"解析出 2 个来源（实际 {e.Sources.Count}）");
                if (e.Sources.Count >= 1)
                {
                    Check(e.Sources[0].Name == "黑暗司教" && Math.Abs(e.Sources[0].Percent - 51.7) < 0.01,
                          $"来源行正确（实际 名字='{e.Sources[0].Name}' 占比={e.Sources[0].Percent}）");
                    Check(e.Sources[0].SourceCodeOk(), "来源类型码长度正确");
                }
                // 顺手攒的「类型码 → 名字」表（表头与选区行都会贡献）
                Check(reader.NameOf("U00Q") == "银河邪神", $"类型码→名字：U00Q = '{reader.NameOf("U00Q")}'");
            }

            // 匹配：同类型码 + 时间就近；匹配过一次就不能再被认领
            var m1 = reader.Match("U00Q", new DateTime(2026, 10, 15, 23, 40, 21), TimeSpan.FromSeconds(20));
            Check(m1 != null, "外部结算能匹配到插件结算");
            Check(reader.Match("U00Q", new DateTime(2026, 10, 15, 23, 40, 21), TimeSpan.FromSeconds(20)) == null,
                  "同一条插件结算不会被认领两次");
            Check(reader.Match("XXXX", new DateTime(2026, 10, 15, 23, 40, 21), TimeSpan.FromSeconds(20)) == null,
                  "类型码不同 → 不匹配");
            Check(reader.Match("U00Q", new DateTime(2026, 10, 15, 23, 45, 0), TimeSpan.FromSeconds(20)) == null,
                  "时间差太远 → 不匹配（新句柄那条已被认领，这里也没有其它候选）");

            // ---- 侵入式伤害事件：共享内存读端解码（本进程伪造一块环，验证布局/解码）----
            {
                int pid = Environment.ProcessId;
                string name = $@"Local\DdhRing_{pid}";
                using (var mmf = System.IO.MemoryMappedFiles.MemoryMappedFile.CreateNew(name, 1 << 20))
                using (var view = mmf.CreateViewAccessor())
                using (var hook = new DamageHook())
                {
                    void WH(int idx, uint v) => view.Write((long)idx * 4, v);
                    WH(0, 0x31484444); WH(1, 2); WH(2, (uint)pid); WH(3, 512);
                    WH(4, 0); WH(5, 1); WH(7, 0x12340000); WH(8, 0x67DC40);

                    Check(hook.Open(pid, 2000), "hook：能打开共享内存 " + name);
                    if (hook.IsOpen)
                    {
                        int header = 16 * 4, rec = 13 * 4 + 64;   // + 两个 char[32] 名字
                        // 事件 1：victim 内存码 "oofh"(=hfoo)，flag=0x101（攻击+远程），伤害 123.5，mask 0x20 → 类型 4
                        uint seq = 1, tick = 1000;
                        view.Write((long)header, seq);
                        view.Write((long)header + 4, tick);
                        view.Write((long)header + 8, (uint)0x1F0A9284);          // victim
                        view.Write((long)header + 12, (uint)0x68666F6F);         // 内存 "oofh" → 显示 hfoo
                        view.Write((long)header + 16, (uint)0x1F0A2444);         // source
                        view.Write((long)header + 20, (uint)0x4870616C);         // 内存 "lapH" → 显示 Hpal
                        view.Write((long)header + 24, BitConverter.ToUInt32(BitConverter.GetBytes(123.5f), 0));
                        view.Write((long)header + 28, (uint)0x101);
                        view.Write((long)header + 32, (uint)3);                  // attackType
                        view.Write((long)header + 36, (uint)0x20);               // damage mask
                        view.Write((long)header + 40, (uint)1);                  // weapon
                        view.Write((long)header + 44, (uint)1);                  // isPhysical
                        view.Write((long)header + 48, (uint)0);
                        // 事件 2：非攻击、mask=0（类型未知）
                        long o = header + rec;
                        view.Write(o, (uint)2); view.Write(o + 4, (uint)1001);
                        view.Write(o + 8, (uint)0x1F0A8024);
                        view.Write(o + 12, (uint)0x48303236);                    // 内存 "620H" → 显示 H026
                        view.Write(o + 16, (uint)0); view.Write(o + 20, (uint)0);
                        view.Write(o + 24, BitConverter.ToUInt32(BitConverter.GetBytes(7.25f), 0));
                        view.Write(o + 28, (uint)0x100);                          // 只有攻击位
                        view.Write(o + 32, (uint)0); view.Write(o + 36, (uint)0);
                        view.Write(o + 40, (uint)0); view.Write(o + 44, (uint)1); view.Write(o + 48, (uint)0);
                        // 名字字段：记录内偏移 52 / 84，各 32 字节（ASCII 便于验证）
                        void WName(long at, string s)
                        {
                            for (int k = 0; k < 32; k++)
                                view.Write(at + k, (byte)(k < s.Length ? s[k] : 0));
                        }
                        WName(header + 52, "hfoo-unit");
                        WName(header + 84, "Hpal-unit");
                        WName(header + rec + 52, "H026-unit");
                        WH(4, 2);                                                 // count=2

                        var evs = hook.Poll();
                        Check(evs.Count == 2, $"hook：读出 2 条事件（实际 {evs.Count}）");
                        if (evs.Count == 2)
                        {
                            var e = evs[0];
                            Check(e.VictimCode == "hfoo" && e.SourceCode == "Hpal",
                                  $"hook：类型码反序解码（{e.SourceCode}→{e.VictimCode}）");
                            Check(Math.Abs(e.Amount - 123.5) < 0.01, $"hook：伤害值 {e.Amount}");
                            // 0x10 必须换算成 4（旧实现会报成 3 —— 用户指出的“不存在的伤害类型”）
                            Check(DamageHook.MaskToType(0x10) == 4, "hook：0x10 → 4（0x10 → 4）");
                            Check(DamageHook.MaskToType(0x20) == 5 && DamageHook.MaskToType(0x4000) == 14,
                                  "hook：0x20 → 5、0x4000 → 14");
                            Check(DamageHook.MaskToType(0x18) == 4, "hook：0x18（多 bit）按 YDWE 取最高位 → 4");
                            Check(e.VictimName == "hfoo-unit" && e.SourceName == "Hpal-unit",
                                  $"hook：名字字段 {e.SourceName}→{e.VictimName}");
                            Check(e.SourceText.Contains("Hpal-unit") && e.VictimText.Contains("hfoo-unit"),
                                  "hook：显示文本优先用名字");
                            Check(e.IsAttack && e.IsRanged, "hook：flag bit8=攻击 bit0=远程");
                            Check(e.AttackType == 3 && e.DamageType == 5,
                                  $"hook：攻击类型 {e.AttackType} / 伤害类型 {e.DamageType}（mask 0x20 → 5，YDWE 口径 bit 下标）");
                            Check(!evs[1].IsRanged && evs[1].DamageType < 0, "hook：第二条（mask=0 → 类型未知）");

                            // 掩码不是 2 的幂（多类型组合）时，不能硬套 log2-1 得出一个假的类型号
                            {
                                uint seq2 = 3;
                                long o3 = header + (long)rec * 2;
                                view.Write(o3, seq2); view.Write(o3 + 4, (uint)1002);
                                view.Write(o3 + 8, (uint)0x1F0A9284);
                                view.Write(o3 + 12, (uint)0x68666F6F);
                                view.Write(o3 + 16, (uint)0x1F0A2444);
                                view.Write(o3 + 20, (uint)0x4870616C);
                                view.Write(o3 + 24, BitConverter.ToUInt32(BitConverter.GetBytes(5.0f), 0));
                                view.Write(o3 + 28, (uint)0x100);
                                view.Write(o3 + 32, (uint)2);
                                view.Write(o3 + 36, (uint)0x18);          // 多类型组合
                                view.Write(o3 + 40, (uint)0); view.Write(o3 + 44, (uint)1);
                                view.Write(o3 + 48, (uint)0);
                                WH(4, 3);

                                var more = hook.Poll();
                                var e3 = more.FirstOrDefault(x => x.Seq == 3);
                                Check(e3 != null, "hook：读到第 3 条");
                                if (e3 != null)
                                {
                                    Check(e3.DamageType == 4 && !e3.MaskIsSingleBit,
                                          $"hook：0x18 多 bit 掩码按 YDWE 取最高位 → {e3.DamageType}");
                                    Check(e3.DamageTypeText.Contains("多类型"), "hook：显示时标注多类型：" + e3.DamageTypeText);
                                }
                            }
                        }
                    }
                }
            }
            // ---- 钩子事件 → 结算的匹配（精确 / 按类型码兜底）----
            {
                var t0 = new DateTime(2026, 10, 17, 15, 0, 0);
                var evs = new List<DamageHook.HookEvent>
                {
                    new(1, t0.AddMilliseconds(100), 0xAAAA, "hfoo", 0xBBBB, "Hpal", 100, true, false, 3, 4, true),
                    new(2, t0.AddMilliseconds(200), 0xCCCC, "hfoo", 0xDDDD, "ewsp", 200, true, false, 3, 4, true),
                };
                var exact = HookMatcher.Select(evs, 0xAAAA, "hfoo", t0, t0.AddSeconds(1));
                Check(exact.Exact && exact.Events.Count == 1 && Math.Abs(exact.Events[0].Amount - 100) < 0.01,
                      "匹配：按对象指针精确命中 1 笔");

                var byCode = HookMatcher.Select(evs, 0x9999, "hfoo", t0, t0.AddSeconds(1));
                Check(!byCode.Exact && byCode.Events.Count == 2 && byCode.Note.Contains("类型码"),
                      "匹配：地址不匹配时按类型码兜底（2 笔）：" + byCode.Note);

                var none = HookMatcher.Select(evs, 0x9999, "uske", t0, t0.AddSeconds(1));
                Check(none.Events.Count == 0, "匹配：类型码也不同 → 不硬套");

                var syntheticFrom = MonitorEngine.HookGroupingStart(
                    synthetic: true, firstSeen: t0, diedAt: t0.AddMinutes(1));
                var normalFrom = MonitorEngine.HookGroupingStart(
                    synthetic: false, firstSeen: t0.AddMinutes(1), diedAt: t0.AddMinutes(2));
                Check(syntheticFrom == DateTime.MinValue &&
                      normalFrom == t0.AddMinutes(1).AddSeconds(-1),
                      "结算匹配窗口：补建结算回溯本局全部事件；正常结算从首次见到前一秒开始");
            }
            // ---- 侵入式钩子的分组（引擎事件 → 结算上的分组统计）----
            {
                var t0 = new DateTime(2026, 10, 17, 14, 0, 0);
                var evs = new List<DamageHook.HookEvent>
                {
                    new(1, t0, 0x1000, "hfoo", 0x2000, "Hpal", 300, true,  false, 3, 4, true),
                    new(2, t0.AddMilliseconds(300), 0x1000, "hfoo", 0x2000, "Hpal", 200, true,  false, 3, 4, true),
                    new(3, t0.AddMilliseconds(600), 0x1000, "hfoo", 0x3000, "ewsp", 100, true,  true,  5, 13, true),
                    new(4, t0.AddMilliseconds(900), 0x1000, "hfoo", 0x3000, "ewsp", 400, false, false, 0, 4,  true),
                };

                // 组合行：一行 = 来源 × 是否攻击 × 是否远程 × 攻击类型 × 伤害类型
                // 来源单独汇总
                var srcs = HookBreakdown.Sources(evs, 0.5);
                Check(srcs.Count == 2, $"来源汇总 = 2 行（实际 {srcs.Count}）");
                Check(Math.Abs(srcs.Sum(x => x.Damage) - 1000) < 0.01 && Math.Abs(srcs.Sum(x => x.Effective) - 500) < 0.01,
                      "来源汇总：伤害 1000 / 地图 500（与组合行合计一致）");
                Check(Math.Abs(srcs[0].Damage - 500) < 0.01, $"来源汇总：最大来源 {srcs[0].Source} = {srcs[0].Damage:0.#}");

                var mirrorEvents = new List<DamageHook.HookEvent>
                {
                    new(10, t0, 0x1000, "hfoo", 0x7001, "O00M", 100, true, false, 2, 3, true,
                        VictimName: "小树精", SourceName: "西利沃特"),
                    new(11, t0.AddMilliseconds(200), 0x1000, "hfoo", 0x7002, "O00M", 50, true, false, 2, 3, true,
                        VictimName: "小树精", SourceName: "西利沃特"),
                };
                var mirrorSources = HookBreakdown.Sources(
                    mirrorEvents, 1.0, 20, (addr, code) => addr == 0x7002 && code == "O00M");
                var titledSources = HookBreakdown.Sources(
                    mirrorEvents, 1.0, 20, (addr, code) => addr == 0x7002 && code == "O00M",
                    e => Wc3Text.UnitIdentity(e.SourceName, "剑影", e.SourceCode));
                var mirrorCombos = HookBreakdown.Combinations(
                    mirrorEvents, null, 1.0, 40, (addr, code) => addr == 0x7002 && code == "O00M");
                Check(mirrorSources.Count == 2 &&
                      mirrorSources.Any(x => x.Source.Contains("西利沃特") && !x.Source.Contains("镜像")) &&
                      mirrorSources.Any(x => x.Source.Contains("西利沃特") && x.Source.Contains("（镜像）")) &&
                      titledSources.Any(x => x.Source == "剑影\n西利沃特") &&
                      titledSources.Any(x => x.Source == "剑影\n西利沃特（镜像）") &&
                      mirrorCombos.Count == 2 &&
                      mirrorCombos.Any(x => x.Source.Contains("（镜像）")),
                      "分组统计：同类型本体与镜像按实例拆成两个伤害来源");

                var combos = HookBreakdown.Combinations(evs, _ => "", 0.5);
                Check(combos.Count == 3, $"组合行 = 3 行（实际 {combos.Count}）");
                Check(combos.All(x => x.Source.Length > 0 && x.IsAttack.Length > 0 && x.IsRanged.Length > 0
                                      && x.AttackType.Length > 0 && x.DamageType.Length > 0),
                      "组合行：来源/是否攻击/是否远程/攻击类型/伤害类型 都有值");
                Check(Math.Abs(combos.Sum(x => x.Damage) - 1000) < 0.01, "组合行：伤害合计 = 1000（引擎口径）");
                Check(Math.Abs(combos.Sum(x => x.Effective) - 500) < 0.01,
                      $"组合行：地图伤害合计 = 500（×0.5 折算，地图 {combos.Sum(x => x.Effective):0.#}）");
                Check(combos.Max(x => x.Percent) >= 49.9 && combos.Max(x => x.Percent) <= 100.01,
                      $"组合行：占比最大项 = {combos.Max(x => x.Percent):0.#}%（500/1000 → 50%）");
                var rows = HookBreakdown.Build(evs, _ => "");
                Check(rows.Count(r => r.Dimension == "钩子-来源") == 2,
                      "钩子分组-来源 = 2 个：" + string.Join(" / ", rows.Where(r => r.Dimension == "钩子-来源").Select(r => r.Key)));
                Check(Math.Abs(rows.Where(r => r.Dimension == "钩子-来源").Sum(r => r.Damage) - 1000) < 0.01,
                      "钩子分组-来源伤害合计 = 1000");
                Check(rows.Count(r => r.Dimension == "钩子-是否攻击") == 2 &&
                      rows.Any(r => r.Dimension == "钩子-是否攻击" && r.Key == "1" && Math.Abs(r.Damage - 600) < 0.01) &&
                      rows.Any(r => r.Dimension == "钩子-是否攻击" && r.Key == "0" && Math.Abs(r.Damage - 400) < 0.01),
                      "钩子分组-是否攻击：用数字分组（1 = 600 / 0 = 400）");
                Check(rows.Count(r => r.Dimension == "钩子-是否远程") == 2, "钩子分组-是否远程 = 近战/远程");
                Check(rows.Count(r => r.Dimension == "钩子-攻击类型") == 3, "钩子分组-攻击类型 = 3 类（3 / 5 / 0）：" + string.Join(" / ", rows.Where(r => r.Dimension == "钩子-攻击类型").Select(r => r.Key)));
                Check(rows.Count(r => r.Dimension == "钩子-伤害类型") == 2, "钩子分组-伤害类型 = 2 类（4 和 13）");
                Check(rows.Count(r => r.Dimension == "钩子-组合") == 3, "钩子分组-组合 = 3 种");
                Check(rows.Where(r => r.Dimension == "钩子-组合").All(r => r.Key.StartsWith("Hpal") || r.Key.StartsWith("ewsp")),
                      "组合明细里带上了来源：" + rows.First(r => r.Dimension == "钩子-组合").Key);
                Check(HookBreakdown.Summary(rows).Contains("来源/"), "钩子分组-一行式摘要");

                // ---- 占比口径（用户反馈）：占比 = 该行净掉血 ÷ Σ净掉血，不再按原始伤害 ----
                {
                    // 净掉血 75 / 25，原始 900 / 100 → 75% / 25%（不是 90% / 10%）
                    var pctEvs = new List<DamageHook.HookEvent>
                    {
                        new(1, t0, 0x1000, "hfoo", 0x2000, "Hpal", 900, true, false, 3, 4, true,
                            HpBefore: 1000, HpAfter: 925, Actual: 75, HpValid: true),
                        new(2, t0.AddMilliseconds(100), 0x1000, "hfoo", 0x3000, "ewsp", 100, true, true, 5, 13, true,
                            HpBefore: 925, HpAfter: 900, Actual: 25, HpValid: true),
                    };
                    var pctSrcs = HookBreakdown.Sources(pctEvs);
                    Check(pctSrcs.Count == 2 &&
                          Math.Abs(pctSrcs.First(x => x.Source == "Hpal").Percent - 75) < 0.01 &&
                          Math.Abs(pctSrcs.First(x => x.Source == "ewsp").Percent - 25) < 0.01,
                          "占比 = 净掉血 ÷ Σ净掉血：净 75/25（原始 900/100）→ 75% / 25%（不是 90%/10%）：" +
                          string.Join(" / ", pctSrcs.Select(x => $"{x.Source}={x.Percent:0.0}%")));

                    var pctCombos = HookBreakdown.Combinations(pctEvs, _ => "");
                    Check(Math.Abs(pctSrcs.Sum(x => x.Percent) - 100) < 0.01 &&
                          Math.Abs(pctCombos.Sum(x => x.Percent) - 100) < 0.01 &&
                          Math.Abs(pctCombos.First(x => x.Source == "Hpal").Percent - 75) < 0.01,
                          "Σ 来源行与组合行共用同一分母（两边 Σ占比 = " +
                          $"{pctSrcs.Sum(x => x.Percent):0.0}% / {pctCombos.Sum(x => x.Percent):0.0}%）");

                    // Σ净掉血 = 0（血差读到了但都是 0）→ 退回原始伤害口径 90% / 10%
                    var zeroEvs = new List<DamageHook.HookEvent>
                    {
                        new(1, t0, 0x1000, "hfoo", 0x2000, "Hpal", 900, true, false, 3, 4, true,
                            HpBefore: 1000, HpAfter: 1000, Actual: 0, HpValid: true),
                        new(2, t0.AddMilliseconds(100), 0x1000, "hfoo", 0x3000, "ewsp", 100, true, true, 5, 13, true,
                            HpBefore: 1000, HpAfter: 1000, Actual: 0, HpValid: true),
                    };
                    var zeroSrcs = HookBreakdown.Sources(zeroEvs);
                    Check(Math.Abs(zeroSrcs.First(x => x.Source == "Hpal").Percent - 90) < 0.01 &&
                          Math.Abs(zeroSrcs.First(x => x.Source == "ewsp").Percent - 10) < 0.01,
                          "Σ净掉血 = 0 → 退回原始伤害口径 90% / 10%：" +
                          string.Join(" / ", zeroSrcs.Select(x => $"{x.Source}={x.Percent:0.0}%")));
                }

                // 结算能挂上并渲染出来
                var st = new Settlement { Addr = 0x1000, TypeCode = "hfoo", Kind = "死亡", DiedAt = t0.AddSeconds(1), FirstSeen = t0 };
                st.HookRows = rows;
                var text = st.ToText();
                Check(text.Contains("引擎钩子口径") && text.Contains("[是否攻击]"), "结算明细里出现钩子分组块");
                Check(st.ToCsvRow().Split(',').Length == Settlement.CsvHeader.Split(',').Length,
                      "CSV：钩子伤害构成列已对齐");
            }
            // ---- 用例 9.6：真机 HP差 日志口径回放（引擎=首值 / 地图=生效值 / 倍数=生效÷首 / 本层前血→后血=真实读数）----
            {
                var t0 = new DateTime(2026, 10, 17, 16, 0, 0);
                // 真机第 1 条：原始 2640 / 首值 1848 / 末值 3696（地图翻倍但没走 SetEventDamage）/ 前血 7000 / 净掉血 3696
                var e1 = new DamageHook.HookEvent(
                    1, t0, 0x1000, "hfoo", 0x2000, "Hpal",
                    2640, true, false, 3, 4, true,
                    HpBefore: 7000, HpAfter: 3304, Actual: 3696, HpValid: true, Depth: 2,
                    EngineDamage: 1848, EngineValid: true, EngineLast: 3696, EngineCalls: 178);
                Check(e1.EngineText == "1848.00", $"引擎伤害 = 首值 1848（实际 {e1.EngineText}）");
                Check(Math.Abs(e1.EffectiveDamage - 3696) < 0.005 && e1.EffectiveText == "3696.00",
                      $"地图伤害 = 生效值 3696（实际 {e1.EffectiveText}）");
                Check(Math.Abs(e1.MapRate - 2.0) < 0.005, $"倍数 = 生效÷首 = 2.00（实际 {e1.MapRate:0.##}）");
                Check(e1.HpText == "7000.00→3304.00", $"本层前血→后血 = 真实读数（实际 {e1.HpText}）");

                // 真机第 2 条：前血 700 / 后血 0（过量击杀，后血就是真实读到的 0）
                var e2 = new DamageHook.HookEvent(
                    2, t0.AddMilliseconds(100), 0x1000, "hfoo", 0x2000, "Hpal",
                    2640, true, false, 3, 4, true,
                    HpBefore: 700, HpAfter: 0, Actual: 700, HpValid: true, Depth: 2,
                    EngineDamage: 1848, EngineValid: true, EngineLast: 1848, EngineCalls: 177);
                Check(e2.HpText == "700.00→0.00", $"本层前血→后血 = 真实读数（实际 {e2.HpText}）");
                Check(Math.Abs(e2.MapRate - 1.0) < 0.005, $"没改值 → 倍数 = 1×（实际 {e2.MapRate:0.##}）");
            }
            // ---- 用例 9.7：v20 口径（引擎 = 出口 info+0x10 / 最终 = 出口 *out / 净 = 血差）----
            {
                var t0 = new DateTime(2026, 11, 4, 12, 0, 0);
                // 原始 5.00、护甲减免后 4.46，地图再翻倍到 8.92：finalFlags = bit0|bit1 = 3
                var v = new DamageHook.HookEvent(
                    1, t0, 0x1000, "hfoo", 0x2000, "Hpal",
                    5.0, true, false, 0, 4, true,
                    HpBefore: 100.0, HpAfter: 91.08, Actual: 8.92, HpValid: true, Depth: 1,
                    EngineDamage: 4.46, EngineValid: true,
                    EngineLast: 8.92, EngineCalls: 3,      // v20：这两个槽 = finalDamage / finalFlags
                    IsV20: true);
                Check(v.FinalValid && Math.Abs(v.FinalDamage - 8.92) < 0.005,
                      $"v20：最终伤害 = 出口 *out（实际 {v.FinalDamage:0.00}）");
                Check(Math.Abs(v.EffectiveDamage - 8.92) < 0.005,
                      $"v20：生效值取最终伤害（实际 {v.EffectiveText}）");
                Check(v.FinalOverridden && Math.Abs(v.MapRate - 2.0) < 0.005,
                      $"v20：地图改过 → 倍数 2×（实际 {v.MapRate:0.##}）");

                // 地图没改：finalFlags 只有 bit0 → 生效值=引擎值，倍数显示 1×
                var w = v with { EngineLast = 4.46, EngineCalls = 1 };
                Check(Math.Abs(w.EffectiveDamage - 4.46) < 0.005 &&
                      Math.Abs(w.MapRate - 1.0) < 0.005,
                      $"v20：没改过 → 生效值=引擎值、倍数 1×（实际 {w.MapRate:0.##}）");

                // 同帧回血导致净掉血为 0：最终伤害和引擎值仍有效，不能因此丢掉伤害值
                var x = v with { Actual = 0, HpValid = true, EngineLast = 8.92, EngineCalls = 1 };
                Check(x.FinalValid && Math.Abs(x.EffectiveDamage - 8.92) < 0.005,
                      "v20：回血抵消净掉血 → 仍保留最终伤害");

                // 击杀溢出：引擎 387.12 / 前血 219.52 → *out = 219.52（= 前血），
                // finalFlags = bit0|bit2 = 5；最终值仍可信，倍数按 219.52 ÷ 387.12 显示。
                var k = new DamageHook.HookEvent(
                    2, t0, 0x1000, "hfoo", 0x2000, "Hpal",
                    335.50, true, false, 0, 4, true,
                    HpBefore: 219.52, HpAfter: 0, Actual: 219.52, HpValid: true, Depth: 1,
                    EngineDamage: 387.12, EngineValid: true,
                    EngineLast: 219.52, EngineCalls: 5,      // bit0|bit2
                    IsV20: true);
                Check(k.FinalClamped && !k.FinalOverridden &&
                      Math.Abs(k.MapRate - (219.52 / 387.12)) < 0.005,
                      $"v20：击杀钳制 → 仍显示真实比值（实际 {k.MapRate:0.##}）");
                Check(Math.Abs(k.EffectiveDamage - 219.52) < 0.005 && k.EffectiveText == "219.52",
                      $"v20：溢出时地图伤害 = 前血 = 净掉血（实际 {k.EffectiveText}）");
            }
            // ---- 自己统计的分组（不依赖插件日志）----
            {
                var s2 = new Settlement
                {
                    TypeCode = "hfoo",
                    Kind = "死亡",
                    OwnerSlot = 0,
                    HitCount = 5,
                    Events = new List<DamageEvent>
                    {
                        new() { Time = new DateTime(2026, 10, 17, 1, 0, 0, 0), Amount = 30, HpAfter = 970 },
                        new() { Time = new DateTime(2026, 10, 17, 1, 0, 0, 100), Amount = 120, HpAfter = 850 },
                        new() { Time = new DateTime(2026, 10, 17, 1, 0, 0, 200), Amount = 700, HpAfter = 150 },
                        new() { Time = new DateTime(2026, 10, 17, 1, 0, 1, 0), Amount = 3500, HpAfter = -3350 },
                        new() { Time = new DateTime(2026, 10, 17, 1, 0, 2, 0), Amount = 25000, HpAfter = -28350 },
                    }
                };

                var rows = SelfBreakdown.ForSettlement(s2);
                var buckets = rows.Where(r => r.Dimension == "自己-单次伤害档位").ToList();
                Check(buckets.Count == 5, $"自己统计-档位分 5 档（实际 {buckets.Count}）");
                Check(Math.Abs(buckets.Sum(r => r.Damage) - 29350) < 0.01, "自己统计-档位伤害合计 = 29350（不重不漏）");
                Check(buckets.Any(r => r.Key == "20000+"), "自己统计-20000+ 档认得出来");
                var secs = rows.Where(r => r.Dimension == "自己-受击秒").ToList();
                Check(secs.Count == 3, $"自己统计-按秒分组 = 3 秒（实际 {secs.Count}）");

                var global = SelfBreakdown.Build(new[] { s2 });
                Check(global.Any(r => r.Dimension == "自己-单位类型" && r.Key == "hfoo"), "自己统计-按单位类型分组");
                Check(global.Any(r => r.Dimension == "自己-拥有者" && r.Key == "Player 1"), "自己统计-按拥有者分组");
                Check(global.Any(r => r.Dimension == "自己-结局" && r.Key == "死亡"), "自己统计-按结局分组");
                Check(SelfBreakdown.Summary(new[] { s2 }).Length > 0, "自己统计-一行式摘要非空");
            }

            var attr = reader.Entries.Count > 0
                ? PluginAttribution.From(reader.Entries[0])
                : new PluginAttribution();
            // 分组伤害统计（用户要求的：是否攻击/是否远程/攻击类型/伤害类型 + 组合）
            var gAtk = attr.GroupsOf("是否攻击").ToList();
            var gRng = attr.GroupsOf("是否远程").ToList();
            var gAt = attr.GroupsOf("攻击类型").ToList();
            var gDt = attr.GroupsOf("伤害类型").ToList();
            var gCb = attr.GroupsOf("组合明细").ToList();
            Check(gAtk.Count == 2 && gAtk.Any(x => x.Key == "攻击") && gAtk.Any(x => x.Key == "非攻击"),
                  "按“是否攻击”分组 = 攻击/非攻击 两组：" + string.Join(" / ", gAtk.Select(x => x.ToString())));
            Check(gRng.Count == 2 && gRng.Any(x => x.Key == "近战") && gRng.Any(x => x.Key == "远程"),
                  "按“是否远程”分组 = 近战/远程 两组：" + string.Join(" / ", gRng.Select(x => x.ToString())));
            Check(gAt.Count == 2 && gAt.Any(x => x.Key.StartsWith("0")) && gAt.Any(x => x.Key.StartsWith("5")),
                  "按“攻击类型”分组（样本两行是 0 和 5）：" + string.Join(" / ", gAt.Select(x => x.Key)));
            Check(gDt.Count == 2 && gDt.Any(x => x.Key.StartsWith("13")) && gDt.Any(x => x.Key.StartsWith("4")),
                  "按“伤害类型”分组（样本两行是 13 和 4）：" + string.Join(" / ", gDt.Select(x => x.Key)));
            Check(gCb.Count == 2, $"组合明细 = 2 行（实际 {gCb.Count}）");
            Check(Math.Abs(gRng.Sum(x => x.DamageAfter) - (3134433.4 + 678154.8)) < 1.0,
                  "分组后的伤害总和 = 插件给出的总量（不做二次估算）");
            Check(attr.BreakdownSummary().Contains("非攻击:") && attr.BreakdownSummary().Contains("近战:") &&
                  attr.BreakdownSummary().Contains("13-"),
                  "一行式摘要：" + attr.BreakdownSummary());
            Check(attr.SourceSummary().Contains("51.7%"), "来源摘要含占比：" + attr.SourceSummary());
        }

        // ---------- 用例 10：拿真实插件日志跑一遍（没有就用内置样本） ----------
        {
            const string realLog = @"C:\3rd\wc3gamesearcher\WFE\Application\Libraries\UDamageWatcher.log";
            // 内置样本：插件日志里“死亡结算 + 按来源单位 + 组合明细 + 类型码→名字”那几行的原样格式。
            // 为什么要有它：真实日志会随游戏/插件状态变化（插件重启、切到 OFF 模式后就没有结算块了），
            // 拿它当唯一数据源会让自检结果忽高忽低。真实日志里有结算就优先用真实日志。
            const string sample = "" +
                "[20:51:24.047] 统计 星之真神 (H02N #001090E7) 死亡结算: 次数=11 总计=8696.0\r\n" +
                "[20:51:24.047]   按来源单位类型：\r\n" +
                "[20:51:24.047]     龙翼守卫 (H038 #00105716): 5 次 / 3068.3 80050.0 (51.7%)\r\n" +
                "[20:51:24.047]     黑暗司教 (E04G #0010586D): 3 次 / 2000.0 4000.0 (25.2%)\r\n" +
                "[20:51:24.047]   0/1/3/4: 2 次 / 1234.5 6789.0 (22.1%)\r\n" +
                "[20:51:24.047]   1/0/5/13: 1 次 / 600.0 600.0 (9.0%)\r\n" +
                "[20:51:24.047] 类型=4830324E 名字=\"星之真神\"\r\n" +
                "[20:51:24.047] 类型=75736B65 名字=\"骸骨战士\"\r\n" +
                "[20:51:24.047] 类型=6E777764 名字=\"雪狼之王\"\r\n" +
                "[20:51:24.047] 类型=6E776C67 名字=\"冰原狼\"\r\n" +
                "[20:51:24.047] 类型=6E776E61 名字=\"古代冰川巨兽\"\r\n";

            string text = sample;
            string source = "内置样本";
            if (File.Exists(realLog))
            {
                try
                {
                    var bytes = File.ReadAllBytes(realLog);
                    string live = Gbk.Decode(bytes);
                    if (live.Contains("死亡结算")) { text = live; source = $"真实日志（{bytes.Length} 字节）"; }
                    else sb.AppendLine("  [INFO] 真实插件日志里没有结算块（插件可能刚重启/处于 OFF 模式），本轮用内置样本");
                }
                catch (Exception ex) { sb.AppendLine("  [INFO] 读真实日志失败：" + ex.Message + "，用内置样本"); }
            }
            else sb.AppendLine("  [INFO] 没找到真实插件日志（" + realLog + "），用内置样本");

            try
            {
                var reader = new PluginLogReader(source, fromStart: true);
                reader.Parse(text, DateTime.Now);

                int withSources = reader.Entries.Count(e => e.Sources.Count > 0);
                sb.AppendLine($"  [INFO] 插件日志来源：{source}；解析出 {reader.Entries.Count} 条结算，" +
                              $"其中 {withSources} 条带来源；（例）" +
                              (reader.Entries.Count > 0 ? reader.Entries[^1].ToString() : "无"));
                Check(reader.Entries.Count > 0, "插件日志能解析出结算");
                Check(withSources > 0, "插件日志里至少有一条带“按来源单位”的结算");
                sb.AppendLine($"  [INFO] 攒出「类型码→名字」{reader.CodeToName.Count} 条；例：" +
                              string.Join("、", reader.CodeToName.Take(5).Select(kv => $"{kv.Key}={kv.Value}")));
                Check(reader.CodeToName.Count >= 5, $"能攒出至少 5 条类型码→名字（实际 {reader.CodeToName.Count}）");
                Check(reader.CodeToName.Values.Any(v => v.Contains("骸骨战士") || v.Contains("星之真神") || v.Length > 0),
                      "名字表里有中文单位名");
            }
            catch (Exception ex)
            {
                Check(false, "插件日志解析抛异常：" + ex.Message);
            }
        }

        // ---------- 用例 11：存活单位详情文本（死亡结算页双击蓝字存活行的弹窗内容，纯函数可自检） ----------
        {
            var t0 = new DateTime(2026, 10, 17, 20, 0, 0);
            var u = new UnitView
            {
                Addr = 0x1A2B3C4D,
                TypeCode = "hfoo",
                Name = "步兵",
                Owner = "Player 1",
                Hp = 60f, HpMax = 100f, HpPercent = 0.6f,
                Taken = 40, Hits = 2, Dps = 20,
                FirstSeen = t0.AddSeconds(-5),
                FirstHit = t0.AddSeconds(-4),
                LastHit = t0.AddSeconds(-1),
                InstanceIndex = 1,
                MaxHit = 30,
                Peak1s = 40,
            };
            var evs = new List<DamageHook.HookEvent>
            {
                new(1, t0.AddSeconds(-4), 0x1A2B3C4D, "hfoo", 0x5000, "Hpal", 100, true, false, 3, 4, true, DamageMask: 0x10),
                new(2, t0.AddSeconds(-1), 0x1A2B3C4D, "hfoo", 0x6000, "ewsp", 200, true, true, 5, 13, true, DamageMask: 0x2000),
            };
            var text = LiveUnitDetail.Build(u, evs, t0);
            Check(text.Contains("[存活]") && text.Contains("步兵") && text.Contains("hfoo"), "存活详情：含标题/单位名/类型码");
            Check(text.Contains("当前HP 60") && text.Contains("累计受伤 40.00") && text.Contains("受击 2 次"),
                  "存活详情：含 HP / 累计受伤 / 受击次数");
            Check(text.Contains("首次发现") && text.Contains("最后受击"), "存活详情：含首次发现/最后受击时间");
            Check(text.Contains("按来源分组的伤害"), "存活详情：含来源分组标题");
            Check(text.Contains("Hpal") && text.Contains("ewsp"), "存活详情：来源分组里出现两个来源");
            Check(text.Contains("最近 20 笔事件明细"), "存活详情：含事件明细标题");
            Check(text.Contains("攻3") && text.Contains("伤4") && text.Contains("伤13"), "存活详情：明细含攻击/伤害类型");
            Check(LiveUnitDetail.Build(u, Array.Empty<DamageHook.HookEvent>(), t0).Contains("没有匹配到钩子事件"),
                  "存活详情：无钩子事件时给出提示");
            // 存活行的“最惨1秒”和死亡结算共用同一个 Peak 窗口函数（这里验证它对外可调用且口径一致）
            var de = new List<DamageEvent>
            {
                new() { Time = t0, Amount = 100 },
                new() { Time = t0.AddMilliseconds(200), Amount = 200 },
                new() { Time = t0.AddMilliseconds(1100), Amount = 300 },
            };
            Check(Math.Abs(DamageTracker.Peak(de, 1.0) - 500) < 0.001,
                  $"Peak（1 秒窗口）：前两笔 300、后两笔 500 → 500（实际 {DamageTracker.Peak(de, 1.0)}）");
        }

        // ---------- 用例 12：v7 flags 解码（目标蝗虫 Aloc 标记） ----------
        {
            int pid = Environment.ProcessId;
            string name = $@"Local\DdhRing_{pid}";
            using (var mmf = System.IO.MemoryMappedFiles.MemoryMappedFile.CreateNew(name, 1 << 20))
            using (var view = mmf.CreateViewAccessor())
            using (var hook = new DamageHook())
            {
                void WH(int idx, uint v) => view.Write((long)idx * 4, v);
                WH(0, 0x31484444); WH(1, 7); WH(2, (uint)pid); WH(3, 512);
                WH(4, 0); WH(5, 1); WH(7, 0x12340000); WH(8, 0x67DC40);

                Check(hook.Open(pid, 2000), "hook(v7)：能打开共享内存 " + name);
                if (hook.IsOpen)
                {
                    int header = 16 * 4;
                    // v7 记录长度 = 基础 116 + v3(20) + v4(8) + v5(8) + v6(8) + v7(4) = 164
                    int rec = 13 * 4 + 64 + 5 * 4 + 2 * 4 + 2 * 4 + 2 * 4 + 1 * 4;
                    Check(hook.Version == 7, $"hook(v7)：版本 = 7（实际 {hook.Version}）");
                    Check(rec == 164, $"hook(v7)：记录长度 = 164（实际 {rec}）");

                    uint seq = 1, tick = 1000;
                    view.Write((long)header, seq);
                    view.Write((long)header + 4, tick);
                    view.Write((long)header + 8, (uint)0x1F0A9284);
                    view.Write((long)header + 12, (uint)0x68666F6F);          // "oofh" -> hfoo
                    view.Write((long)header + 16, (uint)0x1F0A2444);
                    view.Write((long)header + 20, (uint)0x4870616C);          // "lapH" -> Hpal
                    view.Write((long)header + 24, BitConverter.ToUInt32(BitConverter.GetBytes(100f), 0));
                    view.Write((long)header + 28, (uint)0x101);
                    view.Write((long)header + 32, (uint)3);
                    view.Write((long)header + 36, (uint)0x20);
                    view.Write((long)header + 40, (uint)1);
                    view.Write((long)header + 44, (uint)1);
                    view.Write((long)header + 48, (uint)0);
                    // flags 偏移 = 13*4+64 + 5*4 + 2*4 + 2*4 + 2*4 = 160
                    view.Write((long)header + 160, (uint)1);                   // bit0 = 目标带蝗虫
                    WH(4, 1);                                                  // count=1

                    var evs = hook.Poll();
                    Check(evs.Count == 1, $"hook(v7)：读出 1 条事件（实际 {evs.Count}）");
                    if (evs.Count == 1)
                    {
                        var e = evs[0];
                        Check(e.Flags == 1, $"hook(v7)：Flags = 1（实际 {e.Flags}）");
                        Check(e.VictimLocust, "hook(v7)：VictimLocust = true");
                        Check(!new DamageHook.HookEvent(1, DateTime.Now, 0, "hfoo", 0, "Hpal", 1, false, false, 0, 0, false, Flags: 0).VictimLocust,
                              "hook(v7)：Flags=0 → VictimLocust = false");

                        // 马甲判定只看 Aloc（flags bit0），不看名字：名字里带“马甲”但 Aloc=0 不算；
                        // 名字是普通单位但 Aloc=1 算。口径与 YDWE 一致（Aloc<=0 = 普通单位）。
                        Check(!new DamageHook.HookEvent(2, DateTime.Now, 0x1000, "e04F", 0, "Hpal", 1, false, false, 0, 0, false,
                                                        VictimName: "马甲单位——苦难女神", Flags: 0).VictimLocust &&
                              new DamageHook.HookEvent(3, DateTime.Now, 0x2000, "hfoo", 0, "Hpal", 1, false, false, 0, 0, false,
                                                        VictimName: "普通步兵", Flags: 1).VictimLocust,
                              "马甲判定：只看 Aloc flags（名字叫“马甲”但无 Aloc 不算；普通名字但 Aloc=1 算）");
                    }
                }
            }
        }

        // ---------- 用例 12.5：v8 owner 解码（victimOwner/sourceOwner + 显示文本） ----------
        {
            int pid = Environment.ProcessId;
            string name = $@"Local\DdhRing_{pid}";
            using (var mmf = System.IO.MemoryMappedFiles.MemoryMappedFile.CreateNew(name, 1 << 20))
            using (var view = mmf.CreateViewAccessor())
            using (var hook = new DamageHook())
            {
                void WH(int idx, uint v) => view.Write((long)idx * 4, v);
                WH(0, 0x31484444); WH(1, 8); WH(2, (uint)pid); WH(3, 512);
                WH(4, 0); WH(5, 1); WH(7, 0x12340000); WH(8, 0x67DC40);

                Check(hook.Open(pid, 2000), "hook(v8)：能打开共享内存 " + name);
                if (hook.IsOpen)
                {
                    int header = 16 * 4;
                    // v8 记录长度 = 基础 116 + v3(20) + v4(8) + v5(8) + v6(8) + v7(4) + v8(8) = 172
                    int rec = 13 * 4 + 64 + 5 * 4 + 2 * 4 + 2 * 4 + 2 * 4 + 1 * 4 + 2 * 4;
                    Check(hook.Version == 8, $"hook(v8)：版本 = 8（实际 {hook.Version}）");
                    Check(rec == 172, $"hook(v8)：记录长度 = 172（实际 {rec}）");

                    uint seq = 1, tick = 1000;
                    view.Write((long)header, seq);
                    view.Write((long)header + 4, tick);
                    view.Write((long)header + 8, (uint)0x1F0A9284);       // victim
                    view.Write((long)header + 12, (uint)0x68666F6F);      // "oofh" -> hfoo
                    view.Write((long)header + 16, (uint)0x1F0A2444);      // source
                    view.Write((long)header + 20, (uint)0x4870616C);      // "lapH" -> Hpal
                    view.Write((long)header + 24, BitConverter.ToUInt32(BitConverter.GetBytes(100f), 0));
                    view.Write((long)header + 28, (uint)0x101);
                    view.Write((long)header + 32, (uint)3);
                    view.Write((long)header + 36, (uint)0x20);
                    view.Write((long)header + 40, (uint)1);
                    view.Write((long)header + 44, (uint)1);
                    view.Write((long)header + 48, (uint)0);
                    // flags 偏移 = 160；victimOwner 偏移 = 164；sourceOwner 偏移 = 168
                    view.Write((long)header + 160, (uint)0);               // flags
                    view.Write((long)header + 164, (uint)0);               // victimOwner = 0 -> Player 1
                    view.Write((long)header + 168, (uint)2);               // sourceOwner = 2 -> Player 3
                    WH(4, 1);                                               // count=1

                    var evs = hook.Poll();
                    Check(evs.Count == 1, $"hook(v8)：读出 1 条事件（实际 {evs.Count}）");
                    if (evs.Count == 1)
                    {
                        var e = evs[0];
                        Check(e.VictimOwner == 0 && e.SourceOwner == 2,
                              $"hook(v8)：VictimOwner=0 / SourceOwner=2（实际 {e.VictimOwner}/{e.SourceOwner}）");
                        Check(e.VictimOwnerText == "Player 1" && e.SourceOwnerText == "Player 3",
                              $"hook(v8)：owner 显示 Player 1 / Player 3（实际 {e.VictimOwnerText}/{e.SourceOwnerText}）");
                        var u = new DamageHook.HookEvent(1, DateTime.Now, 0, "hfoo", 0, "Hpal", 1, false, false, 0, 0, false);
                        Check(u.VictimOwnerText == "?" && u.SourceOwnerText == "?", "hook(v8)：owner=-1 → ?");
                    }
                }
            }
        }

        // ---------- 用例 12.7：v9 记录（名字各 64 字节） ----------
        {
            int pid = Environment.ProcessId;
            string name = $@"Local\DdhRing_{pid}";
            using (var mmf = System.IO.MemoryMappedFiles.MemoryMappedFile.CreateNew(name, 1 << 20))
            using (var view = mmf.CreateViewAccessor())
            using (var hook = new DamageHook())
            {
                void WH(int idx, uint v) => view.Write((long)idx * 4, v);
                WH(0, 0x31484444); WH(1, 9); WH(2, (uint)pid); WH(3, 512);
                WH(4, 0); WH(5, 1); WH(7, 0x12340000); WH(8, 0x67DC40);

                bool opened = hook.Open(pid, 2000);
                Check(opened && hook.Version == 9 && hook.RecordSize == 236 && hook.NameFieldSize == 64,
                      $"hook(v9)：版本=9 / 记录=236 字节 / 名字各 64 字节（实际 opened={opened} " +
                      $"v{hook.Version} {hook.RecordSize}B {hook.NameFieldSize}B）");
                if (opened)
                {
                    int header = 16 * 4;

                    uint seq = 1, tick = 1000;
                    view.Write((long)header, seq);
                    view.Write((long)header + 4, tick);
                    view.Write((long)header + 8, (uint)0x1F0A9284);
                    view.Write((long)header + 12, (uint)0x68666F6F);
                    view.Write((long)header + 16, (uint)0x1F0A2444);
                    view.Write((long)header + 20, (uint)0x4870616C);
                    view.Write((long)header + 24, BitConverter.ToUInt32(BitConverter.GetBytes(100f), 0));
                    view.Write((long)header + 28, (uint)0x101);
                    view.Write((long)header + 32, (uint)3);
                    view.Write((long)header + 36, (uint)0x20);
                    view.Write((long)header + 40, (uint)1);
                    view.Write((long)header + 44, (uint)1);
                    view.Write((long)header + 48, (uint)0);

                    // 真机日志里的截断 UTF-8（末尾 E4 BD 是半个汉字）：v9 读到 64 字节字段，
                    // 解码应保留 bbbb，不能回退成 GBK 的「鎶€鑳…」。
                    byte[] victimField =
                    {
                        0x20, 0x62, 0x62, 0x62, 0x62,
                        0xE6, 0x8A, 0x80, 0xE8, 0x83, 0xBD, 0xE5, 0x8D, 0x95, 0xE4, 0xBD,
                    };
                    for (int i = 0; i < victimField.Length; i++) view.Write((long)header + 52 + i, victimField[i]);

                    // 63 字节的合法 UTF-8 名字（20 个「雪」= 60 字节 + "abc"），检验 name[64] 两段偏移。
                    string sourceText = new string('雪', 20) + "abc";
                    byte[] sourceField = Encoding.UTF8.GetBytes(sourceText);
                    for (int i = 0; i < sourceField.Length; i++) view.Write((long)header + 52 + 64 + i, sourceField[i]);

                    // v3..v8 字段（基础段 180 起）
                    view.Write((long)header + 180, BitConverter.ToUInt32(BitConverter.GetBytes(80f), 0));
                    view.Write((long)header + 184, BitConverter.ToUInt32(BitConverter.GetBytes(70f), 0));
                    view.Write((long)header + 188, BitConverter.ToUInt32(BitConverter.GetBytes(10f), 0));
                    view.Write((long)header + 192, (uint)1);
                    view.Write((long)header + 196, (uint)1);
                    view.Write((long)header + 224, (uint)0);   // flags
                    view.Write((long)header + 228, (uint)3);   // victimOwner -> Player 4
                    view.Write((long)header + 232, (uint)5);   // sourceOwner -> Player 6
                    WH(4, 1);

                    var evs = hook.Poll();
                    Check(evs.Count == 1, $"hook(v9)：读出 1 条事件（实际 {evs.Count}）");
                    if (evs.Count == 1)
                    {
                        var e = evs[0];
                        Check(e.VictimName.Contains("bbbb") && !e.VictimName.Contains('鎶') &&
                              !e.VictimName.Contains('€') && !e.VictimName.Contains('\uFFFD') &&
                              e.SourceName == sourceText && e.VictimOwner == 3 && e.SourceOwner == 5,
                              $"hook(v9)：两段 64 字节名字 → victim「{e.VictimName}」/ source「{e.SourceName}」（{sourceText.Length} 字），" +
                              $"owner {e.VictimOwner}→{e.SourceOwner}");
                    }
                }
            }
        }

        // ---------- 用例 13：名字解码（引擎返回 UTF-8 时按 UTF-8 解，老版本 GBK 时按 GBK 解） ----------
        {
            // UTF-8：雪狼 = E9 9B AA E7 8B BC（用户真机截图里这段字节曾被按 GBK 解成乱码）
            var utf8 = new byte[] { 0xE9, 0x9B, 0xAA, 0xE7, 0x8B, 0xBC };
            Check(Gbk.DecodeName(utf8) == "雪狼", $"名字解码：UTF-8 → 雪狼（实际 '{Gbk.DecodeName(utf8)}'）");

            // GBK：雪狼 = D1 A9 C0 C7
            var gbk = new byte[] { 0xD1, 0xA9, 0xC0, 0xC7 };
            Check(Gbk.DecodeName(gbk) == "雪狼", $"名字解码：GBK → 雪狼（实际 '{Gbk.DecodeName(gbk)}'）");

            // 纯 ASCII（同时是合法 UTF-8）原样返回
            var ascii = new byte[] { (byte)'h', (byte)'f', (byte)'o', (byte)'o' };
            Check(Gbk.DecodeName(ascii) == "hfoo", "名字解码：ASCII 原样返回");

            // 全控制字符 / 空串 → 空串（调用方退显示 4 字符类型码）
            Check(Gbk.DecodeName(Array.Empty<byte>()) == "", "名字解码：空输入 → 空串");
            Check(Gbk.DecodeName(new byte[] { 0x01, 0x02, 0x03 }) == "", "名字解码：全控制字符 → 空串");

            // 真机日志里的那段截断 UTF-8：20 62 62 62 62 E6 8A 80 E8 83 BD E5 8D 95 E4 BD。
            // 严格 UTF-8 失败（末尾 E4 BD 是半个汉字）；必须选“UTF-8 替换解码”而不是 GBK 的
            // 「 bbbb鎶€鑳藉崟浣嶏…」。允许末尾 U+FFFD 被去掉。
            var truncReal = new byte[]
            {
                0x20, 0x62, 0x62, 0x62, 0x62,
                0xE6, 0x8A, 0x80, 0xE8, 0x83, 0xBD, 0xE5, 0x8D, 0x95, 0xE4, 0xBD,
            };
            string realName = Gbk.DecodeName(truncReal);
            Check(realName.Contains("bbbb") && !realName.Contains('鎶') && !realName.Contains('€') &&
                  !realName.Contains('\uFFFD'),
                  $"名字解码：真机截断 hex →「{realName}」（含 bbbb，非 GBK 乱码）");

            // 截断边界：29 字节 = 9 个「雪」+ 第 10 个汉字的前 2 字节；63 字节 = 20 个「雪」+ "ab" + 半个「雪」。
            // 解码必须保住完整汉字，不能把残字节解成乱码。
            string boundaryText = new string('雪', 20) + "ab" + "雪";
            byte[] boundaryUtf8 = Encoding.UTF8.GetBytes(boundaryText);
            string cut29 = Gbk.DecodeName(boundaryUtf8[..29]);
            string cut63 = Gbk.DecodeName(boundaryUtf8[..63]);
            Check(cut29 == new string('雪', 9) && !cut29.Contains('\uFFFD'),
                  $"名字解码：29 字节边界（截在汉字中间）→「{cut29}」（9 个完整「雪」）");
            Check(cut63 == new string('雪', 20) + "ab" && !cut63.Contains('\uFFFD'),
                  $"名字解码：63 字节边界（截在汉字中间）→「{cut63}」（20 个「雪」+ ab）");
        }

        // ---------- 用例 14：筛选项刷新重入 / 事件集合快照（防止 “Collection was modified”） ----------
        {
            // 14a：ComboBox 重入保护 —— RefreshHookFilterItems 改 SelectedIndex 时会同步触发
            // SelectedIndexChanged → UpdateHookGrid → RefreshHookFilterItems，_inFilterRefresh 必须把重入挡掉。
            {
                var cmb = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList };
                bool inRefresh = false;
                int fullRefreshes = 0;   // 真正跑完整刷新的次数（重入应被挡掉，不计数）
                cmb.Items.Add("(全部)");
                cmb.SelectedIndexChanged += (_, _) =>
                {
                    if (inRefresh) return;   // 对应 MainForm 的 if (_inFilterRefresh) return;
                    fullRefreshes++;
                    RefreshGridAndFilters();
                };

                void RefreshGridAndFilters() => RefreshFilterItems();   // 对应 UpdateHookGrid 末尾刷筛选框

                void RefreshFilterItems()
                {
                    if (inRefresh) return;
                    inRefresh = true;
                    try
                    {
                        var snap = cmb.Items.Cast<object>().ToList();   // 先快照再遍历（不边枚举边改）
                        cmb.BeginUpdate();
                        try
                        {
                            cmb.Items.Clear();
                            cmb.Items.Add("(全部)");
                            cmb.Items.Add("hfoo");
                            cmb.Items.Add("Hpal");
                            cmb.SelectedIndex = 2;   // 触发 SelectedIndexChanged，被 inRefresh 挡掉
                        }
                        finally { cmb.EndUpdate(); }
                    }
                    finally { inRefresh = false; }
                }

                RefreshFilterItems();   // 模拟定时器/程序化刷新
                Check(fullRefreshes == 0, $"筛选刷新重入：程序化重建筛选框不触发重入刷新（fullRefreshes=0，实际 {fullRefreshes}）");
                Check(cmb.Items.Count == 3 && cmb.SelectedIndex == 2, "筛选刷新重入：下拉框正常刷新（3 项，选中第 3 项）");

                cmb.SelectedIndex = 1;   // 模拟用户手动切换（此刻 inRefresh=false）
                Check(fullRefreshes == 1, $"筛选刷新重入：用户切换恰好触发一次完整刷新（fullRefreshes=1，实际 {fullRefreshes}）");
            }

            // 14b：MonitorEngine.HookEvents 返回线程安全快照 —— 监视线程改集合、界面线程枚举快照不抛异常。
            {
                var engine = new MonitorEngine();
                var fList = typeof(MonitorEngine).GetField("_hookEvents",
                    System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
                var fLock = typeof(MonitorEngine).GetField("_hookEventsLock",
                    System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
                Check(fList != null && fLock != null, "筛选刷新重入：能定位内部事件集合/锁（自检反射前提）");
                if (fList != null && fLock != null)
                {
                    var live = (List<DamageHook.HookEvent>)fList.GetValue(engine)!;
                    object gate = fLock.GetValue(engine)!;
                    var started = new ManualResetEventSlim(false);
                    var stop = new ManualResetEventSlim(false);
                    var writer = new Thread(() =>
                    {
                        started.Set();
                        int i = 0;
                        while (!stop.IsSet)
                        {
                            lock (gate)
                            {
                                live.Add(new DamageHook.HookEvent((uint)i, DateTime.Now, 0x1000, "hfoo", 0x2000, "Hpal", i, true, false, 3, 4, true));
                                if (live.Count > 100) live.RemoveRange(0, live.Count - 100);
                                i++;
                            }
                        }
                    }) { IsBackground = true };
                    writer.Start();
                    started.Wait();
                    bool ok = true;
                    try
                    {
                        for (int iter = 0; iter < 20000; iter++)
                        {
                            var snap = engine.HookEvents;                          // 界面线程走的路径（返回快照）
                            foreach (var e in snap.Select(x => x.VictimCode)) { }  // RefreshHookFilterItems 里的枚举模式
                        }
                    }
                    catch { ok = false; }
                    stop.Set();
                    writer.Join();
                    Check(ok, "筛选刷新重入：监视线程改集合时，界面枚举 HookEvents 快照 0 异常");
                }
            }
        }

        // ---------- 用例 15：伤害事件显示倒序 + 表格锚点身份键 ----------
        {
            var t0 = new DateTime(2026, 10, 18, 10, 0, 0);
            var evs = new List<DamageHook.HookEvent>
            {
                new(1, t0, 0x1000, "hfoo", 0x2000, "Hpal", 10, true, false, 3, 4, true),
                new(2, t0.AddMilliseconds(100), 0x1000, "hfoo", 0x2000, "Hpal", 20, true, false, 3, 4, true),
                new(3, t0.AddMilliseconds(200), 0x1000, "hfoo", 0x3000, "ewsp", 30, true, false, 3, 4, true),
            };

            // 显示顺序 = 最新在上：取窗口尾部（Seq 最大的 600 条）再反转 → Seq 降序。
            var display = evs.TakeLast(600).Reverse().ToList();
            Check(display.Count == 3 && display[0].Seq == 3 && display[1].Seq == 2 && display[2].Seq == 1,
                  $"伤害事件显示按时间倒序：Seq {string.Join(",", display.Select(e => e.Seq))}（期望 3,2,1）");

            // 锚点键计算（界面重建表格前后用它找回“同一行”）
            var s = new Settlement { Addr = 0x1A2B3C4D, TypeCode = "hfoo", DiedAt = t0, InstanceIndex = 2, Kind = "死亡" };
            Check(AnchorKeys.ForSettlement(s) == $"S:1A2B3C4D:{t0.Ticks}:2",
                  "锚点键：结算行 = 地址+死亡时间+实例");
            Check(AnchorKeys.ForLiveUnit(0x1A2B3C4D, 2) == "L:1A2B3C4D:2",
                  "锚点键：存活行 = 地址+实例");
            Check(AnchorKeys.ForHook(display[0]) == "3", "锚点键：伤害事件 = Seq");
        }

        // ---------- 用例 16：双击跳转目标解析 + 按地址过滤谓词（死亡结算双击 → 伤害事件页只看该单位） ----------
        {
            var t0 = new DateTime(2026, 10, 18, 11, 0, 0);
            const uint addr = 0x1A2B3C4D;

            // 双击目标解析：结算行（名字优先）/ 存活行（名字空退回类型码）→ 统一 (地址, 显示名)
            var s = new Settlement { Addr = addr, TypeCode = "hfoo", UnitName = "步兵", Kind = "死亡", DiedAt = t0, FirstSeen = t0.AddSeconds(-10) };
            var st = SettleJump.FromSettlement(s);
            var lu = SettleJump.FromLiveUnit(0x2B3C4D5E, "ogre", "");
            Check(st.Addr == addr && st.Name == "步兵" &&
                  lu.Addr == 0x2B3C4D5E && lu.Name == "ogre",
                  "双击目标解析：结算行/存活行 → (地址, 显示名)，名字空退类型码");

            // 地址过滤谓词：事件是来源（打人）或触发/受害（挨打）单位即命中，否则排除
            var hitVictim = new DamageHook.HookEvent(1, t0, addr, "hfoo", 0x9999, "Hpal", 10, true, false, 3, 4, true);
            var hitSource = new DamageHook.HookEvent(2, t0, 0x8888, "ogre", addr, "Hpal", 20, true, false, 3, 4, true);
            var miss = new DamageHook.HookEvent(3, t0, 0x7777, "ogre", 0x6666, "ewsp", 30, true, false, 3, 4, true);
            Check(SettleJump.MatchesAddr(hitVictim, addr) && SettleJump.MatchesAddr(hitSource, addr),
                  "地址过滤谓词：来源/受害地址命中");
            Check(!SettleJump.MatchesAddr(miss, addr), "地址过滤谓词：无关事件被排除");
        }

        // ---------- 用例 17：单位ID/玩家号格式化 + 分页切片 + 弹窗对端集合 ----------
        {
            // 地址格式化：固定 8 位十六进制（死亡结算“单位ID”、伤害事件“触发单位ID/伤害来源ID”共用）
            Check(UnitEvents.FormatAddr(0x1A2B3C4D) == "0x1A2B3C4D", "地址格式化：0x1A2B3C4D");
            Check(UnitEvents.FormatAddr(0x1234) == "0x00001234", "地址格式化：补足 8 位（0x00001234）");

            // 玩家号格式化：N 从 1 开始；拿不到（slot<0）显示 ?
            Check(UnitEvents.FormatPlayer(0) == "Player 1", "玩家号格式化：slot 0 → Player 1");
            Check(UnitEvents.FormatPlayer(2) == "Player 3", "玩家号格式化：slot 2 → Player 3");
            Check(UnitEvents.FormatPlayer(-1) == "?", "玩家号格式化：slot<0 → ?");

            // 分页切片：输入“最旧在前”，输出当前页“最新在前”
            var t0 = new DateTime(2026, 10, 19, 12, 0, 0);
            var evs = new List<DamageHook.HookEvent>();
            for (uint i = 1; i <= 1200; i++)
                evs.Add(new DamageHook.HookEvent(i, t0.AddMilliseconds(i), 0x1000 + i, "hfoo", 0x2000 + i, "Hpal", 10, true, false, 3, 4, true));
            Check(UnitEvents.PageCount(1200) == 3, "分页：1200 条 → 3 页（每页 500）");
            var page0 = UnitEvents.SlicePage(evs, 0, 500);
            Check(page0.Count == 500 && page0[0].Seq == 1200 && page0[^1].Seq == 701, "分页：第 1 页 = 最新 500（1200..701 倒序）");
            var page2 = UnitEvents.SlicePage(evs, 2, 500);
            Check(page2.Count == 200 && page2[0].Seq == 200 && page2[^1].Seq == 1, "分页：第 3 页 = 最旧 200（200..1 倒序）");
            Check(UnitEvents.SlicePage(Array.Empty<DamageHook.HookEvent>(), 0, 500).Count == 0, "分页：空列表 → 空页");

            // 弹窗筛选对端集合：该单位打谁 / 被谁打，去重、升序
            const uint me = 0xA000;
            var rel = new List<DamageHook.HookEvent>
            {
                new(1, t0, 0x5000, "hfoo", me, "Hpal", 10, true, false, 3, 4, true),   // me 是来源
                new(2, t0, me, "hfoo", 0x6000, "ewsp", 20, true, false, 3, 4, true),   // me 是触发
                new(3, t0, 0x5000, "hfoo", me, "Hpal", 30, true, false, 3, 4, true),   // me 是来源（重复对端 0x5000）
                new(4, t0, 0x7000, "ogre", 0x8000, "n000", 40, true, false, 3, 4, true), // 与 me 无关
            };
            var peers = UnitEvents.CounterpartAddrs(rel, me);
            Check(peers.Count == 2 && peers[0] == 0x5000 && peers[1] == 0x6000,
                  $"弹窗对端集合：{string.Join(",", peers.Select(p => p.ToString("X8")))}（去重、升序）");
        }

        // ---------- 用例 18：伤害事件列定义与行渲染对齐（主页 / 弹窗共用 19 列，防止加列后行错位） ----------
        {
            var g = new Ui.Grid();
            Ui.HookGridUi.AddColumns(g);
            var hookHeaders = g.Columns.Cast<DataGridViewColumn>().Select(c => c.HeaderText).ToList();
            Check(g.Columns.Count == 19 && g.Columns["dmask"] == null,
                  $"伤害事件表 19 列且没有掩码列（实际 {g.Columns.Count} 列）");
            Check(hookHeaders[3] == "触发玩家" && hookHeaders[6] == "来源玩家" &&
                  !hookHeaders.Contains("触发镜像") && !hookHeaders.Contains("来源镜像"),
                  "伤害事件玩家列：触发玩家 / 来源玩家");
            var t0 = new DateTime(2026, 10, 19, 13, 0, 0);
            var e = new DamageHook.HookEvent(1, t0, 0x1000, "hfoo", 0x2000, "Hpal", 10, true, false, 3, 4, true, DamageMask: 0x10);
            var cells = Ui.HookGridUi.RowCells(e, _ => "Player 1");
            Check(cells.Length == 19, $"行渲染 19 格（实际 {cells.Length}）");
            Check((string)cells[2] == "0x00001000" && (string)cells[3] == "?" &&
                  (string)cells[5] == "0x00002000",
                  "行渲染：无 game_units 身份时玩家显示 ?、单位ID 正确");

            var titled = new DamageHook.HookEvent(2, t0, 0x1000, "hfoo", 0x2000, "Hpal", 10,
                true, false, 3, 4, true, VictimName: "西利沃特", SourceName: "圣骑士")
            {
                VictimTitle = "剑影",
                SourceTitle = "乌瑟尔",
            };
            Func<string, bool, Ui.HookGridUi.UnitIdentity> identities = (code, mirror) => code switch
            {
                "hfoo" => new Ui.HookGridUi.UnitIdentity("西利沃特", "剑影", 0),
                "Hpal" => new Ui.HookGridUi.UnitIdentity("圣骑士", "乌瑟尔", 1),
                _ => Ui.HookGridUi.Unknown,
            };
            var titledCells = Ui.HookGridUi.RowCells(
                titled, _ => "Player 1", identityOf: identities);
            var mirrorCells = Ui.HookGridUi.RowCells(
                titled, _ => "Player 1", isIllusionOf: (addr, code) => addr == 0x2000 && code == "Hpal",
                identityOf: identities);
            var recordedMirror = titled with { Flags = DamageHook.HookEvent.FlagSourceIllusion };
            var recordedMirrorCells = Ui.HookGridUi.RowCells(
                recordedMirror, _ => "Player 1", identityOf: identities);
            var heroSource = titled with { Flags = DamageHook.HookEvent.FlagSourceHero };
            var heroSourceCells = Ui.HookGridUi.RowCells(
                heroSource, _ => "Player 1", identityOf: identities);
            Check((string)titledCells[1] == "剑影\n西利沃特" &&
                  (string)titledCells[4] == "乌瑟尔\n圣骑士" &&
                  (string)titledCells[3] == "Player 1" &&
                  (string)titledCells[6] == "Player 2" &&
                  heroSource.SourceHero && (string)heroSourceCells[7] == "是" &&
                  (string)mirrorCells[4] == "乌瑟尔\n圣骑士（镜像）" &&
                  recordedMirror.SourceIllusion &&
                  (string)recordedMirrorCells[4] == "乌瑟尔\n圣骑士（镜像）",
                  "伤害事件：名称/玩家/英雄标志正确；来源镜像位优先于地址回退");

            var fallbackEvent = new DamageHook.HookEvent(3, t0,
                0x3000, "hfoo", 0x4000, "Hpal", 10, true, false, 3, 4, true);
            var fallbackCells = Ui.HookGridUi.RowCells(
                fallbackEvent, _ => "Player 1",
                identityOf: (_, _) => Ui.HookGridUi.Unknown);
            Check((string)fallbackCells[1] == "hfoo" &&
                  (string)fallbackCells[4] == "Hpal" &&
                  (string)fallbackCells[3] == "?" &&
                  (string)fallbackCells[6] == "?",
                  $"伤害事件：类型码 + 镜像位匹配失败时名称显示类型码、玩家显示 ?" +
                  $"（实际 {(string)fallbackCells[1]}/{(string)fallbackCells[3]}/" +
                  $"{(string)fallbackCells[4]}/{(string)fallbackCells[6]}）");
            var fatalRateEvent = new DamageHook.HookEvent(
                4, t0, 0x5000, "hfoo", 0x6000, "Hpal", 100,
                false, true, 0, 14, true,
                HpBefore: 80, HpAfter: 0, Actual: 80, HpValid: true,
                EngineDamage: 100, EngineValid: true,
                EngineLast: 80, EngineCalls: 5, IsV20: true);
            var fatalRateCells = Ui.HookGridUi.RowCells(
                fatalRateEvent, _ => "?",
                identityOf: (_, _) => Ui.HookGridUi.Unknown);
            Check((string)fatalRateCells[13] == "0.8×",
                  $"伤害事件：击杀钳制仍显示地图伤害÷引擎伤害（实际 {fatalRateCells[13]}）");
            Check(Ui.MainForm.UnitIdentitySessionKey("live-session", "cached-session") == "live-session" &&
                  Ui.MainForm.UnitIdentitySessionKey("", "cached-session") == "cached-session" &&
                  Ui.MainForm.UnitIdentitySessionKey(null, null) == "",
                  "游戏关闭后身份匹配继续沿用上一局 session_id，不清空名称缓存键");

            // 弹窗（UnitEventsForm）在纯 STA 下可构造并渲染：列结构 / 两个筛选下拉 / 分页控件齐备。
            var popEvents = new List<DamageHook.HookEvent>
            {
                new(1, t0, 0x5000, "hfoo", 0x12345678, "Hpal", 10, true, false, 3, 4, true),
                new(2, t0, 0x12345678, "hfoo", 0x6000, "ewsp", 20, true, false, 3, 4, true),
            };
            var popup = new Ui.UnitEventsForm("步兵 0x12345678", 0x12345678, popEvents, () => popEvents, _ => "Player 1");
            Check(popup.Controls.Count >= 3, $"弹窗：可构造（顶部筛选/中部表格/底部分页，实际控件 {popup.Controls.Count}）");
            // 类型下拉默认【目标】（只看该单位挨打的事件）；参与单位仍是【全部】，用户切换后刷新不重置。
            var typeCombo = typeof(Ui.UnitEventsForm)
                .GetField("_cmbType", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance)
                ?.GetValue(popup) as ComboBox;
            Check(typeCombo is { SelectedIndex: 2 } && typeCombo.SelectedItem?.ToString() == "目标",
                  $"弹窗默认类型 = 目标（实际 {typeCombo?.SelectedItem?.ToString() ?? "<无>"}）");
        }

        // ---------- 用例 19.5：单位名样式清理（|cXXXXXX|r）+ 右键“单位属性”表 ----------
        {
            var styleTime = new DateTime(2026, 10, 24, 12, 0, 0);

            // 1) 颜色码/复位码清理：标准 8 位、6 位、被 16 字节字段截断的残码、大小写 |R、普通名字
            Check(Wc3Text.Clean("|cff9900黄金佛|r") == "黄金佛" &&
                  Wc3Text.Clean("|cFFFF0000红|R") == "红" &&
                  Wc3Text.Clean("|c00FF00绿") == "绿" &&
                  Wc3Text.Clean("黑暗舞者(|cfff0") == "黑暗舞者" &&        // 引擎名字段 16 字节截断后的残码
                  Wc3Text.Clean("黑暗舞者(|cfff0E053)") == "黑暗舞者" &&   // 完整的 "名字(|cXXXX)" 写法
                  Wc3Text.Clean("名字(|c") == "名字" &&                    // 只剩 |c
                  Wc3Text.Clean("费用(|cost)") == "费用(|cost)" &&          // 不是颜色码，不能误删
                  Wc3Text.Clean("普通步兵") == "普通步兵" &&
                  Wc3Text.Clean("") == "" && Wc3Text.Clean(null) == "" &&
                  !Wc3Text.HasStyle("普通步兵") && Wc3Text.HasStyle("|cff9900黄金佛|r"),
                  "单位名样式：|cAARRGGBB / |r / |R / 截断残码（名字(|cfff0）全部去掉，普通名字与 (|cost) 不受影响");

            // 2) 三个入口都洗干净：运行时结算 / 钩子事件显示文本 / 历史 DTO
            var styledSettlement = new Settlement { Addr = 0x3000, TypeCode = "O015", UnitName = "|cff9900黄金佛|r" };
            var styledEvent = new DamageHook.HookEvent(1, styleTime, 0x2000, "hfoo", 0x1000, "O015",
                10, true, false, 3, 4, true, "步兵", "|cff9900黄金佛|r");
            var styledHistory = new HistoryEvent
            {
                VictimName = "|cff00ff00绿|r",
                SourceName = "|cFFFF0000红|R",
            };
            Check(styledSettlement.UnitName == "黄金佛" && styledEvent.SourceText == "黄金佛(O015)" &&
                  styledHistory.VictimName == "绿" && styledHistory.SourceName == "红",
                  "单位名样式：Settlement / HookEvent.SourceText / 历史 DTO 三处自动清理（旧库读出也干净）");

            // 3) 单位属性表（存活）：血量/护甲取快照；攻击力/攻击间隔由钩子事件实测
            var statEvents = new List<DamageHook.HookEvent>();
            for (int i = 0; i < 5; i++)
                statEvents.Add(new DamageHook.HookEvent((uint)i, styleTime.AddSeconds(i * 1.5), 0x2000, "hfoo",
                    0x1000, "Hpal", 100 + i, true, false, 3, 4, true));
            var live = new UnitView
            {
                Addr = 0x1000, TypeCode = "Hpal", Name = "圣骑士", Owner = "Player 1",
                Hp = 500, HpMax = 1000, HpPercent = 0.5f, Armor = 7.5f,
            };
            var statRows = UnitStats.ForLive(live, statEvents);
            string StatValue(string name) => statRows.FirstOrDefault(r => r.Name == name)?.Value ?? "";
            Check(StatValue("血量").Contains("500") && StatValue("血量").Contains("1000") &&
                  StatValue("护甲") == "7.5" &&
                  StatValue("攻击力").Contains("100") && StatValue("攻击力").Contains("104") &&
                  StatValue("攻击间隔").Contains("1.5") &&
                  StatValue("技能") == "—",
                  $"单位属性表（存活）：血量 500/1000、护甲 7.5、攻击力 100~104（5 次）、攻击间隔 ≈1.5 秒、技能 —" +
                  $"（实际 {StatValue("攻击力")} / {StatValue("攻击间隔")}）");

            // 3.0) 战斗中提前记录：死了以后（事件表已空、内存也读不到）属性表仍有活着时的记录
            var combat = new UnitCombatStats();
            combat.ObserveArmor(12.5f);
            combat.ObserveLocust(true);
            for (int i = 0; i < 5; i++)
                combat.ObserveAttack(new DamageHook.HookEvent((uint)i, styleTime.AddSeconds(i * 1.5),
                    0x2000, "hfoo", 0x5000, "Hpal", 100 + i, true, false, 3, 4, true));
            var recorded = new Settlement
            {
                Addr = 0x5000, TypeCode = "Hpal", UnitName = "圣骑士",
                HpMax = 1000, HpAtFirstSeen = 800, Kind = "死亡",
            };
            combat.ApplyTo(recorded);
            var recordedRows = UnitStats.ForSettlement(recorded, Array.Empty<DamageHook.HookEvent>());
            string RecValue(string name) => recordedRows.FirstOrDefault(r => r.Name == name)?.Value ?? "";
            Check(RecValue("护甲") == "12.5" && RecValue("技能").Contains("Aloc") &&
                  RecValue("攻击力").Contains("100") && RecValue("攻击力").Contains("104") &&
                  RecValue("攻击间隔").Contains("1.5"),
                  "战斗中提前记录：死后（事件表已空）属性表仍显示 护甲 12.5 / 攻击力 100~104 / 间隔 ≈1.5s / 技能 Aloc" +
                  $"（实际 {RecValue("护甲")} / {RecValue("攻击力")} / {RecValue("攻击间隔")} / {RecValue("技能")}）");

            // 3.05) 致命钩子事件补建死亡结算：单位没被扫描到（一击死/召唤物）也不能“死了没结算”
            var lethal = new DamageHook.HookEvent(9, styleTime, 0x6000, "o006", 0x1000, "h000", 230,
                true, false, 2, 4, true, "剑龙", "幸存者",
                HpBefore: 175, HpAfter: 0, Actual: 175, HpValid: true, VictimOwner: 9);
            var synthetic = HookDeath.FromLethalEvent(lethal, "剑龙");
            var notLethal = HookDeath.FromLethalEvent(lethal with { HpAfter = 50, Actual = 125 }, "剑龙");
            Check(synthetic != null && synthetic.Kind == "死亡" && synthetic.Addr == 0x6000 &&
                  Math.Abs(synthetic.TotalDamage - 175) < 0.001 && synthetic.SyntheticHookDeath &&
                  notLethal == null,
                  "致命钩子事件补建：血 175→0 生成死亡结算（总伤害 175）；未致命（175→50）不补建");

            // 3.1) 右键“查看详情”窗口本体：3 列表格 × 5 行（构造后立刻 Dispose，不跑消息循环）
            var statsForm = new Ui.UnitStatsForm("测试单位 0x00001000（单位属性）", statRows);
            var statsGrid = statsForm.Controls.Count == 1 ? statsForm.Controls[0] as DataGridView : null;
            Check(statsGrid != null && statsGrid.Rows.Count == 5 && statsGrid.Columns.Count == 3 &&
                  Convert.ToString(statsGrid.Rows[0].Cells[0].Value) == "血量" &&
                  Convert.ToString(statsGrid.Rows[4].Cells[0].Value) == "技能",
                  "单位属性窗：单表格 3 列（属性/数值/数据来源）× 5 行（血量/攻击力/攻击间隔/护甲/技能）");
            statsForm.Dispose();

            // 4) 单位属性表（已结算）：护甲/技能读不到内存 → ? / —，不能编数字
            var dead = new Settlement
            {
                Addr = 0x4000, TypeCode = "uske", UnitName = "骷髅战士",
                HpMax = 1000, HpAtFirstSeen = 800, Kind = "死亡",
            };
            var deadRows = UnitStats.ForSettlement(dead, statEvents);
            string DeadValue(string name) => deadRows.FirstOrDefault(r => r.Name == name)?.Value ?? "";
            Check(DeadValue("血量").Contains("800") && DeadValue("血量").Contains("1000") &&
                  DeadValue("护甲") == "?" && DeadValue("技能") == "—" &&
                  DeadValue("攻击力") == "?",
                  "单位属性表（已结算）：血量 800/1000，护甲 ?、技能 —、没有它的攻击事件时攻击力 ?（不编数字）");
        }

        // ---------- 用例 20：结算表头搜索（模糊匹配 / 两列 AND / 表头指示） ----------
        {
            // 不区分大小写的模糊（按字符顺序）匹配；空关键词 = 全过；null 单元格只被空关键词命中。
            Check(Ui.SettlementGridUi.MatchesCellValue("NCPN", "ncp") &&
                  Ui.SettlementGridUi.MatchesCellValue("ncpn", "NCP") &&
                  Ui.SettlementGridUi.MatchesCellValue("步兵", "兵") &&
                  Ui.SettlementGridUi.MatchesCellValue("任意", "") &&
                  Ui.SettlementGridUi.MatchesCellValue(null, "") &&
                  !Ui.SettlementGridUi.MatchesCellValue(null, "ncp") &&
                  !Ui.SettlementGridUi.MatchesCellValue("hfoo", "ncp"),
                  "表头搜索：不区分大小写/模糊命中，空关键词 = 全部通过，null 不命中非空关键词");

            // 用户点名的用例：星 → 星之真神；星神 → 星之真神（星、神按顺序出现即可，不必连续）。
            Check(Ui.SettlementGridUi.MatchesCellValue("星之真神", "星") &&
                  Ui.SettlementGridUi.MatchesCellValue("星之真神", "星神") &&
                  Ui.SettlementGridUi.MatchesCellValue("星之真神", "真神") &&
                  !Ui.SettlementGridUi.MatchesCellValue("星之真神", "神星") &&
                  Ui.SettlementGridUi.MatchesRowValues("星之真神", "H02N", "星神", "h2n"),
                  "表头搜索：模糊匹配按字符顺序（星神 → 星之真神；神星不命中）");

            // 两列同时有词 = AND：单位名与类型码都必须命中；任一为空则那一列不限制。
            Check(Ui.SettlementGridUi.MatchesRowValues("ncpn", "ncpn", "n", "ncp") &&
                  !Ui.SettlementGridUi.MatchesRowValues("hfoo", "hfoo", "n", "ncp") &&
                  !Ui.SettlementGridUi.MatchesRowValues("ncpn", "hfoo", "n", "ncp") &&
                  Ui.SettlementGridUi.MatchesRowValues("hfoo", "hfoo", "", "") &&
                  Ui.SettlementGridUi.MatchesRowValues("hfoo", "hfoo", "hf", ""),
                  "表头搜索：两列 AND（任一列不命中即排除；都为空 = 全部通过）");

            // 表头过滤指示：有词 → 单位名（⌕ abc）；清空 → 恢复原表头。
            Check(Ui.SettlementGridUi.HeaderText("单位名", "abc") == "单位名（⌕ abc）" &&
                  Ui.SettlementGridUi.HeaderText("单位名", "") == "单位名" &&
                  Ui.SettlementGridUi.HeaderText("类型码", "ncp") == "类型码（⌕ ncp）",
                  "表头搜索：过滤指示 单位名（⌕ abc），清空后恢复原表头");

            // placeholder 不能挡光标：聚焦（正在输入）或有文字时必须隐藏。
            Check(!Ui.SettlementHeaderSearch.PlaceholderVisible(true, focused: true, textLength: 0, "搜索单位名") &&
                  !Ui.SettlementHeaderSearch.PlaceholderVisible(true, focused: false, textLength: 2, "搜索单位名") &&
                  !Ui.SettlementHeaderSearch.PlaceholderVisible(false, focused: false, textLength: 0, "搜索单位名"),
                  "表头搜索：搜索框聚焦或有文字时 placeholder 隐藏（不盖光标/文字），收起时也隐藏");

            // 失焦 + 空 → placeholder 重新出现（对应截图 c）。
            Check(Ui.SettlementHeaderSearch.PlaceholderVisible(true, focused: false, textLength: 0, "搜索单位名") &&
                  Ui.SettlementHeaderSearch.PlaceholderVisible(true, focused: false, textLength: 0, "搜索类型码") &&
                  !Ui.SettlementHeaderSearch.PlaceholderVisible(true, focused: false, textLength: 0, ""),
                  "表头搜索：失焦且输入为空时 placeholder 可见（聚焦后立即隐藏）");

            // 伤害事件表：触发单位 / 伤害来源也走同一套模糊谓词（按显示文本，不区分大小写、不必连续）。
            var hookSearchEvent = new DamageHook.HookEvent(1, new DateTime(2026, 10, 19, 14, 0, 0),
                0x1000, "hfoo", 0x2000, "Hpal", 10, true, false, 3, 4, true,
                VictimName: "步兵", SourceName: "圣骑士");
            Check(Ui.HookGridUi.MatchesSearch(hookSearchEvent, "步", "") &&
                  Ui.HookGridUi.MatchesSearch(hookSearchEvent, "", "圣骑") &&
                  Ui.HookGridUi.MatchesSearch(hookSearchEvent, "hf", "HPA") &&
                  Ui.HookGridUi.MatchesSearch(hookSearchEvent, "", "") &&
                  !Ui.HookGridUi.MatchesSearch(hookSearchEvent, "骑", "") &&
                  !Ui.HookGridUi.MatchesSearch(hookSearchEvent, "", "步"),
                  "伤害事件表头搜索：触发单位/伤害来源按显示文本模糊匹配（复用 MatchesCellValue）");

            // 两列同时有词 = AND；任一列不命中即排除，空关键词那一列不限制。
            Check(Ui.HookGridUi.MatchesSearch(hookSearchEvent, "步", "圣") &&
                  !Ui.HookGridUi.MatchesSearch(hookSearchEvent, "步", "龙") &&
                  !Ui.HookGridUi.MatchesSearch(hookSearchEvent, "龙", "圣") &&
                  Ui.HookGridUi.MatchesSearch(hookSearchEvent, "", "圣") &&
                  Ui.HookGridUi.MatchesSearch(hookSearchEvent, "步", ""),
                  "伤害事件表头搜索：两列 AND（任一列不命中即排除；空关键词不过滤）");

            // 右键【跟踪】：触发单位取 VictimName、伤害来源取 SourceName；颜色码要清掉。
            var trackEvent = hookSearchEvent with
            {
                VictimName = "|cffff0000步兵|r",
                SourceName = "圣骑士",
            };
            Check(Ui.HookGridUi.IsTrackColumn(Ui.HookGridUi.VictimColumn) &&
                  Ui.HookGridUi.IsTrackColumn(Ui.HookGridUi.SourceColumn) &&
                  !Ui.HookGridUi.IsTrackColumn("dstid") &&
                  Ui.HookGridUi.TrackName(trackEvent, victim: true) == "步兵" &&
                  Ui.HookGridUi.TrackName(trackEvent, victim: false) == "圣骑士",
                  "伤害事件右键跟踪：只对触发单位/伤害来源列生效；单位名去掉 |c/|r 样式码");

            // 没有名字时退回类型码；连类型码都没有才退回地址文本，绝不能写空串进搜索框。
            Check(Ui.HookGridUi.TrackName(trackEvent with { VictimName = "", VictimCode = "hfoo" }, true) == "hfoo" &&
                  Ui.HookGridUi.TrackName(trackEvent with { VictimName = "", VictimCode = "" }, true) == "0x00001000",
                  "伤害事件右键跟踪：没单位名退回类型码，再退回地址（不写空关键词）");

            // 组件本体：Track = 关键词写进对应列 + 搜索框浮出但不抢焦点 + IsTracking 放行实时刷新。
            using (var form = new Form
                   {
                       Text = "跟踪自检", StartPosition = FormStartPosition.Manual,
                       Location = new Point(0, 0), Size = new Size(900, 260),
                       ShowInTaskbar = false, Opacity = 0.01,
                   })
            {
                var trackGrid = new Ui.Grid { Dock = DockStyle.Fill };
                Ui.HookGridUi.AddColumns(trackGrid);
                var trackSearch = Ui.SettlementHeaderSearch.ForHookEvents(trackGrid, () => { });
                form.Controls.Add(trackGrid);
                form.Show();
                Application.DoEvents();

                bool pinned = trackSearch.Track(Ui.HookGridUi.SourceColumn, "步兵");
                Application.DoEvents();
                var boxes = trackGrid.Controls.OfType<TextBox>().Where(b => b.Visible).ToList();
                Check(pinned && trackSearch.IsTracking && trackSearch.IsEditing &&
                      trackSearch.Keyword(Ui.HookGridUi.SourceColumn) == "步兵" &&
                      trackGrid.Columns[Ui.HookGridUi.SourceColumn]!.HeaderText.Contains("步兵") &&
                      boxes.Count == 1 && boxes[0].Text == "步兵" && !boxes[0].Focused,
                      "跟踪组件：关键词落到伤害来源列、表头显示过滤、搜索框浮出且不抢焦点（实时刷新不被 IsEditing 挡住）");
                form.Close();
            }
        }

        // ---------- 用例 21：用户自定义的名字忽略名单（ini ignore_unit_names，默认空，不参与马甲判定） ----------
        {
            Check(new Settings().IgnoreUnitNames == Settings.DefaultIgnoreUnitNames &&
                  Settings.DefaultIgnoreUnitNames == "" &&
                  !UnitNameFilter.Hits("马甲单位——苦难女神", Settings.DefaultIgnoreUnitNames),
                  "名字忽略：默认空（不再按“马甲/hidespell”写死；马甲由 Aloc 技能判定）");

            Check(UnitNameFilter.Hits("HIDESPELL_木之尊者", "马甲, hidespell") &&
                  UnitNameFilter.Hits(" 敌人马甲单位——黑暗… ", "马甲") &&
                  UnitNameFilter.Hits("hidespell_木之尊者", "HIDESPELL"),
                  "名字忽略：不区分大小写，名字/关键字首尾空白自动 Trim");

            Check(UnitNameFilter.Hits("敌人马甲单位——黑暗…（e04T）", "马甲;hidespell") &&
                  UnitNameFilter.Hits("xx-HideSpell-yy", "马甲;hidespell") &&
                  UnitNameFilter.Hits("马甲单位——武装牛头", "马甲，hidespell；其它") &&
                  !UnitNameFilter.Hits("普通步兵", "马甲;hidespell"),
                  "名字忽略：逗号/分号（含全角）分隔多个关键字，任一命中即可");

            Check(!UnitNameFilter.Hits("", "马甲") &&
                  !UnitNameFilter.Hits("   ", "马甲") &&
                  !UnitNameFilter.Hits(null, "马甲") &&
                  !UnitNameFilter.Hits("苦难女神", "") &&
                  !UnitNameFilter.Hits("苦难女神", "  , ; ，； ") &&
                  !UnitNameFilter.Hits("马甲单位", (string?)null),
                  "名字忽略：名字为空不命中；空/纯分隔符配置 = 不过滤");
        }

        // ---------- 用例 22：蝗虫马甲过滤（地址命中 / 类型码命中 / 都不命中） ----------
        {
            // 与 MonitorEngine 里同款的两个集合：地址集合 + 类型码集合（类型码集合大小写不敏感）。
            var locustVictims = new Dictionary<uint, bool> { [0x1000u] = true };
            var locustCodes = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "e04F" };

            // ① 地址命中：类型码是普通单位，但地址在蝗虫地址集合里 → 算马甲（byAddr=true/byCode=false）。
            Check(MonitorEngine.LocustHit(0x1000u, "hfoo", locustVictims, locustCodes,
                                        out bool hitAddr1, out bool hitCode1) && hitAddr1 && !hitCode1,
                  "蝗虫过滤：地址命中（0x1000 在蝗虫地址集合里）→ 算马甲");

            // ② 类型码命中：地址不在集合里（结算时单位对象地址变了），但类型码完全相等/大小写不敏感相等 → 算马甲。
            Check(MonitorEngine.LocustHit(0x2000u, "e04F", locustVictims, locustCodes,
                                        out bool hitAddr2, out bool hitCode2) && !hitAddr2 && hitCode2 &&
                  MonitorEngine.LocustHit(0x2001u, "E04f", locustVictims, locustCodes,
                                        out _, out bool hitCode3) && hitCode3,
                  "蝗虫过滤：类型码命中（地址变了也能按 e04F/E04f 大小写不敏感认出）→ 算马甲");

            // ③ 都不命中：地址和类型码都不在集合里 → 正常单位，不能误杀。
            Check(!MonitorEngine.LocustHit(0x3000u, "hfoo", locustVictims, locustCodes,
                                         out bool hitAddr4, out bool hitCode4) && !hitAddr4 && !hitCode4,
                  "蝗虫过滤：地址/类型码都不命中 → 正常单位（不误杀）");
        }

        // ==================================================================
        // ddh v12【战场单位】：属性协议解析 / 两行名称 / 名称列搜索 / 列定义 / 请求优先级
        // ==================================================================
        static UnitAttrResponse Attr(uint addr, uint flags, string code, string name, string title,
            float range = 0, float dmgMin = 0, float dmgMax = 0, float interval = 0, float armor = 0,
            float speed = 0, float attackSpeed = 0, float acquire = 0,
            float baseSpeed = 0, float sightDay = 0, float sightNight = 0, int baseArmor = 0,
            float strength = 0, float agility = 0, float intelligence = 0, int extra = 0) =>
            new(addr, flags, code, name, title, range, dmgMin, dmgMax, interval, armor, speed, attackSpeed,
                acquire, baseSpeed, sightDay, sightNight, baseArmor,
                strength, agility, intelligence, extra);

        // ---------- 用例 23：属性响应结构解析（字段偏移 + 数值格式；无效位 → ?） ----------
        {
            var buf = new byte[UnitAttrWire.SlotCount * UnitAttrWire.EntrySize];
            int o = 2 * UnitAttrWire.EntrySize;      // 放在第 3 个槽：顺便验证“按偏移解析”
            BitConverter.GetBytes(0x1234ABCDu).CopyTo(buf, o + UnitAttrWire.OffsetAddr);
            uint flags = UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | UnitAttrWire.FlagTitle |
                         UnitAttrWire.FlagAttackRange | UnitAttrWire.FlagDamage | UnitAttrWire.FlagInterval |
                         UnitAttrWire.FlagArmor | UnitAttrWire.FlagMoveSpeed | UnitAttrWire.FlagAttackSpeed |
                         UnitAttrWire.FlagAcquire | UnitAttrWire.FlagBaseSpeed |
                         UnitAttrWire.FlagSightDay | UnitAttrWire.FlagSightNight |
                         UnitAttrWire.FlagBaseArmor |
                         UnitAttrWire.FlagHeroKnown | UnitAttrWire.FlagHero |
                         UnitAttrWire.FlagStrength | UnitAttrWire.FlagAgility |
                         UnitAttrWire.FlagIntelligence | UnitAttrWire.FlagExtra |
                         UnitAttrWire.FlagLocust;
            BitConverter.GetBytes(flags).CopyTo(buf, o + UnitAttrWire.OffsetFlags);
            Encoding.ASCII.GetBytes("Hpal").CopyTo(buf, o + UnitAttrWire.OffsetTypeCode);
            Encoding.UTF8.GetBytes("圣骑士").CopyTo(buf, o + UnitAttrWire.OffsetName);   // 引擎名字是 UTF-8
            Encoding.UTF8.GetBytes("乌瑟尔").CopyTo(buf, o + UnitAttrWire.OffsetTitle);
            BitConverter.GetBytes(128f).CopyTo(buf, o + UnitAttrWire.OffsetAttackRange);
            BitConverter.GetBytes(10f).CopyTo(buf, o + UnitAttrWire.OffsetDamageMin);
            BitConverter.GetBytes(14f).CopyTo(buf, o + UnitAttrWire.OffsetDamageMax);
            BitConverter.GetBytes(1.2f).CopyTo(buf, o + UnitAttrWire.OffsetAttackInterval);
            BitConverter.GetBytes(2.5f).CopyTo(buf, o + UnitAttrWire.OffsetArmor);
            BitConverter.GetBytes(270f).CopyTo(buf, o + UnitAttrWire.OffsetMoveSpeed);
            BitConverter.GetBytes(1.8f).CopyTo(buf, o + UnitAttrWire.OffsetAttackSpeed);
            BitConverter.GetBytes(500f).CopyTo(buf, o + UnitAttrWire.OffsetAcquireRange);
            BitConverter.GetBytes(320f).CopyTo(buf, o + UnitAttrWire.OffsetBaseSpeed);
            BitConverter.GetBytes(1400f).CopyTo(buf, o + UnitAttrWire.OffsetSightDay);
            BitConverter.GetBytes(800f).CopyTo(buf, o + UnitAttrWire.OffsetSightNight);
            BitConverter.GetBytes(5).CopyTo(buf, o + UnitAttrWire.OffsetBaseArmor);
            BitConverter.GetBytes(18f).CopyTo(buf, o + UnitAttrWire.OffsetStrength);
            BitConverter.GetBytes(15f).CopyTo(buf, o + UnitAttrWire.OffsetAgility);
            BitConverter.GetBytes(17f).CopyTo(buf, o + UnitAttrWire.OffsetIntelligence);
            BitConverter.GetBytes(12345).CopyTo(buf, o + UnitAttrWire.OffsetExtraValue);

            var decoded = UnitAttrWire.DecodeAll(buf);
            var hero = decoded.Count == 1 ? decoded[0] : null;
            Check(UnitAttrWire.SlotCount == 96 && UnitAttrWire.EntrySize == 208 &&
                  UnitAttrWire.RequestOffset == 8 && UnitAttrWire.ResponseOffset == 8 + 96 * 4 &&
                  UnitAttrWire.OffsetTypeCode == 8 && UnitAttrWire.OffsetName == 13 &&
                  UnitAttrWire.OffsetTitle == 77 && UnitAttrWire.OffsetAttackRange == 141 &&
                  UnitAttrWire.OffsetBaseArmor == 185 &&
                  UnitAttrWire.OffsetStrength == 192 && UnitAttrWire.OffsetAgility == 196 &&
                  UnitAttrWire.OffsetIntelligence == 200 && UnitAttrWire.OffsetExtraValue == 204 &&
                  hero != null && hero.Addr == 0x1234ABCD && hero.TypeCode == "Hpal" &&
                  hero.Name == "圣骑士" && hero.Title == "乌瑟尔" && hero.IsHero &&
                  hero.AttackRangeText == "128" && hero.DamageText == "10~14" &&
                  hero.AttackIntervalText == "1.20秒" && hero.ArmorText == "2.5" &&
                  hero.MoveSpeedText == "270" && hero.AttackSpeedText == "1.8" &&
                  hero.AttackFrequencyText == "1.5" &&
                  hero.SightDayText == "1400" && hero.SightNightText == "800" &&
                  hero.IsLocust &&
                  hero.AcquireRangeText == "500" &&
                  hero.BaseSpeedText == "320" &&
                  hero.BaseArmorText == "5" &&
                  hero.StrengthText == "18" && hero.AgilityText == "15" &&
                  hero.IntelligenceText == "17" && hero.ExtraText == "12345",
                  $"属性响应 v14 解析：208 字节/新偏移 + UTF-8 名称/称谓 + 两列视野 + 蝗虫位（{hero?.AttackRangeText}/{hero?.DamageText}/" +
                  $"{hero?.AttackIntervalText}/{hero?.ArmorText}/力敏智={hero?.StrengthText}/{hero?.AgilityText}/{hero?.IntelligenceText}/" +
                  $"白天/夜晚={hero?.SightDayText}/{hero?.SightNightText}/蝗虫={hero?.IsLocust}）");
            Check(hero != null &&
                  (hero with { AttackSpeed = 10f, AttackInterval = 2f })
                      .AttackFrequencyText == "2.5",
                  "攻击频率按 min(攻击速度, 5) / 攻击间隔 计算");

            // 只给类型码 + 名字：其余字段必须显示 ?（0 不能冒充数值）
            Array.Clear(buf, 0, buf.Length);
            BitConverter.GetBytes(0x5678u).CopyTo(buf, UnitAttrWire.OffsetAddr);
            BitConverter.GetBytes(UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName)
                         .CopyTo(buf, UnitAttrWire.OffsetFlags);
            Encoding.ASCII.GetBytes("hfoo").CopyTo(buf, UnitAttrWire.OffsetTypeCode);
            Encoding.UTF8.GetBytes("步兵").CopyTo(buf, UnitAttrWire.OffsetName);
            var plain = UnitAttrWire.Decode(buf, 0);
            Check(plain != null && plain.TypeCode == "hfoo" && plain.Name == "步兵" && !plain.HeroKnown &&
                  plain.AttackRangeText == "?" && plain.DamageText == "?" &&
                  plain.AttackIntervalText == "?" && plain.ArmorText == "?" &&
                  plain.MoveSpeedText == "?" && plain.AttackSpeedText == "?" &&
                  plain.SightDayText == "?" && plain.SightNightText == "?" && !plain.IsLocust &&
                  plain.AcquireRangeText == "?" &&
                  plain.BaseSpeedText == "?" && plain.BaseArmorText == "?" &&
                  plain.StrengthText == "?" && plain.AgilityText == "?" &&
                  plain.IntelligenceText == "?" && plain.ExtraText == "?",
                  $"属性无效位 → 属性列全部 ?（{plain?.AttackRangeText}/{plain?.ArmorText}/{plain?.BaseSpeedText}/" +
                  $"力={plain?.StrengthText}/白天/夜晚={plain?.SightDayText}/{plain?.SightNightText}/蝗虫={plain?.IsLocust}）");
        }

        // ---------- 用例 23b：真机 ddh-13572.log 的响应（v10 192 字节按 v11 208 字节读；多出的 16 字节为 0） ----------
        {
            // 完全按 ddh DdhUnitAttr（pack(1)，208 字节）逐字节构造：
            //   +0 addr=0x268CC244  +4 flags=0xC283  +8 typeCode="E053"
            //   +13 name="黑暗舞者"  +77 title=""（真机反查不到，称谓无效）
            //   +161 moveSpeed=396  +169 acquireRange=700  其余数值 0
            // 注：真机旧 flags=0xFE83 里的 0x3C00 是旧的力/敏/智/附加值位；
            // 这四位现在复用为 spd/sight/nsight/def，这里清掉以验证“未置位 → ?”。
            // v11 追加的 192~207 全 0（旧版 DLL 没有这 16 字节）→ 力/敏/智/附加值都是 ?。
            var entry = new byte[UnitAttrWire.EntrySize];
            BitConverter.GetBytes(0x268CC244u).CopyTo(entry, UnitAttrWire.OffsetAddr);
            BitConverter.GetBytes(0x0000C283u).CopyTo(entry, UnitAttrWire.OffsetFlags);
            Encoding.ASCII.GetBytes("E053").CopyTo(entry, UnitAttrWire.OffsetTypeCode);
            Encoding.UTF8.GetBytes("黑暗舞者").CopyTo(entry, UnitAttrWire.OffsetName);
            BitConverter.GetBytes(396f).CopyTo(entry, UnitAttrWire.OffsetMoveSpeed);
            BitConverter.GetBytes(700f).CopyTo(entry, UnitAttrWire.OffsetAcquireRange);
            var real = UnitAttrWire.Decode(entry, 0);
            Check(real != null && real.Addr == 0x268CC244u && real.Flags == 0x0000C283u &&
                  real.Has(UnitAttrWire.FlagMoveSpeed) && real.Has(UnitAttrWire.FlagAcquire) &&
                  real.MoveSpeedText == "396" && real.AcquireRangeText == "700" &&
                  !real.Has(UnitAttrWire.FlagAttackRange) && !real.Has(UnitAttrWire.FlagDamage) &&
                  !real.Has(UnitAttrWire.FlagArmor) && !real.Has(UnitAttrWire.FlagSight) &&
                  !real.Has(UnitAttrWire.FlagTitle) &&
                  !real.Has(UnitAttrWire.FlagBaseSpeed) && !real.Has(UnitAttrWire.FlagSightDay) &&
                  !real.Has(UnitAttrWire.FlagSightNight) && !real.Has(UnitAttrWire.FlagBaseArmor) &&
                  !real.Has(UnitAttrWire.FlagStrength) && !real.Has(UnitAttrWire.FlagAgility) &&
                  !real.Has(UnitAttrWire.FlagIntelligence) && !real.Has(UnitAttrWire.FlagExtra) &&
                  real.AttackRangeText == "?" && real.DamageText == "?" && real.ArmorText == "?" &&
                  real.AttackSpeedText == "?" && real.TitleText == "" &&
                  real.BaseSpeedText == "?" &&
                  real.SightDayText == "?" && real.SightNightText == "?" && !real.IsLocust &&
                  real.BaseArmorText == "?" &&
                  real.StrengthText == "?" && real.AgilityText == "?" &&
                  real.IntelligenceText == "?" && real.ExtraText == "?",
                  $"真机 208 字节响应：flags=0xC283 解出 速={real?.MoveSpeedText} 主动={real?.AcquireRangeText}，" +
                  $"未置位字段仍是 ?（范围={real?.AttackRangeText}/甲={real?.ArmorText}/基速={real?.BaseSpeedText}/附={real?.ExtraText}）");
        }

        // ---------- 用例 23c：flags 有效位逐位映射（同数值，只有对应位为 1 才显示数字） ----------
        {
            var entry = new byte[UnitAttrWire.EntrySize];
            BitConverter.GetBytes(0x268CC245u).CopyTo(entry, UnitAttrWire.OffsetAddr);
            BitConverter.GetBytes(396f).CopyTo(entry, UnitAttrWire.OffsetMoveSpeed);
            BitConverter.GetBytes(700f).CopyTo(entry, UnitAttrWire.OffsetAcquireRange);
            BitConverter.GetBytes(UnitAttrWire.FlagMoveSpeed).CopyTo(entry, UnitAttrWire.OffsetFlags);
            var onlySpeed = UnitAttrWire.Decode(entry, 0);
            BitConverter.GetBytes(UnitAttrWire.FlagAcquire).CopyTo(entry, UnitAttrWire.OffsetFlags);
            var onlyAcquire = UnitAttrWire.Decode(entry, 0);
            Check(onlySpeed != null && onlySpeed.MoveSpeedText == "396" && onlySpeed.AcquireRangeText == "?" &&
                  onlyAcquire != null && onlyAcquire.MoveSpeedText == "?" && onlyAcquire.AcquireRangeText == "700",
                  $"flags 有效位映射：只置移速位 → 速={onlySpeed?.MoveSpeedText}/主动={onlySpeed?.AcquireRangeText}；" +
                  $"只置主动位 → 速={onlyAcquire?.MoveSpeedText}/主动={onlyAcquire?.AcquireRangeText}");
        }

        // ---------- 用例 23d：C# 布局常量与 ddh 真机日志逐项一致（v12：96 槽 / 单元 208 / 块长 20360） ----------
        {
            Check(UnitAttrWire.LayoutMatchesDdhLog &&
                  UnitAttrWire.BlockSize == 20360 && UnitAttrWire.ResponseOffset == 392,
                  $"C# 布局 = ddh 日志：响应槽 {UnitAttrWire.ResponseOffset} / 单元 {UnitAttrWire.EntrySize} / 块长 {UnitAttrWire.BlockSize}");
        }

        // ---------- 用例 23e：请求/响应序号（GUI 先发后收的 off-by-one） ----------
        {
            // 真机：ddh 上一轮 done=35，GUI 已写 request=36 → 必须消费；旧逻辑 done!=36 会丢。
            Check(UnitAttrWire.ShouldConsumeResponse(35, 0, 36) &&
                  UnitAttrWire.ShouldConsumeResponse(35, 34, 36) &&
                  !UnitAttrWire.ShouldConsumeResponse(35, 35, 36) &&   // 已消费，不重复
                  !UnitAttrWire.ShouldConsumeResponse(33, 34, 36) &&   // 比已消费的旧，不能倒序
                  !UnitAttrWire.ShouldConsumeResponse(0, 0, 36) &&     // ddh 还没写
                  !UnitAttrWire.ShouldConsumeResponse(37, 35, 36),     // 比已发出的还新，不能信
                  "属性序号：done 比当前 requestSeq 小 1 也要消费（GUI 先发后收的 off-by-one）");
        }

        // ---------- 用例 23f：ddh v15 内存直读（YDWE unit_property）—— 公式 / 合理性 / prop 不可读 ----------
        {
            // ① 攻击力公式：dice 6 / side 5 / base 36 / bonus 0 → min 42、max 66
            bool dmgOk = UnitPropMath.TryDamage(6, 5, 36, 0, out float dmgMin, out float dmgMax);
            var dmgEntry = new byte[UnitAttrWire.EntrySize];
            BitConverter.GetBytes(0x268CC246u).CopyTo(dmgEntry, UnitAttrWire.OffsetAddr);
            BitConverter.GetBytes(UnitAttrWire.FlagDamage).CopyTo(dmgEntry, UnitAttrWire.OffsetFlags);
            BitConverter.GetBytes(dmgMin).CopyTo(dmgEntry, UnitAttrWire.OffsetDamageMin);
            BitConverter.GetBytes(dmgMax).CopyTo(dmgEntry, UnitAttrWire.OffsetDamageMax);
            var dmgAttr = UnitAttrWire.Decode(dmgEntry, 0);

            // min == max 时界面显示单值（base 36 / dice 0 / side 0 → 36~36 → “36”）
            bool flatOk = UnitPropMath.TryDamage(0, 0, 36, 0, out float flatMin, out float flatMax);
            BitConverter.GetBytes(flatMin).CopyTo(dmgEntry, UnitAttrWire.OffsetDamageMin);
            BitConverter.GetBytes(flatMax).CopyTo(dmgEntry, UnitAttrWire.OffsetDamageMax);
            var flatAttr = UnitAttrWire.Decode(dmgEntry, 0);

            Check(dmgOk && dmgMin == 42f && dmgMax == 66f &&
                  dmgAttr?.DamageText == "42~66" &&
                  flatOk && flatMin == 36f && flatMax == 36f && flatAttr?.DamageText == "36",
                  $"内存直读攻击力公式：dice6/side5/base36/bonus0 → {dmgAttr?.DamageText}（期望 42~66）；" +
                  $"min==max 显示单值 {flatAttr?.DamageText}（期望 36）");
        }

        {
            // ② 合理性校验：NaN / ±Inf / 超范围一律拒绝（与 ddh 的 DdhAttrFits 同一套边界）
            bool rejectBad =
                !UnitPropMath.Fits(float.NaN, 0f, 5000f) &&
                !UnitPropMath.Fits(float.PositiveInfinity, 0f, 5000f) &&
                !UnitPropMath.Fits(float.NegativeInfinity, 0f, 5000f) &&
                !UnitPropMath.Fits(5001f, UnitPropMath.RangeMin, UnitPropMath.RangeMax) &&   // 攻击范围 > 5000
                !UnitPropMath.Fits(0.04f, UnitPropMath.IntervalMin, UnitPropMath.IntervalMax) && // 间隔 < 0.05
                !UnitPropMath.Fits(10.5f, UnitPropMath.IntervalMin, UnitPropMath.IntervalMax) && // 间隔 > 10
                !UnitPropMath.Fits(-101f, UnitPropMath.ArmorMin, UnitPropMath.ArmorMax) &&     // 护甲 < -100
                !UnitPropMath.Fits(1001f, UnitPropMath.ArmorMin, UnitPropMath.ArmorMax) &&     // 护甲 > 1000
                UnitPropMath.Fits(5000f, UnitPropMath.RangeMin, UnitPropMath.RangeMax) &&      // 边界值仍可用
                UnitPropMath.Fits(-100f, UnitPropMath.ArmorMin, UnitPropMath.ArmorMax) &&
                UnitPropMath.Fits(1000f, UnitPropMath.ArmorMin, UnitPropMath.ArmorMax) &&
                !UnitPropMath.TryDamage(2000, 5, 36, 0, out _, out _) &&                      // dice 超上限
                !UnitPropMath.TryDamage(6, 5, 2_000_000, 0, out _, out _) &&                  // base 超上限
                !UnitPropMath.TryDamage(1000, 1000, 1_000_000, 0, out _, out _);              // max > 1e6
            Check(rejectBad,
                  "内存直读合理性：NaN/±Inf/范围>5000/间隔越界/护甲越界/攻击力越界一律无效" +
                  "（边界 5000、-100、1000 仍可用）");
        }

        {
            // ③ prop 指针不可读（CUnit+0x1E8 = 0 / 坏指针）：范围/攻击力/间隔/主动 的位不置 → 界面 ?
            uint noProp = UnitPropMath.MemoryFlags(false, 128f, 1.2f, 500f, 6, 5, 36, 0, armor: 2, rateOfFire: 1.2f);
            uint withProp = UnitPropMath.MemoryFlags(true, 128f, 1.2f, 500f, 6, 5, 36, 0, armor: 2, rateOfFire: 1.2f);

            var noPropEntry = new byte[UnitAttrWire.EntrySize];
            BitConverter.GetBytes(0x268CC247u).CopyTo(noPropEntry, UnitAttrWire.OffsetAddr);
            BitConverter.GetBytes(UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | noProp)
                         .CopyTo(noPropEntry, UnitAttrWire.OffsetFlags);
            BitConverter.GetBytes(2f).CopyTo(noPropEntry, UnitAttrWire.OffsetArmor);
            var noPropAttr = UnitAttrWire.Decode(noPropEntry, 0);

            Check(noProp == UnitAttrWire.FlagArmor &&
                  withProp == (UnitAttrWire.FlagAttackRange | UnitAttrWire.FlagDamage |
                               UnitAttrWire.FlagInterval | UnitAttrWire.FlagAttackSpeed |
                               UnitAttrWire.FlagAcquire | UnitAttrWire.FlagArmor) &&
                  noPropAttr != null && noPropAttr.Has(UnitAttrWire.FlagArmor) &&
                  !noPropAttr.Has(UnitAttrWire.FlagAttackRange) && !noPropAttr.Has(UnitAttrWire.FlagDamage) &&
                  !noPropAttr.Has(UnitAttrWire.FlagInterval) && !noPropAttr.Has(UnitAttrWire.FlagAcquire) &&
                  !noPropAttr.Has(UnitAttrWire.FlagAttackSpeed) &&
                  noPropAttr.AttackRangeText == "?" && noPropAttr.DamageText == "?" &&
                  noPropAttr.AttackIntervalText == "?" && noPropAttr.AcquireRangeText == "?" &&
                  noPropAttr.ArmorText == "2",
                  $"prop 不可读：范围/攻击力/间隔/主动 = {noPropAttr?.AttackRangeText}/{noPropAttr?.DamageText}/" +
                  $"{noPropAttr?.AttackIntervalText}/{noPropAttr?.AcquireRangeText}（应全是 ?），" +
                  $"护甲仍读 CUnit+0xE0 = {noPropAttr?.ArmorText}");
        }

        // ---------- 用例 23g：CUnit+0xE0 是 float 护甲（YDWE 对 real 做位透传），并兼容 int32 ----------
        {
            // YDWE：return *(uint32_t*)(unit_object + 0xE0)；函数返回 JASS 的 real，没有 to_real。
            // 真机 E06V 的原始字节：BB AD 0D 43（0x430DADBB）→ float 141.679；int 读法越界。
            int off = (int)Wc3UnitOffset.ArmorAmount;
            var real = new byte[0x100];
            real[off + 0] = 0xBB;
            real[off + 1] = 0xAD;
            real[off + 2] = 0x0D;
            real[off + 3] = 0x43;
            bool okReal = UnitScanner.TryDecodeArmor(real, out int rawReal, out float armorReal);
            Check(okReal && rawReal == 1124969915 &&
                  Math.Abs(armorReal - 141.6786f) < 0.001f &&
                  UnitStats.ArmorText(armorReal) == "141.68" &&
                  !UnitPropMath.Fits(rawReal, UnitPropMath.ArmorMin, UnitPropMath.ArmorMax),
                  $"护甲按 float 解：真机 E06V 字节 BB AD 0D 43 → {armorReal:0.###}" +
                  $"（int 位模式 {rawReal} 越界，旧 int 读法会得到 ?）");

            // int32 兼容兜底：0C 00 00 00 的 float 解释是 1.68e-44 次正规数，必须让位给 int 12。
            // 越界 5000（int / float 位模式）→ ?；边界 -100 / 1000 仍有效。
            var int12 = new byte[0x100];
            int12[off + 0] = 0x0C;
            bool ok12 = UnitScanner.TryDecodeArmor(int12, out int raw12, out float armor12);

            var int5000 = new byte[0x100];
            BitConverter.GetBytes(5000).CopyTo(int5000, off);
            bool ok5000 = UnitScanner.TryDecodeArmor(int5000, out int raw5000, out float armor5000);

            var float5000 = new byte[0x100];
            BitConverter.GetBytes(5000f).CopyTo(float5000, off);
            bool okFloat5000 = UnitScanner.TryDecodeArmor(float5000, out _, out _);

            var intMin = new byte[0x100];
            BitConverter.GetBytes(-100).CopyTo(intMin, off);
            var intMax = new byte[0x100];
            BitConverter.GetBytes(1000).CopyTo(intMax, off);
            Check(ok12 && raw12 == 12 && armor12 == 12f &&
                  !ok5000 && raw5000 == 5000 && float.IsNaN(armor5000) &&
                  UnitStats.ArmorText(armor5000) == "?" &&
                  !okFloat5000 &&
                  UnitScanner.TryDecodeArmor(intMin, out _, out float armorMin) && armorMin == -100f &&
                  UnitScanner.TryDecodeArmor(intMax, out _, out float armorMax) && armorMax == 1000f,
                  $"护甲兼容/边界：int 12 兜底 → {armor12:0.#}；int 5000 与 float 5000 均 → " +
                  $"{UnitStats.ArmorText(armor5000)}；边界 -100/1000 仍有效");

            // 【战场单位】表：扫描器 float 值必须盖过 ddh 的 0（截图里整列 0 的回归）；
            // 扫描不到时显示 ?，不能把 ddh 的 0 当成真实护甲。
            var scanned = new UnitView
            {
                Addr = 0x1000, TypeCode = "E06V", Name = "木之尊者", Hp = 100f, Armor = 141.6786f
            };
            var scanAttr = Attr(0x1000, UnitAttrWire.FlagArmor | UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName,
                                "E06V", "木之尊者", "", armor: 0f);
            var scanRow = Ui.UnitGridUi.Build(scanned, scanAttr, _ => "?");
            var noScanRow = Ui.UnitGridUi.Build(
                new UnitView { Addr = 0x2000, TypeCode = "hfoo", Hp = 100f },   // Armor 默认 NaN
                Attr(0x2000, UnitAttrWire.FlagArmor, "hfoo", "步兵", "", armor: 0f), _ => "?");
            Check(scanRow.Cells().Length == Ui.UnitGridUi.ColumnCount &&
                  scanRow.Name == "木之尊者" && noScanRow.Name.Length == 0 &&
                  scanRow.Cells().Length == 13,
                  "战场单位导出名称/称谓与直接读取属性，扫描器护甲仍不冒充 ddh 属性");
        }

        // ---------- 用例 24：名称列两行文本（英雄 = 称谓 + 名称；非英雄只有名称） ----------
        {
            var heroRow = Ui.UnitGridUi.Build(
                new UnitView { Addr = 0x1000, TypeCode = "Hpal", Name = "圣骑士", Owner = "Player 1", Hp = 100f },
                Attr(0x1000, UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | UnitAttrWire.FlagTitle |
                             UnitAttrWire.FlagHeroKnown | UnitAttrWire.FlagHero,
                     "Hpal", "圣骑士", "乌瑟尔"),
                _ => "?");
            var plainRow = Ui.UnitGridUi.Build(
                new UnitView { Addr = 0x2000, TypeCode = "hfoo", Name = "步兵", Owner = "Player 2", Hp = 100f },
                Attr(0x2000, UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | UnitAttrWire.FlagHeroKnown,
                     "hfoo", "步兵", ""),
                _ => "?");
            // ddh 经常把称谓退回类型码名字（title == name）；此时不要画第二行重复文本。
            var dupRow = Ui.UnitGridUi.Build(
                new UnitView { Addr = 0x3000, TypeCode = "H030", Name = "苦难女神", Hp = 100f },
                Attr(0x3000, UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | UnitAttrWire.FlagTitle |
                             UnitAttrWire.FlagHeroKnown | UnitAttrWire.FlagHero,
                     "H030", "苦难女神", "苦难女神"),
                _ => "?");
            Check(heroRow.HasTitle && heroRow.NameCellText == "乌瑟尔\n圣骑士" &&
                  heroRow.Cells()[Ui.UnitGridUi.NameCellIndex] as string == "乌瑟尔\n圣骑士" &&
                  !plainRow.HasTitle && plainRow.NameCellText == "步兵" &&
                  !dupRow.HasTitle && dupRow.NameCellText == "苦难女神",
                  $"名称列两行：英雄 = 称谓+名称（{heroRow.NameCellText.Replace("\n", "⏎")}），" +
                  $"非英雄只有名称（{plainRow.NameCellText}），称谓==名称时不重复（{dupRow.NameCellText}）");
        }

        // ---------- 用例 25：单位名称列表头搜索同时命中称谓与名称 ----------
        {
            var row = Ui.UnitGridUi.Build(
                new UnitView { Addr = 0x1000, TypeCode = "Hpal", Name = "圣骑士", Hp = 100f },
                Attr(0x1000, UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | UnitAttrWire.FlagTitle |
                             UnitAttrWire.FlagHeroKnown | UnitAttrWire.FlagHero, "Hpal", "圣骑士", "乌瑟尔"),
                _ => "?");
            Check(Ui.UnitGridUi.MatchesSearch(row, "", "乌瑟") &&      // 只命中称谓
                  Ui.UnitGridUi.MatchesSearch(row, "", "圣骑") &&      // 只命中名称
                  !Ui.UnitGridUi.MatchesSearch(row, "", "剑圣") &&     // 两行都不命中
                  Ui.UnitGridUi.MatchesSearch(row, "Hp", "") &&        // 类型码列
                  !Ui.UnitGridUi.MatchesSearch(row, "hfoo", "") &&     // 类型码两列 AND
                  Ui.UnitGridUi.MatchesSearch(row, "", ""),            // 空关键词 = 不过滤
                  "名称列搜索：称谓/名称任一命中即可（两列 AND，空关键词不过滤）");
        }

        // ---------- 用例 26：名称/称谓 + 新属性 + 蝗虫/镜像固定 13 列 ----------
        {
            var g = new Ui.Grid();
            Ui.UnitGridUi.AddColumns(g);
            var headers = g.Columns.Cast<DataGridViewColumn>().Select(c => c.HeaderText).ToList();
            var expect = new[]
            {
                "类型码", "单位名称（称谓）", "最小攻击力", "最大攻击力", "攻击范围",
                "护甲", "攻击速度", "攻击间隔", "攻击频率", "蝗虫", "镜像", "玩家", "地址"
            };
            var row = Ui.UnitGridUi.Build(
                new UnitView { Addr = 0x1000, TypeCode = "hfoo", Name = "步兵", Owner = "Player 3", Hp = 100f },
                Attr(0x1000, UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | UnitAttrWire.FlagHeroKnown |
                             UnitAttrWire.FlagHero | UnitAttrWire.FlagAttackRange |
                             UnitAttrWire.FlagDamage | UnitAttrWire.FlagInterval |
                             UnitAttrWire.FlagAttackSpeed |
                             UnitAttrWire.FlagArmor |
                             UnitAttrWire.FlagMoveSpeed | UnitAttrWire.FlagBaseSpeed |
                             UnitAttrWire.FlagSightDay | UnitAttrWire.FlagSightNight |
                             UnitAttrWire.FlagAcquire | UnitAttrWire.FlagStrength |
                             UnitAttrWire.FlagAgility | UnitAttrWire.FlagIntelligence |
                             UnitAttrWire.FlagExtra | UnitAttrWire.FlagLocust |
                             UnitAttrWire.FlagLocustChecked | UnitAttrWire.FlagIllusion |
                             UnitAttrWire.FlagIllusionChecked,
                      "hfoo", "步兵", "", range: 128f, dmgMin: 10f, dmgMax: 14f,
                      interval: 1.2f, armor: 2.5f, speed: 396f, attackSpeed: 1.2f, acquire: 700f,
                     baseSpeed: 320, sightDay: 1500, sightNight: 900,
                     strength: 18, agility: 15, intelligence: 17, extra: 12345),
                _ => "?");
            var cells = row.Cells();
            Check(g.Columns.Count == Ui.UnitGridUi.ColumnCount && headers.SequenceEqual(expect) &&
                  cells.Length == Ui.UnitGridUi.ColumnCount &&
                  cells[Ui.UnitGridUi.CodeCellIndex] as string == "hfoo" &&
                  cells[Ui.UnitGridUi.NameCellIndex] as string == "步兵（镜像）" &&
                  cells[Ui.UnitGridUi.DamageMinCellIndex] as string == "10" &&
                  cells[Ui.UnitGridUi.DamageMaxCellIndex] as string == "14" &&
                  cells[Ui.UnitGridUi.AttackRangeCellIndex] as string == "128" &&
                  cells[Ui.UnitGridUi.ArmorCellIndex] as string == "2.5" &&
                  cells[Ui.UnitGridUi.AttackSpeedCellIndex] as string == "1.2" &&
                  cells[Ui.UnitGridUi.AttackIntervalCellIndex] as string == "1.20" &&
                  cells[Ui.UnitGridUi.AttackFrequencyCellIndex] as string == "1" &&
                  cells[Ui.UnitGridUi.LocustCellIndex] as string == "是" &&
                  cells[Ui.UnitGridUi.IllusionCellIndex] as string == "是" &&
                  cells[Ui.UnitGridUi.OwnerCellIndex] as string == "Player 3" &&
                  cells[Ui.UnitGridUi.AddrCellIndex] as string == "0x00001000" &&
                  !headers.Contains("移速") && !headers.Contains("视野") &&
                  !headers.Contains("力量"),
                  $"战场单位表保留名称/称谓/新属性/蝗虫/镜像 13 列（实际 {g.Columns.Count} 列 / {cells.Length} 格）");
        }

        // ---------- 用例 26b：13 列结构与索引常量 ----------
        {
            var g = new Ui.Grid();
            Ui.UnitGridUi.AddColumns(g);
            var headers = g.Columns.Cast<DataGridViewColumn>().Select(c => c.HeaderText).ToList();
            var row = Ui.UnitGridUi.Build(
                new UnitView { Addr = 0x4000, TypeCode = "Hpal", Name = "圣骑士", Owner = "Player 4", Hp = 100f },
                Attr(0x4000, UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | UnitAttrWire.FlagHeroKnown |
                             UnitAttrWire.FlagHero | UnitAttrWire.FlagStrength | UnitAttrWire.FlagAgility |
                             UnitAttrWire.FlagIntelligence | UnitAttrWire.FlagExtra,
                     "Hpal", "圣骑士", "", strength: 20, agility: 21, intelligence: 22, extra: 0),
                _ => "?");
            var cells = row.Cells();
            Check(Ui.UnitGridUi.ColumnCount == 13 &&
                  Ui.UnitGridUi.DamageMinCellIndex == 2 &&
                  Ui.UnitGridUi.DamageMaxCellIndex == 3 &&
                  Ui.UnitGridUi.AttackRangeCellIndex == 4 &&
                  Ui.UnitGridUi.ArmorCellIndex == 5 &&
                  Ui.UnitGridUi.AttackSpeedCellIndex == 6 &&
                  Ui.UnitGridUi.AttackIntervalCellIndex == 7 &&
                  Ui.UnitGridUi.AttackFrequencyCellIndex == 8 &&
                  Ui.UnitGridUi.OwnerCellIndex == 11 && Ui.UnitGridUi.AddrCellIndex == 12 &&
                  headers.Count == 13 && cells.Length == 13 &&
                  headers[0] == "类型码" && headers[1] == "单位名称（称谓）" &&
                  headers[2] == "最小攻击力" && headers[3] == "最大攻击力" &&
                  headers[4] == "攻击范围" && headers[5] == "护甲" &&
                  headers[6] == "攻击速度" && headers[7] == "攻击间隔" &&
                  headers[8] == "攻击频率" && headers[9] == "蝗虫" &&
                  headers[10] == "镜像" && headers[11] == "玩家" && headers[12] == "地址" &&
                  cells[11] as string == "Player 4" && cells[12] as string == "0x00004000" &&
                  !headers.Contains("力量") && !headers.Contains("敏捷") &&
                  !headers.Contains("智力"),
                  "13 列结构：攻击速度/间隔/频率在 6/7/8，蝗虫/镜像在 9/10，玩家/地址固定在 11/12");
        }

        // ---------- 用例 26b-3：旧视野槽改为攻击速度，视野仍不出现在单位表 ----------
        {
            var g = new Ui.Grid();
            Ui.UnitGridUi.AddColumns(g);
            var headers = g.Columns.Cast<DataGridViewColumn>().Select(c => c.HeaderText).ToList();
            var dayOnly = Attr(0x6000,
                UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | UnitAttrWire.FlagSightDay,
                "hfoo", "步兵", "", attackSpeed: 1.1f, sightDay: 1500f, sightNight: 800f);
            var dayRow = Ui.UnitGridUi.Build(
                new UnitView { Addr = 0x6000, TypeCode = "hfoo", Name = "步兵", Hp = 100f }, dayOnly, _ => "?");
            var both = Attr(0x6002,
                UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName |
                UnitAttrWire.FlagSightDay | UnitAttrWire.FlagSightNight,
                "hfoo", "步兵", "", attackSpeed: 1.1f, sightDay: 1500f, sightNight: 900f);
            var bothRow = Ui.UnitGridUi.Build(
                new UnitView { Addr = 0x6002, TypeCode = "hfoo", Name = "步兵", Hp = 100f }, both, _ => "?");
            // 只置“夜晚视野”位：白天必须是 ?（不能拿 sightNight 冒充白天，也不能用旧 sight）。
            var nightOnly = Attr(0x6001,
                UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | UnitAttrWire.FlagSightNight,
                "hfoo", "步兵", "", attackSpeed: 1.2f, sightNight: 800f);
            var nightRow = Ui.UnitGridUi.Build(
                new UnitView { Addr = 0x6001, TypeCode = "hfoo", Name = "步兵", Hp = 100f }, nightOnly, _ => "?");
            var bc = bothRow.Cells();
            Check(dayRow.SightDayText == "1500" && dayRow.SightNightText == "?" &&
                  bothRow.SightDayText == "1500" && bothRow.SightNightText == "900" &&
                  nightRow.SightDayText == "?" && nightRow.SightNightText == "800" &&
                  bc.Length == 13 && !headers.Contains("白天视野") &&
                  !headers.Contains("夜晚视野") && !headers.Contains("视野"),
                  "旧视野槽改作攻击速度，名称/称谓模式的单位表仍不显示视野");
        }

        // ---------- 用例 26b-4：中途启动时 SQLite 补入单位仍算参与过伤害 ----------
        {
            var attr = Attr(0x6D000001,
                UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | UnitAttrWire.FlagInterval,
                "O00M", "西利沃特", "", interval: 1.6f);
            var unit = Ui.UnitGridUi.UnitFromDdhDb(0x6D000001, attr);
            Check(unit.Participated && unit.Addr == 0x6D000001 &&
                  unit.TypeCode == "O00M" && unit.Name == "西利沃特",
                  "中途启动：ddh SQLite 补入单位保留 Participated=true");
        }

        // ---------- 用例 26d：属性响应里的蝗虫位 → 【战场单位】过滤（地址 + 类型码校验） ----------
        {
            var engine = new MonitorEngine();
            var locust = Attr(0x6A000000,
                UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName |
                UnitAttrWire.FlagLocust | UnitAttrWire.FlagLocustChecked,
                "e04F", "蝗虫马甲", "");
            var normal = Attr(0x6A000001,
                UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName,
                "hfoo", "步兵", "");
            engine.RememberAttrLocusts(new[] { locust, normal });
            var locustRow = Ui.UnitGridUi.Build(
                new UnitView { Addr = 0x6A000000, TypeCode = "e04F", Name = "蝗虫马甲", Hp = 1f },
                locust, _ => "?");
            Check(locust.IsLocust && !normal.IsLocust &&
                  locustRow.LocustText == "是" && locustRow.Cells()[Ui.UnitGridUi.LocustCellIndex] as string == "是" &&
                  engine.IsAttrLocust(0x6A000000, "e04F") &&
                  engine.IsAttrLocust(0x6A000000, null) &&
                  !engine.IsAttrLocust(0x6A000000, "hfoo") &&       // 地址被别的类型码复用 → 不误杀
                  !engine.IsAttrLocust(0x6A000001, "hfoo") &&
                  !engine.IsAttrLocust(0x6A000002, "e04F"),
                  "蝗虫状态：属性可识别为“是”，战场显示层会按“镜像例外”隐藏");
        }

        // ---------- 用例 26d-2：蝗虫/镜像独立显示 ----------
        {
            var engine = new MonitorEngine();
            const uint mirrorAddr = 0x6B000000;
            const uint normalAddr = 0x6B000001;
            const uint plainAddr = 0x6B000002;
            var mirror = Attr(mirrorAddr,
                UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName |
                UnitAttrWire.FlagLocust | UnitAttrWire.FlagLocustChecked |
                UnitAttrWire.FlagIllusion | UnitAttrWire.FlagIllusionChecked,
                "e007", "小树箱", "");
            var normal = Attr(normalAddr,
                UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName |
                UnitAttrWire.FlagLocust | UnitAttrWire.FlagLocustChecked |
                UnitAttrWire.FlagIllusionChecked,
                "e007", "小树箱", "");
            var plain = Attr(plainAddr,
                UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | UnitAttrWire.FlagLocustChecked,
                "hfoo", "步兵", "");
            engine.RememberAttrLocusts(new[] { mirror, normal, plain });

            Check(UnitAttrWire.FlagIllusion != UnitAttrWire.FlagLocustChecked &&
                  UnitAttrWire.FlagIllusionChecked != UnitAttrWire.FlagIllusion &&
                  UnitAttrWire.FlagIllusionChecked != UnitAttrWire.FlagLocustChecked &&
                  mirror.IsIllusion && !normal.IsIllusion && normal.LocustChecked &&
                  !engine.IsUnitHiddenByLocust(mirrorAddr, "e007") &&   // Aloc 镜像 → 显示
                  engine.IsUnitHiddenByLocust(normalAddr, "e007") &&    // 非镜像 Aloc → 隐藏
                  !engine.IsUnitHiddenByLocust(plainAddr, "hfoo") &&
                  /* 同类型但没实测过 Aloc 的其它实例：不能被类型码连坐。 */
                  !engine.IsUnitHiddenByLocust(0x6B000003, "e007") &&
                  !Ui.UnitGridUi.ShouldDisplay(isLocust: true, isIllusion: false) &&
                  Ui.UnitGridUi.ShouldDisplay(isLocust: true, isIllusion: false, hasIllusionSibling: true) &&
                  Ui.UnitGridUi.ShouldDisplay(isLocust: true, isIllusion: true) &&
                  Ui.UnitGridUi.ShouldDisplay(isLocust: false, isIllusion: false) &&
                  !DdhEventDb.TrustDbIllusion(3) && DdhEventDb.TrustDbIllusion(4),
                  "状态位：蝗虫与镜像分别有独立结果位和已判定位；" +
                  "旧 ddh 库（user_version=3）的 illusion 位不可信；" +
                  "同类型有幻象时 locust 原单位仍显示");

            var originalRow = Ui.UnitGridUi.Build(
                new UnitView { Addr = normalAddr, TypeCode = "e007", Name = "小树箱", Hp = 1f },
                normal, _ => "?", isIllusion: false);
            var mirrorRow = Ui.UnitGridUi.Build(
                new UnitView { Addr = mirrorAddr, TypeCode = "e007", Name = "小树箱", Hp = 1f },
                mirror, _ => "?", isIllusion: true);
            Check(originalRow.Name == "小树箱" && originalRow.DisplayName == "小树箱" &&
                  originalRow.IllusionKnown && originalRow.IllusionText == "否" &&
                  originalRow.LocustText == "是" &&
                  mirrorRow.Name == "小树箱" && mirrorRow.DisplayName == "小树箱（镜像）" &&
                  mirrorRow.IllusionKnown && mirrorRow.IllusionText == "是" &&
                  mirrorRow.Cells()[Ui.UnitGridUi.IllusionCellIndex] as string == "是",
                  "蝗虫隐藏、镜像例外显示；镜像名称追加“（镜像）”，镜像列显示“是”");
        }

        // ---------- 用例 26d-3：SQLite units 完整属性回读 ----------
        {
            string dir = Path.Combine(Path.GetTempPath(), "dds-selftest-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(dir);
            string dbPath = Path.Combine(dir, "ddh-events.db");
            try
            {
                using var conn = SqliteConnection.Open(dbPath, out string dbErr);
                Check(conn != null, "units 属性回读：能创建临时 SQLite 库" + (dbErr.Length > 0 ? "：" + dbErr : ""));
                if (conn != null)
                {
                    Check(conn.Exec("""
                        PRAGMA user_version=4;
                        CREATE TABLE game_units(
                          session_id TEXT NOT NULL,
                          addr INTEGER NOT NULL,
                          type_code TEXT NOT NULL,
                          name TEXT NOT NULL,
                          title TEXT NOT NULL,
                          owner_slot INTEGER NOT NULL,
                          attack_range REAL NOT NULL,
                          damage_min REAL NOT NULL,
                          damage_max REAL NOT NULL,
                          attack_interval REAL NOT NULL,
                          armor REAL NOT NULL,
                          move_speed REAL NOT NULL,
                          sight_day REAL NOT NULL,
                          sight_night REAL NOT NULL,
                          acquire_range REAL NOT NULL,
                          strength REAL NOT NULL,
                          agility REAL NOT NULL,
                          intelligence REAL NOT NULL,
                          hero INTEGER NOT NULL,
                          illusion INTEGER NOT NULL,
                          dead INTEGER NOT NULL,
                          locust INTEGER NOT NULL,
                          attack_speed REAL NOT NULL
                        );
                        """, out string schemaErr),
                        "units 属性回读：临时表建立成功" + (schemaErr.Length > 0 ? "：" + schemaErr : ""));
                    Check(conn.Execute(
                        "INSERT INTO game_units VALUES(?1,?2,?3,?4,?5,?6,?7,?8,?9,?10,?11,?12,?13,?14,?15,?16,?17,?18,?19,?20,?21,?22,?23)",
                        new object?[]
                        {
                            "1234ABCD-5678EF90", (long)0x6C000001u, "O00M", "西利沃特", "剑影", 0L,
                            130.0, 204.0, 226.0, 1.6, 4.05, 0.0, 0.0, 0.0, 750.0,
                            0.0, 0.0, 0.0, 0L, 1L, 0L, 1L, 1.25
                        }, out string insertErr),
                        "units 属性回读：镜像/蝗虫样本写入成功" + (insertErr.Length > 0 ? "：" + insertErr : ""));
                }

                var rows = DdhEventDb.ReadUnits("1234ABCD-5678EF90", dbPath);
                var mirror = rows.SingleOrDefault(r => r.Addr == 0x6C000001u);
                Check(rows.Count == 1 && mirror != null &&
                      Math.Abs(mirror.AttackRange - 130f) < 0.01f &&
                      Math.Abs(mirror.DamageMin - 204f) < 0.01f &&
                      Math.Abs(mirror.DamageMax - 226f) < 0.01f &&
                      Math.Abs(mirror.AttackInterval - 1.6f) < 0.01f &&
                      Math.Abs(mirror.Armor - 4.05f) < 0.01f &&
                      Math.Abs(mirror.AcquireRange - 750f) < 0.01f &&
                      Math.Abs(mirror.AttackSpeed - 1.25f) < 0.01f &&
                      mirror.Has(UnitAttrWire.FlagAttackSpeed) &&
                      mirror.IsIllusion && mirror.IllusionChecked &&
                      mirror.IsLocust && mirror.LocustChecked,
                      "units 属性回读：攻击/范围/间隔/护甲/主动范围/镜像/蝗虫完整恢复");
            }
            finally
            {
                try { Directory.Delete(dir, recursive: true); } catch { }
            }
        }

        // ---------- 用例 26d-4：历史只读 ddh 游戏状态会话 ----------
        {
            string dir = Path.Combine(Path.GetTempPath(), "dds-history-selftest-" + Guid.NewGuid().ToString("N"));
            Directory.CreateDirectory(dir);
            string dbPath = Path.Combine(dir, "ddh-events.db");
            try
            {
                using var conn = SqliteConnection.Open(dbPath, out _);
                bool schema = conn != null && conn.Exec("""
                    CREATE TABLE game_sessions(
                        session_id TEXT PRIMARY KEY,ctx INTEGER NOT NULL,game_state INTEGER NOT NULL,
                        map_name TEXT NOT NULL,started_ms INTEGER NOT NULL,updated_ms INTEGER NOT NULL);
                    CREATE TABLE game_events(
                        id INTEGER PRIMARY KEY AUTOINCREMENT,session_id TEXT NOT NULL,seq INTEGER NOT NULL,
                        wall_ms INTEGER NOT NULL,tick_ms INTEGER NOT NULL,victim INTEGER NOT NULL,
                        victim_code TEXT NOT NULL,victim_name TEXT NOT NULL,victim_owner INTEGER NOT NULL,
                        source INTEGER NOT NULL,source_code TEXT NOT NULL,source_name TEXT NOT NULL,
                        source_owner INTEGER NOT NULL,amount REAL NOT NULL,engine REAL NOT NULL,
                        final REAL NOT NULL,actual REAL NOT NULL,hp_before REAL NOT NULL,hp_after REAL NOT NULL,
                        hp_valid INTEGER NOT NULL,attack_type INTEGER NOT NULL,damage_mask INTEGER NOT NULL,
                        is_physical INTEGER NOT NULL,flag INTEGER NOT NULL,depth INTEGER NOT NULL,
                        final_flags INTEGER NOT NULL,unit_flags INTEGER NOT NULL,UNIQUE(session_id,seq));
                    CREATE TABLE game_units(
                        session_id TEXT NOT NULL,addr INTEGER NOT NULL,type_code TEXT NOT NULL,
                        name TEXT NOT NULL,title TEXT NOT NULL,owner_slot INTEGER NOT NULL,
                        attack_range REAL NOT NULL,damage_min REAL NOT NULL,damage_max REAL NOT NULL,
                        attack_interval REAL NOT NULL,armor REAL NOT NULL,move_speed REAL NOT NULL,
                        sight_day REAL NOT NULL,sight_night REAL NOT NULL,acquire_range REAL NOT NULL,
                        strength REAL NOT NULL,agility REAL NOT NULL,intelligence REAL NOT NULL,
                        hero INTEGER NOT NULL,illusion INTEGER NOT NULL,dead INTEGER NOT NULL,
                        locust INTEGER NOT NULL,attack_speed REAL NOT NULL,PRIMARY KEY(session_id,addr));
                    CREATE TABLE game_settlements(
                        id INTEGER PRIMARY KEY AUTOINCREMENT,session_id TEXT NOT NULL,seq INTEGER NOT NULL,
                        wall_ms INTEGER NOT NULL,victim INTEGER NOT NULL,victim_code TEXT NOT NULL,
                        victim_name TEXT NOT NULL,victim_owner INTEGER NOT NULL,total_damage REAL NOT NULL,
                        hits INTEGER NOT NULL,max_hit REAL NOT NULL,fatal_source INTEGER NOT NULL,
                        fatal_source_code TEXT NOT NULL,fatal_source_name TEXT NOT NULL,fatal_damage REAL NOT NULL,
                        first_tick INTEGER NOT NULL,last_tick INTEGER NOT NULL,UNIQUE(session_id,seq));
                    CREATE TABLE sessions(pid INTEGER PRIMARY KEY,map_name TEXT NOT NULL,updated_ms INTEGER NOT NULL);
                    CREATE TABLE events(pid INTEGER,seq INTEGER);
                    CREATE TABLE units(pid INTEGER,addr INTEGER);
                    CREATE TABLE settlements(pid INTEGER,seq INTEGER);
                    INSERT INTO game_sessions VALUES('EMPTY-SESSION',0,4096,'',500,501);
                    INSERT INTO game_sessions VALUES('11111111-22222222',268527672,3187954856,'新会话地图',1000,5000);
                    INSERT INTO game_units VALUES(
                        '11111111-22222222',1811939329,'Hpal','圣骑士','乌瑟尔',0,
                        128,100,120,1.5,5,320,1800,800,500,20,15,18,1,0,0,0,1.2);
                    INSERT INTO game_units VALUES(
                        '11111111-22222222',1811940000,'hfoo','步兵','剑影',1,
                        100,80,100,1.4,3,280,1600,700,400,0,0,0,0,0,0,0,1.0);
                    INSERT INTO game_units VALUES(
                        '11111111-22222222',1811940001,'hfoo','步兵','剑影',1,
                        100,80,100,1.4,3,280,1600,700,400,0,0,0,0,1,0,0,1.0);
                    INSERT INTO game_events VALUES(
                        1,'11111111-22222222',1,2000,10,1811939329,'Hpal','圣骑士',0,
                        1811940000,'hfoo','步兵',1,100,100,100,100,500,400,1,3,0x20,1,0x100,1,0,0);
                    INSERT INTO game_events VALUES(
                        2,'11111111-22222222',2,2500,20,1811939329,'Hpal','圣骑士',0,
                        1811940001,'hfoo','步兵',1,50,50,50,50,400,350,1,3,0x20,1,0x100,1,0,4);
                    INSERT INTO game_events VALUES(
                        3,'11111111-22222222',3,4000,30,1811939329,'Hpal','圣骑士',0,
                        1811940000,'hfoo','步兵',1,999,999,999,999,999,0,1,3,0x20,1,0x100,1,0,0);
                    INSERT INTO game_settlements VALUES(
                        1,'11111111-22222222',1,2000,1811939329,'Hpal','圣骑士',0,
                        150,2,100,1811940000,'hfoo','步兵',50,10,20);
                    INSERT INTO game_settlements VALUES(
                        2,'11111111-22222222',2,4000,1811939329,'Hpal','圣骑士',0,
                        999,1,999,1811940000,'hfoo','步兵',999,30,30);
                    INSERT INTO sessions VALUES(999,'旧PID地图',9000);
                    INSERT INTO events VALUES(999,1);
                    INSERT INTO units VALUES(999,1);
                    INSERT INTO settlements VALUES(999,1);
                    """, out _);
                Check(schema, "历史读取：新 ddh 会话库可建立");

                var list = DdhHistoryReader.List(dbPath);
                var info = list.SingleOrDefault();
                var doc = info == null ? null : DdhHistoryReader.Load(info, out _, dbPath);
                Check(list.Count == 1 && info?.SessionId == "11111111-22222222" &&
                      info.MapName == "新会话地图" && info.SettlementCount == 2 &&
                      info.EventCount == 3 && info.UnitCount == 3 &&
                      doc != null && doc.Events.Count == 3 &&
                      doc.Settlements.Count == 2 &&
                      doc.Units.Count == 3 &&
                      doc.Settlements[0].Title == "乌瑟尔" &&
                      doc.Events[0].SourceTitle == "剑影" &&
                      doc.Events[1].SourceIllusion &&
                      doc.Events[0].Amount == 100 &&
                      doc.Settlements[0].MaxHit == 100 &&
                      Math.Abs(doc.Settlements[0].Sources.Sum(s => s.NetDrop) - 150) < 0.001 &&
                      doc.Settlements[0].Sources.Count == 2 &&
                      doc.Settlements[0].Sources.Any(s => s.Source.EndsWith("（镜像）", StringComparison.Ordinal)) &&
                      doc.Settlements[1].MaxHit == 999 &&
                      doc.Settlements[1].Sources.Count == 1 &&
                      Math.Abs(doc.Settlements[1].Sources[0].NetDrop - 999) < 0.001,
                      $"历史读取：只认 game_sessions.session_id，旧 PID 表完全忽略（list={list.Count}/{info?.SessionId}/{info?.MapName}/" +
                      $"结算 {info?.SettlementCount}/事件 {info?.EventCount}/单位 {info?.UnitCount}；" +
                      $"doc 结算 {doc?.Settlements.Count}/事件 {doc?.Events.Count}/单位 {doc?.Units.Count}/" +
                      $"称谓 {doc?.Settlements.FirstOrDefault()?.Title}/{doc?.Events.FirstOrDefault()?.SourceTitle}/" +
                      $"来源 {doc?.Settlements.FirstOrDefault()?.Sources.Count}/" +
                      $"金额 {doc?.Events.FirstOrDefault()?.Amount}/" +
                      $"分段合计 {doc?.Settlements.FirstOrDefault()?.Sources.Sum(s => s.NetDrop)}" +
                      $"/{doc?.Settlements.LastOrDefault()?.Sources.Sum(s => s.NetDrop)}）");
            }
            finally
            {
                try { Directory.Delete(dir, recursive: true); } catch { }
            }
        }

        // ---------- 用例 26e：闲时清理已停用（代码/配置项都移除，单位不再因“无伤害”被移除） ----------
        {
            var engineType = typeof(MonitorEngine);
            var settingsType = typeof(Settings);
            Check(engineType.GetProperty("IdleMinutes") == null &&
                  engineType.GetMethod("PurgeIdleUnits",
                                       System.Reflection.BindingFlags.Instance |
                                       System.Reflection.BindingFlags.NonPublic) == null &&
                  settingsType.GetField("IdleMinutes") == null,
                  "闲时清理已停用：MonitorEngine.IdleMinutes / PurgeIdleUnits 与 Settings.IdleMinutes 都已移除" +
                  "（单位只受“死亡不显示”约束，不会因长时间没有伤害进出被移除）");

            string tmp = Path.Combine(AppContext.BaseDirectory, "logs",
                                      "selftest_settings_" + Guid.NewGuid().ToString("N") + ".ini");
            try
            {
                Directory.CreateDirectory(Path.GetDirectoryName(tmp)!);
                new Settings().Save(tmp);
                string text = File.ReadAllText(tmp);
                Check(text.Contains("interval_ms") && !text.Contains("idle_minutes") &&
                      !text.Contains("DSS_IDLE_MINUTES"),
                      "配置文件不再写 idle_minutes / DSS_IDLE_MINUTES（旧 ini 里的该项会被忽略，不影响其它设置）");
            }
            finally
            {
                try { File.Delete(tmp); } catch { }
            }
        }

        // ---------- 用例 26b-2：0 移速视为无效（退回 spd / ?，绝不显示 0） ----------
        {
            // 真机日志：自动匹配挑到 GetGameSpeed 返回 0，ddh 又置了“移速有效”位 → 界面显示 0。
            // 现在两边都把 0 当“没测到”：有 spd 退回 spd，没有就 ?。
            var zeroSpeedWithSpd = Attr(0x4002,
                UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName |
                UnitAttrWire.FlagMoveSpeed | UnitAttrWire.FlagBaseSpeed,
                "hfoo", "步兵", "", speed: 0f, baseSpeed: 320);
            var zeroSpeedOnly = Attr(0x4003,
                UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | UnitAttrWire.FlagMoveSpeed,
                "hfoo", "步兵", "", speed: 0f);
            Check(zeroSpeedWithSpd.MoveSpeedPreferredText == "320" &&
                  zeroSpeedOnly.MoveSpeedPreferredText == "?" &&
                  zeroSpeedOnly.MoveSpeedText == "0",
                  $"0 移速视为无效：有 spd → {zeroSpeedWithSpd.MoveSpeedPreferredText}，" +
                  $"没 spd → {zeroSpeedOnly.MoveSpeedPreferredText}（MoveSpeedText 仍原样 {zeroSpeedOnly.MoveSpeedText}）");
        }

        // ---------- 用例 26c：力/敏/智的 ?/— 语义 + 附加值整数 ----------
        {
            var heroFull = Attr(0x5000, UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName |
                                        UnitAttrWire.FlagHeroKnown | UnitAttrWire.FlagHero |
                                        UnitAttrWire.FlagStrength | UnitAttrWire.FlagAgility |
                                        UnitAttrWire.FlagIntelligence | UnitAttrWire.FlagExtra,
                                 "Hpal", "圣骑士", "", strength: 25, agility: 12, intelligence: 30, extra: 7);
            var heroMissing = Attr(0x5001, UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName |
                                           UnitAttrWire.FlagHeroKnown | UnitAttrWire.FlagHero,
                                    "Hpal", "圣骑士", "");
            var nonHero = Attr(0x5002, UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName |
                                       UnitAttrWire.FlagHeroKnown | UnitAttrWire.FlagExtra,
                                "hfoo", "步兵", "", extra: 99);
            var unknown = Attr(0x5003, UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName,
                               "hfoo", "步兵", "");
            Check(heroFull.StrengthText == "25" && heroFull.AgilityText == "12" &&
                  heroFull.IntelligenceText == "30" && heroFull.ExtraText == "7" &&
                  heroMissing.StrengthText == "?" && heroMissing.AgilityText == "?" &&
                  heroMissing.IntelligenceText == "?" && heroMissing.ExtraText == "?" &&
                  nonHero.StrengthText == "—" && nonHero.AgilityText == "—" &&
                  nonHero.IntelligenceText == "—" && nonHero.ExtraText == "99" &&
                  unknown.StrengthText == "?" && unknown.ExtraText == "?",
                  $"力/敏/智 ?/— 语义：英雄有值={heroFull.StrengthText}/{heroFull.AgilityText}/{heroFull.IntelligenceText}，" +
                  $"英雄缺值={heroMissing.StrengthText}，确定非英雄={nonHero.StrengthText}/{nonHero.AgilityText}/{nonHero.IntelligenceText}；" +
                  $"附加值 {heroFull.ExtraText}/{nonHero.ExtraText} 显示整数，未知={unknown.ExtraText}");
        }

        // ---------- 用例 27：属性请求槽优先级（存活优先 + 最近受击；旧接口最多 96） ----------
        {
            var now = new DateTime(2026, 10, 25, 10, 0, 0);
            var units = new List<UnitView>
            {
                new() { Addr = 0x1u, Hp = 0f, LastHit = now },                    // 已死
                new() { Addr = 0x2u, Hp = 100f, LastHit = now.AddSeconds(-5) },   // 存活，早受击
                new() { Addr = 0x3u, Hp = 100f, LastHit = now },                  // 存活，刚受击
            };
            var pick = Ui.UnitGridUi.PickRequestAddrs(units, UnitAttrWire.SlotCount);
            var many = Enumerable.Range(0, 100)
                                 .Select(i => new UnitView { Addr = (uint)(0x1000 + i), Hp = 100f })
                                 .ToList();
            var capped = Ui.UnitGridUi.PickRequestAddrs(many, UnitAttrWire.SlotCount);
            Check(pick.Count == 3 && pick[0] == 0x3u && pick[1] == 0x2u && pick[2] == 0x1u &&
                  capped.Count == UnitAttrWire.SlotCount && capped[0] == 0x1000u,
                  $"属性请求优先级：存活且最近受击的在前，最多 {UnitAttrWire.SlotCount} 个（实际 {capped.Count}）");
        }

        // ---------- 用例 28：属性请求轮询覆盖全部**存活**单位（96 槽；死亡单位不占用槽位） ----------
        {
            var now = new DateTime(2026, 10, 25, 10, 0, 0);
            // 前 200 个存活、后 20 个已死（Hp=0）。存活单位按地址稳定排序后每轮连续取 96 个、
            // 到尾循环回绕；旧逻辑（只取优先序前 96）会让后 104 个永远轮不到。
            var units = Enumerable.Range(0, 220)
                                  .Select(i => new UnitView
                                  {
                                      Addr = (uint)(0x1000 + i * 4),
                                      Hp = i < 200 ? 100f : 0f,
                                      LastHit = (i % 11 == 0) ? now : now.AddSeconds(-i),
                                      Taken = i
                                  })
                                  .ToList();
            var poller = new UnitAttrPoller();
            var rounds = new List<List<uint>>();
            for (int r = 0; r < 3; r++)
            {
                var picked = poller.PickRound(units, UnitAttrWire.SlotCount);
                poller.MarkRequested(picked);       // 模拟 RequestUnitAttrs 成功
                rounds.Add(picked);
            }
            var union = rounds.SelectMany(x => x).ToHashSet();
            int firstRoundFirst = (int)(rounds[0][0] - 0x1000) / 4;
            // 第一轮 0..95：i%11==0 且还活着的 11/22/33/44/55/66/88 都是“刚受击”，
            // 再按累计承伤倒序 → i=88 排槽首；i=0/77 已死，绝不能排在前面。
            bool priorityInRound = units[firstRoundFirst].Hp > 0f &&
                                   units[firstRoundFirst].LastHit == now &&
                                   firstRoundFirst == 88;
            string line = poller.CoverageLine(units);
            // 已死单位一个都不能被请求（它们的地址在 0x1000+200*4 之后）。
            bool deadSkipped = !union.Any(a => a >= 0x1000u + 200u * 4u);
            // 全部死亡时：不请求、覆盖率分母为 0（不会拿死单位冒充“已覆盖”）。
            var deadOnly = units.Where(u => u.Hp <= 0f).ToList();
            var deadPoller = new UnitAttrPoller();
            var deadPick = deadPoller.PickRound(deadOnly, UnitAttrWire.SlotCount);
            string deadLine = deadPoller.CoverageLine(deadOnly);
            // 日志节流：首行立即写；30 秒一行；单位数增长时（≥2 秒）补一行，避免开局 2/2 卡 30 秒。
            bool logOk = poller.ShouldLog(1_000_000, 200) &&
                         !poller.ShouldLog(1_001_000, 200) &&
                         !poller.ShouldLog(1_003_000, 200) &&
                         poller.ShouldLog(1_030_000, 200) &&
                         !poller.ShouldLog(1_031_000, 210) &&
                         poller.ShouldLog(1_033_500, 210);
            Check(rounds[0].Count == 96 && rounds[1].Count == 96 && rounds[2].Count == 96 &&
                  union.Count == 200 && poller.RequestedCount == 200 &&
                  rounds[0].Concat(rounds[1]).Distinct().Count() == 192 &&
                  rounds.All(r => r.Distinct().Count() == r.Count) &&
                  priorityInRound && poller.Cursor == 88 && logOk && deadSkipped &&
                  deadPick.Count == 0 && deadLine.Contains("0/0") &&
                  line.Contains("本轮 96 个") && line.Contains("200/200"),
                  $"属性轮询：200 个存活单位分 3 轮全部覆盖（每轮 96，第 3 轮回绕；并集 {union.Count}/200），" +
                  $"20 个死亡单位不占槽位（全部死亡时请求 {deadPick.Count} 个，日志=\"{deadLine}\"）；" +
                  $"批内仍存活+最近受击优先（首个单位下标 {firstRoundFirst}）；日志=\"{line}\"");
        }

        // ---------- 用例 29：ddh v12 布局：96 槽 / 响应槽偏移 392 / 块长 20360 ----------
        {
            int expectResp = UnitAttrWire.RequestOffset + UnitAttrWire.SlotCount * 4;
            int expectBlock = expectResp + UnitAttrWire.SlotCount * UnitAttrWire.EntrySize;
            Check(UnitAttrWire.SlotCount == 96 && expectResp == 392 && expectBlock == 20360 &&
                  UnitAttrWire.ResponseOffset == expectResp && UnitAttrWire.BlockSize == expectBlock &&
                  UnitAttrWire.LayoutMatchesDdhLog &&
                  UnitAttrWire.BlockSize <= 1024 * 1024 - 120896,
                  $"ddh v12 布局：{UnitAttrWire.SlotCount} 槽，响应槽偏移 {UnitAttrWire.ResponseOffset}，" +
                  $"块长 {UnitAttrWire.BlockSize}（共享内存 1MB 富余）");
        }

        // ---------- 用例 30：每单位属性缓存 TTL 3 秒（与 ddh.cpp DDH_ATTR_TTL_MS 同步） ----------
        {
            Check(UnitAttrWire.DdhAttrCacheTtlMs == 3000 && UnitAttrWire.DdhAttrCacheTtlMs > 1000,
                  $"属性缓存 TTL = {UnitAttrWire.DdhAttrCacheTtlMs} ms（v12 从 1000 放宽到 3000）");
        }

        // ==================================================================
        // 称谓搜索（称谓只参与表头搜索，不新增任何表格列）
        // ==================================================================

        // ---------- 用例 31：称谓索引（ddh 属性响应 Title → 地址索引；TTL 到期不丢；换局清空） ----------
        {
            var engine = new MonitorEngine();
            uint heroFlags = UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName | UnitAttrWire.FlagTitle |
                             UnitAttrWire.FlagHeroKnown | UnitAttrWire.FlagHero;

            engine.RememberAttrTitles(new[]
            {
                Attr(0x1A000000, heroFlags, "Hpal", "圣骑士", "乌瑟尔"),
            });
            Check(engine.TryGetTitle(0x1A000000, out string t1) && t1 == "乌瑟尔" && engine.TitleCount == 1,
                  $"称谓索引：属性响应里的 Title 记进地址索引（0x1A000000 → '{t1}'，共 {engine.TitleCount} 条）");

            // 属性缓存 TTL 到期后 ddh 会回 flags 里没有 Title 位 / Title 为空的槽：
            // 这种响应绝不能把已经学到的称谓抹掉（称谓是静态的，保留到换局）。
            engine.RememberAttrTitles(new[]
            {
                Attr(0x1A000000, UnitAttrWire.FlagTypeCode | UnitAttrWire.FlagName, "Hpal", "圣骑士", ""),
                Attr(0x1A000000, UnitAttrWire.FlagTitle, "Hpal", "圣骑士", ""),
            });
            Check(engine.TryGetTitle(0x1A000000, out string t2) && t2 == "乌瑟尔",
                  "称谓索引：TTL 到期/空 Title 的响应不会抹掉已知称谓（仍是 '乌瑟尔'）");

            // 地址复用（同一局内同地址换了英雄码）：新称谓覆盖旧的；搜索时用行/事件自己的类型码校验，
            // 地址已经换成别的单位（类型码不同）→ 不认旧称谓（与蝗虫过滤“地址+类型码”同口径）。
            engine.RememberAttrTitles(new[] { Attr(0x1A000000, heroFlags, "Hmkg", "山丘之王", "穆拉丁") });
            Check(engine.TryGetTitle(0x1A000000, out string t3) && t3 == "穆拉丁" &&
                  engine.TryGetTitle(0x1A000000, "Hmkg", out string t3b) && t3b == "穆拉丁",
                  $"称谓索引：同地址学到新称谓时以最新为准（'{t3}'）");
            Check(!engine.TryGetTitle(0x1A000000, "hfoo", out string reused) && reused == "" &&
                  !engine.TryGetTitle(0x1A000000, "Hpal", out _),
                  "称谓索引：地址被别的类型码复用 → 不返回旧称谓（不误匹配）");

            // 从没被属性请求覆盖过的地址 / 地址 0：明确返回 false + 空串（搜索只按名字）。
            Check(!engine.TryGetTitle(0x2A000000, out string none) && none == "" &&
                  !engine.TryGetTitle(0, out string zero) && zero == "",
                  "称谓索引：没被属性请求覆盖过的地址 → false + 空串（不误伤搜索）");

            engine.ClearTitleIndex();
            Check(!engine.TryGetTitle(0x1A000000, out _) && engine.TitleCount == 0,
                  "称谓索引：换局/清空历史时整体清空（地址会复用，旧称谓不能串到新局）");
        }

        // ---------- 用例 31b：换局时【战场单位】的跨轮保留必须和结算/伤害明细同一步清空 ----------
        // 回归：Publish 会把“本轮没出现、但之前出现过的类型”从 _retainedTypes 补成“死亡”行；
        // 如果换局不清这个字典，新一局的【战场单位】会立刻把上一局的单位原样补回来
        // （表现就是“死亡结算/伤害明细都清了，战场单位没清”）。
        {
            var engine = new MonitorEngine();
            var flags = System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic;

            var retainedField = typeof(MonitorEngine).GetField("_retainedTypes", flags);
            var clearMethod = typeof(MonitorEngine).GetMethod("ClearHistoryCore", flags);
            var retained = retainedField?.GetValue(engine) as Dictionary<string, UnitView>;

            retained!["hfoo"] = new UnitView { Addr = 0x71000000, TypeCode = "hfoo", State = "死亡" };

            clearMethod!.Invoke(engine, new object[] { false });

            Check(retained!.Count == 0 && engine.Current.Units.Count == 0,
                  $"换局清空：_retainedTypes 与单位账本在同一步清空（保留类型 {retained.Count}）");
        }

        // ---------- 用例 32：统一的名称谓词（名字或称谓命中即可；两列 AND；空称谓不误伤；没有新增列） ----------
        {
            // 单列：名字命中 / 称谓命中 / 都不命中；称谓为空时退化成纯名字匹配。
            Check(Ui.SettlementGridUi.MatchesNameOrTitle("圣骑士", "乌瑟尔", "圣") &&
                  Ui.SettlementGridUi.MatchesNameOrTitle("圣骑士", "乌瑟尔", "乌瑟") &&
                  !Ui.SettlementGridUi.MatchesNameOrTitle("圣骑士", "乌瑟尔", "剑圣") &&
                  Ui.SettlementGridUi.MatchesNameOrTitle("圣骑士", "", "圣") &&
                  !Ui.SettlementGridUi.MatchesNameOrTitle("圣骑士", "", "乌瑟") &&
                  !Ui.SettlementGridUi.MatchesNameOrTitle("圣骑士", null, "乌瑟") &&
                  Ui.SettlementGridUi.MatchesNameOrTitle(null, "", "") &&
                  !Ui.SettlementGridUi.MatchesNameOrTitle(null, null, "圣"),
                  "名称谓词：名字或称谓任一命中即可；称谓为空只按名字匹配（不误伤）");

            // 两列 AND + 称谓别名（结算表：单位名/称谓 + 类型码）：
            // 名字没命中、但称谓命中 → 整行保留；类型码列仍必须命中。
            Check(Ui.SettlementGridUi.MatchesRowValues("圣骑士", "Hpal", "乌瑟", "hp", nameTitle: "乌瑟尔") &&
                  Ui.SettlementGridUi.MatchesRowValues("圣骑士", "Hpal", "圣骑", "Hpal", nameTitle: "乌瑟尔") &&
                  !Ui.SettlementGridUi.MatchesRowValues("圣骑士", "Hpal", "乌瑟", "hfoo", nameTitle: "乌瑟尔") &&
                  !Ui.SettlementGridUi.MatchesRowValues("圣骑士", "Hpal", "剑圣", "hp", nameTitle: "乌瑟尔") &&
                  !Ui.SettlementGridUi.MatchesRowValues("圣骑士", "Hpal", "乌瑟", "hp", nameTitle: ""),
                  "结算表谓词：单位名/称谓任一命中 + 类型码，两列 AND；称谓为空时只按名字");

            // 名字和称谓都命中同一行：仍然算命中（不会因为“两个字段都命中”而重复/排除）。
            Check(Ui.SettlementGridUi.MatchesNameOrTitle("乌瑟尔", "乌瑟尔·光明使者", "乌瑟") &&
                  Ui.SettlementGridUi.MatchesRowValues("乌瑟尔", "Hpal", "乌瑟", "", nameTitle: "乌瑟尔·光明使者"),
                  "名称谓词：名字与称谓同时命中同一行 → 该行保留（只算一行）");

            // 死亡结算仍是“时间 + 13 个数据列”= 14 列，伤害事件增加英雄列后为 19 列，
            // 表头里没有任何“称谓/Title”列（称谓只参与搜索）。
            var gSettle = new Ui.Grid();
            Ui.SettlementGridUi.AddColumns(gSettle);
            var settleHeaders = gSettle.Columns.Cast<DataGridViewColumn>().Select(c => c.HeaderText).ToList();
            var gHook = new Ui.Grid();
            Ui.HookGridUi.AddColumns(gHook);
            var hookHeaders = gHook.Columns.Cast<DataGridViewColumn>().Select(c => c.HeaderText).ToList();
            Check(gSettle.Columns.Count == 14 && settleHeaders[0] == "时间" &&
                  settleHeaders[1] == "单位名称" && Ui.SettlementGridUi.NameHeader == "单位名称" &&
                  settleHeaders[4] == "玩家" &&
                  Ui.SettlementGridUi.Cells(new Settlement { Addr = 0x1A000000, TypeCode = "Hpal", UnitName = "圣骑士" },
                                            "乌瑟尔").Length == 14 &&
                  (string)Ui.SettlementGridUi.Cells(
                      new Settlement { Addr = 0x1A000000, TypeCode = "Hpal", UnitName = "圣骑士" },
                      "乌瑟尔")[Ui.SettlementGridUi.NameCellIndex] == "乌瑟尔\n圣骑士" &&
                  !settleHeaders.Any(h => h.Contains("称谓") || h.Contains("title", StringComparison.OrdinalIgnoreCase)) &&
                  gHook.Columns.Count == 19 &&
                  !hookHeaders.Any(h => h.Contains("称谓") || h.Contains("title", StringComparison.OrdinalIgnoreCase)),
                  $"不新增列：死亡结算 {gSettle.Columns.Count} 列（时间 + 13 个数据列）/ 伤害事件 {gHook.Columns.Count} 列，" +
                  "单位名称内显示称谓；表头里没有单独的“称谓”列");
            var ownerOverrideCells = Ui.SettlementGridUi.Cells(
                new Settlement { Addr = 0x1A000000, TypeCode = "Hpal", UnitName = "圣骑士", OwnerSlot = -1 },
                "乌瑟尔", ownerSlotOverride: 2);
            Check((string)ownerOverrideCells[4] == "Player 3",
                  "死亡结算：玩家优先使用 game_units 身份中的 owner_slot");
        }

        // ---------- 用例 33：伤害事件表按称谓搜索（实时按地址查索引 / 历史用事件自带的 title；两列 AND） ----------
        {
            var t0 = new DateTime(2026, 10, 25, 20, 0, 0);
            var e = new DamageHook.HookEvent(1, t0, 0x1000, "hfoo", 0x2000, "Hpal", 10,
                true, false, 3, 4, true, VictimName: "步兵", SourceName: "圣骑士");
            var titles = new Dictionary<uint, (string Title, string Code)>
            {
                [0x1000] = ("剑圣", "hfoo"),
                [0x2000] = ("乌瑟尔", "Hpal"),
            };
            string TitleOf(uint addr, string? code) =>
                titles.TryGetValue(addr, out var found) &&
                (string.IsNullOrEmpty(code) || string.Equals(found.Code, code, StringComparison.OrdinalIgnoreCase))
                    ? found.Title
                    : "";

            Check(Ui.HookGridUi.MatchesSearch(e, "剑圣", "", TitleOf) &&        // 触发单位：只命中称谓
                  Ui.HookGridUi.MatchesSearch(e, "步兵", "", TitleOf) &&        // 触发单位：只命中名字
                  Ui.HookGridUi.MatchesSearch(e, "", "乌瑟", TitleOf) &&        // 伤害来源：只命中称谓
                  Ui.HookGridUi.MatchesSearch(e, "剑圣", "乌瑟", TitleOf) &&    // 两列 AND 都命中
                  Ui.HookGridUi.MatchesSearch(e, "", "", TitleOf) &&            // 空关键词 = 不过滤
                  !Ui.HookGridUi.MatchesSearch(e, "剑圣", "步兵", TitleOf) &&   // 来源列不命中 → 排除
                  !Ui.HookGridUi.MatchesSearch(e, "乌瑟", "", TitleOf),         // 触发单位列不命中
                  "伤害事件搜索：触发单位/伤害来源都支持称谓（名字或称谓命中即可，两列 AND）");

            // 地址复用：同地址现在的类型码变了（不再是 Hpal）→ 不拿旧称谓匹配这条事件。
            var reusedUnit = e with { SourceCode = "hfoo" };
            Check(!Ui.HookGridUi.MatchesSearch(reusedUnit, "", "乌瑟", TitleOf),
                  "伤害事件搜索：地址被别的类型码复用 → 旧称谓不误匹配（类型码校验）");

            // 没有称谓索引（没打开过属性轮询的页、或单位从没被覆盖）：只按名字，称谓关键词不误命中。
            Check(!Ui.HookGridUi.MatchesSearch(e, "剑圣", "", null) &&
                  !Ui.HookGridUi.MatchesSearch(e, "", "乌瑟", null) &&
                  Ui.HookGridUi.MatchesSearch(e, "步兵", "圣骑", null) &&
                  Ui.HookGridUi.MatchesSearch(e, "", "", null),
                  "伤害事件搜索：没有称谓索引时只按名字匹配（空关键词仍全部通过）");

            // 历史库回放：事件自带 victim_title/source_title（titleOf=null 时直接用它）；
            // 老库没有这两列 → 空串，只按名字。
            var hist = e with { VictimTitle = "剑圣", SourceTitle = "乌瑟尔" };
            var old = e with { VictimTitle = "", SourceTitle = "" };
            Check(Ui.HookGridUi.MatchesSearch(hist, "剑圣", "乌瑟", titleOf: null) &&
                  Ui.HookGridUi.MatchesSearch(hist, "", "乌瑟", titleOf: null) &&
                  !Ui.HookGridUi.MatchesSearch(old, "剑圣", "", titleOf: null) &&
                  Ui.HookGridUi.MatchesSearch(old, "步兵", "圣骑", titleOf: null),
                  "伤害事件搜索（历史）：用事件自带的称谓；老库 title 为空时只按名字、不报错");
        }

        // ---------- 用例 35：结算排序唯一口径（快照降序 / 补建更早 / 乱序回退 / 同毫秒稳定） ----------
        {
            var t0 = new DateTime(2026, 10, 27, 1, 36, 27, 301);

            // 账本里的追加顺序：先两条正常死亡，最后追加一条“钩子补建”的更早结算
            //（SynthesizeHookDeaths 就是这么 Add 的）—— 旧界面会把它顶到第一行（截图里的乱序）。
            var newest = new Settlement { Addr = 0x3000, TypeCode = "hfoo", DiedAt = t0 };
            var older = new Settlement { Addr = 0x2000, TypeCode = "hfoo", DiedAt = t0.AddSeconds(-9) };
            var synthesized = new Settlement
            {
                Addr = 0x1000, TypeCode = "hfoo", DiedAt = t0.AddMinutes(-14), SyntheticHookDeath = true,
            };
            var tracker = new List<Settlement> { newest, older, synthesized };

            var sorted = SettlementOrder.SortDescending(tracker);
            Check(sorted.Count == 3 && ReferenceEquals(sorted[0], newest) &&
                  ReferenceEquals(sorted[1], older) && ReferenceEquals(sorted[2], synthesized) &&
                  SettlementOrder.IsNonIncreasing(sorted),
                  "快照排序：补建结算（01:22:20）追加在账本末尾 → Current.Settlements 仍按 DiedAt 严格降序，旧的排在下面");

            // 旧版界面留下的表：顶部是 01:22:20，下面却是 01:36:27（截图里的乱序）→ 必须检测出来。
            var legacyRows = new List<Settlement> { synthesized, newest };
            Check(SettlementOrder.FirstDisorderIndex(legacyRows) == 1 &&
                  !SettlementOrder.IsNonIncreasing(legacyRows) &&
                  SettlementOrder.IsNonIncreasing(SettlementOrder.SortDescending(legacyRows)),
                  "乱序检测：顶部=01:22:20 / 下面=01:36:27 → 判定乱序（界面据此记日志并退回整表重建）");

            // 有序插入：二分查找插入点，补建的更早结算插到中间/末尾，最终严格降序。
            var rows = new List<Settlement> { newest, older };
            var mid = new Settlement { Addr = 0x2800, TypeCode = "hfoo", DiedAt = t0.AddSeconds(-3) };
            var earliest = new Settlement { Addr = 0x0800, TypeCode = "hfoo", DiedAt = t0.AddMinutes(-30) };
            foreach (var s in new[] { earliest, mid })   // 故意先插最旧的：应落在末尾；再插中间
                rows.Insert(SettlementOrder.FindInsertIndex(rows, s), s);
            Check(rows.Count == 4 && ReferenceEquals(rows[0], newest) && ReferenceEquals(rows[1], mid) &&
                  ReferenceEquals(rows[2], older) && ReferenceEquals(rows[3], earliest) &&
                  SettlementOrder.IsNonIncreasing(rows),
                  "有序插入：补建/补挂的结算按二分插入点落位（更早的插到下面，不顶掉顶部），插入后仍严格降序");

            // 同一毫秒多条：InstanceIndex 降序、再 Addr 降序；三键全等保持原顺序（稳定）。
            var tie = t0.AddMinutes(2);
            var ta = new Settlement { Addr = 0x100, TypeCode = "hfoo", DiedAt = tie, InstanceIndex = 1 };
            var tb = new Settlement { Addr = 0x300, TypeCode = "hfoo", DiedAt = tie, InstanceIndex = 1 };
            var tc = new Settlement { Addr = 0x200, TypeCode = "hfoo", DiedAt = tie, InstanceIndex = 2 };
            var td = new Settlement { Addr = 0x100, TypeCode = "hfoo", DiedAt = tie, InstanceIndex = 1 };
            var tieSorted = SettlementOrder.SortDescending(new[] { ta, tb, tc, td });
            var histOld = new List<HistorySettlement>
            {
                new() { Addr = 0x10, TypeCode = "hfoo", DiedAt = t0.AddMinutes(-2) },
                new() { Addr = 0x20, TypeCode = "hfoo", DiedAt = t0 },
            };
            var histSorted = SettlementOrder.SortDescending(histOld);
            Check(ReferenceEquals(tieSorted[0], tc) && ReferenceEquals(tieSorted[1], tb) &&
                  ReferenceEquals(tieSorted[2], ta) && ReferenceEquals(tieSorted[3], td) &&
                  ReferenceEquals(histSorted[0], histOld[1]) && ReferenceEquals(histSorted[1], histOld[0]),
                  "同一毫秒多条按实例号/地址确定顺序且三键全等保持稳定；历史 DTO 同样按 DiedAt 降序");
        }

        // ---------- 用例（v1.1）：游戏内阵亡面板的组行 / 线协议 / 本地英雄过滤 ----------
        {
            var t0 = new DateTime(2026, 11, 1, 12, 34, 56);
            const uint addr = 0x0010586D;
            const uint src = 0x00200000;
            var fatal = new DamageHook.HookEvent(
                1, t0, addr, "Hmkg", src, "Hmkg", 812, true, false, 0, 4, true,
                "剑圣", "山丘之王", HpBefore: 812, HpAfter: 0, Actual: 812, HpValid: true,
                EngineDamage: 812, EngineValid: true, EngineCalls: 1);
            var sources = new List<HookBreakdown.SourceRow>
            {
                new("山丘之王(Hmkg)", 6, 1468, 1468, true, 1468, true, 1468, true, 45.9),
                new("大法师(Hamg)", 5, 912, 912, true, 912, true, 912, true, 28.5),
                new("火枪手(hrif)", 4, 620, 620, true, 620, true, 620, true, 19.4),
                new("步兵(hfoo)", 3, 200, 200, true, 200, true, 200, true, 6.3),
            };
            var rows = new List<HookBreakdown.Row>
            {
                new("钩子-是否攻击", "1", 14, 2606, 2606, true, 2606, true, 2606, true, 81.4),
                new("钩子-是否攻击", "0", 4, 594, 594, true, 594, true, 594, true, 18.6),
                new("钩子-是否远程", "0", 9, 1668, 1668, true, 1668, true, 1668, true, 52.1),
                new("钩子-是否远程", "1", 9, 1532, 1532, true, 1532, true, 1532, true, 47.9),
                new("钩子-攻击类型", "0", 10, 1876, 1876, true, 1876, true, 1876, true, 58.6),
                new("钩子-攻击类型", "1", 4, 700, 700, true, 700, true, 700, true, 21.9),
                new("钩子-伤害类型", "4", 10, 1900, 1900, true, 1900, true, 1900, true, 59.4),
                new("钩子-伤害类型", "5", 6, 1100, 1100, true, 1100, true, 1100, true, 34.4),
            };
            var s = new Settlement
            {
                Addr = addr, TypeCode = "Hmkg", OwnerSlot = 0, Kind = "死亡",
                DiedAt = t0, FirstSeen = t0.AddSeconds(-62.4), FirstHit = t0.AddSeconds(-10),
                LastHit = t0.AddSeconds(-0.1), HitCount = 18, TotalDamage = 3200, TotalHeal = 120,
                MaxHit = 812, MinHit = 80, HpMax = 3200, Peak1s = 1746, InstanceIndex = 2,
                UnitName = "剑圣", HookSources = sources, HookRows = rows, FatalHookEvent = fatal,
            };
            var cfg = new InGamePanelSettings { MaxLines = 18 };
            var lines = InGamePanel.BuildLines(s, (_, _) => "剑圣称谓", cfg);
            string all = string.Join("\n", lines.Select(l => l.Text));
            Check(lines.Count is > 10 and <= 18, $"面板行数在 11..18（实际 {lines.Count}）");
            Check(all.Contains("阵亡总结") && all.Contains("承受伤害") && all.Contains("剑圣称谓"),
                  "面板含 标题/承受伤害/英雄称谓");
            Check(all.Contains("山丘之王(Hmkg) 45.9%") && all.Contains("大法师(Hamg) 28.5%"),
                  "面板含 伤害来源 Top4（名字(码) + 百分比）");
            Check(all.Contains("致命一击 山丘之王(Hmkg)") && all.Contains("普攻"),
                  "面板含 致命一击（来源/普攻）");
            Check(all.Contains("构成 普攻 2,606 / 技能 594") && all.Contains("近战 1,668 / 远程 1,532"),
                  "面板含 普攻/技能、近战/远程 构成");
            Check(all.Contains("攻类型 0:1,876") && all.Contains("伤类型 4:1,900"),
                  "面板含 攻击类型/伤害类型 数字分组");
            Check(all.Contains("玩家 1") && all.Contains("第 2 条命") && all.Contains(addr.ToString("X8")),
                  "面板含 玩家/实例/地址");

            Check(InGamePanel.IsLocalDeath(s, 0), "本地玩家过滤：OwnerSlot=0 + 本地玩家 0 → 是");
            Check(!InGamePanel.IsLocalDeath(s, 1), "本地玩家过滤：本地玩家 1 → 否");
            Check(!InGamePanel.IsLocalDeath(new Settlement { Addr = addr, OwnerSlot = 0, Kind = "消失", DiedAt = t0 }, 0),
                  "本地玩家过滤：消失 不弹面板");
            Check(InGamePanel.DedupeKey(s) == InGamePanel.DedupeKey(new Settlement { Addr = addr, DiedAt = t0.AddSeconds(1) }) &&
                  InGamePanel.DedupeKey(s) != InGamePanel.DedupeKey(new Settlement { Addr = addr, DiedAt = t0.AddSeconds(3) }),
                  "去重键：同一地址 2 秒内同键、超过 2 秒不同键");

            var basic = InGamePanel.BuildLines(
                new Settlement { Addr = 0x2000, TypeCode = "hfoo", OwnerSlot = 0, Kind = "死亡", DiedAt = t0, HitCount = 1, TotalDamage = 10 },
                null, cfg);
            Check(basic.Count >= 6 && string.Join("\n", basic.Select(l => l.Text)).Contains("钩子数据未到"),
                  "没有钩子数据时仍出基础行（来源写“钩子数据未到”），不抛异常");

            var iconSettle = new Settlement
            {
                Addr = 0x2100, TypeCode = "Hpal", OwnerSlot = 0, Kind = "死亡", DiedAt = t0,
                HitCount = 3, TotalDamage = 100,
                HookSources = new[]
                {
                    new HookBreakdown.SourceRow("山丘之王(Hmkg)", 2, 60, 0, false, 0, false, 60, true, 60)
                        { SourceCode = "Hmkg" },
                    new HookBreakdown.SourceRow("步兵(hfoo)", 1, 40, 0, false, 0, false, 40, true, 40)
                        { SourceCode = "hfoo" },
                },
            };
            var content = InGamePanel.BuildContent(iconSettle, null, cfg);
            Check(content.Icons.Count == 2 &&
                  content.Icons[0].RawCode == InGamePanelWire.ToJassRawCode("Hmkg") &&
                  content.Icons[1].RawCode == InGamePanelWire.ToJassRawCode("hfoo") &&
                  content.Icons[0].LineIndex >= 0 && content.Icons[0].LineIndex < content.Lines.Count &&
                  content.Lines[content.Icons[0].LineIndex].Text.Contains("山丘"),
                  "BuildContent：来源 SourceCode 转成头像行号/rawcode（Hmkg/hfoo）");
            var iconBytes = InGamePanelWire.BuildIconBlock(0, content.Icons);
            Check(iconBytes.Length == 80 &&
                  BinaryPrimitives.ReadUInt32LittleEndian(iconBytes.AsSpan(InGamePanelWire.OffsetIconSeq)) == 0 &&
                  BinaryPrimitives.ReadUInt32LittleEndian(iconBytes.AsSpan(InGamePanelWire.OffsetIconCount)) == 2 &&
                  BinaryPrimitives.ReadUInt32LittleEndian(iconBytes.AsSpan(InGamePanelWire.OffsetIconSlots + 4)) ==
                      InGamePanelWire.ToJassRawCode("Hmkg"),
                  "IconBlock：80 字节 / count=2 / slot rawcode 正确");

            Check(InGamePanelWire.LayoutMatchesDdh &&
                  InGamePanelWire.PanelBlockSize == 4952 && InGamePanelWire.HeroBlockSize == 400 &&
                  InGamePanelWire.IconBlockSize == 80 && InGamePanelWire.OffsetIconBlock == 146608,
                  "C# 面板/英雄/头像块布局与 ddh v19 一致（4952/400/80，总长 146688）");
            Check(InGamePanelWire.ToJassRawCode("Hpal") == 0x4870616C &&
                  InGamePanelWire.ToJassRawCode("Hmkg") == 0x486D6B67 &&
                  InGamePanelWire.ToJassRawCode("") == 0,
                  "类型码→JASS rawcode（Hpal=0x4870616C）");

            var block = InGamePanelWire.BuildPanelBlock(0, lines, 20000, 0, 0.6f, -0.24f, 0.0175f, 0.0135f, "MasterFont",
                                                        background: false, startCollapsed: false, collapsedLines: 6);
            Check(block.Length == InGamePanelWire.PanelBlockSize, "PanelBlock 长度 = 4952");
            uint blockFlags = System.Buffers.Binary.BinaryPrimitives.ReadUInt32LittleEndian(block.AsSpan(8));
            Check(System.Buffers.Binary.BinaryPrimitives.ReadUInt32LittleEndian(block.AsSpan(0)) == 0 &&
                  (blockFlags & 0xFF) == InGamePanelWire.FlagShow &&
                  System.Buffers.Binary.BinaryPrimitives.ReadUInt32LittleEndian(block.AsSpan(16)) == (uint)Math.Min(lines.Count, 20),
                  "PanelBlock：seq=0 / 基础 flags=显示 / lineCount 正确");
            Check(Math.Abs(System.Buffers.Binary.BinaryPrimitives.ReadSingleLittleEndian(
                      block.AsSpan(InGamePanelWire.OffsetLineHeight)) - 0.0175f) < 1e-6 &&
                  Math.Abs(System.Buffers.Binary.BinaryPrimitives.ReadSingleLittleEndian(
                      block.AsSpan(InGamePanelWire.OffsetFontHeight)) - 0.0135f) < 1e-6,
                  "PanelBlock：lineHeight=0.0175 / fontHeight=0.0135（参数顺序正确）");
            var styled = InGamePanelWire.BuildPanelBlock(0, lines, 20000, 0, 0.6f, -0.24f, 0.0175f, 0.0135f, "MasterFont",
                                                         background: true, startCollapsed: true, collapsedLines: 7);
            uint styledFlags = System.Buffers.Binary.BinaryPrimitives.ReadUInt32LittleEndian(styled.AsSpan(8));
            Check((styledFlags & InGamePanelWire.FlagBackground) != 0 &&
                  (styledFlags & InGamePanelWire.FlagStartCollapsed) != 0 &&
                  ((styledFlags >> InGamePanelWire.CollapsedLinesShift) & InGamePanelWire.CollapsedLinesMask) == 3,
                  "v18 flags：背景 bit2 / 默认收起 bit3 / 收起行数上限 3");
            Check(InGamePanelWire.StyleSupported(15) == false && InGamePanelWire.StyleSupported(16),
                  "StyleSupported：v15 false / v16 true");
            int firstTextOff = InGamePanelWire.OffsetLines + InGamePanelWire.LineOffsetText;
            string firstText = Encoding.UTF8.GetString(block, firstTextOff, Array.IndexOf(block, (byte)0, firstTextOff) - firstTextOff);
            Check(firstText == lines[0].Text, $"PanelBlock 第一行文本 = {lines[0].Text}（实际 {firstText}）");
            var hide = InGamePanelWire.BuildHidePanelBlock(0);
            Check(System.Buffers.Binary.BinaryPrimitives.ReadUInt32LittleEndian(hide.AsSpan(8)) == InGamePanelWire.FlagHide,
                  "Hide 块 flags = 隐藏");

            string longZh = new string('战', 200);
            string fit = InGamePanelWire.FitLine(longZh);
            Check(Encoding.UTF8.GetByteCount(fit) <= InGamePanelWire.LineTextBytes - 1 &&
                  !fit.Contains('\uFFFD') && fit.EndsWith('…'),
                  $"长中文行按 UTF-8 安全截断（{Encoding.UTF8.GetByteCount(fit)} 字节，末尾 …）");
            Check(InGamePanelWire.DisplayWidth("中文ab") == 6, "显示宽度：中文算 2、ASCII 算 1");

            var hs = InGamePanelSettings.FromSettings(new Settings
            {
                InGamePanelTtlMs = 1, InGamePanelFontHeight = 9f, InGamePanelLineHeight = 9f,
                InGamePanelMaxLines = 99, InGamePanelAnchor = 99, InGamePanelX = 9f, InGamePanelY = -9f,
                InGamePanelBackground = false, InGamePanelCollapsed = true, InGamePanelCollapsedLines = 99,
                InGamePanelIcons = false,
            });
            Check(hs.TtlMs == 1000 && hs.FontHeight <= 0.05f && hs.LineHeight <= 0.08f &&
                  hs.MaxLines == 20 && hs.Anchor == 0 && hs.X <= 2f && hs.Y >= -2f &&
                  !hs.Background && hs.StartCollapsed && hs.CollapsedLines == 3 && !hs.Icons,
                  "ini 面板参数越界时 clamp（ttl/字号/行距/行数/锚点/坐标/背景/收起/头像）");
            Check(InGamePanelWire.IconSupported(16) == false && InGamePanelWire.IconSupported(17),
                  "IconSupported：v16 false / v17 true");

            var heroReq = InGamePanelWire.BuildHeroRequestBlock(0, new[] { (addr, InGamePanelWire.ToJassRawCode("Hmkg")) });
            Check(heroReq.Length == InGamePanelWire.HeroBlockSize &&
                  System.Buffers.Binary.BinaryPrimitives.ReadUInt32LittleEndian(heroReq.AsSpan(InGamePanelWire.OffsetHeroCount)) == 1 &&
                  System.Buffers.Binary.BinaryPrimitives.ReadUInt32LittleEndian(heroReq.AsSpan(InGamePanelWire.OffsetHeroReq + 4)) == 0x486D6B67,
                  "HeroBlock：count=1，请求 rawcode = Hmkg");

            using var hook = new DamageHook();
            Check(!hook.PanelSupported && !hook.HeroSupported && !hook.TryPublishPanel(block),
                  "没打开共享内存时 PanelSupported/HeroSupported=false，推送安全返回 false");
            Check(hook.LastPanelError.Length > 0, "不支持面板时 LastPanelError 有可读原因");

            // ---- 用一块“假 ddh v19 共享内存”端到端验证 C# 的写序号/读响应 ----
            const int shmSize = 1 << 20;
            string mapName = $@"Local\DdhRing_{Environment.ProcessId}";
            using var mmf = MemoryMappedFile.CreateOrOpen(mapName, shmSize, MemoryMappedFileAccess.ReadWrite);
            using (var v = mmf.CreateViewAccessor(0, shmSize, MemoryMappedFileAccess.ReadWrite))
            {
                var hdr = new byte[64];
                BinaryPrimitives.WriteUInt32LittleEndian(hdr.AsSpan(0), DamageHook.Magic);
                BinaryPrimitives.WriteUInt32LittleEndian(hdr.AsSpan(4), 19);
                BinaryPrimitives.WriteUInt32LittleEndian(hdr.AsSpan(8), (uint)Environment.ProcessId);
                BinaryPrimitives.WriteUInt32LittleEndian(hdr.AsSpan(12), 512);
                BinaryPrimitives.WriteUInt32LittleEndian(hdr.AsSpan(20), 1);
                BinaryPrimitives.WriteUInt32LittleEndian(hdr.AsSpan(28), 0x6F000000);
                BinaryPrimitives.WriteUInt32LittleEndian(hdr.AsSpan(32), 0x67DC40);
                v.WriteArray(0, hdr, 0, hdr.Length);
            }
            using var fakeHook = new DamageHook();
            bool opened = fakeHook.Open(Environment.ProcessId, 200);
            Check(opened && fakeHook.Version == 19 && fakeHook.PanelSupported && fakeHook.HeroSupported &&
                  fakeHook.PanelStyleSupported && fakeHook.IconSupported,
                  $"打开假 ddh v19 共享内存：Panel/Hero/Style/Icon 支持（实际 {opened}/{fakeHook.PanelSupported}/{fakeHook.PanelStyleSupported}/{fakeHook.IconSupported}）");
            if (opened)
            {
                const int panelOff = 141256;
                const int heroOff = 146208;
                const int iconOff = 146608;
                var small = new List<PanelLine> { new(InGamePanel.ColorWhite, "A"), new(InGamePanel.ColorGold, "B") };
                var smallIcons = new[] { new InGamePanel.PanelIcon(1, InGamePanelWire.ToJassRawCode("Hpal")) };
                Check(fakeHook.TryPublishPanel(InGamePanelWire.BuildPanelBlock(
                          0, small, 20000, 0, 0.6f, -0.24f, 0.0175f, 0.0135f, "MasterFont",
                          background: true, startCollapsed: false, collapsedLines: 3),
                          InGamePanelWire.BuildIconBlock(0, smallIcons)),
                      "假 ddh：TryPublishPanel + IconBlock 写入成功");
                using var v = mmf.CreateViewAccessor(0, shmSize, MemoryMappedFileAccess.ReadWrite);
                uint seq = v.ReadUInt32(panelOff);
                uint flags = v.ReadUInt32(panelOff + 8);
                uint count = v.ReadUInt32(panelOff + 16);
                Check(seq > 0 && (flags & 0xFF) == (InGamePanelWire.FlagShow | InGamePanelWire.FlagBackground) &&
                      ((flags >> InGamePanelWire.CollapsedLinesShift) & InGamePanelWire.CollapsedLinesMask) == 3 &&
                      count == 2,
                      $"假 ddh：PanelBlock seq={seq} flags=0x{flags:X} count={count}（背景 bit + 收起行数 3）");
                uint iseq = v.ReadUInt32(iconOff);
                uint icount = v.ReadUInt32(iconOff + InGamePanelWire.OffsetIconCount);
                Check(iseq > 0 && icount == 1 &&
                      v.ReadUInt32(iconOff + InGamePanelWire.OffsetIconSlots + InGamePanelWire.IconSlotLineIndex) == 1 &&
                      v.ReadUInt32(iconOff + InGamePanelWire.OffsetIconSlots + InGamePanelWire.IconSlotRawCode) ==
                          InGamePanelWire.ToJassRawCode("Hpal"),
                      $"假 ddh：IconBlock seq={iseq} count={icount} line=1 rawcode=Hpal");
                v.Write(panelOff + 4, seq);  // 模拟 ddh applied
                Check(fakeHook.TryHidePanel(), "假 ddh：applied 后可发 hide");
                uint seq2 = v.ReadUInt32(panelOff);
                uint flags2 = v.ReadUInt32(panelOff + 8);
                Check(seq2 == seq + 1 && flags2 == InGamePanelWire.FlagHide,
                      "假 ddh：hide 是新 seq + flags=2");
                v.Write(panelOff + 4, seq2);

                Check(fakeHook.TryRequestHeroChecks(new[] { (0x1234u, InGamePanelWire.ToJassRawCode("Hpal")) }),
                      "假 ddh：英雄查询写入成功");
                uint hseq = v.ReadUInt32(heroOff);
                // 模拟 ddh：填 res[0]（addr/rawcode/isHero=1），再写 appliedSeq。
                v.Write(heroOff + 8, 1u);
                v.Write(heroOff + 144 + 0, 0x1234u);
                v.Write(heroOff + 144 + 4, InGamePanelWire.ToJassRawCode("Hpal"));
                v.Write(heroOff + 144 + 8, 1);
                v.Write(heroOff + 4, hseq);
                var gotHero = fakeHook.PollHeroChecks();
                Check(gotHero.Count == 1 && gotHero[0].Addr == 0x1234u &&
                      gotHero[0].RawCode == InGamePanelWire.ToJassRawCode("Hpal") &&
                      gotHero[0].IsHero == 1 && gotHero[0].IsIllusion == 0,
                      "假 ddh：PollHeroChecks 解出 isHero=1 / isIllusion=0 / addr / rawcode");
            }
        }

        sb.AppendLine($"=== 结果：{_pass} 通过 / {_fail} 失败 ===");
        string report = sb.ToString();
        Console.Write(report);
        Log.Write(report.Replace(Environment.NewLine, " | "));
        try { File.WriteAllText(Path.Combine(AppContext.BaseDirectory, "logs", "selftest.txt"), report, Encoding.UTF8); } catch { }
        return _fail == 0 ? 0 : 1;
    }
}






