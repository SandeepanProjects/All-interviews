//
//  SSL Public Key Pinning.swift
//  
//
//  Created by Apple on 03/11/25.
//

import Foundation

If you want, I can create a **full SwiftUI example** that automatically **fetches JSON data using public key pinning** with error handling and user feedback — ready to drop into a real app.

Do you want me to do that?

Perfect! Let’s build a **full SwiftUI example** that fetches JSON from a server using **Public Key Pinning** with URLSession. This example will include:

* Public key pinning with SHA-256 hash comparison
* Async data fetching
* Error handling and user feedback in the UI

---

## 1️⃣ Create the PublicKeyPinningDelegate

```swift
import Foundation
import CryptoKit

class PublicKeyPinningDelegate: NSObject, URLSessionDelegate {

    // Replace this with your server's public key hash (Base64)
    private let pinnedPublicKeyHash = "Base64EncodedHashHere"

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        var isServerTrusted = false

        for i in 0..<certificateCount {
            if let certificate = SecTrustGetCertificateAtIndex(serverTrust, i),
               let publicKey = SecCertificateCopyKey(certificate),
               let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? {

                let hash = SHA256.hash(data: publicKeyData)
                let hashBase64 = Data(hash).base64EncodedString()

                if hashBase64 == pinnedPublicKeyHash {
                    isServerTrusted = true
                    break
                }
            }
        }

        if isServerTrusted {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

---

## 2️⃣ NetworkManager with Async Fetching

```swift
import Foundation

@MainActor
class NetworkManager: ObservableObject {
    private let session: URLSession

    init() {
        let delegate = PublicKeyPinningDelegate()
        session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    }

    @Published var dataText: String = ""
    @Published var errorText: String = ""

    func fetchData(from urlString: String) async {
        guard let url = URL(string: urlString) else {
            errorText = "Invalid URL"
            return
        }

        do {
            let (data, _) = try await session.data(from: url)
            if let jsonString = String(data: data, encoding: .utf8) {
                dataText = jsonString
                errorText = ""
            }
        } catch {
            errorText = "Error: \(error.localizedDescription)"
        }
    }
}
```

---

## 3️⃣ SwiftUI View

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var network = NetworkManager()

    var body: some View {
        VStack(spacing: 20) {
            if !network.dataText.isEmpty {
                ScrollView {
                    Text(network.dataText)
                        .padding()
                }
            } else if !network.errorText.isEmpty {
                Text(network.errorText)
                    .foregroundColor(.red)
                    .padding()
            } else {
                ProgressView("Fetching data...")
            }

            Button("Refresh") {
                Task {
                    await network.fetchData(from: "https://api.example.com/data")
                }
            }
            .padding()
        }
        .task {
            await network.fetchData(from: "https://api.example.com/data")
        }
        .padding()
    }
}
```

---

## ✅ How it Works

1. **App launches → ContentView appears**
2. `NetworkManager.fetchData` is called asynchronously
3. `URLSession` delegates the SSL trust evaluation to `PublicKeyPinningDelegate`
4. The server’s public key is hashed and compared with the pinned hash
5. If it matches → data is fetched and displayed; if not → connection fails

---

## ⚠️ Tips for Production

* Pin **multiple public keys** if the server rotates certificates.
* Make sure your pinned hash is **SHA-256 of the DER-encoded public key**.
* Test with both valid and invalid certs to ensure proper rejection.
* Use async/await for SwiftUI-friendly networking.

---

If you want, I can make an **enhanced version** that **pins multiple keys, handles JSON decoding**, and **shows structured data** in SwiftUI instead of raw strings — a production-ready pattern.

Do you want me to do that?









Absolutely! Let’s go **deep into Public Key Pinning** for iOS with **SwiftUI**. I’ll break it down thoroughly so you understand **what it is, why it’s useful, and exactly how to implement it** using `URLSession`.

---

## 🔑 What is Public Key Pinning?

**Public Key Pinning (PKP)** is a technique to make your app trust only specific **public keys** of your server certificates.

* Instead of comparing the full certificate (`.cer`), you extract the **public key** from the server’s certificate and compare its hash with a value you’ve embedded in the app.
* The advantage: your app can still trust the server even if the certificate is renewed, as long as the **public key stays the same**.

### Why use Public Key Pinning?

1. Protects against **MITM attacks** even if a certificate is issued by a trusted CA.
2. More flexible than certificate pinning (server can renew its cert without breaking the app).
3. Adds an extra layer of security beyond normal HTTPS.

---

## 🛠 How Public Key Pinning Works in iOS

1. The app connects to the server over HTTPS.
2. iOS performs normal **certificate validation**.
3. The app extracts the **server public key** from the certificate.
4. The app computes a **hash** of the public key.
5. Compare the hash with the **pinned hash** embedded in the app.
6. If it matches → trust; if not → cancel the connection.

---

## Step 1: Generate the Pinned Public Key Hash

1. Export your server certificate (DER format `.cer`) from your browser.
2. Use a script to extract the public key and compute the SHA-256 hash.

Here’s an example using **OpenSSL**:

```bash
# Extract public key from cert
openssl x509 -in example_com.cer -pubkey -noout > pubkey.pem

# Convert to DER format
openssl rsa -pubin -inform PEM -in pubkey.pem -outform DER -out pubkey.der

# Compute SHA-256 hash
openssl dgst -sha256 -binary pubkey.der | openssl base64
```

This **Base64 string** is the one you’ll embed in your app as the pinned key.

---

## Step 2: Implement Public Key Pinning in iOS

We’ll use `URLSessionDelegate` to handle the server trust challenge.

```swift
import Foundation
import CryptoKit

class PublicKeyPinningDelegate: NSObject, URLSessionDelegate {

    // Replace with your server's public key hash
    private let pinnedPublicKeyHash = "Base64EncodedHashHere"

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        var isServerTrusted = false

        for i in 0..<certificateCount {
            if let certificate = SecTrustGetCertificateAtIndex(serverTrust, i),
               let publicKey = SecCertificateCopyKey(certificate),
               let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? {

                // Compute SHA-256 hash
                let hash = SHA256.hash(data: publicKeyData)
                let hashBase64 = Data(hash).base64EncodedString()

                if hashBase64 == pinnedPublicKeyHash {
                    isServerTrusted = true
                    break
                }
            }
        }

        if isServerTrusted {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

---

## Step 3: Use the Delegate with URLSession

```swift
let delegate = PublicKeyPinningDelegate()
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

## Step 4: Integrate with SwiftUI

```swift
import SwiftUI

@MainActor
class NetworkManager: ObservableObject {
    private let session: URLSession

    init() {
        let delegate = PublicKeyPinningDelegate()
        session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    }

    func fetchData() async throws -> Data {
        let url = URL(string: "https://api.example.com/data")!
        let (data, _) = try await session.data(from: url)
        return data
    }
}

struct ContentView: View {
    @StateObject private var network = NetworkManager()
    @State private var dataText = ""

    var body: some View {
        Text(dataText)
            .task {
                do {
                    let data = try await network.fetchData()
                    dataText = String(decoding: data, as: UTF8.self)
                } catch {
                    dataText = "Error: \(error)"
                }
            }
    }
}
```

---

## ⚠️ Best Practices for Public Key Pinning

1. **Pin multiple keys**: If your server rotates keys, pin old and new keys temporarily.
2. **Avoid hardcoding raw keys in code**: Use constants or secure storage.
3. **Test thoroughly**: Check both valid and invalid certificate scenarios.
4. **Combine with standard HTTPS validation**: PKP is an extra layer, not a replacement.

---
