import Cocoa

// 粉色小飞机浮层：从命令行参数读文案与 emoji。
//   plane <message> [emoji]
// 例：plane "皇帝，该吃午饭了" 🍱
// 动画约 10 秒，飞完自动退出，不常驻后台。

struct PlaneConfig {
    let message: String
    let emoji: String

    static func fromArguments() -> PlaneConfig {
        let args = CommandLine.arguments
        // args[0] 是程序路径；args[1] 文案；args[2] 可选 emoji。
        let message = args.count > 1 && !args[1].isEmpty ? args[1] : "皇帝，该休息一下了"
        let emoji = args.count > 2 && !args[2].isEmpty ? args[2] : "🛩"
        return PlaneConfig(message: message, emoji: emoji)
    }
}

final class PlaneView: NSView {
    private let config: PlaneConfig
    private let startTime = Date()
    private let duration: TimeInterval = 10.0
    private var timer: Timer?

    private enum Palette {
        static let rose = NSColor(calibratedRed: 0.98, green: 0.23, blue: 0.55, alpha: 1)
        static let pink = NSColor(calibratedRed: 1.00, green: 0.48, blue: 0.72, alpha: 1)
        static let blush = NSColor(calibratedRed: 1.00, green: 0.78, blue: 0.88, alpha: 1)
        static let porcelain = NSColor(calibratedRed: 1.00, green: 0.96, blue: 0.98, alpha: 1)
        static let burgundy = NSColor(calibratedRed: 0.48, green: 0.05, blue: 0.22, alpha: 1)
        static let gold = NSColor(calibratedRed: 1.00, green: 0.78, blue: 0.30, alpha: 1)
    }

    init(frame frameRect: NSRect, config: PlaneConfig) {
        self.config = config
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        startAnimationLoop()
    }

    required init?(coder: NSCoder) {
        self.config = PlaneConfig.fromArguments()
        super.init(coder: coder)
        startAnimationLoop()
    }

    private func startAnimationLoop() {
        // 60 FPS 刷新，飞完后自动退出，不常驻后台。
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if Date().timeIntervalSince(self.startTime) >= self.duration {
                NSApp.terminate(nil)
            } else {
                self.needsDisplay = true
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        NSGraphicsContext.current?.shouldAntialias = true

        let elapsed = Date().timeIntervalSince(startTime)
        let progress = max(0, min(1, elapsed / duration))
        let easedProgress = 0.5 - cos(CGFloat(progress) * .pi) / 2
        let planeWidth: CGFloat = 500
        let startX = -planeWidth - 80
        let endX = bounds.width + 80
        let x = startX + easedProgress * (endX - startX)
        let bob = sin(CGFloat(progress) * .pi * 5)
        let y = bounds.height * 0.58 + bob * 8

        context.saveGState()
        context.translateBy(x: x, y: y)
        context.rotate(by: bob * 0.018)
        drawSpeedTrails(in: context, progress: CGFloat(progress))
        drawSparkles(in: context, progress: CGFloat(progress))
        drawPlane(in: context, progress: CGFloat(progress))
        drawMessageBubble()
        context.restoreGState()
    }

    private func drawPlane(in context: CGContext, progress: CGFloat) {
        drawTailAndWings(in: context)

        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: -7),
            blur: 18,
            color: NSColor.black.withAlphaComponent(0.22).cgColor
        )

        // 一体式胶囊机身，顶部更亮、底部更浓，增加立体感。
        let body = NSBezierPath()
        body.move(to: NSPoint(x: 55, y: -28))
        body.curve(to: NSPoint(x: 302, y: -23), controlPoint1: NSPoint(x: 110, y: -34), controlPoint2: NSPoint(x: 255, y: -31))
        body.curve(to: NSPoint(x: 328, y: 0), controlPoint1: NSPoint(x: 318, y: -20), controlPoint2: NSPoint(x: 328, y: -11))
        body.curve(to: NSPoint(x: 300, y: 27), controlPoint1: NSPoint(x: 328, y: 13), controlPoint2: NSPoint(x: 315, y: 24))
        body.curve(to: NSPoint(x: 55, y: 28), controlPoint1: NSPoint(x: 240, y: 34), controlPoint2: NSPoint(x: 112, y: 33))
        body.curve(to: NSPoint(x: 55, y: -28), controlPoint1: NSPoint(x: 36, y: 18), controlPoint2: NSPoint(x: 36, y: -18))
        body.close()
        NSGradient(starting: Palette.blush, ending: Palette.rose)?.draw(in: body, angle: -90)
        Palette.burgundy.withAlphaComponent(0.18).setStroke()
        body.lineWidth = 1.4
        body.stroke()
        context.restoreGState()

