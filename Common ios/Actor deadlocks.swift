//
//  Actor deadlocks.swift
//  
//
//  Created by Apple on 04/03/26.
//

import Foundation

Since you’re preparing for senior/lead iOS roles (based on your previous questions on actors, deadlocks, priority inversion, etc.), let’s go deep and understand **Swift actor reentrancy** properly — not just definition level, but interview + production level.

---

# 🔁 Swift Actor Reentrancy — Deep Explanation

## 1️⃣ What is Actor Reentrancy?

In Swift Concurrency, **actors are reentrant by default**.

That means:

> When an actor function hits an `await`, the actor can temporarily suspend that function and allow another task to enter the actor and mutate its state.

So even though actors provide **data isolation**, they do **NOT** guarantee that state remains unchanged across `await` suspension points.

---

## 2️⃣ Why Does Swift Allow Reentrancy?

If actors were non-reentrant:

* One slow network call inside actor
* Entire actor blocked
* All other requests queued
* Massive performance bottleneck

Reentrancy improves:

* Throughput
* Responsiveness
* Deadlock avoidance
* Avoids priority inversion

---

## 3️⃣ Visual Timeline Example

```swift
actor BankAccount {
    var balance: Int = 1000

    func withdraw(amount: Int) async throws {
        guard balance >= amount else {
            throw Error.insufficientFunds
        }

        await processTransaction()   // ⛔ suspension point

        balance -= amount
    }

    func processTransaction() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}
```

### What Can Go Wrong?

Timeline:

1. Task A enters `withdraw(800)`
2. balance = 1000 ✅
3. Hits `await processTransaction()` → suspends
4. Task B enters `withdraw(500)`
5. balance still = 1000 ✅
6. B suspends
7. A resumes → balance = 200
8. B resumes → balance = -300 ❌

Even though actor protects memory, logical race still happened.

This is **reentrancy bug**.

---

# 🧠 Key Rule

> Actor guarantees memory safety
> Actor does NOT guarantee logical consistency across suspension points

---

# 4️⃣ Reentrancy vs Deadlock

Earlier you asked about actor deadlocks. Reentrancy actually helps avoid this:

```swift
actor A {
    var b: B?

    func callB() async {
        await b?.callA()
    }
}

actor B {
    var a: A?

    func callA() async {
        await a?.callB()
    }
}
```

Because actors are reentrant:

* They don’t block themselves permanently
* They yield at suspension points
* So traditional thread deadlocks don’t happen

But you may create:

* Infinite recursion
* Livelocks
* Logical starvation

---

# 5️⃣ How to Fix Reentrancy Bugs

## ✅ Pattern 1: Re-check State After Await

```swift
func withdraw(amount: Int) async throws {
    guard balance >= amount else {
        throw Error.insufficientFunds
    }

    await processTransaction()

    guard balance >= amount else {
        throw Error.insufficientFunds
    }

    balance -= amount
}
```

---

## ✅ Pattern 2: Move Mutation Before Await

Safer approach:

```swift
func withdraw(amount: Int) async throws {
    guard balance >= amount else {
        throw Error.insufficientFunds
    }

    balance -= amount   // mutate first

    await processTransaction()
}
```

This is usually preferred.

---

## ✅ Pattern 3: Use Non-Async Critical Sections

Split logic:

```swift
func withdraw(amount: Int) async throws {
    try deduct(amount)
    await processTransaction()
}

private func deduct(_ amount: Int) throws {
    guard balance >= amount else {
        throw Error.insufficientFunds
    }
    balance -= amount
}
```

No suspension inside critical section.

---

## 6️⃣ Real-World Example (Token Refresh Actor)

You asked earlier about production-grade token refresh using actors.

Classic bug:

```swift
actor AuthManager {
    var token: String?

    func getToken() async -> String {
        if token == nil {
            token = await refresh()
        }
        return token!
    }
}
```

Two tasks call `getToken()`:

* Both see `token == nil`
* Both call refresh()
* Double refresh ❌

Fix with in-flight task tracking:

```swift
actor AuthManager {
    private var token: String?
    private var refreshTask: Task<String, Never>?

    func getToken() async -> String {
        if let token = token {
            return token
        }

        if let task = refreshTask {
            return await task.value
        }

        let task = Task { await refresh() }
        refreshTask = task

        let newToken = await task.value
        token = newToken
        refreshTask = nil

        return newToken
    }
}
```

This is production-grade reentrancy-safe pattern.

---

