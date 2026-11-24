const fs = require('fs');
const path = require('path');

const dll = process.argv[2] || "C:\\3rd\\wc3gamesearcher\\WFE\\Application\\WFEDll.dll";
const outDir = process.argv[3] || "C:\\3rd\\wc3gamesearcher\\WFE\\Application\\re_analysis";
const buf = fs.readFileSync(dll);

const out = [];
function log(s) { out.push(s); }

// --- UTF-16LE strings (wide strings) ---
log('=== UTF-16LE STRINGS (len>=3, non-ascii) ===');
{
  const seen = new Map();
  let i = 0;
  while (i + 1 < buf.length) {
    const c = buf.readUInt16LE(i);
    if (c >= 0x20 && c < 0xFFFE) {
      let j = i;
      const chars = [];
      while (j + 1 < buf.length) {
        const cc = buf.readUInt16LE(j);
        if (cc >= 0x20 && cc < 0xFFFE) { chars.push(cc); j += 2; }
        else break;
      }
      if (chars.length >= 3) {
        const s = String.fromCharCode(...chars);
        if (/[\u0080-\uFFFF]/.test(s) && !seen.has(s)) seen.set(s, i);
      }
      i = j + 2;
    } else i += 2;
  }
  const items = [...seen.entries()].sort((a,b)=>a[1]-b[1]);
  for (const [s, off] of items) log(`0x${off.toString(16).padStart(8)}  ${s}`);
}

// --- GBK (ANSI Chinese) strings ---
log('\n=== GBK / ANSI STRINGS (containing CJK, len>=4) ===');
{
  const gd = new TextDecoder('gbk');
  const runs = [];
  let i = 0;
  while (i < buf.length) {
    const b = buf[i];
    let start = -1;
    // find start of a run: printable ascii or valid gbk lead
    if (b >= 0x20 && b < 0x7F) start = i;
    else if (b >= 0x81 && b <= 0xFE && i + 1 < buf.length) {
      const t = buf[i+1];
      if (t >= 0x40 && t <= 0xFE && t !== 0x7F) start = i;
    }
    if (start < 0) { i++; continue; }
    // extend run
    let j = start;
    const bytes = [];
    while (j < buf.length) {
      const bb = buf[j];
      if (bb >= 0x20 && bb < 0x7F) { bytes.push(bb); j++; }
      else if (bb >= 0x81 && bb <= 0xFE && j + 1 < buf.length) {
        const t = buf[j+1];
        if (t >= 0x40 && t <= 0x7F && t !== 0x7F) { bytes.push(bb, t); j += 2; }
        else if (t >= 0x80 && t <= 0xFE) { bytes.push(bb, t); j += 2; }
        else break;
      } else break;
    }
    if (bytes.length >= 4) runs.push({ off: start, bytes: Buffer.from(bytes) });
    i = j;
  }
  const seen = new Map();
  for (const r of runs) {
    let s;
    try { s = gd.decode(r.bytes); } catch (e) { continue; }
    if (/[\u4e00-\u9fff]/.test(s) && !seen.has(s)) seen.set(s, r.off);
  }
  const items = [...seen.entries()].sort((a,b)=>a[1]-b[1]);
  for (const [s, off] of items) log(`0x${off.toString(16).padStart(8)}  ${s}`);
}

fs.writeFileSync(path.join(outDir, 'strings2.txt'), out.join('\n'), 'utf8');
console.log('Wrote strings2.txt, lines:', out.length);
