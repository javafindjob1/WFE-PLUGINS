using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.Globalization;
using System.IO.MemoryMappedFiles;
using System.Runtime.InteropServices;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace DdhWebHost;

internal static class Program
{
    private const int HeaderBytes = 64;
    private const int InputBytes = 64;
    private const int Magic = 0x31484844; // 'DHH1'
    private const string HtmlPath = @"C:\launch\ddh_web\dss.html";

    private static int _pid;
    private static string _html = HtmlPath;
    private static string _database = DefaultDatabasePath();
    private static int _width = 1200;
    private static int _height = 760;
    private static string _mapName = "";
    private static string _dump = "";
    private static string _sessionId = "";
    private static string _buildMarker = "";
    private static string _uri = "";
    private static string _logPath = @"C:\launch\ddh-web.txt";
    private static string _userData = "";
    private static int _fps = 60;
    private static int _dataHz = 2;

    private static MemoryMappedFile? _mmf;
    private static MemoryMappedViewAccessor? _view;
    private static WebView2? _web;
    private static Form? _form;
    private static byte[]? _frame;
    private static int _seq;
    private static bool _navigated;
    private static bool _loopsStarted;
    private static bool _navigationRetryPending;
    private static int _navigationAttempts;
    private static System.Windows.Forms.Timer? _captureTimer;
    private static System.Windows.Forms.Timer? _dataTimer;
    private static System.Windows.Forms.Timer? _inputTimer;
    private static System.Windows.Forms.Timer? _navigationRetryTimer;
    private static int _sendingSnapshot;
    private static int _processingInput;
    private static int _lastInputSequence;
    private static int _lastClickSequence;
    private static int _lastWheelSequence;
    private static int _lastTextSequence;
    private static int _lastPointerX = -1;
    private static int _lastPointerY = -1;
    private static int _lastPointerButtons = -1;
    private static int _viewportWidth = 1200;
    private static int _viewportHeight = 760;
    private static bool _cdpPointerHeld;
    private static string _lastSnapshotKey = "";
    private static volatile bool _textFocused;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping,
    };

    [STAThread]
    private static void Main(string[] args)
    {
        try
        {
            _logPath = Arg(args, "--log", _logPath);
            _pid = int.Parse(Arg(args, "--pid", "0"));
            _html = Arg(args, "--html", HtmlPath);
            _database = Arg(args, "--db", DefaultDatabasePath());
            _width = Math.Clamp(int.Parse(Arg(args, "--w", "1200")), 320, 1600);
            _height = Math.Clamp(int.Parse(Arg(args, "--h", "760")), 240, 1200);
            _dump = Arg(args, "--dump", "");
            _fps = Math.Clamp(int.Parse(Arg(args, "--fps", "60")), 1, 60);
            _dataHz = Math.Clamp(int.Parse(Arg(args, "--data-hz", "2")), 1, 10);
            _userData = Arg(args, "--user-data", "");
            _mapName = Arg(args, "--map", "");
            if (_mapName.Length == 0) _mapName = "Local\\DdhHtml_" + _pid;
            _sessionId = Arg(args, "--session", "");
            _buildMarker = Arg(args, "--ddh-marker", "");
            PersistBuildMarker();

            Log($"start html={_html} size={_width}x{_height} db={_database} map={_mapName} session={_sessionId}");
            if (!File.Exists(_html))
            {
                Log("HTML missing: " + _html);
                return;
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            _form = new Form
            {
                Text = "ddh_web",
                FormBorderStyle = FormBorderStyle.None,
                ShowInTaskbar = false,
                StartPosition = FormStartPosition.Manual,
                Location = new Point(-32000, -32000),
                Size = new Size(_width, _height),
                BackColor = Color.Black,
            };
            _web = new WebView2 { Dock = DockStyle.Fill };
            _form.Controls.Add(_web);
            _form.Load += async (_, _) => await InitAsync();
            _form.Shown += (_, _) => _form.Location = new Point(-32000, -32000);
            _form.FormClosed += (_, _) => StopTimers();

            if (_pid > 0 && _dump.Length == 0)
            {
                var watcher = new Thread(() =>
                {
                    while (true)
                    {
                        Thread.Sleep(1000);
                        try { Process.GetProcessById(_pid); }
                        catch
                        {
                            Log("game process gone, exiting");
                            SafeQuit();
                            return;
                        }
                    }
                }) { IsBackground = true };
                watcher.Start();
            }

            Application.Run(_form);
            CleanupUserData();
        }
        catch (Exception ex)
        {
            Log("fatal: " + ex);
        }
    }

    private static void PersistBuildMarker()
    {
        if (_buildMarker.Length != 1) return;
        char marker = char.ToUpperInvariant(_buildMarker[0]);
        if (marker < 'A' || marker > 'S') return;
        string dir = @"C:\Users\Public\Documents\War3DeathSettlement";
        Directory.CreateDirectory(dir);
        File.WriteAllText(Path.Combine(dir, "ddh-button-seq.txt"), marker.ToString());
        Log("button marker persisted: " + marker);
    }

    private static async Task InitAsync()
    {
        try
        {
            if (_userData.Length == 0)
            {
                _userData = Path.Combine(
                    @"C:\Users\Public\Documents\War3DeathSettlement", "wv2",
                    $"{_pid}-{Environment.ProcessId}");
            }
            Directory.CreateDirectory(_userData);
            Log("webview profile " + _userData);
            var options = new CoreWebView2EnvironmentOptions(
                "--disable-backgrounding-occluded-windows " +
                "--disable-renderer-backgrounding " +
                "--disable-features=CalculateNativeWinOcclusion");
            CoreWebView2Environment env = await CoreWebView2Environment.CreateAsync(null, _userData, options);
            WebView2 web = _web ?? throw new InvalidOperationException("WebView2 尚未创建");
            await web.EnsureCoreWebView2Async(env);
            Log("webview ready: " + web.CoreWebView2.Environment.BrowserVersionString);

            web.CoreWebView2.Settings.AreDefaultContextMenusEnabled = false;
            web.CoreWebView2.Settings.IsStatusBarEnabled = false;
            web.CoreWebView2.Settings.AreDevToolsEnabled = false;
            web.CoreWebView2.WebMessageReceived += (_, e) =>
            {
                try
                {
                    using JsonDocument message = JsonDocument.Parse(e.WebMessageAsJson);
                    JsonElement root = message.RootElement;
                    string type = JsonString(root, "type");
                    if (type == "ddh-focus" &&
                        root.TryGetProperty("focused", out JsonElement focused))
                    {
                        _textFocused = focused.ValueKind == JsonValueKind.True;
                    }
                    else if (type == "dss-ready")
                    {
                        SendSnapshot();
                    }
                    else if (type == "dss-command")
                    {
                        HandleDataCommand(root);
                    }
                }
                catch (Exception ex) { Log("web message failed: " + ex.Message); }
            };
            web.CoreWebView2.NavigationCompleted += async (_, e) =>
            {
                Log($"navigation completed ok={e.IsSuccess} err={e.WebErrorStatus}");
                if (!e.IsSuccess)
                {
                    _navigated = false;
                    ScheduleNavigationRetry();
                    return;
                }

                _navigated = true;
                _navigationRetryPending = false;
                _navigationAttempts = 0;
                await RefreshViewportAsync();
                SendSnapshot();
                if (_dump.Length > 0) StartDumpOnce();
                else if (!_loopsStarted)
                {
                    _loopsStarted = true;
                    StartCaptureLoop();
                    StartDataLoop();
                    StartInputLoop();
                }
            };

            Uri uri;
            if (Uri.TryCreate(_html, UriKind.Absolute, out Uri? absolute) &&
                (absolute.Scheme is "http" or "https"))
            {
                uri = absolute;
            }
            else
            {
                string fullPath = Path.GetFullPath(_html);
                string folder = Path.GetDirectoryName(fullPath)
                    ?? throw new InvalidOperationException("HTML 目录无效");
                web.CoreWebView2.SetVirtualHostNameToFolderMapping(
                    "ddh-ui.local",
                    folder,
                    CoreWebView2HostResourceAccessKind.Allow);
                uri = new Uri("https://ddh-ui.local/" + Uri.EscapeDataString(Path.GetFileName(fullPath)));
            }
            Log("navigate " + uri);
            _uri = uri.ToString();
            web.CoreWebView2.Navigate(_uri);
        }
        catch (Exception ex)
        {
            Log("init failed: " + ex);
            SafeQuit();
        }
    }

    private static void ScheduleNavigationRetry()
    {
        if (_navigationRetryPending || _web?.CoreWebView2 == null) return;
        int attempt = ++_navigationAttempts;
        if (attempt > 5)
        {
            Log($"navigation failed {attempt - 1} times; restarting host");
            SafeQuit();
            return;
        }

        _navigationRetryPending = true;
        int delay = Math.Min(5000, 500 * attempt);
        Log($"navigation retry {attempt}/5 in {delay} ms");
        _navigationRetryTimer = new System.Windows.Forms.Timer { Interval = delay };
        _navigationRetryTimer.Tick += (_, _) =>
        {
            _navigationRetryTimer?.Stop();
            _navigationRetryTimer?.Dispose();
            _navigationRetryTimer = null;
            _navigationRetryPending = false;
            if (_web?.CoreWebView2 != null && _uri.Length > 0)
                _web.CoreWebView2.Navigate(_uri);
        };
        _navigationRetryTimer.Start();
    }

    private static void StartDataLoop()
    {
        _dataTimer = new System.Windows.Forms.Timer { Interval = Math.Max(100, 1000 / _dataHz) };
        _dataTimer.Tick += (_, _) => SendSnapshot();
        _dataTimer.Start();
    }

    private static void SendSnapshot()
    {
        if (!_navigated || _web?.CoreWebView2 == null) return;
        if (Interlocked.CompareExchange(ref _sendingSnapshot, 1, 0) != 0) return;

        Task.Run(() =>
        {
            SettlementSnapshot snapshot;
            try
            {
                snapshot = SnapshotReader.Read(_database, _pid, _sessionId);
            }
            catch (Exception ex)
            {
                snapshot = new SettlementSnapshot
                {
                    GeneratedAt = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"),
                    Pid = Math.Max(0, _pid),
                    DatabasePath = _database,
                    Message = "SQLite 读取失败：" + ex.Message,
                };
            }
            string json = JsonSerializer.Serialize(snapshot, JsonOptions);
            string key = SnapshotKey(snapshot);
            if (string.Equals(key, _lastSnapshotKey, StringComparison.Ordinal))
            {
                Interlocked.Exchange(ref _sendingSnapshot, 0);
                return;
            }
            PostJson(json, () => _lastSnapshotKey = key, releaseSnapshot: true);
        });
    }

    private static void HandleDataCommand(JsonElement root)
    {
        string action = JsonString(root, "action");
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
                        _database,
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
                PostJson(JsonSerializer.Serialize(result, JsonOptions));
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
                        _database,
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
                PostJson(JsonSerializer.Serialize(result, JsonOptions));
            });
            return;
        }

        if (action == "settlement-detail")
        {
            long seq = JsonLong(root, "seq");
            Task.Run(() =>
            {
                SettlementDetail result;
                try
                {
                    result = SnapshotReader.ReadSettlementDetail(
                        _database,
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
                PostJson(JsonSerializer.Serialize(result, JsonOptions));
            });
        }
    }

    private static string SnapshotKey(SettlementSnapshot snapshot) =>
        string.Join(
            "\u0001",
            snapshot.SessionId,
            snapshot.EventRevision,
            snapshot.Counts.Settlements,
            snapshot.Counts.Events,
            snapshot.Counts.Units,
            snapshot.SessionRevision,
            snapshot.SessionUpdatedAt,
            snapshot.MapName,
            snapshot.Message);

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

    private static void PostJson(
        string json,
        Action? onPosted = null,
        bool releaseSnapshot = false)
    {
        try
        {
            _form?.BeginInvoke(new Action(() =>
            {
                try
                {
                    if (_navigated)
                    {
                        _web?.CoreWebView2?.PostWebMessageAsJson(json);
                        onPosted?.Invoke();
                    }
                }
                catch (Exception ex) { Log("post message failed: " + ex.Message); }
                finally
                {
                    if (releaseSnapshot) Interlocked.Exchange(ref _sendingSnapshot, 0);
                }
            }));
        }
        catch
        {
            if (releaseSnapshot) Interlocked.Exchange(ref _sendingSnapshot, 0);
        }
    }

    private static async void StartDumpOnce()
    {
        try
        {
            await Task.Delay(1200);
            SendSnapshot();
            await Task.Delay(900);
            for (int i = 0; i < 6; i++)
            {
                if (await CaptureAsync())
                {
                    using Bitmap bitmap = FrameToBitmap();
                    bitmap.Save(_dump, ImageFormat.Png);
                    Log("dumped " + _dump);
                    SafeQuit();
                    return;
                }
                await Task.Delay(400);
            }
            Log("dump failed");
        }
        catch (Exception ex)
        {
            Log("dump fatal: " + ex);
        }
        SafeQuit();
    }

    private static Bitmap FrameToBitmap()
    {
        var bitmap = new Bitmap(_width, _height, PixelFormat.Format32bppArgb);
        BitmapData data = bitmap.LockBits(
            new Rectangle(0, 0, _width, _height),
            ImageLockMode.WriteOnly,
            PixelFormat.Format32bppArgb);
        try { Marshal.Copy(_frame!, 0, data.Scan0, _frame!.Length); }
        finally { bitmap.UnlockBits(data); }
        return bitmap;
    }

    private static async Task<bool> CaptureAsync()
    {
        if (_web?.CoreWebView2 == null) return false;
        using var stream = new MemoryStream();
        await _web.CoreWebView2.CapturePreviewAsync(CoreWebView2CapturePreviewImageFormat.Png, stream);
        if (stream.Length < 100) return false;
        stream.Position = 0;
        using var source = new Bitmap(stream);
        using var scaled = new Bitmap(_width, _height, PixelFormat.Format32bppArgb);
        using (Graphics graphics = Graphics.FromImage(scaled))
        {
            graphics.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBilinear;
            graphics.DrawImage(source, new Rectangle(0, 0, _width, _height));
        }
        _frame ??= new byte[_width * _height * 4];
        BitmapData data = scaled.LockBits(
            new Rectangle(0, 0, _width, _height),
            ImageLockMode.ReadOnly,
            PixelFormat.Format32bppArgb);
        try { Marshal.Copy(data.Scan0, _frame, 0, _frame.Length); }
        finally { scaled.UnlockBits(data); }
        return true;
    }

    private static void Publish()
    {
        if (_mmf == null)
        {
            int size = HeaderBytes + _width * _height * 4 + InputBytes;
            _mmf = MemoryMappedFile.CreateOrOpen(_mapName, size);
            _view = _mmf.CreateViewAccessor(0, size);
            _view.Write(0, Magic);
            _view.Write(4, _width);
            _view.Write(8, _height);
            _view.Write(12, 0);
            Log($"mapped {_mapName} {size} bytes");
        }
        _view!.WriteArray(HeaderBytes, _frame!, 0, _frame!.Length);
        _seq++;
        _view.Write(12, _seq);
        _view.Write(16, Environment.TickCount);
    }

    private static void StartInputLoop()
    {
        int inputOffset = HeaderBytes + _width * _height * 4;
        _lastTextSequence = _view?.ReadInt32(inputOffset + 28) ?? 0;
        _inputTimer = new System.Windows.Forms.Timer { Interval = 50 };
        _inputTimer.Tick += async (_, _) =>
        {
            if (_view == null || _web?.CoreWebView2 == null) return;
            if (Interlocked.CompareExchange(ref _processingInput, 1, 0) != 0) return;
            try
            {
                _view.Write(inputOffset + 36, _textFocused ? 1 : 0);
                int textSequence = _view.ReadInt32(inputOffset + 28);
                if (textSequence != _lastTextSequence)
                {
                    int textCode = _view.ReadInt32(inputOffset + 32);
                    if (_view.ReadInt32(inputOffset + 28) == textSequence)
                    {
                        _lastTextSequence = textSequence;
                        try
                        {
                            await _web.CoreWebView2.ExecuteScriptAsync(
                                $"window.__ddhText && window.__ddhText({textCode});");
                        }
                        catch (Exception ex) { Log("input text failed: " + ex.Message); }
                    }
                }
                int sequence = _view.ReadInt32(inputOffset);
                if (sequence == _lastInputSequence) return;
                int clickSequence = _view.ReadInt32(inputOffset + 12);
                int wheelSequence = _view.ReadInt32(inputOffset + 16);
                int wheelDelta = _view.ReadInt32(inputOffset + 20);
                int buttons = _view.ReadInt32(inputOffset + 24);
                int normalizedX = _view.ReadInt32(inputOffset + 40);
                int normalizedY = _view.ReadInt32(inputOffset + 44);
                if (_view.ReadInt32(inputOffset) != sequence) return;
                _lastInputSequence = sequence;

                bool changed = normalizedX != _lastPointerX ||
                               normalizedY != _lastPointerY ||
                               buttons != _lastPointerButtons;
                bool releasedThisTick = false;
                if (changed)
                {
                    await DispatchScrollPointerAsync(normalizedX, normalizedY, buttons);
                    if (buttons > 0 && _lastPointerButtons <= 0)
                    {
                        Log($"input press norm={normalizedX},{normalizedY}");
                        await DispatchMouseAsync("mouseMoved", normalizedX, normalizedY, 0);
                        await DispatchMouseAsync("mousePressed", normalizedX, normalizedY, 1);
                        _cdpPointerHeld = true;
                    }
                    else if (buttons <= 0 && _lastPointerButtons > 0)
                    {
                        Log($"input release norm={normalizedX},{normalizedY}");
                        await DispatchMouseAsync("mouseMoved", normalizedX, normalizedY, 1);
                        await DispatchMouseAsync("mouseReleased", normalizedX, normalizedY, 0);
                        _cdpPointerHeld = false;
                        releasedThisTick = true;
                    }
                    else
                    {
                        await DispatchMouseAsync("mouseMoved", normalizedX, normalizedY, buttons);
                    }
                    _lastPointerX = normalizedX;
                    _lastPointerY = normalizedY;
                    _lastPointerButtons = buttons;
                }

                if (clickSequence != _lastClickSequence)
                {
                    _lastClickSequence = clickSequence;
                    if (!_cdpPointerHeld && !releasedThisTick)
                    {
                        await DispatchMouseAsync("mouseMoved", normalizedX, normalizedY, 0);
                        await DispatchMouseAsync("mousePressed", normalizedX, normalizedY, 1);
                        await DispatchMouseAsync("mouseReleased", normalizedX, normalizedY, 0);
                    }
                }
                if (wheelSequence != _lastWheelSequence)
                {
                    _lastWheelSequence = wheelSequence;
                    Log($"input wheel norm={normalizedX},{normalizedY} delta={wheelDelta}");
                    await DispatchMouseWheelAsync(normalizedX, normalizedY, wheelDelta);
                }
            }
            catch (Exception ex) { Log("input dispatch failed: " + ex.Message); }
            finally { Interlocked.Exchange(ref _processingInput, 0); }
        };
        _inputTimer.Start();
    }

    private static async Task RefreshViewportAsync()
    {
        try
        {
            string output = await _web!.CoreWebView2.ExecuteScriptAsync(
                "JSON.stringify({width:window.innerWidth,height:window.innerHeight,dpr:window.devicePixelRatio})");
            string? json = JsonSerializer.Deserialize<string>(output);
            if (json == null) return;
            using var document = JsonDocument.Parse(json);
            JsonElement root = document.RootElement;
            int width = (int)root.GetProperty("width").GetDouble();
            int height = (int)root.GetProperty("height").GetDouble();
            double dpr = root.GetProperty("dpr").GetDouble();
            if (width > 0) _viewportWidth = width;
            if (height > 0) _viewportHeight = height;
            Log($"viewport {_viewportWidth}x{_viewportHeight} dpr={dpr:0.##}");
        }
        catch (Exception ex)
        {
            Log("viewport probe failed: " + ex.Message);
        }
    }

    private static async Task DispatchMouseAsync(
        string type, int normalizedX, int normalizedY, int buttons)
    {
        if (_web?.CoreWebView2 == null) return;
        double x = normalizedX / 10000.0 * _viewportWidth;
        double y = normalizedY / 10000.0 * _viewportHeight;
        var payload = new Dictionary<string, object?>
        {
            ["type"] = type,
            ["x"] = x,
            ["y"] = y,
            ["button"] = type is "mousePressed" or "mouseReleased" ? "left" : "none",
            ["buttons"] = buttons,
            ["clickCount"] = type is "mousePressed" or "mouseReleased" ? 1 : 0,
            ["pointerType"] = "mouse",
        };
        await _web.CoreWebView2.CallDevToolsProtocolMethodAsync(
            "Input.dispatchMouseEvent",
            JsonSerializer.Serialize(payload, JsonOptions));
    }

    private static async Task DispatchScrollPointerAsync(
        int normalizedX, int normalizedY, int buttons)
    {
        if (_web?.CoreWebView2 == null) return;
        double x = normalizedX / 10000.0 * _viewportWidth;
        double y = normalizedY / 10000.0 * _viewportHeight;
        string js =
            $"window.__ddhPointer && window.__ddhPointer(" +
            $"{x.ToString("0.###", CultureInfo.InvariantCulture)}," +
            $"{y.ToString("0.###", CultureInfo.InvariantCulture)},{buttons});";
        await _web.CoreWebView2.ExecuteScriptAsync(js);
    }

    private static async Task DispatchMouseWheelAsync(
        int normalizedX, int normalizedY, int wheelDelta)
    {
        if (_web?.CoreWebView2 == null) return;
        double x = normalizedX / 10000.0 * _viewportWidth;
        double y = normalizedY / 10000.0 * _viewportHeight;
        var payload = new Dictionary<string, object?>
        {
            ["type"] = "mouseWheel",
            ["x"] = x,
            ["y"] = y,
            ["deltaX"] = 0,
            ["deltaY"] = wheelDelta > 0 ? -120 : 120,
            ["pointerType"] = "mouse",
        };
        await _web.CoreWebView2.CallDevToolsProtocolMethodAsync(
            "Input.dispatchMouseEvent",
            JsonSerializer.Serialize(payload, JsonOptions));
    }

    private static void StartCaptureLoop()
    {
        _captureTimer = new System.Windows.Forms.Timer { Interval = Math.Max(1, 1000 / _fps) };
        _captureTimer.Tick += async (_, _) =>
        {
            _captureTimer.Stop();
            try
            {
                if (_navigated && await CaptureAsync()) Publish();
            }
            catch (Exception ex) { Log("capture failed: " + ex.Message); }
            finally { _captureTimer.Start(); }
        };
        _captureTimer.Start();
        Log($"capture loop started at {_fps} fps; data refresh {_dataHz} Hz");
    }

    private static void StopTimers()
    {
        _captureTimer?.Stop();
        _dataTimer?.Stop();
        _captureTimer?.Dispose();
        _dataTimer?.Dispose();
        _inputTimer?.Stop();
        _inputTimer?.Dispose();
        _navigationRetryTimer?.Stop();
        _navigationRetryTimer?.Dispose();
        _navigationRetryTimer = null;
        _view?.Dispose();
        _mmf?.Dispose();
    }

    private static void SafeQuit()
    {
        try { _form?.BeginInvoke(new Action(Application.Exit)); } catch { }
    }

    private static void CleanupUserData()
    {
        if (_userData.Length == 0) return;
        for (int attempt = 0; attempt < 5; attempt++)
        {
            try
            {
                Directory.Delete(_userData, recursive: true);
                return;
            }
            catch
            {
                if (attempt < 4) Thread.Sleep(100);
            }
        }
    }

    private static string Arg(string[] args, string name, string fallback)
    {
        for (int i = 0; i < args.Length - 1; i++)
        {
            if (string.Equals(args[i], name, StringComparison.OrdinalIgnoreCase))
                return args[i + 1];
        }
        return fallback;
    }

    private static string DefaultDatabasePath()
    {
        return Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "War3DeathSettlement", "ddh", "ddh-events.db");
    }

    private static void Log(string message)
    {
        string line = $"[{DateTime.Now:HH:mm:ss.fff}] [{_pid}] {message}\r\n";
        foreach (string path in new[] { _logPath, Path.Combine(AppContext.BaseDirectory, "ddh-web.log") })
        {
            try
            {
                File.AppendAllText(path, line);
                return;
            }
            catch { }
        }
    }
}