        // 机身高光。
        let highlight = NSBezierPath()
        highlight.move(to: NSPoint(x: 68, y: 17))
        highlight.curve(to: NSPoint(x: 286, y: 19), controlPoint1: NSPoint(x: 132, y: 27), controlPoint2: NSPoint(x: 235, y: 25))
        NSColor.white.withAlphaComponent(0.48).setStroke()
        highlight.lineWidth = 4
        highlight.lineCapStyle = .round
        highlight.stroke()

        drawCockpit()
        drawWindows()
        drawEmojiBadge()
        drawHeartMark()
        drawNoseAndPropeller(in: context, progress: progress)
    }

    private func drawTailAndWings(in context: CGContext) {
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -4), blur: 9, color: NSColor.black.withAlphaComponent(0.14).cgColor)

        // 后方机翼先画，保持自然遮挡关系。
        let lowerWing = NSBezierPath()
        lowerWing.move(to: NSPoint(x: 155, y: -7))
        lowerWing.line(to: NSPoint(x: 218, y: -72))
        lowerWing.curve(to: NSPoint(x: 244, y: -62), controlPoint1: NSPoint(x: 230, y: -76), controlPoint2: NSPoint(x: 245, y: -71))
        lowerWing.line(to: NSPoint(x: 205, y: -5))
        lowerWing.close()
        NSGradient(starting: Palette.pink, ending: Palette.rose)?.draw(in: lowerWing, angle: 90)

        // 圆润尾翼。
        let tailFin = NSBezierPath()
        tailFin.move(to: NSPoint(x: 76, y: 12))
        tailFin.line(to: NSPoint(x: 36, y: 63))
        tailFin.curve(to: NSPoint(x: 70, y: 24), controlPoint1: NSPoint(x: 56, y: 65), controlPoint2: NSPoint(x: 74, y: 49))
        tailFin.close()
        NSGradient(starting: Palette.pink, ending: Palette.rose)?.draw(in: tailFin, angle: -35)

        let tailWing = NSBezierPath()
        tailWing.move(to: NSPoint(x: 72, y: 2))
        tailWing.line(to: NSPoint(x: 23, y: -16))
        tailWing.curve(to: NSPoint(x: 88, y: -10), controlPoint1: NSPoint(x: 31, y: -29), controlPoint2: NSPoint(x: 67, y: -20))
        tailWing.close()
        Palette.blush.setFill()
        tailWing.fill()
        context.restoreGState()

        // 上方主翼最后压在机身上，轮廓更有层次。
        let upperWing = NSBezierPath()
        upperWing.move(to: NSPoint(x: 145, y: 7))
        upperWing.line(to: NSPoint(x: 220, y: 76))
        upperWing.curve(to: NSPoint(x: 249, y: 65), controlPoint1: NSPoint(x: 232, y: 81), controlPoint2: NSPoint(x: 251, y: 75))
        upperWing.line(to: NSPoint(x: 205, y: 5))
        upperWing.close()
        NSGradient(starting: Palette.porcelain, ending: Palette.pink)?.draw(in: upperWing, angle: -70)
        Palette.rose.withAlphaComponent(0.28).setStroke()
        upperWing.lineWidth = 1.2
        upperWing.stroke()
    }

    private func drawCockpit() {
        let cockpit = NSBezierPath()
        cockpit.move(to: NSPoint(x: 220, y: 23))
        cockpit.curve(to: NSPoint(x: 279, y: 20), controlPoint1: NSPoint(x: 238, y: 45), controlPoint2: NSPoint(x: 270, y: 40))
        cockpit.curve(to: NSPoint(x: 220, y: 23), controlPoint1: NSPoint(x: 264, y: 24), controlPoint2: NSPoint(x: 240, y: 24))
        cockpit.close()
        let glassTop = NSColor(calibratedRed: 0.64, green: 0.34, blue: 0.55, alpha: 1)
        let glassBottom = NSColor(calibratedRed: 0.18, green: 0.10, blue: 0.22, alpha: 1)
        NSGradient(starting: glassTop, ending: glassBottom)?.draw(in: cockpit, angle: -90)
        NSColor.white.withAlphaComponent(0.48).setStroke()
        cockpit.lineWidth = 1.5
        cockpit.stroke()

        let reflection = NSBezierPath()
        reflection.move(to: NSPoint(x: 235, y: 28))
        reflection.curve(to: NSPoint(x: 258, y: 31), controlPoint1: NSPoint(x: 242, y: 34), controlPoint2: NSPoint(x: 251, y: 35))
        NSColor.white.withAlphaComponent(0.42).setStroke()
        reflection.lineWidth = 3
        reflection.lineCapStyle = .round
        reflection.stroke()
    }

    private func drawWindows() {
        for index in 0..<3 {
            let x = CGFloat(138 + index * 25)
            let outer = NSBezierPath(ovalIn: NSRect(x: x, y: -7, width: 17, height: 17))
            Palette.burgundy.withAlphaComponent(0.48).setFill()
            outer.fill()
            let inner = NSBezierPath(ovalIn: NSRect(x: x + 3, y: -3.5, width: 11, height: 11))
            NSColor(calibratedRed: 0.97, green: 0.88, blue: 0.96, alpha: 0.94).setFill()
            inner.fill()
        }
    }

    private func drawEmojiBadge() {
        let badgeRect = NSRect(x: 87, y: -18, width: 40, height: 36)
        let badge = NSBezierPath(roundedRect: badgeRect, xRadius: 12, yRadius: 12)
        Palette.porcelain.setFill()
        badge.fill()
        Palette.gold.withAlphaComponent(0.7).setStroke()
        badge.lineWidth = 1.2
        badge.stroke()

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24)
        ]
        config.emoji.draw(in: NSRect(x: 94, y: -14, width: 28, height: 28), withAttributes: attributes)
    }

    private func drawHeartMark() {
        let heart = NSBezierPath()
        heart.move(to: NSPoint(x: 72, y: -3))
        heart.curve(to: NSPoint(x: 61, y: 7), controlPoint1: NSPoint(x: 67, y: 3), controlPoint2: NSPoint(x: 61, y: 1))
        heart.curve(to: NSPoint(x: 72, y: 17), controlPoint1: NSPoint(x: 61, y: 12), controlPoint2: NSPoint(x: 66, y: 15))
        heart.curve(to: NSPoint(x: 83, y: 7), controlPoint1: NSPoint(x: 78, y: 15), controlPoint2: NSPoint(x: 83, y: 12))
        heart.curve(to: NSPoint(x: 72, y: -3), controlPoint1: NSPoint(x: 83, y: 1), controlPoint2: NSPoint(x: 77, y: 3))
        heart.close()
        Palette.porcelain.setFill()
        heart.fill()
    }

    private func drawNoseAndPropeller(in context: CGContext, progress: CGFloat) {
        let nose = NSBezierPath(ovalIn: NSRect(x: 304, y: -23, width: 32, height: 46))
        NSGradient(starting: Palette.rose, ending: Palette.burgundy)?.draw(in: nose, angle: 0)

        let hub = NSBezierPath(ovalIn: NSRect(x: 327, y: -9, width: 18, height: 18))
        Palette.gold.setFill()
        hub.fill()

        context.saveGState()
        context.translateBy(x: 343, y: 0)
        context.rotate(by: progress * .pi * 34)
        for angle in [CGFloat(0), .pi / 2] {
            context.saveGState()
            context.rotate(by: angle)
            let blade = NSBezierPath(roundedRect: NSRect(x: -5, y: -42, width: 10, height: 84), xRadius: 5, yRadius: 5)
            NSColor.white.withAlphaComponent(0.62).setFill()
            blade.fill()
            Palette.rose.withAlphaComponent(0.34).setStroke()
            blade.lineWidth = 1
            blade.stroke()
            context.restoreGState()
        }
        let center = NSBezierPath(ovalIn: NSRect(x: -7, y: -7, width: 14, height: 14))
        Palette.gold.setFill()
        center.fill()
        context.restoreGState()
    }

    private func drawMessageBubble() {
        let bubbleRect = NSRect(x: -26, y: -96, width: 420, height: 48)
        let bubble = NSBezierPath(roundedRect: bubbleRect, xRadius: 18, yRadius: 18)
        NSGraphicsContext.current?.cgContext.setShadow(
            offset: CGSize(width: 0, height: -4),
            blur: 12,
            color: NSColor.black.withAlphaComponent(0.18).cgColor
        )
        NSColor.white.withAlphaComponent(0.96).setFill()
        bubble.fill()
        NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: 0, color: nil)

        let pointer = NSBezierPath()
        pointer.move(to: NSPoint(x: 252, y: -48))
        pointer.line(to: NSPoint(x: 270, y: -48))
        pointer.line(to: NSPoint(x: 263, y: -38))
        pointer.close()
        NSColor.white.withAlphaComponent(0.96).setFill()
        pointer.fill()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 22, weight: .semibold),
            .foregroundColor: Palette.burgundy,
            .paragraphStyle: paragraph
        ]
        config.message.draw(in: NSRect(x: 2, y: -87, width: 368, height: 30), withAttributes: attributes)
    }

    private func drawSparkles(in context: CGContext, progress: CGFloat) {
        for index in 0..<9 {
            let offset = CGFloat(index) * 31
            let alphaWave = 0.28 + 0.52 * abs(sin(progress * 18 + CGFloat(index)))
            context.setAlpha(alphaWave)
            let size = CGFloat(4 + index % 3)
            let center = NSPoint(x: 28 - offset, y: CGFloat(index % 5) * 14 - 29)

            if index % 3 == 0 {
                Palette.gold.setFill()
                let star = NSBezierPath()
                star.move(to: NSPoint(x: center.x, y: center.y + size))
                star.line(to: NSPoint(x: center.x + size * 0.3, y: center.y + size * 0.3))
                star.line(to: NSPoint(x: center.x + size, y: center.y))
                star.line(to: NSPoint(x: center.x + size * 0.3, y: center.y - size * 0.3))
                star.line(to: NSPoint(x: center.x, y: center.y - size))
                star.line(to: NSPoint(x: center.x - size * 0.3, y: center.y - size * 0.3))
                star.line(to: NSPoint(x: center.x - size, y: center.y))
                star.line(to: NSPoint(x: center.x - size * 0.3, y: center.y + size * 0.3))
                star.close()
                star.fill()
            } else {
                Palette.blush.setFill()
                NSBezierPath(ovalIn: NSRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)).fill()
            }
        }
        context.setAlpha(1)
    }

    private func drawSpeedTrails(in context: CGContext, progress: CGFloat) {
        context.saveGState()
        context.setLineCap(.round)
        for index in 0..<3 {
            let y = CGFloat(index - 1) * 17
            let pulse = 16 * abs(sin(progress * 12 + CGFloat(index)))
            let trail = NSBezierPath()
            trail.move(to: NSPoint(x: 45, y: y))
            trail.line(to: NSPoint(x: -115 - CGFloat(index * 30) - pulse, y: y))
            let trailColor = index == 1 ? Palette.gold : Palette.pink
            trailColor.withAlphaComponent(0.24 - CGFloat(index) * 0.035).setStroke()
            trail.lineWidth = CGFloat(7 - index * 2)
            trail.lineCapStyle = .round
            trail.stroke()
        }
        context.restoreGState()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let config = PlaneConfig.fromArguments()

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else {
            NSApp.terminate(nil)
            return
        }

        let visibleFrame = screen.visibleFrame
        let windowHeight: CGFloat = 300
        let frame = NSRect(
            x: screen.frame.minX,
            y: visibleFrame.maxY - windowHeight,
            width: screen.frame.width,
            height: windowHeight
        )

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.contentView = PlaneView(frame: NSRect(origin: .zero, size: frame.size), config: config)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: false)
        self.window = window
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
