//
//  concurrency bug resolved.swift
//  
//
//  Created by Apple on 20/08/25.
//

import Foundation

Sure — here’s a **realistic example of a concurrency bug** often encountered in iOS development, along with how it was identified and fixed.

---

## 🐛 **The Bug: Crashing When Saving User Preferences**

### **Scenario:**

In an iOS app, user preferences were being saved to `UserDefaults` from multiple parts of the app — sometimes from background threads, other times from the main thread.

```swift
func updateSetting(_ key: String, value: Any) {
    UserDefaults.standard.set(value, forKey: key)
}
```

### **Symptoms:**

* Occasional **crashes** or **corrupt data** in `UserDefaults`.
* Hard to reproduce, but logs showed issues during simultaneous writes.

---

## 🔍 **Diagnosis: Race Condition**

* `UserDefaults` is **not guaranteed to be thread-safe for concurrent writes**.
* Multiple threads were calling `.set(_:forKey:)` simultaneously.
* This led to race conditions and crashes in low-level storage operations.

---

## ✅ **Solution: Use a Serial Queue to Synchronize Access**

```swift
let userDefaultsQueue = DispatchQueue(label: "com.myapp.userDefaultsQueue")

func updateSetting(_ key: String, value: Any) {
    userDefaultsQueue.async {
        UserDefaults.standard.set(value, forKey: key)
    }
}
```

### ✅ Why This Works:

* All access to `UserDefaults` is funneled through a **single serial queue**.
* Prevents simultaneous writes and **eliminates race conditions**.
* Easy to maintain and integrate across the app.

---

## 🔧 Alternative Fix (if using Swift Concurrency): Use an Actor

```swift
actor PreferencesStore {
    func set(_ value: Any, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
```

Then use:

```swift
let store = PreferencesStore()
await store.set("dark", forKey: "theme")
```

---

## 🧠 Lessons Learned

* Don’t assume system APIs are thread-safe — **check documentation**.
* Race conditions often show up **intermittently**, so use tools like:

  * Xcode’s Thread Sanitizer
  * Logging and symbolicated crash reports
* Synchronization is not just for performance — it’s critical for correctness.

---
