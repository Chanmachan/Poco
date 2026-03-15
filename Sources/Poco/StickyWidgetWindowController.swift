import AppKit
import SwiftUI

class StickyWidgetWindowController {
    private var window: NSWindow?
    private let memoStore: MemoStore

    init(memoStore: MemoStore) {
        self.memoStore = memoStore
    }

    func show(colorFilter: String?,
              onCompleteMemo: @escaping (MemoEntity) -> Void,
              onTapMemo: @escaping (MemoEntity) -> Void) {
        if window == nil { createWindow(colorFilter: colorFilter,
                                        onCompleteMemo: onCompleteMemo,
                                        onTapMemo: onTapMemo) }
        window?.makeKeyAndOrderFront(nil)
    }

    func hide() { window?.orderOut(nil) }

    func toggle(colorFilter: String?,
                onCompleteMemo: @escaping (MemoEntity) -> Void,
                onTapMemo: @escaping (MemoEntity) -> Void) {
        if window?.isVisible == true { hide() }
        else { show(colorFilter: colorFilter,
                    onCompleteMemo: onCompleteMemo,
                    onTapMemo: onTapMemo) }
    }

    private func createWindow(colorFilter: String?,
                               onCompleteMemo: @escaping (MemoEntity) -> Void,
                               onTapMemo: @escaping (MemoEntity) -> Void) {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 400),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        win.backgroundColor = .clear
        win.isOpaque = false
        win.hasShadow = false
        win.isMovableByWindowBackground = true
        win.collectionBehavior = [.canJoinAllSpaces, .stationary]

        // 画面右上に配置
        if let screen = NSScreen.main {
            let x = screen.visibleFrame.maxX - 260 - 16
            let y = screen.visibleFrame.maxY - 400 - 16
            win.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let view = StickyWidgetView(
            memoStore: memoStore,
            colorFilter: colorFilter,
            onCompleteMemo: onCompleteMemo,
            onTapMemo: onTapMemo
        )
        win.contentView = NSHostingView(rootView: view)
        self.window = win
        win.orderFront(nil)
    }
}
