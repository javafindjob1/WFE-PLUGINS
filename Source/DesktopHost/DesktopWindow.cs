using System.Diagnostics;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text.Json;
using DdhWebHost;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;
using War3DeathSettlement.Core;

namespace War3DeathSettlement.Desktop;

internal sealed class DesktopWindow : Form
{
    private const string AppHost = "ddh-desktop.local";
    private readonly DesktopRuntime _runtime = new();
    private readonly WebView2 _web = new() { Dock = DockStyle.Fill };
    private readonly System.Windows.Forms.Timer _timer = new() { Interval = 500 };
    private readonly JsonSerializerOptions _json = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping,
    };
    private int _sending;
    private bool _webReady;
    private string _lastCommandError = "";
    private string _lastSnapshotKey = "";
    private volatile string _viewingSession = "";

    public DesktopWindow()
    {
        Text = "魔兽死亡结算 Vue Desktop";
        Width = 1360;
        Height = 860;
        FormBorderStyle = FormBorderStyle.None;
        MinimumSize = new Size(980, 620);
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(17, 18, 15);
        ForeColor = Color.Gainsboro;
        Controls.Add(_web);

        Load += async (_, _) => await InitializeWebAsync();
        FormClosed += (_, _) =>
        {
            _timer.Stop();
            _runtime.Dispose();
        };
        Resize += (_, _) => PostWindowState();
        _timer.Tick += (_, _) => QueueSnapshot();
    }

    protected override CreateParams CreateParams
    {
        get
        {
            CreateParams parameters = base.CreateParams;
            parameters.Style |= 0x00040000; // WS_THICKFRAME，无边框窗口仍可从边缘调整大小
            return parameters;
        }
    }

    protected override void OnHandleCreated(EventArgs e)
    {
        base.OnHandleCreated(e);

        int darkMode = 1;
        DwmSetWindowAttribute(Handle, 20, ref darkMode, sizeof(int)); // DWMWA_USE_IMMERSIVE_DARK_MODE
        int borderColor = 0x000F1211; // COLORREF: RGB(17, 18, 15)
        DwmSetWindowAttribute(Handle, 34, ref borderColor, sizeof(int)); // DWMWA_BORDER_COLOR
    }

    private async Task InitializeWebAsync()
    {
        try
        {
            string data = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "War3DeathSettlement",
                "vue-desktop-webview2");
            Directory.CreateDirectory(data);

            var options = new CoreWebView2EnvironmentOptions(
                "--disable-backgrounding-occluded-windows " +
                "--disable-renderer-backgrounding");
            CoreWebView2Environment env =
                await CoreWebView2Environment.CreateAsync(null, data, options);
            await _web.EnsureCoreWebView2Async(env);

            CoreWebView2 core = _web.CoreWebView2;
            core.Settings.AreDefaultContextMenusEnabled = false;
            core.Settings.IsStatusBarEnabled = false;
            core.Settings.AreDevToolsEnabled = false;
            core.Settings.IsZoomControlEnabled = true;
            core.WebMessageReceived += OnWebMessage;
            core.AddWebResourceRequestedFilter(
                $"https://{AppHost}/*",
                CoreWebView2WebResourceContext.All);
            core.WebResourceRequested += OnWebResourceRequested;
            core.NavigationCompleted += (_, e) =>
            {
                if (!e.IsSuccess)
                {
                    Log.Error("Vue 桌面页面加载失败：" + e.WebErrorStatus);
                    return;
                }
                Log.Write("Vue 桌面页面加载完成");
                _webReady = true;
                QueueSnapshot();
                PostWindowState();
                _timer.Start();
            };
            core.Navigate($"https://{AppHost}/index.html");
        }
        catch (Exception ex)
        {
            Log.Error("初始化 WebView2 失败：" + ex);
            MessageBox.Show(
                "WebView2 初始化失败。\n\n请安装 Microsoft Edge WebView2 Runtime。\n\n" + ex.Message,
                "War3DeathSettlement",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            Close();
        }
    }

    private void OnWebResourceRequested(object? sender, CoreWebView2WebResourceRequestedEventArgs e)
    {
        try
        {
            var uri = new Uri(e.Request.Uri);
            string path = Uri.UnescapeDataString(uri.AbsolutePath).TrimStart('/');
            if (path.Length == 0) path = "index.html";
            Assembly assembly = typeof(DesktopWindow).Assembly;
            string wanted = "wwwroot/" + path.Replace('\\', '/');
            string resourceName = assembly.GetManifestResourceNames()
                .FirstOrDefault(x => x.Replace('\\', '/')
                    .Equals(wanted, StringComparison.OrdinalIgnoreCase))
                ?? wanted;
            using Stream? source = assembly.GetManifestResourceStream(resourceName);
            if (source == null)
            {
                if (!path.Equals("favicon.ico", StringComparison.OrdinalIgnoreCase))
                    Log.Warn("内嵌 Vue 资源不存在：" + resourceName);
                var empty = new MemoryStream(Array.Empty<byte>());
                e.Response = _web.CoreWebView2.Environment.CreateWebResourceResponse(
                    empty, 404, "Not Found", "Content-Type: text/plain\r\n");
                return;
            }

            var buffer = new MemoryStream();
            source.CopyTo(buffer);
            buffer.Position = 0;
            e.Response = _web.CoreWebView2.Environment.CreateWebResourceResponse(
                buffer,
                200,
                "OK",
                $"Content-Type: {ContentType(path)}\r\nCache-Control: no-store\r\n");
        }
        catch (Exception ex)
        {
            Log.Warn("加载内嵌 Vue 资源失败：" + ex.Message);
        }
    }

    private static string ContentType(string path) =>
        Path.GetExtension(path).ToLowerInvariant() switch
        {
            ".html" => "text/html; charset=utf-8",
            ".js" or ".mjs" => "text/javascript; charset=utf-8",
            ".css" => "text/css; charset=utf-8",
            ".json" => "application/json; charset=utf-8",
            ".svg" => "image/svg+xml",
            ".png" => "image/png",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".woff" => "font/woff",
            ".woff2" => "font/woff2",
            _ => "application/octet-stream",
        };

    private void OnWebMessage(object? sender, CoreWebView2WebMessageReceivedEventArgs e)
    {
        try
        {
            using JsonDocument doc = JsonDocument.Parse(e.WebMessageAsJson);
            JsonElement root = doc.RootElement;
            string type = root.TryGetProperty("type", out JsonElement typeElement)
                ? typeElement.GetString() ?? ""
                : "";
            if (type == "dss-ready")
            {
                QueueSnapshot();
                PostWindowState();
                return;
            }
            if (type == "dss-titlebar")
            {
                string titlebarAction = JsonString(root, "action");
                HandleTitlebarAction(titlebarAction);
                return;
            }
            if (type != "dss-command") return;

            string action = root.TryGetProperty("action", out JsonElement actionElement)
                ? actionElement.GetString() ?? ""
                : "";
            if (action is "settlement-page" or "event-page" or "settlement-detail")
            {
                RunDataCommand(root, action);
                return;
            }
            string sessionId = root.TryGetProperty("sessionId", out JsonElement sessionElement)
                ? sessionElement.GetString() ?? ""
                : "";
            RunCommand(action, sessionId);
        }
        catch (Exception ex)
        {
            Log.Warn("桌面命令解析失败：" + ex.Message);
        }
    }

    private void HandleTitlebarAction(string action)
    {
        void Execute()
        {
            if (IsDisposed) return;
            switch (action)
            {
                case "drag":
                    ReleaseCapture();
                    SendMessage(Handle, 0x00A1, (IntPtr)0x0002, IntPtr.Zero);
                    break;
                case "minimize":
                    WindowState = FormWindowState.Minimized;
                    break;
                case "toggle-maximize":
                    ToggleMaximize();
                    break;
                case "close":
                    Close();
                    break;
            }
            if (action is "minimize" or "toggle-maximize")
                PostWindowState();
        }

        if (InvokeRequired)
            BeginInvoke(new Action(Execute));
        else
            Execute();
    }

    private void ToggleMaximize()
    {
        if (WindowState == FormWindowState.Maximized)
        {
            WindowState = FormWindowState.Normal;
            return;
        }

        MaximizedBounds = Screen.FromControl(this).WorkingArea;
        WindowState = FormWindowState.Maximized;
    }

    private void PostWindowState()
    {
        PostMessage(new
        {
            type = "window-state",
            maximized = WindowState == FormWindowState.Maximized,
        });
    }

    private void RunCommand(string action, string sessionId)
    {
        switch (action)
        {
            case "find-game":
                Task.Run(() =>
                {
                    var result = _runtime.AttachGame();
                    PostCommandResult(result.Ok, result.Message);
                    if (result.Ok) QueueSnapshot();
                });
                break;

            case "open-logs":
                OpenPath(Path.GetDirectoryName(Log.Path) ?? Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "War3DeathSettlement",
                    "logs"));
                PostCommandResult(true, "");
                break;

            case "open-settings":
                OpenSettings();
                PostCommandResult(true, "");
                break;

            case "history-list":
                Task.Run(() =>
                {
                    try
                    {
                        var items = _runtime.ListHistory().Select(x => new
                        {
                            sessionId = x.SessionId,
                            mapName = x.MapName,
                            startedAt = x.StartedAt.LocalDateTime.ToString("yyyy-MM-dd HH:mm:ss"),
                            endedAt = x.EndedAt.LocalDateTime.ToString("yyyy-MM-dd HH:mm:ss"),
                            totalDamage = x.TotalDamage,
                            settlementCount = x.SettlementCount,
                            eventCount = x.EventCount,
                            unitCount = x.UnitCount,
                        }).ToList();
                        PostMessage(new { type = "history-list", items, error = "" });
                    }
                    catch (Exception ex)
                    {
                        PostMessage(new { type = "history-list", items = Array.Empty<object>(), error = ex.Message });
                    }
                    finally
                    {
                        PostCommandResult(true, "");
                    }
                });
                break;

            case "history-load":
                if (string.IsNullOrWhiteSpace(sessionId))
                {
                    PostCommandResult(false, "历史会话 ID 为空");
                    break;
                }
                Task.Run(() =>
                {
                    try
                    {
                        _viewingSession = sessionId;
                        SettlementSnapshot snapshot = _runtime.BuildHistorySnapshot(sessionId);
                        PostSnapshot(snapshot, force: true);
                        PostCommandResult(true, "");
                    }
                    catch (Exception ex)
                    {
                        PostCommandResult(false, "读取历史失败：" + ex.Message);
                    }
                });
                break;

            case "resume-live":
                _viewingSession = "";
                QueueSnapshot();
                PostCommandResult(true, "");
                break;

            default:
                PostCommandResult(false, "未知命令：" + action);
                break;
        }
    }

    private void RunDataCommand(JsonElement root, string action)
    {
        string sessionId = JsonString(root, "sessionId");
        long requestId = JsonLong(root, "requestId");
        if (action == "settlement-page")
        {
            string query = JsonString(root, "query");
            int page = (int)JsonLong(root, "page");
            int pageSize = (int)JsonLong(root, "pageSize", 200);
            string victimCode = JsonString(root, "victimCode");
            Task.Run(() =>
            {
                SettlementPage result;
                try
                {
                    result = SnapshotReader.ReadSettlementPage(
                        DdhEventDb.FixedPath,
                        sessionId,
                        query,
                        page,
                        pageSize,
                        victimCode,
                        requestId);
                }
                catch (Exception ex)
                {
                    result = new SettlementPage
                    {
                        RequestId = requestId,
                        Page = Math.Max(0, page),
                        PageSize = Math.Clamp(pageSize, 50, 500),
                        Error = "读取死亡结算页失败：" + ex.Message,
                    };
                }
                PostMessage(result);
            });
            return;
        }

        if (action == "event-page")
        {
            string query = JsonString(root, "query");
            int page = (int)JsonLong(root, "page");
            int pageSize = (int)JsonLong(root, "pageSize", 500);
            string victimCode = JsonString(root, "victimCode");
            bool victimIllusion = JsonBool(root, "victimIllusion");
            string sourceCode = JsonString(root, "sourceCode");
            bool sourceIllusion = JsonBool(root, "sourceIllusion");
            Task.Run(() =>
            {
                EventPage result;
                try
                {
                    result = SnapshotReader.ReadEventPage(
                        DdhEventDb.FixedPath,
                        sessionId,
                        query,
                        page,
                        pageSize,
                        victimCode,
                        victimIllusion,
                        sourceCode,
                        sourceIllusion,
                        requestId);
                }
                catch (Exception ex)
                {
                    result = new EventPage
                    {
                        RequestId = requestId,
                        Page = Math.Max(0, page),
                        PageSize = Math.Max(50, pageSize),
                        Error = "读取事件页失败：" + ex.Message,
                    };
                }
                PostMessage(result);
            });
            return;
        }

        long seq = JsonLong(root, "seq");
        Task.Run(() =>
        {
            SettlementDetail result;
            try
            {
                result = SnapshotReader.ReadSettlementDetail(
                    DdhEventDb.FixedPath,
                    sessionId,
                    seq,
                    requestId);
            }
            catch (Exception ex)
            {
                result = new SettlementDetail
                {
                    RequestId = requestId,
                    Seq = seq,
                    Error = "读取死亡明细失败：" + ex.Message,
                };
            }
            PostMessage(result);
        });
    }

    private static string JsonString(JsonElement root, string name)
    {
        if (!root.TryGetProperty(name, out JsonElement value)) return "";
        return value.ValueKind == JsonValueKind.String ? value.GetString() ?? "" : "";
    }

    private static long JsonLong(JsonElement root, string name, long fallback = 0)
    {
        if (!root.TryGetProperty(name, out JsonElement value)) return fallback;
        return value.ValueKind == JsonValueKind.Number && value.TryGetInt64(out long number)
            ? number
            : fallback;
    }

    private static bool JsonBool(JsonElement root, string name, bool fallback = false)
    {
        if (!root.TryGetProperty(name, out JsonElement value)) return fallback;
        if (value.ValueKind is JsonValueKind.True or JsonValueKind.False)
            return value.GetBoolean();
        return value.ValueKind == JsonValueKind.Number &&
               value.TryGetInt64(out long number) &&
               number != 0;
    }

    private void OpenSettings()
    {
        try
        {
            Process.Start(new ProcessStartInfo(
                "notepad.exe",
                QuoteArgument(Settings.DefaultPath))
            {
                UseShellExecute = true,
            });
        }
        catch (Exception ex)
        {
            Log.Warn("打开设置失败：" + ex.Message);
        }
    }

    private static string QuoteArgument(string value)
    {
        if (value.Length == 0) return "\"\"";
        if (value.IndexOfAny(new[] { ' ', '\t', '"' }) < 0) return value;
        return "\"" + value.Replace("\"", "\\\"") + "\"";
    }

    private void OpenPath(string path)
    {
        try
        {
            Directory.CreateDirectory(path);
            Process.Start(new ProcessStartInfo(path) { UseShellExecute = true });
        }
        catch (Exception ex)
        {
            Log.Warn("打开目录失败：" + ex.Message);
        }
    }

    private void QueueSnapshot()
    {
        if (!_webReady) return;
        if (_viewingSession.Length > 0) return;
        if (Interlocked.CompareExchange(ref _sending, 1, 0) != 0) return;
        Task.Run(() =>
        {
            try
            {
                SettlementSnapshot snapshot = _runtime.BuildLiveSnapshot();
                PostSnapshot(snapshot);
            }
            catch (Exception ex)
            {
                PostCommandResult(false, "生成界面快照失败：" + ex.Message);
            }
            finally
            {
                Interlocked.Exchange(ref _sending, 0);
            }
        });
    }

    private void PostSnapshot(SettlementSnapshot snapshot, bool force = false)
    {
        string key = SnapshotKey(snapshot);
        if (!force && string.Equals(key, _lastSnapshotKey, StringComparison.Ordinal)) return;
        _lastSnapshotKey = key;
        PostMessage(snapshot);
    }

    private static string SnapshotKey(SettlementSnapshot snapshot)
    {
        DesktopState? desktop = snapshot.Desktop;
        return string.Join(
            "\u0001",
            snapshot.SessionId,
            snapshot.EventRevision,
            snapshot.Counts.Settlements,
            snapshot.Counts.Events,
            snapshot.Counts.Units,
            snapshot.SessionRevision,
            snapshot.SessionUpdatedAt,
            snapshot.MapName,
            snapshot.Message,
            desktop?.Mode,
            desktop?.Status,
            desktop?.ScanCount,
            desktop?.HookStatus,
            desktop?.Ready);
    }

    private void PostCommandResult(bool ok, string error)
    {
        if (!ok && error.Length > 0 && error != _lastCommandError)
        {
            _lastCommandError = error;
            Log.Warn(error);
        }
        PostMessage(new { type = "command-result", busy = false, ok, error });
    }

    private void PostMessage(object value)
    {
        if (!_webReady || IsDisposed) return;
        string json = JsonSerializer.Serialize(value, _json);
        try
        {
            if (InvokeRequired)
                BeginInvoke(new Action(() => _web.CoreWebView2.PostWebMessageAsJson(json)));
            else
                _web.CoreWebView2.PostWebMessageAsJson(json);
        }
        catch (Exception ex)
        {
            Log.Warn("向 Vue 推送消息失败：" + ex.Message);
        }
    }

    [DllImport("user32.dll")]
    private static extern bool ReleaseCapture();

    [DllImport("user32.dll")]
    private static extern IntPtr SendMessage(IntPtr window, int message, IntPtr wParam, IntPtr lParam);

    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(
        IntPtr window,
        int attribute,
        ref int value,
        int valueSize);
}
