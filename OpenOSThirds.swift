import Cocoa
import ApplicationServices

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = ThirdsController()

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: "pro.openos.thirds")
        if others.count > 1 { NSApp.terminate(nil); return }
        controller.start()
    }
}

struct Zone {
    let action: String
    let label: String
    let nx: CGFloat
    let ny: CGFloat
    let nw: CGFloat
    let nh: CGFloat

    var norm: NormRect {
        NormRect(nx: Double(nx), ny: Double(ny), nw: Double(nw), nh: Double(nh))
    }
}

struct ZoneLayout {
    let id: String
    let title: String
    let zones: [Zone]

    var labels: [String] { zones.map(\.label) }

    static let modeKey = "zoneMode"
    static let railKey = "showRail"
    static var catalog: [(id: String, title: String)] { SnapMath.catalog }

    static func mode() -> String {
        let raw = UserDefaults.standard.string(forKey: modeKey) ?? "auto"
        if catalog.contains(where: { $0.id == raw }) { return raw }
        return "auto"
    }

    static func setMode(_ mode: String) {
        UserDefaults.standard.set(mode, forKey: modeKey)
    }

    static func showRail() -> Bool {
        UserDefaults.standard.bool(forKey: railKey)
    }

    static func setShowRail(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: railKey)
    }

    static func make(mode: String, screenWidth: CGFloat) -> ZoneLayout {
        let spec = SnapMath.layout(mode: mode, screenWidth: Double(screenWidth))
        return ZoneLayout(
            id: spec.id,
            title: spec.title,
            zones: spec.zones.map {
                Zone(
                    action: $0.action,
                    label: $0.label,
                    nx: CGFloat($0.nx),
                    ny: CGFloat($0.ny),
                    nw: CGFloat($0.nw),
                    nh: CGFloat($0.nh)
                )
            }
        )
    }
}

enum StoredConfig {
    static let domain = "pro.openos.thirds"

    /// Older installs may have persisted Rectangle URL actions. Rewrite them to native ids.
    static func migrate() {
        var names = [domain]
        if let id = Bundle.main.bundleIdentifier, !names.contains(id) {
            names.append(id)
        }
        let defaults = UserDefaults.standard
        for name in names {
            guard let raw = defaults.persistentDomain(forName: name) else { continue }
            let (migrated, changed) = SnapMath.migrateValue(raw)
            guard changed, let dict = migrated as? [String: Any] else { continue }
            defaults.setPersistentDomain(dict, forName: name)
        }
    }
}

enum WindowSnapper {
    private static var didPrompt = false
    private static var didWarn = false

