import AppKit
import WebKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
var layerReports = [[String: Any]]()
for name in ["bat", "head", "smoke"] {
 let bitmap=NSBitmapImageRep(data: try Data(contentsOf: root.appendingPathComponent("assets/diamond-argument/argument-\(name).png")))!
 var clear=0, translucent=0, opaque=0, sum=0.0, maxAlpha=0.0
 for y in 0..<bitmap.pixelsHigh { for x in 0..<bitmap.pixelsWide {
  let a=Double(bitmap.colorAt(x:x,y:y)!.alphaComponent);sum += a;maxAlpha=max(maxAlpha,a)
  if a==0 {clear += 1} else if a==1 {opaque += 1} else {translucent += 1}
 }}
 precondition(bitmap.hasAlpha && clear>0 && translucent>0 && bitmap.pixelsWide==1536 && bitmap.pixelsHigh==1024)
 if name=="smoke" {precondition(opaque==0)}
 layerReports.append(["file":"argument-\(name).png","hasAlpha":bitmap.hasAlpha,"width":bitmap.pixelsWide,"height":bitmap.pixelsHigh,"clear":clear,"translucent":translucent,"opaque":opaque,"alphaMax":maxAlpha,"alphaMean":sum/Double(bitmap.pixelsWide*bitmap.pixelsHigh)])
 print(name,"transparent pixels",clear,"alpha max",maxAlpha)
}
try JSONSerialization.data(withJSONObject: layerReports,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("qa/diamond-argument-alpha-validation.json"))

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
final class ArgumentLayersReview: NSObject, WKNavigationDelegate {
    var view: WKWebView!
    var window: NSWindow!
    func start() throws {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        view = WKWebView(frame: CGRect(x: 0, y: 0, width: 1080, height: 1150), configuration: config)
        window = NSWindow(contentRect: CGRect(x: -10000, y: -10000, width: 1080, height: 1150), styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = view; window.orderBack(nil); view.navigationDelegate = self
        var html = try String(contentsOf: root.appendingPathComponent("qa/diamond-argument-review.html"), encoding: .utf8)
        for name in ["bat", "head", "smoke"] { let path="assets/diamond-argument/argument-\(name).png";html=html.replacingOccurrences(of:"../"+path,with:"data:image/png;base64,\(try Data(contentsOf:root.appendingPathComponent(path)).base64EncodedString())") }
        view.loadHTMLString(html, baseURL: root)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.callAsyncJavaScript("await Promise.all([...document.images].map(i=>i.decode())); return true;", arguments: [:], in: nil, in: .page) { result in
            if case .failure(let error) = result { print(error); exit(2) }
            let config = WKSnapshotConfiguration(); config.rect = webView.bounds; config.snapshotWidth = 1080
            webView.takeSnapshot(with: config) { image, error in
                guard let image = image, let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else { print(String(describing: error)); exit(3) }
                try! bitmap.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent("previews/02-argument-layers.png"))
                print("Saved checkerboard transparency preview."); exit(0)
            }
        }
    }
}
let review = ArgumentLayersReview()
DispatchQueue.main.async { try! review.start() }
DispatchQueue.main.asyncAfter(deadline: .now() + 45) { print("Smoke preview timed out."); exit(4) }
app.run()
