//
//  CheckedContinuation.swift
//  
//
//  Created by Apple on 26/10/25.
//

import Foundation

Ah, you’re asking about **“checked continuation” in iOS/Swift** — that’s part of Swift’s **concurrency system** (`async/await`) and **bridging callback-based APIs to async code**. Let me break it down clearly.

---

## 1️⃣ What is a Continuation?

In Swift concurrency:

* A **continuation** is a mechanism that lets you **pause an `async` function** and **resume it later** when a value or error is available.
* Think of it as a bridge between **callback-based APIs** and **Swift’s async/await**.

There are **two main types**:

1. `UnsafeContinuation` – no safety checks, lower overhead.
2. `CheckedContinuation` – safer, checks that the continuation is resumed exactly **once**.

---

## 2️⃣ Why `CheckedContinuation`?

* Ensures you **don’t accidentally resume twice**.
* Ensures you **don’t forget to resume**, preventing deadlocks.
* Helps catch mistakes at **runtime**.

Apple recommends using **`withCheckedContinuation`** instead of `withUnsafeContinuation` unless you have a performance-critical reason.

---

## 3️⃣ Syntax of `withCheckedContinuation`

```swift
func fetchData() async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
        someLegacyAPI { result, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else if let result = result {
                continuation.resume(returning: result)
            }
        }
    }
}
```

* `withCheckedContinuation` → for **non-throwing continuations**
* `withCheckedThrowingContinuation` → for **throwing continuations**
* `continuation.resume(returning:)` → resume successfully
* `continuation.resume(throwing:)` → resume with error

✅ Swift runtime will check that **resume is called exactly once**, otherwise you get a runtime warning.

---

## 4️⃣ Example: Converting a Callback API

Imagine a callback-based API:

```swift
func fetchUsername(completion: @escaping (String?, Error?) -> Void)
```

You can wrap it into `async` like this:

```swift
func fetchUsername() async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
        fetchUsername { username, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else if let username = username {
                continuation.resume(returning: username)
            }
        }
    }
}
```

Now you can use it naturally with async/await:

```swift
Task {
    do {
        let name = try await fetchUsername()
        print("Username:", name)
    } catch {
        print("Failed:", error)
    }
}
```

---

## 5️⃣ Key Notes About Checked Continuation

1. **Resume exactly once** — runtime warning if called multiple times.
2. **Never forget to resume** — otherwise the async function hangs.
3. **Checked** → provides runtime safety, logs helpful debug messages.
4. **Unsafe** → slightly faster, no runtime safety.

---

## 6️⃣ Real iOS Example

Bridging `URLSession` data task:

```swift
func fetchURL(_ url: URL) async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else if let data = data {
                continuation.resume(returning: data)
            }
        }.resume()
    }
}
```

✅ You can now `await fetchURL(url)` instead of dealing with callbacks.

---

### 🔑 Summary

| Feature  | CheckedContinuation                                           | UnsafeContinuation                                          |
| -------- | ------------------------------------------------------------- | ----------------------------------------------------------- |
| Safety   | Runtime checks resume called exactly once                     | No checks                                                   |
| Use Case | Bridging callback APIs safely                                 | Performance-critical or trusted APIs                        |
| Function | `withCheckedContinuation` / `withCheckedThrowingContinuation` | `withUnsafeContinuation` / `withUnsafeThrowingContinuation` |

---

If you want, I can make a **diagram showing how checked continuation pauses and resumes async functions** — it’s a great way to visualize how the runtime manages the continuation.

Do you want me to do that?

Perfect! Let’s visualize **how `CheckedContinuation` works** in Swift’s async/await system. I’ll explain it step by step with a simple diagram.

---

# 🖼️ Checked Continuation Flow

Imagine you have an async function that calls a callback-based API:

```swift
func fetchUsername() async throws -> String
```

Internally, using `withCheckedThrowingContinuation`, Swift handles it like this:

```
+--------------------------+
|  fetchUsername() async   |  <-- your async function starts
+--------------------------+
            |
            v
+--------------------------+
| withCheckedThrowingContinuation { cont } |
|  Creates a continuation object          |
+--------------------------+
            |
            v
   [async function pauses here]
            |
            v
+--------------------------+
| Legacy API callback      |  <-- e.g., fetchUsername { name, error in ... }
+--------------------------+
            |
            v
+--------------------------+
| cont.resume(returning:)  |
| OR cont.resume(throwing:)|
+--------------------------+
            |
            v
   [async function resumes execution]
            |
            v
+--------------------------+
| async function completes |
| returns result or throws |
+--------------------------+
```

---

## 🔑 Key Points from Diagram

1. **Continuation Object (`cont`)**

   * Acts like a “bookmark” for where to resume the async function.

2. **Async Function Pauses**

   * `fetchUsername()` is suspended until the continuation is resumed.

3. **Callback Eventually Calls Resume**

   * Once the result/error is available, you call `resume(returning:)` or `resume(throwing:)`.

4. **Checked Safety**

   * Swift ensures the continuation is **resumed exactly once**.
   * If you resume twice or forget to resume → runtime warning.

5. **Bridges Old APIs to async/await**

   * Makes callback-based APIs “play nicely” with Swift concurrency.

---

### ⚡ Example in SwiftUI Context

```swift
struct ContentView: View {
    @State private var username = ""
    
    var body: some View {
        Text(username.isEmpty ? "Loading..." : username)
            .task {
                do {
                    username = try await fetchUsername()
                } catch {
                    username = "Error loading"
                }
            }
    }
}
```

* The `task` modifier automatically handles the **suspension**.
* The continuation resumes when `fetchUsername` completes.

---

If you want, I can make a **fancier diagram showing “multiple async functions sharing a continuation”** so you can visualize how multiple paused tasks interact with continuations in Swift concurrency.

