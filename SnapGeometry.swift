import Foundation

struct NormRect: Equatable {
    var nx: Double
    var ny: Double
    var nw: Double
    var nh: Double
}

struct PixelRect: Equatable {
    var x: Double
    var y: Double
    var w: Double
    var h: Double
}

struct ZoneDef: Equatable {
    var action: String
    var label: String
    var nx: Double
    var ny: Double
    var nw: Double
    var nh: Double

    var norm: NormRect { NormRect(nx: nx, ny: ny, nw: nw, nh: nh) }
}

struct LayoutDef: Equatable {
    var id: String
    var title: String
    var zones: [ZoneDef]
}

enum SnapMath {
    static let wideCutoff: Double = 3000

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

    static let concreteLayouts: [LayoutDef] = [
        LayoutDef(id: "three", title: "3 iguais", zones: [
            ZoneDef(action: "first-third", label: "Esquerda", nx: 0, ny: 0, nw: 1.0 / 3.0, nh: 1),
            ZoneDef(action: "center-third", label: "Meio", nx: 1.0 / 3.0, ny: 0, nw: 1.0 / 3.0, nh: 1),
            ZoneDef(action: "last-third", label: "Direita", nx: 2.0 / 3.0, ny: 0, nw: 1.0 / 3.0, nh: 1),
        ]),
        LayoutDef(id: "wideRight", title: "2/3 + 1/3", zones: [
            ZoneDef(action: "first-two-thirds", label: "Grande", nx: 0, ny: 0, nw: 2.0 / 3.0, nh: 1),
            ZoneDef(action: "last-third", label: "Pequena", nx: 2.0 / 3.0, ny: 0, nw: 1.0 / 3.0, nh: 1),
        ]),
        LayoutDef(id: "wideLeft", title: "1/3 + 2/3", zones: [
            ZoneDef(action: "first-third", label: "Pequena", nx: 0, ny: 0, nw: 1.0 / 3.0, nh: 1),
            ZoneDef(action: "last-two-thirds", label: "Grande", nx: 1.0 / 3.0, ny: 0, nw: 2.0 / 3.0, nh: 1),
        ]),
        LayoutDef(id: "corners", title: "4 cantos", zones: [
            ZoneDef(action: "top-left", label: "Cima esq.", nx: 0, ny: 0.5, nw: 0.5, nh: 0.5),
            ZoneDef(action: "top-right", label: "Cima dir.", nx: 0.5, ny: 0.5, nw: 0.5, nh: 0.5),
            ZoneDef(action: "bottom-left", label: "Baixo esq.", nx: 0, ny: 0, nw: 0.5, nh: 0.5),
            ZoneDef(action: "bottom-right", label: "Baixo dir.", nx: 0.5, ny: 0, nw: 0.5, nh: 0.5),
        ]),
        LayoutDef(id: "rows", title: "Cima / Baixo", zones: [
            ZoneDef(action: "top-half", label: "Cima", nx: 0, ny: 0.5, nw: 1, nh: 0.5),
            ZoneDef(action: "bottom-half", label: "Baixo", nx: 0, ny: 0, nw: 1, nh: 0.5),
        ]),
        LayoutDef(id: "mainRight", title: "1 grande + 2 dir.", zones: [
            ZoneDef(action: "left-half", label: "Grande", nx: 0, ny: 0, nw: 0.5, nh: 1),
            ZoneDef(action: "top-right", label: "Cima", nx: 0.5, ny: 0.5, nw: 0.5, nh: 0.5),
            ZoneDef(action: "bottom-right", label: "Baixo", nx: 0.5, ny: 0, nw: 0.5, nh: 0.5),
        ]),
        LayoutDef(id: "mainLeft", title: "2 esq. + 1 grande", zones: [
            ZoneDef(action: "top-left", label: "Cima", nx: 0, ny: 0.5, nw: 0.5, nh: 0.5),
            ZoneDef(action: "bottom-left", label: "Baixo", nx: 0, ny: 0, nw: 0.5, nh: 0.5),
            ZoneDef(action: "right-half", label: "Grande", nx: 0.5, ny: 0, nw: 0.5, nh: 1),
        ]),
        LayoutDef(id: "center", title: "1/4 + 1/2 + 1/4", zones: [
            ZoneDef(action: "first-fourth", label: "Esq.", nx: 0, ny: 0, nw: 0.25, nh: 1),
            ZoneDef(action: "center-half", label: "Meio", nx: 0.25, ny: 0, nw: 0.5, nh: 1),
            ZoneDef(action: "last-fourth", label: "Dir.", nx: 0.75, ny: 0, nw: 0.25, nh: 1),
        ]),
        LayoutDef(id: "four", title: "4 colunas", zones: [
            ZoneDef(action: "first-fourth", label: "1", nx: 0, ny: 0, nw: 0.25, nh: 1),
            ZoneDef(action: "second-fourth", label: "2", nx: 0.25, ny: 0, nw: 0.25, nh: 1),
            ZoneDef(action: "third-fourth", label: "3", nx: 0.5, ny: 0, nw: 0.25, nh: 1),
            ZoneDef(action: "last-fourth", label: "4", nx: 0.75, ny: 0, nw: 0.25, nh: 1),
        ]),
        LayoutDef(id: "two", title: "2 iguais", zones: [
            ZoneDef(action: "left-half", label: "Esquerda", nx: 0, ny: 0, nw: 0.5, nh: 1),
            ZoneDef(action: "right-half", label: "Direita", nx: 0.5, ny: 0, nw: 0.5, nh: 1),
        ]),
    ]

