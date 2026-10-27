import SwiftUI

struct WorkshopView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        HStack(spacing: 0) {
            CategorySidebar()
            Divider().overlay(Color.orange.opacity(0.15))
            WeaponListColumn()
            Divider().overlay(Color.orange.opacity(0.15))
            WeaponDetailColumn()
        }
        .background(LineBackground())
    }
}

// MARK: - 左侧分类
struct CategorySidebar: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        VStack(spacing: 0) {
            Text("武器分类")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16).padding(.vertical, 14)
            Divider().overlay(Color.orange.opacity(0.2))
            VStack(spacing: 0) {
                ForEach(WeaponCategory.allCases) { cat in
                    CategoryRow(cat: cat)
                    if cat != WeaponCategory.allCases.last {
                        Divider().overlay(Color.orange.opacity(0.12))
                    }
                }
            }
            Spacer(minLength: 0)
            Divider().overlay(Color.orange.opacity(0.2))
            VStack(spacing: 10) {
                Button { app.screen = .lobby } label: { Text("返回大厅").frame(maxWidth: .infinity) }
                    .buttonStyle(MilButtonStyle())
                Button { app.settingsOpen = true } label: { Text("设置").frame(maxWidth: .infinity) }
                    .buttonStyle(MilButtonStyle())
            }
            .padding(12)
        }
        .frame(width: 224)
        .background(Color(white: 0.055))
    }
}

struct CategoryRow: View {
    @EnvironmentObject var app: AppState
    let cat: WeaponCategory
    private var count: Int { app.weapons.filter { $0.category == cat }.count }
    private var selected: Bool { app.selectedCategory == cat }
    var body: some View {
        Button {
            app.selectedCategory = cat
        } label: {
            HStack(spacing: 10) {
                CategoryIcon(cat: cat)
                    .frame(width: 30, height: 24)
                    .foregroundColor(selected ? .orange : Color(white: 0.55))
                Text(cat.rawValue)
                    .font(.system(size: 15, weight: selected ? .bold : .regular, design: .monospaced))
                    .foregroundColor(selected ? .orange : Color(white: 0.8))
                Spacer()
                Text("\(count)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
            }
            .padding(.horizontal, 14)
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(selected ? Color.orange.opacity(0.08) : Color.clear)
            .overlay(alignment: .leading) {
                if selected { Rectangle().fill(Color.orange).frame(width: 3) }
            }
        }
        .buttonStyle(.plain)
    }
}

// 线条分类图标（无 emoji）
struct CategoryIcon: View {
    let cat: WeaponCategory
    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            let w = size.width, h = size.height
            switch cat {
            case .sniper:
                p.move(to: .init(x: 2, y: h*0.5)); p.addLine(to: .init(x: w-6, y: h*0.5))
                p.addRect(.init(x: 4, y: h*0.3, width: w*0.3, height: h*0.3))
                p.addRect(.init(x: w*0.4, y: h*0.1, width: w*0.3, height: h*0.15))
            case .rifle:
                p.move(to: .init(x: 2, y: h*0.5)); p.addLine(to: .init(x: w-4, y: h*0.5))
                p.addRect(.init(x: 4, y: h*0.35, width: w*0.35, height: h*0.25))
                p.addRect(.init(x: w*0.4, y: h*0.6, width: w*0.15, height: h*0.3))
            case .smg:
                p.addRect(.init(x: 4, y: h*0.35, width: w*0.45, height: h*0.25))
                p.move(to: .init(x: w*0.5, y: h*0.5)); p.addLine(to: .init(x: w-4, y: h*0.5))
                p.addRect(.init(x: w*0.2, y: h*0.6, width: w*0.12, height: h*0.3))
            case .pistol:
                p.addRect(.init(x: 4, y: h*0.35, width: w*0.55, height: h*0.2))
                p.addRect(.init(x: w*0.15, y: h*0.55, width: w*0.15, height: h*0.35))
            case .shotgun:
                p.addRect(.init(x: 2, y: h*0.4, width: w*0.75, height: h*0.15))
                p.addRect(.init(x: w*0.2, y: h*0.55, width: w*0.2, height: h*0.12))
                p.addRect(.init(x: w*0.8, y: h*0.45, width: w*0.12, height: h*0.18))
            case .special:
                p.addEllipse(in: .init(x: 2, y: h*0.25, width: w-4, height: h*0.5))
                p.addRect(.init(x: w*0.15, y: h*0.55, width: w*0.18, height: h*0.3))
            case .melee:
                p.move(to: .init(x: 2, y: h*0.55))
                p.addLine(to: .init(x: w*0.75, y: h*0.2))
                p.addLine(to: .init(x: w*0.8, y: h*0.3))
                p.addLine(to: .init(x: w*0.1, y: h*0.65))
                p.closeSubpath()
                p.addRect(.init(x: w*0.7, y: h*0.25, width: w*0.2, height: h*0.15))
            }
            ctx.stroke(p, with: .color(.current), lineWidth: 1.2)
        }
    }
}

