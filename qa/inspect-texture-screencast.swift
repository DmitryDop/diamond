import AVFoundation
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let input = URL(fileURLWithPath: "/Users/drujkov/Downloads/screencast 2026-10-14 21-38-52.mp4")
let asset = AVURLAsset(url: input)
let duration = CMTimeGetSeconds(asset.duration)
print("Duration:", duration)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.maximumSize = CGSize(width: 1600, height: 1200)
for index in 0..<8 {
    let seconds = duration * (Double(index) + 0.5) / 8
    let frame = try generator.copyCGImage(at: CMTime(seconds: seconds, preferredTimescale: 600), actualTime: nil)
    let bitmap = NSBitmapImageRep(cgImage: frame)
    let path = root.appendingPathComponent("qa/texture-screencast-frame-\(index).png")
    try bitmap.representation(using: .png, properties: [:])!.write(to: path)
    print(index, seconds, path.path)
}
