//
//  CombineNotificationCenter.swift
//  
//
//  Created by Apple on 29/01/26.
//

import Foundation

Perfect 👍 — Combine is actually *the cleanest* way to do this in modern SwiftUI.

We’ll rewrite your **custom Notification Center** using **Combine**, keeping:

* `addObserver`
* `post`
* `remove`
* **Type safety**
* **SwiftUI-friendly API**

Think of this as a **typed event bus powered by Combine**.

---

## 1️⃣ Core idea (Combine version)

* Each event type gets its own `PassthroughSubject`
* Observers subscribe using `AnyCancellable`
* Removal = cancel the subscription

No manual token management needed ✨

---

## 2️⃣ Define Event Protocol

Same as before:

```swift
protocol AppEvent {}
```

Example events:

```swift
struct UserLoggedInEvent: AppEvent {
    let userId: String
}

struct LogoutEvent: AppEvent {}
```

---

## 3️⃣ Combine-based Notification Center

```swift
import Combine

final class CombineNotificationCenter {

    static let shared = CombineNotificationCenter()
    private init() {}

    private var subjects: [ObjectIdentifier: Any] = [:]
    private let lock = NSLock()

    // MARK: - Get or Create Subject
    private func subject<T: AppEvent>(for type: T.Type) -> PassthroughSubject<T, Never> {
        lock.lock()
        defer { lock.unlock() }

        let key = ObjectIdentifier(type)

        if let existing = subjects[key] as? PassthroughSubject<T, Never> {
            return existing
        }

        let newSubject = PassthroughSubject<T, Never>()
        subjects[key] = newSubject
        return newSubject
    }

    // MARK: - Add Observer
    func addObserver<T: AppEvent>(
        for type: T.Type,
        receiveOn queue: DispatchQueue = .main,
        handler: @escaping (T) -> Void
    ) -> AnyCancellable {

        subject(for: type)
            .receive(on: queue)
            .sink(receiveValue: handler)
    }

    // MARK: - Post
    func post<T: AppEvent>(_ event: T) {
        subject(for: T.self).send(event)
    }
}
```

### ✅ What Combine gives us for free

* Thread safety via `receive(on:)`
* Automatic cleanup via `AnyCancellable`
* Backpressure control (if needed)
* Perfect SwiftUI integration

---

## 4️⃣ Using it in SwiftUI (ViewModel)

```swift
final class HomeViewModel: ObservableObject {
    @Published var message = "Waiting..."

    private var cancellables = Set<AnyCancellable>()

    init() {
        CombineNotificationCenter.shared
            .addObserver(for: UserLoggedInEvent.self) { [weak self] event in
                self?.message = "User logged in: \(event.userId)"
            }
            .store(in: &cancellables)
    }
}
```

### ❌ No deinit cleanup needed

Combine cancels automatically when the ViewModel deallocates.

---

## 5️⃣ SwiftUI View

```swift
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text(viewModel.message)

            Button("Login") {
                CombineNotificationCenter.shared.post(
                    UserLoggedInEvent(userId: "12345")
                )
            }
        }
        .padding()
    }
}
```

---

## 6️⃣ Removing Observers (Explicitly)

If you *do* want manual removal:

```swift
var loginCancellable: AnyCancellable?

loginCancellable = CombineNotificationCenter.shared
    .addObserver(for: UserLoggedInEvent.self) { event in
        print(event.userId)
    }

// Later
loginCancellable?.cancel()
```

That’s your `removeObserver`.

---

## 7️⃣ Combine vs Custom Non-Combine Version

| Feature             | Custom (Closure) | Combine          |
| ------------------- | ---------------- | ---------------- |
| Type Safety         | ✅                | ✅                |
| Thread Safety       | Manual           | Built-in         |
| Observer Removal    | Manual Token     | `AnyCancellable` |
| SwiftUI Integration | ⚠️               | ✅                |
| Memory Safety       | Needs care       | ✅                |

---

## 8️⃣ When to use this pattern

Use **CombineNotificationCenter** when:

* Multiple features/modules need loose communication
* You don’t want singletons holding references to ViewModels
* You want **clean MVVM + SwiftUI**

❌ Don’t use it for:

* Simple parent → child state passing
* Tight feature coupling (use bindings)

---

## 9️⃣ Interview one-liner 🧠

> “I prefer a Combine-based event bus over NotificationCenter because it’s type-safe, cancellable, SwiftUI-friendly, and avoids string-based notifications.”

---

If you want next:

* 🔄 **AsyncStream version (Swift Concurrency)**
* 🧪 **Unit testing this event bus**
* 🧵 **Background thread handling**
* ⚖️ **EnvironmentObject vs Combine vs NotificationCenter**

Just tell me 😄
