//
//  Passkeys.swift
//  
//
//  Created by Apple on 08/07/25.
//

import Foundation

Implementing Passkeys in iOS involves integrating Apple's Passkeys functionality, which is part of the new passwordless authentication framework introduced with iOS 16. Passkeys leverage public-key cryptography for secure authentication without the need for passwords. Users authenticate using Face ID, Touch ID, or device passcode.

Here’s a step-by-step guide to implementing Passkeys in your iOS app:

### 1. **Requirements:**
   - **Xcode 14** or higher
   - **iOS 16** or higher
   - **A supported authentication API** (e.g., Sign in with Apple, or a custom backend supporting WebAuthn or FIDO2)

### 2. **Enable Passkeys in Your App:**
   You need to ensure your app and server are set up to support Passkeys (i.e., WebAuthn or FIDO2 protocols).

#### a. **Update Your App's Entitlements**:
   Make sure your app is set to use passkeys by enabling the necessary capabilities in your app’s entitlements file.

1. Open your `.xcworkspace` in Xcode.
2. Navigate to your app’s target.
3. In the **Signing & Capabilities** tab, enable **Authentication Services** (to support passkeys).

#### b. **Update Your App’s Info.plist**:
   You'll need to declare support for Passkeys. This is done via the `UIAuthentication` section of your `Info.plist`.

```xml
<key>UIAuthentication</key>
<dict>
    <key>PasskeyAuthentication</key>
    <true/>
</dict>
```

### 3. **Use Passkeys APIs**:

#### a. **Add Passkey Authentication to Your App**:
   Apple provides a native API for handling Passkeys, which is part of the **AuthenticationServices** framework. Here's how you can start integrating Passkeys in your app:

1. Import the **AuthenticationServices** framework:

```swift
import AuthenticationServices
```

2. **Create a Passkey Request**:
   You can initiate a passkey authentication request using `ASPasskeyAuthenticationRequest`.

Here’s an example of how to create and present a passkey request:

```swift
import AuthenticationServices

// Start the Passkey authentication request
func authenticateWithPasskey() {
    let passkeyRequest = ASPasskeyAuthenticationRequest(requestType: .login)
    
    // Optionally, add a challenge or authentication context
    passkeyRequest.challenge = "some-challenge-string" // Unique to your server and session

    passkeyRequest.delegate = self
    passkeyRequest.begin()
}
```

#### b. **Handle Authentication Responses**:
Passkeys will trigger authentication flows like Face ID or Touch ID. You'll need to handle the response and process any errors.

```swift
// Delegate method to handle the result of the Passkey authentication
func passkeyAuthenticationRequest(_ request: ASPasskeyAuthenticationRequest, didAuthenticateWithCredential credential: ASPasskeyCredential) {
    // The authentication was successful
    let userIdentifier = credential.userIdentifier
    // You can now use this userIdentifier to continue the login process
}

func passkeyAuthenticationRequest(_ request: ASPasskeyAuthenticationRequest, didFailWithError error: Error) {
    // Handle error here
    print("Passkey authentication failed: \(error.localizedDescription)")
}
```

### 4. **Backend Integration**:

You need to ensure your backend is set up to support passkey authentication. This usually means integrating WebAuthn or FIDO2 protocols into your backend server.

When a user successfully authenticates, you'll typically get a credential (like a `publicKeyCredential`). Your server will use the associated public key to verify the identity.

### 5. **Testing**:
To test Passkeys, you'll need to:

- Use a real device running iOS 16 or higher.
- Make sure the device has Face ID, Touch ID, or a passcode set up.
- Ensure that your server supports passkey authentication and WebAuthn/FIDO2 protocols.

### 6. **Provide Fallbacks**:
While Passkeys are a modern and secure option, not all users may have devices that support them, or they may not be using Face ID/Touch ID. Always provide a fallback authentication method, such as a password, for users who cannot or choose not to use Passkeys.

### 7. **Handle Edge Cases**:
Consider scenarios such as:

- User doesn’t have Face ID or Touch ID set up.
- Device is locked or the user cancels the authentication process.

Make sure your app gracefully handles such cases to improve user experience.

---

Great question. **Passkeys** are the modern, passwordless alternative to traditional authentication. They’re more secure, user-friendly, and backed by Apple, Google, and Microsoft as the future of login.

Let’s break down **what passkeys are**, and **how to implement them in a SwiftUI app using Swift + iCloud Keychain**.

---

## 🔐 What Are Passkeys?

### ✅ Definition:

A **passkey** is a **cryptographic key pair** (public/private) used for authentication. It replaces passwords by letting users authenticate with **Face ID / Touch ID / device PIN**.
                                                                                                                                                                                                                        
### 👥 Backed by:

* Apple (iCloud Keychain)
* Google (Google Password Manager)
* Microsoft

### 🛡 Why Use Passkeys?

| Feature                             | Passkeys ✅ | Passwords ❌ |
| ----------------------------------- | ---------- | ----------- |
| Phishing-resistant                  | ✅          | ❌           |
| No reuse issues                     | ✅          | ❌           |
| Stored in Keychain (secure enclave) | ✅          | ❌           |
| Face ID / Touch ID login            | ✅          | ❌           |
| Cross-device sync via iCloud        | ✅          | ❌           |

