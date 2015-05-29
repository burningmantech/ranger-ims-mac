//
//  RangerTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import XCTest



class RangerDescriptionTests: XCTestCase {
    
    func test_description_handle() {
        let ranger = Ranger(handle: "Tool")

        XCTAssertEqual(ranger.description, "Tool")
    }

    func test_description_nilStatus() {
        let ranger = Ranger(
            handle: "Tool",
            name: "Wilfredo Sánchez Vega"
        )

        XCTAssertEqual(
            ranger.description,
            "Tool (Wilfredo Sánchez Vega)"
        )
    }

    func test_description_statusVintage() {
        let ranger = Ranger(
            handle: "Tool",
            name: "Wilfredo Sánchez Vega",
            status: "vintage"
        )

        XCTAssertEqual(
            ranger.description,
            "Tool (Wilfredo Sánchez Vega)*"
        )
    }

    func test_description_statusActive() {
        let ranger = Ranger(
            handle: "Tool",
            name: "Wilfredo Sánchez Vega",
            status: "active"
        )

        XCTAssertEqual(
            ranger.description,
            "Tool (Wilfredo Sánchez Vega)"
        )
    }

}