    static func prepare() {
        guard !didPrompt else { return }
        didPrompt = true
        let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    static func snap(norm: NormRect, screen: NSScreen, pid: pid_t?) {
        guard norm.nw > 0, norm.nh > 0 else { return }
        guard trustedOrWarn() else { return }
        guard let primary = NSScreen.screens.first else { return }
        let vis = screen.visibleFrame
        guard vis.width > 1, vis.height > 1 else { return }
        let cocoa = SnapMath.cocoaRect(
            norm,
            visibleX: Double(vis.minX),
            visibleY: Double(vis.minY),
            visibleW: Double(vis.width),
            visibleH: Double(vis.height)
        )
        let ax = SnapMath.axRect(cocoa, primaryMaxY: Double(primary.frame.maxY))
        guard let window = window(pid: pid) else {
            log("não encontrei janela para mover")
            return
        }
        let rect = CGRect(x: ax.x, y: ax.y, width: ax.w, height: ax.h)
        if !setFrame(window, rect) {
            log("a janela recusou o redimensionamento")
        }
    }

    private static func trustedOrWarn() -> Bool {
        if AXIsProcessTrusted() { return true }
        prepare()
        if AXIsProcessTrusted() { return true }
        guard !didWarn else { return false }
        didWarn = true
        log("sem permissão de Acessibilidade")
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Acessibilidade em falta"
        alert.informativeText = "O OpenOS Thirds move as janelas pela API de Acessibilidade. Ativa a app em Definições do Sistema → Privacidade e Segurança → Acessibilidade."
        alert.addButton(withTitle: "OK")
        alert.runModal()
        return false
    }

    private static func window(pid explicit: pid_t?) -> AXUIElement? {
        let me = pid_t(ProcessInfo.processInfo.processIdentifier)
        if let explicit, explicit != me, let found = focused(explicit) ?? firstWindow(explicit) {
            return found
        }
        if let front = NSWorkspace.shared.frontmostApplication?.processIdentifier,
           front != me, let found = focused(front) ?? firstWindow(front) {
            return found
        }
        if let foreign = topForeignPID(), let found = focused(foreign) ?? firstWindow(foreign) {
            return found
        }
        return nil
    }

    private static func focused(_ pid: pid_t) -> AXUIElement? {
        let app = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let value else { return nil }
        return element(value)
    }

    private static func firstWindow(_ pid: pid_t) -> AXUIElement? {
        let app = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
              let value else { return nil }
        if let list = value as? [AXUIElement] {
            return list.first
        }
        if let list = value as? NSArray {
            for case let item as AnyObject in list {
                if let window = element(item) { return window }
            }
        }
        return nil
    }

    private static func element(_ value: CFTypeRef) -> AXUIElement? {
        guard CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    private static func topForeignPID() -> pid_t? {
        let opts = CGWindowListOption.optionOnScreenOnly.union(.excludeDesktopElements)
        guard let info = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        let me = Int(ProcessInfo.processInfo.processIdentifier)
        for window in info {
            if (window[kCGWindowOwnerPID as String] as? Int) == me { continue }
            if (window[kCGWindowLayer as String] as? Int) != 0 { continue }
            guard let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let width = (bounds["Width"] as? NSNumber)?.doubleValue,
                  let height = (bounds["Height"] as? NSNumber)?.doubleValue,
                  width >= 80, height >= 48,
                  let pid = window[kCGWindowOwnerPID as String] as? Int
            else { continue }
            return pid_t(pid)
        }
        return nil
    }

    private static func setFrame(_ window: AXUIElement, _ rect: CGRect) -> Bool {
        var origin = rect.origin
        var size = rect.size
        guard let pos = AXValueCreate(.cgPoint, &origin),
              let sz = AXValueCreate(.cgSize, &size) else { return false }
        let position = kAXPositionAttribute as CFString
        let sizeAttr = kAXSizeAttribute as CFString
        let results = [
            AXUIElementSetAttributeValue(window, position, pos),
            AXUIElementSetAttributeValue(window, sizeAttr, sz),
            AXUIElementSetAttributeValue(window, position, pos),
            AXUIElementSetAttributeValue(window, sizeAttr, sz),
        ]
        return results.contains(.success)
    }

    private static func log(_ message: String) {
        fputs("OpenOS Thirds: \(message)\n", stderr)
    }
}

final class ThirdsController: NSObject {
    private var railPanel: NSPanel!
    private var overlayPanel: NSPanel?
    private var overlayView: OverlayView?
    private var screenObs: Any?
    private var monitors: [Any] = []
    private var dropMode = false
    private var hoverIndex = -1
    private var rightHoldWork: DispatchWorkItem?
    private var rightDownAt: NSPoint?
    private var leftSnap: [CGWindowID: TrackedWindow] = [:]
    private var windowDrag = false
    private var currentLayout = ZoneLayout.make(mode: "auto", screenWidth: 5120)
    private var statusItem: NSStatusItem?

    private let railW: CGFloat = 36
    private let edgeHotW: CGFloat = 96
    private let windowMoveSlop: CGFloat = 6
    private let rightHoldMove: CGFloat = 16

    func start() {
        StoredConfig.migrate()
        WindowSnapper.prepare()
        railPanel = makePanel(frame: .zero, ignoreMouse: false)
        layoutRail()
        setupStatusItem()

        screenObs = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.layoutRail()
            self?.refreshStatus()
        }

        func add(_ mask: NSEvent.EventTypeMask, _ handler: @escaping (NSEvent) -> Void) {
            if let m = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler) {
                monitors.append(m)
            }
        }

        add(.leftMouseDown) { [weak self] _ in self?.onLeftDown() }
        add(.rightMouseDown) { [weak self] e in self?.onRightDown(e) }
        add(.leftMouseDragged) { [weak self] e in self?.onLeftDrag(e) }
        add(.rightMouseDragged) { [weak self] _ in self?.onRightDrag() }
        add([.leftMouseUp, .rightMouseUp]) { [weak self] e in self?.onMouseUp(e) }
        add(.mouseMoved) { [weak self] _ in self?.onMouseMoved() }
        add(.keyDown) { [weak self] e in
            if e.keyCode == 53 { self?.hideZones(); return }
            self?.onShortcut(e)
        }

        if let local = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .mouseMoved, .leftMouseUp, .rightMouseUp],
            handler: { [weak self] e in
                if e.type == .keyDown {
                    if e.keyCode == 53 {
                        self?.hideZones()
                        return nil
                    }
                    self?.onShortcut(e)
                }
                if e.type == .mouseMoved { self?.onMouseMoved() }
                if e.type == .leftMouseUp || e.type == .rightMouseUp { self?.onMouseUp(e) }
                return e
            }
        ) {
            monitors.append(local)
        }
    }

    private func screenAtMouse() -> NSScreen {
        let loc = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(loc, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }

    private func layout(for screen: NSScreen) -> ZoneLayout {
        ZoneLayout.make(mode: ZoneLayout.mode(), screenWidth: screen.frame.width)
    }

    private func layoutRail() {
        guard ZoneLayout.showRail() else {
            railPanel.orderOut(nil)
            return
        }
        let s = (NSScreen.main ?? screenAtMouse())
        currentLayout = layout(for: s)
        let r = NSRect(x: s.frame.maxX - railW, y: s.frame.minY, width: railW, height: s.frame.height)
        railPanel.setFrame(r, display: true)
        let rail = RailView(frame: railPanel.contentView?.bounds ?? r, layout: currentLayout) { [weak self] in
            self?.showZones(dropMode: false)
        }
        railPanel.contentView = rail
        railPanel.contentView?.needsDisplay = true
        railPanel.orderFrontRegardless()
    }

    private func inRightHot(_ point: NSPoint, _ screen: NSScreen) -> Bool {
        point.x >= screen.frame.maxX - edgeHotW && NSMouseInRect(point, screen.frame, false)
    }

    private func leftDown() -> Bool { (NSEvent.pressedMouseButtons & (1 << 0)) != 0 }
    private func rightDown() -> Bool { (NSEvent.pressedMouseButtons & (1 << 1)) != 0 }

    private struct TrackedWindow {
        var pid: pid_t
        var rect: CGRect
    }

    private func snapshotWindows() -> [CGWindowID: TrackedWindow] {
        let opts = CGWindowListOption.optionOnScreenOnly.union(.excludeDesktopElements)
        guard let info = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else {
            return [:]
        }
        let me = Int(ProcessInfo.processInfo.processIdentifier)
        var out: [CGWindowID: TrackedWindow] = [:]
        for w in info {
            guard let pid = w[kCGWindowOwnerPID as String] as? Int, pid != me else { continue }
            if (w[kCGWindowLayer as String] as? Int) != 0 { continue }
            guard let num = w[kCGWindowNumber as String] as? CGWindowID else { continue }
            guard let b = w[kCGWindowBounds as String] as? [String: Any],
                  let x = (b["X"] as? NSNumber)?.doubleValue,
                  let y = (b["Y"] as? NSNumber)?.doubleValue,
                  let ww = (b["Width"] as? NSNumber)?.doubleValue,
                  let hh = (b["Height"] as? NSNumber)?.doubleValue
            else { continue }
            if ww < 80 || hh < 48 { continue }
            out[num] = TrackedWindow(pid: pid_t(pid), rect: CGRect(x: x, y: y, width: ww, height: hh))
        }
        return out
    }

    private func confirmWindowDrag() -> Bool {
        if windowDrag { return true }
        if mostMovedWindow() != nil {
            windowDrag = true
            return true
        }
        return false
    }

    private func draggedWindowPID() -> pid_t? {
        mostMovedWindow()?.pid
    }

    private func mostMovedWindow() -> TrackedWindow? {
        let now = snapshotWindows()
        let slop = windowMoveSlop * windowMoveSlop
        var best: TrackedWindow?
        var bestD = slop
        for (id, win) in now {
            guard let old = leftSnap[id] else { continue }
            let dx = win.rect.minX - old.rect.minX
            let dy = win.rect.minY - old.rect.minY
            let d = dx * dx + dy * dy
            if d > bestD {
                bestD = d
                best = win
            }
        }
        return best
    }

    private func rightHoldMoved() -> Bool {
        guard let origin = rightDownAt else { return false }
        let p = NSEvent.mouseLocation
        let dx = p.x - origin.x
        let dy = p.y - origin.y
        return (dx * dx + dy * dy) >= (rightHoldMove * rightHoldMove)
    }

    private func showIfWindowDrop(at loc: NSPoint) {
        let s = screenAtMouse()
        guard inRightHot(loc, s), confirmWindowDrag() else { return }
        prepareDropChrome()
        showZones(dropMode: true)
    }

    private func showIfRightHoldDrag() {
        guard overlayPanel == nil, rightDown(), rightHoldMoved() else { return }
        prepareDropChrome()
        showZones(dropMode: true)
    }

    private func onLeftDown() {
        leftSnap = snapshotWindows()
        windowDrag = false
    }

    private func onRightDown(_ event: NSEvent) {
        if overlayPanel != nil { return }
        rightDownAt = NSEvent.mouseLocation
        if leftDown(), confirmWindowDrag() {
            rightHoldWork?.cancel()
            prepareDropChrome()
            showZones(dropMode: true)
            return
        }
        rightHoldWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.showIfRightHoldDrag()
        }
        rightHoldWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32, execute: work)
    }

    private func onRightDrag() {
        if overlayPanel != nil {
            updateHover()
            return
        }
        showIfRightHoldDrag()
    }

    private func onLeftDrag(_ event: NSEvent) {
        if overlayPanel != nil {
            updateHover()
            return
        }
        showIfWindowDrop(at: NSEvent.mouseLocation)
    }

    private func onMouseMoved() {
        guard overlayPanel != nil else { return }
        updateHover()
    }

    private func onMouseUp(_ event: NSEvent) {
        rightHoldWork?.cancel()
        rightHoldWork = nil
        rightDownAt = nil
        let draggedPID = overlayPanel != nil && dropMode ? draggedWindowPID() : nil
        leftSnap = [:]
        windowDrag = false
        guard overlayPanel != nil else { return }
        updateHover()
        if dropMode {
            if hoverIndex >= 0, hoverIndex < currentLayout.zones.count {
                pick(currentLayout.zones[hoverIndex], pid: draggedPID)
            } else {
                hideZones()
            }
        }
    }

    private func onShortcut(_ event: NSEvent) {
        if event.isARepeat { return }
        let flags = event.modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .subtracting([.capsLock, .function, .numericPad])
        guard flags == [.control, .option] else { return }
        let action: String
        switch event.keyCode {
        case 18: action = "first-third"
        case 19: action = "center-third"
        case 20: action = "last-third"
        default: return
        }
        guard let norm = SnapMath.frame(forAction: action) else { return }
        let screen = NSScreen.main ?? screenAtMouse()
        if overlayPanel != nil { hideZones() }
        WindowSnapper.snap(norm: norm, screen: screen, pid: nil)
    }

    private func prepareDropChrome() {
        railPanel.ignoresMouseEvents = true
    }

    private func updateHover() {
        guard let view = overlayView, let panel = overlayPanel else { return }
        let loc = NSEvent.mouseLocation
        let local = NSPoint(x: loc.x - panel.frame.minX, y: loc.y - panel.frame.minY)
        let i = view.index(at: local)
        if i != hoverIndex {
            hoverIndex = i
            view.hover = i
            view.needsDisplay = true
        }
    }

    private func showZones(dropMode: Bool) {
        if overlayPanel != nil { return }
        self.dropMode = dropMode
        let screen = screenAtMouse()
        currentLayout = layout(for: screen)
        let overlay = makePanel(frame: screen.frame, ignoreMouse: dropMode)
        let view = OverlayView(frame: overlay.contentView!.bounds, layout: currentLayout) { [weak self] zone in
            self?.pick(zone, pid: nil)
        }
        view.onCancel = { [weak self] in self?.hideZones() }
        overlay.contentView = view
        overlay.orderFrontRegardless()
        overlayPanel = overlay
        overlayView = view
        railPanel.orderOut(nil)
        hoverIndex = -1
        updateHover()
    }

    private func hideZones() {
        rightHoldWork?.cancel()
        rightHoldWork = nil
        overlayPanel?.orderOut(nil)
        overlayPanel = nil
        overlayView = nil
        hoverIndex = -1
        dropMode = false
        railPanel.ignoresMouseEvents = false
        layoutRail()
    }

    private func pick(_ zone: Zone, pid: pid_t?) {
        let screen = screenAtMouse()
        let me = pid_t(ProcessInfo.processInfo.processIdentifier)
        var target = pid
        if target == nil || target == me {
            target = NSWorkspace.shared.frontmostApplication?.processIdentifier
        }
        if target == me { target = nil }
        hideZones()
        let norm = zone.norm
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            WindowSnapper.snap(norm: norm, screen: screen, pid: target)
        }
    }

    private func makePanel(frame: NSRect, ignoreMouse: Bool) -> NSPanel {
        let p = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.level = .statusBar
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        p.hidesOnDeactivate = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        p.ignoresMouseEvents = ignoreMouse
        p.isMovable = false
        return p
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        if let version, !version.isEmpty {
            item.button?.toolTip = "OpenOS Thirds \(version) — zonas"
        } else {
            item.button?.toolTip = "OpenOS Thirds — zonas"
        }
        item.button?.imagePosition = .imageOnly
        statusItem = item
        refreshStatus()
    }

    private func refreshStatus() {
        let mode = ZoneLayout.mode()
        let preview = layout(for: screenAtMouse())
        statusItem?.button?.image = LayoutIcon.image(layout: preview, size: 18)
        let menu = NSMenu()
        for item in ZoneLayout.catalog {
            menu.addItem(modeItem(item.title, item.id, mode))
        }
        menu.addItem(.separator())
        let rail = NSMenuItem(title: "Tab no bordo", action: #selector(toggleRail(_:)), keyEquivalent: "")
        rail.target = self
        rail.state = ZoneLayout.showRail() ? .on : .off
        menu.addItem(rail)
        statusItem?.menu = menu
    }

    private func modeItem(_ title: String, _ value: String, _ current: String) -> NSMenuItem {
        let it = NSMenuItem(title: title, action: #selector(setMode(_:)), keyEquivalent: "")
        it.target = self
        it.representedObject = value
        it.state = current == value ? .on : .off
        let w = screenAtMouse().frame.width
        it.image = LayoutIcon.image(layout: ZoneLayout.make(mode: value, screenWidth: w), size: 14)
        return it
    }

    @objc private func setMode(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String else { return }
        ZoneLayout.setMode(value)
        hideZones()
        refreshStatus()
    }

    @objc private func toggleRail(_ sender: NSMenuItem) {
        ZoneLayout.setShowRail(!ZoneLayout.showRail())
        hideZones()
        refreshStatus()
    }
}

enum LayoutIcon {
    static func image(layout: ZoneLayout, size: CGFloat) -> NSImage {
        let s = NSSize(width: size, height: size)
        let img = NSImage(size: s, flipped: false) { _ in
            let pad: CGFloat = size * 0.12
            let box = NSRect(x: pad, y: pad, width: size - pad * 2, height: size - pad * 2)
            let gap: CGFloat = max(1, size * 0.06)
            NSColor.black.setFill()
            for z in layout.zones {
                var r = NSRect(
                    x: box.minX + z.nx * box.width,
                    y: box.minY + z.ny * box.height,
                    width: z.nw * box.width,
                    height: z.nh * box.height
                )
                r = r.insetBy(dx: gap / 2, dy: gap / 2)
                NSBezierPath(roundedRect: r, xRadius: 1.2, yRadius: 1.2).fill()
            }
            return true
        }
        img.isTemplate = true
        return img
    }
}

final class RailView: NSView {
    let onClick: () -> Void
    let layout: ZoneLayout
    init(frame: NSRect, layout: ZoneLayout, onClick: @escaping () -> Void) {
        self.onClick = onClick
        self.layout = layout
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .pointingHand) }
    override func mouseDown(with event: NSEvent) { onClick() }
    override func rightMouseDown(with event: NSEvent) { onClick() }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.22).setFill()
        bounds.fill()
        let handleH: CGFloat = 240
        let r = NSRect(x: 4, y: bounds.midY - handleH / 2, width: bounds.width - 8, height: handleH)
        let path = NSBezierPath(roundedRect: r, xRadius: 8, yRadius: 8)
        NSColor.black.withAlphaComponent(0.68).setFill()
        path.fill()
        NSColor.white.withAlphaComponent(0.92).setStroke()
        path.lineWidth = 1.5
        path.stroke()
        let inner = r.insetBy(dx: 7, dy: 22)
        let gap: CGFloat = 3
        NSColor.white.withAlphaComponent(0.95).setFill()
        for z in layout.zones {
            var zr = NSRect(
                x: inner.minX + z.nx * inner.width,
                y: inner.minY + z.ny * inner.height,
                width: z.nw * inner.width,
                height: z.nh * inner.height
            )
            zr = zr.insetBy(dx: gap / 2, dy: gap / 2)
            NSBezierPath(roundedRect: zr, xRadius: 2, yRadius: 2).fill()
        }
    }
}

