import mpq, os, re, sys

P = r'C:\3rd\war5-jass\jass_plugin\w3x2lni_zhCN_v2.5.2\w3x2lni_zhCN_v2.5.2\0mxd\C813AFB5C5992CB8333A76C4FEF3186D.w3x'
OUT = r'lua_tree'
m = mpq.MPQ(P)
os.makedirs(OUT, exist_ok=True)

req_re = re.compile(rb'''require\s*\(?\s*['"]([A-Za-z0-9_\-\.]+)['"]''')

seen = {}
queue = ['h-lua-cli.lua']
while queue:
    name = queue.pop()
    if name in seen:
        continue
    d = m.read_file(name)
    if d is None:
        seen[name] = None
        continue
    seen[name] = d
    for mm in req_re.finditer(d):
        mod = mm.group(1).decode()
        queue.append(mod.replace('.', '\\') + '.lua')

ok = 0
for name, d in seen.items():
    if d is None:
        print('MISSING', name)
        continue
    path = os.path.join(OUT, name.replace('\\', os.sep))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'wb') as f:
        f.write(d)
    ok += 1
print('extracted', ok, 'missing', sum(1 for v in seen.values() if v is None))
for name, d in sorted(seen.items()):
    if d is not None:
        print('%8d  %s' % (len(d), name))
