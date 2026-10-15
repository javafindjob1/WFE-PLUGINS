using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

namespace War3DeathSettlement.Core;

/// <summary>一块已提交的内存区域（VirtualQueryEx 的结果，只读用）。</summary>
public readonly record struct MemRegion(ulong Base, ulong Size, uint Protect, uint Type)
{
    public ulong End => Base + Size;
    public bool Readable => (Protect & (Native.PAGE_NOACCESS | Native.PAGE_GUARD)) == 0 &&
                            (Protect & (Native.PAGE_READONLY | Native.PAGE_READWRITE | Native.PAGE_WRITECOPY |
                                        Native.PAGE_EXECUTE_READ | Native.PAGE_EXECUTE_READWRITE |
                                        Native.PAGE_EXECUTE_WRITECOPY)) != 0;
}

public sealed class ModuleInfo
{
    public string Name { get; init; } = "";
    public string Path { get; init; } = "";
    public ulong Base { get; init; }
    public uint Size { get; init; }
    public override string ToString() => $"{Name} @ 0x{Base:X8} ({Size / 1024}KB)";
}

/// <summary>
/// 对目标进程的【只读】内存访问封装。
/// 设计要点：
///   * 绝不调用 WriteProcessMemory —— 本软件是纯观察者（与 War3Trainer 的“修改器”定位不同）。
///   * 所有读取都先过虚拟内存表（VirtualQueryEx 缓存），避免踩到未提交页造成整段读取失败。
///   * 提供 4 字节/浮点等定长读取，失败返回 false 而不是抛异常。
/// </summary>
public sealed class RemoteProcess : IDisposable
{
    private readonly IntPtr _handle;
    private readonly IntPtr _scratch;
    private readonly object _ioGate = new();   // 中转缓冲只有一块，所有读取串行化（多线程安全）
    private const int ScratchSize = 1 << 20;   // 1 MB 中转缓冲
    private List<MemRegion>? _regions;
    private long _bytesRead;
    private long _readCalls;

    public int Pid { get; }
    public string ProcessName { get; }
    public IntPtr Handle => _handle;
    public List<ModuleInfo> Modules { get; private set; } = new();
    public string? MainModulePath { get; private set; }
    public bool IsWow64 { get; private set; }

    public long BytesRead => Interlocked.Read(ref _bytesRead);
    public long ReadCalls => Interlocked.Read(ref _readCalls);

    private RemoteProcess(int pid, string name, IntPtr handle)
    {
        Pid = pid;
        ProcessName = name;
        _handle = handle;
        _scratch = Marshal.AllocHGlobal(ScratchSize);
    }

    /// <summary>打开目标进程（只读）。失败时 error 里带回 Win32 错误码。</summary>
    public static RemoteProcess? TryOpen(int pid, out string error)
    {
        error = "";
        string name;
        try { name = Process.GetProcessById(pid).ProcessName; }
        catch (Exception ex) { error = "取进程名失败: " + ex.Message; return null; }

        uint access = Native.PROCESS_VM_READ | Native.PROCESS_QUERY_INFORMATION;
        IntPtr h = Native.OpenProcess(access, false, pid);
        if (h == IntPtr.Zero)
        {
            int err = Marshal.GetLastWin32Error();
            // 退化再试一次：有些进程只允许 LIMITED 查询
            h = Native.OpenProcess(Native.PROCESS_VM_READ | Native.PROCESS_QUERY_LIMITED_INFORMATION, false, pid);
            if (h == IntPtr.Zero)
            {
                error = $"OpenProcess 失败（{Native.DescribeError(err)}）。" +
                        (err == 5 ? " 目标以管理员权限运行，请用【以管理员身份重启】。" : "");
                return null;
            }
        }

        var rp = new RemoteProcess(pid, name, h);
        try
        {
            Native.IsWow64Process(h, out bool wow);
            rp.IsWow64 = wow;
            rp.LoadModules();
            rp.LoadRegions();
        }
        catch (Exception ex)
        {
            error = ex.Message;
            rp.Dispose();
            return null;
        }
        return rp;
    }

