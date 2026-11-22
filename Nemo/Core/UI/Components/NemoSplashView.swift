//
//  NemoSplashView.swift
//  Nemo
//
//  Created on 2026/11/22.
//

import SwiftUI

/// Nemo 全新品牌启动屏视图
///
/// 采用纯正现代 SwiftUI 架构设计，面向 iOS 27 / 现代 iOS 规范开发。
/// 开屏动效规范与品牌视觉：
/// 1. 背景色自适应系统外观（浅色纯白，深色纯黑）；
/// 2. 居中深海呼吸环境光晕 (Ambient Aurora Glow)，全屏自然消融弥散，消除任何硬边；
/// 3. 6 组四周漂浮彩色小几何图形（心形、三角、圆角方框）入场弹跳与持续微悬浮浮动；
/// 4. 中央 "Welcome!" 逐字弹性弹跳展开与下方微笑弧线顺滑绘制；
/// 5. 屏幕底部品牌动效：品牌 Logo 弹出 -> Push 弹簧微抖反馈 -> 展开并呈现 Nemo 英文与竖向分割线；
/// 6. 动效完成后触发 `onFinished` 回调，平滑交叉淡出无缝衔接主界面。
public struct NemoSplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// 动效完成回调闭包
    public var onFinished: () -> Void

    // MARK: - 动效状态机变量

    // 底部品牌锁（Lockup）动画状态
    @State private var logoScale: CGFloat = 0.0
    @State private var lockupGap: CGFloat = 0.0
    @State private var nameRevealProgress: CGFloat = 0.0
    @State private var dividerScaleY: CGFloat = 0.0
    @State private var dividerAlpha: Double = 0.0
    @State private var hapticTrigger: Bool = false

    // 中央舞台（光晕 + 几何图形 + Welcome!）入场状态
    @State private var stageAlpha: Double = 0.0
    @State private var charPushed: [Bool] = Array(repeating: false, count: 8)
    @State private var arcProgress: CGFloat = 0.0

    // 6 组小几何图形入场显现与浮动状态
    @State private var shapeEntered: [Bool] = Array(repeating: false, count: 6)
    @State private var shapeFloats: [Bool] = Array(repeating: false, count: 6)

    // 深海呼吸光晕 4.2s 循环呼吸状态
    @State private var isBreathing: Bool = false

    public init(onFinished: @escaping () -> Void = {}) {
        self.onFinished = onFinished
    }

    /// 当前环境是否处于深色模式
    private var isDark: Bool {
        colorScheme == .dark
    }

    /// 背景画布底色
    private var backgroundColor: Color {
        isDark ? Color.black : Color.white
    }

    /// 品牌主前景字色
    private var foregroundColor: Color {
        isDark
            ? Color(red: 0xF5 / 255.0, green: 0xF5 / 255.0, blue: 0xF7 / 255.0)
            : Color(red: 0x0A / 255.0, green: 0x0A / 255.0, blue: 0x0A / 255.0)
    }

    public var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            // ================= 1. 中央舞台（Welcome! + 呼吸光晕 + 浮动几何图形） =================
            ZStack {
                // 1.1 深海呼吸环境光晕 (Ambient Aurora Glow)
                ambientAuroraGlowView

                // 1.2 四周 6 组漂浮小几何图形
                floatingDecoShapesView

                // 1.3 中央 "Welcome!" 逐字弹性展开与微笑弧线
                centerWelcomeBannerView
            }
            .opacity(stageAlpha)

            // ================= 2. 底部品牌锁（Logo + 分割线 + Nemo 文本展开） =================
            VStack {
                Spacer()
                bottomBrandLockupView
                    .padding(.bottom, 85)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
        .task {
            await startSplashAnimationTimeline()
        }
    }

    // MARK: - 1.1 深海呼吸环境光晕子视图

    @ViewBuilder
    private var ambientAuroraGlowView: some View {
        let glowAlpha = (isDark ? 0.22 : 0.16) * stageAlpha
        let w: CGFloat = 460

        ZStack {
            if isDark {
                // 深色模式：深海蓝 + 青绿（多阶平滑指数衰减，彻底无边界消融）
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: Color.nemoSplashGlowSky.opacity(glowAlpha * 0.95), location: 0.00),
                                .init(color: Color.nemoSplashGlowSky.opacity(glowAlpha * 0.60), location: 0.22),
                                .init(color: Color.nemoSplashGlowSky.opacity(glowAlpha * 0.28), location: 0.45),
                                .init(color: Color.nemoSplashGlowSky.opacity(glowAlpha * 0.08), location: 0.70),
                                .init(color: Color.nemoSplashGlowSky.opacity(glowAlpha * 0.02), location: 0.88),
                                .init(color: Color.nemoSplashGlowSky.opacity(0.0), location: 1.00)
                            ],
                            center: UnitPoint(x: 0.42, y: 0.42),
                            startRadius: 0,
                            endRadius: w * 0.38
                        )
                    )

                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: Color.nemoSplashGlowTeal.opacity(glowAlpha * 0.75), location: 0.00),
                                .init(color: Color.nemoSplashGlowTeal.opacity(glowAlpha * 0.48), location: 0.22),
                                .init(color: Color.nemoSplashGlowTeal.opacity(glowAlpha * 0.22), location: 0.45),
                                .init(color: Color.nemoSplashGlowTeal.opacity(glowAlpha * 0.06), location: 0.70),
                                .init(color: Color.nemoSplashGlowTeal.opacity(glowAlpha * 0.015), location: 0.88),
                                .init(color: Color.nemoSplashGlowTeal.opacity(0.0), location: 1.00)
                            ],
                            center: UnitPoint(x: 0.58, y: 0.58),
                            startRadius: 0,
                            endRadius: w * 0.38
                        )
                    )
            } else {
                // 浅色模式：天蓝 + 柔橙（多阶平滑指数衰减，中心开始逐渐消融）
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: Color.nemoSplashGlowLightBlue.opacity(glowAlpha * 0.90), location: 0.00),
                                .init(color: Color.nemoSplashGlowLightBlue.opacity(glowAlpha * 0.55), location: 0.20),
                                .init(color: Color.nemoSplashGlowLightBlue.opacity(glowAlpha * 0.25), location: 0.45),
                                .init(color: Color.nemoSplashGlowLightBlue.opacity(glowAlpha * 0.08), location: 0.70),
                                .init(color: Color.nemoSplashGlowLightBlue.opacity(glowAlpha * 0.02), location: 0.88),
                                .init(color: Color.nemoSplashGlowLightBlue.opacity(0.0), location: 1.00)
                            ],
                            center: UnitPoint(x: 0.40, y: 0.42),
                            startRadius: 0,
                            endRadius: w * 0.38
                        )
                    )

                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: Color.nemoSplashGlowOrange.opacity(glowAlpha * 0.78), location: 0.00),
                                .init(color: Color.nemoSplashGlowOrange.opacity(glowAlpha * 0.48), location: 0.20),
                                .init(color: Color.nemoSplashGlowOrange.opacity(glowAlpha * 0.20), location: 0.45),
                                .init(color: Color.nemoSplashGlowOrange.opacity(glowAlpha * 0.06), location: 0.70),
                                .init(color: Color.nemoSplashGlowOrange.opacity(glowAlpha * 0.015), location: 0.88),
                                .init(color: Color.nemoSplashGlowOrange.opacity(0.0), location: 1.00)
                            ],
                            center: UnitPoint(x: 0.60, y: 0.58),
                            startRadius: 0,
                            endRadius: w * 0.38
                        )
                    )
            }
        }
        .frame(width: w, height: w)
        .blur(radius: 48)
        .scaleEffect(isBreathing ? 1.14 : 0.88)
        .rotationEffect(.degrees(isBreathing ? 6 : -4))
    }

    // MARK: - 1.2 四周 6 组漂浮小几何图形子视图

    @ViewBuilder
    private var floatingDecoShapesView: some View {
        ZStack {
            // Shape 1: 左上粉红心形（实心）
            HeartShape()
                .fill(Color.nemoSplashShapeRose)
                .frame(width: 20, height: 20)
                .scaleEffect(shapeEntered[0] ? (shapeFloats[0] ? 1.08 : 1.0) : 0.001)
                .opacity(shapeEntered[0] ? 0.85 : 0.0)
                .rotationEffect(.degrees(shapeEntered[0] ? (shapeFloats[0] ? -2 : -16) : -35))
                .offset(x: -102, y: -60 + (shapeFloats[0] ? -8 : 0))

            // Shape 2: 右上浅蓝空心三角（描边 2.6pt）
            TriangleShape(isRounded: false)
                .stroke(Color.nemoSplashGlowLightBlue, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                .frame(width: 21, height: 21)
                .scaleEffect(shapeEntered[1] ? (shapeFloats[1] ? 1.08 : 1.0) : 0.001)
                .opacity(shapeEntered[1] ? 0.85 : 0.0)
                .rotationEffect(.degrees(shapeEntered[1] ? (shapeFloats[1] ? 32 : 18) : -35))
                .offset(x: 104, y: -54 + (shapeFloats[1] ? -8 : 0))

            // Shape 3: 左下橙色圆角线框（描边 2.6pt，圆角 4.5pt）
            RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                .stroke(Color.nemoSplashGlowOrange, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                .frame(width: 18, height: 18)
                .scaleEffect(shapeEntered[2] ? (shapeFloats[2] ? 1.08 : 1.0) : 0.001)
                .opacity(shapeEntered[2] ? 0.82 : 0.0)
                .rotationEffect(.degrees(shapeEntered[2] ? (shapeFloats[2] ? 36 : 22) : -35))
                .offset(x: -96, y: 54 + (shapeFloats[2] ? -8 : 0))

            // Shape 4: 右下青色实心圆角三角
            TriangleShape(isRounded: true)
                .fill(Color.nemoSplashGlowTeal)
                .frame(width: 17, height: 17)
                .scaleEffect(shapeEntered[3] ? (shapeFloats[3] ? 1.08 : 1.0) : 0.001)
                .opacity(shapeEntered[3] ? 0.85 : 0.0)
                .rotationEffect(.degrees(shapeEntered[3] ? (shapeFloats[3] ? -6 : -20) : -35))
                .offset(x: 98, y: 52 + (shapeFloats[3] ? -8 : 0))

            // Shape 5: 顶部偏右浅紫空心心形（描边 2.6pt）
            HeartShape()
                .stroke(Color.nemoSplashShapeViolet, style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                .frame(width: 15, height: 15)
                .scaleEffect(shapeEntered[4] ? (shapeFloats[4] ? 1.08 : 1.0) : 0.001)
                .opacity(shapeEntered[4] ? 0.78 : 0.0)
                .rotationEffect(.degrees(shapeEntered[4] ? (shapeFloats[4] ? 26 : 12) : -35))
                .offset(x: 48, y: -78 + (shapeFloats[4] ? -8 : 0))

            // Shape 6: 底部偏左蓝色实心圆角方块（圆角 5pt）
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.nemoSplashShapeBlue)
                .frame(width: 12, height: 12)
                .scaleEffect(shapeEntered[5] ? (shapeFloats[5] ? 1.08 : 1.0) : 0.001)
                .opacity(shapeEntered[5] ? 0.72 : 0.0)
                .rotationEffect(.degrees(shapeEntered[5] ? (shapeFloats[5] ? -14 : -28) : -35))
                .offset(x: -38, y: 74 + (shapeFloats[5] ? -8 : 0))
        }
        .frame(width: 300, height: 240)
    }

    // MARK: - 1.3 中央 "Welcome!" 英文与微笑弧线子视图

    @ViewBuilder
    private var centerWelcomeBannerView: some View {
        let characters = ["W", "e", "l", "c", "o", "m", "e", "!"]

        VStack(spacing: 4) {
            HStack(spacing: 0) {
                ForEach(0..<characters.count, id: \.self) { index in
                    Text(characters[index])
                        .font(.system(size: 44, weight: .heavy, design: .rounded))
                        .foregroundStyle(foregroundColor)
                        .tracking(-0.88)
                        .offset(y: charPushed[index] ? 0 : 18)
                        .scaleEffect(charPushed[index] ? 1.0 : 0.82)
                        .rotationEffect(.degrees(charPushed[index] ? 0 : 4))
                        .opacity(charPushed[index] ? 1.0 : 0.0)
                }
            }

            // 微笑顺滑贝塞尔弧线
            SmileArcShape(progress: arcProgress)
                .stroke(
                    foregroundColor.opacity(0.22),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 116, height: 14)
        }
    }

    // MARK: - 2. 底部品牌锁（Logo + 分割线 + Nemo 文本展开）

    @ViewBuilder
    private var bottomBrandLockupView: some View {
        let nemoTargetWidth: CGFloat = 96
        let currentClipWidth = nemoTargetWidth * nameRevealProgress
        let nameTranslateX = (nameRevealProgress - 1.0) * nemoTargetWidth

        HStack(spacing: 0) {
            // 1. 品牌 Logo（60x60pt，原生圆角比例呈现）
            Image("NemoSplashLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .scaleEffect(logoScale)

            // 间隙 1：Logo 与分割线动态展开
            Spacer()
                .frame(width: lockupGap)

            // 2. 竖向分割线（高 34pt，宽 2pt，G2 连续圆角）
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(foregroundColor)
                .frame(width: 2, height: 34)
                .scaleEffect(y: dividerScaleY, anchor: .center)
                .opacity(dividerAlpha)

            // 间隙 2：分割线与 Nemo 动态展开
            Spacer()
                .frame(width: lockupGap)

            // 3. 展开呈现的 "Nemo" 英文
            ZStack(alignment: .leading) {
                Text("Nemo")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(foregroundColor)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(width: nemoTargetWidth, alignment: .leading)
                    .offset(x: nameTranslateX)
            }
            .frame(width: currentClipWidth, alignment: .leading)
            .clipped()
        }
    }

    // MARK: - 动效编排主时间线（严格对齐 Android 毫秒级节拍）

    @MainActor
    private func startSplashAnimationTimeline() async {
        // 无障碍减弱动态支持：若开启减弱动效，直接呈现就位状态并在 1.2 秒后轻柔转场
        if reduceMotion {
            withAnimation(.easeIn(duration: 0.3)) {
                logoScale = 1.0
                lockupGap = 14
                nameRevealProgress = 1.0
                dividerScaleY = 1.0
                dividerAlpha = 0.35
                stageAlpha = 1.0
                arcProgress = 1.0
                for i in 0..<8 { charPushed[i] = true }
                for i in 0..<6 { shapeEntered[i] = true }
            }
            try? await Task.sleep(for: .seconds(1.2))
            onFinished()
            return
        }

        // 1. 100ms: 品牌 Logo 弹出（原生弹性弹跳）
        try? await Task.sleep(for: .milliseconds(100))
        withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
            logoScale = 1.0
        }

        // 2. 550ms: 品牌 Logo 执行 Push 抖动反馈，同时展开间隙并呈现 Nemo 英文
        try? await Task.sleep(for: .milliseconds(450))
        // 触觉轻微反馈
        hapticTrigger.toggle()

        // Push 弹簧微抖序列 (1.0 -> 0.9 -> 1.05 -> 1.0)
        withAnimation(.easeOut(duration: 0.175)) {
            logoScale = 0.90
        }
        try? await Task.sleep(for: .milliseconds(175))
        withAnimation(.easeInOut(duration: 0.175)) {
            logoScale = 1.05
        }
        try? await Task.sleep(for: .milliseconds(175))
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            logoScale = 1.0
        }

        // 间隙与 "Nemo" 文本平滑展开
        withAnimation(.spring(response: 0.82, dampingFraction: 0.78)) {
            lockupGap = 14
            nameRevealProgress = 1.0
        }

        // 3. 1050ms: 竖向分割线生长拉伸展开
        try? await Task.sleep(for: .milliseconds(150))
        withAnimation(.spring(response: 0.38, dampingFraction: 0.8)) {
            dividerScaleY = 1.0
            dividerAlpha = 0.35
        }

        // 4. 1100ms: 中央舞台淡入，激发 Welcome! 字母弹跳、光晕与几何体
        try? await Task.sleep(for: .milliseconds(50))
        withAnimation(.easeOut(duration: 0.65)) {
            stageAlpha = 1.0
        }

        // 启动深海光晕 4.2s 循环呼吸动效
        withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
            isBreathing = true
        }

        // Welcome! 8 个字母依次弹跳出场（每字延时 55ms）
        for i in 0..<8 {
            Task { @MainActor in
                let delay = Double(i) * 0.055 + 0.08
                try? await Task.sleep(for: .seconds(delay))
                withAnimation(.spring(response: 0.52, dampingFraction: 0.62)) {
                    charPushed[i] = true
                }
            }
        }

        // 微笑弧线顺滑绘制（延时 550ms）
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(550))
            withAnimation(.easeInOut(duration: 0.70)) {
                arcProgress = 1.0
            }
        }

        // 6 组小几何图形弹性弹出入场并开启独立周期浮动
        let shapeDelays: [Double] = [0.12, 0.20, 0.28, 0.34, 0.40, 0.46]
        let floatPeriods: [Double] = [3.2, 3.8, 3.5, 4.0, 3.4, 3.7]

        for i in 0..<6 {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(shapeDelays[i]))
                withAnimation(.spring(response: 0.60, dampingFraction: 0.65)) {
                    shapeEntered[i] = true
                }
                // 形状入场后，启动各自独立周期的微悬浮浮动
                try? await Task.sleep(for: .milliseconds(600))
                withAnimation(.easeInOut(duration: floatPeriods[i]).repeatForever(autoreverses: true)) {
                    shapeFloats[i] = true
                }
            }
        }

        // 5. 2400ms: 所有品牌与欢迎动效完整展现就位后，触发完成回调，进入主页
        try? await Task.sleep(for: .milliseconds(1300))
        onFinished()
    }
}

