import SwiftUI
import CoreGraphics

public struct CustomShapePath {
    public static func cgPath(for kind: ShapeKind, in rect: CGRect, cornerRadius: Double = 12, starPoints: Int = 5, polygonSides: Int = 6) -> CGPath {
        return path(for: kind, in: rect, cornerRadius: cornerRadius, starPoints: starPoints, polygonSides: polygonSides).cgPath
    }

    public static func path(for kind: ShapeKind, in rect: CGRect, cornerRadius: Double = 12, starPoints: Int = 5, polygonSides: Int = 6) -> Path {
        switch kind {
        case .rectangle:
            return Path(rect)

        case .roundedRectangle:
            let radius = min(cornerRadius, min(rect.width, rect.height) / 2.0)
            return Path(roundedRect: rect, cornerRadius: CGFloat(radius))

        case .pill:
            let radius = min(rect.width, rect.height) / 2.0
            return Path(roundedRect: rect, cornerRadius: CGFloat(radius))

        case .washiTape:
            return washiTapePath(in: rect)

        case .postageStamp:
            return postageStampPath(in: rect)

        case .waxSeal:
            return waxSealPath(in: rect)

        case .tornPaper:
            return tornPaperPath(in: rect)

        case .oxfordBorder:
            return Path(rect)

        case .circle:
            return Path(ellipseIn: rect)

        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
            return path

        case .diamond:
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.closeSubpath()
            return path

        case .star:
            return starPath(in: rect, points: max(3, starPoints), innerRatio: 0.42)

        case .sparkleStar:
            return starPath(in: rect, points: 4, innerRatio: 0.22)

        case .starburst:
            return starPath(in: rect, points: 12, innerRatio: 0.72)

        case .polygon:
            return polygonPath(in: rect, sides: max(3, polygonSides))

        case .heart:
            return heartPath(in: rect)

        case .flower:
            return flowerPath(in: rect)

        case .arrow:
            return arrowPath(in: rect)

        case .chevron:
            return chevronPath(in: rect)

        case .speechBubble:
            return speechBubblePath(in: rect, cornerRadius: cornerRadius)

        case .quoteBubble:
            return quoteBubblePath(in: rect, cornerRadius: cornerRadius)

        case .bannerRibbon:
            return bannerRibbonPath(in: rect)

        case .bookmark:
            return bookmarkPath(in: rect)

        case .arch:
            return archPath(in: rect)

        case .shield:
            return shieldPath(in: rect)

        case .tag:
            return tagPath(in: rect)

        case .ticket:
            return ticketPath(in: rect)

        case .cross:
            return crossPath(in: rect)

        case .lightning:
            return lightningPath(in: rect)

        case .crescentMoon:
            return crescentMoonPath(in: rect)

        case .donut:
            return donutPath(in: rect)

        case .database:
            return databasePath(in: rect)

        case .parallelogram:
            return parallelogramPath(in: rect)

        case .trapezoid:
            return trapezoidPath(in: rect)

        case .cloud:
            return cloudPath(in: rect)

        case .badge:
            return starPath(in: rect, points: 16, innerRatio: 0.88)

        case .line:
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }

    // Washi Tape with serrated ripped zig-zag left and right edges
    private static func washiTapePath(in rect: CGRect) -> Path {
        var path = Path()
        let toothCount = 8
        let toothWidth: CGFloat = 6.0
        let toothHeight = rect.height / CGFloat(toothCount)

        // Start top-left
        path.move(to: CGPoint(x: rect.minX + toothWidth, y: rect.minY))

        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - toothWidth, y: rect.minY))

