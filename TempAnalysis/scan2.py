import sys, re
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

PATH = r'C:\3rd\war5\game.dll'
pe = pefile.PE(PATH, fast_load=True)
BASE = pe.OPTIONAL_HEADER.ImageBase
data_all = open(PATH, 'rb').read()


def rva2off(rva):
    for s in pe.sections:
        if s.VirtualAddress <= rva < s.VirtualAddress + max(s.Misc_VirtualSize, s.SizeOfRawData):
            return s.PointerToRawData + (rva - s.VirtualAddress), s
    return None, None


def read(va, n):
    off, s = rva2off(va - BASE)
    if off is None:
        return None
    return s.get_data()[va - BASE - s.VirtualAddress:][:n]


def search(pat, limit=40):
    hits = []
    start = 0
    while len(hits) < limit:
        i = data_all.find(pat, start)
        if i < 0:
            break
        hits.append(i)
        start = i + 1
    out = []
    for off in hits:
        for s in pe.sections:
            if s.PointerToRawData <= off < s.PointerToRawData + s.SizeOfRawData:
                va = BASE + s.VirtualAddress + (off - s.PointerToRawData)
                out.append((hex(va), s.Name.decode(errors='replace')))
                break
    return out


md = Cs(CS_ARCH_X86, CS_MODE_32)
md.detail = True
if __name__ == '__main__':
    mode = sys.argv[1]
    if mode == 'search':
        hexpat = sys.argv[2]
        pat = bytes.fromhex(hexpat)
        hits = search(pat)
        for h in hits:
            print(h)
    else:
        va = int(sys.argv[1], 16)
        nb = int(sys.argv[2], 16) if len(sys.argv) > 2 else 0x300
        d = read(va, nb)
        for i in md.disasm(d, va):
            print('0x%08X  %-20s %s %s' % (i.address, i.bytes.hex(), i.mnemonic, i.op_str))
