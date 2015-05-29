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
            "8:45@C, Red and yellow flags, dome"
        )
    }


    func test_description_concentric() {
        let address = RodGarettAddress(concentric: ConcentricStreet.C)

        XCTAssertEqual(address.description, "-:-@C")
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

        XCTAssertEqual(ConcentricStreet.A.description, "A")
        XCTAssertEqual(ConcentricStreet.B.description, "B")
        XCTAssertEqual(ConcentricStreet.C.description, "C")
        XCTAssertEqual(ConcentricStreet.D.description, "D")
        XCTAssertEqual(ConcentricStreet.E.description, "E")
        XCTAssertEqual(ConcentricStreet.F.description, "F")
        XCTAssertEqual(ConcentricStreet.G.description, "G")
        XCTAssertEqual(ConcentricStreet.H.description, "H")
        XCTAssertEqual(ConcentricStreet.I.description, "I")
        XCTAssertEqual(ConcentricStreet.J.description, "J")
        XCTAssertEqual(ConcentricStreet.K.description, "K")
        XCTAssertEqual(ConcentricStreet.L.description, "L")
        XCTAssertEqual(ConcentricStreet.M.description, "M")
        XCTAssertEqual(ConcentricStreet.N.description, "N")
    }

}
