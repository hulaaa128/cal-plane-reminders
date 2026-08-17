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

        let elapsed = Date().timeIntervalSince(startTime)
        let progress = max(0, min(1, elapsed / duration))
        let easedProgress = 0.5 - cos(CGFloat(progress) * .pi) / 2
        let planeWidth: CGFloat = 420
        let startX = -planeWidth - 80
        let endX = bounds.width + 80
        let x = startX + easedProgress * (endX - startX)
        let y = bounds.height * 0.53 + sin(CGFloat(progress) * .pi * 5) * 9

        context.saveGState()
        context.translateBy(x: x, y: y)
        drawSparkles(in: context, progress: CGFloat(progress))
        drawPlane(in: context)
        drawBadge()
        drawMessage()
        context.restoreGState()
    }

    private func drawPlane(in context: CGContext) {
        let pink = NSColor(calibratedRed: 1.0, green: 0.42, blue: 0.72, alpha: 1.0)
        let hotPink = NSColor(calibratedRed: 1.0, green: 0.20, blue: 0.58, alpha: 1.0)
        let lightPink = NSColor(calibratedRed: 1.0, green: 0.76, blue: 0.88, alpha: 1.0)
        let cream = NSColor(calibratedRed: 1.0, green: 0.96, blue: 0.82, alpha: 1.0)
        let white = NSColor.white.withAlphaComponent(0.94)

        context.setShadow(offset: CGSize(width: 0, height: -4), blur: 14, color: NSColor.black.withAlphaComponent(0.24).cgColor)

        // 机身：粉色圆润主体。
        let body = NSBezierPath(roundedRect: NSRect(x: 58, y: -20, width: 208, height: 40), xRadius: 20, yRadius: 20)
        pink.setFill()
        body.fill()

        // 机头。
        let nose = NSBezierPath()
        nose.move(to: NSPoint(x: 252, y: -20))
        nose.curve(to: NSPoint(x: 318, y: 0), controlPoint1: NSPoint(x: 285, y: -20), controlPoint2: NSPoint(x: 305, y: -9))
        nose.curve(to: NSPoint(x: 252, y: 20), controlPoint1: NSPoint(x: 305, y: 9), controlPoint2: NSPoint(x: 285, y: 20))
        nose.close()
        hotPink.setFill()
        nose.fill()

        // 上机翼。
        let wing = NSBezierPath()
        wing.move(to: NSPoint(x: 130, y: 2))
        wing.line(to: NSPoint(x: 210, y: 78))
        wing.curve(to: NSPoint(x: 234, y: 64), controlPoint1: NSPoint(x: 224, y: 82), controlPoint2: NSPoint(x: 237, y: 76))
        wing.line(to: NSPoint(x: 190, y: 5))
        wing.close()
        lightPink.setFill()
        wing.fill()

        // 下机翼。
        let lowerWing = NSBezierPath()
        lowerWing.move(to: NSPoint(x: 136, y: -5))
        lowerWing.line(to: NSPoint(x: 205, y: -60))
        lowerWing.curve(to: NSPoint(x: 230, y: -47), controlPoint1: NSPoint(x: 219, y: -64), controlPoint2: NSPoint(x: 233, y: -58))
        lowerWing.line(to: NSPoint(x: 190, y: -8))
        lowerWing.close()
        lightPink.withAlphaComponent(0.95).setFill()
        lowerWing.fill()

        // 尾翼。
        let tail = NSBezierPath()
        tail.move(to: NSPoint(x: 62, y: 5))
        tail.line(to: NSPoint(x: 10, y: 52))
        tail.curve(to: NSPoint(x: 42, y: 13), controlPoint1: NSPoint(x: 28, y: 53), controlPoint2: NSPoint(x: 44, y: 38))
        tail.close()
        hotPink.setFill()
        tail.fill()

        // 横幅底色，衬托 emoji。
        let banner = NSBezierPath(roundedRect: NSRect(x: 95, y: -10, width: 126, height: 20), xRadius: 10, yRadius: 10)
        cream.setFill()
        banner.fill()

        // 舷窗。
        for index in 0..<3 {
            let window = NSBezierPath(ovalIn: NSRect(x: 226 + index * 24, y: -7, width: 14, height: 14))
            white.setFill()
            window.fill()
        }
    }

    private func drawBadge() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 32),
            .foregroundColor: NSColor.white
        ]
        config.emoji.draw(in: NSRect(x: 88, y: -17, width: 42, height: 42), withAttributes: attributes)
    }

    private func drawMessage() {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 28),
            .foregroundColor: NSColor(calibratedRed: 0.82, green: 0.04, blue: 0.42, alpha: 1.0),
            .paragraphStyle: paragraph,
            .strokeColor: NSColor.white,
            .strokeWidth: -3.0
        ]
        // 文案可能较长（日程标题），拉宽一点并居中截断。
        config.message.draw(in: NSRect(x: -60, y: -62, width: 520, height: 42), withAttributes: attributes)
    }

    private func drawSparkles(in context: CGContext, progress: CGFloat) {
        let sparkleColor = NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.90, alpha: 0.78)
        sparkleColor.setFill()
        for index in 0..<10 {
            let offset = CGFloat(index) * 27
            let alphaWave = 0.42 + 0.36 * sin(progress * 20 + CGFloat(index))
            context.setAlpha(alphaWave)
            let size = CGFloat(6 + index % 3)
            let rect = NSRect(x: -offset - 24, y: CGFloat(index % 4) * 13 - 25, width: size, height: size)
            NSBezierPath(ovalIn: rect).fill()
        }
        context.setAlpha(1)
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
        let windowHeight: CGFloat = 230
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
