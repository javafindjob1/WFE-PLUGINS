const fs=require('fs');
const p='ddh.cpp';
let t=fs.readFileSync(p,'utf8');
let n=0;
t=t.replace(/static void DdhChartDebugShow\(void\)\r?\n\{\r?\n(\s*)uint32_t ui = DdhGetGameUi\(\);/,(m,sp)=>{n++;return 'static void DdhChartDebugShow(void)\r\n{\r\n'+sp+'if (!DdhInitUiFuncs()) { LogLine("图表调试：UI 函数未就绪"); return; }\r\n'+sp+'uint32_t ui = DdhGetGameUi();';});
t=t.replace(/static void DdhChartDemoShow\(void\)\r?\n\{\r?\n(\s*)uint32_t ui = DdhGetGameUi\(\);/,(m,sp)=>{n++;return 'static void DdhChartDemoShow(void)\r\n{\r\n'+sp+'if (!DdhInitUiFuncs()) { LogLine("图表演示：UI 函数未就绪"); return; }\r\n'+sp+'uint32_t ui = DdhGetGameUi();';});
fs.writeFileSync(p,t,'utf8');
console.log('patched',n);
