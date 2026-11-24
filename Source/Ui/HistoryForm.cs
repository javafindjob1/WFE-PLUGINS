using System.Diagnostics;
using War3DeathSettlement.Core;

namespace War3DeathSettlement.Ui;

/// <summary>
/// 【历史】窗口（非模态、只读）：
///   左 = 对局列表（时间 / 地图 / 时长 / 事件数，按时间倒序，双击加载）；
///   右 = 上：死亡结算表（列同主页）；下：选中结算的分组统计（Sources/Combos）。
///   双击结算行 → 按这个单位打开伤害明细（UnitEventsForm，和主页双击结算行一致）。
/// 数据只读 ddh 的 game_sessions / game_events / game_units / game_settlements。
/// C# 不保存历史，不读取旧 history.db、JSON 或 PID 表。
/// **所有库 I/O 都在后台线程（Task.Run）**：打开窗口/刷新/双击加载都不会卡住 UI 线程，
/// 期间用“正在加载…”占位。
/// </summary>
internal sealed class HistoryForm : Form
{
    private const string WindowTitle = "对局历史 - War3DeathSettlement";

    private readonly Grid _gridMatches = new();
    private readonly Grid _gridSettle = new();
    /// <summary>死亡结算行右键菜单（查看单位属性：血量/攻击力/攻击间隔/护甲/技能）。</summary>
    private readonly ContextMenuStrip _settleMenu = new();
    private readonly Grid _gridBreak = new();
    /// <summary>历史结算表的表头搜索（与主页共用 SettlementHeaderSearch / SettlementGridUi 谓词）。</summary>
    private SettlementHeaderSearch _settleSearch = null!;

    private readonly Button _btnRefresh = new() { Text = "刷新" };
    private readonly Button _btnOpenDir = new() { Text = "打开目录" };
    /// <summary>查看该局落盘的【战场单位】快照（新功能；老库没有数据时提示为空）。</summary>
    private readonly Button _btnUnits = new() { Text = "战场单位" };
    private readonly Label _lblMatches = new();
    private readonly Label _lblSettle = new();
    private readonly Label _lblBreak = new();
    private readonly Label _lblInfo = new();

    private SplitContainer _outer = null!;
    private SplitContainer _rightTop = null!;

    private List<HistoryFileInfo> _files = new();
    private HistoryDocument? _doc;
    private HistorySettlement? _selected;
    private List<DamageHook.HookEvent> _events = new();
    private string _currentPath = "";
    private bool _loading;

    /// <summary>主文件路径 → 左表行（后台补摘要完成后按行更新，不重建整表）。</summary>
    private readonly Dictionary<string, DataGridViewRow> _matchRows = new(StringComparer.OrdinalIgnoreCase);
    /// <summary>列表加载版本号：刷新/重新打开时让旧的后台任务自动作废。</summary>
    private int _listVersion;
    private bool _listLoading;
    private bool _docLoading;

    /// <summary>已经弹过提示的损坏文件（一次性 MessageBox：同一文件不在每次刷新时反复弹）。</summary>
    private readonly HashSet<string> _notifiedBroken = new(StringComparer.OrdinalIgnoreCase);
    private bool _brokenSummaryShown;
    public HistoryForm()
    {
        Text = WindowTitle;
        Width = 1500;
        Height = 900;
        MinimumSize = new Size(1100, 650);
        StartPosition = FormStartPosition.CenterParent;
        ShowInTaskbar = false;
        BackColor = Color.FromArgb(24, 24, 28);
        ForeColor = Color.Gainsboro;
        Font = new Font("Microsoft YaHei UI", 9F);

        BuildUi();
        Shown += (_, _) =>
        {
            // 历史窗比主页大，CenterParent 可能把底部顶到屏幕外：按当前屏幕工作区夹一次。
            try
            {
                var wa = Screen.FromControl(this).WorkingArea;
                Width = Math.Min(Width, wa.Width);
                Height = Math.Min(Height, wa.Height);
                Left = Math.Clamp(Left, wa.Left, Math.Max(wa.Left, wa.Right - Width));
                Top = Math.Clamp(Top, wa.Top, Math.Max(wa.Top, wa.Bottom - Height));
            }
            catch { }

            // 分隔条位置要等布局真正完成（BeginInvoke）后再设：构造/首次 Layout 时子 SplitContainer
            // 的 Width/Height 还是默认值，直接设 PanelMinSize/SplitterDistance 会抛
            // “SplitterDistance 必须在 Panel1MinSize 和 Width - Panel2MinSize 之间”。
            BeginInvoke(new Action(() =>
            {
                SetSplit(_outer, 0.29, 300, 500, vertical: true);
                SetSplit(_rightTop, 0.46, 160, 260, vertical: false);
                ReloadListAsync();
            }));
        };
    }

