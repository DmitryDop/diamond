// Deterministic cutouts of the approved gemstones. The bat is a byte-for-byte copy.
import AppKit
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
let directory=root.appendingPathComponent("assets/diamond-texture-layers")
let source=NSBitmapImageRep(data:try Data(contentsOf:root.appendingPathComponent("assets/diamond-texture-atmosphere-refined.png")))!
let sourcePixels=source.bitmapData!
// Remove the generator's one-byte alpha floor in fully empty regions.
let smoke=NSBitmapImageRep(data:try Data(contentsOf:root.appendingPathComponent("qa/diamond-texture-smoke-generated.png")))!
precondition(smoke.pixelsWide==1672 && smoke.pixelsHigh==941 && smoke.hasAlpha)
let smokePixels=smoke.bitmapData!
var smokeTransparent=0
for y in 0..<smoke.pixelsHigh {for x in 0..<smoke.pixelsWide {
 let i=y*smoke.bytesPerRow+x*(smoke.bitsPerPixel/8)
 if smokePixels[i+3]<=3 {for c in 0..<4 {smokePixels[i+c]=0};smokeTransparent+=1}
}}
precondition(smokeTransparent>0)
try smoke.representation(using:.png,properties:[:])!.write(to:directory.appendingPathComponent("smoke.png"))
struct Point: Equatable { let x:Double; let y:Double }
struct Gem { let id:Int; let group:String; let x:Int; let y:Int; let w:Int; let h:Int; let feather:Double }
let gems=[
 Gem(id:1,group:"back",x:282,y:150,w:70,h:70,feather:1.5),
 Gem(id:2,group:"back",x:553,y:77,w:70,h:70,feather:1.5),
 Gem(id:3,group:"back",x:810,y:245,w:70,h:70,feather:1.5),
 Gem(id:4,group:"mid",x:120,y:365,w:120,h:120,feather:1.1),
 Gem(id:5,group:"mid",x:720,y:415,w:125,h:110,feather:1.1),
 Gem(id:6,group:"mid",x:118,y:566,w:70,h:70,feather:1.3),
 Gem(id:7,group:"mid",x:430,y:555,w:110,h:110,feather:1.1),
 Gem(id:8,group:"back",x:830,y:660,w:80,h:80,feather:1.5),
 Gem(id:9,group:"front",x:35,y:640,w:210,h:210,feather:11),
 Gem(id:10,group:"front",x:550,y:690,w:220,h:190,feather:10)
]
// Tight geometric envelopes exclude old background highlights/shadows.
// They constrain segmentation only; RGB detail comes from the approved plate.
let envelopes:[(Double,Double,Double,Double,Double)]=[
 (316,184,23,19,-40),(586,108,25,18,40),(844,276,25,18,40),
 (182,422,49,39,-40),(780,471,48,35,38),(150,600,23,19,-40),
 (480,608,46,35,-37),(867,694,27,20,40),(133,740,90,74,40),(652,782,83,66,40)
]
func rgb(_ x:Int,_ y:Int,_ c:Int)->Double {
 Double(sourcePixels[y*source.bytesPerRow+x*(source.bitsPerPixel/8)+c])
}
func cross(_ o:Point,_ a:Point,_ b:Point)->Double { (a.x-o.x)*(b.y-o.y)-(a.y-o.y)*(b.x-o.x) }
func hull(_ input:[Point])->[Point] {
 let points=input.sorted { $0.x == $1.x ? $0.y < $1.y : $0.x < $1.x }
 var lower:[Point]=[],upper:[Point]=[]
 for p in points { while lower.count>=2 && cross(lower[lower.count-2],lower.last!,p)<=0 {lower.removeLast()}; lower.append(p) }
 for p in points.reversed() { while upper.count>=2 && cross(upper[upper.count-2],upper.last!,p)<=0 {upper.removeLast()}; upper.append(p) }
 return Array(lower.dropLast())+Array(upper.dropLast())
}
func distance(_ p:Point,_ polygon:[Point])->Double {
 var d=Double.infinity
 for i in polygon.indices {
  let a=polygon[i],b=polygon[(i+1)%polygon.count]
  d=min(d,cross(a,b,p)/hypot(b.x-a.x,b.y-a.y))
 }
 return d
}
var manifestGems:[[String:Any]]=[],validation:[[String:Any]]=[]
for g in gems {
 // Estimate the old smooth backdrop from the four padded crop corners.
 var corners=[[Double]]()
 for corner in [(0,0),(g.w-7,0),(0,g.h-7),(g.w-7,g.h-7)] {
  var sum=[Double](repeating:0,count:3)
  for y in corner.1..<(corner.1+7) {for x in corner.0..<(corner.0+7) {
   for c in 0..<3 {sum[c]+=rgb(g.x+x,g.y+y,c)/49}
  }}
  corners.append(sum)
 }
 func backdrop(_ x:Int,_ y:Int,_ c:Int)->Double {
  let fx=Double(x)/Double(g.w-1),fy=Double(y)/Double(g.h-1)
  return corners[0][c]*(1-fx)*(1-fy)+corners[1][c]*fx*(1-fy)+corners[2][c]*(1-fx)*fy+corners[3][c]*fx*fy
 }
 var points:[Point]=[]
 let e=envelopes[g.id-1],theta=e.4*Double.pi/180
 func envelope(_ x:Int,_ y:Int)->Double {
  let dx=Double(g.x+x)+0.5-e.0,dy=Double(g.y+y)+0.5-e.1
  let u=dx*cos(theta)+dy*sin(theta),v = -dx*sin(theta)+dy*cos(theta)
  return hypot(u/e.2,v/e.3)
 }
 for y in 3..<(g.h-3) {for x in 3..<(g.w-3) {
  let contrast=(0..<3).map{rgb(g.x+x,g.y+y,$0)-backdrop(x,y,$0)}.max()!
  if contrast>(g.group=="front" ? 24 : 25) && (g.group=="front" || envelope(x,y)<1.08) {points.append(Point(x:Double(x)+0.5,y:Double(y)+0.5))}
 }}
 let polygon=hull(points)
 precondition(polygon.count>=3)
 let output=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:g.w,pixelsHigh:g.h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bitmapFormat:.alphaNonpremultiplied,bytesPerRow:g.w*4,bitsPerPixel:32)!
 let pixels=output.bitmapData!
 var zeros=0,partial=0,opaque=0
 for y in 0..<g.h {for x in 0..<g.w {
  let d=distance(Point(x:Double(x)+0.5,y:Double(y)+0.5),polygon)
  let alpha=max(0,min(1,(d+1.2)/g.feather))
  let i=y*output.bytesPerRow+x*4
  pixels[i+3]=UInt8((alpha*255).rounded())
  if pixels[i+3]==0 { zeros+=1; for c in 0..<3 {pixels[i+c]=0} }
  else {
   if pixels[i+3]==255 {opaque+=1} else {partial+=1}
   for c in 0..<3 {
    // Remove the old grey haze from partially transparent edge pixels.
    let value=(rgb(g.x+x,g.y+y,c)-backdrop(x,y,c)*(1-alpha))/alpha
    pixels[i+c]=UInt8(max(0,min(255,Int(value.rounded()))))
   }
  }
 }}
 precondition(zeros>0 && partial>0 && opaque>0)
 let name=String(format:"diamond-%02d-%@.png",g.id,g.group)
 try output.representation(using:.png,properties:[:])!.write(to:directory.appendingPathComponent(name))
 manifestGems.append(["id":String(format:"diamond-%02d",g.id),"file":name,"depth":g.group,"x":g.x,"y":g.y,"width":g.w,"height":g.h,"opacity":0.80,"z_index":1,"parallax_rank":g.group=="front" ? 3 : (g.group=="mid" ? 2 : 1)])
 validation.append(["file":name,"transparent_pixels":zeros,"partial_alpha_pixels":partial,"opaque_pixels":opaque])
 print("\(name): \(g.w)×\(g.h), alpha 0=\(zeros) partial=\(partial) solid=\(opaque)")
}
// The scene opacity belongs in assembly, not in the exported PNG alpha.
let manifest:[String:Any]=[
 "schema_version":1,"coordinate_origin":"top-left","units":"source pixels","atmosphere_canvas":["width":1672,"height":941],
 "background":"#0b0b0e","smoke":["file":"smoke.png","width":1672,"height":941,"opacity":0.28,"z_index":0],
 "bat":["file":"bita.png","source":"../diamond-bat.png","width":1672,"height":941,"z_index":3,"rotation_css_degrees":-15,"transform_origin":"55% 50%",
  "desktop":["left_percent":-8,"top_percent":0,"width_percent":98],"mobile":["left_percent":-30,"top_percent":13,"width_percent":162]],
 "diamonds":manifestGems,"animation_enabled":false,"assembly_note":"Initial draw order preserves the approved overlap: all diamonds below the bat. Depth labels and ranks are ready for independent future parallax.",
 "placeholder":["file":"placeholder-1440.png","width":1440,"height":900,"contains_text":false,"contains_edge_fade":false]
]
try JSONSerialization.data(withJSONObject:manifest,options:[.prettyPrinted,.sortedKeys]).write(to:directory.appendingPathComponent("layers.json"))
try JSONSerialization.data(withJSONObject:validation,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("qa/diamond-texture-cutouts-validation.json"))

