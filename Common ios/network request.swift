//
//  network request.swift
//  
//
//  Created by Apple on 20/12/25.
//

import Foundation

Below is a practical, modern Swift/iOS guide covering each topic, with examples you’d actually use in production apps.

---

## 1. How do you make a network request in Swift?

### Using `URLSession` with `async/await` (recommended)

```swift
struct User: Decodable {
    let id: Int
    let name: String
}

func fetchUser() async throws -> User {
    let url = URL(string: "https://api.example.com/user")!
    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
          200..<300 ~= httpResponse.statusCode else {
        throw URLError(.badServerResponse)
    }

    return try JSONDecoder().decode(User.self, from: data)
}
```

Usage:

```swift
Task {
    do {
        let user = try await fetchUser()
        print(user)
    } catch {
        print(error)
    }
}
```

---

## 2. How do you handle API errors gracefully?

### Define clear error types

```swift
enum APIError: Error {
    case invalidURL
    case network(Error)
    case server(statusCode: Int)
    case decoding
}
```

### Map errors properly

```swift
func fetchData() async throws -> User {
    do {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.server(statusCode: -1)
        }

        guard 200..<300 ~= http.statusCode else {
            throw APIError.server(statusCode: http.statusCode)
        }

        return try JSONDecoder().decode(User.self, from: data)
    } catch is DecodingError {
        throw APIError.decoding
    } catch {
        throw APIError.network(error)
    }
}
```

### UI-level handling

* Show user-friendly messages
* Retry on network failure
* Log technical details silently

---

## 3. How do you cancel an API request?

### With `async/await` and `Task`

```swift
let task = Task {
    try await fetchUser()
}

// Cancel
task.cancel()
```

Inside your async function:

```swift
try Task.checkCancellation()
```

### With `URLSessionDataTask` (completion handler style)

```swift
let task = URLSession.shared.dataTask(with: url) { _, _, _ in }
task.resume()

task.cancel()
```

---

## 4. How do you handle pagination?

### Page-based pagination

```swift
func fetchPage(page: Int) async throws -> [User] {
    let url = URL(string: "https://api.example.com/users?page=\(page)")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([User].self, from: data)
}
```

Usage:

```swift
var currentPage = 1
var allUsers: [User] = []

let users = try await fetchPage(page: currentPage)
allUsers.append(contentsOf: users)
currentPage += 1
```

### Infinite scrolling (best practice)

* Track `isLoading`
* Stop when API returns empty results
* Trigger fetch when user scrolls near the bottom

---

## 5. How do you cache API responses?

### 1️⃣ URLCache (built-in, easiest)

```swift
let cache = URLCache(
    memoryCapacity: 20 * 1024 * 1024,
    diskCapacity: 100 * 1024 * 1024
)
URLCache.shared = cache
```

Ensure server sends proper cache headers.

---

### 2️⃣ In-memory caching (`NSCache`)

```swift
let cache = NSCache<NSString, NSData>()

cache.setObject(data as NSData, forKey: "users" as NSString)
```

Best for:

* Images
* Temporary data

---

### 3️⃣ Persistent caching

* Core Data
* SQLite
* File system

Best for:

* Offline mode
* Large datasets

---

## 6. `async/await` vs completion handlers — pros & cons

### `async/await` ✅ (Modern)

**Pros**

* Clean, readable code
* Easier error handling (`try/catch`)
* Natural cancellation support
* Avoids “callback hell”

**Cons**

* iOS 13+ (iOS 15+ for full support)
* Requires structured concurrency understanding

---

### Completion Handlers ⚠️ (Legacy)

```swift
URLSession.shared.dataTask(with: url) { data, response, error in
    // callback logic
}
```

**Pros**

* Works on older iOS versions
* Familiar to long-time iOS devs

**Cons**

* Nested callbacks
* Harder to cancel and test
* Error handling is messy
* Memory management pitfalls (`[weak self]`)

---

## ✅ Summary

| Topic            | Best Practice                        |
| ---------------- | ------------------------------------ |
| Network Requests | `URLSession` + `async/await`         |
| Error Handling   | Custom error enums                   |
| Cancellation     | `Task.cancel()`                      |
| Pagination       | Page-based + infinite scroll         |
| Caching          | `URLCache` / `NSCache` / persistence |
| Concurrency      | Prefer `async/await`                 |

If you want, I can:

