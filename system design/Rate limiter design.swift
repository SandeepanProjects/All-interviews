//
//  Rate limiter design.swift
//  
//
//  Created by Apple on 23/02/26.
//

import Foundation

Rate Limiter is a **very strong system design + concurrency** interview question (especially for senior iOS engineers).

We’ll cover:

1. ✅ Token Bucket (Best Practical Solution)
2. ✅ Actor-Based Modern Swift Version
3. ✅ GCD + Lock-Free Optimized Version
4. ✅ Sliding Window (Server-Grade Design)

---

# 🚀 1️⃣ Best Practical Design → Token Bucket Algorithm

### 🧠 Why Token Bucket?

* Allows burst traffic
* Smooth refill
* O(1) time
* Memory efficient
* Industry standard (API throttling, network calls)

---

## ✅ Thread-Safe Implementation (GCD + Serial Queue)

```swift
final class RateLimiter {
    
    private let capacity: Int
    private let refillRate: Double   // tokens per second
    
    private var tokens: Double
    private var lastRefillTime: CFTimeInterval
    
    private let queue = DispatchQueue(label: "com.ratelimiter.serial")
    
    init(capacity: Int, refillRate: Double) {
        self.capacity = capacity
        self.refillRate = refillRate
        self.tokens = Double(capacity)
        self.lastRefillTime = CACurrentMediaTime()
    }
    
    func allowRequest() -> Bool {
        return queue.sync {
            refillTokensIfNeeded()
            
            guard tokens >= 1 else { return false }
            tokens -= 1
            return true
        }
    }
    
    private func refillTokensIfNeeded() {
        let now = CACurrentMediaTime()
        let elapsed = now - lastRefillTime
        
        let refillAmount = elapsed * refillRate
        tokens = min(Double(capacity), tokens + refillAmount)
        
        lastRefillTime = now
    }
}
```

---

## ✅ Usage

```swift
let limiter = RateLimiter(capacity: 5, refillRate: 1)

if limiter.allowRequest() {
    print("Request allowed")
} else {
    print("Rate limited")
}
```

---

### ⚡ Why This Is Optimal

| Feature            | Result |
| ------------------ | ------ |
| O(1)               | ✅      |
| Thread-safe        | ✅      |
| Allows burst       | ✅      |
| No timers required | ✅      |
| No blocking        | ✅      |

This is **interview-perfect solution**.

---

# 🚀 2️⃣ Modern Swift Concurrency (Actor-Based)

If using iOS 15+:

```swift
actor RateLimiter {
    
    private let capacity: Int
    private let refillRate: Double
    
    private var tokens: Double
    private var lastRefillTime: CFTimeInterval
    
    init(capacity: Int, refillRate: Double) {
        self.capacity = capacity
        self.refillRate = refillRate
        self.tokens = Double(capacity)
        self.lastRefillTime = CACurrentMediaTime()
    }
    
    func allowRequest() -> Bool {
        refillIfNeeded()
        
        guard tokens >= 1 else { return false }
        tokens -= 1
        return true
    }
    
    private func refillIfNeeded() {
        let now = CACurrentMediaTime()
        let elapsed = now - lastRefillTime
        
        let refillAmount = elapsed * refillRate
        tokens = min(Double(capacity), tokens + refillAmount)
        
        lastRefillTime = now
    }
}
```

### 🔥 Why This Is Cleaner

* No locks
* No dispatch queues
* No race conditions
* Fully isolated state

---

# 🏆 3️⃣ High-Performance Lock-Based Version

If extremely performance-sensitive:

```swift
final class FastRateLimiter {
    
    private let capacity: Int
    private let refillRate: Double
    
    private var tokens: Double
    private var lastRefillTime: CFTimeInterval
    
    private let lock = NSLock()
    
    init(capacity: Int, refillRate: Double) {
        self.capacity = capacity
        self.refillRate = refillRate
        self.tokens = Double(capacity)
        self.lastRefillTime = CACurrentMediaTime()
    }
    
    func allowRequest() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        
        let now = CACurrentMediaTime()
        let elapsed = now - lastRefillTime
        
        tokens = min(Double(capacity),
                     tokens + elapsed * refillRate)
        
        lastRefillTime = now
        
        guard tokens >= 1 else { return false }
        tokens -= 1
        return true
    }
}
```

---

# 🚀 4️⃣ Sliding Window Rate Limiter (More Accurate)

More strict but slightly heavier.

```swift
final class SlidingWindowRateLimiter {
    
    private let maxRequests: Int
    private let interval: TimeInterval
    
    private var timestamps: [TimeInterval] = []
    private let queue = DispatchQueue(label: "com.sliding.window")
    
    init(maxRequests: Int, interval: TimeInterval) {
        self.maxRequests = maxRequests
        self.interval = interval
    }
    
    func allowRequest() -> Bool {
        return queue.sync {
            let now = Date().timeIntervalSince1970
            timestamps = timestamps.filter { now - $0 < interval }
            
            guard timestamps.count < maxRequests else {
                return false
            }
            
            timestamps.append(now)
            return true
        }
    }
}
```

---

# 🧠 Interview-Level Explanation

If asked:

> How would you design a rate limiter in iOS?

You answer:

1. Choose algorithm:

   * Token Bucket (most common)
   * Leaky Bucket
   * Fixed Window
   * Sliding Window
2. Ensure thread-safety
3. Ensure O(1) time
4. Avoid timers
5. Use monotonic clock (CACurrentMediaTime)

---

# 🔥 Senior-Level Talking Points

Be ready to explain:

* Why Token Bucket > Fixed Window
* Burst vs steady rate
* Time drift issues
* Why monotonic clock matters
* Backpressure strategies
* How URLSession can integrate with rate limiter
* How to make it distributed
* How to persist tokens
* Fairness concerns

---

# 📊 Complexity

| Operation    | Time |
| ------------ | ---- |
| allowRequest | O(1) |
| Space        | O(1) |

Sliding window:

* Time: O(n)
* Space: O(n)

---

# 🏆 Which Should You Use?

| Scenario                 | Best Choice    |
| ------------------------ | -------------- |
| API throttling           | Token Bucket   |
| Precise request limiting | Sliding Window |
| Modern Swift app         | Actor version  |
| High-performance system  | Lock version   |

---

If you want, I can now give:

* ⭐ Distributed rate limiter design
* ⭐ URLSession integrated limiter
* ⭐ Combine-based rate limiter
* ⭐ AsyncSequence-based limiter
* ⭐ Lock-free atomic implementation
* ⭐ Production-grade retry + limiter combo

Tell me which level you want 🚀
