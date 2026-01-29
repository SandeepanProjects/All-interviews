//
//  login view model testing.swift
//  
//
//  Created by Apple on 29/01/26.
//

import Foundation

Nice, this is **senior-level iOS testing territory** 👍
I’ll show you a **clean, SOLID, async/await–friendly LoginViewModel** and **test cases using the new Swift Testing framework (`import Testing`)**, with **mocks**, **dependency inversion**, and **modern concurrency**.

No XCTest. No legacy expectations. Pure modern Swift.

---

# 1️⃣ Design first (SOLID-friendly)

### 🎯 Responsibilities

* ViewModel → orchestration + state
* AuthService → login logic
* SessionStore → persistence
* NotificationCenter/EventBus → side effects

Everything is **protocol-driven**.

---

## 2️⃣ Core Models

```swift
struct User: Equatable {
    let id: String
    let name: String
}

enum LoginError: Error, Equatable {
    case invalidCredentials
    case networkFailure
}
```

---

## 3️⃣ Protocols (Dependency Inversion ✅)

```swift
protocol AuthServicing {
    func login(username: String, password: String) async throws -> User
}

protocol SessionStoring {
    func save(user: User)
}
```

---

## 4️⃣ Event (used by ViewModel)

```swift
protocol AppEvent {}

struct UserLoggedInEvent: AppEvent {
    let user: User
}
```

---

## 5️⃣ LoginViewModel (Async + MainActor)

```swift
import Combine

@MainActor
final class LoginViewModel: ObservableObject {

    @Published private(set) var isLoading = false
    @Published private(set) var user: User?
    @Published private(set) var error: LoginError?

    private let authService: AuthServicing
    private let sessionStore: SessionStoring
    private let eventBus: CombineNotificationCenter

    init(
        authService: AuthServicing,
        sessionStore: SessionStoring,
        eventBus: CombineNotificationCenter = .shared
    ) {
        self.authService = authService
        self.sessionStore = sessionStore
        self.eventBus = eventBus
    }

    func login(username: String, password: String) async {
        isLoading = true
        error = nil

        do {
            let user = try await authService.login(
                username: username,
                password: password
            )
            self.user = user
            sessionStore.save(user: user)
            eventBus.post(UserLoggedInEvent(user: user))
        } catch let loginError as LoginError {
            error = loginError
        } catch {
            error = .networkFailure
        }

        isLoading = false
    }
}
```

✅ SOLID
✅ Testable
✅ No side effects hidden
✅ MainActor safe for SwiftUI

---

# 6️⃣ Mocks for Testing

## Mock Auth Service

```swift
final class MockAuthService: AuthServicing {

    var result: Result<User, LoginError>!

    func login(username: String, password: String) async throws -> User {
        switch result! {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }
}
```

---

## Mock Session Store

```swift
final class MockSessionStore: SessionStoring {

    private(set) var savedUser: User?

    func save(user: User) {
        savedUser = user
    }
}
```

---

## Mock Event Bus (Combine-based)

```swift
final class MockEventBus: CombineNotificationCenter {

    private(set) var postedEvents: [AppEvent] = []

    override func post<T>(_ event: T) where T : AppEvent {
        postedEvents.append(event)
    }
}
```

> 👆 This lets us assert **side effects**, not just state.

---

# 7️⃣ Swift Testing Framework Setup

```swift
import Testing
@testable import YourAppModule
```

Swift Testing uses:

* `@Test`
* `#expect`
* async tests by default 🎉

---

# 8️⃣ Test Case: Successful Login

```swift
@Test
func login_success_updatesStateAndSendsEvent() async {
    let auth = MockAuthService()
    let session = MockSessionStore()
    let eventBus = MockEventBus()

    let expectedUser = User(id: "1", name: "Sandeep")
    auth.result = .success(expectedUser)

    let vm = LoginViewModel(
        authService: auth,
        sessionStore: session,
        eventBus: eventBus
    )

    await vm.login(username: "test", password: "1234")

    #expect(vm.isLoading == false)
    #expect(vm.user == expectedUser)
    #expect(vm.error == nil)
    #expect(session.savedUser == expectedUser)
    #expect(eventBus.postedEvents.count == 1)
}
```

---

# 9️⃣ Test Case: Invalid Credentials

```swift
@Test
func login_invalidCredentials_setsError() async {
    let auth = MockAuthService()
    let session = MockSessionStore()
    let eventBus = MockEventBus()

    auth.result = .failure(.invalidCredentials)

    let vm = LoginViewModel(
        authService: auth,
        sessionStore: session,
        eventBus: eventBus
    )

    await vm.login(username: "wrong", password: "wrong")

    #expect(vm.user == nil)
    #expect(vm.error == .invalidCredentials)
    #expect(session.savedUser == nil)
    #expect(eventBus.postedEvents.isEmpty)
}
```

---

# 🔟 Test Case: Loading State (Concurrency)

```swift
@Test
func login_setsLoadingStateCorrectly() async {
    let auth = MockAuthService()
    let session = MockSessionStore()

    auth.result = .success(User(id: "1", name: "Test"))

    let vm = LoginViewModel(
        authService: auth,
        sessionStore: session
    )

    let task = Task {
        await vm.login(username: "a", password: "b")
    }

    #expect(vm.isLoading == true)

    await task.value

    #expect(vm.isLoading == false)
}
```

---

# 1️⃣1️⃣ What this demonstrates (Interview Gold ⭐)

✔ SOLID principles
✔ Dependency Injection
✔ Modern Swift Concurrency
✔ Swift Testing (not XCTest)
✔ Deterministic async tests
✔ Side-effect verification

---

# 1️⃣2️⃣ Interview One-liner

> “I design ViewModels with async/await, protocol-based dependencies, and test them using Swift Testing with mocks, verifying both state and side effects.”

---

If you want next:

* 🧪 **Property-based tests**
* 🔄 **Retry logic + tests**
* 🧵 **Actor-based AuthService**
* 📱 **SwiftUI View tests**

Just say the word 🚀
