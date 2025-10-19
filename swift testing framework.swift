//
//  swift testing framework.swift
//  
//
//  Created by Apple on 20/10/25.
//

import Foundation

Here’s a detailed explanation of the new Swift Testing framework (sometimes called *Swift Testing* or *swift‑testing*) — Apple’s next‑generation testing framework for Swift. I’ll cover **what it is**, **why it exists**, **how it works** (key features & APIs), **how it compares to the older XCTest framework**, and **how you can get started**. If you like, I can also show **migration strategies** from XCTest → Swift Testing.

---

## 1. What is Swift Testing?

Swift Testing is a new, open‑source testing package for Swift that provides a modern, more expressive API tailored for Swift’s concurrency and language features. It’s intended to run on multiple platforms (Apple platforms + Linux + Windows) and to coexist with XCTest. ([GitHub][1])

Key points:

* It’s developed under the “swiftlang” GitHub org: swift‑testing. ([GitHub][1])
* It has been accepted as a “new direction for testing in Swift” by the Swift project. ([Swift Forums][2])
* It integrates with Xcode / SPM toolchains. ([Apple Developer][3])
* It uses newer Swift language features (macros, concurrency, etc). ([Swift with Majid][4])

In short: Swift Testing is **not** just a drop‑in replacement of XCTest (though it may eventually become the main path), but a more modern alternative with more ergonomic APIs.

---

## 2. Why was Swift Testing introduced?

There are several reasons:

* **Ergonomics & boilerplate**: XCTest still uses `XCTestCase` subclasses, `func test…()` naming conventions, `XCTAssert…()` macros, etc. Swift Testing aims to reduce ceremony. ([Medium][5])
* **Concurrency and parallelism support**: As Swift embraces concurrency (`async/await`), tests need to run cleanly in async contexts, in parallel, and more efficiently. Swift Testing supports parallel execution by default. ([GitHub][1])
* **Cross‑platform support**: XCTest is Apple‑platform‑centric; Swift Testing targets Apple + Linux + Windows. ([GitHub][1])
* **Modern language features**: Macros, parameterized tests, traits, scopes—all features that leverage newer Swift capabilities (like macros introduced in Swift 5.9+). ([Swift with Majid][4])
* **Better test organisation and management**: Organising tests into suites, tag‑based filtering, traits for skipping/enabling, etc. ([Apple Developer][3])

---

## 3. How it works — Key features & APIs

Here are the major features of Swift Testing, with examples. I’ll also highlight salient details.

### 3.1 Basic test declaration

In Swift Testing you typically import the `Testing` module (or the package) and then mark test functions with a `@Test` macro rather than having to subclass `XCTestCase`.

```swift
import Testing

@Test func verifyAdd() {
    let result = add(1, 2)
    #expect(result == 3)
}
```

([Swift with Majid][4])

Here:

* `@Test` marks the test.
* `#expect` is similar to an assertion: it expects a condition and, if false, reports a failure with good diagnostics. ([GitHub][1])
* `#require` is another macro for an assertion that aborts the test early if the condition fails (useful when you cannot proceed past some pre‑condition). ([Swift with Majid][4])

### 3.2 Test functions support async / throws

Since Swift Testing integrates with concurrency, you can have test functions that are `async throws`, e.g.:

```swift
@Test func verifyFetch() async throws {
    let data = try await fetchData()
    #expect(data.count > 0)
}
```

Also the framework is designed to run tests in parallel by default (when feasible). ([GitHub][1])

### 3.3 Suites and grouping

You can group tests into suites (e.g., `struct` or `enum`) to organise them logically. Example:

```swift
struct MathTests {
    @Test func verifyAdd() { … }
    @Test func verifyMultiply() { … }
}
```

([Swift with Majid][6])

This grouping allows for common setup/teardown as well.

### 3.4 Lifecycle (setup/teardown) and scoping

Swift Testing introduces “scoping” features: you can have initialisation code in `init()` and teardown in `deinit()` inside a test suite type, and the framework handles running them around each test. ([Swift with Majid][7])

Example:

```swift
struct ModelTests {
    let container: ModelContainer

    init() throws {
        // setup
        container = try ModelContainer(config: .inMemory)
    }
    @Test func verifyBulkImport() throws {
        // test logic uses container
    }
}
```