    private void LoadModules()
    {
        var list = new List<ModuleInfo>();
        IntPtr snap = Native.CreateToolhelp32Snapshot(Native.TH32CS_SNAPMODULE | Native.TH32CS_SNAPMODULE32, (uint)Pid);
        if (snap != IntPtr.Zero && snap != new IntPtr(-1))
        {
            try
            {
                var me = new Native.MODULEENTRY32W { dwSize = (uint)Marshal.SizeOf<Native.MODULEENTRY32W>() };
                if (Native.Module32FirstW(snap, ref me))
                {
                    do
                    {
                        list.Add(new ModuleInfo
                        {
                            Name = me.szModule ?? "",
                            Path = me.szExePath ?? "",
                            Base = (ulong)me.modBaseAddr.ToInt64(),
                            Size = me.modBaseSize
                        });
                        me.dwSize = (uint)Marshal.SizeOf<Native.MODULEENTRY32W>();
                    } while (Native.Module32NextW(snap, ref me));
                }
            }
            finally { Native.CloseHandle(snap); }
        }

        if (list.Count == 0)
        {
            // 退化：至少把主模块放进去（x64 宿主进程读 x86 目标时快照偶尔会空）
            try
            {
                var p = Process.GetProcessById(Pid);
                string path = p.MainModule?.FileName ?? "";
                list.Add(new ModuleInfo
                {
                    Name = Path.GetFileName(path),
                    Path = path,
                    Base = (ulong)(p.MainModule?.BaseAddress.ToInt64() ?? 0),
                    Size = (uint)(p.MainModule?.ModuleMemorySize ?? 0)
                });
                MainModulePath = path;
            }
            catch { /* 忽略 */ }
        }

        Modules = list;
        var main = list.FirstOrDefault();
        if (main != null && MainModulePath == null) MainModulePath = main.Path;
    }

    public ModuleInfo? FindModule(string name) =>
        Modules.FirstOrDefault(m => string.Equals(m.Name, name, StringComparison.OrdinalIgnoreCase));

    /// <summary>枚举整个地址空间的已提交区域（只保留可读的）。</summary>
    public void LoadRegions()
    {
        var regions = new List<MemRegion>();
        ulong addr = 0;
        int mbiSize = Marshal.SizeOf<Native.MEMORY_BASIC_INFORMATION64>();
        while (addr < 0x7FFF_FFFFUL)
        {
            IntPtr r = Native.VirtualQueryEx(_handle, (IntPtr)(long)addr, out var mbi, (IntPtr)mbiSize);
            if (r == IntPtr.Zero) break;
            if (mbi.RegionSize == 0) break;
            var reg = new MemRegion(mbi.BaseAddress, mbi.RegionSize, mbi.Protect, mbi.Type);
            if (mbi.State == Native.MEM_COMMIT && reg.Readable) regions.Add(reg);
            ulong next = mbi.BaseAddress + mbi.RegionSize;
            if (next <= addr) break;
            addr = next;
        }
        _regions = regions;
    }

    public IReadOnlyList<MemRegion> Regions => _regions ??= new List<MemRegion>();

    /// <summary>地址区间是否落在某个已提交且可读的区域里（用于避免无效读取 & 扫描）。</summary>
    public bool IsReadable(ulong addr, int size)
    {
        if (size <= 0) return false;
        ulong end = addr + (ulong)size;
        foreach (var r in Regions)
        {
            if (addr >= r.Base && end <= r.End) return true;
            if (r.Base > addr) break;
        }
        return false;
    }

    public MemRegion? RegionOf(ulong addr)
    {
        foreach (var r in Regions)
            if (addr >= r.Base && addr < r.End) return r;
        return null;
    }

