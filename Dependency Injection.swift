//
//  Dependency Injection.swift
//  
//
//  Created by Apple on 17/08/25.
//

import Foundation

### ✅ What is **Dependency Injection (DI)?**

**Dependency Injection** is a design pattern in which **an object receives (or is “injected with”) the dependencies it needs**, rather than creating them itself.

In Swift/iOS, this usually means **passing required objects (services, data sources, etc.) into a class rather than instantiating them inside the class.**

---

### 🧠 Key Concepts

* A **dependency** is any external object or service a class needs to function (e.g., a network client, database, logger).
* **Injection** means providing that dependency from outside, usually via:

  * Initializers
  * Properties
  * Method parameters

---

### 📦 Example (Without DI – Tight Coupling)

```swift
class LoginViewModel {
    let api = AuthAPI() // bad: hard-coded dependency

    func login(user: String, pass: String) {
        api.authenticate(user: user, pass: pass)
    }
}
```

This class **cannot be reused or tested easily**, because it's tightly coupled to `AuthAPI`.

---

### ✅ Example (With Dependency Injection)

```swift
protocol AuthService {
    func authenticate(user: String, pass: String)
}

class AuthAPI: AuthService {
    func authenticate(user: String, pass: String) {
        // real implementation
    }
}

class LoginViewModel {
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    func login(user: String, pass: String) {
        authService.authenticate(user: user, pass: pass)
    }
}
```

Now:

* You can **inject a real or mock AuthService**.
* Great for **unit testing**.
* `LoginViewModel` depends on **abstractions**, not concrete implementations.

---

### 🔧 Why Use Dependency Injection in iOS (Swift)?

#### ✅ 1. **Improves Testability**

You can inject mock or fake services for unit testing, avoiding real network or database calls.

#### ✅ 2. **Reduces Coupling**

Your classes depend on protocols (interfaces), not concrete implementations. This leads to flexible and reusable code.

#### ✅ 3. **Promotes Modularity**

Makes it easier to separate concerns and break the app into smaller, testable modules.

#### ✅ 4. **Supports Better Architecture**

Works naturally with architectures like **MVVM**, **VIPER**, **Clean Architecture**, and **Modular App Architectures**.

---

### 🧰 Common DI Techniques in Swift

| Technique                 | Example Use Case                                    |
| ------------------------- | --------------------------------------------------- |
| **Initializer Injection** | Most common; used in ViewModels, Services           |
| **Property Injection**    | Useful in UIKit when init injection is tricky       |
| **Method Injection**      | Useful when a dependency is only used in one method |
| **DI Frameworks**         | `Swinject`, `Needle`, `Factory`, etc.               |

---

### 🧪 Testing Example

```swift
class MockAuthService: AuthService {
    var loginCalled = false

    func authenticate(user: String, pass: String) {
        loginCalled = true
    }
}

let mock = MockAuthService()
let viewModel = LoginViewModel(authService: mock)
viewModel.login(user: "john", pass: "123")
assert(mock.loginCalled) // ✅ test passed
```

---

### 🔚 Summary

* **Dependency Injection** is about **giving dependencies to a class instead of making them itself**.
* In iOS, it's crucial for **testability, modularity, and clean architecture**.
* Prefer **initializer injection**, and use protocols to abstract dependencies.
* Consider DI frameworks for large-scale projects.