    static let layoutsByID: [String: LayoutDef] = {
        var map: [String: LayoutDef] = [:]
        for layout in concreteLayouts {
            map[layout.id] = layout
        }
        return map
    }()

    /// Native frame for a Rectangle-style action id. Built from the layouts so the
    /// same id cannot mean two different rectangles.
    static let actionFrames: [String: NormRect] = {
        var map: [String: NormRect] = [:]
        for layout in concreteLayouts {
            for zone in layout.zones where map[zone.action] == nil {
                map[zone.action] = zone.norm
            }
        }
        return map
    }()

    static func frame(forAction action: String) -> NormRect? {
        actionFrames[action.lowercased()]
    }

    static func resolve(mode: String, screenWidth: Double) -> String {
        if mode == "auto" {
            return screenWidth >= wideCutoff ? "three" : "two"
        }
        return mode
    }

    static func layout(mode: String, screenWidth: Double) -> LayoutDef {
        let id = resolve(mode: mode, screenWidth: screenWidth)
        return layoutsByID[id] ?? layoutsByID["two"]!
    }

    static func pixel(_ value: Double) -> Double {
        value.rounded(.toNearestOrAwayFromZero)
    }

    /// AppKit visible frame (origin bottom-left) × normalized zone → points.
    /// Edges are rounded so neighbouring zones share a pixel and tile the screen.
    static func cocoaRect(
        _ norm: NormRect,
        visibleX: Double,
        visibleY: Double,
        visibleW: Double,
        visibleH: Double
    ) -> PixelRect {
        let x0 = pixel(visibleX + norm.nx * visibleW)
        let x1 = pixel(visibleX + (norm.nx + norm.nw) * visibleW)
        let y0 = pixel(visibleY + norm.ny * visibleH)
        let y1 = pixel(visibleY + (norm.ny + norm.nh) * visibleH)
        return PixelRect(x: x0, y: y0, w: x1 - x0, h: y1 - y0)
    }

    /// AppKit global points → Accessibility points (origin top-left of the primary display, y down).
    static func axRect(_ cocoa: PixelRect, primaryMaxY: Double) -> PixelRect {
        let top = cocoa.y + cocoa.h
        return PixelRect(x: cocoa.x, y: pixel(primaryMaxY - top), w: cocoa.w, h: cocoa.h)
    }

