import AppKit

let path = "PocketAILab/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let side = 1024
let image = NSImage(size: NSSize(width: side, height: side))
image.lockFocus()
let rect = NSRect(x: 0, y: 0, width: side, height: side)
let background = NSGradient(colors: [
    NSColor(calibratedRed: 0.93, green: 0.89, blue: 1.0, alpha: 1),
    NSColor(calibratedRed: 1.0, green: 0.90, blue: 0.92, alpha: 1)
])!
background.draw(in: rect, angle: -35)
let bubble = NSBezierPath(roundedRect: NSRect(x: 170, y: 158, width: 684, height: 684), xRadius: 215, yRadius: 215)
NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.84).setFill()
bubble.fill()
let glow = NSBezierPath(ovalIn: NSRect(x: 330, y: 350, width: 364, height: 364))
NSColor(calibratedRed: 0.72, green: 0.60, blue: 0.99, alpha: 1).setFill()
glow.fill()
let leftEye = NSBezierPath(ovalIn: NSRect(x: 441, y: 505, width: 17, height: 34))
let rightEye = NSBezierPath(ovalIn: NSRect(x: 565, y: 505, width: 17, height: 34))
NSColor(calibratedRed: 0.27, green: 0.20, blue: 0.40, alpha: 1).setFill()
leftEye.fill()
rightEye.fill()
let smile = NSBezierPath()
smile.move(to: NSPoint(x: 483, y: 478))
smile.curve(to: NSPoint(x: 541, y: 478), controlPoint1: NSPoint(x: 493, y: 456), controlPoint2: NSPoint(x: 528, y: 456))
smile.lineWidth = 12
smile.lineCapStyle = .round
smile.stroke()
for (x, y) in [(390, 475), (610, 475)] {
    let blush = NSBezierPath(ovalIn: NSRect(x: x, y: y, width: 40, height: 19))
    NSColor(calibratedRed: 1.0, green: 0.65, blue: 0.76, alpha: 0.85).setFill()
    blush.fill()
}
let star = "✦" as NSString
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 125, weight: .light),
    .foregroundColor: NSColor(calibratedRed: 0.68, green: 0.46, blue: 0.95, alpha: 1)
]
star.draw(at: NSPoint(x: 690, y: 670), withAttributes: attrs)
image.unlockFocus()
guard let data = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: data),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not render app icon")
}
try png.write(to: URL(fileURLWithPath: path))
print("Generated \(path)")
