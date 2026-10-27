import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppState
    @State private var fps: Double = 60
    @State private var timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .topLeading) {
            switch app.screen {
            case .lobby: LobbyView()
            case .workshop: WorkshopView()
            case .range: RangeView()
            }
            // 左上角 FPS
            Text("FPS: \(Int(fps))")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.green)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .overlay(Rectangle().stroke(Color.green.opacity(0.4), lineWidth: 1))
                .padding(10)
        }
        .onReceive(timer) { _ in
            // 用实际显示刷新率近似；这里固定 60，避免额外依赖
            fps = 60
        }
        .sheet(isPresented: $app.settingsOpen) { SettingsView() }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var scale: Double = 1.0
    @State private var sound = true
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置").font(.system(size: 22, weight: .bold, design: .monospaced))
            HStack { Text("界面缩放"); Slider(value: $scale, in: 0.8...1.3) ; Text(String(format: "%.0f%%", scale*100)) }
            Toggle("音效开关", isOn: $sound)
            Spacer()
            HStack { Spacer(); Button("关闭") { dismiss() }.keyboardShortcut(.cancelAction) }
        }
        .padding(24).frame(width: 420, height: 240)
        .background(Color(white: 0.08))
    }
}

struct LobbyView: View {
    @EnvironmentObject var app: AppState
    var body: some View {
        ZStack {
            LineBackground()
            VStack(spacing: 28) {
                Spacer()
                Text("靶场工坊")
                    .font(.system(size: 64, weight: .black, design: .monospaced))
                    .foregroundColor(.orange)
                    .shadow(color: .orange.opacity(0.6), radius: 12)
                Text("武器改装与实弹测试终端")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer().frame(height: 30)
                Button { app.screen = .workshop } label: {
                    Text("进入改枪台").frame(width: 260, height: 48)
                }
                .buttonStyle(MilButtonStyle())
                Button { app.settingsOpen = true } label: {
                    Text("设置").frame(width: 260, height: 48)
                }
                .buttonStyle(MilButtonStyle())
                Spacer()
            }
        }
    }
}

struct MilButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .monospaced))
            .foregroundColor(configuration.isPressed ? .black : .orange)
            .background(configuration.isPressed ? Color.orange : Color(white: 0.1))
            .overlay(
                CutCorner().stroke(Color.orange, lineWidth: 1)
            )
            .clipShape(CutCorner())
    }
}

struct CutCorner: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c: CGFloat = 10
        p.move(to: .init(x: rect.minX + c, y: rect.minY))
        p.addLine(to: .init(x: rect.maxX - c, y: rect.minY))
        p.addLine(to: .init(x: rect.maxX, y: rect.minY + c))
        p.addLine(to: .init(x: rect.maxX, y: rect.maxY - c))
        p.addLine(to: .init(x: rect.maxX - c, y: rect.maxY))
        p.addLine(to: .init(x: rect.minX + c, y: rect.maxY))
        p.addLine(to: .init(x: rect.minX, y: rect.maxY - c))
        p.addLine(to: .init(x: rect.minX, y: rect.minY + c))
        p.closeSubpath()
        return p
    }
}

struct LineBackground: View {
    @State private var phase: Double = 0
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                var grid = Path()
                for i in stride(from: 0, through: size.width, by: 40) {
                    grid.move(to: .init(x: i, y: 0)); grid.addLine(to: .init(x: i, y: size.height))
                }
                for j in stride(from: 0, through: size.height, by: 40) {
                    grid.move(to: .init(x: 0, y: j)); grid.addLine(to: .init(x: size.width, y: j))
                }
                ctx.stroke(grid, with: .color(.orange.opacity(0.06)), lineWidth: 0.6)
                // 流动数据线
                for k in 0..<5 {
                    var line = Path()
                    let y = size.height * (0.2 + Double(k) * 0.12) + sin(t * 0.3 + Double(k)) * 20
                    line.move(to: .init(x: 0, y: y))
                    line.addLine(to: .init(x: size.width, y: y))
                    ctx.stroke(line, with: .color(.cyan.opacity(0.08)), lineWidth: 0.8)
                }
            }
        }
        .ignoresSafeArea()
        .background(Color(white: 0.03))
    }
}