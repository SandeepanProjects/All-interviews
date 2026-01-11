//
//  display a list of files:folders.swift
//  
//
//  Created by Apple on 11/01/26.
//

import Foundation

Below is a **compact but production-grade design + implementation sketch** for a *Files & Folders list with search + refresh*, written in **SwiftUI with modern concurrency**, and structured for **clean architecture, testability, and future cloud sync**.

I’ll break it into **4 layers** and then discuss **sync performance, caching, offline**, and **decoupling**.

---

# 1. Architecture Overview (Clean & Maintainable)

Use a **Clean Architecture / MVVM-ish** split:

```
┌──────────────┐
│   SwiftUI    │  ← View (stateless)
└──────┬───────┘
       │
┌──────▼───────┐
│  ViewModel   │  ← State + user intent
└──────┬───────┘
       │
┌──────▼───────┐
│   UseCases   │  ← Business logic
└──────┬───────┘
       │
┌──────▼───────┐
│ Repositories │  ← API / cache / disk
└──────────────┘
```

**Key goals**

* SwiftUI views stay dumb
* Networking + caching isolated
* Easy to swap API / mock data
* Async/await everywhere

---

# 2. Domain Model

```swift
enum FileType {
    case file
    case folder
}

struct FileItem: Identifiable, Hashable {
    let id: String
    let name: String
    let type: FileType
    let modifiedAt: Date
}
```

---

# 3. Repository Layer (API + Cache)

### Protocol (decoupling 🔑)

```swift
protocol FileRepository {
    func fetchFiles() async throws -> [FileItem]
}
```

### API implementation

```swift
final class RemoteFileRepository: FileRepository {
    func fetchFiles() async throws -> [FileItem] {
        // Simulated API delay
        try await Task.sleep(nanoseconds: 500_000_000)

        return [
            FileItem(id: "1", name: "Documents", type: .folder, modifiedAt: .now),
            FileItem(id: "2", name: "Resume.pdf", type: .file, modifiedAt: .now)
        ]
    }
}
```

### Cached decorator (performance & offline)

```swift
final class CachedFileRepository: FileRepository {
    private let remote: FileRepository
    private var cache: [FileItem] = []

    init(remote: FileRepository) {
        self.remote = remote
    }

    func fetchFiles() async throws -> [FileItem] {
        do {
            let fresh = try await remote.fetchFiles()
            cache = fresh
            return fresh
        } catch {
            if !cache.isEmpty {
                return cache // offline fallback
            }
            throw error
        }
    }
}
```

➡️ This decorator pattern lets you **add caching without touching UI or business logic**.

---

# 4. Use Case Layer

```swift
protocol FetchFilesUseCase {
    func execute() async throws -> [FileItem]
}

final class FetchFilesUseCaseImpl: FetchFilesUseCase {
    private let repository: FileRepository

    init(repository: FileRepository) {
        self.repository = repository
    }

    func execute() async throws -> [FileItem] {
        try await repository.fetchFiles()
    }
}
```

---

# 5. ViewModel (Swift Concurrency + Search)

```swift
@MainActor
final class FileListViewModel: ObservableObject {
    @Published private(set) var files: [FileItem] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var error: String?

    private let fetchFiles: FetchFilesUseCase

    init(fetchFiles: FetchFilesUseCase) {
        self.fetchFiles = fetchFiles
    }

    var filteredFiles: [FileItem] {
        guard !searchText.isEmpty else { return files }
        return files.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            files = try await fetchFiles.execute()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func refresh() async {
        await load()
    }
}
```

---

# 6. SwiftUI View

```swift
struct FileListView: View {
    @StateObject private var viewModel: FileListViewModel

    init(viewModel: FileListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List(viewModel.filteredFiles) { item in
                HStack {
                    Image(systemName: item.type == .folder ? "folder" : "doc")
                    Text(item.name)
                }
            }
            .navigationTitle("Files")
            .searchable(text: $viewModel.searchText)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.load()
            }
        }
    }
}
```

---

# 7. Dependency Wiring (Composition Root)

```swift
let remoteRepo = RemoteFileRepository()
let cachedRepo = CachedFileRepository(remote: remoteRepo)
let useCase = FetchFilesUseCaseImpl(repository: cachedRepo)

FileListView(viewModel: FileListViewModel(fetchFiles: useCase))
```

---

# 8. Improving File Sync Performance 🚀

### a) Delta sync (most important)

* Sync only files changed since last timestamp
* Use:

  * `modifiedAt`
  * server-side cursors
  * ETags / version IDs

```text
GET /files?since=lastSyncTime
```

---

### b) Parallel downloads

Use `TaskGroup` for multiple files:

```swift
await withTaskGroup(of: Void.self) { group in
    for file in files {
        group.addTask {
            await download(file)
        }
    }
}
```

---

### c) Background sync

* Use **BGTaskScheduler**
* Sync when:

  * Wi-Fi available
  * Device charging

---

### d) Priority-based sync

* Folders metadata first
* Recently accessed files first
* Large files last

---

# 9. Caching Strategy

### Multi-level cache

1. **Memory** (fast UI)
2. **Disk** (offline)
3. **Remote**

### Suggested storage

* SQLite / Core Data for metadata
* File system for binary data

```text
UI → Memory → Disk → Network
```

---

# 10. Offline Support

* App launches from local DB
* Changes queued locally
* Sync engine reconciles later

```swift
struct PendingOperation {
    let fileID: String
    let action: SyncAction // upload, delete, rename
}
```

Handle conflicts with:

* last-write-wins
* user resolution UI
* version history

---

# 11. Module Decoupling (Scales Well)

Split into Swift Packages:

```
FileDomain
FileUseCases
FileRepository
FileUI
```

Benefits:

* Independent testing
* Faster builds
* Team scalability

---

# Final Takeaway

> **A clean SwiftUI feature is built by isolating UI, business logic, and data access, using async/await end-to-end, layering caching, and designing sync as a delta-based, background, conflict-aware system.**

If you want, I can:

* add Core Data implementation
* design the sync state machine
* show unit tests for ViewModel & UseCases
* extend this into a full Dropbox-style sync engine
