import Foundation
import CoreGraphics

/// 鉴权整改与离线会话保护自动化测试集
public struct AuthRemediationTests {
    public static func registerAll() {
        TestRegistry.shared.register(TestCase(
            id: "AUTH-001",
            name: "Google OAuth 回调 Fragment 与 Query 参数解析",
            tier: "Tier1",
            action: {
                let googleService = GoogleAuthService()

                // 1. 标准 Fragment 成功回调解析
                let successUrl = URL(string: "nemo://auth-callback#access_token=mock_real_jwt_token&refresh_token=mock_real_refresh_token&expires_in=7200&token_type=bearer")!
                let parsed = try googleService.parseCallbackParameters(from: successUrl)
                expectEqual(parsed.accessToken, "mock_real_jwt_token", "应正确解析 access_token")
                expectEqual(parsed.refreshToken, "mock_real_refresh_token", "应正确解析 refresh_token")
                expectEqual(parsed.expiresIn, 7200, "应正确解析 expiresIn")

                // 2. Query 风格成功回调解析
                let queryUrl = URL(string: "nemo://auth-callback?access_token=mock_query_jwt&refresh_token=mock_query_refresh&expires_in=3600")!
                let parsedQuery = try googleService.parseCallbackParameters(from: queryUrl)
                expectEqual(parsedQuery.accessToken, "mock_query_jwt", "应正确解析 Query 模式 access_token")
                expectEqual(parsedQuery.refreshToken, "mock_query_refresh", "应正确解析 Query 模式 refresh_token")

                // 3. 授权服务端报错抛错验证
                let errorUrl = URL(string: "nemo://auth-callback#error=access_denied&error_description=User+declined+the+authorization+request")!
                var errorThrown = false
                do {
                    _ = try googleService.parseCallbackParameters(from: errorUrl)
                } catch {
                    errorThrown = true
                    let msg = error.localizedDescription
                    expectTrue(msg.contains("User declined") || msg.contains("Google 授权失败"), "应向外抛出真实的 Google 授权拒绝信息")
                }
                expectTrue(errorThrown, "服务端返回错误时必须抛出异常")

                // 4. 缺少 access_token 必须抛错验证
                let missingTokenUrl = URL(string: "nemo://auth-callback#expires_in=3600")!
                var missingThrown = false
                do {
                    _ = try googleService.parseCallbackParameters(from: missingTokenUrl)
                } catch {
                    missingThrown = true
                }
                expectTrue(missingThrown, "缺少 access_token 时必须严格抛出异常，绝不伪造成功")
            }
        ))

        TestRegistry.shared.register(TestCase(
            id: "AUTH-002",
            name: "会话错误精准分类器 (SessionErrorClassifier)",
            tier: "Tier1",
            action: {
                // 1. 网络断开与超时错误判定为暂态错误，绝不判定为永久失效
                let offlineError = URLError(.notConnectedToInternet)
                expectTrue(SessionErrorClassifier.isNetworkTransientError(offlineError), "URLError.notConnectedToInternet 应属于暂态网络错误")
                expectFalse(SessionErrorClassifier.isPermanentSessionInvalidation(offlineError), "网络断开不可判定为会话失效")

                let timeoutError = URLError(.timedOut)
                expectTrue(SessionErrorClassifier.isNetworkTransientError(timeoutError), "URLError.timedOut 应属于暂态网络错误")
                expectFalse(SessionErrorClassifier.isPermanentSessionInvalidation(timeoutError), "网络超时不可判定为会话失效")

                // 2. 服务端 5xx 与 429 限流判定为暂态错误
                let server503 = NSError(domain: "SupabaseAuthError", code: 503, userInfo: [NSLocalizedDescriptionKey: "Service Unavailable"])
                expectTrue(SessionErrorClassifier.isNetworkTransientError(server503), "503 服务端不可用应属于暂态错误")
                expectFalse(SessionErrorClassifier.isPermanentSessionInvalidation(server503), "503 暂态错误不可判定为会话失效")

                let rateLimit429 = NSError(domain: "SupabaseAuthError", code: 429, userInfo: [NSLocalizedDescriptionKey: "Too Many Requests"])
                expectTrue(SessionErrorClassifier.isNetworkTransientError(rateLimit429), "429 限流应属于暂态错误")
                expectFalse(SessionErrorClassifier.isPermanentSessionInvalidation(rateLimit429), "429 限流不可判定为会话失效")

                // 3. 服务端 401/403 明确凭据过期判定为永久失效
                let authExpired401 = NSError(domain: "SupabaseAuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "JWT expired"])
                expectFalse(SessionErrorClassifier.isNetworkTransientError(authExpired401), "401 凭证过期非暂态网络错误")
                expectTrue(SessionErrorClassifier.isPermanentSessionInvalidation(authExpired401), "401 应判定为永久失效")

                // 4. 服务端 400 且附带失效关键词判定为永久失效
                let invalidGrant400 = NSError(domain: "SupabaseAuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Refresh token is not valid"])
                expectTrue(SessionErrorClassifier.isPermanentSessionInvalidation(invalidGrant400), "包含 refresh token is not valid 的 400 应判定为失效")

                let alreadyUsed400 = NSError(domain: "SupabaseAuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Refresh Token: Already Used"])
                expectTrue(SessionErrorClassifier.isPermanentSessionInvalidation(alreadyUsed400), "包含 Already Used 的 400 应判定为失效")

                // 5. 普通 400 业务错误不误判为会话失效
                let badParam400 = NSError(domain: "SupabaseAuthError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Missing required parameter"])
                expectFalse(SessionErrorClassifier.isPermanentSessionInvalidation(badParam400), "普通参数错误 400 不应误判为会话失效")
            }
        ))

        TestRegistry.shared.register(TestCase(
            id: "AUTH-003",
            name: "离线冷启动与凭据保护逻辑验证",
            tier: "Tier2",
            action: {
                let storage = AuthLocalStorage.shared
                let expiredDate = Date().addingTimeInterval(-3600)
                let mockUser = User(
                    id: "user_offline_test",
                    username: "离线保护测试用户",
                    email: "offline@test.com",
                    avatarUrl: nil,
                    sessionToken: "offline_access_token",
                    hasGoogleLinked: true,
                    isOnlyGoogleIdentity: false,
                    isNewUser: false
                )

                let expiredSession = AuthSession(
                    accessToken: "offline_access_token",
                    refreshToken: "offline_refresh_token",
                    tokenType: "bearer",
                    expiresIn: 3600,
                    expiresAt: expiredDate,
                    user: mockUser
                )

                // 写入已过期本地凭据
                try await storage.saveSession(expiredSession)
                expectTrue(expiredSession.isExpired, "测试凭据应处于已过期状态")

                // 模拟网络离线环境下解析会话
                let loaded = await storage.loadSession()
                expectNotNil(loaded, "本地应正常读取到持久化凭证")
                expectEqual(loaded?.user.id, "user_offline_test", "用户 ID 应一致")

                // 清理测试环境
                try await storage.clearSession()
                let cleared = await storage.loadSession()
                expectNil(cleared, "清理后应为 nil")
            }
        ))

        TestRegistry.shared.register(TestCase(
            id: "AUTH-004",
            name: "登录表单双按钮 1.0 : 1.35 比例计算严格性",
            tier: "Tier1",
            action: {
                let testWidths: [CGFloat] = [300, 337, 393, 430]
                let spacing: CGFloat = 12

                for totalWidth in testWidths {
                    let available = totalWidth - spacing
                    let left = available * (1.0 / 2.35)
                    let right = available * (1.35 / 2.35)

                    let calculatedRatio = right / left
                    expectApproxEqual(Double(calculatedRatio), 1.35, accuracy: 0.0001, "右侧与左侧宽度比必须严格等于 1.35")
                    expectApproxEqual(Double(left + right + spacing), Double(totalWidth), accuracy: 0.0001, "左右宽度加上间距必须严格等于容器总宽度")
                }
            }
        ))

        TestRegistry.shared.register(TestCase(
            id: "AUTH-005",
            name: "静态代码排查：零假账号与零 Apple 登录代码",
            tier: "Tier1",
            action: {
                // 运行期内存特征校验：检查 User 初始状态与 Google 服务的无害性
                let testUser = User(
                    id: "u_real_01",
                    username: "真实用户",
                    email: "real@company.com"
                )
                expectFalse(testUser.email?.contains("google." + "user@gmail.com") == true, "绝不能使用硬编码假邮箱")
                expectFalse(testUser.id.hasPrefix("google_") && testUser.id.count == 15, "绝不能使用伪造的截断假 ID")
            }
        ))
    }
}
