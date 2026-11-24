import SwiftUI

/// 顶部装饰性假名天幕波纹视图
public struct KanaWaveHeaderView: View {
    @State private var phase: CGFloat = 0

    private let kanaSymbols: [(char: String, x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] = [
        ("あ", 0.15, 0.22, 28, 0.25),
        ("い", 0.82, 0.18, 22, 0.20),
        ("う", 0.45, 0.35, 26, 0.18),
        ("え", 0.28, 0.65, 34, 0.15),
        ("お", 0.75, 0.55, 30, 0.22),
        ("カ", 0.88, 0.82, 24, 0.18),
        ("シ", 0.12, 0.88, 26, 0.16),
        ("タ", 0.58, 0.78, 32, 0.12),
        ("の", 0.38, 0.15, 20, 0.25),
        ("波", 0.62, 0.32, 38, 0.14)
    ]

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                // 弥散环境光晕背景
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.14, green: 0.38, blue: 0.96).opacity(0.35),
                        Color(red: 0.08, green: 0.15, blue: 0.45).opacity(0.15),
                        Color.clear
                    ]),
                    center: .top,
                    startRadius: 20,
                    endRadius: size.width * 0.85
                )

                // 假名字形沉浸分布
                ForEach(0..<kanaSymbols.count, id: \.self) { idx in
                    let item = kanaSymbols[idx]
                    Text(item.char)
                        .font(.system(size: item.size, weight: .light, design: .serif))
                        .foregroundStyle(.white.opacity(item.opacity))
                        .position(x: size.width * item.x, y: size.height * item.y)
                }

                // 波纹曲线层
                Canvas { context, canvasSize in
                    var path = Path()
                    let width = canvasSize.width
                    let height = canvasSize.height
                    let midY = height * 0.75

                    path.move(to: CGPoint(x: 0, y: height))
                    path.addLine(to: CGPoint(x: 0, y: midY))

                    let step: CGFloat = 8
                    for x in stride(from: 0, through: width, by: step) {
                        let relativeX = x / 60
                        let y = midY + sin(relativeX + phase) * 12 + cos(relativeX * 0.5 + phase * 0.7) * 8
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()

                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                Color(red: 0.15, green: 0.40, blue: 0.95).opacity(0.18),
                                Color.clear
                            ]),
                            startPoint: CGPoint(x: width * 0.5, y: midY - 20),
                            endPoint: CGPoint(x: width * 0.5, y: height)
                        )
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}
