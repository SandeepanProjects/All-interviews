//
//  enums.swift
//  
//
//  Created by Apple on 30/08/25.
//

import Foundation

### ❗️**Enums with associated values can’t have raw values.**

Here's **why**:

* **Raw values** are fixed, compile-time values assigned to each enum case.
* **Associated values** are dynamic and can vary each time you create a case — they hold additional data.

Since these are fundamentally different mechanisms, **you can't mix them** in the same enum.

---

### ✅ Example of a Raw Value Enum (✅ works):

```swift
enum Status: Int {
    case success = 200
    case notFound = 404
}
```

* `Status.success.rawValue` → `200`

---

### ✅ Example of an Associated Value Enum (✅ works):

```swift
enum APIResponse {
    case success(data: String)
    case error(code: Int, message: String)
}
```

* This lets you pass different values every time:

```swift
let response = APIResponse.success(data: "User profile loaded")
```

But you **can't do** this:

```swift
enum InvalidEnum: Int { // ❌ Error
    case success(data: String) // ❌ Can't mix raw and associated values
}
```

---

### 🔁 Summary

| Feature                | Raw Values            | Associated Values        |
| ---------------------- | --------------------- | ------------------------ |
| Purpose                | Identifier / constant | Custom per-instance data |
| Value at compile time? | ✅ Yes                 | ❌ No (runtime)           |
| Can mix together?      | ❌ No                  |                          |

---

## ✅ **What are Associated Values in Enums?**

**Associated values** allow each case of an enum to store **custom, dynamic data** **along with** the case.

Think of them as parameters for enum cases. They're **set at runtime** when the case is created.

---

### 🔹 **Example: Associated Values**

```swift
enum Media {
    case book(title: String, author: String)
    case movie(title: String, director: String)
}
```

Now you can create enum values **with unique data**:

```swift
let item1 = Media.book(title: "1984", author: "George Orwell")
let item2 = Media.movie(title: "Inception", director: "Christopher Nolan")
```

Each enum **case** can hold **different types and amounts of data**.

---

### ✅ **What are Raw Values in Enums?**

**Raw values** are **fixed, compile-time values** assigned to each case — like constants.

They’re useful when your enum needs to map to a known value (like `Int` or `String`), e.g., for API responses or database keys.

---

### 🔹 **Example: Raw Values**

```swift
enum Status: Int {
    case success = 200
    case notFound = 404
}
```

```swift
let code = Status.success
print(code.rawValue) // 200
```

You can also initialize an enum from a raw value:

```swift
let status = Status(rawValue: 404) // .notFound
```

---

## 🆚 **Associated Values vs Raw Values**

| Feature            | Associated Values                       | Raw Values                         |
| ------------------ | --------------------------------------- | ---------------------------------- |
| **Purpose**        | Store **custom, dynamic data per case** | Assign **fixed, constant values**  |
| **Assigned When?** | At runtime, when creating a case        | At compile-time                    |
| **Value Type**     | Can be different types per case         | Must be same type for all cases    |
| **Accessed How?**  | Via `switch`/pattern matching           | Via `.rawValue`                    |
| **Can co-exist?**  | ❌ No (mutually exclusive in Swift)      | ✅ Raw-only or Associated-only      |
| **Use case**       | Passing structured data with cases      | Mapping enum to API codes, strings |

---

### 🧠 Real World Use Cases

* **Associated values**:

  * `.error(code: 404, message: "Not Found")`
  * `.payment(amount: Double, currency: String)`

* **Raw values**:

  * `.success = 200`
  * `.red = "#FF0000"`

---

Excellent question — and yes, **memory allocation does differ** between **associated values** and **raw values** in Swift enums.
                                                                                        
Let’s go step by step:
                                                                                            
---
                                                                                            
## ✅ 1. **Memory Allocation in Enums with Raw Values**
                                                                                        
### 🔹 Key point:
                                                                                            
