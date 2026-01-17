//
//  Security Principles (Banking Apps).swift
//  
//
//  Created by Apple on 17/01/26.
//

import Foundation

Below is a **banking-grade explanation** covering **both**:

1️⃣ **Backend DB schema for tokens (with rotation & reuse detection)**
2️⃣ **Transaction signing (how banks approve payments securely)**

This is **real fintech architecture**, not theory.

---

# 1️⃣ Backend Database Schema for Tokens 🔐

In banking apps, **tokens are never “just JWTs”**.
You **must track refresh tokens server-side**.

---

## 🎯 Goals of the Token Schema

The DB must allow you to:

* Rotate refresh tokens
* Detect token reuse (theft)
* Revoke sessions per device
* Force logout on compromise
* Support audits (banking requirement)

---

## 🧱 Recommended Tables

### 🔹 `users`

```sql
users (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE,
  password_hash TEXT,
  mfa_enabled BOOLEAN,
  created_at TIMESTAMP
)
```

---

### 🔹 `devices`

Tracks each logged-in device

```sql
devices (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  device_fingerprint TEXT,
  os TEXT,
  model TEXT,
  last_seen TIMESTAMP,
  trusted BOOLEAN
)
```

---

### 🔹 `refresh_tokens` (CRITICAL TABLE)

```sql
refresh_tokens (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  device_id UUID REFERENCES devices(id),

  token_hash TEXT UNIQUE,        -- never store raw token
  expires_at TIMESTAMP,

  revoked_at TIMESTAMP NULL,
  replaced_by UUID NULL,         -- next refresh token

  created_at TIMESTAMP,
  created_ip TEXT,
  user_agent TEXT
)
```

---

## 🔐 Why Hash Refresh Tokens?

❌ Never store raw refresh tokens
✅ Store `SHA-256(token)`

Just like passwords.

```text
If DB leaks → attacker still can't use tokens
```

---

## 🔁 Refresh Token Rotation Logic

### Refresh request

```text
Client → refresh_token = RT1
```

### Server logic

```pseudo
token = find(token_hash)

if token.revoked_at != null:
    revoke_all_user_tokens()
    alert_security()
    deny()

new_token = generate()

token.revoked_at = now
token.replaced_by = new_token.id

save(new_token)
```

---

## 🚨 Token Reuse Detection (VERY IMPORTANT)

If **RT1 is used again** after rotation:

```text
→ Token theft detected
→ Revoke all tokens for that user/device
→ Force logout on all devices
→ Optional: lock account
```

This is **mandatory for banking**.

---

## ⏳ Token Cleanup Job

```sql
DELETE FROM refresh_tokens
WHERE expires_at < NOW()
```

Run daily.

---

# 2️⃣ Transaction Signing (Banking Critical Feature)

## ❓ What Is Transaction Signing?

> A **second cryptographic approval** for sensitive actions
> (money transfer, beneficiary add, password change)

Even if:

* Access token is stolen
* Session is hijacked

➡ **Money still cannot move**

---

## 🧠 Why Tokens Alone Are NOT Enough

Tokens prove:
✅ “User is authenticated”

They do **NOT** prove:
❌ “User approved THIS transaction”

---

## 💣 Attack Scenario (Without Signing)

```text
Malware steals access token
→ Sends transfer request
→ Money gone
```

❌ Tokens alone are insufficient.

---

# 🔐 How Transaction Signing Works

### 🔹 Core Idea

Every transaction is:

* Canonicalized
* Signed
* Approved by the user
* Verified by backend

---

## 🧩 Transaction Signing Flow (High Level)

```text
1. App requests transaction challenge
2. Backend returns challenge (nonce)
3. App shows transaction details
4. User confirms (Face ID / PIN)
5. App signs transaction
6. Backend verifies signature
7. Transaction executes
```

---

## 📱 iOS Side (SwiftUI Concept)

### Transaction payload

```json
{
  "amount": 1000,
  "currency": "USD",
  "to_account": "987654321",
  "nonce": "abc123"
}
```

### User approval

* Face ID / Touch ID
* Secure Enclave key

### Signed result

```json
{
  "payload": "...",
  "signature": "MEUCIQD..."
}
```

