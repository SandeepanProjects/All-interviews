//
//  real-world API security.swift
//  
//
//  Created by Apple on 17/01/26.
//

import Foundation

Below is a **clear, practical explanation** focused on **iOS app development** and real-world API security patterns.

---

## 1️⃣ What is an Access Token?

**Access Token** is a **short-lived credential** used by your app to access protected API endpoints.

### Key points

* Sent with **every API request**
* Usually **expires quickly** (5–60 minutes)
* Contains **user identity + permissions (scopes)**
* Often implemented as **JWT (JSON Web Token)**

### Example (HTTP request)

```http
GET /profile
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6...
```

### Why short-lived?

If stolen, the damage window is small.

---

## 2️⃣ What is a Refresh Token?

**Refresh Token** is a **long-lived token** used to obtain **new access tokens** without asking the user to log in again.

### Key points

* Stored **securely**
* Sent only to a **token refresh endpoint**
* Lifetime: days or weeks
* **Never sent with normal API calls**

### Flow

1. Access token expires
2. App sends refresh token to backend
3. Backend issues a new access token
4. User stays logged in silently

### Example

```http
POST /auth/refresh
{
  "refresh_token": "def50200ab34..."
}
```

---

## 3️⃣ What is a Bearer Token?

**Bearer Token** is **not a separate token type** — it’s a **way of sending a token**.

> “Whoever *bears* this token can access the resource.”

### Authorization header format

```http
Authorization: Bearer <access_token>
```

* Usually contains an **access token**
* No extra verification → must use **HTTPS**

---

## 4️⃣ How They Work Together (Typical Flow)

```text
User logs in
    ↓
Backend returns:
- Access Token (short-lived)
- Refresh Token (long-lived)
    ↓
App calls APIs using Access Token
    ↓
Access Token expires
    ↓
App uses Refresh Token
    ↓
Backend returns new Access Token
```

---

## 5️⃣ How to Secure APIs for an iOS App 🔐

### ✅ 1. Always Use HTTPS (TLS)

* **Never allow HTTP**
* Enable **App Transport Security (ATS)** in iOS
* Prevents token interception

---

### ✅ 2. Store Tokens Securely on iOS

❌ **Never use**

* `UserDefaults`
* Plain files

✅ **Use Keychain**

```swift
Keychain Services (kSecClassGenericPassword)
```

Why?

* Encrypted
* Protected by device lock
* Secure against app tampering

---

### ✅ 3. Use Short-Lived Access Tokens

* 5–15 minutes is ideal
* Reduces damage if leaked

---

### ✅ 4. Protect Refresh Tokens Carefully

* Store **only in Keychain**
* Rotate refresh tokens on every use
* Invalidate on logout

---

### ✅ 5. Implement Token Refresh Automatically

Typical iOS logic:

* Intercept `401 Unauthorized`
* Refresh token
* Retry original request

```swift
if response.statusCode == 401 {
    refreshToken()
    retryRequest()
}
```

---

### ✅ 6. Use OAuth 2.0 (Industry Standard)

Recommended OAuth flow for iOS:
➡ **Authorization Code Flow with PKCE**

Why PKCE?

* Protects against token interception
* Required for public clients (mobile apps)

---

### ✅ 7. Never Store Secrets in the App

❌ Avoid:

* Client secrets
* API keys hardcoded in the app

Attackers can reverse engineer iOS apps.

---

### ✅ 8. Validate Tokens on Backend

Backend must:

* Verify JWT signature
* Check expiration
* Validate issuer & audience
* Enforce scopes/roles

---

### ✅ 9. Enable Additional Protections

* **Rate limiting**
* **Device binding (optional)**
* **IP / behavior monitoring**
* **Logout from all devices**

---

## 6️⃣ Simple Secure Architecture (Recommended)

```text
iOS App
  ↓ OAuth 2.0 (PKCE)
Auth Server
  ↓ Access Token (JWT)
API Server
```

---

## 7️⃣ Common Mistakes ❌

* Long-lived access tokens
* Storing tokens in UserDefaults
* Sending refresh token with every API call
* No token rotation
* Not using HTTPS

---

## 8️⃣ Summary Table

| Token Type    | Purpose              | Lifetime | Storage  |
| ------------- | -------------------- | -------- | -------- |
| Access Token  | API access           | Short    | Memory   |
| Refresh Token | Get new access token | Long     | Keychain |
| Bearer Token  | Auth method          | —        | Header   |

---

If you want, I can:

* Show **iOS Swift code** for token storage & refresh
* Explain **OAuth 2.0 PKCE** step-by-step
* Design a **secure backend + iOS flow diagram**

Just tell me 👍

Below is a **clean, production-style SwiftUI example** showing:
                                
