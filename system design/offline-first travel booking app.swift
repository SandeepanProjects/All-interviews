//
//  offline-first travel booking app.swift
//  
//
//  Created by Apple on 25/12/25.
//

import Foundation

Perfect! Let’s design a **full offline-first travel booking app flow** in SwiftUI, keeping **MVVM + Clean Architecture + async/await** in mind. I’ll break it into **screens, navigation, offline strategy, and data flow**.

---

## **1. App Feature Flow**

```
Splash Screen → Home TabView
Home TabView:
    ├── Hotels
    │     ├── Hotel List
    │     └── Hotel Detail → Book Hotel
    ├── Flights
    │     ├── Flight List
    │     └── Flight Detail → Book Flight
    └── Bookings
          └── My Bookings (Offline Cached)
```

---

## **2. Navigation Structure (SwiftUI)**

```swift
struct MainView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HotelListView(viewModel: HotelListViewModel(
                    searchUseCase: SearchHotelsUseCase(repository: HotelRepositoryImpl(
                        networkService: NetworkService(),
                        localStorage: LocalStorage()
                    ))
                ))
            }
            .tabItem { Label("Hotels", systemImage: "bed.double.fill") }

            NavigationStack {
                FlightListView(viewModel: FlightListViewModel(
                    searchUseCase: SearchFlightsUseCase(repository: FlightRepositoryImpl(
                        networkService: NetworkService(),
                        localStorage: LocalStorage()
                    ))
                ))
            }
            .tabItem { Label("Flights", systemImage: "airplane") }

            NavigationStack {
                BookingListView(viewModel: BookingListViewModel(
                    repository: BookingRepositoryImpl(
                        networkService: NetworkService(),
                        localStorage: LocalStorage()
                    )
                ))
            }
            .tabItem { Label("Bookings", systemImage: "bag.fill") }
        }
    }
}
```

---

## **3. Offline-First Repository Pattern**

* **Always return local cached data first**
* **Then refresh with network**
* **Sync bookings when back online**

```swift
final class BookingRepositoryImpl: BookingRepository {
    private let networkService: NetworkService
    private let localStorage: LocalStorage

    init(networkService: NetworkService, localStorage: LocalStorage) {
        self.networkService = networkService
        self.localStorage = localStorage
    }

    func getBookings() async -> [Booking] {
        let cached = await localStorage.getBookings()
        Task {
            do {
                let bookings = try await networkService.fetchBookings()
                await localStorage.saveBookings(bookings)
            } catch {
                // offline, ignore
            }
        }
        return cached
    }

    func addBooking(_ booking: Booking) async throws {
        await localStorage.addBooking(booking)
        do {
            try await networkService.createBooking(booking)
        } catch {
            // mark as pending sync
            await localStorage.markBookingPendingSync(booking)
        }
    }
}
```

---

## **4. SwiftUI Screens (Offline Ready)**

### **Hotel List**

```swift
struct HotelListView: View {
    @StateObject var viewModel: HotelListViewModel
    @State private var searchQuery = ""

    var body: some View {
        VStack {
            TextField("Search Hotels", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
                .padding()
                .onSubmit { Task { await viewModel.searchHotels(query: searchQuery) } }

            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                Text(error)
            } else {
                List(viewModel.hotels) { hotel in
                    NavigationLink(destination: HotelDetailView(hotel: hotel, viewModel: viewModel)) {
                        HotelRowView(hotel: hotel)
                    }
                }
            }
        }
        .navigationTitle("Hotels")
    }
}
```

### **Hotel Detail → Booking**

