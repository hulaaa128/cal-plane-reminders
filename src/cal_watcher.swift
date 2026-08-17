import EventKit
import Foundation

// 日历轮询守护：每 60 秒扫描全部日历，
// 对「距开始 ≤ 提前分钟数 且 > 0」的非全天日程，调 plane 弹一次粉色飞机。
// 用 fired 集合去重，同一日程（事件ID+开始时刻）只弹一次。

let LEAD_MINUTES: Double = 5.0        // 提前几分钟提醒
let POLL_INTERVAL: TimeInterval = 60  // 轮询间隔（秒）
let LOOKAHEAD_MINUTES: Double = 15    // 每轮向前查多少分钟内的日程

let installDir = ("~/.local/share/cal-plane-reminders" as NSString).expandingTildeInPath
let planePath = "\(installDir)/plane"
let firedPath = "\(installDir)/fired.txt"

let store = EKEventStore()

func log(_ msg: String) {
    let ts = ISO8601DateFormatter().string(from: Date())
    print("[\(ts)] \(msg)")
    // 立即刷新，方便 launchd 日志实时可见。
    fflush(stdout)
}

// 已弹过的事件标识（事件ID + 开始时间戳），进程内 + 落盘双保险。
var fired = Set<String>()

func loadFired() {
    guard let content = try? String(contentsOfFile: firedPath, encoding: .utf8) else { return }
    for line in content.split(separator: "\n") {
        fired.insert(String(line))
    }
}

func persistFired(_ key: String) {
    fired.insert(key)
    if let handle = FileHandle(forWritingAtPath: firedPath) {
        handle.seekToEndOfFile()
        handle.write((key + "\n").data(using: .utf8)!)
        handle.closeFile()
    } else {
        try? (key + "\n").write(toFile: firedPath, atomically: true, encoding: .utf8)
    }
}

func firePlane(message: String, emoji: String) {
    let proc = Process()
    proc.executableURL = URL(fileURLWithPath: planePath)
    proc.arguments = [message, emoji]
    do {
        try proc.run()
        log("弹飞机：\(message)")
    } catch {
        log("弹飞机失败：\(error.localizedDescription)")
    }
}

func checkOnce() {
    let now = Date()
    let end = now.addingTimeInterval(LOOKAHEAD_MINUTES * 60)
    let calendars = store.calendars(for: .event)  // 全部日历
    let predicate = store.predicateForEvents(withStart: now, end: end, calendars: calendars)
    let events = store.events(matching: predicate)

    for event in events {
        if event.isAllDay { continue }                    // 忽略全天日程
        guard let start = event.startDate else { continue }
        let minutesToStart = start.timeIntervalSince(now) / 60.0
        // 距开始还有 0~LEAD_MINUTES 分钟才提醒（错过了或太远都不弹）。
        guard minutesToStart > 0, minutesToStart <= LEAD_MINUTES else { continue }

        let id = event.eventIdentifier ?? event.title ?? "unknown"
        let key = "\(id)@\(Int(start.timeIntervalSince1970))"
        if fired.contains(key) { continue }

        let title = event.title ?? "日程"
        firePlane(message: "\(Int(LEAD_MINUTES))分钟后：\(title)", emoji: "📅")
        persistFired(key)
    }
}

func startLoop() {
    loadFired()
    log("cal-watcher 启动，提前 \(Int(LEAD_MINUTES)) 分钟提醒，每 \(Int(POLL_INTERVAL)) 秒轮询一次。")
    checkOnce()  // 启动立即查一次
    Timer.scheduledTimer(withTimeInterval: POLL_INTERVAL, repeats: true) { _ in
        checkOnce()
    }
    // 注意：不在此处跑 RunLoop，由主流程统一驻留，避免 RunLoop 嵌套导致 Timer 不触发。
}

// 先确保有日历访问权限，再进入轮询循环。
// 无论走哪条分支，主线程只在最后跑一次 RunLoop，避免嵌套。
let status = EKEventStore.authorizationStatus(for: .event)
if status == .fullAccess {
    startLoop()
} else {
    log("请求日历访问权限……（当前状态 \(status.rawValue)）")
    store.requestFullAccessToEvents { granted, error in
        if granted {
            // 回调可能在非主线程执行；Timer 必须装到主 RunLoop 才会触发，
            // 故派回主队列启动轮询。
            DispatchQueue.main.async {
                log("已获授权。")
                startLoop()
            }
        } else {
            log("未获日历授权，无法读取日程。请到 系统设置→隐私与安全性→日历 手动开启。err=\(String(describing: error))")
            exit(1)
        }
    }
}

// 主线程统一驻留，Timer 才能持续触发。
RunLoop.main.run()
