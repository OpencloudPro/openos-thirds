import Foundation

// swiftc -o /tmp/snap-tests SnapGeometry.swift SnapGeometryTests.swift && /tmp/snap-tests

var passed = 0
var failures: [String] = []

func check(_ condition: Bool, _ message: String) {
    if condition {
        passed += 1
    } else {
        failures.append(message)
    }
}

func walk(_ value: Any, _ visit: (String) -> Void) {
    if let text = value as? String {
        visit(text)
        return
    }
    if let list = value as? [Any] {
        for item in list { walk(item, visit) }
        return
    }
    if let dict = value as? [String: Any] {
        for (key, item) in dict {
            visit(key)
            walk(item, visit)
        }
    }
}

@main
enum SnapTestRunner {
static func main() {
let third = 1.0 / 3.0
for layout in SnapMath.concreteLayouts {
    check(!layout.zones.isEmpty, "\(layout.id) sem zonas")
    for zone in layout.zones {
        let action = zone.action.lowercased()
        check(!action.contains("://"), "\(layout.id) ação com URL: \(zone.action)")
        check(!action.contains("rectangle"), "\(layout.id) depende do Rectangle: \(zone.action)")
        check(!action.contains("execute-action"), "\(layout.id) execute-action: \(zone.action)")
        check(SnapMath.frame(forAction: zone.action) == zone.norm, "\(layout.id) \(zone.action) não bate com o retângulo")
    }
}

for item in SnapMath.catalog where item.id != "auto" {
    check(SnapMath.layoutsByID[item.id]?.title == item.title, "título \(item.id)")
}
check(SnapMath.layoutsByID["auto"] == nil, "auto não é layout concreto")
check(SnapMath.catalog.count == SnapMath.concreteLayouts.count + 1, "catálogo")

check(
    SnapMath.layout(mode: "auto", screenWidth: 3000) == SnapMath.layout(mode: "three", screenWidth: 100),
    "auto em ecrã largo"
)
check(
    SnapMath.layout(mode: "auto", screenWidth: 2999) == SnapMath.layout(mode: "two", screenWidth: 100),
    "auto em ecrã estreito"
)
check(SnapMath.layout(mode: "nope", screenWidth: 8000).id == "two", "modo desconhecido")
check(SnapMath.layout(mode: "corners", screenWidth: 800).id == "corners", "modo explícito")

let last = SnapMath.frame(forAction: "last-third")
check(last == NormRect(nx: 2.0 / 3.0, ny: 0, nw: third, nh: 1), "last-third")
check(SnapMath.frame(forAction: "LAST-THIRD") == last, "ação case-insensitive")
check(SnapMath.frame(forAction: "first-third") == NormRect(nx: 0, ny: 0, nw: third, nh: 1), "first-third")
check(SnapMath.frame(forAction: "center-third") == NormRect(nx: third, ny: 0, nw: third, nh: 1), "center-third")
check(SnapMath.frame(forAction: "does-not-exist") == nil, "ação desconhecida")

let visible = (x: 10.0, y: 40.0, w: 1000.0, h: 900.0)
func cocoa(_ norm: NormRect) -> PixelRect {
    SnapMath.cocoaRect(norm, visibleX: visible.x, visibleY: visible.y, visibleW: visible.w, visibleH: visible.h)
}
let firstC = cocoa(SnapMath.frame(forAction: "first-third")!)
let centerC = cocoa(SnapMath.frame(forAction: "center-third")!)
let lastC = cocoa(SnapMath.frame(forAction: "last-third")!)
check(firstC == PixelRect(x: 10, y: 40, w: 333, h: 900), "cocoa first \(firstC)")
check(centerC == PixelRect(x: 343, y: 40, w: 334, h: 900), "cocoa center \(centerC)")
check(lastC == PixelRect(x: 677, y: 40, w: 333, h: 900), "cocoa last \(lastC)")
check(firstC.w + centerC.w + lastC.w == visible.w, "terços preenchem a largura")
check(firstC.x == visible.x && lastC.x + lastC.w == visible.x + visible.w, "terços cobrem as bordas")
check(firstC.x + firstC.w == centerC.x && centerC.x + centerC.w == lastC.x, "terços sem folga")

let top = cocoa(SnapMath.frame(forAction: "top-half")!)
let bottom = cocoa(SnapMath.frame(forAction: "bottom-half")!)
check(top == PixelRect(x: 10, y: 490, w: 1000, h: 450), "cocoa cima \(top)")
check(bottom == PixelRect(x: 10, y: 40, w: 1000, h: 450), "cocoa baixo \(bottom)")
check(bottom.y + bottom.h == top.y, "metades encostam")

func ax(_ cocoa: PixelRect, _ primaryMaxY: Double) -> PixelRect {
    SnapMath.axRect(cocoa, primaryMaxY: primaryMaxY)
}
check(ax(firstC, 1000) == PixelRect(x: 10, y: 60, w: 333, h: 900), "ax first")
check(ax(lastC, 1000) == PixelRect(x: 677, y: 60, w: 333, h: 900), "ax last")

let primaryFull = SnapMath.cocoaRect(
    NormRect(nx: 0, ny: 0, nw: 1, nh: 1),
    visibleX: 0, visibleY: 80, visibleW: 1920, visibleH: 975
)
check(ax(primaryFull, 1080) == PixelRect(x: 0, y: 25, w: 1920, h: 975), "ax abaixo da menu bar")

let rightHalf = SnapMath.cocoaRect(
    SnapMath.frame(forAction: "left-half")!,
    visibleX: 1920, visibleY: 80, visibleW: 1920, visibleH: 975
)
check(ax(rightHalf, 1080) == PixelRect(x: 1920, y: 25, w: 960, h: 975), "ecrã à direita")

let above = SnapMath.cocoaRect(
    NormRect(nx: 0, ny: 0, nw: 1, nh: 1),
    visibleX: 0, visibleY: 1080, visibleW: 1440, visibleH: 900
)
check(ax(above, 1080) == PixelRect(x: 0, y: -900, w: 1440, h: 900), "ecrã por cima")

let leftScreen = SnapMath.cocoaRect(
    SnapMath.frame(forAction: "left-half")!,
    visibleX: -1920, visibleY: 80, visibleW: 1920, visibleH: 975
)
check(ax(leftScreen, 1080) == PixelRect(x: -1920, y: 25, w: 960, h: 975), "ecrã à esquerda")

let halfPoint = PixelRect(x: 0, y: 0, w: 10, h: 10.5)
check(ax(halfPoint, 100) == PixelRect(x: 0, y: 90, w: 10, h: 10.5), "arredondamento ax .5")

check(
    SnapMath.migrateString("rectangle://execute-action?name=last-third") == "last-third",
    "migra last-third"
)
check(
    SnapMath.migrateString("Rectangle://Execute-Action?Name=Last-Third") == "last-third",
    "migra maiúsculas"
)
check(
    SnapMath.migrateString("rectangle://execute-action?name=first-third&foo=1") == "first-third",
    "migra com query extra"
)
check(
    SnapMath.migrateString("rectangle://execute-action?name=top%2Dleft") == "top-left",
    "migra percent-encoding"
)
check(SnapMath.migrateString("rectangle://top-left") == "top-left", "migra rectangle://top-left")
check(SnapMath.migrateString("rectangle://execute-action") == "", "URL sem nome")
check(SnapMath.migrateString("rectangle://execute-action?name=") == "", "nome vazio")
check(
    SnapMath.migrateString("otherapp://execute-action?name=left-half") == "left-half",
    "outro scheme execute-action"
)
check(SnapMath.migrateString("last-third") == "last-third", "id nativo intacto")
check(SnapMath.migrateString("auto") == "auto", "zoneMode intacto")
check(
    SnapMath.migrateString("https://github.com/rxhanson/Rectangle") == "https://github.com/rxhanson/Rectangle",
    "URL que não é ação"
)

let saved: [String: Any] = [
    "zoneMode": "wideRight",
    "showRail": true,
    "count": 3,
    "zones": [
        ["action": "rectangle://execute-action?name=first-two-thirds", "label": "Grande"],
        ["action": "  rectangle://execute-action?name=LAST-THIRD  ", "label": "Pequena"],
    ],
    "lastDrop": "rectangle://execute-action?name=last-third",
    "note": "https://github.com/rxhanson/Rectangle",
    "rectangle://execute-action?name=left-half": "legado",
]
let (migrated, changed) = SnapMath.migrateValue(saved)
check(changed, "config gravada mudou")
let dict = migrated as? [String: Any]
check(dict?["zoneMode"] as? String == "wideRight", "zoneMode preservado")
check(dict?["showRail"] as? Bool == true, "showRail preservado")
check(dict?["count"] as? Int == 3, "número preservado")
check(dict?["lastDrop"] as? String == "last-third", "lastDrop nativo")
check(dict?["note"] as? String == "https://github.com/rxhanson/Rectangle", "nota preservada")
check(dict?["left-half"] as? String == "legado", "chave URL migrada")
check(dict?["rectangle://execute-action?name=left-half"] == nil, "chave antiga removida")
let zoneList = dict?["zones"] as? [Any] ?? []
check(zoneList.count == 2, "duas zonas")
let zone0 = zoneList.first as? [String: Any]
let zone1 = zoneList.last as? [String: Any]
check(zone0?["action"] as? String == "first-two-thirds", "primeira ação nativa")
check(zone1?["action"] as? String == "last-third", "segunda ação nativa")
check(zone0?["label"] as? String == "Grande", "etiqueta preservada")

walk(migrated) { text in
    let lower = text.lowercased()
    check(!lower.contains("rectangle://"), "ainda há rectangle:// em \(text)")
    check(!lower.contains("execute-action"), "ainda há execute-action em \(text)")
}

let (again, changedAgain) = SnapMath.migrateValue(migrated)
check(!changedAgain, "migração idempotente")
check((again as? [String: Any])?["lastDrop"] as? String == "last-third", "segunda passagem")

let clean: [String: Any] = ["zoneMode": "auto", "showRail": false]
check(!SnapMath.migrateValue(clean).1, "config limpa não é reescrita")

let ns = ["action": "rectangle://execute-action?name=last-third"] as NSDictionary
let (nsOut, nsChanged) = SnapMath.migrateValue(ns)
check(nsChanged, "NSDictionary muda")
check((nsOut as? [String: Any])?["action"] as? String == "last-third", "NSDictionary ação")

let nsList = ["rectangle://execute-action?name=center-third", "auto"] as NSArray
let (listOut, listChanged) = SnapMath.migrateValue(nsList)
check(listChanged, "NSArray muda")
let list = listOut as? [Any]
check(list?.first as? String == "center-third", "NSArray primeiro")
check(list?.last as? String == "auto", "NSArray segundo")

if !failures.isEmpty {
    for failure in failures {
        print("FAIL \(failure)")
    }
    print("\(failures.count) falhas, \(passed) ok")
    exit(1)
}
print("OK \(passed)")
}
}