* **Raw values** are **static constants**, assigned at **compile time**.
* The value is not *stored per instance* — it's known and fixed.
                                                                                        
### 📌 Memory impact:
                                                                                            
* The enum case itself is typically stored using **a small, fixed size** — like an `Int` tag or discriminator.
* The raw value is *not stored with each instance*. It's accessed via logic based on the case.
                                                                                        
#### ✅ Example:
                                                                                            
```swift
enum StatusCode: Int {
case success = 200
case error = 500
}
```

```swift
let code = StatusCode.success
// Only the case `.success` is stored (like a small integer), not 200 itself
print(code.rawValue) // This fetches 200 using a lookup
```

---

## ✅ 2. **Memory Allocation in Enums with Associated Values**

### 🔹 Key point:

* Associated values **store actual data** alongside the enum case.
* This data is **allocated in memory per instance**.
* Swift uses **value types**, so the memory layout can be compact, but **larger enums** with complex associated values can take more memory.

### 📌 Memory impact:

* The enum instance stores:

1. A **tag/discriminator** (to identify the active case)
2. The **associated value(s)** in memory

#### ✅ Example:

```swift
enum Response {
    case success(data: String)
    case failure(errorCode: Int)
}
```

```swift
let res = Response.success(data: "All good!")
// Memory is allocated for the string + the enum case tag
```

> Swift will allocate enough space to store **whichever associated value type is largest** among all cases.

---

## 🧠 Summary Table: Raw vs Associated Values Memory

| Aspect                   | Raw Values                          | Associated Values                       |
| ------------------------ | ----------------------------------- | --------------------------------------- |
| **Stored with enum?**    | ❌ No (only tag stored)              | ✅ Yes (data stored per instance)        |
| **When is memory used?** | At compile-time (lookup)            | At runtime (allocated per instance)     |
| **Memory usage**         | Small (just enum tag/discriminator) | Depends on associated data size         |
| **Performance impact**   | Minimal                             | Varies — more for large data/structures |
                                                                                        
---
                                                                                        
## ⚠️ Bonus Tip:
                                                                                            
If you're working with enums that store **large associated data**, be mindful of copying (especially in structs), as it may impact **performance and memory**.
                                                                                        
---
                                                                                        
Would you like to visualize this with a Swift memory layout example?
                                                                                        
Great! Let's **visualize the memory layout** of enums in Swift — both with **raw values** and **associated values** — to help you see how Swift allocates memory under the hood.
                                                                                        
                                                                                        ---
                                                                                        
## 🧪 Example 1: Enum with Raw Values
                                                                                        
```swift
enum StatusCode: Int {
case success = 200
case error = 500
}
```

### 🧠 Memory Layout:

* Internally, Swift only stores a small value (like an `Int`) to represent the **case**.
* The raw value (`200`, `500`) is **not stored** per instance.
* Swift uses a **lookup** to get `.rawValue`.

> Think of it like this:

| Variable          | Stored in Memory |
| ----------------- | ---------------- |
| `code = .success` | tag: `0`         |

When you call `code.rawValue`, Swift translates tag `0` to `200`.

---

## 🧪 Example 2: Enum with Associated Values

```swift
enum Response {
    case success(data: String)
    case failure(errorCode: Int)
}
```

```swift
let response = Response.success(data: "Fetched data")
```

### 🧠 Memory Layout:

Now Swift needs to store:

1. A **tag** to know which case is active.
2. The **actual associated value**, e.g., the `String`.

> Internally, it's more like:

| Variable   | Stored in Memory                 |
| ---------- | -------------------------------- |
| `response` | tag: `0`, data: `"Fetched data"` |

* If you later do `response = .failure(errorCode: 404)`, Swift will store:

* tag: `1`, data: `404`

---

## 🧰 Using Swift’s `MemoryLayout` to See Sizes

You can actually measure memory usage using Swift:

```swift
enum RawValueEnum: Int {
    case a = 1
    case b = 2
}

enum AssociatedValueEnum {
    case a(String)
    case b(Int)
}

print("Raw value enum size: \(MemoryLayout<RawValueEnum>.size)")       // Typically 1 to 8 bytes
print("Associated value enum size: \(MemoryLayout<AssociatedValueEnum>.size)") // Depends on contents
```

🧪 On most systems:

* RawValueEnum: **4 or 8 bytes**
* AssociatedValueEnum: **Size of largest associated value + 1 byte (tag)**

---

## 🧠 Visualization Summary

| Type                  | What's Stored?              | Memory Usage      | Access Time                           |
| --------------------- | --------------------------- | ----------------- | ------------------------------------- |
| Raw Value Enum        | Enum case tag only          | Low               | Fast                                  |
| Associated Value Enum | Tag + associated value data | Higher (variable) | Still fast, but more copying possible |

---

## ✅ 1. **How Do You Extract Associated Values Using Pattern Matching?**

To **extract associated values** from an enum, you typically use a `switch` statement with **pattern matching**.

### 🔹 Example Enum with Associated Values:

```swift
enum Result {
    case success(data: String)
    case failure(errorCode: Int, message: String)
}
```

### 🔍 Pattern Matching with `switch`:

```swift
let response = Result.failure(errorCode: 404, message: "Not Found")

switch response {
case .success(let data):
    print("Success with data: \(data)")

case .failure(let code, let message):
    print("Error \(code): \(message)")
}
```

You can also use **shorthand** syntax:

```swift
case .success(let data): // Extracts only the needed value
case .failure(let code, _): // Ignores message using `_`
```

---

### 🪄 Pattern Matching with `if case`:

For simpler checks:

```swift
if case let .success(data) = response {
    print("Got success: \(data)")
}
```

Or with `guard`:

```swift
guard case let .failure(code, message) = response else { return }
print("Failed with code \(code), message: \(message)")
```

---

## ✅ 2. **What Is the Use of `@unknown default`?**

The `@unknown default` case is used in `switch` statements **on enums defined outside your code**, especially when the enum is:

* **From Apple's frameworks** (like `UIUserInterfaceStyle`)
* **Marked with `@frozen`** (meaning new cases can be added in the future)

### 🛡 Purpose:

It **protects your code against future cases** being added in SDKs you don't control.

---

### 🔹 Example Without `@unknown default`: ❌ Risky

```swift
enum Theme: String {
    case light, dark
}

switch currentTheme {
case .light: print("Light")
case .dark: print("Dark")
// ❌ If Apple adds `.system` in future, your code will crash
}
```

---

### ✅ Using `@unknown default`

```swift
switch currentTheme {
case .light: print("Light")
case .dark: print("Dark")
@unknown default:
    print("Unknown theme - handle gracefully")
}
```

* Ensures your app **doesn’t crash** if new cases are added.
* **Compiler will warn** if you're missing `@unknown default` when switching over a non-exhaustive enum.

---

### 🧠 Summary

| Concept            | What it Does                         | When to Use                           |
| ------------------ | ------------------------------------ | ------------------------------------- |
| Pattern Matching   | Extract associated values from enums | When working with enums with data     |
| `@unknown default` | Handle future enum cases gracefully  | When switching on SDK/framework enums |

---

Excellent question — enums in Swift are very powerful, but they do have **some limitations**.
                                            
Let’s break this down:
                                                
                                                ---
                                                
## ✅ **Can enums have methods?**
                                            
Yes, absolutely!
                                            
You can define **instance methods** and **static methods** inside enums.
                                            
### 🔹 Example:
                                                
```swift
enum Direction {
case north, south, east, west
    
    func isVertical() -> Bool {
        return self == .north || self == .south
    }
}
```

```swift
let dir = Direction.north
print(dir.isVertical()) // true
```

---

## ✅ **Can enums have computed properties?**

Yes!

