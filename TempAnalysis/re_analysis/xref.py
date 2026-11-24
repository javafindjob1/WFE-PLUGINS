import struct, sys, os
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
    sections.append({
        'name': name,
        'vsize': u32(s+8),
        'va': u32(s+12),
        'rawSize': u32(s+16),
        'rawPtr': u32(s+20),
    })

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

# --- Build target set: all interesting VA addresses ---
# 1) strings in .rdata and .data that look like names/format strings
targets = {}  # VA -> label

def collect_strings(off_start, off_end):
    i = off_start
    while i < off_end:
        b = data[i]
        if 0x20 <= b < 0x7f:
            j = i
            while j < off_end and 0x20 <= data[j] < 0x7f:
                j += 1
            if j - i >= 4:
                s = data[i:j].decode('latin1')
                rva = off_to_rva(i)
                if rva >= 0:
                    va = IMAGE_BASE + rva
                    targets[va] = s
            i = j
        else:
            i += 1

# rdata + data sections
for s in sections:
    if s['name'] in ('.rdata', '.data'):
        collect_strings(s['rawPtr'], s['rawPtr'] + s['rawSize'])

# 2) IAT entries: each first-thunk entry is a VA of a resolved import
# Add them as targets keyed by VA so calls can be resolved.
# We'll parse imports to name IAT slots.
imp = dir(1)
iat_names = {}
if imp[0]:
    off = rva_to_off(imp[0])
    while True:
        d = [u32(off + k*4) for k in range(5)]
        if d[0] == 0 and d[2] == 0 and d[3] == 0:
            break
        dllname_rva, firstThunk = d[3], d[4]
        dllname = data[rva_to_off(dllname_rva):].split(b"\0")[0].decode('latin1')
        oft = d[0]
        thunkOff = rva_to_off(oft) if oft else rva_to_off(firstThunk)
        iatOff = rva_to_off(firstThunk)
        k = 0
        while True:
            tv = u32(thunkOff + k*4)
            if tv == 0: break
            if tv & 0x80000000:
                fn = f"{dllname}!ord#{tv&0xFFFF}"
            else:
                h = rva_to_off(tv & 0x7FFFFFFF)
                fn = f"{dllname}!" + data[h+2:].split(b"\0")[0].decode('latin1')
            iatva = IMAGE_BASE + firstThunk + k*4
            iat_names[iatva] = fn
            k += 1
        off += 20

# --- Disassemble .text and record xrefs ---
text = next(s for s in sections if s['name'] == '.text')
code = data[text['rawPtr']: text['rawPtr'] + text['rawSize']]
base_va = IMAGE_BASE + text['va']

md = Cs(CS_ARCH_X86, CS_MODE_32)
md.detail = True

xref_lines = []
# For each instruction, detect references to target VAs (immediate operands or [disp32])
for ins in md.disasm(code, base_va):
    addr = ins.address
    refs = []
    # immediate
    for op in ins.operands:
        if op.type == 2:  # IMM
            val = op.imm
            if val in targets:
                refs.append(('imm', val, targets[val]))
            if val in iat_names:
                refs.append(('imm-iat', val, iat_names[val]))
        elif op.type == 3:  # MEM
            if op.mem.base == 0 and op.mem.index == 0:
                disp = op.mem.disp
                if disp in iat_names:
                    refs.append(('iat', disp, iat_names[disp]))
                elif disp in targets:
                    refs.append(('mem', disp, targets[disp]))
    if refs:
        for kind, val, label in refs:
            xref_lines.append(f"0x{addr:08X}  {ins.mnemonic} {ins.op_str:30s} ; {kind} -> {label}")

open(os.path.join(OUT, "xrefs.txt"), "w").write("\n".join(xref_lines))
print("targets:", len(targets), "iat_names:", len(iat_names), "xrefs lines:", len(xref_lines))
