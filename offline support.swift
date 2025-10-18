//
//  offline support.swift
//  
//
//  Created by Apple on 18/10/25.
//

import Foundation

Handling **offline mechanisms** in iOS using **SwiftUI** involves designing your app to gracefully work even without a network connection. This is essential for a good user experience, especially when dealing with unreliable connectivity.

Here's a breakdown of how to handle offline support in a SwiftUI app:

---

### ✅ Key Strategies for Offline Support

1. **Check Network Connectivity**
2. **Cache or Persist Data Locally**
3. **Queue Offline Actions for Syncing Later**
4. **Provide User Feedback**
5. **Handle Syncing Once Online**

---

### 1. 🕸️ Check Network Connectivity

Use **`NWPathMonitor`** (from Network framework) to detect internet availability.

```swift
import Network

class NetworkMonitor: ObservableObject {
    private var monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    @Published var isConnected = true

    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
```

Use it in SwiftUI:

```swift
@StateObject var networkMonitor = NetworkMonitor()

var body: some View {
    if networkMonitor.isConnected {
        Text("Online")
    } else {
        Text("Offline Mode")
    }
}
```

---

### 2. 💾 Cache or Persist Data Locally

Use **Core Data**, **Realm**, or **UserDefaults** to store data offline.

Example using `UserDefaults` (for simple cases):

```swift
UserDefaults.standard.set("Some cached data", forKey: "offlineData")
let data = UserDefaults.standard.string(forKey: "offlineData")
```

For more complex data: **Core Data or Realm** is better.

---

### 3. ⏳ Queue Offline Actions (e.g., API calls)

Store user actions (like form submissions or messages) in a local queue when offline, and sync later.

Example:

```swift
struct OfflineAction: Codable {
    let type: String
    let payload: Data
}

class OfflineActionQueue {
    static let shared = OfflineActionQueue()

    private let key = "offlineQueue"

    func enqueue(_ action: OfflineAction) {
        var currentQueue = fetchQueue()
        currentQueue.append(action)
        saveQueue(currentQueue)
    }

    func fetchQueue() -> [OfflineAction] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let queue = try? JSONDecoder().decode([OfflineAction].self, from: data) else {
            return []
        }
        return queue
    }

    func saveQueue(_ queue: [OfflineAction]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func clearQueue() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
```

---

### 4. 🔁 Sync When Back Online

When network becomes available again:

```swift
func syncOfflineActions() {
    let queue = OfflineActionQueue.shared.fetchQueue()

    for action in queue {
        // Convert and send action to server
        // If successful, remove it from queue
    }

    OfflineActionQueue.shared.clearQueue()
}
```

Tie it with `NetworkMonitor`:

```swift
.onChange(of: networkMonitor.isConnected) { isConnected in
    if isConnected {
        syncOfflineActions()
    }
}
```

---

### 5. 🧠 UX Considerations

* Show "Offline Mode" banners.
* Disable or visually mute actions that require connectivity.
* Add retry buttons or sync spinners.
* Indicate last synced time.

---

### Tools & Libraries to Consider

* **Network.framework** – For network reachability
* **Core Data / Realm** – For local data persistence
* **Combine** – For reactive handling of network + data changes
* **BackgroundTasks** – To sync when app is in background

---

### Summary

| Component       | Responsibility                       |
| --------------- | ------------------------------------ |
| `NWPathMonitor` | Detect online/offline status         |
| Core Data/Realm | Store data locally                   |
| Offline Queue   | Queue changes/actions for later sync |
| Sync Logic      | Retry queued tasks when online       |
| UX Feedback     | Let users know app is offline        |

---

Since you're building a **news/content app**, offline support focuses on **caching articles or media for offline reading**, and **showing appropriate UI when there's no connection**.
                                                
Here’s a complete guide tailored for **offline support in a SwiftUI news app**:
                                                    
---
                                                    
## ✅ What You Need to Handle
                                                
| Feature                         | Solution                                  |
| ------------------------------- | ----------------------------------------- |
| Detect network availability     | `NWPathMonitor` or 3rd-party libs         |
| Cache fetched articles locally  | Use `Core Data`, `Realm`, or local files  |
| Load cached data when offline   | Fallback to stored articles               |
| Show offline banner / indicator | SwiftUI UI updates based on network state |
                                                
---
                                                
## 🔁 Basic Flow
                                                
```text
User opens app
├─ If online:
│    ├─ Fetch articles from API
│    ├─ Save them locally (cache)
├─ If offline:
├─ Load articles from local cache
```
                                                
---
                                                
## 🧱 Step-by-Step Implementation
                                                
---
                                                
### 1. 📶 Detect Internet Connection
                                                
