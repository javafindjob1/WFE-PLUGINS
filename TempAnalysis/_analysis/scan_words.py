"""Scan binaries for Chinese labels / ascii tokens in several encodings.

Usage:
  python scan_words.py <file> [<file>...]
Prints counts per word and encoding, plus first UTF-16 context hit.
"""
import sys, os

WORDS = [
    '\u5546\u57ce',      # 商城
    '\u8bbe\u7f6e',      # 设置
    '\u5546\u5e97',      # 商店
    '\u80cc\u5305',      # 背包
    '\u6218\u7ee9',      # 战绩
    '\u9000\u51fa',      # 退出
    '\u6e38\u620f',      # 游戏
]

ENCS = [('utf8', 'utf-8'), ('u16', 'utf-16-le'), ('gbk', 'gbk')]


def main():
    for path in sys.argv[1:]:
        if not os.path.isfile(path):
            continue
        b = open(path, 'rb').read()
        print('=== %s (%d bytes) ===' % (os.path.basename(path), len(b)))
        for w in WORDS:
            row = []
            for name, enc in ENCS:
                try:
                    pat = w.encode(enc)
                except Exception:
                    continue
                n = b.count(pat)
                if n:
                    row.append('%s=%d' % (name, n))
            if row:
                print('  %s -> %s' % (w, ' '.join(row)))
        # first utf-16 context for 商城
        pat = WORDS[0].encode('utf-16-le')
        i = b.find(pat)
        if i >= 0:
            ctx = b[max(0, i - 80):i + 80].decode('utf-16-le', 'ignore')
            print('  ctx(商城): %r' % ctx)


if __name__ == '__main__':
    main()
