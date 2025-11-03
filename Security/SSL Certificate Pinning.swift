//
//  SSL Certificate Pinning.swift
//  
//
//  Created by Apple on 03/11/25.
//

import Foundation

Absolutely — let’s go step-by-step through **SSL certificate pinning** in iOS, focusing on **Swift / SwiftUI** apps that use **URLSession**.

---

## 🧩 What is SSL Certificate Pinning?

**SSL (Secure Sockets Layer) Certificate Pinning** is a security technique that helps ensure your app communicates only with a **trusted server** — even if a malicious actor compromises a Certificate Authority (CA) or installs a fake certificate.

Normally, iOS validates an HTTPS certificate against the trusted system CAs.
However, with **pinning**, you additionally **hardcode (or "pin")** your server’s certificate or public key in the app.
That way, even if someone tries a **man-in-the-middle (MITM)** attack with another valid certificate, your app will **reject** it.

---

## ⚙️ How Certificate Pinning Works in URLSession

In iOS, the key class for handling HTTPS authentication is:

```swift
URLSessionDelegate
```

When using `URLSession`, you can implement:

```swift
func urlSession(_ session: URLSession,
                didReceive challenge: URLAuthenticationChallenge,
                completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
```

This method is called whenever your app receives a server trust challenge.
You can inspect the server’s certificate, compare it to your pinned certificate, and then decide whether to trust it.

---

## 🧠 Two Common Pinning Methods

### 1. **Certificate Pinning (recommended)**

Compare the server’s certificate to a certificate file embedded in your app.

### 2. **Public Key Pinning**

Extract the server’s public key from the certificate and compare its hash to a stored one.

Certificate pinning is simpler, public key pinning is more flexible (survives re-issuance).

---

## 🧪 Example: Certificate Pinning using `URLSession`

Let’s walk through a concrete example.

### Step 1: Get the Server Certificate

In your browser:

* Visit your server URL (e.g., `https://api.example.com`).
* Export the certificate as `.cer` file (DER format).
* Add it to your Xcode project (make sure it's in the **app target bundle**).

Example file: `example_com.cer`

---

### Step 2: Create a Custom URLSessionDelegate

```swift
import Foundation

class PinnedSessionDelegate: NSObject, URLSessionDelegate {

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // 1️⃣ Ensure this is a server trust challenge
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // 2️⃣ Load local (pinned) certificate
        guard let pinnedCertURL = Bundle.main.url(forResource: "example_com", withExtension: "cer"),
              let pinnedCertData = try? Data(contentsOf: pinnedCertURL),
              let pinnedCert = SecCertificateCreateWithData(nil, pinnedCertData as CFData) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // 3️⃣ Get the server’s certificate
        let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0)!
        let serverCertData = SecCertificateCopyData(serverCert) as Data

        // 4️⃣ Compare the certificates
        if serverCertData == pinnedCertData {
            // ✅ The certificate matches
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // ❌ Certificate mismatch
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

---

### Step 3: Use the Custom Delegate with URLSession

```swift
let delegate = PinnedSessionDelegate()
let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

if let url = URL(string: "https://api.example.com/data") {
    let task = session.dataTask(with: url) { data, response, error in
        if let error = error {
            print("Request failed: \(error)")
        } else {
            print("Success! Data received.")
        }
    }
    task.resume()
}
```

---

## 🧱 Integrating with SwiftUI

You can wrap this in a simple service layer:

```swift
import Foundation

class NetworkManager: ObservableObject {
    private let session: URLSession
    
    init() {
        let delegate = PinnedSessionDelegate()
        session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    }
    
    func fetchData() async throws -> Data {
        let url = URL(string: "https://api.example.com/data")!
        let (data, _) = try await session.data(from: url)
        return data
    }
}
```

Then in SwiftUI:

```swift
@StateObject private var network = NetworkManager()

Task {
    do {
        let data = try await network.fetchData()
        print("Data: \(data)")
    } catch {
        print("Error: \(error)")
    }
}
```

---

## 🧰 Public Key Pinning Example (Optional)

If you prefer **public key pinning**, you can hash the public key instead of comparing certificates:

```swift
if let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0),
   let serverKey = SecCertificateCopyKey(serverCert),
   let serverKeyData = SecKeyCopyExternalRepresentation(serverKey, nil) as Data? {
       
    let pinnedKeyHash = "Base64EncodedHashHere"
    let serverKeyHash = sha256(data: serverKeyData).base64EncodedString()

    if serverKeyHash == pinnedKeyHash {
        completionHandler(.useCredential, URLCredential(trust: serverTrust))
    } else {
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}
```

---

## ⚠️ Notes and Best Practices

* 🔐 Always pin the **production** certificate, not staging.
* 🔄 Update your app before certificates expire.
* ⚙️ For multiple environments, you can pin multiple certificates.
* 🧱 Avoid hardcoding raw keys in code — load from bundle resources.
* 🧪 Always test pinning with both valid and invalid certs.

---

Would you like me to show the **public key hash generation process** (so you can get the correct Base64 hash to embed in your app)?
