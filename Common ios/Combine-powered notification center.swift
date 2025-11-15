//
//  Combine-powered notification center.swift
//  
//
//  Created by Apple on 15/11/25.
//

import Foundation

Below is a clean, modern way to **build your own notification center using Combine** — *without using `NotificationCenter`*.
You’ll create a simple, type-safe **event bus** (publisher hub) that lets different parts of your app send and listen to events.

---

# ✅ **Goal**

Build something like:

```swift
EventBus.shared.send(.userLoggedIn)
EventBus.shared.publisher(for: .userLoggedIn)
    .sink { ... }
```

— all completely powered by **Combine**, no `NotificationCenter`.

---

# 🧱 **Step 1: Define your events**

Use an enum or multiple structs—your choice.
Enums are simple:

```swift
enum AppEvent {
    case userLoggedIn
    case userLoggedOut
    case itemAddedToCart(id: Int)
}
```

---

# 🛠️ **Step 2: Create an event bus using a Combine subject**

You need a single place to publish and observe events.

```swift
import Combine

final class EventBus {
    static let shared = EventBus()

    private let subject = PassthroughSubject<AppEvent, Never>()

    private init() {}

    /// Publish event
    func send(_ event: AppEvent) {
        subject.send(event)
    }

    /// Listen to events
    func publisher(for event: AppEvent) -> AnyPublisher<AppEvent, Never> {
        subject
            .filter { $0.matches(event) }
            .eraseToAnyPublisher()
    }
}
```

Since enum cases with associated values cannot be compared directly, add a helper:

```swift
extension AppEvent {
    func matches(_ other: AppEvent) -> Bool {
        switch (self, other) {
        case (.userLoggedIn, .userLoggedIn),
             (.userLoggedOut, .userLoggedOut):
            return true
        case (.itemAddedToCart, .itemAddedToCart):
            return true
        default:
            return false
        }
    }
}
```

---

# 📡 **Step 3: Send an event**

Anywhere in your app:

```swift
EventBus.shared.send(.userLoggedIn)
EventBus.shared.send(.itemAddedToCart(id: 42))
```

---

# 🎧 **Step 4: Subscribe to events**

In a view model or controller:

```swift
var cancellables = Set<AnyCancellable>()

EventBus.shared.publisher(for: .userLoggedIn)
    .sink { _ in
        print("User logged in!")
    }
    .store(in: &cancellables)

EventBus.shared.publisher(for: .itemAddedToCart(id: 0))
    .sink { event in
        if case .itemAddedToCart(let id) = event {
            print("Item added with ID \(id)")
        }
    }
    .store(in: &cancellables)
```

---

# ⭐ **Even Better: Type-Safe Event Bus Using Generics**

If you want *fully decoupled* and type-safe notifications, use generics:

```swift
final class EventBus {
    static let shared = EventBus()

    private init() {}

    private var subjects = [ObjectIdentifier: Any]()

    private func subject<T>(for type: T.Type) -> PassthroughSubject<T, Never> {
        let id = ObjectIdentifier(type)
        if let subject = subjects[id] as? PassthroughSubject<T, Never> {
            return subject
        }
        let new = PassthroughSubject<T, Never>()
        subjects[id] = new
        return new
    }

    func send<T>(_ event: T) {
        subject(for: T.self).send(event)
    }

    func publisher<T>(for type: T.Type) -> AnyPublisher<T, Never> {
        subject(for: T.self).eraseToAnyPublisher()
    }
}
```

### Send event:

```swift
struct UserLoggedIn { let id: Int }

EventBus.shared.send(UserLoggedIn(id: 5))
```

### Receive event:

```swift
EventBus.shared.publisher(for: UserLoggedIn.self)
    .sink { event in print(event.id) }
```

Super clean. Zero enums. Fully type-safe.

---

# 🎯 Summary

You now have a **fully custom, Combine-powered notification center** that:

* doesn’t use `NotificationCenter`
* is type-safe
* supports enums *or* generic events
* is scalable for real apps

---

If you want, I can also provide:

✅ A SwiftUI-friendly version
✅ A multi-channel event bus (per feature)
✅ A thread-safe version
✅ A version using `CurrentValueSubject` for state broadcasting

Just tell me!

Great — here are **all versions** of a fully custom Combine-based notification system, each serving different use cases.
You can mix + match depending on your app architecture (MVC, MVVM, SwiftUI, modular apps).
                    
                    ---
                    
# 🚀 **1. Basic Enum-Based EventBus**
                    
(Simple, lightweight, NotificationCenter replacement)
                    
### **Event Enum**
                    
```swift
enum AppEvent {
case userLoggedIn
case userLoggedOut
case itemAddedToCart(id: Int)
}
```

### **EventBus Implementation**

```swift
import Combine

final class EventBus {
    static let shared = EventBus()
    
    private let subject = PassthroughSubject<AppEvent, Never>()
    private init() {}
    
    func send(_ event: AppEvent) {
        subject.send(event)
    }
    
    func publisher(for event: AppEvent) -> AnyPublisher<AppEvent, Never> {
        subject
            .filter { $0.matches(event) }
            .eraseToAnyPublisher()
    }
}
```

### Matcher Logic

```swift
extension AppEvent {
    func matches(_ other: AppEvent) -> Bool {
        switch (self, other) {
        case (.userLoggedIn, .userLoggedIn),
            (.userLoggedOut, .userLoggedOut):
            return true
        case (.itemAddedToCart, .itemAddedToCart):
            return true
        default:
            return false
        }
    }
}
```

---

