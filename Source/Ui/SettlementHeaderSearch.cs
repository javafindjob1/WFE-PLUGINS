using System.Linq;

namespace War3DeathSettlement.Ui;

/// <summary>
/// 表头搜索（点击式）：
///  · 默认只显示普通表头文字，不显示输入框；
///  · 点表头 → 在该列表头里出现输入框（自动聚焦、全选）；
///  · 失焦 / 回车 → 收起输入框，把关键词直接写进表头（覆盖原表头文字），
///    并在表头右上方显示一个小 ×；
///  · 点 × → 清空该列关键词，表头恢复原文字。
/// 另外：右键这些列会追加【跟踪】（宿主菜单已有同名项时不重复添加）。
/// </summary>
internal sealed class SettlementHeaderSearch
{
    private sealed record SearchColumn(string Name, string Header, string Placeholder);

    private readonly Grid _grid;
    private readonly Action _onChanged;
    private readonly IReadOnlyList<SearchColumn> _columns;
    private readonly Dictionary<string, SearchColumn> _byName;
    private readonly Dictionary<string, TextBox> _boxes = new(StringComparer.Ordinal);
    private readonly Dictionary<string, Label> _clears = new(StringComparer.Ordinal);
    private readonly Dictionary<string, string> _keywords = new(StringComparer.Ordinal);
    private readonly System.Windows.Forms.Timer _timer = new() { Interval = 150 };

    private string _editing = "";
    private string _editBackup = "";
    private ToolStripMenuItem? _trackItem;
    private string _menuColumn = "";
    private string _menuText = "";

    public static SettlementHeaderSearch ForSettlement(Grid grid, Action onChanged) =>
        new(grid, onChanged, new[]
        {
            new SearchColumn(SettlementGridUi.NameColumn, SettlementGridUi.NameHeader, "单位名称/称谓"),
            new SearchColumn(SettlementGridUi.CodeColumn, SettlementGridUi.CodeHeader, "类型码"),
        });

    public static SettlementHeaderSearch ForUnits(Grid grid, Action onChanged) =>
        new(grid, onChanged, new[]
        {
            new SearchColumn(UnitGridUi.CodeColumn, UnitGridUi.CodeHeader, "类型码"),
            new SearchColumn(UnitGridUi.NameColumn, UnitGridUi.NameHeader, "单位名/称谓"),
        });

    public static SettlementHeaderSearch ForHookEvents(Grid grid, Action onChanged) =>
        new(grid, onChanged, new[]
        {
            new SearchColumn(HookGridUi.VictimColumn, HookGridUi.VictimHeader, "触发单位/称谓"),
            new SearchColumn(HookGridUi.VictimPlayerColumn, HookGridUi.VictimPlayerHeader, "触发玩家"),
            new SearchColumn(HookGridUi.SourceColumn, HookGridUi.SourceHeader, "伤害来源/称谓"),
            new SearchColumn(HookGridUi.SourcePlayerColumn, HookGridUi.SourcePlayerHeader, "来源玩家"),
        });

    private SettlementHeaderSearch(Grid grid, Action onChanged, IReadOnlyList<SearchColumn> columns)
    {
        _grid = grid;
        _onChanged = onChanged;
        _columns = columns;
        _byName = columns.ToDictionary(c => c.Name, StringComparer.Ordinal);

        Font headerFont = _grid.ColumnHeadersDefaultCellStyle.Font ?? new Font("Microsoft YaHei UI", 9F);
        try
        {
            // 表头高度 = 输入框高度：编辑时输入框正好铺满表头，不留上下缝
            var probe = new TextBox { Font = headerFont };
            _grid.ColumnHeadersHeight = probe.PreferredHeight;
            _grid.ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.DisableResizing;
            probe.Dispose();
        }
        catch { }

        foreach (var column in columns)
        {
            _keywords[column.Name] = "";

            var box = new TextBox
            {
                BorderStyle = BorderStyle.None,
                Multiline = true,          // 单行 TextBox 高度由字体固定，多行才能铺满表头
                BackColor = Color.White,
                ForeColor = Color.Black,
                Font = headerFont,
                Visible = false,
                Tag = column.Name,
            };
            box.KeyDown += (_, e) =>
            {
                if (e.KeyCode == Keys.Enter) { e.SuppressKeyPress = true; Commit(column.Name); }
                else if (e.KeyCode == Keys.Escape) { e.SuppressKeyPress = true; Cancel(column.Name); }
            };
            box.Leave += (_, _) => { if (_editing == column.Name) Commit(column.Name); };
            box.TextChanged += (_, _) =>
            {
                if (_grid.IsDisposed) return;
                _timer.Stop();
                _timer.Start();
            };
            _boxes[column.Name] = box;
            _grid.Controls.Add(box);

            var clear = new Label
            {
                Text = "×",
                AutoSize = false,
                Size = new Size(14, 14),
                TextAlign = ContentAlignment.MiddleCenter,
                ForeColor = Color.FromArgb(220, 220, 220),
                BackColor = Color.FromArgb(70, 70, 78),
                Font = new Font(headerFont.FontFamily, 8F, FontStyle.Bold),
                Cursor = Cursors.Hand,
                Visible = false,
                Tag = column.Name,
            };
            clear.Click += (_, _) => ClearColumn(column.Name);
            _clears[column.Name] = clear;
            _grid.Controls.Add(clear);
        }

        _timer.Tick += (_, _) => { _timer.Stop(); if (_editing.Length > 0) Commit(_editing); };

        _grid.Scroll += (_, _) => Align();
        _grid.ColumnWidthChanged += (_, _) => Align();
        _grid.SizeChanged += (_, _) => Align();
        _grid.VisibleChanged += (_, _) => { if (_grid.Visible) Align(); };
        _grid.HandleCreated += (_, _) => Align();
        _grid.ColumnHeaderMouseClick += OnHeaderClick;
        _grid.CellMouseDown += OnCellMouseDown;
    }

