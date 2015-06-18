//
//  IncidentTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import XCTest



class IncidentStateDescriptionTests: XCTestCase {
    
    func test_description() {
        XCTAssertEqual(IncidentState.New.description       , "new"       )
        XCTAssertEqual(IncidentState.OnHold.description    , "on hold"   )
        XCTAssertEqual(IncidentState.Dispatched.description, "dispatched")
        XCTAssertEqual(IncidentState.OnScene.description   , "on scene"  )
        XCTAssertEqual(IncidentState.Closed.description    , "closed"    )
    }
    
}



class IncidentPriorityDescriptionTests: XCTestCase {
    
    func test_description() {
        XCTAssertEqual(IncidentPriority.High.description  , "⬆︎")
        XCTAssertEqual(IncidentPriority.Normal.description, "●")
        XCTAssertEqual(IncidentPriority.Low.description   , "⬇︎")
    }
    
}



class IncidentDescriptionTests: XCTestCase {
    
    func test_description_nils() {
        let incident = Incident(number: nil)

        XCTAssertEqual(incident.description, "Incident")
    }

    
    
    func test_description_state() {
        let incident = Incident(number: 1, state: IncidentState.New)
        
        XCTAssertEqual(incident.description, "Incident #1 (new)")
    }


    
    func test_description_stateSummary() {
        let incident = Incident(
            number: 1,
            summary: "MOOP on ground",
            state: IncidentState.New
        )
        
        XCTAssertEqual(
            incident.description,
            "Incident #1 (new): MOOP on ground"
        )
    }
    

    
    func test_description_full() {
        let incident = Incident(
            number: 1,
            priority: IncidentPriority.Normal,
            summary: "MOOP on ground",
            location: location1,
            rangers: [ranger1, ranger2],
            incidentTypes: [],
            reportEntries: [],
            created: date1,
            state: IncidentState.New
        )
        
        XCTAssertEqual(
            incident.description,
            "Incident #1 (new): MOOP on ground"
        )
    }
    
}



class IncidentNumberMutabilityTests: XCTestCase {

    func test_nilThenSet() {
        var incident = Incident(number: nil)
        incident.number = 1
        XCTAssertNotNil(incident.number)
        XCTAssertEqual(incident.number!, 1)
    }


//    func test_setThenSet() {
//        var incident = Incident(number: 1)
//
//        // FIXME: verify this raises… can't do that in swift.  :-(
//        //incident.number = 2
//    }
}



class IncidentTextPropertyTests: XCTestCase {

    func test_rangersAsText_nil() {
        let incident = Incident(
            number: 1,
            rangers: nil
        )

        XCTAssertEqual(incident.rangersAsText, "")
    }


    func test_rangersAsText_empty() {
        let incident = Incident(
            number: 1,
            rangers: []
        )

        XCTAssertEqual(incident.rangersAsText, "")
    }


    func test_rangersAsText_1() {
        let incident = Incident(
            number: 1,
            rangers: [ranger1]
        )

        XCTAssertEqual(incident.rangersAsText, "Tool")
    }


    func test_rangersAsText_12() {
        let incident = Incident(
            number: 1,
            rangers: [ranger1, ranger2]
        )

        XCTAssertEqual(incident.rangersAsText, "Splinter, Tool")
    }


    func test_rangersAsText_21() {
        let incident = Incident(
            number: 1,
            rangers: [ranger2, ranger1]
        )

        XCTAssertEqual(incident.rangersAsText, "Splinter, Tool")
    }
    

    func test_incidentTypesAsText_nil() {
        let incident = Incident(
            number: 1,
            incidentTypes: nil
        )

        XCTAssertEqual(incident.incidentTypesAsText, "")
    }


    func test_incidentTypesAsText_empty() {
        let incident = Incident(
            number: 1,
            incidentTypes: []
        )

        XCTAssertEqual(incident.incidentTypesAsText, "")
    }


    func test_incidentTypesAsText_1() {
        let incident = Incident(
            number: 1,
            incidentTypes: ["Vehicle"]
        )

        XCTAssertEqual(incident.incidentTypesAsText, "Vehicle")
    }


    func test_incidentTypesAsText_12() {
        let incident = Incident(
            number: 1,
            incidentTypes: ["Vehicle", "Fire"]
        )

        XCTAssertEqual(incident.incidentTypesAsText, "Fire, Vehicle")
    }


    func test_incidentTypesAsText_21() {
        let incident = Incident(
            number: 1,
            incidentTypes: ["Fire", "Vehicle"]
        )

        XCTAssertEqual(incident.incidentTypesAsText, "Fire, Vehicle")
    }
    

    func test_summaryAsText_nil() {
        let incident = Incident(
            number: 1,
            summary: nil
        )

        XCTAssertEqual(incident.summaryAsText, "")
    }
    
    
    func test_summaryAsText_empty() {
        let incident = Incident(
            number: 1,
            summary: ""
        )

        XCTAssertEqual(incident.summaryAsText, "")
    }

    
    func test_summaryAsText_content() {
        let incident = Incident(
            number: 1,
            summary: "Thing fell over"
        )

        XCTAssertEqual(incident.summaryAsText, "Thing fell over")
    }

    
    func test_summaryAsText_nil_reportEmpty() {
        let incident = Incident(
            number: 1,
            summary: nil,
            reportEntries: [
                ReportEntry(author: ranger1, text: "")
            ]
        )

        XCTAssertEqual(incident.summaryAsText, "")
    }


    func test_summaryAsText_nil_reportContent() {
        let incident = Incident(
            number: 1,
            summary: nil,
            reportEntries: [
                ReportEntry(author: ranger1, text: "Rolled on along\nAnd along...")
            ]
        )

        XCTAssertEqual(incident.summaryAsText, "Rolled on along")
    }
    
    
    func test_summaryAsText_empty_reportEmpty() {
        let incident = Incident(
            number: 1,
            summary: "",
            reportEntries: [
                ReportEntry(author: ranger1, text: "")
            ]
        )

        XCTAssertEqual(incident.summaryAsText, "")
    }


    func test_summaryAsText_empty_reportContent() {
        let incident = Incident(
            number: 1,
            summary: "",
            reportEntries: [
                ReportEntry(author: ranger1, text: "Rolled on along\nAnd along...")
            ]
        )

        XCTAssertEqual(incident.summaryAsText, "Rolled on along")
    }
    
    
    func test_summaryAsText_content_reportContent() {
        let incident = Incident(
            number: 1,
            summary: "Thing fell over",
            reportEntries: [
                ReportEntry(author: ranger1, text: "Rolled on along\nAnd along...")
            ]
        )

        XCTAssertEqual(incident.summaryAsText, "Thing fell over")
    }

}
