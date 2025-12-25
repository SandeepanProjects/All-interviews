//
//  photo-sharing feature.swift
//  
//
//  Created by Apple on 25/12/25.
//

import Foundation

Perfect! Let’s create a **visual architecture diagram** for the **offline-first photo-sharing feature** in SwiftUI using **MVVM + Clean Architecture + async/await**. I’ll describe it step by step so you could implement it or present it clearly.

---

## **1. Diagram Overview**

```
┌───────────────────────────────┐
│       Presentation Layer       │
│ ┌───────────────┐             │
│ │   FeedView    │<────────────┐│
│ │ PhotoDetailView│            ││
│ └───────────────┘             │
│        ▲                      │
│        │ binds to             │
│ ┌───────────────┐             │
│ │ FeedViewModel │             │
│ │ PhotoViewModel│             │
│ └───────────────┘             │
└─────────────▲─────────────────┘
              │ calls
┌─────────────┴─────────────────┐
│         Domain Layer           │
│ ┌───────────────────────────┐ │
│ │     UseCases / Interactors │ │
│ │ fetchFeed, uploadPhoto,   │ │
│ │ likePhoto                 │ │
│ └─────────────▲─────────────┘ │
└───────────────│──────────────┘
                │ uses
┌───────────────┴────────────────┐
│          Data Layer            │
│ ┌───────────────┐  ┌─────────┐│
│ │ Repository    │  │ Image   ││
│ │ PhotoRepository│ │ Cache   ││
│ └──────▲────────┘  └───▲─────┘│
│        │ calls            │    │
│ ┌──────┴─────────────┐    │    │
│ │ NetworkService     │    │    │
│ │ fetchFeed, upload  │    │    │
│ └────────▲───────────┘    │    │
│          │                 │    │
│ ┌────────┴─────────┐       │    │
│ │ LocalStorage     │◀──────┘    │
│ │ cached feed,     │            │
│ │ pending uploads  │            │
│ └─────────────────┘            │
└────────────────────────────────┘
```

---

## **2. Flow Explanation**

1. **Presentation Layer**

   * `FeedView` shows list of photos
   * `PhotoDetailView` shows one photo + likes
   * Views bind to **ViewModels** (`FeedViewModel`, `PhotoViewModel`) using `@StateObject` / `@Published`

2. **ViewModel Layer**

   * Calls **UseCases** to fetch feed, upload photo, like photo
   * Handles **offline logic**, e.g., showing cached feed first

3. **Domain Layer (UseCases)**

   * `FetchFeedUseCase` → tries cached data first, then network
   * `UploadPhotoUseCase` → writes to local storage first, then syncs
   * `LikePhotoUseCase` → optimistic UI update + network sync

4. **Data Layer**

   * **Repository** orchestrates Network + LocalStorage
   * **NetworkService** handles API calls asynchronously
   * **LocalStorage** caches photos, stores pending uploads, and persists image data
   * **ImageCache** ensures smooth scrolling

---

## **3. Offline + Caching Flow**

```
User opens Feed
        │
        ▼
FeedViewModel
        │
getCachedFeed() ─────────────► LocalStorage
        │                       (return cached photos immediately)
        ▼
fetchFeed() ───────────────► NetworkService
        │
        ▼
Network response ─────────► Repository
        │
        ▼
Update LocalStorage & UI
```

**Photo Upload Flow (Offline-ready):**

```
User uploads photo
        │
        ▼
FeedViewModel calls UploadPhotoUseCase
        │
Save photo to LocalStorage (pending)
        │
Try network upload via NetworkService
        │
Success → mark synced in LocalStorage
Fail → keep in pending queue, sync later
```

---

## **4. Notes on Image Caching**

* Use `NSCache` for in-memory caching
* Persist images in **LocalStorage** for offline feed
* `AsyncImage` fallback → load from cache if offline

---

If you want, I can also make a **fully labeled SwiftUI navigation + data flow diagram**, showing **all screens, viewmodels, repositories, local storage, network, and sync flow**—almost like a blueprint you could hand to a team or use for implementation.

Do you want me to create that full blueprint next?


