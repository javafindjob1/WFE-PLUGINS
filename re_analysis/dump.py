import struct, sys
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

DLL = r"C:\3rd\wc3gamesearcher\WFE\Application\WFEDll.dll"
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

def va_to_off(va):
    return rva_to_off(va - IMAGE_BASE)

# Build string target map (VA -> text) and IAT map (VA -> name)
strmap = {}
for s in sections:
    if s['name'] in ('.rdata', '.data'):
        off = s['rawPtr']; end = s['rawPtr'] + s['rawSize']
        while off < end:
            b = data[off]
            if 0x20 <= b < 0x7f:
                j = off
                while j < end and 0x20 <= data[j] < 0x7f:
                    j += 1
                if j - off >= 3:
                    txt = data[off:j].decode('latin1')
                    rva = off_to_rva(off)
                    if rva >= 0:
                        strmap[IMAGE_BASE + rva] = txt
                off = j
            else:
                off += 1

iatmap = {}
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
            iatmap[IMAGE_BASE + firstThunk + k*4] = fn
            k += 1
        off += 20

md = Cs(CS_ARCH_X86, CS_MODE_32)
md.detail = True

def dump(start_va, length):
    off = va_to_off(start_va)
    code = data[off: off + length]
    lines = []
    for ins in md.disasm(code, start_va):
        addr = ins.address
        ann = []
        for op in ins.operands:
            if op.type == 2 and op.imm in strmap:
                ann.append(f'"{strmap[op.imm]}"')
            elif op.type == 2 and op.imm in iatmap:
                ann.append(iatmap[op.imm])
            elif op.type == 3:
                d = op.mem.disp
                if d in strmap:
                    ann.append(f'&"{strmap[d]}"')
                if d in iatmap:
                    ann.append('[' + iatmap[d] + ']')
        # IAT call detection: call dword ptr [iat]
        if ins.mnemonic.startswith('call') and ins.operands and ins.operands[0].type == 3:
            d = ins.operands[0].mem.disp
            if d in iatmap:
                ann.append('-> ' + iatmap[d])
        suffix = (' ; ' + ' | '.join(ann)) if ann else ''
        lines.append(f"{addr:08X}: {ins.bytes.hex():<16} {ins.mnemonic:<7} {ins.op_str}{suffix}")
    return "\n".join(lines)

if __name__ == "__main__":
    start = int(sys.argv[1], 16)
    length = int(sys.argv[2], 16) if len(sys.argv) > 2 else 0x200
    print(dump(start, length))
