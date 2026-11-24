"""Extract named entries from an MPQ into an output directory.

Usage:
  python mpq_extract.py <archive.mpq> <outdir> <name> [name...]
"""
import sys, os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from mpq import MPQ


def main():
    path, outdir = sys.argv[1], sys.argv[2]
    names = sys.argv[3:]
    os.makedirs(outdir, exist_ok=True)
    m = MPQ(path)
    for name in names:
        raw = m.read_file(name)
        if raw is None:
            print('MISS %s' % name)
            continue
        dst = os.path.join(outdir, name.replace('\\', '_').replace('/', '_'))
        with open(dst, 'wb') as f:
            f.write(raw)
        print('OK %-60s %8d -> %s' % (name, len(raw), dst))


if __name__ == '__main__':
    main()
