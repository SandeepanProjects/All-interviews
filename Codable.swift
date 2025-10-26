//
//  Codable.swift
//  
//
//  Created by Apple on 26/10/25.
//

import Foundation

Sure! Let’s break this down carefully. You asked about **Codable in iOS** and **interview questions related to it**, so I’ll cover both in detail.

---

## **1. What is Codable in iOS?**

In iOS, **`Codable`** is a protocol introduced in Swift 4. It allows a type (usually a struct or class) to be encoded to or decoded from external representations like **JSON**, **Property List (plist)**, etc.

* `Codable` is actually a type alias for two protocols:

  ```swift
  typealias Codable = Decodable & Encodable
  ```

  * **Encodable** → Convert Swift object to external format (e.g., JSON)
  * **Decodable** → Convert external format (e.g., JSON) into Swift object

---

### **Example: Codable with JSON**

```swift
struct User: Codable {
    var id: Int
    var name: String
    var email: String
}

// JSON Data
let jsonData = """
{
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com"
}
""".data(using: .utf8)!

do {
    let user = try JSONDecoder().decode(User.self, from: jsonData)
    print(user.name)  // John Doe
    
    let encodedData = try JSONEncoder().encode(user)
    let jsonString = String(data: encodedData, encoding: .utf8)
    print(jsonString!)  // {"id":1,"name":"John Doe","email":"john@example.com"}
} catch {
    print(error)
}
```

✅ Key Points:

1. Swift automatically generates encoding/decoding for properties if their types are also `Codable`.
2. `CodingKeys` enum can be used if JSON keys differ from your property names.

---

### **Custom CodingKeys Example**

```swift
struct User: Codable {
    var id: Int
    var fullName: String
    var emailAddress: String

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "name"
        case emailAddress = "email"
    }
}
```

Here, you map the JSON key `"name"` to `fullName` property.

---

### **2. Common Interview Questions on Codable**

Here are some frequently asked interview questions about `Codable`:

#### **Basic**

1. What is Codable in Swift?
2. Difference between `Encodable` and `Decodable`.
3. How to convert JSON to a Swift object and vice versa?

#### **Intermediate**

4. What is `CodingKeys` and why is it used?
5. How do you handle nested JSON using Codable?
6. How do you handle optional or missing keys while decoding?
7. Difference between `JSONSerialization` and `Codable`? Why prefer Codable?

#### **Advanced**

8. How do you encode/decode custom types, like `Date` or `URL`?
9. What are `keyDecodingStrategy` and `keyEncodingStrategy` in `JSONDecoder`/`JSONEncoder`?
10. How do you handle polymorphic data (like multiple types) with Codable?
11. Performance considerations of Codable vs manual parsing.
12. How to handle arrays of objects or dictionaries using Codable?

---

### **Pro Tips for Interviews**

* Always know how to handle **date formatting**:

  ```swift
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .iso8601
  ```
* Know how to handle **nested JSON objects**.
* Be able to write **custom encode/decode** if the automatic synthesis doesn’t work.

---

If you want, I can make a **crash course “Codable interview Q&A cheat sheet”** with **code examples** that covers almost everything interviewers ask.

Do you want me to do that?

Absolutely! Let’s go **step by step** and answer all your questions in detail, with explanations and code examples where necessary. I’ll organize them by **Basic**, **Intermediate**, and **Advanced**.
                                                        
---
                                                        
## **BASIC**
                                                        
### **1. What is Codable in Swift?**
                                                        
**Answer:**
`Codable` is a protocol in Swift that allows a type to be encoded to or decoded from an external representation like JSON or Property List (plist).
                                                        
* It is a typealias for:
                                                            
```swift
typealias Codable = Encodable & Decodable
```
                                                        
* **Encodable:** Convert Swift object to external format.
* **Decodable:** Convert external format into Swift object.
                                                        
**Example:**
                                                            
```swift
struct User: Codable {
    var id: Int
    var name: String
}

let jsonData = """
{"id":1,"name":"John"}
""".data(using: .utf8)!

let user = try JSONDecoder().decode(User.self, from: jsonData)
```

---

### **2. Difference between Encodable and Decodable**

| Aspect        | Encodable                       | Decodable                       |
| ------------- | ------------------------------- | ------------------------------- |
| Purpose       | Convert Swift object → external | Convert external → Swift object |
| Protocol      | Encodable                       | Decodable                       |
| Example Usage | JSONEncoder().encode(object)    | JSONDecoder().decode(Type.self) |

