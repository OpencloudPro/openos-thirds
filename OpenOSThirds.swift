import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = ThirdsController()
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
}

struct ZoneLayout {
    let id: String
    let title: String
    let zones: [Zone]

    var count: Int { zones.count }
    var actions: [String] { zones.map(\.action) }
    var labels: [String] { zones.map(\.label) }

    static let modeKey = "zoneMode"
    static let railKey = "showRail"
    static let wideCutoff: CGFloat = 3000

    static let catalog: [(id: String, title: String)] = [
        ("auto", "Auto (por ecrã)"),
        ("two", "2 iguais"),
        ("three", "3 iguais"),
        ("wideRight", "2/3 + 1/3"),
        ("wideLeft", "1/3 + 2/3"),
        ("corners", "4 cantos"),
        ("rows", "Cima / Baixo"),
        ("mainRight", "1 grande + 2 dir."),
        ("mainLeft", "2 esq. + 1 grande"),
        ("center", "1/4 + 1/2 + 1/4"),
        ("four", "4 colunas"),
    ]

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

    static func resolve(_ mode: String, screenWidth: CGFloat) -> String {
        if mode == "auto" {
            return screenWidth >= wideCutoff ? "three" : "two"
        }
        return mode
    }

    static func make(mode: String, screenWidth: CGFloat) -> ZoneLayout {
        switch resolve(mode, screenWidth: screenWidth) {
        case "three":
            return ZoneLayout(id: "three", title: "3 iguais", zones: [
                Zone(action: "first-third", label: "Esquerda", nx: 0, ny: 0, nw: 1 / 3, nh: 1),
                Zone(action: "center-third", label: "Meio", nx: 1 / 3, ny: 0, nw: 1 / 3, nh: 1),
                Zone(action: "last-third", label: "Direita", nx: 2 / 3, ny: 0, nw: 1 / 3, nh: 1),
            ])
        case "wideRight":
            return ZoneLayout(id: "wideRight", title: "2/3 + 1/3", zones: [
                Zone(action: "first-two-thirds", label: "Grande", nx: 0, ny: 0, nw: 2 / 3, nh: 1),
                Zone(action: "last-third", label: "Pequena", nx: 2 / 3, ny: 0, nw: 1 / 3, nh: 1),
            ])
        case "wideLeft":
            return ZoneLayout(id: "wideLeft", title: "1/3 + 2/3", zones: [
                Zone(action: "first-third", label: "Pequena", nx: 0, ny: 0, nw: 1 / 3, nh: 1),
                Zone(action: "last-two-thirds", label: "Grande", nx: 1 / 3, ny: 0, nw: 2 / 3, nh: 1),
            ])
        case "corners":
            return ZoneLayout(id: "corners", title: "4 cantos", zones: [
                Zone(action: "top-left", label: "Cima esq.", nx: 0, ny: 0.5, nw: 0.5, nh: 0.5),
                Zone(action: "top-right", label: "Cima dir.", nx: 0.5, ny: 0.5, nw: 0.5, nh: 0.5),
                Zone(action: "bottom-left", label: "Baixo esq.", nx: 0, ny: 0, nw: 0.5, nh: 0.5),
                Zone(action: "bottom-right", label: "Baixo dir.", nx: 0.5, ny: 0, nw: 0.5, nh: 0.5),
            ])
        case "rows":
            return ZoneLayout(id: "rows", title: "Cima / Baixo", zones: [
                Zone(action: "top-half", label: "Cima", nx: 0, ny: 0.5, nw: 1, nh: 0.5),
                Zone(action: "bottom-half", label: "Baixo", nx: 0, ny: 0, nw: 1, nh: 0.5),
            ])
        case "mainRight":
            return ZoneLayout(id: "mainRight", title: "1 grande + 2 dir.", zones: [
                Zone(action: "left-half", label: "Grande", nx: 0, ny: 0, nw: 0.5, nh: 1),
                Zone(action: "top-right", label: "Cima", nx: 0.5, ny: 0.5, nw: 0.5, nh: 0.5),
                Zone(action: "bottom-right", label: "Baixo", nx: 0.5, ny: 0, nw: 0.5, nh: 0.5),
            ])
        case "mainLeft":
            return ZoneLayout(id: "mainLeft", title: "2 esq. + 1 grande", zones: [
                Zone(action: "top-left", label: "Cima", nx: 0, ny: 0.5, nw: 0.5, nh: 0.5),
                Zone(action: "bottom-left", label: "Baixo", nx: 0, ny: 0, nw: 0.5, nh: 0.5),
                Zone(action: "right-half", label: "Grande", nx: 0.5, ny: 0, nw: 0.5, nh: 1),
            ])
        case "center":
            return ZoneLayout(id: "center", title: "1/4 + 1/2 + 1/4", zones: [
                Zone(action: "first-fourth", label: "Esq.", nx: 0, ny: 0, nw: 0.25, nh: 1),
                Zone(action: "center-half", label: "Meio", nx: 0.25, ny: 0, nw: 0.5, nh: 1),
                Zone(action: "last-fourth", label: "Dir.", nx: 0.75, ny: 0, nw: 0.25, nh: 1),
            ])
        case "four":
            return ZoneLayout(id: "four", title: "4 colunas", zones: [
                Zone(action: "first-fourth", label: "1", nx: 0, ny: 0, nw: 0.25, nh: 1),
                Zone(action: "second-fourth", label: "2", nx: 0.25, ny: 0, nw: 0.25, nh: 1),
                Zone(action: "third-fourth", label: "3", nx: 0.5, ny: 0, nw: 0.25, nh: 1),
                Zone(action: "last-fourth", label: "4", nx: 0.75, ny: 0, nw: 0.25, nh: 1),
            ])
        default:
            return ZoneLayout(id: "two", title: "2 iguais", zones: [
                Zone(action: "left-half", label: "Esquerda", nx: 0, ny: 0, nw: 0.5, nh: 1),
                Zone(action: "right-half", label: "Direita", nx: 0.5, ny: 0, nw: 0.5, nh: 1),
            ])
        }
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
    private var currentLayout = ZoneLayout.make(mode: "auto", screenWidth: 5120)
    private var statusItem: NSStatusItem?

    private let railW: CGFloat = 36
    private let edgeHotW: CGFloat = 96

    func start() {
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

        add(.rightMouseDown) { [weak self] e in self?.onRightDown(e) }
        add(.leftMouseDragged) { [weak self] e in self?.onLeftDrag(e) }
        add([.leftMouseUp, .rightMouseUp]) { [weak self] e in self?.onMouseUp(e) }
        add(.mouseMoved) { [weak self] _ in self?.onMouseMoved() }
        add(.keyDown) { [weak self] e in
            if e.keyCode == 53 { self?.hideZones() }
        }

        if let local = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .mouseMoved, .leftMouseUp, .rightMouseUp],
            handler: { [weak self] e in
                if e.type == .keyDown, e.keyCode == 53 {
                    self?.hideZones()
                    return nil
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

    private func onRightDown(_ event: NSEvent) {
        if overlayPanel != nil { return }
        let loc = NSEvent.mouseLocation
        let s = screenAtMouse()
        if leftDown() || inRightHot(loc, s) {
            rightHoldWork?.cancel()
            prepareDropChrome()
            showZones(dropMode: true)
            return
        }
        rightHoldWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.rightDown(), self.overlayPanel == nil else { return }
            self.prepareDropChrome()
            self.showZones(dropMode: true)
        }
        rightHoldWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32, execute: work)
    }

    private func onLeftDrag(_ event: NSEvent) {
        if overlayPanel != nil {
            updateHover()
            return
        }
        let loc = NSEvent.mouseLocation
        let s = screenAtMouse()
        if inRightHot(loc, s) {
            prepareDropChrome()
            showZones(dropMode: true)
        }
    }

    private func onMouseMoved() {
        guard overlayPanel != nil else { return }
        updateHover()
    }

    private func onMouseUp(_ event: NSEvent) {
        rightHoldWork?.cancel()
        rightHoldWork = nil
        guard overlayPanel != nil else { return }
        updateHover()
        if dropMode {
            if hoverIndex >= 0, hoverIndex < currentLayout.actions.count {
                pick(currentLayout.actions[hoverIndex])
            } else {
                hideZones()
            }
        }
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
        let view = OverlayView(frame: overlay.contentView!.bounds, layout: currentLayout) { [weak self] action in
            self?.pick(action)
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

    private func pick(_ action: String) {
        hideZones()
        guard !action.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            if let url = URL(string: "rectangle://execute-action?name=\(action)") {
                NSWorkspace.shared.open(url)
            }
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
        item.button?.toolTip = "OpenOS Thirds — zonas"
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
    let onPick: (String) -> Void
    var onCancel: (() -> Void)?
    private let layout: ZoneLayout
    var hover = -1

    init(frame: NSRect, layout: ZoneLayout, onPick: @escaping (String) -> Void) {
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
        if i >= 0 { onPick(layout.actions[i]) } else { onCancel?() }
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

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
