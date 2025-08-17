//
//  Trailing Closures.swift
//  
//
//  Created by Apple on 26/07/25.
//

import Foundation

### What are Trailing Closures in Swift?

A **trailing closure** in Swift is a closure that is passed as the last argument to a function or method, but instead of passing it inside the parentheses, you can write it **outside** the parentheses.

The primary advantage of trailing closures is that it makes the code cleaner and easier to read, especially when the closure is large or contains many lines of code.

### Syntax

The basic syntax of a trailing closure looks like this:

```swift
someFunction(arg1, arg2) {
    // Closure code goes here
}
```

Instead of writing the closure inside the parentheses like this:

```swift
someFunction(arg1, arg2, closure: {
    // Closure code goes here
})
```

### Example of Trailing Closure

Let’s say you have a function that takes a closure as a parameter. Here’s how it would work without a trailing closure:

```swift
func performOperation(x: Int, y: Int, completion: (Int) -> Void) {
    let result = x + y
    completion(result)
}

performOperation(x: 2, y: 3, completion: { result in
    print("The result is \(result)")
})
```

Now, with a trailing closure, you can write the closure **outside** of the parentheses:

```swift
performOperation(x: 2, y: 3) { result in
    print("The result is \(result)")
}
```

Notice how the closure is written **outside** the parentheses, making the code more readable, especially when closures contain multiple lines of code.

### When to Use Trailing Closures

1. **When the Closure Is the Last Parameter**:
   Trailing closures are most commonly used when the closure is the last parameter of a function. This allows you to write cleaner, more readable code.

2. **For Closure-heavy Functions**:
   If the function expects a closure as one of its main arguments (e.g., functions that perform asynchronous tasks or UI updates), using a trailing closure can make the code more succinct.

   For example, consider methods like `map`, `filter`, and `reduce` in the Swift standard library, which are often called with trailing closures:

   ```swift
   let numbers = [1, 2, 3, 4, 5]
   let doubled = numbers.map { $0 * 2 }
   ```

   This is much cleaner than passing the closure within the parentheses.

3. **To Improve Readability**:
   When a closure is large or contains multiple lines, trailing closures can greatly improve the readability of the code. For instance, UI setup in iOS development frequently uses trailing closures, as the closure code is often verbose:

   ```swift
   someView.addGestureRecognizer(UITapGestureRecognizer()) { gesture in
       print("View tapped!")
   }
   ```

4. **Closure with Multiple Statements**:
   If your closure has multiple statements, the trailing closure syntax can make your code much easier to follow.

   ```swift
   someFunction(arg1: value1, arg2: value2) { result in
       let modifiedResult = result * 2
       print(modifiedResult)
   }
   ```

### Key Points to Remember

* **Trailing closures** are used when a closure is the last parameter of a function.
* They are particularly useful when the closure is long or contains multiple lines of code.
* Swift allows trailing closures only for the last parameter of the function or method.

### When NOT to Use Trailing Closures

* When the closure is **not the last parameter** of the function, you cannot use a trailing closure.
* In cases where the closure is very short or simple, passing it inside the parentheses may be more concise.

### Summary

Trailing closures are a convenient feature in Swift that help improve the readability of code, especially when working with closures that have many lines of code. They are most useful when the closure is the last parameter of the function and when the closure is large or multi-line.

Do you have an example in mind where you'd want to use trailing closures? Or perhaps a situation you're trying to understand better?

Sure! Let’s go over more **detailed examples** to better illustrate **trailing closures** and how they improve code readability.

### 1. Basic Example: Passing a Closure to a Function

Let's start with a simple function that takes a closure as its last parameter.

#### Without Trailing Closure:

Imagine we have a function that takes two numbers and a closure to perform an operation on them:

```swift
func performCalculation(x: Int, y: Int, operation: (Int, Int) -> Int) {
    let result = operation(x, y)
    print("The result is \(result)")
}

performCalculation(x: 5, y: 3, operation: { (a, b) in
    return a + b
})
```

Here, the closure is inside the parentheses of the function call. You can see how this can get verbose, especially when the closure gets more complex.

#### With Trailing Closure:

Now, we use a **trailing closure** to write the closure **outside** the parentheses:

```swift
performCalculation(x: 5, y: 3) { (a, b) in
    return a + b
}
```

This is **cleaner and easier to read**, especially when the closure logic is simple, and it improves the clarity of the function call.

### 2. Using Trailing Closures with Multiple Statements

