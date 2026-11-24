using System.Runtime.InteropServices;
using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>
/// Windows 自带 SQLite（<c>winsqlite3.dll</c>）的<b>最小 P/Invoke 封装</b>——不引任何 NuGet 包。
///
/// 为什么用它：Win8 起系统盘 <c>C:\Windows\System32\winsqlite3.dll</c> 自带（Win10/11 实测存在），
/// 本机离线、又不想为了存 20~30MB/局的 JSON 去拉 Microsoft.Data.Sqlite 的依赖树。
///
/// 约定：
///   · 文本一律 UTF-8（winsqlite3 默认编码就是 UTF-8）；绑定字符串用 SQLITE_TRANSIENT 让 SQLite 自己拷贝；
///   · 每次操作单独开连接（open/close 很便宜），并用 <see cref="SqliteConnection"/> 内的锁串行化；
///   · <b>所有入口都 try/catch</b>：失败返回 false + 错误文本，绝不把异常抛给界面。
/// </summary>
public static class Sqlite
{
    internal const string Lib = "winsqlite3.dll";

    internal const int Ok = 0;
    internal const int Row = 100;
    internal const int Done = 101;

    internal const int OpenReadWrite = 0x00000002;
    internal const int OpenCreate = 0x00000004;
    internal const int OpenFullMutex = 0x00010000;

    /// <summary>SQLITE_TRANSIENT = (sqlite3_destructor_type)-1：让 SQLite 立刻复制一份绑定值。</summary>
    internal static readonly IntPtr Transient = new(-1);

    private static readonly object ProbeGate = new();
    private static int _probe;          // 0 = 还没探测，1 = 可用，2 = 不可用
    private static string _probeError = "";
    private static string _version = "";

    /// <summary>winsqlite3.dll 能不能用（第一次访问时探测一次并缓存）。</summary>
    public static bool Available
    {
        get
        {
            if (Volatile.Read(ref _probe) == 0) Probe();
            return Volatile.Read(ref _probe) == 1;
        }
    }

    /// <summary>不可用时的原因（可用时为空串）。</summary>
    public static string Error
    {
        get
        {
            if (Volatile.Read(ref _probe) == 0) Probe();
            lock (ProbeGate) return _probeError;
        }
    }

    /// <summary>SQLite 版本号（例如 "3.53.4"；不可用返回空串）。</summary>
    public static string Version
    {
        get
        {
            if (Volatile.Read(ref _probe) == 0) Probe();
            lock (ProbeGate)
            {
                if (_probe == 1) return _version;
            }
            try
            {
                IntPtr p = NativeSqlite.sqlite3_libversion();
                return p == IntPtr.Zero ? "" : (Marshal.PtrToStringUTF8(p) ?? "");
            }
            catch
            {
                return "";
            }
        }
    }

    /// <summary>自检用：清掉探测结果，让下一次访问重新探测。</summary>
    internal static void ResetProbe()
    {
        lock (ProbeGate)
        {
            Volatile.Write(ref _probe, 0);
            _probeError = "";
            _version = "";
        }
    }

    private static void Probe()
    {
        lock (ProbeGate)
        {
            if (_probe != 0) return;
            try
            {
                IntPtr p = NativeSqlite.sqlite3_libversion();
                string version = p == IntPtr.Zero ? "" : (Marshal.PtrToStringUTF8(p) ?? "");
                if (version.Length == 0)
                {
                    _probeError = "winsqlite3.dll 已加载但 sqlite3_libversion 返回空";
                    Volatile.Write(ref _probe, 2);
                    return;
                }
                _version = version;
                _probeError = "";
                Volatile.Write(ref _probe, 1);
            }
            catch (Exception ex)
            {
                _probeError = ex is DllNotFoundException
                    ? "找不到 winsqlite3.dll（Win8 以下 / 系统被精简）"
                    : ex.GetType().Name + "：" + ex.Message;
                Volatile.Write(ref _probe, 2);
            }
        }
    }
}

/// <summary>一条打开的 SQLite 连接（自己开、自己关；不做连接池）。</summary>
public sealed class SqliteConnection : IDisposable
{
    private readonly object _gate = new();
    private IntPtr _db;
    private string _lastError = "";

    public string LastError
    {
        get { lock (_gate) return _lastError; }
    }

    public bool IsOpen
    {
        get { lock (_gate) return _db != IntPtr.Zero; }
    }

