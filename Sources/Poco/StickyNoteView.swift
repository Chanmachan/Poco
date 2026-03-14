import SwiftUI
import AppKit

// MARK: - Color Helpers

extension Color {
    init(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.hasPrefix("#") ? String(sanitized.dropFirst()) : sanitized

        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - StickyColor

enum StickyColor: String, CaseIterable {
    case yellow = "#FFF9C4"
    case blue   = "#E3F2FD"
    case green  = "#E8F5E9"
    case pink   = "#FCE4EC"
    case white  = "#FAFAFA"

    var displayName: String {
        switch self {
        case .yellow: return "🟡 黄"
        case .blue:   return "🔵 青"
        case .green:  return "🟢 緑"
        case .pink:   return "🩷 ピンク"
        case .white:  return "⬜ 白"
        }
    }

    var headerHex: String {
        switch self {
        case .yellow: return "#F9A825"
        case .blue:   return "#1565C0"
        case .green:  return "#2E7D32"
        case .pink:   return "#C62828"
        case .white:  return "#9E9E9E"
        }
    }

    var backgroundColor: Color { Color(hex: rawValue) }
    var accentColor: Color     { Color(hex: headerHex) }

    // Keep headerColor as alias for compatibility
    var headerColor: Color     { Color(hex: headerHex) }

    static func from(_ hex: String) -> StickyColor {
        StickyColor(rawValue: hex) ?? .yellow
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
    @FocusState private var editorFocused: Bool

    var onComplete: (() -> Void)?

    private var stickyColor: StickyColor {
        StickyColor.from(memo.color)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Check button - small circle on left (16pt)
            Button(action: startComplete) {
                ZStack {
                    Circle()
                        .strokeBorder(stickyColor.accentColor, lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(stickyColor.accentColor)
                }
            }
            .buttonStyle(.plain)
            .frame(width: 16, height: 16)

            // Content area
            if isEditing {
                TextEditor(text: $editText)
                    .font(.system(size: 13))
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .focused($editorFocused)
                    .onChange(of: editorFocused) { focused in
                        if !focused { saveEdit() }
                    }
            } else {
                Text(memo.content.isEmpty ? "テキストを入力..." : memo.content)
                    .font(.system(size: 13))
                    .foregroundColor(memo.content.isEmpty ? .secondary : .black.opacity(0.82))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .lineLimit(nil)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editText = memo.content
                        isEditing = true
                        editorFocused = true
                    }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(width: 260, height: 80)
        .background(stickyColor.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.22), radius: 10, x: 0, y: 5)
        .opacity(opacity)
        .contextMenu {
            ForEach(StickyColor.allCases, id: \.rawValue) { color in
                Button(color.displayName) {
                    memoStore.updateColor(memo, color: color.rawValue)
                }
            }
            Divider()
            Button("削除", role: .destructive) {
                showDeleteConfirm = true
            }
        }
        .alert("このメモを削除しますか？", isPresented: $showDeleteConfirm) {
            Button("削除", role: .destructive) {
                memoStore.deleteMemo(memo)
            }
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
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
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
            contentRect: NSRect(x: memo.positionX, y: memo.positionY, width: 260, height: 80),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        win.backgroundColor = .clear
        win.isOpaque = false
        win.hasShadow = false
        win.isMovableByWindowBackground = true
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]
        win.ignoresMouseEvents = false

        let view = StickyNoteView(memo: memo, memoStore: memoStore, onComplete: { [weak win] in
            win?.orderOut(nil)
        })
        win.contentView = NSHostingView(rootView: view)

        self.window = win

        // Observe window moves to persist position
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

    deinit {
        close()
    }
}