# 7️⃣ Interview-Level Definition

If interviewer asks:

> What is actor reentrancy?

Answer:

> Swift actors are reentrant, meaning when an actor-isolated function suspends at an await point, other tasks may enter the actor and execute concurrently. This prevents blocking and improves performance but requires careful state management because actor state can change between suspension points.

---

# 8️⃣ When Is Reentrancy Dangerous?

Be careful when:

* Checking state before await
* Read → await → write pattern
* Banking logic
* Inventory systems
* Token refresh
* Caching layers
* Retry mechanisms (like you’re building)

---

# 9️⃣ When Is Reentrancy Helpful?

* Networking
* Database calls
* File IO
* Background refresh
* Large modular apps (like you asked earlier)

---

# 🔥 Senior-Level Insight

Actors give:

* Thread safety ✅
* Memory safety ✅
* Isolation ✅

But NOT:

* Atomic async operations ❌
* Transaction guarantees ❌

If you need atomic async operations:

* Use task tracking
* Use state machines
* Use AsyncSequence
* Use explicit locking inside actor (rare but possible)
* Or design idempotent operations

---

# 🎯 Final Mental Model

Think of an actor like:

> A single-threaded room with a door
> But whenever someone inside says “await”, they temporarily step outside
> And someone else can enter the room

That’s reentrancy.

---

If you want, I can next explain:

* ❓ How reentrancy affects priority inversion
* ❓ How Swift 6 strict concurrency impacts actor reentrancy
* ❓ Non-reentrant actor patterns
* ❓ Advanced reentrancy-safe architecture for large modular apps

Tell me what you want to go deeper into.


Great question 👍 — since you’re working deeply with Swift concurrency, let’s fix this properly at an architectural level.

Deadlocks with Swift actors are usually **logical dependency cycles**, not lock-based issues.

Below is a practical, production-grade guide.

---

# 🔥 1️⃣ Fix Cyclic Actor Calls (Most Common Issue)

## ❌ Problem

```
ActorA → awaits ActorB
ActorB → awaits ActorA
```

Example:

```swift
actor A {
    var b: B?

    func callB() async {
        await b?.callA()
    }
}

actor B {
    var a: A?

    func callA() async {
        await a?.callB()
    }
}
```

This creates a circular dependency.

---

## ✅ Fix: Break the Cycle with a Coordinator

Instead of actors calling each other, use a third layer:

```swift
class Coordinator {
    let a = A()
    let b = B()

    func start() async {
        await a.work()
        await b.work()
    }
}
```

### Rule:

👉 **Actors should not form bidirectional await chains.**

Prefer:

```
Coordinator → A
Coordinator → B
```

Not:

```
A ↔ B
```

---

# 🔥 2️⃣ Remove Blocking Calls Inside Actors

## ❌ Problem

```swift
actor MyActor {
    func work() {
        DispatchQueue.main.sync {
            print("Deadlock")
        }
    }
}
```

This can deadlock if you're already on the main thread.

---

## ✅ Fix: Use async APIs Instead

```swift
actor MyActor {
    func work() async {
        await MainActor.run {
            print("Safe")
        }
    }
}
```

### Golden Rule:

🚫 Never use:

* `DispatchQueue.sync`
* `semaphore.wait()`
* `sleep()`
* blocking I/O

Actors must stay non-blocking.

---

# 🔥 3️⃣ Avoid Awaiting Back Into Same Actor

## ❌ Problem

```swift
actor Counter {
    func increment() async {
        await helper()
    }

    func helper() async {
        await increment() // cycle
    }
}
```

Infinite suspension.

---

## ✅ Fix: Separate Internal Sync Logic from Async Entry Points

```swift
actor Counter {
    func increment() async {
        helper()
    }

    private func helper() {
        // internal logic
    }
}
```

### Rule:

👉 Internal actor logic should be synchronous whenever possible.

---

# 🔥 4️⃣ Fix Long Await Chains (Reentrancy Issues)

Actors are **reentrant**.

When you do:

```swift
actor BankAccount {
    var balance = 100

    func withdraw() async {
        if balance > 0 {
            await networkCall()
            balance -= 10
        }
    }
}
```

Another task can modify `balance` during `await`.

This is not a deadlock — but can create logical corruption.

---

## ✅ Fix: Capture State Before Await

```swift
actor BankAccount {
    var balance = 100

    func withdraw() async {
        guard balance > 0 else { return }
        balance -= 10 // mutate first
        await networkCall()
    }
}
```

