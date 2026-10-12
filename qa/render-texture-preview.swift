// Static composition preview. Not a browser screenshot. Original bat is unchanged.
import AppKit
import CoreText
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
for name in ["Manrope-SemiBold.otf", "Inter-Regular.ttf", "Inter-Medium.ttf"] {
    CTFontManagerRegisterFontsForURL(FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Fonts/\(name)") as CFURL,.process,nil)
}
func color(_ hex:Int, _ alpha:CGFloat = 1) -> NSColor {
    NSColor(srgbRed:CGFloat((hex>>16)&255)/255,green:CGFloat((hex>>8)&255)/255,blue:CGFloat(hex&255)/255,alpha:alpha)
}
func bitmap(_ w:Int,_ h:Int) -> NSBitmapImageRep {
    NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:w,pixelsHigh:h,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:w*4,bitsPerPixel:32)!
}
let bat=NSImage(contentsOf:root.appendingPathComponent("assets/diamond-texture-layers/bita.png"))!
let plate=NSImage(contentsOf:root.appendingPathComponent("assets/diamond-texture-layers/atmosphere-composite.png"))!
let copy="Бриллиантовая поверхность и гладкая платина. Металлический череп вписан в форму, а белая рукоять уравновешивает холодный блеск."
let bg=color(0x0b0b0e)
for width in [1440,1920,390] {
    let mobile=width==390
    let W=CGFloat(width), H:CGFloat=mobile ? 797 : W*0.625
    let canvas=bitmap(width,Int(H))
    let artHeight:CGFloat=mobile ? W*1.34 : H
    let artTop:CGFloat=mobile ? 274 : 0
    let art=bitmap(width,Int(ceil(artHeight)))
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:art)
    bg.setFill(); NSBezierPath(rect:NSRect(x:0,y:0,width:W,height:artHeight)).fill()
    let plateW=max(mobile ? W*1.78 : W,artHeight*1672/941)
    let plateH=plateW*941/1672
    plate.draw(in:NSRect(x:0,y:(artHeight-plateH)/2,width:plateW,height:plateH),from:.zero,operation:.sourceOver,fraction:1)
    // Render the complete original RGBA bat; fade only at scene boundaries.
    let batW=mobile ? W*1.62 : W*0.98
    let batH=batW*941/1672
    let batRaster=bitmap(Int(ceil(batW)),Int(ceil(batH)))
    NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:batRaster)
    bat.draw(in:NSRect(x:0,y:0,width:batW,height:batH))
    NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:art)
    let left=mobile ? -W*0.30 : -W*0.08
    let top=mobile ? artHeight*0.13 : 0
    let transform=NSAffineTransform()
    let pivot=NSPoint(x:left+batW*0.55,y:artHeight-top-batH*0.5)
    transform.translateX(by:pivot.x,yBy:pivot.y); transform.rotate(byDegrees:15); transform.translateX(by:-pivot.x,yBy:-pivot.y); transform.concat()
    NSImage(cgImage:batRaster.cgImage!,size:NSSize(width:batW,height:batH)).draw(in:NSRect(x:left,y:artHeight-top-batH,width:batW,height:batH))
    transform.invert(); transform.concat()
    // Full scene placeholder without text or the later edge mask.
    let placeholderName=mobile ? "placeholder-mobile-390.png" : "placeholder-\(width).png"
    let unmasked=bitmap(width,Int(ceil(artHeight)))
    unmasked.bitmapData!.update(from:art.bitmapData!,count:art.bytesPerRow*art.pixelsHigh)
    try unmasked.representation(using:.png,properties:[:])!.write(to:root.appendingPathComponent("assets/diamond-texture-layers/\(placeholderName)"))
    NSGradient(colorsAndLocations:(bg,0),(bg.withAlphaComponent(0),mobile ? 0.08 : 0.07),(bg.withAlphaComponent(0),mobile ? 0.87 : 0.88),(bg,1))!.draw(in:NSRect(x:0,y:0,width:W,height:artHeight),angle:0)
    NSGradient(colorsAndLocations:(bg,0),(bg.withAlphaComponent(0),mobile ? 0.19 : 0.20),(bg.withAlphaComponent(0),mobile ? 0.85 : 0.87),(bg,1))!.draw(in:NSRect(x:0,y:0,width:W,height:artHeight),angle:90)
    NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:canvas)
    bg.setFill();NSBezierPath(rect:NSRect(x:0,y:0,width:W,height:H)).fill()
    NSImage(cgImage:art.cgImage!,size:NSSize(width:W,height:artHeight)).draw(in:NSRect(x:0,y:H-artTop-artHeight,width:W,height:artHeight))
    func text(_ value:String,_ x:CGFloat,_ top:CGFloat,_ fontName:String,_ size:CGFloat,_ hex:Int,_ kern:CGFloat=0) {
        let font=NSFont(name:fontName,size:size)!
        let a=NSAttributedString(string:value,attributes:[.font:font,.foregroundColor:color(hex),.kern:kern])
        a.draw(at:NSPoint(x:x,y:H-top-font.ascender+font.descender-font.leading))
    }
    let copyX:CGFloat=mobile ? 22 : W*(width==1920 ? 0.70 : 0.71)
    let copyTop:CGFloat=mobile ? 48 : H*0.38
    let copyWidth:CGFloat=mobile ? 346 : min(390,W*0.24)
    let headingSize:CGFloat=mobile ? 40 : min(72,W*0.045)
    let bodySize:CGFloat=mobile ? 16 : 18
    let labelGap:CGFloat=mobile ? 20 : 26
    text("02 / 03",copyX,copyTop,"Inter-Medium",13,0xa4a0ad,1.3)
    let headingTop=copyTop+19.5+labelGap
    text("Фактура",copyX,headingTop,"Manrope-SemiBold",headingSize,0xf2f1f3,-headingSize*0.055)
    let bodyTop=headingTop+headingSize*1.12+(mobile ? 20 : 26)
    let bodyFont=NSFont(name:"Inter-Regular",size:bodySize)!
    var lines:[String]=[]
    for word in copy.split(separator:" ") {
        let candidate=(lines.last.map{$0+" "} ?? "")+word
        if lines.isEmpty || NSAttributedString(string:candidate,attributes:[.font:bodyFont]).size().width>copyWidth { lines.append(String(word)) }
        else { lines[lines.count-1]=candidate }
    }
    for (i,line) in lines.enumerated() {text(line,copyX,bodyTop+CGFloat(i)*bodySize*1.6,"Inter-Regular",bodySize,0xbab7c1)}
    NSGraphicsContext.restoreGraphicsState()
    let output=root.appendingPathComponent("previews/02-texture-preview-\(width).png")
    try canvas.representation(using:.png,properties:[:])!.write(to:output)
    print(output.path)
}