    /// <summary>安全设置分隔条：先按当前真实尺寸夹住 MinSize/距离，任何一步失败都只跳过（不影响窗口）。</summary>
    private static void SetSplit(SplitContainer sc, double ratio, int min1, int min2, bool vertical)
    {
        try
        {
            int size = vertical ? sc.Width : sc.Height;
            if (size <= 0) return;
            if (size <= min1 + min2 + 8)
            {
                min1 = Math.Max(25, size / 5);
                min2 = Math.Max(25, size / 5);
            }
            sc.Panel1MinSize = min1;
            sc.Panel2MinSize = min2;
            int max = Math.Max(min1, size - min2);
            sc.SplitterDistance = Math.Clamp((int)(size * ratio), min1, max);
        }
        catch { }
    }

    // ------------------------------------------------------------------
    private void BuildUi()
    {
        // ---- 顶部：标题 + 刷新 / 打开目录 ----
        var top = new FlowLayoutPanel
        {
            Dock = DockStyle.Top,
            Height = 40,
            BackColor = Color.FromArgb(40, 40, 46),
            ForeColor = Color.Gainsboro,
            WrapContents = false,
            Padding = new Padding(6, 5, 6, 5),
        };
        var title = new Label
        {
            // ddh 明细库最多保留 50 个 session；历史窗口自身不再按局数截断。
            Text = "对局历史（按时间倒序；双击左侧一局加载）",
            AutoSize = true,
            ForeColor = Color.Khaki,
            Margin = new Padding(2, 6, 16, 0),
        };
        StyleButton(_btnRefresh, Color.FromArgb(50, 50, 58));
        StyleButton(_btnOpenDir, Color.FromArgb(50, 50, 58));
        if (FeatureFlags.BattlefieldUnitsEnabled)
            StyleButton(_btnUnits, Color.FromArgb(50, 50, 58));
        _btnRefresh.Click += (_, _) => ReloadListAsync();
        _btnOpenDir.Click += (_, _) => OpenHistoryDir();
        if (FeatureFlags.BattlefieldUnitsEnabled)
            _btnUnits.Click += (_, _) => ShowUnitsOfLoadedMatch();
        top.Controls.Add(title);
        top.Controls.Add(_btnRefresh);
        top.Controls.Add(_btnOpenDir);
        if (FeatureFlags.BattlefieldUnitsEnabled) top.Controls.Add(_btnUnits);

        // ---- 左：对局列表 ----
        _gridMatches.Dock = DockStyle.Fill;
        _gridMatches.AddText("时间", "time", 145);
        _gridMatches.AddText("地图", "map", 150);
        _gridMatches.AddText("时长", "dur", 65);
        _gridMatches.AddText("事件", "events", 65);
        foreach (DataGridViewColumn col in _gridMatches.Columns)
        {
            col.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
            col.FillWeight = Math.Max(8, col.Width);
            col.MinimumWidth = 45;
        }
        _gridMatches.CellClick += (_, e) => OnMatchDoubleClick(e);
        _gridMatches.CellDoubleClick += (_, e) => OnMatchDoubleClick(e);

        _lblMatches.Dock = DockStyle.Top;
        _lblMatches.Height = 26;
        _lblMatches.TextAlign = ContentAlignment.MiddleLeft;
        _lblMatches.Padding = new Padding(8, 0, 0, 0);
        _lblMatches.BackColor = Color.FromArgb(32, 32, 38);
        _lblMatches.ForeColor = Color.Khaki;
        _lblMatches.Text = "对局列表";

        var leftPanel = new Panel { Dock = DockStyle.Fill };
        leftPanel.Controls.Add(_gridMatches);
        // 不再显示“对局列表（…局，按时间倒序…）”标题行：表格直接占满左栏。

        // ---- 右上：死亡结算 ----
        _gridSettle.Dock = DockStyle.Fill;
        SettlementGridUi.AddColumns(_gridSettle);
        _gridSettle.RowTemplate.Height = 36;
        _gridSettle.DefaultCellStyle.WrapMode = DataGridViewTriState.True;
        // 历史窗口右侧比主页窄：结算表按设计宽度等比例 Fill（列与主页一致，只是不横向溢出）。
        foreach (DataGridViewColumn col in _gridSettle.Columns)
        {
            col.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
            int weight = Math.Max(8, col.Width);
            // 「单位名」「类型码」要放得下过滤指示（单位名（⌕ …））；历史窗口窄，多给 40% 权重，
            // 不然长一点的关键词会把表头指示裁成“类型码（⌕”。
            if (col.Name is SettlementGridUi.NameColumn or SettlementGridUi.CodeColumn)
                weight = Math.Max(8, (int)(weight * 1.4));
            col.FillWeight = weight;
            col.MinimumWidth = 40;
        }
        // 表头搜索：点「单位名」/「类型码」表头 → 浮出搜索框，过滤后按同一个谓词重填本表。
        _settleSearch = SettlementHeaderSearch.ForSettlement(_gridSettle, ApplySettleFilter);
        _gridSettle.SelectionChanged += (_, _) => OnSettleSelectionChanged();
        _gridSettle.CellDoubleClick += (_, e) => OnSettleDoubleClick(e);
        BuildSettleMenu();

        _lblSettle.Dock = DockStyle.Top;
        _lblSettle.Height = 26;
        _lblSettle.TextAlign = ContentAlignment.MiddleLeft;
        _lblSettle.Padding = new Padding(8, 0, 0, 0);
        _lblSettle.BackColor = Color.FromArgb(32, 32, 38);
        _lblSettle.ForeColor = Color.Khaki;
        _lblSettle.Text = "死亡结算（未加载对局）";

        var settlePanel = new Panel { Dock = DockStyle.Fill };
        settlePanel.Controls.Add(_gridSettle);
        // 不再显示“死亡结算（…条，新的在上…）”标题行：表格直接占满右栏。

        // ---- 右中：选中结算的分组统计 ----
        _gridBreak.Dock = DockStyle.Fill;
        SettlementGridUi.AddBreakdownColumns(_gridBreak);
        _gridBreak.RowTemplate.Height = 36;
        _gridBreak.DefaultCellStyle.WrapMode = DataGridViewTriState.True;

        _lblBreak.Dock = DockStyle.Top;
        _lblBreak.Height = 26;
        _lblBreak.TextAlign = ContentAlignment.MiddleLeft;
        _lblBreak.Padding = new Padding(8, 0, 0, 0);
        _lblBreak.BackColor = Color.FromArgb(32, 32, 38);
        _lblBreak.ForeColor = Color.Khaki;
        _lblBreak.Text = "分组统计（选中上面的结算行）";

        var breakPanel = new Panel { Dock = DockStyle.Fill };
        breakPanel.Controls.Add(_gridBreak);
        breakPanel.Controls.Add(_lblBreak);

        // ---- 右侧：上=死亡结算，下=选中结算的分组统计 ----
        // 整局“伤害明细”不再常驻：双击结算行 → 按这个单位打开 UnitEventsForm（和主页双击一致）。
        _rightTop = new SplitContainer
        {
            Dock = DockStyle.Fill,
            Orientation = Orientation.Horizontal,
            BackColor = Color.FromArgb(40, 40, 46),
        };
        _rightTop.Panel1.Controls.Add(settlePanel);
        _rightTop.Panel2.Controls.Add(breakPanel);

        _outer = new SplitContainer
        {
            Dock = DockStyle.Fill,
            Orientation = Orientation.Vertical,
            BackColor = Color.FromArgb(40, 40, 46),
            FixedPanel = FixedPanel.Panel1,
        };
        _outer.Panel1.Controls.Add(leftPanel);
        _outer.Panel2.Controls.Add(_rightTop);

        // ---- 底部状态 ----
        _lblInfo.Dock = DockStyle.Bottom;
        _lblInfo.Height = 26;
        _lblInfo.TextAlign = ContentAlignment.MiddleLeft;
        _lblInfo.Padding = new Padding(8, 0, 0, 0);
        _lblInfo.BackColor = Color.FromArgb(40, 40, 46);
        _lblInfo.ForeColor = Color.LightGray;
        _lblInfo.AutoEllipsis = true;
        _lblInfo.Text = "ddh 明细库：" + DdhHistoryReader.DatabasePath;

        Controls.Add(_outer);
        Controls.Add(_lblInfo);
        Controls.Add(top);
    }

