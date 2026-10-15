import AppKit
let root=URL(fileURLWithPath:FileManager.default.currentDirectoryPath)
func cg(_ name:String)->CGImage {NSBitmapImageRep(data:try! Data(contentsOf:root.appendingPathComponent(name)))!.cgImage!}
func render(_ images:[CGImage],_ w:Int,_ h:Int,_ space:CGColorSpace)->[UInt8] {
 var pixels=[UInt8](repeating:0,count:w*h*4)
 pixels.withUnsafeMutableBytes { bytes in
  let context=CGContext(data:bytes.baseAddress,width:w,height:h,bitsPerComponent:8,bytesPerRow:w*4,space:space,bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue)!
  context.interpolationQuality = .high
  for image in images {context.draw(image,in:CGRect(x:0,y:0,width:w,height:h))}
 }
 return pixels
}
var reports:[[String:Any]]=[]
for (label,source,widths) in [("character","assets/diamond-character-campaign.jpg",[1519,1267,1640,680]),("character-mobile","assets/diamond-character-campaign-mobile.jpg",[1122,390,620])] {
 let original=cg(source),base=cg("assets/diamond-character/\(label)-base.png"),smoke=cg("assets/diamond-character/\(label)-smoke.png")
 for w in widths {
  let h=Int((Double(w)*Double(original.height)/Double(original.width)).rounded())
  let before=render([original],w,h,original.colorSpace!),after=render([base,smoke],w,h,original.colorSpace!)
  var maximum=0,total=0,changed=0
  for p in 0..<(w*h) {for c in 0..<3 {let difference=abs(Int(before[p*4+c])-Int(after[p*4+c]));maximum=max(maximum,difference);total+=difference;if difference>0 {changed+=1}}}
  let mean=Double(total)/Double(w*h*3)
  reports.append(["scene":label,"render_width":w,"render_height":h,"maximum_rgb_rounding_difference":maximum,"mean_rgb_difference":mean,"differing_channels":changed])
  print("\(label) \(w)×\(h): max=\(maximum), mean=\(mean)")
 }
}
try! JSONSerialization.data(withJSONObject:reports,options:[.prettyPrinted,.sortedKeys]).write(to:root.appendingPathComponent("qa/diamond-atmosphere-resampling-validation.json"))
