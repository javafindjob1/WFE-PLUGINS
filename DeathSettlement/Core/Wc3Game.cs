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

    /// <summary>找出正在运行的魔兽进程（与 War3Trainer 的 FrmMain::FindGame 同思路：按进程名找）。</summary>
    public static List<Process> FindCandidates()
    {
        var result = new List<Process>();
        foreach (var p in Process.GetProcesses())
        {
            try
            {
                foreach (var n in ProcessNames)
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
        return result;
    }

    /// <summary>尝试连接；无论成功失败都返回带诊断信息的对象（失败时 State 说明原因）。</summary>
    public static Wc3Game Attach()
    {
        var candidates = FindCandidates();
        if (candidates.Count == 0)
        {
            return new Wc3Game
            {
                State = AttachState.NoProcess,
                Message = "游戏未运行 —— 先启动魔兽，再点【查找游戏】。"
            };
        }

        string lastError = "";
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

                string versionRaw = ReadModuleVersion(gameDll.Path) ?? ReadModuleVersion(rp.MainModulePath) ?? "";
                if (!Wc3Versions.TryGet(versionRaw, out var ver))
                {
                    lastError = $"检测到游戏（PID {proc.Id}），但版本（{versionRaw}）不被支持。";
                    rp.Dispose();
                    continue;
                }

                var g = new Wc3Game { Mem = rp, Version = ver, GameDll = gameDll };
                g.Refresh();
                if (g.State == AttachState.Ready) return g;
                lastError = g.Message;
            }
            catch (Exception ex)
            {
                lastError = "连接异常：" + ex.Message;
                rp?.Dispose();
            }
        }

        return new Wc3Game
        {
            State = AttachState.UnsupportedVersion,
            Message = lastError.Length > 0 ? lastError : "没有可用的魔兽进程。"
        };
    }

    private static string? ReadModuleVersion(string? path)
    {
        if (string.IsNullOrEmpty(path) || !File.Exists(path)) return null;
        try
        {
            var fv = FileVersionInfo.GetVersionInfo(path);
            return !string.IsNullOrWhiteSpace(fv.ProductVersion) ? fv.ProductVersion : fv.FileVersion;
        }
        catch { return null; }
    }

    /// <summary>重新读取三个全局（地图载入/换图后数值会变）。</summary>
    public void Refresh()
    {
        Ctx = Mem.U32(GameDllBase + Version.UnitListRva);
        ThisGame = Mem.U32(GameDllBase + Version.ThisGameRva);
        GameMemory = ThisGame != 0 ? Mem.U32(ThisGame + 0x0C) : 0;

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
