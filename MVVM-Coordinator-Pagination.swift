//
//  MVVM-Coordinator-Pagination.swift
//  
//
//  Created by Apple on 18/10/25.
//

import Foundation

Below is a detailed, production‑grade sketch of how you could build a **SwiftUI + MVVM + Coordinator + pagination + concurrency** networking layer in **Swift 6**, with proper error handling, retries, caching, etc. Think of this as a blueprint you can adapt (you’ll need to fill in some pieces to suit your API, models, etc.).

Because this is a large architecture, I’ll break it into parts:

* Networking & caching / retry layer
* Models / DTOs
* Repository / Data layer
* ViewModels
* Views
* Coordinator / Navigation
* App startup / dependency wiring
* Notes on edge cases, testability, improvements

You can take this as a strong template to evolve. (If you want a fully runnable sample repo, I can build one too.)

---

## 1. Networking + Caching + Retry Layer

First, define a robust networking abstraction. Use async/await, structured concurrency, and incorporate caching and retry policies.

```swift
import Foundation
import os

/// A protocol for caching fetched decodable data (in-memory, disk, etc).
protocol Cache {
    func get<T: Decodable>(forKey key: String, as type: T.Type) async -> T?
    func set<T: Encodable>(_ value: T, forKey key: String) async
}

/// Simple in-memory cache (could be replaced by disk or sqlite etc)
actor InMemoryCache: Cache {
    private var storage: [String: Data] = [:]
    func get<T: Decodable>(forKey key: String, as type: T.Type) async -> T? {
        guard let data = storage[key] else { return nil }
        do {
            let v = try JSONDecoder().decode(T.self, from: data)
            return v
        } catch {
            return nil
        }
    }
    func set<T: Encodable>(_ value: T, forKey key: String) async {
        do {
            let data = try JSONEncoder().encode(value)
            storage[key] = data
        } catch {
            // ignore
        }
    }
}

/// A simple retry policy
struct RetryPolicy {
    let maxRetries: Int
    let baseDelay: TimeInterval  // e.g. 0.5s, 1s, exponential
    
    func shouldRetry(attempt: Int, for error: Error) -> Bool {
        return attempt < maxRetries
    }
    
    func delay(for attempt: Int) -> TimeInterval {
        // exponential backoff
        return baseDelay * pow(2.0, Double(attempt))
    }
}

/// Core HTTP client
struct HTTPClient {
    let session: URLSession
    let cache: Cache?
    let retryPolicy: RetryPolicy
    let logger = Logger(subsystem: "com.myapp.network", category: "HTTPClient")
    
    init(session: URLSession = .shared,
         cache: Cache? = nil,
         retryPolicy: RetryPolicy = RetryPolicy(maxRetries: 2, baseDelay: 0.5)) {
        self.session = session
        self.cache = cache
        self.retryPolicy = retryPolicy
    }
    
    /// Generic GET
    func get<T: Decodable>(url: URL,
                           useCache: Bool = true) async throws -> T {
        let cacheKey = url.absoluteString
        
        // Try cache first
        if useCache, let cache = cache {
            if let cached: T = await cache.get(forKey: cacheKey, as: T.self) {
                logger.debug("Cache hit for \(cacheKey)")
                return cached
            }
        }
        
        var attempt = 0
        var lastError: Error?
        while true {
            do {
                let (data, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard (200 ..< 300).contains(http.statusCode) else {
                    throw HTTPError.status(code: http.statusCode, data: data)
                }
                let decoded = try JSONDecoder().decode(T.self, from: data)
                
                // Cache result
                if useCache, let cache = cache {
                    await cache.set(decoded, forKey: cacheKey)
                }
                return decoded
            } catch {
                lastError = error
                if retryPolicy.shouldRetry(attempt: attempt, for: error) {
                    let delayTime = retryPolicy.delay(for: attempt)
                    logger.debug("Retrying \(url) in \(delayTime) seconds, attempt \(attempt)")
                    try await Task.sleep(nanoseconds: UInt64(delayTime * 1_000_000_000))
                    attempt += 1
                    continue
                } else {
                    logger.error("Request failed for \(url): \(error.localizedDescription)")
                    throw error
                }
            }
        }
    }
}

/// Custom error for HTTP status codes
enum HTTPError: Error {
    case status(code: Int, data: Data)
}
```

