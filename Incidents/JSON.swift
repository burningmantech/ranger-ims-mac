//
//  JSON.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

// JSON schema:
/**********************************************************************
{
    "number": 101,                              // int >= 0
    "priority": 3,                              // int {1,3,5}
    "summary": "Diapers, please",               // one line
    "location": {
        "name": "Camp Fishes",                  // one line
        "type": "garett",                       // {"text","garett"}
        "concentric": 11,                       // int >= 0 (garett)
        "radial_hour": 8,                       // int 2-10 (garett)
        "radial_minute": 15,                    // int 0-59 (garett)
        "description: "Large dome, red flags"   // one line (garett,text)
    }
    "ranger_handles": [
        "Santa Cruz"                            // handle in Clubhouse
    ],
    "incident_types": [
        "Law Enforcement"                       // from list in config
    ],
    "report_entries": [
        {
            "author": "Hot Yogi",               // handle in Clubhouse
            "created": "2014-08-30T21:12:50Z",  // RFC 3339, Zulu
            "system_entry": false,              // boolean
            "text": "Need diapers\nPronto"      // multi-line
        }
    ],
    "timestamp": "2014-08-30T21:38:11Z"         // RFC 3339, Zulu
    "state": "closed",                          // from JSON.state_*
}
**********************************************************************/

typealias IncidentDictionary = [String: AnyObject]



func incidentFromJSON(input: IncidentDictionary) -> FailableOf<Incident> {
    let json = JSON(input)

    let number: Int
    if let jsonNumber = json["number"].int {
        if jsonNumber < 0 {
            return FailableOf(Error("Incident number may not be negative"))
        }
        number = jsonNumber
    } else {
        return FailableOf(Error("Incident number is required"))
    }

    let priority: IncidentPriority?
    if let jsonPriority = json["priority"].int {
        switch jsonPriority {
            case 1, 2: priority = IncidentPriority.High
            case 3   : priority = IncidentPriority.Medium
            case 4, 5: priority = IncidentPriority.Low

            default:
                return FailableOf(Error("Unknown priority: \(jsonPriority)"))
        }
    } else {
        priority = nil
    }

    let summary = json["summary"].string

    let locationType: String
    if let _locationType = json["location"]["type"].string {
        locationType = _locationType
    } else {
        locationType = "text"  // default is text
    }

    let locationAddress: Address?
    switch locationType {
        case "text":
            locationAddress = TextOnlyAddress(
                textDescription: json["location"]["description"].string
            )
        case "garett":
            let concentric: ConcentricStreet?
            if let jsonConcentric = json["location"]["concentric"].int {
                concentric = ConcentricStreet(rawValue: jsonConcentric)
            } else {
                concentric = nil
            }

            locationAddress = RodGarettAddress(
                concentric     : concentric,
                radialHour     : json["location"]["radial_hour"  ].int,
                radialMinute   : json["location"]["radial_minute"].int,
                textDescription: json["location"]["description"  ].string
            )
        default:
            return FailableOf(Error("Unknown location type: \(locationType)"))
    }

    let location = Location(
        name: json["location"]["name"].string,
        address: locationAddress
    )

    var rangers: Set<Ranger> = Set()
    for (index, jsonHandle) in json["ranger_handles"] {
        if let handle = jsonHandle.string {
            rangers.insert(Ranger(handle: handle))
        }
    }

    var incidentTypes : Set<String> = Set()
    for (index, jsonIncidentType) in json["incident_types"] {
        incidentTypes.insert(jsonIncidentType.string!)
    }

    var reportEntries: [ReportEntry] = []
    for (index, jsonEntry) in json["report_entries"] {
        let author: Ranger
        if let jsonAuthor = jsonEntry["author"].string {
            author = Ranger(handle: jsonAuthor)
        } else {
            return FailableOf(Error("Report entry author is required"))
        }

        let entryCreated: DateTime
        if let jsonEntryCreated = jsonEntry["created"].string {
            entryCreated = DateTime.fromRFC3339String(jsonEntryCreated)
        } else {
            return FailableOf(Error("Report entry created is required"))
        }

        let systemEntry: Bool
        if let jsonSystemEntry = jsonEntry["system_entry"].bool {
            systemEntry = jsonSystemEntry
        } else {
            systemEntry = false  // default
        }

        let text: String
        if let jsonText = jsonEntry["text"].string {
            text = jsonText
        } else {
            logError("JSON for incident #\(number) has an empty report entry")
            continue
        }

        reportEntries.append(
            ReportEntry(
                author: author,
                text: text,
                created: entryCreated,
                systemEntry: systemEntry
            )
        )
    }

    let created: DateTime?
    if let jsonCreated = json["created"].string {
        created = DateTime.fromRFC3339String(jsonCreated)
    } else {
        created = nil
    }

    let state: IncidentState?
    if let jsonState = json["state"].string {
        switch jsonState {
            case "new"       : state = IncidentState.New
            case "on_hold"   : state = IncidentState.OnHold
            case "dispatched": state = IncidentState.Dispatched
            case "on_scene"  : state = IncidentState.OnScene
            case "closed"    : state = IncidentState.Closed
            default:
                return FailableOf(Error("Unknown incident state: \(jsonState)"))
        }
    } else {
        state = nil
    }

    let incident = Incident(
        number: number,
        priority: priority,
        summary: summary,
        location: location,
        rangers: rangers,
        incidentTypes: incidentTypes,
        reportEntries: reportEntries,
        created: created,
        state: state
    )

    return FailableOf(incident)
}
