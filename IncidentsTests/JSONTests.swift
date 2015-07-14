//
//  JSONTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import XCTest



class IncidentJSONDeserializationTests: XCTestCase {
    
    func test_deserialize_noNumber() {
        let json = IncidentDictionary()

        do { try incidentFromJSON(json) } catch { return }

        XCTFail("Parser should have failed")
    }


    func test_deserialize_number() throws {
        let json = [ "number": 1 ]

        let incident = try incidentFromJSON(json)

        XCTAssertEqual(incident, Incident(number: 1))
    }


    func test_deserialize_negativeNumber() {
        let json = [ "number": -1 ]

        do { try incidentFromJSON(json) } catch { return }

        XCTFail("Parser should have failed")
    }


    func test_deserialize_priority() throws {
        for (jsonPriority, expectedPriority) in [
            1: IncidentPriority.High,
            2: IncidentPriority.High,
            3: IncidentPriority.Normal,
            4: IncidentPriority.Low,
            5: IncidentPriority.Low,
        ] {
            let json = [ "number": 1, "priority": jsonPriority ]

            let incident = try incidentFromJSON(json)

            XCTAssertEqual(
                incident,
                Incident(number: 1, priority: expectedPriority)
            )
        }
    }


    func test_deserialize_summary() throws {
        let json = [ "number": 1, "summary": "Cheese and pickles" ]

        let incident = try incidentFromJSON(json)

        XCTAssertEqual(
            incident,
            Incident(number: 1, summary: "Cheese and pickles")
        )
    }


    func test_deserialize_address_text() throws {
        let json: IncidentDictionary = [
            "number": 1,
            "location": [
                "type": "text",
                "name": "Camp Fishes",
                "description": "Large dome, red flags"
            ]
        ]

        let incident = try incidentFromJSON(json)

        XCTAssertEqual(
            incident,
            Incident(
                number: 1,
                location: Location(
                    name: "Camp Fishes",
                    address: TextOnlyAddress(
                        textDescription: "Large dome, red flags"
                    )
                )
            )
        )
    }


    func test_deserialize_address_garett() throws {
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

        let incident = try incidentFromJSON(json)

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
    }


    func test_deserialize_rangers() throws {
        let json: IncidentDictionary = [
            "number": 1,
            "ranger_handles": [ "Tool", "Splinter" ]
        ]

        let incident = try incidentFromJSON(json)

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
    }


    func test_deserialize_incidentTypes() throws {
        let json: IncidentDictionary = [
            "number": 1,
            "incident_types": ["Medical", "Fire"]
        ]

        let incident = try incidentFromJSON(json)

        XCTAssertEqual(
            incident,
            Incident(
                number: 1,
                incidentTypes: ["Medical", "Fire"]
            )
        )
    }


    func test_deserialize_reportEntries() throws {
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

        let incident = try incidentFromJSON(json)

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
    }


    func test_deserialize_created() throws {
        let json = [ "number": 1, "created": "2014-08-30T21:12:50Z" ]

        let incident = try incidentFromJSON(json)

        XCTAssertEqual(
            incident,
            Incident(
                number: 1,
                created: DateTime.fromRFC3339String("2014-08-30T21:12:50Z")
            )
        )
    }


    func test_deserialize_state() throws {
        let json = [ "number": 1, "state": "on_scene" ]

        let incident = try incidentFromJSON(json)

        XCTAssertEqual(
            incident,
            Incident(number: 1, state: IncidentState.OnScene)
        )
    }

}



class IncidentJSONSerializationTests: XCTestCase {
    