You can define **computed properties**, which calculate a value based on the enum case.

### 🔹 Example:

```swift
enum Planet {
    case earth, mars
    
    var description: String {
        switch self {
        case .earth: return "Our home planet"
        case .mars: return "The red planet"
        }
    }
}
```

```swift
let p = Planet.mars
print(p.description) // "The red planet"
```

---

## ❌ **Can enums have stored properties?**

**No, enums cannot have stored properties.**

### ❗ Why not?

* Enums represent **distinct cases**, each potentially with different associated values.
* Allowing stored properties would **violate the fixed layout** Swift requires for enums.
                                                                                    
### 🧪 What happens if you try?
                                                                                    
```swift
enum BadExample {
    var value: Int = 0 // ❌ Error: Enums cannot contain stored properties
}
```

You’ll get a compile-time error:

> *"Enums must not contain stored properties."*

---

## ✅ Workaround: Use Associated Values

Instead of stored properties, use **associated values** to store data **per case**:

```swift
enum Result {
    case success(data: String)
    case failure(errorCode: Int)
}
```

This allows each case to **carry custom data**, similar to stored properties — but only when that case is active.

---

## ✅ Summary Table

| Feature                 | Enum Support | Notes                                     |
| ----------------------- | ------------ | ----------------------------------------- |
| **Methods**             | ✅ Yes        | Instance and static methods are supported |
| **Computed Properties** | ✅ Yes        | Great for logic based on case             |
| **Stored Properties**   | ❌ No         | Use associated values instead             |
                                                        

Great topic! Enums with `Codable`/`Decodable` are common in iOS, especially when parsing JSON APIs. Swift makes it pretty straightforward when enums have **raw values**, but it gets trickier with **associated values**.
                                                        
---
                                                        
**Enum with Raw Values conforming to Codable**
                                                        
If your enum has **raw values** (like `String` or `Int`), Swift can auto-synthesize `Codable` conformance.
                                                        
### Example:
                                                            
```swift
enum Status: String, Codable {
case success = "success"
case failure = "failure"
}
```

### Usage:

```swift
let jsonData = """
"success"
""".data(using: .utf8)!

let status = try JSONDecoder().decode(Status.self, from: jsonData)
print(status) // success

let encodedData = try JSONEncoder().encode(status)
print(String(data: encodedData, encoding: .utf8)!) // "success"
```

Swift handles encoding/decoding automatically here.

---

## 2. **Enum with Associated Values and Codable**

Swift **cannot automatically synthesize Codable** for enums with associated values. You need to implement `init(from:)` and `encode(to:)` manually.
                                                        
                                                        ### Example:
                                                            
                                                            ```swift
                                                        enum MediaType: Codable {
case book(title: String, author: String)
case movie(title: String, director: String)
    
    private enum CodingKeys: String, CodingKey {
        case type
        case title
        case author
        case director
    }
    
    enum MediaTypeTag: String, Codable {
        case book
        case movie
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .book(let title, let author):
            try container.encode(MediaTypeTag.book, forKey: .type)
            try container.encode(title, forKey: .title)
            try container.encode(author, forKey: .author)
        case .movie(let title, let director):
            try container.encode(MediaTypeTag.movie, forKey: .type)
            try container.encode(title, forKey: .title)
            try container.encode(director, forKey: .director)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MediaTypeTag.self, forKey: .type)
        
        switch type {
        case .book:
            let title = try container.decode(String.self, forKey: .title)
            let author = try container.decode(String.self, forKey: .author)
            self = .book(title: title, author: author)
        case .movie:
            let title = try container.decode(String.self, forKey: .title)
            let director = try container.decode(String.self, forKey: .director)
            self = .movie(title: title, director: director)
        }
    }
}
```

### Explanation:

* Use a **discriminator key** (here, `.type`) to identify the case.
* Encode/decode each associated value accordingly.

---