    private static void StyleButton(Button b, Color back)
    {
        b.FlatStyle = FlatStyle.Flat;
        b.BackColor = back;
        b.ForeColor = Color.Gainsboro;
        b.FlatAppearance.BorderColor = Color.FromArgb(80, 80, 90);
    }

    // ------------------------------------------------------------------
    /// <summary>
    /// 重新读历史列表（**后台** Task.Run）。读取期间左表显示“正在加载历史列表…”占位、
    /// 禁用列表/刷新；完成后回 UI 线程填表。
    /// </summary>
    private async void ReloadListAsync()
    {
        int version = ++_listVersion;
        _listLoading = true;
        _btnRefresh.Enabled = false;
        _gridMatches.Enabled = false;
        _gridMatches.Rows.Clear();
        _matchRows.Clear();

        int placeholder = _gridMatches.Rows.Add("正在加载历史列表…", "", "", "");
        _gridMatches.Rows[placeholder].DefaultCellStyle.ForeColor = Color.Khaki;
        _lblMatches.Text = "正在加载历史列表…（后台读取 ddh 会话）";
        Text = "对局历史 - 正在加载历史列表…";
        SetInfo("正在加载历史列表…");

        var sw = Stopwatch.StartNew();
        List<HistoryFileInfo>? files = null;
        Exception? listError = null;
        try
        {
            files = await Task.Run(() => DdhHistoryReader.List());
        }
        catch (Exception ex)
        {
            listError = ex;
        }

        if (IsDisposed || version != _listVersion) return;
        _listLoading = false;
        _btnRefresh.Enabled = true;
        _gridMatches.Enabled = true;
        Text = WindowTitle;

        if (listError != null)
        {
            _files = new List<HistoryFileInfo>();
            _gridMatches.Rows.Clear();
            _lblMatches.Text = "对局列表（读取失败）";
            SetInfo("加载历史列表失败：" + listError.Message);
            Log.Warn("加载历史列表失败：" + listError.Message);
            return;
        }

        _files = files ?? new List<HistoryFileInfo>();
        FillMatchRows();
        if (_files.Count > 0 && _doc == null)
        {
            _gridMatches.Rows[0].Selected = true;
            LoadMatch(_files[0]);
        }
        Log.Write($"历史列表：{_files.Count} 局，后台读取 {sw.ElapsedMilliseconds} ms（ddh）");
        if (_files.Count > 0) SetInfo($"历史列表就绪：{_files.Count} 局（ddh 游戏状态会话）");
        ShowBrokenSummaryIfNeeded();
    }

