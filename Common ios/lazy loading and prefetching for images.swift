//
//  lazy loading and prefetching for images.swift
//  
//
//  Created by Apple on 09/11/25.
//

import Foundation

Perfect! Let’s build a **complete SwiftUI example** that combines **lazy loading** and **prefetching** for images in a scrollable list, with caching to prevent redundant network requests.

---

## **Step 1: Image Cache Helper**

We need a simple cache to store downloaded images:

```swift
import SwiftUI

class ImageCache {
    static let shared = ImageCache()
    private init() {}
    
    private var cache = NSCache<NSURL, UIImage>()
    
    func getImage(url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
    
    func downloadImage(from url: URL, completion: ((UIImage?) -> Void)? = nil) {
        if let cached = getImage(url: url) {
            completion?(cached)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            var image: UIImage? = nil
            if let data = data, let uiImage = UIImage(data: data) {
                self.cache.setObject(uiImage, forKey: url as NSURL)
                image = uiImage
            }
            DispatchQueue.main.async {
                completion?(image)
            }
        }.resume()
    }
}
```

---

## **Step 2: Image View with Lazy Loading**

This view will load an image only when it appears:

```swift
struct LazyImageView: View {
    let url: URL
    @State private var image: UIImage? = nil

    var body: some View {
        Image(uiImage: image ?? UIImage(systemName: "photo")!)
            .resizable()
            .scaledToFit()
            .frame(height: 200)
            .onAppear {
                loadImage()
            }
    }

    private func loadImage() {
        guard image == nil else { return }
        ImageCache.shared.downloadImage(from: url) { downloaded in
            self.image = downloaded
        }
    }
}
```

---

## **Step 3: ContentView with Prefetching**

We’ll prefetch a few images ahead of the current scroll position:

```swift
struct ContentView: View {
    let imageURLs: [URL] = [
        // Replace with your image URLs
        URL(string: "https://via.placeholder.com/600/92c952")!,
        URL(string: "https://via.placeholder.com/600/771796")!,
        URL(string: "https://via.placeholder.com/600/24f355")!,
        URL(string: "https://via.placeholder.com/600/d32776")!,
        URL(string: "https://via.placeholder.com/600/f66b97")!,
        URL(string: "https://via.placeholder.com/600/56a8c2")!,
        URL(string: "https://via.placeholder.com/600/b0f7cc")!,
        URL(string: "https://via.placeholder.com/600/54176f")!
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(imageURLs.indices, id: \.self) { index in
                    LazyImageView(url: imageURLs[index])
                        .onAppear {
                            prefetchNext(index: index)
                        }
                }
            }
        }
    }
    
    private func prefetchNext(index: Int) {
        let prefetchRange = (index + 1)...min(index + 3, imageURLs.count - 1)
        for i in prefetchRange {
            ImageCache.shared.downloadImage(from: imageURLs[i])
        }
    }
}
```

---

## ✅ **How This Works**

1. **Lazy Loading:**

   * `LazyVStack` ensures only visible views are created.
   * `LazyImageView` loads images only when they appear.

2. **Prefetching:**

   * `.onAppear` of each image triggers a prefetch of the next 3 images.
   * Prefetched images are cached so scrolling is smooth.

3. **Caching:**

   * `NSCache` prevents duplicate downloads and saves bandwidth.

---

This setup is lightweight, smooth, and works well for scrollable lists with network images.

If you want, I can **enhance it further** to **cancel unnecessary downloads for off-screen images**, which makes it even more memory-efficient and performant—like `UITableView` prefetching in UIKit.

Do you want me to do that next?

Perfect! Let’s make the SwiftUI image loader even smarter by **cancelling unnecessary downloads for off-screen images**, just like UIKit prefetching does. This ensures smooth scrolling and better memory/network efficiency.
                                                        
---
                                                        
## **Step 1: Update the Image Cache with Cancel Support**
                                                        
We'll keep track of active download tasks and allow cancellation:
                                                            
```swift
import SwiftUI
                                                        
class ImageCache {
    static let shared = ImageCache()
    private init() {}
    
    private var cache = NSCache<NSURL, UIImage>()
    private var runningTasks = [URL: URLSessionDataTask]()
    
    func getImage(url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
    
    func downloadImage(from url: URL, completion: ((UIImage?) -> Void)? = nil) {
        // Return cached image if available
        if let cached = getImage(url: url) {
            completion?(cached)
            return
        }
        
        // Avoid duplicate tasks
        if runningTasks[url] != nil { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            var image: UIImage? = nil
            if let data = data, let uiImage = UIImage(data: data) {
                self.cache.setObject(uiImage, forKey: url as NSURL)
                image = uiImage
            }
            DispatchQueue.main.async {
                completion?(image)
            }
            self.runningTasks[url] = nil
        }
        runningTasks[url] = task
        task.resume()
    }
    
    func cancelDownload(for url: URL) {
        runningTasks[url]?.cancel()
        runningTasks[url] = nil
    }
}
```

✅ Now we can **cancel any download** if the user scrolls past the item.
                                            
---
                                            
## **Step 2: Update LazyImageView to Cancel Downloads**
                                            
```swift
struct LazyImageView: View {
    let url: URL
    @State private var image: UIImage? = nil
    
    var body: some View {
        Image(uiImage: image ?? UIImage(systemName: "photo")!)
            .resizable()
            .scaledToFit()
            .frame(height: 200)
            .onAppear {
                loadImage()
            }
            .onDisappear {
                cancelLoad()
            }
    }
    
    private func loadImage() {
        guard image == nil else { return }
        ImageCache.shared.downloadImage(from: url) { downloaded in
            self.image = downloaded
        }
    }
    
    private func cancelLoad() {
        ImageCache.shared.cancelDownload(for: url)
    }
}
```

✅ Key changes:

* `.onDisappear` cancels downloads for cells that scroll off-screen.
* Prevents wasted network requests and unnecessary memory usage.
                                        
---
                                        
## **Step 3: Prefetching in ContentView**
                                        
Prefetch logic remains mostly the same, but now downloads are cancellable:
                                            
```swift
struct ContentView: View {
    let imageURLs: [URL] = [
        URL(string: "https://via.placeholder.com/600/92c952")!,
        URL(string: "https://via.placeholder.com/600/771796")!,
        URL(string: "https://via.placeholder.com/600/24f355")!,
        URL(string: "https://via.placeholder.com/600/d32776")!,
        URL(string: "https://via.placeholder.com/600/f66b97")!,
        URL(string: "https://via.placeholder.com/600/56a8c2")!,
        URL(string: "https://via.placeholder.com/600/b0f7cc")!,
        URL(string: "https://via.placeholder.com/600/54176f")!
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(imageURLs.indices, id: \.self) { index in
                    LazyImageView(url: imageURLs[index])
                        .onAppear {
                            prefetchNext(index: index)
                        }
                        .onDisappear {
                            // Optional: cancel prefetch for nearby items if desired
                        }
                }
            }
        }
    }
    
    private func prefetchNext(index: Int) {
        let prefetchRange = (index + 1)...min(index + 3, imageURLs.count - 1)
        for i in prefetchRange {
            ImageCache.shared.downloadImage(from: imageURLs[i])
        }
    }
}
```

---

## **✅ Benefits of This Approach**

1. **Lazy Loading:** Only load images as they appear on screen.
2. **Prefetching:** Smooth scrolling by preloading the next few images.
3. **Caching:** Prevents duplicate network requests.
4. **Cancellation:** Stops downloads for off-screen cells to save memory and bandwidth.

