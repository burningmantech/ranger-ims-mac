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

import Foundation

typealias IncidentDictionary    = [String: AnyObject]
typealias LocationDictionary    = [String: AnyObject]
typealias ReportEntryDictionary = [String: AnyObject]

let null = NSNull()


func incidentFromJSON(json: IncidentDictionary) throws -> Incident {
    guard json.indexForKey("number") != nil else {
        throw JSONDeserializationError.NoIncidentNumber
    }
    guard let number = json["number"] as? Int else {
        throw JSONDeserializationError.InvalidDataType("number")
    }
    guard number >= 0 else {
        throw JSONDeserializationError.NegativeIncidentNumber
    }

    let priority: IncidentPriority?
    if json.indexForKey("priority") == nil || json["priority"] === null {
        priority = nil
    } else {
        guard let jsonPriority = json["priority"] as? Int else {
            throw JSONDeserializationError.InvalidDataType("priority")
        }
        switch jsonPriority {
            case 1, 2: priority = IncidentPriority.High
            case 3   : priority = IncidentPriority.Normal
            case 4, 5: priority = IncidentPriority.Low

            default:
                throw JSONDeserializationError.UnknownPriority(jsonPriority)
        }
    }

    let summary: String?
    if json.indexForKey("summary") == nil || json["summary"] === null {
        summary = nil
    } else {
        guard let _summary = json["summary"] as? String else {
            throw JSONDeserializationError.InvalidDataType("summary")
        }
        summary = _summary
    }

    let location: Location?
    if json.indexForKey("location") == nil || json["location"] === null {
        location = nil
    } else {
        guard let jsonLocation = json["location"] as? IncidentDictionary else {
            throw JSONDeserializationError.InvalidDataType("location")
        }
        location = try locationFromJSON(jsonLocation)
    }

    let rangers: Set<Ranger>
    if json.indexForKey("ranger_handles") == nil || json["ranger_handles"] === null {
        rangers = Set()
    } else {
        guard let handles = json["ranger_handles"] as? [String] else {
            throw JSONDeserializationError.InvalidDataType("ranger_handles")
        }
        rangers = Set(handles.map({Ranger(handle: $0)}))
    }

    let incidentTypes: Set<String>
    if json.indexForKey("incident_types") == nil || json["incident_types"] === null {
        incidentTypes = Set()
    } else {
        guard let jsonIncidentTypes = json["incident_types"] as? [String] else {
            throw JSONDeserializationError.InvalidDataType("incident_types")
        }
        incidentTypes = Set(jsonIncidentTypes)
    }

    let reportEntries: [ReportEntry]
    if json.indexForKey("report_entries") == nil || json["report_entries"] === null {
        reportEntries = []
    } else {
        guard let jsonReportEntries = json["report_entries"] as? [ReportEntryDictionary] else {
            throw JSONDeserializationError.InvalidDataType("report_entries")
        }
        reportEntries = try jsonReportEntries.map {
            jsonEntry in

            guard jsonEntry.indexForKey("author") != nil else {
                throw JSONDeserializationError.NoReportEntryAuthor
            }
            guard let authorHandle = jsonEntry["author"] as? String else {
                throw JSONDeserializationError.InvalidDataType("author")
            }
            let author = Ranger(handle: authorHandle)
            
            guard jsonEntry.indexForKey("created") != nil else {
                throw JSONDeserializationError.NoReportEntryCreated
            }
            guard let jsonCreated = jsonEntry["created"] as? String else {
                throw JSONDeserializationError.InvalidDataType("created")
            }
            let created = DateTime.fromRFC3339String(jsonCreated)
            
            let systemEntry: Bool
            if jsonEntry.indexForKey("system_entry") == nil || jsonEntry["system_entry"] === null {
                systemEntry = false  // default is false
            } else {
                guard let _systemEntry = jsonEntry["system_entry"] as? Bool else {
                    throw JSONDeserializationError.InvalidDataType("system_entry")
                }
                systemEntry = _systemEntry
            }

            let text: String
            if jsonEntry.indexForKey("text") == nil || jsonEntry["text"] === null {
                logError("JSON for incident #\(number) has a report entry with no text")
                text = ""
            } else {
                guard let _text = jsonEntry["text"] as? String else {
                    throw JSONDeserializationError.InvalidDataType("text")
                }
                text = _text
            }

            return ReportEntry(
                author: author,
                text: text,
                created: created,
                systemEntry: systemEntry
            )
        }
    }

    let created: DateTime?
    if json.indexForKey("created") == nil || json["created"] === null {
        created = nil
    } else {
        guard let jsonCreated = json["created"] as? String else {
            throw JSONDeserializationError.InvalidDataType("created")
        }
        created = DateTime.fromRFC3339String(jsonCreated)
    }
    
    let state: IncidentState?
    if json.indexForKey("state") == nil || json["state"] === null {
        state = nil
    } else {
        guard let jsonState = json["state"] as? String else {
            throw JSONDeserializationError.InvalidDataType("state")
        }
        switch jsonState {
            case "new"       : state = IncidentState.New
            case "on_hold"   : state = IncidentState.OnHold
            case "dispatched": state = IncidentState.Dispatched
            case "on_scene"  : state = IncidentState.OnScene
            case "closed"    : state = IncidentState.Closed
            default:
                throw JSONDeserializationError.UnknownIncidentState(jsonState)
        }
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



func locationFromJSON(json: LocationDictionary) throws -> Location {
    let locationType: String
    if json.indexForKey("type") == nil || json["type"] === null {
        locationType = "text"  // default is text
    } else {
        guard let _locationType = json["type"] as? String else {
            throw JSONDeserializationError.InvalidDataType("type")
        }
        locationType = _locationType
    }

    let textDescription: String?
    if json.indexForKey("description") == nil || json["description"] === null {
        textDescription = nil
    } else {
        guard let _textDescription = json["description"] as? String else {
            throw JSONDeserializationError.InvalidDataType("description")
        }
        textDescription = _textDescription
    }

    let locationAddress: Address?
    switch locationType {
        case "text":
            locationAddress = TextOnlyAddress(textDescription: textDescription)

        case "garett":
            let radialHour: Int?
            if json.indexForKey("radial_hour") == nil || json["radial_hour"] === null {
                radialHour = nil
            } else {
                guard let _radialHour = json["radial_hour"] as? Int else {
                    throw JSONDeserializationError.InvalidDataType("radial_hour")
                }
                radialHour = _radialHour
            }

            let radialMinute: Int?
            if json.indexForKey("radial_minute") == nil || json["radial_minute"] === null {
                radialMinute = nil
            } else {
                guard let _radialMinute = json["radial_minute"] as? Int else {
                    throw JSONDeserializationError.InvalidDataType("radial_minute")
                }
                radialMinute = _radialMinute
            }

            let concentric: ConcentricStreet?
            if json.indexForKey("concentric") == nil || json["concentric"] === null {
                concentric = nil
            } else {
                guard let jsonConcentric = json["concentric"] as? Int else {
                    throw JSONDeserializationError.InvalidDataType("concentric")
                }
                concentric = ConcentricStreet(rawValue: jsonConcentric)
            }

            locationAddress = RodGarettAddress(
                concentric     : concentric,
                radialHour     : radialHour,
                radialMinute   : radialMinute,
                textDescription: textDescription
            )

        default:
            throw JSONDeserializationError.UnknownLocationType(locationType)
    }

    let name: String?
    if json["name"] !== null {
        guard let _name = json["name"] as? String? else {
            throw JSONDeserializationError.InvalidDataType("name")
        }
        name = _name
    } else {
        name = nil
    }
    
    return Location(name: name, address: locationAddress)
}



func incidentAsJSON(incident: Incident) throws -> IncidentDictionary {
    var json: IncidentDictionary = [:]
    
    if let number        = incident.number        { json["number"        ] = number                       }
    if let summary       = incident.summary       { json["summary"       ] = summary                      }
    if let location      = incident.location      { json["location"      ] = try locationAsJSON(location) }
    if let incidentTypes = incident.incidentTypes { json["incident_types"] = incidentTypes.sort()         }
    if let created       = incident.created       { json["created"       ] = created.asRFC3339String()    }

    if let priority = incident.priority {
        switch priority {
            case .High  : json["priority"] = 1
            case .Normal: json["priority"] = 3
            case .Low   : json["priority"] = 5
        }
    }

    if let state = incident.state {
        switch state {
            case IncidentState.New       : json["state"] = "new"
            case IncidentState.OnHold    : json["state"] = "on_hold"
            case IncidentState.Dispatched: json["state"] = "dispatched"
            case IncidentState.OnScene   : json["state"] = "on_scene"
            case IncidentState.Closed    : json["state"] = "closed"
        }
    }

    if let rangers = incident.rangers {
        var handles: [String] = []

        for ranger in rangers { handles.append(ranger.handle) }

        json["ranger_handles"] = handles.sort()
    }

    if let reportEntries = incident.reportEntries {
        var jsonEntries: [ReportEntryDictionary] = []

        for reportEntry in reportEntries {
            var jsonEntry: ReportEntryDictionary = [:]

            if let author = reportEntry.author { jsonEntry["author" ] = author.handle }

            jsonEntry["created"     ] = reportEntry.created.asRFC3339String()
            jsonEntry["system_entry"] = reportEntry.systemEntry
            jsonEntry["text"        ] = reportEntry.text

            jsonEntries.append(jsonEntry)
        }

        json["report_entries"] = jsonEntries
    }

    return json
}


func locationAsJSON(location: Location) throws -> LocationDictionary {
    var json: LocationDictionary = [:]
    
    if let name = location.name { json["name"] = name }

    if location.address == nil {
        json["type"] = "text"
    }
    else if let address = location.address as? TextOnlyAddress {
        if let description = address.textDescription {
            json["type"       ] = "text"
            json["description"] = description
        }
    }
    else if let address = location.address as? RodGarettAddress {
        json["type"] = "garett"

        if let concentric = address.concentric {
            json["concentric"] = concentric.rawValue
        }
        if let radialHour = address.radialHour {
            json["radial_hour"] = radialHour
        }
        if let radialMinute = address.radialMinute {
            json["radial_minute"] = radialMinute
        }
        if let description = address.textDescription {
            json["description"] = description
        }
    }
    else {
        throw JSONSerializationError.UnknownAddressType(location.address!)
    }

    return json
}



enum JSONDeserializationError: ErrorType {
    case InvalidDataType(String)
    case NoIncidentNumber
    case NegativeIncidentNumber
    case UnknownPriority(Int)
    case UnknownLocationType(String)
    case NoReportEntryAuthor
    case NoReportEntryCreated
    case UnknownIncidentState(String)
}



enum JSONSerializationError: ErrorType {
    case UnknownAddressType(Address)
}
