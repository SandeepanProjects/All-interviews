//
//  Dependency Inversion.swift
//  
//
//  Created by Apple on 17/08/25.
//

import Foundation

### 🔄 What is **Dependency Inversion** in iOS (Swift)?

**Dependency Inversion** is one of the **SOLID** principles of object-oriented design:

> **"High-level modules should not depend on low-level modules. Both should depend on abstractions."**

> **"Abstractions should not depend on details. Details should depend on abstractions."**

---

### 🧱 Breaking It Down (in iOS/Swift terms)

* **High-level module**: Business logic (e.g., ViewModel, Interactor)
* **Low-level module**: Services (e.g., networking, storage)
* **Abstraction**: Protocols (e.g., `AuthService`, `DatabaseService`)

Instead of your business logic depending on concrete implementations (like `AuthAPI`), you invert the dependency so that **both business logic and implementations depend on protocols**.

---

### ❌ Without Dependency Inversion (Bad)

```swift
class LoginViewModel {
    let api = AuthAPI() // tightly coupled to concrete class
}
```

* `LoginViewModel` (high-level) depends on `AuthAPI` (low-level).
* Hard to test, swap, or extend.

---

### ✅ With Dependency Inversion (Good)

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

* `LoginViewModel` depends on the **abstraction**, not the implementation.
* `AuthAPI` also depends on the abstraction (it conforms to `AuthService`).
* You have **inverted the dependency** from low-level to high-level.

---

### 📍 Why Use Dependency Inversion in iOS?

| Benefit              | Explanation                                                                              |
| -------------------- | ---------------------------------------------------------------------------------------- |
| ✅ Testability        | Easily mock or stub services in tests.                                                   |
| ✅ Flexibility        | Swap different implementations (e.g., REST vs. GraphQL) without changing business logic. |
| ✅ Loose Coupling     | Modules don’t care how others work internally.                                           |
| ✅ Clean Architecture | Essential for MVVM, VIPER, Clean Swift, etc.                                             |

---

### 🧪 Example Scenario

#### Case: Building a User Authentication Flow

Without Dependency Inversion:

* `LoginViewModel` directly creates and uses `FirebaseAuthService`.

With Dependency Inversion:

1. Define an abstraction:

   ```swift
   protocol AuthService {
       func login(email: String, password: String) -> Bool
   }
   ```
2. Implement it in different ways:

   ```swift
   class FirebaseAuthService: AuthService { ... }
   class MockAuthService: AuthService { ... }
   ```
3. Inject into ViewModel:

   ```swift
   class LoginViewModel {
       init(authService: AuthService) { ... }
   }
   ```

Now you can:

* Swap real or fake services easily
* Write unit tests without Firebase
* Add a new backend later without touching the ViewModel

---

### 🧠 Summary

| Concept                  | Explanation                                                                                                |
| ------------------------ | ---------------------------------------------------------------------------------------------------------- |
| **Dependency Injection** | A **technique** used to implement dependency inversion (by passing dependencies into a class).             |
| **Dependency Inversion** | A **principle** that ensures both high-level and low-level modules depend on abstractions, not each other. |

---

### 🔄 Final Thought

Use **Dependency Inversion** when:

* You're designing scalable, testable architectures (MVVM, VIPER, Clean)
* You want to avoid tight coupling between services and business logic
* You expect to **mock**, **swap**, or **extend** implementations later

Would you like a small real-world Clean Architecture example showing this in action?