This gives you a flexible HTTP client you can inject into higher layers. It supports caching, retries, and proper error propagation.

You might consider adding cancellation support, request timeouts, circuit breakers, etc, but this is a solid foundation.

---

## 2. Models / DTOs

Define your DTOs (data transfer objects) matching your API response, and map them (if needed) to domain models.

```swift
struct PagingInfo: Decodable {
    let currentPage: Int
    let totalPages: Int
    let hasNextPage: Bool
    // use coding keys if different key names
    
    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case totalPages = "total_pages"
        case hasNextPage = "has_next_page"
    }
}

struct ApiResponse<Item: Decodable>: Decodable {
    let data: [Item]
    let paging: PagingInfo
}

struct ItemDTO: Decodable, Identifiable {
    let id: Int
    let title: String
    // other fields...
}

// Domain model (if you want a clean separation)
struct ItemModel: Identifiable {
    let id: Int
    let title: String
}
```

If your API has nested envelopes, adapt accordingly.

---

## 3. Repository / Data Layer

This layer coordinates HTTPClient and caching logic, and offers a clean API to ViewModels.

```swift
protocol ItemRepository {
    /// Fetch a page of items
    func fetchPage(page: Int, pageSize: Int) async throws -> (items: [ItemModel], paging: PagingInfo)
    /// Optionally, clear cache or prefetch
}

final class ItemRepositoryImpl: ItemRepository {
    private let http: HTTPClient
    private let baseURL: URL
    
    init(http: HTTPClient, baseURL: URL) {
        self.http = http
        self.baseURL = baseURL
    }
    
    func fetchPage(page: Int, pageSize: Int) async throws -> (items: [ItemModel], paging: PagingInfo) {
        var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)")
        ]
        guard let url = comps.url else {
            throw URLError(.badURL)
        }
        let dto: ApiResponse<ItemDTO> = try await http.get(url: url, useCache: false)
        // Map DTO -> domain model
        let mapped = dto.data.map { ItemModel(id: $0.id, title: $0.title) }
        return (mapped, dto.paging)
    }
}
```

You might also add caching at repository level, e.g. cache entire pages, or combine with local DB (CoreData or SQLite) for offline support.

---

## 4. ViewModel with Pagination & Concurrency

Here’s a `ViewModel` for a view that lists items with infinite scroll / pagination.

```swift
import Foundation
import SwiftUI

@MainActor
final class ItemListViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loadedAll
        case error(Error)
    }

    @Published private(set) var items: [ItemModel] = []
    @Published private(set) var state: State = .idle
    
    private let repo: ItemRepository
    private let pageSize: Int
    private var currentPage: Int = 1
    private var hasNextPage: Bool = true
    private var isLoadingPage: Bool = false
    
    init(repo: ItemRepository, pageSize: Int = 20) {
        self.repo = repo
        self.pageSize = pageSize
    }
    
    func reload() async {
        // Reset
        currentPage = 1
        hasNextPage = true
        items = []
        state = .idle
        await loadNextIfNeeded()
    }
    
    func loadNextIfNeeded(currentItem: ItemModel? = nil) async {
        guard hasNextPage, !isLoadingPage else { return }
        if let current = currentItem {
            // If this is not close to the end, skip
            guard items.last?.id == current.id else { return }
        }
        isLoadingPage = true
        state = .loading
        
        do {
            let result = try await repo.fetchPage(page: currentPage, pageSize: pageSize)
            items.append(contentsOf: result.items)
            currentPage += 1
            hasNextPage = result.paging.hasNextPage
            if !hasNextPage {
                state = .loadedAll
            } else {
                state = .idle
            }
        } catch {
            state = .error(error)
        }
        isLoadingPage = false
    }
}
```

Key points:

* `@MainActor` ensures UI updates happen on main thread.
* `loadNextIfNeeded(currentItem:)` is called from the view when a cell appears — if that cell is the last cell, we trigger loading next page.
* `reload()` can be used for pull-to-refresh.
* State enum tracks whether you're loading or error, etc.

You could improve this by queuing multiple concurrent page loads, cancellation support, using `Task { }` with cancellation, etc.

---

## 5. Views (SwiftUI)

Here is how you wire the view to the viewModel:

