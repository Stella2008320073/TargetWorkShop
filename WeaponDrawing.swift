import SwiftUI

struct WeaponGraphic: View {
    let weapon: Weapon
    let config: WeaponConfig
    let scale: CGFloat
    var body: some View {
        Canvas { ctx, size in
            draw(ctx: &ctx, size: size)
        }
        .frame(width: size.width, height: size.height)
        .scaleEffect(scale)
        .drawingGroup()
    }
    private var size: CGSize { CGSize(width: 520, height: 220) }

    private func part(_ slot: String) -> Attachment? {
        guard let pid = config.parts[slot] else { return nil }
        return weapon.slotAttachments[slot]?.first { $0.id == pid }
    }
    private func variant(_ slot: String) -> Int { part(slot)?.visualVariant ?? 0 }

    private func draw(ctx: inout GraphicsContext, size: CGSize) {
        let v = weapon.visual
        let centerY = size.height * 0.55
        let metal = Color(white: 0.62)
        let dark = Color(white: 0.25)
        switch v.bodyStyle {
        case 8: drawMelee(ctx: &ctx, size: size, v: v)
        case 2: drawPistol(ctx: &ctx, size: size, v: v, metal: metal, dark: dark)
        case 3: drawShotgun(ctx: &ctx, size: size, v: v, metal: metal, dark: dark)
        case 4: drawSMG(ctx: &ctx, size: size, v: v, metal: metal, dark: dark)
        case 5,6,7: drawSpecial(ctx: &ctx, size: size, v: v, metal: metal, dark: dark)
        default: drawRifle(ctx: &ctx, size: size, v: v, metal: metal, dark: dark)
        }
        _ = centerY
    }

    private func drawRifle(ctx: inout GraphicsContext, size: CGSize, v: WeaponVisual, metal: Color, dark: Color) {
        let cy = size.height * 0.5
        let startX = size.width * 0.15
        let bodyW = size.width * 0.34
        let barrelLen = size.width * 0.28 * v.barrelLen / 0.45
        // 枪身
        let body = Path(roundedRect: CGRect(x: startX, y: cy - 14, width: bodyW, height: 28), cornerRadius: 4)
        ctx.fill(body, with: .linearGradient(Gradient(colors: [metal, dark]), startPoint: .init(x: startX, y: cy-14), endPoint: .init(x: startX+bodyW, y: cy+14)))
        // 枪管
        let barrel = Path(CGRect(x: startX + bodyW, y: cy - 5, width: barrelLen, height: 10))
        ctx.fill(barrel, with: .color(metal))
        // 枪口
        let muzzleV = variant("muzzle")
        let muzzle = Path(CGRect(x: startX + bodyW + barrelLen, y: cy - 7 - CGFloat(muzzleV)*2, width: 14, height: 14 + CGFloat(muzzleV)*4))
        ctx.fill(muzzle, with: .color(dark))
        // 弹匣
        let magV = variant("mag")
        if magV >= 0 {
            let mh = 30.0 + Double(magV) * 8
            let mag = Path(roundedRect: CGRect(x: startX + bodyW*0.45, y: cy+14, width: 18 + CGFloat(magV)*3, height: mh), cornerRadius: 3)
            ctx.fill(mag, with: .color(dark))
        }
        // 枪托
        if v.stockStyle > 0 {
            let sw = v.stockStyle == 3 ? 30.0 : 42.0
            let stock = Path(CGRect(x: startX - sw, y: cy - 10, width: sw, height: 20))
            ctx.fill(stock, with: .color(metal.opacity(0.8)))
        }
        // 瞄具
        if v.scopeStyle > 0 {
            let sh = v.scopeStyle == 2 ? 14.0 : 8.0
            let scope = Path(roundedRect: CGRect(x: startX + bodyW*0.5, y: cy - 14 - sh, width: 60, height: sh), cornerRadius: 3)
            ctx.fill(scope, with: .color(.cyan.opacity(0.5)))
        }
        // 握把
        let grip = Path(roundedRect: CGRect(x: startX + bodyW*0.35, y: cy+12, width: 16, height: 34), cornerRadius: 4)
        ctx.fill(grip, with: .color(dark))
        // 高光
        var hl = Path(); hl.move(to: .init(x: startX, y: cy-12)); hl.addLine(to: .init(x: startX+bodyW, y: cy-12))
        ctx.stroke(hl, with: .color(.white.opacity(0.25)), lineWidth: 1)
    }

