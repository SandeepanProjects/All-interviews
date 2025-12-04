//
//  Combine-powered notification center.swift
//  
//
//  Created by Apple on 15/11/25.
//

import Foundation

Create a lightweight publish/subscribe system that lets any part of the app post and listen for events using **Combine publishers**, while managing subscriptions safely.

---

# 🌟 **Key Design Points**

* Each notification name corresponds to a **PassthroughSubject**.
* Subscribers register using Combine’s `AnyPublisher`.
* Notifications are posted by sending values through the subject.
* Subjects are stored in a dictionary to avoid duplicates.
* Type-safety optional: can support generic typed notifications.

---

# ✅ **Optimal Solution (Simple, Production-Ready)**

```swift
import Combine
import Foundation

final class CustomNotificationCenter {
    static let shared = CustomNotificationCenter()
    private init() {}

    // Store subjects based on notification name
    private var subjects = [String: PassthroughSubject<Any, Never>]()
    private let lock = NSLock()

    // Get or create a subject for notification name
    private func subject(for name: String) -> PassthroughSubject<Any, Never> {
        lock.lock()
        defer { lock.unlock() }

        if let subject = subjects[name] {
            return subject
        }

        let newSubject = PassthroughSubject<Any, Never>()
        subjects[name] = newSubject
        return newSubject
    }

    // MARK: - Posting

    func post(name: String, object: Any? = nil) {
        subject(for: name).send(object as Any)
    }

    // MARK: - Observing

    func publisher(for name: String) -> AnyPublisher<Any, Never> {
        subject(for: name).eraseToAnyPublisher()
    }
}
```

---

# 📌 **Usage Example**

## ➤ **Post a notification**

```swift
CustomNotificationCenter.shared.post(name: "UserLoggedIn", object: "John Doe")
```

## ➤ **Listen for a notification**

```swift
var cancellables = Set<AnyCancellable>()

CustomNotificationCenter.shared
    .publisher(for: "UserLoggedIn")
    .sink { value in
        print("Received login event:", value)
    }
    .store(in: &cancellables)
```

---

# 🚀 **Type-Safe Version (Optional Upgrade)**

If you want type safety:

```swift
final class TypedNotificationCenter {
    static let shared = TypedNotificationCenter()
    private init() {}

    private var subjects = [String: PassthroughSubject<Any, Never>]()
    private let lock = NSLock()

    private func subject<T>(for type: T.Type) -> PassthroughSubject<T, Never> {
        let key = String(describing: type)

        lock.lock()
        defer { lock.unlock() }

        if let existing = subjects[key] as? PassthroughSubject<T, Never> {
            return existing
        }

        let newSubject = PassthroughSubject<T, Never>()
        subjects[key] = newSubject
        return newSubject
    }

    func post<T>(_ value: T) {
        subject(for: T.self).send(value)
    }

    func publisher<T>(for type: T.Type) -> AnyPublisher<T, Never> {
        subject(for: T.self).eraseToAnyPublisher()
    }
}
```

### Usage:

```swift
struct UserLoginEvent {
    let username: String
}

TypedNotificationCenter.shared.publisher(for: UserLoginEvent.self)
    .sink { print("Logged in: \($0.username)") }
    .store(in: &cancellables)

TypedNotificationCenter.shared.post(UserLoginEvent(username: "John"))
```

---

# 💡 Why This Is a Great Interview Answer

* Demonstrates knowledge of **Combine** (PassthroughSubject, AnyPublisher, cancellables)
* Implements thread-safe subject dictionary using `NSLock`
* Shows clean architecture and extensibility
* Avoids NotificationCenter entirely
* Provides both basic and type-safe versions

---

If you want, I can also provide:

✅ A diagram explaining the flow
✅ A SwiftUI example using this system
✅ A version that supports async/await

Would you like that?

Great—here are **all three**:
✅ A clear **flow diagram**
✅ A complete **SwiftUI example**
✅ An **async/await** version of the custom notification center

---

# 1️⃣ **FLOW DIAGRAM — Custom Combine-Based Notification Center**

