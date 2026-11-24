"""Find 32-bit pointers to a VA and dump surrounding dwords (PE32).

Usage:
  python ptr_scan.py <pe> <va-hex> [before] [after]
  python ptr_scan.py <pe> --string <substring> [before] [after]
"""
import sys, os
from pe_probe import PE


def dump(pe, va, before=4, after=6):
    needle = va.to_bytes(4, 'little')
    out = []
    for s in pe.sections:
        d = pe.buf[s['raw']:s['raw'] + s['rsize']]
        i = 0
        while True:
            j = d.find(needle, i)
            if j < 0:
                break
            off = s['va'] + j
            rows = []
            for k in range(-before, after + 1):
                p = off + k * 4
                raw = pe.read_va(p, 4)
                if raw is None or len(raw) < 4:
                    continue
                v = int.from_bytes(raw, 'little')
                tag = '<-- target' if k == 0 else ''
                rows.append('0x%08X: 0x%08X %s' % (p, v, tag))
            out.append((off, s['name'], rows))
            i = j + 1
    return out


def main():
    pe = PE(sys.argv[1])
    if sys.argv[2] == '--string':
        vas = []
        for va in pe.find(sys.argv[3]):
            vas.append(va)
        print('string VAs: ' + ', '.join('0x%08X' % v for v in vas))
    else:
        vas = [int(sys.argv[2], 16)]
    before = int(sys.argv[4]) if len(sys.argv) > 4 else 4
    after = int(sys.argv[5]) if len(sys.argv) > 5 else 6
    for va in vas:
        for off, sec, rows in dump(pe, va, before, after):
            print('--- %s @0x%08X ---' % (sec, off))
            for r in rows:
                print('   ' + r)


if __name__ == '__main__':
    main()
