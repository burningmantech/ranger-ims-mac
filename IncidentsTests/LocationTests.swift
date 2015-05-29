//
//  LocationTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import XCTest



class LocationDescriptionTests: XCTestCase {

    let address = RodGarettAddress(
        concentric      : ConcentricStreet.C,
        radialHour      : 8,
        radialMinute    : 45,
        textDescription : "Red and yellow flags, dome"
    )

    
    func test_description_full() {
        let location = Location(
            name: "Camp Equilibrium",
            address: address
        )

        XCTAssertEqual(
            location.description,
            "Camp Equilibrium (8:45@C, Red and yellow flags, dome)"
        )
    }


    func test_description_name() {
        let location = Location(name: "Camp Equilibrium")

        XCTAssertEqual(
            location.description,
            "Camp Equilibrium"
        )
    }


    func test_description_address() {
        let location = Location(address: address)

        XCTAssertEqual(
            location.description,
            "(8:45@C, Red and yellow flags, dome)"
        )
    }


    func test_description_same() {
        let location = Location(
            name: "The Man",
            address: TextOnlyAddress(textDescription: "The Man")
        )

        XCTAssertEqual(
            location.description,
            "The Man"
        )
    }

}



class LocationNillishTests: XCTestCase {

    func test_nilAttributes() {
        XCTAssertTrue(Location().isNillish())
    }


    func test_name() {
        XCTAssertFalse(Location(name: "Distrikt").isNillish())
    }


    func test_address() {
        XCTAssertFalse(
            Location(
                address: Address(textDescription: "over there")
            ).isNillish()
        )
    }

}