    private func drawPistol(ctx: inout GraphicsContext, size: CGSize, v: WeaponVisual, metal: Color, dark: Color) {
        let cy = size.height * 0.5
        let x = size.width * 0.35
        let body = Path(roundedRect: CGRect(x: x, y: cy-12, width: 110, height: 24), cornerRadius: 3)
        ctx.fill(body, with: .linearGradient(Gradient(colors: [metal, dark]), startPoint: .init(x: x, y: cy-12), endPoint: .init(x: x+110, y: cy+12)))
        let barrel = Path(CGRect(x: x+110, y: cy-4, width: 30 + CGFloat(v.barrelLen)*20, height: 8))
        ctx.fill(barrel, with: .color(metal))
        let grip = Path(roundedRect: CGRect(x: x+20, y: cy+10, width: 26, height: 50), cornerRadius: 5)
        ctx.fill(grip, with: .color(dark))
        // 弹匣/弹巢
        if v.magStyle == 4 {
            let cyl = Path(ellipseIn: CGRect(x: x+55, y: cy-2, width: 26, height: 26))
            ctx.fill(cyl, with: .color(metal))
        } else if v.magStyle > 0 {
            let mag = Path(CGRect(x: x+24, y: cy+56, width: 18, height: 20))
            ctx.fill(mag, with: .color(dark))
        }
        let scope = Path(CGRect(x: x+70, y: cy-18, width: 34, height: 6))
        ctx.fill(scope, with: .color(.cyan.opacity(0.5)))
    }

    private func drawShotgun(ctx: inout GraphicsContext, size: CGSize, v: WeaponVisual, metal: Color, dark: Color) {
        let cy = size.height * 0.5
        let x = size.width * 0.2
        let body = Path(roundedRect: CGRect(x: x, y: cy-12, width: 150, height: 24), cornerRadius: 4)
        ctx.fill(body, with: .linearGradient(Gradient(colors: [metal, dark]), startPoint: .init(x: x, y: cy-12), endPoint: .init(x: x+150, y: cy+12)))
        let barrel = Path(CGRect(x: x+150, y: cy-6, width: 90, height: 12))
        ctx.fill(barrel, with: .color(metal))
        // 泵动护木
        if v.stockStyle != 3 {
            let pump = Path(roundedRect: CGRect(x: x+120, y: cy+6, width: 34, height: 14), cornerRadius: 3)
            ctx.fill(pump, with: .color(dark))
        }
        let stock = Path(CGRect(x: x-36, y: cy-8, width: 36, height: 18))
        ctx.fill(stock, with: .color(metal.opacity(0.8)))
        if v.magStyle == 3 {
            let drum = Path(ellipseIn: CGRect(x: x+60, y: cy+10, width: 34, height: 34))
            ctx.fill(drum, with: .color(dark))
        }
    }

    private func drawSMG(ctx: inout GraphicsContext, size: CGSize, v: WeaponVisual, metal: Color, dark: Color) {
        let cy = size.height * 0.5
        let x = size.width * 0.3
        let body = Path(roundedRect: CGRect(x: x, y: cy-10, width: 100, height: 20), cornerRadius: 3)
        ctx.fill(body, with: .linearGradient(Gradient(colors: [metal, dark]), startPoint: .init(x: x, y: cy-10), endPoint: .init(x: x+100, y: cy+10)))
        let barrel = Path(CGRect(x: x+100, y: cy-4, width: 46, height: 8))
        ctx.fill(barrel, with: .color(metal))
        let grip = Path(roundedRect: CGRect(x: x+30, y: cy+8, width: 16, height: 40), cornerRadius: 4)
        ctx.fill(grip, with: .color(dark))
        let mag = Path(CGRect(x: x+18, y: cy+12, width: 14, height: 46))
        ctx.fill(mag, with: .color(dark))
        if v.stockStyle == 2 {
            let stock = Path(CGRect(x: x-28, y: cy-6, width: 28, height: 12))
            ctx.fill(stock, with: .color(metal.opacity(0.7)))
        }
    }

