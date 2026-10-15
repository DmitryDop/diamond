import { spawn } from 'node:child_process';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
const root=resolve(import.meta.dirname,'..'),profile=resolve(root,'qa/.logo-check-profile');
await mkdir(profile,{recursive:true});
const chrome=spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',[
  '--headless=new','--no-first-run','--no-default-browser-check','--disable-background-networking',
  '--remote-debugging-port=0',`--user-data-dir=${profile}`,'about:blank'
],{stdio:'ignore'});
const wait=ms=>new Promise(r=>setTimeout(r,ms));
let ws;
try{
 let target;
 for(let attempt=0;attempt<100;attempt++){try{const port=(await readFile(resolve(profile,'DevToolsActivePort'),'utf8')).split('\n')[0];target=await(await fetch(`http://127.0.0.1:${port}/json/new?about:blank`,{method:'PUT'})).json();break;}catch{await wait(100);}}
 if(!target)throw Error('Chrome did not start');
 ws=new WebSocket(target.webSocketDebuggerUrl);await new Promise((r,j)=>{ws.onopen=r;ws.onerror=j;});
 let id=0;const pending=new Map(),consoleErrors=[],httpErrors=[],iconRequests=[];
 ws.onmessage=event=>{
  const m=JSON.parse(event.data);if(m.id){const p=pending.get(m.id);pending.delete(m.id);m.error?p?.reject(Error(JSON.stringify(m.error))):p?.resolve(m.result);}
  if(m.method==='Runtime.exceptionThrown')consoleErrors.push(m.params.exceptionDetails.text+': '+(m.params.exceptionDetails.exception?.description||''));
  if(m.method==='Log.entryAdded'&&m.params.entry.level==='error')consoleErrors.push(m.params.entry.text);
  if(m.method==='Network.responseReceived'){
   const r=m.params.response;if(r.status>=400)httpErrors.push({url:r.url,status:r.status});
   if(/\/favicon\.(svg|ico)(\?|$)/.test(r.url))iconRequests.push({url:r.url,status:r.status});
  }
 };
 const send=(method,params={})=>new Promise((resolve,reject)=>{const n=++id;pending.set(n,{resolve,reject});ws.send(JSON.stringify({id:n,method,params}));});
 const evaluate=async expression=>{const r=await send('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(r.exceptionDetails.exception?.description||r.exceptionDetails.text);return r.result.value;};
 await send('Page.enable');await send('Runtime.enable');await send('Log.enable');await send('Network.enable');await send('Network.setCacheDisabled',{cacheDisabled:true});
 async function navigate(path){await send('Page.navigate',{url:`http://127.0.0.1:8765/${path}`});for(let i=0;i<200;i++){await wait(100);if(await evaluate("document.readyState==='complete'"))return;}throw Error('Page did not finish loading: '+path);}
 await send('Emulation.setDeviceMetricsOverride',{width:1440,height:1000,deviceScaleFactor:1,mobile:false});
 await navigate('qa/logo-favicon-review.html?final=1');
 let comparison;
 for(let i=0;i<30;i++){const text=await evaluate("document.querySelector('#report').textContent");try{comparison=JSON.parse(text);break;}catch{await wait(100);}}
 if(!comparison?.checks.clipRemovalIdentical||!comparison?.checks.optimizationVisuallyEquivalent)throw Error('Logo render comparison failed: '+JSON.stringify(comparison));
 await writeFile(resolve(root,'previews/logo-favicon-review-1440.png'),Buffer.from((await send('Page.captureScreenshot',{format:'png'})).data,'base64'));
 const viewports=[];
 for(const [width,height]of [[1440,900],[390,844],[320,740]]){
  await send('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});
  await navigate(`index.html?logo-qa=${width}`);
  await evaluate('document.fonts.ready.then(()=>true)');
  const data=await evaluate(`(()=>{const link=document.querySelector('.brand'),svg=link.querySelector('svg'),r=svg.getBoundingClientRect(),actions=document.querySelector('.header-actions').getBoundingClientRect(),links=[...document.querySelectorAll('head link[rel="icon"],head link[rel="apple-touch-icon"]')];return{width:innerWidth,height:innerHeight,viewBox:svg.getAttribute('viewBox'),logo:{x:r.x,y:r.y,width:r.width,height:r.height,right:r.right},actionsLeft:actions.left,href:link.getAttribute('href'),label:link.getAttribute('aria-label'),clipPaths:svg.querySelectorAll('clipPath').length,overflow:document.documentElement.scrollWidth>innerWidth,logoOverlapsActions:r.right>actions.left,favicons:links.map(e=>({type:e.type,href:e.getAttribute('href'),sizes:e.getAttribute('sizes')}))};})()`);
  viewports.push(data);
  await writeFile(resolve(root,`previews/final-header-${width}.png`),Buffer.from((await send('Page.captureScreenshot',{format:'png'})).data,'base64'));
 }
 const resources=await evaluate("Promise.all(['/favicon.svg','/favicon.ico','/apple-touch-icon.png'].map(async url=>{const r=await fetch(url,{cache:'no-store'});return{url,status:r.status,type:r.headers.get('content-type')};}))");
 const ico=await readFile(resolve(root,'favicon.ico')),reference=await readFile(resolve(root,'draft/32.png'));
 const entries=[];for(let i=0;i<ico.readUInt16LE(4);i++){const n=6+i*16,size=ico.readUInt32LE(n+8),offset=ico.readUInt32LE(n+12),png=ico.subarray(offset,offset+size);entries.push({width:ico[n],height:ico[n+1],pngWidth:png.readUInt32BE(16),pngHeight:png.readUInt32BE(20),referencePreserved:ico[n]===32?png.equals(reference):null});}
 const apple=await readFile(resolve(root,'apple-touch-icon.png'));
 const result={comparison,viewports,resources,icoEntries:entries,apple:{width:apple.readUInt32BE(16),height:apple.readUInt32BE(20)},iconRequests,consoleErrors,httpErrors};
 await writeFile(resolve(root,'qa/diamond-logo-favicon-browser-validation.json'),JSON.stringify(result,null,2)+'\n');
 console.log(JSON.stringify(result,null,2));
 if(viewports.some(x=>x.overflow||x.logoOverlapsActions||x.viewBox!=='0 0 203 48')||resources.some(x=>x.status!==200)||consoleErrors.length||httpErrors.length)process.exitCode=1;
}finally{ws?.close();chrome.kill('SIGTERM');}
