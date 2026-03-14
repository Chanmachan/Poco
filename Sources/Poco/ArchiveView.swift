import SwiftUI
import AppKit

// MARK: - ArchiveView

struct ArchiveView: View {
    @ObservedObject var memoStore: MemoStore
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("📋 未完了").tag(0)
                Text("✅ 完了済み").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            if selectedTab == 0 {
                activeTab
            } else {
                completedTab
            }
        }
        .frame(width: 500, height: 420)
    }

    @ViewBuilder
    private var activeTab: some View {
        if memoStore.activeMemos.isEmpty {
            emptyStateView(icon: "note.text", message: "アクティブなメモはありません")
        } else {
            List(memoStore.activeMemos, id: \.objectID) { memo in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: memo.color))
                        .frame(width: 6, height: 36)

                    Text(memo.content)
                        .font(.body)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button("完了") {
                        memoStore.completeMemoFromArchive(memo)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(Color(hex: "#2E7D32").opacity(0.85))
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset)
        }
    }

    @ViewBuilder
    private var completedTab: some View {
        if memoStore.archivedMemos.isEmpty {
            emptyStateView(icon: "checkmark.circle", message: "完了済みメモはありません")
        } else {
            List(memoStore.archivedMemos, id: \.objectID) { memo in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(memo.content)
                            .font(.body)
                            .lineLimit(2)
                        if let completedAt = memo.completedAt {
                            Text("完了: " + dateString(from: completedAt))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button("未完了に戻す") {
                        memoStore.restoreMemo(memo)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .clipShape(Capsule())
                }
                .padding(.vertical, 4)
            }
            .listStyle(.inset)
        }
    }

    private func emptyStateView(icon: String, message: String) -> some View {
        VStack {
            Spacer()
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 42))
                    .foregroundColor(.secondary.opacity(0.6))
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func dateString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "M/d HH:mm"
        return f.string(from: date)
    }
}

// MARK: - ArchiveWindowController

class ArchiveWindowController: NSWindowController {
    private let memoStore: MemoStore

    init(memoStore: MemoStore) {
        self.memoStore = memoStore

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 420),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Poco - メモ一覧"
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
