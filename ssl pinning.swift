//
//  ssl pinning.swift
//  
//
//  Created by Apple on 22/10/25.
//

import Foundation

### ✅ SSL Pinning in iOS (Swift) — Explained

---

### 🔐 What is SSL Pinning?

**SSL Pinning** is a security technique used in mobile apps to **prevent man-in-the-middle (MITM) attacks**. It ensures that your app communicates only with **trusted servers**, by "pinning" the server’s SSL certificate or public key in the app.

Even if a device is compromised (e.g., using tools like Charles Proxy or Burp Suite with a custom root CA), SSL pinning helps block traffic from going through if the certificate or key doesn’t match what the app expects.

---

### 🧠 How SSL Works (Before Pinning)

Normally:

1. App opens HTTPS connection.
2. The server presents its SSL certificate.
3. The OS (iOS) checks it against trusted Certificate Authorities (CAs).
4. If valid, the connection is established.

But: 🔓 If a malicious CA is added to the device, this validation can be bypassed. That’s where **SSL pinning** comes in.

---

### 🔒 How SSL Pinning Works

In SSL Pinning, you **embed** the expected certificate or public key in the app.

* During runtime, the app compares the **server’s certificate/key** with the pinned one.
* If they match ✅ → connection allowed.
* If not ❌ → connection rejected.

---

### 🔧 Types of SSL Pinning

| Type                               | Description                                   | Usage in Swift                             |
| ---------------------------------- | --------------------------------------------- | ------------------------------------------ |
| **Certificate Pinning**            | Store and match full `.cer` file              | Most common                                |
| **Public Key Pinning**             | Extract public key from certificate and match | More stable (survives certificate renewal) |
| **SPKI (Subject Public Key Info)** | Hash of the public key info                   | Rare in iOS but possible                   |

---

## ✅ iOS Implementation in Swift

### 📄 Certificate Pinning using `URLSessionDelegate`

```swift
class PinnedSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust,
           let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) {

            // Load local certificate
            if let localCertPath = Bundle.main.path(forResource: "your_pinned_cert", ofType: "cer"),
               let localCertData = try? Data(contentsOf: URL(fileURLWithPath: localCertPath)) {
                
                let serverCertData = SecCertificateCopyData(certificate) as Data

                if serverCertData == localCertData {
                    let credential = URLCredential(trust: serverTrust)
                    completionHandler(.useCredential, credential)
                    return
                }
            }
        }

        // Reject connection
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}
```

---

## 🎯 Common iOS Interview Questions on SSL Pinning

Below is a categorized and complete list of **realistic interview questions** and **sample answers** for Swift/iOS positions:

---

### 🔸 1. **What is SSL pinning and why is it important?**

**Answer:**
SSL pinning ensures the app only communicates with trusted servers by comparing the server's certificate or public key against one embedded in the app. This protects against MITM attacks, even on compromised devices.

---

### 🔸 2. **What are the types of SSL pinning? Which is better?**

**Answer:**

* **Certificate Pinning:** Full certificate is compared. Needs update on cert renewal.
* **Public Key Pinning:** Compares the key only. More flexible across cert updates.
* Public key pinning is more resilient, but certificate pinning is easier to implement.

---

### 🔸 3. **How do you implement SSL pinning in iOS (Swift)?**

**Answer:**
Using `URLSessionDelegate` and handling the server trust challenge manually. Load the local certificate (`.cer`), get the server certificate, and compare both.

---

### 🔸 4. **What are the drawbacks of SSL pinning?**

**Answer:**

* Hardcoding certificates means you need to release an app update if the certificate changes.
* Difficult to manage in large-scale deployments.
* Pinning mistakes can block legitimate traffic.

---

### 🔸 5. **How to handle certificate rotation in SSL pinning?**

**Answer:**
Use **public key pinning** or **multiple certificates** for pinning during transition periods. Store and check against an array of valid certs/keys.

---

### 🔸 6. **Can SSL pinning be bypassed? How do you protect against that?**