([Swift with Majid][6])

### 3.5 Parameterized tests

One of the big upgrades: you can provide arguments to a `@Test` and run multiple test invocations with different parameters.

Example:

```swift
@Test(arguments: [18,30,50,70], [77.0,73.0,65.0,61.0])
func verifyNormalHeartRate(age: Int, bpm: Double) {
    // test logic…
}
```

([Swift with Majid][8])

This helps reduce duplication and enhances coverage.

### 3.6 Traits and tags

Swift Testing supports “traits” (metadata/conditions) for tests and suites: you can mark tests to be disabled, enabled only when certain condition holds, or give tags (for categorisation). Example:

```swift
@Test(.enabled(if: FeatureFlag.someFeature))
func testFeatureActivated() { … }

@Test(.tags(.crucial, .checkout))
func testCheckoutFlow() { … }
```

([Swift with Majid][9])

Tags help you run subsets of tests (e.g., only “crucial” ones) and skip or enable tests based on environment or platform.

### 3.7 Parallel execution & multi‑platform

Swift Testing is built for tests to run in parallel by default, enabling faster test suites. ([GitHub][1])

Also, it’s cross‑platform (Apple platforms + Linux + Windows) and can be integrated via Swift Package Manager. ([GitHub][1])

### 3.8 Integration with XCTest

You don’t have to throw away your existing XCTest tests. Swift Testing can run side‑by‑side with XCTest, so you can migrate gradually. ([GitHub][1])

---

## 4. How it compares to XCTest

Here’s a comparison of the two frameworks:

| Feature                  | XCTest                                                                | Swift Testing                                                                             |
| ------------------------ | --------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Test declaration         | Subclass `XCTestCase`, methods named `test…`                          | Use `@Test` macro on free functions or within structs                                     |
| Assertions               | `XCTAssert…`, `XCTFail`, etc.                                         | `#expect`, `#require`, richer diagnostics                                                 |
| Async support            | `async` with `XCTestExpectation`, or `async/await` (with limitations) | Native `async throws` support, built‑for concurrency                                      |
| Parallel execution       | Some support via `XCTest` parallel testing, but more limited          | Parallel by default, scalable execution model ([Medium][5])                               |
| Setup/Teardown           | `setUp()`, `tearDown()` methods in `XCTestCase`                       | `init()/deinit()` in suite types + scoping traits ([Swift with Majid][7])                 |
| Parameterised tests      | Custom libraries or patterns needed                                   | Built‑in parameterised tests support ([Swift with Majid][8])                              |
| Cross‑platform           | Apple platforms primarily                                             | Apple + Linux + Windows support ([GitHub][1])                                             |
| Migration                | Many existing tests                                                   | Side‑by‑side support for gradual migration                                                |
| Organisation/tags/traits | Basic (skip test, etc.)                                               | Rich trait system, tags for filtering, conditional enable/disable ([Swift with Majid][9]) |

---

## 5. Getting started with Swift Testing

Here’s how you can start using it:

1. Make sure you’re using a Swift toolchain that supports it (e.g., Swift 6 or newer, Xcode 16+). ([GitHub][1])

2. In your test target, import the `Testing` module (or ensure your SPM package includes the `swift‑testing` package).

3. Write a simple test:

   ```swift
   import Testing

   @Test func testAdd() {
       let sum = add(1, 2)
       #expect(sum == 3)
   }
   ```

4. Use parameterised tests when you have multiple inputs/outputs:

   ```swift
   @Test(arguments: [1,2,3], [2,3,4])
   func testIncrement(input: Int, expected: Int) {
       #expect(increment(input) == expected)
   }
   ```

5. Group tests into suites for better organisation:

   ```swift
   struct StringTests {
       @Test func testEmpty() { … }
       @Test func testNonEmpty() { … }
   }
   ```

6. Use traits/tags:

   ```swift
   @Test(.disabled("Waiting for bug fix")) func testSomething() { … }
   ```

7. Run tests via Xcode Test Navigator or via Swift Package Manager in the terminal. Swift Testing integrates with both. ([Apple Developer][3])