// MARK: - 矢量图形辅助几何定义（与 Android 保持绝对一致）

/// 心形矢量路径（基于 24x24 viewBox 等比适配）
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let scaleX = rect.width / 24.0
        let scaleY = rect.height / 24.0

        path.move(to: CGPoint(x: 12.0 * scaleX, y: 21.35 * scaleY))
        path.addLine(to: CGPoint(x: (12.0 - 1.45) * scaleX, y: (21.35 - 1.32) * scaleY))
        path.addCurve(
            to: CGPoint(x: 2.0 * scaleX, y: 8.5 * scaleY),
            control1: CGPoint(x: 5.4 * scaleX, y: 15.36 * scaleY),
            control2: CGPoint(x: 2.0 * scaleX, y: 12.28 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 7.5 * scaleX, y: 3.0 * scaleY),
            control1: CGPoint(x: 2.0 * scaleX, y: 5.42 * scaleY),
            control2: CGPoint(x: 4.42 * scaleX, y: 3.0 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 12.0 * scaleX, y: 5.09 * scaleY),
            control1: CGPoint(x: 9.24 * scaleX, y: 3.0 * scaleY),
            control2: CGPoint(x: 10.91 * scaleX, y: 3.81 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 16.5 * scaleX, y: 3.0 * scaleY),
            control1: CGPoint(x: 13.09 * scaleX, y: 3.81 * scaleY),
            control2: CGPoint(x: 14.76 * scaleX, y: 3.0 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 22.0 * scaleX, y: 8.5 * scaleY),
            control1: CGPoint(x: 19.58 * scaleX, y: 3.0 * scaleY),
            control2: CGPoint(x: 22.0 * scaleX, y: 5.42 * scaleY)
        )
        path.addCurve(
            to: CGPoint(x: 13.45 * scaleX, y: 19.89 * scaleY),
            control1: CGPoint(x: 22.0 * scaleX, y: 12.28 * scaleY),
            control2: CGPoint(x: 18.6 * scaleX, y: 15.36 * scaleY)
        )
        path.closeSubpath()
        return path
    }
}