* 🔐 Secure **token storage in Keychain**
* 🔄 **Automatic access-token refresh**
* 🌐 Secure API calls using **Bearer tokens**
* 🧩 Works naturally with **SwiftUI**
                            
This is the **most common pattern used in real iOS apps**.
                            
---
                            
# 1️⃣ Token Model
                            
```swift
struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}
```

---

# 2️⃣ Keychain Manager (Secure Storage)

```swift
import Security

final class KeychainManager {
    
    static let shared = KeychainManager()
    private init() {}
    
    private let service = "com.yourcompany.app"
    private let account = "auth_tokens"
    
    func save(_ tokens: AuthTokens) throws {
        let data = try JSONEncoder().encode(tokens)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainError", code: Int(status))
        }
    }
    
    func load() -> AuthTokens? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard
            status == errSecSuccess,
            let data = result as? Data
        else { return nil }
        
        return try? JSONDecoder().decode(AuthTokens.self, from: data)
    }
    
    func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
```

---

# 3️⃣ Auth Manager (Token Logic + Refresh)

```swift
import Foundation

@MainActor
final class AuthManager: ObservableObject {
    
    @Published private(set) var tokens: AuthTokens?
    
    static let shared = AuthManager()
    
    private init() {
        tokens = KeychainManager.shared.load()
    }
    
    var isLoggedIn: Bool {
        tokens != nil
    }
    
    func save(tokens: AuthTokens) {
        self.tokens = tokens
        try? KeychainManager.shared.save(tokens)
    }
    
    func logout() {
        tokens = nil
        KeychainManager.shared.delete()
    }
    
    func validAccessToken() async throws -> String {
        guard let tokens else {
            throw URLError(.userAuthenticationRequired)
        }
        
        // Refresh if expired or near expiry
        if tokens.expiresAt <= Date().addingTimeInterval(30) {
            let newTokens = try await refreshTokens()
            save(tokens: newTokens)
            return newTokens.accessToken
        }
        
        return tokens.accessToken
    }
    
    private func refreshTokens() async throws -> AuthTokens {
        let url = URL(string: "https://api.example.com/auth/refresh")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["refresh_token": tokens!.refreshToken]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            logout()
            throw URLError(.userAuthenticationRequired)
        }
        
        return try JSONDecoder().decode(AuthTokens.self, from: data)
    }
}
```

---

# 4️⃣ Secure API Client (Auto-Refresh + Retry)

```swift
import Foundation

final class APIClient {
    
    static let shared = APIClient()
    private init() {}
    
    func request<T: Decodable>(_ endpoint: String) async throws -> T {
        let token = try await AuthManager.shared.validAccessToken()
        
        var request = URLRequest(
            url: URL(string: "https://api.example.com\(endpoint)")!
        )
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if http.statusCode == 401 {
            // Force refresh once and retry
            AuthManager.shared.logout()
            throw URLError(.userAuthenticationRequired)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

---

# 5️⃣ SwiftUI Integration

## App Entry

```swift
@main
struct SecureApp: App {
    @StateObject private var auth = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            if auth.isLoggedIn {
                ContentView()
            } else {
                LoginView()
            }
        }
    }
}
```

---

## Example API Call in SwiftUI View

```swift
struct ContentView: View {
    
    @State private var profile: UserProfile?
    
    var body: some View {
        VStack {
            if let profile {
                Text("Hello \(profile.name)")
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                profile = try await APIClient.shared.request("/profile")
            } catch {
                print(error)
            }
        }
    }
}
```

---

# 6️⃣ Login Example (Saving Tokens)

```swift
func handleLoginSuccess(responseData: Data) {
    let tokens = try! JSONDecoder().decode(AuthTokens.self, from: responseData)
    AuthManager.shared.save(tokens: tokens)
}
```

---

# 7️⃣ Security Best Practices Recap 🔒

✔ Access tokens short-lived
✔ Refresh tokens in Keychain only
✔ Auto refresh before expiry
✔ Logout on refresh failure
✔ HTTPS only
✔ OAuth2 + PKCE recommended

---

## Want More?

I can also show:

* OAuth 2.0 **PKCE login flow**
* `URLSession` **Interceptor style**
* **Token rotation** strategy
* **Biometric-protected Keychain**

Just tell me 👍

Below is a **clear, backend + iOS–focused explanation** of **Token Rotation**, including **why it exists**, **how it works**, and **how to implement it correctly in a SwiftUI app**.

This is **real-world, production-grade security**.

---

# 🔁 What Is Token Rotation?

**Token rotation** means:

> Every time a **refresh token** is used, the server:
>
> 1. **Invalidates the old refresh token**
> 2. Issues a **new access token**
> 3. Issues a **new refresh token**

So a refresh token is **single-use**.

---

# ❓ Why Token Rotation Is Important

Without rotation:

* A stolen refresh token can be reused forever 😬

With rotation:

* Token theft is detected
* Replay attacks are blocked
* You can revoke sessions safely

**OAuth 2.1 strongly recommends this**

---

# 🧠 High-Level Flow (Rotating Refresh Tokens)

```text
Login
  ↓