8. Gradually migrate existing XCTest tests if desired; you can have both frameworks co‑existing. ([GitHub][1])

---

## 6. Things to watch out for / Limitations

* Since it’s relatively new, some features (UI testing, performance testing) may not yet have full rich support. For example, one article noted UI tests still rely on XCTest. ([Medium][5])
* Because of parallelism, you must ensure your tests are safe for parallel execution (no shared mutable global state unless guarded).
* Some third‑party tools and CI integrations may still assume XCTest; you may need to check compatibility.
* Since it depends on newer Swift features (macros, etc.), you may need updated toolchains.
* If you have a large legacy codebase in XCTest, migration may require effort and planning.

---

## 7. Why you should consider using it

* Cleaner syntax and less boilerplate → easier to write and maintain tests.
* Better support for modern Swift features (async/await, structured concurrency).
* Parameterised tests save duplication and help coverage.
* Cross‑platform compatibility if you target non‑Apple platforms.
* Future‑proof: since the Swift project has accepted this as the “new direction,” it’s likely to get growing support.

---

## 8. Quick example walk‑through

Putting many features together:

```swift
import Testing

// Tag definitions
extension Tag {
    @Tag static var integration: Self
    @Tag static var fast: Self
}

struct UserServiceTests {
    let userService: UserService

    init() throws {
        // setup
        userService = UserService(storage: InMemoryStorage())
    }

    @Test(.tags(.fast))
    func testCreateUser() async throws {
        let user = try await userService.createUser(name: "Alice")
        #expect(user.name == "Alice")
    }

    @Test(
      "Test invalid names",
      arguments: ["", "A", String(repeating: "x", count: 101)]
    )
    func testCreateUserInvalid(name: String) async throws {
        do {
            _ = try await userService.createUser(name: name)
            #expect(false)  // we expect failure
        } catch {
            #expect(error is UserError.invalidName)
        }
    }

    @Test(.tags(.integration))
    func testUserPersistence() async throws {
        let user = try await userService.createUser(name: "Bob")
        let fetched = try await userService.fetchUser(id: user.id)
        #expect(fetched?.name == "Bob")
    }
}
```

This example shows: usage of `@Test`, async test functions, parameterised arguments, tags to classify tests, setup via `init()`—giving a concise but rich test suite.

---

Here’s a detailed overview of the new Swift Testing framework **as covered by Kodeco** (formerly Ray Wenderlich) — its motivation, core components, how to get started, and how it compares to the older XCTest framework. I’ll pull out key points from the Kodeco article and highlight them. ([Kodeco][1])

---

## ✅ Why Swift Testing (per Kodeco)

‑ Kodeco explains that while XCTest is mature and powerful, it carries legacy patterns (from Objective‑C era) which feel less natural in modern Swift. ([Kodeco][1])
‑ With Swift concurrency, macros, and cross‑platform (Linux/Windows) support, there was a natural opening for a “more Swifty” testing framework. ([Kodeco][2])
‑ Kodeco gives you this summary of differences:

* Use `@Test` rather than naming methods starting with `test`. ([Kodeco][1])
* Tests can be global functions, static methods, or instance methods — you’re not forced into subclassing `XCTestCase`. ([Kodeco][1])
* New assertion macros (e.g., `#expect`, `try #require`) rather than many `XCTAssert…` variants. ([Kodeco][1])
* Built‑in support for parameterized tests. ([Kodeco][1])
* Rich traits/tags to control when or how tests run. ([Kodeco][1])
* Parallel execution by default. ([Kodeco][1])

---

## 🧱 Core Concepts & Building Blocks (per Kodeco)

According to the Kodeco article, there are “four building blocks” you should understand. ([Kodeco][1]) Here’s a breakdown of them:

### 1. `@Test` functions

* A test is declared by applying the `@Test` attribute on a function. Example:

  ```swift
  @Test func myFirstTest() {
     #expect(myValue == expectedValue)
  }
  ```
* Tests can be synchronous or `async throws`.
* The function name doesn’t have to start with `test…`, though you may choose a readable name.
* This removes the `class MyTests: XCTestCase { ... }` boilerplate.

### 2. Assertions / Expectations

