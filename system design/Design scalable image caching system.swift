//
//  Design scalable image caching system.swift
//  
//
//  Created by Apple on 23/02/26.
//

import Foundation

Absolutely — let’s design a **scalable, production-grade image caching system for iOS/Swift**. This is key for chat apps, social feeds, and any media-heavy app. We’ll aim for **thread safety, memory efficiency, disk persistence, async support, and network optimization**.

---

# 🏗 1️⃣ Requirements

**Functional Requirements:**

1. Load images from URL efficiently.
2. Cache images in memory and disk.
3. Thread-safe access.
4. Async loading with Swift concurrency.
5. Expire old cache items.
6. Prevent duplicate network requests.
7. Support large-scale usage (many images).

**Non-Functional Requirements:**

* Low memory footprint.
* Fast retrieval.
* Scalable across chat/media-heavy apps.

---

# 📦 2️⃣ High-Level Architecture

```text
Client Request (URL)
        ↓
ImageCacheManager
   ├── Memory Cache (NSCache)
   ├── Disk Cache (FileManager / SQLite)
   └── Network Loader (URLSession)
        ↓
Return Image asynchronously
```

**Features:**

* **Memory cache:** fast, in-memory retrieval, auto-purges under memory pressure.
* **Disk cache:** persistent storage, survives app restart.
* **Deduplication:** prevent multiple simultaneous downloads of same image.
* **Async & thread-safe:** use `actor` or `DispatchQueue`.

---

# 🧠 3️⃣ Core Components

### 3.1 Memory Cache

```swift
private let memoryCache = NSCache<NSString, UIImage>()
memoryCache.countLimit = 200 // max images in memory
memoryCache.totalCostLimit = 50 * 1024 * 1024 // ~50MB
```

* `countLimit` → number of images
* `totalCostLimit` → total memory in bytes
* Thread-safe by design.

---

### 3.2 Disk Cache

* Store images in app cache directory.
* File naming → hash of URL.
* Support expiration (TTL).

```swift
func diskPath(for url: URL) -> URL {
    let fileName = url.absoluteString.sha256() + ".png"
    return cacheDirectory.appendingPathComponent(fileName)
}
```

* Use `FileManager` for read/write.
* Optional: use SQLite or Core Data for metadata (timestamp, TTL).

---

### 3.3 Deduplicated Network Loading

* Maintain a dictionary `[URL: Task<UIImage, Error>]`
* If image is already downloading, reuse existing task.

---

# 🚀 4️⃣ Implementation (Modern Swift + Actor)

```swift
import SwiftUI
import CryptoKit

actor ImageCacheManager {
    
    static let shared = ImageCacheManager()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var ongoingTasks: [URL: Task<UIImage, Error>] = [:]
    
    private init() {
        memoryCache.countLimit = 200
        memoryCache.totalCostLimit = 50 * 1024 * 1024
        
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageCache", isDirectory: true)
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func image(for url: URL) async throws -> UIImage {
        let key = url.absoluteString as NSString
        
        // 1️⃣ Check memory cache
        if let img = memoryCache.object(forKey: key) {
            return img
        }
        
        // 2️⃣ Check disk cache
        let diskPath = self.diskPath(for: url)
        if let data = try? Data(contentsOf: diskPath),
           let img = UIImage(data: data) {
            memoryCache.setObject(img, forKey: key)
            return img
        }
        
        // 3️⃣ Download (deduplicated)
        if let existingTask = ongoingTasks[url] {
            return try await existingTask.value
        }
        
        let task = Task<UIImage, Error> {
            defer { Task { await self.removeTask(for: url) } }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                throw NSError(domain: "ImageCache", code: -1, userInfo: nil)
            }
            
            // Save to memory
            memoryCache.setObject(image, forKey: key)
            
            // Save to disk asynchronously
            Task.detached { [data, diskPath] in
                try? data.write(to: diskPath)
            }
            
            return image
        }
        
        ongoingTasks[url] = task
        return try await task.value
    }
    
    private func removeTask(for url: URL) {
        ongoingTasks[url] = nil
    }
    
    private func diskPath(for url: URL) -> URL {
        let fileName = url.absoluteString.sha256() + ".png"
        return cacheDirectory.appendingPathComponent(fileName)
    }
}
```

