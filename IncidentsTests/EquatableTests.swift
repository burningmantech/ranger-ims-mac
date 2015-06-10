//
//  EquatableTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import XCTest



class OptionalsEqualTests: XCTestCase {

    func test_nilBoth() {
        let l1: NillishThing? = nil
        let l2: NillishThing? = nil
        XCTAssertTrue(optionalsEqual(l2, l1))
    }


    func test_nillLeft() {
        let l1: NillishThing? = nil
        let l2: NillishThing? = NillishThing("foo")
        XCTAssertFalse(optionalsEqual(l2, l1))
    }


    func test_nillLeftNillishRight() {
        let l1: NillishThing? = nil
        let l2: NillishThing? = NillishThing()
        XCTAssertTrue(optionalsEqual(l2, l1))
    }


    func test_nillRight() {
        let l1: NillishThing? = NillishThing("foo")
        let l2: NillishThing? = nil
        XCTAssertFalse(optionalsEqual(l1, l2))
    }


    func test_nillRightNillishLeft() {
        let l1: NillishThing? = NillishThing()
        let l2: NillishThing? = nil
        XCTAssertTrue(optionalsEqual(l1, l2))
    }
    
}



class OptionalArrayEqualsTests: XCTestCase {

    func test_nilBoth() {
        let a1: Array<Int>? = nil
        let a2: Array<Int>? = nil

        XCTAssertTrue(optionalArrayEquals(a1, a2))
    }


    func test_nilLeft() {
        let a1: Array<Int>? = nil
        let a2: Array<Int>? = [1]

        XCTAssertFalse(optionalArrayEquals(a1, a2))
    }


    func test_nilLeftEmptyRight() {
        let a1: Array<Int>? = nil
        let a2: Array<Int>? = []

        XCTAssertTrue(optionalArrayEquals(a1, a2))
    }
    
    
    func test_nilRight() {
        let a1: Array<Int>? = [1]
        let a2: Array<Int>? = nil

        XCTAssertFalse(optionalArrayEquals(a1, a2))
    }


    func test_nilRightEmptyLeft() {
        let a1: Array<Int>? = []
        let a2: Array<Int>? = nil

        XCTAssertTrue(optionalArrayEquals(a1, a2))
    }


    func test_emptyBoth() {
        let a1: Array<Int>? = []
        let a2: Array<Int>? = []

        XCTAssertTrue(optionalArrayEquals(a1, a2))
    }


    func test_emptyLeft() {
        let a1: Array<Int>? = []
        let a2: Array<Int>? = [1]

        XCTAssertFalse(optionalArrayEquals(a1, a2))
    }
    
    
    func test_emptyRight() {
        let a1: Array<Int>? = [1]
        let a2: Array<Int>? = []

        XCTAssertFalse(optionalArrayEquals(a1, a2))
    }


    func test_unequalLengths() {
        let a1 = [1]
        let a2 = [1,2]

        XCTAssertFalse(optionalArrayEquals(a1, a2))
        XCTAssertFalse(optionalArrayEquals(a2, a1))
    }


    func test_equalLengthSame() {
        let a1 = [1,2]
        let a2 = [1,2]

        XCTAssertTrue(optionalArrayEquals(a1, a2))
        XCTAssertTrue(optionalArrayEquals(a2, a1))
    }


    func test_equalLengthDifferent() {
        let a1 = [1,2]
        let a2 = [1,3]

        XCTAssertFalse(optionalArrayEquals(a1, a2))
        XCTAssertFalse(optionalArrayEquals(a2, a1))
    }

}



class OptionalSetEqualsTests: XCTestCase {

    func test_nilBoth() {
        let a1: Set<Int>? = nil
        let a2: Set<Int>? = nil

        XCTAssertTrue(optionalSetEquals(a1, a2))
    }


    func test_nilLeft() {
        let a1: Set<Int>? = nil
        let a2: Set<Int>? = [1]

        XCTAssertFalse(optionalSetEquals(a1, a2))
    }


    func test_nilLeftEmptyRight() {
        let a1: Set<Int>? = nil
        let a2: Set<Int>? = []

        XCTAssertTrue(optionalSetEquals(a1, a2))
    }


    func test_nilRight() {
        let a1: Set<Int>? = [1]
        let a2: Set<Int>? = nil

        XCTAssertFalse(optionalSetEquals(a1, a2))
    }


    func test_nilRightEmptyLeft() {
        let a1: Set<Int>? = []
        let a2: Set<Int>? = nil

        XCTAssertTrue(optionalSetEquals(a1, a2))
    }


    func test_emptyBoth() {
        let a1: Set<Int>? = []
        let a2: Set<Int>? = []

        XCTAssertTrue(optionalSetEquals(a1, a2))
    }


    func test_emptyLeft() {
        let a1: Set<Int>? = []
        let a2: Set<Int>? = [1]

        XCTAssertFalse(optionalSetEquals(a1, a2))
    }


    func test_emptyRight() {
        let a1: Set<Int>? = [1]
        let a2: Set<Int>? = []

        XCTAssertFalse(optionalSetEquals(a1, a2))
    }


    func test_unequalLengths() {
        let a1 = Set([1])
        let a2 = Set([1,2])

        XCTAssertFalse(optionalSetEquals(a1, a2))
        XCTAssertFalse(optionalSetEquals(a2, a1))
    }


    func test_equalLengthSame() {
        let a1 = Set([1,2])
        let a2 = Set([1,2])

        XCTAssertTrue(optionalSetEquals(a1, a2))
        XCTAssertTrue(optionalSetEquals(a2, a1))
    }


    func test_equalLengthDifferent() {
        let a1 = Set([1,2])
        let a2 = Set([1,3])
        
        XCTAssertFalse(optionalSetEquals(a1, a2))
        XCTAssertFalse(optionalSetEquals(a2, a1))
    }
    
}



class NillishThing: NillishEquatable {
    let string: String?


    init(_ string: String? = nil) {
        self.string = string
    }


    func isNillish() -> Bool {
        return string == nil
    }
}


func ==(lhs: NillishThing, rhs: NillishThing) -> Bool {
    return lhs.string == rhs.string
}
