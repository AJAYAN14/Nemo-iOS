import Foundation

/// SRS 复习间隔时间格式化工具
public enum SrsTimeFormatter {
    private static let second: Int64 = 1
    private static let minute: Int64 = 60 * second
    private static let hour: Int64 = 60 * minute
    private static let day: Int64 = 24 * hour
    private static let year: Int64 = Int64(365.25 * Double(day))
    private static let month: Int64 = year / 12

    /// 将天数格式化为按钮展示字符串（如 "< 1m", "1d", "3d", "2mo", "1.1y"）
    public static func formatInterval(days: Int) -> String {
        formatSeconds(Int64(days) * day)
    }

    /// 将秒数格式化为层次化时间字符串
    public static func formatSeconds(_ seconds: Int64) -> String {
        if seconds <= 0 {
            return "< 1m"
        }

        let absSeconds = abs(seconds)
        switch absSeconds {
        case ..<minute:
            return "\(absSeconds)s"
        case ..<hour:
            let mins = Int((Double(absSeconds) / Double(minute)).rounded())
            return "\(mins)m"
        case ..<day:
            let hours = Double(absSeconds) / Double(hour)
            return formatWithDecimal(hours, unit: "h")
        case ..<month:
            let days = Int((Double(absSeconds) / Double(day)).rounded())
            return "\(days)d"
        case ..<year:
            let months = Double(absSeconds) / Double(month)
            return formatWithDecimal(months, unit: "mo")
        default:
            let years = Double(absSeconds) / Double(year)
            return formatWithDecimal(years, unit: "y")
        }
    }

    /// 浮点数格式化：若是整数则不显示小数位，否则保留一位小数
    private static func formatWithDecimal(_ value: Double, unit: String) -> String {
        let rounded = (value * 10.0).rounded() / 10.0
        if rounded.truncatingRemainder(dividingBy: 1.0) == 0.0 {
            return "\(Int(rounded))\(unit)"
        } else {
            return String(format: "%.1f%@", rounded, unit)
        }
    }
}