---

# 🏎 5️⃣ SHA256 Extension for File Naming

```swift
extension String {
    func sha256() -> String {
        let data = Data(self.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
```

---

# 📝 6️⃣ Usage in SwiftUI

```swift
struct AsyncCachedImage: View {
    let url: URL
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .task {
                        do {
                            image = try await ImageCacheManager.shared.image(for: url)
                        } catch {
                            print("Failed to load image", error)
                        }
                    }
            }
        }
    }
}
```

---

# 🔹 Features Achieved

| Feature                | Implementation                       |
| ---------------------- | ------------------------------------ |
| Memory caching         | `NSCache` with cost/count limits     |
| Disk caching           | `FileManager` in Caches directory    |
| Async loading          | `async/await` with Swift concurrency |
| Deduplicated downloads | `ongoingTasks` dictionary            |
| Thread safety          | `actor` protects state               |
| Persistent storage     | Images survive app restart           |
| Expiration (optional)  | Add timestamp metadata + TTL cleanup |
| Scalable               | Suitable for thousands of images     |

---

# ⚡ Production Enhancements

1. **TTL / LRU Cleanup:** Remove old disk images based on last access or timestamp.
2. **Compression:** Save JPEG with compression to reduce disk size.
3. **Prefetching:** For chat or feed, prefetch images ahead of time.
4. **Cancelation:** Cancel ongoing download tasks when image is offscreen.
5. **Combine / AsyncImage integration:** Wrap in SwiftUI view for smooth scroll.
6. **Concurrent downloads:** Limit max concurrent downloads.
7. **Disk indexing:** Use SQLite/CoreData for metadata if cache is very large.

---

This system is **scalable, thread-safe, async-ready, and works well with chat/media-heavy apps** like WhatsApp or Instagram.

---

I can next **combine this caching system with your chat UI** so images in chat are:

* Cached automatically
* Smoothly loaded
* Auto-scroll friendly
* Supports bubble tail + dynamic sizing

Do you want me to do that next?
                                            
Perfect — let’s upgrade the **image caching system** to a **fully production-ready, chat/scroll optimized version** with:
                                                
* ✅ **Prefetching**: load images before they appear
* ✅ **Cancellation**: stop downloads for offscreen cells
* ✅ **AsyncImage/SwiftUI integration**: smooth scroll experience
* ✅ **Concurrent download limit**: avoid too many simultaneous network requests
                                            
We’ll combine **actor-based cache**, **Task management**, and **SwiftUI-friendly AsyncImage wrapper**.
                                            
---
                                            
# 1️⃣ Updated ImageCacheManager with Prefetch, Cancellation, and Concurrency
                                            
