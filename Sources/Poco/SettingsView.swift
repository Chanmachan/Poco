import SwiftUI

struct SettingsView: View {
    @AppStorage("shortcutModifierFlags") var modifierFlags: Int = 786432  // ⌃⌥
    @AppStorage("shortcutKeyCode") var keyCode: Int = 45  // N
    @State private var isRecording = false
    @State private var recordedKey = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("設定")
                .font(.title2.bold())

            GroupBox("ショートカットキー") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("クイック入力のショートカット")
                        .font(.subheadline)
                    HStack {
                        Text("現在: ⌃⌥N")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(isRecording ? "キーを押してください..." : "変更") {
                            isRecording = true
                        }
                        .buttonStyle(.bordered)
                    }
                    Text("※ ショートカット変更後は再起動が必要です")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(8)
            }

            GroupBox("クイック入力") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("背景の不透明度")
                        Slider(value: .init(
                            get: { Double(UserDefaults.standard.float(forKey: "quickInputOpacity").isZero ? 0.85 : UserDefaults.standard.float(forKey: "quickInputOpacity")) },
                            set: { UserDefaults.standard.set(Float($0), forKey: "quickInputOpacity") }
                        ), in: 0.5...1.0)
                        .frame(width: 120)
                    }
                }
                .padding(8)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 360, height: 300)
    }
}
