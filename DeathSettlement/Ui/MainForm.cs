using System.Text;
using War3DeathSettlement.Core;

namespace War3DeathSettlement.Ui;

/// <summary>双缓冲的表格（避免高刷新率下闪烁）。</summary>
internal sealed class Grid : DataGridView
{
    public Grid()
    {
        DoubleBuffered = true;
        AllowUserToAddRows = false;
        AllowUserToDeleteRows = false;
        AllowUserToResizeRows = false;
        ReadOnly = true;
        RowHeadersVisible = false;
        SelectionMode = DataGridViewSelectionMode.FullRowSelect;
        MultiSelect = false;
        BackgroundColor = Color.FromArgb(32, 32, 36);
        GridColor = Color.FromArgb(64, 64, 70);
        BorderStyle = BorderStyle.None;
        EnableHeadersVisualStyles = false;
        ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(48, 48, 56);
        ColumnHeadersDefaultCellStyle.ForeColor = Color.Gainsboro;
        ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.DisableResizing;
        ColumnHeadersHeight = 26;
        DefaultCellStyle.BackColor = Color.FromArgb(32, 32, 36);
        DefaultCellStyle.ForeColor = Color.Gainsboro;
        DefaultCellStyle.SelectionBackColor = Color.FromArgb(70, 90, 130);
        DefaultCellStyle.SelectionForeColor = Color.White;
        RowTemplate.Height = 22;
        Font = new Font("Microsoft YaHei UI", 9F);
    }

    public void AddText(string header, string prop, int width, bool fill = false)
    {
        var col = new DataGridViewTextBoxColumn
        {
            HeaderText = header,
            Name = prop,
            Width = width,
            SortMode = DataGridViewColumnSortMode.NotSortable,
            AutoSizeMode = fill ? DataGridViewAutoSizeColumnMode.Fill : DataGridViewAutoSizeColumnMode.None
        };
        Columns.Add(col);
    }
}

/// <summary>
/// 主窗口：左边/上面是“死亡结算”历史，另一个页签是“战场单位”，再一个是“诊断”。
/// 交互刻意做成 War3Trainer 那样：先【查找游戏】，然后它自己一直盯着游戏。
/// </summary>
public sealed class MainForm : Form
{
    private readonly MonitorEngine _engine = new();
    private readonly System.Windows.Forms.Timer _uiTimer = new();

    private readonly ToolStripButton _cmdAuto = new("自动连接") { CheckOnClick = true, Checked = true };
    private readonly ToolStripButton _cmdFind = new("查找游戏");
    private readonly ToolStripButton _cmdPause = new("暂停监视") { Enabled = false };
    private readonly ToolStripButton _cmdClear = new("清空账本") { Enabled = false };
    private readonly ToolStripButton _cmdDeep = new("立即深度扫描") { Enabled = false };
    private readonly ToolStripButton _cmdDiag = new("生成诊断报告") { Enabled = false };
    private readonly ToolStripButton _cmdExport = new("导出结算 CSV") { Enabled = false };
    private readonly ToolStripButton _cmdLogs = new("打开日志目录");
    private readonly ToolStripButton _cmdElevate = new("以管理员身份重启");
    private readonly ToolStripLabel _lblState = new("游戏未运行");
    private readonly ToolStripLabel _lblStats = new("");

    private readonly Grid _gridSettle = new();
    private readonly Grid _gridUnits = new();
    private readonly TextBox _txtDetail = new();
    private readonly TextBox _txtDiag = new();
    private readonly Label _lblConn = new();
    private readonly StatusStrip _status = new();
    private readonly ToolStripStatusLabel _statusText = new("就绪");

    private DateTime _lastShown = DateTime.MinValue;
    private DateTime _lastDiag = DateTime.MinValue;
    private int _lastSettlementShown = -1;
    private bool _wasReady;

    public MainForm()
    {
        Text = "魔兽死亡结算 War3DeathSettlement v1.0 — 纯外部只读（不注入、不改游戏）";
        Width = 1280;
        Height = 800;
        MinimumSize = new Size(900, 600);
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(24, 24, 28);
        ForeColor = Color.Gainsboro;
        Font = new Font("Microsoft YaHei UI", 9F);

        BuildUi();
        Log.LineWritten += _ => { };

        _uiTimer.Interval = 200;
        _uiTimer.Tick += (_, _) => RefreshUi();
        _uiTimer.Start();

        _engine.AutoAttach = _cmdAuto.Checked;
        _engine.Start();
        Log.Write("界面已就绪：自动连接已开启 —— war3.exe 一出现就自动挂上。");
    }