    public bool HasFilter => _keywords.Values.Any(k => k.Length > 0);
    public bool IsEditing => _editing.Length > 0;
    public bool IsTracking => false;

    public string Keyword(string columnName) =>
        _keywords.TryGetValue(columnName, out var keyword) ? keyword : "";

    /// <summary>右键【跟踪】：直接写入关键词（不打开输入框），表头显示关键词 + ×。</summary>
    public bool Track(string columnName, string keyword)
    {
        if (!_byName.ContainsKey(columnName)) return false;
        keyword = (keyword ?? "").Trim();
        if (keyword.Length == 0) return false;
        Apply(columnName, keyword);
        return true;
    }

    /// <summary>清空全部（换局）。</summary>
    public void Clear(bool notify = true)
    {
        foreach (var name in _byName.Keys.ToList()) ClearColumn(name, notify: false);
        if (notify) { try { _onChanged(); } catch { } }
    }

    public bool MatchesValues(object? firstValue, object? secondValue,
                              string? firstTitle = null, string? secondTitle = null)
    {
        if (_columns.Count < 2) return true;
        return SettlementGridUi.MatchesNameOrTitle(firstValue, firstTitle, _keywords[_columns[0].Name])
            && SettlementGridUi.MatchesNameOrTitle(secondValue, secondTitle, _keywords[_columns[1].Name]);
    }

    internal static bool PlaceholderVisible(bool editorVisible, bool focused, int textLength, string placeholderText) =>
        editorVisible && !focused && textLength == 0 && placeholderText.Length > 0;

    // ------------------------------------------------------------------
    private void OnHeaderClick(object? sender, DataGridViewCellMouseEventArgs e)
    {
        if (e.ColumnIndex < 0 || e.ColumnIndex >= _grid.Columns.Count) return;
        string column = _grid.Columns[e.ColumnIndex].Name;
        if (!_byName.TryGetValue(column, out var spec)) return;

        // 点 14×14 的清空按钮区域 → 清空该列
        if (_clears.TryGetValue(column, out var clear) && clear.Visible &&
            clear.Bounds.Contains(_grid.PointToClient(Cursor.Position)))
        {
            ClearColumn(column);
            return;
        }

        BeginEdit(column);
    }

    private void BeginEdit(string column)
    {
        if (!_boxes.TryGetValue(column, out var box)) return;
        if (_editing.Length > 0 && _editing != column) Commit(_editing);

        _editing = column;
        _editBackup = _keywords[column];
        box.Text = _keywords[column];
        Align();
        box.Visible = true;
        box.BringToFront();
        box.Focus();
        box.SelectAll();
    }

    private void Commit(string column)
    {
        if (_editing != column) return;
        if (!_boxes.TryGetValue(column, out var box)) return;
        _editing = "";
        box.Visible = false;
        Apply(column, box.Text.Trim());
    }

    private void Cancel(string column)
    {
        if (_editing != column) return;
        if (!_boxes.TryGetValue(column, out var box)) return;
        _editing = "";
        box.Visible = false;
        box.Text = _editBackup;
        Apply(column, _editBackup);
    }

    private void Apply(string column, string keyword)
    {
        bool changed = !string.Equals(_keywords[column], keyword, StringComparison.Ordinal);
        _keywords[column] = keyword;
        UpdateHeader(column);
        if (changed) { try { _onChanged(); } catch { } }
    }

