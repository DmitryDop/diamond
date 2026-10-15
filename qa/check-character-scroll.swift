// Offline WebKit QA of the actual Character markup, CSS and product asset.
import AppKit
import WebKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

final class CharacterReview: NSObject, WKNavigationDelegate {
    let sizes = [(1440, 1000), (850, 1000), (390, 1000), (320, 1000)]
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
        html = String(html[..<headEnd]) + "<main><div style=\"height:100vh\"></div>" + String(html[sectionStart..<sectionEnd]) + "</main><div style=\"height:100vh\"></div></body></html>"
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
        html = html.replacingOccurrences(of: "<head>", with: """
        <head><script>
        let frameId=0,clock=performance.now();const frames=new Map();
        window.requestAnimationFrame=f=>{frames.set(++frameId,f);return frameId};
        window.cancelAnimationFrame=id=>frames.delete(id);
        window.flushFrames=(count=240)=>{for(let i=0;i<count;i++){clock+=1000/60;const batch=[...frames.values()];frames.clear();batch.forEach(f=>f(clock))}};
        const originalMatch=window.matchMedia.bind(window);let reduced=false;const listeners=[];
        window.matchMedia=q=>q==='(prefers-reduced-motion: reduce)'?{get matches(){return reduced},addEventListener(t,f){listeners.push(f)}}:originalMatch(q);
        window.setReduced=v=>{reduced=v;listeners.forEach(f=>f({matches:v}))};
        </script>
        """)

    }

    func next() {
        if index == sizes.count {
            try! JSONSerialization.data(withJSONObject: results, options: [.prettyPrinted, .sortedKeys])
                .write(to: root.appendingPathComponent("qa/diamond-character-scroll-validation.json"))
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
        const section=document.querySelector('.final-section'),stage=section.querySelector('.character-stage');
        const objects=[...section.querySelectorAll('.character-object')];
        await Promise.all([...stage.querySelectorAll('img')].map(i=>{i.loading='eager';return i.decode()}));
        document.documentElement.style.scrollBehavior='auto';
        const top=section.getBoundingClientRect().top+scrollY;
        const capture=()=>({height:section.offsetHeight,scrollWidth:document.documentElement.scrollWidth,
          objects:objects.map(n=>{const m=new DOMMatrix(getComputedStyle(n).transform);return {key:n.dataset.characterObject,x:m.m41,y:m.m42,angle:Math.atan2(m.b,m.a)*180/Math.PI,scale:Math.hypot(m.a,m.b),opacity:+getComputedStyle(n).opacity,width:n.offsetWidth,height:n.offsetHeight,z:+getComputedStyle(n).zIndex}})});
        const wait=async()=>{await new Promise(r=>setTimeout(r,120));window.flushFrames()};
        const go=async p=>{scrollTo(0,top-innerHeight*(.95-.9*p));await wait();return capture()};
        const start=await go(0),early=await go(.25),middle=await go(.5),end=await go(1),reverse=await go(.5);
        setReduced(true);await wait();const reduced=capture();setReduced(false);await wait();const resumed=capture();
        await go(0);
        scrollTo(0,top-innerHeight*.05);await new Promise(r=>setTimeout(r,120));
        window.flushFrames(1);const scrubFirst=capture();
        window.flushFrames(36);const scrubMiddle=capture();
        window.flushFrames(204);const scrubEnd=capture();
        const travel=s=>s.objects.reduce((sum,o)=>sum+Math.hypot(o.x,o.y),0);
        if(!(travel(scrubFirst)>travel(scrubMiddle)&&travel(scrubMiddle)>travel(scrubEnd)))throw Error('Scrub does not settle gradually');
        const samples=[start,early,middle,end,reverse,reduced,resumed,scrubFirst,scrubMiddle,scrubEnd];
        if(samples.some(s=>s.scrollWidth>innerWidth))throw Error('Horizontal overflow');
        if(samples.some(s=>s.height!==start.height))throw Error('Layout shift');
        if(samples.some(s=>s.objects.some(o=>Math.abs(o.scale-1)>.0001)))throw Error('Scale changed');
        if(end.objects.some(o=>Math.abs(o.x)>.001||Math.abs(o.y)>.001||Math.abs(o.angle)>.001||o.opacity!==1))throw Error('End not at rest '+JSON.stringify(end));
        if(JSON.stringify(middle)!==JSON.stringify(reverse))throw Error('Reverse mismatch');
        if(reduced.objects.some(o=>Math.abs(o.x)>.001||Math.abs(o.y)>.001||Math.abs(o.angle)>.001||o.opacity!==1))throw Error('Reduced motion failed');
        if(JSON.stringify(resumed)!==JSON.stringify(middle))throw Error('Resume mismatch');
        await go(1);scrollTo(0,top);await wait();
        const r=section.getBoundingClientRect();
        return {width:innerWidth,start,early,middle,end,reverse,reduced,resumed,scrubFirst,scrubMiddle,scrubEnd,passed:true,scene:{x:r.x,y:r.y,width:r.width,height:Math.min(r.height,innerHeight)}};

        """
        webView.callAsyncJavaScript(script, arguments: [:], in: nil, in: .page) { result in
            switch result {
            case .failure(let error): print("DOM QA failed: \(error)"); exit(2)
            case .success(let value):
                guard let data = value as? [String: Any] else { exit(3) }
                self.results.append(data)
                print("\(self.sizes[self.index]): passed=\(data["passed"]!)")
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
                .write(to: root.appendingPathComponent("previews/03-character-scroll-\(self.sizes[self.index].0).png"))
            completion()
        }
    }
}

let review = CharacterReview()
try review.prepare()
DispatchQueue.main.async { review.next() }
DispatchQueue.main.asyncAfter(deadline: .now() + 55) { print("Character WebKit QA timed out."); exit(6) }
app.run()