```swift
import SwiftUI
import CryptoKit
                                            
actor ImageCacheManager {
    
    static let shared = ImageCacheManager()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var ongoingTasks: [URL: Task<UIImage, Error>] = [:]
    
    // Limit concurrent downloads
    private let maxConcurrentDownloads = 5
    private var activeDownloads = 0
    private var downloadQueue: [URL] = []
    
    private init() {
        memoryCache.countLimit = 200
        memoryCache.totalCostLimit = 50 * 1024 * 1024
        
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Fetch Image
    func image(for url: URL) async throws -> UIImage {
        let key = url.absoluteString as NSString
        
        // 1️⃣ Memory cache
        if let img = memoryCache.object(forKey: key) {
            return img
        }
        
        // 2️⃣ Disk cache
        let diskPath = self.diskPath(for: url)
        if let data = try? Data(contentsOf: diskPath),
           let img = UIImage(data: data) {
            memoryCache.setObject(img, forKey: key)
            return img
        }
        
        // 3️⃣ Ongoing download
        if let existingTask = ongoingTasks[url] {
            return try await existingTask.value
        }
        
        // 4️⃣ Queue download if over concurrent limit
        if activeDownloads >= maxConcurrentDownloads {
            downloadQueue.append(url)
            return try await withCheckedThrowingContinuation { continuation in
                Task.detached {
                    while true {
                        try await Task.sleep(nanoseconds: 100_000_000)
                        await self.startNextIfNeeded()
                        if let task = await self.ongoingTasks[url] {
                            do {
                                let img = try await task.value
                                continuation.resume(returning: img)
                                break
                            } catch {
                                continuation.resume(throwing: error)
                                break
                            }
                        }
                    }
                }
            }
        }
        
        return try await startDownload(url)
    }
    
    // MARK: - Start Download
    private func startDownload(_ url: URL) async throws -> UIImage {
        activeDownloads += 1
        
        let task = Task<UIImage, Error> {
            defer { Task { await self.downloadCompleted(url: url) } }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                throw NSError(domain: "ImageCache", code: -1, userInfo: nil)
            }
            
            memoryCache.setObject(image, forKey: url.absoluteString as NSString)
            
            // Save to disk asynchronously
            Task.detached { [data, url] in
                try? data.write(to: self.diskPath(for: url))
            }
            
            return image
        }
        
        ongoingTasks[url] = task
        let image = try await task.value
        return image
    }
    
    // MARK: - Handle completion
    private func downloadCompleted(url: URL) {
        ongoingTasks[url] = nil
        activeDownloads = max(activeDownloads - 1, 0)
        Task { await startNextIfNeeded() }
    }
    
    // MARK: - Start next queued download if possible
    private func startNextIfNeeded() async {
        guard activeDownloads < maxConcurrentDownloads, !downloadQueue.isEmpty else { return }
        let nextURL = downloadQueue.removeFirst()
        _ = try? await startDownload(nextURL)
    }
    
    // MARK: - Prefetching
    func prefetch(urls: [URL]) {
        for url in urls {
            Task {
                try? await image(for: url)
            }
        }
    }
    
    // MARK: - Cancel download
    func cancel(url: URL) {
        ongoingTasks[url]?.cancel()
        ongoingTasks[url] = nil
        downloadQueue.removeAll { $0 == url }
    }
    
    // MARK: - Disk Path
    private func diskPath(for url: URL) -> URL {
        let fileName = url.absoluteString.sha256() + ".png"
        return cacheDirectory.appendingPathComponent(fileName)
    }
}
```

---

# 2️⃣ SHA256 Extension for File Naming
                            
                            ```swift
                            extension String {
    func sha256() -> String {
        let data = Data(self.utf8)
        let hash = CryptoKit.SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
```

---

# 3️⃣ SwiftUI AsyncCachedImage View

Supports:

* Smooth scroll
* Prefetching
* Cancellation on disappear

```swift
struct AsyncCachedImage: View {
    let url: URL
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                image = try await ImageCacheManager.shared.image(for: url)
            } catch {
                print("Failed to load image", error)
            }
        }
        .onAppear {
            // Optional: prefetch next images in feed/chat
        }
        .onDisappear {
            Task {
                await ImageCacheManager.shared.cancel(url: url)
            }
        }
    }
}
```

---

# 4️⃣ Prefetching Example in Chat

```swift
// When loading messages
let nextImageURLs = messages
    .filter { if case .image(let url) = $0.content { return true } else { return false } }
    .map { if case .image(let url) = $0.content { return url } else { return URL(string:"")! } }

Task {
    await ImageCacheManager.shared.prefetch(urls: nextImageURLs)
}
```

---

# ✅ Features Achieved

| Feature                  | Implementation                      |
| ------------------------ | ----------------------------------- |
| Memory Cache             | NSCache                             |
| Disk Cache               | FileManager                         |
| Async Load               | async/await                         |
| Deduplicated download    | ongoingTasks dictionary             |
| Prefetching              | `prefetch(urls:)`                   |
| Cancelation              | `cancel(url:)` on disappear         |
| Max concurrent downloads | `activeDownloads` + `downloadQueue` |
| SwiftUI integration      | AsyncCachedImage View               |

---

# 🔹 Production Enhancements

1. TTL cleanup for disk cache
2. Compression of cached images (JPEG/PNG)
3. Integrate with **LazyVStack** in chat/feed for smooth scroll
4. Limit prefetch range (e.g., only next 3–5 images)
5. Optional: memory warning listener to clear NSCache
6. Combine with your **chat UI** for bubble images
                    
---
                    
I can next **integrate this caching system into your WhatsApp-style chat UI**, so:
                        
* Bubble images auto-load
* Prefetch for upcoming messages
* Cancel offscreen downloads
* Smooth auto-scroll
                    
