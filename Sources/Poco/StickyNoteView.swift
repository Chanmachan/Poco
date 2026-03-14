import SwiftUI
import AppKit

// MARK: - StickyHostingView (ドラッグ対応NSHostingView)

/// borderless window をドラッグ移動しつつ SwiftUI イベント（ダブルクリック・右クリック）を妨げない
class StickyHostingView<Content: View>: NSHostingView<Content> {
    private var storedMouseDownEvent: NSEvent?

    override func mouseDown(with event: NSEvent) {
        storedMouseDownEvent = event
        super.mouseDown(with: event)   // SwiftUI に先に処理させる
    }

    override func mouseDragged(with event: NSEvent) {
        guard let initialEvent = storedMouseDownEvent else {
            super.mouseDragged(with: event)
            return
        }
        // 5pt 以上動いた場合のみドラッグとみなす
        let dx = event.locationInWindow.x - initialEvent.locationInWindow.x
        let dy = event.locationInWindow.y - initialEvent.locationInWindow.y
        let distance = sqrt(dx * dx + dy * dy)
        if distance > 5 {
            storedMouseDownEvent = nil
            window?.performDrag(with: initialEvent)
        }
    }

    override func mouseUp(with event: NSEvent) {
        storedMouseDownEvent = nil
        super.mouseUp(with: event)
    }
    // rightMouseDown はオーバーライドしない → SwiftUI .contextMenu が正常動作
}

// MARK: - NativeTextField (NSViewRepresentable)

struct NativeTextField: NSViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let tf = NSTextField()
        tf.isBordered = false
        tf.backgroundColor = .clear
        tf.focusRingType = .none
        tf.font = .systemFont(ofSize: 12.5)
        tf.delegate = context.coordinator
        return tf
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text { nsView.stringValue = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NativeTextField
        init(_ parent: NativeTextField) { self.parent = parent }

        func controlTextDidChange(_ obj: Notification) {
            if let tf = obj.object as? NSTextField { parent.text = tf.stringValue }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            if selector == #selector(NSResponder.insertNewline(_:)) { parent.onCommit(); return true }
            if selector == #selector(NSResponder.cancelOperation(_:)) { parent.onCommit(); return true }
            return false
        }
    }
}

// MARK: - StickyNoteView

struct StickyNoteView: View {
    @ObservedObject var memo: MemoEntity
    @ObservedObject var memoStore: MemoStore

    @State private var opacity: Double = 1.0
    @State private var showDeleteConfirm = false
    @State private var isEditing = false
    @State private var editText = ""
    @State private var isCheckHovered = false

    var onComplete: (() -> Void)?

    private var stickyColor: StickyColor { StickyColor.from(memo.color) }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // テキスト表示 / 編集
            if isEditing {
                NativeTextField(text: $editText, onCommit: { saveEdit() })
                    .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 20)
            } else {
                Text(memo.content.isEmpty ? "ダブルクリックで編集..." : memo.content)
                    .font(.system(size: 12.5, weight: .regular, design: .rounded))
                    .foregroundColor(
                        memo.content.isEmpty
                            ? .secondary
                            : .primary.opacity(0.82)
                    )
                    .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 20)
                    .lineLimit(1)
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)
                    .onTapGesture(count: 2) {
                        editText = memo.content
                        isEditing = true
                    }
            }

            // 完了ボタン（Liquid Glass 風）
            Button(action: startComplete) {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.4), lineWidth: 0.8))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.primary)
                    )
            }
            .buttonStyle(.plain)
            .onHover { isCheckHovered = $0 }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 260, height: 72)
        .background(.ultraThinMaterial)
        .background(stickyColor.backgroundColor.opacity(0.35))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
        .opacity(opacity)
        .contextMenu {
            Menu("色を変更") {
                ForEach(StickyColor.allCases, id: \.rawValue) { color in
                    Button(color.displayName) {
                        memoStore.updateColor(memo, color: color.rawValue)
                    }
                }
            }
            Divider()
            Button("削除", role: .destructive) {
                showDeleteConfirm = true
            }
        }
        .alert("このメモを削除しますか？", isPresented: $showDeleteConfirm) {
            Button("削除", role: .destructive) { memoStore.deleteMemo(memo) }
            Button("キャンセル", role: .cancel) {}
        }
    }

    private func saveEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            memoStore.updateContent(memo, content: trimmed)
        }
        isEditing = false
    }

    private func startComplete() {
        withAnimation(.easeOut(duration: 0.3)) { opacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onComplete?()
            memoStore.completeMemo(memo)
        }
    }
}

// MARK: - StickyNoteWindowController

class StickyNoteWindowController {
    private var window: NSWindow?
    private let memo: MemoEntity
    private let memoStore: MemoStore
    private var moveObserver: NSObjectProtocol?

    var memoObjectID: NSManagedObjectID { memo.objectID }

    init(memo: MemoEntity, memoStore: MemoStore) {
        self.memo = memo
        self.memoStore = memoStore

        let win = NSWindow(
            contentRect: NSRect(x: memo.positionX, y: memo.positionY, width: 260, height: 72),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        win.backgroundColor = .clear
        win.isOpaque = false
        win.hasShadow = false
        // ドラッグは StickyHostingView が担うため false に
        win.isMovableByWindowBackground = false
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]
        win.ignoresMouseEvents = false
        win.acceptsMouseMovedEvents = true

        let view = StickyNoteView(memo: memo, memoStore: memoStore, onComplete: { [weak win] in
            win?.orderOut(nil)
        })
        win.contentView = StickyHostingView(rootView: view)
        self.window = win

        moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: win,
            queue: .main
        ) { [weak self, weak win] _ in
            guard let win else { return }
            self?.memoStore.updatePosition(
                memo,
                x: Double(win.frame.origin.x),
                y: Double(win.frame.origin.y)
            )
        }

        win.orderFront(nil)
    }

    func close() {
        if let observer = moveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        window?.orderOut(nil)
        window = nil
    }

    deinit { close() }
}
