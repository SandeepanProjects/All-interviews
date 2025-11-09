//
//  Stack .swift
//  
//
//  Created by Apple on 09/11/25.
//

import Foundation

Sure! Let’s implement a **`Stack` interface** in Swift, along with a concrete class that conforms to it. I’ll include the typical operations: `push`, `pop`, `peek`, and `isEmpty`.

---

### **Step 1: Define the Stack Protocol (Interface)**

```swift
protocol Stack {
    associatedtype Element
    mutating func push(_ element: Element)
    mutating func pop() -> Element?
    func peek() -> Element?
    func isEmpty() -> Bool
}
```

* `associatedtype Element` → makes it generic for any data type.
* `mutating` → needed for methods that modify a `struct` implementation.

---

### **Step 2: Implement a Stack Using Array**

```swift
struct ArrayStack<T>: Stack {
    private var elements: [T] = []

    // Push element to the top
    mutating func push(_ element: T) {
        elements.append(element)
    }

    // Pop element from the top
    mutating func pop() -> T? {
        return elements.popLast()
    }

    // Peek at the top element without removing
    func peek() -> T? {
        return elements.last
    }

    // Check if stack is empty
    func isEmpty() -> Bool {
        return elements.isEmpty
    }
}
```

---

### **Step 3: Usage Example**

```swift
var stack = ArrayStack<Int>()
stack.push(10)
stack.push(20)
stack.push(30)

print(stack.peek() ?? "Empty") // 30
print(stack.pop() ?? "Empty")  // 30
print(stack.pop() ?? "Empty")  // 20
print(stack.isEmpty())          // false
stack.pop()
print(stack.isEmpty())          // true
```

---

### ✅ **Notes**

1. `Array` in Swift is already a dynamic array, so `append`/`popLast` make stack operations **O(1) amortized**.
2. You could also implement it as a **linked list** if you want **O(1) push/pop** without resizing arrays.
3. The `Stack` protocol allows multiple concrete implementations (`ArrayStack`, `LinkedListStack`, etc.) without changing the rest of the code.

---

If you want, I can also show a **Linked List version of Stack** which is interview favorite because it avoids array resizing and demonstrates pointer manipulation skills.

Do you want me to do that?
