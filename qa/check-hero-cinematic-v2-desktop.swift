// Offline WebKit QA of the actual Hero markup, CSS and product asset.
import AppKit
import WebKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

final class HeroReview: NSObject, WKNavigationDelegate {
    let sizes = [(1440,900),(1920,1080),(1280,720)]
    var index = 0
    var view: WKWebView!
    var window: NSWindow!
    var results = [[String: Any]]()
    var html = ""

    func prepare() throws {
        html = try String(contentsOf: root.appendingPathComponent("index.html"), encoding: .utf8)
        // Keep the real header and Hero; other sections are outside this visual review.
        let end = html.range(of: "    <section class=\"details-section\"")!.lowerBound
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
                .write(to: root.appendingPathComponent("qa/diamond-hero-cinematic-v2-desktop-validation.json"))
            print("Hero WebKit QA complete: \(results.count) viewports.")
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
        let setup = """
        <script>
        // Isolate physical input and advance the application's frame callback
        // at an explicit 60 Hz. Offscreen WebKit throttles native timers/rAF.
        Object.defineProperty(document,'hidden',{get:()=>false});
        let frameClock=performance.now(),frameID=0;const pendingFrames=new Map();
        Object.defineProperty(performance,'now',{value:()=>frameClock});
        window.requestAnimationFrame=callback=>{pendingFrames.set(++frameID,callback);return frameID;};
        window.cancelAnimationFrame=id=>pendingFrames.delete(id);
        window.qaFrames=count=>{for(let i=0;i<count;i++){frameClock+=1000/60;const callbacks=[...pendingFrames.values()];pendingFrames.clear();callbacks.forEach(callback=>callback(frameClock));}};
        const nativeMatch=window.matchMedia.bind(window);
        const listeners=[];let reduced=false;
        window.matchMedia=query=>query==='(prefers-reduced-motion: reduce)'?{get matches(){return reduced;},addEventListener(type,fn){listeners.push(fn);}}:nativeMatch(query);
        window.qaSetReduced=value=>{reduced=value;listeners.forEach(fn=>fn({matches:value}));};
        </script>
        """
        view.loadHTMLString(html.replacingOccurrences(of:"<head>",with:"<head>"+setup), baseURL: root)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let script = """
        await Promise.all([...document.querySelectorAll('.hero-scene img')].map(i=>i.decode()));await document.fonts.ready;
        document.documentElement.style.scrollBehavior='auto';window.scrollTo(0,0);
        const wait=async ms=>{await new Promise(r=>setTimeout(r,100));window.qaFrames(Math.ceil(ms/(1000/60)));};
        await wait(1800);document.querySelector('.hero-scene').getAnimations().forEach(a=>a.finish());
        const box=s=>{const r=document.querySelector(s).getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height,bottom:r.bottom,right:r.right};};
        const hero=document.querySelector('.hero'),track=document.querySelector('[data-hero-track]'),stage=document.querySelector('.hero-art');
        const layers=[...document.querySelectorAll('.hero-layer')];
        const capture=()=>({scrollY,pin:track.hasAttribute('data-hero-pin'),hero:box('.hero'),track:box('[data-hero-track]'),stage:box('.hero-art'),scene:box('.hero-scene'),copy:box('.hero-copy'),concept:box('.concept'),
          layers:layers.map(l=>{const m=new DOMMatrix(getComputedStyle(l).transform);return {key:l.dataset.heroLayer,x:m.m41,y:m.m42,scale:m.m11,right:l.getBoundingClientRect().right,bottom:l.getBoundingClientRect().bottom};}),
          air:[...document.querySelectorAll('.hero-smoke')].map(i=>getComputedStyle(i).transform)});
        const initial=capture();
        const pointer=async (nx,ny)=>{const r=hero.getBoundingClientRect();hero.dispatchEvent(new PointerEvent('pointermove',{pointerType:'mouse',clientX:r.left+(nx+1)*r.width/2,clientY:r.top+(ny+1)*r.height/2}));await wait(5500);return capture();};
        const cursorLeft=await pointer(-1,-1),cursorRight=await pointer(1,1);
        await wait(1600);const held=capture();
        hero.dispatchEvent(new PointerEvent('pointerleave'));await wait(10000);
        const duration=innerHeight*.9;
        const go=async p=>{window.scrollTo(0,p*duration);await wait(2400);return capture();};
        const half=await go(.5),full=await go(1),combined=await pointer(-1,-1);
        hero.dispatchEvent(new PointerEvent('pointerleave'));await wait(10000);
        const airBefore=capture();await wait(600);const airAfter=capture();
        const reverse=await go(.5),released=await go(1.3),returned=await go(0);
        window.qaSetReduced(true);await wait(100);const reduced=capture();
        window.qaSetReduced(false);await wait(500);const resumed=capture();
        return {width:innerWidth,height:innerHeight,initial,cursorLeft,cursorRight,held,half,full,combined,airBefore,airAfter,reverse,released,returned,reduced,resumed,
          horizontalOverflow:document.documentElement.scrollWidth>innerWidth,imagesLoaded:[...document.querySelectorAll('.hero-scene img')].every(i=>i.naturalWidth>0),
          finePointer:matchMedia('(hover: hover) and (pointer: fine) and (min-width: 851px)').matches};
        """
        webView.callAsyncJavaScript(script, arguments: [:], in: nil, in: .page) { result in
            switch result {
            case .failure(let error): print("DOM QA failed: \(error)"); exit(2)
            case .success(let value):
                guard let data = value as? [String: Any] else { exit(3) }
                self.results.append(data)
                print("\(self.sizes[self.index]): overflow=\(data["horizontalOverflow"]!), loaded=\(data["imagesLoaded"]!)")
                self.snapshot(suffix: "initial") {
                    webView.callAsyncJavaScript("document.documentElement.style.scrollBehavior='auto';window.scrollTo(0,innerHeight*.9);await new Promise(r=>setTimeout(r,100));window.qaFrames(240);const h=document.querySelector('.hero'),r=h.getBoundingClientRect();h.dispatchEvent(new PointerEvent('pointermove',{pointerType:'mouse',clientX:r.left,clientY:r.top}));window.qaFrames(480);return true;", arguments: [:], in: nil, in: .page) { _ in
                        self.snapshot(suffix: "push-cursor-left") {
                            webView.callAsyncJavaScript("window.scrollTo(0,0);await new Promise(r=>setTimeout(r,100));window.qaFrames(240);const h=document.querySelector('.hero'),r=h.getBoundingClientRect();h.dispatchEvent(new PointerEvent('pointermove',{pointerType:'mouse',clientX:r.right,clientY:r.bottom}));window.qaFrames(480);return true;", arguments: [:], in: nil, in: .page) { _ in
                                self.snapshot(suffix: "cursor-right") { self.index += 1; self.next() }
                            }
                        }
                    }
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
                .write(to: root.appendingPathComponent("previews/00-hero-v2-desktop-\(self.sizes[self.index].0)-\(suffix).png"))
            completion()
        }
    }
}

let review = HeroReview()
try review.prepare()
DispatchQueue.main.async { review.next() }
DispatchQueue.main.asyncAfter(deadline: .now() + 220) { print("Hero WebKit QA timed out."); exit(6) }
app.run()
