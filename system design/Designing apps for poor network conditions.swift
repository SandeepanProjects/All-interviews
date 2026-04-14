//
//  Designing apps for poor network conditions.swift
//  
//
//  Created by Apple on 14/04/26.
//

import Foundation

Designing apps for poor network conditions is a **staff-level iOS/system design topic**. The goal is simple: your app should feel *fast, reliable, and usable* even when the network is slow, flaky, or completely offline.

Let’s break this down in a **practical, production-grade way**.

---

# 🧠 1. Core Principle: Offline-First Mindset

Instead of designing:

> ❌ “Fetch → then show UI”

Design like:

> ✅ “Show local data → sync in background”

This is called an **offline-first architecture**.

---

# 🏗️ 2. Architecture Overview (Production Grade)

```
UI (SwiftUI)
   ↓
ViewModel (State + Intent)
   ↓
Repository (Single Source of Truth)
   ↓
-----------------------------------
| Local DB (CoreData / SQLite)   |
| Remote API (Network Layer)     |
-----------------------------------
```

👉 **Key idea:**
Repository decides:

* When to read from cache
* When to hit network
* How to merge data

---

# 📦 3. Local Storage is Mandatory

### Use:

* CoreData / SQLite / Realm

### Strategy:

* Always read from DB first
* Persist every successful network response

```swift
func fetchChats() async {
    // 1. Load from DB instantly
    let local = await db.fetchChats()
    self.chats = local
    
    // 2. Fetch from network
    do {
        let remote = try await api.fetchChats()
        await db.save(remote)
        self.chats = remote
    } catch {
        // Silent fail, UI already has data
    }
}
```

👉 This removes loading spinners and improves UX drastically.

---

# 🔄 4. Smart Caching Strategy

### Types of caching:

* Memory cache (NSCache) → fast UI reuse
* Disk cache → persistence

### Techniques:

* Cache API responses with expiry (TTL)
* Use ETags / If-Modified-Since (backend support)

---

# 🌐 5. Handle Network Failures Gracefully

### Never:

* Crash
* Block UI

### Always:

* Show stale data
* Show retry options

```swift
enum ViewState {
    case loading
    case success([Chat])
    case error(String, cached: [Chat]?)
}
```

---

# 🔁 6. Retry Mechanism (Critical)

Implement:

* Exponential backoff
* Retry only for transient failures

```swift
func retry<T>(
    maxRetries: Int = 3,
    delay: Double = 1,
    task: @escaping () async throws -> T
) async throws -> T {
    var currentDelay = delay
    
    for i in 0..<maxRetries {
        do {
            return try await task()
        } catch {
            if i == maxRetries - 1 { throw error }
            try await Task.sleep(nanoseconds: UInt64(currentDelay * 1_000_000_000))
            currentDelay *= 2
        }
    }
    throw URLError(.badServerResponse)
}
```

---

# 📡 7. Network Awareness

Use:

* NWPathMonitor

Detect:

* Offline
* Expensive network (cellular)
* Constrained network (low data mode)

```swift
if path.isConstrained {
    // Reduce data usage
}
```

---

# ⚡ 8. Reduce Network Usage

### Techniques:

* Pagination (never load everything)
* Compression (gzip)
* Send only diffs (delta sync)
* Image optimization (thumbnails first)

---

# 🔃 9. Background Sync

Use:

* BackgroundTasks
* Silent push notifications

Sync:

* When app resumes
* Periodically

---

# ✍️ 10. Write Operations (Hard Part)

### Use Optimistic UI

```swift
func sendMessage(_ text: String) {
    let temp = Message(id: UUID(), text: text, status: .sending)
    messages.append(temp)
    
    Task {
        do {
            let confirmed = try await api.send(text)
            update(temp, with: confirmed)
        } catch {
            markFailed(temp)
        }
    }
}
```

### Handle:

* Retry failed messages
* Queue offline writes

---

# 🧵 11. Request Queue (Offline Mode)

When offline:

* Queue requests locally
* Replay when network returns

```
[User Action] → Queue → Persist → Retry Later
```

---

# 🎯 12. UX Best Practices

### Always show:

* Cached content
* Loading indicators only when needed

### Add:

* “Last updated” timestamp
* Retry button
* Offline banner

---

# 🚀 13. Real-World Example (WhatsApp-like)

* Messages stored locally
* Sent immediately (optimistic)
* Synced in background
* Retry failed messages automatically

---

# 🔥 14. Common Mistakes (Interview Gold)

❌ Blocking UI on network
❌ No caching
❌ No retry logic
❌ No offline support
❌ Fetching large payloads
❌ Not handling partial failures

---

# 🧩 15. Staff-Level Additions

* Conflict resolution (server vs local edits)
* Data versioning
* Feature flags for network behavior
* Observability (logs, metrics)

---

# 💡 Final Summary

To design for poor networks:

1. **Offline-first architecture**
2. **Local DB as source of truth**
3. **Smart caching + TTL**
4. **Retry with backoff**
5. **Network awareness**
6. **Optimistic UI + request queue**
7. **Background sync**
8. **Graceful degradation**

---

If you want, I can:
✅ Build a **full production SwiftUI architecture (offline-first + sync engine)**
✅ Give **interview-ready system design answer (like Stripe/WhatsApp level)**
✅ Add **real CoreData + sync conflict resolution code**

Just tell me 👍
