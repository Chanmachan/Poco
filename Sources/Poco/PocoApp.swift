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
            showQuickInputHandler: { [weak self] in self?.showQuickInput() }
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
        quickInputController?.show { [weak self] text in
            guard let self else { return }
            self.memoStore.createMemo(content: text)
        }
    }

    // MARK: - Archive

    private func openArchive() {
        archiveWindowController?.show()
    }

    // MARK: - Sticky Note Window Sync

    private func syncStickyWindows(memos: [MemoEntity]) {
        let currentIDs = Set(stickyNoteControllers.keys)
        let newIDs = Set(memos.map { $0.objectID })

        // Remove windows for memos no longer active
        for id in currentIDs.subtracting(newIDs) {
            stickyNoteControllers[id]?.close()
            stickyNoteControllers.removeValue(forKey: id)
        }

        // Add windows for new active memos
        for memo in memos where !currentIDs.contains(memo.objectID) {
            let controller = StickyNoteWindowController(memo: memo, memoStore: memoStore)
            stickyNoteControllers[memo.objectID] = controller
        }
    }
}