Absolutely! Let’s design a **photo-sharing feature** in **SwiftUI**, fully **offline-capable**, using **MVVM + Clean Architecture + async/await**, with **caching** for images. I’ll break it down step by step: architecture, caching, offline strategy, data flow, and SwiftUI implementation.

---

## **1. Architecture Overview (Clean + MVVM)**

```
Presentation Layer (SwiftUI + ViewModel)
        ↓
Domain Layer (Entities + Use Cases)
        ↓
Data Layer (Repositories → Network + Local Storage)
```

**Layers explained:**

1. **Presentation Layer:**

   * SwiftUI views: feed, photo upload, photo detail
   * ViewModels manage state and call UseCases

2. **Domain Layer:**

   * Entities: Photo, User, Comment
   * UseCases: fetchFeed, uploadPhoto, likePhoto
   * Pure business logic, no dependencies on networking or storage

3. **Data Layer:**

   * Repositories implement domain protocols
   * Network service: API calls
   * Local storage: caching images & metadata for offline access
   * Offline-first strategy: always show cached feed first

---

## **2. Core Entities**

```swift
struct Photo: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    let username: String
    let imageURL: URL?
    let caption: String
    let timestamp: Date
    var likes: Int
    var isLiked: Bool
}
```

---

## **3. Repository Protocols (Domain Layer)**

```swift
protocol PhotoRepository {
    func fetchFeed() async throws -> [Photo]
    func getCachedFeed() async -> [Photo]
    func uploadPhoto(imageData: Data, caption: String) async throws -> Photo
    func likePhoto(photoId: String) async throws
}
```

---

## **4. Use Cases (Domain Layer)**

```swift
struct FetchFeedUseCase {
    private let repository: PhotoRepository

    init(repository: PhotoRepository) {
        self.repository = repository
    }

    func execute() async -> [Photo] {
        var photos = await repository.getCachedFeed() // first, load cached
        do {
            photos = try await repository.fetchFeed()  // refresh from network
        } catch {
            // offline, return cached feed
        }
        return photos
    }
}
```

```swift
struct UploadPhotoUseCase {
    private let repository: PhotoRepository

    init(repository: PhotoRepository) {
        self.repository = repository
    }

    func execute(imageData: Data, caption: String) async throws -> Photo {
        try await repository.uploadPhoto(imageData: imageData, caption: caption)
    }
}
```

---

## **5. Data Layer Implementation**

### **Repository Implementation (Offline-first)**

```swift
final class PhotoRepositoryImpl: PhotoRepository {
    private let networkService: NetworkService
    private let localStorage: LocalStorage
    private let imageCache: ImageCache

    init(networkService: NetworkService, localStorage: LocalStorage, imageCache: ImageCache) {
        self.networkService = networkService
        self.localStorage = localStorage
        self.imageCache = imageCache
    }

    func fetchFeed() async throws -> [Photo] {
        let photos = try await networkService.fetchFeed()
        await localStorage.savePhotos(photos)
        return photos
    }

    func getCachedFeed() async -> [Photo] {
        return await localStorage.getPhotos()
    }

    func uploadPhoto(imageData: Data, caption: String) async throws -> Photo {
        // save locally first
        let tempPhoto = Photo(id: UUID().uuidString,
                              userId: "me",
                              username: "Me",
                              imageURL: nil,
                              caption: caption,
                              timestamp: Date(),
                              likes: 0,
                              isLiked: false)
        await localStorage.addPhoto(tempPhoto, imageData: imageData)
        
        do {
            let uploadedPhoto = try await networkService.uploadPhoto(imageData: imageData, caption: caption)
            await localStorage.updatePhoto(uploadedPhoto)
            return uploadedPhoto
        } catch {
            // mark as pending upload for background sync
            await localStorage.markPhotoPendingUpload(tempPhoto)
            return tempPhoto
        }
    }

    func likePhoto(photoId: String) async throws {
        try await networkService.likePhoto(photoId: photoId)
        await localStorage.updatePhotoLikeStatus(photoId: photoId)
    }
}
```

---

### **Network Service (Async/Await)**

```swift
actor NetworkService {
    func fetchFeed() async throws -> [Photo] {
        let url = URL(string: "https://api.example.com/photos")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Photo].self, from: data)
    }

    func uploadPhoto(imageData: Data, caption: String) async throws -> Photo {
        // implement multipart upload
        // return uploaded Photo object
        fatalError("Implement API upload")
    }

    func likePhoto(photoId: String) async throws {
        // send like API
    }
}
```

