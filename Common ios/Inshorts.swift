//
//  Inshorts.swift
//  
//
//  Created by Apple on 17/12/25.
//

import Foundation

Below is a **senior-level High-Level Design (HLD)** for an app like **Inshorts** (news-in-shorts), structured exactly how interviewers expect: **architecture → data flow → storage → APIs → pagination → edge cases**.

---

# 📰 Inshorts-Like App — High-Level Design

## 1. Functional Requirements

### Core

* Show short news cards (title + summary)
* Infinite vertical feed
* Categories (Tech, Sports, Business)
* Pull to refresh
* Offline reading

### Non-Functional

* Fast cold start
* Low memory usage
* Smooth scrolling
* Offline resilience
* Scalable backend APIs

---

## 2. High-Level Architecture

### Client (Mobile App)

```
UI Layer (SwiftUI / UIKit)
   ↓
ViewModel (MVVM)
   ↓
Repository
   ↓
Data Sources
   ├── Remote (API)
   └── Local (DB / Cache)
```

### Backend (Simplified)

```
API Gateway
   ↓
News Aggregation Service
   ↓
Cache (Redis)
   ↓
DB (Articles)
```

---

## 3. Data Flow (End-to-End)

1. App launches
2. Load cached articles from local DB
3. Render feed instantly
4. Fetch latest articles from API
5. Merge + update DB
6. UI auto-updates

> **Offline-first strategy**

---

## 4. Local Storage Strategy

### Why Local Storage?

* Instant feed load
* Offline access
* Reduced API calls
* Pagination continuity

---

### Storage Options

| Storage            | Use                 |
| ------------------ | ------------------- |
| SQLite / Core Data | Persistent articles |
| File system        | Images (cached)     |
| In-memory cache    | Session state       |

---

### Data Model (Article)

```json
Article {
  id: String
  title: String
  summary: String
  category: String
  publishedAt: Timestamp
  source: String
  imageUrl: String
  isRead: Bool
}
```

---

### Storage Strategy

#### 1️⃣ Normalize Data

* Store articles by `id`
* Index by `publishedAt`, `category`

#### 2️⃣ Retention Policy

* Keep last **N articles per category** (e.g., 200)
* Periodic cleanup

#### 3️⃣ Offline Support

* Show cached feed if network unavailable
* Mark stale content

---

### Sync Logic

```
if app_launch:
  load_from_db()

if network_available:
  fetch_latest()
  upsert_into_db()
```

---

## 5. API Contract Design

### Base URL

```
/v1/news
```

---

### 5.1 Fetch Feed (Paginated)

```
GET /v1/news
```

#### Query Params

| Param    | Type   | Description      |
| -------- | ------ | ---------------- |
| category | String | Optional         |
| limit    | Int    | Page size        |
| cursor   | String | Pagination token |

---

#### Response

```json
{
  "articles": [
    {
      "id": "a1",
      "title": "Apple launches...",
      "summary": "In short...",
      "imageUrl": "...",
      "publishedAt": "2025-01-01T10:00:00Z",
      "category": "Tech"
    }
  ],
  "nextCursor": "eyJ0aW1lIjoxNzAwfQ==",
  "hasMore": true
}
```

---

### Why Cursor-Based Pagination?

| Offset             | Cursor       |
| ------------------ | ------------ |
| ❌ duplicates       | ✅ stable     |
| ❌ breaks on insert | ✅ consistent |
| ❌ expensive        | ✅ scalable   |

---

### 5.2 Pull-to-Refresh (Latest)

```
GET /v1/news/latest
```

Returns:

* Articles newer than latest cached `publishedAt`

---

### 5.3 Mark Article as Read

```
POST /v1/news/read
```

```json
{
  "articleId": "a1"
}
```

---

## 6. Pagination Handling (Client Side)

### Strategy: Cursor-Based Infinite Scroll

---

### ViewModel State

```swift
struct FeedState {
    var articles: [Article]
    var isLoading: Bool
    var nextCursor: String?
    var hasMore: Bool
}
```

---

### Pagination Logic

```swift
func loadNextPage() async {
    guard !isLoading, hasMore else { return }

    isLoading = true
    let response = await api.fetchNews(cursor: nextCursor)
    nextCursor = response.nextCursor
    hasMore = response.hasMore

    saveToDB(response.articles)
    articles.append(contentsOf: response.articles)
    isLoading = false
}
```

---

### Scroll Trigger

* Load when user reaches ~70–80% of list

---

### Avoid Duplicate Loads

* Single in-flight request
* Idempotent API responses
* Article `id` de-duplication

---

## 7. Pull-to-Refresh Strategy

```
latestPublishedAt = max(articles.publishedAt)
GET /latest?after=latestPublishedAt
```