---
## 🧱 How It Works (Under the Hood)

1. The app asks the system to create a **credential (passkey)**.
2. The system generates:

* A **public/private key pair**.
* Private key stays on device.
* Public key sent to the server.
3. For login:

* Server sends a **challenge**.
* User authenticates with biometrics.
* The private key signs the challenge and sends it back.
4. Server verifies the signature using the stored public key.

---

## ✅ How to Implement Passkeys in SwiftUI (iOS 16+)

> Passkeys are built on `AuthenticationServices.framework`, and you can use them in SwiftUI via `UIViewControllerRepresentable` or directly with `.signInWithAppleButton`.

---

### 📦 1. Import the Framework

```swift
import AuthenticationServices
```

---

### 🧑‍💻 2. Registration: Create a Passkey

```swift
func registerWithPasskey(userID: String, username: String) {
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "yourdomain.com")
    
    let registrationRequest = provider.createCredentialRegistrationRequest(
        userID: userID.data(using: .utf8)!,
        name: username,
        challenge: generateChallengeFromServer()
    )
    
    let controller = ASAuthorizationController(authorizationRequests: [registrationRequest])
    controller.delegate = self
    controller.presentationContextProvider = self
    controller.performRequests()
}
```

**You need to implement:**

* `ASAuthorizationControllerDelegate`
* `ASAuthorizationControllerPresentationContextProviding`

---

### 🔐 3. Login: Authenticate with Passkey

```swift
func signInWithPasskey() {
    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "yourdomain.com")
    
    let assertionRequest = provider.createCredentialAssertionRequest(challenge: getLoginChallengeFromServer())
    
    let controller = ASAuthorizationController(authorizationRequests: [assertionRequest])
    controller.delegate = self
    controller.presentationContextProvider = self
    controller.performRequests()
}
```

---

### 🧩 4. Handle the Result

Implement the delegate methods:

```swift
extension YourViewModel: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
            // Send credential.rawAttestationObject and credential.credentialID to server
        } else if let assertion = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
            // Send assertion.signature and assertion.userID to server
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Authorization failed: \(error)")
    }
}
```

---

### 🖼 5. Presenting in SwiftUI

Wrap the login button using `UIViewControllerRepresentable` or use a `.signInWithAppleButton` as a placeholder:

```swift
SignInWithAppleButton(.signIn, onRequest: { request in
    // Not used for passkeys, but useful if you add Apple Sign In too
}, onCompletion: { result in
    // Handle result
})
.frame(height: 50)
```

---

## 🌐 Server-Side Requirements (Summary)

To use passkeys, your server must:

1. Support **WebAuthn (FIDO2)**.
2. Generate and validate **challenge strings**.
3. Store **credential ID** and **public key** per user.
4. Verify signed assertions during login.

👉 Popular frameworks:

* [webauthn.io](https://webauthn.io)
                * [FIDO2 libraries](https://fidoalliance.org/developer-tools/)
* Firebase and Auth0 are also starting to support passkeys.
                                    
---
                                    
## 🧪 Test on Device
                                    
* iOS 16+
* Works best with **real devices**, not simulators.
* iCloud Keychain must be **enabled**.
* Test cross-device sync by registering on iPhone, logging in on iPad/Mac.
                                    
---
                                    
## ✅ Summary
                                    
| Task             | Swift Code                              |
| ---------------- | --------------------------------------- |
| Register Passkey | `createCredentialRegistrationRequest()` |
| Sign In          | `createCredentialAssertionRequest()`    |
| SwiftUI Support  | Use via `UIViewControllerRepresentable` |
| Server           | Must support **WebAuthn/FIDO2**         |
                                    
---
                                    
Would you like:
                                        
* A SwiftUI **wrapper component** for a reusable Passkey button?
* Sample **server-side code** for WebAuthn in Node, Django, or Go?
* Firebase + Passkey walkthrough?
                                    
Here’s a polished implementation covering both parts you asked for:
                                        
                                        ---
                                        
## 🔲 SwiftUI Wrapper Component for a Reusable Passkey Button
                                    
SwiftUI doesn’t natively support passkey APIs, so we’ll wrap Apple’s `ASAuthorizationController` using `UIViewControllerRepresentable`:
                                        
```swift
import SwiftUI
import AuthenticationServices
                                    
struct PasskeyButton: UIViewRepresentable {
    var onRegister: (ASAuthorizationPlatformPublicKeyCredentialRegistration) -> Void
    var onLogin: (ASAuthorizationPlatformPublicKeyCredentialAssertion) -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.cornerRadius = 8
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleTap), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onRegister: onRegister, onLogin: onLogin)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onRegister: (ASAuthorizationPlatformPublicKeyCredentialRegistration) -> Void
        let onLogin: (ASAuthorizationPlatformPublicKeyCredentialAssertion) -> Void
        
        init(onRegister:..., onLogin:...) {
            self.onRegister = onRegister
            self.onLogin = onLogin
        }
        
        @objc func handleTap() {
            // Example for login, modify for registration
            let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "yourdomain.com")
            let request = provider.createCredentialAssertionRequest(challenge: fetchChallengeFromServer())
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization auth: ASAuthorization) {
            if let reg = auth.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
                onRegister(reg)
            } else if let assertion = auth.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
                onLogin(assertion)
            }
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            print("Passkey error:", error)
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            UIApplication.shared.windows.first { $0.isKeyWindow }!
        }
        
        func fetchChallengeFromServer() -> Data {
            // Call your server to get challenge
            Data()
        }
    }
}
```
                                    
### Usage in SwiftUI:
                                        
                                        ```swift
PasskeyButton(
onRegister: { reg in
uploadRegistration(reg)
},
onLogin: { assertion in
uploadAssertion(assertion)
}
)
.frame(height: 50)
.padding()
                                    ```
                                    
This gives you a reusable passkey button that handles both register/login flows cleanly.
                                    
                                    ---
                                    
## 🛠️ Sample Server‑Side Code: WebAuthn in Node.js (TypeScript)

Using **@simplewebauthn/server**, inspired by Medium's guide ([reddit.com][1], [medium.com][2]):
                                        
                                        ```ts
// server.ts
import express from "express";
import cors from "cors";
import {
    generateRegistrationOptions,
    verifyRegistrationResponse,
    generateAuthenticationOptions,
    verifyAuthenticationResponse
} from "@simplewebauthn/server";
                                    
const app = express();
app.use(cors(), express.json());
const users: Record<string, any> = {};
                                    
app.post("/generate-registration-options", (req, res) => {
    const { username } = req.body;
    const opts = generateRegistrationOptions({
    rpName: "Demo",
    rpID: "localhost",
    userID: username,
    userName: username,
    attestationType: "none",
    authenticatorSelection: { authenticatorAttachment: "platform", userVerification: "discouraged" },
    });
    users[username] = { currentChallenge: opts.challenge };
    res.json(opts);
});
                                    
                                    app.post("/verify-registration", async (req, res) => {
    const { username, credential } = req.body;
    const expectedChallenge = users[username]?.currentChallenge;
    try {
        const v = await verifyRegistrationResponse({
        response: credential,
            expectedChallenge,
        expectedOrigin: "http://localhost:3000",
        expectedRPID: "localhost",
        requireUserVerification: false,
        });
        if (v.verified) {
            users[username] = {
            credentialID: v.registrationInfo!.credentialID,
            publicKey: v.registrationInfo!.credentialPublicKey,
            counter: v.registrationInfo!.counter,
            };
            res.json({ verified: true });
        } else res.sendStatus(400);
    } catch {
        res.sendStatus(400);
    }
});
                                    
                                    app.post("/generate-authentication-options", (req, res) => {
    const { username } = req.body;
    const user = users[username];
    if (!user?.credentialID) return res.sendStatus(400);
    const opts = generateAuthenticationOptions({
    rpID: "localhost",
    allowCredentials: [{ id: user.credentialID, type: "public-key", transports: ["internal"] }],
    userVerification: "discouraged",
    });
    users[username].currentChallenge = opts.challenge;
    res.json(opts);
});
                                    
                                    app.post("/verify-authentication", async (req, res) => {
    const { username, credential } = req.body;
    const user = users[username];
    try {
        const v = await verifyAuthenticationResponse({
        response: credential,
        expectedChallenge: user.currentChallenge,
        expectedOrigin: "http://localhost:3000",
        expectedRPID: "localhost",
        authenticator: {
        credentialID: user.credentialID,
        credentialPublicKey: user.publicKey,
        counter: user.counter,
        },
        requireUserVerification: false,
        });
        if (v.verified) {
            user.counter = v.authenticationInfo.newCounter;
            res.json({ verified: true });
        } else res.sendStatus(400);
    } catch {
        res.sendStatus(400);
    }
});
                                    
app.listen(3001, () => console.log("Listening on 3001"));
```
                                    
This demonstrates a complete **passkey/WebAuthn backend** for registration and login flows ([medium.com][2]).
                                    
                                    ---
                                    
## 🧩 Next Steps
                                    
1. **Wire it up** — connect your SwiftUI `PasskeyButton` to these endpoints.
2. Make `fetchChallengeFromServer()` a real network call.
3. Use the responses to complete registration or login.
4. Protect routes and sessions as needed.
                                    
Let me know if you'd like:

* Integration with Firebase or Django backend code
* A complete SwiftUI + Node example repo
* Help with session management after login
                                    
[1]: https://www.reddit.com/r/webdevelopment/comments/188daug?utm_source=chatgpt.com "Passkeys @ Django app"
[2]: https://medium.com/%40siddhantahire98/building-a-modern-authentication-system-with-webauthn-passkeys-a-complete-guide-65cac3511049?utm_source=chatgpt.com "Building a Modern Authentication System with WebAuthn/Passkeys: A Complete Guide | by siddhant ahire | Medium"