* Instead of `XCTAssertEqual`, `XCTAssertTrue`, etc., you use macros like `#expect`, `#require`.
* `#expect(condition)` checks the condition; if it fails, a meaningful diagnostic is printed.
* `try #require(...)` aborts the test early if the required condition fails (so you don’t continue in an invalid state).
* This is more concise and more “Swifty”.

### 3. Parameterized Tests

* You can supply an array of inputs (and optionally expected outputs) to a single test function so it runs for each argument set. Example in Kodeco:

  ```swift
  @Test("Number of objects fetched", arguments: [
      "rhino", "cat", "peony", "ocean"
  ])
  func objectsCount(query: String) async throws {
    try await sut.fetchObjects(for: query)
    #expect(sut.objects.count <= sut.maxIndex)
  }
  ```

  ([Kodeco][1])
* This helps reduce duplication of test code when you’re doing the same logic over many inputs.
* The Kodeco article points out that each invocation runs in parallel (where possible) and independently. ([Kodeco][1])

### 4. Traits, Tags, and Test Organisation

* You can annotate tests (and suites) with traits that control when they run, on which platforms, or with which tags.
  Example:

  ```swift
  @Test(.tags(.metadata))
  func videoMetadata() {
     // ...
  }
  ```

  ([Apple Developer][3])
* You can group tests logically (e.g., via `struct MyTests { … }`) rather than only via classes.
* Suites can be nested, and you can apply tags at higher levels to influence many tests.
* This helps with filtering (run only “fast” tests, skip “integration” tests, etc.).

---

## 🚀 Getting Started (per Kodeco)

How you actually set up and begin using Swift Testing, as described by Kodeco: ([Kodeco][1])

1. Requires newer Swift / Xcode version (the article mentions Xcode 16 beta) because Swift Testing depends on new features like macros.
2. In an existing project, create (or convert) a test target and import `Testing` (or the module provided by Swift Testing).
3. Replace `import XCTest` with `import Testing`, change your test class to e.g. `struct MyTests { … }`, change `func test…` to `@Test func …`.
   Example migration from Kodeco:

   ```swift
   // old XCTest
   class BullsEyeTests: XCTestCase {
     override func setUpWithError() { … }
     override func tearDownWithError() { … }
     func testScoreIsComputedWhenGuessIsHigherThanTarget() {
       let guess = sut.targetValue + 5
       sut.check(guess: guess)
       XCTAssertEqual(sut.scoreRound, 95)
     }
   }
   ```

   becomes:

   ```swift
   struct BullsEyeTests {
     var sut: BullsEyeGame
     init() {
       sut = BullsEyeGame()
     }
     @Test func scoreIsComputedWhenGuessIsHigherThanTarget() {
       let guess = sut.targetValue + 5
       sut.check(guess: guess)
       #expect(sut.scoreRound == 95)
     }
   }
   ```

   ([Kodeco][1])
4. You can gradually migrate: you can keep existing XCTest tests and create new tests using Swift Testing in the same target. Co‑existence is supported. ([Apple Developer][3])
5. Use parameterized tests for scenarios with multiple inputs, use traits/tags for filtering, and keep test suites well organised.

---

## 🔍 How it Compares to XCTest (Summary from Kodeco)

From the Kodeco article: ([Kodeco][1])

* **Test Declaration**: XCTest uses `class` subclassing + `func test…`, Swift Testing uses `@Test` (on struct, class, actor or global func).
* **Assertions**: XCTest has many `XCTAssert…` functions; Swift Testing uses macros like `#expect`, `#require`.
* **Setup/Teardown**: In XCTest you override `setUp()`/`tearDown()`. In Swift Testing you use `init()` for setup (in struct/actor/class) and optionally `deinit()` for teardown.
* **Parallelism & Concurrency**: XCTest has some support, but Swift Testing is built for concurrency (async/throws) and parallel execution by default.
* **Parameterized Tests**: XCTest doesn’t have built‑in simple parameterized test support; Swift Testing does.
* **Tags/Traits**: More sophisticated in Swift Testing.
* **Migration**: You can migrate gradually — existing XCTest and new Swift Testing can live side by side.

---

## 🎯 Key Takeaways

