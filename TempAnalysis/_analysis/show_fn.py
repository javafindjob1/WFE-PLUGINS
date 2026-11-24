"""Print selected parts of a rea CLI JSON result (function dossier).

Usage:
  python show_fn.py <json> [pseudo|calls|strings|refs|all] [--limit N]
"""
import json, sys, io


def main():
    path = sys.argv[1]
    what = sys.argv[2] if len(sys.argv) > 2 else 'pseudo'
    limit = 400
    for i, a in enumerate(sys.argv):
        if a == '--limit' and i + 1 < len(sys.argv):
            limit = int(sys.argv[i + 1])

    with io.open(path, 'r', encoding='utf-8', errors='replace') as f:
        doc = json.load(f)

    data = doc.get('result', doc)
    ident = data.get('identity') or {}
    print('== identity ==')
    for k in ('name', 'entry', 'signature', 'size', 'blocks'):
        if k in ident:
            print('  %s: %s' % (k, ident[k]))
    proc = data.get('procedure') or {}
    for k in ('name', 'entry', 'canonical_entry', 'size', 'block_count'):
        if k in proc:
            print('  procedure.%s: %s' % (k, proc[k]))
    if data.get('limitations'):
        print('== limitations ==')
        for l in data['limitations']:
            print('  - ' + l)

    if what in ('pseudo', 'all'):
        pc = data.get('pseudocode') or data.get('decompilation') or {}
        text = pc.get('text') if isinstance(pc, dict) else pc
        print('== pseudocode ==')
        print((text or '(none)')[:20000])

    if what in ('calls', 'all'):
        calls = data.get('calls') or data.get('callees') or []
        print('== calls (%d) ==' % len(calls))
        for c in calls[:limit]:
            if isinstance(c, dict):
                print('  %s %s' % (c.get('name') or c.get('target') or '?', c.get('entry') or ''))
            else:
                print('  %s' % (c,))

    if what in ('strings', 'all'):
        strs = data.get('strings') or data.get('referenced_strings') or []
        print('== strings (%d) ==' % len(strs))
        for s in strs[:limit]:
            if isinstance(s, dict):
                print('  %s  %r' % (s.get('address') or '', s.get('value') or s.get('text') or ''))
            else:
                print('  %r' % (s,))


if __name__ == '__main__':
    main()
