//
//  Tasks in iOS.swift
//  
//
//  Created by Apple on 18/10/25.
//

import Foundation

Swift Concurrency, introduced in Swift 5.5 (iOS 13+ with back-deployment, fully available in iOS 15+), brings structured concurrency to Swift through constructs like `async/await`, `Task`, `TaskGroup`, and more. Tasks are the foundation of concurrency in Swift. This guide gives you **everything you need to know** about **Tasks** in **iOS using Swift Concurrency**.

---

## 🧱 What is a `Task`?

A `Task` is a lightweight, concurrent unit of work that can run asynchronously. It’s like a thread of execution, but much more efficient.

```swift
Task {
    // asynchronous code here
    let data = await fetchData()
    print(data)
}
```

A `Task`:

* Executes async code concurrently.
* Can run in parallel with other tasks.
* Can be **cancelled**, **prioritized**, **awaited**, and **structured**.

---

## 🧭 Types of Tasks

There are two main types:

### 1. **Top-Level Tasks**

Created using the `Task {}` initializer.

```swift
Task {
    let result = await someAsyncFunction()
}
```

* These are **unstructured**.
* Can escape the current context (e.g., a view or controller).
* Not automatically tied to the caller’s lifetime.

### 2. **Child Tasks (Structured Tasks)**

Created inside a parent task using `async let` or `TaskGroup`.

```swift
func fetchMultiple() async {
    async let a = fetchA()
    async let b = fetchB()
    let (resultA, resultB) = await (a, b)
}
```

* Part of **structured concurrency**.
* Automatically canceled if the parent task is canceled.
* Better memory safety and easier debugging.

---

## 🧠 Task Lifecycle

### ✅ Start

A `Task` begins immediately when initialized.

### ⏸️ Suspension

It suspends when `await` is called. Other tasks can execute during this time.

### 🔁 Resume

When the awaited result is ready, the task resumes.

### ❌ Cancel

Tasks can be cancelled using `task.cancel()` or cooperatively by checking `Task.isCancelled`.

```swift
let task = Task {
    while !Task.isCancelled {
        // keep working
    }
}

task.cancel()
```

---

## ⚙️ Task Priorities

Swift Concurrency supports priority hints:

```swift
Task(priority: .background) {
    await doWork()
}
```

Available priorities:

* `.userInteractive`
* `.userInitiated`
* `.default`
* `.utility`
* `.background`
* `.low`
* `.high`

Note: Priorities are **hints**, not guarantees.

---

## 📥 Returning Values from Tasks

You can create tasks that return a value:

```swift
let task = Task { () -> Int in
    return await computeValue()
}

let result = await task.value
```

* `task.value` suspends until the task completes.

---

## 🔁 TaskGroup

Use `TaskGroup` when you want to create multiple child tasks and wait for them all:

```swift
func fetchAll() async throws -> [Data] {
    return try await withThrowingTaskGroup(of: Data.self) { group in
        for url in urls {
            group.addTask {
                return try await fetchData(from: url)
            }
        }

        var results = [Data]()
        for try await data in group {
            results.append(data)
        }
        return results
    }
}
```

* Automatically cancels remaining tasks on error.
* Supports both `withTaskGroup` and `withThrowingTaskGroup`.

---

## 🧹 Task Cancellation

Tasks can be cancelled, but they must **cooperate**:

```swift
func doWork() async {
    guard !Task.isCancelled else { return }

    // Or periodically check
    for i in 0..<100 {
        if Task.isCancelled { return }
        // work
    }
}
```

You can use `try Task.checkCancellation()` to throw an error when cancelled.

---

## 💣 DetachedTask

Creates a task not attached to any parent. Use carefully.

```swift
let detached = Task.detached(priority: .background) {
    await doBackgroundWork()
}
```

* Not tied to current actor.
* Use when you truly want a task isolated from its creator.
* Must manage cancellation and lifecycle manually.

---

## 🧵 Tasks and Actors

Tasks can be used to interact with `actors`:

```swift
actor Counter {
    var value = 0

    func increment() {
        value += 1
    }
}

let counter = Counter()

Task {
    await counter.increment()
}
```

* Use `await` when calling actor methods/properties from outside.

---

## 🧪 Task Handles