Or split logic:

```swift
func withdraw() async {
    let canWithdraw = balance > 0
    guard canWithdraw else { return }

    await networkCall()
    balance -= 10
}
```

---

# 🔥 5️⃣ Use Detached Tasks Carefully

Bad:

```swift
actor A {
    func start() {
        Task {
            await self.doWork()
        }
    }
}
```

You can accidentally create hidden dependencies.

---

## ✅ Fix: Prefer Structured Concurrency

Use:

* `async let`
* `TaskGroup`
* top-level coordination

Avoid nested unstructured tasks inside actors unless necessary.

---

# 🧠 Architectural Patterns That Prevent Actor Deadlocks

### ✅ Pattern 1: Single Responsibility Actors

Each actor owns one domain:

* CacheActor
* NetworkActor
* DatabaseActor

No cross-calls unless strictly one-directional.

---

### ✅ Pattern 2: Event-Driven Instead of Call-Driven

Instead of:

```
A calls B and waits
```

Use:

```
A emits event
Coordinator reacts
```

This removes circular waits entirely.

---

### ✅ Pattern 3: Dependency Injection Without Cycles

Never do:

```
A has B
B has A
```

Instead inject only what is required, or use weak references + coordinator.

---

# 🧪 How to Debug Actor Deadlocks

### 1️⃣ Enable Concurrency Debugging

In Xcode:

```
Thread Sanitizer
Concurrency Runtime Checks
```

### 2️⃣ Look for:

* Tasks stuck in “Suspended”
* Circular await stacks
* Actor hops in stack traces

---

# 🎯 Senior-Level Interview Answer

If asked:

> How do you fix deadlocks in Swift actors?

You say:

> Deadlocks in Swift actors typically arise from cyclic async dependencies rather than traditional locking. I fix them by breaking bidirectional await chains using coordinators, avoiding blocking calls inside actors, minimizing awaits within actor-isolated state mutations, and structuring concurrency to prevent circular task dependencies.

That answer signals deep concurrency understanding.

---

If you want next-level depth, I can explain:

* 🔬 How executors schedule actor tasks internally
* ⚠️ Reentrancy hazards in production banking/chat apps
* 🏗 Designing actor graphs for systems with 10M users (like you asked earlier)

Just tell me how deep you want to go.



Good — this is a classic **cyclic actor dependency** problem in Swift.

Your current structure creates this wait cycle:

```
A.callB() → awaits B.callA()
B.callA() → awaits A.callB()
```

That can suspend forever.

Let’s fix this **properly**, not with hacks.

---

# ✅ Correct Fix: Remove Bidirectional Await

The real problem is:

```
A ↔ B (two-way async dependency)
```

We must make it:

```
Coordinator → A
Coordinator → B
```

Actors should **not call each other and await back**.

---

# 🔥 Proper Architectural Fix (Coordinator Pattern)

## Step 1: Remove references to each other

```swift
actor A {
    func doWork() async {
        print("A work done")
    }
}

actor B {
    func doWork() async {
        print("B work done")
    }
}
```

---

## Step 2: Introduce a Coordinator

```swift
final class Coordinator {
    private let a = A()
    private let b = B()

    func start() async {
        await a.doWork()
        await b.doWork()
    }
}
```

Now there is:

* No circular await
* No dependency cycle
* No logical deadlock

---

# 🚀 If A Truly Needs Something From B

Instead of calling and waiting, inject a closure or value.

## Option 1 — Pass Data Instead of Actor

```swift
actor A {
    func process(input: String) async {
        print("A received \(input)")
    }
}

actor B {
    func produce() async -> String {
        return "Data from B"
    }
}

final class Coordinator {
    let a = A()
    let b = B()

    func run() async {
        let value = await b.produce()
        await a.process(input: value)
    }
}
```

This is clean and safe.

---

# 🧠 If You Absolutely Need Cross-Communication

Use **non-blocking notification style** instead of awaiting back.

## Example Using Detached Fire-and-Forget

```swift
actor A {
    weak var b: B?

    func callB() {
        Task {
            await b?.notify()
        }
    }

    func notify() {
        print("A notified")
    }
}

actor B {
    weak var a: A?

    func notify() {
        print("B notified")
    }
}
```

Notice:

* No `await` cycle
* No circular suspension
* No deadlock

But coordinator pattern is still better.

---

# 🏗 Production-Grade Rule

For large systems (like chat / banking / 10M users):

