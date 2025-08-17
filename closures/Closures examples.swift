//
//  Closures examples.swift
//  
//
//  Created by Apple on 08/07/25.
//

import Foundation

//
//  SimpleClosure.swift
//  Closure
//
//

import Foundation

let simpleClosure = {

}

let closureWithStatement = {
    print("Hello, World!")
}

let closureWithArgument:(String) -> () = { name in
    print("Hi \(name)")
}


let closureReturnValueWithOutArgument:() -> (String) = {
    
    let greeting = "Hello, World! "
    return greeting
}

let closureReturnValueWithArgument:(String) -> (String) = { name in
    
    let str = "Hello, \(name) "
    return str
}

//
//  Closer+Notifier.swift
//  Closure
//

class A {
    let b = B()
    func someFunction() {
        b.tapAction = { (message) in
            print("tapAction message displayed in class A \(message)")
        }
        b.buttonTapped()
    }
}

public class B {
    public var tapAction: ((String) -> Void)?
    func buttonTapped() {
        print("Button tapped in class B")
        tapAction?("Class B Button tapped")
    }
}


//
//  closureType.swift
//  Closure
//
//


func functionWithClosureAsArgument(closure: ()->()) {
    print("Function Called")
}

func functionWithClosureAsArgumentAndClosureCalls(closure: ()->()) {
    print("Function Called")
    closure()
}

func trailingClosure(msg:String, closure:  ()->()) {
    print(msg)
    closure()
}


func functionWithoutAutoClosure(closure: ()->(), msg: String) {
    print(msg)
    closure()
}


//
//  ClosureAsCompletionHandler.swift
//  ClosuresInSwift
//
//


func closureAsCompletionHandler(completion:()->()) {
    print("function called")
    print("before calling callback")
    completion()
    print("after calling callback")
}

func trailingClosureAsCompletionHandler(msg: String, completion: ()->()) {
    print(msg)
    print("before calling callback")
    completion()
    print("after calling callback")
}

func trailingClosureWithArgumentAsCompletionHandler(msg: String, completion: (Bool)->()) {
    print(msg)
    print("before calling callback")
    completion(true)
    print("after calling callback")
}
