import SwiftUI
import AppKit

// 通过 NSViewRepresentable 捕获键盘（R 换弹、ESC 双击、鼠标按下）
struct KeyboardCatcher: NSViewRepresentable {
    let engine: RangeEngine
    let app: AppState
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        engine.appRef = app
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown]) { e in
            if e.type == .keyDown {
                if e.keyCode == 15 { // R
                    engine.reload()
                    return nil
                }
                if e.keyCode == 53 { // ESC
                    engine.handleESC()
                    return nil
                }
            }
            return e
        }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}