//
//  real-time sync.swift
//  
//
//  Created by Apple on 14/04/26.
//

import Foundation

Alright — let’s design a **staff-level real-time sync system** with **production-grade architecture + full Swift code** (client side), covering:

* Offline-first
* Conflict resolution
* Real-time updates (WebSocket)
* Background sync
* Retry + backoff
* Clean Architecture (MVVM + UseCases + Repository)
* Scalable design (like WhatsApp / Slack)

---

# 🧠 1. SYSTEM DESIGN (STAFF LEVEL)

## 🔷 Core Principles

* **Offline-first** → UI always reads from local DB
* **Event-driven sync** → server pushes updates
* **Eventually consistent**
* **Idempotent operations**
* **Conflict resolution (LWW or versioning)**

---

## 🏗️ Architecture Overview

```
UI (SwiftUI)
   ↓
ViewModel (State + Intent)
   ↓
UseCases (Business Logic)
   ↓
Repository (Single Source of Truth)
   ↓
-------------------------------------
| Local DB (CoreData / SQLite)
| Remote API (REST + WebSocket)
-------------------------------------
```

---

## 🔄 Data Flow

### 1. Write Flow

```
User Action → Local DB → Sync Queue → API → Server → WebSocket → Other Clients
```

### 2. Read Flow

```
UI → Local DB (instant)
     ↳ Background sync updates DB
```

---

## 🧩 Key Components

| Component        | Responsibility     |
| ---------------- | ------------------ |
| SyncEngine       | Orchestrates sync  |
| WebSocketManager | Real-time updates  |
| SyncQueue        | Pending operations |
| ConflictResolver | Merge logic        |
| Repository       | Abstracts data     |
| LocalStore       | CoreData           |
| RemoteAPI        | REST               |

---

# 🚀 2. DATA MODELS

```swift
struct Message: Identifiable, Codable, Equatable {
    let id: String
    let text: String
    let createdAt: Date
    let updatedAt: Date
    let version: Int
    let isDeleted: Bool
}
```

---

# 🧱 3. LOCAL STORE (Core Data Wrapper)

```swift
protocol LocalStore {
    func fetchMessages() async throws -> [Message]
    func save(_ messages: [Message]) async
    func upsert(_ message: Message) async
    func pendingSyncItems() async -> [SyncItem]
}
```

---

# 🌐 4. REMOTE API

```swift
protocol RemoteAPI {
    func fetchChanges(since: Date) async throws -> [Message]
    func send(_ item: SyncItem) async throws
}
```

---

# 🔁 5. SYNC ITEM

```swift
struct SyncItem: Codable {
    enum Operation {
        case create, update, delete
    }

    let id: String
    let operation: Operation
    let payload: Message
    let timestamp: Date
}
```

---

# 🧠 6. CONFLICT RESOLUTION

```swift
protocol ConflictResolver {
    func resolve(local: Message, remote: Message) -> Message
}

final class LastWriteWinsResolver: ConflictResolver {
    func resolve(local: Message, remote: Message) -> Message {
        return local.updatedAt > remote.updatedAt ? local : remote
    }
}
```

---

# 🔌 7. WEBSOCKET MANAGER (REAL-TIME)

```swift
import Foundation

final class WebSocketManager {
    private var task: URLSessionWebSocketTask?
    
    var onMessage: ((Message) -> Void)?

    func connect() {
        let url = URL(string: "wss://yourserver.com/ws")!
        task = URLSession.shared.webSocketTask(with: url)
        task?.resume()
        listen()
    }

    private func listen() {
        task?.receive { [weak self] result in
            switch result {
            case .success(.data(let data)):
                if let message = try? JSONDecoder().decode(Message.self, from: data) {
                    self?.onMessage?(message)
                }
            case .failure(let error):
                print("WebSocket error:", error)
            default:
                break
            }
            self?.listen()
        }
    }

    func send(_ message: Message) {
        guard let data = try? JSONEncoder().encode(message) else { return }
        task?.send(.data(data)) { error in
            if let error = error {
                print("Send error:", error)
            }
        }
    }
}
```

---

# 🔄 8. SYNC ENGINE (CORE LOGIC)

```swift
final class SyncEngine {
    private let local: LocalStore
    private let remote: RemoteAPI
    private let resolver: ConflictResolver

    private var isSyncing = false

    init(local: LocalStore, remote: RemoteAPI, resolver: ConflictResolver) {
        self.local = local
        self.remote = remote
        self.resolver = resolver
    }

    func sync() async {
        guard !isSyncing else { return }
        isSyncing = true
        
        do {
            try await pushPending()
            try await pullChanges()
        } catch {
            print("Sync failed:", error)
        }

        isSyncing = false
    }

    private func pushPending() async throws {
        let items = await local.pendingSyncItems()
        
        for item in items {
            try await remote.send(item)
        }
    }

    private func pullChanges() async throws {
        let changes = try await remote.fetchChanges(since: Date().addingTimeInterval(-3600))
        
        for remoteMsg in changes {
            let locals = try await local.fetchMessages()
            if let localMsg = locals.first(where: { $0.id == remoteMsg.id }) {
                let merged = resolver.resolve(local: localMsg, remote: remoteMsg)
                await local.upsert(merged)
            } else {
                await local.upsert(remoteMsg)
            }
        }
    }
}
```