    private func drawSpecial(ctx: inout GraphicsContext, size: CGSize, v: WeaponVisual, metal: Color, dark: Color) {
        let cy = size.height * 0.5
        if v.bodyStyle == 7 {
            let x = size.width * 0.25
            let body = Path(roundedRect: CGRect(x: x, y: cy-16, width: 140, height: 32), cornerRadius: 6)
            ctx.fill(body, with: .linearGradient(Gradient(colors: [metal, dark]), startPoint: .init(x: x, y: cy-16), endPoint: .init(x: x+140, y: cy+16)))
            let crystal = Path(ellipseIn: CGRect(x: x+130, y: cy-8, width: 30, height: 16))
            ctx.fill(crystal, with: .color(.cyan.opacity(0.7)))
            let battery = Path(CGRect(x: x+10, y: cy+16, width: 36, height: 18))
            ctx.fill(battery, with: .color(dark))
        } else {
            let x = size.width * 0.2
            let tube = Path(roundedRect: CGRect(x: x, y: cy-20, width: 200, height: 40), cornerRadius: 20)
            ctx.fill(tube, with: .linearGradient(Gradient(colors: [metal, dark]), startPoint: .init(x: x, y: cy-20), endPoint: .init(x: x+200, y: cy+20)))
            let back = Path(CGRect(x: x-30, y: cy-12, width: 32, height: 24))
            ctx.fill(back, with: .color(dark))
            if v.magStyle == 3 {
                let drum = Path(ellipseIn: CGRect(x: x+50, y: cy+16, width: 40, height: 40))
                ctx.fill(drum, with: .color(dark))
            }
        }
    }

    private func drawMelee(ctx: inout GraphicsContext, size: CGSize, v: WeaponVisual) {
        let cy = size.height * 0.5
        let x = size.width * 0.35
        let bladeLen = size.width * 0.32 * v.barrelLen / 0.4
        let tipY = cy - CGFloat(v.bladeStyle == 1 ? 20 : 0)
        var blade = Path()
        blade.move(to: .init(x: x, y: cy-10))
        blade.addLine(to: .init(x: x+bladeLen, y: cy-10+tipY))
        blade.addLine(to: .init(x: x+bladeLen*0.95, y: cy+10+tipY))
        blade.addLine(to: .init(x: x, y: cy+10))
        blade.closeSubpath()
        ctx.fill(blade, with: .linearGradient(Gradient(colors: [Color(white:0.8), Color(white:0.5)]), startPoint: .init(x: x, y: cy), endPoint: .init(x: x+bladeLen, y: cy)))
        // 能量导槽
        var glow = Path()
        glow.move(to: .init(x: x+8, y: cy-2))
        glow.addLine(to: .init(x: x+bladeLen*0.9, y: cy-2+tipY*0.8))
        ctx.stroke(glow, with: .color(.cyan.opacity(0.8)), lineWidth: 2)
        // 护手
        let guard = Path(roundedRect: CGRect(x: x-8, y: cy-16, width: 10, height: 32), cornerRadius: 2)
        ctx.fill(guard, with: .color(Color(white:0.3)))
        // 握柄
        let handle = Path(roundedRect: CGRect(x: x-70, y: cy-8, width: 62, height: 16), cornerRadius: 4)
        ctx.fill(handle, with: .color(Color(white:0.2)))
        for i in 0..<4 {
            let seg = Path(CGRect(x: x-66+CGFloat(i)*14, y: cy-8, width: 2, height: 16))
            ctx.fill(seg, with: .color(.cyan.opacity(0.3)))
        }
    }
}