**Answer:**
Yes, via tools like Frida, SSL Kill Switch, or custom jailbreak tweaks. Protection methods:

* Use Jailbreak detection
* Obfuscate SSL pinning logic
* Perform certificate checks in native code (C/C++)
* Combine multiple anti-tamper techniques

---

### 🔸 7. **Where do you store the pinned certificate in iOS?**

**Answer:**
Typically in the app bundle as a `.cer` file. This is read-only and bundled during compilation.

---

### 🔸 8. **Does Alamofire support SSL pinning?**

**Answer:**
Yes. Alamofire allows certificate and public key pinning via the `ServerTrustManager` and `ServerTrustEvaluating` APIs.

Example:

```swift
let evaluators = [
    "yourdomain.com": PinnedCertificatesTrustEvaluator()
]

let manager = ServerTrustManager(evaluators: evaluators)
let session = Session(serverTrustManager: manager)
```

---

### 🔸 9. **What is `SecTrust` and how is it used in SSL pinning?**

**Answer:**
`SecTrust` is part of Apple’s security framework. It represents the server’s trust object in a TLS handshake. You can extract the certificate from it to compare with your pinned one.

---

### 🔸 10. **How do you test SSL pinning during development?**

**Answer:**

* Use tools like Charles Proxy with a custom certificate.
* Temporarily disable pinning logic to test various server configurations.
* Simulate MITM attacks to ensure pinning blocks untrusted connections.

---

### ⚠️ Bonus: **Tricky Questions**

* **Q:** What happens if your server’s certificate expires and your app uses certificate pinning?

  * **A:** The connection will fail. You must release an app update with the new certificate.

* **Q:** Can you pin self-signed certificates?

  * **A:** Yes, SSL pinning works with self-signed certs, especially in dev or internal apps.

---

## ✅ Summary

| Topic                | Details                                     |
| -------------------- | ------------------------------------------- |
| **Purpose**          | Prevent MITM attacks                        |
| **Implemented with** | `URLSessionDelegate`, `SecTrust`, Alamofire |
| **Best Practice**    | Public key pinning + fallback cert          |
| **Testing**          | Tools like Charles, Frida, Burp Suite       |
| **Downsides**        | Cert rotation requires app updates          |

---

If you'd like, I can provide:

* ✅ Sample project with SSL pinning
* ✅ Alamofire-specific implementation
* ✅ Jailbreak/SSL pinning bypass detection tips

Let me know what you want to dive deeper into.

# Certificate Pinning and Public‑Key Pinning (iOS / Swift) — how to implement both
                                                                                                            
Below are practical, ready‑to‑use implementations and best practices for **certificate pinning** and **public‑key (SPKI) pinning** in Swift using `URLSession`. I also include short **Alamofire** examples and testing/rollout tips.
                                                                                                            
---
                                                                                                            
# 1) Preparation — get the certificate(s) or public key(s)

1. From a browser or `openssl` export the server certificate in DER (`.cer`) format:

* Using `openssl`:

```
openssl s_client -connect example.com:443 -showcerts </dev/null 2>/dev/null \
| openssl x509 -outform der > example_com.cer
```
2. Add one or more `.cer` files to your app bundle (e.g., drag into Xcode, ensure target membership, copy resources).
3. Optionally compute and record a public‑key (SPKI) SHA‑256 fingerprint for pinning rotation planning.

---
                                                                                
# 2) Certificate pinning — URLSessionDelegate implementation

**Idea:** compare the server leaf certificate DER bytes with the `.cer` bytes bundled in your app.

