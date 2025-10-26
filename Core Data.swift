//
//  Core Data.swift
//  
//
//  Created by Apple on 26/10/25.
//

import Foundation

Fantastic — this set of questions focuses on **Core Data performance optimization**, another key topic for **senior iOS interviews** (and real-world app performance).

Below, I’ll go through each question one by one — explaining the concepts, giving **best practices**, and including **code snippets** to show how you’d apply them.

---

## ⚡ 1. How do you improve fetch performance in Core Data?

Fetching efficiently is essential, especially when you deal with thousands of records or large relationships.
Here are the **main strategies**:

---

### ✅ **1. Use Fetch Limits and Batch Size**

These limit how much data Core Data loads at once.

**Example:**

```swift
let request: NSFetchRequest<User> = User.fetchRequest()
request.fetchLimit = 50              // Only fetch 50 objects total
request.fetchBatchSize = 20          // Fetch in small batches
request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
```

**Why:**

* `fetchLimit` restricts the total number of results.
* `fetchBatchSize` lets Core Data fault objects in small groups — improving **memory efficiency**.

---

### ✅ **2. Use Predicates to Narrow Results**

Only fetch what you need:

```swift
request.predicate = NSPredicate(format: "isActive == %@", NSNumber(value: true))
```

**Why:** Reduces unnecessary data load and speeds up queries.

---

### ✅ **3. Lightweight Faulting**

By default, Core Data returns **faults** (placeholders).
You can control faulting behavior to reduce memory overhead:

```swift
request.returnsObjectsAsFaults = true  // Default - more memory efficient
```

Or if you **know you’ll need all attributes immediately**:

```swift
request.returnsObjectsAsFaults = false // Avoids lazy loading
```

---

### ✅ **4. Prefetch Relationships**

If you know you’ll access related data, prefetch it to avoid multiple round-trips to the persistent store:

```swift
request.relationshipKeyPathsForPrefetching = ["posts", "profile"]
```

**Why:** Prevents “N+1 fetch” problems.

---

### ✅ **5. Use Asynchronous Fetching (iOS 10+)**

For long-running queries, use `NSAsynchronousFetchRequest`:

```swift
let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { result in
    guard let users = result.finalResult else { return }
    print("Fetched \(users.count) users")
}
try context.execute(asyncRequest)
```

**Why:** Keeps the UI thread responsive.

---

## 🧮 2. What is a Batch Update or Batch Delete, and when would you use them?

### **Batch Update**

Performs an **update directly on the persistent store** (e.g., SQLite), bypassing object loading.

```swift
let batchUpdate = NSBatchUpdateRequest(entityName: "User")
batchUpdate.propertiesToUpdate = ["isActive": false]
batchUpdate.resultType = .updatedObjectsCountResultType

let result = try context.execute(batchUpdate) as? NSBatchUpdateResult
print("Updated \(result?.result ?? 0) users")
```

**When to use:**

* You need to update **many records** quickly.
* You **don’t need to load objects into memory**.

---

### **Batch Delete**

Deletes data **directly at the store level**, without fetching each object.

```swift
let fetchRequest: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
batchDelete.resultType = .resultTypeObjectIDs

let result = try context.execute(batchDelete) as? NSBatchDeleteResult
if let deletedIDs = result?.result as? [NSManagedObjectID] {
    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: deletedIDs], into: [context])
}
```

**When to use:**

* Large cleanup operations (e.g., clearing cache or user data).
* Avoid loading thousands of objects into RAM.

---

## 🧠 3. How do you handle memory management with large data sets?

When working with tens of thousands of records, memory can spike if you’re not careful.
Here’s how to manage it effectively:

---

### ✅ **Use Faulting**

Core Data automatically faults objects to keep memory usage low.
Avoid forcing faults to be fired unnecessarily (e.g., avoid printing large relationships).

```swift
context.refresh(object, mergeChanges: false) // Turn object back into a fault
```

---

### ✅ **Use Autorelease Pools During Bulk Operations**

If you’re inserting or processing thousands of objects, wrap your loop in autorelease pools to release temporary memory early:

```swift
for (index, data) in largeDataset.enumerated() {
    autoreleasepool {
        let user = User(context: backgroundContext)
        user.name = data.name
        
        if index % 500 == 0 { // Save every few hundred records
            try? backgroundContext.save()
            backgroundContext.reset() // Clear cache
        }
    }
}
```

---

### ✅ **Reset the Context**

After bulk inserts or deletes, clear the in-memory object graph.

```swift
context.reset()
```

