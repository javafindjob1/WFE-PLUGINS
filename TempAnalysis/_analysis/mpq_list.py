"""List / filter entries of an MPQ archive via (listfile).

Usage:
  python mpq_list.py <archive.mpq>                -> print summary + count
  python mpq_list.py <archive.mpq> --grep dz      -> filter names
  python mpq_list.py <archive.mpq> --ext fdf,blp  -> filter by extension
"""
import sys, os, re

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from mpq import MPQ


def get_listfile(m):
    raw = m.read_file('(listfile)')
    if not raw:
        # try lower / backslash variants
        for name in ('(listfile)', '(LISTFILE)', 'listfile'):
            raw = m.read_file(name)
            if raw:
                break
    if not raw:
        return []
    text = raw.decode('utf-8', 'ignore')
    return [ln.strip() for ln in text.splitlines() if ln.strip()]


def main():
    path = sys.argv[1]
    grep = None
    exts = None
    for i, a in enumerate(sys.argv):
        if a == '--grep' and i + 1 < len(sys.argv):
            grep = sys.argv[i + 1].lower()
        if a == '--ext' and i + 1 < len(sys.argv):
            exts = [('.' + e.strip().lstrip('.').lower()) for e in sys.argv[i + 1].split(',')]

    m = MPQ(path)
    names = get_listfile(m)
    print('archive=%s entries=%d base=0x%X fmt=%d sector=%d' % (
        os.path.basename(path), len(names), m.base, m.fmt, m.sector_size))
    sel = names
    if grep:
        sel = [n for n in sel if grep in n.lower()]
    if exts:
        sel = [n for n in sel if os.path.splitext(n)[1].lower() in exts]
    print('selected=%d' % len(sel))
    for n in sel[:400]:
        print(n)


if __name__ == '__main__':
    main()