    /// Rewrites a stored preference string that points at an external app URL scheme
    /// (`rectangle://execute-action?name=last-third`, or any `execute-action` URL)
    /// into the bare native action id. Other strings are left alone.
    static func migrateString(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return raw }
        let lower = trimmed.lowercased()
        guard lower.contains("://") else { return raw }
        let isRectangle = lower.hasPrefix("rectangle://")
        let isExecute = lower.contains("execute-action")
        guard isRectangle || isExecute else { return raw }
        return actionName(in: trimmed) ?? ""
    }

    static func actionName(in stored: String) -> String? {
        if let name = queryName(stored) { return name }
        let lower = stored.lowercased()
        let prefix = "rectangle://"
        guard lower.hasPrefix(prefix) else { return nil }
        var rest = String(lower.dropFirst(prefix.count))
        if let q = rest.firstIndex(of: "?") {
            rest = String(rest[..<q])
        }
        while rest.hasSuffix("/") { rest.removeLast() }
        while rest.hasPrefix("/") { rest.removeFirst() }
        if rest.isEmpty || rest == "execute-action" { return nil }
        return rest
    }

    static func queryName(_ stored: String) -> String? {
        let lower = stored.lowercased()
        guard let range = lower.range(of: "name=") else { return nil }
        let rest = lower[range.upperBound...]
        let end = rest.firstIndex(where: { $0 == "&" || $0 == "#" || $0 == " " }) ?? rest.endIndex
        var raw = String(rest[..<end])
        raw = raw.removingPercentEncoding ?? raw
        raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? nil : raw
    }

    static func migrateValue(_ value: Any) -> (Any, Bool) {
        if let text = value as? String {
            let migrated = migrateString(text)
            return (migrated, migrated != text)
        }
        if let list = value as? [Any] {
            return migrateList(list)
        }
        if let list = value as? NSArray {
            return migrateList(list.map { $0 })
        }
        if let dict = value as? [String: Any] {
            return migrateDict(dict)
        }
        if let dict = value as? NSDictionary {
            var swift: [String: Any] = [:]
            swift.reserveCapacity(dict.count)
            for (key, item) in dict {
                guard let key = key as? String else { continue }
                swift[key] = item
            }
            return migrateDict(swift)
        }
        if let mirrored = migrateMirrored(value) {
            return mirrored
        }
        return (value, false)
    }

    /// Swift arrays stored in `Any` often fail `as? [Any]`. Walk them so a saved
    /// zone list still migrates.
    private static func migrateMirrored(_ value: Any) -> (Any, Bool)? {
        let mirror = Mirror(reflecting: value)
        switch mirror.displayStyle {
        case .collection:
            return migrateList(mirror.children.map(\.value))
        case .dictionary:
            var dict: [String: Any] = [:]
            for child in mirror.children {
                let parts = Mirror(reflecting: child.value).children.map(\.value)
                guard parts.count == 2, let key = parts[0] as? String else { continue }
                dict[key] = parts[1]
            }
            return migrateDict(dict)
        default:
            return nil
        }
    }

    private static func migrateList(_ list: [Any]) -> (Any, Bool) {
        var changed = false
        let out: [Any] = list.map { item in
            let (migrated, itemChanged) = migrateValue(item)
            if itemChanged { changed = true }
            return migrated
        }
        return (out, changed)
    }

    private static func migrateDict(_ dict: [String: Any]) -> (Any, Bool) {
        var changed = false
        var out: [String: Any] = [:]
        out.reserveCapacity(dict.count)
        for (key, item) in dict {
            let newKey = migrateString(key)
            let (migrated, itemChanged) = migrateValue(item)
            if itemChanged || newKey != key { changed = true }
            out[newKey] = migrated
        }
        return (out, changed)
    }
}