* If you’re starting a new Swift project (especially with Swift Concurrency, cross‑platform ambition, or with desire for more “Swifty” code), using Swift Testing is a solid choice.
* If you have an existing codebase with many XCTest tests, you don’t have to rewrite everything immediately — you can adopt Swift Testing incrementally.
* Use features like parameterized tests to reduce boilerplate and improve coverage.
* Organise tests well: suites, tags, traits help maintainability and make filtering easier (especially in CI).
* Because tests run in parallel by default, ensure your tests are safe for parallel execution (avoid shared mutable state without isolation).
* While Swift Testing is newer, it’s open‑source and cross‑platform, which may give you an edge if you care about non‑Apple targets (Linux/Windows).

---

If you like, I **can share direct code snippets from the Kodeco tutorial** (with explanations) for things like parameterized tests, traits/tags, and full migration steps. Would you like that?

[1]: https://www.kodeco.com/45333595-swift-testing-getting-started?utm_source=chatgpt.com "Swift Testing: Getting Started | Kodeco"
[2]: https://www.kodeco.com/ios/paths/networking-concurrency-swiftui/48743668-performance-optimization/04-introduction-to-unit-testing/02?utm_source=chatgpt.com "Swift Testing | Kodeco"
[3]: https://developer.apple.com/xcode/swift-testing/?utm_source=chatgpt.com "Swift Testing - Xcode - Apple Developer"


Awesome! Here are some **direct code snippets from Kodeco’s Swift Testing tutorial**, with explanations to help you get comfortable with the new framework. I’ll cover:

* Basic test declaration
* Parameterized tests
* Traits/Tags
* Setup & teardown in the new style
* Migration example from XCTest to Swift Testing

---

### 1. Basic Test Declaration with `@Test`

```swift
import Testing

struct MyTests {

    @Test
    func additionWorks() {
        let result = 2 + 2
        #expect(result == 4)
    }
}
```

* `@Test` marks this function as a test (no need to prefix with `test`).
* Use `#expect` macro for assertion. It’s concise and expressive.
* Tests can be synchronous or `async throws`.

---

### 2. Parameterized Tests (Run the same test for multiple inputs)

```swift
import Testing

struct MathTests {

    @Test("Testing multiplication", arguments: [
        (2, 3, 6),
        (4, 5, 20),
        (7, 8, 56)
    ])
    func multiply(a: Int, b: Int, expected: Int) {
        #expect(a * b == expected)
    }
}
```

* `arguments` takes an array of tuples or values.
* The test runs once per argument set, making repetitive tests concise.
* Runs tests in parallel for better speed.

---

### 3. Using Traits and Tags to Categorize Tests

```swift
import Testing

struct NetworkTests {

    @Test(.tags(.network, .slow))
    func testFetchingData() async throws {
        let data = try await fetchDataFromAPI()
        #expect(!data.isEmpty)
    }

    @Test(.tags(.fast))
    func testParsing() {
        let json = "{\"name\": \"ChatGPT\"}"
        #expect(parse(json).name == "ChatGPT")
    }
}
```

* Use `.tags(...)` attribute to label tests (e.g., `.network`, `.slow`, `.fast`).
* You can then run tests selectively via CLI or Xcode using tags.
* Great for CI pipelines to skip slow/integration tests when needed.

---

### 4. Setup & Teardown Using Initializers and `deinit`

```swift
import Testing

struct CalculatorTests {
    var calculator: Calculator

    init() {
        calculator = Calculator()
        // Setup code here
    }

    deinit {
        // Teardown code here, if needed
    }

    @Test
    func testAddition() {
        #expect(calculator.add(2, 3) == 5)
    }
}
```

* No more `setUp()`/`tearDown()` overrides; use `init` and `deinit` in your struct/class/actor.
* Keeps setup code close to your tests.

---

### 5. Migrating XCTest to Swift Testing Example

**Old XCTest:**

```swift
import XCTest

class BullsEyeTests: XCTestCase {
    var sut: BullsEyeGame!

    override func setUpWithError() throws {
        sut = BullsEyeGame()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testScoreIsComputedWhenGuessIsHigherThanTarget() {
        let guess = sut.targetValue + 5
        sut.check(guess: guess)
        XCTAssertEqual(sut.scoreRound, 95)
    }
}
```

