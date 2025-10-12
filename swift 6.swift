//
//  swift 6.swift
//  
//
//  Created by Apple on 12/10/25.
//

import Foundation

Here are some of the big new features in **Swift 6**, along with enhancements added in Swift 6.1 and 6.2. If you want, I can give a shorter summary or focus on features relevant to a certain domain (iOS, server‑side, embedded, etc.).

---

## Key Features in Swift 6

1. **Opt‑in Data‑Race Safety Mode / Concurrency Safety**
   Swift 6 introduces a language mode (opt‑in) that enforces stronger data‑race safety: the compiler can diagnose potential data races as *errors* rather than just warnings. Improvements have also been made in `Sendable` inference and in how mutable state is transferred between actors. ([Swift.org][1])

2. **Typed Throws**
   Functions can now explicitly specify *which error type* they throw as part of their signature. This gives stronger guarantees / clarity about what kind of error is possible. ([Swift.org][1])

3. **Enhanced C++ Interoperability**
   More support for interoperability with C++: move‑only types, virtual methods, default arguments, `std::map`, `std::optional`, etc. Also ability to annotate C++ types as non‑copyable (or force Swift to treat them that way) for performance or ownership semantics. ([Swift.org][1])

4. **Embedded Swift (Experimental Preview)**
   A subset of Swift and a toolchain mode for embedded environments (microcontrollers, bare‑metal). It aims for small binaries, no big runtime/type metadata dependencies, targets like ARM and RISC‑V bare metal. ([Swift.org][1])

5. **128‑bit Integers**
   Swift 6 adds `Int128` and `UInt128`, i.e. signed/unsigned 128‑bit integer types. Useful in domains needing large integer arithmetic, cryptography, etc. ([Swift.org][1])

6. **Synchronization & Low‑Level Concurrency APIs**
   New standard library support: atomic operations, a mutex API, etc. These help when writing performant, safe concurrent code at lower levels. ([Swift.org][1])

7. **Unification of Foundation Across Platforms**
   The Foundation library (things like `URL`, `Calendar`, `JSONDecoder`, etc.) have been reimplemented in Swift and unified so behavior is more consistent across macOS, iOS, Linux, and Windows. ([Swift.org][1])

8. **Swift Testing Library**
   A new testing library designed for Swift. More expressive APIs, macros like `#expect`, better support for parameterized tests, etc. ([Swift.org][1])

9. **Platform Support & Toolchain Improvements**

   * More Linux distributions officially supported (Debian, Fedora, Ubuntu 24.04). ([Swift.org][1])
   * Fully static SDK for Linux: ability to build statically linked executables. ([Swift.org][1])
   * Better build performance on Windows (especially for ARM), e.g., parallel builds. ([Swift.org][1])

10. **Productivity / Syntax Enhancements**
    Some smaller but very useful improvements, such as:

    * `count(where:)` on sequence types. ([Swift.org][1])
    * Pack iteration (for parameter packs). ([Swift.org][1])
    * Access control for imports: you can control visibility when importing modules. ([Swift.org][1])
    * Macros: things like `@attached(body)` macros, expression macros as default arguments. ([Swift.org][1])
    * Debugging improvements: new macro `@DebugDescription` for customizing LLDB summaries. ([Swift.org][1])

---

## Updates in Swift 6.1 & 6.2

Since initial Swift 6 release, there are newer enhancements in **6.1** and **6.2**:

* **Swift 6.1**:
  • Extend `nonisolated` keyword to types and extensions so you can say “this type or extension is safe from any concurrent context,” not just individual methods. ([Swift.org][2])
  • Package traits: allow Swift Packages to specify traits/environments (e.g. Embedded, WebAssembly) that enable/disable features or conditional dependencies. ([InfoQ][3])
  • Trailing commas allowed more places (tuples, generic parameter lists, closure capture lists, etc.). ([InfoQ][3])

* **Swift 6.2**:
  • **InlineArray**: fixed‑size arrays with inline storage; helps avoid heap allocations when you know size at compile time. ([Swift.org][4])
  • **Span** type: safe, direct view over contiguous memory with compile‑time checks; an alternative to unsafe buffer pointers. ([Swift.org][4])
  • Opt‑in strict memory safety: the compiler can flag unsafe constructs unless explicitly acknowledged. ([Swift.org][4])
  • Subprocess APIs for launching/managing external processes more safely/async‑aware. ([Swift.org][4])
  • Modernizing NotificationCenter in Foundation: using concrete notification types rather than untyped strings/dicts. ([Swift.org][4])

---

If you want, I can list all the accepted proposals (SE proposals) for Swift 6 so you see the full scope. Do you prefer that?

[1]: https://www.swift.org/blog/announcing-swift-6/?utm_source=chatgpt.com "Announcing Swift 6 | Swift.org"
[2]: https://www.swift.org/blog/swift-6.1-released/?utm_source=chatgpt.com "Swift 6.1 Released | Swift.org"
[3]: https://www.infoq.com/news/2025/05/swift-6-1-released/?utm_source=chatgpt.com "Swift 6.1 Enhances Concurrency, Introduces Package Traits, and More - InfoQ"
[4]: https://www.swift.org/blog/swift-6.2-released/?utm_source=chatgpt.com "Swift 6.2 Released | Swift.org"

