import SwiftUI
import AppKit
import Combine

// MARK: - App Entry Point

@main
struct PocoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // All UI is managed by AppDelegate; Settings scene is a no-op.
        Settings {
            EmptyView()
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var memoStore: MemoStore!
    private var statusBarController: StatusBarController?
    private var globalShortcutManager: GlobalShortcutManager?
    private var quickInputController: QuickInputWindowController?
    private var archiveWindowController: ArchiveWindowController?

    // Tracks open sticky note windows by Core Data object ID
    private var stickyNoteControllers: [NSManagedObjectID: StickyNoteWindowController] = [:]
    private var cancellables = Set<AnyCancellable>()

    /// Active color filter hex string. nil = show all.
    private var activeColorFilter: String? = nil

    // MARK: - Launch

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Hide from Dock before any windows appear
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Core Data + store
        memoStore = MemoStore(persistence: PersistenceController.shared)

        // Status bar
        statusBarController = StatusBarController(
            memoStore: memoStore,
            openArchiveHandler: { [weak self] in self?.openArchive() },
            showQuickInputHandler: { [weak self] in self?.showQuickInput() },
            colorFilterHandler: { [weak self] hex in self?.applyColorFilter(hex) }
        )

        // Global shortcut (⌃⌥N)
        globalShortcutManager = GlobalShortcutManager()
        globalShortcutManager?.shortcutHandler = { [weak self] in
            self?.showQuickInput()
        }
        globalShortcutManager?.start()

        // Lazy-init helpers
        quickInputController = QuickInputWindowController()
        archiveWindowController = ArchiveWindowController(memoStore: memoStore)

        // Observe active memos → sync sticky note windows
        memoStore.$activeMemos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] memos in
                self?.syncStickyWindows(memos: memos)
            }
            .store(in: &cancellables)
    }

    // MARK: - Quick Input

    private func showQuickInput() {
        quickInputController?.show { [weak self] text, color in
            guard let self else { return }
            self.memoStore.createMemo(content: text, color: color)
        }
    }

    // MARK: - Archive

    private func openArchive() {
        archiveWindowController?.show()
    }

    // MARK: - Color Filter

    private func applyColorFilter(_ hex: String?) {
        activeColorFilter = hex
        syncStickyWindows(memos: memoStore.activeMemos)
    }

    // MARK: - Sticky Note Window Sync

    private func syncStickyWindows(memos: [MemoEntity]) {
        let filteredMemos: [MemoEntity]
        if let filter = activeColorFilter {
            filteredMemos = memos.filter { $0.color == filter }
        } else {
            filteredMemos = memos
        }

        let currentIDs = Set(stickyNoteControllers.keys)
        let visibleIDs = Set(filteredMemos.map { $0.objectID })

        // Remove windows for memos no longer active or filtered out
        for id in currentIDs.subtracting(visibleIDs) {
            stickyNoteControllers[id]?.close()
            stickyNoteControllers.removeValue(forKey: id)
        }

        // Add windows for new visible memos
        for memo in filteredMemos where !currentIDs.contains(memo.objectID) {
            let controller = StickyNoteWindowController(memo: memo, memoStore: memoStore, onTap: { [weak self] in
                self?.openArchive()
            })
            stickyNoteControllers[memo.objectID] = controller
        }
    }
}
