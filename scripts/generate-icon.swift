import AppKit
import Foundation

// GlassNeedle's original app icon is generated for all iconset resolutions
// on the actual macOS GitHub Actions build machine.
let folder = URL(fileURLWithPath: "Resources/AppIcon.iconset", isDirectory: true)
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
let sizes: [(String, Int)] = [
    ("icon_16x16.png",16),("icon_16x16@2x.png",32),
    ("icon_32x32.png",32),("icon_32x32@2x.png",64),
    ("icon_128x128.png",128),("icon_128x128@2x.png",256),
    ("icon_256x256.png",256),("icon_256x256@2x.png",512),
    ("icon_512x512.png",512),("icon_512x512@2x.png",1024)
]
for (filename, width) in sizes {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width,
        pixelsHigh: width, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0),
        let ctx = NSGraphicsContext(bitmapImageRep: bitmap) else { fatalError("bitmap") }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    let c = ctx.cgContext
    let s = CGFloat(width)
    c.setAllowsAntialiasing(true)
    let bg = CGRect(x: s*0.035, y: s*0.035, width: s*0.93, height: s*0.93)
    let rounded = CGPath(roundedRect: bg, cornerWidth: s*0.22,
                         cornerHeight: s*0.22, transform: nil)
    c.addPath(rounded); c.clip()
    c.setFillColor(CGColor(red:0.052,green:0.075,blue:0.125,alpha:1));c.fill(bg)
    let cx=s*0.46,cy=s*0.49,r=s*0.30
    c.setFillColor(CGColor(red:0.015,green:0.023,blue:0.036,alpha:1))
    c.fillEllipse(in:CGRect(x:cx-r,y:cy-r,width:r*2,height:r*2))
    for i in 0..<12 {
        let radius=r*(0.40+CGFloat(i)*0.051)
        c.setStrokeColor(CGColor(red:0.73,green:0.85,blue:1.0,alpha:0.15))
        c.setLineWidth(max(0.6,s*0.002))
        c.strokeEllipse(in:CGRect(x:cx-radius,y:cy-radius,width:radius*2,height:radius*2))
    }
    let lr=s*0.105
    c.setFillColor(CGColor(red:0.2,green:0.80,blue:0.9,alpha:1))
    c.fillEllipse(in:CGRect(x:cx-lr,y:cy-lr,width:lr*2,height:lr*2))
    c.setLineCap(.round)
    c.setLineWidth(s*0.027)
    c.setStrokeColor(CGColor(red:0.87,green:0.90,blue:0.96,alpha:1))
    c.move(to:CGPoint(x:s*0.79,y:s*0.79))
    c.addLine(to:CGPoint(x:s*0.735,y:s*0.48))
    c.addLine(to:CGPoint(x:s*0.64,y:s*0.42))
    c.strokePath()
    c.setFillColor(CGColor(red:0.93,green:0.96,blue:1,alpha:1))
    c.fillEllipse(in:CGRect(x:s*0.77,y:s*0.75,width:s*0.07,height:s*0.07))
    c.setStrokeColor(CGColor(red:0.73,green:0.85,blue:1,alpha:0.5))
    c.setLineWidth(s*0.013);c.addPath(rounded);c.strokePath()
    NSGraphicsContext.restoreGraphicsState()
    guard let data=bitmap.representation(using:.png,properties:[:]) else { fatalError("png") }
    try data.write(to:folder.appendingPathComponent(filename))
}
print("Created \(sizes.count) macOS icon sizes")