    // ------------------------------------------------------------------
    private void BuildUi()
    {
        var tool = new ToolStrip
        {
            GripStyle = ToolStripGripStyle.Hidden,
            BackColor = Color.FromArgb(40, 40, 46),
            ForeColor = Color.Gainsboro,
            Renderer = new ToolStripProfessionalRenderer(new DarkColors()),
            ImageScalingSize = new Size(16, 16)
        };
        foreach (var b in new[] { _cmdAuto, _cmdFind, _cmdPause, _cmdClear, _cmdDeep, _cmdExport, _cmdDiag, _cmdLogs, _cmdElevate })
        {
            b.DisplayStyle = ToolStripItemDisplayStyle.Text;
            b.ForeColor = Color.Gainsboro;
            tool.Items.Add(b);
        }
        tool.Items.Add(new ToolStripSeparator());
        _lblState.ForeColor = Color.Khaki;
        _lblStats.ForeColor = Color.LightGray;
        tool.Items.Add(_lblState);
        tool.Items.Add(new ToolStripSeparator());
        tool.Items.Add(_lblStats);

        _cmdFind.Click += (_, _) => DoFind();
        _cmdAuto.Click += (_, _) =>
        {
            _engine.AutoAttach = _cmdAuto.Checked;
            SetStatus(_cmdAuto.Checked ? "自动连接已开启（每秒找一次 war3 进程）" : "自动连接已关闭");
        };
        _cmdPause.Click += (_, _) => TogglePause();
        _cmdClear.Click += (_, _) => { _engine.ClearAll(); _lastSettlementShown = -1; _gridSettle.Rows.Clear(); _gridUnits.Rows.Clear(); _txtDetail.Clear(); Log.Write("账本已清空"); };
        _cmdDeep.Click += (_, _) => { _engine.RequestDeepScan(); SetStatus("已请求一次深度扫描…"); };
        _cmdExport.Click += (_, _) => ExportCsv();
        _cmdDiag.Click += (_, _) => RunDiagnostics();
        _cmdLogs.Click += (_, _) => OpenLogs();
        _cmdElevate.Click += (_, _) => RelaunchElevated();

        // ---- 页签 ----
        var tabs = new TabControl { Dock = DockStyle.Fill, Padding = new Point(14, 6) };

        // 页 1：死亡结算
        var tabSettle = new TabPage("死亡结算") { BackColor = Color.FromArgb(24, 24, 28) };
        _gridSettle.Dock = DockStyle.Fill;
        _gridSettle.AddText("时间", "t", 130);
        _gridSettle.AddText("类型码", "code", 80);
        _gridSettle.AddText("拥有者", "owner", 70);
        _gridSettle.AddText("结局", "kind", 60);
        _gridSettle.AddText("实例", "inst", 50);
        _gridSettle.AddText("受击", "hits", 55);
        _gridSettle.AddText("总伤害", "total", 90);
        _gridSettle.AddText("最大单次", "max", 90);
        _gridSettle.AddText("最惨1秒", "peak", 90);
        _gridSettle.AddText("秒伤", "dps", 80);
        _gridSettle.AddText("存活s", "life", 70);
        _gridSettle.AddText("战斗s", "combat", 70);
        _gridSettle.Columns["t"]!.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
        _gridSettle.SelectionChanged += (_, _) => ShowSettlementDetail();

        _txtDetail.Multiline = true;
        _txtDetail.ScrollBars = ScrollBars.Both;
        _txtDetail.WordWrap = false;
        _txtDetail.ReadOnly = true;
        _txtDetail.BackColor = Color.FromArgb(28, 28, 32);
        _txtDetail.ForeColor = Color.Gainsboro;
        _txtDetail.Font = new Font("Consolas", 9F);
        _txtDetail.Dock = DockStyle.Fill;

        var splitSettle = new SplitContainer
        {
            Dock = DockStyle.Fill,
            Orientation = Orientation.Horizontal,
            SplitterDistance = 420,
            BackColor = Color.FromArgb(40, 40, 46)
        };
        splitSettle.Panel1.Controls.Add(_gridSettle);
        splitSettle.Panel2.Controls.Add(_txtDetail);
        tabSettle.Controls.Add(splitSettle);

        // 页 2：战场单位
        var tabUnits = new TabPage("战场单位") { BackColor = Color.FromArgb(24, 24, 28) };
        _gridUnits.Dock = DockStyle.Fill;
        _gridUnits.AddText("类型码", "code", 80);
        _gridUnits.AddText("拥有者", "owner", 70);
        _gridUnits.AddText("HP", "hp", 80);
        _gridUnits.AddText("HP上限", "hpmax", 90);
        _gridUnits.AddText("HP%", "pct", 70);
        _gridUnits.AddText("累计受伤", "taken", 100);
        _gridUnits.AddText("受击次数", "hits", 80);
        _gridUnits.AddText("秒伤", "dps", 80);
        _gridUnits.AddText("状态", "state", 60);
        _gridUnits.AddText("坐标", "pos", 160);
        _gridUnits.AddText("发现方式", "found", 130);
        _gridUnits.AddText("地址", "addr", 100);
        _gridUnits.Columns["found"]!.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
        tabUnits.Controls.Add(_gridUnits);

        // 页 3：诊断
        var tabDiag = new TabPage("诊断 / 日志") { BackColor = Color.FromArgb(24, 24, 28) };
        _txtDiag.Multiline = true;
        _txtDiag.ScrollBars = ScrollBars.Both;
        _txtDiag.WordWrap = false;
        _txtDiag.ReadOnly = true;
        _txtDiag.BackColor = Color.FromArgb(18, 18, 20);
        _txtDiag.ForeColor = Color.LightGreen;
        _txtDiag.Font = new Font("Consolas", 9F);
        _txtDiag.Dock = DockStyle.Fill;
        tabDiag.Controls.Add(_txtDiag);

        tabs.TabPages.Add(tabSettle);
        tabs.TabPages.Add(tabUnits);
        tabs.TabPages.Add(tabDiag);

        // 底部状态栏
        _status.BackColor = Color.FromArgb(40, 40, 46);
        _statusText.ForeColor = Color.Gainsboro;
        _status.Items.Add(_statusText);

        // 顶部“连接提示”横幅
        _lblConn.Dock = DockStyle.Top;
        _lblConn.Height = 34;
        _lblConn.TextAlign = ContentAlignment.MiddleLeft;
        _lblConn.Padding = new Padding(10, 0, 0, 0);
        _lblConn.BackColor = Color.FromArgb(50, 46, 30);
        _lblConn.ForeColor = Color.Khaki;
        _lblConn.Text = "① 先启动魔兽（进地图后）→ ② 点左上【查找游戏】→ ③ 之后它自动跟踪，单位死亡即出结算。";

        Controls.Add(tabs);
        Controls.Add(_lblConn);
        Controls.Add(tool);
        Controls.Add(_status);
    }