```swift
import SwiftUI

struct ItemListView: View {
    @StateObject var viewModel: ItemListViewModel
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.items) { item in
                    Text(item.title)
                        .onAppear {
                            Task {
                                await viewModel.loadNextIfNeeded(currentItem: item)
                            }
                        }
                }
                
                // Footer: show loading indicator or error
                switch viewModel.state {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                case .error(let err):
                    VStack {
                        Text("Failed: \(err.localizedDescription)")
                        Button("Retry") {
                            Task {
                                await viewModel.loadNextIfNeeded()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Items")
            .refreshable {
                await viewModel.reload()
            }
            .task {
                // initial load
                await viewModel.loadNextIfNeeded()
            }
        }
    }
}
```

This is a basic list with infinite scroll and pull-to-refresh behavior.

You can further decorate with placeholders, empty states, error overlays, etc.

---

## 6. Coordinator / Navigation

In SwiftUI, with iOS 16+, we have `NavigationStack` and `NavigationPath` which you can integrate with a coordinator to isolate navigation logic. The coordinator holds the navigation path/state, and views bind to it.

Here’s a minimal coordinator pattern:

```swift
import SwiftUI

enum Route: Hashable {
    case detail(item: ItemModel)
    // add other routes if needed
}

final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func showDetail(item: ItemModel) {
        path.append(Route.detail(item: item))
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}

// Root view that uses the coordinator
struct CoordinatorRootView: View {
    @StateObject var coordinator = AppCoordinator()
    let repo: ItemRepository
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            let vm = ItemListViewModel(repo: repo)
            ItemListView(viewModel: vm)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .detail(let item):
                        ItemDetailView(item: item)
                    }
                }
                // Also inject coordinator to child views (e.g. via environment)
                .environmentObject(coordinator)
        }
    }
}

// Example detail view
struct ItemDetailView: View {
    let item: ItemModel
    var body: some View {
        VStack {
            Text(item.title)
                .font(.largeTitle)
            // more UI
        }
        .navigationTitle("Detail")
    }
}

// In ItemListView, when tapping, tell coordinator to navigate
extension ItemListView {
    func makeRow(item: ItemModel) -> some View {
        Button(action: {
            // navigate
            // this view probably has access to coordinator via .environmentObject
        }) {
            Text(item.title)
        }
    }
}
```

Better practice is to inject coordinator into your view models (or wrap views so they only know an “onSelect: (ItemModel) -> Void” callback, which the coordinator provides). The views itself shouldn’t know how to navigate directly — they should call back to the coordinator (or a closure) to do the navigation.

You can refine this pattern further (child coordinators, flows, deep linking, etc).

---

## 7. App Startup / Dependency Injection

In your `@main` App file, wire things together:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            let cache = InMemoryCache()
            let http = HTTPClient(session: .shared, cache: cache)
            let baseURL = URL(string: "https://api.myserver.com/items")!
            let repo = ItemRepositoryImpl(http: http, baseURL: baseURL)
            CoordinatorRootView(repo: repo)
        }
    }
}
```

You could also use a DI container (Swinject, Resolver, etc) for bigger apps.

---

## 8. Edge Cases, Improvements & Further Considerations

Here’s a non‑exhaustive list of production considerations:

* **Cancellation**: Use `Task` and pass around `Task.Handle` so you can cancel in-flight requests (e.g. when view disappears or user navigates away).
* **Concurrency & Actors**: Use actors to protect mutable state, isolate side effects. E.g. your cache is actor, your repository could have internal concurrent limits.
* **Prefetching**: You might want to start loading the next page before the user reaches the last cell — e.g. when current appears and you have N items remaining.
* **Memory / disk caching**: For large data sets, consider using disk cache (e.g. SQLite, CoreData) or file cache so that app relaunch doesn’t refetch.
* **Offline support**: If API fails and you have cached pages, serve cache fallback instead of failing fully.
* **Error classification & user feedback**: Distinguish network errors, data errors, server errors. Show friendly messages, retry UI, fallback.
* **Exponential backoff / jitter** in retry policy to avoid thundering herd.
* **Concurrency limits**: If multiple page loads or parallel loads, you may want to limit concurrency (e.g. only one page load at a time, or limit to 2 concurrent).
* **Testing / mocks**: Make HTTPClient, Repository injectable so you can mock for unit tests.
* **Logging & metrics**: Log network calls, durations, errors — use os.Logger or your preferred logger.
* **Pagination parameter flexibility**: Some APIs use offset/limit instead of page, or cursor-based paging (next token). Your repository should abstract that.
* **Deep linking & state restoration**: Coordinator should support restoring navigation state when app cold-starts.
* **Memory leaks / retain cycles**: Be careful if view models hold strong references to coordinator or vice versa; use weak references or decoupled closures.
* **Loading indicators / skeleton UIs**: Instead of showing blank view, show skeleton placeholders until first load finishes.
* **Rate limiting / throttling**: If API has rate limits, back off accordingly.

---

## 9. Full Combined Example (Skeleton)

Here’s a more integrated code snippet bringing pieces together:

```swift
// — HTTPClient, Cache, RetryPolicy, HTTPError as above —

