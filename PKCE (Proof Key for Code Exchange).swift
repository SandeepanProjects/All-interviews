//
//  PKCE (Proof Key for Code Exchange).swift
//  
//
//  Created by Apple on 26/07/25.
//

import Foundation

**PKCE (Proof Key for Code Exchange)** is a security extension to the OAuth 2.0 authorization code flow, designed to secure public clients (like mobile apps) that can't safely store client secrets.

### 🔐 Why Use PKCE?

Without PKCE, malicious apps could intercept authorization codes and exchange them for tokens. PKCE protects against this by binding the authorization request to the token exchange using a dynamically generated secret.

---

## ✅ PKCE Flow Overview

1. **Client (your app)** generates:

   * `code_verifier` – a cryptographically random string
   * `code_challenge` – a hashed version of `code_verifier`

2. The app initiates an OAuth authorization request with:

   * `code_challenge`
   * `code_challenge_method` (`S256` or `plain`)

3. User logs in and authorizes the app.

4. Authorization server redirects back with `authorization_code`.

5. The app sends a **token request** to the token endpoint with:

   * `authorization_code`
   * `code_verifier`

6. Server validates the `code_verifier` matches the original `code_challenge`, then issues access token.

---

## 🛠️ Implementing PKCE in iOS (SwiftUI)

### Step 1: Generate `code_verifier` and `code_challenge`

```swift
import Foundation
import CryptoKit

func generateCodeVerifier() -> String {
    let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
    return String((0..<64).map { _ in characters.randomElement()! })
}

func generateCodeChallenge(from verifier: String) -> String {
    let data = Data(verifier.utf8)
    let hashed = SHA256.hash(data: data)
    return Data(hashed).base64URLEncodedString()
}

extension Data {
    func base64URLEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
```

### Step 2: Start Authorization (Open Browser)

Use `ASWebAuthenticationSession` for OAuth login:

```swift
import AuthenticationServices

func startOAuthLogin() {
    let codeVerifier = generateCodeVerifier()
    let codeChallenge = generateCodeChallenge(from: codeVerifier)
    
    let clientID = "your-client-id"
    let redirectURI = "yourapp://callback"
    let authorizationEndpoint = "https://auth.example.com/authorize"
    
    var components = URLComponents(string: authorizationEndpoint)!
    components.queryItems = [
        URLQueryItem(name: "response_type", value: "code"),
        URLQueryItem(name: "client_id", value: clientID),
        URLQueryItem(name: "redirect_uri", value: redirectURI),
        URLQueryItem(name: "code_challenge", value: codeChallenge),
        URLQueryItem(name: "code_challenge_method", value: "S256"),
        URLQueryItem(name: "scope", value: "openid profile email")
    ]
    
    guard let authURL = components.url else { return }
    
    let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "yourapp") { callbackURL, error in
        guard let callbackURL = callbackURL else {
            print("Login failed: \(String(describing: error))")
            return
        }
        
        // Extract the authorization code
        if let code = URLComponents(string: callbackURL.absoluteString)?
            .queryItems?
            .first(where: { $0.name == "code" })?.value {
            exchangeCodeForToken(code: code, codeVerifier: codeVerifier)
        }
    }
    
    session.presentationContextProvider = YourPresentationContextProvider()
    session.start()
}
```

> Make sure `YourPresentationContextProvider` conforms to `ASWebAuthenticationPresentationContextProviding`.

### Step 3: Exchange Code for Token

```swift
func exchangeCodeForToken(code: String, codeVerifier: String) {
    let tokenEndpoint = URL(string: "https://auth.example.com/token")!
    var request = URLRequest(url: tokenEndpoint)
    request.httpMethod = "POST"
    let bodyParams = [
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": "yourapp://callback",
        "client_id": "your-client-id",
        "code_verifier": codeVerifier
    ]
    request.httpBody = bodyParams
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: "&")
        .data(using: .utf8)
    
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data else { return }
        // Parse the token response
        print(String(data: data, encoding: .utf8) ?? "")
    }.resume()
}
```

