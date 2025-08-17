//
//  why swift uses struct.swift
//  
//
//  Created by Apple on 26/07/25.
//

import Foundation

Swift uses **structs** as **value types** for several important reasons, all of which revolve around **performance, safety, and simplicity**. Let's break down the primary motivations for choosing **value types (structs)** over **reference types (classes)** in Swift.

---

## 1. **Performance: Structs Are More Efficient**

### Value Types vs Reference Types in Memory

* **Value types (structs)** are typically allocated **on the stack** (for small objects), which makes them **faster** to allocate and deallocate. When you pass a value type around, the system **copies** the data, but it doesn’t require complex memory management (like reference counting) that comes with reference types.

* **Reference types (classes)**, on the other hand, are allocated **on the heap**. When you pass a reference type around, the system only passes a **pointer** to the object, and every time the object is referenced or mutated, the system has to keep track of that reference. This adds a layer of **overhead** due to **automatic reference counting (ARC)**, which can affect performance.

### **Why it Matters**:

* **Swift prioritizes performance** and struct-based design allows for more **predictable memory usage** and **lower overhead**.
* Operations on structs are often **faster** because copying data is quicker than managing references, especially for **smaller objects**.

---

## 2. **Safety: Avoiding Shared Mutable State**

### **Mutability in Reference Types**:

With reference types (classes), when you pass an object to a function or assign it to another variable, you’re passing a **reference** to that object. This means if one part of your code modifies that object, it can unexpectedly affect other parts of the code that are also holding references to the same object.

This introduces the possibility of **unintended side effects** and **race conditions** when dealing with concurrent programming. In a multithreaded environment, if multiple parts of your code are modifying the same object without synchronization, it can result in unpredictable behavior.

### **With Structs (Value Types)**:

When you pass a struct around, a **copy** is made. This ensures that **each copy of the struct is independent**, and changes to one instance do not affect others. This is particularly helpful when you want to avoid:

* **Accidental side effects** caused by modifying shared state.
* **Race conditions** or concurrent issues in a multithreaded environment.

### **Why it Matters**:

* By using structs (value types), **Swift promotes safer programming**. It prevents unwanted side effects, making it easier to reason about your code, especially when it comes to **state management** and **concurrency**.

---

## 3. **Immutability by Default**

In Swift, value types are inherently **immutable** unless explicitly marked as mutable with the `mutating` keyword. This means that:

* You don’t have to worry about external code changing an object unexpectedly.
* Swift encourages **functional programming practices** where values don’t change over time. This helps you manage state in a predictable and safe way.

For example, in a struct, you must use `mutating` to modify its properties:

```swift
struct Counter {
    var count = 0

    mutating func increment() {
        count += 1
    }
}

var counter = Counter()
counter.increment() // OK
// counter.count = 10 // Error: Cannot modify value of 'counter' as it's a constant
```

By enforcing immutability, Swift ensures **data integrity** and **code clarity**.

### **Why it Matters**:

* Immutability is **critical for thread safety** and **predictability** in large systems, and **value types** naturally support this by **avoiding shared state**.
* By making value types immutable by default, Swift encourages better practices for managing state in your app.

---

## 4. **Simplicity: Clear Ownership and Lifecycle**

When you use value types, you don’t have to deal with **reference counting**, **retain cycles**, or worrying about **deinitializers**. Swift handles memory management for structs in a very straightforward way — when a struct goes out of scope, it’s simply **deallocated**, and there’s no need to manage object lifetimes explicitly.

With reference types (classes), **ARC (Automatic Reference Counting)** keeps track of the number of references to an object. If the object is referenced too many times and not properly deallocated, you might run into **retain cycles** (where two objects reference each other, preventing deallocation). This can lead to memory leaks, which are challenging to track down.

### **Why it Matters**:

* **Memory management** with value types is simpler and safer because **structs don't require ARC**, whereas **classes** require careful management to prevent memory leaks or reference cycles.
* **Simplicity** means less overhead and fewer potential bugs.

---

## 5. **Swift’s Functional Programming Roots**

Swift has many **functional programming** features, and value types align well with this paradigm. Functional programming encourages working with **immutable values**, where data flows through functions rather than being changed in place.

In functional programming, functions are expected to avoid **side effects**, and structs (value types) help achieve this by **creating new instances** instead of mutating existing ones.

### Example in Swift:

```swift
struct Person {
    var name: String
}

func changeName(person: Person, newName: String) -> Person {
    var newPerson = person
    newPerson.name = newName
    return newPerson
}

let originalPerson = Person(name: "Alice")
let updatedPerson = changeName(person: originalPerson, newName: "Bob")

print(originalPerson.name) // Alice
print(updatedPerson.name) // Bob
```

Here, the **original instance** of `Person` is unchanged, and a new instance is created with the modified name. This is a **pure function** that avoids side effects, which is a core principle of functional programming.

### **Why it Matters**:

* By using structs (value types), Swift encourages the use of **pure functions** and **immutability**, which simplifies reasoning about your code and helps avoid bugs in more complex systems.

---

## 6. **Swift’s Emphasis on Safe and Fast Code**

Swift’s goal is to make programming safer and more efficient. By using structs as value types, Swift:

* **Reduces complexity** by minimizing reference counting, ARC overhead, and memory management issues.
* **Promotes safety** by ensuring that data is **copied** when passed around, not **shared**, which reduces bugs due to unintended side effects.
* **Encourages efficient code** with stack-based allocation for structs, improving performance in certain scenarios.

---

## 📝 **Summary: Why Swift Uses Structs as Value Types**

Swift chooses **structs as value types** for several important reasons:

1. **Performance**: Value types are faster because they are stack-allocated and avoid reference counting overhead.
2. **Safety**: Passing a value type around creates a copy, preventing unintended side effects and race conditions.
3. **Immutability by default**: Encourages safer, more predictable code.
4. **Simplicity**: No need to worry about memory management issues like retain cycles or ARC.
5. **Functional programming**: Promotes immutability, reducing bugs and making code easier to reason about.
6. **Thread safety**: Value types don’t share mutable state, making concurrent programming safer and easier.

Swift encourages **value types** because they make your code **safer**, **faster**, and **easier to reason about**, which leads to fewer bugs and a more maintainable codebase.

---

Let me know if you’d like to dive deeper into any specific point, or if you want to see more examples of how structs and classes behave in different scenarios!
