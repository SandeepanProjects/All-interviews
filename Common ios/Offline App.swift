//
//  Offline App.swift
//  
//
//  Created by Apple on 25/12/25.
//

import Foundation

Below is a **senior-level, interview-ready walkthrough** for **Designing an Offline-First iOS App**. This is the kind of structured, trade-off-aware answer interviewers look for.

---

# 🧠 Problem Framing (30–45 seconds)

> *Design an iOS app that works reliably without network, syncs efficiently when online, and safely handles conflicts.*

Assumptions (say these out loud):

* Users can create/update/delete data offline
* Data must survive app restarts & crashes
* Backend supports versioning / change tracking
* Network is unreliable

---

# 🧱 High-Level Architecture

```
UI
↓
ViewModel
↓
Domain Layer
↓
Sync Engine
↓
Local Store (Source of Truth)
↓
Network Layer
```

**Key principle:**
➡️ **Local database is the source of truth**, not the server.

---

# 🔄 1. Sync Engine Design (Core Senior Topic)

### Responsibilities

* Track local changes
* Upload changes when online
* Download remote changes
* Resolve conflicts
* Maintain sync state

### Core Components

* **Change Queue**

  * Tracks CREATE / UPDATE / DELETE operations
  * Stored persistently (Core Data / SQLite)
* **Sync Coordinator**

  * Triggered by:

    * App launch
    * Network reachable
    * Background tasks
    * Manual refresh
* **State Machine**

  * `idle → syncing → failed → retrying`

### Sync Flow

1. Fetch remote changes (delta)
2. Apply them locally
3. Upload local pending changes
4. Resolve conflicts
5. Update sync metadata

---

# ⚔️ 2. Conflict Resolution Strategies

Conflicts occur when **same entity changed locally & remotely**.

### Common Strategies

#### 🔹 Last Write Wins (LWW)

* Based on timestamp or version
* Simple, fast
* ❌ Can lose user data

#### 🔹 Field-Level Merging (Preferred)

* Track per-field versions
* Merge non-overlapping changes
* Example: title changed locally, description changed remotely

#### 🔹 Client Wins / Server Wins

* Depends on business rules
* Example: offline edits override remote

#### 🔹 Manual Resolution

* Show UI to user
* Used sparingly (expensive UX)

🧠 **Senior signal:** mention **business-driven resolution**, not just technical.

---

# 🧬 3. Data Versioning

Each entity includes:

```swift
id
version
updatedAt
lastSyncedAt
isDirty
isDeleted
```

### Versioning Approaches

* **Incrementing version numbers**
* **ETags**
* **Vector clocks** (advanced, rarely needed)

Used for:

* Conflict detection
* Delta sync
* Safe retries

---

# 📉 4. Partial Sync & Delta Updates

### Why Full Sync Is Bad

* Slow
* Battery heavy
* Wastes data

### Delta Sync Approach

* Client stores `lastSyncToken`
* Server returns only:

  * Changed records
  * Deleted IDs
* Supports pagination

Example:

```
GET /changes?since=lastSyncToken
```

### Local Handling

* Apply updates transactionally
* Maintain referential integrity
* Soft delete locally before purge

---

# ⛔ 5. Handling App Termination During Sync

### Risks

* App killed mid-sync
* Partial writes
* Corrupt state

### Solutions

#### ✅ Atomic Operations

* Use DB transactions
* Apply remote changes in batches

#### ✅ Idempotent APIs

* Safe retries
* Server ignores duplicate operations

#### ✅ Checkpointing

* Persist sync progress
* Resume from last successful step

#### ✅ Background Tasks

* `BGAppRefreshTask`
* `BGProcessingTask` (for longer syncs)

#### ✅ Resume Logic

* On next launch:

  * Inspect pending operations
  * Restart sync safely

---

# ⚡ Performance & Reliability Considerations

* Batch network requests
* Exponential backoff retries
* Network reachability awareness
* Priority sync (user-visible data first)
* Graceful degradation (read-only mode)

---

# 🔐 Data Integrity & Security

* Encrypt local DB if sensitive
* Sign sync payloads
* Avoid syncing PII unnecessarily
* Handle account logout → data purge

---

# 🧪 Testing Strategy (Senior Signal)

* Unit test conflict resolution logic
* Integration test sync flows
* Simulate:

  * App kill mid-sync
  * Network flapping
  * Partial failures

---

# 🗣️ How This Sounds in an Interview (TL;DR)

> “I’d treat the local database as the source of truth, use a sync engine with a persistent change queue, rely on delta-based syncing with versioned entities, resolve conflicts based on business rules, and make all sync operations idempotent so app termination doesn’t corrupt state.”

That sentence alone scores **senior-level points**.

---

If you want, I can:

* Turn this into a **10-minute whiteboard answer**
* Map this to **Core Data vs Realm**
* Add **real production pitfalls**
* Do a **mock follow-up grilling**

Just say the word.