---

## 📌 Notes

* Replace URLs, client ID, and scopes with values from your OAuth provider.
* Securely store tokens (e.g., in Keychain).
* Handle token expiration and refresh logic.

---

Would you like a working SwiftUI demo project link or help with a specific OAuth provider (e.g., Google, Auth0, Okta)?

### 1. **What is PKCE? (Proof Key for Code Exchange)**

PKCE is a security enhancement to the standard OAuth 2.0 authorization code flow. It was specifically designed to address the vulnerability where public clients, such as mobile apps, are unable to securely store secrets. PKCE mitigates the risk of authorization code interception by requiring an additional proof of possession for the authorization code when exchanging it for an access token.

#### **Key Concepts**:

1. **Public Clients**: These are clients (like mobile or browser apps) that can't store client secrets securely (because they are exposed on the client side).
2. **Authorization Code Flow**: This is the flow where the client first gets an authorization code (after user authentication) and then exchanges it for an access token from the authorization server.
3. **Code Verifier**: A random string generated by the client. This string is kept secret by the client.
4. **Code Challenge**: A hashed version of the `code_verifier`. It’s sent in the initial authorization request to the authorization server.
5. **Code Challenge Method**: Specifies how the `code_challenge` is generated. The most common method is `S256` (SHA-256 hash).

#### **How PKCE Works**:

1. **Client**: Generates a random `code_verifier` and derives the `code_challenge` from it.
2. **Authorization Request**: When the client redirects the user to the authorization server, it includes the `code_challenge` and the `code_challenge_method` (`S256` or `plain`).
3. **User Authentication**: The user logs in and authorizes the client.
4. **Authorization Code**: The server redirects the user back to the client with an `authorization_code`.
5. **Token Request**: The client sends the `authorization_code` to the server along with the `code_verifier` in a POST request.
6. **Token Exchange**: The server hashes the `code_verifier` and compares it to the original `code_challenge`. If they match, the server issues the access token.

---

### 2. **Implementing PKCE in iOS (SwiftUI)**

To implement PKCE in iOS, you'll typically interact with an OAuth authorization flow where you need to generate a `code_verifier` and `code_challenge`, start the OAuth process using a web authentication session, and then exchange the code for a token. Below, I'll walk you through the steps for implementing PKCE in a SwiftUI iOS app.

#### **Step-by-Step Implementation**

1. **Generate `code_verifier` and `code_challenge`**:

   In PKCE, the `code_verifier` is a cryptographically random string (64 characters long), and the `code_challenge` is a SHA-256 hash of the `code_verifier`.

   Here’s how you can generate them in Swift:

   ```swift
   import Foundation
   import CryptoKit

   func generateCodeVerifier() -> String {
       let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
       return String((0..<64).map { _ in characters.randomElement()! })
   }

   func generateCodeChallenge(from verifier: String) -> String {
       let data = Data(verifier.utf8)
       let hashed = SHA256.hash(data: data)
       return Data(hashed).base64URLEncodedString()
   }

   extension Data {
       func base64URLEncodedString() -> String {
           return self.base64EncodedString()
               .replacingOccurrences(of: "+", with: "-")
               .replacingOccurrences(of: "/", with: "_")
               .replacingOccurrences(of: "=", with: "")
       }
   }
   ```

   * **`generateCodeVerifier()`**: Generates a random 64-character string that serves as the `code_verifier`.
   * **`generateCodeChallenge(from:)`**: Creates a SHA-256 hash of the `code_verifier`, which is then Base64 URL encoded to form the `code_challenge`.

---

