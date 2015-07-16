//
//  HTTPRequestTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import XCTest



class HTTPMethodDescriptionTests: XCTestCase {

    func test_description() {
        XCTAssertEqual(HTTPMethod.HEAD.description, "HEAD")
        XCTAssertEqual(HTTPMethod.GET.description , "GET" )
        XCTAssertEqual(HTTPMethod.POST.description, "POST")
    }

}