# 🧬 **2. Fully Type-Safe Generic EventBus** (Best for large apps)

Each event type becomes a struct/class. No enums.

### EventBus

```swift
import Combine

final class EventBus {
    static let shared = EventBus()
    private init() {}
    
    private var subjects = [ObjectIdentifier: Any]()
    
    private func subject<T>(for type: T.Type) -> PassthroughSubject<T, Never> {
        let id = ObjectIdentifier(type)
        if let s = subjects[id] as? PassthroughSubject<T, Never> {
            return s
        }
        let new = PassthroughSubject<T, Never>()
        subjects[id] = new
        return new
    }
    
    func send<T>(_ event: T) {
        subject(for: T.self).send(event)
    }
    
    func publisher<T>(for type: T.Type) -> AnyPublisher<T, Never> {
        subject(for: T.self).eraseToAnyPublisher()
    }
}
```

### Example Events

```swift
struct UserLoggedIn { let id: Int }
struct CartUpdated { let items: [Int] }
```

### Sending

```swift
EventBus.shared.send(UserLoggedIn(id: 42))
```

### Subscribing

```swift
EventBus.shared.publisher(for: UserLoggedIn.self)
    .sink { print("User ID:", $0.id) }
    .store(in: &cancellables)
```

---

# 📱 **3. SwiftUI-Friendly EventBus (ObservableObject wrapper)**

### Global Notification Manager

```swift
class EventCenter: ObservableObject {
    static let shared = EventCenter()
    private init() {}
    
    @Published var lastEvent: AppEvent?
    
    func send(_ event: AppEvent) {
        lastEvent = event
    }
}
```

### SwiftUI View Listening

```swift
struct HomeView: View {
    @ObservedObject var events = EventCenter.shared
    
    var body: some View {
        Text("Home Screen")
            .onChange(of: events.lastEvent) { event in
                if event == .userLoggedIn {
                    print("SwiftUI reacting to login event")
                }
            }
    }
}
```

---

# 🧵 **4. Thread-Safe EventBus**

Combine subjects are not automatically thread-safe, so here’s a version protected by a lock.

```swift
import Combine

final class ThreadSafeEventBus {
    static let shared = ThreadSafeEventBus()
    private init() {}
    
    private var lock = NSLock()
    private var subjects = [ObjectIdentifier: Any]()
    
    private func subject<T>(for type: T.Type) -> PassthroughSubject<T, Never> {
        lock.lock()
        defer { lock.unlock() }
        
        let id = ObjectIdentifier(type)
        if let s = subjects[id] as? PassthroughSubject<T, Never> {
            return s
        }
        
        let new = PassthroughSubject<T, Never>()
        subjects[id] = new
        return new
    }
    
    func send<T>(_ event: T) {
        let s = subject(for: T.self)
        DispatchQueue.global().async { s.send(event) } // safe dispatch
    }
    
    func publisher<T>(for type: T.Type) -> AnyPublisher<T, Never> {
        subject(for: T.self).eraseToAnyPublisher()
    }
}
```

---

# 🗂 **5. Multi-channel EventBus (Per module / feature)**

Useful for large modular apps.
            
            ### Channel Key
            
            ```swift
            enum EventChannel {
case auth
case cart
case settings
}
```

### Multi-Channel Implementation

```swift
final class ChannelEventBus {
    static let shared = ChannelEventBus()
    private init() {}
    
    private var channels = [EventChannel : PassthroughSubject<Any, Never>]()
    
    private func channel(_ c: EventChannel) -> PassthroughSubject<Any, Never> {
        if let subject = channels[c] {
            return subject
        }
        let new = PassthroughSubject<Any, Never>()
        channels[c] = new
        return new
    }
    
    func send(_ event: Any, on channel: EventChannel) {
        channel(channel).send(event)
    }
    
    func publisher<T>(on channel: EventChannel, as type: T.Type) -> AnyPublisher<T, Never> {
        channel(channel)
            .compactMap { $0 as? T }
            .eraseToAnyPublisher()
    }
}
```

### Usage

```swift
ChannelEventBus.shared.send(UserLoggedIn(id: 1), on: .auth)

ChannelEventBus.shared.publisher(on: .auth, as: UserLoggedIn.self)
    .sink { print("Auth event:", $0) }
```

---

# 🔄 **6. State Broadcasting (Combine + CurrentValueSubject)**

For events that represent *state*, not *notifications*.

### Global App State

```swift
final class AppState {
    static let shared = AppState()
    private init() {}
    
    let userState = CurrentValueSubject<User?, Never>(nil)
    let cartState = CurrentValueSubject<[Int], Never>([])
}
```

### Updating state

```swift
AppState.shared.userState.send(User(id: 5, name: "John"))
```

### Observing in SwiftUI

```swift
@StateObject var store = AppState.shared

store.userState
    .sink { user in ... }
```

(This is basically Redux-lite.)

---

# 🧨 Which one should you use?

| Version                | Best for                    | Notes                                         |
| ---------------------- | --------------------------- | --------------------------------------------- |
| **Enum Bus**           | small apps                  | simple, no type safety with associated values |
| **Generic Bus ✔**      | large apps                  | best architecture, scalable                   |
| **SwiftUI Bus**        | SwiftUI-only apps           | works with `.onChange`                        |
| **Thread-Safe Bus**    | multi-threaded environments | recommended for production                    |
| **Multi-Channel Bus**  | modular apps                | each module has its own channel               |
| **State Broadcasting** | global state                | same idea as Redux, unidirectional            |
                                                            
---