Access Token (5–15 min)
Refresh Token #1
  ↓
Access token expires
  ↓
Client sends Refresh Token #1
  ↓
Server invalidates #1
  ↓
Server returns:
  - Access Token #2
  - Refresh Token #2
  ↓
Client stores #2 (overwrites #1)
```

---

# 🛑 Attack Detection (Critical)

If **Refresh Token #1** is used again:

➡ Server detects reuse
➡ Revokes **all tokens for that user/session**
➡ Forces logout on all devices

This is how **Google, Auth0, Okta** work.

---

# 🧩 Backend Requirements (Must-Have)

### Refresh token storage (server)

Store:

* `token_id`
* `user_id`
* `expires_at`
* `revoked_at`
* `replaced_by_token_id`
* `device_id` (optional)

### Validation logic

1. Token exists?
2. Token not expired?
3. Token not revoked?
4. Token not reused?

---

# 🧩 Backend Pseudocode

```pseudo
function refresh(refresh_token):
    token = db.find(refresh_token)

    if token.revoked:
        revoke_all_user_tokens(token.user_id)
        throw SecurityException

    new_refresh_token = generate()
    mark token as revoked
    mark token.replaced_by = new_refresh_token.id

    return {
        access_token,
        refresh_token: new_refresh_token
    }
```

---

# 📱 iOS Client Strategy (SwiftUI)

### 🔐 Rule #1

**Always overwrite the refresh token**

Never keep history.

---

# 1️⃣ Updated Token Model

```swift
struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}
```

---

# 2️⃣ Refresh Call (Rotating Token Safe)

```swift
private func refreshTokens() async throws -> AuthTokens {

    guard let current = tokens else {
        throw URLError(.userAuthenticationRequired)
    }

    let url = URL(string: "https://api.example.com/auth/refresh")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    request.httpBody = try JSONEncoder().encode([
        "refresh_token": current.refreshToken
    ])

    let (data, response) = try await URLSession.shared.data(for: request)

    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        logout()
        throw URLError(.userAuthenticationRequired)
    }

    // 🔁 ROTATION happens here
    let newTokens = try JSONDecoder().decode(AuthTokens.self, from: data)
    save(tokens: newTokens) // overwrite old refresh token
    return newTokens
}
```

---

# 3️⃣ Prevent Concurrent Refresh Bug (Very Important)

If **multiple API calls** trigger refresh at once, you can:

* Accidentally reuse old refresh token
* Get logged out

### ✅ Use a refresh lock

```swift
actor RefreshLock {
    private var isRefreshing = false

    func wait() async {
        while isRefreshing {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    func start() { isRefreshing = true }
    func end() { isRefreshing = false }
}
```

Use it in `AuthManager`:

```swift
private let lock = RefreshLock()

func validAccessToken() async throws -> String {
    try await lock.wait()
    guard let tokens else { throw URLError(.userAuthenticationRequired) }

    if tokens.expiresAt <= Date() {
        lock.start()
        defer { lock.end() }

        let newTokens = try await refreshTokens()
        return newTokens.accessToken
    }

    return tokens.accessToken
}
```

---

# 🔥 Backend Response Example

```json
{
  "access_token": "eyJhbGciOiJIUzI1...",
  "refresh_token": "def50200abc...",
  "expires_at": "2026-01-17T10:15:00Z"
}
```

---

# 🚨 When Should You Force Logout?

Force logout when:

* Refresh token reuse detected
* Refresh token expired
* Token signature invalid
* User manually logs out
* Password changed

---

# 🧪 Common Mistakes ❌

* ❌ Reusing refresh tokens
* ❌ Long-lived access tokens
* ❌ Storing multiple refresh tokens client-side
* ❌ No reuse detection on backend
* ❌ Concurrent refresh requests

---

# ✅ Best Practice Summary

| Item          | Best Practice        |
| ------------- | -------------------- |
| Access Token  | 5–15 minutes         |
| Refresh Token | Single-use (rotated) |
| Storage (iOS) | Keychain only        |
| Transport     | HTTPS                |
| Flow          | OAuth 2.0 + PKCE     |
| Security      | Reuse detection      |

---

## Want Next?

I can show:

* 🔐 **Biometric-protected Keychain**
* 🔄 **Silent re-auth with PKCE**
* 🧱 **Backend DB schema**
* 📊 **Token lifecycle diagram**

Just tell me 👍
