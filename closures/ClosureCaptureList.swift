//
//  ClosureCaptureList.swift
//  
//
//  Created by Apple on 08/07/25.
//

import Foundation

//
//  ClosureCaptureList.swift
//  Closure
//
//

class Person {
    var name: String
    init(_ name: String) {
        self.name = name
    }
}


func closureWithoutCaptureList() {
    var p1: Person? = Person("varsha")
    let closure: (Person) -> Void = { _ in
        DispatchQueue.global().asyncAfter(deadline: .now()+3) {
            print("name in closure is \(p1?.name ?? "person object is deallocated") ")
        }
    }
    closure(p1!)
    p1 = nil
    print("name is \(p1?.name ?? "person object is deallocated")")
}

func closureWithCaptureList() {
    var p1: Person? = Person("varsha")
    let closure: (Person) -> Void = { (p1) in
        DispatchQueue.global().asyncAfter(deadline: .now()+3) {
            print("name in closure is \(p1.name)")
        }
    }
    closure(p1!)
    p1 = nil
    print("name is \(p1?.name ?? "person object is deallocated")")
}
