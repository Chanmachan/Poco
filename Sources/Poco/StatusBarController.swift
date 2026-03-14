import AppKit

class StatusBarController {
    private var statusItem: NSStatusItem
    private let memoStore: MemoStore
    private let openArchiveHandler: () -> Void
    private let showQuickInputHandler: () -> Void

    init(
        memoStore: MemoStore,
        openArchiveHandler: @escaping () -> Void,
        showQuickInputHandler: @escaping () -> Void
    ) {
        self.memoStore = memoStore
        self.openArchiveHandler = openArchiveHandler
        self.showQuickInputHandler = showQuickInputHandler

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        configureButton()
        buildMenu()
    }

    // MARK: - Button

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Poco")
        button.image?.isTemplate = true
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()

        let newItem = NSMenuItem(
            title: "新しいメモ (⌃⌥N)",
            action: #selector(handleNewMemo),
            keyEquivalent: ""
        )
        newItem.target = self
        menu.addItem(newItem)

        menu.addItem(.separator())

        let archiveItem = NSMenuItem(
            title: "アーカイブを開く",
            action: #selector(handleOpenArchive),
            keyEquivalent: ""
        )
        archiveItem.target = self
        menu.addItem(archiveItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "終了",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func handleNewMemo() {
        showQuickInputHandler()
    }

    @objc private func handleOpenArchive() {
        openArchiveHandler()
    }
}
