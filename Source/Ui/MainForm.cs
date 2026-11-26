using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using War3DeathSettlement.Core;

namespace War3DeathSettlement.Ui;

/// <summary>双缓冲的表格（避免高刷新率下闪烁）。</summary>
internal sealed class Grid : DataGridView
{
    [DllImport("user32.dll")]
    private static extern IntPtr GetCapture();
    [DllImport("user32.dll")]
    private static extern bool IsChild(IntPtr hWndParent, IntPtr hWnd);

    /// <summary>
    /// 用户正在这张表上操作（按住左键选行 / 拖滚动条）。这期间**绝不能重建行**：
    /// DataGridView 一 Rows.Clear() 就会把鼠标捕获和滚动条抢走，表现就是滚动条剧烈抖动、选不中、拖不动。
    /// </summary>
    public bool IsUserInteracting
    {
        get
        {
            try
            {
                if (!IsHandleCreated || IsDisposed || !Visible) return false;
                if (IsCurrentCellInEditMode) return true;
                if (Control.MouseButtons != MouseButtons.Left) return false;

                // 鼠标捕获在表格自己或它的子窗口（滚动条）上 → 正在选行/拖滚动条。
                IntPtr cap = GetCapture();
                if (cap == IntPtr.Zero) return false;
                if (cap == Handle || IsChild(Handle, cap)) return true;

                // 兜底：捕获窗口不是子窗口（某些主题的滚动条不是 Control），
                // 但光标还在表格范围内，也按“正在操作”处理。
                return RectangleToScreen(ClientRectangle).Contains(Cursor.Position);
            }
            catch { return false; }
        }
    }

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
        // 点列头时 DataGridView 会把表头切成“选中”状态；不设这两项就会露出一块系统蓝
        // （0,120,215），在暗色表头里非常突兀，看起来像还有颜色码。改成和表头同色，点哪列都不变色。
        ColumnHeadersDefaultCellStyle.SelectionBackColor = Color.FromArgb(48, 48, 56);
        ColumnHeadersDefaultCellStyle.SelectionForeColor = Color.Gainsboro;
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
/// 主窗口：两个页签 ——【死亡结算】（结算列表 + 分组统计）与【伤害事件】（引擎级伤害明细）。
/// 交互刻意做成 War3Trainer 那样：先【查找游戏】，然后它自己一直盯着游戏。
/// </summary>
public sealed class MainForm : Form
{
    // 战场单位采集类型码、名称、称谓和战斗属性；页签保留。
    private static readonly bool BattlefieldUnitsEnabled = FeatureFlags.BattlefieldUnitsEnabled;

    private readonly MonitorEngine _engine = new();
    private readonly CliOptions _opt;
    private readonly Settings _settings = Settings.Load();
    private readonly System.Windows.Forms.Timer _uiTimer = new();
    /// <summary>右下角【回到顶部】：仅当当前页行数够多且已向下滚动时出现。</summary>
    private readonly Button _btnBackTop = new();
    /// <summary>最近一次切页时间：只做 150ms 防抖（合并连点），切完立即刷新当前页。</summary>
    private DateTime _tabSwitchedAt = DateTime.MinValue;
    // 单位地址 → 玩家号解析（读 CUnit+0x58，按地址缓存；重连/换局自动清缓存）
    private UnitOwnerResolver _owner = null!;

    // 工具栏：查找游戏 / 历史 / 生成诊断报告 / 打开日志
    private readonly ToolStripButton _cmdFind = new("查找游戏");
    private readonly ToolStripButton _cmdHistory = new("历史");
    private readonly ToolStripButton _cmdRestartAdmin = new("以管理员身份重启") { Visible = false };
    private readonly ToolStripButton _cmdDiag = new("生成诊断报告") { Enabled = false };
    private readonly ToolStripButton _cmdLogs = new("打开日志");
    private readonly ToolStripLabel _lblState = new("游戏未运行");
    private readonly ToolStripLabel _lblStats = new("");
    /// <summary>【历史】窗口（非模态；重复点按钮只激活，不再开第二个）。</summary>
    private HistoryForm? _historyForm;

    // 伤害事件页的两个筛选框（触发单位 / 伤害来源）
    private readonly ComboBox _cmbFilterVictim = new() { DropDownStyle = ComboBoxStyle.DropDownList, Width = 150 };
    private readonly ComboBox _cmbFilterSource = new() { DropDownStyle = ComboBoxStyle.DropDownList, Width = 150 };
    private string _filterVictim = "";
    private string _filterSource = "";
    // 筛选框刷新重入保护：RefreshHookFilterItems 改 ComboBox.Items/SelectedIndex 时会同步触发
    // SelectedIndexChanged → UpdateHookGrid → RefreshHookFilterItems，用这个标志打断递归。
    private bool _inFilterRefresh;
    // 伤害事件页分页状态（每页 UnitEvents.PageSize 行）。
    private int _hookPage;
    private string _hookSig = "";

    private readonly Grid _gridSettle = new();
    private readonly Grid _gridBreak = new();
    private readonly Grid _gridHook = new();
    /// <summary>【战场单位】表（ddh v12 属性请求/响应；名称列两行自绘）。</summary>
    private readonly Grid _gridUnits = new();
    /// <summary>【死亡结算】表头搜索（点「单位名」/「类型码」表头 → 输入 → 模糊过滤）。</summary>
    private SettlementHeaderSearch _settleSearch = null!;
    /// <summary>【伤害事件】表头搜索（点「触发单位」/「伤害来源」表头 → 输入 → 模糊过滤，和结算表共用组件）。</summary>
    private SettlementHeaderSearch _hookSearch = null!;
    /// <summary>【战场单位】表头搜索（类型码 / 单位名称：名称列的谓词同时匹配称谓和名称）。</summary>
    private SettlementHeaderSearch _unitsSearch = null!;
    private TabControl _tabs = null!;
    private TabPage _tabHook = null!;
    private TabPage _tabUnits = null!;
    // 伤害事件页分页控件（底部）
    private readonly Button _btnHookFirst = new() { Text = "首页" };
    private readonly Button _btnHookPrev = new() { Text = "上一页" };
    private readonly Button _btnHookNext = new() { Text = "下一页" };
    private readonly Button _btnHookLast = new() { Text = "末页" };
    private readonly Label _lblHookPage = new();
    private readonly ContextMenuStrip _settleMenu = new();
    // 伤害事件表右键【跟踪】：只对「触发单位 / 伤害来源」两列弹出，点击后把单位名写进对应表头搜索框。
    private readonly ContextMenuStrip _hookMenu = new();
    private readonly ToolStripMenuItem _hookTrackItem = new("跟踪");
    private DamageHook.HookEvent? _hookTrackEvent;
    private string _hookTrackColumn = "";
    /// <summary>右键那一刻的跟踪目标（事件 + 列）。点菜单时从 Tag 取，不依赖菜单关闭事件的先后顺序。</summary>
    private sealed record HookTrackTarget(DamageHook.HookEvent Event, string Column);
    private readonly Label _lblConn = new();
    private readonly StatusStrip _status = new();
    private readonly ToolStripStatusLabel _statusText = new("就绪");

    private DateTime _lastShown = DateTime.MinValue;
    private int _lastSettlementShown = -1;
    /// <summary>上一次画表用的结算快照列表（按对象引用比较）：条数没变但内容被替换（补建↔正常结算）也能感知。</summary>
    private IReadOnlyList<Settlement>? _lastSettlementList;
    private int _lastNamesShown = -1;
    private long _attrIdentityVersion;
    private DateTime _lastHookIdentityRefresh = DateTime.MinValue;
    private long _lastAttrIdentityShown = -1;
    // 伤害事件页筛选下拉的刷新节流：条数变了或每 2 秒刷新一次（100000 条时避免每 200ms 全量重建）。
    private int _lastHookFilterCount = -1;
    private DateTime _lastHookFilterAt = DateTime.MinValue;
    private string _lastBannerSig = "";
    private string _lastLiveSig = "";

    // 结算表分块：前 _settleRowCount 行是结算（按 DiedAt 降序，新的在上），后面是存活行。
    // 存活行只原地改数字/在底部增删，不再因为血量变化把整张结算表清空重建。
    private int _settleRowCount;
    private string _liveRowKey = "";
    /// <summary>“结算表乱序 → 退回整表重建”的限流日志计数（最多 5 条）。</summary>
    private int _settleOrderLogged;

    // 伤害事件页当前已经画出来的“页 + 筛选”，用来区分“只是又来了新事件”还是真的换了页/筛选。
    private int _hookPageShown = -1;
    private string _hookFilterShown = "";

    // 【战场单位】页：ddh 属性请求约 1 秒一轮；地址 → 上一轮响应的缓存（ddh 完成一轮才有新值）。
    private DateTime _lastUnitsRefresh = DateTime.MinValue;
    /// <summary>后台单位属性轮询（不依赖【战场单位】页可见）：把单位地址送去 ddh 取完整属性。</summary>
    private DateTime _lastClassifyRefresh = DateTime.MinValue;
    /// <summary>后台单位属性轮询游标：保证所有单位都会轮到。</summary>
    private int _classifyCursor;
    /// <summary>换进程后短暂屏蔽战场单位刷新，避免把上一局的单位快照当成新局显示。</summary>
    private readonly Dictionary<uint, UnitAttrResponse> _unitAttr = new();
    /// <summary>按类型码缓存最近一次读到的属性：同类型单位合并/死亡后仍能用它填属性列。</summary>
    private readonly Dictionary<string, UnitAttrResponse> _typeAttr = new(StringComparer.OrdinalIgnoreCase);
    /// <summary>类型码 + 镜像位 → 战场单位属性，名称/称谓匹配的唯一键。</summary>
    private readonly Dictionary<string, UnitAttrResponse> _typeIllusionAttr = new(StringComparer.OrdinalIgnoreCase);
    /// <summary>
    /// 请求轮询游标 + 覆盖率：每轮从全部单位里连续取 96 个（循环），保证每个单位都会
    /// 被请求到；存活/最近受击只在同一轮内排序。见 <see cref="UnitAttrPoller"/>。
    /// </summary>
    private readonly UnitAttrPoller _unitPoll = new();
    /// <summary>上次刷新时的游戏进程号：换进程/重连时属性缓存整体作废（地址会复用）。</summary>
    private string _unitSessionKey = "";
    /// <summary>换进程/换图后短暂不重填战场单位，等引擎扫描出新局数据（否则旧快照会立刻填回）。</summary>
    private DateTime _unitsSuppressUntil = DateTime.MinValue;

    /// <summary>名称列两行用的字体：称谓小一号（7.5pt），名称与表格一致（9pt）。</summary>
    private static readonly Font UnitTitleFont = new("Microsoft YaHei UI", 7.5F);
    private static readonly Font UnitNameFont = new("Microsoft YaHei UI", 9F);
    /// <summary>称谓颜色（与名称的浅灰/白色明显不同）。</summary>
    private static readonly Color UnitTitleColor = Color.FromArgb(214, 178, 92);

    // 【死亡结算】下方分组统计：只显示当前选中行（单选）。_breakSig 是当前已画内容的
    // 签名，_breakScrollTop 标记“刚切换选中、要把滚动条拉回顶”，_restoringSelection
    // 标记“正在程序化恢复选中（重建表格后找回选中行，不是用户点的）”。
    private string _breakSig = "";
    private bool _breakScrollTop;
    private bool _restoringSelection;

    /// <summary>存活行的 Tag：用它和结算行（Tag=Settlement）区分开，双击时好派发。</summary>
    private sealed record LiveUnitRow(UnitView Unit);

