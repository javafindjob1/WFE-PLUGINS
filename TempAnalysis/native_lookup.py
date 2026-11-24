import struct, sys
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

PATH = r'C:\3rd\war5\game.dll'
pe = pefile.PE(PATH, fast_load=True)
BASE = pe.OPTIONAL_HEADER.ImageBase
raw = open(PATH, 'rb').read()

secs = []
for s in pe.sections:
    secs.append((s.Name.decode(errors='replace').strip('\x00'), s.PointerToRawData,
                 s.SizeOfRawData, BASE + s.VirtualAddress, s.Misc_VirtualSize))


def off2va(off):
    for n, pr, sr, va, vs in secs:
        if pr <= off < pr + sr:
            return va + (off - pr), n
    return None, None


def va2off(va):
    for n, pr, sr, base, vs in secs:
        if base <= va < base + max(sr, vs):
            return pr + (va - base), n
    return None, None


def find_str(s):
    b = s.encode() + b'\x00'
    out = []
    i = 0
    while True:
        i = raw.find(b, i)
        if i < 0:
            break
        out.append(i)
        i += 1
    return [(hex(off2va(o)[0]), off2va(o)[1]) for o in out]


def find_imm32(va):
    pat = struct.pack('<I', va)
    hits = []
    i = 0
    while True:
        i = raw.find(pat, i)
        if i < 0:
            break
        hits.append(i)
        i += 1
    return hits


def dump(va, n=0x120):
    off, _ = va2off(va)
    if off is None:
        return
    md = Cs(CS_ARCH_X86, CS_MODE_32)
    for ins in md.disasm(raw[off:off + n], va):
        print('0x%08X  %-18s %s %s' % (ins.address, ins.bytes.hex(), ins.mnemonic, ins.op_str))


if __name__ == '__main__':
    name = sys.argv[1]
    print('strings for', name, find_str(name))
    for va_hex, sec in find_str(name):
        va = int(va_hex, 16)
        hits = find_imm32(va)
        print('refs to', va_hex, [(hex(off2va(h)[0]), off2va(h)[1]) for h in hits])
        for h in hits:
            rva = off2va(h)[0]
            print('--- table around', hex(rva), '---')
            off = h - 4
            for k in range(-4, 5):
                o = h + k * 4
                v = struct.unpack('<I', raw[o:o + 4])[0]
                print('  ', hex(off2va(o)[0]), hex(v))
            # last dword likely func ptr
            fp = struct.unpack('<I', raw[h + 4:h + 8])[0]
            print('--- disasm candidate func', hex(fp), '---')
            dump(fp, 0x140)
