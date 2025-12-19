//
//  Nearby app.swift
//  
//
//  Created by Apple on 17/12/25.
//

import Foundation

Below is a **2-hour take-home–style solution outline** for a **“Nearby” location-based listing app**, optimized for **clean architecture, async networking, and usable UX** rather than sheer feature count.

I’ll structure this exactly how interviewers typically expect to see it.

---

# 📍 “Nearby” App — Design & Architecture

## 1. Problem Overview

**Goal**
Build a mobile app that shows nearby places (restaurants, cafés, stores, etc.) based on the user’s current location.

**Core requirements**

* Fetch nearby listings from an API
* Display results in a clean, scrollable UI
* Handle loading, errors, and empty states gracefully
* Clean architecture (MVVM preferred)
* Efficient async networking

---

## 2. Architecture Choice

### ✅ MVVM (Recommended)

**Why MVVM?**

* Clear separation of concerns
* Easy to test ViewModels
* Scales well beyond a prototype

```
View (UIKit / SwiftUI)
   ↓ binds to
ViewModel
   ↓ uses
Service / API Client
   ↓ decodes
Models
```

---

## 3. API Design (Mock / Realistic)

### Base URL

```
https://api.nearbyapp.com
```

### 3.1 Fetch Nearby Places

```
GET /v1/places/nearby
```

**Query Parameters**

| Param    | Type    | Description      |
| -------- | ------- | ---------------- |
| lat      | Double  | User latitude    |
| lng      | Double  | User longitude   |
| radius   | Int     | Radius in meters |
| category | String? | Optional filter  |

**Example**

```
/v1/places/nearby?lat=37.78&lng=-122.41&radius=1000
```

**Response**

```json
{
  "places": [
    {
      "id": "1",
      "name": "Blue Bottle Coffee",
      "category": "Cafe",
      "distance": 120,
      "rating": 4.6,
      "image_url": "https://...",
      "location": {
        "lat": 37.776,
        "lng": -122.417
      }
    }
  ]
}
```

---

### 3.2 Error Response

```json
{
  "error": {
    "code": "LOCATION_UNAVAILABLE",
    "message": "Unable to fetch nearby places."
  }
}
```

---

## 4. Data Models (Swift)

```swift
struct Place: Decodable, Identifiable {
    let id: String
    let name: String
    let category: String
    let distance: Int
    let rating: Double
    let imageURL: URL?
}
```

---

## 5. Networking Layer

### API Client (Async / Await)

```swift
protocol PlacesService {
    func fetchNearbyPlaces(
        lat: Double,
        lng: Double,
        radius: Int
    ) async throws -> [Place]
}
```

```swift
final class PlacesAPI: PlacesService {
    func fetchNearbyPlaces(
        lat: Double,
        lng: Double,
        radius: Int
    ) async throws -> [Place] {

        let url = URL(string:
          "https://api.nearbyapp.com/v1/places/nearby?lat=\(lat)&lng=\(lng)&radius=\(radius)"
        )!

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }

        return try JSONDecoder()
            .decode(PlacesResponse.self, from: data)
            .places
    }
}
```

---

## 6. ViewModel

### Responsibilities

* Request location
* Fetch places
* Expose UI state
* Handle errors gracefully

```swift
@MainActor
final class NearbyViewModel: ObservableObject {
    @Published var places: [Place] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: PlacesService

    init(service: PlacesService = PlacesAPI()) {
        self.service = service
    }

    func loadNearbyPlaces(lat: Double, lng: Double) async {
        isLoading = true
        errorMessage = nil

        do {
            places = try await service.fetchNearbyPlaces(
                lat: lat,
                lng: lng,
                radius: 1000
            )
        } catch {
            errorMessage = "Failed to load nearby places."
        }

        isLoading = false
    }
}
```

---

## 7. UI Design (SwiftUI Example)

### Rough Layout

```
NavigationView
 └── List
     ├── Place Row
     │    ├── Image
     │    ├── Name
     │    ├── Category
     │    └── Distance
     └── Empty / Error State
```

---

### Nearby Screen

```swift
struct NearbyView: View {
    @StateObject private var viewModel = NearbyViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Finding places...")
                } else if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                } else if viewModel.places.isEmpty {
                    Text("No places nearby")
                } else {
                    List(viewModel.places) { place in
                        PlaceRow(place: place)
                    }
                }
            }
            .navigationTitle("Nearby")
            .task {
                await viewModel.loadNearbyPlaces(
                    lat: 37.78,
                    lng: -122.41
                )
            }
        }
    }
}
```

---

### Place Row

```swift
struct PlaceRow: View {
    let place: Place

    var body: some View {
        HStack {
            AsyncImage(url: place.imageURL) { image in
                image.resizable()
            } placeholder: {
                Color.gray
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)

            VStack(alignment: .leading) {
                Text(place.name).font(.headline)
                Text(place.category).font(.subheadline)
                Text("\(place.distance)m away")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}
```

---

## 8. UX & Error Handling

### Loading

* Non-blocking `ProgressView`
* Smooth async transitions

### Errors

* Human-readable error message
* Retry option (easy extension)

### Empty State

* Friendly message instead of blank list

---

## 9. What Fits in 2 Hours (Realistically)

✅ Nearby list screen
✅ API client + models
✅ MVVM structure
✅ Async/await networking
✅ Loading / empty / error states

🚫 Map view (nice-to-have)
🚫 Pagination
🚫 Caching (mention as future improvement)

---

## 10. How This Impresses Interviewers

✔ Clean separation of concerns
✔ Testable ViewModels
✔ Realistic API modeling
✔ Modern async patterns
✔ Thoughtful UX states

---

If you want, I can:

* Convert this to **UIKit + Combine**
* Add **unit tests for the ViewModel**
* Add a **MapKit-based Nearby Map**
* Show how I’d **explain this in an interview**

Just say the word 🚀
