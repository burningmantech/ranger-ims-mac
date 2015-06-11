//
//  InMemoryIncidentManagementSystemTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import XCTest



class InMemoryIncidentManagementSystemTests: XCTestCase {

    let cannedIncidentTypes = Set([
        "Airport",
        "Animal",
        "Art",
        "Assault",
        "Fire",
        "Law Enforcement",
        "Medical",
        "Staff",
        "Theft",
        "Vehicle",
    ])


    let cannedRangers = [
        "k8"         : Ranger(handle: "k8"         ),
        "Safety Phil": Ranger(handle: "Safety Phil"),
        "Splinter"   : Ranger(handle: "Splinter"   ),
        "Tool"       : Ranger(handle: "Tool"       ),
        "Tulsa"      : Ranger(handle: "Tulsa"      ),
    ]

    let cannedLocations = [
        "The Man": Location(
            name: "The Man",
            address: Address(textDescription: "The Man")
        ),
        "The Temple": Location(
            name: "The Temple",
            address: Address(textDescription: "The Temple")
        ),
        "Camp Fishes": Location(
            name: "Camp Fishes",
            address: RodGarettAddress(
                concentric: ConcentricStreet.J,
                radialHour: 3,
                radialMinute: 30,
                textDescription: "Big fish tank"
            )
        ),
    ]

    var cannedIncidents: [Incident]?

    var ims: IncidentManagementSystem?


    override func setUp() {
        super.setUp()

        let ims = InMemoryIncidentManagementSystem()

        cannedIncidents = [
            Incident(
                number: 1,
                priority: IncidentPriority.Medium,
                summary: "Participant fell from structure at Camp Fishes",
                location: cannedLocations["Camp Fishes"]!,
                rangers: [cannedRangers["Splinter"]!],
                incidentTypes: ["Medical"],
                reportEntries: [
                    ReportEntry(
                        author: cannedRangers["k8"]!,
                        text: "Participant fell from structure at Camp Fishes.\nSplinter on scene.",
                        created: date1
                    )
                ],
                created: date1,
                state: IncidentState.OnScene
            ),
            Incident(
                number: 2,
                priority: IncidentPriority.Low,
                summary: "Lost keys",
                location: Location(
                    address: Address(textDescription: "Near the portos on 9:00 promenade")
                ),
                rangers: [cannedRangers["Safety Phil"]!],
                created: date2,
                state: IncidentState.OnHold
            ),
            Incident(
                number: 3,
                priority: IncidentPriority.High,
                summary: "Speeding near the Man",
                location: cannedLocations["The Man"]!,
                rangers: [cannedRangers["Tulsa"]!],
                incidentTypes: ["Vehicle"],
                reportEntries: [
                    ReportEntry(
                        author: cannedRangers["Tool"]!,
                        text: "Black sedan, unlicensed, travelling at high speed around the Man.",
                        created: date3
                    )
                ],
                created: date2,
                state: IncidentState.OnScene
            ),
            Incident(
                number: 4,
                priority: IncidentPriority.High,
                summary: "Need MHB at the Temple",
                location: cannedLocations["The Temple"]!,
                rangers: [cannedRangers["Tulsa"]!],
                incidentTypes: ["Medical"],
                reportEntries: [
                    ReportEntry(
                        author: cannedRangers["Tool"]!,
                        text: "Highly agitated male at Temple.",
                        created: date4
                    )
                ],
                created: date4,
                state: IncidentState.OnScene
            ),
            Incident(
                number: 5,
                priority: IncidentPriority.Medium,
                created: date4,
                state: IncidentState.New
            ),
        ]

        for incidentType in cannedIncidentTypes {
            ims.addIncidentType(incidentType)
        }

        for ranger in cannedRangers.values {
            ims.addRanger(ranger)
        }

        for incident in cannedIncidents! {
            let incidentWithoutNumber = Incident(
                number       : nil,
                priority     : incident.priority,
                summary      : incident.summary,
                location     : incident.location,
                rangers      : incident.rangers,
                incidentTypes: incident.incidentTypes,
                reportEntries: incident.reportEntries,
                created      : incident.created,
                state        : incident.state
            )

            ims.createIncident(incidentWithoutNumber)
        }
        assert(ims.incidentsByNumber.count == cannedIncidents!.count, "No incidents?")

        self.ims = ims
    }


    override func tearDown() {
        ims = nil
        super.tearDown()
    }


    func test_incidentTypes() {
        XCTAssertEqual(ims!.incidentTypes, cannedIncidentTypes)
    }


    func test_rangersByHandle_keysMatch() {
        for (handle, ranger) in ims!.rangersByHandle {
            XCTAssertEqual(handle, ranger.handle)
        }
    }


    func test_rangersByHandle_values() {
        XCTAssertEqual(Set(ims!.rangersByHandle.values), Set(cannedRangers.values))
    }


    func test_locationsByName_keysMatch() {
        for (name, location) in ims!.locationsByName {
            XCTAssertEqual(name, location.name!)
        }
    }


    func test_locationsByName_values() {
        XCTAssertEqual(Set(ims!.locationsByName.values), Set(cannedLocations.values))
    }


    func test_incidentsByNumber_values() {
        XCTAssertEqual(Set(ims!.incidentsByNumber.values), Set(cannedIncidents!))
    }


    func test_createIncident() {
        var incident = Incident(number: nil)
        if ims!.createIncident(incident).failed {
            XCTFail("Create incident failed.")
        }
        incident.number = cannedIncidents!.count + 1

        var expected = Set(cannedIncidents!)
        expected.insert(incident)

        XCTAssertEqual(Set(ims!.incidentsByNumber.values), expected)
    }


    func test_createIncidentWithNumber() {
        let incident = Incident(number: ims!.incidentsByNumber.count)
        if !ims!.createIncident(incident).failed {
            XCTFail("Create incident suceeded when it should have failed.")
        }
    }


    func test_updateInPlace() {
        if var incident = ims!.incidentsByNumber[5] {
            XCTAssertNil(
                incident.summary,
                "Canned incident 5 summary should be nil"
            )

            incident.summary = "Blocked road by Roller Disco"

            if let incidentAgain = ims!.incidentsByNumber[5] {
                XCTAssertNil(
                    incidentAgain.summary,
                    "Canned incident 5 summary should still be nil"
                )
            }
        } else {
            XCTFail("No incident #5?")
        }
    }


    func test_updateIncident() {
        if var incident = ims!.incidentsByNumber[5] {
            XCTAssertNil(
                incident.summary,
                "Canned incident 5 summary should be nil"
            )

            incident.summary = "Blocked road by Roller Disco"

            let f = ims!.updateIncident(incident)
            XCTAssertFalse(f.failed)

            if let incidentAgain = ims!.incidentsByNumber[5] {
                XCTAssertNotNil(incidentAgain.summary)
                XCTAssertEqual(
                    incidentAgain.summary!,
                    "Blocked road by Roller Disco"
                )
            }
        } else {
            XCTFail("No incident #5?")
        }
    }


//    func test_reloadIncidentWithNumber() {
//        let f = ims!.reloadIncidentWithNumber(2)
//        XCTAssertFalse(f.failed)
//    }
//
//
//    func test_reloadIncidentWithNumber_noneSuch() {
//        let f = ims!.reloadIncidentWithNumber(999)
//        XCTAssertTrue(f.failed)
//    }

}
