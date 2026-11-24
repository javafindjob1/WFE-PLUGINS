"""Minimal PE32 helpers (no pefile): sections, imports, strings, capstone xrefs.

Usage:
  python pe_probe.py info  <pe>
  python pe_probe.py find  <pe> <substring> [substring...]
  python pe_probe.py xref  <pe> <substring>...
"""
import sys, os, struct
from capstone import Cs, CS_ARCH_X86, CS_MODE_32


class PE:
    def __init__(self, path):
        self.path = path
        self.buf = open(path, 'rb').read()
        b = self.buf
        e_lfanew = struct.unpack_from('<I', b, 0x3C)[0]
        assert b[e_lfanew:e_lfanew + 4] == b'PE\0\0'
        coff = e_lfanew + 4
        num_sec = struct.unpack_from('<H', b, coff + 2)[0]
        opt_size = struct.unpack_from('<H', b, coff + 16)[0]
        opt = coff + 20
        self.magic = struct.unpack_from('<H', b, opt)[0]
        self.image_base = struct.unpack_from('<I', b, opt + 28)[0]
        self.entry = self.image_base + struct.unpack_from('<I', b, opt + 16)[0]
        self.num_dirs = struct.unpack_from('<I', b, opt + 92)[0]
        self.dirs = []
        for i in range(self.num_dirs):
            rva, size = struct.unpack_from('<II', b, opt + 96 + i * 8)
            self.dirs.append((rva, size))
        self.sections = []
        sec = opt + opt_size
        for i in range(num_sec):
            o = sec + i * 40
            name = b[o:o + 8].rstrip(b'\0').decode('latin1')
            vsize, va, rsize, raw = struct.unpack_from('<IIII', b, o + 8)
            self.sections.append(dict(name=name, va=self.image_base + va, rva=va,
                                      rsize=rsize, raw=raw, vsize=vsize))

    def sec_of_va(self, va):
        for s in self.sections:
            if s['va'] <= va < s['va'] + max(s['rsize'], s['vsize']):
                return s
        return None

    def read_va(self, va, n):
        s = self.sec_of_va(va)
        if not s:
            return None
        off = s['raw'] + (va - s['va'])
        return self.buf[off:off + n]

    def find(self, needle):
        out = []
        b = needle.encode('utf-8') + b'\x00'
        for s in self.sections:
            d = self.buf[s['raw']:s['raw'] + s['rsize']]
            i = 0
            while True:
                j = d.find(b, i)
                if j < 0:
                    break
                out.append(s['va'] + j)
                i = j + 1
        return out

    def exports(self):
        """Return [(name, va)] for named exports (PE32)."""
        if not self.dirs or self.dirs[0][0] == 0:
            return []
        rva, size = self.dirs[0]
        d = self.read_va(self.image_base + rva, 40)
        if not d or len(d) < 40:
            return []
        (chars, ts, maj, mnr, name_rva, base_ord, nfunc, nname,
         addr_funcs, addr_names, addr_ords) = struct.unpack('<IIHHIIIIIII', d)
        funcs = self.read_va(self.image_base + addr_funcs, 4 * nfunc) or b''
        names = self.read_va(self.image_base + addr_names, 4 * nname) or b''
        ords = self.read_va(self.image_base + addr_ords, 2 * nname) or b''
        out = []
        for i in range(nname):
            nr = struct.unpack_from('<I', names, i * 4)[0]
            oi = struct.unpack_from('<H', ords, i * 2)[0]
            if oi >= nfunc:
                continue
            fr = struct.unpack_from('<I', funcs, oi * 4)[0]
            p = self.read_va(self.image_base + nr, 256) or b''
            nm = p.split(b'\0')[0].decode('latin1')
            out.append((nm, self.image_base + fr))
        return out


def main():
    cmd, path = sys.argv[1], sys.argv[2]
    pe = PE(path)

    if cmd == 'info':
        print('%s base=0x%X entry=0x%X dirs=%d' % (os.path.basename(path), pe.image_base, pe.entry, pe.num_dirs))
        for s in pe.sections:
            print('  %-10s va=0x%08X raw=0x%08X rsize=0x%X vsize=0x%X' % (
                s['name'], s['va'], s['raw'], s['rsize'], s['vsize']))
        ex = pe.exports()
        print('exports=%d' % len(ex))
        for nm, va in ex[:80]:
            print('  0x%08X %s' % (va, nm))
        return

    needles = sys.argv[3:]
    if cmd == 'find':
        for n in needles:
            for va in pe.find(n):
                print('0x%08X  %s' % (va, n))
        return

    if cmd == 'xref':
        targets = {}
        for n in needles:
            for va in pe.find(n):
                targets[va] = n
        print('targets: ' + ', '.join('0x%08X' % t for t in sorted(targets)))
        text = next((s for s in pe.sections if s['name'] == '.text'), None)
        if text is None:
            text = max(pe.sections, key=lambda s: s['rsize'])
        md = Cs(CS_ARCH_X86, CS_MODE_32)
        data = pe.buf[text['raw']:text['raw'] + text['rsize']]
        for insn in md.disasm(data, text['va']):
            for t in targets:
                if hex(t) in insn.op_str:
                    print('0x%08X  %-8s %-44s -> 0x%08X (%s)' % (
                        insn.address, insn.mnemonic, insn.op_str, t, targets[t]))
                    break
        return


if __name__ == '__main__':
    main()