This removes all managed objects from memory while keeping the persistent store intact.

---

## 🧩 4. How can `NSFetchedResultsController` help with performance?

**NSFetchedResultsController (FRC)** is designed to efficiently **monitor Core Data changes** and keep a UI (e.g., a table or list) in sync with the database.

---

### **Benefits:**

* Efficiently **fetches data in batches**.
* Keeps your UI updated **incrementally** when changes occur.
* Reduces reload overhead (only diffs are applied).

---

### **Example:**

```swift
let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

let frc = NSFetchedResultsController(
    fetchRequest: fetchRequest,
    managedObjectContext: context,
    sectionNameKeyPath: nil,
    cacheName: "UserCache"
)
try frc.performFetch()
```

You can then listen to delegate methods to **update the UI efficiently**:

```swift
func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                didChange anObject: Any,
                at indexPath: IndexPath?,
                for type: NSFetchedResultsChangeType,
                newIndexPath: IndexPath?) {
    // Apply table updates instead of reloading everything
}
```

---

## 🧠 5. How does Core Data use faulting and caching internally?

### **Faulting**

* When Core Data fetches an object, it creates a **“fault”** — a placeholder object with only metadata.
* The data isn’t loaded until you **access a property**.
* Reduces memory footprint and speeds up fetches.

**Example:**

```swift
let users = try context.fetch(User.fetchRequest())
print(users.first!) // At this point, fault is fired
```

You can check if an object is a fault:

```swift
if user.isFault {
    print("User is a fault (not yet loaded)")
}
```

---

### **Caching**

Core Data uses an **in-memory object graph cache** (the managed object context) to avoid refetching the same object multiple times.

* Each context has its own cache.
* If you fetch the same object twice, Core Data returns the same instance from the context.
* When memory is tight, you can clear cache using:

  ```swift
  context.reset()
  ```

---

### **Combined Example: Faulting + Caching**

```swift
let request: NSFetchRequest<User> = User.fetchRequest()
request.returnsObjectsAsFaults = false
let users = try context.fetch(request)

for user in users {
    print(user.name!) // All data already in memory, no faults fired
}
```

But if you use:

```swift
request.returnsObjectsAsFaults = true
```

Core Data will only fault objects when you actually access them — trading CPU time for memory savings.

---

## 🧩 Summary Table

| Technique                      | Purpose                       | Example                                              |
| ------------------------------ | ----------------------------- | ---------------------------------------------------- |
| **Fetch Limit / Batch Size**   | Reduce result set size        | `request.fetchBatchSize = 50`                        |
| **Predicates**                 | Filter early                  | `request.predicate = NSPredicate(...)`               |
| **Prefetching**                | Avoid N+1 fetches             | `request.relationshipKeyPathsForPrefetching = [...]` |
| **Batch Update/Delete**        | Modify data directly in store | `NSBatchUpdateRequest`, `NSBatchDeleteRequest`       |
| **Faulting**                   | Lazy loading of objects       | Default Core Data behavior                           |
| **Context Reset**              | Clear memory                  | `context.reset()`                                    |
| **NSFetchedResultsController** | Efficient UI updates          | Automatically monitors changes                       |

---

Would you like me to continue with **"Core Data Migrations and Versioning"** (lightweight vs manual migration, version conflicts, and production strategies)?
That’s the next big senior-level area after performance and concurrency.


Perfect 👏 — you’re now diving into one of the **most important senior-level Core Data topics**:
**Concurrency and Thread Safety.**

Let’s go step-by-step through each of your questions with **clear explanations**, **best practices**, and **Swift code samples** you can reference in interviews or projects.

---

## 🧵 1. What are the different Core Data concurrency types?

Core Data contexts (`NSManagedObjectContext`) can be configured with one of **three concurrency types**:

| Concurrency Type                             | Description                                               | Usage                                                   |
| -------------------------------------------- | --------------------------------------------------------- | ------------------------------------------------------- |
| `.confinementConcurrencyType` *(deprecated)* | Used before iOS 9. You had to manually manage threads.    | ❌ Don’t use it.                                         |
| `.mainQueueConcurrencyType`                  | The context runs on the **main (UI) thread**.             | ✅ Use for updating UI and handling user-driven fetches. |
| `.privateQueueConcurrencyType`               | The context runs on its **own private background queue**. | ✅ Use for background work (imports, sync, processing).  |

**Example:**

```swift
let mainContext = NSPersistentContainer(name: "MyApp").viewContext
// Implicitly has .mainQueueConcurrencyType

let backgroundContext = NSPersistentContainer(name: "MyApp").newBackgroundContext()
// Has .privateQueueConcurrencyType
```

