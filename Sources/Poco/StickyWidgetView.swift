import SwiftUI
import AppKit

struct StickyWidgetView: View {
    @ObservedObject var memoStore: MemoStore
    var colorFilter: String?
    var onCompleteMemo: (MemoEntity) -> Void
    var onTapMemo: (MemoEntity) -> Void

    private var displayMemos: [MemoEntity] {
        if let f = colorFilter {
            return memoStore.activeMemos.filter { $0.color == f }
        }
        return memoStore.activeMemos
    }

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー（ドラッグハンドル兼用）
            HStack {
                Text("Poco")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(displayMemos.count)件")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)

            Divider().opacity(0.3)

            if displayMemos.isEmpty {
                VStack {
                    Spacer()
                    Text("メモなし")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(displayMemos, id: \.objectID) { memo in
                            WidgetMemoCard(
                                memo: memo,
                                onComplete: { onCompleteMemo(memo) },
                                onTap: { onTapMemo(memo) }
                            )
                        }
                    }
                    .padding(8)
                }
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
}

struct WidgetMemoCard: View {
    @ObservedObject var memo: MemoEntity
    var onComplete: () -> Void
    var onTap: () -> Void

    @State private var checkHovered = false
    @State private var opacity: Double = 1.0

    var stickyColor: StickyColor { StickyColor.from(memo.color) }

    var body: some View {
        HStack(spacing: 8) {
            // 色インジケーター
            RoundedRectangle(cornerRadius: 2)
                .fill(stickyColor.backgroundColor)
                .frame(width: 4)

            Text(memo.content)
                .font(.system(size: 12, design: .rounded))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onTapGesture { onTap() }

            // 完了ボタン
            Button(action: {
                withAnimation(.easeOut(duration: 0.25)) { opacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { onComplete() }
            }) {
                Circle()
                    .fill(Color.white.opacity(checkHovered ? 0.85 : 0.35))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(stickyColor.accentColor.opacity(checkHovered ? 1 : 0.7))
                    )
            }
            .buttonStyle(.plain)
            .onHover { checkHovered = $0 }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(stickyColor.backgroundColor.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(opacity)
    }
}
