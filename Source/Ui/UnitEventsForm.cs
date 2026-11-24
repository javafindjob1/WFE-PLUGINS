using War3DeathSettlement.Core;

namespace War3DeathSettlement.Ui;

/// <summary>
/// 双击死亡结算行 / 存活行弹出的【非模态】窗口：只看这个单位（来源或触发）的全部伤害事件。
/// 结构对齐【伤害事件】页：两个筛选下拉（参与单位 / 类型）+ 中部事件表 + 底部分页；
/// 事件表与主页共用 HookGridUi 的列/行渲染，也共用 SettlementHeaderSearch（触发单位 / 伤害来源表头搜索）。
/// 打开时用当时快照，不实时刷新；点【刷新】重新取一次事件快照。
/// 类型筛选默认【目标】（只看该单位挨打的事件）；参与单位默认【全部】。
/// </summary>
internal sealed class UnitEventsForm : Form
{
    private readonly uint _addr;
    private readonly Func<IReadOnlyList<DamageHook.HookEvent>> _refresh;
    private readonly Func<uint, string> _playerText;
    /// <summary>
    /// 按 (地址, 类型码) 查英雄称谓（用于名称显示和表头搜索；null = 用事件自带的
    /// victim_title/source_title，历史库回放走这条）。和主页【伤害事件】表用同一个谓词
    /// <see cref="HookGridUi.MatchesSearch"/>。
    /// </summary>
    private readonly Func<uint, string?, string>? _titleOf;
    private readonly Func<uint, string?, bool>? _isIllusionOf;
    private readonly Func<string, bool, HookGridUi.UnitIdentity>? _identityOf;

    private IReadOnlyList<DamageHook.HookEvent> _events;
    private int _page;
    private string _typeFilter = "dst";   // "" = 全部 / "src" = 源 / "dst" = 目标（默认只看目标；用户切换后刷新保持）
    private uint? _peerAddr;

    private readonly Grid _grid = new();
    /// <summary>表头搜索（触发单位 / 伤害来源）：与主页【伤害事件】表共用同一组件与谓词。</summary>
    private SettlementHeaderSearch _search = null!;
    private sealed record HookTrack(DamageHook.HookEvent Event, string Column);
    private readonly ComboBox _cmbPeer = new() { DropDownStyle = ComboBoxStyle.DropDownList, Width = 220 };
    private readonly ComboBox _cmbType = new() { DropDownStyle = ComboBoxStyle.DropDownList, Width = 120 };
    private readonly Button _btnFirst = new() { Text = "首页" };
    private readonly Button _btnPrev = new() { Text = "上一页" };
    private readonly Button _btnNext = new() { Text = "下一页" };
    private readonly Button _btnLast = new() { Text = "末页" };
    private readonly Button _btnRefresh = new() { Text = "刷新" };
    private readonly Label _lblPage = new();

    /// <summary>筛选下拉条目的值对象。</summary>
    private sealed record PeerItem(uint? Addr, string Text)
    {
        public override string ToString() => Text;
    }
    private sealed record TypeItem(string Key, string Text)
    {
        public override string ToString() => Text;
    }

    private bool _inFilter;

    public UnitEventsForm(string title, uint addr, IReadOnlyList<DamageHook.HookEvent> snapshot,
        Func<IReadOnlyList<DamageHook.HookEvent>> refresh, Func<uint, string> playerText,
        Func<uint, string?, string>? titleOf = null,
        Func<uint, string?, bool>? isIllusionOf = null,
        Func<string, bool, HookGridUi.UnitIdentity>? identityOf = null)
    {
        _addr = addr;
        _events = snapshot;
        _refresh = refresh;
        _playerText = playerText;
        _titleOf = titleOf;
        _isIllusionOf = isIllusionOf;
        _identityOf = identityOf;

        Text = title;
        Width = 1320;
        Height = 760;
        MinimumSize = new Size(1000, 560);
        StartPosition = FormStartPosition.CenterParent;
        ShowInTaskbar = false;
        BackColor = Color.FromArgb(24, 24, 28);
        ForeColor = Color.Gainsboro;
        Font = new Font("Microsoft YaHei UI", 9F);

        BuildUi();
        RebuildFilters();
        Render();
    }

