// Browser-engine QA: load the real landing page in WebKit and capture its DOM block.
import AppKit
import WebKit
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
let app=NSApplication.shared
app.setActivationPolicy(.accessory)
final class Review:NSObject,WKNavigationDelegate {
 var view:WKWebView!
 var window:NSWindow!
 let widths=[390,1440,1920,768,1024,1536]
 var index=0
 var results:[[String:Any]]=[]
 func next() {
  if index==widths.count {
   try! JSONSerialization.data(withJSONObject:results,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("qa/diamond-texture-browser-validation.json"))
   print("WebKit browser validation complete.");exit(0)
  }
  let width=widths[index]
  let config=WKWebViewConfiguration()
  config.websiteDataStore = .nonPersistent()
  view=WKWebView(frame:CGRect(x:0,y:0,width:width,height:2400),configuration:config)
  window=NSWindow(contentRect:CGRect(x:-10000,y:-10000,width:width,height:2400),styleMask:.borderless,backing:.buffered,defer:false)
  window.contentView=view;window.orderBack(nil)
  view.navigationDelegate=self
  // Self-contained QA copy: real HTML/CSS/assets, no network or disk reads by WebContent.
  var html=try! String(contentsOf:root.appendingPathComponent("index.html"),encoding:.utf8)
  html=html.components(separatedBy:"\n").filter{ !$0.contains("fonts.googleapis.com") && !$0.contains("fonts.gstatic.com") }.joined(separator:"\n")
  let css=try! String(contentsOf:root.appendingPathComponent("css/styles.css"),encoding:.utf8)
  html=html.replacingOccurrences(of:"<link rel=\"stylesheet\" href=\"css/styles.css\">",with:"<style>\(css)</style>")
  let js=try! String(contentsOf:root.appendingPathComponent("js/main.js"),encoding:.utf8)
  html=html.replacingOccurrences(of:"<script src=\"js/main.js\" defer></script>",with:"<script>window.addEventListener('DOMContentLoaded',()=>{\(js)});</script>")
  let pattern=try! NSRegularExpression(pattern:"(src|srcset)=\"(assets/[^\"]+)\"")
  let matches=pattern.matches(in:html,range:NSRange(html.startIndex...,in:html))
  for match in matches.reversed() {
   let range=Range(match.range(at:2),in:html)!,path=String(html[range])
   let mime=path.hasSuffix(".jpg") ? "image/jpeg" : (path.hasSuffix(".svg") ? "image/svg+xml" : "image/png")
   let data=try! Data(contentsOf:root.appendingPathComponent(path))
   html.replaceSubrange(range,with:"data:\(mime);base64,\(data.base64EncodedString())")
  }
  var fonts=""
  for (family,file,weight) in [("Manrope","Manrope-SemiBold.otf",600),("Inter","Inter-Regular.ttf",400),("Inter","Inter-Medium.ttf",500)] {
   let url=FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Fonts/\(file)")
   if let data=try? Data(contentsOf:url) {fonts+="@font-face{font-family:'\(family)';font-style:normal;font-weight:\(weight);src:url(data:font/\(file.hasSuffix(".otf") ? "otf" : "ttf");base64,\(data.base64EncodedString()));}"}
  }
  html=html.replacingOccurrences(of:"</head>",with:"<style>\(fonts)</style></head>")
  self.view.loadHTMLString(html,baseURL:root)
 }
 func webView(_ webView:WKWebView,didFinish navigation:WKNavigation!) {
  let script="""
  document.documentElement.style.scrollBehavior='auto';
  const section=document.querySelector('.scene-texture');
  const image=section.querySelector('.texture-placeholder');
  section.scrollIntoView({block:'start',behavior:'instant'});
  window.scrollBy(0,-document.querySelector('.site-header').getBoundingClientRect().height);
  image.loading='eager';
  await image.decode();
  await Promise.race([document.fonts.ready,new Promise(resolve=>setTimeout(resolve,4000))]);
  const rect=section.getBoundingClientRect(),photo=image.getBoundingClientRect(),copy=section.querySelector('.scene-copy').getBoundingClientRect();
  return {width:innerWidth,section:{x:rect.x,y:rect.y,width:rect.width,height:rect.height},image:{x:photo.x,y:photo.y,width:photo.width,height:photo.height},copy:{x:copy.x,y:copy.y,width:copy.width,height:copy.height},naturalWidth:image.naturalWidth,naturalHeight:image.naturalHeight,overflow:document.documentElement.scrollWidth>innerWidth};
  """
  webView.callAsyncJavaScript(script,arguments:[:],in:nil,in:.page) { result in
   switch result {
   case .failure(let error):print("WebKit QA failed: \(error)");exit(2)
   case .success(let value):
    guard let data=value as? [String:Any],let rect=data["section"] as? [String:Any] else {print("Invalid DOM result");exit(3)}
    self.results.append(data);print(data)
    let configuration=WKSnapshotConfiguration()
    configuration.rect=CGRect(x:rect["x"] as! Double,y:rect["y"] as! Double,width:rect["width"] as! Double,height:rect["height"] as! Double)
    configuration.snapshotWidth=NSNumber(value:self.widths[self.index])
    webView.takeSnapshot(with:configuration) { image,error in
     guard let image=image,let tiff=image.tiffRepresentation,let bitmap=NSBitmapImageRep(data:tiff) else {print("Snapshot failed: \(String(describing:error))");exit(4)}
     let file=root.appendingPathComponent("previews/02-texture-browser-\(self.widths[self.index]).png")
     try! bitmap.representation(using:.png,properties:[:])!.write(to:file)
     print(file.path);self.index+=1;self.next()
    }
   }
  }
 }
 func webView(_ webView:WKWebView,didFailProvisionalNavigation navigation:WKNavigation!,withError error:Error) {
  print("WebKit navigation failed: \(error)");exit(5)
 }
}
let review=Review()
DispatchQueue.main.async {review.next()}
DispatchQueue.main.asyncAfter(deadline:.now()+55) { print("WebKit QA timed out without completing navigation/snapshot.");exit(6) }
app.run()