* Show a **full networking layer**
* Convert completion handlers → `async/await`
* Explain this in **interview-answer format**
* Show **real-world architecture (MVVM)**


Below is a **clean, production-ready networking layer in Swift**, using **async/await**, **error handling**, **cancellation**, **pagination support**, and **caching**.
This is the kind of setup you’d see in a real iOS app (and in interviews).

---

# 1. Core Concepts (Structure)

```
Networking/
 ├─ APIClient.swift
 ├─ APIRequest.swift
 ├─ APIError.swift
 ├─ HTTPMethod.swift
 ├─ Endpoint.swift
 └─ Models/
     └─ User.swift
```

---

# 2. HTTP Method

```swift
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
```

---

# 3. API Errors

```swift
enum APIError: Error, LocalizedError {
    case invalidURL
    case network(Error)
    case server(statusCode: Int)
    case decoding
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .network:
            return "Network error"
        case .server(let code):
            return "Server error (\(code))"
        case .decoding:
            return "Failed to decode response"
        case .cancelled:
            return "Request was cancelled"
        }
    }
}
```

---

# 4. Endpoint Definition

Centralized endpoints prevent hard-coded URLs everywhere.

```swift
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
}
```

Example:

```swift
enum UserEndpoint: Endpoint {
    case users(page: Int)
    case user(id: Int)

    var path: String {
        switch self {
        case .users:
            return "/users"
        case .user(let id):
            return "/users/\(id)"
        }
    }

    var method: HTTPMethod { .get }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .users(let page):
            return [URLQueryItem(name: "page", value: "\(page)")]
        default:
            return nil
        }
    }
}
```

---

# 5. API Request Builder

```swift
struct APIRequest {
    let endpoint: Endpoint
    let baseURL: String

    func makeURLRequest() throws -> URLRequest {
        guard var components = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }

        components.path += endpoint.path
        components.queryItems = endpoint.queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.cachePolicy = .returnCacheDataElseLoad
        return request
    }
}
```

---

# 6. API Client (Heart of the Layer)

```swift
final class APIClient {

    static let shared = APIClient()
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(
        _ request: APIRequest,
        type: T.Type
    ) async throws -> T {

        let urlRequest = try request.makeURLRequest()

        do {
            let (data, response) = try await session.data(for: urlRequest)

            try Task.checkCancellation()

            guard let http = response as? HTTPURLResponse else {
                throw APIError.server(statusCode: -1)
            }

            guard 200..<300 ~= http.statusCode else {
                throw APIError.server(statusCode: http.statusCode)
            }

            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decoding
            }

        } catch is CancellationError {
            throw APIError.cancelled
        } catch {
            throw APIError.network(error)
        }
    }
}
```

---

# 7. Models

```swift
struct User: Decodable, Identifiable {
    let id: Int
    let name: String
    let email: String
}
```

---

# 8. Repository Layer (Pagination Example)

This keeps networking **out of your view models**.

```swift
final class UserRepository {

    private let client = APIClient.shared
    private let baseURL = "https://api.example.com"

    func fetchUsers(page: Int) async throws -> [User] {
        let endpoint = UserEndpoint.users(page: page)
        let request = APIRequest(endpoint: endpoint, baseURL: baseURL)
        return try await client.request(request, type: [User].self)
    }
}
```

---

# 9. Usage in a ViewModel (MVVM)

```swift
@MainActor
final class UsersViewModel: ObservableObject {

    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repository = UserRepository()
    private var page = 1
    private var task: Task<Void, Never>?

    func loadMoreUsers() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        task = Task {
            do {
                let newUsers = try await repository.fetchUsers(page: page)
                users.append(contentsOf: newUsers)
                page += 1
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func cancelLoading() {
        task?.cancel()
    }
}
```

---

# 10. Caching (URLCache Setup)

```swift
let cache = URLCache(
    memoryCapacity: 50 * 1024 * 1024,
    diskCapacity: 200 * 1024 * 1024
)
URLCache.shared = cache
```

---

# ✅ What This Layer Gives You

✔ Clean separation of concerns
✔ Centralized error handling
✔ Cancellation support
✔ Pagination-ready
✔ Caching enabled
✔ Easy to test & mock
✔ Interview-grade architecture

---

If you want next, I can:

* Add **auth headers / tokens**
* Add **retry & exponential backoff**
* Show **unit tests with mocked URLSession**
* Convert this to **Combine**
* Show **offline-first caching**

Just tell me 👍
