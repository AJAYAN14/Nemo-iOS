import Foundation
import Network
import UserNotifications

/// 应用启动系统权限申请与网络连通性协同中枢
@MainActor
public final class SystemPermissionCoordinator {
    public static let shared = SystemPermissionCoordinator()

    public private(set) var isProbeTriggered: Bool = false
    public private(set) var isMonitoringActive: Bool = false
    public private(set) var isNotificationRequested: Bool = false
    public private(set) var isNetworkSatisfied: Bool = false

    private let pathMonitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.jian.nemo.network.monitor")
    private let probeSession: URLSession

    public init(
        pathMonitor: NWPathMonitor = NWPathMonitor(),
        probeSession: URLSession = .shared
    ) {
        self.pathMonitor = pathMonitor
        self.probeSession = probeSession
    }

    /// 启动生命周期统一入口：发起网络探针、监听链路并申请通知权限
    public func requestStartupPermissionsAndProbeNetwork() {
        triggerNetworkProbe()
        startNetworkMonitoring()
        Task {
            await requestNotificationPermission()
        }
    }

    /// 主动发起轻量网络探针以激活国行 iOS 蜂窝与无线局域网授权提示
    public func triggerNetworkProbe() {
        guard !isProbeTriggered else { return }
        isProbeTriggered = true

        guard let url = URL(string: "https://ccggidebxekvqbpjktxl.supabase.co/rest/v1/") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0

        let task = probeSession.dataTask(with: request) { _, _, _ in
            // 静默探针：网络通信建立尝试将激活系统入网判定
        }
        task.resume()
    }

    /// 开启网络状态持续监听；网络可用时自动触发词库补录更新
    public func startNetworkMonitoring() {
        guard !isMonitoringActive else { return }
        isMonitoringActive = true

        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let satisfied = (path.status == .satisfied)
                self.isNetworkSatisfied = satisfied

                if satisfied {
                    AppStartupManager.shared.performStartupSync()
                }
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    /// 停止网络监听
    public func stopNetworkMonitoring() {
        guard isMonitoringActive else { return }
        pathMonitor.pathUpdateHandler = nil
        pathMonitor.cancel()
        isMonitoringActive = false
    }

    /// 主动申请系统通知权限（对齐 Android POST_NOTIFICATIONS）
    @discardableResult
    public func requestNotificationPermission() async -> Bool {
        isNotificationRequested = true
        guard Bundle.main.bundleIdentifier != nil else {
            return true
        }
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }
}
