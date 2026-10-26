// Tide: a focus timer and lofi radio in the menu bar.
// Clicking the menu bar time opens a panel (panel.html); Open Log and Settings open the dashboard (dashboard.html).
// The study log and the timer and radio settings are saved in ~/Library/Application Support/Tide.
// To keep the log somewhere else, choose a folder in Settings, or:
//   defaults write local.focusmn.app LogFolder ~/path/to/folder
import Cocoa
import WebKit
import UserNotifications
import ServiceManagement
import Carbon

// A borderless window that can still take typing (for the session topic).
final class PanelWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// WebKit only follows the mouse in the active app's windows. The Island shows over other apps, so this view
// watches the mouse itself and tells the page where it is; the page lights up the button under it.
final class HoverForwardingView: NSView {
    weak var target: WKWebView?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect], owner: self))
    }
    private func send(_ event: NSEvent?) {
        guard let target else { return }
        var x = -1.0, y = -1.0
        if let event {
            let p = convert(event.locationInWindow, from: nil)
            x = p.x; y = bounds.height - p.y
        }
        target.evaluateJavaScript("window.hoverAt && hoverAt(\(x), \(y))")
    }
    override func mouseMoved(with event: NSEvent) { send(event) }
    override func mouseEntered(with event: NSEvent) { send(event) }
    override func mouseExited(with event: NSEvent) { send(nil) }
}

// A web view that acts on the first click even while another app is active, so the Island's buttons need one click.
final class FirstClickWebView: WKWebView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, WKScriptMessageHandler, UNUserNotificationCenterDelegate {
    var statusItem: NSStatusItem!
    var panel: PanelWindow!
    var web: WKWebView!
    var dashWindow: NSWindow?
    var dashWeb: WKWebView?
    var rightMenu = NSMenu()
    var updateItem: NSMenuItem?
    var updateURL: URL?
    var panelHeight: CGFloat = 520
    var lastHidden = Date.distantPast
    var hotKeyRef: EventHotKeyRef?
    var island: PanelWindow!
    var islandWeb: WKWebView!
    var islandHeight: CGFloat = 165
    var currentNotice: [String: Any]?
    var lastNoticeId = -1
    let islandWidth: CGFloat = 360
    var activity: NSObjectProtocol?
    let panelWidth: CGFloat = 320
    let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    lazy var stateDir = supportDir.appendingPathComponent("Tide")
    var logDir: URL {
        guard let folder = UserDefaults.standard.string(forKey: "LogFolder"), !folder.isEmpty else { return stateDir }
        return URL(fileURLWithPath: (folder as NSString).expandingTildeInPath, isDirectory: true)
    }
    var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0" }

    func fileURL(for key: String) -> URL {
        key == "studyradio.logs"
            ? logDir.appendingPathComponent("Study Log.json")
            : stateDir.appendingPathComponent(key + ".json")
    }

