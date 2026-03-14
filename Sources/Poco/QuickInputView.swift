import SwiftUI
import AppKit

// MARK: - QuickInputView

struct QuickInputView: View {
    @State private var text = ""
    @FocusState private var isFocused: Bool

    let onSave: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("ここにメモを入力...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .focused($isFocused)
                .onSubmit {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty { onSave(trimmed) }
                }

            Divider()

            HStack {
                Label("return で保存", systemImage: "return")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Label("esc でキャンセル", systemImage: "escape")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 320)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear { isFocused = true }
    }
}

// MARK: - KeyablePanel
// borderless NSPanel がキーウィンドウになれるようにサブクラス化
private class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - QuickInputWindowController

class QuickInputWindowController {
    private var window: KeyablePanel?
    private var localEventMonitor: Any?

    func show(onSave: @escaping (String) -> Void) {
        if window != nil { return }

        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 90),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar + 1
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true

        let view = QuickInputView(
            onSave: { [weak self] text in
                onSave(text)
                self?.close()
            },
            onCancel: { [weak self] in
                self?.close()
            }
        )

        let hostingView = NSHostingView(rootView: view)
        panel.contentView = hostingView

        // fittingSize でパネルサイズを合わせる
        let fittingSize = hostingView.fittingSize
        panel.setContentSize(NSSize(
            width: max(320, fittingSize.width),
            height: fittingSize.height
        ))

        // 画面上部中央に配置
        if let screen = NSScreen.main {
            let x = screen.frame.midX - panel.frame.width / 2
            let y = screen.frame.maxY - 220 - panel.frame.height
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape
                self?.close()
                return nil
            }
            return event
        }

        self.window = panel
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        panel.alphaValue = 0
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            panel.animator().alphaValue = 1
        }
    }

    func close() {
        guard let panel = window else { return }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.1
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.window = nil
        })
    }
}
