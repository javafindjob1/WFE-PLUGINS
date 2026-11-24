import struct, zlib, sys, os, bz2

def _build():
    table = [0] * 0x500
    seed = 0x00100001
    for index1 in range(0x100):
        index2 = index1
        for _ in range(5):
            seed = (seed * 125 + 3) % 0x2AAAAB
            temp1 = (seed & 0xFFFF) << 0x10
            seed = (seed * 125 + 3) % 0x2AAAAB
            temp2 = seed & 0xFFFF
            table[index2] = (temp1 | temp2) & 0xFFFFFFFF
            index2 += 0x100
    return table

CRYPT = _build()

def h(s, htype):
    s = s.upper().replace('/', '\\')
    seed1 = 0x7FED7FED
    seed2 = 0xEEEEEEEE
    for ch in s:
        c = ord(ch)
        seed1 = (CRYPT[(htype << 8) + c] ^ ((seed1 + seed2) & 0xFFFFFFFF)) & 0xFFFFFFFF
        seed2 = (c + seed1 + seed2 + (seed2 << 5) + 3) & 0xFFFFFFFF
    return seed1

def decrypt(data, key):
    seed1 = key
    seed2 = 0xEEEEEEEE
    out = []
    for v in data:
        seed2 = (seed2 + CRYPT[0x400 + (seed1 & 0xFF)]) & 0xFFFFFFFF
        v = (v ^ (seed1 + seed2)) & 0xFFFFFFFF
        out.append(v)
        seed1 = ((((~seed1) << 21) + 0x11111111) | (seed1 >> 11)) & 0xFFFFFFFF
        seed2 = (v + seed2 + (seed2 << 5) + 3) & 0xFFFFFFFF
    return out

F_IMPLODE = 0x00000100
F_COMPRESS = 0x00000200
F_ENCRYPT = 0x00010000
F_FIXKEY = 0x00020000
F_SINGLE = 0x01000000
F_DELETE = 0x02000000
F_CRC = 0x04000000
F_EXISTS = 0x80000000

