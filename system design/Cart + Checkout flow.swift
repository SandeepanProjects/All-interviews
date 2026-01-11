//
//  Cart + Checkout flow.swift
//  
//
//  Created by Apple on 11/01/26.
//

import Foundation

Below is a **clean, end-to-end Cart + Checkout design** that *builds on your approach* and elevates it to **production / Walmart-scale quality**. I’ll validate your decisions, fill gaps, and add the *system-level trade-offs interviewers look for*.

---

## 1. Architecture — Validating & Refining Your Approach

Your choices are solid and industry-correct.

### Final Architecture

```
SwiftUI Views
   ↓
ViewModels (MVVM)
   ↓
Use Cases (Cart / Checkout)
   ↓
Repositories
   ↓
Network / Persistence
```

### Navigation

✔ **MVVM + Coordinators**

* Keeps checkout flows isolated
* Enables A/B tests and feature flags
* Simplifies deep linking (push → cart → checkout)

> **Walmart-style apps rely heavily on coordinators due to complex flows.**

---

## 2. Cart Domain Model (Durable & Merge-Friendly)

```swift
struct CartItem: Identifiable, Equatable {
    let id: String          // SKU
    let name: String
    let price: Decimal
    var quantity: Int
    let updatedAt: Date
}

struct Cart {
    let id: String
    let items: [CartItem]
    let lastSyncedAt: Date?
}
```

✔ Timestamp supports merge conflict resolution
✔ SKU-based identity enables deduplication

---

## 3. Persistence Strategy — Why Your Choice Works

### Core Data (Primary)

* Offline cart survival
* Crash-safe
* Mergeable

### NSCache (Secondary)

* Fast in-memory reads
* Automatically purged under memory pressure

**Flow**

```
UI → NSCache → Core Data → API
```

✔ Best-of-both worlds
✔ Battery & memory friendly

---

## 4. Network Layer (Protocol-Driven & Resilient)

```swift
protocol CartAPI {
    func fetchCart() async throws -> Cart
    func updateItem(_ item: CartItem) async throws
    func checkout(_ cart: Cart) async throws -> Order
}
```

✔ Clean DI
✔ Easy mocking
✔ Supports retries + fallbacks

---

## 5. ViewModel (Reactive + Async)

```swift
@MainActor
final class CartViewModel: ObservableObject {
    @Published private(set) var items: [CartItem] = []
    @Published var error: String?
    @Published var isLoading = false

    private let cartUseCase: CartUseCase

    init(cartUseCase: CartUseCase) {
        self.cartUseCase = cartUseCase
    }

    func loadCart() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await cartUseCase.loadCart()
        } catch {
            self.error = "Unable to load cart"
        }
    }

    func updateQuantity(for item: CartItem, qty: Int) async {
        do {
            try await cartUseCase.update(item, qty: qty)
            await loadCart()
        } catch {
            error = "Update failed"
        }
    }
}
```

✔ `@MainActor` prevents UI races
✔ Async-first, Combine-friendly

---

## 6. Offline Cart Access (Your Edge Case — Well Handled)

### Strategy

* Always allow:

  * Add/remove items
  * Quantity updates
* Queue writes locally
* Sync later

```swift
struct PendingCartMutation {
    let sku: String
    let quantity: Int
}
```

### Sync Policy

| Scenario  | Behavior                        |
| --------- | ------------------------------- |
| Offline   | Local only                      |
| Reconnect | Batch sync                      |
| Conflict  | Server wins or latest timestamp |

✔ Predictable
✔ User-friendly

---

## 7. Guest → Logged-In Cart Merge (Critical at Walmart Scale)

### Merge Strategy (Server-Authoritative)

```
Guest Cart + User Cart
→ Deduplicate by SKU
→ Sum quantities
→ Latest update wins price
```

### Flow

```text
Login success
→ POST /cart/merge
→ Replace local cart
```

✔ Prevents price tampering
✔ Avoids duplicate carts