Let’s expand the closure to contain multiple statements. Suppose we have a function that sorts an array of numbers, but the sorting logic is complex and involves multiple statements:

#### Without Trailing Closure:

```swift
func sortNumbers(_ numbers: [Int], usingComparator comparator: (Int, Int) -> Bool) -> [Int] {
    return numbers.sorted(by: comparator)
}

let sortedNumbers = sortNumbers([3, 1, 4, 2, 5], usingComparator: { (a, b) in
    if a == b {
        return true
    }
    return a < b
})
print(sortedNumbers)
```

This code works, but the closure is written inside the parentheses, and with multiple lines inside the closure, it starts to feel a bit cluttered.

#### With Trailing Closure:

When using a trailing closure, it looks much cleaner and more readable:

```swift
let sortedNumbers = sortNumbers([3, 1, 4, 2, 5]) { (a, b) in
    if a == b {
        return true
    }
    return a < b
}
print(sortedNumbers)
```

Notice how the logic of the closure is **outside the parentheses**, making the function call much easier to read, especially if there are multiple statements.

### 3. Trailing Closures with UIKit: Common in iOS Development

In UIKit or SwiftUI, closures are often used for handling events, UI actions, and animations. Here’s a common example from **UIKit** where trailing closures help improve readability.

#### Without Trailing Closure:

```swift
let button = UIButton(type: .system)
button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

func buttonTapped() {
    print("Button tapped!")
}
```

Here we use a **target-action** approach, but let’s look at a more complex UIKit example, such as adding a **gesture recognizer** to a view:

```swift
let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))

view.addGestureRecognizer(tapGesture)

@objc func handleTap() {
    print("Tapped!")
}
```

Now, let’s consider a scenario where you’re using a **closure-based API**.

#### With Trailing Closure (Common in UIKit or SwiftUI):

UIKit has many functions that allow you to use closures directly. Here’s a **UIButton** example where you use a trailing closure for the action:

```swift
let button = UIButton(type: .system)
button.addAction(UIAction(handler: { action in
    print("Button pressed")
}), for: .touchUpInside)
```

Here, the closure is passed outside the parentheses as a **trailing closure**, making the action setup much cleaner and easier to read.

### 4. Example with Async Callbacks

Another scenario where trailing closures are useful is in asynchronous functions. Here’s an example where you use a trailing closure with an async function that fetches data from a server.

#### Without Trailing Closure:

```swift
func fetchData(url: String, completion: @escaping (Data?, Error?) -> Void) {
    // Simulate fetching data
    let data = Data() // Dummy data
    completion(data, nil)
}

fetchData(url: "https://example.com") { data, error in
    if let error = error {
        print("Error: \(error)")
    } else {
        print("Data fetched: \(data!)")
    }
}
```

#### With Trailing Closure:

When using a trailing closure, the code becomes more readable, especially when the closure is long or complex:

```swift
fetchData(url: "https://example.com") { data, error in
    if let error = error {
        print("Error: \(error)")
    } else {
        print("Data fetched: \(data!)")
    }
}
```

### 5. Example with Collection Methods (`map`, `filter`, etc.\`)

In Swift, functions like `map`, `filter`, and `reduce` accept closures as parameters, and these are excellent examples of where trailing closures shine.

#### Using `map` without Trailing Closure:

```swift
let numbers = [1, 2, 3, 4, 5]
let doubledNumbers = numbers.map({ number in
    return number * 2
})
print(doubledNumbers) // [2, 4, 6, 8, 10]
```

#### Using `map` with Trailing Closure:

This is the **cleaner and more natural** way to write it:

```swift
let doubledNumbers = numbers.map { number in
    return number * 2
}
print(doubledNumbers) // [2, 4, 6, 8, 10]
```

### Summary of Examples

* **Simple closures**: Trailing closures make function calls more readable by placing the closure outside the parentheses.
* **Multiple statements**: Trailing closures are especially useful for closures that contain more complex logic (i.e., multiple statements).
* **Async closures**: In asynchronous operations, trailing closures provide a more natural syntax, improving readability.
* **Collection operations**: Methods like `map`, `filter`, and `reduce` use trailing closures to make the code concise and easy to understand.

### Conclusion

Trailing closures help **improve code readability** and **cleanliness**, particularly in scenarios where the closure is large or contains multiple lines of code. They are used when a function's closure is the **last parameter** and are very common in **UIKit**, **SwiftUI**, and **functional programming** with arrays or other collections.

Would you like to dive deeper into any specific example or use case?
