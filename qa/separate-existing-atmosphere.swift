// Local, deterministic decomposition of existing JPEGs. No generated pixels.
import AppKit
import ImageIO
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
let output=root.appendingPathComponent("assets/diamond-atmosphere")
try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
let reference:[Double]=[35.218888888887136,38.45083333333209,45.348333333335574]
func linear(_ c:Double)->Double {let s=c/255;return s<=0.04045 ? s/12.92 : pow((s+0.055)/1.055,2.4)}
func luminance(_ c:[Double])->Double {0.2126*linear(c[0])+0.7152*linear(c[1])+0.0722*linear(c[2])}
func cold(_ c:[Double])->[Double] {
 let target=luminance(c),ratios=reference.map{$0/reference[2]}
 var lo=0.0,hi=255.0
 for _ in 0..<22 {let m=(lo+hi)/2;if luminance(ratios.map{$0*m})<target {lo=m}else{hi=m}}
 return ratios.map{($0*(lo+hi)/2).rounded()}
}
func png(_ bytes:[UInt8],_ w:Int,_ h:Int,_ space:CGColorSpace,_ name:String) throws {
 let provider=CGDataProvider(data:Data(bytes) as CFData)!
 let image=CGImage(width:w,height:h,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:w*4,space:space,bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.last.rawValue),provider:provider,decode:nil,shouldInterpolate:true,intent:.defaultIntent)!
 let dest=CGImageDestinationCreateWithURL(output.appendingPathComponent(name) as CFURL,"public.png" as CFString,1,nil)!
 CGImageDestinationAddImage(dest,image,nil);precondition(CGImageDestinationFinalize(dest))
}
func sumTable(_ v:[Double],_ w:Int,_ h:Int)->[Double] {
 var table=[Double](repeating:0,count:(w+1)*(h+1))
 for y in 0..<h {var row=0.0;for x in 0..<w {row+=v[y*w+x];table[(y+1)*(w+1)+x+1]=table[y*(w+1)+x+1]+row}}
 return table
}
func average(_ table:[Double],_ x:Int,_ y:Int,_ r:Int,_ w:Int,_ h:Int)->Double {
 let x0=max(0,x-r),x1=min(w,x+r+1),y0=max(0,y-r),y1=min(h,y+r+1),s=w+1
 return (table[y1*s+x1]-table[y0*s+x1]-table[y1*s+x0]+table[y0*s+x0])/Double((x1-x0)*(y1-y0))
}
func inPolygon(_ x:Double,_ y:Double,_ p:[[Double]])->Bool {
 var inside=false,j=p.count-1
 for i in p.indices {let a=p[i],b=p[j];if (a[1]>y) != (b[1]>y) && x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0] {inside.toggle()};j=i}
 return inside
}
let desktopPolygons:[[[Double]]]=[
 [[20,110],[70,110],[510,350],[670,495],[1240,775],[1470,895],[1480,975],[1410,1010],[1140,825],[555,515],[430,420],[15,230]],
 [[1040,45],[1120,50],[1140,95],[1123,164],[1168,215],[1170,280],[1110,530],[1080,680],[1015,720],[950,718],[745,690],[735,640],[830,380],[870,280],[900,220],[970,175],[1020,155]],
 [[310,625],[310,590],[550,520],[595,545],[695,860],[690,935],[630,965],[375,965],[350,915]]
]
let mobilePolygons:[[[Double]]]=[
 [[20,112],[70,85],[435,475],[650,775],[810,940],[1040,1160],[1080,1295],[1065,1365],[994,1380],[935,1330],[600,850],[355,555],[15,209]],
 [[905,130],[993,150],[1008,217],[977,281],[1025,330],[1025,420],[930,730],[885,835],[790,850],[601,765],[607,688],[680,440],[745,320],[820,270],[895,245]],
 [[150,882],[410,750],[460,780],[583,1140],[575,1220],[485,1250],[242,1250],[204,1193],[145,915]]
]
var reports:[[String:Any]]=[]
for (label,path) in [("character","assets/diamond-character-campaign.jpg"),("character-mobile","assets/diamond-character-campaign-mobile.jpg"),("impact","assets/diamond-impact.jpg")] {
 let source=NSBitmapImageRep(data:try Data(contentsOf:root.appendingPathComponent(path)))!
 let w=source.pixelsWide,h=source.pixelsHigh,n=w*h,raw=source.bitmapData!,stride=source.bitsPerPixel/8
 var original=[UInt8](repeating:255,count:n*4),values=[Double](repeating:0,count:n)
 for y in 0..<h {for x in 0..<w {let p=y*w+x,s=y*source.bytesPerRow+x*stride;for c in 0..<3 {original[p*4+c]=raw[s+c]};values[p]=0.2126*Double(raw[s])+0.7152*Double(raw[s+1])+0.0722*Double(raw[s+2])}}
 let means=sumTable(values,w,h),squares=sumTable(values.map{$0*$0},w,h)
 var protection=[Double](repeating:0,count:n)
 var objectMattes:[NSBitmapImageRep]=[]
 if label=="impact" {for name in ["diamond-impact-bat.png","diamond-impact-sculpture.png"] {objectMattes.append(NSBitmapImageRep(data:try Data(contentsOf:root.appendingPathComponent("assets/\(name)")))!)}}
 for y in 0..<h {for x in 0..<w {
  let p=y*w+x,c=(0..<3).map{Double(original[p*4+$0])},m=average(means,x,y,6,w,h)
  let deviation=sqrt(max(0,average(squares,x,y,6,w,h)-m*m))
  var protected=c.max()!>90 || deviation>5 || abs(values[p]-m)>5 || c.max()!-c.min()!>32
  if label=="impact" {
   for matte in objectMattes {let s=y*matte.bytesPerRow+x*(matte.bitsPerPixel/8);if matte.bitmapData![s+3]>20 {protected=true}}
  } else {
   for polygon in label=="character" ? desktopPolygons : mobilePolygons {if inPolygon(Double(x),Double(y),polygon) {protected=true;break}}
  }
  protection[p]=protected ? 1 : 0
 }}
 let protectTable=sumTable(protection,w,h)
 var dilated=[Double](repeating:0,count:n)
 for y in 0..<h {for x in 0..<w {dilated[y*w+x]=average(protectTable,x,y,12,w,h)>0 ? 1 : 0}}
 let featherTable=sumTable(dilated,w,h)
 var safety=[Double](repeating:0,count:n),base=original,smoke=[UInt8](repeating:0,count:n*4)
 var centroidX=0.0,centroidY=0.0,weight=0.0,rebuiltDifferences=0,protectedCount=0
 for y in 0..<h {for x in 0..<w {
  let p=y*w+x,m=max(0,1-average(featherTable,x,y,6,w,h));safety[p]=m
  if protection[p]>0 {protectedCount+=1}
  let c=(0..<3).map{Double(original[p*4+$0])},maximum=c.max()!
  if maximum<8 || m==0 {continue}
  let brightness=maximum/180
  let alphaByte=Int(floor(min(0.90,m*brightness)*255))
  if alphaByte==0 {continue}
  let a=Double(alphaByte)/255
  smoke[p*4+3]=UInt8(alphaByte)
  for channel in 0..<3 {
   let haze=floor(c[channel]/brightness)
   let b=(c[channel]-a*haze)/(1-a)
   base[p*4+channel]=UInt8(max(0,min(255,Int(b.rounded()))))
   smoke[p*4+channel]=UInt8(max(0,min(255,Int(haze))))
   let rebuilt=(Double(base[p*4+channel])*(1-a)+Double(smoke[p*4+channel])*a).rounded()
   if Int(rebuilt) != Int(original[p*4+channel]) {rebuiltDifferences+=1}
  }
  centroidX+=Double(x)*a;centroidY+=Double(y)*a;weight+=a
 }}
 precondition(rebuiltDifferences==0,"Character/source decomposition must reassemble exactly")
 let space=source.cgImage!.colorSpace!
 try png(base,w,h,space,"\(label)-base.png")
 let cx=centroidX/weight,cy=centroidY/weight
 if label=="impact" {
  let observed=(0..<n).map {safety[$0]>0.999 ? 1.0 : 0.0}
  let observedTable=sumTable(observed,w,h)
  var field=[Double](repeating:0,count:n*3),tables:[[Double]]=[]
  for c in 0..<3 {
   var samples=[Double](repeating:0,count:n)
   for p in 0..<n {samples[p]=Double(original[p*4+c])*observed[p]}
   tables.append(sumTable(samples,w,h))
  }
  for y in 0..<h {for x in 0..<w {
   let p=y*w+x
   if observed[p]>0 {for c in 0..<3 {field[p*3+c]=Double(original[p*4+c])};continue}
   var radius=18
   while radius<576 && average(observedTable,x,y,radius,w,h)<0.03 {radius*=2}
   let weight=average(observedTable,x,y,radius,w,h)
   for c in 0..<3 {field[p*3+c]=weight>0 ? average(tables[c],x,y,radius,w,h)/weight : Double(original[p*4+c])}
  }}
  var adjustment=[UInt8](repeating:0,count:n*4)
  base=original;smoke=[UInt8](repeating:0,count:n*4)
  for y in 0..<h {for x in 0..<w {
   let p=y*w+x,sx=cx+(Double(x)-cx)/1.12,sy=cy+(Double(y)-cy)/1.12
   let x0=Int(floor(sx)),y0=Int(floor(sy)),fx=sx-Double(x0),fy=sy-Double(y0)
   var c=[Double](repeating:0,count:3)
   for dy in 0...1 {for dx in 0...1 {
    let xx=max(0,min(w-1,x0+dx)),yy=max(0,min(h-1,y0+dy))
    let q=(dx==0 ? 1-fx : fx)*(dy==0 ? 1-fy : fy)
    for ch in 0..<3 {c[ch]+=q*field[(yy*w+xx)*3+ch]}
   }}
   let rgb=cold(c),maskByte=Int((safety[p]*255).rounded()),m=Double(maskByte)/255
   adjustment[p*4+3]=UInt8(maskByte)
   for ch in 0..<3 {adjustment[p*4+ch]=UInt8(rgb[ch])}
   let brightness=rgb.max()!/180
   if brightness==0 || m==0 {continue}
   let alphaByte=Int(floor(min(0.9,m*brightness)*255)),a=Double(alphaByte)/255
   if alphaByte==0 {continue}
   smoke[p*4+3]=UInt8(alphaByte)
   for ch in 0..<3 {
    let target=(Double(original[p*4+ch])*(1-m)+rgb[ch]*m).rounded(),haze=floor(rgb[ch]/brightness)
    base[p*4+ch]=UInt8(max(0,min(255,Int(((target-a*haze)/(1-a)).rounded()))))
    smoke[p*4+ch]=UInt8(max(0,min(255,Int(haze))))
   }
  }}
  try png(adjustment,w,h,space,"impact-adjustment.png")
  try png(base,w,h,space,"impact-base.png")
 }
 try png(smoke,w,h,space,"\(label)-smoke.png")
 var composed=base,protectedDifferences=0
 for p in 0..<n {
  let a=Double(smoke[p*4+3])/255
  for c in 0..<3 {composed[p*4+c]=UInt8(max(0,min(255,Int((Double(base[p*4+c])*(1-a)+Double(smoke[p*4+c])*a).rounded()))))
   if protection[p]>0 && composed[p*4+c] != original[p*4+c] {protectedDifferences+=1}
  }
 }
 precondition(protectedDifferences==0,"Subjects must retain original pixels")
 if label != "impact" {precondition(composed==original,"Character cannot change visually")}
 try png(composed,w,h,space,"\(label)-composite-check.png")
 let report:[String:Any]=["scene":label,"source":path,"width":w,"height":h,"source_reassembly_rgb_differences":rebuiltDifferences,"protected_subject_rgb_differences":protectedDifferences,"protected_pixels":protectedCount,"smoke_scale":label=="impact" ? 1.12 : 1,"smoke_scale_origin":[cx,cy],"independent_smoke":"\(label)-smoke.png"]
 reports.append(report);print(report)
}
try JSONSerialization.data(withJSONObject:["reference_rgb":reference,"scenes":reports,"generation_used":false],options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("qa/diamond-atmosphere-pixel-validation.json"))
