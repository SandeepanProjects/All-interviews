//
//  offline mechanism using core data.swift
//  
//
//  Created by Apple on 26/10/25.
//

import Foundation

Excellent — this is a very practical and important topic:
how to make a **SwiftUI app work offline** using **Core Data**, then **sync changes** when the internet returns.

Let’s go step-by-step so you can both **save locally** and **sync remotely** safely.

---

## 🧭 What You’ll Learn

You’ll learn how to:

1. **Cache and save data offline using Core Data**
2. **Detect online/offline state**
3. **Queue up pending changes**
4. **Push local changes to the server** when back online
5. **Pull remote updates** and resolve conflicts

---

## 🧱 Architecture Overview

A reliable offline-first architecture for SwiftUI + Core Data looks like this:

```
[ SwiftUI Views ]
        ↓
[ ViewModel / Repository ]
        ↓
[ Core Data Store ] ←→ [ API Client (Network) ]
        ↑
  (Reachability / Network Monitor)
```

* **SwiftUI Views** bind to Core Data via `@FetchRequest` or a ViewModel.
* **Core Data** is your local database.
* **Network Manager** checks for connectivity.
* **Sync Manager** pushes unsynced local data and fetches remote updates.

---

## 1️⃣ Create a Local Core Data Store

You can use the standard `PersistenceController` used in SwiftUI templates.

```swift
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "OfflineModel")

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved Core Data error: \(error)")
            }
        }
    }
}
```

---

## 2️⃣ Add Sync Metadata to Entities

To track what needs to be synced, add **metadata attributes** in your Core Data model.

Example: `Task` entity

| Attribute      | Type   | Purpose                     |
| -------------- | ------ | --------------------------- |
| `id`           | UUID   | Unique ID                   |
| `title`        | String | Task text                   |
| `isCompleted`  | Bool   | Task status                 |
| `isSynced`     | Bool   | Marks if synced with server |
| `lastModified` | Date   | Helps resolve conflicts     |

---

## 3️⃣ Detect Network Connectivity

Use **`NWPathMonitor`** from `Network` framework.

```swift
import Network

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected = true

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
```

Now you can observe network changes in SwiftUI views or a sync manager.

---

## 4️⃣ Save Data Locally (Offline-First)

When a user creates or updates something, **save to Core Data immediately**, mark it as `isSynced = false`.

Example (ViewModel):

```swift
class TaskViewModel: ObservableObject {
    private let context = PersistenceController.shared.container.viewContext

    func addTask(title: String) {
        let task = Task(context: context)
        task.id = UUID()
        task.title = title
        task.isCompleted = false
        task.isSynced = false
        task.lastModified = Date()
        
        saveContext()
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}
```

Now, the app works even offline.

---

## 5️⃣ Implement a Sync Manager

This is where the magic happens.
A `SyncManager` listens for:

* **Network reconnects**
* **Local unsynced data**

And pushes changes to your backend.

```swift
class SyncManager {
    static let shared = SyncManager()
    private let context = PersistenceController.shared.container.viewContext
    private var cancellables = Set<AnyCancellable>()

    init() {
        NetworkMonitor.shared.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.syncPendingTasks()
                }
            }
            .store(in: &cancellables)
    }

    func syncPendingTasks() {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isSynced == NO")

        do {
            let unsyncedTasks = try context.fetch(fetchRequest)

            for task in unsyncedTasks {
                uploadTask(task)
            }
        } catch {
            print("Failed to fetch unsynced tasks: \(error)")
        }
    }

    private func uploadTask(_ task: Task) {
        // Example: simple REST API call
        guard let url = URL(string: "https://api.example.com/tasks") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = [
            "id": task.id?.uuidString,
            "title": task.title,
            "isCompleted": task.isCompleted
        ] as [String : Any]

        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if error == nil {
                DispatchQueue.main.async {
                    task.isSynced = true
                    try? self?.context.save()
                }
            }
        }.resume()
    }
}
```

---

## 6️⃣ Handle Sync Conflicts

When syncing **both ways** (server ↔︎ device):

You can handle conflicts using timestamps:

1. Compare `lastModified` on server and client.
2. If client’s timestamp is newer → update server.
3. If server’s timestamp is newer → overwrite local Core Data record.

---

## 7️⃣ Integrate It in SwiftUI

Example usage in a SwiftUI view:

```swift
struct TaskListView: View {
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Task.lastModified, ascending: false)])
    private var tasks: FetchedResults<Task>

    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var viewModel = TaskViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(tasks) { task in
                    HStack {
                        Text(task.title ?? "")
                        Spacer()
                        if !task.isSynced {
                            Image(systemName: "icloud.slash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                Button("Add") {
                    viewModel.addTask(title: "New Task")
                }
            }
        }
        .onAppear {
            _ = SyncManager.shared // initialize sync system
        }
    }
}
```

---

## 8️⃣ Summary of the Flow

| Step                 | Action                                                  | Works Offline? |
| -------------------- | ------------------------------------------------------- | -------------- |
| User adds data       | Saved locally to Core Data, `isSynced = false`          | ✅              |
| Device offline       | Data stays local                                        | ✅              |
| Device online        | `SyncManager` detects connection, uploads unsynced data | ✅              |
| Server confirms      | Mark record `isSynced = true`                           | ✅              |
| Server sends updates | App merges remote data into Core Data                   | ✅              |

---

## ⚡ Bonus: Tools & Frameworks That Can Help

If you want a more advanced sync setup, check out:

* **CloudKit + Core Data** → built-in Apple solution for iCloud syncing.
* **Realm Sync** → alternative database with built-in sync.
* **Firebase Firestore + Local Persistence** → easy to integrate but not Core Data-based.

---

Would you like me to extend this example to **handle bidirectional sync** (download remote changes and merge them with Core Data safely)?

Perfect 👏 — let’s take your offline-first Core Data + SwiftUI setup **to the next level** by adding **bidirectional sync** — meaning:
                                                                
* You can **work fully offline**
* When online again, your app **pushes local changes to the server**
* Then it **downloads remote changes**, updates Core Data, and **resolves conflicts** safely
                                                            
---
                                                            
# 🧭 Overview of the Full Sync Flow
                                                            
### 🔁 The Bidirectional Sync Cycle
                                                            
1. **Push Phase:** Upload local unsynced Core Data objects → Server
2. **Pull Phase:** Download new or updated server objects → Core Data
3. **Conflict Resolution:** Decide which version “wins” (usually based on `lastModified`)
4. **Mark Synced:** Mark both sides as up to date
                                                            
---

## 🧱 Prerequisites
                                                            
Your Core Data entity (e.g. `Task`) should have:
                                                                
| Attribute      | Type   | Purpose                           |
| -------------- | ------ | --------------------------------- |
| `id`           | UUID   | Stable unique identifier          |
| `title`        | String | Task title                        |
| `isCompleted`  | Bool   | Task status                       |
| `isSynced`     | Bool   | Indicates if synced with server   |
| `lastModified` | Date   | Timestamp for conflict resolution |
                                                            
---
                                                            
# ⚙️ Step 1: Add the Sync Manager (Bidirectional)
                                                            
Here’s a full version of the `SyncManager` that handles **push + pull + conflict resolution**.
                                                            
