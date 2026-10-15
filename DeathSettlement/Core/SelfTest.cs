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

        // ---------- 用例 6：CSV / 文本导出行数 ----------
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

        {
            var tr = new DamageTracker();
            var t0 = new DateTime(2026, 1, 1, 12, 0, 0);
            tr.Update(Scan((0x6000u, "uske", 300f, 300f, 2)), t0);
            tr.Update(Scan((0x6000u, "uske", 0f, 300f, 2)), t0.AddMilliseconds(50));
            var s = tr.Settlements[0];
            Check(s.ToCsvRow().Split(',').Length == Settlement.CsvHeader.Split(',').Length, "CSV 列数与表头一致");
            Check(s.ToText().Contains("死亡结算"), "文本结算含标题");
            Check(s.OwnerText == "玩家 3", "玩家号显示为 P3");
        }

        sb.AppendLine($"=== 结果：{_pass} 通过 / {_fail} 失败 ===");
        string report = sb.ToString();
        Console.Write(report);
        Log.Write(report.Replace(Environment.NewLine, " | "));
        try { File.WriteAllText(Path.Combine(AppContext.BaseDirectory, "logs", "selftest.txt"), report, Encoding.UTF8); } catch { }
        return _fail == 0 ? 0 : 1;
    }
}