    private void BuildUi()
    {
        _grid.Dock = DockStyle.Fill;
        HookGridUi.AddColumns(_grid);
        _grid.RowTemplate.Height = 36;
        _grid.DefaultCellStyle.WrapMode = DataGridViewTriState.True;
        // 表头搜索：过滤条件变化 → 回到第一页并重算（分页页数按“过滤后条数”算，见 Render）。
        _search = SettlementHeaderSearch.ForHookEvents(_grid, () => { _page = 0; Render(); });

        // 右键【跟踪】：把单位名/玩家写进对应列的表头搜索框并钉住
        var menu = new ContextMenuStrip();
        var trackItem = new ToolStripMenuItem("跟踪");
        HookTrack? track = null;
        trackItem.Click += (_, _) =>
        {
            if (track == null) return;
            string col = track.Column;
            string name = HookGridUi.TrackName(track.Event, col);
            if (name.Length == 0) return;
            _page = 0;
            _search.Track(col, name);
            Render();
        };
        menu.Items.Add(trackItem);
        menu.Opening += (_, e) =>
        {
            bool ok = track != null && HookGridUi.IsTrackColumn(track.Column);
            trackItem.Enabled = ok;
            e.Cancel = !ok;
        };
        _grid.ContextMenuStrip = menu;
        _grid.CellMouseDown += (_, e) =>
        {
            track = null;
            if (e.Button != MouseButtons.Right || e.RowIndex < 0 || e.ColumnIndex < 0) return;
            if (e.RowIndex >= _grid.Rows.Count || e.ColumnIndex >= _grid.Columns.Count) return;
            string col = _grid.Columns[e.ColumnIndex].Name;
            if (!HookGridUi.IsTrackColumn(col)) return;
            if (_grid.Rows[e.RowIndex].Tag is not DamageHook.HookEvent ev) return;
            track = new HookTrack(ev, col);
            _grid.ClearSelection();
            _grid.Rows[e.RowIndex].Selected = true;
            _grid.CurrentCell = _grid.Rows[e.RowIndex].Cells[e.ColumnIndex];
        };

        // 顶部：参与单位 / 类型 两个下拉 + 刷新按钮
        var filterBar = new Panel { Dock = DockStyle.Top, Height = 38, BackColor = Color.FromArgb(28, 28, 34) };
        var lblPeer = new Label { Text = "参与单位：", AutoSize = true, ForeColor = Color.LightGray, Location = new Point(8, 11) };
        _cmbPeer.Location = new Point(88, 7);
        var lblType = new Label { Text = "类型：", AutoSize = true, ForeColor = Color.LightGray, Location = new Point(324, 11) };
        _cmbType.Location = new Point(374, 7);
        _btnRefresh.Location = new Point(520, 7);
        _btnRefresh.Size = new Size(70, 25);
        StyleButton(_btnRefresh, Color.FromArgb(50, 50, 58));
        filterBar.Controls.AddRange(new Control[] { lblPeer, _cmbPeer, lblType, _cmbType, _btnRefresh });

        // 底部：分页控件
        var pageBar = new Panel { Dock = DockStyle.Bottom, Height = 36, BackColor = Color.FromArgb(28, 28, 34) };
        _btnFirst.Location = new Point(8, 6);  _btnFirst.Size = new Size(56, 25);
        _btnPrev.Location = new Point(70, 6);  _btnPrev.Size = new Size(68, 25);
        _btnNext.Location = new Point(144, 6); _btnNext.Size = new Size(68, 25);
        _btnLast.Location = new Point(218, 6); _btnLast.Size = new Size(56, 25);
        _lblPage.Location = new Point(288, 10);
        _lblPage.AutoSize = true;
        _lblPage.ForeColor = Color.Gainsboro;
        foreach (var b in new[] { _btnFirst, _btnPrev, _btnNext, _btnLast })
            StyleButton(b, Color.FromArgb(50, 50, 58));
        pageBar.Controls.AddRange(new Control[] { _btnFirst, _btnPrev, _btnNext, _btnLast, _lblPage });

        Controls.Add(_grid);
        Controls.Add(pageBar);
        Controls.Add(filterBar);

        _cmbPeer.SelectedIndexChanged += (_, _) =>
        {
            if (_inFilter) return;
            _peerAddr = (_cmbPeer.SelectedItem as PeerItem)?.Addr;
            _page = 0;
            Render();
        };
        _cmbType.SelectedIndexChanged += (_, _) =>
        {
            if (_inFilter) return;
            _typeFilter = (_cmbType.SelectedItem as TypeItem)?.Key ?? "";
            _page = 0;
            Render();
        };
        _btnRefresh.Click += (_, _) =>
        {
            _events = _refresh();
            RebuildFilters();
            Render();   // Render 里会把 _page 夹回合法范围，不主动抢页
        };
        _btnFirst.Click += (_, _) => { _page = 0; Render(); };
        _btnPrev.Click += (_, _) => { _page = Math.Max(0, _page - 1); Render(); };
        _btnNext.Click += (_, _) => { _page = Math.Min(UnitEvents.PageCount(Filtered().Count) - 1, _page + 1); Render(); };
        _btnLast.Click += (_, _) => { _page = UnitEvents.PageCount(Filtered().Count) - 1; Render(); };
    }

