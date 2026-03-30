//
//  Liskov Substitution Principle.swift
//  
//
//  Created by Apple on 30/03/26.
//

import Foundation

A clean real-world scenario of the **Liskov Substitution Principle (LSP)** in iOS is **network layer abstraction**—something you’ll definitely encounter in production apps.

---

## 🔹 Scenario: Network Service Abstraction

### 🎯 Problem

You have a networking layer that fetches data from APIs. Later, you want to:

* Switch between real API and mock data (for testing)
* Add caching layer
* Add offline support

You don’t want your app to break when swapping implementations.

---

## ❌ Without LSP (Bad Design)

```swift
class APIService {
    func fetchUsers() async throws -> [User] {
        // actual API call
    }
}

class MockAPIService: APIService {
    override func fetchUsers() async throws -> [User] {
        fatalError("Not implemented properly") // ❌ breaks expectation
    }
}
```

👉 Problem:

* `MockAPIService` **cannot safely replace** `APIService`
* Violates LSP because behavior is inconsistent

---

## ✅ With LSP (Good Design)

### Step 1: Define a Protocol (Contract)

```swift
protocol UserService {
    func fetchUsers() async throws -> [User]
}
```

---

### Step 2: Real Implementation

```swift
class APIService: UserService {
    func fetchUsers() async throws -> [User] {
        // real API call
        return [User(name: "John")]
    }
}
```

---

### Step 3: Mock Implementation

```swift
class MockAPIService: UserService {
    func fetchUsers() async throws -> [User] {
        return [User(name: "Mock User")]
    }
}
```

---

### Step 4: Usage in ViewModel

```swift
class UserViewModel {
    private let service: UserService

    init(service: UserService) {
        self.service = service
    }

    func loadUsers() async {
        do {
            let users = try await service.fetchUsers()
            print(users)
        } catch {
            print(error)
        }
    }
}
```

---

## 🔥 Why This Follows LSP

* `APIService` and `MockAPIService` are **fully interchangeable**
* Both:

  * Return valid `[User]`
  * Don’t crash unexpectedly
  * Follow same contract

👉 You can substitute one with another **without breaking behavior**

---

## 🚀 Real iOS Use Cases

This pattern is used in:

1. **Unit Testing**

   * Inject `MockAPIService` instead of real API

2. **Feature Flags / Environments**

   * Dev → Mock
   * Prod → Real API

3. **Offline-first apps**

   * Replace with `CachedUserService`

---

## ⚠️ Common LSP Violation in iOS

```swift
class Bird {
    func fly() { }
}

class Penguin: Bird {
    override func fly() {
        fatalError("Penguins can't fly") // ❌ LSP violation
    }
}
```

👉 In iOS terms, similar mistake:

* A subclass crashes or behaves differently than expected contract

---

## 🧠 Key Takeaway

> If your subclass (or implementation) **forces the caller to know its type**, you’ve broken LSP.

---

If you want, I can give you a **SwiftUI + Clean Architecture + LSP example (with Repository pattern + DI)** — that’s exactly what companies like Apple / Uber / eBay expect in interviews.


Great—this is exactly where **LSP shines in real apps**. Let’s extend the previous example to support **offline mode + caching** without breaking existing code.

---

# 🚀 Goal

Add offline support such that:

* If internet is available → fetch from API
* If offline → return cached data
* Caller (ViewModel) doesn’t change at all ✅

---

# ✅ Step 1: Keep the Same Contract (LSP)

```swift
protocol UserService {
    func fetchUsers() async throws -> [User]
}
```

👉 This is critical:
We **do NOT change this interface** — otherwise we break LSP.

---

# ✅ Step 2: Add Cache Layer

```swift
class CacheService {
    private var users: [User] = []

    func save(users: [User]) {
        self.users = users
    }

    func loadUsers() -> [User] {
        return users
    }
}
```

> In real apps → use CoreData / SQLite / file storage

---

# ✅ Step 3: Real API Service (unchanged)

```swift
class APIService: UserService {
    func fetchUsers() async throws -> [User] {
        // simulate API
        return [User(name: "Online User")]
    }
}
```

---

# ✅ Step 4: NEW → Offline-Capable Service (LSP Compliant)

```swift
class OfflineUserService: UserService {
    private let apiService: UserService
    private let cache: CacheService

    init(apiService: UserService, cache: CacheService) {
        self.apiService = apiService
        self.cache = cache
    }

    func fetchUsers() async throws -> [User] {
        do {
            let users = try await apiService.fetchUsers()
            cache.save(users: users)
            return users
        } catch {
            let cachedUsers = cache.loadUsers()
            
            if !cachedUsers.isEmpty {
                return cachedUsers // ✅ fallback
            } else {
                throw error // no data available
            }
        }
    }
}
```

---

# ✅ Step 5: ViewModel (NO CHANGE ❗)

```swift
class UserViewModel {
    private let service: UserService

    init(service: UserService) {
        self.service = service
    }

    func loadUsers() async {
        do {
            let users = try await service.fetchUsers()
            print(users)
        } catch {
            print("Error:", error)
        }
    }
}
```

---

# 🔥 Usage

```swift
let api = APIService()
let cache = CacheService()

let service = OfflineUserService(apiService: api, cache: cache)

let viewModel = UserViewModel(service: service)
```

---

# 💡 Why This is LSP-Compliant

* `OfflineUserService` can fully replace `APIService`
* It:

  * Returns `[User]` ✅
  * Doesn’t crash unexpectedly ✅
  * Enhances behavior (adds fallback) ✅

👉 ViewModel has **no idea** whether data is:

* from network
* from cache
* from hybrid source

---

# 🧠 Real-World Upgrade (Production Level)

You can extend this further:

### 1. Add Network Monitor

```swift
protocol NetworkMonitor {
    var isConnected: Bool { get }
}
```

---

### 2. Smarter Strategy

* Online → API + Cache
* Offline → Cache only
* Slow network → Cache first, then refresh

---

### 3. Clean Architecture Structure

```
Presentation (ViewModel)
        ↓
Domain (UserService protocol)
        ↓
Data Layer
   ├── APIService
   ├── CacheService
   └── OfflineUserService (Coordinator)
```

---

# ⚠️ Common Mistake (LSP Violation)

```swift
func fetchUsers() async throws -> [User]? // ❌ changed return type
```

👉 Now callers must handle `nil` → breaks substitution

---

# 🏁 Final Insight

This pattern is called:
👉 **Decorator Pattern + Repository Pattern**

Used in:

* Uber (offline rides)
* WhatsApp (message caching)
* Spotify (offline music)

---

If you want next level: I can show
👉 **CoreData-based offline storage + background sync + pagination (real production design)**