    /// <summary>读一段字节；返回实际读到的长度（0 表示失败）。</summary>
    public int ReadBytes(ulong addr, byte[] dest, int offset, int length)
    {
        if (length <= 0) return 0;
        lock (_ioGate)
        {
            int done = 0;
            while (done < length)
            {
                int chunk = Math.Min(ScratchSize, length - done);
                if (!TryReadRaw(addr + (ulong)done, chunk, out int got) || got <= 0) break;
                Marshal.Copy(_scratch, dest, offset + done, got);
                done += got;
                if (got < chunk) break;
            }
            return done;
        }
    }

    public byte[]? ReadBytes(ulong addr, int length)
    {
        if (length <= 0) return Array.Empty<byte>();
        var buf = new byte[length];
        int got = ReadBytes(addr, buf, 0, length);
        if (got <= 0) return null;
        if (got == length) return buf;
        Array.Resize(ref buf, got);
        return buf;
    }

    private bool TryReadRaw(ulong addr, int length, out int got)
    {
        Interlocked.Increment(ref _readCalls);
        bool ok = Native.ReadProcessMemory(_handle, (IntPtr)(long)addr, _scratch, (IntPtr)length, out IntPtr read);
        got = (int)read.ToInt64();
        if (got > 0) Interlocked.Add(ref _bytesRead, got);
        return ok && got > 0;
    }

    // ---- 定长读取 --------------------------------------------------------
    public bool ReadU32(ulong addr, out uint value)
    {
        value = 0;
        lock (_ioGate)
        {
            if (!TryReadRaw(addr, 4, out int got) || got < 4) return false;
            value = (uint)Marshal.ReadInt32(_scratch);
            return true;
        }
    }

    public bool ReadI32(ulong addr, out int value)
    {
        value = 0;
        lock (_ioGate)
        {
            if (!TryReadRaw(addr, 4, out int got) || got < 4) return false;
            value = Marshal.ReadInt32(_scratch);
            return true;
        }
    }

    public bool ReadU16(ulong addr, out ushort value)
    {
        value = 0;
        lock (_ioGate)
        {
            if (!TryReadRaw(addr, 2, out int got) || got < 2) return false;
            value = (ushort)Marshal.ReadInt16(_scratch);
            return true;
        }
    }

    public bool ReadF32(ulong addr, out float value)
    {
        value = 0f;
        lock (_ioGate)
        {
            if (!TryReadRaw(addr, 4, out int got) || got < 4) return false;
            value = BitConverter.ToSingle(BitConverter.GetBytes(Marshal.ReadInt32(_scratch)), 0);
            return true;
        }
    }

    public uint U32(ulong addr) => ReadU32(addr, out uint v) ? v : 0u;
    public int I32(ulong addr) => ReadI32(addr, out int v) ? v : 0;
    public float F32(ulong addr) => ReadF32(addr, out float v) ? v : 0f;

    /// <summary>读 4 字符类型码（CUnit+0x30 之类）；不可打印时返回空串。</summary>
    public string ReadTypeCode(ulong addr)
    {
        if (!ReadU32(addr, out uint raw) || raw == 0) return "";
        Span<char> c = stackalloc char[4];
        for (int i = 0; i < 4; i++)
        {
            byte b = (byte)((raw >> (8 * i)) & 0xFF);
            if (b < 0x20 || b > 0x7E) return "";
            c[i] = (char)b;
        }
        return new string(c);
    }

    /// <summary>按游戏编码（GBK）读一个以 0 结尾的字符串，最多 max 字节。</summary>
    public string ReadCString(ulong addr, int max = 128)
    {
        var buf = ReadBytes(addr, max);
        if (buf == null || buf.Length == 0) return "";
        int n = Array.IndexOf(buf, (byte)0);
        if (n < 0) n = buf.Length;
        try { return Encoding.GetEncoding(936).GetString(buf, 0, n); }
        catch { return Encoding.ASCII.GetString(buf, 0, n); }
    }

    public void Dispose()
    {
        if (_scratch != IntPtr.Zero) Marshal.FreeHGlobal(_scratch);
        if (_handle != IntPtr.Zero) Native.CloseHandle(_handle);
    }
}
