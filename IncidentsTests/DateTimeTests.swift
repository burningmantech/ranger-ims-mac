//
//  DateTimeTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Foundation
import XCTest



class DateTimeComparisonTests: XCTestCase {

    func test_fromRFC3339String_asRFC3339String() {
        XCTAssertEqual(
            DateTime.fromRFC3339String(date1String).asRFC3339String(),
            date1String
        )
    }


// FIXME: Figure out how to set current locale?
//    func test_fromRFC3339String_asShortString() {
//        XCTAssertEqual(
//            DateTime.fromRFC3339String(date1String).asShortString(),
//            "xxx"
//        )
//    }
//
//
//    func test_fromRFC3339String_asLongString() {
//        XCTAssertEqual(
//            DateTime.fromRFC3339String(date1String).asLongString(),
//            "xxx"
//        )
//    }


    func test_equal() {
        XCTAssertEqual(
            DateTime.fromRFC3339String(date1String),
            DateTime.fromRFC3339String(date1String)
        )
    }


    func test_notEqual() {
        XCTAssertNotEqual(
            DateTime.fromRFC3339String(date1String),
            DateTime.fromRFC3339String(date2String)
        )
    }


    func test_lessThan() {
        XCTAssertLessThan(
            DateTime.fromRFC3339String(date1String),
            DateTime.fromRFC3339String(date2String)
        )
    }


    func test_notLessThan_greater() {
        XCTAssertFalse(
            DateTime.fromRFC3339String(date2String) <
            DateTime.fromRFC3339String(date1String)
        )
    }

    
    func test_notLessThan_equal() {
        XCTAssertFalse(
            DateTime.fromRFC3339String(date1String) <
            DateTime.fromRFC3339String(date1String)
        )
    }

}
