import struct, sys
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

DLL = r"C:\3rd\wc3gamesearcher\WFE\Application\WFEDll.dll"
BASE = 0x10000000
data = open(DLL, "rb").read()
def u16(o): return struct.unpack_from("<H", data, o)[0]
def u32(o): return struct.unpack_from("<I", data, o)[0]
e = u32(0x3C); optOff = e + 4 + 20
numSec = u16(e + 4 + 2); sizeOpt = u16(e + 4 + 16); secTab = optOff + sizeOpt
secs = []
for i in range(numSec):
    s = secTab + i * 40
    secs.append({'n': data[s:s+8].split(b"\0")[0].decode('latin1'),
                 'vs': u32(s+8), 'va': u32(s+12), 'rs': u32(s+16), 'rp': u32(s+20)})
def r2o(rva):
    for s in secs:
        if s['va'] <= rva < s['va'] + max(s['vs'], s['rs']): return s['rp'] + (rva - s['va'])
    return -1
def o2r(off):
    for s in secs:
        if s['rp'] <= off < s['rp'] + s['rs']: return s['va'] + (off - s['rp'])
    return -1
def v2o(va): return r2o(va - BASE)

strmap = {}
for s in secs:
    if s['n'] in ('.rdata', '.data'):
        off = s['rp']; end = s['rp'] + s['rs']
        while off < end:
            if 0x20 <= data[off] < 0x7f:
                j = off
                while j < end and 0x20 <= data[j] < 0x7f: j += 1
                if j - off >= 3:
                    r = o2r(off)
                    if r >= 0: strmap[BASE + r] = data[off:j].decode('latin1')
                off = j
            else: off += 1

md = Cs(CS_ARCH_X86, CS_MODE_32)
md.detail = True
text = next(s for s in secs if s['n'] == '.text')
code = data[text['rp']:text['rp'] + text['rs']]
base_va = BASE + text['va']

# find every instruction that writes to a given absolute address
targets = set(int(a, 16) for a in sys.argv[1:])
print('looking for writes to: %s' % ', '.join('%08X' % t for t in sorted(targets)))
hits = 0
for ins in md.disasm(code, base_va):
    s = ins.op_str
    for t in targets:
        if ('0x%x' % t) not in s and ('0x%X' % t) not in s:
            continue
        if ins.mnemonic in ('mov', 'movzx', 'movsx', 'lea', 'push', 'cmp', 'and', 'or', 'test'):
            # only report actual writes (dest is the memory operand)
            if ins.operands and ins.operands[0].type == 3 and ins.operands[0].mem.disp == t:
                ann = ''
                for op in ins.operands:
                    if op.type == 2 and op.imm in strmap: ann = '  ; "%s"' % strmap[op.imm]
                print('  WRITE %08X: %-8s %s%s' % (ins.address, ins.mnemonic, s, ann))
                hits += 1
print('total writes found: %d' % hits)
