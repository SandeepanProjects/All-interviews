//
//  Clean Architecture.swift
//  
//
//  Created by Apple on 28/03/26.
//

import Foundation

Great—let’s level this up to **real production-grade architecture** like what you’d see at companies such as eBay or Uber.

We’ll cover **both**:

1. 📁 Production Folder Structure
2. 🧩 Dependency Injection (DI)
3. ⚡ Advanced features: Pagination, Caching, Error Handling, Retry, Actors

---

# 📁 1. Production Folder Structure (Scalable)

```id="0n1m2k"
App/
│
├── Core/
│   ├── Network/
│   ├── DI/
│   ├── Extensions/
│   ├── Utils/
│
├── Features/
│   ├── Users/
│   │   ├── Domain/
│   │   │   ├── Entities/
│   │   │   ├── UseCases/
│   │   │   ├── Repositories/
│   │   │
│   │   ├── Data/
│   │   │   ├── DTOs/
│   │   │   ├── RepositoryImpl/
│   │   │   ├── DataSources/
│   │   │
│   │   ├── Presentation/
│   │       ├── ViewModels/
│   │       ├── Views/
│
├── Resources/
└── App.swift
```

---

## 🔥 Why This Works

* Feature-based → scalable for large teams
* Domain isolated → testable
* Data layer swappable → REST / GraphQL / DB

---

# 🧩 2. Dependency Injection (DI)

## 🔹 Simple DI Container

```swift
final class DIContainer {
    static let shared = DIContainer()

    private init() {}

    // MARK: - Services
    lazy var apiService = APIService()

    // MARK: - Repositories
    lazy var userRepository: UserRepository =
        UserRepositoryImpl(api: apiService)

    // MARK: - UseCases
    func makeFetchUsersUseCase() -> FetchUsersUseCase {
        FetchUsersUseCase(repository: userRepository)
    }

    // MARK: - ViewModels
    func makeUserViewModel() -> UserViewModel {
        UserViewModel(useCase: makeFetchUsersUseCase())
    }
}
```

---

## 🔹 Inject into View

```swift
struct UserView: View {
    @StateObject var vm = DIContainer.shared.makeUserViewModel()
}
```

---

## 🧠 Interview Tip

> “We use dependency injection to decouple layers and enable mocking, following Dependency Inversion.”

---

# ⚡ 3. Advanced Real-World Features

---

# 🔄 A. Pagination (API + ViewModel)

## API

```swift
func fetchUsers(page: Int) async throws -> [UserDTO]
```

---

## ViewModel

```swift
@MainActor
final class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    private var page = 1
    private var isFetching = false

    private let useCase: FetchUsersUseCase

    func loadMoreIfNeeded(currentItem: User?) {
        guard let currentItem = currentItem else {
            loadUsers()
            return
        }

        let thresholdIndex = users.index(users.endIndex, offsetBy: -5)
        if users.firstIndex(where: { $0.id == currentItem.id }) == thresholdIndex {
            loadUsers()
        }
    }

    func loadUsers() {
        guard !isFetching else { return }
        isFetching = true

        Task {
            defer { isFetching = false }

            do {
                let newUsers = try await useCase.execute(page: page)
                users.append(contentsOf: newUsers)
                page += 1
            } catch {
                print(error)
            }
        }
    }
}
```

---

# 💾 B. Caching (Using Actor)

## Why Actor?

Thread-safe shared state ✅

---

```swift
actor UserCache {
    private var storage: [Int: User] = [:]

    func save(users: [User]) {
        for user in users {
            storage[user.id] = user
        }
    }

    func getAll() -> [User] {
        Array(storage.values)
    }
}
```

---

## Use in Repository

```swift
final class UserRepositoryImpl: UserRepository {
    private let api: APIService
    private let cache = UserCache()

    func fetchUsers() async throws -> [User] {
        let cached = await cache.getAll()
        if !cached.isEmpty {
            return cached
        }

        let dtos = try await api.request()
        let users = dtos.map { $0.toDomain() }

        await cache.save(users: users)

        return users
    }
}
```

