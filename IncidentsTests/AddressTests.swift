//
//  AddressTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import XCTest



class AddressDescriptionTests: XCTestCase {
    
    func test_description_full() {
        let address = Address(textDescription: "Camp with tents")

        XCTAssertEqual(address.description, "Camp with tents")
    }


    func test_description_nil() {
        let address = Address()

        XCTAssertEqual(address.description, "")
    }

}



class AddressNillishTests: XCTestCase {

    func test_nilAttributes() {
        XCTAssertTrue(Address().isNillish())
    }


    func test_textDescription() {
        XCTAssertFalse(
            Address(textDescription: "over there").isNillish()
        )
    }
    
}



class RodGarettAddressDescriptionTests: XCTestCase {
    
    func test_description_full() {
        let address = RodGarettAddress(
            concentric      : ConcentricStreet.C,
            radialHour      : 8,
            radialMinute    : 45,
            textDescription : "Red and yellow flags, dome"
        )

        XCTAssertEqual(
            address.description,
            "8:45@\(ConcentricStreet.C), Red and yellow flags, dome"
        )
    }


    func test_description_concentric() {
        let address = RodGarettAddress(concentric: ConcentricStreet.C)

        XCTAssertEqual(address.description, "-:-@\(ConcentricStreet.C)")
    }


    func test_description_radialHour() {
        let address = RodGarettAddress(radialHour: 8)

        XCTAssertEqual(address.description, "8:-@-")
    }


    func test_description_radialMinute() {
        let address = RodGarettAddress(radialMinute: 45)

        XCTAssertEqual(address.description, "-:45@-")
    }


    func test_description_textDescription() {
        let address = RodGarettAddress(
            textDescription : "Red and yellow flags, dome"
        )

        XCTAssertEqual(
            address.description,
            "-:-@-, Red and yellow flags, dome"
        )
    }

}



class RodGarettAddressNillishTests: XCTestCase {

    func test_nilAttributes() {
        XCTAssertTrue(RodGarettAddress().isNillish())
    }


    func test_concentric() {
        XCTAssertFalse(
            RodGarettAddress(concentric: ConcentricStreet.A).isNillish()
        )
    }


    func test_radialHour() {
        XCTAssertFalse(
            RodGarettAddress(radialHour: 8).isNillish()
        )
    }


    func test_radialMinute() {
        XCTAssertFalse(
            RodGarettAddress(radialMinute: 45).isNillish()
        )
    }


    func test_textDescription() {
        XCTAssertFalse(
            RodGarettAddress(textDescription: "over there").isNillish()
        )
    }
    
}



class ConcentricStreetNameTests: XCTestCase {

    func test_name() {
        XCTAssertEqual(ConcentricStreet.Esplanade.description, "Esplanade")

        XCTAssertTrue(ConcentricStreet.A.description.hasPrefix("A"))
        XCTAssertTrue(ConcentricStreet.B.description.hasPrefix("B"))
        XCTAssertTrue(ConcentricStreet.C.description.hasPrefix("C"))
        XCTAssertTrue(ConcentricStreet.D.description.hasPrefix("D"))
        XCTAssertTrue(ConcentricStreet.E.description.hasPrefix("E"))
        XCTAssertTrue(ConcentricStreet.F.description.hasPrefix("F"))
        XCTAssertTrue(ConcentricStreet.G.description.hasPrefix("G"))
        XCTAssertTrue(ConcentricStreet.H.description.hasPrefix("H"))
        XCTAssertTrue(ConcentricStreet.I.description.hasPrefix("I"))
        XCTAssertTrue(ConcentricStreet.J.description.hasPrefix("J"))
        XCTAssertTrue(ConcentricStreet.K.description.hasPrefix("K"))
        XCTAssertTrue(ConcentricStreet.L.description.hasPrefix("L"))
        XCTAssertTrue(ConcentricStreet.M.description.hasPrefix("M"))
        XCTAssertTrue(ConcentricStreet.N.description.hasPrefix("N"))
    }

}