final class OverlayView: NSView {
    let onPick: (Zone) -> Void
    var onCancel: (() -> Void)?
    private let layout: ZoneLayout
    var hover = -1

    init(frame: NSRect, layout: ZoneLayout, onPick: @escaping (Zone) -> Void) {
        self.onPick = onPick
        self.layout = layout
        super.init(frame: frame)
    }
    required init?(coder: NSCoder) { fatalError() }
    override var acceptsFirstResponder: Bool { true }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .pointingHand) }
    override func updateTrackingAreas() {
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        ))
    }
    override func mouseMoved(with event: NSEvent) {
        let i = index(at: convert(event.locationInWindow, from: nil))
        if i != hover { hover = i; needsDisplay = true }
    }
    override func mouseDown(with event: NSEvent) { click(event) }
    override func rightMouseDown(with event: NSEvent) { click(event) }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onCancel?() }
    }
    private func click(_ event: NSEvent) {
        let i = index(at: convert(event.locationInWindow, from: nil))
        if i >= 0 { onPick(layout.zones[i]) } else { onCancel?() }
    }
    func index(at p: NSPoint) -> Int {
        zoneRects().firstIndex { $0.contains(p) } ?? -1
    }
    private func zoneRects() -> [NSRect] {
        let gap: CGFloat = 14
        let inset: CGFloat = 22
        let box = bounds.insetBy(dx: inset, dy: inset)
        return layout.zones.map { z in
            var r = NSRect(
                x: box.minX + z.nx * box.width,
                y: box.minY + z.ny * box.height,
                width: z.nw * box.width,
                height: z.nh * box.height
            )
            r = r.insetBy(dx: gap / 2, dy: gap / 2)
            return r
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.40).setFill()
        bounds.fill()
        let rects = zoneRects()
        for (i, r) in rects.enumerated() {
            let path = NSBezierPath(roundedRect: r, xRadius: 16, yRadius: 16)
            if i == hover {
                NSColor.systemBlue.withAlphaComponent(0.52).setFill()
            } else {
                NSColor.white.withAlphaComponent(0.16).setFill()
            }
            path.fill()
            NSColor.white.withAlphaComponent(0.70).setStroke()
            path.lineWidth = 2
            path.stroke()
            let title = layout.labels[i] as NSString
            let fontSize: CGFloat = r.height < 120 ? 22 : 32
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: NSColor.white
            ]
            let size = title.size(withAttributes: attrs)
            title.draw(
                at: NSPoint(x: r.midX - size.width / 2, y: r.midY - size.height / 2 + 10),
                withAttributes: attrs
            )
            let sub = "Larga aqui" as NSString
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: NSColor.white.withAlphaComponent(0.82)
            ]
            let ss = sub.size(withAttributes: subAttrs)
            if r.height > 90 {
                sub.draw(
                    at: NSPoint(x: r.midX - ss.width / 2, y: r.midY - size.height / 2 - 16),
                    withAttributes: subAttrs
                )
            }
        }
    }
}
