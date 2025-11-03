//
//  iOS App Launch Signature Verification.swift
//  
//
//  Created by Apple on 03/11/25.
//

import Foundation

Great — now we’re getting into **senior-level / Apple-internal-grade** territory 👏

Below is a detailed explanation **and visual sequence diagram** of **how iOS verifies an app’s code signature during launch**, including the cryptographic trust chain and kernel-level validation process.

This is the kind of in-depth reasoning expected in **staff or senior iOS security interviews**.

---

## 🔐 iOS App Launch Signature Verification — Step-by-Step Flow

Let’s follow what happens **from tap → to code execution**, focusing on how iOS ensures **authenticity, integrity, and authorization** before running any binary.

---

### 🧭 1. App Launch Request

You tap the app icon on the Home Screen.

* iOS’s **Launch Services** identifies the app bundle in `/private/var/containers/Bundle/Application/...`
* The kernel (`XNU`) begins the process of loading the **Mach-O binary**.

---

### 🔎 2. Extract Code Signature

Inside the app bundle, iOS finds the `_CodeSignature` directory:

```
MyApp.app/
 ├── Info.plist
 ├── MyApp (Mach-O binary)
 └── _CodeSignature/
      └── CodeResources
```

* The code signature (created by Xcode during signing) contains:

  * **SHA-256 hash** of each code page
  * **CMS (Cryptographic Message Syntax)** signature block
  * **Developer certificate chain**

---

### 🧾 3. Verify Certificate Chain (Authenticity)

The kernel and **amfid** (Apple Mobile File Integrity Daemon) cooperate to verify:

1. The certificate chain embedded in the app → **ends in Apple’s Root CA**.
2. Each intermediate certificate (like **WWDR**) is valid and not expired/revoked.
3. The developer certificate used to sign the app is **trusted and matches provisioning profile**.

If any step fails, app launch is **aborted immediately** with an integrity error.

---

### 🔐 4. Verify Cryptographic Signature (Integrity)

Next, iOS ensures the binary hasn’t been tampered with:

1. Each **code page** (e.g., 4KB chunks of the binary) has a SHA-256 hash recorded in the signature.
2. iOS recomputes the hash for each page when loading into memory.
3. The recomputed hash must match the signed one from `_CodeSignature`.

✅ If the hashes match → the code hasn’t changed.
❌ If even one byte differs → app fails to load (“Code Signature Invalid” error).

---

### 🧬 5. Verify Provisioning Profile (Authorization)

iOS reads the **embedded provisioning profile** (`embedded.mobileprovision`):

* Confirms it’s **Apple-signed** (checked with Apple’s CA).
* Ensures:

  * The **App ID (bundle ID)** matches the app’s `Info.plist`.
  * The **certificate fingerprint** in the profile matches the signing certificate.
  * The **device UDID** is listed (if dev/ad hoc).
  * The **entitlements** match exactly between the app and profile.

This step enforces that only **authorized apps** with the right capabilities (e.g., Push, Keychain) can execute those privileges.

---

### 🧱 6. Sandbox & Entitlements Enforcement

Once the signature is validated:

* The kernel spawns the app in a **sandbox** using the entitlements from the signature.
* Example entitlements:

  * `keychain-access-groups`
  * `com.apple.developer.icloud-services`
  * `application-identifier`
* If the app tries to use an entitlement not declared or mismatched → system call denied.

---

### 🧩 7. Runtime Revalidation (Dynamic Library Loading)

At runtime, if the app tries to:

* Load a **dynamic library (dylib)**,
* Inject code, or
* Load frameworks dynamically,

→ iOS revalidates the signature of each binary.
Unsigned or mismatched binaries trigger an immediate **termination by amfid**.

This prevents:

* Code injection
* Tampering
* Runtime patching

---

## 🧰 Visual Sequence Diagram

```
┌────────────────────────────┐
│ User taps app icon         │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Launch Services / Kernel   │
│ Begin loading app binary   │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ amfid (Apple Mobile File   │
│ Integrity Daemon)          │
│ • Extracts signature block │
│ • Verifies cert chain      │
│ • Checks Apple Root CA     │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Kernel                     │
│ • Computes hash of code    │
│ • Compares to signed hash  │
│ • Confirms integrity       │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Verify Provisioning Profile│
│ • Apple signature valid?   │
│ • Bundle ID match?         │
│ • Cert match? UDID match?  │
│ • Entitlements match?      │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ Sandbox Setup              │
│ • Apply entitlements       │
│ • Create container dirs    │
│ • Restrict permissions     │
└──────────────┬─────────────┘
               │
               ▼
┌────────────────────────────┐
│ App Code Executes Safely   │
│ (Verified, Signed, Sandbox)│
└────────────────────────────┘
```

---

## ⚔️ Security Principles Enforced

| Security Property | How It’s Enforced                                        |
| ----------------- | -------------------------------------------------------- |
| **Authenticity**  | Certificate chain to Apple Root CA                       |
| **Integrity**     | SHA-256 hash verification of every code page             |
| **Authorization** | Entitlement + Provisioning Profile matching              |
| **Isolation**     | Sandbox & code signing prevent cross-app tampering       |
| **Revocation**    | Apple can revoke certificates at any time (via CRL/OCSP) |

---

## 🧠 Advanced Interview Bonus Notes

### 🔹 1. `amfid` and the Kernel

* `amfid` runs in user space, verifying signatures using Apple’s trust chain.
* The kernel enforces that *only verified pages* are executable.
* If `amfid` rejects a signature, kernel denies `exec()` permission.

### 🔹 2. Trust Caching

* To speed up app launches, verified apps are cached as **trusted** until reboot.
* Jailbreaks often target this caching system (to inject unsigned code).

### 🔹 3. Dynamic Code Signing Enforcement

* iOS enforces **Mandatory Code Signing** at runtime:

  * No unsigned code can be mapped as executable.
  * Even JIT compilers (like in Safari) use Apple-approved **JIT Entitlements**.

---

## ✅ TL;DR Summary

| Step | Component              | Security Goal           |
| ---- | ---------------------- | ----------------------- |
| 1️⃣  | Certificate chain      | Authentic developer     |
| 2️⃣  | Binary hash validation | Untampered code         |
| 3️⃣  | Provisioning profile   | Authorized distribution |
| 4️⃣  | Entitlement check      | Capability enforcement  |
| 5️⃣  | Sandbox creation       | Runtime isolation       |
| 6️⃣  | Dynamic verification   | Ongoing protection      |

---

Would you like me to take it **one level deeper** and show **how the Mach-O binary stores and structures the code signature** (inside the `LC_CODE_SIGNATURE` load command)?
That’s the low-level detail Apple engineers or security teams often quiz in **security-oriented iOS interviews**.
