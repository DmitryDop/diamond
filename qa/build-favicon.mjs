import { readFile, writeFile } from 'node:fs/promises';
import { deflateSync } from 'node:zlib';

// The five corners of the supplied 32px diamond, on its original 32px canvas.
// No bat, lettering, facet lines or additional decoration is used.
const contour = [[10,5],[23,5],[30,13],[16.5,28],[3,13]];
const svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><path fill="#000" d="M0 0h32v32H0z"/><path fill="#fff" d="M10 5h13l7 8L16.5 28 3 13z"/></svg>\n';
const root = new URL('../', import.meta.url);
await writeFile(new URL('favicon.svg', root), svg);

const crc32 = bytes => {
  let crc = 0xffffffff;
  for (const byte of bytes) {
    crc ^= byte;
    for (let k=0;k<8;k++) crc = (crc>>>1)^((crc&1)?0xedb88320:0);
  }
  return (crc^0xffffffff)>>>0;
};
const chunk = (name, data) => {
  const type=Buffer.from(name), out=Buffer.alloc(data.length+12);
  out.writeUInt32BE(data.length);type.copy(out,4);data.copy(out,8);
  out.writeUInt32BE(crc32(Buffer.concat([type,data])),data.length+8);return out;
};
function clip(poly, axis, edge, greater) {
  const out=[];
  for(let i=0;i<poly.length;i++) {
    const a=poly[i],b=poly[(i+1)%poly.length];
    const ai=greater?a[axis]>=edge:a[axis]<=edge,bi=greater?b[axis]>=edge:b[axis]<=edge;
    if(ai)out.push(a);
    if(ai!==bi){const t=(edge-a[axis])/(b[axis]-a[axis]);out.push([a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t]);}
  }
  return out;
}
function png(size) {
  const points=contour.map(p=>p.map(v=>v*size/32));
  const raw=Buffer.alloc((size*4+1)*size);
  for(let y=0;y<size;y++)for(let x=0;x<size;x++) {
    // Exact polygon/pixel intersection area: antialias without repeated bitmap scaling.
    let poly=points;
    for(const [axis,edge,greater]of [[0,x,true],[0,x+1,false],[1,y,true],[1,y+1,false]])poly=clip(poly,axis,edge,greater);
    let area=0;for(let i=0;i<poly.length;i++){const a=poly[i],b=poly[(i+1)%poly.length];area+=a[0]*b[1]-b[0]*a[1];}
    const gray=Math.round(Math.min(1,Math.abs(area)/2)*255),offset=y*(size*4+1)+1+x*4;
    raw[offset]=raw[offset+1]=raw[offset+2]=gray;raw[offset+3]=255;
  }
  const header=Buffer.alloc(13);header.writeUInt32BE(size);header.writeUInt32BE(size,4);header[8]=8;header[9]=6;
  return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),chunk('IDAT',deflateSync(raw,{level:9})),chunk('IEND',Buffer.alloc(0))]);
}
const icons=[];
for(const size of [16,32,48]) {
  // Preserve the supplied 32px reference byte-for-byte in the 32px ICO entry.
  const data=size===32?await readFile(new URL('draft/32.png',root)):png(size);
  icons.push({size,data});await writeFile(new URL(`./favicon-${size}.png`,import.meta.url),data);
}
await writeFile(new URL('./favicon-vector-32.png',import.meta.url),png(32));
const header=Buffer.alloc(6+icons.length*16);header.writeUInt16LE(1,2);header.writeUInt16LE(icons.length,4);
let offset=header.length;
icons.forEach(({size,data},index)=>{const entry=6+index*16;header[entry]=header[entry+1]=size;header.writeUInt16LE(1,entry+4);header.writeUInt16LE(32,entry+6);header.writeUInt32LE(data.length,entry+8);header.writeUInt32LE(offset,entry+12);offset+=data.length;});
await writeFile(new URL('favicon.ico',root),Buffer.concat([header,...icons.map(x=>x.data)]));
await writeFile(new URL('apple-touch-icon.png',root),png(180));
console.log('Created SVG, ICO (16/32/48), Apple Touch Icon (180) and QA samples.');