    /// <summary>打开（不存在则创建）一个库文件；失败返回 null 并给出原因（不抛异常）。</summary>
    public static SqliteConnection? Open(string path, out string error)
    {
        error = "";
        try
        {
            byte[] name = Encoding.UTF8.GetBytes(path + "\0");
            int flags = Sqlite.OpenReadWrite | Sqlite.OpenCreate | Sqlite.OpenFullMutex;
            int rc = NativeSqlite.sqlite3_open_v2(name, out IntPtr db, flags, IntPtr.Zero);
            if (rc != Sqlite.Ok || db == IntPtr.Zero)
            {
                string why = db != IntPtr.Zero ? NativeSqlite.Errmsg(db) : "";
                error = $"打开 SQLite 库失败（rc={rc}）{(why.Length > 0 ? "：" + why : "")}";
                if (db != IntPtr.Zero) NativeSqlite.sqlite3_close_v2(db);
                return null;
            }
            try { NativeSqlite.sqlite3_busy_timeout(db, 5000); } catch { }
            return new SqliteConnection { _db = db };
        }
        catch (Exception ex)
        {
            error = ex.Message;
            return null;
        }
    }

    /// <summary>执行一段（可含多条语句的）SQL，不取结果行。</summary>
    public bool Exec(string sql, out string error)
    {
        lock (_gate)
        {
            error = "";
            if (_db == IntPtr.Zero) { error = "SQLite 连接已关闭"; return false; }
            IntPtr err = IntPtr.Zero;
            try
            {
                byte[] bytes = Encoding.UTF8.GetBytes(sql + "\0");
                int rc = NativeSqlite.sqlite3_exec(_db, bytes, IntPtr.Zero, IntPtr.Zero, out err);
                if (rc == Sqlite.Ok) return true;
                error = err != IntPtr.Zero ? (Marshal.PtrToStringUTF8(err) ?? "") : Errmsg();
                if (error.Length == 0) error = "exec rc=" + rc;
                return false;
            }
            catch (Exception ex)
            {
                error = ex.Message;
                return false;
            }
            finally
            {
                if (err != IntPtr.Zero) NativeSqlite.sqlite3_free(err);
            }
        }
    }

    /// <summary>带参数执行一条写语句（INSERT/UPDATE/DELETE/DDL），参数用 bind_* 绑定。</summary>
    public bool Execute(string sql, object?[]? args, out string error)
    {
        error = "";
        using SqliteStatement? st = Prepare(sql, out error);
        if (st == null) return false;
        if (!st.Bind(args, out error)) return false;
        if (!st.Step(out _, out error)) return false;
        return true;
    }

    /// <summary>带参数查询；每读到一行回调一次 <paramref name="onRow"/>（行对象只在回调期间有效）。</summary>
    public bool Query(string sql, object?[]? args, Action<SqliteRow> onRow, out string error)
    {
        error = "";
        using SqliteStatement? st = Prepare(sql, out error);
        if (st == null) return false;
        if (!st.Bind(args, out error)) return false;
        while (true)
        {
            if (!st.Step(out bool hasRow, out error)) return false;
            if (!hasRow) return true;
            try { onRow(st.Row); }
            catch (Exception ex) { error = "行回调异常：" + ex.Message; return false; }
        }
    }

    /// <summary>预编译一条语句（批量写事件时复用，省掉 2 万次 parse）。</summary>
    public SqliteStatement? Prepare(string sql, out string error)
    {
        error = "";
        lock (_gate)
        {
            if (_db == IntPtr.Zero) { error = "SQLite 连接已关闭"; return null; }
            IntPtr stmt = IntPtr.Zero;
            try
            {
                byte[] bytes = Encoding.UTF8.GetBytes(sql);
                int rc = NativeSqlite.sqlite3_prepare_v2(_db, bytes, bytes.Length, out stmt, out IntPtr tail);
                if (rc != Sqlite.Ok || stmt == IntPtr.Zero)
                {
                    error = $"prepare 失败（rc={rc}）：{Errmsg()}";
                    if (stmt != IntPtr.Zero) NativeSqlite.sqlite3_finalize(stmt);
                    return null;
                }
                return new SqliteStatement(stmt);
            }
            catch (Exception ex)
            {
                if (stmt != IntPtr.Zero) { try { NativeSqlite.sqlite3_finalize(stmt); } catch { } }
                error = ex.Message;
                return null;
            }
        }
    }