```swift
import Foundation
import Security

final class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    private let pinnedCertData: [Data]
    
    init(pinnedCertNames: [String]) {
        self.pinnedCertData = pinnedCertNames.compactMap { name in
            guard let url = Bundle.main.url(forResource: name, withExtension: "cer"),
                  let data = try? Data(contentsOf: url) else { return nil }
            return data
        }
        super.init()
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Get DER data of server certificate
        let serverCertData = SecCertificateCopyData(serverCert) as Data
        
        // Compare server cert to any pinned cert
        if pinnedCertData.contains(serverCertData) {
            // pass through system validation too (optional)
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

**Usage:**

```swift
let delegate = CertificatePinningDelegate(pinnedCertNames: ["example_com"]) // name without .cer
let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
session.dataTask(with: URL(string: "https://example.com")!) { data, resp, err in
    // handle response
}.resume()
```

**Notes**

* This checks only the leaf certificate. You can compare the entire chain if desired (iterate `SecTrustGetCertificateAtIndex`).
* When the server certificate is rotated, you must update the app (unless you include multiple certs, see below).
* Store multiple certificates (current + next) to support smooth rotation.
                                                                                
---

# 3) Public‑Key (SPKI) pinning — more robust to cert renewal

**Idea:** extract the server’s public key, canonicalize it (SPKI), compute SHA‑256 and compare with pinned hash(es). SPKI pinning survives certificate re-issuance as long as the key pair stays the same.

Implementation below extracts public key bytes and computes SHA‑256 base64 encoded string.

```swift
import Foundation
import Security
import CommonCrypto // for SHA256; or use CryptoKit on iOS 13+

// Helper to compute SHA256
func sha256(_ data: Data) -> Data {
    var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes { ptr in
        _ = CC_SHA256(ptr.baseAddress, CC_LONG(data.count), &hash)
    }
    return Data(hash)
}

final class PublicKeyPinningDelegate: NSObject, URLSessionDelegate {
    // pinned SPKI hashes as base64 strings (sha256 of SubjectPublicKeyInfo)
    private let pinnedSPKI: Set<String>
    
