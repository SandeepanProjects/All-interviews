//
//  Handle API Errors Gracefully.swift
//  
//
//  Created by Apple on 09/11/25.
//

import Foundation

Handling API errors gracefully is crucial in iOS apps to ensure a smooth user experience, maintain trust, and make debugging easier. Here’s a **structured approach with best practices**, including Swift examples.

---

## **1. Categorize Errors**

First, understand the types of errors you might encounter:

| Error Type         | Examples                                           | How to Handle                                    |
| ------------------ | -------------------------------------------------- | ------------------------------------------------ |
| **Network Errors** | No internet, timeout, DNS failure                  | Retry, show “No internet” UI                     |
| **Server Errors**  | 500 Internal Server Error, 503 Service Unavailable | Show “Server unavailable”, maybe retry later     |
| **Client Errors**  | 400 Bad Request, 401 Unauthorized                  | Show appropriate message, prompt login if needed |
| **Parsing Errors** | JSON decode failure                                | Log error, show generic error message            |
| **Unknown Errors** | Anything unexpected                                | Show generic “Something went wrong” message      |

---

## **2. Use a Structured API Response Handling**

Define an **enum for API errors**:

```swift
enum APIError: Error, LocalizedError {
    case network
    case server(statusCode: Int)
    case unauthorized
    case decoding
    case unknown

    var errorDescription: String? {
        switch self {
        case .network:
            return "Please check your internet connection."
        case .server(let statusCode):
            return "Server error occurred. Code: \(statusCode)"
        case .unauthorized:
            return "You are not authorized. Please login again."
        case .decoding:
            return "Failed to process data from the server."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
```

---

## **3. Centralize Network Calls**

Use a **network manager** to handle API calls and errors consistently:

```swift
import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}

    func fetchData<T: Decodable>(from url: URL, completion: @escaping (Result<T, APIError>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            
            if let _ = error {
                completion(.failure(.network))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.unknown))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                guard let data = data else {
                    completion(.failure(.unknown))
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(.decoding))
                }
            case 401:
                completion(.failure(.unauthorized))
            case 500...599:
                completion(.failure(.server(statusCode: httpResponse.statusCode)))
            default:
                completion(.failure(.unknown))
            }
        }.resume()
    }
}
```

---

## **4. Handle Errors in SwiftUI / UIKit**

### **SwiftUI Example:**

```swift
struct ContentView: View {
    @State private var items: [String] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                List(items, id: \.self) { item in
                    Text(item)
                }
            }
            .onAppear(perform: loadData)
            .navigationTitle("Items")
        }
    }

    func loadData() {
        guard let url = URL(string: "https://example.com/items") else { return }

        NetworkManager.shared.fetchData(from: url) { (result: Result<[String], APIError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    self.items = data
                    self.errorMessage = nil
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
```

### **UIKit Example:**

```swift
NetworkManager.shared.fetchData(from: url) { (result: Result<[String], APIError>) in
    DispatchQueue.main.async {
        switch result {
        case .success(let data):
            self.items = data
        case .failure(let error):
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
```

---

## **5. Best Practices**

1. **Always show user-friendly messages** instead of raw errors.
2. **Retry logic**: Retry network requests for transient errors (like timeouts).
3. **Logging**: Log errors for debugging (but avoid showing raw errors to users).
4. **Use Combine or async/await** for cleaner code in Swift 5.5+:

```swift
do {
    let data: [String] = try await NetworkManager.shared.fetchData(from: url)
} catch {
    self.errorMessage = error.localizedDescription
}
```

5. **Handle unauthorized errors gracefully**: Redirect to login if 401 occurs.
6. **Fallback UI**: Show a placeholder view if data cannot load.

---

If you want, I can create a **full SwiftUI example with async/await, retry logic, and graceful error UI** that’s production-ready. It’s a very clean modern approach for iOS 15+.

Do you want me to do that?
Great! Let’s build a **modern, production-ready SwiftUI example** for handling API errors gracefully using **async/await**, **retry logic**, and a **clean error UI**. This approach works best with iOS 15+.
                                                                    
---
                                                                    
## **1. Define APIError**
                                                                    
We start by defining structured, user-friendly errors:
                                                                        
```swift
import Foundation
                                                                    
enum APIError: Error, LocalizedError {
case network
case server(statusCode: Int)
case unauthorized
case decoding
case unknown
    
    var errorDescription: String? {
        switch self {
        case .network:
            return "Please check your internet connection."
        case .server(let code):
            return "Server error occurred. Code: \(code)"
        case .unauthorized:
            return "You are not authorized. Please login again."
        case .decoding:
            return "Failed to process data from the server."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
```

---

## **2. NetworkManager with Async/Await and Retry**

```swift
import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    func fetchData<T: Decodable>(from url: URL, retries: Int = 2) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    return decoded
                } catch {
                    throw APIError.decoding
                }
            case 401:
                throw APIError.unauthorized
            case 500...599:
                throw APIError.server(statusCode: httpResponse.statusCode)
            default:
                throw APIError.unknown
            }
        } catch {
            if retries > 0 {
                // Retry after 1 second
                try await Task.sleep(nanoseconds: 1_000_000_000)
                return try await fetchData(from: url, retries: retries - 1)
            } else if (error as? URLError) != nil {
                throw APIError.network
            } else {
                throw APIError.unknown
            }
        }
    }
}
```

✅ Features:

* Uses `async/await` for clean asynchronous code.
* Implements **retry logic** for transient errors.
* Converts common errors into **user-friendly messages**.
                            
---
                            
## **3. SwiftUI ViewModel**
                            
Use `ObservableObject` to manage state and errors:
                                
```swift
import SwiftUI
                            
@MainActor
class ItemsViewModel: ObservableObject {
    @Published var items: [String] = []
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    func loadData() async {
        guard let url = URL(string: "https://example.com/items") else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let data: [String] = try await NetworkManager.shared.fetchData(from: url)
            self.items = data
        } catch let apiError as APIError {
            self.errorMessage = apiError.localizedDescription
        } catch {
            self.errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
```

---

## **4. SwiftUI View**

```swift
struct ContentView: View {
    @StateObject private var viewModel = ItemsViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await viewModel.loadData()
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                } else {
                    List(viewModel.items, id: \.self) { item in
                        Text(item)
                    }
                }
            }
            .navigationTitle("Items")
            .task {
                await viewModel.loadData()
            }
        }
    }
}
```

---

## **✅ Key Features**

1. **Async/Await** for readable, modern asynchronous code.
2. **Retry logic** automatically retries failed network requests.
3. **Graceful error handling** with user-friendly messages.
4. **Loading state** via `ProgressView`.
5. **Retry button** to let the user attempt again.
6. Fully **MainActor safe**, so all UI updates happen on the main thread.
                        
---
                        
This pattern is **production-ready**, clean, and works well with SwiftUI apps that consume network APIs.
                        
---
