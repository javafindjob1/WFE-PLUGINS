using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>
/// 极简设置持久化（exe 同目录的 War3DeathSettlement.ini）。
/// 只存几项：轮询间隔、深扫间隔、自动连接、上次连接的进程名/强制版本。
/// 写失败的唯一后果是下次启动回到默认值，不影响功能。
/// </summary>
public sealed class Settings
{
    public int IntervalMs = 50;
    public int DeepSeconds = 8;          // 0 = 关闭深度扫描
    public bool AutoAttach = true;
    public string LastProcessName = "";  // 上次成功连接/手动选中的进程名（用于放宽匹配）
    public string ForceVersion = "";     // 非空则强制用这个版本的地址表
    public bool ReadPluginLog = true;    // 读游戏内插件日志补上“伤害来源”

    /// <summary>攻击类型编号→名字（`1=普通,2=近战,3=穿刺`）；空 = 用内置表。</summary>
    public string AttackTypeLabels = "";

    /// <summary>伤害类型编号→名字（`4=普通,8=火焰,13=神圣`）；空 = 用内置表。</summary>
    public string DamageTypeLabels = "";
    public string PluginLogPath = @"C:\3rd\wc3gamesearcher\WFE\Application\Libraries\UDamageWatcher.log";

    public static string DefaultPath => Path.Combine(AppContext.BaseDirectory, "War3DeathSettlement.ini");

    public static Settings Load(string? path = null)
    {
        var s = new Settings();
        try
        {
            path ??= DefaultPath;
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
                    case "deep_seconds": if (int.TryParse(v, out int dv)) s.DeepSeconds = Math.Clamp(dv, 0, 600); break;
                    case "auto_attach": s.AutoAttach = v is "1" or "true" or "yes"; break;
                    case "last_process_name": s.LastProcessName = v; break;
                    case "force_version": s.ForceVersion = v; break;
                    case "read_plugin_log": s.ReadPluginLog = v is "1" or "true" or "yes"; break;
                    case "plugin_log_path": if (v.Length > 0) s.PluginLogPath = v; break;
                case "atype_labels": s.AttackTypeLabels = v; break;
                case "dtype_labels": s.DamageTypeLabels = v; break;
                }
            }
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
            sb.AppendLine("; deep_seconds  : 深度扫描间隔秒；0 = 关闭（关闭后不再发现新单位）");
            sb.AppendLine("; auto_attach   : 1 = 启动后自动找游戏");
            sb.AppendLine("; last_process_name : 上次连接的进程名（自动连接会一并尝试它）");
            sb.AppendLine("; force_version : 非空则强制用这个版本的地址表，例如 1.27.0.52240");
            sb.AppendLine("; read_plugin_log : 1 = 读游戏内插件日志，把“伤害来源/攻击类型”补进结算（插件在跑才有）");
            sb.AppendLine("; plugin_log_path : 插件日志路径");
            sb.AppendLine();
            sb.AppendLine($"interval_ms={IntervalMs}");
            sb.AppendLine($"deep_seconds={DeepSeconds}");
            sb.AppendLine($"auto_attach={(AutoAttach ? 1 : 0)}");
            sb.AppendLine($"last_process_name={LastProcessName}");
            sb.AppendLine($"force_version={ForceVersion}");
            sb.AppendLine($"read_plugin_log={(ReadPluginLog ? 1 : 0)}");
            sb.AppendLine($"plugin_log_path={PluginLogPath}");
        sb.AppendLine($"atype_labels={AttackTypeLabels}");
        sb.AppendLine($"dtype_labels={DamageTypeLabels}");
            File.WriteAllText(path, sb.ToString(), new UTF8Encoding(false));
        }
        catch (Exception ex) { Log.Warn("写设置失败：" + ex.Message); }
    }

    public AttachOptions ToAttach() =>
        new(null, string.IsNullOrWhiteSpace(LastProcessName) ? null : LastProcessName,
            string.IsNullOrWhiteSpace(ForceVersion) ? null : ForceVersion);
}


