//
//  Two-factor authentication.swift
//  
//
//  Created by Apple on 28/10/25.
//

import Foundation

Excellent — let’s take it up a notch and talk about **two-factor authentication (2FA)** **using passkeys** in the context of a **modern SwiftUI iOS app** from a **senior iOS developer’s** perspective.

We’ll break this down from *architecture*, *frameworks*, and *implementation flow* to practical *SwiftUI integration*.

---

## 🔐 What 2FA with Passkeys Actually Means on iOS

Normally, **2FA** means verifying the user’s identity in **two steps**:

1. **Something they have** → The **passkey** (stored in the Secure Enclave).
2. **Something they know or are** → A **biometric (Face ID/Touch ID)** or a **verification code (TOTP / OTP)**.

When you use **Passkeys (WebAuthn/FIDO2)**, the system **already fulfills both factors** by design:

| Factor                 | Implementation                                 | Where it happens |
| ---------------------- | ---------------------------------------------- | ---------------- |
| **Something you have** | Device-bound private key (Secure Enclave)      | iPhone/iPad      |
| **Something you are**  | Face ID / Touch ID required to use private key | Local hardware   |

So **passkeys are inherently multi-factor**.
However, for **additional assurance** (e.g. financial transactions, admin operations, or compliance reasons), apps may still **add a second explicit factor** like an **OTP**, **email code**, or **push verification**.

---

## 🧠 Architecture Overview

```
iOS App (SwiftUI)
│
├── Passkey Auth (FIDO2 / WebAuthn)
│     ├── AuthManager.swift — handles registration + assertion
│     └── ASAuthorizationController
│
├── Server (Backend)
│     ├── Issues WebAuthn challenge
│     ├── Verifies signed assertion
│     └── Triggers 2FA code (SMS/Email/App TOTP)
│
└── SwiftUI Flow
      1️⃣ User signs in with passkey
      2️⃣ Server validates → returns "2FA required"
      3️⃣ App prompts for code → calls verify endpoint
```

---

## 🏗️ Step-by-Step Flow

### **1️⃣ Passkey Sign-In**

Use `ASAuthorizationPlatformPublicKeyCredentialProvider` to perform a WebAuthn challenge.

If successful, the backend returns a `requires2FA: true` flag.

### **2️⃣ Prompt for Second Factor**

Your SwiftUI UI presents a secure field for the 6-digit code.

### **3️⃣ Validate 2FA**

The app sends the 2FA code (or TOTP) to the backend endpoint.
If valid → backend issues final session token.

---

## 📱 Example SwiftUI Implementation

Let’s look at a realistic demo setup.

---

### `AuthManager.swift`

```swift
import Foundation
import AuthenticationServices

@MainActor
final class AuthManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var requires2FA = false
    @Published var errorMessage: String?
    
    private let relyingPartyID = "example.com"
    
    func signInWithPasskey() {
        let challenge = Data(UUID().uuidString.utf8) // In reality, fetch from backend
        
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: relyingPartyID)
        let request = provider.createCredentialAssertionRequest(challenge: challenge)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    func verify2FACode(_ code: String) async {
        // Simulated backend verification
        try? await Task.sleep(for: .seconds(1))
        if code == "123456" {
            isAuthenticated = true
            requires2FA = false
        } else {
            errorMessage = "Invalid 2FA code"
        }
    }
}

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard authorization.credential is ASAuthorizationPlatformPublicKeyCredentialAssertion else { return }
        
        // Simulated backend passkey verification result
        Task {
            try? await Task.sleep(for: .seconds(1))
            // Backend verified passkey but requires second factor
            requires2FA = true
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        errorMessage = error.localizedDescription
    }
}

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? UIWindow()
    }
}
```

---

### `TwoFactorView.swift`

```swift
import SwiftUI

struct TwoFactorView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var code = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Enter 2FA Code")
                .font(.title)
            
            SecureField("6-digit code", text: $code)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
            
            Button("Verify") {
                Task {
                    isLoading = true
                    await authManager.verify2FACode(code)
                    isLoading = false
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(code.count < 6)
            
            if isLoading {
                ProgressView()
            }
            
            if let error = authManager.errorMessage {
                Text(error).foregroundColor(.red)
            }
        }
        .padding()
    }
}
```

---

### `LoginView.swift`

```swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Sign in with Passkey")
                .font(.largeTitle)
            
            Button("🔑 Sign In") {
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

### `RootView.swift`

```swift
import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        if authManager.isAuthenticated {
            SecureAreaView()
        } else if authManager.requires2FA {
            TwoFactorView()
        } else {
            LoginView()
        }
    }
}

struct SecureAreaView: View {
    var body: some View {
        Text("✅ Authenticated with Passkey + 2FA")
            .font(.title)
            .padding()
    }
}
```

---

## 🔒 Security & Senior-Level Design Notes

### **1. Passkeys already provide MFA**

* The private key (in Secure Enclave) = *“something you have”*
* Face ID / Touch ID = *“something you are”*
  ✅ So even before explicit 2FA, it’s a strong multi-factor system.

### **2. Explicit 2FA adds compliance & layered defense**

Use this when:

* Required by **financial** or **regulated** industries.
* For **step-up authentication** (e.g., wire transfer).
* When **cross-device** login occurs (new device → always require extra factor).

### **3. Never store 2FA codes locally**

Codes should be validated server-side only.
Optionally cache the verification timestamp securely in **Keychain** if needed for session persistence.

### **4. Handle fallback UX**

Provide alternate methods if:

* Passkeys aren’t available
* User hasn’t enrolled Face ID / Touch ID
* Code delivery fails

### **5. Modern Server Coordination**

Your backend must implement:

* WebAuthn (challenge issuance & verification)
* OTP or TOTP generation (RFC 6238)
* Session token issuance on both-step success

---

## ⚙️ Real-World Integration Example

In production, the flow might look like this:

1. **POST** `/auth/webauthn/challenge` → get `challenge`
2. User signs with passkey → get `assertion`
3. **POST** `/auth/webauthn/verify` → returns `requires_2fa = true`
4. **POST** `/auth/2fa/verify` with code → returns `session_token`
5. Store `session_token` securely in **Keychain**

---

## 🧩 TL;DR for Senior SwiftUI Developers

| Concept                | Role                   | Framework                       |
| ---------------------- | ---------------------- | ------------------------------- |
| **Passkey**            | Primary authentication | `AuthenticationServices`        |
| **2FA code**           | Secondary factor       | Custom network + SwiftUI        |
| **Face ID / Touch ID** | Local biometric factor | `LocalAuthentication`           |
| **State-driven flow**  | UI transitions         | SwiftUI + Combine / Observation |
| **Secure storage**     | Session token          | Keychain / Secure Enclave       |

---

Would you like me to extend this example into a **full working SwiftUI app** that includes:

* A mock backend service (`URLSession` calls),
* Local biometric unlock integration, and
* A real `Keychain`-based session manager?
