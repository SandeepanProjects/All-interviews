//
//  How APIs are secured in production (JWT, bearer tokens).swift
//  
//
//  Created by Apple on 29/11/25.
//

import Foundation

Below is a **clear, complete, production-grade explanation** of how APIs are secured using **JWTs**, **Bearer tokens**, and the surrounding infrastructure that makes them safe in real-world systems.
I’ll cover:

1. What JWTs and bearer tokens actually are
2. How they are issued
3. How APIs validate them
4. How to secure them (best practices)
5. Common vulnerabilities and how production systems mitigate them
6. How OAuth2, OpenID Connect, and refresh tokens fit in

---

# 🔐 **1. What is a Bearer Token?**

A **Bearer token** is an authorization credential that says:

> If you have this token, you are trusted.

Typical format:

```
Authorization: Bearer <token>
```

The server receiving it:

* Does **not** care *who* the caller is, only that they possess a valid token.
* Validates token integrity and claims.
* Allows the request if valid.

Bearer tokens are simple, but require careful security because **anyone who obtains a bearer token can act as the user**.

---

# 🔑 **2. What is a JWT (JSON Web Token)?**

A **JWT** is a cryptographically signed token, commonly used as the *payload* of a bearer token.

JWT structure:

```
header.payload.signature
```

Example decoded JWT:

```json
{
  "sub": "12345",
  "role": "admin",
  "exp": 1735689600
}
```

The important part:
**The signature guarantees that the token was created by a trusted issuer and was not modified.**

Common signing algorithms:

* **HS256** — symmetric key (shared secret)
* **RS256** — asymmetric key (public/private RSA)

Production systems overwhelmingly use **RS256 (asymmetric)** because:

* API servers can verify using *public* keys
* Only auth servers hold the private signing key
* No shared secrets between many microservices

---

# 🏭 **3. How tokens are issued in production**

High-level flow:

### **Step 1 — Client authenticates**

* username/password
* SSO (Google, Apple, Microsoft)
* MFA
* OAuth2 authorization code flow

### **Step 2 — Authentication server issues tokens**

Usually:

* **Access token (short-lived JWT)**
* **Refresh token (long-lived, opaque or JWT)**

Example:

```json
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR...",
  "refresh_token": "f82a70c2-9378-4c5e-b...",
  "expires_in": 3600
}
```

### **Step 3 — Client uses the access token for API calls**

```
Authorization: Bearer eyJhbGc...
```

### **Step 4 — API server validates every request**

More on that below.

---

# 🧪 **4. How APIs validate tokens (the core security)**

When a server receives:

```
Authorization: Bearer <token>
```

It performs:

---

## **1. Signature validation**

For RS256:

* Server downloads the issuer's **public key (JWKS)**
* Validates the JWT signature using it
* Ensures token was issued by trusted issuer

If signature check fails → **unauthorized**.

---

## **2. Claims validation**

Key claims to check:

### ✔️ `exp`

Token expiration. Required.

### ✔️ `iat`

Issued-at timestamp.

### ✔️ `nbf`

Not-before timestamp.

### ✔️ `iss`

Issuer (e.g., `https://auth.mycompany.com`)

### ✔️ `aud`

Audience (the API identifier). Prevents tokens from being used on wrong APIs.

### ✔️ `sub`

Subject (user or service identity)

### ✔️ Custom claims

* roles
* permissions
* tenant id
* scopes

---

## **3. Scope/Role Permission Check**

Example:

```
scopes: ["payments.write"]
```

API enforces:

```
if "payments.write" not in scopes → 403
```

(Never trust the client to enforce this.)

---

# 🔁 **5. Access Tokens vs Refresh Tokens**

**Access Tokens**

* short lived (5–30 mins)
* sent to APIs
* must be easily verifiable
* typically JWTs

**Refresh Tokens**

* long-lived (days–months)
* never sent to APIs
* ONLY sent to auth server
* used to get new access tokens
* usually stored securely (encrypted DB, rotated on every use)

