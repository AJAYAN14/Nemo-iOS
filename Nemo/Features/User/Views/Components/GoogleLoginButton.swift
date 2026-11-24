import SwiftUI

/// Google 品牌原生风格快捷登录按钮
public struct GoogleLoginButton: View {
    public var title: String
    public var isLoading: Bool
    public var action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    public init(
        title: String = "使用 Google 账号登录",
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    private var isDark: Bool {
        colorScheme == .dark
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: isDark ? .white : Color(red: 0.15, green: 0.20, blue: 0.30)))
                        .frame(width: 20, height: 20)
                } else {
                    GoogleIconView()
                        .frame(width: 20, height: 20)
                }

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isDark ? Color.white : Color(red: 0.12, green: 0.16, blue: 0.24))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                isDark
                    ? Color.white.opacity(0.08)
                    : Color.white
            )
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(
                        isDark ? Color.white.opacity(0.12) : Color(red: 0.88, green: 0.91, blue: 0.94),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isDark ? Color.black.opacity(0.20) : Color.black.opacity(0.04),
                radius: 6,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(NemoPressableButtonStyle())
        .disabled(isLoading)
    }
}

/// Google 官方四色矢量 G 图标纯原生绘制视图
public struct GoogleIconView: View {
    public init() {}

    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let center = CGPoint(x: w / 2, y: h / 2)
            let radius = min(w, h) / 2
            let innerRadius = radius * 0.58

            let blueColor = Color(red: 0x42 / 255.0, green: 0x85 / 255.0, blue: 0xF4 / 255.0)
            let redColor = Color(red: 0xEA / 255.0, green: 0x43 / 255.0, blue: 0x35 / 255.0)
            let yellowColor = Color(red: 0xFB / 255.0, green: 0xBC / 255.0, blue: 0x05 / 255.0)
            let greenColor = Color(red: 0x34 / 255.0, green: 0xA8 / 255.0, blue: 0x53 / 255.0)

            // 1. 绿色底部扇环 (45° 到 135°)
            var greenPath = Path()
            greenPath.addArc(center: center, radius: radius, startAngle: .degrees(45), endAngle: .degrees(135), clockwise: false)
            greenPath.addArc(center: center, radius: innerRadius, startAngle: .degrees(135), endAngle: .degrees(45), clockwise: true)
            greenPath.closeSubpath()
            context.fill(greenPath, with: .color(greenColor))

            // 2. 黄色左侧扇环 (135° 到 225°)
            var yellowPath = Path()
            yellowPath.addArc(center: center, radius: radius, startAngle: .degrees(135), endAngle: .degrees(225), clockwise: false)
            yellowPath.addArc(center: center, radius: innerRadius, startAngle: .degrees(225), endAngle: .degrees(135), clockwise: true)
            yellowPath.closeSubpath()
            context.fill(yellowPath, with: .color(yellowColor))

            // 3. 红色顶部扇环 (225° 到 315°)
            var redPath = Path()
            redPath.addArc(center: center, radius: radius, startAngle: .degrees(225), endAngle: .degrees(315), clockwise: false)
            redPath.addArc(center: center, radius: innerRadius, startAngle: .degrees(315), endAngle: .degrees(225), clockwise: true)
            redPath.closeSubpath()
            context.fill(redPath, with: .color(redColor))

            // 4. 蓝色右下扇环 (0° 到 45°)
            var blueArcPath = Path()
            blueArcPath.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(45), clockwise: false)
            blueArcPath.addArc(center: center, radius: innerRadius, startAngle: .degrees(45), endAngle: .degrees(0), clockwise: true)
            blueArcPath.closeSubpath()
            context.fill(blueArcPath, with: .color(blueColor))

            // 5. 蓝色中心水平横杠 (从圆心延展至外圆)
            let barHeight = radius * 0.42
            let barY = center.y - barHeight / 2
            var barPath = Path()
            barPath.addRect(CGRect(x: center.x - 0.5, y: barY, width: radius + 0.5, height: barHeight))
            context.fill(barPath, with: .color(blueColor))
        }
    }
}