// MARK: - 中间武器列表
struct WeaponListColumn: View {
    @EnvironmentObject var app: AppState
    private var weapons: [Weapon] {
        guard let c = app.selectedCategory else { return [] }
        return app.weapons.filter { $0.category == c }
    }
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(weapons) { w in
                    WeaponCard(weapon: w, selected: app.selectedWeaponID == w.id)
                        .onTapGesture {
                            app.selectedWeaponID = w.id
                            app.selectedSlotID = nil
                        }
                }
            }
            .padding(12)
        }
        .frame(minWidth: 320, maxWidth: 360)
        .background(Color(white: 0.045))
    }
}

struct WeaponCard: View {
    @EnvironmentObject var app: AppState
    let weapon: Weapon
    let selected: Bool
    var body: some View {
        let stats = app.stats(for: weapon)
        HStack(spacing: 12) {
            // 卡片图：小尺寸矢量图
            WeaponGraphic(weapon: weapon, config: app.config(for: weapon.id), scale: 1)
                .frame(width: 120, height: 60)
                .clipped()
                .overlay(Rectangle().stroke(Color.white.opacity(0.08)))
            VStack(alignment: .leading, spacing: 4) {
                Text(weapon.name)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                Text(modeText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(white: 0.6))
                Text(summary(stats))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(10)
        .background(selected ? Color.orange.opacity(0.1) : Color(white: 0.08))
        .overlay(Rectangle().stroke(selected ? Color.orange : Color.white.opacity(0.12), lineWidth: 1))
        .clipShape(CutCorner())
    }
    private var modeText: String {
        weapon.fireModes.map { $0.rawValue }.joined(separator: " / ")
    }
    private func summary(_ s: WeaponStats) -> String {
        if weapon.category == .melee {
            return "挥砍 \(Int(s.meleeSpeed))  范围 \(Int(s.meleeRange))  穿透 \(Int(s.penetration))"
        }
        return "射速 \(Int(s.fireRate))  容量 \(s.mag)  后坐 \(Int(s.recoil))"
    }
}

// MARK: - 右侧改装区
struct WeaponDetailColumn: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        VStack(spacing: 0) {
            if let id = app.selectedWeaponID, let w = app.weapon(id) {
                detail(w)
            } else {
                Spacer()
                Text("请从左侧选择一把武器开始改装")
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundColor(Color(white: 0.5))
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.04))
    }

