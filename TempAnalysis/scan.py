import mpq, os, sys, zlib

p = r'C:\3rd\war5-jass\jass_plugin\w3x2lni_zhCN_v2.5.2\w3x2lni_zhCN_v2.5.2\0mxd\C813AFB5C5992CB8333A76C4FEF3186D.w3x'
out = r'lua_scan'
os.makedirs(out, exist_ok=True)
m = mpq.MPQ(p)
print('blocks', len(m.block_entries))

MAGICS = (b'MDLX', b'BLP1', b'BLP2', b'RIFF', b'OggS', b'ID3\x03', b'\x89PNG', b'DDS ', b'\x00\x00\x00\x00')
found = 0
for i in range(len(m.block_entries)):
    off, cs, fs, fl = m.block_entries[i]
    if fs == 0 or fs > 8 * 1024 * 1024 or not (fl & 0x80000000):
        continue
    if fl & 0x02000000:
        continue
    try:
        d = m.read_block(i)
    except Exception:
        continue
    if not d or len(d) < 20:
        continue
    if d[:4] in MAGICS:
        continue
    head = d[:4096]
    bad = sum(1 for b in head if b < 9 or (13 < b < 32) or b > 126)
    if bad > len(head) * 0.02:
        continue
    if (b'function' in d) or (b'local ' in d) or d.lstrip().startswith(b'--'):
        name = os.path.join(out, '%05d_%d.lua' % (i, len(d)))
        with open(name, 'wb') as fh:
            fh.write(d)
        found += 1
print('lua-like', found)
