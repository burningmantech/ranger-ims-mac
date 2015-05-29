//
//  HTTPHeadersTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import XCTest



class HTTPHeadersCollectionTests: XCTestCase {

    func test_indexes() {
        var headers = HTTPHeaders()

        XCTAssertEqual(headers.startIndex, headers.endIndex)

        headers["accept"] = ["application/json"]

        XCTAssertNotEqual(headers.startIndex, headers.endIndex)

        // Not sure this is a valid test
        XCTAssertLessThan(headers.startIndex, headers.endIndex)
    }


    func test_count() {
        var headers = HTTPHeaders()

        XCTAssertEqual(headers.count, 0)

        headers["accept"] = ["application/json"]

        XCTAssertEqual(headers.count, 1)
    }


    func test_isEmpty() {
        var headers = HTTPHeaders()

        XCTAssertTrue(headers.isEmpty)

        headers["accept"] = ["application/json"]

        XCTAssertFalse(headers.isEmpty)
    }


    func test_keys() {
        var headers = HTTPHeaders()

        for key in headers.keys {
            XCTFail("No keys expected")
        }

        headers["accept"] = ["application/json"]

        var expected = Set(["accept"])

        for key in headers.keys {
            if !expected.contains(key) {
                XCTFail("\(key) not expected")
            }
            expected.remove(key)
        }
        XCTAssertEqual(expected.count, 0)
    }


    func test_values() {
        var headers = HTTPHeaders()

        for key in headers.values {
            XCTFail("No values expected")
        }

        headers["accept"] = ["application/json"]

        var expected = Set([["application/json"]])

        for value in headers.values {
            if !expected.contains(value) {
                XCTFail("\(value) not expected")
            }
            expected.remove(value)
        }
        XCTAssertEqual(expected.count, 0)
    }


    func test_subscript_setAndGet() {
        var headers = HTTPHeaders()

        headers["accept"] = ["application/json"]

        if let acceptTypes = headers["accept"] {
            XCTAssertEqual(acceptTypes, ["application/json"])
        } else {
            XCTFail("No accept key")
        }
    }


    func test_subscript_setAndGetCaseInsensitive() {
        var headers = HTTPHeaders()

        // Use both uppercase and lowercase in both set and get
        // operations, to make sure that both are normalized.
        headers["AcCePt"] = ["application/json"]

        if let acceptTypes = headers["aCcEpT"] {
            XCTAssertEqual(acceptTypes, ["application/json"])
        } else {
            XCTFail("No aCcEpT key")
        }
    }


    // FIXME: Don't know how to test this...
    // func test_subscript_position() {
    // }


    func test_generate() {
        var headers = HTTPHeaders()

        headers["accept"] = ["application/json"]

        var expected = Set([
            ["accept", ["application/json"]]
            ])

        for (name, values) in headers {
            let item = [name, values]
            if !expected.contains(item) {
                XCTFail("\(item) not expected")
            }
            expected.remove(item)
        }
        XCTAssertEqual(expected.count, 0)
    }

}



class HTTPHeadersEditTests: XCTestCase {

    func test_setValue() {
        var headers = HTTPHeaders()

        headers.set(name: "Accept", value: "application/json")

        if let acceptTypes = headers["Accept"] {
            XCTAssertEqual(acceptTypes, ["application/json"])
        } else {
            XCTFail("No Accept key")
        }
    }


    func test_setValues() {
        var headers = HTTPHeaders()

        headers.set(name: "Accept", values: ["application/json"])

        if let acceptTypes = headers["Accept"] {
            XCTAssertEqual(acceptTypes, ["application/json"])
        } else {
            XCTFail("No Accept key")
        }
    }


    func test_addValue() {
        var headers = HTTPHeaders()

        // addValue() adds an initial value
        headers.add(name: "Accept", value: "application/json")

        if let acceptTypes = headers["Accept"] {
            XCTAssertEqual(acceptTypes, ["application/json"])
        } else {
            XCTFail("No Accept key")
        }

        // addValue() appends to existing values
        headers.add(name: "Accept", value: "text/plain")

        if let acceptTypes = headers["Accept"] {
            XCTAssertEqual(acceptTypes, ["application/json", "text/plain"])
        } else {
            XCTFail("No Accept key")
        }
    }


    func test_addValues_fromArray() {
        var headers = HTTPHeaders()

        // Adds initial values
        headers.add(name: "Accept", values: ["application/json"])

        if let acceptTypes = headers["Accept"] {
            XCTAssertEqual(acceptTypes, ["application/json"])
        } else {
            XCTFail("No Accept key")
        }

        // Appends to existing values
        headers.add(name: "Accept", values: ["text/plain"])

        if let acceptTypes = headers["Accept"] {
            XCTAssertEqual(acceptTypes, ["application/json", "text/plain"])
        } else {
            XCTFail("No Accept key")
        }
    }


    func test_addValues_fromDictionary() {
        var headers = HTTPHeaders()

        headers.set(name: "Accept", values: ["application/json"])

        headers.add(
            dictionary: [
                "Accept"      : ["text/plain"],
                "Content-Type": ["application/json"]
            ]
        )

        if let acceptTypes = headers["Accept"] {
            XCTAssertEqual(acceptTypes, ["application/json", "text/plain"])
        } else {
            XCTFail("No Accept key")
        }

        if let acceptTypes = headers["Content-Type"] {
            XCTAssertEqual(acceptTypes, ["application/json"])
        } else {
            XCTFail("No Content-Type key")
        }
    }


    func test_addValues_fromHeaders() {
        var headers     = HTTPHeaders()
        var moreHeaders = HTTPHeaders()

        headers    .set(name: "Accept"      , values: ["application/json"])
        moreHeaders.set(name: "Accept"      , values: ["text/plain"      ])
        moreHeaders.set(name: "Content-Type", values: ["application/json"])
        
        headers.add(headers: moreHeaders)
        
        if let acceptTypes = headers["Accept"] {
            XCTAssertEqual(acceptTypes, ["application/json", "text/plain"])
        } else {
            XCTFail("No Accept key")
        }
        
        if let acceptTypes = headers["Content-Type"] {
            XCTAssertEqual(acceptTypes, ["application/json"])
        } else {
            XCTFail("No Content-Type key")
        }
    }
    
}