2. **Start OAuth Flow (Using Web Authentication)**:

   iOS provides a class called `ASWebAuthenticationSession` to open a web page where the user can authenticate and authorize the app. You'll send the `code_challenge` and `code_challenge_method` (`S256`) in the query parameters.

   ```swift
   import AuthenticationServices

   func startOAuthLogin() {
       let codeVerifier = generateCodeVerifier()
       let codeChallenge = generateCodeChallenge(from: codeVerifier)
       
       let clientID = "your-client-id"
       let redirectURI = "yourapp://callback"
       let authorizationEndpoint = "https://auth.example.com/authorize"
       
       var components = URLComponents(string: authorizationEndpoint)!
       components.queryItems = [
           URLQueryItem(name: "response_type", value: "code"),
           URLQueryItem(name: "client_id", value: clientID),
           URLQueryItem(name: "redirect_uri", value: redirectURI),
           URLQueryItem(name: "code_challenge", value: codeChallenge),
           URLQueryItem(name: "code_challenge_method", value: "S256"),
           URLQueryItem(name: "scope", value: "openid profile email")
       ]
       
       guard let authURL = components.url else { return }
       
       let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "yourapp") { callbackURL, error in
           guard let callbackURL = callbackURL else {
               print("Login failed: \(String(describing: error))")
               return
           }
           
           // Extract the authorization code
           if let code = URLComponents(string: callbackURL.absoluteString)?
               .queryItems?
               .first(where: { $0.name == "code" })?.value {
               exchangeCodeForToken(code: code, codeVerifier: codeVerifier)
           }
       }
       
       session.presentationContextProvider = YourPresentationContextProvider()
       session.start()
   }
   ```

   * **Authorization URL**: The `authorizationEndpoint` is the OAuth provider's URL that handles authentication.
   * **`ASWebAuthenticationSession`**: It provides a seamless way to open the login page and handle the callback (with the authorization code).

---

3. **Exchange Authorization Code for Access Token**:

   After the user authorizes the app, they are redirected back with an authorization code. Now you need to exchange that code for an access token by sending a POST request to the token endpoint, including the `code_verifier`.

   ```swift
   func exchangeCodeForToken(code: String, codeVerifier: String) {
       let tokenEndpoint = URL(string: "https://auth.example.com/token")!
       var request = URLRequest(url: tokenEndpoint)
       request.httpMethod = "POST"
       let bodyParams = [
           "grant_type": "authorization_code",
           "code": code,
           "redirect_uri": "yourapp://callback",
           "client_id": "your-client-id",
           "code_verifier": codeVerifier
       ]
       request.httpBody = bodyParams
           .map { "\($0.key)=\($0.value)" }
           .joined(separator: "&")
           .data(using: .utf8)
       
       request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
       
       URLSession.shared.dataTask(with: request) { data, response, error in
           guard let data = data else { return }
           // Parse the token response
           print(String(data: data, encoding: .utf8) ?? "")
       }.resume()
   }
   ```

   * **Token Request**: The request contains the `authorization_code` received from the callback and the `code_verifier` that proves the client was involved in the original authorization.
   * **Server Validation**: The server will validate the `code_verifier` and `code_challenge` and, if they match, issue the access token.

---

### Recap:

1. **Client generates `code_verifier`**: A random string, and sends a hash of it (`code_challenge`) to the OAuth server.
2. **User authenticates**: The app redirects the user to the OAuth provider to log in.
3. **Authorization code is returned**: After login, the app gets an `authorization_code`.
4. **Token exchange**: The app exchanges the `authorization_code` for an access token, including the original `code_verifier`.

---

### 💡 Extra Notes:

* **Security**: PKCE makes it much harder for malicious apps to intercept and use the authorization code.
* **OAuth Providers**: This can be adapted to work with any OAuth 2.0 provider (Google, Facebook, Auth0, etc.).
* **Authorization Server Setup**: Make sure your OAuth provider supports PKCE (most modern ones do).

---

Would you like a full project setup, or further explanations about specific steps (like handling token refresh)?
Sure! I'll break down both **PKCE (Proof Key for Code Exchange)** and the **OAuth 2.0 authorization code flow** in detail, and also guide you through implementing them in **SwiftUI**. Let’s start by explaining **PKCE** and **OAuth**, and then we’ll get into the iOS (SwiftUI) implementation.
                                                                                                        