---

## 🔐 Signing Options (From Weak → Strong)

| Method             | Used by Banks |
| ------------------ | ------------- |
| SMS OTP            | ❌ Legacy      |
| App PIN            | ⚠️ Weak       |
| Biometrics         | ✅             |
| Secure Enclave Key | ✅✅ BEST       |
| Hardware Token     | ✅             |

---

## 🧠 Secure Enclave Signing (Best Practice)

* Private key **never leaves device**
* Protected by Face ID
* Non-exportable

```text
iOS Secure Enclave
  └── Private Key 🔒
```

---

## 🔁 Backend Verification Flow

```pseudo
verify_signature(payload, signature, public_key)

if invalid:
    reject()

if nonce already used:
    reject()

execute_transaction()
```

---

## 🧱 Backend Tables for Transactions

### 🔹 `transaction_challenges`

```sql
transaction_challenges (
  id UUID PRIMARY KEY,
  user_id UUID,
  nonce TEXT UNIQUE,
  expires_at TIMESTAMP,
  used BOOLEAN
)
```

---

### 🔹 `transactions`

```sql
transactions (
  id UUID PRIMARY KEY,
  user_id UUID,
  from_account TEXT,
  to_account TEXT,
  amount DECIMAL,
  currency TEXT,
  status TEXT,
  signed_at TIMESTAMP,
  executed_at TIMESTAMP
)
```

---

## 🚨 Anti-Replay Protection

* Each transaction has:

  * Nonce
  * Expiration
  * One-time use

```text
Replay = rejected
```

---

# 🧨 What Happens If Attacker Steals Tokens?

| Attack              | Result    |
| ------------------- | --------- |
| API read            | Limited   |
| Refresh token reuse | Logout    |
| Transfer money      | ❌ BLOCKED |
| Replay transaction  | ❌ BLOCKED |

---

# 🏦 Banking Security Golden Rule

> **Authentication ≠ Authorization ≠ Transaction Approval**

All three must be **independent**.

---

# ✅ Final Summary

### Token Security

✔ Refresh tokens hashed
✔ Rotation enabled
✔ Reuse detection
✔ Device binding

### Transaction Security

✔ User-visible approval
✔ Cryptographic signing
✔ Secure Enclave
✔ Nonce + expiry

---

## Want Next?

I can:

* Show **Secure Enclave Swift code**
* Draw a **sequence diagram**
* Explain **PSD2 / Strong Customer Authentication**
* Provide **API contract examples**

Just tell me 👍


Below is a **banking-grade, end-to-end design** showing **how a secure backend and an iOS SwiftUI app should work together**.

I’ll explain:

1. **Architecture**
2. **Security principles (banking-level)**
3. **Step-by-step auth flow**
4. **API call flow**
5. **Threat protection**
6. **Text-based flow diagram**

This matches **real fintech / banking implementations**.

---

# 🏦 1️⃣ Core Security Principles (Banking Apps)

A banking app must assume:

* The **mobile app is untrusted**
* The **network is hostile**
* Tokens **will eventually leak**

So we design for:
✅ Zero trust
✅ Short-lived credentials
✅ Strong device binding
✅ Continuous validation

---

# 🧱 2️⃣ High-Level Architecture

```text
┌────────────┐
│ SwiftUI App│
│ (iOS)      │
└─────┬──────┘
      │ HTTPS + TLS
      ▼
┌────────────┐
│ API Gateway│
│ (WAF, Rate │
│ Limiting)  │
└─────┬──────┘
      │
      ▼
┌────────────┐        ┌────────────┐
│ Auth Server│◄──────►│ Token Store│
│ (OAuth2)   │        │ (DB/Redis) │
└─────┬──────┘        └────────────┘
      │
      ▼
┌────────────┐
│ Core Bank  │
│ Services   │
│ (Accounts,│
│ Payments) │
└────────────┘
```

---

# 🔐 3️⃣ Authentication Strategy (Mandatory)

**OAuth 2.1 + PKCE**
**Rotating Refresh Tokens**
**JWT Access Tokens (5–10 min)**

### Why PKCE?

* iOS apps **cannot keep secrets**
* Prevents auth code interception