---

# ❌ C. Error Handling (Production Grade)

```swift
enum AppError: Error {
    case network
    case decoding
    case unknown
}
```

---

## API Layer

```swift
func request() async throws -> [UserDTO] {
    do {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw AppError.network
        }

        return try JSONDecoder().decode([UserDTO].self, from: data)

    } catch {
        throw AppError.unknown
    }
}
```

---

# 🔁 D. Retry Logic

```swift
func fetchWithRetry<T>(
    retries: Int = 3,
    operation: @escaping () async throws -> T
) async throws -> T {

    var attempts = 0

    while attempts < retries {
        do {
            return try await operation()
        } catch {
            attempts += 1
            if attempts == retries {
                throw error
            }
        }
    }

    throw AppError.unknown
}
```

---

## Usage

```swift
let users = try await fetchWithRetry {
    try await api.request()
}
```

---

# 🧵 E. Modern Concurrency Best Practices

### ✅ Use `@MainActor`

UI updates only

### ✅ Use `actor`

Shared mutable state

### ✅ Use `Task`

Fire async work

### ❌ Avoid:

* GCD (`DispatchQueue`)
* Callback hell

---

# 🚀 Final Architecture Flow

```id="o9h0k1"
SwiftUI View
   ↓
ViewModel (@MainActor)
   ↓
UseCase
   ↓
Repository (Protocol)
   ↓
RepositoryImpl
   ↓
API + Cache (Actor)
```

---

# 🎯 Interview Killer Summary

> “We use a feature-based Clean Architecture with MVVM in the presentation layer. Dependencies are injected via a DI container following SOLID principles, especially Dependency Inversion. We use async/await for API calls, actors for thread-safe caching, and implement pagination, retry logic, and error handling for production resilience.”

---

# 🔥 If You Want Next Level

I can go even deeper with:

* 🔐 Token refresh + auth interceptor
* 📡 Combine vs async/await comparison
* 🧪 Unit + UI testing setup (with mocks)
* 🧵 Offline-first architecture
* 📦 Modularization (SPM-based like large apps)

Just tell me 👍


Let’s break this down in a **clear, interview-ready + practical way**—connecting:

* Clean Architecture
* SOLID principles
* MVVM
* Modern Concurrency (Swift async/await)
* Fetching data from API

---

# 🧠 1. Clean Architecture (Core Idea)

Clean Architecture is about **separating concerns into layers** so your code is:

* Testable ✅
* Scalable ✅
* Maintainable ✅

### 🔷 Layers

```
Presentation (UI + ViewModel)
        ↓
Domain (Business Logic)
        ↓
Data (API, DB, Repository)
```

---

## 🔹 Each Layer Responsibility

### 1. Presentation Layer (MVVM here)

* SwiftUI Views
* ViewModels
* No business logic ❌

### 2. Domain Layer (Core logic)

* UseCases
* Entities (Models)
* Protocols (abstractions)

👉 PURE Swift → no UIKit, no API calls

### 3. Data Layer

* API calls
* Repository implementations
* DTOs → converted to domain models

---

# 🧱 2. SOLID Principles (Applied)

Let’s map SOLID to Clean Architecture:

### 🔹 S — Single Responsibility

Each class does ONE thing
✔ ViewModel → UI logic only
✔ Repository → data fetching only

---

### 🔹 O — Open/Closed

Open for extension, closed for modification

👉 Add new API without changing existing code

---

### 🔹 L — Liskov Substitution

Subclasses should behave like parent

👉 MockRepository should work like RealRepository

---

### 🔹 I — Interface Segregation

Small focused protocols

❌ Bad:

```swift
protocol DataService {
    func fetch()
    func save()
    func delete()
}
```

✔ Good:

```swift
protocol FetchService {
    func fetch() async throws
}
```

