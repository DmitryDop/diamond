// Offline WebKit QA of the actual Anatomy markup, CSS and product asset.
import AppKit
import WebKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

final class AnatomyReview: NSObject, WKNavigationDelegate {
    let sizes = [(1920, 1280), (1440, 1080), (1280, 980), (1101, 980), (1100, 980), (1024, 980),
                 (850, 980), (768, 980), (556, 844), (390, 844), (375, 812), (320, 740)]
    var index = 0
    var view: WKWebView!
    var window: NSWindow!
    var results = [[String: Any]]()
    var html = ""

    func prepare() throws {
        html = try String(contentsOf: root.appendingPathComponent("index.html"), encoding: .utf8)
        // Keep the real page through Anatomy and leave scroll space for section screenshots.
        let end = html.range(of: "      <article class=\"detail-scene scene-texture\"")!.lowerBound
        html = String(html[..<end]) + "</section></main><div style=\"height:100vh\" aria-hidden=\"true\"></div></body></html>"
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
                .write(to: root.appendingPathComponent("qa/diamond-anatomy-browser-validation.json"))
            print("Anatomy WebKit QA complete: \(results.count) viewports.")
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
        const section=document.querySelector('.scene-silhouette');
        const image=section.querySelector('.silhouette-image');
        image.loading='eager';await image.decode();await document.fonts.ready;
        document.documentElement.style.scrollBehavior='auto';
        section.scrollIntoView({block:'start',behavior:'instant'});
        window.scrollBy(0,-document.querySelector('.site-header').getBoundingClientRect().height);
        const box=s=>{const r=document.querySelector(s).getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,bottom:r.bottom,right:r.right};};
        const scene=box('.scene-silhouette'),stage=box('.silhouette-art'),photo=box('.silhouette-image'),copy=box('.scene-silhouette .scene-copy');
        const scale=Math.min(photo.width/1600,photo.height/900);
        const offsetX=(photo.width-1600*scale)/2,offsetY=(photo.height-900*scale)/2;
        const points=[[38,739],[1550,180],[1100,350],[300,399],[665,736],[848,156],[1460,475]].map(([x,y])=>({x:photo.x+offsetX+x*scale,y:photo.y+offsetY+y*scale}));
        const canvas=document.createElement('canvas');canvas.width=1;canvas.height=1;
        const ctx=canvas.getContext('2d');ctx.drawImage(image,0,0);
        return {width:innerWidth,height:innerHeight,scene,stage,photo,copy,hasCaption:!!section.querySelector('figcaption'),
          title:section.querySelector('h3').textContent,naturalWidth:image.naturalWidth,naturalHeight:image.naturalHeight,
          PNGTopLeftAlpha:ctx.getImageData(0,0,1,1).data[3],
          fullWidthScene:Math.abs(stage.width-innerWidth)<1,
          horizontalOverflow:document.documentElement.scrollWidth>innerWidth,
          imageFit:getComputedStyle(image).objectFit,imageMask:getComputedStyle(image).maskImage,
          imageHasBackground:getComputedStyle(image).backgroundImage!=='none',
          diagramPoints:points,diagramPointsVisible:points.every(p=>p.x>=stage.x&&p.x<=stage.right&&p.y>=stage.y&&p.y<=stage.bottom),
          sceneAfterCopy:innerWidth>1100||stage.y>=copy.bottom,
          textAboveScene:Number(getComputedStyle(section.querySelector('.scene-layout')).zIndex)>Number(getComputedStyle(section.querySelector('.silhouette-art')).zIndex)};
        """
        webView.callAsyncJavaScript(script, arguments: [:], in: nil, in: .page) { result in
            switch result {
            case .failure(let error): print("DOM QA failed: \(error)"); exit(2)
            case .success(let value):
                guard let data = value as? [String: Any] else { exit(3) }
                self.results.append(data)
                print("\(self.sizes[self.index]): fullWidth=\(data["fullWidthScene"]!), diagramVisible=\(data["diagramPointsVisible"]!), overflow=\(data["horizontalOverflow"]!)")
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
                .write(to: root.appendingPathComponent("previews/01-anatomy-\(self.sizes[self.index].0).png"))
            completion()
        }
    }
}

let review = AnatomyReview()
try review.prepare()
DispatchQueue.main.async { review.next() }
DispatchQueue.main.asyncAfter(deadline: .now() + 55) { print("Anatomy WebKit QA timed out."); exit(6) }
app.run()
