//
//  What are actors in Swift, and how do they help with concurrency?.swift
//  
//
//  Created by Apple on 27/08/25.
//

import Foundation
Great question! Actors are a key part of Swift's **concurrency model** introduced in **Swift 5.5 (iOS 15+)**. They’re designed to solve one of the **hardest problems in concurrent programming**: **data races**.

---

## ✅ What Are Actors in Swift?

### 📘 Definition:

An **actor** is a **reference type** (like a class) that protects its **mutable state** by **serializing access** to it. Only **one task at a time** can interact with its internal state.

In other words:

> "An actor is like a class with a built-in mutex."

---

### 🔧 Basic Syntax:

```swift
actor BankAccount {
    private var balance: Int = 0

    func deposit(_ amount: Int) {
        balance += amount
    }

    func getBalance() -> Int {
        return balance
    }
}
```

You use it like this:

```swift
let account = BankAccount()

Task {
    await account.deposit(100)
    let balance = await account.getBalance()
    print("Balance: \(balance)")
}
```

* The `await` keyword is required when calling actor methods **from outside the actor**.

---

## ✅ Why Use Actors?

### 🔐 They solve **data races**

A data race occurs when **two threads access shared data simultaneously**, and at least one of them modifies it. This leads to **undefined behavior**.

With actors:

* Swift ensures that **only one task at a time** accesses the actor’s state
* You don’t need to use locks, semaphores, or `DispatchQueue.sync`

---

## ✅ How Do Actors Help with Concurrency?

| Problem Without Actors      | How Actors Help                      |
| --------------------------- | ------------------------------------ |
| Shared mutable state        | Actors **encapsulate** state safely  |
| Data races                  | Automatically **serialized access**  |
| Complex thread-safety logic | You write **safe, normal code**      |
| Manual synchronization      | No need for `DispatchQueue` or locks |

---

## 🚦 Accessing Actor Properties & Methods

### ➤ From **outside** the actor:

You must use `await`:

```swift
await account.deposit(100)
```

### ➤ From **inside** the actor:

You can access properties directly:

```swift
func applyInterest() {
    balance = balance * 105 / 100
}
```

---

## ✅ Actors vs Classes

| Feature                   | `Class`            | `Actor`                   |
| ------------------------- | ------------------ | ------------------------- |
| Reference type            | ✅ Yes              | ✅ Yes                     |
| Thread-safe by default    | ❌ No               | ✅ Yes (automatically)     |
| Access control            | Manually via locks | Automatic via async/await |
| Inherits from other types | ✅ Yes              | ❌ No class inheritance    |

---

## ✅ Reentrancy and Actor Isolation

### 📌 Actor isolation:

Code inside an actor can access its own state **synchronously** — but **other code must `await` it**.

### ⚠️ Reentrancy:

If an actor method calls `await` inside its own function, **another task may start running** on that actor before the first one finishes.

**Example:**

```swift
actor Printer {
    var isPrinting = false

    func printDocument() async {
        isPrinting = true
        await Task.sleep(1_000_000_000) // 1 second
        isPrinting = false
    }
}
```

During the `await`, another task may access `isPrinting` — so don’t assume state remains unchanged across an `await` inside actors. You must account for this!

---

## 🧠 Summary

| Feature              | Description                                                                   |
| -------------------- | ----------------------------------------------------------------------------- |
| **Actors**           | Reference types that **protect their internal state** from concurrent access  |
| **Concurrency-safe** | Automatically serializes access — prevents data races                         |
| **Uses `await`**     | To access actor methods/properties from outside                               |
| **Best for**         | Managing shared state (counters, caches, models, services) in concurrent code |
| **Replaces**         | Complex locking, `DispatchQueue`, `NSLock`, etc. for many use cases           |

---

## 🚀 Example Use Case

```swift
actor DownloadManager {
    private var activeDownloads: [URL] = []

    func startDownload(from url: URL) {
        activeDownloads.append(url)
    }

    func getDownloads() -> [URL] {
        return activeDownloads
    }
}
```

In a multithreaded app, you can safely access this actor from multiple concurrent tasks — no crashes, no corruption.

---