---

### 🔹 D — Dependency Inversion (MOST IMPORTANT)

High-level modules depend on **abstractions**

```swift
// Domain
protocol UserRepository {
    func fetchUsers() async throws -> [User]
}
```

NOT:

```swift
// ❌ Don't do this
let repo = APIService()
```

---

# 🧩 3. MVVM inside Clean Architecture

```
View → ViewModel → UseCase → Repository → API
```

### Responsibilities:

| Component  | Responsibility   |
| ---------- | ---------------- |
| View       | UI               |
| ViewModel  | State + UI logic |
| UseCase    | Business logic   |
| Repository | Data source      |

---

# ⚡ 4. Modern Concurrency (Swift)

Use:

* `async/await`
* `Task`
* `actor` (for thread safety)

---

### Example:

```swift
func fetchUsers() async throws -> [User]
```

---

# 🔄 5. Full Flow (Real Example)

Let’s build a **User Fetch Feature**

---

## 🧱 Domain Layer

### Entity

```swift
struct User: Identifiable {
    let id: Int
    let name: String
}
```

---

### Repository Protocol (D in SOLID)

```swift
protocol UserRepository {
    func fetchUsers() async throws -> [User]
}
```

---

### UseCase

```swift
final class FetchUsersUseCase {
    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func execute() async throws -> [User] {
        try await repository.fetchUsers()
    }
}
```

---

## 🌐 Data Layer

### API Service

```swift
final class APIService {
    func request() async throws -> [UserDTO] {
        let url = URL(string: "https://api.example.com/users")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([UserDTO].self, from: data)
    }
}
```

---

### DTO

```swift
struct UserDTO: Decodable {
    let id: Int
    let name: String

    func toDomain() -> User {
        User(id: id, name: name)
    }
}
```

---

### Repository Implementation

```swift
final class UserRepositoryImpl: UserRepository {
    private let api: APIService

    init(api: APIService) {
        self.api = api
    }

    func fetchUsers() async throws -> [User] {
        let dtos = try await api.request()
        return dtos.map { $0.toDomain() }
    }
}
```

---

## 📱 Presentation Layer (MVVM)

### ViewModel

```swift
@MainActor
final class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false

    private let useCase: FetchUsersUseCase

    init(useCase: FetchUsersUseCase) {
        self.useCase = useCase
    }

    func loadUsers() {
        Task {
            isLoading = true
            do {
                users = try await useCase.execute()
            } catch {
                print("Error: \(error)")
            }
            isLoading = false
        }
    }
}
```

---

### SwiftUI View

```swift
struct UserView: View {
    @StateObject var viewModel: UserViewModel

    var body: some View {
        List(viewModel.users) { user in
            Text(user.name)
        }
        .task {
            viewModel.loadUsers()
        }
    }
}
```

---

# 🧪 6. Why This Is Powerful (Interview Gold)

### ✅ Testability

```swift
class MockUserRepository: UserRepository {
    func fetchUsers() async throws -> [User] {
        return [User(id: 1, name: "Test")]
    }
}
```

---

### ✅ Replace API easily

* REST → GraphQL
* Local DB → Remote

---

### ✅ Scalability

Add new features without breaking old code

---

# 🔥 7. Key Takeaways (Memorize This)

* Clean Architecture = **Separation of Concerns**
* MVVM = **UI pattern inside Presentation**
* SOLID = **Design principles to keep code clean**
* Concurrency = **Non-blocking async code**

---

# 🎯 Interview One-Liner

> “I use Clean Architecture with MVVM where ViewModel interacts with UseCases, which depend on repository abstractions following Dependency Inversion. I use async/await for non-blocking API calls and keep domain layer pure for testability.”

---

If you want next level:
👉 I can give you a **production-level folder structure + dependency injection setup (like eBay/Uber level)** or
👉 Add **pagination, caching, error handling, retry, and actors** (real-world scenario)


