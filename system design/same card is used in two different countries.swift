//
//  same card is used in two different countries.swift
//  
//
//  Created by Apple on 11/01/26.
//

import Foundation

write optimal solution in swift

You receive a list of transactions with (cardNumber, country, timestamp). Detect if the same card is used in two different countries within 5 minutes.

Thought Process:

Sort transactions by timestamp.

Store last transaction in a dictionary keyed by card number.

Compare current with last-If countries differ and time gap ≤ 5 minutes, return true.

Here’s a **clean, optimal Swift solution** that follows exactly the approach you described, with correct data modeling and edge-case handling.

---

## Data model

```swift
struct Transaction {
    let cardNumber: String
    let country: String
    let timestamp: Date
}
```

---

## Solution

```swift
func hasSuspiciousTransaction(_ transactions: [Transaction]) -> Bool {
    // 1. Sort by timestamp ascending
    let sorted = transactions.sorted { $0.timestamp < $1.timestamp }

    // 2. Track last transaction per card
    var lastTransactionByCard: [String: Transaction] = [:]

    // 5 minutes in seconds
    let fiveMinutes: TimeInterval = 5 * 60

    // 3. Scan transactions
    for transaction in sorted {
        if let last = lastTransactionByCard[transaction.cardNumber] {
            let timeDiff = transaction.timestamp.timeIntervalSince(last.timestamp)

            // 4. Check country mismatch within 5 minutes
            if last.country != transaction.country && timeDiff <= fiveMinutes {
                return true
            }
        }

        // 5. Update last transaction for this card
        lastTransactionByCard[transaction.cardNumber] = transaction
    }

    return false
}
```

---

## Why this is optimal

### Time Complexity

* Sorting: **O(n log n)**
* Single pass scan: **O(n)**

### Space Complexity

* Dictionary storing last transaction per card: **O(k)**
  where `k` = number of unique cards

---

## Notes an interviewer would like

* Only the **most recent transaction per card** matters
* Early exit on first detection
* Works for:

  * Same timestamp transactions
  * Multiple cards
  * Multiple countries
* Easily adaptable for streaming data (remove sorting)

---

## Optional: Streaming version (no sorting)

If transactions already arrive in timestamp order:

```swift
func hasSuspiciousTransactionStreaming(_ transactions: [Transaction]) -> Bool {
    var lastTransactionByCard: [String: Transaction] = [:]
    let fiveMinutes: TimeInterval = 5 * 60

    for transaction in transactions {
        if let last = lastTransactionByCard[transaction.cardNumber] {
            if last.country != transaction.country &&
               transaction.timestamp.timeIntervalSince(last.timestamp) <= fiveMinutes {
                return true
            }
        }
        lastTransactionByCard[transaction.cardNumber] = transaction
    }

    return false
}
```

---

### One-line takeaway

> **Sort by time, track last use per card, and flag a country change within 5 minutes — clean, optimal, and production-ready.**
