//
//  ReportEntryTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import XCTest



class ReportEntryDescriptionTests: XCTestCase {

    let dateString = "1971-04-20T16:20:04Z"


    let tool = Ranger(
        handle: "Tool",
        name: "Wilfredo Sánchez Vega",
        status: "vintage"
    )


    func test_description_nonSystem() {
        let date = DateTime.fromRFC3339String(dateString)
        let entry = ReportEntry(
            author: tool,
            text: "Random edict!\n",
            created: date
        )

        XCTAssertEqual(
            entry.description,
            "Tool @ \(dateString):\nRandom edict!\n"
        )
    }


    func test_description_system() {
        let date = DateTime.fromRFC3339String(dateString)
        let entry = ReportEntry(
            author: tool,
            text: "some event",
            created: date,
            systemEntry: true
        )

        XCTAssertEqual(
            entry.description,
            "Tool @ \(dateString): some event"
        )
    }

}
