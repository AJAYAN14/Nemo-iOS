//
//  NemoCardWhiteboardView.swift
//  Nemo
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// 包含颜色信息的画笔笔迹
public struct WhiteboardColoredStroke: Identifiable {
    public let id = UUID()
    public let path: Path
    public let color: Color
}

/// 学习卡片内嵌手写白板视图（1:1 对齐 Android 端 NemoWhiteboard 架构与手势）
public struct NemoCardWhiteboardView: View {
    public let wordId: Int
    public let height: CGFloat
    public var onClose: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var paths: [WhiteboardColoredStroke] = []
    @State private var currentPath: Path? = nil
    @State private var currentColor: Color = Color.primary
    @State private var isColorPaletteExpanded: Bool = false

    public init(
        wordId: Int,
        height: CGFloat = 380,
        onClose: (() -> Void)? = nil
    ) {
        self.wordId = wordId
        self.height = height
        self.onClose = onClose
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    // 预设笔刷颜色 (深/浅色模式自适应，与 Android 端 LearningPalette 对齐)
    private var penColors: [Color] {
        if isDarkMode {
            return [
                Color(red: 0.96, green: 0.96, blue: 0.97), // 珍珠白 (默认)
                Color(red: 1.00, green: 0.27, blue: 0.23), // 霓虹红
                Color(red: 0.04, green: 0.52, blue: 1.00), // 霓虹蓝
                Color(red: 0.19, green: 0.82, blue: 0.35)  // 薄荷绿
            ]
        } else {
            return [
                Color(red: 0.11, green: 0.11, blue: 0.12), // 墨黑 (默认)
                Color(red: 1.00, green: 0.23, blue: 0.19), // 正红
                Color(red: 0.00, green: 0.48, blue: 1.00), // 湖蓝
                Color(red: 0.20, green: 0.78, blue: 0.35)  // 草绿
            ]
        }
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // 1. 白板底板与画布
            Canvas { context, _ in
                for item in paths {
                    context.stroke(
                        item.path,
                        with: .color(item.color),
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round)
                    )
                }

                if let current = currentPath {
                    context.stroke(
                        current,
                        with: .color(currentColor),
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .round, lineJoin: .round)
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Color.nemoSecondaryGroupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .gesture(
                DragGesture(minimumDistance: 0.1)
                    .onChanged { value in
                        if currentPath == nil {
                            var p = Path()
                            p.move(to: value.startLocation)
                            p.addLine(to: value.location)
                            currentPath = p
                        } else {
                            currentPath?.addLine(to: value.location)
                        }
                    }
                    .onEnded { _ in
                        if let validPath = currentPath {
                            paths.append(WhiteboardColoredStroke(path: validPath, color: currentColor))
                            currentPath = nil
                        }
                    }
            )

            // 2. 顶部悬浮工具栏
            HStack(alignment: .center) {
                // 左侧关闭/退出按钮（保持 34×34 恒定对称占位）
                if let closeAction = onClose {
                    Button {
                        closeAction()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.primary.opacity(0.7))
                            .frame(width: 34, height: 34)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 34, height: 34)
                }

                Spacer()

                // 中间折叠式调色盘胶囊
                HStack(spacing: 8) {
                    if !isColorPaletteExpanded {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isColorPaletteExpanded = true
                            }
                        } label: {
                            Circle()
                                .fill(currentColor)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1.5)
                                )
                                .padding(4)
                        }
                        .buttonStyle(.plain)
                    } else {
                        ForEach(penColors.indices, id: \.self) { idx in
                            let color = penColors[idx]
                            Button {
                                currentColor = color
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isColorPaletteExpanded = false
                                }
                            } label: {
                                Circle()
                                    .fill(color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                currentColor == color ? Color.blue : Color.primary.opacity(0.15),
                                                lineWidth: currentColor == color ? 2.5 : 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, isColorPaletteExpanded ? 10 : 6)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )

                Spacer()

                // 右侧一键清空按钮（保持 34×34 恒定对称占位，消除动态左右跳动）
                if !paths.isEmpty || currentPath != nil {
                    Button {
                        paths.removeAll()
                        currentPath = nil
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.primary.opacity(0.7))
                            .frame(width: 34, height: 34)
                            .background(Color.primary.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 34, height: 34)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
        }
        .onAppear {
            currentColor = penColors[0]
        }
        .onChange(of: wordId) { _, _ in
            paths.removeAll()
            currentPath = nil
            isColorPaletteExpanded = false
            currentColor = penColors[0]
        }
    }
}
