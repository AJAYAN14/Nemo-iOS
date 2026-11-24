import SwiftUI

/// 原生质感认证专用输入框组件
public struct AuthTextField: View {
    @Binding public var text: String
    public var placeholder: String
    public var systemImage: String
    public var isSecure: Bool
    public var isPasswordVisible: Binding<Bool>?
    public var isError: Bool
    public var keyboardType: UIKeyboardType
    public var textContentType: UITextContentType?
    public var onSubmit: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool

    public init(
        text: Binding<String>,
        placeholder: String,
        systemImage: String,
        isSecure: Bool = false,
        isPasswordVisible: Binding<Bool>? = nil,
        isError: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.systemImage = systemImage
        self.isSecure = isSecure
        self.isPasswordVisible = isPasswordVisible
        self.isError = isError
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.onSubmit = onSubmit
    }

    private var isDark: Bool {
        colorScheme == .dark
    }

    private var containerBackground: Color {
        if isDark {
            return Color(red: 0.086, green: 0.082, blue: 0.106) // #16151B
        } else {
            return Color.white
        }
    }

    private var borderColor: Color {
        if isError {
            return Color.red.opacity(0.85)
        }
        if isFocused {
            return Color(red: 0.14, green: 0.38, blue: 0.96)
        }
        if isDark {
            return Color.white.opacity(0.08)
        } else {
            return Color(red: 0.88, green: 0.91, blue: 0.94) // #E2E8F0
        }
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(isError ? .red : (isFocused ? Color(red: 0.14, green: 0.38, blue: 0.96) : (isDark ? Color.white.opacity(0.45) : Color(red: 0.58, green: 0.64, blue: 0.72))))
                .frame(width: 22)

            Group {
                if isSecure && !(isPasswordVisible?.wrappedValue ?? false) {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: 15))
            .foregroundStyle(isDark ? Color.white : Color(red: 0.06, green: 0.09, blue: 0.16))
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .focused($isFocused)
            .onSubmit {
                onSubmit?()
            }

            if let passwordVisible = isPasswordVisible {
                Button {
                    passwordVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: passwordVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(isDark ? Color.white.opacity(0.45) : Color(red: 0.58, green: 0.64, blue: 0.72))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(containerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: isFocused || isError ? 1.5 : 1.0)
        )
        .shadow(
            color: isDark ? Color.black.opacity(0.25) : Color.black.opacity(0.03),
            radius: 8,
            x: 0,
            y: 2
        )
    }
}