Use `NetworkMonitor` to detect if you're online/offline:
                                                    
```swift
import Network
import Combine
                                                
class NetworkMonitor: ObservableObject {
    private var monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    
    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
```

Use in your SwiftUI view:

```swift
@StateObject var networkMonitor = NetworkMonitor()

if !networkMonitor.isConnected {
    Text("You are offline").foregroundColor(.red)
}
```

---

### 2. 💾 Store Articles Offline (Using Codable + FileManager or Core Data)

Here’s a simple approach using Codable + FileManager.

#### Define your `Article` model:

```swift
struct Article: Codable, Identifiable {
    let id: UUID
    let title: String
    let content: String
}
```

#### Create a CacheManager:

```swift
class ArticleCache {
    private let fileName = "cached_articles.json"
    
    private var fileURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent(fileName)
    }
    
    func save(_ articles: [Article]) {
        do {
            let data = try JSONEncoder().encode(articles)
            try data.write(to: fileURL)
        } catch {
            print("Error saving articles:", error)
        }
    }
    
    func load() -> [Article] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([Article].self, from: data)
        } catch {
            print("Error loading cached articles:", error)
            return []
        }
    }
}
```

---

### 3. 🔄 Fetch and Cache Articles

```swift
class ArticleViewModel: ObservableObject {
    @Published var articles: [Article] = []
    
    private let cache = ArticleCache()
    private var cancellables = Set<AnyCancellable>()
    private let networkMonitor = NetworkMonitor()
    
    init() {
        loadArticles()
    }
    
    func loadArticles() {
        if networkMonitor.isConnected {
            fetchFromAPI()
        } else {
            loadFromCache()
        }
    }
    
    func fetchFromAPI() {
        // Replace with your actual API call
        let dummyArticles = [
            Article(id: UUID(), title: "Online Article 1", content: "Some content..."),
            Article(id: UUID(), title: "Online Article 2", content: "More content...")
        ]
        
        // Simulate delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.articles = dummyArticles
            self.cache.save(dummyArticles)
        }
    }
    
    func loadFromCache() {
        self.articles = cache.load()
    }
}
```

---

### 4. 🧑‍🎨 Show Articles in SwiftUI

```swift
struct ArticleListView: View {
    @StateObject var viewModel = ArticleViewModel()
    @StateObject var networkMonitor = NetworkMonitor()
    
    var body: some View {
        NavigationView {
            VStack {
                if !networkMonitor.isConnected {
                    Text("You are offline").foregroundColor(.red)
                }
                
                List(viewModel.articles) { article in
                    VStack(alignment: .leading) {
                        Text(article.title).font(.headline)
                        Text(article.content).font(.subheadline)
                    }
                }
            }
            .navigationTitle("News")
        }
    }
}
```

---

## 🔔 Bonus Tips

### 🧠 Improve with Core Data (optional)

Use Core Data for more scalable and persistent storage (especially with images, large text, syncing, etc.).
                    
### 📸 Cache Images
                    
Use libraries like **SDWebImageSwiftUI** or cache manually using `URLCache`.
                    
### 📱 Background Fetch
                    
Enable **Background Fetch** to pre-download articles even before the user opens the app.
                    
---
                    
## ✅ Final Outcome
                    
* ✅ App works offline
* ✅ Cached articles shown when offline
* ✅ New articles fetched and saved when back online
* ✅ Offline banner shown clearly
                    
                    ---
                    
Would you like me to help you **implement image caching**, **Core Data version**, or **background syncing** next?

Perfect — let’s go deep! Below is a **complete guide** to building a **news/content app with full offline support** in **SwiftUI**, covering:
                        
---
                        
### 🔎 What We'll Cover:
                        
1. ✅ Image Caching (with or without libraries)
2. 🗃️ Core Data for Persistent Article Storage
3. 🔄 Background Fetch for Preloading Content
                    
Each section includes sample code, when to use it, and how to combine it into your app architecture.
                    
---
                    
## 1. ✅ Image Caching in SwiftUI
                    
### 📌 Why:
                        
News apps often load thumbnail images. You need to **cache images** so users don’t re-download them when offline.
                    
---
                    
### Option A: Use **SDWebImageSwiftUI** (recommended)
                    
#### ✅ Pros:
                        
* Handles disk/memory caching out of the box
* SwiftUI-ready
* Actively maintained
                    
#### 🧪 Install:
                        
```bash
https://github.com/SDWebImage/SDWebImageSwiftUI
```
                    
Using Swift Package Manager:
`File > Add Packages > Paste URL`
                    
#### 🧩 Usage:
                        