    public MainForm(CliOptions? opt = null)
    {
        _opt = opt ?? new CliOptions();
        _owner = new UnitOwnerResolver(() => _engine.Game);
        string build = "";
        try { build = "　[构建 " + File.GetLastWriteTime(System.Reflection.Assembly.GetExecutingAssembly().Location).ToString("MM-dd HH:mm") + "]"; }
        catch { }
        string version = "1.0.0";
        try { version = System.Reflection.Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? version; }
        catch { }
        Text = "魔兽死亡结算 War3DeathSettlement v" + version + build;
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
        _engine.ReadPluginLog = _settings.ReadPluginLog;
        _engine.PluginLogPath = _settings.PluginLogPath;
        // ini 里可以改「攻击类型/伤害类型编号 → 名字」的对照表（atype_labels / dtype_labels）
        DamageTypeNames.Override(_settings.AttackTypeLabels, _settings.DamageTypeLabels);
        // 伤害钩子（侵入式）现在是**默认开启**：ini 里 hook_enable 默认就是 1，
        // 界面上不再给开关（工具栏只留 查找游戏 / 生成诊断报告 / 打开日志）。
        _engine.HookEnabled = _settings.HookEnabled;
        _engine.HookDllPath = _settings.HookDll;
        _engine.HookInjectorPath = _settings.HookInjector;

        // 启动提示：钩子开着、但当前不是管理员 —— 只说一次（记进 ini，别每次启动都弹）。
        // 窗口真正显示后再问，否则没有 owner，弹框会跑到错误的位置/被别的窗口盖住。
        if (_settings.HookEnabled) Shown += (_, _) => HintHookNeedsAdminOnce();

        _engine.AttachOptions = _settings.ToAttach();
        if (_opt.Pid != null || _opt.Name != null || _opt.ForceVersion != null)
            _engine.AttachOptions = _opt.ToAttach();          // 命令行显式给的优先

        // 自动连接开关跟随 ini（auto_attach）；关闭时也不崩，只是不自动连，用户可点【查找游戏】。
        _engine.AutoAttach = _settings.AutoAttach;
        // 用户自定义的名字忽略名单（可选，默认空）；马甲单位由 ddh 的 Aloc 技能判定自动过滤
        _engine.IgnoreUnitNames = _settings.IgnoreUnitNames;
        _engine.Start();
        Log.Write($"界面已就绪：自动连接={(_engine.AutoAttach ? "开" : "关")}，伤害钩子={(_engine.HookEnabled ? "开" : "关")}，轮询 {_engine.IntervalMs}ms，" +
                  $"忽略名字 {(string.IsNullOrWhiteSpace(_engine.IgnoreUnitNames) ? "关" : _engine.IgnoreUnitNames)}，设置文件 {Log.Relative(Settings.DefaultPath)}");
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
        foreach (var b in new[] { _cmdFind, _cmdHistory, _cmdDiag, _cmdLogs })
        {
            b.DisplayStyle = ToolStripItemDisplayStyle.Text;
            b.ForeColor = Color.Gainsboro;
            tool.Items.Add(b);
        }
        _cmdRestartAdmin.DisplayStyle = ToolStripItemDisplayStyle.Text;
        _cmdRestartAdmin.ForeColor = Color.Salmon;
        tool.Items.Add(_cmdRestartAdmin);
        tool.Items.Add(new ToolStripSeparator());
        _lblState.ForeColor = Color.Khaki;
        _lblStats.ForeColor = Color.LightGray;
        tool.Items.Add(_lblState);
        tool.Items.Add(new ToolStripSeparator());
        tool.Items.Add(_lblStats);

        _cmdFind.Click += (_, _) => DoFind();
        _cmdHistory.Click += (_, _) => OpenHistory();
        _cmdRestartAdmin.Click += (_, _) => RestartAsAdmin();
        _cmdDiag.Click += (_, _) => RunDiagnostics();
        _cmdLogs.Click += (_, _) => OpenLogs();

        // ---- 页签 ----
        _tabs = new TabControl { Dock = DockStyle.Fill, Padding = new Point(14, 6) };

        // 页 1：死亡结算
        var tabSettle = new TabPage("死亡结算") { BackColor = Color.FromArgb(24, 24, 28) };
        _gridSettle.Dock = DockStyle.Fill;
        // 列定义与【历史】窗口共用（SettlementGridUi），保证两处列序/列宽一致。
        SettlementGridUi.AddColumns(_gridSettle);
        _gridSettle.RowTemplate.Height = 36;
        _gridSettle.DefaultCellStyle.WrapMode = DataGridViewTriState.True;
        // 表头搜索：只对「单位名」「类型码」两列生效；过滤变化后立即整表重建（见 ApplySettlementFilterNow）。
        _settleSearch = SettlementHeaderSearch.ForSettlement(_gridSettle, ApplySettlementFilterNow);
        // 双击：结算行 / 存活行 → 打开【非模态】弹窗（UnitEventsForm），只看这个单位的事件。
        // 用双击而不是单击，避免和“点一下选中行”打架。
        _gridSettle.CellDoubleClick += (_, e) => OnSettleDoubleClick(e);
        // 右键 → 查看详情（结算明细 / 存活快照），保留详情窗但不和双击冲突。
        BuildSettleMenu();
        // 单击（选中）任意一行 → 下方分组统计立刻切到这一行（单选）。
        _gridSettle.SelectionChanged += (_, _) => OnSettleSelectionChanged();

        // 【伤害构成】不再单独占一个页签，合并到【死亡结算】里：
        //   上 = 结算列表；下 = 所有结算的分组统计（原来右下角的文字明细区已按要求去掉）。
        _gridBreak.Dock = DockStyle.Fill;
        // 列定义与【历史】窗口共用（SettlementGridUi），列宽等比例 Fill。
        SettlementGridUi.AddBreakdownColumns(_gridBreak);
        _gridBreak.RowTemplate.Height = 36;
        _gridBreak.DefaultCellStyle.WrapMode = DataGridViewTriState.True;

        // 黄色说明文字已按要求全部删除：各列口径（原始/引擎/地图/净掉血、占比、层…）
        // 统一写在 exe 同目录的 运行前必读.txt 里，界面只留表格。
        var breakPanel = new Panel { Dock = DockStyle.Fill };
        breakPanel.Controls.Add(_gridBreak);

        var splitSettle = new SplitContainer
        {
            Dock = DockStyle.Fill,
            Orientation = Orientation.Horizontal,
            BackColor = Color.FromArgb(40, 40, 46)
        };
        splitSettle.Panel1.Controls.Add(_gridSettle);
        splitSettle.Panel2.Controls.Add(breakPanel);
        tabSettle.Controls.Add(splitSettle);

        // SplitterDistance 必须在控件拿到真实尺寸之后再设，否则会抛异常（以前被 catch 吞掉，
        // 结果上下就是默认的 50/50，下面那块“伤害构成”被挤得很小，看着像没了）。
        Shown += (_, _) =>
        {
            try
            {
                int h = splitSettle.Height;
                splitSettle.SplitterDistance = Math.Clamp((int)(h * 0.45), 220, Math.Max(240, h - 200));
            }
            catch { }
        };

        // 页 2：伤害事件（ddh.dll 挂钩引擎伤害函数）
        // 列与双击弹窗一致（见 HookGridUi.AddColumns）：时间 / 触发单位 / 触发单位ID / 触发单位玩家 /
        // 伤害来源 / 伤害来源ID / 伤害来源玩家 / 层 / 原始 / 引擎 / 地图 / 净掉血 / 倍数 / 本层前血→后血 /
        // 攻击 / 远程 / 攻击类型 / 伤害类型。触发单位/伤害来源除页顶下拉（按类型码）外，还可点表头模糊搜索。
        _tabHook = new TabPage("伤害事件") { BackColor = Color.FromArgb(24, 24, 28) };
        _gridHook.Dock = DockStyle.Fill;
        HookGridUi.AddColumns(_gridHook);
        _gridHook.RowTemplate.Height = 36;
        _gridHook.DefaultCellStyle.WrapMode = DataGridViewTriState.True;
        // 表头搜索：与【死亡结算】共用 SettlementHeaderSearch（触发单位 / 伤害来源，两列 AND）。
        // 过滤变化后立即整页重建（见 ApplyHookFilterNow）。
        _hookSearch = SettlementHeaderSearch.ForHookEvents(_gridHook, ApplyHookFilterNow);
        // 右键「触发单位 / 伤害来源」单元格 → 【跟踪】：把单位名写进对应表头搜索框并钉住，事件实时刷新。
        BuildHookMenu();

        var hookFilterBar = new Panel { Dock = DockStyle.Top, Height = 34, BackColor = Color.FromArgb(28, 28, 34) };
        var lblDstFilter = new Label
        {
            Text = "触发单位：", AutoSize = true, ForeColor = Color.LightGray,
            Location = new Point(8, 9)
        };
        _cmbFilterVictim.Location = new Point(80, 5);
        _cmbFilterVictim.Items.Add(new HookFilterItem("", "(全部)"));
        _cmbFilterVictim.SelectedIndex = 0;
        _cmbFilterVictim.SelectedIndexChanged += (_, _) =>
        {
            if (_inFilterRefresh) return;   // 程序化重建筛选框触发的，别重入
            _filterVictim = (_cmbFilterVictim.SelectedItem as HookFilterItem)?.Code ?? "";
            _hookPage = 0;                  // 换筛选回到第一页
            UpdateHookGrid();
        };
        var lblSrcFilter = new Label
        {
            Text = "伤害来源：", AutoSize = true, ForeColor = Color.LightGray,
            Location = new Point(250, 9)
        };
        _cmbFilterSource.Location = new Point(322, 5);
        _cmbFilterSource.Items.Add(new HookFilterItem("", "(全部)"));
        _cmbFilterSource.SelectedIndex = 0;
        _cmbFilterSource.SelectedIndexChanged += (_, _) =>
        {
            if (_inFilterRefresh) return;   // 程序化重建筛选框触发的，别重入
            _filterSource = (_cmbFilterSource.SelectedItem as HookFilterItem)?.Code ?? "";
            _hookPage = 0;
            UpdateHookGrid();
        };
        var btnFilterClear = new Button
        {
            Text = "清除筛选", Location = new Point(492, 4), Size = new Size(80, 25),
            FlatStyle = FlatStyle.Flat, BackColor = Color.FromArgb(50, 50, 58), ForeColor = Color.Gainsboro
        };
        btnFilterClear.Click += (_, _) =>
        {
            _filterSource = _filterVictim = "";
            _cmbFilterSource.SelectedIndex = 0;
            _cmbFilterVictim.SelectedIndex = 0;
            _hookPage = 0;
            UpdateHookGrid();
        };
        var btnClearDetails = new Button
        {
            Text = "清除伤害明细", Location = new Point(582, 4), Size = new Size(110, 25),
            FlatStyle = FlatStyle.Flat, BackColor = Color.FromArgb(60, 40, 40), ForeColor = Color.Gainsboro
        };
        btnClearDetails.Click += (_, _) =>
        {
            if (MessageBox.Show(this, "清空伤害事件列表，并把各条结算里的伤害构成/来源汇总一起清掉？\n（结算行本身保留）",
                    "清除伤害明细", MessageBoxButtons.YesNo, MessageBoxIcon.Question) != DialogResult.Yes) return;
            _engine.ClearHookDetails();
            _hookPage = 0;
            _hookSig = "";
            _lastSettlementShown = -1;
            _breakSig = "";
            _gridHook.Rows.Clear();
            _gridBreak.Rows.Clear();
            UpdateHookGrid();
            UpdateBreakdown();
            SetStatus("已清除伤害明细（含汇总结算）");
        };
        hookFilterBar.Controls.AddRange(new Control[] { lblDstFilter, _cmbFilterVictim, lblSrcFilter, _cmbFilterSource, btnFilterClear, btnClearDetails });

        // 底部分页条：首页 / 上一页 / 下一页 / 末页 + 页码标签
        var hookPageBar = new Panel { Dock = DockStyle.Bottom, Height = 34, BackColor = Color.FromArgb(28, 28, 34) };
        _btnHookFirst.Location = new Point(8, 5);  _btnHookFirst.Size = new Size(56, 25);
        _btnHookPrev.Location = new Point(70, 5);  _btnHookPrev.Size = new Size(68, 25);
        _btnHookNext.Location = new Point(144, 5); _btnHookNext.Size = new Size(68, 25);
        _btnHookLast.Location = new Point(218, 5); _btnHookLast.Size = new Size(56, 25);
        _lblHookPage.Location = new Point(288, 10);
        _lblHookPage.AutoSize = true;
        _lblHookPage.ForeColor = Color.Gainsboro;
        foreach (var b in new[] { _btnHookFirst, _btnHookPrev, _btnHookNext, _btnHookLast })
        {
            b.FlatStyle = FlatStyle.Flat;
            b.BackColor = Color.FromArgb(50, 50, 58);
            b.ForeColor = Color.Gainsboro;
            b.FlatAppearance.BorderColor = Color.FromArgb(80, 80, 90);
        }
        _btnHookFirst.Click += (_, _) => { _hookPage = 0; UpdateHookGrid(); };
        _btnHookPrev.Click += (_, _) => { _hookPage = Math.Max(0, _hookPage - 1); UpdateHookGrid(); };
        _btnHookNext.Click += (_, _) => { _hookPage++; UpdateHookGrid(); };
        _btnHookLast.Click += (_, _) => { _hookPage = int.MaxValue; UpdateHookGrid(); };   // UpdateHookGrid 里夹到末页
        hookPageBar.Controls.AddRange(new Control[] { _btnHookFirst, _btnHookPrev, _btnHookNext, _btnHookLast, _lblHookPage });

        _tabHook.Controls.Add(_gridHook);
        _tabHook.Controls.Add(hookFilterBar);
        _tabHook.Controls.Add(hookPageBar);

        if (BattlefieldUnitsEnabled)
        {
            // 页 3：战场单位（ddh 返回类型码、名称、称谓和单位属性）。
            // 名称列两行渲染（英雄：称谓小字 + 名称；非英雄：只有名称、垂直居中）。
            _tabUnits = new TabPage("战场单位") { BackColor = Color.FromArgb(24, 24, 28) };
            _gridUnits.Dock = DockStyle.Fill;
            _gridUnits.RowTemplate.Height = 36;
            UnitGridUi.AddColumns(_gridUnits);
            _gridUnits.CellPainting += OnUnitCellPainting;
            _unitsSearch = SettlementHeaderSearch.ForUnits(_gridUnits, ApplyUnitsFilterNow);
            _tabUnits.Controls.Add(_gridUnits);
        }

        // 页签顺序：死亡结算 / 伤害事件 / 战场单位名称
        _tabs.TabPages.Add(tabSettle);
        _tabs.TabPages.Add(_tabHook);
        if (BattlefieldUnitsEnabled) _tabs.TabPages.Add(_tabUnits);
        // 启动固定停在【死亡结算】：TabControl 在页面多、控件创建顺序不同时偶尔会停在别的页，
        // 首屏必须是死亡结算（用户打开软件第一眼要看的表）。
        _tabs.SelectedIndex = 0;
        // 切到【战场单位】时立刻刷新一轮（不等 1 秒节流），否则刚切过去会是一片 ? 停顿一下。
        _tabs.SelectedIndexChanged += (_, _) =>
        {
            // 切页后给一个很短（150ms）的防抖，避免连点两个页签时重复重建；
            // 不再像旧版那样空等 1.2 秒——那会让第一次切页明显“没反应”。
            _tabSwitchedAt = DateTime.Now;
            UpdateBackTopButton();

            // 等这一帧画完，立刻把当前页刷出来（用户看到的是“点完就有内容”，而不是空白等定时器）。
            if (!IsHandleCreated) return;   // 构造期设置初始页时还没有窗口句柄，跳过
            BeginInvoke(new Action(() =>
            {
                if (IsDisposed) return;
                _tabSwitchedAt = DateTime.MinValue;      // 取消防抖，后续 200ms tick 正常跟进
                if (BattlefieldUnitsEnabled && _tabs.SelectedTab == _tabUnits)
                {
                    _lastUnitsRefresh = DateTime.Now;
                    UpdateUnitsPage();
                }
                else if (_tabs.SelectedTab == _tabHook)
                {
                    UpdateHookGrid();
                }
                else
                {
                    UpdateSettlementGrid(_engine.Current);
                }
            }));
        };

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
        _lblConn.Text = "游戏未运行（自动重连中）";

        Controls.Add(_tabs);
        Controls.Add(_lblConn);
        Controls.Add(tool);
        // 底部状态栏已按要求删除：连接信息上面横幅已经有，底部这条是重复的。
        // （_status 控件保留但不加入布局，SetStatus/SetStatusRed 仍可安全调用。）

        // ---- 右下角【回到顶部】----
        // 当前页行数够多（>40）且已经往下滚过时才出现；点它回到第一行。
        _btnBackTop.Text = "回到顶部";
        _btnBackTop.Size = new Size(96, 30);
        _btnBackTop.Visible = false;
        _btnBackTop.TabStop = false;
        _btnBackTop.FlatStyle = FlatStyle.Flat;
        _btnBackTop.BackColor = Color.FromArgb(50, 50, 58);
        _btnBackTop.ForeColor = Color.Gainsboro;
        _btnBackTop.FlatAppearance.BorderColor = Color.FromArgb(90, 90, 100);
        _btnBackTop.Click += (_, _) => ScrollActiveGridToTop();
        Controls.Add(_btnBackTop);
        _btnBackTop.BringToFront();

        foreach (var g in new[] { _gridSettle, _gridHook })
            g.Scroll += (_, _) => UpdateBackTopButton();
        Resize += (_, _) => UpdateBackTopButton();

        // 首屏预热：窗口显示后立刻把可见页表的句柄/列布局建好。
        Shown += (_, _) => BeginInvoke(new Action(() =>
        {
            foreach (var g in new[] { _gridSettle, _gridHook })
            {
                try { g.CreateControl(); g.PerformLayout(); } catch { /* 预热失败不影响功能 */ }
            }
        }));
    }

    /// <summary>当前页对应的表格（用于【回到顶部】）。</summary>
    private DataGridView? ActiveGrid()
    {
        if (BattlefieldUnitsEnabled && _tabs.SelectedTab == _tabUnits) return _gridUnits;
        if (_tabs.SelectedTab == _tabHook) return _gridHook;
        return _gridSettle;
    }

    /// <summary>按“当前页行数 + 是否向下滚动过”决定【回到顶部】是否显示。</summary>
    private void UpdateBackTopButton()
    {
        bool show = false;
        var g = ActiveGrid();
        if (g != null && g.Rows.Count > 40)
        {
            try { show = g.FirstDisplayedScrollingRowIndex > 0; } catch { show = false; }
        }
        if (_btnBackTop.Visible != show) _btnBackTop.Visible = show;
        if (!show) return;
        _btnBackTop.Location = new Point(
            Math.Max(8, _tabs.Right - _btnBackTop.Width - 26),
            Math.Max(8, _tabs.Bottom - _btnBackTop.Height - 26));
        _btnBackTop.BringToFront();
    }

