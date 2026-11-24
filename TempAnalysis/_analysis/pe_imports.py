"""Dump PE32 imports grouped by DLL.

Usage: python pe_imports.py <pe> [dll-substr]
"""
import sys
from pe_probe import PE


def main():
    pe = PE(sys.argv[1])
    want = sys.argv[2].lower() if len(sys.argv) > 2 else None
    imp_rva, imp_size = pe.dirs[1]
    if imp_rva == 0:
        print('no imports')
        return
    va = pe.image_base + imp_rva
    out = {}
    for _ in range(512):
        desc = pe.read_va(va, 20)
        if not desc or len(desc) < 20:
            break
        import struct
        oft, ts, fc, name_rva, first_thunk = struct.unpack('<IIIII', desc)
        if name_rva == 0:
            break
        nm = (pe.read_va(pe.image_base + name_rva, 256) or b'').split(b'\0')[0].decode('latin1')
        names = []
        thunk = pe.image_base + (oft or first_thunk)
        for i in range(4096):
            v = pe.read_va(thunk + i * 4, 4)
            if not v or len(v) < 4:
                break
            v = int.from_bytes(v, 'little')
            if v == 0:
                break
            if v & 0x80000000:
                names.append('#%d' % (v & 0xFFFF))
            else:
                hint = pe.read_va(pe.image_base + v + 2, 128) or b''
                names.append(hint.split(b'\0')[0].decode('latin1'))
        out[nm] = names
        va += 20
    for nm, names in out.items():
        if want and want not in nm.lower():
            continue
        print('== %s (%d) ==' % (nm, len(names)))
        for n in names:
            print('   ' + n)


if __name__ == '__main__':
    main()
