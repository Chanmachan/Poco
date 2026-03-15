import AppKit
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem
    private let memoStore: MemoStore
    private let openArchiveHandler: () -> Void
    private let showQuickInputHandler: () -> Void
    private let colorFilterHandler: (String?) -> Void
    private let toggleWidgetHandler: () -> Void
    private let toggleDisplayModeHandler: () -> Void
    private let settingsHandler: () -> Void
    private let isWidgetOnlyModeProvider: () -> Bool
    private var displayModeItem: NSMenuItem?

    init(
        memoStore: MemoStore,
        openArchiveHandler: @escaping () -> Void,
        showQuickInputHandler: @escaping () -> Void,
        colorFilterHandler: @escaping (String?) -> Void,
        toggleWidgetHandler: @escaping () -> Void,
        toggleDisplayModeHandler: @escaping () -> Void,
        settingsHandler: @escaping () -> Void,
        isWidgetOnlyModeProvider: @escaping () -> Bool
    ) {
        self.memoStore = memoStore
        self.openArchiveHandler = openArchiveHandler
        self.showQuickInputHandler = showQuickInputHandler
        self.colorFilterHandler = colorFilterHandler
        self.toggleWidgetHandler = toggleWidgetHandler
        self.toggleDisplayModeHandler = toggleDisplayModeHandler
        self.settingsHandler = settingsHandler
        self.isWidgetOnlyModeProvider = isWidgetOnlyModeProvider

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

        // Color filter: すべて表示
        let allItem = NSMenuItem(
            title: "すべて表示",
            action: #selector(handleFilterAll),
            keyEquivalent: ""
        )
        allItem.target = self
        menu.addItem(allItem)

        // Color filter items (circle icons)
        for color in StickyColor.allCases {
            let item = NSMenuItem(
                title: "",
                action: #selector(handleFilterColor(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = color.rawValue

            let size = NSSize(width: 16, height: 16)
            let image = NSImage(size: size, flipped: false) { rect in
                let path = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
                NSColor(Color(hex: color.rawValue)).setFill()
                path.fill()
                return true
            }
            item.image = image
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let widgetItem = NSMenuItem(
            title: "ウィジェット表示/非表示",
            action: #selector(handleToggleWidget),
            keyEquivalent: ""
        )
        widgetItem.target = self
        menu.addItem(widgetItem)

        menu.addItem(.separator())

        // 表示モード（チェックマーク式）
        let modeHeader = NSMenuItem(title: "付箋の表示方法", action: nil, keyEquivalent: "")
        modeHeader.isEnabled = false
        menu.addItem(modeHeader)

        let widgetModeItem = NSMenuItem(
            title: "ウィジェットのみ",
            action: #selector(handleToggleDisplayMode),
            keyEquivalent: ""
        )
        widgetModeItem.target = self
        widgetModeItem.state = isWidgetOnlyModeProvider() ? .on : .off
        widgetModeItem.tag = 1
        self.displayModeItem = widgetModeItem
        menu.addItem(widgetModeItem)

        let desktopModeItem = NSMenuItem(
            title: "デスクトップに個別表示",
            action: #selector(handleToggleDisplayMode),
            keyEquivalent: ""
        )
        desktopModeItem.target = self
        desktopModeItem.state = isWidgetOnlyModeProvider() ? .off : .on
        desktopModeItem.tag = 2
        menu.addItem(desktopModeItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "設定...",
            action: #selector(handleSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

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

    @objc private func handleSettings() {
        settingsHandler()
    }

    @objc private func handleToggleWidget() {
        toggleWidgetHandler()
    }

    @objc private func handleToggleDisplayMode() {
        toggleDisplayModeHandler()
    }

    func updateDisplayModeCheckmark(isWidgetOnly: Bool) {
        statusItem.menu?.items.forEach { item in
            if item.tag == 1 { item.state = isWidgetOnly ? .on : .off }
            if item.tag == 2 { item.state = isWidgetOnly ? .off : .on }
        }
    }

    @objc private func handleFilterAll() {
        colorFilterHandler(nil)
    }

    @objc private func handleFilterColor(_ sender: NSMenuItem) {
        guard let hex = sender.representedObject as? String else { return }
        colorFilterHandler(hex)
    }
}
