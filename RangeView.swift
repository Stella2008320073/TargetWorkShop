import SwiftUI
import AppKit

struct RangeView: View {
    @EnvironmentObject var app: AppState
    @StateObject private var engine = RangeEngine()

    var body: some View {
        ZStack {
            RangeSceneView(engine: engine)
            RangeHUD(engine: engine)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        engine.exit(app: app)
                    } label: {
                        Text("退出靶场（双击 ESC）").frame(width: 220, height: 40)
                    }
                    .buttonStyle(MilButtonStyle())
                    .padding(.trailing, 24).padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            if let id = app.returnWeaponID ?? app.selectedWeaponID, let w = app.weapon(id) {
                engine.load(weapon: w, stats: app.stats(for: w), config: app.config(for: w.id))
            }
        }
        .background(Color.black)
    }
}

// MARK: - 引擎
final class RangeEngine: ObservableObject {
    @Published var weapon: Weapon?
    @Published var stats: WeaponStats = WeaponStats()
    @Published var fireMode: FireMode = .semiAuto
    @Published var ammo: Int = 0
    @Published var magSize: Int = 1
    @Published var reloading = false
    @Published var reloadRemaining: Double = 0
    @Published var reloadTotal: Double = 1
    @Published var recoil: CGFloat = 0
    @Published var spread: CGFloat = 8
    @Published var muzzleFlash: Double = 0
    @Published var shells: [Shell] = []
    @Published var holes: [Hole] = []
    @Published var lastHole: CGPoint = .zero
    @Published var message: String = ""
    @Published var actionTimer: Double = 0     // 栓动/泵动/单发冷却
    @Published var meleeSwing: Double = 0
    @Published var hitFlash: Double = 0
    @Published var hitPart: String = ""
    @Published var shotsFired = 0
    @Published var hits = 0

    private var displayLink: CVDisplayLink?
    private var lastTime = Date()
    private var lastESCTime: Date = .distantPast
    private var autoFireHeld = false
    private var timer: Timer?

    struct Shell: Identifiable { let id = UUID(); var x: CGFloat; var y: CGFloat; var vx: CGFloat; var vy: CGFloat; var life: Double }
    struct Hole: Identifiable { let id = UUID(); var pos: CGPoint; var ring: Int }

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func load(weapon: Weapon, stats: WeaponStats, config: WeaponConfig) {
        self.weapon = weapon
        self.stats = stats
        self.fireMode = config.fireMode ?? weapon.defaultMode
        self.magSize = stats.mag
        self.ammo = stats.mag
        self.reloading = false
        self.message = ""
        self.holes = []
        self.shells = []
        self.shotsFired = 0
        self.hits = 0
        lastTime = Date()
    }

    func exit(app: AppState) {
        app.screen = .workshop
        app.selectedWeaponID = app.returnWeaponID ?? app.selectedWeaponID
        app.returnWeaponID = nil
        app.selectedSlotID = nil
    }

    // 由视图调用：按下开火
    func beginFire() {
        autoFireHeld = true
        tryFire()
    }
    func endFire() { autoFireHeld = false }

    func reload() {
        guard !reloading, ammo < magSize, let w = weapon else { return }
        if w.category == .melee { return }
        reloading = true
        reloadTotal = stats.reload
        reloadRemaining = stats.reload
        message = "换弹中"
    }

    func handleESC() {
        let now = Date()
        if now.timeIntervalSince(lastESCTime) < 0.6 {
            if let app = appRef { exit(app: app) }
        }
        lastESCTime = now
    }
    var appRef: AppState?