---

## 8. Checkout Flow (Resilient by Design)

### Step-Based Checkout State Machine

```
Cart Review
→ Address
→ Payment
→ Confirmation
```

```swift
enum CheckoutStep {
    case review
    case address
    case payment
    case processing
    case success
    case failure
}
```

✔ State-driven UI
✔ Easy recovery

---

## 9. Checkout UI Resilience (Partial Failures)

### Examples

| Failure          | Behavior            |
| ---------------- | ------------------- |
| Payment declined | Retry payment only  |
| Inventory change | Reprice cart        |
| Network loss     | Resume at last step |

### Never:

* Clear cart on failure
* Retry payment automatically
* Charge twice

✔ Idempotent checkout calls
✔ Explicit user intent

---

## 10. Retry & Network Loss Handling

### Reads

* Retry with backoff
* Cache fallback

### Writes

* Idempotency keys
* Server-side de-duplication

```http
POST /checkout
Idempotency-Key: UUID
```

✔ No double orders
✔ Safe retries

---

## 11. Security & Compliance (Often Missed)

* PCI: No card data stored locally
* Tokens in Keychain
* Certificate pinning
* Encrypted Core Data store
* Jailbreak detection (optional)

---

## 12. Performance Optimizations

### UI

* Diffable lists
* Debounce quantity changes
* Batch updates

### Network

* Coalesce cart updates
* Avoid refetch on every change

---

## 13. What You Got Right (Explicitly Call This Out)

✔ MVVM + Coordinators
✔ Protocol-driven networking
✔ Offline-first thinking
✔ Cart merging logic
✔ Checkout failure handling

> **These are exactly the concerns raised in real Walmart-scale apps.**

---

## 14. Trade-Offs (Interview Gold)

| Choice              | Trade-Off        |
| ------------------- | ---------------- |
| Offline cart        | Complex sync     |
| Server-auth pricing | Extra API calls  |
| Coordinators        | More boilerplate |
| Core Data           | Migration cost   |

---

## Final Takeaway

> **A production cart + checkout system prioritizes correctness, recoverability, and trust—handling offline use, merges, retries, and partial failures without ever losing user intent or double-charging.**

If you want next:

* Write Core Data schemas
* Implement cart merge logic
* Design checkout idempotency backend
* Add unit tests for edge cases
* Compare Combine vs async/await here

Just say the word.


Below is a **concrete, production-grade continuation** of your Cart + Checkout design, covering **all three asks** with the right level of depth for a senior / Walmart-scale discussion.
                        
I’ll structure it as:
                            
1. **Core Data schema (cart + pending mutations)**
2. **Cart merge logic (guest → signed-in)**
3. **Checkout idempotency backend design**
4. **Client retry logic (safe, payment-aware)**
                        
---
                        
# 1. Core Data Schemas (Offline-First Cart)
                        
### Entities
                        
## `CartEntity`
                        
Represents the *current active cart*.
                        
| Field          | Type         | Notes                          |
| -------------- | ------------ | ------------------------------ |
| `id`           | String       | Cart ID (server or local UUID) |
| `userId`       | String?      | `nil` for guest                |
| `lastSyncedAt` | Date?        | Used for conflict resolution   |
| `items`        | Relationship | To `CartItemEntity`            |
                        
---
                        
## `CartItemEntity`
                        
| Field       | Type         | Notes                |
| ----------- | ------------ | -------------------- |
| `sku`       | String       | **Primary key**      |
| `name`      | String       | Snapshot             |
| `price`     | Decimal      | Server-authoritative |
| `quantity`  | Int32        | Editable offline     |
| `updatedAt` | Date         | For merge conflicts  |
| `cart`      | Relationship | To `CartEntity`      |
                        
---
                        
## `PendingCartMutationEntity`
                        
Tracks offline writes.
                        
