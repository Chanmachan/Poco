import SwiftUI
import AppKit

// MARK: - ArchiveView

struct ArchiveView: View {
    @ObservedObject var memoStore: MemoStore

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/d HH:mm"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("完了済みメモ (\(memoStore.archivedMemos.count)件)")
                    .font(.headline)
                    .padding()
                Spacer()
            }
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            if memoStore.archivedMemos.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("完了済みメモはありません")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                List(memoStore.archivedMemos, id: \.objectID) { memo in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(memo.content)
                                .font(.body)
                                .lineLimit(2)
                            if let completedAt = memo.completedAt {
                                Text(Self.dateFormatter.string(from: completedAt))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button("未完了に戻す") {
                            memoStore.restoreMemo(memo)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - ArchiveWindowController

class ArchiveWindowController: NSWindowController {
    private let memoStore: MemoStore

    init(memoStore: MemoStore) {
        self.memoStore = memoStore

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Poco - アーカイブ"
        window.center()
        window.contentView = NSHostingView(rootView: ArchiveView(memoStore: memoStore))

        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