---

## 🧠 2. How do you safely use a Core Data context across multiple threads?

> ❗ Rule: **Never** use an `NSManagedObjectContext` or its managed objects directly across threads.

Each context is **bound to a specific queue**.
Instead of sharing contexts or passing managed objects between threads, you should:

### ✅ Use `perform {}` or `performAndWait {}` to safely access the context.

These methods ensure that Core Data operations are executed on the **correct queue**.

**Example:**

```swift
let backgroundContext = container.newBackgroundContext()

backgroundContext.perform {
    // Safe access
    let newUser = User(context: backgroundContext)
    newUser.name = "John"
    try? backgroundContext.save()
}
```

### ✅ Use **object IDs** to transfer objects between contexts.

You can safely pass `NSManagedObjectID` between threads and use it to fetch the corresponding object.

**Example:**

```swift
let userID = user.objectID // from main thread

backgroundContext.perform {
    let bgUser = backgroundContext.object(with: userID) as! User
    bgUser.name = "Updated Name"
    try? backgroundContext.save()
}
```

---

## ⚙️ 3. Explain the difference between `perform` and `performAndWait`.

| Method               | Thread-Safety                                         | Blocking Behavior                     | Typical Use                                        |
| -------------------- | ----------------------------------------------------- | ------------------------------------- | -------------------------------------------------- |
| `perform { }`        | Executes block **asynchronously** on context’s queue. | Non-blocking (returns immediately).   | Background operations.                             |
| `performAndWait { }` | Executes block **synchronously** on context’s queue.  | Blocking (waits for block to finish). | When you need results immediately or during setup. |

**Example:**

```swift
// Async (non-blocking)
backgroundContext.perform {
    let user = User(context: backgroundContext)
    user.name = "Async Example"
    try? backgroundContext.save()
}

// Sync (blocking)
backgroundContext.performAndWait {
    let userCount = try? backgroundContext.count(for: User.fetchRequest())
    print("User count: \(userCount ?? 0)")
}
```

🧩 **Rule of Thumb:**

* Use `perform` for long-running tasks or background imports.
* Use `performAndWait` when you must return data immediately (e.g., on app startup).

---

## ⚠️ 4. Common threading pitfalls in Core Data (and how to avoid them)

| Pitfall                                                | Description                                                            | Fix                                                                                            |
| ------------------------------------------------------ | ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| ❌ Accessing a managed object from a different thread   | Managed objects are **not thread-safe**.                               | Pass `objectID`, refetch using destination context.                                            |
| ❌ Updating UI from background context                  | UI must be updated on the **main thread**.                             | Use `DispatchQueue.main.async` or `mainContext`.                                               |
| ❌ Saving parent/child contexts in wrong order          | Background changes don’t reach persistent store if parent isn’t saved. | Always save **child first**, then **parent**.                                                  |
| ❌ Not merging background changes into the main context | Main context may not see updates made in background.                   | Observe `.NSManagedObjectContextDidSave` or use `automaticallyMergesChangesFromParent = true`. |
| ❌ Retaining large context                              | Holding large contexts causes memory bloat.                            | Use short-lived background contexts.                                                           |

**Example of automatic merging:**

```swift
let container = NSPersistentContainer(name: "MyApp")
container.loadPersistentStores { _, _ in }
container.viewContext.automaticallyMergesChangesFromParent = true
```

---

## 🚀 5. How would you handle background data import in Core Data?

Here’s a **real-world approach** to importing or syncing large data sets efficiently and safely.

### ✅ Step-by-step:

1. **Use a private background context**

```swift
let backgroundContext = container.newBackgroundContext()
```

2. **Perform import in background**

```swift
backgroundContext.perform {
    for json in apiResponse {
        let user = User(context: backgroundContext)
        user.id = json["id"] as? UUID
        user.name = json["name"] as? String
    }
    try? backgroundContext.save()
}
```

3. **Automatically merge into main context**

```swift
container.viewContext.automaticallyMergesChangesFromParent = true
```

This ensures the **UI updates automatically** in SwiftUI or UIKit once background changes are saved.

---

### ✅ Example with SwiftUI Integration

```swift
struct ImportButton: View {
    @Environment(\.managedObjectContext) private var viewContext
    let container: NSPersistentContainer

    var body: some View {
        Button("Import Data") {
            let bgContext = container.newBackgroundContext()
            bgContext.perform {
                for i in 1...1000 {
                    let user = User(context: bgContext)
                    user.name = "User \(i)"
                }
                try? bgContext.save()
            }
        }
    }
}
```