| Field       | Type   | Notes                     |
| ----------- | ------ | ------------------------- |
| `sku`       | String | SKU being updated         |
| `quantity`  | Int32  | Desired quantity          |
| `createdAt` | Date   | Ordering                  |
| `type`      | String | `add`, `update`, `remove` |
                        
✔ Enables **offline cart editing**
✔ Enables **safe replay**
✔ Avoids lost intent
                        
---
                        
## Why This Schema Works
                        
* One active cart per user/device
* SKU uniqueness prevents duplication
* Pending mutations allow **eventual consistency**
* Easy migration if pricing rules change
                        
---
                        
# 2. Cart Merge Logic (Guest → Signed-In)
                        
### When merge happens
                        
```
Guest user → Login success → Merge carts
```
                        
### Rules (Server-Aligned)
                        
1. Deduplicate by SKU
2. Quantities are **summed**
3. Latest `updatedAt` wins for metadata
4. Server revalidates prices & inventory
                        
---
                        
## Swift Merge Implementation
                        
```swift
func merge(
guestItems: [CartItem],
userItems: [CartItem]
) -> [CartItem] {
    
    var merged: [String: CartItem] = [:]
    
    // Insert user cart first
    for item in userItems {
        merged[item.id] = item
    }
    
    // Merge guest cart
    for guestItem in guestItems {
        if let existing = merged[guestItem.id] {
            let combinedQty = existing.quantity + guestItem.quantity
            
            let latestItem = existing.updatedAt > guestItem.updatedAt
            ? existing
            : guestItem
            
            merged[guestItem.id] = CartItem(
                id: guestItem.id,
                name: latestItem.name,
                price: latestItem.price,
                quantity: combinedQty,
                updatedAt: max(existing.updatedAt, guestItem.updatedAt)
            )
        } else {
            merged[guestItem.id] = guestItem
        }
    }
    
    return Array(merged.values)
}
```

---

## Post-Merge Flow

```text
Client → POST /cart/merge
Server → Reprice + validate
Client → Replace local cart
```

✔ Prevents price abuse
✔ Avoids duplicate carts
✔ Server stays authoritative

---

# 3. Checkout Idempotency Backend Design

This is **critical** in real commerce systems.

---

## API Contract

```http
POST /checkout
Authorization: Bearer <token>
Idempotency-Key: 2b3a8e9e-9b24-4f4d-ae91-91c9f8d1f222
```

```json
{
    "cartId": "cart_123",
    "paymentMethodId": "pm_456",
    "shippingAddressId": "addr_789"
}
```

---

## Backend Behavior

### Step 1: Idempotency Lookup

```sql
PRIMARY KEY (user_id, idempotency_key)
```

| Case                        | Result                 |
| --------------------------- | ---------------------- |
| New key                     | Process checkout       |
| Same key, same payload      | Return cached response |
| Same key, different payload | `409 Conflict`         |

---

## Idempotency Table

```sql
CREATE TABLE checkout_idempotency (
    user_id TEXT,
    idempotency_key TEXT,
    request_hash TEXT,
    response JSON,
    status TEXT,
    created_at TIMESTAMP,
    PRIMARY KEY (user_id, idempotency_key)
);
```

---

## Checkout State Machine (Backend)

```
VALIDATING
→ AUTHORIZING_PAYMENT
→ RESERVING_INVENTORY
→ COMPLETED
→ FAILED
```

✔ Prevents partial orders
✔ Enables recovery after crashes

---

## Why This Is Safe

* Network retries won’t double-charge
* App restarts won’t lose checkout state
* Client can safely retry on timeouts

---

# 4. Client Retry Logic (Correct & Safe)

### Golden Rule

> **Never automatically retry payments unless the backend guarantees idempotency.**

---

## Retry Policy

### Safe to Retry Automatically

* Fetch cart
* Fetch pricing
* Inventory validation

### Retry with Idempotency Key

* Checkout submission

### Never Auto-Retry

* Card authorization without idempotency

---

## Retry Implementation (Swift)

