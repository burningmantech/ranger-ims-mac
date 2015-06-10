//
//  Equatable.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

protocol Nillish {
    func isNillish() -> Bool
}


func nillish(obj: Nillish?) -> Bool {
    if let o = obj {
        return o.isNillish()
    } else {
        return true
    }
}


protocol NillishEquatable: Nillish, Equatable {}


func optionalsEqual<T: NillishEquatable>(a: T?, _ b: T?) -> Bool {
    let aIsNillish: Bool = nillish(a)
    let bIsNillish: Bool = nillish(b)

    if aIsNillish && bIsNillish {
        return true
    }

    return a == b
}


func optionalArrayEquals<T: Equatable>(a1: Array<T>?, _ a2: Array<T>?) -> Bool {
    if a1 == nil {
        return a2 == nil || a2!.count == 0
    }
    else if a2 == nil {
        return a1!.count == 0
    }

    return a1! == a2!
}


func optionalSetEquals<T: Equatable>(a1: Set<T>?, _ a2: Set<T>?) -> Bool {
    if a1 == nil {
        return a2 == nil || a2!.count == 0
    }
    else if a2 == nil {
        return a1!.count == 0
    }

    return a1! == a2!
}
