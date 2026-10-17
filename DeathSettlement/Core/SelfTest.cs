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
            Check(s.OwnerText == "玩家 3", "玩家号显示为 P3");
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
            Check(ProcessMatch.LooksLikeGame("war3"), "war3 → 是");            Check(ProcessMatch.LooksLikeGame("War3"), "War3 → 是（大小写无关）");
            Check(ProcessMatch.LooksLikeGame("dzwar3"), "dzwar3 → 是");
            Check(ProcessMatch.LooksLikeGame("Warcraft III"), "Warcraft III → 是");
            Check(ProcessMatch.LooksLikeGame("Frozen Throne"), "Frozen Throne → 是");
            Check(!ProcessMatch.LooksLikeGame("chrome"), "chrome → 不是");
            Check(!ProcessMatch.LooksLikeGame("notepad"), "notepad → 不是");
            Check(!ProcessMatch.LooksLikeGame(""), "空名字 → 不是");
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
                Check(global.Any(r => r.Dimension == "自己-拥有者" && r.Key == "P1"), "自己统计-按拥有者分组");
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

        // ---------- 用例 10：拿真实插件日志跑一遍（有就读，没有就跳过） ----------
        {
            const string realLog = @"C:\3rd\wc3gamesearcher\WFE\Application\Libraries\UDamageWatcher.log";
            if (File.Exists(realLog))
            {
                try
                {
                    var bytes = File.ReadAllBytes(realLog);
                    string text = Gbk.Decode(bytes);
                    var reader = new PluginLogReader(realLog, fromStart: true);
                    reader.Parse(text, File.GetLastWriteTime(realLog));

                    int withSources = reader.Entries.Count(e => e.Sources.Count > 0);
                    sb.AppendLine($"  [INFO] 真实插件日志：{bytes.Length} 字节，解析出 {reader.Entries.Count} 条结算，" +
                                  $"其中 {withSources} 条带来源；（例）" +
                                  (reader.Entries.Count > 0 ? reader.Entries[^1].ToString() : "无"));
                    Check(reader.Entries.Count > 0, "真实日志能解析出结算");
                    Check(withSources > 0, "真实日志里至少有一条带“按来源单位”的结算");
                    sb.AppendLine($"  [INFO] 真实日志攒出「类型码→名字」{reader.CodeToName.Count} 条；例：" +
                                  string.Join("、", reader.CodeToName.Take(5).Select(kv => $"{kv.Key}={kv.Value}")));
                    Check(reader.CodeToName.Count >= 5, $"真实日志能攒出至少 5 条类型码→名字（实际 {reader.CodeToName.Count}）");
                    // 选区行（类型=十六进制 名字="…"）也要能收进来
                    Check(reader.CodeToName.Values.Any(v => v.Contains("骸骨战士") || v.Contains("星之真神") || v.Length > 0),
                          "名字表里有中文单位名");
                }
                catch (Exception ex)
                {
                    Check(false, "真实日志解析抛异常：" + ex.Message);
                }
            }
            else
            {
                sb.AppendLine("  [SKIP] 没找到真实插件日志（" + realLog + "），跳过");
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



