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
    private readonly CliOptions _opt;
    private readonly Settings _settings = Settings.Load();
    private readonly ToolStripButton _cmdPick = new("选择进程…");
    private readonly ToolStripButton _cmdPluginLog = new("读插件日志") { CheckOnClick = true, Checked = true };
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
    private readonly ToolStripComboBox _cmbInterval = new() { DropDownStyle = ComboBoxStyle.DropDownList, Width = 86 };
    private readonly ToolStripComboBox _cmbDeep = new() { DropDownStyle = ComboBoxStyle.DropDownList, Width = 104 };

    private readonly Grid _gridSettle = new();
    private readonly Grid _gridUnits = new();
    private readonly Grid _gridPlayers = new();
    private readonly Grid _gridBreak = new();
    private readonly TextBox _txtDetail = new();
    private readonly TextBox _txtDiag = new();
    private readonly Label _lblConn = new();
    private readonly StatusStrip _status = new();
    private readonly ToolStripStatusLabel _statusText = new("就绪");

    private DateTime _lastShown = DateTime.MinValue;
    private DateTime _lastDiag = DateTime.MinValue;
    private DateTime _lastUnitsRefresh = DateTime.MinValue;
    private int _lastSettlementShown = -1;
    private int _lastAttributedShown = -1;
    private int _lastNamesShown = -1;
    private int _lastBreakShown = -1;
    private bool _wasReady;
    private string _lastBannerStatus = "";

    public MainForm(CliOptions? opt = null)
    {
        _opt = opt ?? new CliOptions();
        string build = "";
        try { build = "　[构建 " + File.GetLastWriteTime(System.Reflection.Assembly.GetExecutingAssembly().Location).ToString("MM-dd HH:mm") + "]"; }
        catch { }
        Text = "魔兽死亡结算 War3DeathSettlement v1.0 — 纯外部只读（不注入、不改游戏）" + build;
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

        // ---- 设置：命令行 > ini > 默认 ----
        _engine.IntervalMs = _settings.IntervalMs;
        _engine.EnableDeepScan = _settings.DeepSeconds > 0;
        if (_settings.DeepSeconds > 0) _engine.DeepInterval = TimeSpan.FromSeconds(_settings.DeepSeconds);
        _engine.ReadPluginLog = _settings.ReadPluginLog;
        _engine.PluginLogPath = _settings.PluginLogPath;
        // ini 里可以改「攻击类型/伤害类型编号 → 名字」的对照表（atype_labels / dtype_labels）
        DamageTypeNames.Override(_settings.AttackTypeLabels, _settings.DamageTypeLabels);
        _cmdPluginLog.Checked = _settings.ReadPluginLog;
        _cmdAuto.Checked = _settings.AutoAttach;
        _engine.AttachOptions = _settings.ToAttach();
        if (_opt.Pid != null || _opt.Name != null || _opt.ForceVersion != null)
            _engine.AttachOptions = _opt.ToAttach();          // 命令行显式给的优先

        _cmbInterval.SelectedIndex = _settings.IntervalMs switch { <= 30 => 0, <= 50 => 1, <= 100 => 2, _ => 3 };
        _cmbDeep.SelectedIndex = _settings.DeepSeconds switch { 0 => 0, <= 8 => 1, <= 20 => 2, _ => 3 };

        _engine.AutoAttach = _cmdAuto.Checked;
        _engine.Start();
        Log.Write($"界面已就绪：自动连接={_cmdAuto.Checked}，轮询 {_engine.IntervalMs}ms，" +
                  $"深扫 {(_engine.EnableDeepScan ? _engine.DeepInterval.TotalSeconds + "s" : "关")}，设置文件 {Settings.DefaultPath}");
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
        foreach (var b in new[] { _cmdAuto, _cmdFind, _cmdPick, _cmdPluginLog, _cmdPause, _cmdClear, _cmdDeep, _cmdExport, _cmdDiag, _cmdLogs, _cmdElevate })
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

        // 轮询间隔 / 深扫间隔（CPU 与精度的取舍，用户自己调）
        tool.Items.Add(new ToolStripLabel("轮询") { ForeColor = Color.LightGray });
        _cmbInterval.Items.AddRange(new object[] { "30 ms", "50 ms", "100 ms", "200 ms" });
        _cmbInterval.SelectedIndex = 1;
        _cmbInterval.SelectedIndexChanged += (_, _) =>
        {
            _engine.IntervalMs = _cmbInterval.SelectedIndex switch { 0 => 30, 1 => 50, 2 => 100, _ => 200 };
            SetStatus($"轮询间隔 = {_engine.IntervalMs} ms");
        };
        tool.Items.Add(_cmbInterval);

        tool.Items.Add(new ToolStripLabel("深扫") { ForeColor = Color.LightGray });
        _cmbDeep.Items.AddRange(new object[] { "关闭", "8 秒", "20 秒", "60 秒" });
        _cmbDeep.SelectedIndex = 1;
        _cmbDeep.SelectedIndexChanged += (_, _) =>
        {
            switch (_cmbDeep.SelectedIndex)
            {
                case 0: _engine.EnableDeepScan = false; break;
                case 1: _engine.EnableDeepScan = true; _engine.DeepInterval = TimeSpan.FromSeconds(8); break;
                case 2: _engine.EnableDeepScan = true; _engine.DeepInterval = TimeSpan.FromSeconds(20); break;
                default: _engine.EnableDeepScan = true; _engine.DeepInterval = TimeSpan.FromSeconds(60); break;
            }
            SetStatus(_engine.EnableDeepScan ? $"深度扫描间隔 = {_engine.DeepInterval.TotalSeconds:0} 秒" : "深度扫描已关闭");
        };
        tool.Items.Add(_cmbDeep);
        tool.Items.Add(new ToolStripSeparator());
        tool.Items.Add(_lblStats);

        _cmdFind.Click += (_, _) => DoFind();
        _cmdPick.Click += (_, _) => DoPickProcess();
        _cmdPluginLog.Click += (_, _) =>
        {
            _engine.ReadPluginLog = _cmdPluginLog.Checked;
            SetStatus(_cmdPluginLog.Checked
                ? "会读游戏内插件日志，把“伤害来源/攻击类型”补进结算"
                : "已关闭插件日志读取（结算里就没有来源那一块了）");
        };
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
        _gridSettle.AddText("单位名", "name", 110);
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
        _gridSettle.AddText("伤害来源（插件日志）", "src", 240);
        _gridSettle.Columns["t"]!.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
        _gridSettle.SelectionChanged += (_, _) => ShowSettlementDetail();
        _gridSettle.CellClick += (_, _) => ShowSettlementDetail();
        _gridSettle.RowEnter += (_, _) => ShowSettlementDetail();

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
        _gridUnits.AddText("名字", "name", 110);
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

        // 页：伤害构成（按 是否攻击 / 是否远程 / 攻击类型 / 伤害类型 分组）
        var tabBreak = new TabPage("伤害构成") { BackColor = Color.FromArgb(24, 24, 28) };
        _gridBreak.Dock = DockStyle.Fill;
        _gridBreak.AddText("时间", "t", 120);
        _gridBreak.AddText("单位", "unit", 130);
        _gridBreak.AddText("类型码", "code", 70);
        _gridBreak.AddText("维度", "dim", 90);
        _gridBreak.AddText("分组", "key", 200);
        _gridBreak.AddText("笔数", "count", 60);
        _gridBreak.AddText("伤害", "dmg", 100);
        _gridBreak.AddText("占比", "pct", 70);
        _gridBreak.Columns["key"]!.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
        var hintBreak = new Label
        {
            Dock = DockStyle.Top,
            Height = 42,
            ForeColor = Color.Khaki,
            Padding = new Padding(8, 6, 8, 0),
            Text = "上半部分是**本软件自己统计**的分组（只用观测到的每一笔掉血，不需要任何插件）：单次伤害档位/每秒伤害档位/单位类型/拥有者/结局。\n" +
                   "下半部分（灰色）是插件日志口径的 是否攻击/是否远程/攻击类型/伤害类型 —— 那四项只在引擎伤害事件里，纯外部读不到，只有插件在跑才有。"
        };
        tabBreak.Controls.Add(_gridBreak);
        tabBreak.Controls.Add(hintBreak);

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

        // 页 3：按玩家统计
        var tabPlayers = new TabPage("按玩家统计") { BackColor = Color.FromArgb(24, 24, 28) };
        _gridPlayers.Dock = DockStyle.Fill;
        _gridPlayers.AddText("玩家", "owner", 80);
        _gridPlayers.AddText("死亡", "deaths", 70);
        _gridPlayers.AddText("消失", "gone", 70);
        _gridPlayers.AddText("总承受伤害", "total", 120);
        _gridPlayers.AddText("平均每次", "avg", 100);
        _gridPlayers.AddText("最惨1秒(最大)", "worst", 120);
        _gridPlayers.AddText("最大单次", "maxhit", 100);
        _gridPlayers.AddText("涉及单位种类", "kinds", 110);
        _gridPlayers.AddText("最近一次", "last", 160);
        _gridPlayers.Columns["kinds"]!.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
        var panelPlayers = new Panel { Dock = DockStyle.Fill };
        var lblPlayers = new Label
        {
            Dock = DockStyle.Top,
            Height = 34,
            Padding = new Padding(10, 8, 0, 0),
            ForeColor = Color.Khaki,
            Text = "按“谁的单位死了”汇总（结算来源：本软件按血量差记账）。"
        };
        panelPlayers.Controls.Add(_gridPlayers);
        panelPlayers.Controls.Add(lblPlayers);
        tabPlayers.Controls.Add(panelPlayers);

        tabs.TabPages.Add(tabSettle);
        tabs.TabPages.Add(tabBreak);
        tabs.TabPages.Add(tabUnits);
        tabs.TabPages.Add(tabPlayers);
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
    // ------------------------------------------------------------------
    /// <summary>“选择进程”：列出所有加载了 game.dll 的进程，点一下就连上去（等价于更明确的“查找游戏”）。</summary>
    private void DoPickProcess()
    {
        using var dlg = new ProcessPickerForm();
        if (dlg.ShowDialog(this) != DialogResult.OK || dlg.SelectedPid is not int pid) return;

        string name = string.IsNullOrWhiteSpace(dlg.SelectedName) ? _settings.LastProcessName : dlg.SelectedName;
        _engine.AttachOptions = new AttachOptions(pid,
            string.IsNullOrWhiteSpace(name) ? null : name,
            string.IsNullOrWhiteSpace(_settings.ForceVersion) ? null : _settings.ForceVersion);

        if (!string.IsNullOrWhiteSpace(name))
        {
            _settings.LastProcessName = name;   // 下次启动自动连接也认这个名字
            _settings.Save();
        }

        SetStatus($"正在连接 PID {pid}…");
        bool ok = _engine.Attach(out string msg);
        _lastBannerStatus = "";
        SetStatus(msg);
        Log.Write($"手动选择进程 PID {pid} {name}：{(ok ? "成功" : msg)}");
        if (!ok && msg.Contains("管理员"))
        {
            if (MessageBox.Show(this, msg + "\n\n是否以管理员身份重新启动本软件？", "需要管理员权限",
                    MessageBoxButtons.YesNo, MessageBoxIcon.Warning) == DialogResult.Yes)
                RelaunchElevated();
        }
        else if (!ok)
        {
            MessageBox.Show(this, msg, "连接失败", MessageBoxButtons.OK, MessageBoxIcon.Warning);
        }
    }

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
            _lblState.Text = snap.Ready ? "监视中" : "未连接";
            _lblState.ForeColor = snap.Ready ? Color.LightGreen : Color.Khaki;
            _lastBannerStatus = "";   // 强制下面按最新状态刷新一次横幅
        }

        // 横幅跟着引擎的状态走（包含“还没发现单位”这种提示；单位一出来提示就自动消失）
        if (snap.Ready && !string.Equals(_lastBannerStatus, snap.Status, StringComparison.Ordinal))
        {
            _lastBannerStatus = snap.Status;
            _lblConn.Text = "已连接：" + snap.Status + "　——　死亡即出结算（同时写入 logs\\settlements.csv）。";
        }

        // 状态栏
        _lblStats.Text = snap.Ready
            ? $"单位 {snap.Units.Count}｜结算 {snap.Settlements.Count}｜" +
              $"扫描 {snap.Stats.ElapsedMs}ms（{snap.Stats.Mode}）｜深扫 {snap.Stats.DeepMb}MB"
            : "";
        if (snap.Ready) _statusText.Text = snap.Status;

        // 单位表：500 个单位时每 200ms 重建 6000 个字符串太浪费，降到 2 次/秒
        if ((DateTime.Now - _lastUnitsRefresh).TotalMilliseconds >= 500)
        {
            _lastUnitsRefresh = DateTime.Now;
            UpdateUnitsGrid(snap.Units);
        }

        // 结算表（新的在最上面）
        var set = snap.Settlements;
        int namesKnown = _engine.PluginLog?.CodeToName.Count ?? 0;
        if (set.Count != _lastSettlementShown || _engine.AttributedCount != _lastAttributedShown ||
            namesKnown != _lastNamesShown)
        {
            _lastSettlementShown = set.Count;
            _lastAttributedShown = _engine.AttributedCount;
            _lastNamesShown = namesKnown;
            _gridSettle.Rows.Clear();
            for (int i = set.Count - 1; i >= 0; i--)
            {
                var s = set[i];
                int idx = _gridSettle.Rows.Add(s.DiedAt.ToString("HH:mm:ss.fff"), s.UnitName, s.TypeCode, s.OwnerText, s.Kind,
                    s.InstanceIndex, s.HitCount, s.TotalDamage.ToString("0.#"), s.MaxHit.ToString("0.#"),
                    s.Peak1s.ToString("0.#"), s.DpsCombat.ToString("0.#"),
                    s.LifetimeSeconds.ToString("0.0"), s.CombatSeconds.ToString("0.0"),
                    s.Attribution?.SourceSummary(2) ?? "");
                _gridSettle.Rows[idx].Tag = s;
            }
            if (_gridSettle.Rows.Count > 0)
            {
                _gridSettle.Rows[0].Selected = true;
                _gridSettle.CurrentCell = _gridSettle.Rows[0].Cells[0];
                ShowSettlementDetail();   // 选中行变了，明细要跟着刷（不然右下方老是空的）
            }

            // 新结算：整行标红，方便一眼看到
            foreach (DataGridViewRow r in _gridSettle.Rows)
            {
                if (r.Tag is Settlement s2 && s2.Kind == "死亡")
                    r.DefaultCellStyle.ForeColor = Color.FromArgb(255, 140, 140);
                else
                    r.DefaultCellStyle.ForeColor = Color.FromArgb(200, 200, 140);
            }

            UpdatePlayerSummary(set);
        }

        // 诊断页（1 秒刷新一次就够）
        if ((DateTime.Now - _lastDiag).TotalSeconds >= 1.0)
        {
            _lastDiag = DateTime.Now;
            var sb = new StringBuilder();
            sb.AppendLine($"时间 {DateTime.Now:HH:mm:ss}   状态 {snap.Status}");
            sb.AppendLine($"统计：单位 {snap.Units.Count}，结算 {snap.Settlements.Count}，扫描模式 {snap.Stats.Mode}，用时 {snap.Stats.ElapsedMs}ms");
            sb.AppendLine($"插件日志：{(_engine.ReadPluginLog ? "开" : "关")}　" +
                          $"已解析插件结算 {_engine.PluginSettlementsSeen} 条，" +
                          $"其中 {_engine.AttributedCount} 条来源已补进本软件结算" +
                          $"{(File.Exists(_engine.PluginLogPath) ? "" : "（日志文件不存在）")}");
            sb.AppendLine($"          路径 {_engine.PluginLogPath}　名字表 {_engine.PluginLog?.CodeToName.Count ?? 0} 个");
            foreach (var n in snap.Stats.Notes) sb.AppendLine("  · " + n);
            sb.AppendLine();
            sb.AppendLine("---- 日志尾巴 ----");
            sb.Append(Log.SnapshotText());
            _txtDiag.Text = sb.ToString();
            _txtDiag.SelectionStart = _txtDiag.TextLength;
            _txtDiag.ScrollToCaret();
        }
    }

    /// <summary>“按玩家统计”页：谁的单位死得多、挨了多少（汇总逻辑在 Core.PlayerSummary，可自检）。</summary>
    private void UpdatePlayerSummary(IReadOnlyList<Settlement> set)
    {
        _gridPlayers.Rows.Clear();
        foreach (var r in PlayerSummary.Build(set))
        {
            _gridPlayers.Rows.Add(
                r.OwnerText, r.Deaths, r.Gone, r.TotalDamage.ToString("0.#"),
                r.AvgPerSettlement.ToString("0.#"), r.WorstPeak1s.ToString("0.#"),
                r.MaxHit.ToString("0.#"), r.KindCount, r.LastDiedAt.ToString("HH:mm:ss"));
        }

        UpdateBreakdown(set);
    }

    /// <summary>
    /// 伤害构成页：把每条结算的「是否攻击 / 是否远程 / 攻击类型 / 伤害类型 / 组合」分组平铺出来。
    /// 数据来自插件日志的“联合统计”拆分行，所以是精确分组（不是估算）。
    /// </summary>
    private void UpdateBreakdown(IReadOnlyList<Settlement> set)
    {
        if (set.Count == _lastBreakShown) return;
        _lastBreakShown = set.Count;

        _gridBreak.Rows.Clear();

        // ① 主体：**本软件自己统计**的分组（只看我们观测到的血量变化，与插件无关）
        var self = SelfBreakdown.Build(set);
        foreach (var r in self)
        {
            _gridBreak.Rows.Add("—", "（全部结算）", "", r.Dimension, r.Key, r.Count,
                r.Damage.ToString("0.#"), r.Percent.ToString("0.#") + "%");
        }

        // ② 附：插件日志口径（插件在跑且写了“联合统计”才有），逐条结算铺开
        var pluginRows = 0;
        foreach (var s in set.TakeLast(40))
        {
            if (s.Attribution == null || s.Attribution.Groups.Count == 0) continue;
            foreach (var g in s.Attribution.Groups)
            {
                int idx = _gridBreak.Rows.Add(
                    s.DiedAt.ToString("HH:mm:ss"), s.UnitName.Length > 0 ? s.UnitName : s.TypeCode,
                    s.TypeCode, "插件-" + g.Dimension, g.Key, g.Count,
                    g.DamageAfter.ToString("0.#"), g.Percent.ToString("0.#") + "%");
                _gridBreak.Rows[idx].DefaultCellStyle.ForeColor = Color.DarkGray;
                pluginRows++;
            }
        }

        if (self.Count == 0 && pluginRows == 0)
            _gridBreak.Rows.Add("—", "（还没有结算）", "", "—", "打起来之后这里会出现分组统计", 0, "", "");
    }

    /// <summary>生成实机诊断报告（全堆深度扫描 + 各条发现路径的命中情况）。</summary>
    private void RunDiagnostics()
    {
        var g = _engine.Game;
        if (g == null || !g.IsReady)
        {
            MessageBox.Show(this, "还没连上游戏：先启动魔兽并进入地图。", "诊断", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }

        _cmdDiag.Enabled = false;
        SetStatus("正在生成诊断报告（含一次全堆深度扫描，约 2~5 秒）…");
        Task.Run(() =>
        {
            string path;
            try { path = Probe.ReportForGame(g, deep: true); }
            catch (Exception ex) { path = "生成失败：" + ex; }
            BeginInvoke(new Action(() =>
            {
                _cmdDiag.Enabled = true;
                SetStatus("诊断报告：" + path);
                MessageBox.Show(this, "诊断报告已生成：\n" + path, "诊断", MessageBoxButtons.OK, MessageBoxIcon.Information);
                try { System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(path) { UseShellExecute = true }); } catch { }
            }));
        });
    }

    /// <summary>刷新“战场单位”表（原地更新，不做整表重建）。</summary>
    private void UpdateUnitsGrid(IReadOnlyList<UnitView> units)
    {
        if (_gridUnits.Rows.Count != units.Count) _gridUnits.Rows.Clear();

        if (_gridUnits.Rows.Count == 0)
        {
            foreach (var u in units) _gridUnits.Rows.Add(UnitCells(u));
        }
        else
        {
            for (int i = 0; i < units.Count; i++)
                _gridUnits.Rows[i].SetValues(UnitCells(units[i]));
        }
    }

    private static object[] UnitCells(UnitView u) => new object[]
    {
        u.Name, u.TypeCode, u.Owner, u.Hp.ToString("0.#"), u.HpMax.ToString("0.#"),
        (u.HpPercent * 100).ToString("0"), u.Taken.ToString("0.#"), u.Hits, u.Dps.ToString("0.#"),
        u.State, $"({u.X:0.#}, {u.Y:0.#})", u.Found, "0x" + u.Addr.ToString("X8")
    };

    private void ShowSettlementDetail()    {
        if (_gridSettle.SelectedRows.Count == 0) return;
        if (_gridSettle.SelectedRows[0].Tag is Settlement s) _txtDetail.Text = s.ToText();
    }

    private void SetStatus(string s) => _statusText.Text = s;

    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        _uiTimer.Stop();
        try
        {
            _settings.IntervalMs = _engine.IntervalMs;
            _settings.DeepSeconds = _engine.EnableDeepScan ? (int)Math.Round(_engine.DeepInterval.TotalSeconds) : 0;
            _settings.AutoAttach = _cmdAuto.Checked;
            _settings.ReadPluginLog = _engine.ReadPluginLog;
            _settings.PluginLogPath = _engine.PluginLogPath;
            if (string.IsNullOrWhiteSpace(_settings.ForceVersion) && !string.IsNullOrWhiteSpace(_opt.ForceVersion))
                _settings.ForceVersion = _opt.ForceVersion!;
            _settings.Save();
        }
        catch { }
        _engine.Dispose();
        base.OnFormClosing(e);
    }
}







