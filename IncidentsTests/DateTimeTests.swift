//
//  DateTimeTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Foundation
import XCTest



class DateTimeRFC3339Tests: XCTestCase {

    // FIXME: Can't test fromRFC3339String because we can't access the internal
    // NSDate value, which is private.
    

    func test_fromRFC3339String_asRFC3339String_roundtrip() {
        XCTAssertEqual(
            DateTime.fromRFC3339String(date1String).asRFC3339String(),
            date1String
        )
    }


    func test_description() {
        XCTAssertEqual(
            DateTime.fromRFC3339String(date1String).description,
            date1String
        )
    }

    
//    // FIXME: Figure out how to set current locale so that the tests below work
//    // reliably.
//
//    
//    func test_asShortString() {
//        XCTAssertEqual(
//            DateTime.fromRFC3339String(date1String).asShortString(),
//            "20/08:20"
//        )
//    }
//    
//
//    func test_asString() {
//        XCTAssertEqual(
//            DateTime.fromRFC3339String(date1String).asString(),
//            "1971-04-20 08:20"
//        )
//    }
//
//
//    func test_asLongString() {
//        XCTAssertEqual(
//            DateTime.fromRFC3339String(date1String).asLongString(),
//            "Tuesday, April 20, 1971 08:20:04 PST"
//        )
//    }

}



class DateTimeComparisonTests: XCTestCase {

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
