//
//  Describe a concurrency bug you've encountered and how you resolved it..swift
//  
//
//  Created by Apple on 27/08/25.
//

import Foundation

Sure — here’s a real-world-style concurrency bug that often occurs in iOS apps, especially when working with shared mutable state in background threads.

---

## 🐞 **The Bug: Race Condition in Shared Cache**

### 🧩 Context:

In an image-heavy app, we had an **in-memory image cache** implemented using a `class`:

```swift
class ImageCache {
    private var cache: [URL: UIImage] = [:]

    func set(_ image: UIImage, for url: URL) {
        cache[url] = image
    }

    func get(for url: URL) -> UIImage? {
        return cache[url]
    }
}
```

Multiple concurrent `URLSession` download tasks were fetching and caching images. It worked fine in testing — but in production, we started seeing:

* Crashes like: `EXC_BAD_ACCESS` or `dictionary mutated while being enumerated`
* Images not appearing randomly
* Rare, hard-to-reproduce bugs

### ⚠️ Cause:

This was a **classic race condition**:

* Multiple threads were **reading/writing to the `cache` dictionary simultaneously**.
* Since dictionaries aren’t thread-safe in Swift, concurrent access led to **undefined behavior and crashes**.

---

## ✅ **The Fix: Use an Actor for Thread-Safety**

We replaced the class with a **Swift actor**, which serializes all access to its internal state:

```swift
actor ImageCache {
    private var cache: [URL: UIImage] = [:]

    func set(_ image: UIImage, for url: URL) {
        cache[url] = image
    }

    func get(for url: URL) -> UIImage? {
        return cache[url]
    }
}
```

### 🧪 Usage:

```swift
let imageCache = ImageCache()

// Called from multiple async contexts:
Task {
    if let image = await imageCache.get(for: url) {
        imageView.image = image
    } else {
        let image = try await downloadImage(url)
        await imageCache.set(image, for: url)
        imageView.image = image
    }
}
```

---

## 🎯 Result

✅ **Fixed the crash**
✅ **Made cache access safe**
✅ **Removed the need for custom locking or serial queues**

This change also improved **code clarity** — no more worrying about synchronizing access to shared state. The actor handles it.

---

## 🧠 Takeaway

> When you’re sharing mutable state across concurrent tasks, using an **`actor`** is usually the safest and cleanest way to prevent concurrency bugs in Swift.

Would you like a SwiftUI example that uses this actor-based cache in practice?

Great! Here's a **complete SwiftUI example** that uses an `actor`-based `ImageCache` to safely manage image downloads and caching across multiple views or tasks — with **no risk of concurrency bugs**.
                            
                            ---
                            
## ✅ Goal:
                                
* Load remote images from URLs
* Cache them in memory
* Avoid downloading the same image multiple times
* Prevent crashes from concurrent access
                            
                            ---
                            
## 🧱 Step 1: Define the `ImageCache` Actor
                            
```swift
import SwiftUI
                            
actor ImageCache {
    private var cache: [URL: UIImage] = [:]
    
    func image(for url: URL) -> UIImage? {
        return cache[url]
    }
    
    func set(_ image: UIImage, for url: URL) {
        cache[url] = image
    }
}
```

---

## 🌐 Step 2: Create an `ImageLoader` ViewModel

This class handles downloading the image and caching it using our actor.

```swift
@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    private static let cache = ImageCache()
    
    func load(from url: URL) {
        Task {
            if let cached = await Self.cache.image(for: url) {
                self.image = cached
                return
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return }
                
                await Self.cache.set(image, for: url)
                
                self.image = image
            } catch {
                print("Failed to load image: \(error)")
            }
        }
    }
}
```

> 🔐 Note: The cache is shared **statically**, but its access is safe due to `actor`.

---

## 🖼️ Step 3: Create a SwiftUI `RemoteImageView`

```swift
struct RemoteImageView: View {
    @StateObject private var loader = ImageLoader()
    let url: URL
    let placeholder: Image
    
    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                placeholder
                    .resizable()
                    .scaledToFit()
            }
        }
        .onAppear {
            loader.load(from: url)
        }
    }
}
```

---

## 🧪 Step 4: Test in a List or ScrollView

```swift
struct ContentView: View {
    let imageUrls = [
        URL(string: "https://picsum.photos/id/1003/400/300")!,
        URL(string: "https://picsum.photos/id/1011/400/300")!,
        URL(string: "https://picsum.photos/id/1021/400/300")!,
        URL(string: "https://picsum.photos/id/1033/400/300")!
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(imageUrls, id: \.self) { url in
                    RemoteImageView(url: url, placeholder: Image(systemName: "photo"))
                        .frame(height: 200)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
        }
    }
}
```

---

## ✅ Why This Works Well

* 🧠 `ImageCache` is an `actor`, so all access is serialized and safe.
* 🎯 You can call it from any thread without crashing or blocking the main thread.
* 📦 Reuses images once downloaded (no duplicate network calls).
* 🔁 Easy to plug into larger apps or async pipelines.

---

Would you like to add **disk caching**, error retrying, or **loading indicators** next?