/// 三角形矢量路径（基于 24x24 viewBox 等比适配，支持圆角与尖角）
struct TriangleShape: Shape {
    var isRounded: Bool = false

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let scaleX = rect.width / 24.0
        let scaleY = rect.height / 24.0

        if isRounded {
            // 实心圆角三角
            path.move(to: CGPoint(x: 10.3 * scaleX, y: 3.9 * scaleY))
            path.addCurve(
                to: CGPoint(x: 13.7 * scaleX, y: 3.9 * scaleY),
                control1: CGPoint(x: 11.05 * scaleX, y: 2.6 * scaleY),
                control2: CGPoint(x: 12.95 * scaleX, y: 2.6 * scaleY)
            )
            path.addLine(to: CGPoint(x: 21.2 * scaleX, y: 16.9 * scaleY))
            path.addCurve(
                to: CGPoint(x: 19.5 * scaleX, y: 19.8 * scaleY),
                control1: CGPoint(x: 21.95 * scaleX, y: 18.2 * scaleY),
                control2: CGPoint(x: 21.0 * scaleX, y: 19.8 * scaleY)
            )
            path.addLine(to: CGPoint(x: 4.5 * scaleX, y: 19.8 * scaleY))
            path.addCurve(
                to: CGPoint(x: 2.8 * scaleX, y: 16.9 * scaleY),
                control1: CGPoint(x: 3.0 * scaleX, y: 19.8 * scaleY),
                control2: CGPoint(x: 2.05 * scaleX, y: 18.2 * scaleY)
            )
            path.closeSubpath()
        } else {
            // 空心三角
            path.move(to: CGPoint(x: 12.0 * scaleX, y: 3.0 * scaleY))
            path.addLine(to: CGPoint(x: 22.0 * scaleX, y: 20.0 * scaleY))
            path.addLine(to: CGPoint(x: 2.0 * scaleX, y: 20.0 * scaleY))
            path.closeSubpath()
        }
        return path
    }
}

/// 微笑弧线矢量路径（带绘制进度动画，二次贝塞尔曲线 M6 10 Q 60 2 114 9）
struct SmileArcShape: Shape {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let scaleX = rect.width / 120.0
        let scaleY = rect.height / 14.0

        path.move(to: CGPoint(x: 6.0 * scaleX, y: 10.0 * scaleY))
        path.addQuadCurve(
            to: CGPoint(x: 114.0 * scaleX, y: 9.0 * scaleY),
            control: CGPoint(x: 60.0 * scaleX, y: 2.0 * scaleY)
        )

        if progress < 1.0 {
            return path.trimmedPath(from: 0, to: progress)
        }
        return path
    }
}

#Preview {
    NemoSplashView()
}