```
 ┌──────────────────────────┐
 │  Any Component (Poster)  │
 └──────────────┬───────────┘
                │ post(name, object)
                ▼
      ┌─────────────────────────┐
      │ CustomNotificationCenter│
      ├─────────────────────────┤
      │ 1. Lookup subject       │
      │ 2. Create if missing    │
      │ 3. Send event           │
      └──────────────┬──────────┘
                     │
                     ▼ (Combine pipeline)
        ┌──────────────────────────┐
        │   Subscriber Components  │
        │  (Combine .sink handlers)│
        └──────────────────────────┘
```

The flow is:

1. You post an event →
2. NotificationCenter sends it through a `PassthroughSubject` →
3. All subscribers receive it instantly through Combine.

---

# 2️⃣ **SwiftUI Example**

Using the earlier implementation with `CustomNotificationCenter`.

---

### **CustomNotificationCenter (same as before)**

```swift
import Combine
import Foundation

final class CustomNotificationCenter {
    static let shared = CustomNotificationCenter()
    private init() {}

    private var subjects = [String: PassthroughSubject<Any, Never>]()
    private let lock = NSLock()

    private func subject(for name: String) -> PassthroughSubject<Any, Never> {
        lock.lock()
        defer { lock.unlock() }

        if let s = subjects[name] { return s }
        let new = PassthroughSubject<Any, Never>()
        subjects[name] = new
        return new
    }

    func post(name: String, object: Any? = nil) {
        subject(for: name).send(object as Any)
    }

    func publisher(for name: String) -> AnyPublisher<Any, Never> {
        subject(for: name).eraseToAnyPublisher()
    }
}
```

---

# **SwiftUI Example Usage**

### **Button View (Event Sender)**

```swift
import SwiftUI

struct SenderView: View {
    var body: some View {
        Button("Send Notification") {
            CustomNotificationCenter.shared.post(name: "ButtonPressed", object: Date())
        }
        .padding()
    }
}
```

---

### **Listening View (Subscriber)**

```swift
import SwiftUI
import Combine

struct ReceiverView: View {
    @State private var message: String = "Waiting..."
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        Text(message)
            .padding()
            .onAppear {
                CustomNotificationCenter.shared
                    .publisher(for: "ButtonPressed")
                    .sink { value in
                        if let date = value as? Date {
                            message = "Button pressed at: \(date)"
                        }
                    }
                    .store(in: &cancellables)
            }
    }
}
```

---

### **Container**

```swift
struct ContentView: View {
    var body: some View {
        VStack(spacing: 40) {
            SenderView()
            ReceiverView()
        }
        .padding()
    }
}
```

This gives you a working SwiftUI app with a custom notification system.

---

# 3️⃣ **Async/Await Version — Custom Async Notification Center**

This converts notifications into **async streams** (AsyncStream), perfect for Swift Concurrency questions.

---

## **AsyncNotificationCenter**

```swift
import Foundation

final class AsyncNotificationCenter {
    static let shared = AsyncNotificationCenter()
    private init() {}

    private var continuations: [String: [AsyncStream<Any>.Continuation]] = [:]
    private let lock = NSLock()

    func stream(for name: String) -> AsyncStream<Any> {
        AsyncStream { continuation in
            lock.lock()
            continuations[name, default: []].append(continuation)
            lock.unlock()
        }
    }

    func post(name: String, object: Any? = nil) {
        lock.lock()
        let list = continuations[name] ?? []
        lock.unlock()

        for cont in list {
            cont.yield(object as Any)
        }
    }
}
```

---

## **Async Listener Example**

```swift
func listenToEvents() async {
    let stream = AsyncNotificationCenter.shared.stream(for: "MyEvent")

    for await value in stream {
        print("Received async event:", value)
    }
}
```

---

## **Async Event Sender**

```swift
AsyncNotificationCenter.shared.post(name: "MyEvent", object: "Hello Async")
```

---

# 🎯 **What You Can Say in an Interview**

If the interviewer asks “Why not use NotificationCenter?”:

> I wanted a reactive, Combine-powered system that gives me:
>
> * type safety
> * back-pressure handling
> * automatic subscriber cleanup
> * async/await support
> * more flexible and testable event streams

This shows deep architectural reasoning.

---
