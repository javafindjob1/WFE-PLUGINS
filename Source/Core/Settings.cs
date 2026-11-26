using System.Globalization;
using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>
/// 极简设置持久化（exe 同目录的 War3DeathSettlement.ini）。
/// 只存几项：轮询间隔、自动连接、上次连接的进程名/强制版本。
/// 写失败的唯一后果是下次启动回到默认值，不影响功能。
/// </summary>
public sealed class Settings
{
    public int IntervalMs = 50;
    public bool AutoAttach = true;
    public string LastProcessName = "";  // 上次成功连接/手动选中的进程名（用于放宽匹配）
    public string ForceVersion = "";     // 非空则强制用这个版本的地址表
    public bool ReadPluginLog = true;    // 读游戏内插件日志补上“伤害来源”

    /// <summary>侵入式伤害事件：注入 ddh.dll 挂引擎伤害函数（能看到 是否攻击/远程/攻击类型/伤害类型/来源）。</summary>
    public bool HookEnabled = true;   // 默认开：伤害钩子是常规功能，界面上不再给开关
    public string HookDll = "hook\\ddh.dll";
    public string HookInjector = "hook\\ddh_inject.exe";
    /// <summary>连接游戏后由桌面 C# 进程启动 Vue WebHost（避开 War3 的 Job 限制）。</summary>
    public bool WebHostAutoStart = true;
    public string WebHostExe = @"C:\launch\ddh_web\ddh_web.exe";
    public string WebHostHtml = @"C:\launch\ddh_web\dss.html";

    /// <summary>
    /// "钩子需要管理员权限"那条启动提示是否已经显示过。
    /// 钩子默认开着，如果每次启动都弹窗就成了骚扰；弹一次、记进 ini，之后只在日志里写一行。
    /// 想再看一次就把 ini 里的 hook_admin_hint_shown 改成 0。
    /// </summary>
    public bool HookAdminHintShown = false;

    /// <summary>攻击类型编号→名字（`1=普通,2=近战,3=穿刺`）；空 = 用内置表。</summary>
    public string AttackTypeLabels = "";

    /// <summary>伤害类型编号→名字（`4=普通,8=火焰,13=神圣`）；空 = 用内置表。</summary>
    public string DamageTypeLabels = "";
    public string PluginLogPath = @"C:\3rd\wc3gamesearcher\WFE\Application\Libraries\UDamageWatcher.log";

    /// <summary>
    /// 手动按名字忽略单位的默认关键字：**空**。
    /// 马甲单位不再按名字写死，而是由 ddh 对每个伤害目标实测
    /// `GetUnitAbilityLevel(handle, 'Aloc') > 0`（与 YDWE 同口径：&lt;= 0 = 普通单位，&gt; 0 = 马甲）。
    /// </summary>
    public const string DefaultIgnoreUnitNames = "";

    /// <summary>
    /// 手动按名字忽略的单位（可选，默认空 = 不按名字过滤）：名字包含任一关键字就不进死亡结算；
    /// 逗号/分号分隔。注意：这是**用户自定义**的忽略名单，不参与“马甲”判定；
    /// 马甲判定只看 Aloc（ddh flags bit0）。
    /// ini: ignore_unit_names；环境变量 DSS_IGNORE_UNIT_NAMES 可覆盖。
    /// </summary>
    public string IgnoreUnitNames = DefaultIgnoreUnitNames;

    /// <summary>
    /// 盟友玩家号（0 基，逗号/分号分隔，例如 "1,2"）。本地玩家自己的单位恒为盟友。
    /// 只影响【战场单位】的排序/颜色；中立玩家（12~15）不显示。
    /// </summary>
    public string AllySlots = "";

    /// <summary>解析 ally_slots；忽略越界/非法项。</summary>
    public HashSet<int> AllySlotSet()
    {
        var set = new HashSet<int>();
        foreach (var part in AllySlots.Split(new[] { ',', ';', ' ', '，', '；' }, StringSplitOptions.RemoveEmptyEntries))
            if (int.TryParse(part.Trim(), out int n) && n >= 0 && n < 24) set.Add(n);
        return set;
    }

    public static string DefaultPath => Path.Combine(AppContext.BaseDirectory, "War3DeathSettlement.ini");