    /// <summary>最近一次 INSERT 的 rowid（AUTOINCREMENT 主键）。</summary>
    public long LastInsertRowId
    {
        get
        {
            lock (_gate)
            {
                try { return _db == IntPtr.Zero ? 0 : NativeSqlite.sqlite3_last_insert_rowid(_db); }
                catch { return 0; }
            }
        }
    }

    public bool Begin(out string error) => Exec("BEGIN IMMEDIATE;", out error);
    public bool Commit(out string error) => Exec("COMMIT;", out error);

    /// <summary>回滚；没有活动事务时也安全（失败只记 LastError）。</summary>
    public bool Rollback()
    {
        try
        {
            bool ok = Exec("ROLLBACK;", out string error);
            if (!ok) lock (_gate) _lastError = error;
            return ok;
        }
        catch
        {
            return false;
        }
    }

    private string Errmsg()
    {
        try { return _db == IntPtr.Zero ? "" : NativeSqlite.Errmsg(_db); }
        catch { return ""; }
    }

    public void Dispose()
    {
        lock (_gate)
        {
            if (_db == IntPtr.Zero) return;
            try { NativeSqlite.sqlite3_close_v2(_db); } catch { }
            _db = IntPtr.Zero;
        }
    }
}

/// <summary>一条预编译语句；<see cref="Bind"/>→<see cref="Step"/> 可反复复用（批量插入）。</summary>
public sealed class SqliteStatement : IDisposable
{
    private IntPtr _stmt;

    internal SqliteStatement(IntPtr stmt) => _stmt = stmt;

    public bool IsValid => _stmt != IntPtr.Zero;

    /// <summary>当前行的只读视图（只在 Step 返回 hasRow=true 到下一次 Step 之间有效）。</summary>
    public SqliteRow Row => new(_stmt);

    /// <summary>按 1..N 绑定参数：long/int→bind_int64，double/float→bind_double，string→UTF-8 bind_text，bool→0/1，null→bind_null。</summary>
    public bool Bind(object?[]? args, out string error)
    {
        error = "";
        if (_stmt == IntPtr.Zero) { error = "语句已释放"; return false; }
        try
        {
            int rc = NativeSqlite.sqlite3_reset(_stmt);
            if (rc != Sqlite.Ok) { error = "reset 失败 rc=" + rc; return false; }

            int n = args?.Length ?? 0;
            for (int i = 0; i < n; i++)
            {
                int idx = i + 1;
                object? v = args![i];
                switch (v)
                {
                    case null:
                    case DBNull:
                        rc = NativeSqlite.sqlite3_bind_null(_stmt, idx);
                        break;
                    case string s:
                    {
                        byte[] bytes = Encoding.UTF8.GetBytes(s);
                        rc = NativeSqlite.sqlite3_bind_text(_stmt, idx, bytes, bytes.Length, Sqlite.Transient);
                        break;
                    }
                    case bool b:
                        rc = NativeSqlite.sqlite3_bind_int64(_stmt, idx, b ? 1 : 0);
                        break;
                    case byte or sbyte or short or ushort or int or uint or long:
                        rc = NativeSqlite.sqlite3_bind_int64(_stmt, idx, Convert.ToInt64(v));
                        break;
                    case ulong ul:
                        rc = NativeSqlite.sqlite3_bind_int64(_stmt, idx, unchecked((long)ul));
                        break;
                    case float or double or decimal:
                        rc = NativeSqlite.sqlite3_bind_double(_stmt, idx, Convert.ToDouble(v));
                        break;
                    case DateTime dt:
                    {
                        byte[] bytes = Encoding.UTF8.GetBytes(dt.ToString("o", System.Globalization.CultureInfo.InvariantCulture));
                        rc = NativeSqlite.sqlite3_bind_text(_stmt, idx, bytes, bytes.Length, Sqlite.Transient);
                        break;
                    }
                    case DateTimeOffset dto:
                    {
                        byte[] bytes = Encoding.UTF8.GetBytes(dto.ToString("o", System.Globalization.CultureInfo.InvariantCulture));
                        rc = NativeSqlite.sqlite3_bind_text(_stmt, idx, bytes, bytes.Length, Sqlite.Transient);
                        break;
                    }
                    default:
                        error = "不支持的参数类型：" + v.GetType().FullName;
                        return false;
                }
                if (rc != Sqlite.Ok) { error = $"bind 第 {idx} 个参数失败（rc={rc}）"; return false; }
            }
            return true;
        }
        catch (Exception ex)
        {
            error = ex.Message;
            return false;
        }
    }

