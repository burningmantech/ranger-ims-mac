//
//  JSONTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import XCTest



class JSONDeserializationTests: XCTestCase {
    
    func test_deserialize_noNumber() {
        let json = IncidentDictionary()

        let incidentResult = incidentFromJSON(json)
        if !incidentResult.failed {
            XCTFail("Parser should have failed")
        }
    }


    func test_deserialize_number() {
        let json = [ "number": 1 ]

        let incidentResult = incidentFromJSON(json)
        if incidentResult.failed { XCTFail("\(incidentResult.error!)") }

        if let incident = incidentResult.value {
            XCTAssertEqual(incident, Incident(number: 1))
        } else {
            XCTFail("No deserialized incident")
        }
    }


    func test_deserialize_negativeNumber() {
        let json = [ "number": -1 ]

        let incidentResult = incidentFromJSON(json)
        if !incidentResult.failed {
            XCTFail("Parser should have failed")
        }
    }


    func test_deserialize_priority() {
        for (jsonPriority, expectedPriority) in [
            1: IncidentPriority.High,
            2: IncidentPriority.High,
            3: IncidentPriority.Normal,
            4: IncidentPriority.Low,
            5: IncidentPriority.Low,
        ] {
            let json = [ "number": 1, "priority": jsonPriority ]

            let incidentResult = incidentFromJSON(json)
            if incidentResult.failed { XCTFail("\(incidentResult.error!)") }

            if let incident = incidentResult.value {
                XCTAssertEqual(
                    incident,
                    Incident(number: 1, priority: expectedPriority)
                )
            } else {
                XCTFail("No deserialized incident")
            }
        }
    }


    func test_deserialize_summary() {
        let json = [ "number": 1, "summary": "Cheese and pickles" ]

        let incidentResult = incidentFromJSON(json)
        if incidentResult.failed { XCTFail("\(incidentResult.error!)") }

        if let incident = incidentResult.value {
            XCTAssertEqual(
                incident,
                Incident(number: 1, summary: "Cheese and pickles")
            )
        } else {
            XCTFail("No deserialized incident")
        }
    }


    func test_deserialize_address_text() {
        let json: IncidentDictionary = [
            "number": 1,
            "location": [
                "type": "text",
                "name": "Camp Fishes",
                "description": "Large dome, red flags"
            ]
        ]

        let incidentResult = incidentFromJSON(json)
        if incidentResult.failed { XCTFail("\(incidentResult.error!)") }

        if let incident = incidentResult.value {
            XCTAssertEqual(
                incident,
                Incident(
                    number: 1,
                    location: Location(
                        name: "Camp Fishes",
                        address: Address(
                            textDescription: "Large dome, red flags"
                        )
                    )
                )
            )
        } else {
            XCTFail("No deserialized incident")
        }
    }


    func test_deserialize_address_garett() {
        let json: IncidentDictionary = [
            "number": 1,
            "location": [
                "type": "garett",
                "name": "Camp Fishes",
                "concentric": 11,
                "radial_hour": 8,
                "radial_minute": 15,
                "description": "Large dome, red flags"
            ]
        ]

        let incidentResult = incidentFromJSON(json)
        if incidentResult.failed { XCTFail("\(incidentResult.error!)") }

        if let incident = incidentResult.value {
            if let _ = incident.location {
                XCTAssertEqual(
                    incident,
                    Incident(
                        number: 1,
                        location: Location(
                            name: "Camp Fishes",
                            address: RodGarettAddress(
                                concentric: ConcentricStreet.K,
                                radialHour: 8,
                                radialMinute: 15,
                                textDescription: "Large dome, red flags"
                            )
                        )
                    )
                )
            } else {
                XCTFail("No incident location")
            }
        } else {
            XCTFail("No deserialized incident")
        }
    }


    func test_deserialize_rangers() {
        let json: IncidentDictionary = [
            "number": 1,
            "ranger_handles": [ "Tool", "Splinter" ]
        ]

        let incidentResult = incidentFromJSON(json)
        if incidentResult.failed { XCTFail("\(incidentResult.error!)") }

        if let incident = incidentResult.value {
            XCTAssertEqual(
                incident,
                Incident(
                    number: 1,
                    rangers: [
                        Ranger(handle: "Tool"),
                        Ranger(handle: "Splinter")
                    ]
                )
            )
        } else {
            XCTFail("No deserialized incident")
        }
    }


    func test_deserialize_incidentTypes() {
        let json: IncidentDictionary = [
            "number": 1,
            "incident_types": ["Medical", "Fire"]
        ]

        let incidentResult = incidentFromJSON(json)
        if incidentResult.failed { XCTFail("\(incidentResult.error!)") }

        if let incident = incidentResult.value {
            XCTAssertEqual(
                incident,
                Incident(
                    number: 1,
                    incidentTypes: ["Medical", "Fire"]
                )
            )
        } else {
            XCTFail("No deserialized incident")
        }
    }


    func test_deserialize_reportEntries() {
        let json: IncidentDictionary = [
            "number": 1,
            "report_entries": [
                [
                    "author": "Hot Yogi",
                    "created": "2014-08-30T21:12:50Z",
                    "system_entry": false,
                    "text": "Need diapers\nPronto"
                ]
            ]
        ]

        let incidentResult = incidentFromJSON(json)
        if incidentResult.failed { XCTFail("\(incidentResult.error!)") }

        if let incident = incidentResult.value {
            XCTAssertEqual(
                incident,
                Incident(
                    number: 1,
                    reportEntries: [
                        ReportEntry(
                            author: Ranger(handle: "Hot Yogi"),
                            text: "Need diapers\nPronto",
                            created: DateTime.fromRFC3339String("2014-08-30T21:12:50Z"),
                            systemEntry: false
                        )
                    ]
                )
            )
        } else {
            XCTFail("No deserialized incident")
        }
    }


    func test_deserialize_created() {
        let json = [ "number": 1, "created": "2014-08-30T21:12:50Z" ]

        let incidentResult = incidentFromJSON(json)
        if incidentResult.failed { XCTFail("\(incidentResult.error!)") }

        if let incident = incidentResult.value {
            XCTAssertEqual(
                incident,
                Incident(
                    number: 1,
                    created: DateTime.fromRFC3339String("2014-08-30T21:12:50Z")
                )
            )
        } else {
            XCTFail("No deserialized incident")
        }
    }


    func test_deserialize_state() {
        let json = [ "number": 1, "state": "on_scene" ]

        let incidentResult = incidentFromJSON(json)
        if incidentResult.failed { XCTFail("\(incidentResult.error!)") }

        if let incident = incidentResult.value {
            XCTAssertEqual(
                incident,
                Incident(number: 1, state: IncidentState.OnScene)
            )
        } else {
            XCTFail("No deserialized incident")
        }
    }

}
