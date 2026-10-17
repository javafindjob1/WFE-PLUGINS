using System.ComponentModel;
using System.Diagnostics;
using War3DeathSettlement.Core;

namespace War3DeathSettlement.Ui;

/// <summary>
/// “选择进程”对话框。
///
/// 为什么需要它：平台的魔兽进程名可能不是 war3，甚至进程名是平台自己的；
/// 而我们能直接看到的判据是「这个进程里加载了 game.dll」。
/// 所以这里把进程列出来、标出谁加载了 game.dll（绿色），点一下就连。
///
/// 设计要点（都是踩过坑之后加的）：
///   * **默认只看候选**，但可以取消勾选看全部进程 —— 万一权限不足导致读不到 game.dll，
///     用户还能自己认出魔兽并手动选它；
///   * 读不到模块列表（权限不足）会明确标成“读不到”，而不是把进程藏起来；
///   * 打开对话框期间**每 2 秒自动重扫**，这样“先开这个窗、再启动游戏”也能看到它冒出来。
/// </summary>
public sealed class ProcessPickerForm : Form
{
    private readonly ListView _list = new();
    private readonly Label _hint = new();
    private readonly CheckBox _onlyCandidates = new() { Text = "只看魔兽候选", Checked = true, AutoSize = true };
    private readonly Button _ok = new() { Text = "连接这个进程" };
    private readonly Button _refresh = new() { Text = "重新扫描" };
    private readonly Button _cancel = new() { Text = "取消" };
    private readonly TextBox _manual = new();
    private readonly System.Windows.Forms.Timer _timer = new() { Interval = 2000 };

    [DesignerSerializationVisibility(DesignerSerializationVisibility.Hidden)]
    [Browsable(false)]
    public int? SelectedPid { get; private set; }

    [DesignerSerializationVisibility(DesignerSerializationVisibility.Hidden)]
    [Browsable(false)]
    public string SelectedName { get; private set; } = "";

    private sealed record Row(int Pid, string Name, string GameDll, string Ver, string Path, bool ModuleUnknown);

    public ProcessPickerForm()
    {
        Text = "选择魔兽进程（绿色的确实加载了 game.dll）";
        Width = 1000;
        Height = 560;
        StartPosition = FormStartPosition.CenterParent;
        BackColor = Color.FromArgb(28, 28, 32);
        ForeColor = Color.Gainsboro;
        Font = new Font("Microsoft YaHei UI", 9F);

        _hint.Dock = DockStyle.Top;
        _hint.Height = 44;
        _hint.Padding = new Padding(10, 6, 10, 0);
        _hint.ForeColor = Color.Khaki;

        _list.Dock = DockStyle.Fill;
        _list.View = View.Details;
        _list.FullRowSelect = true;
        _list.MultiSelect = false;
        _list.HideSelection = false;
        _list.BackColor = Color.FromArgb(24, 24, 28);
        _list.ForeColor = Color.Gainsboro;
        _list.Columns.Add("PID", 70);
        _list.Columns.Add("进程名", 170);
        _list.Columns.Add("game.dll 基址", 130);
        _list.Columns.Add("game.dll 版本", 140);
        _list.Columns.Add("路径", 430);
        _list.DoubleClick += (_, _) => Accept();

        var bottom = new Panel { Dock = DockStyle.Bottom, Height = 46 };
        _onlyCandidates.SetBounds(10, 12, 130, 24);
        _onlyCandidates.ForeColor = Color.Gainsboro;
        _onlyCandidates.CheckedChanged += (_, _) => Scan();
        _ok.SetBounds(150, 8, 130, 30);
        _ok.Click += (_, _) => Accept();
        _refresh.SetBounds(290, 8, 100, 30);
        _refresh.Click += (_, _) => Scan();
        _cancel.SetBounds(400, 8, 80, 30);
        _cancel.DialogResult = DialogResult.Cancel;

        var lblManual = new Label { Text = "或直接填 PID：", AutoSize = true, ForeColor = Color.Gainsboro };
        lblManual.SetBounds(510, 14, 100, 20);
        _manual.SetBounds(610, 9, 90, 26);
        var btnManual = new Button { Text = "连接", Bounds = new Rectangle(710, 8, 60, 30) };
        btnManual.Click += (_, _) =>
        {
            if (int.TryParse(_manual.Text.Trim(), out int pid)) { SelectedPid = pid; SelectedName = ""; DialogResult = DialogResult.OK; Close(); }
            else MessageBox.Show(this, "PID 得是数字。", "提示");
        };

        bottom.Controls.AddRange(new Control[] { _onlyCandidates, _ok, _refresh, _cancel, lblManual, _manual, btnManual });

        Controls.Add(_list);
        Controls.Add(bottom);
        Controls.Add(_hint);

        Shown += (_, _) => { Scan(); _timer.Start(); };
        FormClosed += (_, _) => _timer.Stop();
        _timer.Tick += (_, _) => Scan();
    }

