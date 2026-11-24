using System.Text.RegularExpressions;

namespace War3DeathSettlement.Core;

/// <summary>
/// 魔兽文本样式清理：单位名/伤害来源名里经常夹带 <c>|cAARRGGBB</c> 颜色码和 <c>|r</c> 复位码
/// （YDWE/WFE 地图给单位名上色后，钩子/插件日志里带回来的就是这种原文）。
/// 这些是**显示样式**，不是名字本身：界面表格、历史库、CSV 里都应该只保留纯文本。
///
/// 处理规则（与魔兽的富文本约定一致）：
///   · <c>|c</c> + 1~8 位十六进制颜色 → 删掉；前面的 <c>(</c> / 后面的 <c>)</c> 一起删
///     （地图常写成 <c>名字(|cfff0E053)</c>；引擎名字段只有 16 字节，长名字会被截成
///     <c>名字(|cfff0</c> —— 只有 4 位十六进制，所以不能只认 6~8 位）；
///   · <c>|r</c> / <c>|R</c> 复位 → 删掉；结尾只剩 <c>|c</c> 的残码也删掉；
///   · 其它内容原样保留（只做 Trim，不动名字里的空格/符号）。
/// 纯函数、幂等：同一段文本清理多次结果一致，可在数据入库/出库/渲染三处放心调用。
/// </summary>
public static class Wc3Text
{
    // 颜色码：|c + 1~8 位十六进制；连带紧邻的 '(' / ')'（地图常用的 "名字(|cXXXX)" 写法）。
    private static readonly Regex ColorCode =
        new(@"\(?\|[cC][0-9a-fA-F]{1,8}\)?", RegexOptions.Compiled);

    // 极端截断：名字末尾只剩 "|c" 或 "(|c"（16 字节字段把颜色码切成两半）。
    private static readonly Regex DanglingColor =
        new(@"\(?\|[cC]$", RegexOptions.Compiled);

    private static readonly Regex ResetCode =
        new(@"\|[rR](?![a-zA-Z])", RegexOptions.Compiled);

    /// <summary>去掉颜色码/复位码并 Trim；null 返回空串；没有样式码时只 Trim（保留原有语义）。</summary>
    public static string Clean(string? text)
    {
        if (string.IsNullOrEmpty(text)) return text ?? "";
        if (text.IndexOf('|') < 0) return text.Trim();

        string s = ColorCode.Replace(text, "");
        s = DanglingColor.Replace(s, "");
        s = ResetCode.Replace(s, "");
        return s.Trim();
    }

    /// <summary>这段文本里有没有魔兽样式码（自检/日志用）。</summary>
    public static bool HasStyle(string? text) =>
        !string.IsNullOrEmpty(text) && text.IndexOf('|') >= 0 &&
        (ColorCode.IsMatch(text) || DanglingColor.IsMatch(text) || ResetCode.IsMatch(text));

    /// <summary>
    /// 统一的单位显示名：有称谓时第一行称谓、第二行单位名称；
    /// 没有称谓时只显示名称，名称也没有才回退类型码。
    /// </summary>
    public static string UnitIdentity(string? name, string? title, string? code)
    {
        name = Clean(name ?? "");
        title = Clean(title ?? "");
        if (title.Length > 0 && string.Equals(title, name, StringComparison.Ordinal)) title = "";
        if (title.Length > 0 && name.Length > 0) return title + "\n" + name;
        if (title.Length > 0) return title;
        if (name.Length > 0) return name;
        return code ?? "";
    }
}
