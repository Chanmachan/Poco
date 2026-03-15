import SwiftUI
import AppKit
import CoreData

// MARK: - Notification Name

extension Notification.Name {
    static let archiveOpenTab = Notification.Name("archiveOpenTab")
}

// MARK: - ArchiveView

struct ArchiveView: View {
    @ObservedObject var memoStore: MemoStore
    @State private var selectedTab: Int = 0

    @State private var editingMemoID: NSManagedObjectID? = nil
    @State private var editText: String = ""

    // Color filter
    @State private var colorFilter: String? = nil

    // Bulk selection (active tab)
    @State private var isSelectMode = false
    @State private var selectedIDs = Set<NSManagedObjectID>()

    // Bulk selection (completed tab)
    @State private var isCompletedSelectMode = false
    @State private var completedSelectedIDs = Set<NSManagedObjectID>()

    private var filteredMemos: [MemoEntity] {
        if let filter = colorFilter {
            return memoStore.activeMemos.filter { $0.color == filter }
        }
        return memoStore.activeMemos
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("未完了").tag(0)
                Text("完了済み").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)

            Divider()

            if selectedTab == 0 {
                activeTab
            } else {
                completedTab
            }
        }
        .frame(width: 480, height: 520)
        .background(.regularMaterial)
        .onReceive(NotificationCenter.default.publisher(for: .archiveOpenTab)) { notification in
            if let tab = notification.object as? Int {
                selectedTab = tab
            }
        }
    }

    // MARK: - Color Filter Bar

    private var colorFilterBar: some View {
        HStack(spacing: 8) {
            Button("すべて") { colorFilter = nil }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: colorFilter == nil ? .semibold : .regular))
                .foregroundColor(colorFilter == nil ? .primary : .secondary)

            ForEach(StickyColor.allCases, id: \.rawValue) { color in
                Circle()
                    .fill(Color(hex: color.rawValue))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle().strokeBorder(
                            colorFilter == color.rawValue ? Color.primary : Color.clear,
                            lineWidth: 2
                        )
                    )
                    .onTapGesture {
                        colorFilter = colorFilter == color.rawValue ? nil : color.rawValue
                        // Reset selection when filter changes
                        selectedIDs.removeAll()
                    }
            }

            Spacer()

            Button(isSelectMode ? "キャンセル" : "選択") {
                isSelectMode.toggle()
                selectedIDs.removeAll()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.blue)

            if isSelectMode {
                Button("全選択") {
                    selectedIDs = Set(filteredMemos.map { $0.objectID })
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Active Tab

    @ViewBuilder
    private var activeTab: some View {
        VStack(spacing: 0) {
            colorFilterBar
            Divider()

            if filteredMemos.isEmpty {
                emptyStateView(icon: "note.text", message: colorFilter != nil ? "この色のメモはありません" : "アクティブなメモはありません")
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredMemos, id: \.objectID) { memo in
                            HStack(spacing: 12) {
                                // Checkbox in select mode
                                if isSelectMode {
                                    Image(systemName: selectedIDs.contains(memo.objectID) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 16))
                                        .foregroundColor(selectedIDs.contains(memo.objectID) ? .blue : .secondary)
                                        .onTapGesture {
                                            if selectedIDs.contains(memo.objectID) {
                                                selectedIDs.remove(memo.objectID)
                                            } else {
                                                selectedIDs.insert(memo.objectID)
                                            }
                                        }
                                }

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(hex: memo.color))
                                    .frame(width: 5, height: 32)

                                if editingMemoID == memo.objectID {
                                    TextField("", text: $editText, onCommit: {
                                        memoStore.updateContent(memo, content: editText)
                                        editingMemoID = nil
                                    })
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 13, design: .rounded))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    Text(memo.content)
                                        .font(.system(size: 13, design: .rounded))
                                        .lineLimit(2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if isSelectMode {
                                                if selectedIDs.contains(memo.objectID) {
                                                    selectedIDs.remove(memo.objectID)
                                                } else {
                                                    selectedIDs.insert(memo.objectID)
                                                }
                                            } else {
                                                editText = memo.content
                                                editingMemoID = memo.objectID
                                            }
                                        }
                                }

                                if !isSelectMode {
                                    HStack(spacing: 4) {
                                        ForEach(StickyColor.allCases, id: \.rawValue) { color in
                                            Circle()
                                                .fill(Color(hex: color.rawValue))
                                                .frame(width: 12, height: 12)
                                                .overlay(
                                                    Circle().strokeBorder(
                                                        memo.color == color.rawValue ? Color.primary : Color.clear,
                                                        lineWidth: 1.5
                                                    )
                                                )
                                                .onTapGesture {
                                                    memoStore.updateColor(memo, color: color.rawValue)
                                                }
                                        }
                                    }

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

            // Bulk action bar
            if isSelectMode && !selectedIDs.isEmpty {
                HStack(spacing: 12) {
                    // 一括完了ボタン
                    Button(action: {
                        for id in selectedIDs {
                            if let memo = filteredMemos.first(where: { $0.objectID == id }) {
                                memoStore.completeMemoFromArchive(memo)
                            }
                        }
                        selectedIDs.removeAll()
                        isSelectMode = false
                    }) {
                        Label("完了 (\(selectedIDs.count)件)", systemImage: "checkmark.circle")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(.thinMaterial))
                            .overlay(Capsule().strokeBorder(Color.green.opacity(0.4), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)

                    // 一括削除ボタン
                    Button(action: {
                        for id in selectedIDs {
                            if let memo = filteredMemos.first(where: { $0.objectID == id }) {
                                memoStore.deleteMemo(memo)
                            }
                        }
                        selectedIDs.removeAll()
                        isSelectMode = false
                    }) {
                        Label("削除 (\(selectedIDs.count)件)", systemImage: "trash")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(.thinMaterial))
                            .overlay(Capsule().strokeBorder(Color.red.opacity(0.4), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Completed Tab

    @ViewBuilder
    private var completedTab: some View {
        if memoStore.archivedMemos.isEmpty {
            emptyStateView(icon: "checkmark.circle", message: "完了済みメモはありません")
        } else {
            VStack(spacing: 0) {
                completedTabToolbar()
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(memoStore.archivedMemos, id: \.objectID) { memo in
                            completedRow(memo)
                        }
                    }
                    .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                }
                if isCompletedSelectMode && !completedSelectedIDs.isEmpty {
                    completedBulkBar()
                }
            }
        }
    }

    private func completedTabToolbar() -> some View {
        HStack(spacing: 8) {
            Button(isCompletedSelectMode ? "キャンセル" : "選択") {
                isCompletedSelectMode.toggle()
                completedSelectedIDs.removeAll()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.blue)

            if isCompletedSelectMode {
                Button(completedSelectedIDs.count == memoStore.archivedMemos.count ? "選択解除" : "全選択") {
                    if completedSelectedIDs.count == memoStore.archivedMemos.count {
                        completedSelectedIDs.removeAll()
                    } else {
                        completedSelectedIDs = Set(memoStore.archivedMemos.map { $0.objectID })
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.blue)
            }

            Spacer()

            if !isCompletedSelectMode {
                Button(action: {
                    memoStore.archivedMemos.forEach { memoStore.deleteMemo($0) }
                }) {
                    Label("全て削除", systemImage: "trash")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(.thinMaterial))
                        .overlay(Capsule().strokeBorder(Color.red.opacity(0.4), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func completedRow(_ memo: MemoEntity) -> some View {
        let isSelected = completedSelectedIDs.contains(memo.objectID)
        return HStack(spacing: 12) {
            if isCompletedSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .blue : .secondary)
            }

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

            if !isCompletedSelectMode {
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
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? AnyShapeStyle(Color.blue.opacity(0.08)) : AnyShapeStyle(.ultraThinMaterial))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isCompletedSelectMode {
                if isSelected {
                    completedSelectedIDs.remove(memo.objectID)
                } else {
                    completedSelectedIDs.insert(memo.objectID)
                }
            }
        }
    }

    private func completedBulkBar() -> some View {
        HStack(spacing: 12) {
            Button(action: {
                for id in completedSelectedIDs {
                    if let memo = memoStore.archivedMemos.first(where: { $0.objectID == id }) {
                        memoStore.restoreMemo(memo)
                    }
                }
                completedSelectedIDs.removeAll()
                isCompletedSelectMode = false
            }) {
                Label("未完了に戻す (\(completedSelectedIDs.count)件)", systemImage: "arrow.uturn.backward")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.thinMaterial))
                    .overlay(Capsule().strokeBorder(Color.blue.opacity(0.4), lineWidth: 0.8))
            }
            .buttonStyle(.plain)

            Button(action: {
                for id in completedSelectedIDs {
                    if let memo = memoStore.archivedMemos.first(where: { $0.objectID == id }) {
                        memoStore.deleteMemo(memo)
                    }
                }
                completedSelectedIDs.removeAll()
                isCompletedSelectMode = false
            }) {
                Label("削除 (\(completedSelectedIDs.count)件)", systemImage: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.thinMaterial))
                    .overlay(Capsule().strokeBorder(Color.red.opacity(0.4), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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

        super.init(window: window)

        window.contentView = NSHostingView(rootView: ArchiveView(memoStore: memoStore))
    }

    required init?(coder: NSCoder) { fatalError() }

    func openToTab(_ tab: Int) {
        NotificationCenter.default.post(name: .archiveOpenTab, object: tab)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func show(tab: Int = 0) {
        openToTab(tab)
    }
}