    private func detail(_ w: Weapon) -> some View {
        let cfg = app.config(for: w.id)
        let slots = app.activeSlots(for: w)
        let stats = app.stats(for: w)
        return VStack(spacing: 0) {
            HStack {
                Text(w.name).font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(.orange)
                Spacer()
                if w.fireModes.count > 1 {
                    Picker("射击模式", selection: Binding(
                        get: { cfg.fireMode ?? w.defaultMode },
                        set: { app.setMode(w.id, $0) }
                    )) {
                        ForEach(w.fireModes) { m in Text(m.rawValue).tag(m) }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 160)
                } else {
                    Text(w.defaultMode.rawValue)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            Divider().overlay(Color.orange.opacity(0.15))

            HStack(spacing: 0) {
                // 预览 + 槽位
                VStack(spacing: 8) {
                    ZStack {
                        GridPreviewBackground()
                        FocusedPreview(weapon: w, slots: slots)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()

                    SlotNodeList(weapon: w, slots: slots)
                }
                .frame(maxWidth: .infinity)

                Divider().overlay(Color.orange.opacity(0.15))

                // 配件 + 属性
                VStack(spacing: 0) {
                    if let sid = app.selectedSlotID,
                       let slot = slots.first(where: { $0.id == sid }) {
                        AttachmentPanel(weapon: w, slot: slot)
                    } else {
                        VStack {
                            Spacer()
                            Text("选中槽位后在此更换配件")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(white: 0.45))
                            Spacer()
                        }
                    }
                    Divider().overlay(Color.orange.opacity(0.15))
                    StatsPanel(weapon: w, stats: stats)
                }
                .frame(width: 340)
            }

            Spacer(minLength: 0)
            HStack {
                Spacer()
                Button {
                    app.returnWeaponID = w.id
                    app.screen = .range
                } label: {
                    Text("进入靶场").frame(width: 180, height: 44)
                }
                .buttonStyle(MilButtonStyle())
            }
            .padding(16)
        }
    }
}

struct GridPreviewBackground: View {
    var body: some View {
        Canvas { ctx, size in
            var p = Path()
            for i in stride(from: 0, through: size.width, by: 24) {
                p.move(to: .init(x: i, y: 0)); p.addLine(to: .init(x: i, y: size.height))
            }
            for j in stride(from: 0, through: size.height, by: 24) {
                p.move(to: .init(x: 0, y: j)); p.addLine(to: .init(x: size.width, y: j))
            }
            ctx.stroke(p, with: .color(.orange.opacity(0.05)), lineWidth: 0.5)
        }
        .background(Color(white: 0.03))
    }
}

// 聚焦预览：选中槽位时旋转缩放
struct FocusedPreview: View {
    @EnvironmentObject var app: AppState
    let weapon: Weapon
    let slots: [SlotDef]
    var body: some View {
        let cfg = app.config(for: weapon.id)
        let slot = slots.first { $0.id == app.selectedSlotID }
        WeaponGraphic(weapon: weapon, config: cfg, scale: 1)
            .scaleEffect(slot?.zoom ?? 1.0)
            .rotation3DEffect(.degrees(slot?.tiltX ?? 0), axis: (x: 1, y: 0, z: 0))
            .rotation3DEffect(.degrees(slot?.tiltY ?? 0), axis: (x: 0, y: 1, z: 0))
            .offset(x: slot?.offsetX ?? 0, y: slot?.offsetY ?? 0)
            .animation(.easeInOut(duration: 0.35), value: app.selectedSlotID)
    }
}

// 槽位节点列表（含锚点连线示意）
struct SlotNodeList: View {
    @EnvironmentObject var app: AppState
    let weapon: Weapon
    let slots: [SlotDef]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(slots) { s in
                    Button {
                        app.selectedSlotID = (app.selectedSlotID == s.id) ? nil : s.id
                    } label: {
                        VStack(spacing: 3) {
                            Text(s.name)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            Text(partName(s))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(Color(white: 0.5))
                        }
                        .foregroundColor(app.selectedSlotID == s.id ? .black : .orange)
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(app.selectedSlotID == s.id ? Color.orange : Color(white: 0.1))
                        .overlay(CutCorner().stroke(Color.orange.opacity(0.6), lineWidth: 1))
                        .clipShape(CutCorner())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: 70)
    }
    private func partName(_ s: SlotDef) -> String {
        let cfg = app.config(for: weapon.id)
        guard let pid = cfg.parts[s.id],
              let p = weapon.slotAttachments[s.id]?.first(where: { $0.id == pid }) else { return "未安装" }
        return p.name
    }
}

struct AttachmentPanel: View {
    @EnvironmentObject var app: AppState
    let weapon: Weapon
    let slot: SlotDef
    var body: some View {
        let parts = weapon.slotAttachments[slot.id] ?? []
        let current = app.config(for: weapon.id).parts[slot.id]
        VStack(alignment: .leading, spacing: 6) {
            Text("\(slot.name) 配件").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(.orange)
                .padding(.horizontal, 12).padding(.top, 10)
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(parts) { p in
                        Button {
                            app.setPart(weaponID: weapon.id, slotID: slot.id, partID: p.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(p.name).font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    Spacer()
                                    if current == p.id {
                                        Text("已装").font(.system(size: 10, design: .monospaced)).foregroundColor(.green)
                                    }
                                }
                                Text(p.desc).font(.system(size: 10, design: .monospaced)).foregroundColor(Color(white: 0.5))
                                Text(effectText(p)).font(.system(size: 10, design: .monospaced)).foregroundColor(.cyan)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(current == p.id ? Color.orange.opacity(0.12) : Color(white: 0.08))
                            .overlay(Rectangle().stroke(current == p.id ? Color.orange : Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12).padding(.bottom, 10)
            }
        }
    }
    private func effectText(_ p: Attachment) -> String {
        var parts: [String] = []
        func add(_ name: String, _ v: Double) {
            if v != 0 { parts.append("\(name) \(v > 0 ? "+" : "")\(String(format: "%.1f", v))") }
        }
        add("后坐", p.recoil); add("稳定", p.stability); add("操控", p.handling)
        add("射速", p.fireRate); add("射程", p.range); add("初速", p.muzzleVelocity)
        if p.magCapacity != 0 { parts.append("容量 \(p.magCapacity > 0 ? "+" : "")\(p.magCapacity)") }
        if p.reloadSpeed != 0 { parts.append("换弹 \(String(format: "%+.2f", p.reloadSpeed))") }
        add("挥砍", p.meleeSpeed); add("范围", p.meleeRange); add("穿透", p.penetration)
        return parts.joined(separator: "  ")
    }
}

struct StatsPanel: View {
    let weapon: Weapon
    let stats: WeaponStats
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("属性").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(.orange)
            if weapon.category == .melee {
                statRow("挥砍速度", stats.meleeSpeed)
                statRow("攻击范围", stats.meleeRange)
                statRow("穿透力", stats.penetration)
                statRow("配重平衡", stats.balance)
            } else {
                statRow("后坐力控制", stats.recoil)
                statRow("据枪稳定性", stats.stability)
                statRow("操控速度", stats.handling)
                statRow("腰际精度", stats.hip)
                statRow("枪口初速", stats.velocity)
                statRow("优势射程", stats.range)
                statRow("射速", stats.fireRate)
                HStack { Text("弹匣容量").font(.system(size: 11, design: .monospaced)); Spacer(); Text("\(stats.mag)").font(.system(size: 11, design: .monospaced)).foregroundColor(.cyan) }
                HStack { Text("换弹时长").font(.system(size: 11, design: .monospaced)); Spacer(); Text(String(format: "%.2f 秒", stats.reload)).font(.system(size: 11, design: .monospaced)).foregroundColor(.cyan) }
            }
        }
        .padding(12)
    }
    private func statRow(_ name: String, _ v: Double) -> some View {
        HStack(spacing: 8) {
            Text(name).font(.system(size: 11, design: .monospaced)).frame(width: 90, alignment: .leading)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.white.opacity(0.08))
                    Rectangle().fill(Color.orange.opacity(0.7))
                        .frame(width: max(0, min(1, v/100)) * g.size.width)
                }
            }.frame(height: 6)
            Text("\(Int(v))").font(.system(size: 10, design: .monospaced)).frame(width: 32, alignment: .trailing)
        }
    }
}

extension AppState {
    func setMode(_ weaponID: String, _ mode: FireMode) {
        var c = config(for: weaponID)
        c.fireMode = mode
        configs[weaponID] = c
    }
}