---
                                                                                                        
### **1. PKCE (Proof Key for Code Exchange)**
                                                                                                        
**PKCE** (pronounced *pixy*) is an extension to the **OAuth 2.0 authorization code flow** that provides an additional layer of security. It's particularly useful for public clients like **mobile apps** or **single-page web apps**, which can't securely store secrets because they run in an environment where attackers could intercept them.
                                                                                                        
#### **Why PKCE is Needed**:
                                                                                                            
In the traditional OAuth 2.0 flow, the **client secret** (which is known to both the client and the server) is used to verify the client’s identity when it exchanges the **authorization code** for an **access token**. However, **public clients** (like mobile apps) can't store client secrets securely. This makes them vulnerable to **authorization code interception attacks**.
                                                                                                        
PKCE solves this by requiring the client to generate a **unique secret** for each authorization request, called the **code verifier**. This secret is never transmitted or stored permanently; instead, it’s used to create a **code challenge** that’s sent with the **authorization request**. When the authorization code is later exchanged for an access token, the authorization server checks that the code verifier used to exchange the code matches the original challenge.

---

#### **PKCE Flow** (How It Works):
1. **Client generates a code verifier** (random string).
2. **Client creates a code challenge** from the verifier (usually using a SHA-256 hash).
3. **Authorization Request**: The client sends the **code challenge** and the **code challenge method** (`S256` for SHA-256) in the request to the authorization server.
4. **User Authentication**: The user logs in and grants the client permissions.
5. **Authorization Code**: The authorization server redirects the user back to the client with an authorization code.
6. **Token Request**: The client sends the authorization code and the **code verifier** back to the authorization server to exchange it for an access token.
7. **Token Validation**: The authorization server hashes the **code verifier** and checks if it matches the **code challenge**. If they match, the server issues the access token.

---

### **2. OAuth 2.0 Authorization Code Flow (with PKCE)**

OAuth 2.0 is a framework for token-based authentication and authorization. It’s widely used by services like **Google**, **Facebook**, and **GitHub**. The **authorization code flow** is one of the most secure flows and is typically used in server-side apps.

#### **OAuth 2.0 Flow** (with PKCE):

1. **Client redirects to the authorization server**:

* The client sends the user to an authorization server’s authorization endpoint.
* The request contains the **client ID**, **redirect URI**, **response type** (`code`), **scope**, and **code challenge**.
2. **User logs in and grants permission**:

* The user logs into the authorization server and grants permission to the client app to access certain resources (e.g., email, profile).
3. **Authorization server redirects to the client**:

* The authorization server redirects the user back to the client's **redirect URI** with an **authorization code**.
4. **Client exchanges the code for a token**:

* The client sends the **authorization code** along with the **code verifier** (original secret) to the token endpoint of the authorization server.
5. **Authorization server verifies the code and issues the token**:

* The authorization server checks if the **code verifier** matches the **code challenge** it received earlier.
* If they match, the server issues an **access token** and an **ID token** (in case of OpenID Connect).

---

### **3. Implementing PKCE in iOS (SwiftUI)**

Now, let's walk through the practical steps of implementing **PKCE** in a **SwiftUI iOS app** using the **OAuth 2.0 authorization code flow**.

---

#### **Step-by-Step Implementation**:

**Step 1: Generate `code_verifier` and `code_challenge`**

The **`code_verifier`** is a random string that is unique for every authorization request. The **`code_challenge`** is a hashed version of the `code_verifier`.

Here’s how you can implement these in Swift:

```swift
import Foundation
import CryptoKit

// Step 1: Generate a random code_verifier (64 characters long)
func generateCodeVerifier() -> String {
let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
return String((0..<64).map { _ in characters.randomElement()! })
}

// Step 2: Generate code_challenge (SHA-256 hash of the code_verifier)
func generateCodeChallenge(from verifier: String) -> String {
    let data = Data(verifier.utf8)
    let hashed = SHA256.hash(data: data)
    return Data(hashed).base64URLEncodedString()
}

extension Data {
    func base64URLEncodedString() -> String {
        return self.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
```

* **`generateCodeVerifier()`** creates a random 64-character string.
* **`generateCodeChallenge(from:)`** hashes the `code_verifier` using SHA-256 and then Base64 URL encodes it.

---

**Step 2: Start OAuth Login Process (Web Authentication)**

Next, we use **`ASWebAuthenticationSession`** to open a web page where the user can authenticate and authorize the app.

```swift
import AuthenticationServices

func startOAuthLogin() {
    // Step 1: Generate the code_verifier and code_challenge
    let codeVerifier = generateCodeVerifier()
    let codeChallenge = generateCodeChallenge(from: codeVerifier)
    
    // Your OAuth provider info
    let clientID = "your-client-id"
    let redirectURI = "yourapp://callback"
    let authorizationEndpoint = "https://auth.example.com/authorize"
    
    // Step 2: Build the authorization URL with code_challenge
    var components = URLComponents(string: authorizationEndpoint)!
    components.queryItems = [
        URLQueryItem(name: "response_type", value: "code"),
        URLQueryItem(name: "client_id", value: clientID),
        URLQueryItem(name: "redirect_uri", value: redirectURI),
        URLQueryItem(name: "code_challenge", value: codeChallenge),
        URLQueryItem(name: "code_challenge_method", value: "S256"),
        URLQueryItem(name: "scope", value: "openid profile email")
    ]
    
    guard let authURL = components.url else { return }
    
    // Step 3: Open the authorization page using ASWebAuthenticationSession
    let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "yourapp") { callbackURL, error in
        guard let callbackURL = callbackURL else {
            print("Login failed: \(String(describing: error))")
            return
        }
        
        // Step 4: Extract the authorization code from the callback URL
        if let code = URLComponents(string: callbackURL.absoluteString)?
            .queryItems?
            .first(where: { $0.name == "code" })?.value {
            exchangeCodeForToken(code: code, codeVerifier: codeVerifier)
        }
    }
    
    // Optional: Set the presentation context provider for the session
    session.presentationContextProvider = YourPresentationContextProvider()
    session.start()
}
```

---

**Step 3: Exchange Authorization Code for Access Token**
                                            
Once the user successfully authenticates and is redirected back to the app with an **authorization code**, we exchange it for an access token by sending the `code_verifier` to the token endpoint.
                                            
```swift
func exchangeCodeForToken(code: String, codeVerifier: String) {
    let tokenEndpoint = URL(string: "https://auth.example.com/token")!
    var request = URLRequest(url: tokenEndpoint)
    request.httpMethod = "POST"
    let bodyParams = [
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": "yourapp://callback",
        "client_id": "your-client-id",
        "code_verifier": codeVerifier
    ]
    request.httpBody = bodyParams
        .map { "\($0.key)=\($0.value)" }
        .joined(separator: "&")
        .data(using: .utf8)
    
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data else { return }
        // Handle token response (parse the data to extract access token)
        print(String(data: data, encoding: .utf8) ?? "")
    }.resume()
}
```

* The **authorization code** and **code\_verifier** are sent to the **token endpoint**.
* The server verifies that the **code\_verifier** matches the original **code\_challenge** and then issues an **access token**.

---

### Summary of Key Steps in the PKCE Flow:

1. \*\*Generate `code_verifier` and `code_challenge`


\*\*.
2\. **Redirect the user to the authorization server** for login, passing the `code_challenge`.
                                                            3\. **User grants permission** and is redirected back with an **authorization code**.
                                                            4\. **Exchange the authorization code for an access token** by sending the `code_verifier`.
                                                            
---
                                                    
