//
//  EquatableTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import XCTest


class NSDataBytesExtensionsTests: XCTestCase {

    func test_asBytes() {
        let bytes: [UInt8] = [116, 101, 115, 116]
        
        let nsData = NSData(bytes: bytes, length: 4)
        
        XCTAssertEqual(nsData.asBytes(), bytes)
    }

    
    func test_fromBytes() {
        let bytes: [UInt8] = [116, 101, 115, 116]
        
        let nsData = NSData.fromBytes(bytes)
        
        XCTAssertEqual(nsData.asBytes(), bytes)
    }

}