```swift
struct HotelDetailView: View {
    let hotel: Hotel
    @ObservedObject var viewModel: HotelListViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text(hotel.name).font(.title).bold()
            Text(hotel.location)
            Text("$\(hotel.price, specifier: "%.2f")")

            Button("Book Now") {
                Task {
                    let booking = Booking(id: UUID().uuidString, type: .hotel, referenceId: hotel.id, date: Date())
                    try? await viewModel.bookHotel(booking: booking)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

---

### **Flight List & Detail**

* Same pattern as **Hotels**
* Use **FlightListViewModel**, **FlightDetailView**
* Offline caching of flight search results
* Booking creation works offline with **sync queue**

---

### **Booking List (Offline)**

```swift
struct BookingListView: View {
    @StateObject var viewModel: BookingListViewModel

    var body: some View {
        List(viewModel.bookings) { booking in
            VStack(alignment: .leading) {
                Text("\(booking.type.rawValue.capitalized) Booking")
                Text("Reference: \(booking.referenceId)")
                Text("Date: \(booking.date.formatted())")
            }
        }
        .task { await viewModel.loadBookings() }
        .navigationTitle("My Bookings")
    }
}
```

---

## **5. Data Flow Summary**

```
User Action (Search/Book)
        ↓
ViewModel (HotelListViewModel/FlightListViewModel)
        ↓
UseCase (SearchHotelsUseCase/SearchFlightsUseCase)
        ↓
Repository (HotelRepositoryImpl/FlightRepositoryImpl)
        ↓
LocalStorage (Cached data first) & NetworkService (Fetch/Sync)
        ↓
Back to ViewModel → UI updates
```

---

## **6. Offline Sync Strategy**

1. **Read-first from local DB**

   * Ensures offline browsing works

2. **Write-first to local DB**

   * Queue unsynced bookings

3. **Background Sync**

   * Task runs when network available
   * Marks booking as synced

```swift
Task.detached {
    await repository.syncPendingBookings()
}
```

---

## ✅ **Benefits of This Design**

* Fully offline-first: cached searches & bookings
* Modern SwiftUI + async/await
* MVVM + Clean Architecture for testability
* Easy to expand: add hotels, flights, cars, user profiles
* Background syncing ensures data consistency

---

If you want, I can **draw a visual SwiftUI navigation diagram** showing **all screens, ViewModels, and data flow**—perfect for building or presenting this app.

Do you want me to create that diagram next?


Absolutely! Let’s design an **offline-first travel booking app** in **iOS SwiftUI** using **modern concurrency (async/await)**, **MVVM**, and **Clean Architecture** principles. I’ll break it down step by step: **architecture, data flow, offline-first strategy, SwiftUI implementation, and concurrency**.

---

## **1. Architecture Overview**

We'll follow **Clean Architecture** layers:

```
Presentation (SwiftUI + ViewModel) → Domain (UseCases / Business Logic) → Data (Repositories + Network / Local DB)
```

**Layers:**

1. **Presentation Layer**

   * SwiftUI Views
   * ViewModels using `@MainActor` + `ObservableObject`
   * Handles UI state, triggers use cases

2. **Domain Layer**

   * Entities (Hotel, Flight, Booking)
   * UseCases / Interactors (SearchHotels, BookFlight)
   * Pure Swift, no dependencies

3. **Data Layer**

   * Repository implementation
   * Network + Local Storage (CoreData / Realm / SQLite)
   * Offline-first caching strategy

---

## **2. Offline-First Strategy**

* **Local Database:** CoreData or Realm
* **Network Layer:** Fetch data from API, update local cache
* **Repository:** Always returns cached data first, then refreshes with network
* **Synchronization:**

  * Background task to sync bookings and search data
  * Conflict resolution (e.g., last write wins or merge strategy)

---

## **3. Core Entities**

```swift
struct Hotel: Identifiable, Codable {
    let id: String
    let name: String
    let location: String
    let price: Double
    let imageURL: URL?
}

struct Flight: Identifiable, Codable {
    let id: String
    let airline: String
    let departure: Date
    let arrival: Date
    let price: Double
}

struct Booking: Identifiable, Codable {
    let id: String
    let type: BookingType
    let referenceId: String
    let date: Date
}