You can keep a reference to a task:

```swift
var handle: Task<Void, Never>?

handle = Task {
    await doWork()
}

handle?.cancel()
```

Useful for long-running or cancelable operations like network calls, animation loops, etc.

---

## 🐛 Error Handling

Tasks can throw errors. If a task throws, you can catch it like this:

```swift
let task = Task { () throws -> String in
    return try await mayThrow()
}

do {
    let result = try await task.value
} catch {
    print("Task failed: \(error)")
}
```

In a `TaskGroup`, remaining tasks are cancelled if one throws.

---

## 🧼 Best Practices

| Practice                                    | Why                                              |
| ------------------------------------------- | ------------------------------------------------ |
| ✅ Use `async let` and `TaskGroup`           | For structured concurrency and better safety.    |
| ❌ Avoid `Task.detached` unless needed       | Breaks structured concurrency; harder to manage. |
| ✅ Check `Task.isCancelled`                  | Make your tasks responsive to cancellation.      |
| ✅ Use `@MainActor` for UI updates           | Ensures thread safety in UI code.                |
| ✅ Cancel tasks in `deinit` or `onDisappear` | Prevent memory leaks or ghost tasks.             |
| ✅ Use `task(value:)` modifier in SwiftUI    | Ties the task to the view lifecycle.             |

---

## 🧭 When to Use `Task`

* **In SwiftUI views** (e.g., `onAppear`, or with `.task {}`).
* **To launch async operations** from synchronous code.
* **When performing parallel workloads**.
* **To offload work from the main actor/thread**.

---

## 🧰 SwiftUI `.task` Modifier

```swift
.task {
    await loadData()
}
```

* Runs when the view appears.
* Automatically cancelled when the view disappears.

---

## 🏁 Summary Cheat Sheet

```swift
// Create a basic task
Task {
    await doSomething()
}

// Task with priority
Task(priority: .userInitiated) {
    await fetchImportantData()
}

// Cancelable task
let task = Task {
    while !Task.isCancelled {
        // work
    }
}
task.cancel()

// Concurrent child tasks
async let a = doA()
async let b = doB()
let (resultA, resultB) = await (a, b)

// Task group
try await withTaskGroup(of: String.self) { group in
    group.addTask { "Task 1" }
    group.addTask { "Task 2" }
    for await result in group {
        print(result)
    }
}
```

---

If you’d like a **real-world example**, like using `Task` for a network call, or integrating with `Combine` or `URLSession`, let me know — I can provide sample code.
Great! Here's a **real-world example** using `Task` and **Swift Concurrency** to perform a **network request** using `URLSession` in an iOS app, the modern way.
                                                                
---
                                                                
## 🔌 Real-World Example: Fetching JSON with `Task` and `URLSession`

We’ll create:
                                                                    
1. A `User` model.
2. A `NetworkManager` class with an async `fetchUsers()` function.
3. A SwiftUI `View` that calls it using `.task {}` and shows the data.

---

### 1. 👤 Define the Data Model

```swift
struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
}
```

Example JSON endpoint:

```json
[
    {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
}
]
```

---

### 2. 🌐 Create the Network Manager with Async Function

```swift
class NetworkManager {
    static let shared = NetworkManager()
    
    func fetchUsers() async throws -> [User] {
        let url = URL(string: "https://jsonplaceholder.typicode.com/users")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([User].self, from: data)
    }
}
```

---

### 3. 🧠 ViewModel with `@MainActor`

```swift
@MainActor
class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadUsers() {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                users = try await NetworkManager.shared.fetchUsers()
            } catch {
                errorMessage = "Failed to fetch users: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
```

---

### 4. 🖼 SwiftUI View Using `.task {}`

```swift
struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading {
                    ProgressView("Loading users...")
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                } else {
                    ForEach(viewModel.users) { user in
                        VStack(alignment: .leading) {
                            Text(user.name).font(.headline)
                            Text(user.email).font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Users")
        }
        .task {
            viewModel.loadUsers()
        }
    }
}
```

---

### ✅ What This Shows

* `Task {}` runs in a safe, structured way when the view appears.
* The `@MainActor` ViewModel ensures UI updates are thread-safe.
* We fetch from the network using `async/await` and decode JSON.
* Error handling and loading state are integrated.

