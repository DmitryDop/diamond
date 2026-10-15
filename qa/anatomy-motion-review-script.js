
const composition=document.querySelector('#composition');
const files=Array.from({length:10},(_,i)=>`${i+1}.png`).concat('planka.png','legenda.png');
function show(mode){composition.replaceChildren();for(const file of mode==='bat'?['bat.png']:files){const img=new Image();img.src=`../assets/diamond-anatomy/${file}`;composition.append(img);}}
document.querySelectorAll('[data-mode]').forEach(button=>button.onclick=()=>show(button.dataset.mode));show('final');
const site=document.querySelector('#site'),report=document.querySelector('#report');
const wait=ms=>new Promise(r=>setTimeout(r,ms));
async function load(width,height,reduced=false){
  composition.hidden=true;site.hidden=false;site.width=width;site.height=height;
  let html=await(await fetch('../index.html',{cache:'no-store'})).text();
  html=html.replace('src="js/main.js"',`src="js/main.js?qa=${Date.now()}"`).replace('href="css/styles.css"',`href="css/styles.css?qa=${Date.now()}"`);
  const setup=`<base href="../"><script>window.__errors=[];window.addEventListener('error',e=>window.__errors.push(e.message));${reduced?"const originalMatch=window.matchMedia.bind(window);window.matchMedia=q=>q.includes('prefers-reduced-motion')?{media:q,matches:q.includes(': reduce)'),addEventListener(){},removeEventListener(){},addListener(){},removeListener(){}}:originalMatch(q);":''}<\/script>`;
  html=html.replace('<head>','<head>'+setup);site.srcdoc=html;
  await new Promise(resolve=>site.onload=resolve);await wait(600);
  report.textContent=JSON.stringify({width,height,reduced,gsap:site.contentWindow.gsap?.version,ready:!!site.contentDocument.querySelector('[data-anatomy-ready]'),errors:site.contentWindow.__errors},null,2);
}
document.querySelector('#desktop').onclick=()=>load(1440,900);
document.querySelector('#mobile').onclick=()=>load(390,844);
document.querySelector('#reduced').onclick=()=>load(390,844,true);
async function scroll(p){const w=site.contentWindow,t=w.ScrollTrigger?.getById('anatomy-scroll');if(!t){report.textContent+='\nNo Anatomy trigger';return;}w.scrollTo({top:t.start+(t.end-t.start)*p,behavior:'instant'});await wait(100);w.ScrollTrigger.update();}
for(const [id,p]of [['start',0],['swap',.22],['middle',.5],['end',.9]])document.querySelector('#'+id).onclick=()=>scroll(p);
async function runChecks(){
 const w=site.contentWindow,d=site.contentDocument,g=w.gsap,t=w.ScrollTrigger?.getById('anatomy-scroll');
 const checks=[],check=(name,ok)=>{checks.push({name,ok});if(!ok)throw Error(name);};
 try{
 check('All source images decoded', [...d.querySelectorAll('.silhouette-art .anatomy-canvas img')].every(e=>e.complete&&e.naturalWidth===2000));
 const bat=d.querySelector('.anatomy-bat'),parts=d.querySelector('.anatomy-parts'),legend=d.querySelector('.anatomy-legend'),pieces=[...parts.querySelectorAll('img')];
 const state=()=>[g.getProperty(bat,'opacity'),g.getProperty(parts,'opacity'),g.getProperty(legend,'opacity'),...pieces.flatMap(e=>[g.getProperty(e,'xPercent'),g.getProperty(e,'yPercent')])];
 if(w.matchMedia('(prefers-reduced-motion: reduce)').matches){check('Reduced motion has no Anatomy trigger',!t);check('Reduced motion shows final parts',getComputedStyle(parts).opacity==='1'&&getComputedStyle(legend).opacity==='1'&&getComputedStyle(bat).opacity==='0');}
 else{
 check('One scrub trigger',!!t&&t.vars.scrub===true&&w.ScrollTrigger.getAll().filter(x=>x.vars.id==='anatomy-scroll').length===1);
 await scroll(0);const initial=state();check('Intact entry',initial[0]===1&&initial[1]===0&&initial[2]===0);
 await scroll(.22);const swap=state();check('Crossfade overlaps',swap[0]>0&&swap[0]<1&&swap[1]>0&&swap[1]<1);
 await scroll(.5);const middle=state();check('Legend waits for assembly',middle[2]===0);await wait(350);check('No time-driven drift',JSON.stringify(state())===JSON.stringify(middle));
 await scroll(.9);const end=state();check('Original final coordinates',end[0]===0&&end[1]===1&&end[2]===1&&end.slice(3).every(x=>Math.abs(x)<.001));
 await scroll(1.02);const released=d.querySelector('.scene-silhouette').getBoundingClientRect().top;check('Pin releases',!t.pin||released<d.querySelector('.site-header').offsetHeight);
 await scroll(.5);check('Reverse midpoint',state().every((n,i)=>Math.abs(n-middle[i])<.03));await scroll(0);check('Reverse restores intact',state().every((n,i)=>Math.abs(n-initial[i])<.03));
 w.ScrollTrigger.refresh();await scroll(.9);check('Refresh preserves final',state().every((n,i)=>Math.abs(n-end[i])<.03));
 }
 check('No horizontal page overflow',d.documentElement.scrollWidth<=w.innerWidth);
 const canvas=d.querySelector('.silhouette-art .anatomy-canvas').getBoundingClientRect();check('Source canvas fits horizontally',canvas.left>=0&&canvas.right<=w.innerWidth);
 const zoom=d.querySelector('.anatomy-zoom');zoom.click();check('Zoom opens',d.querySelector('dialog').open);const enlarged=d.querySelector('.anatomy-zoom-scroll .anatomy-canvas');check('Readable zoom scale',enlarged.clientWidth>=1100);d.querySelector('[data-anatomy-close]').click();check('Zoom closes',!d.querySelector('dialog').open);
 const result={width:w.innerWidth,height:w.innerHeight,reduced:w.matchMedia('(prefers-reduced-motion: reduce)').matches,gsap:g?.version,pinned:!!t?.pin,checks,errors:w.__errors};report.textContent=JSON.stringify(result,null,2);return result;
 }catch(e){const result={width:w.innerWidth,height:w.innerHeight,checks,error:e.message,errors:w.__errors,scroll:{y:w.scrollY,start:t?.start,end:t?.end,active:t?.isActive,progress:t?.progress,trigger:t?.trigger.className,top:d.querySelector('.scene-silhouette').getBoundingClientRect().top}};report.textContent=JSON.stringify(result,null,2);return result;}
}
document.querySelector('#run').onclick=runChecks;
document.querySelector('#matrix').onclick=async()=>{
 const results=[];
 for(const [width,height,reduced]of [[320,740,false],[390,844,false],[850,980,false],[1100,800,false],[1101,900,false],[1440,900,false],[1920,1080,false],[1440,600,false],[390,844,true],[1440,900,true]]){
  await load(width,height,reduced);results.push(await runChecks());
 }
 report.textContent=JSON.stringify(results,null,2);
};
document.querySelector('#resize').onclick=async()=>{
 await load(1440,900);const results=[];
 for(const [width,height]of [[390,844],[850,980],[1440,900]]){
  site.width=width;site.height=height;await wait(300);site.contentWindow.ScrollTrigger.refresh();await wait(100);results.push(await runChecks());
 }
 report.textContent=JSON.stringify({resize:results},null,2);
};