* Prepend new articles
* Update DB
* Smooth UI insert animation

---

## 8. Error Handling & Edge Cases

### Network Failure

* Show cached data
* Non-blocking banner

### API Failure

* Retry with backoff
* Do not clear cache

### Pagination Errors

* Freeze pagination
* Allow manual retry

---

## 9. Performance Considerations

### Images

* Lazy load
* Disk caching
* Low-res placeholders

### UI

* Cell reuse
* Avoid heavy layouts
* Precompute heights

---

## 10. Scalability & Future Enhancements

* Personalization feed
* Recommendation service
* Trending section
* Analytics events batching
* A/B experiments

---

## 11. Interview-Ready Summary (One Paragraph)

> “The app uses an offline-first MVVM architecture with a repository layer coordinating local and remote data sources. Articles are cached locally for fast startup and offline access. APIs are cursor-based for scalable pagination, and the feed supports pull-to-refresh by fetching only newer items. Pagination state is managed in the ViewModel to ensure smooth infinite scrolling and avoid duplicate loads.”

---

## Want to go deeper?

I can:

* Draw **backend HLD**
* Add **system design diagrams**
* Show **DB schema**
* Compare **offset vs cursor pagination in detail**
* Explain **how Inshorts likely optimizes feed loading**

Just say the word 🚀

Sure! Let’s go **deep and detailed**, covering **everything** about designing an app like Inshorts: architecture, local storage, API design, pagination, offline strategy, performance, and edge cases. I’ll break it down step by step, with explanations suitable for an interview or real-world implementation.
                                                                                                                                                        
---
                                                                                                                                                        
# **1. Functional & Non-Functional Requirements**
                                                                                                                                                        
### **Functional Requirements**
                                                                                                                                                        
1. Display short news cards (title + summary + optional image).
2. Categorized feed (Tech, Sports, Business, etc.).
3. Infinite scrolling with smooth pagination.
4. Pull-to-refresh for new articles.
5. Offline access to previously loaded articles.
6. Mark articles as read/unread.
7. Share articles or open in full web view.
                                                                                                                                                        
### **Non-Functional Requirements**
                                                                                                                                                        
* Fast app launch (cold start < 2s).
* Smooth scrolling, low memory usage.
* Low network usage.
* Scalable backend APIs for millions of users.
* Offline resilience.
                                                                                                                                                        
---
                                                                                                                                                        
# **2. High-Level Architecture**
                                                                                                                                                        
### **Client-Side (Mobile App)**
                                                                                                                                                        
```
UI Layer (UIKit / SwiftUI)
↓
ViewModel / Controller (MVVM / MVC)
↓
Repository Layer
↓
Data Sources:
├── Local DB (SQLite / Core Data / Realm)
└── Remote API
```
                                                                                                                                                        
**Roles:**
                                                                                                                                                            
* **UI Layer:** Displays news cards and forwards user interactions.
* **ViewModel / Controller:** Handles user events, coordinates data fetching.
* **Repository:** Abstracts data sources, decides when to load from cache vs API.
* **Data Sources:** Responsible for actual storage or network calls.
                                                                                                                                                        
---
                                                                                                                                                        
### **Backend Architecture (Simplified)**
                                                                                                                                                        
```
API Gateway
↓
News Aggregation Service
↓
Cache (Redis / CDN)
↓
Database (Articles, Users, Metadata)
```
                                                                                                                                                        
* **News Aggregation Service:** Collects news from sources, filters, shortens text.
* **Cache:** Serves frequently requested feeds quickly.
* **DB:** Persistent storage of articles and user read states.
                                                                                                                                                        
                                                                                                                                                        ---
                                                                                                                                                        
# **3. Local Storage Strategy**
                                                                                                                                                        
### **Why Local Storage**
                                                                                                                                                        
* Fast cold-start experience.
* Offline reading.
* Reduce network requests.
* Maintain pagination continuity.
                                                                                                                                                        
### **Storage Choices**
                                                                                                                                                        
| Storage                  | Use Case                                   |
| ------------------------ | ------------------------------------------ |
| SQLite / Core Data       | Store articles and metadata persistently.  |
| File system / Disk cache | Store images locally for offline access.   |
| In-memory cache          | Session-only fast access for current feed. |
                                                                                                                                                        
### **Article Data Model**
                                                                                                                                                        
```json
{
    "id": "a1",
    "title": "Apple launches new product",
    "summary": "In short...",
    "imageUrl": "https://...",
    "category": "Tech",
    "publishedAt": "2025-12-17T10:00:00Z",
    "source": "TechCrunch",
    "isRead": false
}
```

### **Storage Design**