    // Earlier builds (called Focus MN, Mono FM and Study Radio) kept their data in a folder of that name; copy it over once.
    // The old folder is left in place as a backup.
    func moveOldSettings() {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: stateDir.path) else { return }
        for name in ["Focus MN", "Mono FM", "Study Radio"] {
            let old = supportDir.appendingPathComponent(name)
            if fm.fileExists(atPath: old.path) { try? fm.copyItem(at: old, to: stateDir); return }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpNotifications()
        moveOldSettings()
        try? FileManager.default.createDirectory(at: stateDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        buildMainMenu()
        applyTheme()
        // The timer runs in the panel's page, which is hidden most of the time: keep macOS from napping the app.
        activity = ProcessInfo.processInfo.beginActivity(options: .userInitiatedAllowingIdleSystemSleep, reason: "Focus timer")
        buildPanel()
        buildIsland()
        buildStatusItem()
        registerHotKey()
        // A backstop for the page's own clock: tick every second even if WebKit slows the hidden page down.
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.web.evaluateJavaScript("window.tick && tick()")
        }
        // Bedtime: every 30 seconds, note when the Mac is in use at night and remind after bedtime.
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in self?.bedtimeCheck() }
        // Unlocking the Mac after bedtime brings the reminder straight back.
        DistributedNotificationCenter.default().addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            self?.lastBedNudge = .distantPast
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self?.bedtimeCheck() }
        }
        // Look for a newer release now and once a day.
        checkForUpdate()
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in self?.checkForUpdate() }
        // Testing: `open -a "Tide" --args --test-island done` (or break, topic) shows that question in the Island.
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--test-island") {
            let kind = i + 1 < args.count ? args[i + 1] : "done"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.web.evaluateJavaScript("testIsland(\(self?.json(kind) ?? "\"done\""))")
            }
        }
    }

    // MARK: pages

    // Both pages get the saved data before their script runs; the dashboard also gets its settings and first tab.
    func pageConfig(extra: String = "") -> WKWebViewConfiguration {
        var saved: [String: String] = [:]
        for key in ["studyradio.logs", "studyradio.state", "tide.game", "tide.nights"] {
            if let text = try? String(contentsOf: fileURL(for: key), encoding: .utf8) { saved[key] = text }
        }
        let json = String(data: try! JSONSerialization.data(withJSONObject: saved), encoding: .utf8)!
        let content = WKUserContentController()
        content.add(self, name: "native")
        content.addUserScript(WKUserScript(source: "window.__NATIVE = true; window.__STORE = \(json); window.__THEME = \(self.json(theme)); window.__USER = \(self.json(firstName)); \(extra)",
                                           injectionTime: .atDocumentStart, forMainFrameOnly: true))
        content.addUserScript(WKUserScript(source: fontScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        content.addUserScript(WKUserScript(source: gameScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let config = WKWebViewConfiguration()
        config.userContentController = content
        config.mediaTypesRequiringUserActionForPlayback = []
        // Keep pages running while their window is hidden, so the timer and radio don't stop when the panel closes.
        if #available(macOS 14.0, *) { config.preferences.inactiveSchedulingPolicy = .none }
        return config
    }

    // Theme: "system" follows the Mac; "light" or "dark" fixes every window of the app.
    var theme: String { UserDefaults.standard.string(forKey: "theme") ?? "system" }
    func applyTheme() {
        NSApp.appearance = theme == "light" ? NSAppearance(named: .aqua) : theme == "dark" ? NSAppearance(named: .darkAqua) : nil
    }

    // Pages are loaded from a web address, so they can't read the bundled font file: it goes in as data instead.
    // The game and bedtime rules (game.js), shared by the panel and the dashboard.
    lazy var gameScript: String = {
        guard let url = Bundle.main.url(forResource: "game", withExtension: "js") else { return "" }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }()
    // For the greeting: the first word of the Mac account's full name.
    var firstName: String { (NSFullUserName().split(separator: " ").first.map(String.init) ?? "").capitalized }

    lazy var fontScript: String = {
        guard let url = Bundle.main.url(forResource: "Manrope", withExtension: "ttf"), let data = try? Data(contentsOf: url) else { return "" }
        return "document.fonts.add(new FontFace('Manrope', 'url(data:font/ttf;base64,\(data.base64EncodedString()))', {weight: '200 800'}));"
    }()

    func loadPage(_ name: String, into view: WKWebView) {
        let html = Bundle.main.url(forResource: name, withExtension: "html")!
        // Served from a web address rather than a file, because YouTube's player refuses to run inside file pages.
        let page = (try? String(contentsOf: html, encoding: .utf8)) ?? ""
        view.loadHTMLString(page, baseURL: URL(string: "https://localhost/"))
    }

    func json(_ object: Any) -> String {
        String(data: (try? JSONSerialization.data(withJSONObject: object, options: .fragmentsAllowed)) ?? Data("null".utf8), encoding: .utf8) ?? "null"
    }

    // MARK: the panel

    // A frosted, rounded window that drops down from the menu bar time. It stays alive while hidden,
    // so the timer keeps ticking and the radio keeps playing.
    func buildPanel() {
        panel = PanelWindow(contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
                            styleMask: [.borderless], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isReleasedWhenClosed = false
        panel.delegate = self

        let blur = NSVisualEffectView(frame: panel.contentView!.bounds)
        blur.autoresizingMask = [.width, .height]
        blur.material = .popover
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.maskImage = roundedMask(20)
        panel.contentView = blur

        web = WKWebView(frame: blur.bounds, configuration: pageConfig())
        web.autoresizingMask = [.width, .height]
        web.setValue(false, forKey: "drawsBackground")
        web.wantsLayer = true
        web.layer?.cornerRadius = 20
        web.layer?.masksToBounds = true
        blur.addSubview(web)
        loadPage("panel", into: web)
        // Off screen until first opened; the page runs from the start so the timer and radio work.
        panel.setFrameOrigin(NSPoint(x: -10000, y: -10000))
        panel.orderFront(nil)
        panel.orderOut(nil)
    }

    // A rounded-rectangle mask that stretches to any size.
    func roundedMask(_ r: CGFloat) -> NSImage {
        let edge = 2 * r + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.set()
            NSBezierPath(roundedRect: rect, xRadius: r, yRadius: r).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: r, left: r, bottom: r, right: r)
        image.resizingMode = .stretch
        return image
    }

    // Under the menu bar time, kept on screen. While open it stays put when its height changes,
    // even though the menu bar item gets wider once the time shows.
    func placePanel(recenter: Bool = true) {
        guard let button = statusItem.button, let bw = button.window else { return }
        let b = bw.convertToScreen(button.convert(button.bounds, to: nil))
        var x = recenter ? b.midX - panelWidth / 2 : panel.frame.minX
        if let visible = (bw.screen ?? NSScreen.main)?.visibleFrame {
            x = min(max(x, visible.minX + 8), visible.maxX - panelWidth - 8)
        }
        let top = recenter ? b.minY - 6 : panel.frame.maxY
        panel.setFrame(NSRect(x: x, y: top - panelHeight, width: panelWidth, height: panelHeight), display: true)
    }

    func showPanel() {
        if !panel.isVisible { placePanel() }
        island.orderOut(nil)
        web.evaluateJavaScript("panelVisible(true)")
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        statusItem.button?.highlight(true)
    }

    // Closing the panel hands any unanswered question to the top island.
    func hidePanel() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        lastHidden = Date()
        statusItem.button?.highlight(false)
        web.evaluateJavaScript("panelVisible(false)")
    }

    // MARK: the Island

    // The Island: a black, rounded box hanging from the notch at the top centre of the screen, for a finished block or break while the panel
    // is closed. It stays until answered; its buttons are handled by the panel page through noticeAction().
    func buildIsland() {
        island = PanelWindow(contentRect: NSRect(x: 0, y: 0, width: islandWidth, height: islandHeight),
                             styleMask: [.borderless], backing: .buffered, defer: false)
        island.isOpaque = false
        island.backgroundColor = .clear
        island.hasShadow = true
        island.level = .popUpMenu
        island.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        island.isReleasedWhenClosed = false
        island.acceptsMouseMovedEvents = true
        let hover = HoverForwardingView(frame: island.contentView!.bounds)
        island.contentView = hover
        islandWeb = FirstClickWebView(frame: hover.bounds, configuration: pageConfig())
        islandWeb.autoresizingMask = [.width, .height]
        islandWeb.setValue(false, forKey: "drawsBackground")
        hover.addSubview(islandWeb)
        hover.target = islandWeb
        loadPage("island", into: islandWeb)
    }

    func placeIsland() {
        guard let screen = NSScreen.main else { return }
        let f = screen.frame
        island.setFrame(NSRect(x: f.midX - islandWidth / 2, y: f.maxY - islandHeight, width: islandWidth, height: islandHeight), display: true)
    }

    func showNotice(_ notice: [String: Any]?) {
        currentNotice = notice
        guard let notice else { island.orderOut(nil); return }
        if panel.isVisible { return }   // the panel shows it itself
        // Start the Island's text below the menu bar (and the notch, where there is one).
        if let screen = NSScreen.main {
            var inset = screen.frame.maxY - screen.visibleFrame.maxY
            if #available(macOS 12.0, *) { inset = max(inset, screen.safeAreaInsets.top) }
            islandWeb.evaluateJavaScript("setTopInset(\(Int(inset.rounded())))")
        }
        islandWeb.evaluateJavaScript("setNotice(\(json(notice)))")
        placeIsland()
        let id = notice["id"] as? Int ?? 0
        if id != lastNoticeId { lastNoticeId = id; NSSound(named: "Glass")?.play() }
        if notice["input"] as? Bool ?? false {
            NSApp.activate(ignoringOtherApps: true)
            island.makeKeyAndOrderFront(nil)
        } else {
            island.orderFrontRegardless()
        }
    }

    // Clicking anywhere else closes the panel, like a menu.
    func windowDidResignKey(_ notification: Notification) {
        if (notification.object as? NSWindow) === panel { hidePanel() }
    }

    @objc func togglePanel() {
        // A click on the menu bar time first takes focus from the panel, which hides it; don't reopen it straight away.
        if panel.isVisible { hidePanel(); return }
        if Date().timeIntervalSince(lastHidden) < 0.3 { return }
        showPanel()
    }

    // MARK: bedtime

    var lastBedNudge = Date.distantPast
    func readJSON(_ key: String) -> [String: Any] {
        guard let data = try? Data(contentsOf: fileURL(for: key)),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return [:] }
        return object
    }
    func minutes(_ text: Any?, _ fallback: Int) -> Int {
        let parts = (text as? String ?? "").split(separator: ":").compactMap { Int($0) }
        return parts.count == 2 ? parts[0] * 60 + parts[1] : fallback
    }
    // A night runs until 5 AM. While the Mac is in use from 6 PM, the latest time is kept for that night
    // (the dashboard's Lights out card). After bedtime, the Island reminds every 5 minutes while you keep using it.
    func bedtimeCheck() {
        let game = readJSON("tide.game"), now = Date(), cal = Calendar.current
        let m = cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now)
        let night = m < 300 ? now.addingTimeInterval(-86400) : now
        let key = String(format: "%04d-%02d-%02d", cal.component(.year, from: night), cal.component(.month, from: night), cal.component(.day, from: night))
        let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
        let nightOff = (game["nightOff"] as? String) == key
        if idle < 60, !nightOff, m >= 18 * 60 || m < 300 {
            let value = m < 300 ? m + 1440 : m
            var nights = readJSON("tide.nights")
            if (nights[key] as? Int ?? -1) < value {
                nights[key] = value
                let text = json(nights)
                try? text.write(to: fileURL(for: "tide.nights"), atomically: true, encoding: .utf8)
                for view in [web, dashWeb] { view?.evaluateJavaScript("window.__syncNights && __syncNights(\(text))") }
            }
        }
        // The first use of the Mac in the morning: the panel shows last night's report (once a day).
        if idle < 60, m >= 300, m < 12 * 60 { web.evaluateJavaScript("window.morningReport && morningReport()") }
        guard game["bedOn"] as? Bool ?? true, !nightOff else { return }
        let bed = minutes(game["bedAt"], 22 * 60)
        guard m >= bed || m < 300, idle < 120, now.timeIntervalSince(lastBedNudge) >= 290 else { return }
        web.evaluateJavaScript("window.bedtimeNudge && bedtimeNudge()") { [weak self] result, _ in
            if result as? Bool == true { self?.lastBedNudge = Date() }
        }
    }

    // Locks the screen like Control-Command-Q. Falls back to sleeping the display, which locks if a password is required.
    func lockScreen() {
        if let login = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_NOW),
           let lock = dlsym(login, "SACLockScreenImmediate") {
            typealias Lock = @convention(c) () -> Int32
            _ = unsafeBitCast(lock, to: Lock.self)()
            return
        }
        let sleep = Process()
        sleep.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        sleep.arguments = ["displaysleepnow"]
        try? sleep.run()
    }

    // MARK: messages from the pages

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        if message.webView === islandWeb {
            if type == "noticeAction" {
                web.evaluateJavaScript("noticeAction(\(json(body["id"] ?? "")), \(json(body["topic"] ?? "")))")
            } else if type == "resize", let h = body["h"] as? Double, h.isFinite, h >= 60, h <= 600 {
                islandHeight = CGFloat(h)
                if island.isVisible { placeIsland() }
            }
            return
        }
        let fromDash = dashWeb != nil && message.webView === dashWeb
        switch type {
        case "store":
            if let key = body["key"] as? String, let value = body["value"] as? String {
                if fromDash && key != "studyradio.logs" && key != "tide.game" { return }
                try? value.write(to: fileURL(for: key), atomically: true, encoding: .utf8)
                // Keep the other page's copy of the log and the game settings in step.
                if key == "studyradio.logs" {
                    (fromDash ? web : dashWeb)?.evaluateJavaScript("window.__syncLogs && __syncLogs(\(value))")
                } else if key == "tide.game" {
                    (fromDash ? web : dashWeb)?.evaluateJavaScript("window.__syncGame && __syncGame(\(value))")
                }
            }
        case "resize":
            if !fromDash, let h = body["h"] as? Double, h.isFinite, h >= 200, h <= 1200 {
                panelHeight = CGFloat(h)
                if panel.isVisible { placePanel(recenter: false) } else { panel.setContentSize(NSSize(width: panelWidth, height: panelHeight)) }
            }
        case "clock":
            // Running timer next to the menu bar icon; empty when no session is going.
            let text = body["text"] as? String ?? ""
            statusItem.button?.title = text.isEmpty ? "" : " " + text
        case "notice":
            if !fromDash { showNotice(body["notice"] as? [String: Any]) }
        case "showPanel":
            if !fromDash { showPanel() }
        case "hidePanel":
            hidePanel()
        case "nudge":
            if !fromDash {
                // Replace an earlier nudge instead of piling them up.
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["nudge"])
                let content = UNMutableNotificationContent()
                content.title = body["title"] as? String ?? "Start a session?"
                content.body = body["body"] as? String ?? ""
                content.categoryIdentifier = "NUDGE"
                content.sound = .default
                UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "nudge", content: content, trigger: nil))
            }
        case "notify":
            notify(title: body["title"] as? String ?? "Tide", body: body["body"] as? String ?? "")
            if body["show"] as? Bool ?? false { showPanel() }
        case "resolve":
            if let i = body["i"] as? Int, let channel = body["ch"] as? String, let match = body["match"] as? [String] {
                findLiveStream(channel: channel, match: match) { [weak self] id in
                    guard let id else { return }
                    self?.web.evaluateJavaScript("ytResolved(\(i), '\(id)')")
                }
            }
        case "openDashboard":
            openDashboard(tab: body["tab"] as? String ?? "stats")
        case "theme":
            if let value = body["value"] as? String, ["system", "light", "dark"].contains(value) {
                UserDefaults.standard.set(value, forKey: "theme")
                applyTheme()
            }
        case "lockScreen":
            lockScreen()
        case "quit":
            NSApp.terminate(nil)
        case "copy":
            if let text = body["text"] as? String {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
        case "csv":
            if let text = body["text"] as? String {
                let url = logDir.appendingPathComponent("Study Log.csv")
                try? text.write(to: url, atomically: true, encoding: .utf8)
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        case "setLaunchAtLogin":
            setLaunchAtLogin(body["on"] as? Bool ?? false)
        case "chooseLogFolder":
            chooseLogFolder()
        case "revealLogFolder":
            NSWorkspace.shared.activateFileViewerSelecting([fileURL(for: "studyradio.logs")])
        case "checkUpdates":
            checkForUpdate(manual: true)
        default:
            break
        }
    }

    // MARK: the dashboard

    func settingsJSON() -> String {
        json(["launchAtLogin": SMAppService.mainApp.status == .enabled,
              "logFolder": (logDir.path as NSString).abbreviatingWithTildeInPath,
              "version": version])
    }

    @objc func openDashboard(tab: String = "stats") {
        hidePanel()
        if let window = dashWindow, let view = dashWeb {
            if let text = try? String(contentsOf: fileURL(for: "studyradio.logs"), encoding: .utf8) {
                view.evaluateJavaScript("window.__syncLogs && __syncLogs(\(text))")
            }
            view.evaluateJavaScript("settingsChanged(\(settingsJSON())); showTab(\(json(tab)))")
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 760),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = "Tide"
        // The title bar takes the page's colour and stays draggable.
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(srgbRed: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0, alpha: 1)   // --bg, dark
                : NSColor(srgbRed: 0xea / 255.0, green: 0xee / 255.0, blue: 0xf6 / 255.0, alpha: 1)   // --bg, light
        }
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 640, height: 520)
        let view = WKWebView(frame: window.contentView!.bounds,
                             configuration: pageConfig(extra: "window.__SETTINGS = \(settingsJSON()); window.__TAB = \(json(tab));"))
        view.autoresizingMask = [.width, .height]
        view.setValue(false, forKey: "drawsBackground")
        window.contentView!.addSubview(view)
        loadPage("dashboard", into: view)
        dashWeb = view
        dashWindow = window
        if !window.setFrameUsingName("TideDashboard") { window.center() }
        window.setFrameAutosaveName("TideDashboard")
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    @objc func openLog() { openDashboard(tab: "stats") }
    @objc func openSettings() { openDashboard(tab: "settings") }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            notify(title: "Couldn't change Open at Login", body: error.localizedDescription)
        }
        dashWeb?.evaluateJavaScript("settingsChanged(\(settingsJSON()))")
    }

    // A new log folder gets a copy of the current log if it doesn't have one yet.
    func chooseLogFolder() {
        let open = NSOpenPanel()
        open.canChooseDirectories = true
        open.canChooseFiles = false
        open.canCreateDirectories = true
        open.prompt = "Use This Folder"
        open.message = "Choose where Tide keeps Study Log.json"
        NSApp.activate(ignoringOtherApps: true)
        guard open.runModal() == .OK, let folder = open.url else { return }
        let current = fileURL(for: "studyradio.logs")
        let target = folder.appendingPathComponent("Study Log.json")
        if !FileManager.default.fileExists(atPath: target.path), let data = try? Data(contentsOf: current) {
            try? data.write(to: target)
        }
        UserDefaults.standard.set(folder.path, forKey: "LogFolder")
        if let text = try? String(contentsOf: target, encoding: .utf8) {
            web.evaluateJavaScript("window.__syncLogs && __syncLogs(\(text))")
            dashWeb?.evaluateJavaScript("window.__syncLogs && __syncLogs(\(text))")
        }
        dashWeb?.evaluateJavaScript("settingsChanged(\(settingsJSON()))")
    }

    // MARK: menu bar

    // Click opens the panel; right-click (or Control-click) shows a small menu.
    func buildStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Tide")?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 16, weight: .medium))
        statusItem.button?.imagePosition = .imageLeft
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        rightMenu.addItem(NSMenuItem(title: "Open Tide", action: #selector(togglePanel), keyEquivalent: ""))
        rightMenu.addItem(NSMenuItem(title: "Open Log", action: #selector(openLog), keyEquivalent: ""))
        rightMenu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        rightMenu.addItem(.separator())
        rightMenu.addItem(NSMenuItem(title: "Check for Updates…", action: #selector(checkForUpdatesNow), keyEquivalent: ""))
        rightMenu.items.forEach { $0.target = self }
        rightMenu.addItem(NSMenuItem(title: "Quit Tide", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc func statusClicked() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            hidePanel()
            statusItem.menu = rightMenu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            togglePanel()
        }
    }

    // An Edit menu so copy and paste work in the topic field.
    func buildMainMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem(), editItem = NSMenuItem()
        main.addItem(appItem)
        main.addItem(editItem)
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Quit Tide", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appItem.submenu = appMenu
        let edit = NSMenu(title: "Edit")
        edit.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        edit.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        edit.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        edit.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        edit.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editItem.submenu = edit
        NSApp.mainMenu = main
    }

    // Control-Option-Space starts or pauses the timer from any app. (Option-Command-Space is Finder's search.)
    func registerHotKey() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return noErr }
            let me = Unmanaged<AppDelegate>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async { me.web.evaluateJavaScript("start()") }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
        let id = EventHotKeyID(signature: OSType(0x464D4E31), id: 1)
        RegisterEventHotKey(UInt32(kVK_Space), UInt32(controlKey | optionKey), id, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    // MARK: notifications

    func setUpNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        // The idle nudge gets a "Let's start" button (shown when you hover over the notification).
        let start = UNNotificationAction(identifier: "START", title: "Let\u{2019}s start", options: [])
        center.setNotificationCategories([UNNotificationCategory(identifier: "NUDGE", actions: [start], intentIdentifiers: [])])
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func notify(title: String, body: String, url: URL? = nil, category: String? = nil, sound: Bool = false) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let url { content.userInfo = ["url": url.absoluteString] }
        if let category { content.categoryIdentifier = category }
        if sound { content.sound = .default }
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    // Show notification banners even while Tide is the active app.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list])
    }

    // Clicking an update notice opens the download page; any other opens the panel.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == "START" {
            web.evaluateJavaScript("startCountUp()")   // starts counting up without opening the panel
        } else if let link = response.notification.request.content.userInfo["url"] as? String, let url = URL(string: link) {
            NSWorkspace.shared.open(url)
        } else {
            showPanel()
        }
        completionHandler()
    }

    // Reads a channel's Live tab and returns the live stream whose title contains every match phrase.
    // YouTube lists each stream as a "lockupViewModel"; live ones show a "watching" count.
    func findLiveStream(channel: String, match: [String], done: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://www.youtube.com/@\(channel)/streams") else { return done(nil) }
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en", forHTTPHeaderField: "Accept-Language")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            var found: String?
            if let data, let page = String(data: data, encoding: .utf8),
               let start = page.range(of: "var ytInitialData = "),
               let end = page.range(of: ";</script>", range: start.upperBound..<page.endIndex),
               let json = try? JSONSerialization.jsonObject(with: Data(page[start.upperBound..<end.lowerBound].utf8)) {
                let wanted = match.map { $0.lowercased() }
                func walk(_ node: Any) {
                    if found != nil { return }
                    if let dict = node as? [String: Any] {
                        if let lockup = dict["lockupViewModel"] as? [String: Any], let id = lockup["contentId"] as? String,
                           let meta = (lockup["metadata"] as? [String: Any])?["lockupMetadataViewModel"] as? [String: Any],
                           let title = ((meta["title"] as? [String: Any])?["content"] as? String)?.lowercased(),
                           let raw = try? JSONSerialization.data(withJSONObject: lockup),
                           String(decoding: raw, as: UTF8.self).contains(" watching"),
                           wanted.allSatisfy({ title.contains($0) }) {
                            found = id
                            return
                        }
                        dict.values.forEach(walk)
                    } else if let list = node as? [Any] {
                        list.forEach(walk)
                    }
                }
                walk(json)
            }
            DispatchQueue.main.async { done(found) }
        }.resume()
    }

    // Updates: ask GitHub for the latest release and compare it with this build's version.
    // Nothing is downloaded or installed; the menu and a notification point to the release page.
    func checkForUpdate(manual: Bool = false) {
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/manojitnath/tide/releases/latest")!, timeoutInterval: 20)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            let release = data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            DispatchQueue.main.async { self.handleRelease(release, manual: manual) }
        }.resume()
    }

    func handleRelease(_ release: [String: Any]?, manual: Bool) {
        let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        guard let tag = release?["tag_name"] as? String, let page = (release?["html_url"] as? String).flatMap(URL.init(string:)) else {
            if manual { notify(title: "Couldn't check for updates", body: "GitHub didn't answer. Try again later.") }
            return
        }
        let latest = tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        guard isVersion(latest, newerThan: current) else {
            if manual { notify(title: "Tide is up to date", body: "You have the latest version, \(current).") }
            return
        }
        updateURL = page
        if updateItem == nil {
            let menu = rightMenu
            let item = NSMenuItem(title: "", action: #selector(openUpdate), keyEquivalent: "")
            item.target = self
            menu.insertItem(item, at: 0)
            menu.insertItem(.separator(), at: 1)
            updateItem = item
        }
        updateItem?.title = "Update Available: \(latest)…"
        // Each new version is announced once; a manual check always answers.
        if manual || UserDefaults.standard.string(forKey: "NotifiedVersion") != latest {
            UserDefaults.standard.set(latest, forKey: "NotifiedVersion")
            notify(title: "Tide \(latest) is out", body: "Click to download it. Your log and settings are kept.", url: page)
        }
    }

    // Compares dotted versions number by number, so 1.10 is newer than 1.9.
    func isVersion(_ a: String, newerThan b: String) -> Bool {
        let x = a.split(separator: ".").map { Int($0) ?? 0 }, y = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(x.count, y.count) {
            let p = i < x.count ? x[i] : 0, q = i < y.count ? y[i] : 0
            if p != q { return p > q }
        }
        return false
    }

    @objc func openUpdate() { if let updateURL { NSWorkspace.shared.open(updateURL) } }
    @objc func checkForUpdatesNow() { checkForUpdate(manual: true) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