    /// <summary>走一步：hasRow=true 表示有结果行；false + error 为空表示执行完毕（SQLITE_DONE）。</summary>
    public bool Step(out bool hasRow, out string error)
    {
        hasRow = false;
        error = "";
        if (_stmt == IntPtr.Zero) { error = "语句已释放"; return false; }
        try
        {
            int rc = NativeSqlite.sqlite3_step(_stmt);
            if (rc == Sqlite.Row) { hasRow = true; return true; }
            if (rc == Sqlite.Done) return true;
            error = "step 失败（rc=" + rc + "）";
            return false;
        }
        catch (Exception ex)
        {
            error = ex.Message;
            return false;
        }
    }

    public void Dispose()
    {
        IntPtr stmt = _stmt;
        _stmt = IntPtr.Zero;
        if (stmt == IntPtr.Zero) return;
        try { NativeSqlite.sqlite3_finalize(stmt); } catch { }
    }
}

/// <summary>查询结果的当前行（列从 0 开始）。</summary>
public readonly struct SqliteRow
{
    private readonly IntPtr _stmt;

    internal SqliteRow(IntPtr stmt) => _stmt = stmt;

    /// <summary>该列是不是 SQL NULL。</summary>
    public bool IsNull(int column)
    {
        try { return _stmt == IntPtr.Zero || NativeSqlite.sqlite3_column_type(_stmt, column) == 5; }
        catch { return true; }
    }

    public string GetString(int column)
    {
        try
        {
            IntPtr p = NativeSqlite.sqlite3_column_text(_stmt, column);
            return p == IntPtr.Zero ? "" : (Marshal.PtrToStringUTF8(p) ?? "");
        }
        catch { return ""; }
    }

    public long GetInt64(int column)
    {
        try { return _stmt == IntPtr.Zero ? 0 : NativeSqlite.sqlite3_column_int64(_stmt, column); }
        catch { return 0; }
    }

    public int GetInt32(int column) => unchecked((int)GetInt64(column));

    public double GetDouble(int column)
    {
        try { return _stmt == IntPtr.Zero ? 0 : NativeSqlite.sqlite3_column_double(_stmt, column); }
        catch { return 0; }
    }

    public bool GetBool(int column) => GetInt64(column) != 0;
}

/// <summary>winsqlite3.dll 的原始声明（只声明用到的函数）。</summary>
internal static class NativeSqlite
{
    /// <summary>sqlite3_errmsg 的 UTF-8 文本（读不到返回空串）。</summary>
    internal static string Errmsg(IntPtr db)
    {
        try
        {
            IntPtr p = sqlite3_errmsg(db);
            return p == IntPtr.Zero ? "" : (Marshal.PtrToStringUTF8(p) ?? "");
        }
        catch
        {
            return "";
        }
    }

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr sqlite3_libversion();

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_open_v2(byte[] filename, out IntPtr db, int flags, IntPtr vfs);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_close_v2(IntPtr db);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_busy_timeout(IntPtr db, int ms);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_exec(IntPtr db, byte[] sql, IntPtr callback, IntPtr arg, out IntPtr errmsg);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern void sqlite3_free(IntPtr p);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr sqlite3_errmsg(IntPtr db);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_prepare_v2(IntPtr db, byte[] sql, int nByte, out IntPtr stmt, out IntPtr tail);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_step(IntPtr stmt);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_reset(IntPtr stmt);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_finalize(IntPtr stmt);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_bind_null(IntPtr stmt, int index);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_bind_int64(IntPtr stmt, int index, long value);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_bind_double(IntPtr stmt, int index, double value);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_bind_text(IntPtr stmt, int index, byte[] value, int n, IntPtr destructor);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_column_type(IntPtr stmt, int column);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern IntPtr sqlite3_column_text(IntPtr stmt, int column);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern long sqlite3_column_int64(IntPtr stmt, int column);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern double sqlite3_column_double(IntPtr stmt, int column);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern int sqlite3_column_count(IntPtr stmt);

    [DllImport(Sqlite.Lib, CallingConvention = CallingConvention.Cdecl)]
    internal static extern long sqlite3_last_insert_rowid(IntPtr db);
}