    private void Scan()
    {
        int keepPid = -1;
        if (_list.SelectedItems.Count > 0 && _list.SelectedItems[0].Tag is Row sel) keepPid = sel.Pid;
        bool onlyCand = _onlyCandidates.Checked;

        var rows = new List<Row>();
        int unknown = 0;

        foreach (var p in Process.GetProcesses())
        {
            try
            {
                string name = p.ProcessName;
                string path = "";
                string dll = "";
                string ver = "";
                bool moduleUnknown = false;

                try { path = p.MainModule?.FileName ?? ""; } catch { }

                try
                {
                    foreach (ProcessModule m in p.Modules)
                    {
                        if (!string.Equals(m.ModuleName, "game.dll", StringComparison.OrdinalIgnoreCase)) continue;
                        dll = "0x" + m.BaseAddress.ToInt64().ToString("X8");
                        try
                        {
                            var fv = FileVersionInfo.GetVersionInfo(m.FileName);
                            ver = (!string.IsNullOrWhiteSpace(fv.ProductVersion) ? fv.ProductVersion : fv.FileVersion) ?? "";
                        }
                        catch { }
                        break;
                    }
                }
                catch
                {
                    if (p.Id > 4) { moduleUnknown = true; unknown++; }   // 权限不足之类（PID 0/4 是系统进程，不算）
                }

                bool candidate = dll.Length > 0 || moduleUnknown || ProcessMatch.LooksLikeGame(name);
                if (onlyCand && !candidate) continue;

                rows.Add(new Row(p.Id, name, dll, ver, path, moduleUnknown));
            }
            catch { /* 进程已退出 */ }
        }

        _list.BeginUpdate();
        _list.Items.Clear();
        foreach (var r in rows.OrderByDescending(r => r.GameDll.Length > 0).ThenBy(r => r.Name))
        {
            string dllCell = r.GameDll.Length > 0 ? r.GameDll : (r.ModuleUnknown ? "读不到（权限？）" : "（没有）");
            var it = new ListViewItem(new[] { r.Pid.ToString(), r.Name, dllCell, r.Ver, r.Path });
            it.Tag = r;
            if (r.GameDll.Length > 0) it.ForeColor = Color.LightGreen;
            else if (r.ModuleUnknown) it.ForeColor = Color.Khaki;
            _list.Items.Add(it);
            if (r.Pid == keepPid) { it.Selected = true; it.Focused = true; }
        }
        _list.EndUpdate();

        int green = rows.Count(r => r.GameDll.Length > 0);
        _hint.Text = green > 0
            ? $"找到 {green} 个加载了 game.dll 的进程（绿色行）—— 选中后点【连接这个进程】，或直接双击。" +
              (unknown > 0 ? $"　另有 {unknown} 个进程读不到模块列表（权限不足，黄色行）。" : "")
            : $"暂时没看到加载 game.dll 的进程（当前列出 {rows.Count} 个）。" +
              "先启动魔兽、进游戏；这个窗口每 2 秒自动重扫。" +
              (unknown > 0 ? $"　注意：有 {unknown} 个进程读不到模块列表 —— 若魔兽在里面，请【以管理员身份重启】本软件。" : "");
    }

    private void Accept()
    {
        if (SelectedPid is null)
        {
            if (_list.SelectedItems.Count == 0)
            {
                MessageBox.Show(this, "先选一行。", "提示", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            if (_list.SelectedItems[0].Tag is not Row row)
            {
                MessageBox.Show(this, "这一行没有可用信息。", "提示", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }
            SelectedPid = row.Pid;
            SelectedName = row.Name;
        }
        DialogResult = DialogResult.OK;
        Close();
    }
}


