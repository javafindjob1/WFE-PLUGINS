import sys, struct
import pefile

PATH = r'C:\3rd\war5\game.dll'
pe = pefile.PE(PATH, fast_load=True)
BASE = pe.OPTIONAL_HEADER.ImageBase
raw = open(PATH, 'rb').read()


def secs():
    for s in pe.sections:
        yield s, s.PointerToRawData, s.SizeOfRawData, BASE + s.VirtualAddress


def off2va(off):
    for s, pr, sr, va in secs():
        if pr <= off < pr + sr:
            return va + (off - pr)
    return None


def va2off(va):
    for s, pr, sr, base in secs():
        if base <= va < base + sr:
            return pr + (va - base)
    return None


def xtargets():
    for s, pr, sr, va in secs():
        if b'.text' not in s.Name:
            continue
        d = raw[pr:pr + sr]
        i = 0
        n = len(d)
        while i < n - 5:
            if d[i] == 0xE8:
                rel = struct.unpack('<i', d[i + 1:i + 5])[0]
                src = va + i
                yield src, (src + 5 + rel) & 0xFFFFFFFF
            i += 1


if __name__ == '__main__':
    targets = [int(x, 16) for x in sys.argv[1:]]
    tset = set(targets)
    hits = {t: [] for t in targets}
    for src, dst in xtargets():
        if dst in tset:
            hits[dst].append(src)
    for t in targets:
        print(hex(t), len(hits[t]))
        for h in hits[t][:20]:
            print('   call at', hex(h))
