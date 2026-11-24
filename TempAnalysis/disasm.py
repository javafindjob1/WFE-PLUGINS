import sys
import pefile
from capstone import Cs, CS_ARCH_X86, CS_MODE_32

PATH = r'C:\3rd\war5\game.dll'
pe = pefile.PE(PATH, fast_load=True)
BASE = pe.OPTIONAL_HEADER.ImageBase


def sec_of(va):
    rva = va - BASE
    for s in pe.sections:
        if s.VirtualAddress <= rva < s.VirtualAddress + max(s.Misc_VirtualSize, s.SizeOfRawData):
            return s
    return None


_cache = {}
def read(va, n):
    s = sec_of(va)
    if s is None:
        return None
    if s.Name not in _cache:
        _cache[s.Name] = s.get_data()
    off = va - BASE - s.VirtualAddress
    return _cache[s.Name][off:off + n]


md = Cs(CS_ARCH_X86, CS_MODE_32)
md.detail = True


def linear(va, nbytes):
    data = read(va, nbytes)
    return list(md.disasm(data, va))


def fmt(ins):
    return '0x%08X  %-22s %s %s' % (ins.address, ins.bytes.hex(), ins.mnemonic, ins.op_str)


if __name__ == '__main__':
    va = int(sys.argv[1], 16)
    nb = int(sys.argv[2], 16) if len(sys.argv) > 2 else 0x800
    ins = linear(va, nb)
    calls = []
    for i in ins:
        print(fmt(i))
        if i.mnemonic == 'call' and i.op_str.startswith('0x'):
            calls.append(int(i.op_str, 16))
    print('--- DIRECT CALL TARGETS ---')
    seen = set()
    for c in calls:
        if c in seen:
            continue
        seen.add(c)
        s = sec_of(c)
        print(hex(c), s.Name.decode(errors='replace') if s else '?')
