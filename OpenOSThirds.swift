import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = ThirdsController()
    func applicationDidFinishLaunching(_ notification: Notification) {
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: "pro.openos.thirds")
        if others.count > 1 { NSApp.terminate(nil); return }
        controller.start()
    }
}

final class ThirdsController {
    private var railPanel: NSPanel!
    private var overlayPanel: NSPanel?
    private var overlayView: OverlayView?
    private var screenObs: Any?
    private var monitors: [Any] = []
    private var dropMode = false
    private var hoverIndex = -1
    private var rightHoldWork: DispatchWorkItem?

    private let railW: CGFloat = 36
    private let edgeHotW: CGFloat = 96
    private let actions = ["first-third", "center-third", "last-third"]

    func start() {
        railPanel = makePanel(frame: .zero, ignoreMouse: false)
        layoutRail()
        railPanel.contentView = RailView(frame: railPanel.contentView!.bounds) { [weak self] in
            self?.showZones(dropMode: false)
        }
        railPanel.orderFrontRegardless()

        screenObs = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.layoutRail()
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

    private func layoutRail() {
        let s = (NSScreen.main ?? screenAtMouse()).frame
        let r = NSRect(x: s.maxX - railW, y: s.minY, width: railW, height: s.height)
        railPanel.setFrame(r, display: true)
        railPanel.contentView?.frame = railPanel.contentView?.bounds ?? .zero
        railPanel.contentView?.needsDisplay = true
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
            if hoverIndex >= 0 {
                pick(actions[hoverIndex])
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
        let overlay = makePanel(frame: screen.frame, ignoreMouse: dropMode)
        let view = OverlayView(frame: overlay.contentView!.bounds) { [weak self] action in
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
        railPanel.orderFrontRegardless()
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
}

final class RailView: NSView {
    let onClick: () -> Void
    init(frame: NSRect, onClick: @escaping () -> Void) {
        self.onClick = onClick
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
        let gap: CGFloat = 5
        let stripeW: CGFloat = 3
        let total = stripeW * 3 + gap * 2
        var x = r.midX - total / 2
        let y = r.minY + 22
        let h = r.height - 44
        for _ in 0..<3 {
            NSColor.white.withAlphaComponent(0.95).setFill()
            NSBezierPath(roundedRect: NSRect(x: x, y: y, width: stripeW, height: h), xRadius: 1.5, yRadius: 1.5).fill()
            x += stripeW + gap
        }
    }
}

final class OverlayView: NSView {
    let onPick: (String) -> Void
    var onCancel: (() -> Void)?
    private let actions = ["first-third", "center-third", "last-third"]
    private let labels = ["Esquerda", "Meio", "Direita"]
    var hover = -1

    init(frame: NSRect, onPick: @escaping (String) -> Void) {
        self.onPick = onPick
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
        if i >= 0 { onPick(actions[i]) } else { onCancel?() }
    }
    func index(at p: NSPoint) -> Int {
        columnRects().firstIndex { $0.contains(p) } ?? -1
    }
    private func columnRects() -> [NSRect] {
        let gap: CGFloat = 18
        let inset: CGFloat = 22
        let w = (bounds.width - inset * 2 - gap * 2) / 3
        let h = bounds.height - inset * 2
        return (0..<3).map { i in
            NSRect(x: inset + CGFloat(i) * (w + gap), y: inset, width: w, height: h)
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.40).setFill()
        bounds.fill()
        for (i, r) in columnRects().enumerated() {
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
            let title = labels[i] as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 32, weight: .semibold),
                .foregroundColor: NSColor.white
            ]
            let size = title.size(withAttributes: attrs)
            title.draw(
                at: NSPoint(x: r.midX - size.width / 2, y: r.midY - size.height / 2 + 14),
                withAttributes: attrs
            )
            let sub = "Larga aqui" as NSString
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: NSColor.white.withAlphaComponent(0.82)
            ]
            let ss = sub.size(withAttributes: subAttrs)
            sub.draw(
                at: NSPoint(x: r.midX - ss.width / 2, y: r.midY - size.height / 2 - 18),
                withAttributes: subAttrs
            )
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