    public static Settings Load(string? path = null)
    {
        var s = new Settings();
        try
        {
            path ??= DefaultPath;
            // 环境变量先读出来：即使没有 ini 也要能覆盖（自动化测试就是靠它）。
            var envIgnoreNames = Environment.GetEnvironmentVariable("DSS_IGNORE_UNIT_NAMES");
            if (envIgnoreNames != null) s.IgnoreUnitNames = envIgnoreNames;
            if (!File.Exists(path)) return s;
            foreach (var raw in File.ReadAllLines(path, Encoding.UTF8))
            {
                var line = raw.Trim();
                if (line.Length == 0 || line.StartsWith(';') || line.StartsWith('#')) continue;
                int eq = line.IndexOf('=');
                if (eq <= 0) continue;
                string k = line[..eq].Trim().ToLowerInvariant();
                string v = line[(eq + 1)..].Trim();
                switch (k)
                {
                    case "interval_ms": if (int.TryParse(v, out int iv)) s.IntervalMs = Math.Clamp(iv, 10, 5000); break;
                    // 老 ini 里已废弃的深扫配置项：落到 default 被静默忽略，不报错、也不再写回。
                    case "auto_attach": s.AutoAttach = v is "1" or "true" or "yes"; break;
                    case "last_process_name": s.LastProcessName = v; break;
                    case "force_version": s.ForceVersion = v; break;
                    case "read_plugin_log": s.ReadPluginLog = v is "1" or "true" or "yes"; break;
                    case "plugin_log_path": if (v.Length > 0) s.PluginLogPath = v; break;
                case "hook_enable": s.HookEnabled = v is "1" or "true" or "yes"; break;
                case "hook_dll": if (v.Length > 0) s.HookDll = v; break;
                case "hook_injector": if (v.Length > 0) s.HookInjector = v; break;
                case "webhost_auto_start": s.WebHostAutoStart = v is "1" or "true" or "yes" or "on"; break;
                case "webhost_exe": if (v.Length > 0) s.WebHostExe = v; break;
                case "webhost_html": if (v.Length > 0) s.WebHostHtml = v; break;
                case "hook_admin_hint_shown": s.HookAdminHintShown = v is "1" or "true" or "yes" or "on"; break;
                case "atype_labels": s.AttackTypeLabels = v; break;
                case "dtype_labels": s.DamageTypeLabels = v; break;
                case "ignore_unit_names": s.IgnoreUnitNames = v; break;
                case "ally_slots": s.AllySlots = v; break;
                }
            }

            // 环境变量优先于 ini（没有 ini 时前面已经生效，这里再覆盖一次，避免被 ini 里的值盖掉）
            if (envIgnoreNames != null) s.IgnoreUnitNames = envIgnoreNames;
        }
        catch (Exception ex) { Log.Warn("读设置失败：" + ex.Message); }
        return s;
    }

    public void Save(string? path = null)
    {
        try
        {
            path ??= DefaultPath;
            var sb = new StringBuilder();
            sb.AppendLine("; 魔兽死亡结算 War3DeathSettlement 设置（改完保存即可，下次启动生效）");
            sb.AppendLine("; interval_ms   : 轮询间隔毫秒（10~5000）");
            sb.AppendLine("; auto_attach   : 1 = 启动后自动找游戏");
            sb.AppendLine("; last_process_name : 上次连接的进程名（自动连接会一并尝试它）");
            sb.AppendLine("; force_version : 非空则强制用这个版本的地址表，例如 1.27.0.52240");
            sb.AppendLine("; read_plugin_log : 1 = 读游戏内插件日志，把“伤害来源/攻击类型”补进结算（插件在跑才有）");
            sb.AppendLine("; plugin_log_path : 插件日志路径");
            sb.AppendLine();
            sb.AppendLine($"interval_ms={IntervalMs}");
            sb.AppendLine($"auto_attach={(AutoAttach ? 1 : 0)}");
            sb.AppendLine($"last_process_name={LastProcessName}");
            sb.AppendLine($"force_version={ForceVersion}");
            sb.AppendLine($"read_plugin_log={(ReadPluginLog ? 1 : 0)}");
            sb.AppendLine($"plugin_log_path={PluginLogPath}");
        sb.AppendLine("; hook_enable : 1 = 注入 ddh.dll，挂钩引擎伤害函数，直接拿到 是否攻击/远程/攻击类型/伤害类型/伤害值（侵入式）");
        sb.AppendLine($"hook_enable={(HookEnabled ? 1 : 0)}");
        sb.AppendLine($"hook_dll={HookDll}");
        sb.AppendLine($"hook_injector={HookInjector}");
        sb.AppendLine("; webhost_auto_start : 1 = C# 连接游戏后在游戏 Job 外启动 Vue WebHost");
        sb.AppendLine($"webhost_auto_start={(WebHostAutoStart ? 1 : 0)}");
        sb.AppendLine($"webhost_exe={WebHostExe}");
        sb.AppendLine($"webhost_html={WebHostHtml}");
        sb.AppendLine("; hook_admin_hint_shown : 1 = 已提示过“钩子需要管理员权限”（改回 0 可再提示一次）");
        sb.AppendLine($"hook_admin_hint_shown={(HookAdminHintShown ? 1 : 0)}");
        sb.AppendLine($"atype_labels={AttackTypeLabels}");
        sb.AppendLine($"dtype_labels={DamageTypeLabels}");
        sb.AppendLine("; ignore_unit_names : 手动按名字忽略单位（可选，默认空）；名字包含任一关键字就不进死亡结算；逗号/分号分隔。马甲单位由 Aloc 技能自动判定，不靠这里（环境变量 DSS_IGNORE_UNIT_NAMES 可覆盖）");
        sb.AppendLine($"ignore_unit_names={IgnoreUnitNames}");
        sb.AppendLine("; ally_slots : 盟友玩家号（0 基，逗号分隔，例如 1,2）。战场单位按 盟友→敌人→名称 排序；本地玩家自己的单位恒为盟友。中立玩家(12~15)不显示");
        sb.AppendLine($"ally_slots={AllySlots}");
        sb.AppendLine();
            File.WriteAllText(path, sb.ToString(), new UTF8Encoding(false));
        }
        catch (Exception ex) { Log.Warn("写设置失败：" + ex.Message); }
    }

    public AttachOptions ToAttach() =>
        new(null, string.IsNullOrWhiteSpace(LastProcessName) ? null : LastProcessName,
            string.IsNullOrWhiteSpace(ForceVersion) ? null : ForceVersion);
}