---

# 🗂️ 9. REPOSITORY (SSOT)

```swift
final class MessageRepository {
    private let local: LocalStore
    private let syncEngine: SyncEngine
    
    init(local: LocalStore, syncEngine: SyncEngine) {
        self.local = local
        self.syncEngine = syncEngine
    }

    func messages() async throws -> [Message] {
        return try await local.fetchMessages()
    }

    func send(text: String) async {
        let message = Message(
            id: UUID().uuidString,
            text: text,
            createdAt: Date(),
            updatedAt: Date(),
            version: 1,
            isDeleted: false
        )

        await local.upsert(message)
        await syncEngine.sync()
    }
}
```

---

# 🧑‍💻 10. VIEWMODEL (REAL-TIME UI)

```swift
import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []

    private let repo: MessageRepository
    private let socket: WebSocketManager

    init(repo: MessageRepository, socket: WebSocketManager) {
        self.repo = repo
        self.socket = socket
        
        setupSocket()
        load()
    }

    func load() {
        Task {
            self.messages = (try? await repo.messages()) ?? []
        }
    }

    func send(text: String) {
        Task {
            await repo.send(text: text)
            load()
        }
    }

    private func setupSocket() {
        socket.onMessage = { [weak self] message in
            Task {
                await self?.handleIncoming(message)
            }
        }
        socket.connect()
    }

    private func handleIncoming(_ message: Message) async {
        messages.append(message)
    }
}
```

---

# 🖥️ 11. SWIFTUI UI

```swift
struct ChatView: View {
    @StateObject var vm: ChatViewModel
    @State private var text = ""

    var body: some View {
        VStack {
            List(vm.messages) { msg in
                Text(msg.text)
            }

            HStack {
                TextField("Message", text: $text)
                Button("Send") {
                    vm.send(text: text)
                    text = ""
                }
            }
            .padding()
        }
    }
}
```

---

# ⚡ 12. ADVANCED STAFF-LEVEL IMPROVEMENTS

## 🔥 1. Retry + Backoff

```swift
func retry<T>(
    times: Int = 3,
    delay: Double = 1,
    operation: @escaping () async throws -> T
) async throws -> T {
    var currentDelay = delay
    
    for _ in 0..<times {
        do {
            return try await operation()
        } catch {
            try await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))
            currentDelay *= 2
        }
    }
    throw URLError(.badServerResponse)
}
```

---

## 🔥 2. Background Sync (iOS)

* Use `BGAppRefreshTask`
* Periodic sync even when app closed

---

## 🔥 3. Pagination + Delta Sync

* Use `cursor` instead of timestamp
* Only fetch diffs

---

## 🔥 4. Optimistic UI

* Show message instantly
* Rollback on failure

---

## 🔥 5. Observability

* Logging
* Metrics (sync latency, failure rate)

---

# 🧠 FINAL TAKEAWAY (INTERVIEW GOLD)

If interviewer asks:

👉 “How would you design real-time sync?”

You answer:

* Offline-first architecture
* Local DB as source of truth
* Sync engine (push + pull)
* WebSocket for real-time updates
* Conflict resolution strategy
* Retry + backoff
* Background sync
* Eventual consistency

---

If you want next level:
👉 I can extend this to:

* **WhatsApp-level system (multi-device sync)**
* **CRDT-based conflict resolution**
* **GraphQL subscriptions / Firebase alternative**
* **Full backend (Node / Go / AWS architecture)**

Just tell me 👍

Perfect — this is exactly the kind of thing interviewers expect at **Staff level**: not just concepts, but **production-ready implementation**.
                    
I’ll give you **clean, real-world Swift code** for:
                        
1. ✅ **Background Sync using `BGAppRefreshTask`**
2. ✅ **Pagination + Cursor-based Delta Sync**
3. ✅ Integrated with your **SyncEngine**
                    
                    ---
                    
# 🚀 1. BACKGROUND SYNC (BGAppRefreshTask)
                    
## 🧠 Key Concepts
                    
* Runs even when app is **closed / suspended**
* System decides execution time (you *request*, not control)
* Must be:
                        
* lightweight
* idempotent
* resumable
                    
                    ---
                    
## 🧩 1.1 Enable Background Mode
                    
In **Info.plist**:
                        
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
<string>com.yourapp.sync</string>
</array>
```
                    
                    ---
                    
## 🧱 1.2 Background Task Manager
                    
```swift
import BackgroundTasks
                    
