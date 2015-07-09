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
typealias LocationDictionary = [String: String]


func incidentFromJSON(input: IncidentDictionary) throws -> Incident {
    let json = JSON(input)

    guard let jsonNumber = json["number"].int else {
        throw JSONDeserializationError.NoIncidentNumber
    }

    if jsonNumber < 0 {
        throw JSONDeserializationError.NegativeIncidentNumber
    }
    let number = jsonNumber

    let priority: IncidentPriority?
    if let jsonPriority = json["priority"].int {
        switch jsonPriority {
            case 1, 2: priority = IncidentPriority.High
            case 3   : priority = IncidentPriority.Normal
            case 4, 5: priority = IncidentPriority.Low

            default:
                throw JSONDeserializationError.UnknownPriority(jsonPriority)
        }
    } else {
        priority = nil
    }

    let summary = json["summary"].string

    let location = try _locationFromJSON(json["location"])

    var rangers: Set<Ranger> = Set()
    for (_, jsonHandle) in json["ranger_handles"] {
        if let handle = jsonHandle.string {
            rangers.insert(Ranger(handle: handle))
        }
    }

    var incidentTypes : Set<String> = Set()
    for (_, jsonIncidentType) in json["incident_types"] {
        incidentTypes.insert(jsonIncidentType.string!)
    }

    var reportEntries: [ReportEntry] = []
    for (_, jsonEntry) in json["report_entries"] {
        guard let jsonAuthor = jsonEntry["author"].string else {
            throw JSONDeserializationError.NoReportEntryAuthor
        }
        let author = Ranger(handle: jsonAuthor)

        guard let jsonEntryCreated = jsonEntry["created"].string else {
            throw JSONDeserializationError.NoReportEntryCreated
        }
        let entryCreated = DateTime.fromRFC3339String(jsonEntryCreated)

        let systemEntry: Bool
        if let jsonSystemEntry = jsonEntry["system_entry"].bool {
            systemEntry = jsonSystemEntry
        } else {
            systemEntry = false  // default
        }

        guard let jsonText = jsonEntry["text"].string else {
            logError("JSON for incident #\(number) has an empty report entry")
            continue
        }
        let text = jsonText

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
                throw JSONDeserializationError.UnknownIncidentState(jsonState)
        }
    } else {
        state = nil
    }

    return Incident(
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
}



func locationFromJSON(input: LocationDictionary) throws -> Location {
    return try _locationFromJSON(JSON(input))
}



func _locationFromJSON(json: JSON) throws -> Location {

    let locationType: String
    if let _locationType = json["type"].string {
        locationType = _locationType
    } else {
        locationType = "text"  // default is text
    }

    let locationAddress: Address?
    switch locationType {
    case "text":
        locationAddress = TextOnlyAddress(
            textDescription: json["description"].string
        )
    case "garett":
        let concentric: ConcentricStreet?
        if let jsonConcentric = json["concentric"].int {
            concentric = ConcentricStreet(rawValue: jsonConcentric)
        } else {
            concentric = nil
        }

        locationAddress = RodGarettAddress(
            concentric     : concentric,
            radialHour     : json["radial_hour"  ].int,
            radialMinute   : json["radial_minute"].int,
            textDescription: json["description"  ].string
        )
    default:
        throw JSONDeserializationError.UnknownLocationType(locationType)
    }

    return Location(
        name: json["name"].string,
        address: locationAddress
    )

}


enum JSONDeserializationError: ErrorType {
    case NoIncidentNumber
    case NegativeIncidentNumber
    case UnknownPriority(Int)
    case UnknownLocationType(String)
    case NoReportEntryAuthor
    case NoReportEntryCreated
    case UnknownIncidentState(String)
}
