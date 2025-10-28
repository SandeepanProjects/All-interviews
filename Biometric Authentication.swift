//
//  Biometric Authentication.swift
//  
//
//  Created by Apple on 28/10/25.
//

import Foundation

Alright — let’s go over **biometric authentication** and **passkeys** from the perspective of a **senior iOS developer using SwiftUI**, with practical code-level and architectural insights.

---

## 🔐 Biometric Authentication in iOS

### 1. What It Is

Biometric authentication lets users unlock access using **Touch ID** or **Face ID**, depending on device hardware. It’s part of the **LocalAuthentication** framework (`LAContext`).

You use it to verify the user’s identity **locally**, without transmitting sensitive data to a server. This is ideal for things like unlocking app data, authenticating before a transaction, or gating sensitive UI.

---

### 2. Core Concepts

* **`LAContext`** — manages the authentication session.
* **Biometry Types** — `.faceID`, `.touchID`, `.none`
* **Policy** — `.deviceOwnerAuthenticationWithBiometrics` (biometrics only) or `.deviceOwnerAuthentication` (includes passcode fallback).
* **Error Handling** — handle user cancellations, lockouts, and unavailable hardware.

---

### 3. SwiftUI Implementation Example

```swift
import SwiftUI
import LocalAuthentication

struct BiometricAuthView: View {
    @State private var isUnlocked = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if isUnlocked {
                Text("🔓 Access Granted")
            } else {
                Text("🔒 Locked")
                Button("Authenticate") {
                    authenticateUser()
                }
            }
            
            if let error = errorMessage {
                Text(error).foregroundColor(.red)
            }
        }
        .padding()
    }

    func authenticateUser() {
        let context = LAContext()
        var error: NSError?

        // Check availability
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access sensitive data"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        isUnlocked = true
                    } else {
                        errorMessage = authError?.localizedDescription
                    }
                }
            }
        } else {
            errorMessage = error?.localizedDescription ?? "Biometrics not available"
        }
    }
}
```

✅ **Key Senior-Level Notes:**

* Use `.deviceOwnerAuthentication` if you want a passcode fallback.
* Handle edge cases like `.biometryLockout` or `.biometryNotEnrolled`.
* Avoid prompting immediately on view load; wait for explicit user action (UX best practice).
* Biometric state can change — recheck availability before each authentication.

---

## 🪪 Passkeys (FIDO2 / WebAuthn)

### 1. What It Is

**Passkeys** are a passwordless authentication mechanism built on **public-key cryptography**, part of the **FIDO2** standard (WebAuthn + CTAP).

Instead of storing passwords, iOS securely stores **a key pair in the Secure Enclave**:

* The **public key** is sent to your server during registration.
* The **private key** never leaves the device.
* Authentication works by signing a server-provided challenge with the private key.

Passkeys are automatically synced via **iCloud Keychain**, enabling seamless cross-device authentication.

---

### 2. Where It Fits in Swift / SwiftUI Apps

You use **`ASAuthorizationController`** with **`ASAuthorizationPlatformPublicKeyCredentialProvider`** (from `AuthenticationServices`).

**Use cases:**

* Passwordless login/signup flows.
* Replacing traditional username/password.
* Works alongside Sign in with Apple for a modern auth stack.

---

### 3. Creating a Passkey (Registration)

```swift
import AuthenticationServices

func createPasskey(for userID: String, challenge: Data) {
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "example.com")
    
    let registrationRequest = provider.createCredentialRegistrationRequest(
        challenge: challenge,
        name: "John Doe",
        userID: userID.data(using: .utf8)!
    )
    
    let controller = ASAuthorizationController(authorizationRequests: [registrationRequest])
    controller.delegate = self
    controller.presentationContextProvider = self
    controller.performRequests()
}
```

---

### 4. Authenticating with a Passkey (Sign In)

```swift
func authenticateWithPasskey(challenge: Data) {
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "example.com")
    let assertionRequest = provider.createCredentialAssertionRequest(challenge: challenge)
    
    let controller = ASAuthorizationController(authorizationRequests: [assertionRequest])
    controller.delegate = self
    controller.presentationContextProvider = self
    controller.performRequests()
}
```

---

### 5. Integrating with SwiftUI

Typically, you wrap the `ASAuthorizationController` logic in a view model or use `UIViewControllerRepresentable` for a SwiftUI-friendly interface.

---

### 6. Senior-Level Considerations

* **Backend coordination:**
  You must implement WebAuthn endpoints to issue and verify challenges.
* **Security:**
  Private keys never leave Secure Enclave → far more secure than passwords or even biometric-only systems.
* **UX:**
  Passkeys auto-suggest in the QuickType bar and can be shared across Apple devices.
* **Fallbacks:**
  Offer alternative sign-in (Sign in with Apple or email OTP) for non-passkey users.

---

## ⚖️ Biometric Auth vs Passkeys

| Feature  | Biometric Auth             | Passkey                       |
| -------- | -------------------------- | ----------------------------- |
| Scope    | Local device only          | Cross-device identity         |
| Backend  | None                       | Requires server-side WebAuthn |
| Data     | Unlocks local data         | Authenticates to server       |
| Security | Device PIN/biometrics      | Asymmetric key pair           |
| Use Case | App lock, local encryption | Account login/signup          |

---

## 🧠 TL;DR for Senior SwiftUI Devs

* **Biometric auth** → gate local sensitive data (`LocalAuthentication`).
* **Passkeys** → passwordless remote authentication (`AuthenticationServices`).
* Use **Secure Enclave**, **Keychain**, and **WebAuthn** standards properly.
* Architect cleanly:

  * `AuthManager` for logic
  * SwiftUI view binds to published states
  * Handle async callbacks cleanly with `@MainActor`

