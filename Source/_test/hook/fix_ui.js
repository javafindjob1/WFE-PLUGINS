const fs=require('fs');
const p='ddh.cpp';
const L=fs.readFileSync(p,'utf8').split(/\r?\n/);
L[11465]='    if (!DdhInitUiFuncs()) { LogLine("图表调试：UI 函数未就绪"); return; }';
L[11514]='    if (!DdhInitUiFuncs()) { LogLine("图表演示：UI 函数未就绪"); return; }';
fs.writeFileSync(p,L.join('\r\n'),'utf8'); console.log('ok');
