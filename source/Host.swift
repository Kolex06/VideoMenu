import AppKit
import Foundation
import Darwin

let dry = CommandLine.arguments.contains("--dry-run")
let supportedBrowsers: Set<String> = ["com.brave.Browser", "com.google.Chrome", "org.chromium.Chromium", "com.microsoft.edgemac", "com.vivaldi.Vivaldi", "com.operasoftware.Opera"]
let testBrave = dry && CommandLine.arguments.contains("--test-brave")
let ownerBundle = testBrave ? "com.brave.Browser" : NSRunningApplication(processIdentifier: getppid())?.bundleIdentifier

let idsURL = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Resources/extension-id.txt")
let allowedOrigins = try String(contentsOf: idsURL, encoding: .utf8).split(whereSeparator: \.isNewline).map { "chrome-extension://\($0)/" }
if !dry && !CommandLine.arguments.contains(where: { allowedOrigins.contains($0) }) { exit(2) }
signal(SIGPIPE, SIG_IGN)
// One browser/profile owns the global preference at a time.
let lockPath = NSTemporaryDirectory() + "local.videomenu.\(getuid())\(dry ? ".test" : "").lock"
let lockFD = open(lockPath, O_CREAT | O_RDWR | O_NOFOLLOW, S_IRUSR | S_IWUSR)
guard lockFD >= 0, flock(lockFD, LOCK_EX | LOCK_NB) == 0 else { exit(3) }
let key = "AppleMenuBarVisibleInFullscreen" as CFString
let domain = kCFPreferencesAnyApplication
let user = kCFPreferencesCurrentUser
let host = kCFPreferencesAnyHost
let original = CFPreferencesCopyValue(key, domain, user, host)
var lastWritten: Bool?
var enabled = false
var requestedHide = false
var lastMessage = Date.distantPast
var touched = false

func postPreferenceChange() {
    DistributedNotificationCenter.default().postNotificationName(Notification.Name("AppleInterfaceFullScreenMenuBarVisibilityChangedNotification"), object: nil, userInfo: nil, deliverImmediately: true)
}
func restore() {
    guard touched else { return }
    if !dry {
        CFPreferencesSetValue(key, original, domain, user, host)
        CFPreferencesSynchronize(domain, user, host)
        postPreferenceChange()
    }
    touched = false; lastWritten = nil
}
func apply() -> Bool {
    guard enabled else { restore(); return false }
    let front = testBrave ? "com.brave.Browser" : NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    let hide = requestedHide && ownerBundle != nil && supportedBrowsers.contains(ownerBundle!) && front == ownerBundle && Date().timeIntervalSince(lastMessage) < 6
    let visible = !hide
    if lastWritten != visible {
        if !dry {
            CFPreferencesSetValue(key, visible as CFBoolean, domain, user, host)
            guard CFPreferencesSynchronize(domain, user, host) else { restore(); return false }
            postPreferenceChange()
        }
        touched = true; lastWritten = visible
    }
    return hide
}
func send(_ value: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: value) else { return }
    var count = UInt32(data.count).littleEndian
    FileHandle.standardOutput.write(Data(bytes: &count, count: 4))
    FileHandle.standardOutput.write(data)
}
func exact(_ count: Int) -> Data? {
    var result = Data()
    while result.count < count {
        guard let chunk = try? FileHandle.standardInput.read(upToCount: count-result.count), !chunk.isEmpty else { return nil }
        result.append(chunk)
    }
    return result
}
let timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in _ = apply() }
let notifications = NSWorkspace.shared.notificationCenter
let observer = notifications.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { _ in _ = apply() }
let sleepObserver = notifications.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { _ in requestedHide = false; _ = apply() }
var signals: [DispatchSourceSignal] = []
for sig in [SIGTERM, SIGINT, SIGHUP] {
    signal(sig, SIG_IGN)
    let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
    source.setEventHandler { restore(); exit(0) }
    source.resume(); signals.append(source)
}
DispatchQueue.global().async {
    while let header = exact(4) {
        let count = header.enumerated().reduce(UInt32(0)) { $0 | UInt32($1.element) << (8 * $1.offset) }
        guard count > 0, count <= 4096, let data = exact(Int(count)),
              let message = try? JSONSerialization.jsonObject(with: data) as? [String:Any],
              let en = message["enabled"] as? Bool, let hide = message["hide"] as? Bool else { break }
        DispatchQueue.main.async {
            enabled = en; requestedHide = hide; lastMessage = Date()
            send(["hidden":apply(), "enabled":enabled, "dryRun":dry, "browser":ownerBundle ?? "unknown"])
        }
    }
    DispatchQueue.main.async { restore(); exit(0) }
}
RunLoop.main.run()
