import struct, sys
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

DLL = r"C:\3rd\wc3gamesearcher\WFE\Application\WFEDll.dll"
IMAGE_BASE = 0x10000000
data = open(DLL, "rb").read()

def u16(o): return struct.unpack_from("<H", data, o)[0]
def u32(o): return struct.unpack_from("<I", data, o)[0]
e_lfanew = u32(0x3C)
optOff = e_lfanew + 4 + 20
sizeOpt = u16(e_lfanew + 4 + 16)
numSec = u16(e_lfanew + 4 + 2)
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

def va_to_off(va): return rva_to_off(va - IMAGE_BASE)

# find all call/jmp targets (direct relative) in .text
text = next(s for s in sections if s['name'] == '.text')
code = data[text['rawPtr']: text['rawPtr'] + text['rawSize']]
base = IMAGE_BASE + text['va']

md = Cs(CS_ARCH_X86, CS_MODE_32)
md.detail = True

targets = [int(a, 16) for a in sys.argv[1:]]
result = {}
# scan raw bytes for E8 (call rel32) and E9 (jmp rel32)
for off in range(len(code) - 5):
    b = code[off]
    if b == 0xE8 or b == 0xE9:
        rel = struct.unpack_from('<i', code, off+1)[0]
        dest = base + off + 5 + rel
        if dest in targets:
            result.setdefault(dest, []).append((base + off, 'call' if b == 0xE8 else 'jmp'))

for t in targets:
    hits = result.get(t, [])
    print(f"--- refs to 0x{t:08X} ({len(hits)}) ---")
    for addr, kind in hits:
        print(f"  0x{addr:08X}  {kind}")