// Models
struct PagingInfo: Decodable { ... }
struct ApiResponse<Item: Decodable>: Decodable { ... }
struct ItemDTO: Decodable, Identifiable { … }
struct ItemModel: Identifiable { … }

// Repository
protocol ItemRepository { … }
final class ItemRepositoryImpl: ItemRepository { … }

// ViewModel
@MainActor
final class ItemListViewModel: ObservableObject {
    @Published var items: [ItemModel] = []
    @Published var state: State = .idle
    
    private let repo: ItemRepository
    private let pageSize: Int
    private var currentPage = 1
    private var hasNextPage = true
    private var isLoading = false
    
    init(repo: ItemRepository, pageSize: Int = 20) {
        self.repo = repo
        self.pageSize = pageSize
    }
    
    func reload() async {
        currentPage = 1
        hasNextPage = true
        items = []
        state = .idle
        await loadNextIfNeeded()
    }
    
    func loadNextIfNeeded(currentItem: ItemModel? = nil) async {
        guard hasNextPage, !isLoading else { return }
        if let c = currentItem {
            guard items.last?.id == c.id else { return }
        }
        isLoading = true
        state = .loading
        do {
            let (newItems, paging) = try await repo.fetchPage(page: currentPage, pageSize: pageSize)
            items.append(contentsOf: newItems)
            currentPage += 1
            hasNextPage = paging.hasNextPage
            state = hasNextPage ? .idle : .loadedAll
        } catch {
            state = .error(error)
        }
        isLoading = false
    }
}

// Views & Coordinator
enum Route: Hashable {
    case detail(item: ItemModel)
}

final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    func showDetail(_ item: ItemModel) {
        path.append(Route.detail(item: item))
    }
    func pop() { path.removeLast() }
}

struct CoordinatorRootView: View {
    @StateObject var coordinator = AppCoordinator()
    let repo: ItemRepository
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            let vm = ItemListViewModel(repo: repo)
            ItemListView(viewModel: vm)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .detail(let item):
                        ItemDetailView(item: item)
                    }
                }
                .environmentObject(coordinator)
        }
    }
}

struct ItemListView: View {
    @StateObject var viewModel: ItemListViewModel
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                Button(action: {
                    coordinator.showDetail(item)
                }) {
                    Text(item.title)
                }
                .onAppear {
                    Task {
                        await viewModel.loadNextIfNeeded(currentItem: item)
                    }
                }
            }
            switch viewModel.state {
            case .loading:
                ProgressView().frame(maxWidth: .infinity)
            case .error(let err):
                VStack {
                    Text("Error: \(err.localizedDescription)")
                    Button("Retry") {
                        Task {
                            await viewModel.loadNextIfNeeded()
                        }
                    }
                }.frame(maxWidth: .infinity)
            default:
                EmptyView()
            }
        }
        .navigationTitle("Items")
        .refreshable {
            await viewModel.reload()
        }
        .task {
            await viewModel.loadNextIfNeeded()
        }
    }
}

struct ItemDetailView: View {
    let item: ItemModel
    var body: some View {
        Text("Detail: \(item.title)")
            .navigationTitle("Detail")
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            let cache = InMemoryCache()
            let http = HTTPClient(session: .shared, cache: cache)
            let repo = ItemRepositoryImpl(http: http, baseURL: URL(string: "https://api.example.com/items")!)
            CoordinatorRootView(repo: repo)
        }
    }
}
```

This is sufficiently modular: HTTP client, repository, viewmodels, coordinator.

---

If you like, I can convert this into a fully working Xcode sample (with sample API or mock) and share. Do you want me to build that for you?
