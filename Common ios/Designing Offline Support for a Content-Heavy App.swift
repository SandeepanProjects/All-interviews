//
//  Designing Offline Support for a Content-Heavy App.swift
//  
//
//  Created by Apple on 11/01/26.
//

import Foundation

Below is a **practical, senior-level answer** covering **offline-first design for a content-heavy app** and a **clean Swift implementation for periodic ETA fetching every 10 seconds** using modern concurrency.

---

# 1️⃣ Designing Offline Support for a Content-Heavy App

Think **offline-first**, not “offline as a fallback”.

---

## A. Core Principles

1. **Local storage is the source of truth**
2. **Network augments local data, never blocks UX**
3. **Sync is incremental and resumable**
4. **UI always renders from cache**

---

## B. Architecture (Recommended)

```
UI (SwiftUI)
↓
ViewModel
↓
Repository
↓            ↓
Local Store   Remote API
(Core Data)  (URLSession)
```

The **Repository** decides:

* When to read cache
* When to fetch remote
* How to merge data

---

## C. Data Strategy for Content-Heavy Apps

### 1️⃣ Store Content Locally

* Metadata (titles, thumbnails)
* Content bodies (articles, descriptions)
* Media references (local file URLs)

Use:

* **Core Data / SQLite** for structured data
* **File system** for large media (images/video)

---

### 2️⃣ Partial & Lazy Loading

* List view → metadata only
* Detail view → load full content
* Media → downloaded on demand

This keeps memory usage low.

---

### 3️⃣ Versioning & Staleness

Each content item has:

```swift
lastUpdated: Date
```

Use:

* TTL (e.g., refresh if older than 24h)
* Server-provided version or ETag

---

### 4️⃣ Sync Flow

**On app launch / resume**

1. Load cached content immediately
2. Check connectivity
3. Fetch deltas from API
4. Merge into local DB
5. UI updates automatically

---

### 5️⃣ Offline Actions Queue

For user actions (likes, bookmarks):

```swift
PendingAction {
    id
    type
    timestamp
}
```

* Stored locally
* Synced when network returns
* Idempotent API calls

---

### 6️⃣ Background Refresh

* `BGAppRefreshTask`
* Pre-fetch new content
* Update local DB
* Notify user via push if needed

---

### Interview soundbite

> “For content-heavy apps, I design an offline-first repository where the UI always reads from local storage and network sync happens transparently in the background.”

---

# 2️⃣ Implementing Periodic ETA Fetching (Every 10 Seconds)

This is a **polling problem**, but it must be:

* cancellable
* background-safe
* not leak memory

---

## A. Best Approach: Swift Concurrency + Task

### ETA Service

```swift
protocol ETAService {
    func fetchETA() async throws -> TimeInterval
}
```

---

## B. ETA Poller (10-Second Interval)

```swift
final class ETAPoller {

    private var task: Task<Void, Never>?

    func start(
        interval: TimeInterval = 10,
        fetch: @escaping () async -> Void
    ) {
        task?.cancel()

        task = Task {
            while !Task.isCancelled {
                await fetch()
                try? await Task.sleep(
                    nanoseconds: UInt64(interval * 1_000_000_000)
                )
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
```

---

## C. Usage in ViewModel

```swift
@MainActor
final class RideViewModel: ObservableObject {

    @Published var eta: TimeInterval?
    private let poller = ETAPoller()
    private let service: ETAService

    init(service: ETAService) {
        self.service = service
    }

    func startFetchingETA() {
        poller.start {
            do {
                let eta = try await self.service.fetchETA()
                self.eta = eta
            } catch {
                // Handle error silently or log
            }
        }
    }

    func stopFetchingETA() {
        poller.stop()
    }
}
```

---

## D. SwiftUI Lifecycle Integration

```swift
.onAppear {
    viewModel.startFetchingETA()
}
.onDisappear {
    viewModel.stopFetchingETA()
}
```

---

## E. Important Optimizations

* Pause polling when:

  * App goes to background
  * Network is unavailable
* Use exponential backoff on failures
* Cap retries to avoid battery drain

---

### Interview soundbite

> “I implement periodic fetching using a cancellable Task loop with `Task.sleep`, ensuring it stops when the view disappears or the app backgrounds.”

---

# Key Takeaways

### Offline Support

✔ Local-first storage
✔ Incremental sync
✔ Background refresh
✔ Transparent UX

### ETA Polling

✔ Cancellable tasks
✔ 10-second interval
✔ Lifecycle-aware
✔ Battery-conscious

---

If you want next:

* Background-safe ETA updates
* Combine-based polling
* Adaptive polling intervals
* Offline ETA fallback strategy