    /// <summary>按 _files 重填左表（每行 Tag 保留 HistoryFileInfo，后台更新时按路径找回）。</summary>
    private void FillMatchRows()
    {
        _gridMatches.Rows.Clear();
        _matchRows.Clear();
        foreach (var f in _files)
        {
            int idx = _gridMatches.Rows.Add(MatchRowCells(f));
            var row = _gridMatches.Rows[idx];
            row.Tag = f;
            row.DefaultCellStyle.ForeColor = RowColor(f);
            row.Cells[0].ToolTipText = MatchTooltip(f);
            _matchRows[f.Path] = row;
        }
        UpdateMatchesHeader();
    }

    /// <summary>单行内容：损坏 → 红字；正常 → 摘要数字。</summary>
    private static string[] MatchRowCells(HistoryFileInfo f)
    {
        string time = f.StartedAt.LocalDateTime.ToString("MM-dd HH:mm:ss");
        string map = string.IsNullOrWhiteSpace(f.MapName) ? "—" : f.MapName;
        if (f.Broken) return new[] { "⚠ " + time, map, "—", "损坏" };

        return new[]
        {
            time,
            map,
            FormatDuration(f.Duration),
            f.EventCount + (f.Truncated ? "（截断）" : ""),
        };
    }

    private Color RowColor(HistoryFileInfo f)
    {
        if (f.Broken) return Color.Salmon;
        if (string.Equals(f.Path, _currentPath, StringComparison.OrdinalIgnoreCase)) return Color.LightGreen;
        return Color.Gainsboro;
    }

    private static string MatchTooltip(HistoryFileInfo f)
    {
        if (f.Broken) return f.Path + "\n" + f.Error;
        string text = f.Path + "\n结束：" + f.EndedAt.LocalDateTime.ToString("yyyy-MM-dd HH:mm:ss");
        if (f.MapName.Length > 0) text += "\n地图：" + f.MapName;
        return text + $"\n单位：{UnitCountText(f.UnitCount)}｜事件：{f.EventCount}" +
               (f.Truncated ? "（截断）" : "");
    }

    /// <summary>只更新对应那一行（不重建整表、不丢选中）。</summary>
    private void UpdateMatchRow(HistoryFileInfo f)
    {
        if (!_matchRows.TryGetValue(f.Path, out var row) || row.DataGridView == null) return;
        var cells = MatchRowCells(f);
        for (int i = 0; i < cells.Length && i < row.Cells.Count; i++) row.Cells[i].Value = cells[i];
        row.DefaultCellStyle.ForeColor = RowColor(f);
        if (row.Cells.Count > 0) row.Cells[0].ToolTipText = MatchTooltip(f);
    }

    private void UpdateMatchesHeader()
    {
        _lblMatches.Text = $"对局列表（{_files.Count} 局，按时间倒序；双击加载）";
        if (_files.Count == 0)
            SetInfo("还没有游戏状态会话：ddh 会在进入地图后直接写入 " + DdhHistoryReader.DatabasePath);
    }

