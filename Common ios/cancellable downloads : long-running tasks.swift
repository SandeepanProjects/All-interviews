//
//  cancellable downloads : long-running tasks.swift
//  
//
//  Created by Apple on 17/01/26.
//

import Foundation

Absolutely! Let’s go **deep into cancellable downloads / long-running tasks** using **modern Swift concurrency (`async/await`, `Task`, `TaskGroup`)**. I’ll explain **step by step** with **best practices**, including **progress tracking, cancellation, and background support**.

---

## **1️⃣ Why Cancellation Matters**

In Swift concurrency, **`Task`** can be **cancelled** safely:

* Prevent unnecessary work if the user navigates away.
* Stop network requests to save battery and bandwidth.
* Allow multiple concurrent downloads that can be individually cancelled.

Key tools:

* `Task {}` → creates a cancellable task
* `TaskGroup` → manages multiple cancellable child tasks
* `Task.checkCancellation()` or `try Task.checkCancellation()` → check if cancelled

---

## **2️⃣ Cancellable Download Using Async/Await**

We’ll implement:

1. Download a file from a URL
2. Track progress
3. Support cancellation

```swift
import Foundation

@MainActor
class DownloadManager: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var isDownloading = false
    @Published var errorMessage: String?

    private var downloadTask: Task<Void, Never>? = nil

    func downloadFile(from url: URL) {
        isDownloading = true
        progress = 0
        errorMessage = nil

        downloadTask = Task {
            do {
                try await performDownload(from: url)
                print("Download finished")
            } catch {
                if Task.isCancelled {
                    print("Download cancelled")
                } else {
                    errorMessage = error.localizedDescription
                }
            }
            isDownloading = false
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
    }

    private func performDownload(from url: URL) async throws {
        let (inputStream, outputStream) = try await openStreams(for: url)
        var buffer = [UInt8](repeating: 0, count: 1024)
        var totalBytesRead = 0
        let totalBytes = urlContentLength(url: url) // simulate content length

        while true {
            try Task.checkCancellation() // ✅ check if task cancelled

            let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
            if bytesRead <= 0 { break }
            totalBytesRead += bytesRead

            // Update progress
            await MainActor.run {
                self.progress = Double(totalBytesRead) / Double(totalBytes)
            }

            // Simulate network delay
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    // Helpers
    private func openStreams(for url: URL) async throws -> (InputStream, OutputStream) {
        let inputStream = InputStream(url: url)!
        let outputStream = OutputStream(toMemory: ())
        inputStream.open()
        outputStream.open()
        return (inputStream, outputStream)
    }

    private func urlContentLength(url: URL) -> Int {
        // Simulate content length
        return 1_000_000
    }
}
```

---

### **Usage in SwiftUI**

```swift
struct DownloadView: View {
    @StateObject var manager = DownloadManager()
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: manager.progress)
                .progressViewStyle(LinearProgressViewStyle())
            
            if manager.isDownloading {
                Button("Cancel") {
                    manager.cancelDownload()
                }
            } else {
                Button("Start Download") {
                    manager.downloadFile(from: URL(string: "https://example.com/file")!)
                }
            }
        }
        .padding()
    }
}
```

✅ **Behavior**:

* Progress updates smoothly
* Cancellation works immediately
* Errors are reported

---

## **3️⃣ Multiple Concurrent Downloads with TaskGroup**

```swift
func downloadMultipleFiles(urls: [URL]) {
    Task {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        try await self.performDownload(from: url)
                    }
                }

                for try await _ in group {
                    // Each task finished
                    print("One download finished")
                }
            }
        } catch {
            print("Some download failed: \(error)")
        }
    }
}
```

### ✅ Key Points

* **Each child task is individually cancellable**
* **Use `Task.checkCancellation()`** in loops or long-running operations
* **Progress tracking** can be done per task or aggregated

---

## **4️⃣ Structured Cancellation**

Swift concurrency supports **structured cancellation**:

* When parent task is cancelled, **all child tasks are automatically cancelled**.

```swift
let parentTask = Task {
    try await withThrowingTaskGroup(of: Void.self) { group in
        for url in urls {
            group.addTask {
                try Task.checkCancellation() // stops if parent cancelled
                try await self.performDownload(from: url)
            }
        }
        try await group.waitForAll()
    }
}

// Cancel all downloads
parentTask.cancel()
```

---

## **5️⃣ Best Practices**

1. **Always check for cancellation** inside loops:

   ```swift
   try Task.checkCancellation()
   ```
2. **Update progress on MainActor** for SwiftUI UI binding:

   ```swift
   await MainActor.run { self.progress = ... }
   ```
3. **Use TaskGroup for concurrent downloads** to manage multiple tasks elegantly.
4. **Parent cancellation propagates to children** automatically.
5. **Avoid blocking threads** → use async streams, async URLSession APIs.

---

## **6️⃣ Using URLSession with Async/Await**

Swift 5.5+ has **built-in cancellable async URLSession APIs**:

```swift
let url = URL(string: "https://example.com/file")!
let (data, _) = try await URLSession.shared.data(from: url)

let task = Task {
    let (data, _) = try await URLSession.shared.data(from: url)
    // handle data
}

// Cancel
task.cancel()
```

✅ Modern approach: **no manual threads, no queues**, fully cancellable.

---

## **7️⃣ Summary**

| Feature          | GCD / URLSession         | Swift Concurrency                    |
| ---------------- | ------------------------ | ------------------------------------ |
| Cancellation     | Manual, DispatchWorkItem | Built-in Task cancellation           |
| Dependencies     | Hard                     | TaskGroup for structured concurrency |
| Progress Updates | Manual                   | Use `@MainActor` to bind             |
| Multi-task       | Manual queues            | TaskGroup / async let                |
| Modern Swift     | Not ideal                | Preferred                            |

---

💡 **Rule of Thumb**:

* **Single download → Task + URLSession async**
* **Multiple downloads → TaskGroup**
* **Cancellable loops → Task.checkCancellation()**
* **UI updates → `@MainActor`**

---

If you want, I can **write a full SwiftUI “Download Manager App”** that:

* Handles **multiple concurrent downloads**
* Shows **per-download circular progress**
* Supports **pause / resume / cancel**
* Fully **uses Swift concurrency**

Do you want me to do that next?