### ❌ Never:

* Inject actors into each other
* Await in both directions

### ✅ Always:

* Use orchestration layer
* Use unidirectional flow
* Prefer event-driven communication

---

# 🎯 The Core Principle

Deadlocks disappear when you eliminate:

```
Circular wait + await
```

Actors are safe from data races —
but not from bad architecture.

---

If you'd like, I can now show:

* 🔬 Why Swift actor reentrancy makes this worse
* 🧠 How executors schedule these calls internally
* 🏗 A scalable actor graph design used in real systems


**deadlocks can still happen with actors in Swift**, even though Swift actors are designed to prevent traditional data races.

Actors give you **data isolation**, not automatic deadlock immunity.

Let’s break this down clearly 👇

---

# ✅ What Actors Prevent

Actors:

* Protect mutable state
* Ensure only one task accesses actor-isolated state at a time
* Eliminate classic mutex-based race conditions

But they **do NOT prevent logical deadlocks**.

---

# 🚨 When Deadlocks Can Still Happen

## 1️⃣ Cyclic Await Between Actors (Most Common)

If two actors call each other and both wait for the other to finish — you can create a cycle.

```swift
actor A {
    var b: B?

    func callB() async {
        await b?.callA()
    }
}

actor B {
    var a: A?

    func callA() async {
        await a?.callB()
    }
}
```

If:

```
A → awaits B
B → awaits A
```

You now have a **logical deadlock cycle**.

Even though actors are reentrant, you can still create circular wait dependencies.

---

## 2️⃣ Blocking Inside an Actor (Very Dangerous)

If you block a thread inside an actor:

```swift
actor MyActor {
    func work() {
        DispatchQueue.main.sync {
            print("Deadlock possible")
        }
    }
}
```

If called from main thread → 💥 deadlock.

Actors don’t protect you from:

* `DispatchQueue.sync`
* `semaphore.wait()`
* `sleep()`
* any blocking API

Actors expect **non-blocking async code**.

---

## 3️⃣ Awaiting on the Same Actor Incorrectly

Actors are **reentrant**, meaning:

When you `await`, the actor can process other messages.

But if you accidentally structure code like this:

```swift
actor Counter {
    var value = 0

    func increment() async {
        await longRunningTask()
        value += 1
    }

    func longRunningTask() async {
        await increment() // ⚠️ recursive await cycle
    }
}
```

You can create logical lockups or infinite suspensions.

---

## 4️⃣ Task + Actor Dependency Deadlocks

```swift
actor Database {
    func save() async {}
}

let db = Database()

Task {
    await db.save()
}
```

Now imagine:

* The actor awaits something
* That something awaits the same actor

You can build subtle dependency chains.

---

# ⚠️ Important: Actors Are Reentrant

This is key.

In Swift:

* Actors are **not like locks**
* They release execution when hitting `await`
* Other tasks can enter

So classical mutex deadlocks are rare.

But logical deadlocks (cyclic async dependencies) are still possible.

---

# 🧠 How Swift Actors Actually Work Internally

Under the hood:

* Each actor has a mailbox
* Tasks enqueue messages
* An executor runs them one at a time
* On `await`, execution suspends
* Actor can process another message

So deadlock occurs only when:

```
Task A waits for Task B
Task B waits for Task A
```

That’s a dependency cycle — not a lock issue.

---

# 🚀 Best Practices to Avoid Deadlocks with Actors

### ✅ 1. Avoid cyclic actor references

Break dependency chains.

### ✅ 2. Never block inside actors

No:

* `sync`
* semaphores
* blocking network calls

### ✅ 3. Keep actor methods small

Don’t mix too many responsibilities.

### ✅ 4. Prefer one-directional communication

Instead of:

```
A ↔ B
```

Prefer:

```
Coordinator → A
Coordinator → B
```

---

# 🎯 Interview-Ready Answer

If asked:

> Can deadlocks happen with Swift actors?

You say:

> Yes. Actors prevent data races but do not eliminate logical deadlocks. Cyclic async dependencies between actors, blocking calls inside actor methods, or improper awaiting patterns can still lead to deadlocks. However, classic mutex-style deadlocks are largely avoided due to actor reentrancy.

---

If you want, I can now explain:

* 🔬 Deep internal executor + mailbox mechanics
* 🔥 Actor reentrancy pitfalls in production
* 🏗 Real-world architecture patterns to avoid actor deadlocks (important for senior iOS interviews)

Just tell me your depth level 😄