## 3. **How JSON looks for above enum**
                            
                            ```json
{
    "type": "book",
    "title": "1984",
    "author": "George Orwell"
}
```

---

## Summary:

| Enum Type              | Codable Conformance            | Notes                 |
| ---------------------- | ------------------------------ | --------------------- |
| Raw Value Enums        | Auto-synthesized               | Easy to use           |
| Associated Value Enums | Manual implementation required | Use discriminator key |

---

Great question! Recursive enums are a powerful feature in Swift that let you model **self-referential** data structures — like trees or linked lists.

---

## ✅ What is a Recursive Enum?

A **recursive enum** is an enum that has **cases which refer to the enum itself**. Because Swift needs to know the size of types at compile time, you must mark the recursive case with the `indirect` keyword to tell Swift to handle this indirection.

---

## Syntax

There are two ways to declare recursion:

### 1. Mark the **entire enum** as indirect (all cases are indirect):

```swift
indirect enum ArithmeticExpression {
    case number(Int)
    case addition(ArithmeticExpression, ArithmeticExpression)
    case multiplication(ArithmeticExpression, ArithmeticExpression)
}
```

### 2. Mark only specific cases as indirect:

```swift
enum ArithmeticExpression {
    case number(Int)
    indirect case addition(ArithmeticExpression, ArithmeticExpression)
    indirect case multiplication(ArithmeticExpression, ArithmeticExpression)
}
```

---

## ✅ When to Use Recursive Enums?

Recursive enums are useful when modeling:

* **Tree-like structures**, e.g.:

  * Expression trees (arithmetic expressions)
  * File system directories (folders containing files/folders)
* **Linked lists** or other recursive data structures
* Any data structure where a case contains instances of the enum itself

---

## Example: Arithmetic Expression Tree

```swift
indirect enum ArithmeticExpression {
    case number(Int)
    case addition(ArithmeticExpression, ArithmeticExpression)
    case multiplication(ArithmeticExpression, ArithmeticExpression)
}

let five = ArithmeticExpression.number(5)
let four = ArithmeticExpression.number(4)
let sum = ArithmeticExpression.addition(five, four)
let product = ArithmeticExpression.multiplication(sum, ArithmeticExpression.number(2))
```

---

### Evaluating the expression with recursion:

```swift
func evaluate(_ expression: ArithmeticExpression) -> Int {
    switch expression {
    case .number(let value):
        return value
    case .addition(let left, let right):
        return evaluate(left) + evaluate(right)
    case .multiplication(let left, let right):
        return evaluate(left) * evaluate(right)
    }
}

print(evaluate(product)) // Output: 18
```

---

## Summary

| Aspect             | Explanation                             |
| ------------------ | --------------------------------------- |
| Recursive enum     | Enum case refers to the enum itself     |
| `indirect` keyword | Needed to enable recursion              |
| Use case           | Trees, linked lists, expression parsing |

---

Awesome! Let's build another **recursive enum example**, this time with something more real-world than math:

---

## ✅ **Example: File System Tree**

Let's model a **file system** using a recursive enum. Each **folder** can contain **files** or **more folders** — which is naturally a tree-like structure.

---

### 🔧 Recursive Enum: `FileNode`

```swift
enum FileNode {
    case file(name: String, size: Int)
    indirect case folder(name: String, contents: [FileNode])
}
```

We use `indirect` on the `folder` case because a folder can contain more `FileNode`s, including other folders.

---

### 📦 Sample File Tree

```swift
let myDocuments = FileNode.folder(name: "Documents", contents: [
    .file(name: "Resume.pdf", size: 120),
    .file(name: "CoverLetter.docx", size: 80),
    .folder(name: "Photos", contents: [
        .file(name: "Vacation.jpg", size: 500),
        .file(name: "Birthday.png", size: 300)
    ])
])
```

---

### 🔍 Recursively Traverse and Calculate Total File Size

