// Static integration previews and alpha inspection. This does not control a browser.
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let background = NSColor(srgbRed: 11 / 255, green: 11 / 255, blue: 14 / 255, alpha: 1)
// Approximate section layout from the CSS. This is a static composition review,
// not browser layout verification. All source assets remain untouched.
import CoreText
for name in ["Manrope-SemiBold.otf", "Inter-Regular.ttf", "Inter-Medium.ttf"] {
    CTFontManagerRegisterFontsForURL(FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Fonts/\(name)") as CFURL, .process, nil)
}
func tint(_ hex: Int, alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255)/255, green: CGFloat((hex >> 8) & 255)/255,
        blue: CGFloat(hex & 255)/255, alpha: alpha)
}
func clamp(_ minimum: CGFloat, _ preferred: CGFloat, _ maximum: CGFloat) -> CGFloat {
    min(maximum, max(minimum, preferred))
}
let description = "Платина, бриллианты и лёд. Характер DIAMOND не требует объяснений."
for widthInt in [1920, 1440, 1024, 851, 768, 390, 375] {
    let width = CGFloat(widthInt)
    let stacked = width <= 850, phone = width <= 520
    let gutter: CGFloat = phone ? 22 : clamp(24, width * 0.042, 80)
    let container = min(width - gutter * 2, 1600)
    let copyWidth = stacked ? min(container, 560) : container * (width <= 1100 ? 0.32 : 0.30)
    let copyX = stacked ? gutter : (width - container) / 2 + container - copyWidth
    let artWidth = stacked ? width : (width <= 1100 ? width * 0.8 : min(width * 0.88, 1640))
    let artHeight = artWidth * (width <= 620 ? 1402/1122.0 : 1035/1519.0)
    let artMargin: CGFloat = phone ? 24 : 32
    let headingSize = phone ? clamp(36, width * 0.1, 48) : clamp(40, width * 0.045, 72)
    let headingHeight = headingSize * 1.12 * 2
    let bodySize: CGFloat = phone ? 16 : 18
    let bodyFont = NSFont(name: "Inter-Regular", size: bodySize)!
    let bodyLines = description.split(separator: " ").reduce(into: [String]()) { lines, word in
        let candidate = (lines.last.map { $0 + " " } ?? "") + word
        let measured = NSAttributedString(string: candidate, attributes: [.font: bodyFont]).size().width
        if lines.isEmpty || measured > copyWidth { lines.append(String(word)) }
        else { lines[lines.count - 1] = candidate }
    }
    let gap: CGFloat = phone ? 24 : 28
    let labelHeight: CGFloat = 19.5
    let copyHeight = labelHeight + gap + headingHeight + gap + CGFloat(bodyLines.count) * bodySize * 1.6 + gap + (phone ? 52 : 56)
    let copyTop: CGFloat = stacked ? artMargin + artHeight + (phone ? 12 : 24) : (width <= 1100 ? 96 : clamp(112, width * 0.1, 170))
    let sectionHeight = stacked ? copyTop + copyHeight + (phone ? 48 : 64) : max(clamp(800, width * 0.64, 1140), copyTop + copyHeight + 96)
    let artTop: CGFloat = stacked ? artMargin : (sectionHeight - artHeight) / 2
    let height = Int(ceil(sectionHeight))
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: widthInt, pixelsHigh: height,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    background.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: CGFloat(height))).fill()
    let artRect = NSRect(x: 0, y: CGFloat(height) - artTop - artHeight, width: artWidth, height: artHeight)
    let source = NSImage(contentsOf: root.appendingPathComponent("assets/diamond-character-campaign\(width <= 620 ? "-mobile" : "").jpg"))!
    NSGraphicsContext.current!.cgContext.setBlendMode(.lighten)
    NSGraphicsContext.current!.cgContext.draw(source.cgImage(forProposedRect: nil, context: nil, hints: nil)!, in: artRect)
    NSGraphicsContext.current!.cgContext.setBlendMode(.normal)
    NSGradient(colorsAndLocations: (background, 0), (background.withAlphaComponent(0), 0.01),
        (background.withAlphaComponent(0), 0.99), (background, 1))!.draw(in: artRect, angle: 0)
    NSGradient(colorsAndLocations: (background, 0), (background.withAlphaComponent(0), 0.02),
        (background.withAlphaComponent(0), 0.98), (background, 1))!.draw(in: artRect, angle: 90)
    if !stacked {
        NSGradient(colorsAndLocations: (background, 0), (background.withAlphaComponent(0), 0.06),
            (background.withAlphaComponent(0), 0.94), (background, 1))!
            .draw(in: NSRect(x: 0, y: 0, width: width, height: CGFloat(height)), angle: 90)
    }
    func text(_ value: String, x: CGFloat, top: CGFloat, size: CGFloat, font: String, hex: Int, kern: CGFloat = 0) {
        let face = NSFont(name: font, size: size)!
        let value = NSAttributedString(string: value, attributes: [.font: face, .foregroundColor: tint(hex), .kern: kern])
        let lineHeight = face.ascender - face.descender + face.leading
        value.draw(at: NSPoint(x: x, y: CGFloat(height) - top - lineHeight))
    }
    tint(0x9d98a6).setFill()
    NSBezierPath(rect: NSRect(x: copyX, y: CGFloat(height) - copyTop - labelHeight / 2, width: 32, height: 1)).fill()
    text("DIAMOND / 03", x: copyX + 48, top: copyTop, size: 13, font: "Inter-Medium", hex: 0xbab7c1, kern: 1.3)
    let headingTop = copyTop + labelHeight + gap
    for (i, line) in ["Холодный.", "Крепкий."].enumerated() {
        text(line, x: copyX, top: headingTop + CGFloat(i) * headingSize * 1.12, size: headingSize,
            font: "Manrope-SemiBold", hex: 0xf2f1f3, kern: -headingSize * 0.055)
    }
    let bodyTop = headingTop + headingHeight + gap
    for (i, line) in bodyLines.enumerated() {
        text(line, x: copyX, top: bodyTop + CGFloat(i) * bodySize * 1.6, size: bodySize, font: "Inter-Regular", hex: 0xbab7c1)
    }
    let buttonTop = bodyTop + CGFloat(bodyLines.count) * bodySize * 1.6 + gap
    let buttonLabel = "Перейти в PALKAHELP"
    let labelWidth = NSAttributedString(string: buttonLabel, attributes: [.font: NSFont(name: "Inter-Medium", size: 15)!]).size().width
    let buttonWidth = labelWidth + (phone ? 44 : 50) + 2
    tint(0xf2f1f3).setFill()
    NSBezierPath(rect: NSRect(x: copyX, y: CGFloat(height) - buttonTop - (phone ? 52 : 56), width: buttonWidth, height: phone ? 52 : 56)).fill()
    text(buttonLabel, x: copyX + (buttonWidth - labelWidth) / 2, top: buttonTop + (phone ? 15 : 17), size: 15, font: "Inter-Medium", hex: 0x16151a)
    tint(0xe9e7f0, alpha: 0.14).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: CGFloat(height) - 1, width: width, height: 1)).fill()
    NSGraphicsContext.restoreGraphicsState()
    let output = root.appendingPathComponent("previews/03-character-z-\(widthInt).png")
    try bitmap.representation(using: .png, properties: [:])!.write(to: output)
    print("STATIC: \(widthInt) × \(height), art x=0 y=\(artTop) w=\(artWidth) h=\(artHeight); copy x=\(copyX) y=\(copyTop) w=\(copyWidth) bottom=\(buttonTop + (phone ? 52 : 56))")
}
for name in ["diamond-character-bat", "diamond-character-bottle", "diamond-character-glass-splash"] {
    let data = try Data(contentsOf: root.appendingPathComponent("assets/\(name).png"))
    let bitmap = NSBitmapImageRep(data: data)!
    var transparent = 0, translucent = 0, opaque = 0
    for y in stride(from: 0, to: bitmap.pixelsHigh, by: 4) {
        for x in stride(from: 0, to: bitmap.pixelsWide, by: 4) {
            let a = bitmap.colorAt(x: x, y: y)!.alphaComponent
            if a == 0 { transparent += 1 }
            else if a < 1 { translucent += 1 }
            else { opaque += 1 }
        }
    }
    print("Alpha \(name): transparent=\(transparent), translucent=\(translucent), opaque=\(opaque)")
    assert(transparent > 0 && translucent > 0)
}

// Inspect the cutouts on the actual landing-page background.
let sheet = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1200, pixelsHigh: 1000,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: sheet)
background.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1200, height: 1000)).fill()
for (name, box) in [
    ("diamond-character-bat", NSRect(x: 20, y: 750, width: 1160, height: 230)),
    ("diamond-character-bottle", NSRect(x: 30, y: 20, width: 540, height: 710)),
    ("diamond-character-glass-splash", NSRect(x: 630, y: 20, width: 540, height: 710))
] {
    let image = NSImage(contentsOf: root.appendingPathComponent("assets/\(name).png"))!
    let scale = min(box.width / image.size.width, box.height / image.size.height)
    let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
    image.draw(in: NSRect(x: box.midX - size.width / 2, y: box.midY - size.height / 2, width: size.width, height: size.height))
}
NSGraphicsContext.restoreGraphicsState()
try sheet.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("previews/03-character-objects.png"))