**New Swift Testing:**

```swift
import Testing

struct BullsEyeTests {
    var sut: BullsEyeGame

    init() {
        sut = BullsEyeGame()
    }

    @Test
    func scoreIsComputedWhenGuessIsHigherThanTarget() {
        let guess = sut.targetValue + 5
        sut.check(guess: guess)
        #expect(sut.scoreRound == 95)
    }
}
```

* Convert class to `struct`.
* Remove overrides, move setup to `init`.
* Change test method to use `@Test` attribute.
* Replace `XCTAssertEqual` with `#expect` macro.

---

### Bonus: Running Tests via Command Line with Tags (Example)

You can filter tests by tags:

```bash
swift test --filter-tags network,slow
```

This will run only tests tagged `.network` and `.slow`.

---

Would you like me to help you **write some real tests for your own Swift code** using this new framework? Or maybe help with **migrating existing XCTest code** step-by-step?

Great! Let’s write some **realistic Swift tests** using the new Swift Testing framework with `@Test`, `#expect`, parameterized tests, and tags.
                                                            
I’ll pick a simple example: a **`BankAccount`** class with deposit, withdraw, and balance features. Then I’ll write tests covering:
                                                                
* Basic deposit/withdraw operations
* Checking for overdraft errors
* Parameterized tests for multiple deposits/withdrawals
* Using tags to categorize tests
                                                            
---
                                                            
### 1. Simple BankAccount Swift Code
                                                            
```swift
final class BankAccount {
    private(set) var balance: Double = 0
    
    func deposit(amount: Double) {
        guard amount > 0 else { return }
        balance += amount
    }
    
    func withdraw(amount: Double) throws {
        guard amount > 0 else { return }
        if amount > balance {
            throw WithdrawalError.insufficientFunds
        }
        balance -= amount
    }
    
    enum WithdrawalError: Error {
        case insufficientFunds
    }
}
```

---

### 2. Tests Using New Swift Testing Framework

```swift
import Testing

struct BankAccountTests {
    var account: BankAccount
    
    init() {
        account = BankAccount()
    }
    
    @Test
    func initialBalanceIsZero() {
        #expect(account.balance == 0)
    }
    
    @Test
    func depositIncreasesBalance() {
        account.deposit(amount: 100)
        #expect(account.balance == 100)
    }
    
    @Test
    func withdrawDecreasesBalance() async throws {
        account.deposit(amount: 200)
        try account.withdraw(amount: 50)
        #expect(account.balance == 150)
    }
    
    @Test(.tags(.errorHandling))
    func withdrawingMoreThanBalanceThrows() async {
        account.deposit(amount: 100)
        do {
            try account.withdraw(amount: 150)
            #expect(false) // Should never reach here
        } catch BankAccount.WithdrawalError.insufficientFunds {
            #expect(true)
        } catch {
            #expect(false) // Unexpected error
        }
    }
    
    @Test("Multiple deposits and withdrawals", arguments: [
        (50.0, 30.0, 20.0),
        (200.0, 50.0, 150.0),
        (500.0, 500.0, 0.0)
    ])
    func testMultipleOperations(deposit: Double, withdraw: Double, expectedBalance: Double) async throws {
        account = BankAccount() // reset account for each param test
        account.deposit(amount: deposit)
        try account.withdraw(amount: withdraw)
        #expect(account.balance == expectedBalance)
    }
}
```

---

### Explanation

* `@Test` marks test functions.
* Use `#expect` for assertions.
* Tests can be async and throwing (`async throws` or `async`).
* The parameterized test runs the same logic for each tuple of `(deposit, withdraw, expectedBalance)`.
* The `.tags(.errorHandling)` attribute marks that test with an “errorHandling” tag for filtering.
* We reset `account` in the parameterized test’s body to isolate each run.
                        
---
                        
### How to Run (assuming you have setup Swift Testing)
                        
* Run all tests in Xcode or CLI normally.
* To run only error handling tests:
                            
```bash
swift test --filter-tags errorHandling
```
                        
---

Would you like me to help you write tests for a specific Swift class or function you’re working on? Or maybe add more advanced tests with mocks or async network calls?