    /// <summary>损坏数据汇总提示：只在第一次打开/刷新时弹一次。</summary>
    private void ShowBrokenSummaryIfNeeded()
    {
        var broken = _files.Where(f => f.Broken).ToList();
        if (broken.Count == 0 || _brokenSummaryShown) return;

        _brokenSummaryShown = true;
        foreach (var f in broken) _notifiedBroken.Add(f.Path);
        Log.Warn($"历史列表：发现 {broken.Count} 条损坏/无法解析的记录");
        MessageBox.Show(this,
            $"发现 {broken.Count} 条历史记录损坏或无法解析（列表中红色行）：\n" +
            string.Join("\n", broken.Take(5).Select(f => f.FileName)) +
            (broken.Count > 5 ? "\n…" : "") +
            "\n\n已记日志；其余对局仍可正常查看，程序不会退出。",
            "历史记录损坏", MessageBoxButtons.OK, MessageBoxIcon.Warning);
    }

    private void OnMatchDoubleClick(DataGridViewCellEventArgs e)
    {
        if (e.RowIndex < 0 || e.RowIndex >= _gridMatches.Rows.Count) return;
        if (_gridMatches.Rows[e.RowIndex].Tag is HistoryFileInfo info) LoadMatch(info);
    }

    /// <summary>
    /// 加载一局（**后台** Task.Run 读库 + DTO→HookEvent 转换）：期间窗口标题/状态显示
    /// “正在加载 …”、禁用左表；加载完才回 UI 线程填表。失败只提示，不清掉已加载的内容。
    /// </summary>
    private async void LoadMatch(HistoryFileInfo info)
    {
        if (_listLoading || _docLoading) return;
        if (info.Broken)
        {
            NotifyBroken(info, info.Error);
            return;
        }

        _docLoading = true;
        _gridMatches.Enabled = false;
        _btnRefresh.Enabled = false;
        Text = "对局历史 - 正在加载 " + info.FileName + "…";
        SetInfo($"正在加载 {info.FileName}…（后台读取，窗口可继续响应）");
        UseWaitCursor = true;

        var sw = Stopwatch.StartNew();
        HistoryDocument? doc = null;
        List<DamageHook.HookEvent>? events = null;
        string error = "";
        try
        {
            var result = await Task.Run(() =>
            {
                var d = DdhHistoryReader.Load(info, out string err);
                // 20k 条事件的 DTO→运行时转换也放后台，UI 线程只做表格填充。
                List<DamageHook.HookEvent>? evs = d?.Events.Select(x => x.ToHookEvent()).ToList();
                return (Document: d, Events: evs, Error: err);
            });
            doc = result.Document;
            events = result.Events;
            error = result.Error;
        }
        catch (Exception ex)
        {
            error = ex.Message;
        }

        if (IsDisposed) return;
        _docLoading = false;
        _gridMatches.Enabled = true;
        _btnRefresh.Enabled = true;
        Text = WindowTitle;
        UseWaitCursor = false;

        if (doc == null || events == null)
        {
            info.Broken = true;
            info.Error = error.Length > 0 ? error : "无法解析";
            UpdateMatchRow(info);
            NotifyBroken(info, info.Error);
            return;
        }

        long elapsed = sw.ElapsedMilliseconds;
        ApplyDocument(info, doc, events);
        UpdateMatchRow(info);
        Log.Write($"加载历史：{info.FileName} 后台读取 {elapsed} ms（结算 {doc.Settlements.Count} / 事件 {doc.Events.Count}）");
    }

    /// <summary>把已经解析好的文档填进右侧三张表（UI 线程）。</summary>
    private void ApplyDocument(HistoryFileInfo info, HistoryDocument doc, List<DamageHook.HookEvent> events)
    {
        _doc = doc;
        _currentPath = info.Path;
        _events = events;

        // 换一局：清掉上一局的表头搜索（关键词只对上一局有意义；同一局内的刷新/改关键词会保持）。
        _settleSearch.Clear(notify: false);
        // 和主页一致：新的在最上面（文件里按时间正序存，这里倒着加），并应用当前搜索条件。
        _selected = FillSettleRows(keepSelected: null);

        UpdateSettleHeader();
        UpdateBreakdown();

        // unitCount<=0 是旧文件/退游戏时快照为空留下的 0：显示“-”，不要让它看起来像“本局 0 个单位”。
        string unitText = UnitCountText(doc.UnitCount);
        SetInfo($"已加载 {info.FileName}｜{doc.StartedAt.LocalDateTime:MM-dd HH:mm:ss} → " +
                $"{doc.EndedAt.LocalDateTime:MM-dd HH:mm:ss}（{FormatDuration(TimeSpan.FromSeconds(Math.Max(0, (doc.EndedAt - doc.StartedAt).TotalSeconds)))}）" +
                $"｜会话 {doc.SessionId}｜单位 {unitText}｜结算 {doc.Settlements.Count}｜事件 {doc.Events.Count}" +
                (doc.Truncated ? "（已截断）" : ""));
    }