---

### 🧼 Bonus: Cancel the Task on View Disappear

If you're managing long-running tasks manually:

```swift
@State private var loadTask: Task<Void, Never>? = nil

    .task {
        loadTask = Task {
            await viewModel.loadUsers()
        }
    }
    .onDisappear {
        loadTask?.cancel()
    }
```

> You don’t need this if using `.task {}` in SwiftUI 3+ (iOS 15+) — SwiftUI cancels tasks automatically on view disappearance.

---

Would you like another real-world example — like using `TaskGroup` for parallel downloads, or wrapping legacy completion handlers with `async`?

Great! Let’s explore **two more real-world examples** using Swift Concurrency and `Task` in iOS:
                                                                            
                                                                            ---
                                                                            
## 🔁 Example 1: **Using `TaskGroup` for Parallel Image Downloads**
                                                                        
### 🔥 Scenario:
                                                                            
You want to download **multiple images concurrently** and display them as they finish loading.
                                                                        
---
                                                                        
### ✅ Step-by-step implementation:
                                                                            
#### 1. 📷 Helper to Download an Image
                                                                        
```swift
func fetchImage(from url: URL) async throws -> UIImage {
    let (data, _) = try await URLSession.shared.data(from: url)
    guard let image = UIImage(data: data) else {
        throw URLError(.cannotDecodeContentData)
    }
    return image
}
```

---

#### 2. 🧠 ViewModel with `TaskGroup`

```swift
@MainActor
class ImageLoaderViewModel: ObservableObject {
    @Published var images: [UIImage] = []
    
    let urls: [URL] = [
        URL(string: "https://via.placeholder.com/150")!,
        URL(string: "https://via.placeholder.com/200")!,
        URL(string: "https://via.placeholder.com/250")!
    ]
    
    func loadImagesInParallel() {
        Task {
            await fetchAllImages()
        }
    }
    
    private func fetchAllImages() async {
        images = [] // Clear old results
        await withTaskGroup(of: UIImage?.self) { group in
            for url in urls {
                group.addTask {
                    try? await fetchImage(from: url)
                }
            }
            
            for await image in group {
                if let image = image {
                    images.append(image)
                }
            }
        }
    }
}
```

---

#### 3. 🖼 SwiftUI View

```swift
struct ImageGridView: View {
    @StateObject private var viewModel = ImageLoaderViewModel()
    
    let columns = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.images, id: \.self) { image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                }
            }
            .padding()
        }
        .task {
            viewModel.loadImagesInParallel()
        }
        .navigationTitle("Parallel Images")
    }
}
```

---

### 🚀 What You Learned:

* **`withTaskGroup`** helps run multiple tasks in parallel.
* Tasks run concurrently and append their results to the list.
* Automatically cancels remaining tasks if the view disappears (when used inside `.task {}`).
                                            
---
                                            
## 🔁 Example 2: **Wrapping a Legacy Completion Handler with `async`**
                                            
Sometimes you’re stuck with older APIs using closures. Here’s how to make them work with Swift Concurrency using `withCheckedContinuation`.
                                            
---
                                            
### 🛠 Legacy API
                                            
```swift
func fetchLegacyData(completion: @escaping (String?, Error?) -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
        completion("Legacy Data", nil)
    }
}
```

---

### 🔁 Convert to `async` with Continuation

```swift
func fetchDataAsync() async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
        fetchLegacyData { result, error in
            if let result = result {
                continuation.resume(returning: result)
            } else {
                continuation.resume(throwing: error ?? URLError(.badServerResponse))
            }
        }
    }
}
```

> Use `withCheckedThrowingContinuation` for throwing versions and `withCheckedContinuation` if no error can occur.
                                                
---
                                                
### ✅ Use with `Task`
                                                
```swift
Task {
    do {
        let result = try await fetchDataAsync()
        print("Result: \(result)")
    } catch {
        print("Error: \(error)")
    }
}
```

---

## 🔚 Summary

| Feature                     | Usage                                                  |
| --------------------------- | ------------------------------------------------------ |
| ✅ `TaskGroup`               | Run multiple async tasks in parallel, collect results. |
| ✅ `withCheckedContinuation` | Bridge completion handlers to async/await world.       |
| ✅ `@MainActor` ViewModel    | Safe UI updates on main thread.                        |
| ✅ `.task {}` in SwiftUI     | Launch tasks tied to the view lifecycle.               |

