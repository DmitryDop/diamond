// Offline WebKit QA of the actual Character markup, CSS and product asset.
import AppKit
import WebKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

final class CharacterReview: NSObject, WKNavigationDelegate {
    let sizes = [(1920, 1400), (1440, 1100), (1024, 1000), (850, 1300), (768, 1300), (556, 1300), (390, 1100), (375, 1100), (320, 1000)]
    var index = 0
    var view: WKWebView!
    var window: NSWindow!
    var results = [[String: Any]]()
    var html = ""

    func prepare() throws {
        html = try String(contentsOf: root.appendingPathComponent("index.html"), encoding: .utf8)
        let headEnd = html.range(of: "  <main id=\"main\">")!.lowerBound
        let sectionStart = html.range(of: "    <section class=\"final-section\"")!.lowerBound
        let sectionEnd = html.range(of: "  </main>", range: sectionStart..<html.endIndex)!.lowerBound
        html = String(html[..<headEnd]) + "<main>" + String(html[sectionStart..<sectionEnd]) + "</main><div style=\"height:100vh\"></div></body></html>"
        html = html.components(separatedBy: "\n").filter {
            !$0.contains("fonts.googleapis.com") && !$0.contains("fonts.gstatic.com")
        }.joined(separator: "\n")
        let css = try String(contentsOf: root.appendingPathComponent("css/styles.css"), encoding: .utf8)
        html = html.replacingOccurrences(of: "<link rel=\"stylesheet\" href=\"css/styles.css\">", with: "<style>\(css)</style>")
        let js = try String(contentsOf: root.appendingPathComponent("js/main.js"), encoding: .utf8)
        html = html.replacingOccurrences(of: "<script src=\"js/main.js\" defer></script>", with: "<script>window.addEventListener('DOMContentLoaded',()=>{\(js)});</script>")
        let pattern = try NSRegularExpression(pattern: "(src|srcset)=\"(assets/[^\"]+)\"")
        for match in pattern.matches(in: html, range: NSRange(html.startIndex..., in: html)).reversed() {
            let range = Range(match.range(at: 2), in: html)!
            let path = String(html[range])
            let mime = path.hasSuffix(".svg") ? "image/svg+xml" : (path.hasSuffix(".jpg") ? "image/jpeg" : "image/png")
            let data = try Data(contentsOf: root.appendingPathComponent(path))
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
                .write(to: root.appendingPathComponent("qa/diamond-character-smoke-browser-validation.json"))
            print("Character WebKit QA complete: \(results.count) viewports.")
            exit(0)
        }
        window?.close()
        let (width, height) = sizes[index]
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        view = WKWebView(frame: CGRect(x: 0, y: 0, width: width, height: height), configuration: config)
        window = NSWindow(contentRect: CGRect(x: -10000, y: -10000, width: width, height: height),
                          styleMask: .borderless, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        window.orderBack(nil)
        view.navigationDelegate = self
        view.loadHTMLString(html, baseURL: root)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let script = """
        const section=document.querySelector('.final-section');
        const image=section.querySelector('.character-image'),smoke=section.querySelector('.character-smoke');
        image.loading='eager';smoke.loading='eager';await image.decode();await smoke.decode();await document.fonts.ready;
        document.documentElement.style.scrollBehavior='auto';section.scrollIntoView({block:'start',behavior:'instant'});
        window.scrollBy(0,-document.querySelector('.site-header').getBoundingClientRect().height);
        const art=section.querySelector('.character-stage');
        const mask=getComputedStyle(art);
        const maskImage=mask.maskImage,maskComposite=mask.maskComposite;
        const realAlphaMask=maskImage.includes('linear-gradient')&&maskComposite.includes('intersect');
        if(!realAlphaMask)throw new Error('Character stage alpha mask not applied: '+maskImage+' / '+maskComposite);
        const box=s=>{const r=document.querySelector(s).getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,bottom:r.bottom,right:r.right};};
        const scene=box('.final-section'),stage=box('.character-stage'),photo=box('.character-image'),haze=box('.character-smoke'),copy=box('.character-copy');
        return {width:innerWidth,height:innerHeight,scene,stage,photo,haze,copy,maskImage,maskComposite,realAlphaMask,
          imageSource:image.currentSrc.slice(0,30),smokeSource:smoke.getAttribute('src').slice(0,30),
          smokeWidth:smoke.naturalWidth,smokeHeight:smoke.naturalHeight,smokeHidden:smoke.hidden,
          imageLoaded:image.naturalWidth>0,smokeLoaded:smoke.naturalWidth>0,
          horizontalOverflow:document.documentElement.scrollWidth>innerWidth,
          smokeAlignedWithScene:Math.abs(haze.x-stage.x)<1&&Math.abs(haze.y-stage.y)<1&&Math.abs(haze.width-stage.width)<1&&Math.abs(haze.height-stage.height)<1,
          smokeBelowImage:Number(getComputedStyle(smoke).zIndex)<Number(getComputedStyle(section.querySelector('picture')).zIndex),
          parallaxAnimations:smoke.getAnimations().length,
          title:section.querySelector('h3').textContent};
        """
        webView.callAsyncJavaScript(script, arguments: [:], in: nil, in: .page) { result in
            switch result {
            case .failure(let error): print("DOM QA failed: \(error)"); exit(2)
            case .success(let value):
                guard let data = value as? [String: Any] else { exit(3) }
                self.results.append(data)
                print("\(self.sizes[self.index]): smokeLoaded=\(data["smokeLoaded"]!), aligned=\(data["smokeAlignedWithScene"]!), overflow=\(data["horizontalOverflow"]!)")
                self.snapshot(section: data["scene"] as! [String: Any]) { self.index += 1; self.next() }

            }
        }
    }

    func snapshot(section: [String: Any], completion: @escaping () -> Void) {
        let config = WKSnapshotConfiguration()
        config.rect = CGRect(x: section["x"] as! Double, y: section["y"] as! Double, width: section["width"] as! Double, height: section["height"] as! Double)
        config.snapshotWidth = NSNumber(value: sizes[index].0)
        config.afterScreenUpdates = true
        view.takeSnapshot(with: config) { image, error in
            guard let image = image, let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff) else {
                print("Snapshot failed: \(String(describing: error))"); exit(5)
            }
            try! bitmap.representation(using: .png, properties: [:])!
                .write(to: root.appendingPathComponent("previews/03-character-smoke-\(self.sizes[self.index].0).png"))
            completion()
        }
    }
}

let review = CharacterReview()
try review.prepare()
DispatchQueue.main.async { review.next() }
DispatchQueue.main.asyncAfter(deadline: .now() + 55) { print("Character WebKit QA timed out."); exit(6) }
app.run()