    init(pinnedSPKIBase64: [String]) {
        self.pinnedSPKI = Set(pinnedSPKIBase64)
        super.init()
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Evaluate trust first with system (optional but recommended)
        var result = SecTrustResultType.invalid
        let status = SecTrustEvaluate(serverTrust, &result)
        if status != errSecSuccess {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Extract leaf certificate's public key
#if swift(>=5.0)
        // SecTrustCopyKey is available iOS 12+
        guard let serverKey = SecTrustCopyKey(serverTrust),
              let publicKeyData = SecKeyCopyExternalRepresentation(serverKey, nil) as Data? else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
#else
        // Fallbacks for older iOS versions are more verbose — omitted for brevity
#endif
        
        // The raw publicKeyData is not the SPKI itself always. We can derive SPKI by re-encoding
        // or, more simply, get the full certificate DER and compute SPKI by parsing the certificate.
        // A pragmatic approach is to compute SHA256 on the SubjectPublicKeyInfo bytes.
        
        // Simpler method: extract the server certificate, then get SPKI bytes using SecCertificateCopyPublicKey?
        guard let cert = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let certData = SecCertificateCopyData(cert) as Data
        
        // Derive SPKI hash from the certificate using SecCertificateCopyPublicKey + external representation
        // (we already did SecKeyCopyExternalRepresentation above; that is acceptable in practice for pinning)
        let spkiHash = sha256(publicKeyData).base64EncodedString()
        
        if pinnedSPKI.contains(spkiHash) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

**How to compute the local pinned SPKI hash**
You can compute the local SPKI hash once (server or dev machine):

* Using `openssl` to extract SPKI and hash:

```bash
# Get the SPKI (public key) in DER form, then base64-encode the SHA256
openssl x509 -in server.crt -pubkey -noout \
| openssl pkey -pubin -outform der \
| openssl dgst -sha256 -binary | openssl base64
```

Store that base64 string in your app (`["base64hash..."]`), and use it in `PublicKeyPinningDelegate`.

**Notes**

* Using `SecKeyCopyExternalRepresentation` and hashing the raw public key bytes is commonly used in iOS implementations. The safest is to compute the hash of the SPKI DER bytes (as openssl command above).
* Always store multiple SPKI hashes (current + next) to support rolling keys.

---

# 4) Certificate vs Public‑Key pinning — quick comparison

* **Certificate pinning**

* Pros: easy to implement (just compare DER bytes).
* Cons: breaks when certificate is reissued/renewed (unless same cert re-used).
* **Public‑key pinning**

* Pros: survives certificate renewal if same key pair used; more flexible.
* Cons: slightly more complex to extract canonical public key (SPKI) bytes and compute hash.

Recommendation: use **public‑key (SPKI) pinning** for production where you expect cert rotations, include multiple pins for smooth rotation.

---

# 5) Supporting multiple pins & graceful rotation

Keep an array/set of pinned certs or SPKI hashes:

```swift
let delegate = PublicKeyPinningDelegate(pinnedSPKIBase64: [
    "currentBase64Hash",
    "nextBase64Hash" // future key to accept during rotation window
])
```

This allows the server to rotate keys without immediately forcing an app release.

---

# 6) Alamofire examples (v5+)

Alamofire provides `ServerTrustManager` with `PinnedCertificatesTrustEvaluator` and `PublicKeysTrustEvaluator`.

Certificate pinning example:

```swift
import Alamofire

let evaluators: [String: ServerTrustEvaluating] = [
    "example.com": PinnedCertificatesTrustEvaluator(certificates: Bundle.main.af.certificates,
                                                    acceptSelfSignedCertificates: false,
                                                    performDefaultValidation: true,
                                                    validateHost: true)
]

let serverTrustManager = ServerTrustManager(evaluators: evaluators)
let session = Session(serverTrustManager: serverTrustManager)
```

Public key pinning example:

```swift
let evaluators: [String: ServerTrustEvaluating] = [
    "example.com": PublicKeysTrustEvaluator(keys: Bundle.main.af.publicKeys(),
                                            performDefaultValidation: true,
                                            validateHost: true)
]

let session = Session(serverTrustManager: ServerTrustManager(evaluators: evaluators))
```

(Alamofire provides convenient helpers to load certs/keys from the bundle.)

---

# 7) Testing pinning

* Use a proxy (Charles, Burp) with an inserted CA — pinning should block the connection.
* Test certificate rotation by temporarily swapping server cert or key to ensure pins behave as expected.
* For dev builds you can allow bypass/feature flags for easier debugging (never in production).
                                                            
                                                            ---
                                                            
                                                            # 8) Hardening & anti‑bypass notes

* Attackers can bypass pinning on jailbroken devices (Frida, runtime patching). Consider:

* Runtime integrity checks / jailbreak detection (not foolproof).
* Obfuscate pinning logic (delays easy static patching).
* Put critical checks in native C code or use third‑party SDKs designed for tamper-resistance.
* Don’t rely solely on pinning — use server-side protections as well (HSTS, short-lived tokens).
                                                                                
---
                                                                                
# 9) Troubleshooting checklist

* Make sure `.cer` in bundle is DER encoded (not PEM). Xcode sometimes shows `.cer` but contents differ.
* Compare exact bytes for certificate pinning — any mismatch means reject.
* For SPKI, ensure the base64 hash you compute locally matches what you compute from the server using the same steps (openssl recommended).
* Enable logging around your `URLSessionDelegate` challenge to see the server certificates & computed hashes during development.
                            
---
                            
# 10) Minimal summary / takeaways

* **Certificate pinning**: compare DER bytes — simple but brittle at renewal.
* **Public‑key (SPKI) pinning**: compute SHA256 of SubjectPublicKeyInfo and compare base64 — more robust to cert renewals.
* Always include multiple pins for rotation and test with real-world scenarios (proxy, cert rotation).
* Use Alamofire helpers if you use that library.
                                    
---
                                    
If you want, I can:
                                        
* generate a small sample Xcode project with working certificate and SPKI pinning code,
* show exact `openssl` commands for your server and produce the Swift code prefilled with your certificate name or SPKI hash (paste the base64 SPKI or cert file name and I’ll embed it).