    func test_serialize_noNumber() throws {
        let incident = Incident(number: nil)
        let json = try incidentAsJSON(incident)
        let expected: NSDictionary = [:]
        
        XCTAssertTrue(expected.isEqualToDictionary(json))
    }
    
    
    func test_serialize_number() throws {
        let incident = Incident(number: 1)
        let json = try incidentAsJSON(incident)
        let expected: NSDictionary = [
            "number": 1
        ]
        
        XCTAssertTrue(expected.isEqualToDictionary(json))
    }
    
    
    func test_serialize_negativeNumber() throws {
        let incident = Incident(number: -1)
        let json = try incidentAsJSON(incident)
        let expected: NSDictionary = [
            "number": -1
        ]
        
        XCTAssertTrue(expected.isEqualToDictionary(json))
    }
    
    
    func test_serialize_priority() throws {
        for (priority, jsonPriority) in [
            IncidentPriority.High  : 1,
            IncidentPriority.Normal: 3,
            IncidentPriority.Low   : 5,
        ] {
            let incident = Incident(number: 1, priority: priority)
            let json = try incidentAsJSON(incident)
            let expected: NSDictionary = [
                "number": 1,
                "priority": jsonPriority
            ]

            XCTAssertTrue(expected.isEqualToDictionary(json))
        }
    }
    
    
    func test_serialize_summary() throws {
        let incident = Incident(number: 1, summary: "Cheese and pickles")
        let json = try incidentAsJSON(incident)
        let expected: NSDictionary = [
            "number": 1,
            "summary": "Cheese and pickles"
        ]
        
        XCTAssertTrue(expected.isEqualToDictionary(json))
    }
    
    
    func test_serialize_address_nil() throws {
        let incident = Incident(
            number: 1,
            location: Location(name: "Camp Fishes")
        )
        let json = try incidentAsJSON(incident)
        let expected: NSDictionary = [
            "number": 1,
            "location": [
                "type": "text",
                "name": "Camp Fishes",
            ]
        ]
        
        XCTAssertTrue(expected.isEqualToDictionary(json))
    }
    
    
    func test_serialize_address_text() throws {
        let incident = Incident(
            number: 1,
            location: Location(
                name: "Camp Fishes",
                address: TextOnlyAddress(
                    textDescription: "Large dome, red flags"
                )
            )
        )
        let json = try incidentAsJSON(incident)
        let expected: NSDictionary = [
            "number": 1,
            "location": [
                "type": "text",
                "name": "Camp Fishes",
                "description": "Large dome, red flags"
            ]
        ]
        
        XCTAssertTrue(expected.isEqualToDictionary(json))
    }
    
    
    func test_serialize_address_garett() throws {
        let incident = Incident(
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
        let json = try incidentAsJSON(incident)
        let expected: NSDictionary = [
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
        
        XCTAssertTrue(expected.isEqualToDictionary(json))
    }
    
    
    func test_serialize_rangers() throws {
        let incident = Incident(
            number: 1,
            rangers: [
                Ranger(handle: "Tool"),
                Ranger(handle: "Splinter")
            ]
        )
        let json = try incidentAsJSON(incident)
        let expected: NSDictionary = [
            "number": 1,
            "ranger_handles": [ "Splinter", "Tool" ]  // Should be sorted
        ]

        XCTAssertTrue(expected.isEqualToDictionary(json))
    }
    
    
    func test_serialize_incidentTypes() throws {
        let incident = Incident(
            number: 1,
            incidentTypes: ["Medical", "Fire"]
        )
        let json = try incidentAsJSON(incident)
        let expected: NSDictionary = [
            "number": 1,
            "incident_types": ["Fire", "Medical"]  // Should be sorted
        ]

        XCTAssertTrue(expected.isEqualToDictionary(json))
    }
    
    
    func test_serialize_reportEntries() throws {
        let incident = Incident(
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
        let json = try incidentAsJSON(incident)
        let expected: NSDictionary = [
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

        XCTAssertTrue(expected.isEqualToDictionary(json))
    }
    
    
    func test_serialize_created() throws {
        let incident = Incident(
            number: 1,
            created: DateTime.fromRFC3339String("2014-08-30T21:12:50Z")
        )
        let json = try incidentAsJSON(incident)
        let expected: NSDictionary = [
            "number": 1,
            "created": "2014-08-30T21:12:50Z"
        ]

        XCTAssertTrue(expected.isEqualToDictionary(json))
    }
    
    
    func test_deserialize_state() throws {
        let incident = Incident(
            number: 1,
            state: IncidentState.OnScene
        )
        let json = try incidentAsJSON(incident)
        let expected: NSDictionary = [
            "number": 1,
            "state": "on_scene"
        ]

        XCTAssertTrue(expected.isEqualToDictionary(json))
    }

}
