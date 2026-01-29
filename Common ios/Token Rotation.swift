//
//  Token Rotation.swift
//  
//
//  Created by Apple on 29/01/26.
//

import Foundation

Alright, let’s go **production-grade** 💪
Below is **realistic Swift code for token rotation** as used in **banking / fintech iOS apps**, using **modern concurrency (actors)**, **Keychain**, and **safe refresh synchronization**.

I’ll keep it **clean, layered, and interview-ready**.

---

# 🧱 Architecture Overview

```
APIClient
   │
   ▼
TokenManager (actor)
   │
   ├── Access Token (short-lived)
   ├── Refresh Token (rotating, single-use)
   └── Refresh Lock (prevents multiple refresh calls)
```

---

# 1️⃣ Token Model

```swift
struct AuthTokens: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}
```

---

# 2️⃣ Keychain Storage (Secure & Simple)

```swift
protocol TokenStorage {
    func save(_ tokens: AuthTokens) throws
    func load() throws -> AuthTokens?
    func clear() throws
}
```

### Keychain implementation (simplified)

```swift
final class KeychainTokenStorage: TokenStorage {

    private let key = "auth.tokens"

    func save(_ tokens: AuthTokens) throws {
        let data = try JSONEncoder().encode(tokens)

        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }

    func load() throws -> AuthTokens? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return try JSONDecoder().decode(AuthTokens.self, from: data)
    }

    func clear() throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error {
    case saveFailed
}
```

---

# 3️⃣ TokenManager (🔥 핵심 – Actor)

This guarantees:

* ✅ **Single refresh at a time**
* ✅ **No race conditions**
* ✅ **Safe concurrent API calls**

```swift
actor TokenManager {

    private let storage: TokenStorage
    private let authAPI: AuthAPI

    private var tokens: AuthTokens?
    private var refreshTask: Task<AuthTokens, Error>?

    init(storage: TokenStorage, authAPI: AuthAPI) {
        self.storage = storage
        self.authAPI = authAPI
        self.tokens = try? storage.load()
    }

    // MARK: - Public
    func validAccessToken() async throws -> String {
        if let tokens, !isExpired(tokens) {
            return tokens.accessToken
        }

        return try await refreshTokens().accessToken
    }

    func clearTokens() async throws {
        tokens = nil
        try storage.clear()
    }

    // MARK: - Refresh Logic
    private func refreshTokens() async throws -> AuthTokens {

        // 🔒 If refresh already running, await it
        if let task = refreshTask {
            return try await task.value
        }

        let task = Task<AuthTokens, Error> {
            guard let refreshToken = tokens?.refreshToken else {
                throw AuthError.notAuthenticated
            }

            let newTokens = try await authAPI.refreshToken(refreshToken)

            self.tokens = newTokens
            try self.storage.save(newTokens)
            return newTokens
        }

        refreshTask = task

        defer { refreshTask = nil }

        return try await task.value
    }

    private func isExpired(_ tokens: AuthTokens) -> Bool {
        tokens.expiresAt <= Date().addingTimeInterval(30) // buffer
    }
}

enum AuthError: Error {
    case notAuthenticated
}
```

---

# 4️⃣ Auth API (Refresh Endpoint)

```swift
protocol AuthAPI {
    func refreshToken(_ token: String) async throws -> AuthTokens
}
```

### Example implementation

```swift
final class AuthAPIClient: AuthAPI {

    func refreshToken(_ token: String) async throws -> AuthTokens {
        var request = URLRequest(url: URL(string: "https://api.bank.com/auth/refresh")!)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode([
            "refresh_token": token
        ])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(AuthTokens.self, from: data)
    }
}
```

---

# 5️⃣ API Client Using Token Rotation

```swift
final class APIClient {

    private let tokenManager: TokenManager

    init(tokenManager: TokenManager) {
        self.tokenManager = tokenManager
    }

    func send(_ request: URLRequest) async throws -> Data {
        var request = request

        let token = try await tokenManager.validAccessToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            // 🔄 Retry once after forced refresh
            let newToken = try await tokenManager.validAccessToken()
            request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            return try await URLSession.shared.data(for: request).0
        }

        return data
    }
}
```

---

# 6️⃣ What Makes This **Banking-Grade** ✅

✔ Short-lived access tokens
✔ **Rotating refresh tokens**
✔ Keychain with `ThisDeviceOnly`
✔ Actor-based synchronization
✔ No multiple refresh calls
✔ Safe retry on 401

---

# 🚫 Common Anti-Patterns (Avoid These)

❌ Refresh token stored in memory only
❌ Multiple refresh calls in parallel
❌ Long-lived access tokens
❌ Silent refresh without server invalidation

---

# 🧠 Interview Power Answer

> “I implement token rotation using an actor-based TokenManager that synchronizes refresh requests, stores tokens securely in Keychain, and rotates refresh tokens on every renewal to prevent replay attacks.”

---

If you want next:

* 🧪 **Unit tests for TokenManager**
* 🔁 **Retry + exponential backoff**
* 🔐 **Device-bound refresh tokens**
* 🧵 **Combine-based version**

Say the word 🚀


This is a **core security concept**, especially for **banking & fintech iOS apps**. I’ll explain it **clearly**, **practically**, and **from an iOS-architecture + interview perspective**.

---

# 🔐 What is Token Rotation? (Plain English)

**Token rotation** means:

> *Regularly replacing access tokens with new ones so that stolen tokens become useless very quickly.*

In banking apps, **no token should live “too long”**.

---

# 🧠 Why banking apps MUST use token rotation

Banking apps deal with:

* 💰 Money
* 🆔 Identity
* 🧾 Transactions

Threats:

* Jailbroken devices
* Memory dumps
* MITM attacks
* Stolen refresh tokens
* Replay attacks

👉 **Short-lived access tokens + rotating refresh tokens** drastically reduce blast radius.

---

# 🧱 Typical Banking Auth Architecture

```
┌─────────┐        Access Token (5–10 min)
│  iOS App│ ────────────────────────────▶ API
│         │
│         │        Refresh Token (rotating)
│         │ ◀──────────────────────────── Auth Server
└─────────┘
```

### Tokens used:

| Token         | Lifetime   | Stored where                          |
| ------------- | ---------- | ------------------------------------- |
| Access Token  | 5–10 mins  | Memory / Keychain                     |
| Refresh Token | Single-use | Keychain (Secure Enclave if possible) |

---

# 🔄 What is **Token Rotation** exactly?

Every time you refresh:

1️⃣ Client sends **Refresh Token A**
2️⃣ Server:

* Invalidates Refresh Token A ❌
* Issues:

  * New Access Token
  * New Refresh Token B ✅
    3️⃣ Client stores Refresh Token B
    4️⃣ Token A is now **dead forever**

📌 If Token A is reused → **security breach detected**

---

# ❌ What happens WITHOUT rotation (bad)

```
Refresh Token R1 → valid for months
Attacker steals R1
Attacker can refresh forever 😨
```

---

# ✅ With rotation (good)

```
R1 → used → replaced by R2
Attacker tries R1 → ❌ revoked
```

**Even if stolen → only usable once**

---

# 🧪 Real Banking-grade Flow (Step-by-step)

### 1️⃣ Login

```json
{
  "access_token": "AT_1",
  "refresh_token": "RT_1",
  "expires_in": 300
}
```

---

### 2️⃣ Normal API call

```http
Authorization: Bearer AT_1
```

---

### 3️⃣ Access token expires (401)

iOS app:

```http
POST /auth/refresh
refresh_token=RT_1
```

---

### 4️⃣ Server response

```json
{
  "access_token": "AT_2",
  "refresh_token": "RT_2"
}
```

❌ RT_1 invalid
✅ RT_2 stored securely

---

### 5️⃣ Replay attack attempt

```http
POST /auth/refresh
refresh_token=RT_1
```

🚨 Server detects token reuse
🚨 Session revoked
🚨 User logged out everywhere

---

# 📱 iOS Implementation Strategy

## 1️⃣ Secure Storage (MANDATORY)

```swift
Keychain (ThisDeviceOnly)
```

Best practices:

* `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
* Never store tokens in UserDefaults ❌
* Avoid keeping refresh token in memory

---

## 2️⃣ Token Manager (Single Source of Truth)

```swift
actor TokenManager {

    private var accessToken: String?
    private var refreshToken: String?

    func accessToken() async throws -> String {
        if isExpired(accessToken) {
            try await rotateTokens()
        }
        return accessToken!
    }

    private func rotateTokens() async throws {
        // call /refresh
        // update tokens atomically
    }
}
```

✅ Actor = race-condition safe
✅ One refresh at a time

---

## 3️⃣ Networking Layer Integration

```swift
func authorizedRequest(_ request: URLRequest) async throws -> URLRequest {
    let token = try await tokenManager.accessToken()
    var req = request
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return req
}
```

---

## 4️⃣ Handling Multiple Simultaneous 401s

**Classic banking bug** 👇

❌ 5 requests → 5 refresh calls → token overwrite chaos

### Correct solution:

* Lock refresh
* Queue requests
* Retry after refresh

```swift
await tokenManager.refreshIfNeeded()
```

---

# 🧷 Advanced Banking Protections (Real-world)

Banks usually add:

### 🔹 Device Binding

Refresh token tied to:

* Device ID
* Secure Enclave key
* App instance

Stolen token on another device → ❌

---

### 🔹 Token Family ID

```json
refresh_token: {
  family_id: "ABC123"
}
```

Reuse → entire family revoked

---

### 🔹 Step-up Authentication

On suspicious refresh:

* Force biometric / OTP
* Re-authenticate user

---

# 🚫 Common iOS Mistakes (Interview Red Flags)

❌ Long-lived access tokens
❌ No refresh token rotation
❌ Storing tokens in UserDefaults
❌ Multiple refresh calls in parallel
❌ Silent refresh without server-side invalidation

---

# 🧠 Interview Answer (Perfect)

> “In banking apps, we use short-lived access tokens and rotating refresh tokens. Every refresh invalidates the previous refresh token, so stolen tokens can’t be reused. On iOS, tokens are stored in Keychain, refresh logic is centralized (often via an actor), and concurrent refresh requests are synchronized.”

---

# ✅ When token rotation is NOT enough

You still need:

* TLS + certificate pinning
* Jailbreak detection
* Root detection
* Runtime integrity checks

Token rotation is **one layer**, not the whole shield 🛡️

---

If you want next:

* 🔧 **Swift code for token rotation**
* 🧪 **Test cases for token refresh**
* 🧵 **Actor-based refresh queue**
* 🔐 **Banking app security checklist**

Just say it 🚀


