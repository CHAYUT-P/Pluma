import AppKit
import Foundation

func renderAppIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let scale = size / 1024.0

    // Coordinate system setup: (0,0) at bottom-left
    let fullRect = CGRect(x: 0, y: 0, width: size, height: size)

    // 1. macOS Squircle Shape (App Icon Grid Standard: 824x824 at 1024 base)
    let margin = 100.0 * scale
    let iconRect = fullRect.insetBy(dx: margin, dy: margin)
    let cornerRadius = 185.0 * scale
    let squirclePath = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Drop Shadow for Squircle
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -16 * scale),
        blur: 32 * scale,
        color: NSColor.black.withAlphaComponent(0.22).cgColor
    )
    ctx.addPath(squirclePath)
    ctx.setFillColor(NSColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // 2. Base Background Gradient (Warm Artisan Cream to Soft Amber)
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.99, green: 0.97, blue: 0.94, alpha: 1.0).cgColor,
        NSColor(red: 0.95, green: 0.91, blue: 0.85, alpha: 1.0).cgColor
    ] as CFArray
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(
            bgGradient,
            start: CGPoint(x: iconRect.midX, y: iconRect.maxY),
            end: CGPoint(x: iconRect.midX, y: iconRect.minY),
            options: []
        )
    }

    // Subtle Radial Glow in Center
    let glowColors = [
        NSColor(red: 0.95, green: 0.55, blue: 0.25, alpha: 0.18).cgColor,
        NSColor.clear.cgColor
    ] as CFArray
    if let glowGrad = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(
            glowGrad,
            startCenter: CGPoint(x: iconRect.midX, y: iconRect.midY),
            startRadius: 0,
            endCenter: CGPoint(x: iconRect.midX, y: iconRect.midY),
            endRadius: 400 * scale,
            options: []
        )
    }

    // Inner Border
    ctx.addPath(squirclePath)
    ctx.setLineWidth(2 * scale)
    ctx.setStrokeColor(NSColor.black.withAlphaComponent(0.08).cgColor)
    ctx.strokePath()

    // 3. ULTRA-CLEAN VECTOR MASCOT (Geometric Owl with Artist Paintbrush)
    let cx = iconRect.midX
    let cy = iconRect.midY - 15 * scale

    // 3.1 Mascot Body (Warm Terracotta #C2410C)
    let bodyW = 420.0 * scale
    let bodyH = 460.0 * scale
    let bodyRect = CGRect(x: cx - bodyW / 2 - 30 * scale, y: cy - bodyH / 2, width: bodyW, height: bodyH)
    let bodyCorner = 190.0 * scale
    let bodyPath = CGPath(roundedRect: bodyRect, cornerWidth: bodyCorner, cornerHeight: bodyCorner, transform: nil)

    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -12 * scale),
        blur: 24 * scale,
        color: NSColor(red: 0.76, green: 0.25, blue: 0.05, alpha: 0.35).cgColor
    )
    ctx.addPath(bodyPath)
    ctx.setFillColor(NSColor(red: 0.82, green: 0.30, blue: 0.10, alpha: 1.0).cgColor) // Terracotta
    ctx.fillPath()
    ctx.restoreGState()

    // Ear Tufts (Geometric triangles at top)
    let leftEar = CGMutablePath()
    leftEar.move(to: CGPoint(x: bodyRect.minX + 35 * scale, y: bodyRect.maxY - 80 * scale))
    leftEar.addLine(to: CGPoint(x: bodyRect.minX + 80 * scale, y: bodyRect.maxY + 40 * scale))
    leftEar.addLine(to: CGPoint(x: bodyRect.minX + 140 * scale, y: bodyRect.maxY - 20 * scale))
    leftEar.closeSubpath()
    ctx.addPath(leftEar)
    ctx.setFillColor(NSColor(red: 0.76, green: 0.25, blue: 0.08, alpha: 1.0).cgColor)
    ctx.fillPath()

    let rightEar = CGMutablePath()
    rightEar.move(to: CGPoint(x: bodyRect.maxX - 140 * scale, y: bodyRect.maxY - 20 * scale))
    rightEar.addLine(to: CGPoint(x: bodyRect.maxX - 80 * scale, y: bodyRect.maxY + 40 * scale))
    rightEar.addLine(to: CGPoint(x: bodyRect.maxX - 35 * scale, y: bodyRect.maxY - 80 * scale))
    rightEar.closeSubpath()
    ctx.addPath(rightEar)
    ctx.setFillColor(NSColor(red: 0.76, green: 0.25, blue: 0.08, alpha: 1.0).cgColor)
    ctx.fillPath()

    // 3.2 Cream Belly / Face Mask
    let faceW = 320.0 * scale
    let faceH = 260.0 * scale
    let faceRect = CGRect(x: bodyRect.midX - faceW / 2, y: bodyRect.midY - 80 * scale, width: faceW, height: faceH)
    let faceCorner = 110.0 * scale
    let facePath = CGPath(roundedRect: faceRect, cornerWidth: faceCorner, cornerHeight: faceCorner, transform: nil)

    ctx.addPath(facePath)
    ctx.setFillColor(NSColor(red: 1.0, green: 0.97, blue: 0.91, alpha: 1.0).cgColor) // Linen White
    ctx.fillPath()

    // 3.3 Cute Eyes (Clean Big Circles with Specular Sparkle)
    let eyeRadius = 26.0 * scale
    let eyeY = faceRect.midY + 30 * scale
    let leftEyeCenter = CGPoint(x: faceRect.midX - 60 * scale, y: eyeY)
    let rightEyeCenter = CGPoint(x: faceRect.midX + 60 * scale, y: eyeY)

    for eyeCenter in [leftEyeCenter, rightEyeCenter] {
        // Eye Pupil
        ctx.addArc(center: eyeCenter, radius: eyeRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.setFillColor(NSColor(red: 0.12, green: 0.10, blue: 0.09, alpha: 1.0).cgColor)
        ctx.fillPath()

        // Eye Sparkle Catchlight
        ctx.addArc(center: CGPoint(x: eyeCenter.x - 7 * scale, y: eyeCenter.y + 7 * scale), radius: 8 * scale, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fillPath()
    }

    // Blush Cheeks (Cute soft pink dots)
    let blushY = eyeY - 28 * scale
    ctx.addArc(center: CGPoint(x: faceRect.midX - 95 * scale, y: blushY), radius: 14 * scale, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.setFillColor(NSColor(red: 0.95, green: 0.45, blue: 0.45, alpha: 0.45).cgColor)
    ctx.fillPath()

    ctx.addArc(center: CGPoint(x: faceRect.midX + 95 * scale, y: blushY), radius: 14 * scale, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.setFillColor(NSColor(red: 0.95, green: 0.45, blue: 0.45, alpha: 0.45).cgColor)
    ctx.fillPath()

    // 3.4 Cute Golden Beak
    let beakPath = CGMutablePath()
    let beakTop = eyeY - 2 * scale
    beakPath.move(to: CGPoint(x: faceRect.midX - 22 * scale, y: beakTop))
    beakPath.addLine(to: CGPoint(x: faceRect.midX + 22 * scale, y: beakTop))
    beakPath.addLine(to: CGPoint(x: faceRect.midX, y: beakTop - 34 * scale))
    beakPath.closeSubpath()

    ctx.addPath(beakPath)
    ctx.setFillColor(NSColor(red: 0.96, green: 0.65, blue: 0.12, alpha: 1.0).cgColor) // Amber Gold
    ctx.fillPath()

    // 3.5 Minimalist Paintbrush (Bold Iconic Vector Angle)
    ctx.saveGState()
    ctx.translateBy(x: cx + 140 * scale, y: cy - 20 * scale)
    ctx.rotate(by: 32 * .pi / 180.0)

    // Brush Wooden Handle
    let handleRect = CGRect(x: -16 * scale, y: -180 * scale, width: 32 * scale, height: 220 * scale)
    let handlePath = CGPath(roundedRect: handleRect, cornerWidth: 14 * scale, cornerHeight: 14 * scale, transform: nil)
    ctx.addPath(handlePath)
    ctx.setFillColor(NSColor(red: 0.72, green: 0.48, blue: 0.28, alpha: 1.0).cgColor)
    ctx.fillPath()

    // Brush Metal Ferrule
    let ferruleRect = CGRect(x: -20 * scale, y: 35 * scale, width: 40 * scale, height: 42 * scale)
    let ferrulePath = CGPath(roundedRect: ferruleRect, cornerWidth: 6 * scale, cornerHeight: 6 * scale, transform: nil)
    ctx.addPath(ferrulePath)
    ctx.setFillColor(NSColor(red: 0.85, green: 0.87, blue: 0.90, alpha: 1.0).cgColor)
    ctx.fillPath()

    // Brush Bristles (Teal / Cyan with paint tip)
    let bristlePath = CGMutablePath()
    bristlePath.move(to: CGPoint(x: -22 * scale, y: 76 * scale))
    bristlePath.addCurve(
        to: CGPoint(x: 0, y: 160 * scale),
        control1: CGPoint(x: -32 * scale, y: 120 * scale),
        control2: CGPoint(x: -15 * scale, y: 155 * scale)
    )
    bristlePath.addCurve(
        to: CGPoint(x: 22 * scale, y: 76 * scale),
        control1: CGPoint(x: 15 * scale, y: 155 * scale),
        control2: CGPoint(x: 32 * scale, y: 120 * scale)
    )
    bristlePath.closeSubpath()

    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: 6 * scale),
        blur: 16 * scale,
        color: NSColor(red: 0.05, green: 0.65, blue: 0.85, alpha: 0.4).cgColor
    )
    ctx.addPath(bristlePath)
    ctx.setFillColor(NSColor(red: 0.08, green: 0.72, blue: 0.88, alpha: 1.0).cgColor) // Bright Cyan Paint
    ctx.fillPath()
    ctx.restoreGState()

    // Paint Tip Accents (Magenta & Yellow droplets on brush)
    let tipPink = CGMutablePath()
    tipPink.move(to: CGPoint(x: -12 * scale, y: 105 * scale))
    tipPink.addCurve(to: CGPoint(x: 0, y: 158 * scale), control1: CGPoint(x: -18 * scale, y: 135 * scale), control2: CGPoint(x: -8 * scale, y: 155 * scale))
    tipPink.addCurve(to: CGPoint(x: 8 * scale, y: 115 * scale), control1: CGPoint(x: 2 * scale, y: 145 * scale), control2: CGPoint(x: 6 * scale, y: 125 * scale))
    tipPink.closeSubpath()
    ctx.addPath(tipPink)
    ctx.setFillColor(NSColor(red: 0.95, green: 0.25, blue: 0.55, alpha: 1.0).cgColor) // Magenta Tip
    ctx.fillPath()

    ctx.restoreGState()

    ctx.restoreGState() // Clip restore

    image.unlockFocus()
    return image
}

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

let fileManager = FileManager.default
let iconsetDir = "Resources/AppIcon.iconset"
try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

for (filename, size) in sizes {
    let img = renderAppIcon(size: size)
    if let tiff = img.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        let path = "\(iconsetDir)/\(filename)"
        try? png.write(to: URL(fileURLWithPath: path))
    }
}

print("✅ Generated all vector PNG icon sizes!")
