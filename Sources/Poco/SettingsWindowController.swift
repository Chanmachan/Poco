import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false
        )
        window.title = "Poco 設定"
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView())
        super.init(window: window)
    }
    required init?(coder: NSCoder) { fatalError() }
    func show() { window?.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
}
