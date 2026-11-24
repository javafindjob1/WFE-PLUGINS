import struct, os
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

DLL = r"C:\3rd\wc3gamesearcher\WFE\Application\WFEDll.dll"
OUT = r"C:\3rd\wc3gamesearcher\WFE\Application\re_analysis"
IMAGE_BASE = 0x10000000

data = open(DLL, "rb").read()
def u16(o): return struct.unpack_from("<H", data, o)[0]
def u32(o): return struct.unpack_from("<I", data, o)[0]

e_lfanew = u32(0x3C)
optOff = e_lfanew + 4 + 20
numDirs = u32(optOff + 92)
dirOff = optOff + 96
def dir(i): return (u32(dirOff + i*8), u32(dirOff + i*8 + 4))

numSec = u16(e_lfanew + 4 + 2)
sizeOpt = u16(e_lfanew + 4 + 16)
secTab = optOff + sizeOpt
sections = []
for i in range(numSec):
    s = secTab + i*40
    name = data[s:s+8].split(b"\0")[0].decode('latin1')
    sections.append({'name': name, 'vsize': u32(s+8), 'va': u32(s+12),
                     'rawSize': u32(s+16), 'rawPtr': u32(s+20)})

def rva_to_off(rva):
    for s in sections:
        if s['va'] <= rva < s['va'] + max(s['vsize'], s['rawSize']):
            return s['rawPtr'] + (rva - s['va'])
    return -1

def off_to_rva(off):
    for s in sections:
        if s['rawPtr'] <= off < s['rawPtr'] + s['rawSize']:
            return s['va'] + (off - s['rawPtr'])
    return -1

# Build target map: value(int) -> [labels]
targets = {}
def add_target(va, label):
    targets.setdefault(va, set()).add(label)

# strings from rdata/data
for s in sections:
    if s['name'] in ('.rdata', '.data'):
        off = s['rawPtr']; end = s['rawPtr'] + s['rawSize']
        while off < end:
            b = data[off]
            if 0x20 <= b < 0x7f:
                j = off
                while j < end and 0x20 <= data[j] < 0x7f:
                    j += 1
                if j - off >= 4:
                    txt = data[off:j].decode('latin1')
                    rva = off_to_rva(off)
                    if rva >= 0:
                        add_target(IMAGE_BASE + rva, txt)
                off = j
            else:
                off += 1

# IAT entries
imp = dir(1)
if imp[0]:
    off = rva_to_off(imp[0])
    while True:
        d = [u32(off + k*4) for k in range(5)]
        if d[0] == 0 and d[2] == 0 and d[3] == 0:
            break
        dllname = data[rva_to_off(d[3]):].split(b"\0")[0].decode('latin1')
        oft = d[0]
        thunkOff = rva_to_off(oft) if oft else rva_to_off(d[4])
        firstThunk = d[4]
        k = 0
        while True:
            tv = u32(thunkOff + k*4)
            if tv == 0: break
            if tv & 0x80000000:
                fn = f"{dllname}!ord#{tv&0xFFFF}"
            else:
                h = rva_to_off(tv & 0x7FFFFFFF)
                fn = f"{dllname}!" + data[h+2:].split(b"\0")[0].decode('latin1')
            add_target(IMAGE_BASE + firstThunk + k*4, fn)
            k += 1
        off += 20

# Single-pass byte scan of .text for 4-byte target values
text = next(s for s in sections if s['name'] == '.text')
tstart = text['rawPtr']; tend = tstart + text['rawSize']
hits = []  # (text_offset, value, labels)
for off in range(tstart, tend - 3):
    v = u32(off)
    if v in targets:
        hits.append((off, v, targets[v]))

# Now disassemble around each hit to identify the containing instruction
md = Cs(CS_ARCH_X86, CS_MODE_32)
md.detail = True
lines = []
for off, v, labels in hits:
    rva = off_to_rva(off)
    va = IMAGE_BASE + rva
    label = ";".join(sorted(labels))
    # disassemble a window before the hit
    window_start = off - 8
    if window_start < tstart: window_start = tstart
    chunk = data[window_start: off + 4]
    chunk_va = IMAGE_BASE + off_to_rva(window_start)
    insns = list(md.disasm(chunk, chunk_va))
    # find instruction containing the hit address
    found = None
    for ins in insns:
        if ins.address <= va < ins.address + ins.size:
            found = ins
            break
    if found:
        lines.append(f"0x{found.address:08X}  {found.mnemonic} {found.op_str:34s} ; {label}")
    else:
        lines.append(f"0x{va:08X}  (raw 4-byte) {label}")

open(os.path.join(OUT, "xrefs2.txt"), "w").write("\n".join(lines))
print("hits:", len(hits), "targets:", len(targets))