    /// <summary>
    /// 按当前表头搜索条件（单位名 **或称谓** / 类型码，两列 AND）重填结算表；返回重填后选中的结算。
    /// 称谓取库里的 settlement.title，与单位名称合并显示和搜索；老库 title 为空 → 只按单位名。
    /// keepSelected = null 表示新加载一局（沿用旧行为：默认选中第一行）；否则按身份找回原来选中的行。
    /// </summary>
    private HistorySettlement? FillSettleRows(HistorySettlement? keepSelected)
    {
        if (_doc == null) return null;

        _loading = true;
        try
        {
            _gridSettle.Rows.Clear();
            bool filtering = _settleSearch.HasFilter;
            // 和主页同一口径：显式按 DiedAt 降序（同一毫秒按实例号/地址），新的在最上面。
            // 不依赖文件里的顺序 —— 旧版历史按时间正序存，新版快照按降序存，这里都归一到降序。
            var ordered = SettlementOrder.SortDescending(_doc.Settlements);
            for (int i = 0; i < ordered.Count; i++)
            {
                var s = ordered[i];
                var cells = SettlementGridUi.Cells(s);
                // 「单位名称」列显示并匹配名字与 hero 称谓（老库为空 → 只按名字）。
                if (filtering && !_settleSearch.MatchesValues(
                        cells[SettlementGridUi.NameCellIndex], cells[SettlementGridUi.CodeCellIndex],
                        firstTitle: s.Title))
                    continue;

                int idx = _gridSettle.Rows.Add(cells);
                _gridSettle.Rows[idx].Tag = s;
                _gridSettle.Rows[idx].DefaultCellStyle.ForeColor =
                    s.Kind == "死亡" ? Color.FromArgb(255, 140, 140) : Color.FromArgb(200, 200, 140);
            }
        }
        finally { _loading = false; }

        DataGridViewRow? selected = null;
        if (keepSelected != null)
        {
            foreach (DataGridViewRow r in _gridSettle.Rows)
                if (r.Tag is HistorySettlement hs && SameSettlement(hs, keepSelected)) { selected = r; break; }
        }
        else if (_gridSettle.Rows.Count > 0)
        {
            selected = _gridSettle.Rows[0];
        }

        if (selected != null)
        {
            selected.Selected = true;
            _gridSettle.CurrentCell = selected.Cells[0];
        }
        else
        {
            _gridSettle.CurrentCell = null;   // 选中的行被过滤掉：清掉旧选中，别让下方统计对不上
        }
        return selected?.Tag as HistorySettlement;
    }

    /// <summary>表头搜索关键词变化：按新条件重填结算表，并同步下方分组统计/事件过滤控件。</summary>
    private void ApplySettleFilter()
    {
        if (_doc == null) return;

        _selected = FillSettleRows(_selected);
        UpdateSettleHeader();
        UpdateBreakdown();
    }

    /// <summary>同一条历史结算的身份：地址 + 死亡时间 + 实例号（与主页 AnchorKeys.ForSettlement 同口径）。</summary>
    private static bool SameSettlement(HistorySettlement a, HistorySettlement b) =>
        a.Addr == b.Addr && a.DiedAt == b.DiedAt && a.InstanceIndex == b.InstanceIndex;

    /// <summary>单位名/任意结算行右键 → 查看单位属性（和主页右键同一个表格窗体）。</summary>
    private void BuildSettleMenu()
    {
        var mi = new ToolStripMenuItem("查看详情（单位属性）");
        mi.Click += (_, _) => ShowUnitStats();
        _settleMenu.Items.Add(mi);
        _settleMenu.Opening += (_, e) =>
            e.Cancel = _gridSettle.SelectedRows.Count == 0 ||
                       _gridSettle.SelectedRows[0].Tag is not HistorySettlement;
        _gridSettle.CellMouseDown += (_, e) =>
        {
            if (e.Button != MouseButtons.Right || e.RowIndex < 0 || e.RowIndex >= _gridSettle.Rows.Count) return;
            _gridSettle.ClearSelection();
            _gridSettle.Rows[e.RowIndex].Selected = true;
            if (e.ColumnIndex >= 0) _gridSettle.CurrentCell = _gridSettle.Rows[e.RowIndex].Cells[e.ColumnIndex];
        };
        _gridSettle.ContextMenuStrip = _settleMenu;
    }

    /// <summary>把选中的历史结算弹成“单位属性”表（血量 / 攻击力 / 攻击间隔 / 护甲 / 技能）。</summary>
    private void ShowUnitStats()
    {
        if (_doc == null) return;
        if (_gridSettle.SelectedRows.Count == 0) return;
        if (_gridSettle.SelectedRows[0].Tag is not HistorySettlement s) return;
        string name = s.UnitName.Length > 0 ? s.UnitName : s.TypeCode;
        var rows = UnitStats.ForSettlement(s, _events);
        new UnitStatsForm($"{name} 0x{s.Addr:X8}（{s.Kind}结算｜单位属性）", rows).Show(this);
    }