---

### **Local Storage & Image Cache**

```swift
actor LocalStorage {
    private var photos: [Photo] = []
    private var photoImages: [String: Data] = [:]
    private var pendingUploads: [Photo] = []

    func savePhotos(_ newPhotos: [Photo]) async {
        self.photos = newPhotos
    }

    func getPhotos() async -> [Photo] {
        return photos
    }

    func addPhoto(_ photo: Photo, imageData: Data) async {
        photos.append(photo)
        photoImages[photo.id] = imageData
    }

    func updatePhoto(_ photo: Photo) async {
        if let index = photos.firstIndex(where: { $0.id == photo.id }) {
            photos[index] = photo
        }
    }

    func markPhotoPendingUpload(_ photo: Photo) async {
        pendingUploads.append(photo)
    }

    func getImage(for photoId: String) async -> UIImage? {
        guard let data = photoImages[photoId] else { return nil }
        return UIImage(data: data)
    }
}
```

**Optional:** Use `NSCache` or `Kingfisher` style caching for in-memory images.

---

## **6. SwiftUI + ViewModel**

```swift
@MainActor
final class FeedViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchFeedUseCase: FetchFeedUseCase
    private let uploadPhotoUseCase: UploadPhotoUseCase
    private let repository: PhotoRepository

    init(fetchFeedUseCase: FetchFeedUseCase,
         uploadPhotoUseCase: UploadPhotoUseCase,
         repository: PhotoRepository) {
        self.fetchFeedUseCase = fetchFeedUseCase
        self.uploadPhotoUseCase = uploadPhotoUseCase
        self.repository = repository
    }

    func loadFeed() async {
        isLoading = true
        defer { isLoading = false }
        photos = await fetchFeedUseCase.execute()
    }

    func uploadPhoto(imageData: Data, caption: String) async {
        do {
            let newPhoto = try await uploadPhotoUseCase.execute(imageData: imageData, caption: caption)
            photos.insert(newPhoto, at: 0)
        } catch {
            errorMessage = "Failed to upload photo"
        }
    }

    func likePhoto(_ photo: Photo) async {
        do {
            try await repository.likePhoto(photoId: photo.id)
            if let index = photos.firstIndex(where: { $0.id == photo.id }) {
                photos[index].isLiked.toggle()
                photos[index].likes += photos[index].isLiked ? 1 : -1
            }
        } catch {
            errorMessage = "Failed to like photo"
        }
    }
}
```

---

## **7. SwiftUI Feed View**

```swift
struct FeedView: View {
    @StateObject var viewModel: FeedViewModel

    var body: some View {
        NavigationStack {
            List(viewModel.photos) { photo in
                VStack(alignment: .leading) {
                    Text(photo.username).bold()
                    if let url = photo.imageURL {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    Text(photo.caption)
                    HStack {
                        Button {
                            Task { await viewModel.likePhoto(photo) }
                        } label: {
                            Image(systemName: photo.isLiked ? "heart.fill" : "heart")
                            Text("\(photo.likes)")
                        }
                    }
                }
                .padding()
            }
            .task { await viewModel.loadFeed() }
            .navigationTitle("Feed")
        }
    }
}
```

---

## **8. Offline + Caching Strategy**

1. **Feed**

   * Show cached feed immediately
   * Refresh from network in background

2. **Photo Upload**

   * Save locally first
   * Attempt network upload
   * If offline, mark pending for later sync

3. **Image Caching**

   * Use in-memory cache (`NSCache`) for smooth scrolling
   * Persist image data locally for offline feed

4. **Likes**

   * Optimistically update UI
   * Sync with server asynchronously

---

## ✅ **Benefits of This Design**

* Offline-first feed and uploads
* Smooth scrolling with image caching
* MVVM + Clean Architecture, easy to test
* Async/await for modern concurrency
* Scalable: add comments, stories, or follow features

---

I can also **draw a visual diagram showing the FeedView, ViewModel, UseCases, Repository, Network, and LocalStorage flow**—very useful for implementation planning.

Do you want me to make that diagram next?