    private static void StyleButton(Button b, Color back)
    {
        b.FlatStyle = FlatStyle.Flat;
        b.BackColor = back;
        b.ForeColor = Color.Gainsboro;
        b.FlatAppearance.BorderColor = Color.FromArgb(80, 80, 90);
    }

    /// <summary>用当前事件快照重建两个下拉的条目（保持已选）。</summary>
    private void RebuildFilters()
    {
        _inFilter = true;
        try
        {
            uint? keepPeer = _peerAddr;
            var peers = UnitEvents.CounterpartAddrs(_events, _addr);

            _cmbPeer.Items.Clear();
            _cmbPeer.Items.Add(new PeerItem(null, "(全部)"));
            foreach (var p in peers) _cmbPeer.Items.Add(new PeerItem(p, PeerLabel(p)));
            int peerIdx = 0;
            if (keepPeer is uint kp)
                for (int i = 0; i < _cmbPeer.Items.Count; i++)
                    if (_cmbPeer.Items[i] is PeerItem pi && pi.Addr == kp) { peerIdx = i; break; }
            _cmbPeer.SelectedIndex = peerIdx;

            _cmbType.Items.Clear();
            _cmbType.Items.Add(new TypeItem("", "(全部)"));
            _cmbType.Items.Add(new TypeItem("src", "源"));
            _cmbType.Items.Add(new TypeItem("dst", "目标"));
            int typeIdx = _typeFilter == "src" ? 1 : _typeFilter == "dst" ? 2 : 0;
            _cmbType.SelectedIndex = typeIdx;
        }
        finally { _inFilter = false; }
    }

    /// <summary>对端单位在下拉里的显示名：名字优先，退回类型码，再退回地址。</summary>
    private string PeerLabel(uint addr)
    {
        foreach (var e in _events)
        {
            if (e.Source == addr)
            {
                string n = e.SourceName.Length > 0 ? e.SourceName : e.SourceCode;
                return n.Length > 0 ? $"{n}(0x{addr:X8})" : $"0x{addr:X8}";
            }
            if (e.Victim == addr)
            {
                string n = e.VictimName.Length > 0 ? e.VictimName : e.VictimCode;
                return n.Length > 0 ? $"{n}(0x{addr:X8})" : $"0x{addr:X8}";
            }
        }
        return $"0x{addr:X8}";
    }

    /// <summary>
    /// 当前筛选命中的事件（保持“最旧在前”顺序）：下拉条件与表头搜索关键词 AND 叠加。
    /// 「触发单位 / 伤害来源」显示“称谓 + 单位名称”，表头搜索匹配任一字段。
    /// </summary>
    private List<DamageHook.HookEvent> Filtered()
    {
        string victimKeyword = _search.Keyword(HookGridUi.VictimColumn);
        string sourceKeyword = _search.Keyword(HookGridUi.SourceColumn);
        var list = new List<DamageHook.HookEvent>();
        foreach (var e in _events)
            if (Matches(e) && HookGridUi.MatchesSearch(
                    e, victimKeyword, _search.Keyword(HookGridUi.VictimPlayerColumn),
                    sourceKeyword, _search.Keyword(HookGridUi.SourcePlayerColumn),
                    _titleOf, _isIllusionOf, _identityOf))
                list.Add(e);
        return list;
    }

    private bool Matches(DamageHook.HookEvent e)
    {
        bool asSource = e.Source == _addr;
        bool asVictim = e.Victim == _addr;
        if (!asSource && !asVictim) return false;
        if (_typeFilter == "src" && !asSource) return false;
        if (_typeFilter == "dst" && !asVictim) return false;
        if (_peerAddr is uint peer)
        {
            if (asSource && e.Victim != peer) return false;
            if (asVictim && e.Source != peer) return false;
        }
        return true;
    }

    private void Render()
    {
        var filtered = Filtered();       // 最旧在前
        int total = filtered.Count;
        int pageCount = UnitEvents.PageCount(total);
        _page = Math.Clamp(_page, 0, pageCount - 1);

        var pageItems = UnitEvents.SlicePage(filtered, _page);
        _grid.Rows.Clear();
        foreach (var e in pageItems)
        {
            int idx = _grid.Rows.Add(HookGridUi.RowCells(
                e, _playerText, isIllusionOf: _isIllusionOf, identityOf: _identityOf));
            _grid.Rows[idx].Tag = e;
            if (e.Depth > 1) _grid.Rows[idx].DefaultCellStyle.ForeColor = Color.FromArgb(190, 190, 150);
        }

        _lblPage.Text = $"第 {_page + 1} / {pageCount} 页（共 {total} 条）";
        _btnFirst.Enabled = _btnPrev.Enabled = _page > 0;
        _btnNext.Enabled = _btnLast.Enabled = _page < pageCount - 1;
    }
}