Here are a few of the Swift 6 updates explained with concrete examples, to help show *how* you’d use them and *why* they’re useful.

---

## 1. **Typed Throws**

### What it means

In Swift 5‑and‑before, if a function throws, its signature is just `throws` (i.e. it could throw *any* type conforming to `Error`). With Swift 6, you can specify *which specific error type(s)* the function may throw, using `throws(MyErrorType)`.

This helps make your APIs more precise, better for documentation, and lets the compiler do more checking. ([Swift.org][1])

### Example

```swift
enum DownloadError: Error {
    case invalidURL
    case timeout
}

func fetchData(from urlString: String) throws(DownloadError) -> Data {
    guard urlString.starts(with: "https://") else {
        throw DownloadError.invalidURL
    }
    // Imagine some networking code, but if it times out:
    throw DownloadError.timeout
}

// Using it:
do {
    let data = try fetchData(from: "http://notsecure.com")
    // …
} catch {
    // Here, `error` is inferred to be `DownloadError`, not just `Error`
    switch error {
    case .invalidURL:
        print("Bad URL")
    case .timeout:
        print("Timed out")
    }
}
```

Also, typed throws works with generic functions. For example, Swift’s `map` on `Sequence` can now propagate the particular error type thrown by its closure, instead of defaulting to a general `Error`. ([Swift.org][1])

---

## 2. **Data‑Race Safety Mode / Concurrency Safety**

### What it means

Swift 6 introduces an *opt‑in language mode* in which the compiler treats data races (accessing or mutating shared state without proper synchronization) as *errors*. Usual concurrency safety features like `Sendable`, actors, and isolation of mutable state are enforced more strictly. ([InfoQ][2])

This means fewer bugs slipping through, especially in concurrent / multi‑threaded code. But because older code may not satisfy the rules, the mode is opt‑in so developers can migrate gradually. ([InfoQ][2])

### Example

Consider a simple counter class:

```swift
// Before, in Swift 5+, you might write:

class Counter {
    var value = 0

    func increment() {
        value += 1
    }
}
```

If two threads call `increment()` at the same time, you get a data race: `value` might be read, then written by both, leading to lost updates or undefined behavior.

In Swift 6, in the strict concurrency mode, you’ll get compiler errors unless you make `Counter` safe:

```swift
actor Counter {
    var value = 0

    func increment() {
        value += 1  // safe, because only one actor handles this
    }
}
```

Access to `value` is isolated through the actor, preventing unsafe concurrent mutation. Also, types crossing actor boundaries must conform to `Sendable`, etc. ([Swift.org][1])

---

## 3. **InlineArray (Swift 6.2)**

### What it means

`InlineArray` is a new fixed-size array type with **inline storage**. That means it doesn’t allocate on the heap when the size is known and small; instead storage is inside (on the stack or inside its containing type). Less overhead, more performance. ([Swift.org][3])

Also, there’s some “type sugar” so you can write something like `[40 of Sprite]` to denote an `InlineArray<40, Sprite>` array. (“Of” syntax) ([Swift.org][3])

### Example

```swift
struct Sprite { /* ... */ }

// Using InlineArray explicitly:
var bricks: InlineArray<40, Sprite> = InlineArray(repeating: Sprite())

// With sugar shorthand:
var bricks2: [40 of Sprite] = .init(repeating: Sprite())

// Using it in a struct:
struct GameLevel {
    // 40 sprites, stored inline
    var bricks: [40 of Sprite]
    init(brickSprite: Sprite) {
        bricks = .init(repeating: brickSprite)
    }
}
```

Some constraints:

* The size is fixed: you can’t `append(...)` past the limit or remove arbitrarily.
* If you try to initialize with more elements than allowed, you’ll get a compile‑time error. ([Medium][4])

---

If you like, I can pick a couple more features (e.g. `Span`, 128‑bit integers, or embedding Swift) and show examples for them too. Do you want me to?

[1]: https://www.swift.org/blog/announcing-swift-6/?utm_source=chatgpt.com "Announcing Swift 6 | Swift.org"
[2]: https://www.infoq.com/news/2024/06/swift-6-data-race-safety-mode/?utm_source=chatgpt.com "Swift 6 Brings New Opt-In Data-Race Safe Mode - InfoQ"
[3]: https://www.swift.org/blog/swift-6.2-released/?utm_source=chatgpt.com "Swift 6.2 Released | Swift.org"
[4]: https://medium.com/ios-journeys/inlinearray-in-swift-6-2-why-devs-are-so-excited-about-it-6f35c5f941f6?utm_source=chatgpt.com "InlineArray in Swift 6.2: Why Devs Are So Excited About It | by Koti Avula | Swift Programming | May, 2025 | Medium"
