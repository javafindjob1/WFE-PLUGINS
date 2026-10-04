const fs = require('fs');
const path = require('path');

const dll = process.argv[2] || "C:\\3rd\\wc3gamesearcher\\WFE\\Application\\WFEDll.dll";
const outDir = process.argv[3] || "C:\\3rd\\wc3gamesearcher\\WFE\\Application\\re_analysis";
const buf = fs.readFileSync(dll);
const base = 0x400000; // typical image base for DLL

function u16(o) { return buf.readUInt16LE(o); }
function u32(o) { return buf.readUInt32LE(o); }

// --- PE parse ---
const e_lfanew = u32(0x3C);
const optOff = e_lfanew + 4 + 20;
const numDirs = u32(optOff + 92);
const dirOff = optOff + 96;
function dir(i) { return { va: u32(dirOff + i*8), size: u32(dirOff + i*8 + 4) }; }
const numSections = u16(e_lfanew + 4 + 2);
const secOff = optOff + u16(e_lfanew + 4 + 16); // size of optional header = optOff? no
// sizeOfOptionalHeader is at e_lfanew+4+16
const sizeOpt = u16(e_lfanew + 4 + 16);
const sectionTable = optOff + sizeOpt;

const sections = [];
for (let i = 0; i < numSections; i++) {
  const s = sectionTable + i * 40;
  const name = buf.toString('ascii', s, s + 8).replace(/\0.*$/, '');
  sections.push({
    name,
    vsize: u32(s + 8),
    va: u32(s + 12),
    rawSize: u32(s + 16),
    rawPtr: u32(s + 20),
  });
}
function rvaToOff(rva) {
  for (const s of sections) {
    if (rva >= s.va && rva < s.va + Math.max(s.vsize, s.rawSize)) {
      return s.rawPtr + (rva - s.va);
    }
  }
  return -1;
}
function cstr(off) { // read null-terminated ascii at file offset
  let e = off;
  while (e < buf.length && buf[e] !== 0) e++;
  return buf.toString('ascii', off, e);
}
function cstrAtRva(rva) { return cstr(rvaToOff(rva)); }

const out = [];
function log(s) { out.push(s); }

log('=== SECTIONS ===');
for (const s of sections) {
  log(`${s.name.padEnd(8)} VA=0x${s.va.toString(16)} VSize=0x${s.vsize.toString(16)} RawPtr=0x${s.rawPtr.toString(16)} RawSize=0x${s.rawSize.toString(16)}`);
}

// --- Exports ---
const exp = dir(0);
log('\n=== EXPORTS (directory RVA=0x' + exp.va.toString(16) + ') ===');
if (exp.va) {
  const off = rvaToOff(exp.va);
  const nameRva = u32(off + 12);
  const baseOrd = u32(off + 16);
  const numFuncs = u32(off + 20);
  const numNames = u32(off + 24);
  const addrFuncs = u32(off + 28);
  const addrNames = u32(off + 32);
  const addrOrds = u32(off + 36);
  log(`DLL Name: ${cstrAtRva(nameRva)}`);
  log(`Base ordinal: ${baseOrd}, num functions: ${numFuncs}, num names: ${numNames}`);
  const funcs = [];
  for (let i = 0; i < numFuncs; i++) {
    const frva = u32(rvaToOff(addrFuncs) + i*4);
    if (frva) funcs.push({ ord: baseOrd + i, rva: frva });
  }
  for (let i = 0; i < numNames; i++) {
    const nrva = u32(rvaToOff(addrNames) + i*4);
    const ordIdx = u16(rvaToOff(addrOrds) + i*2);
    const name = cstrAtRva(nrva);
    const f = funcs.find(x => x.ord === baseOrd + ordIdx);
    log(`ord=${(baseOrd+ordIdx).toString().padStart(4)} rva=0x${(f?f.rva:0).toString(16).padStart(8)}  ${name}`);
  }
}

// --- Imports ---
const imp = dir(1);
log('\n=== IMPORTS ===');
if (imp.va) {
  let off = rvaToOff(imp.va);
  while (true) {
    const d = { origFirstThunk: u32(off), tStamp: u32(off+4), fChain: u32(off+8), name: u32(off+12), firstThunk: u32(off+16) };
    if (d.origFirstThunk === 0 && d.name === 0 && d.firstThunk === 0) break;
    const dllName = cstrAtRva(d.name);
    log(`\n[DLL] ${dllName}`);
    // iterate thunks
    const thunkBase = d.origFirstThunk ? rvaToOff(d.origFirstThunk) : rvaToOff(d.firstThunk);
    const iatBase = rvaToOff(d.firstThunk);
    for (let i = 0; ; i++) {
      const tv = u32(thunkBase + i*4);
      if (tv === 0) break;
      if (tv & 0x80000000) {
        log(`  ord#${tv & 0xFFFF}`);
      } else {
        const h = rvaToOff(tv & 0x7FFFFFFF);
        const name = cstr(h + 2);
        const iatVal = iatBase >= 0 ? u32(iatBase + i*4) : 0;
        log(`  ${name}`);
      }
    }
    off += 20;
  }
}

// --- Strings: ASCII ---
log('\n=== ASCII STRINGS (len>=4) ===');
{
  const seen = new Map();
  let i = 0;
  while (i < buf.length) {
    if (buf[i] >= 0x20 && buf[i] < 0x7F) {
      let j = i;
      while (j < buf.length && buf[j] >= 0x20 && buf[j] < 0x7F) j++;
      if (j - i >= 4) {
        const s = buf.toString('ascii', i, j);
        seen.set(s, i);
      }
      i = j;
    } else i++;
  }
  const items = [...seen.entries()].sort((a,b)=>a[0].localeCompare(b[0]));
  for (const [s, off] of items) log(`0x${off.toString(16).padStart(8)}  ${s}`);
}

fs.writeFileSync(path.join(outDir, 'pe_analysis.txt'), out.join('\n'), 'utf8');
console.log('Wrote pe_analysis.txt, lines:', out.length);