---

# 🔁 4️⃣ Full Login Flow (Banking Grade)

### Step-by-step

```text
1. App generates PKCE verifier + challenge
2. App opens secure login (ASWebAuthenticationSession)
3. User authenticates (password + MFA)
4. Auth Server returns authorization code
5. App exchanges code + verifier
6. Server returns:
   - Access Token (short-lived)
   - Refresh Token (rotating)
7. App stores refresh token in Keychain
```

---

# 📱 iOS Login Flow Diagram

```text
SwiftUI App
   │
   │ PKCE Auth Request
   ▼
Auth Server (Login + MFA)
   │
   │ Authorization Code
   ▼
SwiftUI App
   │
   │ Code + PKCE Verifier
   ▼
Auth Server
   │
   │ Access + Refresh Token
   ▼
SwiftUI App (Keychain)
```

---

# 🔄 5️⃣ API Request Flow (Normal Operation)

```text
SwiftUI View
   │
   │ API Request
   ▼
API Client
   │ Authorization: Bearer <AccessToken>
   ▼
API Gateway
   │
   │ Validate JWT
   ▼
Banking Service
   │
   │ Response
   ▼
SwiftUI App
```

---

# ⏳ 6️⃣ Token Expiry & Rotation Flow

```text
Access Token expires
   │
   ▼
SwiftUI App
   │
   │ Refresh Token
   ▼
Auth Server
   │
   │ Rotate refresh token
   │ (invalidate old)
   ▼
SwiftUI App
   │
   │ Store new tokens
   ▼
Retry original API call
```

🚨 If refresh token reuse detected → **global logout**

---

# 🔒 7️⃣ Banking-Specific Hardening

### ✅ Device Binding

* Device ID signed by backend
* Refresh token tied to device
* Prevents token reuse on another phone

```text
Refresh Token + Device ID
```

---

### ✅ Biometric Protection (iOS)

* Keychain item protected by Face ID / Touch ID
* Required for:

  * Login
  * Payments
  * Viewing sensitive data

---

### ✅ Transaction-Level Authorization

**Never rely only on access tokens**

For payments:

* Re-authenticate (biometric or OTP)
* Use **transaction signing**

---

# 🧨 8️⃣ Threat Protection Matrix

| Threat              | Protection              |
| ------------------- | ----------------------- |
| Token theft         | Short TTL + rotation    |
| Replay attack       | Refresh reuse detection |
| MITM                | TLS + ATS               |
| Reverse engineering | No secrets in app       |
| Brute force         | Rate limiting           |
| Device theft        | Biometrics + Keychain   |
| API abuse           | API Gateway + WAF       |

---

# 🧩 9️⃣ Backend Validation Rules (Critical)

Every request:

* Validate JWT signature
* Check `exp`, `aud`, `iss`
* Validate scopes (read vs transfer)
* Verify device binding
* Apply rate limits

---

# 🧠 10️⃣ SwiftUI App Responsibilities

```text
✔ Secure storage (Keychain)
✔ Token refresh logic
✔ Biometric gating
✔ Logout on auth failure
✔ No business logic trust
```

---

# 🧾 11️⃣ Recommended Token Lifetimes (Banking)

| Token              | Lifetime   |
| ------------------ | ---------- |
| Access Token       | 5 minutes  |
| Refresh Token      | 7–14 days  |
| Authorization Code | 30 seconds |

---

# 🧪 12️⃣ Common Banking Mistakes ❌

* Long-lived access tokens
* No token rotation
* No MFA
* Storing tokens in UserDefaults
* Trusting device without verification
* Missing transaction re-auth

---

# 🏁 Final Secure Flow Summary

```text
SwiftUI App (Untrusted)
   ↓
OAuth2 + PKCE + MFA
   ↓
Short-lived JWT Access Token
   ↓
Rotating Refresh Token (Keychain)
   ↓
API Gateway (Zero Trust)
   ↓
Banking Services
```

---

## Want Next?

I can:

* Draw this as a **visual sequence diagram**
* Show **SwiftUI + Face ID Keychain code**
* Provide **backend DB schema for tokens**
* Explain **transaction signing**

Just tell me 👍