    private func tryFire() {
        guard let w = weapon, !reloading else { return }
        if w.category == .melee {
            swing()
            return
        }
        if actionTimer > 0 { return }
        if ammo <= 0 {
            reload()
            return
        }
        ammo -= 1
        shotsFired += 1
        muzzleFlash = 0.08
        recoil += CGFloat(stats.recoil / 20)
        spread = min(40, spread + CGFloat(stats.recoil / 10))
        spawnShell()
        // 命中判定
        let jitter = Double(spread) / 400.0
        let hitRoll = Double.random(in: 0...1)
        if hitRoll < 0.75 {
            hits += 1
            let ring = Int.random(in: 1...10)
            let cx = CGFloat.random(in: -jitter...jitter)
            let cy = CGFloat.random(in: -jitter...jitter)
            lastHole = CGPoint(x: 0.5 + cx, y: 0.5 + cy)
            holes.append(Hole(pos: lastHole, ring: ring))
            hitFlash = 0.15
            hitPart = ["头部","躯干","左臂","右臂","腿部"].randomElement() ?? "躯干"
            message = "命中 \(hitPart)  环数 \(ring)"
        } else {
            message = "未命中"
        }
        // 射击节奏
        switch fireMode {
        case .fullAuto:
            actionTimer = 60.0 / max(60, stats.fireRate)
        case .semiAuto, .singleShot:
            actionTimer = 0.12
        case .boltAction:
            actionTimer = 0.9
        case .pumpAction:
            actionTimer = 0.85
        case .burst:
            actionTimer = 60.0 / max(60, stats.fireRate) * 2
            burstFire(count: 2)
        case .melee:
            break
        }
        if fireMode == .singleShot { actionTimer = max(0.6, stats.reload * 0.6) }
    }

    private func burstFire(count: Int) {
        var remaining = count
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] t in
            guard let self = self, remaining > 0 else { t.invalidate(); return }
            if self.ammo > 0 { self.ammo -= 1; self.shotsFired += 1; self.muzzleFlash = 0.06; self.spawnShell() }
            remaining -= 1
        }
    }

    private func swing() {
        if actionTimer > 0 { return }
        actionTimer = 60.0 / max(30, stats.meleeSpeed)
        meleeSwing = 0.4
        // 近战命中
        if Double.random(in: 0...1) < 0.8 {
            hits += 1
            hitFlash = 0.15
            hitPart = ["头部","躯干","手臂"].randomElement() ?? "躯干"
            message = "挥砍命中 \(hitPart)  穿透 \(Int(stats.penetration))"
            holes.append(Hole(pos: CGPoint(x: 0.5, y: 0.5), ring: 10))
        } else {
            message = "挥砍未命中"
        }
    }

    private func spawnShell() {
        shells.append(Shell(x: 0, y: 0, vx: CGFloat.random(in: 40...100), vy: -CGFloat.random(in: 80...140), life: 1.0))
    }

    private func tick() {
        let now = Date()
        let dt = min(0.05, now.timeIntervalSince(lastTime))
        lastTime = now
        if actionTimer > 0 { actionTimer -= dt }
        if muzzleFlash > 0 { muzzleFlash -= dt }
        if hitFlash > 0 { hitFlash -= dt }
        if meleeSwing > 0 { meleeSwing -= dt }
        recoil = max(0, recoil - CGFloat(dt * 60))
        spread = max(8, spread - CGFloat(dt * 40))
        if reloading {
            reloadRemaining -= dt
            if reloadRemaining <= 0 {
                reloading = false
                ammo = magSize
                message = "换弹完成"
            }
        }
        // 全自动持续射击
        if autoFireHeld && fireMode == .fullAuto && actionTimer <= 0 {
            tryFire()
        }
        // 弹壳运动
        for i in shells.indices {
            shells[i].x += shells[i].vx * CGFloat(dt)
            shells[i].y += shells[i].vy * CGFloat(dt)
            shells[i].vy += 400 * CGFloat(dt)
            shells[i].life -= dt
        }
        shells.removeAll { $0.life <= 0 }
    }
}