```swift
func retrying<T>(
    maxAttempts: Int = 3,
    task: @escaping () async throws -> T
) async throws -> T {
    
    var attempt = 0
    
    while true {
        do {
            return try await task()
        } catch {
            attempt += 1
            if attempt >= maxAttempts {
                throw error
            }
            try await Task.sleep(nanoseconds: 500_000_000)
        }
    }
}
```

---

## Checkout Call (Safe Retry)

```swift
let idempotencyKey = UUID().uuidString

try await retrying {
    try await checkoutAPI.submit(
        cartId: cartId,
        idempotencyKey: idempotencyKey
    )
}
```

✔ Same key reused
✔ No double order risk

---

# 5. Failure Scenarios & UX Behavior

| Failure           | App Response                  |
| ----------------- | ----------------------------- |
| Network drop      | Resume checkout               |
| App killed        | Reload status via idempotency |
| Inventory changed | Reprice & confirm             |
| Payment declined  | User action required          |

---

# 6. What This Design Guarantees

✔ Offline cart persistence
✔ Deterministic cart merges
✔ Safe retries under failure
✔ No double charges
✔ Audit-friendly checkout flow

---

# Final Takeaway

> **A real-world cart + checkout system is an offline-first, idempotent, state-driven workflow that never loses user intent and never charges twice—no matter how bad the network is.**

If you want next:

* Core Data migration strategies
* Cart sync background tasks
* Checkout UI state machine in SwiftUI
* Unit tests for merge + retry logic
* Compare Core Data vs SQLite here


Below is a **complete, production-style answer** covering **all three items**, with **concrete Swift code** and the right architectural reasoning for a large-scale commerce app.
                    
---
                    
# 1️⃣ Cart Sync Background Tasks (iOS)
                    
## Goals
                    
* Sync cart mutations when:
                        
* App enters background
* Network reconnects
* User logs in
* Never block UI
* Never lose cart intent
                    
---
                    
## Background Task Design
                    
### When to sync
                    
* Pending cart mutations exist
* Device has connectivity
* App in background or foreground
                    
### iOS Tooling
                    
* **BGTaskScheduler**
* **URLSession background configuration**
                    
---
                    
## Register Background Task
                    
```swift
func registerBackgroundTasks() {
    BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "com.app.cart.sync",
        using: nil
    ) { task in
        self.handleCartSync(task: task as! BGProcessingTask)
    }
}
```

---

## Schedule Cart Sync

```swift
func scheduleCartSync() {
    let request = BGProcessingTaskRequest(
        identifier: "com.app.cart.sync"
    )
    request.requiresNetworkConnectivity = true
    request.requiresExternalPower = false
    
    try? BGTaskScheduler.shared.submit(request)
}
```

---

## Handle Background Sync

```swift
func handleCartSync(task: BGProcessingTask) {
    task.expirationHandler = {
        task.setTaskCompleted(success: false)
    }
    
    Task {
        do {
            try await cartSyncService.syncPendingMutations()
            task.setTaskCompleted(success: true)
        } catch {
            task.setTaskCompleted(success: false)
        }
    }
}
```

---

## Sync Logic (Batching Mutations)

```swift
final class CartSyncService {
    func syncPendingMutations() async throws {
        let mutations = fetchPendingMutations()
        
        guard !mutations.isEmpty else { return }
        
        try await api.syncCart(mutations)
        deleteSyncedMutations()
    }
}
```

✔ Background-safe
✔ Battery-aware
✔ Resilient to app termination

---

# 2️⃣ Checkout UI State Machine (SwiftUI)

## Why a State Machine?

Checkout flows **must not rely on view navigation alone**.

You need:

* Recoverability
* Partial failure handling
* Deterministic transitions

---

## Checkout States

```swift
enum CheckoutState {
    case review
    case address
    case payment
    case processing
    case success(Order)
    case failure(String)
}
```

---

## Checkout ViewModel

