// Offline WebKit QA of the actual Hero markup, CSS and product asset.
import AppKit
import WebKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

final class HeroReview: NSObject, WKNavigationDelegate {
    let sizes = [(1920,1080),(1440,900),(1100,900),(851,900),(850,900),(768,1024),(390,844),(320,740)]
    var index = 0
    var view: WKWebView!
    var window: NSWindow!
    var results = [[String: Any]]()
    var html = ""

    func prepare() throws {
        html = try String(contentsOf: root.appendingPathComponent("index.html"), encoding: .utf8)
        // Keep the real header and Hero; other sections are outside this visual review.
        let end = html.range(of: "    <section class=\"concept\"")!.lowerBound
        html = String(html[..<end]) + "</main></body></html>"
        html = html.components(separatedBy: "\n").filter {
            !$0.contains("fonts.googleapis.com") && !$0.contains("fonts.gstatic.com")
        }.joined(separator: "\n")
        let css = try String(contentsOf: root.appendingPathComponent("css/styles.css"), encoding: .utf8)
        html = html.replacingOccurrences(of: "<link rel=\"stylesheet\" href=\"css/styles.css\">", with: "<style>\(css)</style>")
        let js = try String(contentsOf: root.appendingPathComponent("js/main.js"), encoding: .utf8)
        html = html.replacingOccurrences(of: "<script src=\"js/main.js\" defer></script>", with: "<script>window.addEventListener('DOMContentLoaded',()=>{\(js)});</script>")
        let pattern = try NSRegularExpression(pattern: "src=\"(assets/[^\"]+)\"")
        for match in pattern.matches(in: html, range: NSRange(html.startIndex..., in: html)).reversed() {
            let range = Range(match.range(at: 1), in: html)!
            let path = String(html[range])
            let mime = path.hasSuffix(".svg") ? "image/svg+xml" : "image/png"
            let data = try Data(contentsOf: root.appendingPathComponent(path.removingPercentEncoding!))
            html.replaceSubrange(range, with: "data:\(mime);base64,\(data.base64EncodedString())")
        }
        var fonts = ""
        for (family, file, weight) in [("Manrope", "Manrope-ExtraBold.otf", 800),
                                     ("Manrope", "Manrope-Bold.otf", 700),
                                     ("Manrope", "Manrope-SemiBold.otf", 600),
                                     ("Inter", "Inter-Regular.ttf", 400),
                                     ("Inter", "Inter-Medium.ttf", 500)] {
            let font = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Fonts/\(file)")
            let data = try Data(contentsOf: font)
            fonts += "@font-face{font-family:'\(family)';font-style:normal;font-weight:\(weight);src:url(data:font/\(file.hasSuffix(".otf") ? "otf" : "ttf");base64,\(data.base64EncodedString()));}"
        }
        html = html.replacingOccurrences(of: "</head>", with: "<style>\(fonts)</style></head>")
    }