    private void OnSettleSelectionChanged()
    {
        if (_loading) return;
        _selected = _gridSettle.SelectedRows.Count > 0 ? _gridSettle.SelectedRows[0].Tag as HistorySettlement : null;
        UpdateSettleHeader();
        UpdateBreakdown();
    }

    private void UpdateSettleHeader()
    {
        if (_doc == null) { _lblSettle.Text = "死亡结算（未加载对局）"; return; }
        int total = _doc.Settlements.Count;
        string filter = _settleSearch.HasFilter
            ? $"｜过滤后 {_gridSettle.Rows.Count} / {total} 行（点表头可改；清空后回车 = 取消）"
            : "";
        _lblSettle.Text = $"死亡结算（{total} 条{filter}，新的在上；单击一行看分组统计）";
    }

    /// <summary>选中结算 → 分组统计表（Σ 来源 + 组合）。未选中时显示一行提示。</summary>
    private void UpdateBreakdown()
    {
        _gridBreak.Rows.Clear();
        if (_selected == null)
        {
            _lblBreak.Text = "分组统计（选中上面的结算行）";
            _gridBreak.Rows.Add("选中上面的结算行查看分组统计", "", "", "", "", "", "", "", "", "", "", "");
            return;
        }

        var s = _selected;
        string unit = s.UnitName.Length > 0 ? s.UnitName : s.TypeCode;
        var sources = s.Sources.Select(x => x.ToSourceRow()).ToList();
        var combos = s.Combos.Select(x => x.ToCombination()).ToList();
        var rows = SettlementGridUi.BreakdownRows(unit, sources, combos, out string message);

        if (rows.Count > 0)
        {
            foreach (var (cells, color) in rows)
            {
                int idx = _gridBreak.Rows.Add(cells);
                if (color != default) _gridBreak.Rows[idx].DefaultCellStyle.ForeColor = color;
            }
        }
        else
        {
            _gridBreak.Rows.Add(message, "", "", "", "", "", "", "", "", "", "", "");
        }

        _lblBreak.Text = $"分组统计（{unit} 0x{s.Addr:X8}；来源 Σ {sources.Count} 行 / 组合 {combos.Count} 行）";
    }

    /// <summary>双击结算行 → 打开这个单位的伤害明细（和主页双击结算行是同一个 UnitEventsForm）。</summary>
    private void OnSettleDoubleClick(DataGridViewCellEventArgs e)
    {
        if (e.RowIndex < 0 || e.RowIndex >= _gridSettle.Rows.Count) return;
        if (_gridSettle.Rows[e.RowIndex].Tag is not HistorySettlement s) return;

        string name = s.UnitName.Length > 0 ? s.UnitName : s.TypeCode;
        var snapshot = _events;
        int related = snapshot.Count(x => x.Source == s.Addr || x.Victim == s.Addr);
        // 历史事件自带 victim_title / source_title（只参与表头搜索，不显示），弹窗不用再查运行时索引。
        // 玩家列优先用事件里的 owner；老事件没有 owner 时，再用这局战场单位表按地址兜底。
        var doc = _doc;
        Func<uint, string> playerText = addr =>
        {
            var u = doc?.Units.FirstOrDefault(x => x.Addr == addr);
            return u is { OwnerSlot: >= 0 } ? "Player " + (u.OwnerSlot + 1) : "?";
        };
        string sessionId = doc?.SessionId ?? "";
        var identities = doc?.Units
            .GroupBy(u => sessionId + "|" + u.TypeCode + "|" + (u.IsIllusion ? "I" : "0"),
                     StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);
        Func<string, bool, HookGridUi.UnitIdentity> identityOf = (code, mirror) =>
            identities != null &&
            identities.TryGetValue(sessionId + "|" + code + "|" + (mirror ? "I" : "0"), out var u)
                ? new HookGridUi.UnitIdentity(u.Name, u.Title, u.OwnerSlot)
                : HookGridUi.Unknown;
        var form = new UnitEventsForm($"{name} 0x{s.Addr:X8}（历史对局｜伤害明细）", s.Addr,
            snapshot, () => _events, playerText, null,
            (addr, _) => doc?.Units.FirstOrDefault(x => x.Addr == addr)?.IsIllusion == true,
            identityOf);
        form.Show(this);
        SetInfo($"已打开 {name} 0x{s.Addr:X8} 的伤害明细（{related} 条相关事件）");
    }

    private void NotifyBroken(HistoryFileInfo info, string error)
    {
        Log.Warn($"加载历史失败：{info.FileName} —— {error}");
        SetInfo("加载历史失败：" + error);
        if (!_notifiedBroken.Add(info.Path)) return;
        MessageBox.Show(this,
            $"历史记录无法加载：\n{info.Path}\n\n{error}\n\n已记日志，程序继续运行。",
            "历史记录损坏", MessageBoxButtons.OK, MessageBoxIcon.Warning);
    }