---

Would you like me to show a **complete SwiftUI passkey + biometric unlock demo app structure** (with a shared `AuthManager` and mock backend)?

Perfect 👍 — let’s design a **complete SwiftUI demo app architecture** that integrates both **biometric authentication** (for local unlock) and **passkeys** (for remote login).
                    
This example will be structured for a **senior iOS engineer**, focusing on modularity, clean async/await usage, and separation of concerns.
                    
---
                    
## 🧩 Architecture Overview
                    
```
AuthDemoApp
│
├── Models/
│   └── UserSession.swift
│
├── Managers/
│   ├── AuthManager.swift        // Handles passkey + biometric logic
│   └── BiometricAuthenticator.swift
│
├── Views/
│   ├── LoginView.swift
│   ├── SecureContentView.swift
│   └── RootView.swift
│
└── AuthDemoApp.swift            // App entry point
```
                    
---
                    
## 🧠 Core Idea
                    
* **Passkey** → Handles server-based authentication (`AuthenticationServices`).
* **Biometric** → Locally unlocks access after the user is logged in (`LocalAuthentication`).
* **AuthManager** → Central source of truth for auth state (`@Published var isAuthenticated`).
                    
---
                    
## 📁 `UserSession.swift`
                    
```swift
import Foundation
                    
struct UserSession: Codable, Identifiable {
    var id: UUID = UUID()
    var username: String
    var token: String // Server-issued JWT or session token
}
```

---

## 📁 `BiometricAuthenticator.swift`

```swift
import LocalAuthentication

@MainActor
final class BiometricAuthenticator {
    func authenticate(reason: String = "Authenticate to access secure data") async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("Biometrics unavailable: \(error?.localizedDescription ?? "")")
            return false
        }
        
        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            return success
        } catch {
            print("Biometric authentication failed: \(error.localizedDescription)")
            return false
        }
    }
}
```

✅ Uses `async/await` cleanly
✅ Handles both Face ID and Touch ID
✅ Works easily in SwiftUI with `.task {}` or `Button` actions

---

## 📁 `AuthManager.swift`

This handles **Passkey-based login** + maintains **authentication state**.

```swift
import Foundation
import AuthenticationServices

@MainActor
final class AuthManager: NSObject, ObservableObject {
    @Published var userSession: UserSession?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    private let relyingPartyID = "example.com"
    private var biometricAuthenticator = BiometricAuthenticator()
    
    // MARK: - Public API
    
    func signInWithPasskey() {
        // Normally fetch a challenge from your backend
        let challenge = Data(UUID().uuidString.utf8)
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyID)
        let request = provider.createCredentialAssertionRequest(challenge: challenge)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func unlockWithBiometrics() async {
        if await biometricAuthenticator.authenticate() {
            isAuthenticated = true
        } else {
            errorMessage = "Biometric unlock failed."
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            // Send credential.response.signature + clientDataJSON to backend for verification
            // Mock backend verification:
            print("Passkey assertion received: \(credential)")
            
            // Mock user session after server validation
            userSession = UserSession(username: "johndoe", token: "mock_token_123")
            isAuthenticated = true
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        errorMessage = error.localizedDescription
        print("Passkey sign-in error: \(error.localizedDescription)")
    }
}

// MARK: - Presentation Context

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? UIWindow()
    }
}
```

✅ Uses WebAuthn APIs
✅ Can easily connect to real backend later
✅ Cleanly integrates biometric fallback

---

## 📁 `LoginView.swift`

```swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to SecureApp")
                .font(.largeTitle)
            
            Button("🔑 Sign In with Passkey") {
                authManager.signInWithPasskey()
            }
            .buttonStyle(.borderedProminent)
            
            if let error = authManager.errorMessage {
                Text(error).foregroundColor(.red)
            }
        }
        .padding()
    }
}
```

---

## 📁 `SecureContentView.swift`

```swift
import SwiftUI

struct SecureContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var unlocked = false
    
    var body: some View {
        VStack(spacing: 24) {
            if unlocked {
                Text("🔓 Sensitive Information Here")
                    .font(.title)
            } else {
                Button("Unlock with Face ID / Touch ID") {
                    Task {
                        await authManager.unlockWithBiometrics()
                        unlocked = authManager.isAuthenticated
                    }
                }
            }
            
            Button("Logout") {
                authManager.isAuthenticated = false
                authManager.userSession = nil
                unlocked = false
            }
            .tint(.red)
        }
        .padding()
    }
}
```

---

## 📁 `RootView.swift`

```swift
import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        if authManager.isAuthenticated {
            SecureContentView()
        } else {
            LoginView()
        }
    }
}
```

---

## 📁 `AuthDemoApp.swift`

```swift
import SwiftUI

@main
struct AuthDemoApp: App {
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
        }
    }
}
```

---

## ✅ Key Takeaways

| Concept                   | Purpose                   | Framework                |
| ------------------------- | ------------------------- | ------------------------ |
| **Passkey**               | Passwordless server login | `AuthenticationServices` |
| **Biometric Auth**        | Local secure access       | `LocalAuthentication`    |
| **Secure Enclave**        | Stores private keys       | System-level             |
| **SwiftUI + async/await** | Clean state-driven UI     | Modern iOS 17+           |

---

## 🧱 Future Enhancements

* Integrate **Keychain storage** for encrypted local data.
* Real **WebAuthn backend** (challenge/response verification).
* Combine with **Sign in with Apple** as a fallback.
* Use **`Observable` macro** (Swift 5.9+) for `AuthManager`.
                                        
---