    func next() {
        if index == sizes.count {
            try! JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys])
                .write(to: root.appendingPathComponent("qa/diamond-hero-animation-validation.json"))
            print("Hero WebKit QA complete: \(results.count) viewports.")
            exit(0)
        }
        window?.close()
        let (width, height) = sizes[index]
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        view = WKWebView(frame: CGRect(x: 0, y: 0, width: width, height: height), configuration: config)
        window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: width, height: height),
                          styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        window.orderFront(nil)
        view.navigationDelegate = self
        view.loadHTMLString(html, baseURL: root)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let script = """
        await Promise.all([...document.querySelectorAll('.hero-scene img')].map(i=>i.decode()));
        await document.fonts.ready;
        document.querySelector('.hero-art').scrollIntoView({behavior:'instant',block:'center'});
        const wait=ms=>new Promise(r=>setTimeout(r,ms));
        await wait(1800);
        const box=s=>{const r=document.querySelector(s).getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,bottom:r.bottom,right:r.right};};
        const layers=[...document.querySelectorAll('.hero-layer')];
        const central=document.querySelector('.hero-scene-image');
        const initial=layers.map(l=>getComputedStyle(l).transform);
        const smoke=document.querySelector('.hero-smoke');
        const airBefore=getComputedStyle(smoke).transform;
        const hero=document.querySelector('.hero');const rect=hero.getBoundingClientRect();
        for(let i=0;i<20;i++){hero.dispatchEvent(new PointerEvent('pointermove',{clientX:rect.right-10,clientY:rect.top+rect.height*.8,pointerType:'mouse'}));await wait(30);}
        const moved=layers.map(l=>getComputedStyle(l).transform);
        const airAfter=getComputedStyle(smoke).transform;
        await wait(2500);
        const settled=layers.map(l=>getComputedStyle(l).transform);
        const scale=box('.hero-layer-central').width/1448;
        const cb=box('.hero-layer-central'),stage=box('.hero-art');
        const batPoints=[[300,850],[1255,330],[1335,285]].map(([x,y])=>({x:cb.x+x*scale,y:cb.y+y*scale}));
        return {width:innerWidth,height:innerHeight,horizontalOverflow:document.documentElement.scrollWidth>innerWidth,
          scene:box('.hero-scene'),stage,hero:box('.hero'),copy:box('.hero-copy'),actions:box('.hero-actions'),
          layerCount:layers.length,allImagesLoaded:[...document.querySelectorAll('.hero-scene img')].every(i=>i.naturalWidth>0),
          initial,moved,settled,airBefore,airAfter,airMoving:airBefore!==airAfter,
          finePointer:matchMedia('(hover: hover) and (pointer: fine) and (min-width: 851px)').matches,
          reducedMotion:matchMedia('(prefers-reduced-motion: reduce)').matches,
          batPoints,batVisible:batPoints.every(p=>p.x>=stage.x&&p.x<=stage.right&&p.y>=stage.y&&p.y<=stage.bottom),
          sceneAfterCTA:innerWidth>1100||stage.y>=box('.hero-actions').bottom,
          aspectPreserved:Math.abs(box('.hero-scene').width/box('.hero-scene').height-1776/1312)<.001,
          texts:[...document.querySelectorAll('.hero-copy')].map(e=>e.textContent)};
        """
        webView.callAsyncJavaScript(script, arguments: [:], in: nil, in: .page) { result in
            switch result {
            case .failure(let error): print("DOM QA failed: \(error)"); exit(2)
            case .success(let value):
                guard let data = value as? [String: Any] else { exit(3) }
                self.results.append(data)
                print("\(self.sizes[self.index]): overflow=\(data["horizontalOverflow"]!), fullWidth=\(data["aspectPreserved"]!), sceneAfterCTA=\(data["sceneAfterCTA"]!), batVisible=\(data["batVisible"]!)")
                self.snapshot(suffix: "top") {
                    if self.sizes[self.index].0 <= 1100 {
                        webView.evaluateJavaScript("document.documentElement.style.scrollBehavior='auto';window.scrollTo(0,document.body.scrollHeight-innerHeight)") { _, error in
                            if let error = error { print(error); exit(4) }
                            self.snapshot(suffix: "art") { self.index += 1; self.next() }
                        }
                    } else { self.index += 1; self.next() }
                }
            }
        }
    }

    func snapshot(suffix: String, completion: @escaping () -> Void) {
        let config = WKSnapshotConfiguration()
        config.rect = view.bounds
        config.snapshotWidth = NSNumber(value: sizes[index].0)
        config.afterScreenUpdates = true
        view.takeSnapshot(with: config) { image, error in
            guard let image = image, let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff) else {
                print("Snapshot failed: \(String(describing: error))"); exit(5)
            }
            try! bitmap.representation(using: .png, properties: [:])!
                .write(to: root.appendingPathComponent("previews/00-hero-animation-\(self.sizes[self.index].0)-\(suffix).png"))
            completion()
        }
    }
}

let review = HeroReview()
try review.prepare()
DispatchQueue.main.async { review.next() }
DispatchQueue.main.asyncAfter(deadline: .now() + 160) { print("Hero WebKit QA timed out."); exit(6) }
app.run()
