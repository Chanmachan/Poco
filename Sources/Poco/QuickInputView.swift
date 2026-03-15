import SwiftUI
import AppKit

// MARK: - QuickInputView

struct QuickInputView: View {
    @State private var text = ""
    @State private var selectedColor: StickyColor = .yellow
    @FocusState private var isFocused: Bool

    let onSave: (String, String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("メモを入力...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .focused($isFocused)
                    .onSubmit {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { onSave(trimmed, selectedColor.rawValue) }
                    }

                HStack(spacing: 4) {
                    ForEach(StickyColor.allCases, id: \.rawValue) { color in
                        Circle()
                            .fill(Color(hex: color.rawValue))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle().strokeBorder(
                                    selectedColor == color ? Color.primary.opacity(0.6) : Color.clear,
                                    lineWidth: 1.5
                                )
                            )
                            .onTapGesture { selectedColor = color }
                    }
                }
            }

            Divider().opacity(0.3)

            HStack(spacing: 12) {
                Text("⏎ 保存")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("esc キャンセル")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(width: 340)
        .background(.ultraThinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 12)
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

    func show(onSave: @escaping (String, String) -> Void) {
        if window != nil { return }

        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 90),
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
            onSave: { [weak self] text, color in
                onSave(text, color)
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
            width: max(340, fittingSize.width),
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