---

### ✅ Advanced: Parent-Child Context Approach

Sometimes you want finer control over when changes are persisted to disk:

```swift
let mainContext = container.viewContext
let childContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
childContext.parent = mainContext

childContext.perform {
    // Create or update objects
    try? childContext.save() // pushes to parent
    mainContext.performAndWait {
        try? mainContext.save() // persists to store
    }
}
```

---

## 🧩 Summary Table

| Concept           | Best Practice                                                   |
| ----------------- | --------------------------------------------------------------- |
| Concurrency Types | Use `.mainQueue` for UI, `.privateQueue` for background.        |
| Thread Safety     | Never share contexts; use `perform` or `performAndWait`.        |
| Object Sharing    | Pass `objectID`, not `NSManagedObject`.                         |
| Background Import | Use background context + automatic merge.                       |
| Merging           | Enable `automaticallyMergesChangesFromParent` or observe saves. |

---

Would you like me to show a **complete SwiftUI + Core Data concurrency demo** (main view updates automatically after background import)?
It’s a short example but shows how `automaticallyMergesChangesFromParent` and `@FetchRequest` work together — very impressive in interviews.


Excellent 👍 — let’s go deep.
Below is a **comprehensive Core Data + SwiftUI interview prep guide for senior iOS developers**, including **sample answers**, **code examples**, and **tips** that show senior-level thinking.

---

## 🧠 1. Core Concepts and Architecture

### **Q: What is Core Data, and how does it differ from SQLite or Realm?**

**Answer:**
Core Data is an **object graph management and persistence framework**, not just a database. It allows you to:

* Manage object life cycles,
* Track changes,
* Handle relationships and constraints,
* Persist data using different backends (SQLite, Binary, In-Memory).

Unlike SQLite or Realm, Core Data:

* Works with **object graphs** (not raw rows/columns),
* Supports **faulting**, **undo/redo**, and **versioned migrations**,
* Can use SQLite internally but abstracts it away.

---

### **Q: Explain the Core Data stack.**

**Answer:**
The Core Data stack has three key components:

1. **NSManagedObjectModel** – Describes the schema (entities, attributes, relationships).
2. **NSPersistentStoreCoordinator** – Bridges the model and the persistent store (e.g., SQLite file).
3. **NSManagedObjectContext** – In-memory workspace for managed objects. You fetch, create, and delete within it.
4. (iOS 10+) **NSPersistentContainer** – Simplifies stack setup.

**Code Example:**

```swift
let container = NSPersistentContainer(name: "MyAppModel")
container.loadPersistentStores { storeDescription, error in
    if let error = error {
        fatalError("Failed to load store: \(error)")
    }
}
let context = container.viewContext
```

---

### **Q: What is faulting in Core Data?**

**Answer:**
Faulting is a **lazy loading mechanism**.
When you fetch objects, Core Data initially returns *faults* — lightweight placeholders. Data is loaded only when accessed.

**Benefit:** Improves memory efficiency.
**Example:**

```swift
let users = try context.fetch(User.fetchRequest())
print(users.first?.name) // Access triggers fault resolution
```

---

## ⚙️ 2. Data Modeling and Relationships

### **Q: Explain delete rules.**

**Answer:**
Delete rules define how related objects behave when the source object is deleted.

| Rule          | Behavior                                 |
| ------------- | ---------------------------------------- |
| **Nullify**   | Sets relationship to nil                 |
| **Cascade**   | Deletes related objects                  |
| **Deny**      | Prevents deletion if relationships exist |
| **No Action** | Does nothing (be careful!)               |

---

### **Q: What’s the difference between lightweight and manual migration?**

**Answer:**

* **Lightweight migration** happens automatically if only simple changes (e.g., adding an attribute) are made.
* **Manual migration** is needed when schema changes are complex (e.g., relationship changes, data transformation).

**Lightweight Migration Example:**

```swift
let options = [
    NSMigratePersistentStoresAutomaticallyOption: true,
    NSInferMappingModelAutomaticallyOption: true
]

container.persistentStoreDescriptions.first?.options = options
container.loadPersistentStores(completionHandler: { _, error in ... })
```

---

## ⚡ 3. Performance and Optimization

### **Q: How do you optimize fetch performance?**

**Answer:**
Use:

* **Fetch limits and batch size:**

