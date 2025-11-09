//
//  access specifiers.swift
//  
//
//  Created by Apple on 09/11/25.
//

import Foundation

In Swift, **access specifiers** (also called *access control levels*) determine **how visible or accessible a class, struct, enum, property, or method is** from other parts of your code or modules. They are essential for **encapsulation** and **hiding implementation details**. Swift provides **five access levels**.

---

## **1️⃣ Open**

* The **highest level of access**.
* Can be accessed **and subclassed/overridden** from **any module** (your module or others).
* Only applies to **classes and class members**.

```swift
open class OpenClass {
    open func openMethod() {
        print("Open method")
    }
}
```

✅ **Use case:** Frameworks where you want external developers to subclass your classes.

---

## **2️⃣ Public**

* Can be accessed from **any module**, but **cannot be subclassed or overridden outside the module**.
* Works for **classes, structs, enums, properties, methods**.

```swift
public struct PublicStruct {
    public var value: Int
    public func doSomething() {}
}
```

✅ **Use case:** Library code you want others to use but not extend.

---

## **3️⃣ Internal** (default)

* Can be accessed **anywhere within the same module**, but **not from outside the module**.
* If you don’t specify an access level, Swift assumes `internal`.

```swift
struct InternalStruct {
    var value: Int      // internal by default
    func doSomething() {}
}
```

✅ **Use case:** Typical app code where everything is part of the same project/module.

---

## **4️⃣ Fileprivate**

* Accessible **only within the same Swift file**.
* Useful for grouping related code but **hiding details from other files**.

```swift
fileprivate class FilePrivateClass {
    fileprivate func helper() {}
}
```

✅ **Use case:** Private helper classes or functions inside the same file.

---

## **5️⃣ Private**

* The **most restrictive level**.
* Accessible **only within the enclosing declaration** (class, struct, or extension) **and its extensions in the same file**.

```swift
class MyClass {
    private var secret = 42
    
    private func secretFunction() {
        print("This is secret")
    }
}
```

✅ **Use case:** Internal state or logic you don’t want exposed anywhere else.

---

## **💡 Summary Table**

| Access Level  | Same File               | Same Module | Other Modules | Can Subclass/Override |
| ------------- | ----------------------- | ----------- | ------------- | --------------------- |
| `open`        | ✅                       | ✅           | ✅             | ✅                     |
| `public`      | ✅                       | ✅           | ✅             | ❌                     |
| `internal`    | ✅                       | ✅           | ❌             | ❌                     |
| `fileprivate` | ✅                       | ❌           | ❌             | ❌                     |
| `private`     | ✅ (enclosing type only) | ❌           | ❌             | ❌                     |

---

### **Quick Tips**

* Use **private/fileprivate** for encapsulation.
* Use **internal** for most app-level code.
* Use **public/open** when writing a framework or library that others will use.
* Prefer the **most restrictive access** you can — it’s safer and makes your code easier to maintain.

---

If you want, I can also explain **the difference between `private` and `fileprivate` with a practical Swift example**, which often confuses candidates in interviews.

Do you want me to do that?

Perfect! Let’s clarify the **difference between `private` and `fileprivate`** with a practical Swift example. This is a common **iOS interview question**, and understanding it shows you know Swift’s **access control nuances**.
                                    
---
                                    
## **Key Difference**
                                    
* `private` → accessible **only inside the enclosing declaration** (class, struct, or extension) and its extensions in the **same file**.
* `fileprivate` → accessible **anywhere in the same Swift file**, including outside the enclosing declaration.
                                    
---
                                    
## **Example**
                                    
```swift
// File: MyFile.swift
                                    
class MyClass {
    private var privateValue = 10
    fileprivate var fileprivateValue = 20
    
    func testAccess() {
        print(privateValue)       // ✅ Accessible
        print(fileprivateValue)   // ✅ Accessible
    }
}

class AnotherClass {
    func test() {
        // print(MyClass().privateValue)     // ❌ Error: 'privateValue' is private
        print(MyClass().fileprivateValue)   // ✅ Accessible because it's same file
    }
}

extension MyClass {
    func extensionTest() {
        print(privateValue)     // ✅ Accessible: extensions in the same file can access private
        print(fileprivateValue) // ✅ Accessible
    }
}
```

---

### **Explanation**

1. `privateValue`

* Only `MyClass` and its extensions in the same file can access it.
* `AnotherClass` **cannot access** it, even though it’s in the same file.

2. `fileprivateValue`

* Any code in the same **file** can access it, including `AnotherClass`.

---

### **When to Use**

| Access Level  | Use Case                                                                                                                                         |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `private`     | Hide implementation details **inside a class or struct**. Safer for encapsulation.                                                               |
|`fileprivate` | Hide details **from other files** but allow sharing within the same file (useful for helpers, unit tests, or closely related types in one file). |
                                                                                        
---
                                                                                        
### **Interview Tip**
                                                                                        
* If asked: “Why not just use `private` all the time?” → Explain that sometimes you want multiple classes or extensions in the same file to share implementation details, but still prevent access outside the file. That’s `fileprivate`.
                                                                                        
---
                                                                                        
Let’s break down the **difference between `open` and `public` in Swift**. This is another common interview topic, and it often confuses people because both allow access **outside the module**, but the key difference is about **subclassing and overriding**.
                                                                                        
---
                                                                                        
## **1️⃣ Public**
                                                                                        
* Can be accessed **from any module**.
* **Cannot be subclassed or overridden outside the module**.
* Works for **classes, structs, enums, functions, properties**.
                                                                                        
```swift
// ModuleA
public class PublicClass {
    public func greet() {
        print("Hello from PublicClass")
    }
}

// ModuleB
// let obj = PublicClass()      // ✅ Can create instance
// class SubClass: PublicClass {} // ❌ Error: Cannot subclass
```

**Use case:** You want external modules to **use** your class or function, but not extend it.

---

## **2️⃣ Open**

* Can be accessed **from any module**.
* **Can be subclassed and overridden even outside the module**.
* Only applies to **classes and class members**.

```swift
// ModuleA
open class OpenClass {
    open func greet() {
        print("Hello from OpenClass")
    }
}

// ModuleB
class SubClass: OpenClass {
    override func greet() {
        print("Hello from SubClass")
    }
}
```

**Use case:** You’re writing a **framework or SDK** and want other developers to **subclass your classes or override methods**.

---

## **Key Differences Table**

| Feature            | Public                                         | Open                           |
| ------------------ | ---------------------------------------------- | ------------------------------ |
| Access from module | ✅ Any module                                   | ✅ Any module                   |
| Can subclass       | ❌ Outside the module                           | ✅ Outside the module           |
| Can override       | ❌ Outside the module                           | ✅ Outside the module           |
| Applicable to      | Classes, structs, enums, functions, properties | Only classes and class members |

---

### **Interview Tip**

* If asked: *“When would you use `open` instead of `public`?”* →
✅ Answer: Only when writing **frameworks or SDKs** that other developers need to **subclass or override** your classes. Otherwise, stick to `public` for safety.

---
