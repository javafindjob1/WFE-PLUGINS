const fs=require('fs');
const t=fs.readFileSync('ddh.cpp','utf8').split(/\r?\n/);
const re=/[\u0370-\u04ff\u0080-\u00ff]/;
let hit=[];
t.forEach((l,i)=>{ if(re.test(l)) hit.push((i+1)+': '+l.trim().slice(0,120)); });
console.log('lines',hit.length); hit.slice(0,40).forEach(x=>console.log(x));
