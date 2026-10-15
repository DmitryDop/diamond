// Offline WebKit QA of the actual Character markup, CSS and product asset.
import AppKit
import WebKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

final class ArgumentReview: NSObject, WKNavigationDelegate {
    let sizes = [(1440, 900), (850, 900), (390, 844), (320, 640), (1440, 900), (850, 900), (390, 844), (320, 640)]
    var index = 0
    var view: WKWebView!
    var window: NSWindow!
    var results = [[String: Any]]()
    var html = ""

    func prepare() throws {
        html = try String(contentsOf: root.appendingPathComponent("index.html"), encoding: .utf8)
        // Offscreen WebKit throttles rAF; keep real-time animation frames for QA.
        html = html.replacingOccurrences(of: "<head>", with: "<head><script>window.requestAnimationFrame=cb=>setTimeout(()=>cb(performance.now()),16);window.cancelAnimationFrame=clearTimeout;</script>")
        let headEnd = html.range(of: "  <main id=\"main\">")!.lowerBound
        let sectionStart = html.range(of: "      <article class=\"detail-scene scene-impact\"")!.lowerBound
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
                .write(to: root.appendingPathComponent("qa/diamond-argument-scrub-validation.json"))
            print("Argument WebKit QA complete: \(results.count) viewports.")
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
        await new Promise(resolve=>setTimeout(resolve,250));
        const fast=FAST_MODE;
        const section=document.querySelector('.scene-impact'),art=section.querySelector('.impact-art');
        const images=[...section.querySelectorAll('img')];for(const image of images){image.loading='eager';await image.decode();}
        await document.fonts.ready;
        if(!window.gsap||!window.ScrollTrigger)throw new Error('GSAP/ScrollTrigger unavailable');
        ScrollTrigger.refresh();
        const trigger=ScrollTrigger.getById('argument-visibility'),timeline=gsap.getById('argument-strike');
        if(!trigger||!timeline||trigger.vars.scrub!==true||trigger.pin!==section)throw new Error('Expected section pin and scrub:true');
        if(Math.abs((trigger.end-trigger.start)/innerHeight-.9)>.001)throw new Error('Pin exceeds 90vh');
        const intact=section.querySelector('.impact-head-intact'),broken=section.querySelector('.impact-head-broken'),bat=section.querySelector('.impact-bat'),smoke=section.querySelector('.impact-smoke');
        const intactVisible=()=>getComputedStyle(intact).visibility==='visible'&&getComputedStyle(broken).visibility==='hidden';
        const wait=async ms=>{await new Promise(resolve=>setTimeout(resolve,ms));ScrollTrigger.update();};
        const scroll=async y=>{window.scrollTo({top:y,behavior:'instant'});await wait(60);};
        const progress=async p=>scroll(trigger.start+(trigger.end-trigger.start)*p);
        const state=()=>({x:gsap.getProperty(bat,'xPercent'),y:gsap.getProperty(bat,'yPercent'),rotation:gsap.getProperty(bat,'rotation'),timeline:timeline.progress(),smoke:smoke.style.cssText});
        await progress(-.3);
        if(!intactVisible()||timeline.progress()!==0)throw new Error('Started before composition entered');
        await progress(.01);
        const head=intact.getBoundingClientRect(),header=document.querySelector('.site-header').getBoundingClientRect().bottom;
        const visible=Math.max(0,Math.min(head.bottom,innerHeight)-Math.max(head.top,header));
        if(visible/head.height<.69)throw new Error('Head insufficiently visible at pin start');
        const pinY=section.getBoundingClientRect().top;
        const smokeBefore=smoke.style.cssText;
        if(fast){await progress(1.1);if(intactVisible())throw new Error('Fast forward did not break head');await progress(.1);if(!intactVisible())throw new Error('Fast reverse did not restore head');}
        else{for(const p of [.1,.25,.5,.6])await progress(p);}
        await progress(.7);
        if(!intactVisible())throw new Error('Head broken before contact');
        const stopped=state();
        await wait(650);
        if(JSON.stringify(stopped)!==JSON.stringify(state()))throw new Error('Scene moved after scroll stopped');
        if(Math.abs(section.getBoundingClientRect().top-pinY)>1)throw new Error('Pin moved with scroll');
        await progress(.748);
        if(!intactVisible())throw new Error('Early head swap');
        await progress(.752);
        if(getComputedStyle(broken).visibility!=='visible'||getComputedStyle(intact).visibility!=='hidden')throw new Error('Contact head swap failed');
        await progress(.9);
        await progress(1);
        for(const name of ['xPercent','yPercent','rotation'])if(Math.abs(gsap.getProperty(bat,name))>.001)throw new Error('Final composition changed');
        if(Math.abs(gsap.getProperty(bat,'scaleX')-1)>.001)throw new Error('Bat scale changed');
        if(smokeBefore!==smoke.style.cssText)throw new Error('Smoke modified');
        await progress(.749);
        if(!intactVisible())throw new Error('Reverse contact did not restore head');
        await progress(0);
        if(!intactVisible()||Math.abs(gsap.getProperty(bat,'xPercent')+5)>.001)throw new Error('Initial scene not restored');
        await progress(.9);
        ScrollTrigger.refresh();
        await wait(80);
        await progress(.6);
        if(!intactVisible())throw new Error('Refresh broke reverse head swap');
        await progress(1);
        const overflow=document.documentElement.scrollWidth>innerWidth;
        if(overflow)throw new Error('Horizontal overflow');
        for(const head of section.querySelectorAll('.impact-head')){const box=head.getBoundingClientRect();if(Math.abs(box.width/box.height-head.naturalWidth/head.naturalHeight)>.001)throw new Error('Head proportions changed');}
        const r=section.getBoundingClientRect();
        return {width:innerWidth,height:innerHeight,mode:fast?'fast':'normal',smokeLoaded:images.every(i=>i.naturalWidth>0),horizontalOverflow:overflow,
          scrub:trigger.vars.scrub,pinViewport:.9,contactProgress:.75,headVisibleAtStart:visible/head.height,
          stoppedImmediately:true,reversed:true,refreshReversed:true,smokeUntouched:true,headProportionsPreserved:true,
          gsap:gsap.version,batScale:gsap.getProperty(bat,'scaleX'),scene:{x:r.x,y:r.y,width:r.width,height:r.height}};
        """
        webView.callAsyncJavaScript(script.replacingOccurrences(of: "FAST_MODE", with: index >= 4 ? "true" : "false"), arguments: [:], in: nil, in: .page) { result in
            switch result {
            case .failure(let error): print("DOM QA failed: \(error)"); exit(2)
            case .success(let value):
                guard let data = value as? [String: Any] else { exit(3) }
                self.results.append(data)
                print("\(self.sizes[self.index]): smokeLoaded=\(data["smokeLoaded"]!), overflow=\(data["horizontalOverflow"]!)")
                self.snapshot(section: data["scene"] as! [String: Any]) {
                    if self.index == 0 { self.verifyResize { self.index += 1; self.next() } }
                    else { self.index += 1; self.next() }
                }

            }
        }
    }

    func verifyResize(completion: @escaping () -> Void) {
        window.setContentSize(NSSize(width: 390, height: 844))
        view.setFrameSize(NSSize(width: 390, height: 844))
        let script = """
        await new Promise(resolve=>setTimeout(resolve,300));
        ScrollTrigger.refresh();
        await new Promise(resolve=>setTimeout(resolve,80));
        const t=ScrollTrigger.getById('argument-visibility');
        if(!t||innerWidth!==390||ScrollTrigger.getAll().filter(x=>x.vars.id==='argument-visibility').length!==1)throw new Error('Resize created missing/duplicate triggers');
        const scroll=async p=>{window.scrollTo({top:t.start+(t.end-t.start)*p,behavior:'instant'});await new Promise(resolve=>setTimeout(resolve,60));ScrollTrigger.update();};
        const head=document.querySelector('.impact-head-intact'),broken=document.querySelector('.impact-head-broken');
        await scroll(.7);
        if(getComputedStyle(head).visibility!=='visible')throw new Error('Resize reverse failed');
        await scroll(.8);
        if(getComputedStyle(broken).visibility!=='visible')throw new Error('Resize forward failed');
        await scroll(0);
        if(getComputedStyle(head).visibility!=='visible')throw new Error('Resize did not restore initial scene');
        if(Math.abs((t.end-t.start)/innerHeight-.9)>.001)throw new Error('Resize pin distance wrong');
        const r=head.getBoundingClientRect();
        if(Math.abs(r.width/r.height-16/9)>.001)throw new Error('Resize changed head proportions');
        return {fromWidth:1440,toWidth:innerWidth,height:innerHeight,reversed:true,headProportionsPreserved:true,pinViewport:.9};
        """
        view.callAsyncJavaScript(script, arguments: [:], in: nil, in: .page) { result in
            switch result {
            case .failure(let error): print("Resize QA failed: \(error)"); exit(7)
            case .success(let value):
                guard let data = value as? [String: Any] else { exit(8) }
                try! JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .sortedKeys])
                    .write(to: root.appendingPathComponent("qa/diamond-argument-scrub-resize-validation.json"))
                print("Resize 1440 → 390: passed")
                completion()
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
                .write(to: root.appendingPathComponent("previews/02-argument-scrub-\(self.sizes[self.index].0)-\(self.index >= 4 ? "fast" : "normal").png"))
            completion()
        }
    }
}

let review = ArgumentReview()
try review.prepare()
DispatchQueue.main.async { review.next() }
DispatchQueue.main.asyncAfter(deadline: .now() + 110) { print("Argument WebKit QA timed out."); exit(6) }
app.run()