    /// <summary>回到当前页第一行（不改变选中行，避免顺带触发详情刷新）。</summary>
    private void ScrollActiveGridToTop()
    {
        var g = ActiveGrid();
        if (g == null || g.Rows.Count == 0) return;
        try { g.FirstDisplayedScrollingRowIndex = 0; } catch { }
        UpdateBackTopButton();
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
    private void DoFind()
    {
        SetStatus("正在查找 war3 进程…");
        _cmdFind.Enabled = false;
        Application.DoEvents();
        try
        {
            // 断开/退出后保留当前结算，方便还在界面上直接看；
            // 只有真正连上新一局时，Attach 内部才会保存旧局并清空（用户要求）。
            bool ok = _engine.Attach(out string msg);
            if (ok)
            {
                _lblConn.BackColor = Color.FromArgb(28, 48, 28);
                _lblConn.ForeColor = Color.LightGreen;
                _lblConn.Text = "已连接：" + msg;
                SetStatus(msg);
            }
            else
            {
                // 失败态不再弹模态框：只把横幅/状态栏提示一下，后台自动重连继续跑。
                // 只有"权限不足"才用红色；"游戏没启动"是正常状态，用中性色，别把它画成错误。
                bool denied = _engine.Current.AccessDeniedPid != null;
                _lblConn.BackColor = denied ? Color.FromArgb(60, 34, 34) : Color.FromArgb(50, 46, 30);
                _lblConn.ForeColor = denied ? Color.Salmon : Color.Khaki;
                _lblConn.Text = msg;
                if (denied) SetStatusRed(msg); else SetStatus(msg);
            }
        }
        finally { _cmdFind.Enabled = true; }
    }

    /// <summary>
    /// 启动时的一次性提示：伤害钩子要注入 ddh.dll，而注入需要"不比自己低 + 拿得到 DACL"。
    /// <para>
    /// 实测（本机 11 平台拉起的 war3）：**即使游戏也是 Medium**，普通权限下
    /// <c>OpenProcess</c> 仍然 <c>err=5</c> —— 所以这功能实际上等于"需要管理员"。
    /// 但也别把话说死：游戏由自己的启动器以普通权限拉起时，普通权限是能注入的。
    /// </para>
    /// </summary>
    private void HintHookNeedsAdminOnce()
    {
        if (!_settings.HookEnabled) return;

        if (Integrity.IsSelfElevated)
        {
            Log.Write("伤害钩子：已开启，当前是管理员权限 —— 注入不会被权限挡住。");
            return;
        }

        Log.Write("伤害钩子：已开启，但本程序是 " + Integrity.Name(Integrity.Self) +
                  " —— 若游戏由 11/网易等平台或服务拉起，注入会 err=5，需要以管理员身份运行。");

        if (_settings.HookAdminHintShown) return;   // 提示过就不再骚扰，日志里仍有记录

        try
        {
            var r = MessageBox.Show(this,
                "配置里开启了伤害钩子（hook_enable=1），但本程序当前不是管理员权限。\n\n" +
                "· 游戏由你自己的启动器以普通权限拉起 → 通常能正常注入；\n" +
                "· 游戏由 11 平台 / 网易平台 / 服务拉起 → 注入会被系统拒绝（OpenProcess err=5，\n" +
                "  连进程都查询不了），必须以管理员身份运行。\n\n" +
                "现在以管理员身份重启吗？\n\n" +
                "（选“否”继续用普通权限；这个提示只出现这一次，之后可在上方工具栏点【以管理员身份重启】）",
                "伤害钩子需要管理员权限",
                MessageBoxButtons.YesNo, MessageBoxIcon.Information, MessageBoxDefaultButton.Button2);
            if (r == DialogResult.Yes) { RestartAsAdmin(); return; }
        }
        catch (Exception ex) { Log.Warn("启动提示失败：" + ex.Message); }

        try { _settings.HookAdminHintShown = true; _settings.Save(); } catch { }
    }

    /// <summary>以管理员身份重启自身（UseShellExecute + runas，不写任何注册表）。用户取消 UAC 不崩。</summary>
    private void RestartAsAdmin()
    {
        // 已经是管理员就别再 runas 一次：那会多开一个窗口，用户以为"点了没反应"。
        if (Integrity.IsSelfElevated)
        {
            SetStatus("当前已经是管理员权限，无需重启");
            return;
        }
        try
        {
            string exe = Environment.ProcessPath ?? Application.ExecutablePath;
            var psi = new System.Diagnostics.ProcessStartInfo(exe)
            {
                UseShellExecute = true,
                Verb = "runas"
            };
            var argv = Environment.GetCommandLineArgs();
            if (argv.Length > 1)
                psi.Arguments = string.Join(" ", argv.Skip(1).Select(CliOptions.Quote));
            System.Diagnostics.Process.Start(psi);
            Close();
        }
        catch (Exception ex)
        {
            // 用户取消 UAC（Win32Exception，ERROR_CANCELLED=1223）会走到这里：不崩，只提示。
            SetStatusRed("已取消提权：" + ex.Message);
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

    /// <summary>
    /// 打开【历史】窗口（非模态、只读）：显示 ddh 游戏状态会话的死亡结算 + 分组统计 + 伤害明细。
    /// 已经开着就只激活，不重复开窗口。
    /// </summary>
    private void OpenHistory()
    {
        if (_historyForm is { IsDisposed: false })
        {
            if (_historyForm.WindowState == FormWindowState.Minimized)
                _historyForm.WindowState = FormWindowState.Normal;
            _historyForm.Activate();
            return;
        }

        _historyForm = new HistoryForm();
        _historyForm.FormClosed += (_, _) => _historyForm = null;
        _historyForm.Show(this);
        SetStatus($"已打开对局历史（ddh：{DdhHistoryReader.DatabasePath}）");
    }

    // ------------------------------------------------------------------
    private void RefreshUi()
    {
        // 切页后的极短防抖（150ms）：只用于合并连点页签，不再挡住第一次切页的数据。
        if ((DateTime.Now - _tabSwitchedAt).TotalMilliseconds < 150)
        {
            UpdateBackTopButton();
            return;
        }

        var snap = _engine.Current;
        // 快照必须属于当前进程：过期快照一律不渲染（换局/重连旧数据残留的根治点）
        int livePid = _engine.Game?.Mem.Pid ?? 0;
        if (snap.Pid != 0 && livePid != 0 && snap.Pid != livePid)
        {
            return;
        }
        if (livePid > 0)

        // 【战场单位】与新局同一步清空：连接新进程 / 同进程换图时，这里在 200ms 的界面节拍上
        // 立刻清表并作废属性缓存，而不是等用户切到【战场单位】页或滚回顶部才清。
        // 退出游戏（livePid == 0）不清：与死亡结算/伤害明细一样保留上一局，直到真正连上新局。
        if (BattlefieldUnitsEnabled && livePid != 0)
        {
            string session = CurrentUnitSessionKey();
            if (session.Length > 0 &&
                !string.Equals(session, _unitSessionKey, StringComparison.Ordinal))
            {
                _unitSessionKey = session;
                ResetUnitsForNewSession();
            }
        }
        if (snap.At == _lastShown) { UpdateBackTopButton(); return; }
        _lastShown = snap.At;

        // 连接状态 / 权限不足 / 未运行 → 更新横幅、状态标签与按钮
        int? deniedPid = snap.AccessDeniedPid;
        // 注入被完整性级别拦下也要进签名：不然"已连接"的绿横幅永远不会刷新成红提示。
        bool hookBlocked = snap.Ready && _engine.HookBlockedByIntegrity;
        string bannerSig = (snap.Ready ? "R" : "N") + "|" + (deniedPid?.ToString() ?? "") + "|"
                         + (hookBlocked ? "I" : "") + "|" + snap.Status;
        if (!string.Equals(bannerSig, _lastBannerSig, StringComparison.Ordinal))
        {
            _lastBannerSig = bannerSig;
            if (snap.Ready)
            {
                if (hookBlocked)
                {
                    // 读得到、写不进去：只读路径不需要管理员，注入 ddh.dll 需要，
                    // 于是会出现"已连接但钩子死活挂不上"——这里必须说清原因并给出按钮。
                    _lblConn.BackColor = Color.FromArgb(60, 34, 34);
                    _lblConn.ForeColor = Color.Salmon;
                    _lblConn.Text = $"已连接，但注入需要管理员（{_engine.HookIntegrityHint}）——点上方【以管理员身份重启】";
                    _cmdRestartAdmin.Visible = true;
                    _lblState.Text = "可读，注入受限";
                    _lblState.ForeColor = Color.Salmon;
                }
                else
                {
                    _lblConn.BackColor = Color.FromArgb(28, 48, 28);
                    _lblConn.ForeColor = Color.LightGreen;
                    _lblConn.Text = "已连接：" + snap.Status;
                    _cmdRestartAdmin.Visible = false;
                    _lblState.Text = "监视中";
                    _lblState.ForeColor = Color.LightGreen;
                }
                _cmdDiag.Enabled = true;
            }
            else if (deniedPid is int dp)
            {
                _lblConn.BackColor = Color.FromArgb(60, 34, 34);
                _lblConn.ForeColor = Color.Salmon;
                _lblConn.Text = $"找到魔兽（PID {dp}）但权限不足";
                _cmdRestartAdmin.Visible = true;
                _cmdDiag.Enabled = false;
                _lblState.Text = "权限不足";
                _lblState.ForeColor = Color.Salmon;
            }
            else
            {
                _lblConn.BackColor = Color.FromArgb(50, 46, 30);
                _lblConn.ForeColor = Color.Khaki;
                _lblConn.Text = "游戏未运行（自动重连中；当前结算保留，连上新游戏后清空）";
                _cmdRestartAdmin.Visible = false;
                _cmdDiag.Enabled = false;
                _lblState.Text = "游戏未运行";
                _lblState.ForeColor = Color.Khaki;
            }
        }

        // 状态栏
        _lblStats.Text = snap.Ready
            ? $"单位 {snap.Units.Count(u => u.Hp > 0f)}｜结算 {snap.Settlements.Count}｜" +
              $"扫描 {snap.Stats.ElapsedMs}ms（{snap.Stats.Mode}）"
            : "";
        if (snap.Ready)
        {
            _statusText.Text = snap.Status;
            _statusText.ForeColor = Color.Gainsboro;
        }

        // 结算表：结算行（新的在上面）+ 还活着的受伤单位（蓝字，见 UpdateSettlementGrid）。
        // 不可见页 / 用户正在拖滚动条或选行 / 正在表头搜索框里输入时先不动表，等下一轮再补。
        // 【关键】已经往下滚过（含滚到底）就整页冻结：不插入新行、不删旧行，内容和滚动条一点都不动；
        // 滚回顶部后下一轮自然刷新（翻页/换筛选不受影响，那是用户主动操作）。
        if (_gridSettle.Visible && !IsScrolledDown(_gridSettle) && !_settleSearch.IsEditing && !_gridSettle.IsUserInteracting)
            UpdateSettlementGrid(snap);

        // 下方分组统计跟着当前选中行走；存活行每次刷新重算（数据在变）
        if (_gridBreak.Visible && !_gridBreak.IsUserInteracting)
            UpdateBreakdown();

        // 伤害事件页：只在可见时更新（隐藏页不重建 500 行），用户拖滚动条/正在表头输入时让路
        // （输入即搜由搜索组件自己的 150ms 定时器触发 onChanged，不依赖这里的 200ms 刷新）。
        // 例外：右键【跟踪】钉住的搜索框（IsTracking）没有焦点、用户也没在输入，照常实时刷新。
        // 同样：滚过就冻结，避免“新事件把第 1 页的行挤走、内容一直变”。
        if (_gridHook.Visible && !IsScrolledDown(_gridHook) && (!_hookSearch.IsEditing || _hookSearch.IsTracking) && !_gridHook.IsUserInteracting)
            UpdateHookGrid();

        // 战场单位页：ddh 每隔约 1 秒处理一轮单位属性请求，所以这里也按 1 秒节流；
        // 不可见 / 用户正在拖滚动条或选行 / 正在表头输入 / 已经往下滚过时让路（滚过就冻结，内容不动）。
        if (BattlefieldUnitsEnabled && _gridUnits.Visible && !IsScrolledDown(_gridUnits) &&
            !_unitsSearch.IsEditing && !_gridUnits.IsUserInteracting &&
            (DateTime.Now - _lastUnitsRefresh).TotalMilliseconds >= 1000)
        {
            _lastUnitsRefresh = DateTime.Now;
            UpdateUnitsPage();
        }
        else if (BattlefieldUnitsEnabled &&
                 (DateTime.Now - _lastClassifyRefresh).TotalMilliseconds >= 2000)
        {
            _lastClassifyRefresh = DateTime.Now;
            PumpUnitClassification();
        }
    }

    /// <summary>
    /// 表格是否已经往下滚过（第一可见行 &gt; 0）。为真时【冻结刷新】：不插入/删除行，
    /// 内容和滚动条都保持不动；用户滚回顶部后下一次刷新自动恢复。空表的 FirstDisplayedScrollingRowIndex
    /// 是 -1，所以首次填充不会被挡住。
    /// </summary>
    private static bool IsScrolledDown(DataGridView g)
    {
        try { return g.Rows.Count > 0 && g.FirstDisplayedScrollingRowIndex > 0; }
        catch { return false; }
    }

    // ------------------------------------------------------------------
    /// <summary>
    /// 批量重建表格。
    /// 逐行 Insert/Add 且列是 AutoSizeMode=Fill 时，每加一行都会触发表格重新布局、重新计算列宽，
    /// 500 行就是 O(n²) 的布局开销 —— 这是“第一次切到伤害事件/战场单位”卡几百毫秒的主因。
    /// 这里先 SuspendLayout、把 Fill 临时改成 None，用 Rows.Add(count) 一次建行再 SetValues，
    /// 最后恢复列模式；整个重建只做一次列宽计算。
    /// </summary>
    private static void BulkFill(DataGridView g, int count,
                                 Func<int, object[]> cells,
                                 Action<DataGridViewRow, int>? decorate = null)
    {
        var sw = System.Diagnostics.Stopwatch.StartNew();
        g.SuspendLayout();
        var modes = new DataGridViewAutoSizeColumnMode[g.Columns.Count];
        for (int i = 0; i < g.Columns.Count; i++)
        {
            modes[i] = g.Columns[i].AutoSizeMode;
            if (modes[i] != DataGridViewAutoSizeColumnMode.None)
                g.Columns[i].AutoSizeMode = DataGridViewAutoSizeColumnMode.None;
        }
        try
        {
            g.Rows.Clear();
            if (count <= 0) return;
            g.Rows.Add(count);
            for (int i = 0; i < count; i++)
            {
                var row = g.Rows[i];
                row.SetValues(cells(i));
                decorate?.Invoke(row, i);
            }
        }
        finally
        {
            for (int i = 0; i < g.Columns.Count; i++) g.Columns[i].AutoSizeMode = modes[i];
            g.ResumeLayout(true);
            sw.Stop();
            if (sw.ElapsedMilliseconds >= 50)
                Log.Write($"界面：批量填充 {g.Columns.Count} 列 × {count} 行，用时 {sw.ElapsedMilliseconds}ms（{g.Name}）");
        }
    }

    // ------------------------------------------------------------------
    /// <summary>
    /// 【死亡结算】页：结算行（按 DiedAt 降序，新的在上）+ 还活着的受伤单位（蓝字，按累计受伤降序）。
    /// 结算数变化时优先增量**有序插入**（新行二分插到该在的位置，不盲插顶部）；名字表变化 /
    /// 行集合对不上 / 检测到乱序才整表重建。存活行只要“存活且 Hits&gt;0”的
    /// 单位集合或它们的数字变了就跟着刷新 —— 用签名比较避免每 200ms 都整表重建。
    /// 重建全程按身份锚定视口（PreserveViewAnchor），并在重建后按身份找回用户选中的行（不抢用户选择）。
    /// </summary>
    private void UpdateSettlementGrid(Snapshot snap)
    {
        var set = snap.Settlements;
        // 换局/清空历史后结算从 0 重新开始：把上一局的表头搜索一起清掉，
        // 否则新的一局一进来可能“一行都看不到”，只剩表头里的（⌕ 上一局关键词）。
        if (set.Count == 0 && _lastSettlementShown > 0) _settleSearch.Clear(notify: false);

        bool filtering = _settleSearch.HasFilter;

        // 名字表（钩子事件 + 插件日志）条数变化 → 结算行「单位名」列也要跟着刷新。
        int namesKnown = (_engine.PluginLog?.CodeToName.Count ?? 0) + _engine.HookNameCount;
        bool namesChanged = namesKnown != _lastNamesShown ||
                            _attrIdentityVersion != _lastAttrIdentityShown;
        // 条数变化 = 有新增；快照列表换了 (条数不变) = 有结算被替换/重新过滤（例如补建↔正常结算），也要重画。
        bool settlementsChanged = set.Count != _lastSettlementShown || namesChanged ||
                                  !ReferenceEquals(set, _lastSettlementList);

        // 死亡结算页只列真正死亡（DiedAt 非空）的结算；存活受伤单位不再追加到底部。
        var liveUnits = new List<UnitView>();
        string liveSig = LiveSignature(snap.Units);
        bool liveValuesChanged = liveSig != _lastLiveSig;
        string liveKey = LiveRowKey(liveUnits);
        bool liveSetChanged = liveKey != _liveRowKey;

        if (!settlementsChanged && !liveValuesChanged && !liveSetChanged) return;

        // 重建前记住当前选中行的“身份”，整表重建后找回来（见 SameRowTag）
        object? selectedTag = _gridSettle.SelectedRows.Count > 0 ? _gridSettle.SelectedRows[0].Tag : null;
        bool hadSelection = selectedTag != null;

        // 整个更新过程都用 _restoringSelection 包住：程序化插行/删除/恢复选中触发的
        // SelectionChanged 不当作“用户切换选中”，下方分组统计不会闪、不抢滚动条。
        _restoringSelection = true;
        try
        {
            bool fullRebuild = false;
            if (settlementsChanged)
            {
                // 快照已按 SettlementOrder 降序（新的在前）。新增的结算不一定在快照尾部、也不一定比
                // 现有行新（致命事件补建/无来源补挂会更早），所以增量路径只负责“插到它该在的位置”。
                // 名字表变化或表头搜索生效时行集合对不上 → 必须整表重建。
                if (!filtering && !namesChanged && TryInsertSettlementRows(set))
                {
                    // 已增量插入，下面的存活行同步只处理底部
                }
                else
                {
                    RebuildSettlementRows(set, liveUnits, snap.At, selectedTag);
                    fullRebuild = true;
                }
            }

            if (!fullRebuild)
            {
                if (filtering)
                {
                    // 过滤生效时蓝字存活行的数字/集合变化也会改变“命中集合” → 同样走整表重建
                    // （RebuildSettlementRows 内部用 PreserveViewAnchor 保滚动、按身份找回选中）。
                    RebuildSettlementRows(set, liveUnits, snap.At, selectedTag);
                }
                else
                {
                    SyncLiveRows(liveUnits, snap.At, liveSetChanged, liveValuesChanged);
                    if (!hadSelection && _gridSettle.Rows.Count > 0)
                        _gridSettle.CurrentCell = null;   // 清掉加行时可能产生的自动首行选中
                }
            }
        }
        finally { _restoringSelection = false; }

        _lastSettlementShown = set.Count;
        _lastSettlementList = set;
        _lastNamesShown = namesKnown;
        _lastAttrIdentityShown = _attrIdentityVersion;
        _lastLiveSig = liveSig;
        _liveRowKey = liveKey;
        // _settleRowCount 由 TryInsertSettlementRows / RebuildSettlementRows / SyncLiveRows 自己维护：
        // 过滤生效时表里的结算行数 < set.Count，不能再无条件写成 set.Count。
    }

    /// <summary>
    /// 表头搜索框应用 / 清除关键词后立即整表重建，不等 200ms 定时器。
    /// 同时把增量状态作废：过滤期间表里的行是筛过的，下一次刷新也必须走整表重建，
    /// 不能拿“旧行数 + 新结算数”去做增量插入。
    /// </summary>
    private void ApplySettlementFilterNow()
    {
        _lastSettlementShown = -1;
        _lastNamesShown = -1;
        _lastAttrIdentityShown = -1;
        _lastLiveSig = "";
        _liveRowKey = "";
        UpdateSettlementGrid(_engine.Current);
    }

    /// <summary>存活行集合的“身份键”（地址 + 实例，按显示顺序）：只变数字时不重建行。</summary>
    private static string LiveRowKey(IReadOnlyList<UnitView> liveUnits)
    {
        var sb = new StringBuilder();
        foreach (var u in liveUnits)
            sb.Append(u.Addr.ToString("X8")).Append(':').Append(u.InstanceIndex).Append(';');
        return sb.ToString();
    }

    /// <summary>
    /// 增量更新结算区（原 TryPrependSettlementRows）：把新增的结算行**插到它该在的位置**，
    /// 不再假设“新的一定在快照尾部、一定比现有行新”。
    /// 顺序统一走 <see cref="SettlementOrder"/>：现有行本来就按 DiedAt 降序，二分查找插入点即可；
    /// 致命事件补建 / 无来源补挂带来的更早结算会插到中间或末尾，不会顶到顶部。
    ///
    /// 返回 false 的情况（调用方走整表重建）：过滤生效 / 现有行不是结算 / 现有时间序列已经乱序 /
    /// 行集合和快照对不上。乱序时记一条限流日志（最多 5 条），方便以后定位是谁绕过了有序插入。
    /// </summary>
    private bool TryInsertSettlementRows(IReadOnlyList<Settlement> set)
    {
        // 过滤生效时表里的行是筛过的，旧行数/行序都对不上 set，直接让调用方走整表重建。
        if (_settleSearch.HasFilter) return false;

        int oldCount = _settleRowCount;
        if (oldCount <= 0 || set.Count <= oldCount || _gridSettle.Rows.Count < oldCount) return false;

        // 现有结算行（新的在上）：必须清一色是 Settlement，且时间序列已经非递增。
        var rows = new List<Settlement>(oldCount);
        for (int i = 0; i < oldCount; i++)
        {
            if (_gridSettle.Rows[i].Tag is not Settlement rowTag) return false;
            rows.Add(rowTag);
        }
        int disorder = SettlementOrder.FirstDisorderIndex(rows);
        if (disorder >= 0)
        {
            LogSettlementOrderDisorder(rows[0], rows[disorder]);
            return false;
        }

        // 快照里必须还包含所有现有行（有行被删/被替换 → 增量对不上，整表重建）。
        var inSnapshot = new HashSet<Settlement>(set);
        foreach (var s in rows)
            if (!inSnapshot.Contains(s)) return false;

        // 新增行 = 快照里有、表里还没有的（按快照顺序收集；通常只有 1 条）。
        var shown = new HashSet<Settlement>(rows);
        var fresh = new List<Settlement>(set.Count - oldCount);
        foreach (var s in set)
            if (!shown.Contains(s)) fresh.Add(s);
        if (fresh.Count != set.Count - oldCount) return false;   // 有重复/漏算 → 整表重建更稳

        int first = -1, visible = 1;
        string settleAnchor = "";
        try
        {
            visible = Math.Max(1, _gridSettle.DisplayedRowCount(false));
            first = _gridSettle.Rows.Count > 0 ? _gridSettle.FirstDisplayedScrollingRowIndex : -1;
            // 需求：只有停在最顶部才跟随新数据；一旦往下滚过（含滚到底），按第一可见行的身份钉住视口。
            if (first > 0 && first < _gridSettle.Rows.Count)
                settleAnchor = SettlementKey(_gridSettle.Rows[first].Tag);
        }
        catch { }

        int above = 0;   // 插到当前视口上方的新行数：滚动锚点按它下移，保持用户看的内容不动
        int anchor = first;   // 视口第一行在“当前行集合”里的下标（每次在它上面插行就 +1）
        int settleCount = oldCount;
        foreach (var s in fresh)
        {
            int pos = SettlementOrder.FindInsertIndex(rows, s);
            AddSettlementRow(pos, s);   // 存活行在结算区下方，会被整体挤下去，位置逻辑不变
            rows.Insert(pos, s);
            settleCount++;
            if (first >= 0 && pos <= anchor) { above++; anchor++; }
        }
        _settleRowCount = settleCount;

        // 插入后整段仍然必须降序（二分插入保证；万一出现意外 → 记日志并退回整表重建）。
        disorder = SettlementOrder.FirstDisorderIndex(rows);
        if (disorder >= 0)
        {
            LogSettlementOrderDisorder(rows[0], rows[disorder]);
            return false;
        }

        // 滚动锚点：停在最顶部 → 留在顶部看新行；一旦往下滚过（含滚到底）→ 按身份钉回去，
        // 内容与滚动条都不动（原来贴底会一直往下跳，已去掉）。
        try
        {
            if (_gridSettle.Rows.Count > 0)
            {
                int target = 0;
                if (first > 0)
                {
                    int found = -1;
                    if (settleAnchor.Length > 0)
                    {
                        for (int i = 0; i < _gridSettle.Rows.Count; i++)
                            if (string.Equals(SettlementKey(_gridSettle.Rows[i].Tag), settleAnchor, StringComparison.Ordinal)) { found = i; break; }
                    }
                    if (found < 0) found = first + above;   // 锚点没了就按“上方插入数”下移
                    target = Math.Clamp(found, 0, Math.Max(0, _gridSettle.Rows.Count - visible));
                }
                _gridSettle.FirstDisplayedScrollingRowIndex = target;
            }
        }
        catch { }
        return true;
    }

    /// <summary>
    /// 结算表乱序限流日志（最多 5 条）：命中说明“新行没插到它该在的位置”，这一轮直接退回整表重建。
    /// 正常路径不会打这条；留着是为了下次真出现乱序时能从日志一眼看出顶部/越界行的时间。
    /// </summary>
    private void LogSettlementOrderDisorder(Settlement top, Settlement offender)
    {
        if (_settleOrderLogged >= 5) return;
        _settleOrderLogged++;
        Log.Write($"结算排序：检测到乱序（顶部={top.DiedAt:HH:mm:ss.fff} 新={offender.DiedAt:HH:mm:ss.fff}）→ 整表重建");
    }

    /// <summary>整表重建结算区（结算行 + 存活行）。只在名字变化 / 列表缩小 / 增量对不上时走这里。</summary>
    private void RebuildSettlementRows(IReadOnlyList<Settlement> set, IReadOnlyList<UnitView> liveUnits,
                                       DateTime at, object? selectedTag)
    {
        PreserveViewAnchor(_gridSettle, r => SettlementKey(r.Tag), () =>
        {
            // 先把要显示的行收集齐，再一次性 BulkFill：
            // 逐行 Insert + Fill 列会让每一行都重算列宽（O(n²)），首次显示会明显卡顿。
            var cellsList = new List<object[]>(set.Count + liveUnits.Count);
            var tags = new List<object>(set.Count + liveUnits.Count);
            var colors = new List<Color>(set.Count + liveUnits.Count);

            // ① 结算行（新的在最上面）；行渲染与【历史】窗口共用。
            //    快照本身已按 SettlementOrder 降序，这里再显式排一次兜底（调用方顺序不对也不会乱）。
            //    表头搜索生效时只插入命中的行（谓词与单元格 Value 同源：单位名 / 类型码）。
            //    单位名称这一列显示并匹配英雄称谓（按地址查 MonitorEngine 的称谓索引）。
            bool filtering = _settleSearch.HasFilter;
            int settleRows = 0;
            var ordered = SettlementOrder.SortDescending(set);
            for (int i = 0; i < ordered.Count; i++)
            {
                var s = ordered[i];
                var identity = UnitIdentityFor(s.Addr, s.TypeCode);
                string title = identity.Title;
                var cells = SettlementGridUi.Cells(
                    s, title, identity.Name is { Length: > 0 } ? identity.Name : s.UnitName,
                    identity.OwnerSlot);
                if (filtering && !_settleSearch.MatchesValues(
                        cells[SettlementGridUi.NameCellIndex], cells[SettlementGridUi.CodeCellIndex],
                        firstTitle: title))
                    continue;
                cellsList.Add(cells);
                tags.Add(s);
                colors.Add(s.Kind == "死亡" ? Color.FromArgb(255, 140, 140) : Color.FromArgb(200, 200, 140));
                settleRows++;
            }

            // ② 存活行（还活着、且受过伤害；蓝字区分）。存活行也要一起过滤（同样按名字或称谓）。
            foreach (var u in liveUnits)
            {
                var cells = LiveCells(u, at);
                if (filtering && !_settleSearch.MatchesValues(
                        cells[SettlementGridUi.NameCellIndex], cells[SettlementGridUi.CodeCellIndex],
                        firstTitle: TitleOf(u.Addr, u.TypeCode)))
                    continue;
                cellsList.Add(cells);
                tags.Add(new LiveUnitRow(u));
                colors.Add(Color.FromArgb(120, 190, 255));
            }

            BulkFill(_gridSettle, cellsList.Count, i => cellsList[i], (row, i) =>
            {
                row.Tag = tags[i];
                row.DefaultCellStyle.ForeColor = colors[i];
            });

            _settleRowCount = settleRows;
        });

        // 恢复选中：只恢复用户之前选中的行；原本没选中就保持未选中。
        if (_gridSettle.Rows.Count > 0)
        {
            DataGridViewRow? sel = null;
            if (selectedTag != null)
            {
                foreach (DataGridViewRow r in _gridSettle.Rows)
                    if (SameRowTag(r.Tag, selectedTag)) { sel = r; break; }
            }
            if (sel != null) sel.Selected = true;
            else _gridSettle.CurrentCell = null;   // 清掉加行时的自动首行选中
        }
    }

    /// <summary>插一条结算行（index=0 插到顶部，index=Rows.Count 追加到尾部），颜色按死亡/消失。</summary>
    private void AddSettlementRow(int index, Settlement s)
    {
        var identity = UnitIdentityFor(s.Addr, s.TypeCode);
        AddSettlementRow(index, s, SettlementGridUi.Cells(
            s, identity.Title, identity.Name is { Length: > 0 } ? identity.Name : s.UnitName,
            identity.OwnerSlot));
    }

    /// <summary>同上，复用已经算好的单元格文本（过滤时要先看值再决定插不插，避免重复拼字符串）。</summary>
    private void AddSettlementRow(int index, Settlement s, object[] cells)
    {
        _gridSettle.Rows.Insert(index, cells);
        var row = _gridSettle.Rows[index];
        row.Tag = s;
        row.DefaultCellStyle.ForeColor = s.Kind == "死亡"
            ? Color.FromArgb(255, 140, 140)
            : Color.FromArgb(200, 200, 140);
    }

    /// <summary>追加一条蓝色存活行。</summary>
    private void AddLiveRow(UnitView u, DateTime at) => AddLiveRow(u, at, LiveCells(u, at));

    /// <summary>同上，复用已经算好的单元格文本（过滤谓词要读单位名/类型码两格）。</summary>
    private void AddLiveRow(UnitView u, DateTime at, object[] cells)
    {
        int idx = _gridSettle.Rows.Add(cells);
        var row = _gridSettle.Rows[idx];
        row.Tag = new LiveUnitRow(u);
        row.DefaultCellStyle.ForeColor = Color.FromArgb(120, 190, 255);
    }

    /// <summary>
    /// 只同步底部的存活行：数字变了就原地 SetValues（滚动条完全不动）；
    /// 存活单位集合变了才在底部增删，前面的结算行保持不动。
    /// </summary>
    private void SyncLiveRows(IReadOnlyList<UnitView> liveUnits, DateTime at, bool setChanged, bool valuesChanged)
    {
        // 过滤生效时表里只有命中行（结算行数也 < set.Count），原地同步的“结算行 + 存活行”布局不成立。
        if (_settleSearch.HasFilter) return;

        if (_settleRowCount > _gridSettle.Rows.Count)
            _settleRowCount = _gridSettle.Rows.Count;

        if (!setChanged)
        {
            if (!valuesChanged) return;
            for (int i = 0; i < liveUnits.Count; i++)
            {
                int rowIndex = _settleRowCount + i;
                if (rowIndex < 0 || rowIndex >= _gridSettle.Rows.Count) break;
                var row = _gridSettle.Rows[rowIndex];
                row.SetValues(LiveCells(liveUnits[i], at));
                row.Tag = new LiveUnitRow(liveUnits[i]);
            }
            return;
        }

        int first = -1, visible = 1;
        string liveAnchor = "";
        try
        {
            visible = Math.Max(1, _gridSettle.DisplayedRowCount(false));
            first = _gridSettle.Rows.Count > 0 ? _gridSettle.FirstDisplayedScrollingRowIndex : -1;
            if (first > 0 && first < _gridSettle.Rows.Count)
                liveAnchor = SettlementKey(_gridSettle.Rows[first].Tag);
        }
        catch { }

        for (int i = _gridSettle.Rows.Count - 1; i >= _settleRowCount; i--)
            _gridSettle.Rows.RemoveAt(i);
        foreach (var u in liveUnits) AddLiveRow(u, at);

        // 需求：顶部跟随新数据；滚过就按身份钉住（原来贴底会一直往下跳）。
        try
        {
            if (_gridSettle.Rows.Count > 0)
            {
                int target = 0;
                if (first > 0)
                {
                    int found = -1;
                    if (liveAnchor.Length > 0)
                    {
                        for (int i = 0; i < _gridSettle.Rows.Count; i++)
                            if (string.Equals(SettlementKey(_gridSettle.Rows[i].Tag), liveAnchor, StringComparison.Ordinal)) { found = i; break; }
                    }
                    if (found < 0) found = first;   // 行没变就按原下标
                    target = Math.Clamp(found, 0, Math.Max(0, _gridSettle.Rows.Count - visible));
                }
                _gridSettle.FirstDisplayedScrollingRowIndex = target;
            }
        }
        catch { }
    }

    /// <summary>存活行的“变化签名”：只要它变了就更新底部蓝字行（结算行不再跟着重建）。</summary>
    private static string LiveSignature(IReadOnlyList<UnitView> units)
    {
        var sb = new StringBuilder();
        foreach (var u in units.Where(u => u.State == "存活" && u.Hits > 0).OrderByDescending(u => u.Taken))
        {
            sb.Append(u.Addr.ToString("X8")).Append('|')
              .Append(u.InstanceIndex).Append('|')
              .Append(u.Taken.ToString("0.##")).Append('|')
              .Append(u.Hits).Append('|')
              .Append(u.Hp.ToString("0.#")).Append('|')
              .Append(u.MaxHit.ToString("0.##")).Append('|')
              .Append(u.Peak1s.ToString("0.##")).Append(';');
        }
        return sb.ToString();
    }

    /// <summary>存活行的一行单元格（列序和 _gridSettle 的定义一致）。</summary>
    private object[] LiveCells(UnitView u, DateTime at)
    {
        var identity = UnitIdentityFor(u.Addr, u.TypeCode);
        int ownerSlot = identity.OwnerSlot >= 0 ? identity.OwnerSlot : u.OwnerSlot;
        return new object[]
        {
            "—",
            SettlementGridUi.UnitDisplayName(
                identity.Name is { Length: > 0 } ? identity.Name : u.Name,
                identity.Title, u.TypeCode),
            u.TypeCode,
            UnitEvents.FormatAddr(u.Addr),
            UnitEvents.FormatPlayer(ownerSlot),
            "存活",
            u.InstanceIndex,
            u.Hits,
            u.Taken.ToString("0.00"),
            u.MaxHit > 0 ? u.MaxHit.ToString("0.00") : "",
            u.Peak1s > 0 ? u.Peak1s.ToString("0.00") : "",
            u.Dps.ToString("0.00"),
            u.FirstSeen != default ? (at - u.FirstSeen).TotalSeconds.ToString("0.0") : "",
            (u.FirstHit.HasValue && u.LastHit.HasValue)
                ? (u.LastHit.Value - u.FirstHit.Value).TotalSeconds.ToString("0.0") : "",
        };
    }

    /// <summary>判断两次重建里的 Tag 是不是同一行（结算按 地址+死亡时间+实例，存活按 地址+实例）。</summary>
    private static bool SameRowTag(object? a, object? b)
    {
        if (ReferenceEquals(a, b)) return true;
        return (a, b) switch
        {
            (Settlement sa, Settlement sb) => sa.Addr == sb.Addr && sa.DiedAt == sb.DiedAt && sa.InstanceIndex == sb.InstanceIndex,
            (LiveUnitRow la, LiveUnitRow lb) => la.Unit.Addr == lb.Unit.Addr && la.Unit.InstanceIndex == lb.Unit.InstanceIndex,
            _ => false
        };
    }

    /// <summary>
    /// 双击结算表任意一行 → 打开【非模态】弹窗（UnitEventsForm），只看这个单位（来源/触发）的事件。
    /// 结算行取 Settlement.Addr；存活行取 LiveUnitRow.Unit.Addr。弹窗用打开瞬间的事件快照。
    /// </summary>
    private void OnSettleDoubleClick(DataGridViewCellEventArgs e)
    {
        if (e.RowIndex < 0 || e.RowIndex >= _gridSettle.Rows.Count) return;
        var tag = _gridSettle.Rows[e.RowIndex].Tag;
        (uint Addr, string Name) target;
        if (tag is Settlement s) target = SettleJump.FromSettlement(s);
        else if (tag is LiveUnitRow lr) target = SettleJump.FromLiveUnit(lr.Unit.Addr, lr.Unit.TypeCode, lr.Unit.Name);
        else return;

        OpenUnitEventsForm(target.Addr, target.Name);
    }

    /// <summary>打开单位事件弹窗：标题 = 单位名 0x地址，数据 = 该单位是来源/触发的事件快照。</summary>
    private void OpenUnitEventsForm(uint addr, string name)
    {
        string title = $"{name} 0x{addr:X8}";
        var snapshot = _engine.HookEvents;
        // titleOf：弹窗里的「触发单位 / 伤害来源」表头搜索也支持英雄称谓（与主页同一个谓词）。
        var form = new UnitEventsForm(
            title, addr, snapshot, () => _engine.HookEvents, _owner.PlayerText, TitleOf,
            _engine.IsAttrIllusion,
            (code, mirror) => UnitIdentityFromBattlefield(code, mirror));
        form.Show(this);
        SetStatus($"已打开 {title} 的事件弹窗（{snapshot.Count(e => e.Source == addr || e.Victim == addr)} 条相关事件）");
    }

    /// <summary>
    /// 表头搜索用的“单位地址（+ 类型码）→ 英雄称谓”，取不到返回空串。
    /// 称谓索引由 MonitorEngine 维护（ddh v12 属性响应的 Title）；表格**没有称谓列**，
    /// 称谓与单位名称合并显示，并继续参与表头搜索。
    /// 带类型码是为了防地址复用：地址被别的单位占用后，那一行/那条事件不会命中旧称谓。
    /// </summary>
    private string TitleOf(uint addr, string? typeCode)
    {
        if (_unitAttr.TryGetValue(addr, out var byAddr) && byAddr.HasTitle) return byAddr.TitleText;
        if (!string.IsNullOrEmpty(typeCode) &&
            _typeAttr.TryGetValue(typeCode, out var byType) && byType.HasTitle)
            return byType.TitleText;
        return _engine.TryGetTitle(addr, typeCode, out string title) ? title : "";
    }

    /// <summary>单位身份唯一键：当前会话 + 类型码 + 是否镜像。</summary>
    private string TypeMirrorKey(string code, bool illusion) =>
        CurrentUnitIdentitySessionKey() + "|" + code + "|" + (illusion ? "I" : "0");

    /// <summary>
    /// 游戏退出后 Game 会变为空，但界面仍保留上一局伤害事件和身份缓存。
    /// 此时必须继续使用关闭前的 session_id，不能把匹配键切换成空会话。
    /// </summary>
    private string CurrentUnitIdentitySessionKey() =>
        UnitIdentitySessionKey(CurrentUnitSessionKey(), _unitSessionKey);

    internal static string UnitIdentitySessionKey(string? liveSessionId, string? cachedSessionId) =>
        !string.IsNullOrWhiteSpace(liveSessionId) ? liveSessionId : (cachedSessionId ?? "");

    /// <summary>按“类型码 + 是否镜像”到战场单位属性中匹配名称和称谓。</summary>
    private HookGridUi.UnitIdentity UnitIdentityFromBattlefield(string? typeCode, bool illusion)
    {
        if (string.IsNullOrEmpty(typeCode)) return HookGridUi.Unknown;
        if (!_typeIllusionAttr.TryGetValue(TypeMirrorKey(typeCode, illusion), out var attr))
            return HookGridUi.Unknown;
        return new HookGridUi.UnitIdentity(
            attr.HasName ? attr.NameText : "",
            attr.HasTitle ? attr.TitleText : "",
            attr.OwnerSlot);
    }

    private HookGridUi.UnitIdentity UnitIdentityFor(uint addr, string? typeCode) =>
        UnitIdentityFromBattlefield(typeCode, _engine.IsAttrIllusion(addr, typeCode ?? ""));

    /// <summary>
    /// 【伤害事件】表右键菜单：只在「触发单位 / 伤害来源」两列显示【跟踪】。
    /// 跟踪 = 把该单元格对应的**单位名**写进这一列的表头搜索框，并让搜索框钉在表头（不抢焦点）：
    /// 过滤立即生效，之后新伤害事件仍按同一关键词实时刷新（RefreshUi 用 IsTracking 放行）。
    /// </summary>
    private void BuildHookMenu()
    {
        _hookTrackItem.Click += (_, _) => TrackSelectedHookEvent();
        _hookMenu.Items.Add(_hookTrackItem);
        _hookMenu.Opening += (_, e) =>
        {
            bool ok = _hookTrackEvent != null && HookGridUi.IsTrackColumn(_hookTrackColumn);
            _hookTrackItem.Enabled = ok;
            // 关键：把目标存进菜单项 Tag。WinForms 的 Closed 可能先于 Click 触发，
            // 不能依赖字段在点击时还活着（否则“点了跟踪但没反应”）。
            _hookTrackItem.Tag = ok ? new HookTrackTarget(_hookTrackEvent!, _hookTrackColumn) : null;
            e.Cancel = !ok;   // 其它列右键不弹菜单（需求只要触发单位/伤害来源）
        };
        _gridHook.CellMouseDown += (_, e) =>
        {
            _hookTrackEvent = null;
            _hookTrackColumn = "";
            _hookTrackItem.Tag = null;
            if (e.Button != MouseButtons.Right || e.RowIndex < 0 || e.ColumnIndex < 0 ||
                e.RowIndex >= _gridHook.Rows.Count || e.ColumnIndex >= _gridHook.Columns.Count)
                return;

            string column = _gridHook.Columns[e.ColumnIndex].Name;
            if (!HookGridUi.IsTrackColumn(column)) return;
            if (_gridHook.Rows[e.RowIndex].Tag is not DamageHook.HookEvent ev) return;

            _hookTrackEvent = ev;
            _hookTrackColumn = column;
            // 右键也把这一行选上，菜单操作的东西和用户看到的一致。
            _gridHook.ClearSelection();
            _gridHook.Rows[e.RowIndex].Selected = true;
            _gridHook.CurrentCell = _gridHook.Rows[e.RowIndex].Cells[e.ColumnIndex];
        };
        _gridHook.ContextMenuStrip = _hookMenu;
    }

    /// <summary>执行右键【跟踪】：单位名 → 对应列的表头搜索框 → 立即过滤并实时刷新。</summary>
    private void TrackSelectedHookEvent()
    {
        if (_hookTrackItem.Tag is not HookTrackTarget target) return;
        DamageHook.HookEvent ev = target.Event;
        bool victim = string.Equals(target.Column, HookGridUi.VictimColumn, StringComparison.Ordinal);
        bool victimPlayer = string.Equals(target.Column, HookGridUi.VictimPlayerColumn, StringComparison.Ordinal);
        bool source = string.Equals(target.Column, HookGridUi.SourceColumn, StringComparison.Ordinal);
        bool sourcePlayer = string.Equals(target.Column, HookGridUi.SourcePlayerColumn, StringComparison.Ordinal);
        if (!victim && !source && !victimPlayer && !sourcePlayer) return;
        _hookTrackItem.Tag = null;   // 一次点击只执行一次

        string name = HookGridUi.TrackName(ev, target.Column);
        string side = victimPlayer ? "触发单位玩家" : sourcePlayer ? "伤害来源玩家" : victim ? "触发单位" : "伤害来源";
        if (name.Length == 0)
        {
            SetStatusRed($"这个{side}没有可用的单位名，无法跟踪");
            return;
        }

        // 跟踪要看最新事件：回到第一页，再把关键词写进对应的表头搜索框。
        _hookPage = 0;
        bool pinned = _hookSearch.Track(target.Column, name);
        UpdateHookGrid();   // 关键词本来就相同（重复跟踪同一单位）时 Track 不会回调，这里补一次刷页
        SetStatus(pinned
            ? $"正在跟踪{side}「{name}」：新伤害事件实时刷新（点表头上的搜索框可修改关键词）"
            : $"已按{side}「{name}」筛选；搜索框当前不在可视区，横向滚动到该列即可看到");
        Log.Write($"伤害事件跟踪：{side}「{name}」← {ev.VictimText} 0x{ev.Victim:X8} / {ev.SourceText} 0x{ev.Source:X8}" +
                  $"（第 {ev.Seq} 条事件，搜索框钉住={pinned}）");
    }

    /// <summary>右键查看详情：表格显示单位属性（血量 / 攻击力 / 攻击间隔 / 护甲 / 技能），不再弹整页文字。</summary>
    private void BuildSettleMenu()
    {
        var mi = new ToolStripMenuItem("查看详情（单位属性）");
        mi.Click += (_, _) => ShowSelectedDetail();
        _settleMenu.Items.Add(mi);
        _gridSettle.CellMouseDown += (_, e) =>
        {
            if (e.Button == MouseButtons.Right && e.RowIndex >= 0 && e.RowIndex < _gridSettle.Rows.Count)
            {
                _gridSettle.ClearSelection();
                _gridSettle.Rows[e.RowIndex].Selected = true;
                _gridSettle.CurrentCell = _gridSettle.Rows[e.RowIndex].Cells[Math.Max(0, e.ColumnIndex)];
            }
        };
        _gridSettle.ContextMenuStrip = _settleMenu;
    }

    /// <summary>把当前选中行弹成单位属性表（结算行看死前快照，存活行看实时快照 + 本局钩子事件实测值）。</summary>
    private void ShowSelectedDetail()
    {
        object? tag = SelectedTag();
        if (tag is Settlement s)
        {
            var rows = UnitStats.ForSettlement(s, _engine.HookEvents);
            new UnitStatsForm($"{s.DisplayName} 0x{s.Addr:X8}（{s.Kind}结算｜单位属性）", rows).Show(this);
        }
        else if (tag is LiveUnitRow lr)
        {
            var now = DateTime.Now;
            var rows = UnitStats.ForLive(lr.Unit, _engine.HookEvents);
            string name = lr.Unit.Name.Length > 0 ? lr.Unit.Name : lr.Unit.TypeCode;
            new UnitStatsForm($"{name} 0x{lr.Unit.Addr:X8}（单位属性｜快照 {now:HH:mm:ss}）", rows).Show(this);
        }
    }

    /// <summary>用户单击（切换选中）时：下方分组统计回顶、强制重画。</summary>
    private void OnSettleSelectionChanged()
    {
        if (_restoringSelection) return;   // 程序化恢复选中不算“用户切换”，别抢滚动条
        _breakScrollTop = true;
        _breakSig = "";
        UpdateBreakdown();
    }

    /// <summary>当前在【死亡结算】里选中的那一行的 Tag（没有选中返回 null）。</summary>
    private object? SelectedTag()
    {
        if (_gridSettle.SelectedRows.Count > 0) return _gridSettle.SelectedRows[0].Tag;
        return null;
    }

    /// <summary>
    /// 【死亡结算】下方“分组统计”：只显示当前选中的那一行（单选）。
    ///   * 结算行（Tag=Settlement）：HookSources（Σ 来源行）+ HookCombos（组合行）；
    ///     两者都没有就提示“这条结算没有伤害分组数据”。
    ///   * 存活行（Tag=LiveUnitRow）：把 hook 事件里 Victim == 该单位地址 的事件聚合（来源 + 组合），
    ///     每次刷新都重算（存活单位数据在变）；没事件提示“这个单位还没有伤害事件”。
    ///   * 未选中：只剩一行提示“选中上面任意一行查看它的伤害分组”。
    /// 切换选中时滚动条回顶（新数据的开始）；普通刷新（存活行数据变化）用 PreserveScroll 保位置。
    /// </summary>
    private void UpdateBreakdown()
    {
        object? tag = SelectedTag();

        List<(object[] Cells, Color Color)> rows;
        string message;
        string sig;

        if (tag is Settlement s)
        {
            sig = "S:" + s.Addr.ToString("X8") + ":" + s.InstanceIndex + ":" + s.DiedAt.Ticks +
                  ":" + (s.HookSources?.Count ?? 0) + ":" + (s.HookCombos?.Count ?? 0);
            rows = BuildSettlementRows(s, out message);
        }
        else if (tag is LiveUnitRow lr)
        {
            var evs = _engine.HookEvents.Where(e => e.Victim == lr.Unit.Addr).ToList();
            sig = "L:" + lr.Unit.Addr.ToString("X8") + ":" + lr.Unit.InstanceIndex + ":" +
                  evs.Count + ":" + evs.Sum(e => (double)e.Amount).ToString("0.##");
            string unit = lr.Unit.Name.Length > 0 ? lr.Unit.Name : lr.Unit.TypeCode;
            rows = BuildHookRows(unit, evs, out message);
        }
        else
        {
            sig = "NONE";
            rows = new List<(object[], Color)>();
            message = "选中上面任意一行查看它的伤害分组";
        }

        // 内容没变、又不是刚切换选中 → 跳过（避免每 200ms 空转整表重建）
        if (!_breakScrollTop && sig == _breakSig) return;
        _breakSig = sig;
        bool scrollTop = _breakScrollTop;
        _breakScrollTop = false;

        PreserveScroll(_gridBreak, () =>
        {
            // 分组表行数不多，但同样受 Fill 列 + 逐行 Add 的 O(n²) 影响；
            // 统一下沉到 BulkFill（首点/切换选中时不再逐行重算列宽）。
            var cellsList = new List<object[]>(rows.Count + 1);
            var colors = new List<Color>(rows.Count + 1);
            if (rows.Count > 0)
            {
                foreach (var (cells, color) in rows)
                {
                    cellsList.Add(cells);
                    colors.Add(color);
                }
            }
            else
            {
                cellsList.Add(new object[] { message, "", "", "", "", "", "", "", "", "", "", "" });
                colors.Add(default);
            }

            BulkFill(_gridBreak, cellsList.Count, i => cellsList[i], (row, i) =>
            {
                if (colors[i] != default) row.DefaultCellStyle.ForeColor = colors[i];
            });
        });

        // 切换选中 → 回顶（新数据的开始）
        if (scrollTop && _gridBreak.Rows.Count > 0)
        {
            try { _gridBreak.FirstDisplayedScrollingRowIndex = 0; }
            catch { }
        }
    }

    /// <summary>结算行的分组行：Σ 来源 + 组合；没有钩子数据返回空 + 提示（渲染与历史窗口共用）。</summary>
    private List<(object[] Cells, Color Color)> BuildSettlementRows(Settlement s, out string message)
    {
        var unitIdentity = UnitIdentityFor(s.Addr, s.TypeCode);
        string unit = Wc3Text.UnitIdentity(
            unitIdentity.Name is { Length: > 0 } ? unitIdentity.Name : s.UnitName,
            unitIdentity.Title, s.TypeCode);

        static string StripMirror(string source) =>
            source.Replace("（镜像）", "", StringComparison.Ordinal)
                  .Replace("(镜像)", "", StringComparison.Ordinal);

        string SourceIdentity(uint addr, string code, string fallback)
        {
            string cleanFallback = StripMirror(fallback);
            bool mirror = _engine.IsAttrIllusion(addr, code);
            var matched = UnitIdentityFromBattlefield(code, mirror);
            string name = matched.Name;
            if (name.Length == 0) name = cleanFallback;
            if (cleanFallback.Contains('\n') && name.Length == 0) return cleanFallback;
            string identity = Wc3Text.UnitIdentity(name, matched.Title, code);
            return identity;
        }

        /* 早期结算可能在镜像位到达前就把本体/镜像合并了，事后只改字符串无法拆组。
           这里按当前镜像索引重新匹配原始事件并重新分组。 */
        var from = MonitorEngine.HookGroupingStart(s.SyntheticHookDeath, s.FirstSeen, s.DiedAt);
        var to = s.DiedAt.AddSeconds(2);
        var match = HookMatcher.Select(_engine.HookEvents, s.Addr, s.TypeCode, from, to);
        double scale = s.HookDamageScale > 0 ? s.HookDamageScale : 1.0;

        List<HookBreakdown.SourceRow>? sources = null;
        List<HookBreakdown.Combination>? combos = null;
        if (match.Events.Count > 0)
        {
            sources = HookBreakdown.Sources(match.Events, scale, 20,
                                             _engine.IsAttrIllusion,
                                             e => SourceIdentity(e.Source, e.SourceCode, e.SourceText));
            combos = HookBreakdown.Combinations(match.Events, null, scale, 40,
                                                 _engine.IsAttrIllusion,
                                                 e => SourceIdentity(e.Source, e.SourceCode, e.SourceText));
        }

        sources ??= s.HookSources?.Select(sr =>
        {
            string label = SourceIdentity(sr.SourceAddr, sr.SourceCode, sr.Source);
            label = SettlementGridUi.AppendMirrorSuffix(
                label, _engine.IsAttrIllusion(sr.SourceAddr, sr.SourceCode));
            return sr with { Source = label };
        }).ToList();
        combos ??= s.HookCombos?.Select(cb =>
        {
            string label = SourceIdentity(cb.SourceAddr, cb.SourceCode, cb.Source);
            label = SettlementGridUi.AppendMirrorSuffix(
                label, _engine.IsAttrIllusion(cb.SourceAddr, cb.SourceCode));
            return cb with { Source = label };
        }).ToList();
        return SettlementGridUi.BreakdownRows(unit, sources, combos, out message);
    }

    /// <summary>把一批 hook 事件聚合成分组行（Σ 来源 + 组合），事件为空返回空 + 提示。</summary>
    private List<(object[] Cells, Color Color)> BuildHookRows(string unit, IReadOnlyList<DamageHook.HookEvent> evs, out string message)
    {
        message = "";
        var rows = new List<(object[], Color)>();
        if (evs == null || evs.Count == 0)
        {
            message = "这个单位还没有伤害事件";
            return rows;
        }

        string SourceLabelOf(DamageHook.HookEvent e)
        {
            bool mirror = _engine.IsAttrIllusion(e.Source, e.SourceCode);
            var matched = UnitIdentityFromBattlefield(e.SourceCode, mirror);
            string name = matched.Name;
            if (name.Length == 0) name = e.SourceName.Length > 0 ? e.SourceName : e.SourceCode;
            string title = matched.Title;
            return Wc3Text.UnitIdentity(name, title, e.SourceCode);
        }

        foreach (var sr in HookBreakdown.Sources(evs, 1.0, 20, _engine.IsAttrIllusion, SourceLabelOf))
        {
            rows.Add((new object[]
            {
                unit, "Σ " + sr.Source, "汇总", "", "", "",
                sr.Count, sr.Damage.ToString("0.00"),
                sr.EngineValid ? sr.Engine.ToString("0.00") : "",
                sr.EffectiveValid ? sr.Effective.ToString("0.00") : "",
                sr.NetValid ? sr.NetDrop.ToString("0.00") : "",
                sr.Percent.ToString("0.0") + "%"
            }, Color.Gold));
        }

        foreach (var cb in HookBreakdown.Combinations(evs, null, 1.0, 40,
                                                       _engine.IsAttrIllusion, SourceLabelOf))
        {
            rows.Add((new object[]
            {
                unit, cb.Source, cb.IsAttack, cb.IsRanged, cb.AttackType, cb.DamageType,
                cb.Count, cb.Damage.ToString("0.00"),
                cb.EngineValid ? cb.Engine.ToString("0.00") : "",
                cb.EffectiveValid ? cb.Effective.ToString("0.00") : "",
                cb.NetValid ? cb.NetDrop.ToString("0.00") : "",
                cb.Percent.ToString("0.0") + "%"
            }, Color.LightGreen));
        }

        return rows;
    }

    // ==================================================================
    // 【战场单位】页（ddh v12 属性请求 / 响应）
    // ==================================================================

    /// <summary>表头搜索应用 / 清除后立即整表重建（只重建，不再多发一轮请求）。</summary>
    private void ApplyUnitsFilterNow() => UpdateUnitsPage(request: false);

    /// <summary>
    /// 【战场单位】页刷新（约 1 秒一次，读取完整单位属性）：
    ///   ① 用轮询游标从**全部存活单位**里连续取 96 个地址（循环；存活/最近受击只在批内排序），
    ///      保证 N 轮内每个单位都被请求过 —— 旧版只取“存活+最近受击”前 64 个，后面的永远 ?；
    ///   ② 把 ddh 上一轮**已完成**的响应收进缓存（ddh 在游戏线程解析完才写 doneSeq，所以慢一拍）；
    ///   ③ 用快照 + 缓存生成行：条数没变就地更新，否则按“地址”锚定整表重建；
    ///      有表头过滤时一律整表重建（保留锚点）。
    /// 每 30 秒写一行“属性请求：本轮 96 个，累计已覆盖 N/M 个单位”，便于确认轮询真的在推进。
    /// 拿不到属性（没有 ddh / 老版本 ddh / 地图没有 JAPI）时属性列显示 ?，不崩。
    /// </summary>
    /// <summary>
    /// 后台单位属性轮询：即使没打开【战场单位】页，也定期把单位地址送 ddh，
    /// 让名称、称谓和战斗属性进入当前快照及历史快照。
    /// </summary>
    private void RefreshAttrsFromDdhDb()
    {
        if (_engine.Game == null) return;
        var dbUnits = DdhEventDb.ReadUnits(_engine.Game.SessionId);
        _engine.RememberAttrLocusts(dbUnits);
        _engine.RememberAttrTitles(dbUnits);
        bool identityChanged = false;
        foreach (var r in dbUnits)
        {
            if (!_unitAttr.TryGetValue(r.Addr, out var old) ||
                !string.Equals(old.NameText, r.NameText, StringComparison.Ordinal) ||
                !string.Equals(old.TitleText, r.TitleText, StringComparison.Ordinal))
                identityChanged = true;
            /* SQLite 是桌面端的实时属性源。地址已存在时也必须覆盖：
               攻击速度等状态会随地图 Buff/成长变化，跳过旧地址会把第一次读到的值永久冻住。 */
            _unitAttr[r.Addr] = r;
            if (r.HasTypeCode && r.TypeCode.Length > 0)
            {
                _typeAttr[r.TypeCode] = r;
                _typeIllusionAttr[TypeMirrorKey(r.TypeCode, r.IsIllusion)] = r;
            }
        }
        if (identityChanged) _attrIdentityVersion++;
    }

    private void PumpUnitClassification()
    {
        if (!BattlefieldUnitsEnabled) return;
        try
        {
            if (_engine.Game == null) return;
            /* 即使扫描器暂时看不到任何单位，也要先读 SQLite：
               刚死亡/已消失单位的名称和称谓仍属于当前结算。 */
            RefreshAttrsFromDdhDb();

            var snap = _engine.Current;
            var probe = snap.RawUnits.Count > 0 ? snap.RawUnits : snap.Units;
            if (probe.Count == 0) return;

            var got = _engine.PollUnitAttrs();
            foreach (var r in got)
            {
                _unitAttr[r.Addr] = r;
                if (r.HasTypeCode && r.TypeCode.Length > 0)
                {
                    _typeAttr[r.TypeCode] = r;
                    _typeIllusionAttr[TypeMirrorKey(r.TypeCode, r.IsIllusion)] = r;
                }
            }
            _unitPoll.MarkAnswered(got);

            var want = new List<uint>();
            var addrs = probe.Select(u => u.Addr).Distinct().ToList();
            if (addrs.Count > 0)
            {
                _classifyCursor %= addrs.Count;
                int take = Math.Min(UnitAttrWire.SlotCount, addrs.Count);
                want = new List<uint>(take);
                for (int i = 0; i < take; ++i) want.Add(addrs[(_classifyCursor + i) % addrs.Count]);
                _classifyCursor = (_classifyCursor + take) % addrs.Count;
            }
            var wantAddrs = want;
            if (wantAddrs.Count > 0 && _engine.RequestUnitAttrs(wantAddrs)) _unitPoll.MarkRequested(wantAddrs);
        }
        catch (Exception ex) { Log.Warn("后台分类轮询失败：" + ex.Message); }
    }

    /// <summary>
    /// 换进程 / 同进程换图时，把【战场单位】页的会话状态整体作废：
    /// 表格行、地址/类型码属性缓存、轮询覆盖统计全部清掉（地址会复用，旧属性不能串到新单位），
    /// 并短暂屏蔽重填，等引擎扫描出新局数据。
    /// <para>
    /// 调用时机与死亡结算/伤害明细一致：引擎在连接新局（ClearHistoryCore）已经清空账本与事件，
    /// 界面这里在同一个节拍把“上一局的显示残留”清掉；退出游戏不调用（保留上一局供查看）。
    /// </para>
    /// </summary>
    private void ResetUnitsForNewSession()
    {
        if (!BattlefieldUnitsEnabled) return;
        if (_gridUnits.Rows.Count > 0) _gridUnits.Rows.Clear();
        _unitAttr.Clear();
        _typeAttr.Clear();
        _typeIllusionAttr.Clear();
        _attrIdentityVersion++;
        _unitPoll.Reset();
        _classifyCursor = 0;
        _unitsSuppressUntil = DateTime.Now.AddSeconds(2);
    }

    /// <summary>
    /// 战场单位缓存唯一使用游戏状态会话键；不能用 PID/MapGeneration 另算一套，
    /// 否则两个刷新入口会互相判成“新会话”，反复清表。
    /// </summary>
    private string CurrentUnitSessionKey() => _engine.Game?.SessionId ?? "";

    private void UpdateUnitsPage(bool request = true)
    {
        if (!BattlefieldUnitsEnabled) return;
        var snap = _engine.Current;
        var units = snap.Units;
        /* 页面可见时走本方法而不是后台 Pump；DB 模式必须在这里也刷新，
           否则 SQLite 中变化的攻击速度永远进不了界面。 */
        RefreshAttrsFromDdhDb();
        // 属性轮询用“未合并”的原始实例列表：同类型的每个地址都能被探到，
        // 否则只探代表实例，代表句柄解析失败时整类都学不到 Aloc/属性。
        var probeUnits = snap.RawUnits.Count > 0 ? snap.RawUnits : units;
        // 存活单位 + 所有还没有属性缓存的死亡单位（不设时间上限：死了多久都继续补请求）。
        // ddh 对尸体有时还能拿到句柄，内存直读字段更是完全不依赖句柄；能补一点是一点。
        // 存活单位排在前面，尸体排在后面，避免尸体占满 96 个请求槽把活单位饿死。
        var requestable = probeUnits
            .Where(u => u.Hp > 0f || !_unitAttr.ContainsKey(u.Addr) || !_unitAttr[u.Addr].LocustChecked)
            .OrderBy(u => u.Hp > 0f ? 0 : 1)
            .ToList();
        // 需求：战场单位“不要删”——死亡/消失的单位仍然留在表里（属性列显示 ?），排到存活单位后面；
        // 这样一局打完还能回看全场单位，也便于把名单存进历史。
        // v1.3.3：中立玩家(12~15)不显示；其余按 盟友 → 敌人 → 名称 排序（本地玩家/ini ally_slots 判定）。
        int localPid = _engine.LocalPlayerIndex;
        var allySlots = _settings.AllySlotSet();
        uint allyMask = _engine.AllyMask;   // ddh v21：真实结盟掩码（0 = 老 DLL，退回本地玩家 + ally_slots）
        /* 镜像位是实例级的：属性响应或引擎快照任一确认过都算，不能因为缓存里旧响应没有该位就退回原单位。 */
        bool IllusionOf(UnitView u) =>
            u.IsIllusion || (_unitAttr.TryGetValue(u.Addr, out var a) && a.IsIllusion);
        bool LocustOf(UnitView u) =>
            (_unitAttr.TryGetValue(u.Addr, out var a) && a.IsLocust) ||
            _engine.IsAttrLocust(u.Addr, u.TypeCode);
        var illusionCodes = new HashSet<string>(
            units.Where(u => IllusionOf(u)).Select(u => u.TypeCode),
            StringComparer.OrdinalIgnoreCase);
        foreach (var attr in _unitAttr.Values)
            if (attr.IsIllusion && attr.HasTypeCode) illusionCodes.Add(attr.TypeCode);
        var displayed = UnitGridUi.SortForFaction(units, localPid, allySlots, allyMask)
            .Where(u => UnitGridUi.ShouldDisplay(
                LocustOf(u), IllusionOf(u), illusionCodes.Contains(u.TypeCode)))
            .GroupBy(u => u.TypeCode + "|" + (IllusionOf(u) ? "I" : "0"))
            .Select(g => g.First())
            .ToList();
        /* 扫描器可能没把镜像/幻象算进单位表；ddh game_units 里有、扫描器没有的地址补成行。
           game_units 只会收录本局伤害事件的 victim/source，本身已经是“参战单位”，
           不能再依赖实时快照的 DamageUnitAddrs（扫描链异常时会把整页误过滤为空）。 */
        if (_unitAttr.Count > 0)
        {
            var have = new HashSet<uint>(displayed.Select(u => u.Addr));
            foreach (var kv in _unitAttr)
            {
                if (have.Contains(kv.Key)) continue;
                var a = kv.Value;
                string code = a.HasTypeCode ? a.TypeCode : "";
                if (!UnitGridUi.ShouldDisplay(
                        a.IsLocust, a.IsIllusion, illusionCodes.Contains(code))) continue;
                displayed.Add(UnitGridUi.UnitFromDdhDb(kv.Key, a));
            }
        }

        /* 补入 units 行后再按“镜像位 + 类型码”收一次，避免同一类型镜像按地址重复。 */
        displayed = displayed
            .GroupBy(u => u.TypeCode + "|" + (IllusionOf(u) ? "I" : "0"))
            .Select(g => g.First())
            .ToList();

        // 换进程/重连/换图：地址会复用，属性缓存与轮询覆盖统计整体作废。
        // 正常路径由 RefreshUi 在换局那一拍统一清（不清就等用户切页才清，时机与结算/明细不一致）；
        // 这里保留兜底：切页/表头搜索可能比界面节拍先到。
        string session = CurrentUnitSessionKey();
        if (session.Length > 0 && !string.Equals(session, _unitSessionKey, StringComparison.Ordinal))
        {
            _unitSessionKey = session;
            ResetUnitsForNewSession();
        }

        if (DateTime.Now < _unitsSuppressUntil) return;   // 刚换局：先别用旧快照重填

        // ① 先收上一轮响应（ddh 在游戏线程解析完才写 doneSeq，天然慢一拍）。
        // 必须先收再发：否则每轮先写新 requestSeq，上一轮的 doneSeq 永远比它小 1，
        // 会被误判成“没完成”而丢掉 —— 这正是真机界面整列 ? 的原因。
        var got = _engine.PollUnitAttrs();
        foreach (var r in got)
        {
            _unitAttr[r.Addr] = r;
            if (r.HasTypeCode && r.TypeCode.Length > 0)
            {
                _typeAttr[r.TypeCode] = r;
                _typeIllusionAttr[TypeMirrorKey(r.TypeCode, r.IsIllusion)] = r;
            }
        }
        _unitPoll.MarkAnswered(got);

        // ② 再发下一轮请求（96 个槽；只轮询存活单位，不是只发给最活跃的前 96 个）。
        // RequestUnitAttrs 内部会拒绝覆盖“上一轮还没消费”的请求；只有真写进去才记覆盖。
        if (request)
        {
            var want = _unitPoll.PickRound(requestable, UnitAttrWire.SlotCount);
            if (want.Count > 0 && _engine.RequestUnitAttrs(want)) _unitPoll.MarkRequested(want);
            // 还没连上/场上没单位时不要先写一条 0/0 占掉首行；等到真有单位再开始 30 秒计时。
            if (requestable.Count > 0 && _unitPoll.ShouldLog(Environment.TickCount64, requestable.Count))
                Log.Write(_unitPoll.CoverageLine(requestable));
        }

        // 死亡单位保留已经抓到的属性（表格和历史还要显示）；只有地址从快照消失、
        // 或同地址换成了另一个类型码（地址复用）时才丢弃缓存。
        if (_unitAttr.Count > 0)
        {
            var byAddr = new Dictionary<uint, string>(probeUnits.Count);
            foreach (var u in probeUnits) byAddr[u.Addr] = u.TypeCode;
            foreach (var addr in _unitAttr.Keys.ToList())
            {
                if (!byAddr.TryGetValue(addr, out string? code)) continue;   // 扫描器暂时看不到：保留 ddh units 行，避免镜像闪没
                var cached = _unitAttr[addr];
                if (cached.HasTypeCode && code.Length > 0 &&
                    !string.Equals(cached.TypeCode, code, StringComparison.OrdinalIgnoreCase))
                    _unitAttr.Remove(addr);   // 地址被新单位复用
            }
        }

        // ③ 生成行（顺序 = 存活/最近受击优先，死亡单位排在后面且仍保留）
        var rows = new List<UnitGridUi.Row>(displayed.Count);
        foreach (var u in displayed)
        {
            if (!u.Participated) continue;
            // 死亡单位的属性已从缓存清掉（避免地址复用串味），这里只保留名字/类型码/拥有者/地址。
            _unitAttr.TryGetValue(u.Addr, out var attr);
            bool addrAttr = attr != null;
            if (attr == null && u.TypeCode.Length > 0) _typeAttr.TryGetValue(u.TypeCode, out attr);
            /* 类型码兜底只借属性，不能把某个镜像实例的 illusion 位串给同类型原单位。 */
            if (attr != null && !addrAttr)
                attr = attr with { Flags = attr.Flags & ~UnitAttrWire.FlagIllusion };

            bool isIllusion = u.IsIllusion || attr?.IsIllusion == true;
            string rowCode = attr != null && attr.HasTypeCode ? attr.TypeCode : u.TypeCode;
            bool isLocust = attr?.IsLocust == true ||
                            _engine.IsAttrLocust(u.Addr, rowCode);
            if (!UnitGridUi.ShouldDisplay(
                    isLocust, isIllusion, illusionCodes.Contains(rowCode))) continue;
            var row = UnitGridUi.Build(u, attr, _owner.PlayerText, localPid, allySlots, allyMask,
                                       isIllusion);
            rows.Add(row);
        }

        bool filtering = _unitsSearch.HasFilter;
        string codeKeyword = _unitsSearch.Keyword(UnitGridUi.CodeColumn);
        string nameKeyword = _unitsSearch.Keyword(UnitGridUi.NameColumn);
        var shown = filtering
            ? rows.Where(r => UnitGridUi.MatchesSearch(r, codeKeyword, nameKeyword)).ToList()
            : rows;

        if (!filtering && shown.Count == _gridUnits.Rows.Count)
        {
            // 条数没变：原地更新（不重建 → 滚动条不动、选中行不丢）
            for (int i = 0; i < shown.Count; i++)
            {
                _gridUnits.Rows[i].SetValues(shown[i].Cells());
                _gridUnits.Rows[i].Tag = shown[i];
                _gridUnits.Rows[i].DefaultCellStyle.ForeColor = shown[i].Faction == UnitGridUi.Ally
                    ? Color.FromArgb(150, 220, 150)
                    : Color.Gainsboro;
            }
        }
        else
        {
            // 条数变了 / 正在过滤：整表重建，按单位地址把用户正在看的那一行停在原处。
            // 13 列 × 上百个单位，逐行 Add + Fill 列同样会 O(n²)，用 BulkFill 一次建完。
            PreserveViewAnchor(_gridUnits, r => r.Tag is UnitGridUi.Row u ? AnchorKeys.ForUnit(u.Addr) : "", () =>
            {
                BulkFill(_gridUnits, shown.Count, i => shown[i].Cells(), (row, i) =>
                {
                    row.Tag = shown[i];
                    // 盟友行淡绿色，敌人保持默认色（中立已在排序时剔除）。
                    if (shown[i].Faction == UnitGridUi.Ally)
                        row.DefaultCellStyle.ForeColor = Color.FromArgb(150, 220, 150);
                    else
                        row.DefaultCellStyle.ForeColor = Color.Gainsboro;
                });
            });
        }
    }

    /// <summary>
    /// 【战场单位】名称列两行自绘：
    ///   英雄 —— 第一行称谓（小一号字、金色，与名称颜色不同），第二行单位名；
    ///   非英雄 —— 只有单位名，整格垂直居中。
    /// 背景/边框仍走系统绘制（选中行的高亮不变），只替换文字部分。
    /// </summary>
    private void OnUnitCellPainting(object? sender, DataGridViewCellPaintingEventArgs e)
    {
        if (e.RowIndex < 0 || e.ColumnIndex < 0 || e.Graphics == null) return;
        if (_gridUnits.Columns[e.ColumnIndex].Name != UnitGridUi.NameColumn) return;
        if (e.RowIndex >= _gridUnits.Rows.Count) return;
        if (_gridUnits.Rows[e.RowIndex].Tag is not UnitGridUi.Row row) return;

        e.PaintBackground(e.ClipBounds, true);
        e.Paint(e.ClipBounds, DataGridViewPaintParts.Border);

        bool selected = (e.State & DataGridViewElementStates.Selected) != 0;
        Color nameColor = selected ? Color.White : Color.FromArgb(226, 226, 226);
        Color titleColor = selected ? Color.FromArgb(255, 226, 150) : UnitTitleColor;
        const TextFormatFlags flags = TextFormatFlags.NoPrefix | TextFormatFlags.EndEllipsis |
                                      TextFormatFlags.VerticalCenter | TextFormatFlags.Left;
        var area = new Rectangle(e.CellBounds.X + 4, e.CellBounds.Y + 2,
                                 Math.Max(1, e.CellBounds.Width - 8), Math.Max(1, e.CellBounds.Height - 4));

        if (row.HasTitle)
        {
            int titleH = UnitTitleFont.Height;
            int nameH = UnitNameFont.Height;
            int top = area.Y + Math.Max(0, (area.Height - (titleH + nameH)) / 2);
            TextRenderer.DrawText(e.Graphics, row.Title, UnitTitleFont,
                new Rectangle(area.X, top, area.Width, titleH), titleColor, flags);
            TextRenderer.DrawText(e.Graphics, row.DisplayName, UnitNameFont,
                new Rectangle(area.X, top + titleH, area.Width, nameH), nameColor, flags);
        }
        else
        {
            TextRenderer.DrawText(e.Graphics, row.DisplayName, UnitNameFont, area, nameColor, flags);
        }
        e.Handled = true;
    }

    /// <summary>
    /// 伤害事件表头搜索应用 / 清除关键词后立即整页重建，不等 200ms 定时器。
    /// 同时作废增量状态：过滤期间表里的行是筛过的，下一次刷新必须先重建一次。
    /// </summary>
    private void ApplyHookFilterNow()
    {
        _hookSig = "";
        _hookFilterShown = "";
        _hookPageShown = -1;
        UpdateHookGrid();
    }

    /// <summary>侵入式伤害事件页：分页显示引擎级伤害事件（时间倒序，每页 UnitEvents.PageSize 行）。</summary>
    private void UpdateHookGrid()
    {
        /* 伤害页可能在后台分类轮询之前首次打开。先读一次当前会话的 game_units，
           否则事件里的空名称会先渲染成类型码，要等下一轮属性分类才更新。 */
        if (_engine.Game != null &&
            (DateTime.Now - _lastHookIdentityRefresh).TotalMilliseconds >= 1000)
        {
            _lastHookIdentityRefresh = DateTime.Now;
            RefreshAttrsFromDdhDb();
        }

        // 先拿一份线程安全快照：监视线程会并发往事件集合 AddRange/RemoveRange，
        // 直接 foreach 活列表就会抛 “Collection was modified”（真机崩溃的直接原因）。
        var evs = _engine.HookEvents;

        // 表头搜索（触发单位 / 伤害来源，模糊匹配，两列 AND）与页顶两个下拉（按类型码）叠加：
        // 下拉先挡掉不相关事件，再看表头关键词；分页页数按“过滤后条数”计算。
        bool filtering = _hookSearch.HasFilter;
        string victimKeyword = _hookSearch.Keyword(HookGridUi.VictimColumn);
        string victimPlayerKeyword = _hookSearch.Keyword(HookGridUi.VictimPlayerColumn);
        string sourceKeyword = _hookSearch.Keyword(HookGridUi.SourceColumn);
        string sourcePlayerKeyword = _hookSearch.Keyword(HookGridUi.SourcePlayerColumn);
        var filtered = new List<DamageHook.HookEvent>();
        foreach (var e in evs)
        {
            if (_filterSource.Length > 0 && !string.Equals(e.SourceCode, _filterSource, StringComparison.OrdinalIgnoreCase)) continue;
            if (_filterVictim.Length > 0 && !string.Equals(e.VictimCode, _filterVictim, StringComparison.OrdinalIgnoreCase)) continue;
            // 触发单位 / 伤害来源两列显示“称谓 + 单位名称”，搜索任一项都可命中。
            if (filtering && !HookGridUi.MatchesSearch(
                    e, victimKeyword, victimPlayerKeyword, sourceKeyword, sourcePlayerKeyword, TitleOf,
                    _engine.IsAttrIllusion,
                    (code, mirror) => UnitIdentityFromBattlefield(code, mirror))) continue;
            filtered.Add(e);
        }

        int total = filtered.Count;
        int pageCount = UnitEvents.PageCount(total);
        _hookPage = Math.Clamp(_hookPage, 0, pageCount - 1);
        long newestSeq = filtered.Count > 0 ? filtered[^1].Seq : -1;

        string filterKey = _filterSource + "\u001f" + _filterVictim + "\u001f" + victimKeyword + "\u001f" + victimPlayerKeyword + "\u001f" + sourceKeyword + "\u001f" + sourcePlayerKeyword;
        bool pageOrFilterChanged = _hookPage != _hookPageShown ||
                                   !string.Equals(filterKey, _hookFilterShown, StringComparison.Ordinal);
        // 名称/称谓可能比伤害事件晚到；属性身份变化也必须重建，否则会一直停在类型码。
        string sig = $"{filterKey}|{total}|{newestSeq}|{_hookPage}|{_attrIdentityVersion}";
        if (sig != _hookSig)
        {
            var pageItems = UnitEvents.SlicePage(filtered, _hookPage);

            // 有表头过滤时一律整页重建：筛过的行不再满足“旧页是新页后缀”的增量前提，
            // 重建走 PreserveViewAnchor，滚动位置按行身份保留。
            if (filtering || pageOrFilterChanged || _gridHook.Rows.Count == 0)
            {
                RebuildHookPage(pageItems);
                _hookPageShown = _hookPage;
                _hookFilterShown = filterKey;
            }
            else if (_hookPage != 0)
            {
                // 历史页：只更新页码/总数，不把正在看的那一页整页换掉。
                // （新事件只影响第 0 页的“最新 500 条”窗口；等用户翻页时再重建。）
            }
            else if (!TryPrependHookEvents(pageItems))
            {
                RebuildHookPage(pageItems);
                _hookPageShown = _hookPage;
                _hookFilterShown = filterKey;
            }

            UpdateHookPageBar(total, pageCount);
            _hookSig = sig;
        }

        // 刷新筛选下拉（节流）：条数变了或每 2 秒一次；RefreshHookFilterItems 自己有 _inFilterRefresh 重入保护。
        if (evs.Count != _lastHookFilterCount || (DateTime.Now - _lastHookFilterAt).TotalSeconds >= 2)
        {
            _lastHookFilterCount = evs.Count;
            _lastHookFilterAt = DateTime.Now;
            RefreshHookFilterItems(evs);
        }
    }

    /// <summary>整页重建伤害事件表（换页 / 换筛选 / 首次显示时走这里），按身份锚定视口。</summary>
    private void RebuildHookPage(List<DamageHook.HookEvent> pageItems)
    {
        long selectedSeq = -1;
        if (_gridHook.SelectedRows.Count > 0 && _gridHook.SelectedRows[0].Tag is DamageHook.HookEvent sel)
            selectedSeq = sel.Seq;

        PreserveViewAnchor(_gridHook, r => r.Tag is DamageHook.HookEvent he ? AnchorKeys.ForHook(he) : "", () =>
        {
            // 一页 500 行，逐行 Insert/Add + Fill 列会做 500 次列宽重算（首点卡顿的主因之一），
            // 这里一次性建行再填值。
            BulkFill(_gridHook, pageItems.Count,
                i => HookGridUi.RowCells(pageItems[i], _owner.PlayerText, _engine.IsAttrIllusion,
                                         (code, mirror) => UnitIdentityFromBattlefield(code, mirror)),
                (row, i) =>
                {
                    var he = pageItems[i];
                    row.Tag = he;
                    if (he.Depth > 1) row.DefaultCellStyle.ForeColor = Color.FromArgb(190, 190, 150);
                });
        });

        if (selectedSeq >= 0)
        {
            foreach (DataGridViewRow r in _gridHook.Rows)
                if (r.Tag is DamageHook.HookEvent he && he.Seq == selectedSeq) { r.Selected = true; break; }
        }
    }

    /// <summary>追加/插入一条伤害事件行（index=0 为顶部，index=Rows.Count 为尾部）。</summary>
    private void AddHookRow(int index, DamageHook.HookEvent e)
    {
        _gridHook.Rows.Insert(index, HookGridUi.RowCells(
            e, _owner.PlayerText, _engine.IsAttrIllusion,
            (code, mirror) => UnitIdentityFromBattlefield(code, mirror)));
        var row = _gridHook.Rows[index];
        row.Tag = e;
        if (e.Depth > 1) row.DefaultCellStyle.ForeColor = Color.FromArgb(190, 190, 150);
    }

    /// <summary>
    /// 第 0 页的增量更新：新事件只会从顶部进来，旧页是“新页的一个后缀”。
    /// 只在顶部插新增行、从尾部删掉被挤出本页的行，不 Rows.Clear() —— 行对象和滚动条都不动。
    /// </summary>
    private bool TryPrependHookEvents(List<DamageHook.HookEvent> pageItems)
    {
        // 表头过滤生效时表里的行是筛过的，增量插入的前提不成立 → 一律交给整页重建。
        if (_hookSearch.HasFilter) return false;

        int oldCount = _gridHook.Rows.Count;
        if (oldCount <= 0 || pageItems.Count == 0) return false;

        // 旧的第一行在新页里的位置 = 新增事件数；找不到说明整页都换了。
        long firstSeq = _gridHook.Rows[0].Tag is DamageHook.HookEvent oldFirst ? oldFirst.Seq : -1;
        if (firstSeq < 0) return false;
        int insert = -1;
        for (int i = 0; i < pageItems.Count; i++)
            if (pageItems[i].Seq == firstSeq) { insert = i; break; }
        if (insert < 0) return false;

        int keep = pageItems.Count - insert;
        if (keep <= 0 || keep > oldCount) return false;

        // 旧页的每一行都应该能在新页里按顺序对上
        for (int i = 0; i < keep; i++)
        {
            if (!(_gridHook.Rows[i].Tag is DamageHook.HookEvent old) || old.Seq != pageItems[insert + i].Seq)
                return false;
        }
        int remove = oldCount - keep;
        if (insert == 0 && remove == 0) return true;

        int first = -1, visible = 1;
        long anchorSeq = -1;
        try
        {
            visible = Math.Max(1, _gridHook.DisplayedRowCount(false));
            first = _gridHook.Rows.Count > 0 ? _gridHook.FirstDisplayedScrollingRowIndex : -1;
            // 记住“第一可见行”的身份（事件序号），重建后按它把视口钉回去；
            // 不再用“是否贴底”来决定跟随 —— 否则滚到底后每来一条新事件就往下跳一次。
            if (first >= 0 && first < _gridHook.Rows.Count &&
                _gridHook.Rows[first].Tag is DamageHook.HookEvent anchor)
                anchorSeq = anchor.Seq;
        }
        catch { }

        long selectedSeq = -1;
        if (_gridHook.SelectedRows.Count > 0 && _gridHook.SelectedRows[0].Tag is DamageHook.HookEvent sel)
            selectedSeq = sel.Seq;

        _gridHook.SuspendLayout();
        try
        {
            // 先删被挤出本页的尾部，再从顶部按“最终顺序”反向插入新增行。
            for (int i = 0; i < remove; i++)
                _gridHook.Rows.RemoveAt(_gridHook.Rows.Count - 1);
            for (int i = insert - 1; i >= 0; i--)
                AddHookRow(0, pageItems[i]);
        }
        finally { _gridHook.ResumeLayout(); }

        // 恢复视口：停在最顶部 → 留在顶部看新事件；一旦往下滚过（含滚到底）→ 按第一可见行的
        // 身份钉回去，内容和滚动条都不动。锚点行若被新事件挤出本页尾部，就贴到最后一个仍存在的旧行。
        try
        {
            if (_gridHook.Rows.Count > 0)
            {
                int target = 0;
                if (first > 0)
                {
                    int found = -1;
                    if (anchorSeq >= 0)
                    {
                        for (int i = 0; i < _gridHook.Rows.Count; i++)
                            if (_gridHook.Rows[i].Tag is DamageHook.HookEvent he && he.Seq == anchorSeq) { found = i; break; }
                    }
                    if (found < 0) found = insert + keep - 1;   // 被挤出：贴住最后一个旧行
                    target = Math.Clamp(found, 0, Math.Max(0, _gridHook.Rows.Count - visible));
                }
                _gridHook.FirstDisplayedScrollingRowIndex = target;
            }
        }
        catch { }

        // 选中的行如果刚好被尾部删掉，清掉自动选中，避免莫名其妙跳到别的行。
        if (selectedSeq >= 0)
        {
            bool found = false;
            foreach (DataGridViewRow r in _gridHook.Rows)
                if (r.Tag is DamageHook.HookEvent he && he.Seq == selectedSeq) { r.Selected = true; found = true; break; }
            if (!found) _gridHook.CurrentCell = null;
        }

        _hookPageShown = 0;
        return true;
    }

    private void UpdateHookPageBar(int total, int pageCount)
    {
        _lblHookPage.Text = $"第 {_hookPage + 1} / {pageCount} 页（共 {total} 条）";
        _btnHookFirst.Enabled = _btnHookPrev.Enabled = _hookPage > 0;
        _btnHookNext.Enabled = _btnHookLast.Enabled = _hookPage < pageCount - 1;
    }

    /// <summary>筛选框条目：值仍是类型码（筛选逻辑按码匹配），显示文本是「名字(码)」或「码」。</summary>
    private sealed record HookFilterItem(string Code, string Text)
    {
        public override string ToString() => Text;
    }

    /// <summary>
    /// 把“触发单位 / 伤害来源”出现过的类型码填进筛选框：条目显示 名字(码)（没名字就码），
    /// 值仍是类型码（筛选逻辑不变）；刷新后按码找回当前选中项，不打断筛选。
    /// </summary>
    private void RefreshHookFilterItems(IReadOnlyList<DamageHook.HookEvent> evs)
    {
        if (_inFilterRefresh) return;
        _inFilterRefresh = true;
        try
        {
            // 再快照一份：Refill 内部对 values 做 LINQ 惰性枚举，绝不能边枚举边被改动。
            var snapshot = evs.ToArray();
            Refill(_cmbFilterVictim, snapshot.Select(e => (Code: e.VictimCode, Name: e.VictimName)), _filterVictim);
            Refill(_cmbFilterSource, snapshot.Select(e => (Code: e.SourceCode, Name: e.SourceName)), _filterSource);
        }
        finally { _inFilterRefresh = false; }

        void Refill(ComboBox cmb, IEnumerable<(string Code, string Name)> values, string keep)
        {
            // 按类型码去重；名字优先用事件里带回来的（PumpHook 已把插件日志名字表兜底填进 VictimName/SourceName），
            // 事件里没名字再退回当前插件日志名字表（名字晚于事件到的情况）。
            var byCode = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (var v in values)
            {
                if (string.IsNullOrEmpty(v.Code)) continue;
                string name = v.Name;
                if (name.Length == 0) name = _engine.PluginLog?.NameOf(v.Code) ?? "";
                if (byCode.TryGetValue(v.Code, out var cur))
                {
                    if (cur.Length == 0 && name.Length > 0) byCode[v.Code] = name;
                }
                else byCode[v.Code] = name;
            }

            var want = new List<HookFilterItem>();
            foreach (var code in byCode.Keys.OrderBy(c => c, StringComparer.OrdinalIgnoreCase))
            {
                string name = byCode[code];
                want.Add(new HookFilterItem(code, name.Length > 0 ? $"{name}({code})" : code));
            }

            bool same = cmb.Items.Count == want.Count + 1;
            if (same)
            {
                for (int i = 0; i < want.Count; i++)
                    if (cmb.Items[i + 1] is not HookFilterItem it || it != want[i]) { same = false; break; }
            }
            if (same) return;

            cmb.BeginUpdate();
            try
            {
                cmb.Items.Clear();
                cmb.Items.Add(new HookFilterItem("", "(全部)"));
                foreach (var it in want) cmb.Items.Add(it);
                int idx = keep.Length > 0 ? IndexOfCode(cmb, keep) : 0;
                cmb.SelectedIndex = idx >= 0 ? idx : 0;
            }
            finally { cmb.EndUpdate(); }
        }

        static int IndexOfCode(ComboBox cmb, string code)
        {
            for (int i = 0; i < cmb.Items.Count; i++)
                if (cmb.Items[i] is HookFilterItem it && string.Equals(it.Code, code, StringComparison.OrdinalIgnoreCase))
                    return i;
            return -1;
        }
    }

    /// <summary>生成实机诊断报告（句柄表 + 选区链 + 生命表的各条发现路径命中情况）。</summary>
    private void RunDiagnostics()
    {
        var g = _engine.Game;
        if (g == null || !g.IsReady)
        {
            MessageBox.Show(this, "还没连上游戏：先启动魔兽并进入地图。", "诊断", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }

        _cmdDiag.Enabled = false;
        SetStatus("正在生成诊断报告（句柄表 + 选区链，约 1~2 秒）…");
        Task.Run(() =>
        {
            string path;
            try { path = Probe.ReportForGame(g); }
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

    private void SetStatus(string s)
    {
        _statusText.Text = s;
        _statusText.ForeColor = Color.Gainsboro;
    }

    private void SetStatusRed(string s)
    {
        _statusText.Text = s;
        _statusText.ForeColor = Color.Salmon;
    }

    /// <summary>
    /// 重建表格前后保住滚动位置：停在最顶部就继续留在顶部；一旦往下滚过（含滚到底），
    /// 就保持原来的“第一可见行下标”，不再贴底跟随（否则底部会一直跳）。
    /// </summary>
    private static void PreserveScroll(DataGridView g, Action rebuild)
    {
        int first = -1;
        int visible = 1;
        try
        {
            visible = Math.Max(1, g.DisplayedRowCount(false));
            if (g.Rows.Count > 0) first = g.FirstDisplayedScrollingRowIndex;
        }
        catch { }

        rebuild();

        try
        {
            if (g.Rows.Count == 0) return;
            int target = first <= 0 ? 0 : Math.Clamp(first, 0, Math.Max(0, g.Rows.Count - 1));
            if (target >= 0) g.FirstDisplayedScrollingRowIndex = target;
        }
        catch { }
    }

    /// <summary>
    /// 按“内容身份”锚定视口：重建表格前后，让用户正在看的那一行停在原处。
    /// 与 PreserveScroll 只记行号不同，这里记的是“这一行是谁”（keyOf 算出的身份键），
    /// 重建后按身份键找回同一行再设 FirstDisplayedScrollingRowIndex —— 排序变化、顶部插入
    /// 都不会让“行号对应的内容”漂移。原来贴底就继续贴底；原来在顶就留在顶。
    /// </summary>
    private static void PreserveViewAnchor(DataGridView grid, Func<DataGridViewRow, string> keyOf, Action rebuild)
    {
        // 0 = 原无行（重建后停顶） 1 = 顶部 2 = 底部 3 = 中间（按身份键锚定）
        int mode;
        string anchorKey = "";
        int anchorY = 0;
        bool haveY = false;
        int visible = 1;

        try
        {
            visible = Math.Max(1, grid.DisplayedRowCount(false));
            if (grid.Rows.Count == 0)
            {
                mode = 0;
            }
            else
            {
                int first = grid.FirstDisplayedScrollingRowIndex;
                if (first < 0) first = 0;
                // 只有“停在最顶部”时才允许跟随新数据；一旦往下滚过（含滚到底），一律按行身份钉住视口，
                // 刷新时内容不滚动、滚动条不跳。原来“贴底跟随”会导致滚到底后一直往下跳，已去掉。
                if (first <= 0) mode = 1;                               // 顶部：保持
                else
                {
                    mode = 3;
                    anchorKey = keyOf(grid.Rows[first]);
                    try
                    {
                        var r = grid.GetRowDisplayRectangle(first, false);
                        if (r.Height > 0) { anchorY = r.Y; haveY = true; }
                    }
                    catch { }
                }
            }
        }
        catch { mode = 0; }

        rebuild();

        try
        {
            if (grid.Rows.Count == 0) return;
            int target;
            if (mode == 2)
            {
                target = Math.Max(0, grid.Rows.Count - visible);
            }
            else if (mode == 3 && anchorKey.Length > 0)
            {
                int found = -1;
                for (int i = 0; i < grid.Rows.Count; i++)
                    if (string.Equals(keyOf(grid.Rows[i]), anchorKey, StringComparison.Ordinal)) { found = i; break; }

                if (found < 0)
                {
                    // 身份键丢了（被顶出窗口 / 被筛选 / 被清除）：新内容已和旧视口无关，停在顶部最不突兀。
                    target = 0;
                }
                else
                {
                    target = Math.Clamp(found, 0, Math.Max(0, grid.Rows.Count - visible));
                    grid.FirstDisplayedScrollingRowIndex = target;

                    // 像素级修正（best-effort）：把锚点行顶部的 Y 对齐回重建前。
                    // 本应用行高统一（22px）、DataGridView 垂直滚动只按整行吸附（实测无分数行偏移），
                    // 行级锚定后第一可见行的 GetRowDisplayRectangle(...).Y 已与重建前恒等，delta 通常为 0；
                    // 万一未来出现变高行导致偏移，这里用内部垂直滚动条（Value 单位为像素）做一次对齐。
                    if (haveY)
                    {
                        try
                        {
                            int curY = grid.GetRowDisplayRectangle(target, false).Y;
                            int delta = anchorY - curY;
                            if (delta != 0)
                            {
                                var f = typeof(DataGridView).GetField("_vertScrollBar",
                                    BindingFlags.NonPublic | BindingFlags.Instance);
                                if (f?.GetValue(grid) is VScrollBar bar)
                                    bar.Value = Math.Clamp(bar.Value + delta, bar.Minimum, Math.Max(bar.Minimum, bar.Maximum - bar.LargeChange + 1));
                            }
                        }
                        catch { }
                    }
                    return;
                }
            }
            else
            {
                target = 0;   // 顶部 / 原无行：停在顶部
            }

            if (target >= 0 && target < grid.Rows.Count)
                grid.FirstDisplayedScrollingRowIndex = target;
        }
        catch { }
    }

    /// <summary>死亡结算页一行的身份键：结算行 = 地址+死亡时间+实例；存活行 = 地址+实例。</summary>
    private static string SettlementKey(object? tag) => tag switch
    {
        Settlement s => AnchorKeys.ForSettlement(s),
        LiveUnitRow lr => AnchorKeys.ForLiveUnit(lr.Unit.Addr, lr.Unit.InstanceIndex),
        _ => ""
    };

    protected override void OnFormClosing(FormClosingEventArgs e)
    {
        _uiTimer.Stop();
        try
        {
            _settings.IntervalMs = _engine.IntervalMs;
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







