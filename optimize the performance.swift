//
//  optimize the performance.swift
//  
//
//  Created by Apple on 17/08/25.
//

import Foundation

Absolutely! Let's walk through building a **SwiftUI app that displays a large list using MVVM, Swift Concurrency**, and the **SOLID principles** — a professional, scalable architecture for production-quality iOS apps.

---

## ✅ Goal:

Build a SwiftUI app that:

* Displays thousands of items (paginated)
* Uses **MVVM** (Model-View-ViewModel)
* Applies **SOLID principles**
* Uses **Swift Concurrency**
* Uses **AsyncImage** for image loading

---

## 🧱 Architecture Overview (MVVM + SOLID)

| Layer         | Responsibility                   | SOLID Focus                |
| ------------- | -------------------------------- | -------------------------- |
| **Model**     | Plain structs, no logic          | Single Responsibility      |
| **Service**   | Data fetching, no view knowledge | Interface Segregation, DIP |
| **ViewModel** | UI-independent business logic    | Open/Closed, Liskov        |
| **View**      | Displays UI only                 | Single Responsibility      |

---

## 🔹 Step 1: Model (S — Single Responsibility)

```swift
struct Item: Identifiable, Hashable {
    let id: Int
    let title: String
    let imageUrl: String
}
```

---

## 🔹 Step 2: Data Layer (D — Dependency Inversion)

### Protocol for the service layer:

```swift
protocol ItemFetching {
    func fetchItems(page: Int, pageSize: Int) async throws -> [Item]
}
```

### Concrete implementation (simulated API):

```swift
final class ItemService: ItemFetching {
    func fetchItems(page: Int, pageSize: Int) async throws -> [Item] {
        try await Task.sleep(nanoseconds: 1_000_000_000) // simulate network delay
        
        let start = page * pageSize
        return (start..<start + pageSize).map { index in
            Item(
                id: index,
                title: "Item \(index)",
                imageUrl: "https://picsum.photos/id/\(index % 1000)/100/100"
            )
        }
    }
}
```

* ✅ **Dependency Inversion Principle (DIP)**: Business logic depends on an abstraction (`ItemFetching`), not a concrete class.

---

## 🔹 Step 3: ViewModel (O, L — Open/Closed, Liskov)

```swift
@MainActor
final class ItemListViewModel: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private let service: ItemFetching
    private var currentPage = 0
    private let pageSize = 20
    private var hasMore = true
    
    init(service: ItemFetching) {
        self.service = service
    }
    
    func loadInitialItems() {
        currentPage = 0
        items.removeAll()
        hasMore = true
        Task {
            await loadMoreItems()
        }
    }
    
    func loadMoreItems() async {
        guard !isLoading && hasMore else { return }
        isLoading = true
        
        do {
            let newItems = try await service.fetchItems(page: currentPage, pageSize: pageSize)
            if newItems.isEmpty {
                hasMore = false
            } else {
                items.append(contentsOf: newItems)
                currentPage += 1
            }
        } catch {
            errorMessage = "Failed to load items: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
```

* ✅ **Open/Closed**: ViewModel can be extended or tested without modifying.
* ✅ **Liskov Substitution**: `ItemFetching` can be replaced with mocks in tests.

---

## 🔹 Step 4: View (S — Single Responsibility)

### `ItemRow`:

```swift
struct ItemRow: View {
    let item: Item
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: item.imageUrl)) { image in
                image.resizable()
            } placeholder: {
                Color.gray
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(item.title)
                .font(.headline)
                .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
}
```

---

### `ItemListView`:

```swift
struct ItemListView: View {
    @StateObject private var viewModel: ItemListViewModel
    
    init(viewModel: ItemListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.items) { item in
                        ItemRow(item: item)
                            .onAppear {
                                if item == viewModel.items.last {
                                    Task {
                                        await viewModel.loadMoreItems()
                                    }
                                }
                            }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Items")
            .onAppear {
                viewModel.loadInitialItems()
            }
        }
    }
}
```

---

