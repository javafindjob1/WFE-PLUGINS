using War3DeathSettlement.Core;

namespace War3DeathSettlement.Ui;

/// <summary>
/// 按单位对象地址解析“所属玩家”。统一走 Core.OwnerResolver（CUnit+0x58 直读），
/// 与 UnitScanner（单位跟踪 / 死亡结算）共用同一结果，保证各处显示一致。
/// 结果按地址缓存 —— 伤害事件页/双击弹窗每行都要显示玩家，绝不能每个事件都去读一次内存。
/// 缓存只对“同一局游戏”有效：游戏对象引用变化后整体清空。
/// 所有内存读取都走 RemoteProcess（只读、带异常保护）；读失败退回 “?”。
/// </summary>
internal sealed class UnitOwnerResolver
{
    private readonly Func<Wc3Game?> _game;
    private readonly Dictionary<uint, string> _cache = new();
    private Wc3Game? _lastGame;
    private uint[] _players = Array.Empty<uint>();
    private int _ownerOffset = -1;
    private DateTime _playersAt = DateTime.MinValue;

    public UnitOwnerResolver(Func<Wc3Game?> game) => _game = game;

    /// <summary>单位地址 → 玩家显示文本（“Player N” 或 “?”）。</summary>
    public string PlayerText(uint addr)
    {
        if (addr == 0) return "?";
        var g = _game();
        if (!ReferenceEquals(g, _lastGame))
        {
            _lastGame = g;
            _cache.Clear();
            _players = Array.Empty<uint>();
            _ownerOffset = -1;
            _playersAt = DateTime.MinValue;
        }
        if (_cache.TryGetValue(addr, out var cached)) return cached;

        string text = "?";
        try
        {
            if (g != null && g.IsReady)
            {
                // 玩家对象数组只为兼容接口保留；拥有者本身由 CUnit+0x58 直接读取。
                if ((DateTime.UtcNow - _playersAt).TotalSeconds > 3)
                {
                    var np = g.ReadPlayerObjects();
                    if (!SamePlayers(_players, np) || g.OwnerOffset != _ownerOffset)
                        _cache.Clear();
                    _players = np;
                    _ownerOffset = g.OwnerOffset;
                    _playersAt = DateTime.UtcNow;
                }

                int slot = OwnerResolver.Resolve(g, addr, _players, _ownerOffset, out _, out _);
                if (slot >= 0) text = UnitEvents.FormatPlayer(slot);
            }
        }
        catch
        {
            // 读内存失败 → 保持 “?”（不要崩界面）
        }

        _cache[addr] = text;
        return text;
    }

    private static bool SamePlayers(uint[] a, uint[] b)
    {
        if (a.Length != b.Length) return false;
        for (int i = 0; i < a.Length; i++)
            if (a[i] != b[i]) return false;
        return true;
    }
}
