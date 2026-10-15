// WebKit QA of the actual Texture markup, layers and scroll-driven animation.
import AppKit
import WebKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

final class TextureScrollReview: NSObject, WKNavigationDelegate {
    let sizes = [(1440, 1100), (1920, 1400), (390, 844), (320, 640)]
    var index = 0
    var view: WKWebView!
    var window: NSWindow!
    var results = [[String: Any]]()
    var assemblyReports = [[String: Any]]()
    var html = ""

    func prepare() throws {
        html = try String(contentsOf: root.appendingPathComponent("index.html"), encoding: .utf8)
        // Offscreen WebKit throttles rAF; keep real-time animation frames for QA.
        html = html.replacingOccurrences(of: "<head>", with: "<head><script>window.requestAnimationFrame=cb=>setTimeout(()=>cb(performance.now()),16);window.cancelAnimationFrame=clearTimeout;</script>")
        let headEnd = html.range(of: "  <main id=\"main\">")!.lowerBound
        let sectionStart = html.range(of: "      <article class=\"detail-scene scene-texture\"")!.lowerBound
        let sectionEnd = html.range(of: "      </article>", range: sectionStart..<html.endIndex)!.upperBound
        html = String(html[..<headEnd]) + "<main><div style=\"height:120vh\"></div>" + String(html[sectionStart..<sectionEnd]) + "</main><div style=\"height:100vh\"></div></body></html>"
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
                .write(to: root.appendingPathComponent("qa/diamond-texture-scroll-validation.json"))
            print("Texture WebKit QA complete: \(results.count) viewports.")
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
        const section=document.querySelector('.scene-texture'),art=section.querySelector('.texture-art');
        art.scrollIntoView({block:'center',behavior:'instant'});
        await new Promise(resolve=>setTimeout(resolve,300));
        const layers=art.querySelector('.texture-layers');
        await Promise.all([...layers.querySelectorAll('img')].map(image=>image.decode()));
        await document.fonts.ready;
        await new Promise(resolve=>setTimeout(resolve,200));
        if(!art.hasAttribute('data-texture-ready'))throw new Error('Layers not assembled');
        const trigger=ScrollTrigger.getById('texture-scroll'),timeline=gsap.getById('texture-parallax');
        if(!trigger||trigger.vars.scrub!==true||trigger.pin)throw new Error('Incorrect texture scrub');
        const bat=layers.querySelector('.texture-bat'),diamonds=[...layers.querySelectorAll('.texture-diamond')],smoke=layers.querySelector('.texture-smoke');
        const strength=innerWidth<=850?.5:1;
        const geometry=e=>({width:e.clientWidth,height:e.clientHeight,left:e.offsetLeft,top:e.offsetTop});
        const initialGeometry=[bat,...diamonds].map(geometry);
        const mask=getComputedStyle(art,'::after').backgroundImage,smokeStyle=smoke.style.cssText;
        const scroll=async p=>{window.scrollTo({top:trigger.start+(trigger.end-trigger.start)*p,behavior:'instant'});await new Promise(resolve=>setTimeout(resolve,70));ScrollTrigger.update();};
        await scroll(0);
        if(Math.abs(gsap.getProperty(bat,'rotation')+15)>.001)throw new Error('Initial bat orientation changed');
        for(const gem of diamonds)if(Math.abs(gsap.getProperty(gem,'x'))+Math.abs(gsap.getProperty(gem,'y'))>.001)throw new Error('Initial gem position changed');
        await scroll(.5);
        const state=()=>JSON.stringify([gsap.getProperty(bat,'rotation'),...diamonds.map(e=>[gsap.getProperty(e,'x'),gsap.getProperty(e,'y')])]);
        const stopped=state();await new Promise(resolve=>setTimeout(resolve,650));
        if(state()!==stopped)throw new Error('Movement continued without scroll');
        if(Math.abs(gsap.getProperty(bat,'rotation')-(-15+4*strength))>.02)throw new Error('Midpoint rotation incorrect');
        await scroll(1);
        const rotation=gsap.getProperty(bat,'rotation');
        if(Math.abs(rotation-(-15+8*strength))>.001)throw new Error('Amplitude incorrect');
        const distance=e=>Math.hypot(gsap.getProperty(e,'x'),gsap.getProperty(e,'y'))/strength;
        const big=diamonds.filter(e=>e.dataset.small==='false').map(distance),small=diamonds.filter(e=>e.dataset.small==='true').map(distance);
        if(!big.every(d=>d>=35&&d<=50)||Math.min(...small)<=Math.max(...big))throw new Error('Incorrect depth amplitudes');
        if(JSON.stringify(initialGeometry)!==JSON.stringify([bat,...diamonds].map(geometry)))throw new Error('Object sizes or layout changed');
        if(smoke.style.cssText!==smokeStyle||getComputedStyle(art,'::after').backgroundImage!==mask)throw new Error('Atmosphere changed');
        await scroll(0);
        if(Math.abs(gsap.getProperty(bat,'rotation')+15)>.001||diamonds.some(e=>distance(e)>.001))throw new Error('Reverse did not restore original scene');
        await scroll(.8);ScrollTrigger.refresh();await scroll(.2);
        if(Math.abs(gsap.getProperty(bat,'rotation')-(-15+1.6*strength))>.02)throw new Error('Refresh changed motion');
        if(document.documentElement.scrollWidth>innerWidth)throw new Error('Horizontal overflow');
        const picture=art.querySelector('.texture-placeholder');
        const sourceHeight=innerWidth<=850?523/390:.625;
        if(Math.abs(layers.clientHeight-art.clientWidth*sourceHeight)>1)throw new Error('Registration frame mismatch');
        // Capture a readable midpoint of the actual scroll-driven scene.
        await scroll(.45);
        const r=art.getBoundingClientRect();
        return {width:innerWidth,height:innerHeight,smokeLoaded:true,horizontalOverflow:false,scrub:true,noPin:true,
          rotationDelta:8*strength,bigDistances:big,smallDistances:small,stopsWithoutScroll:true,reversed:true,
          atmosphereUnchanged:true,geometryUnchanged:true,refreshPassed:true,
          scene:{x:r.x,y:r.y,width:r.width,height:r.height}};
        """
        webView.callAsyncJavaScript(script, arguments: [:], in: nil, in: .page) { result in
            switch result {
            case .failure(let error): print("DOM QA failed: \(error)"); exit(2)
            case .success(let value):
                guard let data = value as? [String: Any] else { exit(3) }
                self.results.append(data)
                print("\(self.sizes[self.index]): smokeLoaded=\(data["smokeLoaded"]!), overflow=\(data["horizontalOverflow"]!)")
                self.snapshot(section: data["scene"] as! [String: Any]) {
                    if self.index == 0 || self.index == 2 { self.compareAssembly { self.index += 1; self.next() } }
                    else { self.index += 1; self.next() }
                }

            }
        }
    }

    func compareAssembly(completion: @escaping () -> Void) {
        let setup = """
        const art=document.querySelector('.texture-art');
        ScrollTrigger.getById('texture-scroll').disable(false);
        gsap.getById('texture-parallax').progress(0);
        window.scrollTo({top:art.getBoundingClientRect().top+scrollY-document.querySelector('.site-header').offsetHeight,behavior:'instant'});
        await new Promise(resolve=>setTimeout(resolve,120));
        const r=art.getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height};
        """
        view.callAsyncJavaScript(setup, arguments: [:], in: nil, in: .page) { result in
            guard case .success(let value) = result, let rect = value as? [String: Any] else { print("Assembly setup failed"); exit(7) }
            let config = WKSnapshotConfiguration()
            config.rect = CGRect(x: rect["x"] as! Double, y: rect["y"] as! Double, width: rect["width"] as! Double, height: rect["height"] as! Double)
            config.snapshotWidth = NSNumber(value: self.sizes[self.index].0)
            self.view.takeSnapshot(with: config) { live, error in
                guard let live = live, let tiff = live.tiffRepresentation, let a = NSBitmapImageRep(data: tiff) else { exit(8) }
                self.view.callAsyncJavaScript("document.querySelector('.texture-layers').hidden=true;document.querySelector('.texture-art').removeAttribute('data-texture-ready');await new Promise(r=>setTimeout(r,80));return true;", arguments: [:], in: nil, in: .page) { _ in
                    self.view.takeSnapshot(with: config) { flat, error in
                        guard let flat = flat, let tiff = flat.tiffRepresentation, let b = NSBitmapImageRep(data: tiff) else { exit(9) }
                        var total=0.0, square=0.0, count=0
                        for y in stride(from: 0, to: a.pixelsHigh, by: 4) { for x in stride(from: 0, to: a.pixelsWide, by: 4) {
                            let c=a.colorAt(x:x,y:y)!.usingColorSpace(.sRGB)!, d=b.colorAt(x:x,y:y)!.usingColorSpace(.sRGB)!
                            for delta in [c.redComponent-d.redComponent,c.greenComponent-d.greenComponent,c.blueComponent-d.blueComponent] { total += abs(Double(delta));square += Double(delta*delta);count += 1 }
                        }}
                        let mean=total/Double(count)*255, rms=sqrt(square/Double(count))*255
                        print("Initial assembly \(self.sizes[self.index].0): mean RGB difference=\(mean), RMS=\(rms)")
                        if mean > 3 { print("Assembly differs from approved placeholder");exit(10) }
                        self.assemblyReports.append(["width":self.sizes[self.index].0,"meanRGBDifference255":mean,"rmsRGBDifference255":rms,"sameComposition":true])
                        try! JSONSerialization.data(withJSONObject:self.assemblyReports,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("qa/diamond-texture-scroll-assembly-validation.json"))
                        completion()
                    }
                }
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
                .write(to: root.appendingPathComponent("previews/02-texture-scroll-\(self.sizes[self.index].0)-\(self.index >= 4 ? "fast" : "normal").png"))
            completion()
        }
    }
}

let review = TextureScrollReview()
try review.prepare()
DispatchQueue.main.async { review.next() }
DispatchQueue.main.asyncAfter(deadline: .now() + 110) { print("Texture WebKit QA timed out."); exit(6) }
app.run()
