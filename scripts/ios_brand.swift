// Reproduce the Şahsından iOS icon from vector paths. No external assets or services.
// Run on macOS: swift scripts/ios_brand.swift
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("apps/mobile/ios/Runner/Assets.xcassets")
let navy = NSColor(srgbRed: 26 / 255, green: 43 / 255, blue: 71 / 255, alpha: 1)
let cyan = NSColor(srgbRed: 0, green: 209 / 255, blue: 1, alpha: 1)

func png(size: Int, launch: Bool = false) -> Data {
    let canvas = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
        bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let context = NSGraphicsContext(cgContext: canvas, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    (launch ? NSColor.white : navy).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)).fill()
    if launch {
        navy.setFill()
        NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 1024, height: 1024),
                     xRadius: 220, yRadius: 220).fill()
    }
    // An S monogram and its cyan cedilla, kept inside Apple's icon safe area.
    let mark = NSBezierPath()
    mark.move(to: NSPoint(x: 718, y: 708))
    mark.curve(to: NSPoint(x: 339, y: 652), controlPoint1: NSPoint(x: 575, y: 823),
               controlPoint2: NSPoint(x: 306, y: 790))
    mark.curve(to: NSPoint(x: 666, y: 446), controlPoint1: NSPoint(x: 327, y: 531),
               controlPoint2: NSPoint(x: 690, y: 562))
    mark.curve(to: NSPoint(x: 303, y: 358), controlPoint1: NSPoint(x: 646, y: 310),
               controlPoint2: NSPoint(x: 439, y: 273))
    mark.lineWidth = 103
    mark.lineCapStyle = .round
    NSColor.white.setStroke()
    mark.stroke()
    let cedilla = NSBezierPath()
    cedilla.move(to: NSPoint(x: 525, y: 216))
    cedilla.line(to: NSPoint(x: 472, y: 153))
    cedilla.lineWidth = 64
    cedilla.lineCapStyle = .round
    cyan.setStroke()
    cedilla.stroke()
    NSGraphicsContext.restoreGraphicsState()
    return NSBitmapImageRep(cgImage: canvas.makeImage()!).representation(using: .png, properties: [:])!
}

let catalog = assets.appendingPathComponent("AppIcon.appiconset")
let data = try Data(contentsOf: catalog.appendingPathComponent("Contents.json"))
let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
for item in json["images"] as! [[String: String]] {
    let points = Double(item["size"]!.components(separatedBy: "x")[0])!
    let scale = Double(item["scale"]!.replacingOccurrences(of: "x", with: ""))!
    try png(size: Int(points * scale)).write(to: catalog.appendingPathComponent(item["filename"]!))
}
for scale in 1...3 {
    let filename = scale == 1 ? "LaunchImage.png" : "LaunchImage@\(scale)x.png"
    try png(size: 96 * scale, launch: true).write(to:
        assets.appendingPathComponent("LaunchImage.imageset").appendingPathComponent(filename))
}
print("Generated opaque iOS icons and launch mark from local vector paths.")
