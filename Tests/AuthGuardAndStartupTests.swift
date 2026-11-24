import Foundation

/// 认证导航守卫与应用启动数据/权限自动化测试套件
public struct AuthGuardAndStartupTests {
    public static func registerAll() {
        registerGuardTests()
        registerStartupSyncTests()
        registerPermissionTests()
    }

    // MARK: - R1: 登录注册拦截与主界面导航守卫
    private static func registerGuardTests() {
        TestRegistry.shared.register(TestCase(
            id: "GUARD-001",
            name: "未登录冷启动导航守卫阻断",
            tier: "Tier1",
            action: {
                let mockAuth = MockAuthService(initialUser: nil)
                let store = await AuthStore(authService: mockAuth)

                // 模拟冷启动生命周期会话解析
                await store.resolveSession()

                let isResolved = await store.isSessionResolved
                let isLoggedIn = await store.isLoggedIn
                let shouldShowMain = await store.shouldShowMainInterface
                let shouldShowAuth = await store.shouldShowAuthentication
                let navState = await store.navigationState

                expectTrue(isResolved, "冷启动解析必须完成")
                expectFalse(isLoggedIn, "未登录状态下 isLoggedIn 必须为 false")
                expectFalse(shouldShowMain, "未登录状态下严禁挂载主界面 ContentView")
                expectTrue(shouldShowAuth, "未登录状态下必须受控展示登录注册流程 LoginScreenView")
                expectEqual(navState, .unauthenticated, "未登录导航状态必须为 unauthenticated")
            }
        ))

        TestRegistry.shared.register(TestCase(
            id: "GUARD-002",
            name: "登录成功放行进入主界面",
            tier: "Tier1",
            action: {
                let mockAuth = MockAuthService(initialUser: nil)
                let store = await AuthStore(authService: mockAuth)
                await store.resolveSession()

                // 执行正常登录
                let loginSuccess = await store.login(email: "nemo_guard_test@test.local", password: "password123")
                expectTrue(loginSuccess, "合规凭证登录操作必须成功")

                let isLoggedIn = await store.isLoggedIn
                let shouldShowMain = await store.shouldShowMainInterface
                let shouldShowAuth = await store.shouldShowAuthentication
                let navState = await store.navigationState
                let currentUser = await store.currentUser

                expectTrue(isLoggedIn, "登录成功后 isLoggedIn 必须为 true")
                expectTrue(shouldShowMain, "登录成功后应放行主界面")
                expectFalse(shouldShowAuth, "登录成功后应卸载登录阻断页")
                expectEqual(navState, .authenticated, "登录成功后导航状态必须为 authenticated")
                expectNotNil(currentUser, "登录成功后当前用户不可为空")
            }
        ))

        TestRegistry.shared.register(TestCase(
            id: "GUARD-003",
            name: "运行时登出即时拦截并卸载主界面",
            tier: "Tier1",
            action: {
                let initialUser = User(
                    id: "u_guard_logout",
                    username: "登出测试用户",
                    email: "logout@test.local"
                )
                let mockAuth = MockAuthService(initialUser: initialUser)
                let store = await AuthStore(authService: mockAuth)
                await store.resolveSession()

                let preLoggedIn = await store.isLoggedIn
                expectTrue(preLoggedIn, "初始应处于已登录状态")

                // 用户在设置中点击退出登录
                await store.logout()

                let postUser = await store.currentUser
                let postLoggedIn = await store.isLoggedIn
                let shouldShowMain = await store.shouldShowMainInterface
                let shouldShowAuth = await store.shouldShowAuthentication
                let navState = await store.navigationState

                expectNil(postUser, "退出登录后当前用户必须被置空")
                expectFalse(postLoggedIn, "退出登录后 isLoggedIn 必须为 false")
                expectFalse(shouldShowMain, "退出登录后主界面必须即刻被卸载")
                expectTrue(shouldShowAuth, "退出登录后必须受控重定向至登录注册流程")
                expectEqual(navState, .unauthenticated, "退出登录后导航状态必须为 unauthenticated")
            }
        ))
    }

    // MARK: - R2: 启动时词库数据获取与预热
    private static func registerStartupSyncTests() {
        TestRegistry.shared.register(TestCase(
            id: "STARTUP-001",
            name: "启动时词库异步同步触发与本地预热",
            tier: "Tier1",
            action: {
                let startupManager = await AppStartupManager.shared

                // 启动生命周期触发词库同步
                await startupManager.executeStartupSync()

                let isSyncing = await startupManager.isStartupSyncing
                expectFalse(isSyncing, "同步调用结束后 isStartupSyncing 必须复位为 false")

                // 验证本地预热核验接口
                await startupManager.refreshReadiness()
            }
        ))

        TestRegistry.shared.register(TestCase(
            id: "STARTUP-002",
            name: "离线弱网启动优雅降级与沙盒容错",
            tier: "Tier1",
            action: {
                let startupManager = await AppStartupManager.shared

                // 重复执行启动同步，校验连续调度容错性
                await startupManager.executeStartupSync()
                let lastError = await startupManager.lastError

                // 如果离线，不应崩溃，静默保护本地已有数据
                if let error = lastError {
                    expectTrue(error.localizedDescription.count > 0, "暂态错误应具备可排查日志信息")
                }
            }
        ))
    }

    // MARK: - R3: 启动时系统权限与网络探针
    private static func registerPermissionTests() {
        TestRegistry.shared.register(TestCase(
            id: "PERM-001",
            name: "系统权限申请与国行网络探针协同调度",
            tier: "Tier1",
            action: {
                let coordinator = await SystemPermissionCoordinator.shared

                // 触发启动权限与网络探针生命周期
                await coordinator.requestStartupPermissionsAndProbeNetwork()

                let isProbeTriggered = await coordinator.isProbeTriggered
                let isMonitoringActive = await coordinator.isMonitoringActive
                let isNotificationRequested = await coordinator.isNotificationRequested

                expectTrue(isProbeTriggered, "启动生命周期中必须主动发起网络探针以唤醒国行网络权限弹窗")
                expectTrue(isMonitoringActive, "必须激活网络状态持续监听链路")
                expectTrue(isNotificationRequested, "必须主动发起通知权限申请（对齐 Android POST_NOTIFICATIONS）")

                // 校验重复触发幂等性
                await coordinator.triggerNetworkProbe()
                await coordinator.startNetworkMonitoring()
                let probeAgain = await coordinator.isProbeTriggered
                expectTrue(probeAgain, "重复调用探针应保持安全幂等")

                // 清理监听
                await coordinator.stopNetworkMonitoring()
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        ))
    }
}