    private sealed class DarkColors : ProfessionalColorTable
    {
        public override Color ToolStripGradientBegin => Color.FromArgb(40, 40, 46);
        public override Color ToolStripGradientMiddle => Color.FromArgb(40, 40, 46);
        public override Color ToolStripGradientEnd => Color.FromArgb(40, 40, 46);
        public override Color ButtonSelectedHighlight => Color.FromArgb(70, 70, 80);
        public override Color ButtonSelectedGradientBegin => Color.FromArgb(70, 70, 80);
        public override Color ButtonSelectedGradientEnd => Color.FromArgb(70, 70, 80);
        public override Color ButtonPressedGradientBegin => Color.FromArgb(90, 90, 100);
        public override Color ButtonPressedGradientEnd => Color.FromArgb(90, 90, 100);
        public override Color SeparatorDark => Color.FromArgb(70, 70, 78);
        public override Color SeparatorLight => Color.FromArgb(70, 70, 78);
    }

    // ------------------------------------------------------------------
    private void DoFind()
    {
        SetStatus("正在查找 war3 进程…");
        _cmdFind.Enabled = false;
        Application.DoEvents();
        try
        {
            bool ok = _engine.Attach(out string msg);
            if (ok)
            {
                _lblConn.BackColor = Color.FromArgb(28, 48, 28);
                _lblConn.ForeColor = Color.LightGreen;
                _lblConn.Text = "已连接：" + msg + "　——　死亡即出结算（结算同时写入 logs\\settlements.csv）。";
                _cmdPause.Enabled = _cmdClear.Enabled = _cmdDeep.Enabled = _cmdExport.Enabled = true;
                SetStatus(msg);
            }
            else
            {
                _lblConn.BackColor = Color.FromArgb(60, 34, 34);
                _lblConn.ForeColor = Color.Salmon;
                _lblConn.Text = msg;
                SetStatus(msg);
                if (msg.Contains("管理员"))
                {
                    var r = MessageBox.Show(this, msg + "\n\n是否以管理员身份重新启动本软件？", "需要管理员权限",
                        MessageBoxButtons.YesNo, MessageBoxIcon.Warning);
                    if (r == DialogResult.Yes) RelaunchElevated();
                }
                else if (msg.Contains("未运行"))
                {
                    MessageBox.Show(this, msg, "没找到游戏", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            }
        }
        finally { _cmdFind.Enabled = true; }
    }

    private void TogglePause()
    {
        _engine.Paused = !_engine.Paused;
        _cmdPause.Text = _engine.Paused ? "继续监视" : "暂停监视";
        SetStatus(_engine.Paused ? "已暂停（不再读取内存）" : "监视中");
    }

    private void RelaunchElevated()
    {
        try
        {
            string exe = Environment.ProcessPath ?? Application.ExecutablePath;
            Native.ShellExecuteW(IntPtr.Zero, "runas", exe, "", Path.GetDirectoryName(exe) ?? "", 1);
            Close();
        }
        catch (Exception ex)
        {
            MessageBox.Show(this, "提权启动失败：" + ex.Message, "错误", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private void OpenLogs()
    {
        try
        {
            string dir = Path.Combine(AppContext.BaseDirectory, "logs");
            Directory.CreateDirectory(dir);
            System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(dir) { UseShellExecute = true });
        }
        catch (Exception ex) { MessageBox.Show(this, ex.Message); }
    }

    private void ExportCsv()
    {
        var snap = _engine.Current;
        if (snap.Settlements.Count == 0) { MessageBox.Show(this, "还没有结算记录。", "导出", MessageBoxButtons.OK, MessageBoxIcon.Information); return; }
        using var dlg = new SaveFileDialog
        {
            Filter = "CSV 文件|*.csv",
            FileName = $"war3-death-settlement-{DateTime.Now:yyyyMMdd-HHmmss}.csv"
        };
        if (dlg.ShowDialog(this) != DialogResult.OK) return;

        var sb = new StringBuilder();
        sb.AppendLine(Settlement.CsvHeader);
        foreach (var s in snap.Settlements) sb.AppendLine(s.ToCsvRow());
        sb.AppendLine();
        sb.AppendLine("# 明细");
        sb.AppendLine("时间,类型码,伤害,剩余生命,致命");
        foreach (var s in snap.Settlements)
            foreach (var e in s.Events)
                sb.AppendLine($"{e.Time:yyyy-MM-dd HH:mm:ss.fff},{s.TypeCode},{e.Amount:0.##},{e.HpAfter:0.#},{(e.Fatal ? 1 : 0)}");
        try
        {
            File.WriteAllText(dlg.FileName, sb.ToString(), new UTF8Encoding(true));
            SetStatus("已导出：" + dlg.FileName);
        }
        catch (Exception ex) { MessageBox.Show(this, ex.Message, "导出失败"); }
    }

    // ------------------------------------------------------------------
    private void RefreshUi()
    {
        var snap = _engine.Current;
        if (snap.At == _lastShown) return;
        _lastShown = snap.At;

        // 连接状态变化 → 更新横幅与按钮可用性
        if (snap.Ready != _wasReady)
        {
            _wasReady = snap.Ready;
            if (snap.Ready)
            {
                _lblConn.BackColor = Color.FromArgb(28, 48, 28);
                _lblConn.ForeColor = Color.LightGreen;
                _lblConn.Text = "已连接：" + snap.Status + "　——　死亡即出结算（同时写入 logs\\settlements.csv）。";
            }
            else
            {
                _lblConn.BackColor = Color.FromArgb(50, 46, 30);
                _lblConn.ForeColor = Color.Khaki;
                _lblConn.Text = snap.Status.Length > 0
                    ? snap.Status
                    : "正在等待魔兽启动…（自动连接已开启）";
            }
            _cmdPause.Enabled = _cmdClear.Enabled = _cmdDeep.Enabled = _cmdExport.Enabled = _cmdDiag.Enabled = snap.Ready;
        }

        // 状态栏
        _lblStats.Text = snap.Ready
            ? $"单位 {snap.Units.Count}｜结算 {snap.Settlements.Count}｜" +
              $"扫描 {snap.Stats.ElapsedMs}ms（{snap.Stats.Mode}）｜深扫 {snap.Stats.DeepMb}MB"
            : "";
        if (snap.Ready) _statusText.Text = snap.Status;

        // 单位表
        var units = snap.Units;
        if (_gridUnits.Rows.Count != units.Count) _gridUnits.Rows.Clear();
        if (_gridUnits.Rows.Count == 0)
        {
            foreach (var u in units)
                _gridUnits.Rows.Add(u.TypeCode, u.Owner, u.Hp.ToString("0.#"), u.HpMax.ToString("0.#"),
                    (u.HpPercent * 100).ToString("0"), u.Taken.ToString("0.#"), u.Hits, u.Dps.ToString("0.#"),
                    u.State, $"({u.X:0.#}, {u.Y:0.#})", u.Found, "0x" + u.Addr.ToString("X8"));
        }
        else
        {
            for (int i = 0; i < units.Count; i++)
            {
                var u = units[i];
                var row = _gridUnits.Rows[i];
                row.SetValues(u.TypeCode, u.Owner, u.Hp.ToString("0.#"), u.HpMax.ToString("0.#"),
                    (u.HpPercent * 100).ToString("0"), u.Taken.ToString("0.#"), u.Hits, u.Dps.ToString("0.#"),
                    u.State, $"({u.X:0.#}, {u.Y:0.#})", u.Found, "0x" + u.Addr.ToString("X8"));
            }
        }

        // 结算表（新的在最上面）
        var set = snap.Settlements;
        if (set.Count != _lastSettlementShown)
        {
            _lastSettlementShown = set.Count;
            _gridSettle.Rows.Clear();
            for (int i = set.Count - 1; i >= 0; i--)
            {
                var s = set[i];
                int idx = _gridSettle.Rows.Add(s.DiedAt.ToString("HH:mm:ss.fff"), s.TypeCode, s.OwnerText, s.Kind,
                    s.InstanceIndex, s.HitCount, s.TotalDamage.ToString("0.#"), s.MaxHit.ToString("0.#"),
                    s.Peak1s.ToString("0.#"), s.DpsCombat.ToString("0.#"),
                    s.LifetimeSeconds.ToString("0.0"), s.CombatSeconds.ToString("0.0"));
                _gridSettle.Rows[idx].Tag = s;
            }
            if (_gridSettle.Rows.Count > 0) _gridSettle.Rows[0].Selected = true;

            // 新结算：整行标红，方便一眼看到
            foreach (DataGridViewRow r in _gridSettle.Rows)
            {
                if (r.Tag is Settlement s2 && s2.Kind == "死亡")
                    r.DefaultCellStyle.ForeColor = Color.FromArgb(255, 140, 140);
                else
                    r.DefaultCellStyle.ForeColor = Color.FromArgb(200, 200, 140);
            }
        }

        // 诊断页（1 秒刷新一次就够）
        if ((DateTime.Now - _lastDiag).TotalSeconds >= 1.0)
        {
            _lastDiag = DateTime.Now;
            var sb = new StringBuilder();
            sb.AppendLine($"时间 {DateTime.Now:HH:mm:ss}   状态 {snap.Status}");
            sb.AppendLine($"统计：单位 {snap.Units.Count}，结算 {snap.Settlements.Count}，扫描模式 {snap.Stats.Mode}，用时 {snap.Stats.ElapsedMs}ms");
            foreach (var n in snap.Stats.Notes) sb.AppendLine("  · " + n);
            sb.AppendLine();
            sb.AppendLine("---- 日志尾巴 ----");
            sb.Append(Log.SnapshotText());
            _txtDiag.Text = sb.ToString();
            _txtDiag.SelectionStart = _txtDiag.TextLength;
            _txtDiag.ScrollToCaret();
        }
    }

    private void ShowSettlementDetail()    {
        if (_gridSettle.SelectedRows.Count == 0) return;
        if (_gridSettle.SelectedRows[0].Tag is Settlement s) _txtDetail.Text = s.ToText();
    }

    private void SetStatus(string s) => _statusText.Text = s;

    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        _uiTimer.Stop();
        _engine.Dispose();
        base.OnFormClosing(e);
    }
}
