Token rotation in iOS (including SwiftUI apps) is a **security mechanism** where your app periodically replaces expired or soon-to-expire access tokens with new ones using a refresh token. This ensures users stay authenticated **without repeatedly logging in**, while also reducing security risks.

---

## 🔑 Core Concepts

### 1. Access Token

* Short-lived (e.g., 15–60 minutes)
* Sent with API requests (Authorization header)
* If leaked, damage is limited due to short expiry

### 2. Refresh Token

* Long-lived (days/weeks)
* Used to request a new access token
* Stored securely (e.g., Keychain)

---

## 🔄 Token Rotation Flow

1. User logs in → server returns:

   * accessToken
   * refreshToken

2. App makes API requests using accessToken

3. When accessToken expires:

   * App sends refreshToken to server

4. Server validates refreshToken and returns:

   * new accessToken
   * (sometimes) new refreshToken → **this is rotation**

5. App updates stored tokens

---

## ⚠️ Why Token Rotation Matters

* Prevents reuse of stolen refresh tokens
* Each refresh invalidates the previous refresh token
* Adds an extra layer of security

---

## 🧠 Architecture in SwiftUI

You typically structure it like this:

```
SwiftUI View
   ↓
ViewModel (MVVM)
   ↓
AuthManager / TokenManager
   ↓
Network Layer
```

---

## 🧱 Implementation Breakdown

### 1. Token Storage (Keychain)

```swift
final class TokenStorage {
    
    static let shared = TokenStorage()
    
    private init() {}
    
    func save(accessToken: String, refreshToken: String) {
        KeychainHelper.save("accessToken", value: accessToken)
        KeychainHelper.save("refreshToken", value: refreshToken)
    }
    
    func getAccessToken() -> String? {
        KeychainHelper.get("accessToken")
    }
    
    func getRefreshToken() -> String? {
        KeychainHelper.get("refreshToken")
    }
}
```

---

### 2. Auth Manager (Handles Rotation)

```swift
actor AuthManager {
    
    static let shared = AuthManager()
    
    private var isRefreshing = false
    
    func getValidAccessToken() async throws -> String {
        
        if let token = TokenStorage.shared.getAccessToken(),
           !isTokenExpired(token) {
            return token
        }
        
        return try await refreshAccessToken()
    }
    
    private func refreshAccessToken() async throws -> String {
        
        guard let refreshToken = TokenStorage.shared.getRefreshToken() else {
            throw AuthError.noRefreshToken
        }
        
        let newTokens = try await APIService.refreshToken(refreshToken)
        
        TokenStorage.shared.save(
            accessToken: newTokens.accessToken,
            refreshToken: newTokens.refreshToken
        )
        
        return newTokens.accessToken
    }
}
```

---

### 3. Network Layer (Auto Retry)

```swift
final class APIClient {
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        
        do {
            let token = try await AuthManager.shared.getValidAccessToken()
            return try await performRequest(endpoint, token: token)
            
        } catch {
            
            // If unauthorized, try refreshing once
            if case APIError.unauthorized = error {
                
                let newToken = try await AuthManager.shared.refreshAccessToken()
                return try await performRequest(endpoint, token: newToken)
            }
            
            throw error
        }
    }
}
```

---

### 4. SwiftUI Usage

```swift
@MainActor
final class ProfileViewModel: ObservableObject {
    
    @Published var user: User?
    
    func loadProfile() async {
        do {
            user = try await APIClient().request(.profile)
        } catch {
            print("Error: \(error)")
        }
    }
}
```

```swift
struct ProfileView: View {
    
    @StateObject private var vm = ProfileViewModel()
    
    var body: some View {
        Text(vm.user?.name ?? "Loading...")
            .task {
                await vm.loadProfile()
            }
    }
}
```

---

## 🔐 Best Practices

* Store tokens in **Keychain**, NOT UserDefaults
* Use **actor** to avoid race conditions during refresh
* Allow only **one refresh call at a time**
* Handle refresh token expiry → force logout
* Use **HTTP 401** to trigger refresh logic
* Rotate refresh tokens on every use (if backend supports)

---

## 🚨 Common Pitfalls

* Multiple API calls triggering multiple refresh requests ❌
* Not updating refresh token after rotation ❌
* Storing tokens insecurely ❌
* Infinite retry loops ❌

---

## 💡 Pro Tip (Senior-Level)

Implement a **request queue while refreshing**:

* If token refresh is in progress:

  * Queue API calls
  * Resume them after refresh completes

This avoids duplicate refresh calls and improves performance.

---

If you want, I can:

* Build a **production-ready architecture (with retry + caching + interceptor)**
* Add **Combine / async-await comparison**
* Show **unit tests for token rotation logic**

Just tell me 👍


Great—this is where most candidates struggle in interviews, so doing it properly gives you a big edge.

Below is a **clean, testable setup using Swift Testing (modern Apple testing framework)** for token rotation logic.

---

# 🧪 What We’ll Test

We’ll cover:

1. ✅ Returns valid token if not expired
2. ✅ Refreshes token when expired
3. ✅ Saves rotated tokens correctly
4. ✅ Handles refresh failure
5. ✅ Prevents multiple simultaneous refresh calls

---

# 🧱 Step 1: Make Code Testable

### Protocols for Dependency Injection

```swift
protocol TokenStoring {
    func getAccessToken() -> String?
    func getRefreshToken() -> String?
    func save(accessToken: String, refreshToken: String)
}

protocol AuthServicing {
    func refreshToken(_ refreshToken: String) async throws -> TokenResponse
}
```

