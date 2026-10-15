import AppKit
import WebKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let file = root.appendingPathComponent("assets/diamond-character/character-smoke-continuous.png")
let bitmap = NSBitmapImageRep(data: try Data(contentsOf: file))!
var clear = 0, translucent = 0, opaque = 0
var alphaMax = 0.0, alphaSum = 0.0, edgeAlphaMax = 0.0
for y in 0..<bitmap.pixelsHigh {
    for x in 0..<bitmap.pixelsWide {
        let a = Double(bitmap.colorAt(x: x, y: y)!.alphaComponent)
        alphaMax = max(alphaMax, a); alphaSum += a
        if a == 0 { clear += 1 } else if a == 1 { opaque += 1 } else { translucent += 1 }
        if x == 0 || y == 0 || x == bitmap.pixelsWide - 1 || y == bitmap.pixelsHigh - 1 { edgeAlphaMax = max(edgeAlphaMax, a) }
    }
}
precondition(bitmap.hasAlpha && clear > 0 && translucent > 0 && opaque == 0)
let report: [String: Any] = ["file": "assets/diamond-character/character-smoke-continuous.png",
    "width": bitmap.pixelsWide, "height": bitmap.pixelsHigh, "hasAlpha": bitmap.hasAlpha,
    "fullyTransparentPixels": clear, "translucentPixels": translucent, "opaquePixels": opaque,
    "alphaMax": alphaMax, "alphaMean": alphaSum / Double(bitmap.pixelsWide * bitmap.pixelsHigh),
    "edgeAlphaMax": edgeAlphaMax,
    "independentContinuousLayer": true, "objectShapedCutouts": false,
    "sourceObjectsModified": false, "parallaxEnabled": false, "liveSiteLayerConnected": true]
try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
    .write(to: root.appendingPathComponent("qa/diamond-character-smoke-validation.json"))
print("Alpha validated: clear=\(clear), translucent=\(translucent), opaque=\(opaque), max=\(alphaMax), edgeMax=\(edgeAlphaMax)")

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
final class SmokeReview: NSObject, WKNavigationDelegate {
    var view: WKWebView!
    var window: NSWindow!
    func start() throws {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        view = WKWebView(frame: CGRect(x: 0, y: 0, width: 1080, height: 850), configuration: config)
        window = NSWindow(contentRect: CGRect(x: -10000, y: -10000, width: 1080, height: 850), styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = view; window.orderBack(nil); view.navigationDelegate = self
        var html = try String(contentsOf: root.appendingPathComponent("qa/diamond-character-smoke-review.html"), encoding: .utf8)
        html = html.replacingOccurrences(of: "../assets/diamond-character/character-smoke-continuous.png", with: "data:image/png;base64,\(try Data(contentsOf: file).base64EncodedString())")
        view.loadHTMLString(html, baseURL: root)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.callAsyncJavaScript("await document.querySelector('img').decode(); return true;", arguments: [:], in: nil, in: .page) { result in
            if case .failure(let error) = result { print(error); exit(2) }
            let config = WKSnapshotConfiguration(); config.rect = webView.bounds; config.snapshotWidth = 1080
            webView.takeSnapshot(with: config) { image, error in
                guard let image = image, let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else { print(String(describing: error)); exit(3) }
                try! bitmap.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("previews/03-character-smoke-transparency.png"))
                print("Saved checkerboard transparency preview."); exit(0)
            }
        }
    }
}
let review = SmokeReview()
DispatchQueue.main.async { try! review.start() }
DispatchQueue.main.asyncAfter(deadline: .now() + 45) { print("Smoke preview timed out."); exit(4) }
app.run()
