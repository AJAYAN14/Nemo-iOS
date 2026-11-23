import SwiftUI

/// 词库加载骨架屏占位卡片视图。
public struct DictionarySkeletonView: View {
    @State private var isAnimating = false

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<7, id: \.self) { _ in
                skeletonCard
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }

    private var skeletonCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(width: 90, height: 18)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(width: 160, height: 13)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemFill))
                .frame(width: 38, height: 22)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .opacity(isAnimating ? 0.38 : 0.85)
    }
}
