//
//  fintech.swift
//  
//
//  Created by Apple on 11/01/26.
//

import Foundation

Below is a **concise but realistic fintech-style answer** that covers **implementation, architecture, trade-offs, and system thinking**, the way you’d be expected to reason in a senior mobile / fintech interview.

I’ll structure it as:

1. Small payments feature (transaction history) – **clean & testable Swift code**
2. Network error handling strategy
3. Transaction history + caching design
4. Trade-offs: offline, pagination, security
5. Handling failed payments gracefully
6. How to prioritize features in a fast-moving fintech app
7. Key system trade-offs for mobile fintech

---

## 1. Small Payments Feature: Transaction History

### Feature scope (intentionally small)

* Display transaction history
* Pull-to-refresh
* Cached results
* Graceful error handling

---

## 2. Clean Architecture Overview

```
SwiftUI View
   ↓
ViewModel (state + intent)
   ↓
Use Case (business logic)
   ↓
Repository (API + cache)
```

This ensures:

* UI is dumb
* Business rules testable
* Network easily mocked

---

## 3. Domain Model

```swift
struct Transaction: Identifiable, Equatable {
    let id: String
    let amount: Decimal
    let currency: String
    let status: TransactionStatus
    let createdAt: Date
}

enum TransactionStatus {
    case success
    case pending
    case failed(reason: String)
}
```

---

## 4. Repository (API + Cache)

### Protocol (critical for testability)

```swift
protocol TransactionRepository {
    func fetchTransactions(page: Int) async throws -> [Transaction]
}
```

---

### API implementation with error mapping

```swift
enum NetworkError: Error {
    case noInternet
    case serverError
    case unauthorized
}

final class RemoteTransactionRepository: TransactionRepository {
    func fetchTransactions(page: Int) async throws -> [Transaction] {
        // Simulated failure
        if Bool.random() {
            throw NetworkError.noInternet
        }

        return [
            Transaction(
                id: UUID().uuidString,
                amount: 49.99,
                currency: "USD",
                status: .success,
                createdAt: .now
            )
        ]
    }
}
```

---

### Cached decorator

```swift
final class CachedTransactionRepository: TransactionRepository {
    private let remote: TransactionRepository
    private var cache: [Transaction] = []

    init(remote: TransactionRepository) {
        self.remote = remote
    }

    func fetchTransactions(page: Int) async throws -> [Transaction] {
        do {
            let transactions = try await remote.fetchTransactions(page: page)
            if page == 1 {
                cache = transactions
            } else {
                cache += transactions
            }
            return transactions
        } catch {
            if !cache.isEmpty {
                return cache
            }
            throw error
        }
    }
}
```

---

## 5. Use Case

```swift
protocol FetchTransactionsUseCase {
    func execute(page: Int) async throws -> [Transaction]
}

final class FetchTransactionsUseCaseImpl: FetchTransactionsUseCase {
    private let repository: TransactionRepository

    init(repository: TransactionRepository) {
        self.repository = repository
    }

    func execute(page: Int) async throws -> [Transaction] {
        try await repository.fetchTransactions(page: page)
    }
}
```

---

## 6. ViewModel (Error-Aware)

```swift
@MainActor
final class TransactionListViewModel: ObservableObject {
    @Published private(set) var transactions: [Transaction] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let fetchUseCase: FetchTransactionsUseCase
    private var page = 1

    init(fetchUseCase: FetchTransactionsUseCase) {
        self.fetchUseCase = fetchUseCase
    }

    func loadInitial() async {
        page = 1
        await load()
    }

    func loadMore() async {
        page += 1
        await load()
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let newItems = try await fetchUseCase.execute(page: page)
            if page == 1 {
                transactions = newItems
            } else {
                transactions += newItems
            }
        } catch let error as NetworkError {
            handle(error)
        } catch {
            errorMessage = "Unexpected error"
        }
    }

    private func handle(_ error: NetworkError) {
        switch error {
        case .noInternet:
            errorMessage = "No internet connection"
        case .unauthorized:
            errorMessage = "Session expired"
        case .serverError:
            errorMessage = "Server error. Try again."
        }
    }
}
```

---

## 7. SwiftUI View (Minimal)

```swift
struct TransactionListView: View {
    @StateObject var vm: TransactionListViewModel

    var body: some View {
        List(vm.transactions) { tx in
            VStack(alignment: .leading) {
                Text("\(tx.amount) \(tx.currency)")
                Text(tx.statusText).font(.caption)
            }
        }
        .refreshable {
            await vm.loadInitial()
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .task {
            await vm.loadInitial()
        }
    }
}

private extension Transaction {
    var statusText: String {
        switch status {
        case .success: return "Success"
        case .pending: return "Pending"
        case .failed(let reason): return "Failed: \(reason)"
        }
    }
}
```

---

## 8. Transaction History & Caching Design

### Strategy

* **Memory cache** → fast UI
* **Disk cache (encrypted)** → offline
* **Network** → source of truth

### Pagination

* Cursor-based pagination preferred over page numbers
* Prevents duplicates and race conditions

```text
GET /transactions?cursor=abc123
```

---

## 9. Trade-Offs Discussion

### Offline Support

✅ Pros:

* App feels reliable
* Users trust financial apps more

❌ Cons:

* Complex reconciliation
* Conflict handling required

**Typical compromise**

* Read-only offline
* Writes require network

---

### Pagination

* Small pages → smoother UI, more requests
* Large pages → memory + latency spikes

**Fintech standard**: 20–50 items per page

---

### Security

* No sensitive data in logs
* Encrypt disk cache
* Use Secure Enclave / Keychain
* Token rotation + short-lived access tokens

---

## 10. Handling Failed Payments Gracefully

### Golden rules

1. **Never lose user intent**
2. **Never double-charge**
3. **Always show clear status**

### UI states

* Pending (processing)
* Failed (retry / contact support)
* Success (receipt)

### Retry strategy

* Idempotency keys
* Backend-controlled retries
* User-triggered retry only when safe

```text
POST /payments
Idempotency-Key: uuid
```

---

## 11. Prioritizing Features in a Fast-Moving Fintech App

### Priority order (real-world)

1. **Correctness & trust**
2. **Security & compliance**
3. **Core money flows**
4. UX polish
5. Power-user features

Ask:

* Does this reduce failed payments?
* Does this improve trust?
* Does this unblock revenue?

---

## 12. System-Level Trade-Offs in Mobile Fintech

| Trade-off           | Decision           |
| ------------------- | ------------------ |
| Speed vs Safety     | Safety always wins |
| Offline vs Accuracy | Prefer accuracy    |
| UX vs Compliance    | Compliance wins    |
| Caching vs Privacy  | Encrypt + minimize |

---

## Final Takeaway

> **Fintech mobile systems prioritize correctness, security, and trust over speed. Clean architecture, explicit error handling, offline-aware caching, and idempotent payments are what separate a toy app from a real payments system.**

If you want, I can:

* Add unit tests with mocked repositories
* Design a payment retry state machine
* Extend this to real-time updates via WebSockets
* Show how Apple Pay / PCI constraints affect architecture