```swift
import Foundation
import CoreData
import Combine
                                                            
class SyncManager: ObservableObject {
    static let shared = SyncManager()
    private let context = PersistenceController.shared.container.viewContext
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = URL(string: "https://api.example.com/tasks")! // Replace with your API
    
    init() {
        // Auto-start syncing when internet is available
        NetworkMonitor.shared.$isConnected
            .sink { [weak self] isConnected in
                if isConnected {
                    self?.syncAll()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Main sync function — handles both upload & download
    func syncAll() {
        pushLocalChanges {
            self.pullRemoteChanges()
        }
    }
    
    // MARK: - PUSH local unsynced data
    private func pushLocalChanges(completion: @escaping () -> Void) {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "isSynced == NO")
        
        do {
            let unsynced = try context.fetch(request)
            guard !unsynced.isEmpty else {
                completion()
                return
            }
            
            let group = DispatchGroup()
            
            for task in unsynced {
                group.enter()
                upload(task: task) { success in
                    if success {
                        task.isSynced = true
                        task.lastModified = Date()
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                try? self.context.save()
                completion()
            }
            
        } catch {
            print("Push error: \(error)")
            completion()
        }
    }
    
    private func upload(task: Task, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "id": task.id?.uuidString ?? UUID().uuidString,
            "title": task.title ?? "",
            "isCompleted": task.isCompleted,
            "lastModified": ISO8601DateFormatter().string(from: task.lastModified ?? Date())
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            completion(error == nil)
        }.resume()
    }
    
    // MARK: - PULL remote changes
    private func pullRemoteChanges() {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("Pull error: \(error?.localizedDescription ?? "")")
                return
            }
            
            guard let remoteTasks = try? JSONDecoder().decode([RemoteTask].self, from: data) else {
                print("Decoding failed")
                return
            }
            
            DispatchQueue.main.async {
                self.merge(remoteTasks: remoteTasks)
            }
        }.resume()
    }
    
    // MARK: - MERGE remote and local
    private func merge(remoteTasks: [RemoteTask]) {
        for remote in remoteTasks {
            let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", remote.id as CVarArg)
            
            if let existing = try? context.fetch(fetchRequest).first {
                // Conflict resolution based on lastModified
                if remote.lastModified > (existing.lastModified ?? Date.distantPast) {
                    existing.title = remote.title
                    existing.isCompleted = remote.isCompleted
                    existing.lastModified = remote.lastModified
                    existing.isSynced = true
                }
            } else {
                // New task from server — insert it
                let newTask = Task(context: context)
                newTask.id = remote.id
                newTask.title = remote.title
                newTask.isCompleted = remote.isCompleted
                newTask.isSynced = true
                newTask.lastModified = remote.lastModified
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Merge save error: \(error)")
        }
    }
}
```

---

# 🧾 Step 2: Define a Codable Model for Remote Data
                                            
This mirrors your Core Data entity for JSON decoding.
                                            
```swift
struct RemoteTask: Codable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let lastModified: Date
}
```

💡 Tip: You can customize `CodingKeys` if your API uses different field names.
                                            
                                            ---
                                            
# 🕹️ Step 3: Integrate With SwiftUI
                                            
Just like before, you can trigger sync automatically when your main view appears:
                                                
```swift
struct TaskListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.lastModified, ascending: false)]
    ) var tasks: FetchedResults<Task>
    
    @StateObject private var viewModel = TaskViewModel()
    @StateObject private var network = NetworkMonitor.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(tasks) { task in
                    HStack {
                        Text(task.title ?? "")
                        Spacer()
                        if !task.isSynced {
                            Image(systemName: "icloud.slash").foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                Button("Add Task") {
                    viewModel.addTask(title: "New Task")
                }
            }
        }
        .onAppear {
            SyncManager.shared.syncAll()
        }
    }
}
```

---

# ⚖️ Step 4: Conflict Resolution Strategy

You can change the rule depending on your needs:

| Strategy                 | Description                                                                 |
| ------------------------ | --------------------------------------------------------------------------- |
| **Client wins**          | Local changes always overwrite server data                                  |
| **Server wins**          | Remote changes overwrite local data                                         |
| **Last modified wins** ✅ | The object with the most recent `lastModified` timestamp wins (most common) |

This is implemented in:

```swift
if remote.lastModified > (existing.lastModified ?? Date.distantPast)
    ```
    
    ---
    
    # ⚡ Step 5: Extra Enhancements (Optional)
    
    ✅ **Background Sync:**
        Trigger `SyncManager.shared.syncAll()` in `ScenePhase` `.active` or `.background`
    (using `@Environment(\.scenePhase)`).
    
    ✅ **Batch API Calls:**
        Send multiple tasks at once instead of looping one-by-one.
    
    ✅ **Deleted Object Sync:**
        Add an `isDeletedRemotely` flag or implement a `deletedAt` timestamp to track deletions.
    
    ✅ **Conflict Logs:**
        Store conflict details locally for debugging sync issues.
    
    ---
    
    # ✅ Summary
    
    | Feature               | Implementation                 |
    | --------------------- | ------------------------------ |
    | Local Offline Storage | Core Data                      |
    | Track Unsynced Data   | `isSynced` flag                |
    | Network Monitor       | `NWPathMonitor`                |
    | Push Changes          | REST API POST/PUT              |
    | Pull Changes          | REST API GET                   |
    | Conflict Resolution   | Compare `lastModified`         |
    | Bidirectional Sync    | `SyncManager` runs push + pull |
    
    ---
    
    Would you like me to extend this even further and show **how to sync deleted items** (so that if a user deletes an item offline, it also deletes on the server when back online)?