```swift
let request: NSFetchRequest<User> = User.fetchRequest()
request.fetchLimit = 50
request.fetchBatchSize = 20
```

* **Predicates and sort descriptors**

```swift
request.predicate = NSPredicate(format: "isActive == true")
request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
```

* **Faulting control** (e.g., `returnsObjectsAsFaults = false` if you need all data).

---

### **Q: What are batch updates/deletes?**

**Answer:**
They allow you to perform operations **directly on the SQLite store**, skipping object loading.

**Example:**

```swift
let batchUpdate = NSBatchUpdateRequest(entityName: "User")
batchUpdate.propertiesToUpdate = ["isActive": false]
batchUpdate.resultType = .updatedObjectsCountResultType

let result = try context.execute(batchUpdate) as? NSBatchUpdateResult
print("Updated \(result?.result ?? 0) records")
```

---

## 🧵 4. Concurrency and Threading

### **Q: How do you handle Core Data concurrency?**

**Answer:**
Use multiple contexts with **different concurrency types**.

```swift
let backgroundContext = container.newBackgroundContext()
backgroundContext.perform {
    // Background import
    let user = User(context: backgroundContext)
    user.name = "John"
    try? backgroundContext.save()
}
```

* Use `perform {}` for async work and `performAndWait {}` for sync.
* Never pass `NSManagedObject` between threads — use **object IDs**:

```swift
let objectID = user.objectID
let bgUser = backgroundContext.object(with: objectID)
```

---

## 🧩 5. Integration with SwiftUI

### **Q: How do you fetch Core Data in SwiftUI using @FetchRequest?**

**Answer:**

```swift
struct UserListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.name, ascending: true)],
        animation: .default
    ) private var users: FetchedResults<User>

    var body: some View {
        List(users) { user in
            Text(user.name ?? "")
        }
    }
}
```

---

### **Q: What are limitations of @FetchRequest?**

**Answer:**

* Can’t use **dynamic predicates** easily.
* Doesn’t support **complex filtering or batch fetching**.
* Doesn’t work well with **pagination**.

**Solution:** Use manual fetches with `@StateObject` view models.

---

### **Q: How do you preview Core Data in SwiftUI previews?**

**Answer:**

```swift
struct UserListView_Previews: PreviewProvider {
    static var previews: some View {
        let previewContainer = PersistenceController.preview
        return UserListView()
            .environment(\.managedObjectContext, previewContainer.container.viewContext)
    }
}
```

---

## 🧰 6. Error Handling and Debugging

### **Q: How do you debug Core Data SQL queries?**

**Answer:**
Add this launch argument:

```
-com.apple.CoreData.SQLDebug 1
```

This prints the SQL executed by Core Data to the console.

---

### **Q: How do you handle save errors?**

```swift
do {
    try context.save()
} catch {
    context.rollback()
    print("Save failed: \(error.localizedDescription)")
}
```

---

## 🚀 7. Real-World Scenarios

### **Q: How would you sync Core Data with a remote API?**

**Answer:**

* Use a **background context** for importing.
* Convert network responses → Core Data models.
* Use **merge policies** for conflict resolution:

```swift
context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
```

---

### **Q: How do you test Core Data logic?**

**Answer:**
Use an **in-memory store** for unit tests:

```swift
let container = NSPersistentContainer(name: "TestModel")
let description = NSPersistentStoreDescription()
description.type = NSInMemoryStoreType
container.persistentStoreDescriptions = [description]
container.loadPersistentStores { _, _ in }
```

---

## 🧮 8. Advanced Topics

### **Q: What is NSPersistentCloudKitContainer?**

**Answer:**
It integrates Core Data with **CloudKit** to sync data across devices using iCloud.

**Example:**

```swift
let container = NSPersistentCloudKitContainer(name: "MyAppModel")
container.loadPersistentStores { _, error in
    if let error = error {
        fatalError("Failed to load store: \(error)")
    }
}
```

---

### **Q: How do you implement undo/redo in Core Data?**

```swift
context.undoManager = UndoManager()
user.name = "New Name"
context.undo() // reverts
context.redo() // reapplies
```

---

## ✅ Summary: Senior-Level Insights

A senior iOS dev should:

* Design efficient Core Data models.
* Manage multi-threaded contexts safely.
* Handle migrations gracefully.
* Integrate Core Data cleanly with SwiftUI.
* Debug and optimize persistence performance.

---

Would you like me to create a **mini Core Data + SwiftUI sample project structure** (with persistence controller, model, and sample views) that demonstrates these best practices? That’s often a great way to tie it all together for interviews.