    private void ClearColumn(string column, bool notify = true)
    {
        if (!_byName.ContainsKey(column)) return;
        if (_editing == column) { _editing = ""; if (_boxes.TryGetValue(column, out var b)) b.Visible = false; }
        _keywords[column] = "";
        if (_boxes.TryGetValue(column, out var box)) box.Text = "";
        UpdateHeader(column);
        Align();
        if (notify) { try { _onChanged(); } catch { } }
    }

    /// <summary>表头文字：有关键词就显示关键词（覆盖原表头），并亮出 ×。</summary>
    private void UpdateHeader(string column)
    {
        if (!_grid.Columns.Contains(column) || !_byName.TryGetValue(column, out var spec)) return;
        var col = _grid.Columns[column]!;
        string keyword = _keywords[column];

        if (keyword.Length > 0)
        {
            col.HeaderText = keyword;
            col.HeaderCell.ToolTipText = $"{spec.Header} 过滤：{keyword}（点 × 清除，点表头修改）";
        }
        else
        {
            col.HeaderText = spec.Header;
            col.HeaderCell.ToolTipText = $"点表头搜索「{spec.Header}」";
        }

        if (_clears.TryGetValue(column, out var clear)) clear.Visible = keyword.Length > 0;
        Align();
    }

    private void OnCellMouseDown(object? sender, DataGridViewCellMouseEventArgs e)
    {
        if (e.Button != MouseButtons.Right || e.RowIndex < 0 || e.ColumnIndex < 0) return;
        if (e.RowIndex >= _grid.Rows.Count || e.ColumnIndex >= _grid.Columns.Count) return;
        string column = _grid.Columns[e.ColumnIndex].Name;
        if (!_byName.ContainsKey(column)) return;
        _menuColumn = column;
        _menuText = _grid.Rows[e.RowIndex].Cells[e.ColumnIndex].Value?.ToString() ?? "";
        EnsureTrackMenu();
        if (_trackItem != null) _trackItem.Enabled = _menuText.Length > 0;
    }

    private void EnsureTrackMenu()
    {
        if (_trackItem != null) return;
        var menu = _grid.ContextMenuStrip;
        if (menu == null)
        {
            menu = new ContextMenuStrip();
            _grid.ContextMenuStrip = menu;
        }
        // 宿主菜单里已经有【跟踪】就直接复用，别再加第二项
        var existing = menu.Items.OfType<ToolStripMenuItem>()
            .FirstOrDefault(i => (i.Text ?? "").Replace("&", "").Trim() == "跟踪");
        if (existing != null) { _trackItem = existing; return; }

        _trackItem = new ToolStripMenuItem("跟踪");
        _trackItem.Click += (_, _) =>
        {
            if (_menuColumn.Length == 0 || _menuText.Length == 0) return;
            Track(_menuColumn, _menuText);
        };
        menu.Items.Add(_trackItem);
    }

    /// <summary>多行输入框：用 EM_SETRECT 把文本排版区域压到垂直中间。</summary>
    private static void SetVerticalCenter(TextBox box)
    {
        try
        {
            int pad = Math.Max(0, (box.ClientSize.Height - box.Font.Height) / 2);
            var rc = new NativeRect { Left = 2, Top = pad, Right = box.ClientSize.Width - 2, Bottom = box.ClientSize.Height - pad };
            SendMessage(box.Handle, EmSetRect, IntPtr.Zero, ref rc);
        }
        catch { }
    }

    private const int EmSetRect = 0x00B2;

    [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
    private struct NativeRect { public int Left, Top, Right, Bottom; }

    [System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto)]
    private static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, ref NativeRect lParam);

    /// <summary>输入框/× 跟随表头：编辑时铺满表头，× 固定在右上角。</summary>
    private void Align()
    {
        if (_grid.IsDisposed || _grid.Disposing) return;
        foreach (var (name, box) in _boxes)
        {
            try
            {
                if (!_grid.Columns.Contains(name)) { box.Visible = false; continue; }
                int index = _grid.Columns[name]!.Index;
                var rect = _grid.GetCellDisplayRectangle(index, -1, false);
                if (rect.Width <= 8 || rect.Height <= 8) { box.Visible = false; continue; }

                if (_editing == name)
                {
                    box.Bounds = new Rectangle(rect.X, rect.Y, Math.Max(10, rect.Width), Math.Max(14, rect.Height));
                    box.Visible = true;
                    box.BringToFront();
                    SetVerticalCenter(box);
                }

                if (_clears.TryGetValue(name, out var clear))
                {
                    clear.Bounds = new Rectangle(rect.Right - clear.Width - 1, rect.Y + 1, clear.Width, clear.Height);
                    clear.Visible = _keywords[name].Length > 0;
                    if (clear.Visible) clear.BringToFront();
                }
            }
            catch { }
        }
    }
}
