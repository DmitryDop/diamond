// Static layout illustration, not a browser screenshot. No browser or UI control.
import AppKit
import CoreText

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
for name in ["Manrope-SemiBold.otf", "Inter-Regular.ttf", "Inter-Medium.ttf"] {
    let file = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Fonts/\(name)")
    CTFontManagerRegisterFontsForURL(file as CFURL, .process, nil)
}
func color(_ hex: Int, alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: alpha)
}
let asset = NSImage(contentsOf: root.appendingPathComponent("assets/diamond-impact.jpg"))!
for mobile in [false, true] {
    let width: CGFloat = mobile ? 390 : 1440
    let height: CGFloat = mobile ? 645 : 900
    let imageTop: CGFloat = mobile ? 361 : -30
    let imageHeight: CGFloat = mobile ? 260 : 960
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(width), pixelsHigh: Int(height),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    color(0x0b0b0e).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()
    let rect = NSRect(x: 0, y: height - imageTop - imageHeight, width: width, height: imageHeight)
    asset.draw(in: rect)
    let gradient = NSGradient(colorsAndLocations:
        (color(0x0b0b0e), 0), (color(0x0b0b0e, alpha: 0), 0.24),
        (color(0x0b0b0e, alpha: 0), 0.87), (color(0x0b0b0e), 1))!
    gradient.draw(in: mobile ? rect : NSRect(x: 0, y: 0, width: width, height: height), angle: 90)
    if !mobile {
        NSGradient(colorsAndLocations: (color(0x0b0b0e), 0),
            (color(0x0b0b0e, alpha: 0), 0.14),
            (color(0x0b0b0e, alpha: 0), 0.88), (color(0x0b0b0e), 1))!
            .draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: 0)
    }
    func text(_ value: String, x: CGFloat, baseline: CGFloat, size: CGFloat,
              font: String, tint: Int, spacing: CGFloat = 0) {
        let face = NSFont(name: font, size: size) ?? NSFont.systemFont(ofSize: size)
        let string = NSAttributedString(string: value, attributes: [
            .font: face, .foregroundColor: color(tint), .kern: spacing
        ])
        string.draw(at: NSPoint(x: x, y: height - baseline + face.descender))
    }
    let x: CGFloat = mobile ? 22 : 60.48
    text("04 / 04", x: x, baseline: mobile ? 70 : 159, size: 13,
         font: "Inter-Medium", tint: 0xa4a0ad, spacing: 1.3)
    let size: CGFloat = mobile ? 49.92 : 81.36
    for (i, word) in ["Когда", "аргумент", "очевиден."].enumerated() {
        text(word, x: x, baseline: (mobile ? 144 : 259) + CGFloat(i) * (mobile ? 51.92 : 84.61),
             size: size, font: "Manrope-SemiBold", tint: 0xf2f1f3, spacing: -size * 0.055)
    }
    let bodySize: CGFloat = mobile ? 16 : 18
    let body = mobile ? ["Иногда лучший способ проветрить", "мысли — убрать всё лишнее."] :
        ["Иногда лучший способ", "проветрить мысли — убрать", "всё лишнее."]
    for (i, line) in body.enumerated() {
        text(line, x: x, baseline: (mobile ? 298 : 498) + CGFloat(i) * bodySize * 1.65,
             size: bodySize, font: "Inter-Regular", tint: 0xbab7c1)
    }
    NSGraphicsContext.restoreGraphicsState()
    let name = mobile ? "mobile" : "desktop"
    let output = root.appendingPathComponent("previews/04-impact-\(name).png")
    try bitmap.representation(using: .png, properties: [:])!.write(to: output)
    print(output.path)
}
