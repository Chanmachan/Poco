import CoreGraphics
import AppKit

class GlobalShortcutManager {
    var shortcutHandler: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // MARK: - Start / Stop

    func start() {
        guard checkAccessibilityPermission() else { return }
        setupEventTap()
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    // MARK: - Accessibility Permission

    private func checkAccessibilityPermission() -> Bool {
        let options: [CFString: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        if !trusted {
            print("Poco: アクセシビリティの許可が必要です。システム環境設定 > セキュリティとプライバシー > アクセシビリティで許可してください。")
        }
        return trusted
    }

    // MARK: - CGEventTap Setup

    private func setupEventTap() {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(type: type, event: event)
            },
            userInfo: selfPtr
        ) else {
            print("Poco: CGEventTap の作成に失敗しました。アクセシビリティの許可を確認してください。")
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
    }

    // MARK: - Event Handler

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else { return Unmanaged.passRetained(event) }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags

        // kVK_ANSI_N = 0x2D = 45
        let isControlOption = flags.contains(.maskControl) && flags.contains(.maskAlternate)
        let noCommandOrShift = !flags.contains(.maskCommand) && !flags.contains(.maskShift)

        if keyCode == 45 && isControlOption && noCommandOrShift {
            DispatchQueue.main.async { [weak self] in
                self?.shortcutHandler?()
            }
            return nil // consume event
        }

        return Unmanaged.passRetained(event)
    }
}