1. Normalize data by `id`.
2. Index articles by `publishedAt` and `category`.
3. Retention policy: keep last N articles per category (e.g., 200).
4. Offline support: load from DB when network unavailable.
5. Sync logic:

```text
if app_launch:
        load_from_db()
    if network_available:
        fetch_latest()
    upsert_into_db()
    ```
    
    ---
    
    # **4. API Contract Design**
    
    ### **Base URL**
    
    ```
    GET /v1/news
    ```
    
    ### **Fetch Feed (Paginated)**
    
    **Query Params:**
        
        | Param    | Type   | Description                            |
    | -------- | ------ | -------------------------------------- |
    | category | String | Optional                               |
    | limit    | Int    | Number of articles to fetch            |
    | cursor   | String | Pagination token (for infinite scroll) |
    
    **Response:**
        
        ```json
{
    "articles": [
        {
            "id": "a1",
            "title": "Apple launches new product",
            "summary": "In short...",
            "imageUrl": "...",
            "publishedAt": "2025-12-17T10:00:00Z",
            "category": "Tech"
        }
    ],
    "nextCursor": "eyJ0aW1lIjoxNzAwfQ==",
    "hasMore": true
}
```

**Why Cursor-Based Pagination**

* Avoids duplicates when new articles are inserted.
* Scales better than offset-based pagination.
* Ensures consistent feed state even with concurrent updates.

---

### **Pull-to-Refresh API**

```
GET /v1/news/latest?after=<latestPublishedAt>
```

* Fetches only articles newer than latest cached one.

---

### **Mark Article as Read**

```
POST /v1/news/read
{
    "articleId": "a1"
}
```

* Updates local DB and optionally backend analytics.

---

# **5. Pagination Handling (Client-Side)**

### **ViewModel State**

```swift
struct FeedState {
    var articles: [Article]
    var isLoading: Bool
    var nextCursor: String?
    var hasMore: Bool
}
```

### **Pagination Logic**

```swift
func loadNextPage() async {
    guard !isLoading, hasMore else { return }
    isLoading = true
    
    let response = await api.fetchNews(cursor: nextCursor)
    nextCursor = response.nextCursor
    hasMore = response.hasMore
    
    saveToDB(response.articles)
    articles.append(contentsOf: response.articles)
    isLoading = false
}
```

* Trigger load when user scrolls near bottom (70–80%).
* Ensure single in-flight request to avoid duplicates.
* Deduplicate articles by `id`.

---

# **6. Pull-to-Refresh Strategy**

* Keep track of latest `publishedAt`.
* Fetch articles newer than this timestamp.
* Prepend to feed and DB.
* Smooth UI insertion animation.

```swift
func refreshFeed() async {
    guard let latestDate = articles.first?.publishedAt else { return }
    let newArticles = await api.fetchLatest(after: latestDate)
    saveToDB(newArticles)
    articles.insert(contentsOf: newArticles, at: 0)
}
```

---

# **7. Error Handling & Edge Cases**

| Case             | Strategy                                   |
| ---------------- | ------------------------------------------ |
| Network failure  | Show cached data, non-blocking banner.     |
| API failure      | Retry with exponential backoff.            |
| Pagination error | Freeze further scroll, allow manual retry. |
| Empty feed       | Show placeholder or “No news yet.”         |
| Offline mode     | Only show local cached articles.           |

---

# **8. Performance Optimizations**

### **Images**

* Lazy load images only when visible.
* Disk cache for offline usage.
* Low-resolution placeholder images for smooth scrolling.
                    
### **UI**
                    
* Cell reuse (`UITableView` / `UICollectionView`).
* Precompute cell heights if necessary.
* Batch insertions for smooth animations.
                    
### **Memory**
                    
* Keep in-memory cache small.
* Remove old articles periodically.
* Clear images not currently displayed.
                    
---
                    
# **9. Scalability & Future Enhancements**
                    
* Personalization feed per user.
* Recommendation engine for trending news.
* Analytics events batching for engagement tracking.
* Multi-language support.
* Push notifications for breaking news.
                    
---
                    
# **10. Summary (Interview-Ready)**
                    
> “The Inshorts-like app uses an offline-first MVVM architecture with a repository coordinating between local DB and remote APIs. Articles are cached for instant loading and offline access. Cursor-based APIs provide scalable infinite scrolling and pull-to-refresh fetches only new content. Pagination state is managed in the ViewModel to ensure smooth scrolling, prevent duplicates, and enable efficient UI updates. Performance is optimized via image caching, lazy loading, and memory management.”
                    
---
                    
If you want, I can **draw a full diagram** showing:
                        
* Client architecture (UI → VM → Repository → Local/Remote)
* Backend flow (API → cache → DB)
* Pagination and offline sync strategy

This is often expected in **system design rounds**.
