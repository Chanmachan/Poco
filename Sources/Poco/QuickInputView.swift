import SwiftUI
import AppKit

// MARK: - QuickInputView

struct QuickInputView: View {
    @State private var text = ""
    @FocusState private var isFocused: Bool

    let onSave: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("メモを入力...", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.white)
                .focused($isFocused)
                .onSubmit {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        onSave(trimmed)
                    }
                }

            Divider().background(Color.white.opacity(0.15))

            HStack {
                Text("return 保存")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                Text("esc キャンセル")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.13, green: 0.13, blue: 0.15).opacity(0.95))
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 8)
        )
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - QuickInputWindowController

class QuickInputWindowController {
    private var window: NSPanel?
    private var localEventMonitor: Any?

    func show(onSave: @escaping (String) -> Void) {
        if window != nil { return }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 90),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar + 1
        panel.backgroundColor = NSColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 0.92)
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
        hostingView.frame = panel.contentView!.bounds
        let fittingSize = hostingView.fittingSize
        panel.setContentSize(fittingSize)
        panel.contentView = hostingView

        // Position: screen center, y = 200pt from top
        if let screen = NSScreen.main {
            let x = screen.frame.midX - panel.frame.width / 2
            let y = screen.frame.maxY - 200 - panel.frame.height
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // Escape key monitor for cases where SwiftUI onKeyPress may not fire
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

        // Slide-in animation
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
