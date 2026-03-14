import SwiftUI
import AppKit

// MARK: - ArchiveView

struct ArchiveView: View {
    @ObservedObject var memoStore: MemoStore
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("未完了").tag(0)
                Text("完了済み").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            if selectedTab == 0 {
                activeTab
            } else {
                completedTab
            }
        }
        .frame(width: 480, height: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private var activeTab: some View {
        if memoStore.activeMemos.isEmpty {
            emptyStateView(icon: "note.text", message: "アクティブなメモはありません")
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(memoStore.activeMemos, id: \.objectID) { memo in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: memo.color))
                                .frame(width: 5, height: 32)

                            Text(memo.content)
                                .font(.system(size: 13, design: .rounded))
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: {
                                memoStore.completeMemoFromArchive(memo)
                            }) {
                                Text("完了")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(.thinMaterial))
                                    .overlay(Capsule().strokeBorder(Color.green.opacity(0.3), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                memoStore.deleteMemo(memo)
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red.opacity(0.7))
                                    .padding(6)
                                    .background(Capsule().fill(.thinMaterial))
                                    .overlay(Capsule().strokeBorder(Color.red.opacity(0.2), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                                )
                                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    @ViewBuilder
    private var completedTab: some View {
        if memoStore.archivedMemos.isEmpty {
            emptyStateView(icon: "checkmark.circle", message: "完了済みメモはありません")
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(memoStore.archivedMemos, id: \.objectID) { memo in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(memo.content)
                                    .font(.system(size: 13, design: .rounded))
                                    .lineLimit(2)
                                if let completedAt = memo.completedAt {
                                    Text("完了: " + dateString(from: completedAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: {
                                memoStore.restoreMemo(memo)
                            }) {
                                Text("未完了に戻す")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(.thinMaterial))
                                    .overlay(Capsule().strokeBorder(Color.blue.opacity(0.3), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                memoStore.deleteMemo(memo)
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red.opacity(0.7))
                                    .padding(6)
                                    .background(Capsule().fill(.thinMaterial))
                                    .overlay(Capsule().strokeBorder(Color.red.opacity(0.2), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                                )
                                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
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
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 520),
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
