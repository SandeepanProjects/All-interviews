//
//  concurrent image downloader.swift
//  
//
//  Created by Apple on 23/02/26.
//

import Foundation

This is a **very common senior iOS system design question**.
A good answer must cover:

* Concurrency control
* Deduplication (avoid duplicate downloads)
* Caching (memory + disk)
* Cancellation
* Priority handling
* Thread safety

Let’s design it step-by-step like you would in an interview.

---

# 🎯 Requirements

We want:

* Download images concurrently
* Limit max concurrent downloads
* Avoid downloading same URL twice
* Cache images in memory
* Support cancellation
* Be thread-safe
* Use modern Swift concurrency

---

# 🏗 High-Level Architecture

```
View
  ↓
ImageLoader (public API)
  ↓
ImageCache (memory cache)
  ↓
DownloadManager (actor)
  ↓
URLSession
```

---

# ✅ 1️⃣ Memory Cache (Thread Safe)

Use `NSCache` (already thread-safe and memory-aware).

```swift
final class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSURL, UIImage>()
    
    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
```

---

# 🚀 2️⃣ Download Manager (Actor-Based)

Actor ensures:

* No race conditions
* Safe shared state
* No manual locks

```swift
actor ImageDownloadManager {
    
    static let shared = ImageDownloadManager()
    
    private var runningTasks: [URL: Task<UIImage, Error>] = [:]
    
    func download(from url: URL) async throws -> UIImage {
        
        // Deduplicate request
        if let existingTask = runningTasks[url] {
            return try await existingTask.value
        }
        
        let task = Task<UIImage, Error> {
            defer { await removeTask(for: url) }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let image = UIImage(data: data) else {
                throw URLError(.badServerResponse)
            }
            
            ImageCache.shared.insert(image, for: url)
            
            return image
        }
        
        runningTasks[url] = task
        
        return try await task.value
    }
    
    private func removeTask(for url: URL) {
        runningTasks[url] = nil
    }
}
```

---

# ✅ 3️⃣ Public Image Loader API

```swift
final class ImageLoader {
    
    static func loadImage(from url: URL) async throws -> UIImage {
        
        if let cached = ImageCache.shared.image(for: url) {
            return cached
        }
        
        return try await ImageDownloadManager.shared.download(from: url)
    }
}
```

---

# 🔥 Why This Is Strong Design

### ✅ Deduplication

If 10 views request same image → only 1 network call.

### ✅ Thread Safe

Actor protects shared state.

### ✅ No Locks

Modern Swift concurrency.

### ✅ Memory Efficient

NSCache auto-evicts.

---

# 🚀 4️⃣ Add Concurrency Limit (Very Important)

We don’t want unlimited downloads.

We can add a semaphore inside actor:

```swift
actor ImageDownloadManager {
    
    private let semaphore = AsyncSemaphore(value: 4)
    ...
}
```

Since Swift doesn’t have built-in AsyncSemaphore, here’s a simple one:

```swift
actor AsyncSemaphore {
    
    private var value: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []
    
    init(value: Int) {
        self.value = value
    }
    
    func wait() async {
        if value > 0 {
            value -= 1
            return
        }
        
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
    
    func signal() {
        if waiters.isEmpty {
            value += 1
        } else {
            waiters.removeFirst().resume()
        }
    }
}
```

Then in download:

```swift
await semaphore.wait()
defer { semaphore.signal() }
```

Now max 4 concurrent downloads.

---

# ⭐ 5️⃣ Cancellation Support

Because we use `Task`, cancellation works automatically:

```swift
let task = Task {
    try await ImageLoader.loadImage(from: url)
}

task.cancel()
```

Inside download:

```swift
try Task.checkCancellation()
```

---

# 🧠 Interview-Level Talking Points

If asked:

> How would you design concurrent image downloader?

You answer:

1. Use memory cache (NSCache)
2. Use actor for deduplication
3. Track running tasks by URL
4. Limit concurrency
5. Support cancellation
6. Use URLSession
7. Avoid blocking threads
8. Ensure O(1) lookup

---

# 📊 Complexity

| Operation    | Time |
| ------------ | ---- |
| Cache lookup | O(1) |
| Dedup lookup | O(1) |
| Insert       | O(1) |

Memory: O(n images)

---

# 🏆 How Nuke / Kingfisher Do It

Libraries like:

* Nuke
* Kingfisher

Use:

* Memory cache
* Disk cache
* Request coalescing
* Priority handling
* Background decoding
* Progressive loading

---

# 🔥 Senior-Level Enhancements

You can further add:

* Disk cache (FileManager)
* Image decoding on background thread
* Priority queues
* Retry strategy
* Prefetching
* Progressive JPEG support
* Combine wrapper
* URLSessionConfiguration tuning

---

# 🎯 Final Interview-Perfect Summary

A production-ready concurrent image downloader in Swift should:

* Use NSCache for memory caching
* Use actor for thread safety
* Deduplicate in-flight requests
* Limit concurrency
* Support cancellation
* Avoid blocking threads
* Keep O(1) lookups
* Scale efficiently

---

If you want, I can next design:

* ⭐ Full production-level image pipeline
* ⭐ Disk + memory hybrid cache
* ⭐ Priority-aware downloader
* ⭐ SwiftUI integration version
* ⭐ Lock-free version (advanced)

Which level do you want? 🚀