class MPQ:
    def __init__(self, path):
        self.path = path
        self.f = open(path, 'rb')
        self.f.seek(0)
        base = 0
        if self.f.read(4) != b'MPQ\x1a':
            self.f.seek(0x200)
            if self.f.read(4) != b'MPQ\x1a':
                raise RuntimeError('no MPQ header')
            base = 0x200
        self.base = base
        self.f.seek(base)
        hdr = self.f.read(32)
        (self.magic, self.hdr_size, self.arch_size, self.fmt,
         self.sector_shift, self.hash_pos, self.block_pos,
         self.hash_size, self.block_size) = struct.unpack('<4sIIHHIIII', hdr)
        self.sector_size = 512 << self.sector_shift
        self.load_tables()

    def load_tables(self):
        self.f.seek(self.hash_pos + self.base)
        raw = self.f.read(self.hash_size * 16)
        words = list(struct.unpack('<%dI' % (len(raw) // 4), raw))
        dec = decrypt(words, h('(hash table)', 3))
        if self._score_hash(dec) < self._score_hash(words):
            dec = words
        self.hash_entries = [(dec[i], dec[i + 1], dec[i + 2] & 0xFFFF, dec[i + 3])
                             for i in range(0, len(dec), 4)]
        self.f.seek(self.block_pos + self.base)
        raw = self.f.read(self.block_size * 16)
        words = list(struct.unpack('<%dI' % (len(raw) // 4), raw))
        dec = decrypt(words, h('(block table)', 3))
        if self._score_block(dec) < self._score_block(words):
            dec = words
        self.block_entries = [(dec[i], dec[i + 1], dec[i + 2], dec[i + 3])
                              for i in range(0, len(dec), 4)]

    def _score_hash(self, w):
        n = ok = 0
        for i in range(0, min(len(w), 800), 4):
            n += 1
            c, d = w[i + 2] & 0xFFFF, w[i + 3]
            if c in (0, 0xFFFF) and (d == 0xFFFFFFFF or d < self.block_size):
                ok += 1
        return ok / max(n, 1)

    def _score_block(self, w):
        n = ok = 0
        for i in range(0, min(len(w), 800), 4):
            n += 1
            off, cs, fs, fl = w[i], w[i + 1], w[i + 2], w[i + 3]
            if off < self.arch_size and cs <= self.arch_size and fs <= 64 * 1024 * 1024 and fl & 0x80000000:
                ok += 1
        return ok / max(n, 1)

    def find(self, name):
        a = h(name, 1)
        b = h(name, 2)
        idx = h(name, 0) % len(self.hash_entries)
        for i in range(len(self.hash_entries)):
            k = (idx + i) % len(self.hash_entries)
            ent = self.hash_entries[k]
            if ent[3] != 0xFFFFFFFF and ent[0] == a and ent[1] == b:
                return k
        return None

    def read_block(self, bi):
        off, csize, fsize, flags = self.block_entries[bi]
        if fsize == 0 or flags & F_DELETE:
            return None
        self.f.seek(self.base + off)
        raw = self.f.read(csize)
        key = None
        return self.decode(raw, fsize, flags, key)

    def read_file(self, name):
        hi = self.find(name)
        if hi is None:
            return None
        bi = self.hash_entries[hi][3]
        off, csize, fsize, flags = self.block_entries[bi]
        self.f.seek(self.base + off)
        raw = self.f.read(csize)
        key = None
        if flags & F_ENCRYPT:
            key = h(os.path.basename(name.replace('/', '\\')), 3)
        return self.decode(raw, fsize, flags, key)

    def decode(self, raw, fsize, flags, key=None):
        if flags & F_ENCRYPT and key is not None:
            if flags & F_FIXKEY:
                key = (key + self.base) & 0xFFFFFFFF
            words = list(struct.unpack('<%dI' % (len(raw) // 4), raw[:len(raw) // 4 * 4]))
            raw = struct.pack('<%dI' % len(words), *decrypt(words, (key + 0xEEEEEEEE) & 0xFFFFFFFF))
        if flags & F_COMPRESS:
            if flags & F_SINGLE:
                return self._one(raw, fsize)
            res = self._sectors(raw, fsize)
            if res is not None and len(res) == fsize:
                return res
            return self._one(raw, fsize)
        if flags & F_IMPLODE:
            # PKWARE implode; not implemented
            return None
        return raw[:fsize]

    def _sectors(self, raw, fsize):
        sec = self.sector_size
        n = (fsize + sec - 1) // sec
        tbl = 4 * (n + 1)
        if len(raw) < tbl:
            return None
        offs = struct.unpack('<%dI' % (n + 1), raw[:tbl])
        if offs[0] < tbl or offs[0] > tbl + 64:
            return None
        if any(offs[i] > offs[i + 1] for i in range(n)):
            return None
        if offs[n] > len(raw):
            return None
        out = bytearray()
        for i in range(n):
            start, end = offs[i], offs[i + 1]
            want = min(sec, fsize - len(out))
            if start == end:
                out += b'\x00' * want
                continue
            part = self._one(raw[start:end], want)
            if len(part) != want:
                return None
            out += part
        return bytes(out[:fsize])

    def _one(self, raw, fsize):
        if not raw:
            return b''
        t = raw[0]
        body = raw[1:]
        try:
            if t == 2:
                return zlib.decompress(body)[:fsize]
            if t == 0x10:
                return bz2.decompress(body)[:fsize]
            if t == 1:
                return body[:fsize]
        except Exception:
            pass
        try:
            return zlib.decompress(raw)[:fsize]
        except Exception:
            return raw[:fsize]

if __name__ == '__main__':
    p = sys.argv[1]
    m = MPQ(p)
    print('base', hex(m.base), 'fmt', m.fmt, 'sector', m.sector_size,
          'hash', m.hash_size, 'blocks', m.block_size, 'arch', m.arch_size)
    for name in sys.argv[2:]:
        r = m.read_file(name)
        print(name, '->', None if r is None else len(r))