    /// <summary>把该局落盘的【战场单位】名称和称谓以弹窗展示。</summary>
    private void ShowUnitsOfLoadedMatch()
    {
        if (!FeatureFlags.BattlefieldUnitsEnabled) return;
        var doc = _doc;
        if (doc == null)
        {
            MessageBox.Show(this, "请先双击左侧一局加载对局，再点【战场单位】。", "战场单位",
                MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }
        var f = new Form
        {
            Text = $"战场单位名称与称谓（{doc.Units.Count} 个 · 结束于 {doc.EndedAt:yyyy-MM-dd HH:mm:ss}）",
            Width = 860,
            Height = 580,
            StartPosition = FormStartPosition.CenterParent,
            BackColor = Color.FromArgb(24, 24, 28),
        };
        var g = new Grid { Dock = DockStyle.Fill };
        g.AddText("类型码", "hu1", 85);
        g.AddText("单位名", "hu2", 130);
        g.AddText("称谓", "hu3", 110);
        g.AddText("最小攻击力", "hu4", 95);
        g.AddText("最大攻击力", "hu5", 95);
        g.AddText("攻击范围", "hu6", 85);
        g.AddText("护甲", "hu7", 70);
        g.AddText("攻击速度", "hu8", 90);
        g.AddText("攻击间隔", "hu9", 85);
        g.AddText("攻击频率", "hu10", 85);
        g.AddText("玩家", "hu11", 75);
        g.AddText("地址", "hu16", 95);
        g.AddText("状态", "hu17", 65);
        foreach (DataGridViewColumn col in g.Columns)
        {
            col.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
            col.FillWeight = Math.Max(8, col.Width);
            col.MinimumWidth = 45;
        }
        static string N(double? v) => v.HasValue ? v.Value.ToString("0.##") : "?";
        static string Frequency(double? speed, double? interval) =>
            speed is > 0 && interval is > 0
                ? (speed.Value / interval.Value).ToString("0.##")
                : "?";
        foreach (var u in doc.Units)
        {
            int i = g.Rows.Add(new object[]
            {
                u.TypeCode, u.DisplayName, u.Title, N(u.DamageMin), N(u.DamageMax),
                N(u.AttackRange), N(u.Armor), N(u.AttackSpeed), N(u.AttackInterval),
                Frequency(u.AttackSpeed, u.AttackInterval),
                u.OwnerSlot >= 0 ? "Player " + (u.OwnerSlot + 1) : "?",
                "0x" + u.Addr.ToString("X8"),
                u.Dead ? "已死亡" : "存活",
            });
            if (u.Dead) g.Rows[i].DefaultCellStyle.ForeColor = Color.FromArgb(150, 150, 150);
        }
        if (doc.Units.Count == 0)
        {
            var tip = new Label
            {
                Dock = DockStyle.Top,
                Height = 28,
                Text = "这局没有保存战场单位（老版本存的历史，或保存时场上没有单位）。",
                ForeColor = Color.Khaki,
                TextAlign = ContentAlignment.MiddleLeft,
                Padding = new Padding(8, 0, 0, 0),
            };
            f.Controls.Add(g);
            f.Controls.Add(tip);
        }
        else
        {
            f.Controls.Add(g);
        }
        f.ShowDialog(this);
    }

    private void OpenHistoryDir()
    {
        try
        {
            string dir = DdhHistoryReader.DefaultDirectory;
            Directory.CreateDirectory(dir);
            System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(dir) { UseShellExecute = true });
        }
        catch (Exception ex)
        {
            MessageBox.Show(this, "打开历史目录失败：" + ex.Message, "历史", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        }
    }

    /// <summary>
    /// 历史信息栏的“单位”文本：unitCount&lt;=0（旧文件 / 退游戏时快照为空）显示“-”，
    /// 不要显示误导性的 0（真机 match_20261022_000341.json 就是 0，但那一局其实有几十个单位）。
    /// </summary>
    internal static string UnitCountText(int count) => count > 0 ? count.ToString() : "-";

    private void SetInfo(string text)
    {
        _lblInfo.Text = text;
        _lblInfo.ForeColor = Color.LightGray;
    }

    /// <summary>时长显示：不足 1 小时 mm:ss，超过 h:mm:ss。</summary>
    private static string FormatDuration(TimeSpan d)
    {
        if (d <= TimeSpan.Zero) return "0:00";
        return d.TotalHours >= 1
            ? $"{(int)d.TotalHours}:{d.Minutes:00}:{d.Seconds:00}"
            : $"{(int)d.TotalMinutes}:{d.Seconds:00}";
    }
}
