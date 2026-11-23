import SwiftUI

/// 跑道赛道几何形状（顺时针从顶部中心闭合）
public struct LearningTrackShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let radius = height / 2.0
        let midX = rect.midX

        // 起点：顶部直道正中心
        path.move(to: CGPoint(x: midX, y: 0))
        // 1. 顶部直道向右
        path.addLine(to: CGPoint(x: width - radius, y: 0))
        // 2. 右半圆弯道（顺时针经由最右侧转向底部）
        path.addArc(
            center: CGPoint(x: width - radius, y: radius),
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: false
        )
        // 3. 底部直道向左
        path.addLine(to: CGPoint(x: radius, y: height))
        // 4. 左半圆弯道（顺时针经由最左侧转向顶部）
        path.addArc(
            center: CGPoint(x: radius, y: radius),
            radius: radius,
            startAngle: .degrees(90),
            endAngle: .degrees(270),
            clockwise: false
        )
        // 5. 回到顶部中心闭合
        path.addLine(to: CGPoint(x: midX, y: 0))
        path.closeSubpath()

        return path
    }
}

/// 400米跑道胶囊学习进度指示器
public struct LearningTrackProgressIndicator: View {
    public let progress: Double
    public let queueCounts: QueueCountState
    public var onTrackClick: (() -> Void)?

    public init(
        progress: Double,
        queueCounts: QueueCountState,
        onTrackClick: (() -> Void)? = nil
    ) {
        self.progress = min(max(progress, 0.0), 1.0)
        self.queueCounts = queueCounts
        self.onTrackClick = onTrackClick
    }

    public var body: some View {
        Button {
            onTrackClick?()
        } label: {
            ZStack {
                // 1. 跑道底轨基准线
                LearningTrackShape()
                    .stroke(
                        Color.primary.opacity(0.1),
                        style: StrokeStyle(lineWidth: 2.0, lineCap: .round)
                    )

                // 2. 顺时针圆头进度高亮线
                LearningTrackShape()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: 2.8, lineCap: .round)
                    )
                    .animation(.spring(response: 0.45, dampingFraction: 0.75), value: progress)

                // 3. 内场四态队列计数（新学/在学/复习/重学）
                HStack(spacing: 6) {
                    badgeNumber(count: queueCounts.newCount, color: .blue)
                    badgeNumber(count: queueCounts.learningCount, color: .cyan)
                    badgeNumber(count: queueCounts.reviewCount, color: .green)
                    badgeNumber(count: queueCounts.relearnCount, color: .orange)
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .padding(.horizontal, 8)
            }
            .frame(width: 130, height: 34)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// 单个队列数字（0 态半透明弱化）
    @ViewBuilder
    private func badgeNumber(count: Int, color: Color) -> some View {
        Text("\(count)")
            .foregroundStyle(color)
            .opacity(count > 0 ? 1.0 : 0.25)
    }
}

#Preview("Track Progress Indicator") {
    ZStack {
        Color.nemoGroupedBackground.ignoresSafeArea()

        VStack(spacing: 24) {
            LearningTrackProgressIndicator(
                progress: 0.35,
                queueCounts: QueueCountState(newCount: 8, learningCount: 2, reviewCount: 4, relearnCount: 1)
            )

            LearningTrackProgressIndicator(
                progress: 0.85,
                queueCounts: QueueCountState(newCount: 0, learningCount: 1, reviewCount: 9, relearnCount: 0)
            )

            LearningTrackProgressIndicator(
                progress: 1.0,
                queueCounts: QueueCountState(newCount: 0, learningCount: 0, reviewCount: 0, relearnCount: 0)
            )
        }
        .padding()
    }
}