**Why?**

To reduce exposure:
If an attacker steals a short-lived access token, it expires quickly.

Refresh tokens remain in secure storage and never leave the client’s backend/mobile storage plugin.

---

# 🛡️ **6. Where tokens are stored (securely)**

### **Web apps**

* Access token: In-memory only (not cookies, not localStorage)
* Refresh token: HttpOnly secure cookie OR rotated opaque token

### **Mobile apps**

* Access token: memory
* Refresh token: Keychain / SecureStorage

### **Backend services**

* Env vars or vaults
* Token refresh handled via OAuth2 client credentials

### Never store tokens in:

❌ LocalStorage
❌ SessionStorage
❌ Plain cookies
❌ Source code
❌ Logs

---

# 🔒 **7. Preventing token theft in production**

### ✔ HTTPS everywhere

Bearer tokens must **never** go over plaintext HTTP.

### ✔ Short-lived access tokens

Minimize damage window.

### ✔ Refresh token rotation

Each refresh creates a new refresh token → old one becomes invalid.

### ✔ Token binding / sender constraint (MTLS, DPoP)

Reduces "bearer" nature → token must be tied to the client.

### ✔ IP/device/user agent validation (optional, risk-based)

### ✔ Rate limiting

Mitigates brute-force attempts.

### ✔ Revocation lists (for refresh tokens)

On logout, compromise, rotation.

### ✔ JWT blacklisting for critical events

Even though JWTs are stateless, APIs can use:

* blocklists
* "session version" claim
* user table's token-version field

---

# 🏗️ **8. JWT vs Opaque Tokens vs Session Tokens**

| Token Type         | Advantages                        | Disadvantages                     |
| ------------------ | --------------------------------- | --------------------------------- |
| **JWT**            | Fast API validation, no DB lookup | Hard to revoke, more complex      |
| **Opaque token**   | Easy revocation, simple           | Requires DB lookup every API call |
| **Session cookie** | Simple for browsers               | Not ideal for cross-service APIs  |

**Best practice in microservices:**
JWT access tokens + opaque refresh tokens.

---

# 🔐 **9. How OAuth2 and OpenID Connect Fit In**

In real production systems:

* **OAuth2** governs *authorization*
* **OIDC** governs *authentication* (userinfo, identity)
* **JWT** carries claims
* **Bearer** is how clients present tokens
* **PKCE** secures mobile/web public clients
* **JWKS** distributes public keys for verification
* **Token rotation** protects against replay

Modern systems:
AWS Cognito, Auth0, Okta, Azure AD, Keycloak → all use this architecture.

---

# 🧱 **10. Putting it All Together: Complete Flow**

```
User logs in
       ↓
Auth server verifies identity
       ↓
Auth server issues:
   - access JWT (short)
   - refresh token (long)
       ↓
Client calls API with:
   Authorization: Bearer <access-token>
       ↓
API verifies:
   - signature (public key)
   - expiration
   - issuer
   - audience
   - scopes/permissions
       ↓
If access token expired:
   Client uses refresh token
   to obtain new access token
       ↓
API processes request
```

This is the exact pattern used by:
Google Cloud APIs, AWS APIs, Microsoft Graph, Stripe, Plaid, Slack, Dropbox, GitHub, etc.

---

# 🎉 **In Summary**

**JWTs** = signed containers of identity + permissions
**Bearer tokens** = tokens that grant access if you possess them
**Auth server** = issues & rotates tokens
**API server** = validates tokens and permissions
**Refresh tokens** = safely renew access tokens
**Best practices** = short-lived access tokens, HTTPS, rotation, secure storage

**This is how “real-world” API authentication and authorization works in modern production environments.**

---

If you want, I can also explain:

🔹 JWT vs OAuth access token differences
🔹 How zero-trust architecture uses tokens
🔹 How to secure mobile & SPA clients
🔹 How backend-for-frontend (BFF) patterns protect tokens
🔹 Sample code for validating JWTs in Node/Go/Python/Swift

Just tell me!