final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    
    private let taskId = "com.yourapp.sync"
    
    private init() {}
    
    func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskId,
            using: nil
        ) { task in
            self.handle(task: task as! BGAppRefreshTask)
        }
    }
    
    func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 mins
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule:", error)
        }
    }
    
    private func handle(task: BGAppRefreshTask) {
        schedule() // 🔁 reschedule for next run
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let operation = SyncOperation()
        
        task.expirationHandler = {
            queue.cancelAllOperations()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        queue.addOperation(operation)
    }
}
```

---

## 🔄 1.3 SyncOperation (Bridge to SyncEngine)

```swift
import Foundation

final class SyncOperation: Operation {
    override func main() {
        if isCancelled { return }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            await DIContainer.shared.syncEngine.sync()
            semaphore.signal()
        }
        
        semaphore.wait()
    }
}
```

---

## 🧩 1.4 App Integration

```swift
@main
struct MyApp: App {
    
    init() {
        BackgroundTaskManager.shared.register()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                BackgroundTaskManager.shared.schedule()
            }
        }
    }
}
```

---

# 🔥 2. PAGINATION + CURSOR-BASED DELTA SYNC

---

## 🧠 Why Cursor > Timestamp?

| Timestamp ❌     | Cursor ✅         |
| --------------- | ---------------- |
| Clock issues    | Stable           |
| Missing updates | Exact continuity |
| Not scalable    | Pagination-ready |

---

# 🧩 2.1 API Response Model

```swift
struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let nextCursor: String?
    let hasMore: Bool
}
```

---

# 🌐 2.2 Remote API (Cursor-based)

```swift
protocol RemoteAPI {
    func fetchMessages(cursor: String?) async throws -> PaginatedResponse<Message>
    func send(_ item: SyncItem) async throws
}
```

---

## ✅ Example Implementation

```swift
final class RemoteAPIImpl: RemoteAPI {
    
    func fetchMessages(cursor: String?) async throws -> PaginatedResponse<Message> {
        var components = URLComponents(string: "https://api.yourapp.com/messages")!
        
        if let cursor = cursor {
            components.queryItems = [
                URLQueryItem(name: "cursor", value: cursor)
            ]
        }
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        
        return try JSONDecoder().decode(PaginatedResponse<Message>.self, from: data)
    }
    
    func send(_ item: SyncItem) async throws {
        // same as before
    }
}
```

---

# 🔄 2.3 SYNC ENGINE WITH CURSOR

```swift
actor SyncCursorStore {
    private var cursor: String?
    
    func get() -> String? { cursor }
    func set(_ new: String?) { cursor = new }
}
```

---

## 🔥 Updated SyncEngine

```swift
final class SyncEngine {
    private let local: LocalStore
    private let remote: RemoteAPI
    private let resolver: ConflictResolver
    private let cursorStore = SyncCursorStore()
    
    init(local: LocalStore, remote: RemoteAPI, resolver: ConflictResolver) {
        self.local = local
        self.remote = remote
        self.resolver = resolver
    }
    
    func sync() async {
        do {
            try await pushPending()
            try await pullPaginated()
        } catch {
            print("Sync error:", error)
        }
    }
    
    private func pushPending() async throws {
        let items = await local.pendingSyncItems()
        for item in items {
            try await remote.send(item)
        }
    }
    
    private func pullPaginated() async throws {
        var cursor = await cursorStore.get()
        var hasMore = true
        
        while hasMore {
            let response = try await remote.fetchMessages(cursor: cursor)
            
            for remoteMsg in response.data {
                try await merge(remoteMsg)
            }
            
            cursor = response.nextCursor
            await cursorStore.set(cursor)
            
            hasMore = response.hasMore
        }
    }
    
    private func merge(_ remoteMsg: Message) async throws {
        let locals = try await local.fetchMessages()
        
        if let localMsg = locals.first(where: { $0.id == remoteMsg.id }) {
            let merged = resolver.resolve(local: localMsg, remote: remoteMsg)
            await local.upsert(merged)
        } else {
            await local.upsert(remoteMsg)
        }
    }
}
```

---

# ⚡ 3. PRODUCTION IMPROVEMENTS (IMPORTANT)

## 🔥 1. Persist Cursor (Critical)

```swift
actor PersistentCursorStore {
    private let key = "sync_cursor"
    
    func get() -> String? {
        UserDefaults.standard.string(forKey: key)
    }
    
    func set(_ value: String?) {
        UserDefaults.standard.set(value, forKey: key)
    }
}
```

---

## 🔥 2. Limit Page Size

Backend should support:

```json
?cursor=abc&limit=50
```

---

## 🔥 3. Combine with WebSocket

| Mechanism   | Role        |
| ----------- | ----------- |
| WebSocket   | real-time   |
| Cursor Sync | reliability |

---

## 🔥 4. Handle App Kill

* Cursor persisted ✅
* Pending queue persisted ✅
* Sync resumes safely ✅

---

# 🧠 STAFF-LEVEL SUMMARY

When explaining:

👉 “How do you implement background + delta sync?”

You say:

* Use `BGAppRefreshTask` for periodic sync
* Always **reschedule**
* Keep tasks short & cancelable
* Use **cursor-based pagination**
* Persist cursor locally
* Fetch only diffs
* Combine with WebSocket for real-time
                                
                           
