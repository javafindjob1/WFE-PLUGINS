using War3DeathSettlement.Core;

namespace War3DeathSettlement.Ui;

/// <summary>
/// 单位属性表（【死亡结算】右键 → 查看详情）：只读非模态表格，
/// 五行为 血量 / 攻击力 / 攻击间隔 / 护甲 / 技能，第三列注明数据来源。
/// 不再放任何说明文字（说明统一写进 exe 同目录的 运行前必读.txt）。
/// </summary>
internal sealed class UnitStatsForm : Form
{
    public UnitStatsForm(string title, IReadOnlyList<UnitStatLine> rows)
    {
        Text = title;
        Width = 980;
        Height = 300;
        MinimumSize = new Size(640, 240);
        StartPosition = FormStartPosition.CenterParent;
        ShowInTaskbar = false;
        MinimizeBox = false;
        MaximizeBox = true;
        ShowIcon = false;
        BackColor = Color.FromArgb(24, 24, 28);
        ForeColor = Color.Gainsboro;
        Font = new Font("Microsoft YaHei UI", 9F);

        var grid = new Grid { Dock = DockStyle.Fill };
        grid.AddText("属性", "name", 90);
        grid.AddText("数值", "value", 380);
        grid.AddText("数据来源", "source", 420);
        foreach (DataGridViewColumn col in grid.Columns)
        {
            col.AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill;
            col.FillWeight = Math.Max(20, col.Width);
            col.MinimumWidth = 70;
        }
        grid.Columns["name"]!.MinimumWidth = 70;
        grid.Columns["value"]!.MinimumWidth = 180;

        foreach (var r in rows)
        {
            int idx = grid.Rows.Add(r.Name, r.Value, r.Source);
            // 读不到的项（? / —）用暗一点的颜色，别让人以为是有值。
            if (r.Value is "?" or "—" or "")
                grid.Rows[idx].DefaultCellStyle.ForeColor = Color.FromArgb(150, 150, 150);
        }

        Controls.Add(grid);
    }
}