## 🔹 Step 5: App Entry Point

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            let service = ItemService()
            let viewModel = ItemListViewModel(service: service)
            ItemListView(viewModel: viewModel)
        }
    }
}
```

---

## ✅ Benefits from SOLID Principles

| SOLID Principle               | Applied Where                                 |
| ----------------------------- | --------------------------------------------- |
| **S - Single Responsibility** | Views show UI only, ViewModel handles logic   |
| **O - Open/Closed**           | ViewModel and services can be extended safely |
| **L - Liskov Substitution**   | `ItemFetching` can be replaced in tests       |
| **I - Interface Segregation** | Only essential methods in `ItemFetching`      |
| **D - Dependency Inversion**  | ViewModel depends on protocol, not concrete   |

---

## 🔍 Next Steps

Want to:

* Add error handling UI?
* Add pull-to-refresh?
* Inject a **mock service for unit testing**?
* Use Combine or async streams for more reactivity?

Let me know what you'd like to extend next.

Great — let’s take this architecture further with **mock service injection for unit testing**, and then explore how to **replace async/await with Combine or AsyncStream** for more reactive control.
                                
                                ---
                                
## ✅ Part 1: **Inject a Mock Service for Unit Testing**
                                
### 🔹 Why?
                                
* So you can test your `ItemListViewModel` without relying on real network calls.
* Adheres to **Dependency Inversion Principle (D in SOLID)**.
                                
                                ---
                                
### 🧪 Step-by-step Mock Injection
                                
#### 1. Your `ItemFetching` protocol (already created):
                                    
```swift
protocol ItemFetching {
    func fetchItems(page: Int, pageSize: Int) async throws -> [Item]
}
```

#### 2. Create a **MockItemService** for testing:
                                                
                                                ```swift
final class MockItemService: ItemFetching {
    var itemsToReturn: [Item]
    var shouldThrowError = false
    
    init(itemsToReturn: [Item] = []) {
        self.itemsToReturn = itemsToReturn
    }
    
    func fetchItems(page: Int, pageSize: Int) async throws -> [Item] {
        if shouldThrowError {
            throw URLError(.badServerResponse)
        }
        return itemsToReturn
    }
}
```

#### 3. Write a test for `ItemListViewModel`
                            
> You’d typically use XCTest in a test target. Here’s a simple manual test you can adapt.
                            
                            ```swift
func test_ViewModelLoadsItemsSuccessfully() async {
    let mockItems = (0..<5).map {
        Item(id: $0, title: "Mock \($0)", imageUrl: "")
    }
    let mockService = MockItemService(itemsToReturn: mockItems)
    let viewModel = ItemListViewModel(service: mockService)
    
    await viewModel.loadMoreItems()
    
    assert(viewModel.items.count == 5, "Expected 5 items, got \(viewModel.items.count)")
}
```

✅ This gives you full **unit testability** of the ViewModel, without touching SwiftUI views.

---

## ✅ Part 2: Use **Combine** or **AsyncStream** for More Reactivity
                                                        
                                                        ---
                                                        
### 🔁 Option A: Use **Combine** (pre-iOS 15 or for reactive patterns)
                                                        
If you want more **observable-style updates**, you could replace `@Published` state with Combine pipelines. Example:
                                                            
                                                            ```swift
final class CombineItemViewModel: ObservableObject {
    @Published private(set) var items: [Item] = []
    private var cancellables = Set<AnyCancellable>()
    
    private let service: ItemFetching
    
    init(service: ItemFetching) {
        self.service = service
    }
    
    func load() {
        Task {
            let publisher = Future { promise in
                Task {
                    do {
                        let data = try await self.service.fetchItems(page: 0, pageSize: 20)
                        promise(.success(data))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
            
            publisher
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] items in
                    self?.items = items
                })
                .store(in: &cancellables)
        }
    }
}
```

✅ Combine gives you cancelation, chaining, debouncing, etc.

---

### 🔁 Option B: Use **AsyncStream** (recommended for Swift Concurrency)

If you want to "stream" data as it arrives (e.g., infinite scrolling or live feeds), use `AsyncStream`.

#### Example: Paged data stream

```swift
func makeItemStream(pageSize: Int = 20) -> AsyncStream<[Item]> {
    var page = 0
    
    return AsyncStream { continuation in
        Task {
            while true {
                do {
                    let data = try await service.fetchItems(page: page, pageSize: pageSize)
                    if data.isEmpty {
                        continuation.finish()
                        break
                    }
                    continuation.yield(data)
                    page += 1
                } catch {
                    continuation.finish()
                    break
                }
            }
        }
    }
}
```

#### In your ViewModel:

```swift
func streamItems() {
    Task {
        for await newItems in makeItemStream() {
            items.append(contentsOf: newItems)
        }
    }
}
```

✅ `AsyncStream` gives you **lazy paging** and a clean way to model long-lived, async sequences.

---

## ✅ Summary

| Feature                | Solution                       | Benefit                            |
| ---------------------- | ------------------------------ | ---------------------------------- |
| Unit testing ViewModel | Inject mock service (protocol) | Fast, reliable tests               |
| More reactive control  | Combine or AsyncStream         | Better for streaming / cancelation |
| Clean architecture     | MVVM + SOLID                   | Scalable and testable              |
                                                                        
                                                                        ---
                                                                        
                                                                      