---

### Models

```swift
struct TokenResponse {
    let accessToken: String
    let refreshToken: String
}
```

---

### AuthManager (Testable Version)

```swift
actor AuthManager {
    
    private let storage: TokenStoring
    private let service: AuthServicing
    
    private var refreshTask: Task<String, Error>?
    
    init(storage: TokenStoring, service: AuthServicing) {
        self.storage = storage
        self.service = service
    }
    
    func getValidAccessToken() async throws -> String {
        
        if let token = storage.getAccessToken(),
           !isExpired(token) {
            return token
        }
        
        return try await refreshAccessToken()
    }
    
    private func refreshAccessToken() async throws -> String {
        
        if let existingTask = refreshTask {
            return try await existingTask.value
        }
        
        let task = Task<String, Error> {
            defer { refreshTask = nil }
            
            guard let refreshToken = storage.getRefreshToken() else {
                throw AuthError.noRefreshToken
            }
            
            let response = try await service.refreshToken(refreshToken)
            
            storage.save(
                accessToken: response.accessToken,
                refreshToken: response.refreshToken
            )
            
            return response.accessToken
        }
        
        refreshTask = task
        return try await task.value
    }
    
    private func isExpired(_ token: String) -> Bool {
        token.contains("expired") // simplified for testing
    }
}
```

---

# 🧪 Step 2: Mock Implementations

```swift
final class MockStorage: TokenStoring {
    
    var accessToken: String?
    var refreshToken: String?
    
    func getAccessToken() -> String? { accessToken }
    func getRefreshToken() -> String? { refreshToken }
    
    func save(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
```

```swift
final class MockAuthService: AuthServicing {
    
    var refreshCallCount = 0
    var shouldFail = false
    
    func refreshToken(_ refreshToken: String) async throws -> TokenResponse {
        refreshCallCount += 1
        
        if shouldFail {
            throw AuthError.refreshFailed
        }
        
        return TokenResponse(
            accessToken: "new_access_token",
            refreshToken: "new_refresh_token"
        )
    }
}
```

---

# 🧪 Step 3: Swift Testing Unit Tests

> Uses `import Testing` (not XCTest)

---

### 1. ✅ Returns Existing Token if Valid

```swift
import Testing

@Test
func returnsExistingTokenIfValid() async throws {
    
    let storage = MockStorage()
    storage.accessToken = "valid_token"
    storage.refreshToken = "refresh_token"
    
    let service = MockAuthService()
    
    let manager = AuthManager(storage: storage, service: service)
    
    let token = try await manager.getValidAccessToken()
    
    #expect(token == "valid_token")
    #expect(service.refreshCallCount == 0)
}
```

---

### 2. 🔄 Refreshes When Token Expired

```swift
@Test
func refreshesTokenWhenExpired() async throws {
    
    let storage = MockStorage()
    storage.accessToken = "expired_token"
    storage.refreshToken = "refresh_token"
    
    let service = MockAuthService()
    
    let manager = AuthManager(storage: storage, service: service)
    
    let token = try await manager.getValidAccessToken()
    
    #expect(token == "new_access_token")
    #expect(service.refreshCallCount == 1)
}
```

---

### 3. 🔁 Saves Rotated Tokens

```swift
@Test
func savesRotatedTokens() async throws {
    
    let storage = MockStorage()
    storage.accessToken = "expired_token"
    storage.refreshToken = "old_refresh"
    
    let service = MockAuthService()
    
    let manager = AuthManager(storage: storage, service: service)
    
    _ = try await manager.getValidAccessToken()
    
    #expect(storage.accessToken == "new_access_token")
    #expect(storage.refreshToken == "new_refresh_token")
}
```

---

### 4. ❌ Handles Refresh Failure

```swift
@Test
func throwsErrorWhenRefreshFails() async {
    
    let storage = MockStorage()
    storage.accessToken = "expired_token"
    storage.refreshToken = "refresh_token"
    
    let service = MockAuthService()
    service.shouldFail = true
    
    let manager = AuthManager(storage: storage, service: service)
    
    await #expect(throws: AuthError.refreshFailed) {
        try await manager.getValidAccessToken()
    }
}
```

---

### 5. 🚦 Prevents Multiple Refresh Calls (Concurrency Test)

```swift
@Test
func onlyOneRefreshCallForConcurrentRequests() async throws {
    
    let storage = MockStorage()
    storage.accessToken = "expired_token"
    storage.refreshToken = "refresh_token"
    
    let service = MockAuthService()
    
    let manager = AuthManager(storage: storage, service: service)
    
    async let t1 = manager.getValidAccessToken()
    async let t2 = manager.getValidAccessToken()
    async let t3 = manager.getValidAccessToken()
    
    let results = try await [t1, t2, t3]
    
    #expect(results.allSatisfy { $0 == "new_access_token" })
    #expect(service.refreshCallCount == 1) // 🔥 critical assertion
}
```

---

# 🧠 Key Takeaways (Senior-Level)

* Use **protocols** → makes testing easy
* Use **actor + Task caching** → avoids duplicate refresh calls
* Test **concurrency explicitly** → most people skip this
* Always verify **side effects (storage updates)**

---

If you want next level:

* Add **APIClient tests with 401 retry**
* Add **integration tests with URLProtocol mocking**
* Add **token expiry decoding from JWT instead of string hack**

Just tell me 👍