// MARK: - 场景绘制
struct RangeSceneView: View {
    @ObservedObject var engine: RangeEngine
    var body: some View {
        Canvas { ctx, size in
            drawRange(ctx: &ctx, size: size)
        }
        .background(Color(white: 0.02))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in engine.beginFire() }
                .onEnded { _ in engine.endFire() }
        )
        .onAppear { engine.beginLoopIfNeeded() }
        .onExitCommand { engine.handleESC() }
    }

    private func drawRange(ctx: inout GraphicsContext, size: CGSize) {
        let horizon = size.height * 0.52
        // 地面
        var floor = Path()
        floor.addRect(CGRect(x: 0, y: horizon, width: size.width, height: size.height - horizon))
        ctx.fill(floor, with: .linearGradient(Gradient(colors: [Color(white: 0.06), Color(white: 0.02)]), startPoint: .init(x: 0, y: horizon), endPoint: .init(x: 0, y: size.height)))
        // 透视网格
        var grid = Path()
        for i in 0...20 {
            let x = size.width * CGFloat(i) / 20
            grid.move(to: .init(x: x, y: horizon))
            grid.addLine(to: .init(x: (x - size.width/2) * 2.5 + size.width/2, y: size.height))
        }
        for j in 0...8 {
            let t = CGFloat(j) / 8
            let y = horizon + (size.height - horizon) * t * t
            grid.move(to: .init(x: 0, y: y)); grid.addLine(to: .init(x: size.width, y: y))
        }
        ctx.stroke(grid, with: .color(.cyan.opacity(0.08)), lineWidth: 0.6)
        // 靶纸位（多个距离）
        let targets = [0.18, 0.34, 0.52, 0.7]
        for (i, tx) in targets.enumerated() {
            let cx = size.width * tx
            let cy = horizon - size.height * 0.08 + CGFloat(i) * 2
            let w = 70 - CGFloat(i) * 8
            let h = 110 - CGFloat(i) * 12
            var t = Path(roundedRect: CGRect(x: cx - w/2, y: cy - h/2, width: w, height: h), cornerRadius: 3)
            ctx.fill(t, with: .color(Color(white: 0.85)))
            t = Path(ellipseIn: CGRect(x: cx - w/4, y: cy - h/4, width: w/2, height: h/2))
            ctx.stroke(t, with: .color(.red.opacity(0.6)), lineWidth: 1)
            // 弹孔
            for hole in engine.holes {
                let hx = cx - w/2 + w * hole.pos.x
                let hy = cy - h/2 + h * hole.pos.y
                let dot = Path(ellipseIn: CGRect(x: hx-1.5, y: hy-1.5, width: 3, height: 3))
                ctx.fill(dot, with: .color(.black))
            }
            // 距离标注
            let label = Text("\([25,50,100,150][i])m").font(.system(size: 9, design: .monospaced)).foregroundColor(.gray)
            ctx.draw(label, at: CGPoint(x: cx, y: cy + h/2 + 8))
        }
        // 人形靶
        drawDummy(ctx: &ctx, size: size)
        // 第一人称手持武器
        drawFirstPersonWeapon(ctx: &ctx, size: size)
        // 准星
        drawCrosshair(ctx: &ctx, size: size)
        // 枪口火焰
        if engine.muzzleFlash > 0 {
            let flash = Path(ellipseIn: CGRect(x: size.width/2 - 20, y: size.height*0.62 - 20, width: 40, height: 40))
            ctx.fill(flash, with: .color(.orange.opacity(0.6)))
        }
        // 弹壳
        for shell in engine.shells {
            let p = Path(ellipseIn: CGRect(x: size.width*0.55 + shell.x, y: size.height*0.62 + shell.y, width: 4, height: 2))
            ctx.fill(p, with: .color(.yellow.opacity(shell.life)))
        }
    }

    private func drawDummy(ctx: inout GraphicsContext, size: CGSize) {
        let cx = size.width * 0.42
        let baseY = size.height * 0.44
        let s = size.height * 0.18
        // 头
        var head = Path(ellipseIn: CGRect(x: cx - s*0.12, y: baseY - s*0.5, width: s*0.24, height: s*0.24))
        ctx.fill(head, with: .color(Color(white: 0.4)))
        // 躯干
        var body = Path(roundedRect: CGRect(x: cx - s*0.22, y: baseY - s*0.28, width: s*0.44, height: s*0.6), cornerRadius: 6)
        ctx.fill(body, with: .color(Color(white: 0.35)))
        // 手臂
        var arm = Path(CGRect(x: cx - s*0.4, y: baseY - s*0.26, width: s*0.16, height: s*0.5))
        ctx.fill(arm, with: .color(Color(white: 0.33)))
        arm = Path(CGRect(x: cx + s*0.24, y: baseY - s*0.26, width: s*0.16, height: s*0.5))
        ctx.fill(arm, with: .color(Color(white: 0.33)))
        // 腿
        var leg = Path(CGRect(x: cx - s*0.18, y: baseY + s*0.32, width: s*0.14, height: s*0.4))
        ctx.fill(leg, with: .color(Color(white: 0.3)))
        leg = Path(CGRect(x: cx + s*0.04, y: baseY + s*0.32, width: s*0.14, height: s*0.4))
        ctx.fill(leg, with: .color(Color(white: 0.3)))
        // 命中闪光
        if engine.hitFlash > 0 {
            let flash = Path(ellipseIn: CGRect(x: cx - s*0.1, y: baseY - s*0.05, width: s*0.2, height: s*0.2))
            ctx.fill(flash, with: .color(.red.opacity(engine.hitFlash * 4)))
        }
    }

    private func drawFirstPersonWeapon(ctx: inout GraphicsContext, size: CGSize) {
        guard let w = engine.weapon else { return }
        let baseX = size.width * 0.55
        let baseY = size.height * 0.72 + engine.recoil
        // 手部
        var hand = Path(roundedRect: CGRect(x: baseX - 90, y: baseY + 30, width: 160, height: 60), cornerRadius: 20)
        ctx.fill(hand, with: .linearGradient(Gradient(colors: [Color(red: 0.55, green: 0.4, blue: 0.3), Color(red: 0.4, green: 0.28, blue: 0.2)]), startPoint: .init(x: baseX, y: baseY), endPoint: .init(x: baseX, y: baseY+90)))
        // 枪身
        var gun = Path(roundedRect: CGRect(x: baseX - 120, y: baseY - 20, width: 260, height: 44), cornerRadius: 6)
        ctx.fill(gun, with: .linearGradient(Gradient(colors: [Color(white: 0.5), Color(white: 0.2)]), startPoint: .init(x: baseX, y: baseY-20), endPoint: .init(x: baseX, y: baseY+24)))
        // 枪管
        var barrel = Path(CGRect(x: baseX + 140, y: baseY - 6, width: 120 * w.visual.barrelLen / 0.45, height: 12))
        ctx.fill(barrel, with: .color(Color(white: 0.45)))
        // 瞄具
        if w.visual.scopeStyle > 0 {
            var scope = Path(roundedRect: CGRect(x: baseX + 30, y: baseY - 36, width: 80, height: 16), cornerRadius: 3)
            ctx.fill(scope, with: .color(.cyan.opacity(0.5)))
        }
        // 近战刀
        if w.category == .melee {
            var blade = Path()
            blade.move(to: .init(x: baseX - 120, y: baseY))
            blade.addLine(to: .init(x: baseX + 180, y: baseY - 40 + CGFloat(engine.meleeSwing) * 100))
            blade.addLine(to: .init(x: baseX + 180, y: baseY - 20 + CGFloat(engine.meleeSwing) * 100))
            blade.addLine(to: .init(x: baseX - 120, y: baseY + 20))
            blade.closeSubpath()
            ctx.fill(blade, with: .linearGradient(Gradient(colors: [Color(white: 0.8), Color(white: 0.4)]), startPoint: .init(x: baseX, y: baseY), endPoint: .init(x: baseX+180, y: baseY)))
        }
    }

    private func drawCrosshair(ctx: inout GraphicsContext, size: CGSize) {
        let cx = size.width * 0.5
        let cy = size.height * 0.42
        let s = engine.spread
        var p = Path()
        p.move(to: .init(x: cx - s, y: cy)); p.addLine(to: .init(x: cx + s, y: cy))
        p.move(to: .init(x: cx, y: cy - s)); p.addLine(to: .init(x: cx, y: cy + s))
        ctx.stroke(p, with: .color(.orange.opacity(0.8)), lineWidth: 1.2)
    }
}

// MARK: - HUD
struct RangeHUD: View {
    @ObservedObject var engine: RangeEngine
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("射击模式：\(engine.fireMode.rawValue)")
                    Text("弹药：\(engine.ammo) / \(engine.magSize)")
                    Text("射击：\(engine.shotsFired)  命中：\(engine.hits)")
                    if !engine.message.isEmpty { Text(engine.message).foregroundColor(.orange) }
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.cyan)
                .padding(10)
                .background(Color.black.opacity(0.5))
                Spacer()
            }
            .padding(14)
            Spacer()
            if engine.reloading {
                VStack(spacing: 4) {
                    Text(String(format: "换弹中 %.1f 秒", max(0, engine.reloadRemaining)))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                    ProgressView(value: 1.0 - engine.reloadRemaining / engine.reloadTotal)
                        .frame(width: 260)
                        .tint(.orange)
                }
                .padding(12)
                .background(Color.black.opacity(0.6))
                .padding(.bottom, 80)
            }
        }
    }
}