---

Would you like an example of:

* Animations with async/await?
* File downloading with progress and cancellation?
* Using `AsyncSequence` for live updates?
                                
Awesome — let’s dive into another real-world use case with **Swift Concurrency**.
                                
---
                                
## 📦 Example 3: **File Download with Progress, Cancellation, and Swift Concurrency**
                                
### 🔥 Scenario:
                                    
You want to download a file from a URL, **track its progress**, and allow the user to **cancel** the download — all using `Task`, `@Published`, and SwiftUI.
                                
---
                                
## 🛠️ What You'll Learn:
                                    
* Use `URLSession` with a `URLSessionDownloadDelegate`.
* Bridge it into async/await using `AsyncStream`.
* Track download **progress in real time**.
* Support **cancellation** using `Task`.
                                
---
                                
### 🗂 Step 1: FileDownloader with Progress + AsyncStream
                                
```swift
import Foundation
import Combine
                                
final class FileDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: Double = 0.0
    @Published var fileURL: URL? = nil
    @Published var error: Error?
    
    private var session: URLSession!
    private var continuation: AsyncStream<ProgressUpdate>.Continuation?
    private var downloadTask: URLSessionDownloadTask?
    
    struct ProgressUpdate {
        let progress: Double
        let url: URL?
    }
    
    override init() {
        super.init()
        let config = URLSessionConfiguration.default
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func startDownload(from url: URL) -> AsyncStream<ProgressUpdate> {
        return AsyncStream { continuation in
            self.continuation = continuation
            self.downloadTask = session.downloadTask(with: url)
            self.downloadTask?.resume()
        }
    }
    
    func cancel() {
        downloadTask?.cancel()
        continuation?.finish()
    }
    
    // MARK: - URLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        continuation?.yield(.init(progress: progress, url: nil))
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        continuation?.yield(.init(progress: 1.0, url: location))
        continuation?.finish()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.error = error
            continuation?.finish()
        }
    }
}
```

---

### 🧠 ViewModel Using Task

```swift
@MainActor
class DownloadViewModel: ObservableObject {
    @Published var downloadProgress: Double = 0.0
    @Published var downloadedFileURL: URL?
    @Published var errorMessage: String?
    
    private let downloader = FileDownloader()
    private var downloadTask: Task<Void, Never>?
    
    func startDownloading() {
        downloadTask = Task {
            for await update in downloader.startDownload(from: URL(string: "https://speed.hetzner.de/100MB.bin")!) {
                self.downloadProgress = update.progress
                if let fileURL = update.url {
                    self.downloadedFileURL = fileURL
                }
            }
        }
    }
    
    func cancelDownload() {
        downloader.cancel()
        downloadTask?.cancel()
    }
}
```

---

### 🖼 SwiftUI View

```swift
struct FileDownloadView: View {
    @StateObject private var viewModel = DownloadViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: viewModel.downloadProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .padding()
            
            if let url = viewModel.downloadedFileURL {
                Text("Downloaded to: \(url.lastPathComponent)")
                    .font(.footnote)
            }
            
            if let error = viewModel.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }
            
            HStack {
                Button("Start Download") {
                    viewModel.startDownloading()
                }
                Button("Cancel") {
                    viewModel.cancelDownload()
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .navigationTitle("Download File")
    }
}
```

---

## ✅ Features You Now Have:

* **Download with progress bar**.
* Uses `Task` + `AsyncStream` to deliver updates in real time.
* Can **cancel** the task at any time.
* Clean UI/logic separation with `@MainActor` and `ObservableObject`.

---

## 👨‍🔧 Bonus Tip: File Preview

You can preview the downloaded file using `QuickLookPreview` or open it with `UIDocumentInteractionController` if you want.
                                                                                                                    
---
                                                                                                                    
## 💡 More Ideas?
                                                                                                                    
Would you like one of the following next?
                                                                                                                    
* `AsyncSequence` to stream data (like live updates or search suggestions)?
* Using `await` for animation timing?
* Real-world use of `actor` for data protection?
* Combine + async/await hybrid patterns?