```swift
import SDWebImageSwiftUI
                    
struct ArticleRowView: View {
    var article: Article
    
    var body: some View {
        HStack {
            WebImage(url: URL(string: article.imageURL))
                .resizable()
                .placeholder {
                    Rectangle().foregroundColor(.gray)
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text(article.title).font(.headline)
                Text(article.summary).font(.subheadline)
            }
        }
    }
}
```

> SDWebImage automatically caches the image locally for offline use.
                                                            
---
                                                            
### Option B: Manual Image Caching (if you don’t want a library)
                                                            
```swift
class ImageCache {
    static let shared = NSCache<NSString, UIImage>()
    
    static func getImage(url: URL, completion: @escaping (UIImage?) -> Void) {
        if let cached = shared.object(forKey: url.absoluteString as NSString) {
            completion(cached)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            shared.setObject(image, forKey: url.absoluteString as NSString)
            completion(image)
        }.resume()
    }
}
```

Use in a `@State`-driven view:

```swift
struct CachedImageView: View {
    let url: URL
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image).resizable()
            } else {
                ProgressView()
            }
        }
        .onAppear {
            ImageCache.getImage(url: url) { img in
                self.image = img
            }
        }
    }
}
```

---

## 2. 🗃️ Core Data for Offline Articles
                            
### 📌 Why:
                                
Use **Core Data** for long-term storage (hundreds/thousands of articles), relationships (tags, authors), and syncing.
                            
---
                            
### 🛠️ Step-by-Step:
                                
#### ✅ Step 1: Create Core Data Model
                            
* Open `.xcdatamodeld`
* Add Entity: `CDArticle`
                            
* `id: UUID`
* `title: String`
* `content: String`
* `imageURL: String`
* `date: Date`
                            
---
                            
#### ✅ Step 2: Set up Core Data Stack (or use SwiftData in iOS 17+)
                            
Using `PersistenceController.swift`:
                                
```swift
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "NewsModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data load failed: \(error)")
            }
        }
    }
}
```

---

#### ✅ Step 3: Save Articles

```swift
func saveArticlesToCoreData(_ articles: [Article], context: NSManagedObjectContext) {
    for article in articles {
        let cdArticle = CDArticle(context: context)
        cdArticle.id = article.id
        cdArticle.title = article.title
        cdArticle.content = article.content
        cdArticle.imageURL = article.imageURL
        cdArticle.date = Date()
    }
    
    try? context.save()
}
```

---

#### ✅ Step 4: Fetch Articles from Core Data

```swift
func fetchArticlesFromCoreData(context: NSManagedObjectContext) -> [Article] {
    let request: NSFetchRequest<CDArticle> = CDArticle.fetchRequest()
    let results = try? context.fetch(request)
    
    return results?.map {
        Article(
            id: $0.id ?? UUID(),
            title: $0.title ?? "",
            content: $0.content ?? "",
            imageURL: $0.imageURL ?? ""
        )
    } ?? []
}
```

---

## 3. 🔄 Background Fetch (Preload Content While App is Inactive)

### 📌 Why:

Even when the user hasn’t opened the app, you can **fetch new articles silently** using background fetch.

---

### ⚙️ Enable Background Fetch

#### ✅ In Xcode:

1. Go to project settings > *Capabilities*
2. Enable **Background Modes**
3. Check ✅ **Background fetch**

---

### 🧠 AppDelegate Method

```swift
func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    ArticleService.fetchLatestArticles { result in
        switch result {
        case .success(let articles):
            // Save to Core Data
            saveArticlesToCoreData(articles, context: PersistenceController.shared.container.viewContext)
            completionHandler(.newData)
        case .failure:
            completionHandler(.failed)
        }
    }
}
```

Make sure `ArticleService` is a helper class that fetches articles from your backend.

---

## 🧱 Integrating Everything: Architecture Summary

| Layer         | Tech                         | Purpose                        |
| ------------- | ---------------------------- | ------------------------------ |
| UI            | SwiftUI                      | Displays articles              |
| Caching       | SDWebImage / Manual          | Caches images                  |
| Storage       | Core Data                    | Stores article content offline |
| Network Check | `NWPathMonitor`              | Determines online/offline      |
| Syncing       | Background Fetch + ViewModel | Auto-fetches + manual reload   |

---

## ✅ Offline Experience: What the User Gets

* Articles are **still visible** without internet
* Images are **cached** and displayed offline
* New articles are **fetched silently** in the background
* UI clearly **shows offline state** (e.g., red banner)

---

### Want a Starter Project?

I can scaffold a SwiftUI starter app with:

* Core Data model
* Network monitor
* Cached API calls
* Background fetch support
* SDWebImage integration

Let me know and I’ll prepare the base code for you to extend!
                                                
                                                