```swift
@MainActor
final class CheckoutViewModel: ObservableObject {
    @Published private(set) var state: CheckoutState = .review
    
    func next() {
        switch state {
        case .review:
            state = .address
        case .address:
            state = .payment
        case .payment:
            submit()
        default:
            break
        }
    }
    
    func submit() {
        state = .processing
        
        Task {
            do {
                let order = try await checkout()
                state = .success(order)
            } catch {
                state = .failure("Payment failed")
            }
        }
    }
}
```

---

## SwiftUI View

```swift
struct CheckoutView: View {
    @StateObject var vm: CheckoutViewModel
    
    var body: some View {
        switch vm.state {
        case .review:
            ReviewView(onNext: vm.next)
        case .address:
            AddressView(onNext: vm.next)
        case .payment:
            PaymentView(onPay: vm.next)
        case .processing:
            ProgressView("Processing...")
        case .success(let order):
            SuccessView(order: order)
        case .failure(let message):
            ErrorView(message: message, retry: vm.submit)
        }
    }
}
```

✔ No illegal transitions
✔ Resume-safe
✔ Easy analytics instrumentation

---

# 3️⃣ Unit Tests — Merge + Retry Logic

## A) Cart Merge Unit Tests

### Merge Function (recap)

```swift
func mergeCarts(
    guest: [CartItem],
    user: [CartItem]
) -> [CartItem] {
    var map = Dictionary(
        uniqueKeysWithValues: user.map { ($0.id, $0) }
    )
    
    for item in guest {
        if let existing = map[item.id] {
            map[item.id] = CartItem(
                id: item.id,
                name: existing.name,
                price: existing.price,
                quantity: existing.quantity + item.quantity,
                updatedAt: max(existing.updatedAt, item.updatedAt)
            )
        } else {
            map[item.id] = item
        }
    }
    return Array(map.values)
}
```

---

### Unit Test

```swift
func test_cart_merge_combines_quantities() {
    let user = [
        CartItem(id: "sku1", name: "Item", price: 10, quantity: 1, updatedAt: .now)
    ]
    let guest = [
        CartItem(id: "sku1", name: "Item", price: 10, quantity: 2, updatedAt: .now)
    ]
    
    let merged = mergeCarts(guest: guest, user: user)
    
    XCTAssertEqual(merged.first?.quantity, 3)
}
```

---

## B) Retry Logic Unit Tests

### Retry Helper

```swift
func retry<T>(
    maxAttempts: Int,
    task: @escaping () async throws -> T
) async throws -> T {
    var attempts = 0
    while true {
        do {
            return try await task()
        } catch {
            attempts += 1
            if attempts >= maxAttempts {
                throw error
            }
        }
    }
}
```

---

### Test: Succeeds After Retry

```swift
func test_retry_succeeds_after_failure() async throws {
    var callCount = 0
    
    let result = try await retry(maxAttempts: 3) {
        callCount += 1
        if callCount < 2 {
            throw URLError(.timedOut)
        }
        return "Success"
    }
    
    XCTAssertEqual(result, "Success")
    XCTAssertEqual(callCount, 2)
}
```

---

### Test: Fails After Max Retries

```swift
func test_retry_fails_after_max_attempts() async {
    var callCount = 0
    
    do {
        _ = try await retry(maxAttempts: 2) {
            callCount += 1
            throw URLError(.cannotConnectToHost)
        }
        XCTFail("Expected failure")
    } catch {
        XCTAssertEqual(callCount, 2)
    }
}
```

---

# 4️⃣ What This Design Guarantees

✔ Cart never lost offline
✔ Sync happens opportunistically
✔ Checkout never double-charges
✔ UI always reflects real state
✔ Tests protect critical logic

---

# Final Takeaway

> **A real commerce app treats cart sync as a background system, checkout as a state machine, and retries as a correctness problem—not a UX hack.**

If you want next:

* Cart conflict resolution strategies
* Checkout recovery after app crash
* Background task limits & tuning
* Payment analytics instrumentation
* Feature flagging checkout steps
