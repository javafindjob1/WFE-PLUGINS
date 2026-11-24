import struct, sys
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

DLL = r"C:\3rd\wc3gamesearcher\WFE\Application\WFEDll.dll"
IMAGE_BASE = 0x10000000
data = open(DLL, "rb").read()

def u16(o): return struct.unpack_from("<H", data, o)[0]
def u32(o): return struct.unpack_from("<I", data, o)[0]
e = u32(0x3C); optOff = e + 4 + 20
numSec = u16(e + 4 + 2); sizeOpt = u16(e + 4 + 16); secTab = optOff + sizeOpt
sections = []
for i in range(numSec):
    s = secTab + i*40
    sections.append({'name': data[s:s+8].split(b"\0")[0].decode('latin1'),
                     'vsize': u32(s+8), 'va': u32(s+12), 'rawSize': u32(s+16), 'rawPtr': u32(s+20)})
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
def va_to_off(va): return rva_to_off(va - IMAGE_BASE)

strmap = {}
for s in sections:
    if s['name'] in ('.rdata', '.data'):
        off = s['rawPtr']; end = s['rawPtr'] + s['rawSize']
        while off < end:
            if 0x20 <= data[off] < 0x7f:
                j = off
                while j < end and 0x20 <= data[j] < 0x7f: j += 1
                if j - off >= 3:
                    r = off_to_rva(off)
                    if r >= 0: strmap[IMAGE_BASE + r] = data[off:j].decode('latin1')
                off = j
            else: off += 1

def find_func_start(va, back=0x1200):
    """walk back to a CC-padded prologue"""
    off = va_to_off(va)
    if off < 0: return None
    for d in range(0, back):
        p = off - d
        if p < 16: break
        if data[p-1] == 0xCC and data[p-2] == 0xCC:
            return IMAGE_BASE + off_to_rva(p)
    return None

md = Cs(CS_ARCH_X86, CS_MODE_32)
md.detail = True

def dump(start_va, length, mark=None):
    off = va_to_off(start_va)
    if off < 0:
        print('bad va %08X' % start_va); return
    code = data[off:off + length]
    for ins in md.disasm(code, start_va):
        ann = []
        for op in ins.operands:
            if op.type == 2 and op.imm in strmap:
                ann.append('"%s"' % strmap[op.imm])
            elif op.type == 3 and op.mem.base == 0 and op.mem.index == 0 and op.mem.disp in strmap:
                ann.append('&"%s"' % strmap[op.mem.disp])
        m = '  <<<<' if (mark is not None and ins.address == mark) else ''
        print('%08X: %-18s %-7s %s%s%s' % (ins.address, ins.bytes.hex(), ins.mnemonic, ins.op_str,
                                           ('  ; ' + ' | '.join(ann)) if ann else '', m))

if __name__ == '__main__':
    target = int(sys.argv[1], 16)
    length = int(sys.argv[2], 16) if len(sys.argv) > 2 else 0x200
    if '--func' in sys.argv:
        fs = find_func_start(target)
        print('=== function start for %08X: %s ===' % (target, ('%08X' % fs) if fs else '?'))
        if fs:
            dump(fs, target - fs + length, mark=target)
    else:
        dump(target, length)
