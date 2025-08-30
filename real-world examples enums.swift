//
//  real-world examples enums.swift
//  
//
//  Created by Apple on 30/08/25.
//

import Foundation

Absolutely — enums are incredibly useful in real-world iOS projects. Here's how they're typically used across **Networking**, **UI State Management**, **Routing**, and **Error Handling** — along with real-world-style code examples.

---

## 📡 1. **Networking – Result Types, Status Codes**

### 🔸 Use Case: Representing network request outcomes

```swift
enum NetworkResult<T> {
    case success(T)
    case failure(NetworkError)
}
```

### 🔸 Use Case: HTTP status code groups

```swift
enum HTTPStatus: Int {
    case ok = 200
    case notFound = 404
    case unauthorized = 401
    case serverError = 500
    case unknown

    init(statusCode: Int) {
        self = HTTPStatus(rawValue: statusCode) ?? .unknown
    }
}
```

---

## 🎨 2. **UI State Management**

Enums make state machines clean, safe, and declarative — especially in **MVVM** or **SwiftUI**.

```swift
enum ViewState<Data> {
    case idle
    case loading
    case loaded(Data)
    case failed(Error)
}
```

### 🔸 Example in ViewModel:

```swift
@Published var state: ViewState<[User]> = .idle

func loadUsers() {
    state = .loading
    service.fetchUsers { result in
        DispatchQueue.main.async {
            switch result {
            case .success(let users):
                self.state = .loaded(users)
            case .failure(let error):
                self.state = .failed(error)
            }
        }
    }
}
```

### 🔸 Usage in SwiftUI:

```swift
switch viewModel.state {
case .idle:
    Text("Idle")
case .loading:
    ProgressView()
case .loaded(let users):
    List(users) { user in Text(user.name) }
case .failed(let error):
    Text("Error: \(error.localizedDescription)")
}
```

---

## 🧭 3. **Routing / Navigation State**

Enums are perfect for modeling which screen you're on, or what the next screen should be.

```swift
enum AppRoute {
    case login
    case home(user: User)
    case settings
    case details(itemID: String)
}
```

This is useful in **coordinators**, **navigation stacks**, or **state-driven SwiftUI navigation**:

```swift
class Router: ObservableObject {
    @Published var currentRoute: AppRoute = .login
}

switch router.currentRoute {
case .login:
    LoginView()
case .home(let user):
    HomeView(user: user)
case .settings:
    SettingsView()
case .details(let id):
    DetailView(itemID: id)
}
```

---

## ❗ 4. **Error Handling**

Enums are the idiomatic way to model custom `Error` types in Swift.

```swift
enum NetworkError: Error {
    case noInternet
    case serverError(code: Int)
    case decodingFailed
    case unauthorized
    case unknown(Error)
}
```

Use in a function:

```swift
func fetchData() throws {
    let statusCode = 500
    guard statusCode == 200 else {
        throw NetworkError.serverError(code: statusCode)
    }
}
```

Handle with pattern matching:

```swift
do {
    try fetchData()
} catch NetworkError.noInternet {
    print("No internet connection.")
} catch NetworkError.serverError(let code) {
    print("Server error with code: \(code)")
} catch {
    print("Unhandled error: \(error)")
}
```

---

## 🧠 Why Use Enums in These Cases?

| Use Case       | Why Enums Are Ideal                             |
| -------------- | ----------------------------------------------- |
| Networking     | Clear success/failure representation (`Result`) |
| View State     | Finite, mutually exclusive UI states            |
| Routing        | Clean, type-safe screen navigation              |
| Error Handling | Precise error modeling with associated values   |

---

Would you like a small demo project outline using these concepts together? (e.g. networking + view state + error handling in SwiftUI)?

Great! Let’s design a **small demo project outline** that uses enums effectively across:

* ✅ **Networking**
* ✅ **UI state management**
* ✅ **Error handling**
* ✅ **Routing/navigation**

This will be a clean SwiftUI + Combine/MVVM-based app called:

---

# 📱 **"UserFetcher" – A SwiftUI App to Fetch and Show Users**

---

## 🧩 Project Structure Overview

```
UserFetcher/
├── Models/
│   ├── User.swift
│   ├── ViewState.swift
│   └── AppRoute.swift
├── Networking/
│   ├── APIService.swift
│   └── NetworkError.swift
├── ViewModels/
│   └── UserViewModel.swift
├── Views/
│   ├── UserListView.swift
│   └── UserDetailView.swift
└── App/
    └── UserFetcherApp.swift
```

---

## 🧱 1. **Models**

### `User.swift`

```swift
struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
}
```

### `ViewState.swift` – Enum for UI state

```swift
enum ViewState<Data> {
    case idle
    case loading
    case loaded(Data)
    case failed(NetworkError)
}
```

### `AppRoute.swift` – Enum for navigation

```swift
enum AppRoute: Hashable {
    case userList
    case userDetail(User)
}
```

---

## 🌐 2. **Networking**

### `NetworkError.swift`

```swift
enum NetworkError: Error, LocalizedError {
    case noInternet
    case decodingFailed
    case serverError(code: Int)
    case unknown

    var errorDescription: String? {
        switch self {
        case .noInternet: return "No internet connection"
        case .decodingFailed: return "Failed to decode response"
        case .serverError(let code): return "Server error: \(code)"
        case .unknown: return "An unknown error occurred"
        }
    }
}
```

### `APIService.swift`

```swift
class APIService {
    func fetchUsers() async throws -> [User] {
        let url = URL(string: "https://jsonplaceholder.typicode.com/users")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw NetworkError.serverError(code: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode([User].self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }
}
```

---

## 🧠 3. **ViewModel**

### `UserViewModel.swift`

```swift
@MainActor
class UserViewModel: ObservableObject {
    @Published var state: ViewState<[User]> = .idle
    private let service = APIService()

    func loadUsers() async {
        state = .loading
        do {
            let users = try await service.fetchUsers()
            state = .loaded(users)
        } catch let error as NetworkError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown)
        }
    }
}
```

---

## 🎨 4. **Views**

### `UserListView.swift`

```swift
struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()
    @State private var selectedUser: User?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Users")
                .task {
                    await viewModel.loadUsers()
                }
                .navigationDestination(item: $selectedUser) { user in
                    UserDetailView(user: user)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading...")
        case .loaded(let users):
            List(users) { user in
                Button(user.name) {
                    selectedUser = user
                }
            }
        case .failed(let error):
            VStack {
                Text("Error: \(error.localizedDescription)")
                Button("Retry") {
                    Task { await viewModel.loadUsers() }
                }
            }
        }
    }
}
```

### `UserDetailView.swift`

```swift
struct UserDetailView: View {
    let user: User

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Name: \(user.name)")
            Text("Email: \(user.email)")
        }
        .navigationTitle("User Details")
        .padding()
    }
}
```

---

## 🚀 5. **App Entry Point**

### `UserFetcherApp.swift`

```swift
@main
struct UserFetcherApp: App {
    var body: some Scene {
        WindowGroup {
            UserListView()
        }
    }
}
```

---

## ✅ Summary of Enum Usage

| Enum           | Purpose                                                  |
| -------------- | -------------------------------------------------------- |
| `ViewState`    | UI state machine (`idle`, `loading`, `loaded`, `failed`) |
| `NetworkError` | Strongly-typed error handling                            |
| `AppRoute`     | Navigation representation                                |

---