// Flatten only the atmosphere as a deterministic comparison/reference plate.
// The HTML preview uses individual transparent files instead.
let plate=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:1672,pixelsHigh:941,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:plate)
NSColor(srgbRed:11/255,green:11/255,blue:14/255,alpha:1).setFill();NSBezierPath(rect:NSRect(x:0,y:0,width:1672,height:941)).fill()
NSImage(cgImage:smoke.cgImage!,size:NSSize(width:1672,height:941)).draw(in:NSRect(x:0,y:0,width:1672,height:941),from:.zero,operation:.sourceOver,fraction:0.28)
for g in gems {
 let name=String(format:"diamond-%02d-%@.png",g.id,g.group)
 NSImage(contentsOf:directory.appendingPathComponent(name))!.draw(in:NSRect(x:g.x,y:941-g.y-g.h,width:g.w,height:g.h),from:.zero,operation:.sourceOver,fraction:0.80)
}
NSGraphicsContext.restoreGraphicsState()
try plate.representation(using:.png,properties:[:])!.write(to:directory.appendingPathComponent("atmosphere-composite.png"))

// Examine all masks against both the actual scene background and white.
let sheet=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:1250,pixelsHigh:1000,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:sheet)
NSColor(srgbRed:11/255,green:11/255,blue:14/255,alpha:1).setFill();NSBezierPath(rect:NSRect(x:0,y:500,width:1250,height:500)).fill()
NSColor.white.setFill();NSBezierPath(rect:NSRect(x:0,y:0,width:1250,height:500)).fill()
for bg in 0...1 {for (i,g) in gems.enumerated() {
 let name=String(format:"diamond-%02d-%@.png",g.id,g.group)
 let image=NSImage(contentsOf:directory.appendingPathComponent(name))!
 let cell=NSRect(x:CGFloat(i%5)*250+20,y:CGFloat(bg)*500+CGFloat(1-i/5)*250+40,width:210,height:190)
 let scale=min(cell.width/CGFloat(g.w),cell.height/CGFloat(g.h))
 let size=NSSize(width:CGFloat(g.w)*scale,height:CGFloat(g.h)*scale)
 image.draw(in:NSRect(x:cell.midX-size.width/2,y:cell.midY-size.height/2,width:size.width,height:size.height))
 (name as NSString).draw(at:NSPoint(x:cell.minX,y:cell.minY-25),withAttributes:[.font:NSFont.systemFont(ofSize:12),.foregroundColor:bg==0 ? NSColor.black : NSColor.white])
}}
NSGraphicsContext.restoreGraphicsState()
try sheet.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("qa/diamond-texture-cutouts-contact-sheet.png"))
