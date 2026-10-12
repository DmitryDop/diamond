import AppKit

// Original pixels are retained. Generated data is used only behind the bat
// and as a starting point for the sculpture's alpha matte.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let source = NSBitmapImageRep(data: try Data(contentsOf: root.appendingPathComponent("assets/diamond-impact.png")))!
let restored = NSBitmapImageRep(data: try Data(contentsOf: root.appendingPathComponent("qa/diamond-impact-sculpture-restoration.png")))!
let w = source.pixelsWide, h = source.pixelsHigh
precondition(w == restored.pixelsWide && h == restored.pixelsHigh)

func rgba() -> NSBitmapImageRep {
    NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
      colorSpaceName: .deviceRGB, bitmapFormat: .alphaNonpremultiplied,
      bytesPerRow: w * 4, bitsPerPixel: 32)!
}
let mask = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: w * 4, bitsPerPixel: 32)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: mask)
let path = NSBezierPath()
func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x, y: CGFloat(h) - y) }
func move(_ x: CGFloat, _ y: CGFloat) { path.move(to: point(x,y)) }
func line(_ x: CGFloat, _ y: CGFloat) { path.line(to: point(x,y)) }
func curve(_ x: CGFloat, _ y: CGFloat, _ a: CGFloat, _ b: CGFloat, _ c: CGFloat, _ d: CGFloat) {
    path.curve(to: point(x,y), controlPoint1: point(a,b), controlPoint2: point(c,d))
}
move(81,743)
curve(112,748,92,740,103,745)
curve(386,610,193,717,311,650)
curve(414,597,397,603,405,600)
curve(688,429,507,543,601,487)
curve(761,375,715,410,734,392)
curve(1086,184,862,310,1039,208)
curve(1121,172,1098,176,1106,171)
curve(1151,184,1132,172,1144,179)
curve(1180,243,1168,203,1179,226)
curve(1163,300,1189,270,1176,288)
curve(1110,331,1151,312,1127,321)
curve(835,470,1030,377,933,434)
curve(427,650,716,527,545,596)
curve(123,807,343,692,207,764)
curve(99,830,114,816,107,826)
curve(76,833,91,839,84,837)
curve(58,796,62,826,56,809)
curve(81,743,54,770,67,749)
path.close()
NSColor.white.setFill(); path.fill()
NSGraphicsContext.restoreGraphicsState()
let occlusion = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
 colorSpaceName: .deviceRGB, bytesPerRow: w * 4, bitsPerPixel: 32)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: occlusion)
NSColor.white.setFill(); NSColor.white.setStroke()
path.fill(); path.lineWidth = 14; path.stroke()
NSGraphicsContext.restoreGraphicsState()

let bat = rgba(), sculpture = rgba()
let src = source.bitmapData!, gen = restored.bitmapData!, mat = mask.bitmapData!
let bp = bat.bitmapData!, sp = sculpture.bitmapData!
let occ = occlusion.bitmapData!
func sample(_ b: NSBitmapImageRep, _ data: UnsafeMutablePointer<UInt8>, _ x: Int, _ y: Int, _ channel: Int) -> UInt8 {
    data[y * b.bytesPerRow + x * (b.bitsPerPixel / 8) + channel]
}
func luminance(_ x: Int, _ y: Int) -> Double {
    let p = y * source.bytesPerRow + x * (source.bitsPerPixel / 8)
    return Double(src[p]) * 0.2126 + Double(src[p+1]) * 0.7152 + Double(src[p+2]) * 0.0722
}
var restoredPixels = 0, opaqueBatPixels = 0, preservedBatPixels = 0
for y in 0..<h { for x in 0..<w {
    let o = y * w * 4 + x * 4
    let ba = sample(mask,mat,x,y,3)
    let ga = sample(restored,gen,x,y,3)
    let oa = sample(occlusion,occ,x,y,3)
    var sa = Int(ga)
    // Fully opaque sculpture interior retains the source, including its shadows.
    if sa > 235 { sa = 255 }
    if ba > 0 {
        for c in 0..<3 { bp[o+c] = sample(source,src,x,y,c) }
        bp[o+3] = ba
        if ba == 255 { opaqueBatPixels += 1; preservedBatPixels += 1 }
    }
    // Recover original floating fragments and powder outside the main bust.
    if ga < 200 && oa == 0 && x > 490 {
        var nearby: [Double] = []
        for dy in [-18,0,18] { for dx in [-18,0,18] where dx != 0 || dy != 0 {
            nearby.append(luminance(max(0,min(w-1,x+dx)),max(0,min(h-1,y+dy))))
        }}
        nearby.sort()
        let contrast = luminance(x,y) - nearby[nearby.count/2]
        if contrast > 9 { sa = max(sa, min(255,Int((contrast - 9) * 9))) }
    }
    // Suppress any generated background haze; retain actual source debris.
    if ga < 200 && oa == 0 && luminance(x,y) < 32 { sa = 0 }
    // Hidden sculpture pixels alone come from the restoration.
    let hidden = oa > 0 && ga > 0
    if oa > 0 { sa = ga > 235 ? 255 : Int(ga) }
    // Match the existing cast shadow at the edge of the reconstructed region.
    // The correction fades entirely inside the formerly occluded area.
    var edgeY: Int? = nil
    var edgeDistance = 0
    if hidden && ga > 220 && x > 900 {
        for d in 1...36 {
            for yy in [y-d,y+d] where yy >= 0 && yy < h {
                if sample(occlusion,occ,x,yy,3) == 0 && sample(restored,gen,x,yy,3) > 235 {
                    edgeY = yy; edgeDistance = d; break
                }
            }
            if edgeY != nil { break }
        }
    }
    for c in 0..<3 {
        var value = Double(hidden ? sample(restored,gen,x,y,c) : sample(source,src,x,y,c))
        if let yy = edgeY {
            let delta = Double(sample(source,src,x,yy,c)) - Double(sample(restored,gen,x,yy,c))
            value += delta * pow(1 - Double(edgeDistance-1)/36,1.5)
        }
        sp[o+c] = UInt8(max(0,min(255,Int(value.rounded()))))
    }
    if hidden { restoredPixels += 1 }
    sp[o+3] = UInt8(sa)
    if sa == 0 { for c in 0..<3 { sp[o+c] = 0 } }
}}
func save(_ b: NSBitmapImageRep, _ name: String) throws {
    try b.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent(name))
}
try save(bat,"assets/diamond-impact-bat.png")
try save(sculpture,"assets/diamond-impact-sculpture.png")
let preview = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w*2, pixelsHigh: h,
 bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
 colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: preview)
NSColor(srgbRed: 0.12,green: 0.12,blue: 0.15,alpha: 1).setFill()
NSBezierPath(rect: NSRect(x:0,y:0,width:w*2,height:h)).fill()
NSColor(srgbRed: 0.88,green: 0.87,blue: 0.85,alpha: 1).setFill()
NSBezierPath(rect: NSRect(x:w,y:0,width:w,height:h)).fill()
for x in [0,w] {
    let rect = NSRect(x:x,y:0,width:w,height:h)
    let layer = x == 0 ? bat : sculpture
    NSImage(cgImage: layer.cgImage!,size:NSSize(width:w,height:h)).draw(in: rect)
}
NSGraphicsContext.restoreGraphicsState()
try save(preview,"qa/diamond-impact-layers-preview.png")
print("1536 × 1024 RGBA layers. Bat opaque pixels retained: \(preservedBatPixels)/\(opaqueBatPixels). Hidden sculpture pixels reconstructed: \(restoredPixels).")