        // Right serrated edge
        for i in 0..<toothCount {
            let y1 = rect.minY + CGFloat(i) * toothHeight + toothHeight * 0.5
            let y2 = rect.minY + CGFloat(i + 1) * toothHeight
            let xTip = (i % 2 == 0) ? rect.maxX : (rect.maxX - toothWidth)
            path.addLine(to: CGPoint(x: xTip, y: y1))
            path.addLine(to: CGPoint(x: rect.maxX - toothWidth, y: y2))
        }

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + toothWidth, y: rect.maxY))

        // Left serrated edge
        for i in (0..<toothCount).reversed() {
            let y1 = rect.minY + CGFloat(i) * toothHeight + toothHeight * 0.5
            let y2 = rect.minY + CGFloat(i) * toothHeight
            let xTip = (i % 2 == 0) ? rect.minX : (rect.minX + toothWidth)
            path.addLine(to: CGPoint(x: xTip, y: y1))
            path.addLine(to: CGPoint(x: rect.minX + toothWidth, y: y2))
        }

        path.closeSubpath()
        return path
    }

    // Postage Stamp with scalloped perforated teeth along all 4 edges
    private static func postageStampPath(in rect: CGRect) -> Path {
        var path = Path()
        let notchRadius: CGFloat = 4.0
        let notchSpacing: CGFloat = 14.0

        let hNotches = max(2, Int(rect.width / notchSpacing))
        let vNotches = max(2, Int(rect.height / notchSpacing))

        let actualHStep = rect.width / CGFloat(hNotches)
        let actualVStep = rect.height / CGFloat(vNotches)

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // Top edge
        for i in 0..<hNotches {
            let cx = rect.minX + CGFloat(i) * actualHStep + actualHStep / 2.0
            path.addLine(to: CGPoint(x: cx - notchRadius, y: rect.minY))
            path.addArc(
                center: CGPoint(x: cx, y: rect.minY),
                radius: notchRadius,
                startAngle: .radians(.pi),
                endAngle: .radians(0),
                clockwise: true
            )
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Right edge
        for i in 0..<vNotches {
            let cy = rect.minY + CGFloat(i) * actualVStep + actualVStep / 2.0
            path.addLine(to: CGPoint(x: rect.maxX, y: cy - notchRadius))
            path.addArc(
                center: CGPoint(x: rect.maxX, y: cy),
                radius: notchRadius,
                startAngle: .radians(1.5 * .pi),
                endAngle: .radians(0.5 * .pi),
                clockwise: true
            )
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        // Bottom edge
        for i in (0..<hNotches).reversed() {
            let cx = rect.minX + CGFloat(i) * actualHStep + actualHStep / 2.0
            path.addLine(to: CGPoint(x: cx + notchRadius, y: rect.maxY))
            path.addArc(
                center: CGPoint(x: cx, y: rect.maxY),
                radius: notchRadius,
                startAngle: .radians(0),
                endAngle: .radians(.pi),
                clockwise: true
            )
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        // Left edge
        for i in (0..<vNotches).reversed() {
            let cy = rect.minY + CGFloat(i) * actualVStep + actualVStep / 2.0
            path.addLine(to: CGPoint(x: rect.minX, y: cy + notchRadius))
            path.addArc(
                center: CGPoint(x: rect.minX, y: cy),
                radius: notchRadius,
                startAngle: .radians(0.5 * .pi),
                endAngle: .radians(1.5 * .pi),
                clockwise: true
            )
        }
        path.closeSubpath()
        return path
    }

    // Wax Seal with organic scalloped edges
    private static func waxSealPath(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerR = min(rect.width, rect.height) / 2.0
        let innerR = outerR * 0.92
        let scallops = 20
        let angleStep = (2.0 * .pi) / CGFloat(scallops)

        for i in 0..<scallops {
            let a1 = CGFloat(i) * angleStep
            let a2 = CGFloat(i + 1) * angleStep
            let aMid = (a1 + a2) / 2.0

            let p1 = CGPoint(x: center.x + innerR * cos(a1), y: center.y + innerR * sin(a1))
            let pTip = CGPoint(x: center.x + outerR * cos(aMid), y: center.y + outerR * sin(aMid))
            let p2 = CGPoint(x: center.x + innerR * cos(a2), y: center.y + innerR * sin(a2))

            if i == 0 {
                path.move(to: p1)
            }
            path.addQuadCurve(to: p2, control: pTip)
        }
        path.closeSubpath()
        return path
    }

    // Torn Paper Deckled Edge
    private static func tornPaperPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 8))

        // Torn bottom edge
        let step: CGFloat = 16
        var x = rect.maxX
        var toggle = false
        while x > rect.minX + step {
            x -= step
            let yOffset: CGFloat = toggle ? 0 : 8
            path.addLine(to: CGPoint(x: x, y: rect.maxY - yOffset))
            toggle.toggle()
        }
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 8))
        path.closeSubpath()
        return path
    }

    private static func starPath(in rect: CGRect, points: Int, innerRatio: CGFloat) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2.0
        let innerRadius = outerRadius * innerRatio
        let angleStep = .pi / CGFloat(points)
        var angle: CGFloat = -.pi / 2.0

        for i in 0..<(points * 2) {
            let radius = (i % 2 == 0) ? outerRadius : innerRadius
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            angle += angleStep
        }
        path.closeSubpath()
        return path
    }

    private static func polygonPath(in rect: CGRect, sides: Int) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2.0
        let angleStep = (2.0 * .pi) / CGFloat(sides)
        var angle: CGFloat = -.pi / 2.0

        for i in 0..<sides {
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            angle += angleStep
        }
        path.closeSubpath()
        return path
    }

    private static func heartPath(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: rect.minX + width * 0.5, y: rect.minY + height * 0.8))
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + height * 0.3),
            control1: CGPoint(x: rect.minX + width * 0.1, y: rect.minY + height * 0.6),
            control2: CGPoint(x: rect.minX + width * 0.45, y: rect.minY + height * 0.45)
        )
        path.addArc(
            center: CGPoint(x: rect.minX + width * 0.25, y: rect.minY + height * 0.25),
            radius: width * 0.25,
            startAngle: .radians(.pi),
            endAngle: .radians(0),
            clockwise: false
        )
        path.addArc(
            center: CGPoint(x: rect.minX + width * 0.75, y: rect.minY + height * 0.25),
            radius: width * 0.25,
            startAngle: .radians(.pi),
            endAngle: .radians(0),
            clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + width * 0.5, y: rect.minY + height * 0.8),
            control1: CGPoint(x: rect.maxX, y: rect.minY + height * 0.45),
            control2: CGPoint(x: rect.minX + width * 0.9, y: rect.minY + height * 0.6)
        )
        path.closeSubpath()
        return path
    }

    private static func arrowPath(in rect: CGRect) -> Path {
        var path = Path()
        let headWidth = rect.width * 0.35
        let stemHeight = rect.height * 0.4
        let stemTop = (rect.height - stemHeight) / 2.0
        let stemBottom = stemTop + stemHeight

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + stemTop))
        path.addLine(to: CGPoint(x: rect.maxX - headWidth, y: rect.minY + stemTop))
        path.addLine(to: CGPoint(x: rect.maxX - headWidth, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - headWidth, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - headWidth, y: rect.minY + stemBottom))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + stemBottom))
        path.closeSubpath()
        return path
    }

    private static func speechBubblePath(in rect: CGRect, cornerRadius: Double) -> Path {
        var path = Path()
        let tailHeight: CGFloat = min(20, rect.height * 0.2)
        let bubbleRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailHeight)
        let radius = CGFloat(min(cornerRadius, min(bubbleRect.width, bubbleRect.height) / 2.0))

        path.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: radius, height: radius))

        let tailStart = bubbleRect.minX + bubbleRect.width * 0.25
        let tailEnd = tailStart + min(30, bubbleRect.width * 0.2)
        path.move(to: CGPoint(x: tailStart, y: bubbleRect.maxY))
        path.addLine(to: CGPoint(x: tailStart + 8, y: rect.maxY))
        path.addLine(to: CGPoint(x: tailEnd, y: bubbleRect.maxY))
        path.closeSubpath()
        return path
    }

    private static func chevronPath(in rect: CGRect) -> Path {
        var path = Path()
        let indent = rect.width * 0.28
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - indent, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - indent, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + indent, y: rect.midY))
        path.closeSubpath()
        return path
    }

    private static func bannerRibbonPath(in rect: CGRect) -> Path {
        var path = Path()
        let notch = rect.width * 0.12
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + notch, y: rect.midY))
        path.closeSubpath()
        return path
    }

    private static func archPath(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.width / 2.0
        let archTop = rect.minY + radius

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: archTop))
        path.addArc(
            center: CGPoint(x: rect.midX, y: archTop),
            radius: radius,
            startAngle: .radians(.pi),
            endAngle: .radians(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    private static func shieldPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.55))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.8),
            control2: CGPoint(x: rect.midX + rect.width * 0.2, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.55),
            control1: CGPoint(x: rect.midX - rect.width * 0.2, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.8)
        )
        path.closeSubpath()
        return path
    }

    private static func tagPath(in rect: CGRect) -> Path {
        var path = Path()
        let chamfer = min(rect.width * 0.25, rect.height * 0.25)
        path.move(to: CGPoint(x: rect.minX + chamfer, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - chamfer, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + chamfer))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + chamfer))
        path.closeSubpath()
        return path
    }

    private static func ticketPath(in rect: CGRect) -> Path {
        var path = Path()
        let notchRadius = min(16.0, min(rect.width, rect.height) * 0.18)

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        // Right notch
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY - notchRadius))
        path.addArc(
            center: CGPoint(x: rect.maxX, y: rect.midY),
            radius: notchRadius,
            startAngle: .radians(1.5 * .pi),
            endAngle: .radians(0.5 * .pi),
            clockwise: true
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        // Left notch
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + notchRadius))
        path.addArc(
            center: CGPoint(x: rect.minX, y: rect.midY),
            radius: notchRadius,
            startAngle: .radians(0.5 * .pi),
            endAngle: .radians(1.5 * .pi),
            clockwise: true
        )
        path.closeSubpath()
        return path
    }

    private static func crossPath(in rect: CGRect) -> Path {
        var path = Path()
        let armW = rect.width * 0.34
        let armH = rect.height * 0.34
        let x1 = (rect.width - armW) / 2.0 + rect.minX
        let x2 = x1 + armW
        let y1 = (rect.height - armH) / 2.0 + rect.minY
        let y2 = y1 + armH

        path.move(to: CGPoint(x: x1, y: rect.minY))
        path.addLine(to: CGPoint(x: x2, y: rect.minY))
        path.addLine(to: CGPoint(x: x2, y: y1))
        path.addLine(to: CGPoint(x: rect.maxX, y: y1))
        path.addLine(to: CGPoint(x: rect.maxX, y: y2))
        path.addLine(to: CGPoint(x: x2, y: y2))
        path.addLine(to: CGPoint(x: x2, y: rect.maxY))
        path.addLine(to: CGPoint(x: x1, y: rect.maxY))
        path.addLine(to: CGPoint(x: x1, y: y2))
        path.addLine(to: CGPoint(x: rect.minX, y: y2))
        path.addLine(to: CGPoint(x: rect.minX, y: y1))
        path.addLine(to: CGPoint(x: x1, y: y1))
        path.closeSubpath()
        return path
    }

    private static func flowerPath(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let petalCount = 8
        let radius = min(rect.width, rect.height) / 2.0
        let petalRadius = radius * 0.45

        for i in 0..<petalCount {
            let angle = (CGFloat(i) * 2.0 * .pi) / CGFloat(petalCount)
            let petalCenter = CGPoint(
                x: center.x + (radius - petalRadius) * cos(angle),
                y: center.y + (radius - petalRadius) * sin(angle)
            )
            path.addEllipse(in: CGRect(
                x: petalCenter.x - petalRadius,
                y: petalCenter.y - petalRadius,
                width: petalRadius * 2,
                height: petalRadius * 2
            ))
        }
        path.addEllipse(in: CGRect(
            x: center.x - petalRadius * 0.8,
            y: center.y - petalRadius * 0.8,
            width: petalRadius * 1.6,
            height: petalRadius * 1.6
        ))
        return path
    }

    private static func quoteBubblePath(in rect: CGRect, cornerRadius: Double) -> Path {
        var path = Path()
        let bubbleRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height * 0.85)
        let radius = min(cornerRadius, min(bubbleRect.width, bubbleRect.height) / 2.0)
        path.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: radius, height: radius))

        // Curved quote tail on bottom left
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.2, y: bubbleRect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.maxY),
            control: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.maxY - 4)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.35, y: bubbleRect.maxY),
            control: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.maxY - 2)
        )
        path.closeSubpath()
        return path
    }

    private static func bookmarkPath(in rect: CGRect) -> Path {
        var path = Path()
        let notchHeight = min(30.0, rect.height * 0.22)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - notchHeight))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    private static func lightningPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.55, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.minY + rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.48, y: rect.minY + rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.35, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.85, y: rect.minY + rect.height * 0.44))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.52, y: rect.minY + rect.height * 0.44))
        path.closeSubpath()
        return path
    }

    private static func crescentMoonPath(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2.0

        // Outer circular arc
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .radians(-0.4 * .pi),
            endAngle: .radians(0.6 * .pi),
            clockwise: false
        )
        // Inner scooping arc
        path.addCurve(
            to: CGPoint(x: center.x + radius * cos(-0.4 * .pi), y: center.y + radius * sin(-0.4 * .pi)),
            control1: CGPoint(x: center.x + radius * 0.2, y: center.y + radius * 0.5),
            control2: CGPoint(x: center.x + radius * 0.2, y: center.y - radius * 0.3)
        )
        path.closeSubpath()
        return path
    }

    private static func donutPath(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect)
        let innerRect = rect.insetBy(dx: rect.width * 0.25, dy: rect.height * 0.25)
        path.addEllipse(in: innerRect)
        return path
    }

    /// Database cylinder (OOXML "can" / flowChartMagneticDisk): elliptical lid,
    /// straight sides, curved bottom edge. The lid's back arc closes the body
    /// and a full top ellipse adds the front rim — matching PowerPoint's "can".
    private static func databasePath(in rect: CGRect) -> Path {
        var path = Path()
        let capH = min(rect.height * 0.22, rect.width * 0.5)
        let rx = rect.width / 2
        let ry = capH / 2
        let cx = rect.midX
        let topCY = rect.minY + ry
        let botCY = rect.maxY - ry
        let k: CGFloat = 0.5522847498 // circle→cubic constant for a quarter ellipse

        // Body: left rim → down → front bottom half-ellipse → up right rim →
        // back arc of the lid → close.
        path.move(to: CGPoint(x: rect.minX, y: topCY))
        path.addLine(to: CGPoint(x: rect.minX, y: botCY))
        path.addCurve(
            to: CGPoint(x: cx, y: rect.maxY),
            control1: CGPoint(x: rect.minX, y: botCY + k * ry),
            control2: CGPoint(x: cx - k * rx, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: botCY),
            control1: CGPoint(x: cx + k * rx, y: rect.maxY),
            control2: CGPoint(x: rect.maxX, y: botCY + k * ry)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: topCY))
        path.addCurve(
            to: CGPoint(x: cx, y: rect.minY),
            control1: CGPoint(x: rect.maxX, y: topCY - k * ry),
            control2: CGPoint(x: cx + k * rx, y: rect.minY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: topCY),
            control1: CGPoint(x: cx - k * rx, y: rect.minY),
            control2: CGPoint(x: rect.minX, y: topCY - k * ry)
        )
        path.closeSubpath()

        // Full lid ellipse: fills the top and strokes the front rim.
        path.addEllipse(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: capH))
        return path
    }

    private static func parallelogramPath(in rect: CGRect) -> Path {
        var path = Path()
        let slant = rect.width * 0.22
        path.move(to: CGPoint(x: rect.minX + slant, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - slant, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    private static func trapezoidPath(in rect: CGRect) -> Path {
        var path = Path()
        let inset = rect.width * 0.18
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    private static func cloudPath(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let baseH = h * 0.3

        // Flat bottom with rounded corners
        path.move(to: CGPoint(x: rect.minX + w * 0.2, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.2, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.maxX - w * 0.2, y: rect.maxY - baseH * 0.5), radius: baseH * 0.5, startAngle: .radians(0.5 * .pi), endAngle: .radians(0), clockwise: true)
        path.addArc(center: CGPoint(x: rect.maxX - w * 0.3, y: rect.minY + h * 0.45), radius: w * 0.2, startAngle: .radians(0), endAngle: .radians(-0.5 * .pi), clockwise: true)
        path.addArc(center: CGPoint(x: rect.minX + w * 0.45, y: rect.minY + h * 0.35), radius: w * 0.28, startAngle: .radians(-0.3 * .pi), endAngle: .radians(-0.9 * .pi), clockwise: true)
        path.addArc(center: CGPoint(x: rect.minX + w * 0.2, y: rect.maxY - baseH * 0.7), radius: w * 0.18, startAngle: .radians(-0.8 * .pi), endAngle: .radians(0.5 * .pi), clockwise: true)
        path.closeSubpath()
        return path
    }
}