enum BookingType: String, Codable {
    case hotel
    case flight
}
```

---

## **4. Repository Protocols (Domain Layer)**

```swift
protocol HotelRepository {
    func getHotels(query: String) async throws -> [Hotel]
    func getCachedHotels() async -> [Hotel]
}

protocol FlightRepository {
    func getFlights(query: String) async throws -> [Flight]
    func getCachedFlights() async -> [Flight]
}
```

---

## **5. Use Cases (Domain Layer)**

```swift
struct SearchHotelsUseCase {
    private let repository: HotelRepository

    init(repository: HotelRepository) {
        self.repository = repository
    }

    func execute(query: String) async -> [Hotel] {
        // Return cached first
        var hotels = await repository.getCachedHotels()
        do {
            hotels = try await repository.getHotels(query: query)
        } catch {
            // Handle offline scenario
        }
        return hotels
    }
}
```

---

## **6. Data Layer Implementation**

```swift
final class HotelRepositoryImpl: HotelRepository {
    private let networkService: NetworkService
    private let localStorage: LocalStorage

    init(networkService: NetworkService, localStorage: LocalStorage) {
        self.networkService = networkService
        self.localStorage = localStorage
    }

    func getHotels(query: String) async throws -> [Hotel] {
        let hotels = try await networkService.fetchHotels(query: query)
        await localStorage.saveHotels(hotels)
        return hotels
    }

    func getCachedHotels() async -> [Hotel] {
        return await localStorage.getHotels()
    }
}
```

---

## **7. SwiftUI + ViewModel (Presentation Layer)**

```swift
@MainActor
final class HotelListViewModel: ObservableObject {
    @Published var hotels: [Hotel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let searchUseCase: SearchHotelsUseCase

    init(searchUseCase: SearchHotelsUseCase) {
        self.searchUseCase = searchUseCase
    }

    func searchHotels(query: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            hotels = await searchUseCase.execute(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

```swift
struct HotelListView: View {
    @StateObject var viewModel: HotelListViewModel

    @State private var searchQuery = ""

    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search Hotels", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onSubmit {
                        Task { await viewModel.searchHotels(query: searchQuery) }
                    }

                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.errorMessage {
                    Text(error)
                } else {
                    List(viewModel.hotels) { hotel in
                        VStack(alignment: .leading) {
                            Text(hotel.name).bold()
                            Text(hotel.location)
                            Text("$\(hotel.price, specifier: "%.2f")")
                        }
                    }
                }
            }
            .navigationTitle("Hotels")
        }
    }
}
```

---

## **8. Network Layer (Async/Await)**

```swift
actor NetworkService {
    func fetchHotels(query: String) async throws -> [Hotel] {
        guard let url = URL(string: "https://api.example.com/hotels?q=\(query)") else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Hotel].self, from: data)
    }
}
```

---

## **9. Local Storage Layer (Offline)**

```swift
actor LocalStorage {
    private var hotelsCache: [Hotel] = []

    func saveHotels(_ hotels: [Hotel]) async {
        self.hotelsCache = hotels
    }

    func getHotels() async -> [Hotel] {
        return hotelsCache
    }
}
```

> Later, you can replace `hotelsCache` with **CoreData/Realm** for persistence across app launches.

---

## ✅ **Key Features of This Design**

1. **Offline-first:**

   * Always serves cached data first
   * Syncs with API asynchronously

2. **Modern Concurrency:**

   * `async/await` for network and database
   * `actor` for thread safety

3. **MVVM + Clean Architecture:**

   * Decoupled View, ViewModel, UseCase, Repository
   * Testable and scalable

4. **Expandable:**

   * Add Flights, Bookings, User Profiles easily
   * Swap `LocalStorage` with CoreData or Realm later

---

If you want, I can **draw a full SwiftUI offline-first navigation flow** for a **complete Expedia-like app**, including **Hotels, Flights, Bookings, and Offline Sync**, so you can use it as a real project blueprint.

Do you want me to do that next?