---

### **3. How to convert JSON to a Swift object and vice versa?**

**Decoding JSON → Swift object**

```swift
let jsonData = """
{"id":1,"name":"John"}
""".data(using: .utf8)!

let user = try JSONDecoder().decode(User.self, from: jsonData)
```

**Encoding Swift object → JSON**

```swift
let user = User(id: 1, name: "John")
let jsonData = try JSONEncoder().encode(user)
let jsonString = String(data: jsonData, encoding: .utf8)
```

✅ Tip: Swift automatically synthesizes Codable conformance if all properties are Codable.
                                                                
---
                                                                
## **INTERMEDIATE**
                                                                
### **4. What is CodingKeys and why is it used?**
                                                                
**Answer:**
`CodingKeys` is an enum used to map property names to different keys in the JSON or external data. Useful when the JSON keys don’t match your Swift property names.
                                                                
**Example:**
                                                                    
```swift
struct User: Codable {
    var id: Int
    var fullName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "name"
    }
}
```

Here, `fullName` maps to the `"name"` key in JSON.

---

### **5. How do you handle nested JSON using Codable?**

**Nested JSON Example:**

```json
{
    "id": 1,
    "name": "John",
    "address": {
        "city": "New York",
        "zip": "10001"
    }
}
```

**Swift Codable:**

```swift
struct Address: Codable {
    var city: String
    var zip: String
}

struct User: Codable {
    var id: Int
    var name: String
    var address: Address
}
```

Decoding works automatically because `Address` is Codable too.

---

### **6. How do you handle optional or missing keys while decoding?**
                                                            
* Use optional properties (`?`) in your struct.
                                                            
```swift
struct User: Codable {
    var id: Int
    var name: String?
}
```

* If the JSON key is missing, `name` will be `nil` instead of causing a crash.

---

### **7. Difference between JSONSerialization and Codable? Why prefer Codable?**

| Feature     | JSONSerialization                     | Codable                                  |
| ----------- | ------------------------------------- | ---------------------------------------- |
| Type Safety | None (returns `[String: Any]`)        | Full Swift type safety                   |
| Boilerplate | High                                  | Low (automatic synthesis)                |
| Performance | Manual parsing                        | Optimized built-in                       |
| Example     | `JSONSerialization.jsonObject(with:)` | `JSONDecoder().decode(User.self, from:)` |

**✅ Prefer Codable** because it’s type-safe, concise, and less error-prone.

---

## **ADVANCED**

### **8. How do you encode/decode custom types, like Date or URL?**

**Example: Date**

```swift
struct Event: Codable {
    var name: String
    var date: Date
}

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
```

**Example: URL**

```swift
struct Website: Codable {
    var url: URL
}
```

`URL` is Codable by default.

---

### **9. What are keyDecodingStrategy and keyEncodingStrategy in JSONDecoder/JSONEncoder?**

* Used to automatically map JSON keys to Swift property names.

**Example: snake_case → camelCase**

```swift
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
```

* `"first_name"` in JSON → `firstName` in Swift.

---

### **10. How do you handle polymorphic data (multiple types) with Codable?**

* Use enums with associated values or custom `init(from decoder:)`.

```swift
enum Animal: Codable {
    case dog(String)
    case cat(String)
    
    enum CodingKeys: String, CodingKey { case type, name }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let name = try container.decode(String.self, forKey: .name)
        if type == "dog" { self = .dog(name) }
        else { self = .cat(name) }
    }
}
```

---

### **11. Performance considerations of Codable vs manual parsing**

* **Codable:** Faster, type-safe, less boilerplate, optimized by Apple.
* **Manual parsing (JSONSerialization):** Slightly more control but slower, error-prone.
✅ Codable is recommended unless extreme performance optimization is needed.

---

### **12. How to handle arrays of objects or dictionaries using Codable?**

**Array of objects:**

```json
[
    {"id":1,"name":"John"},
    {"id":2,"name":"Jane"}
]
```

```swift
let users = try JSONDecoder().decode([User].self, from: jsonData)
```

**Dictionary:**

```json
{
    "1": {"name":"John"},
    "2": {"name":"Jane"}
}
```

```swift
let dict = try JSONDecoder().decode([String: User].self, from: jsonData)
```

---

If you want, I can also **create a single-page “Codable Interview Cheat Sheet”** with **all answers + concise code snippets** for quick revision.
                                                                                                                                    