```swift
func totalSize(of node: FileNode) -> Int {
    switch node {
    case .file(_, let size):
        return size
    case .folder(_, let contents):
        return contents.map(totalSize).reduce(0, +)
    }
}
```

```swift
print("Total size: \(totalSize(of: myDocuments)) KB") // Total size: 1000 KB
```

---

## ✅ Summary

| Feature             | Value                                                  |
| ------------------- | ------------------------------------------------------ |
| Recursive Enum Used | ✅ Yes (`indirect` for folders)                         |
| Real-world Use Case | File system modeling                                   |
| Benefits            | Elegant tree structure, clean traversal with recursion |

---

Would you like to expand this to support printing the file tree with indentation, or add Codable support?

Perfect! Let's **expand the recursive enum example** of the file system to:

### ✅ 1. **Print the file tree with indentation**

### ✅ 2. **Add `Codable` support** so it can be encoded/decoded from JSON

---

## ✅ Step 1: Print File Tree with Indentation

We'll write a recursive `printTree(indentLevel:)` function to pretty-print the hierarchy.

### 🧱 FileNode Enum:

```swift
enum FileNode {
    case file(name: String, size: Int)
    indirect case folder(name: String, contents: [FileNode])
}
```

---

### 🔧 Printing Function

```swift
extension FileNode {
    func printTree(indentLevel: Int = 0) {
        let indent = String(repeating: "    ", count: indentLevel)
        
        switch self {
        case .file(let name, let size):
            print("\(indent)📄 \(name) (\(size) KB)")
        case .folder(let name, let contents):
            print("\(indent)📁 \(name)/")
            for item in contents {
                item.printTree(indentLevel: indentLevel + 1)
            }
        }
    }
}
```

---

### 📦 Sample Tree

```swift
let myDocuments = FileNode.folder(name: "Documents", contents: [
    .file(name: "Resume.pdf", size: 120),
    .file(name: "CoverLetter.docx", size: 80),
    .folder(name: "Photos", contents: [
        .file(name: "Vacation.jpg", size: 500),
        .file(name: "Birthday.png", size: 300)
    ])
])

myDocuments.printTree()
```

### 📤 Output:

```
📁 Documents/
    📄 Resume.pdf (120 KB)
    📄 CoverLetter.docx (80 KB)
    📁 Photos/
        📄 Vacation.jpg (500 KB)
        📄 Birthday.png (300 KB)
```

---

## ✅ Step 2: Add Codable Support

Enums with associated values need **manual conformance** to `Codable`.

### 🧬 Add Codable:

```swift
extension FileNode: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case name
        case size
        case contents
    }
    
    enum FileType: String, Codable {
        case file
        case folder
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .file(let name, let size):
            try container.encode(FileType.file, forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(size, forKey: .size)

        case .folder(let name, let contents):
            try container.encode(FileType.folder, forKey: .type)
            try container.encode(name, forKey: .name)
            try container.encode(contents, forKey: .contents)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(FileType.self, forKey: .type)

        switch type {
        case .file:
            let name = try container.decode(String.self, forKey: .name)
            let size = try container.decode(Int.self, forKey: .size)
            self = .file(name: name, size: size)

        case .folder:
            let name = try container.decode(String.self, forKey: .name)
            let contents = try container.decode([FileNode].self, forKey: .contents)
            self = .folder(name: name, contents: contents)
        }
    }
}
```

---

### 🔄 Encode to JSON

```swift
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

if let jsonData = try? encoder.encode(myDocuments),
   let jsonString = String(data: jsonData, encoding: .utf8) {
    print(jsonString)
}
```

### 🔁 Decode from JSON

```swift
let decoder = JSONDecoder()
if let decoded = try? decoder.decode(FileNode.self, from: jsonData) {
    decoded.printTree()
}
```

---

## ✅ Done! You now have:

* A **recursive enum**
* A **function to print it like a file explorer**
* Full **Codable** support to serialize/deserialize to/from JSON

---
