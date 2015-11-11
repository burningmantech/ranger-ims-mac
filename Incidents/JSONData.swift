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
    guard let _number = json["number"] as? Int? else {
        throw JSONDeserializationError.InvalidDataType("number")
    }
    guard let number = _number else {
        throw JSONDeserializationError.NoIncidentNumber
    }
    guard number >= 0 else {
        throw JSONDeserializationError.NegativeIncidentNumber
    }

    let priority: IncidentPriority?
    if json["priority"] !== null {
        guard let _jsonPriority = json["priority"] as? Int? else {
            throw JSONDeserializationError.InvalidDataType("priority")
        }
        if let jsonPriority = _jsonPriority {
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
    } else {
        priority = nil
    }

    let summary: String?
    if json["summary"] !== null {
        guard let _summary = json["summary"] as? String? else {
            throw JSONDeserializationError.InvalidDataType("summary")
        }
        summary = _summary
    } else {
        summary = nil
    }

    let location: Location?
    if json["location"] !== null {
        guard let jsonLocation = json["location"] as? IncidentDictionary? else {
            throw JSONDeserializationError.InvalidDataType("location")
        }
        if let jsonLocation = jsonLocation {
            location = try locationFromJSON(jsonLocation)
        } else {
            location = nil
        }
    } else {
        location = nil
    }

    let rangers: Set<Ranger>
    if json["ranger_handles"] !== null {
        guard let handles = json["ranger_handles"] as? [String]? else {
            throw JSONDeserializationError.InvalidDataType("ranger_handles")
        }
        if let handles = handles {
            rangers = Set(handles.map({Ranger(handle: $0)}))
        } else {
            rangers = Set()
        }
    } else {
        rangers = Set()
    }

    let incidentTypes: Set<String>
    if json["incident_types"] !== null {
        guard let jsonIncidentTypes = json["incident_types"] as? [String]? else {
            throw JSONDeserializationError.InvalidDataType("incident_types")
        }
        if let jsonIncidentTypes = jsonIncidentTypes {
            incidentTypes = Set(jsonIncidentTypes)
        } else {
            incidentTypes = Set()
        }
    } else {
        incidentTypes = Set()
    }

    let reportEntries: [ReportEntry]
    if json["report_entries"] !== null {
        guard let jsonReportEntries = json["report_entries"] as? [ReportEntryDictionary]? else {
            throw JSONDeserializationError.InvalidDataType("report_entries")
        }
        if let jsonReportEntries = jsonReportEntries {
            reportEntries = try jsonReportEntries.map {
                jsonEntry in

                guard let _authorHandle = jsonEntry["author"] as? String? else {
                    throw JSONDeserializationError.InvalidDataType("author")
                }
                guard let authorHandle = _authorHandle else {
                    throw JSONDeserializationError.NoReportEntryAuthor
                }
                let author = Ranger(handle: authorHandle)
                
                guard let _jsonCreated = jsonEntry["created"] as? String? else {
                    throw JSONDeserializationError.InvalidDataType("created")
                }
                guard let jsonCreated = _jsonCreated else {
                    throw JSONDeserializationError.NoReportEntryCreated
                }
                let created = DateTime.fromRFC3339String(jsonCreated)
                
                guard let _systemEntry = jsonEntry["system_entry"] as? Bool? else {
                    throw JSONDeserializationError.InvalidDataType("system_entry")
                }
                let systemEntry: Bool
                if _systemEntry == nil {
                    systemEntry = false  // default is false
                } else {
                    systemEntry = _systemEntry!
                }

                guard let _text = jsonEntry["text"] as? String? else {
                    throw JSONDeserializationError.InvalidDataType("text")
                }
                let text: String
                if _text == nil {
                    logError("JSON for incident #\(number) has an empty report entry")
                    text = ""
                } else {
                    text = _text!
                }

                return ReportEntry(
                    author: author,
                    text: text,
                    created: created,
                    systemEntry: systemEntry
                )
            }
        } else {
            reportEntries = []
        }
    } else {
        reportEntries = []
    }

    let created: DateTime?
    if json["created"] !== null {
        guard let jsonCreated = json["created"] as? String? else {
            throw JSONDeserializationError.InvalidDataType("created")
        }
        if let jsonCreated = jsonCreated {
            created = DateTime.fromRFC3339String(jsonCreated)
        } else {
            created = nil
        }
    } else {
        created = nil
    }
    
    let state: IncidentState?
    if json["state"] !== null {
        guard let jsonState = json["state"] as? String? else {
            throw JSONDeserializationError.InvalidDataType("state")
        }
        if let jsonState = jsonState {
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



func locationFromJSON(json: LocationDictionary) throws -> Location {
    let locationType: String
    if json["type"] !== null {
        guard let _locationType = json["type"] as? String? else {
            throw JSONDeserializationError.InvalidDataType("type")
        }
        if _locationType == nil {
            locationType = "text"  // default is text
        } else {
            locationType = _locationType!
        }
    } else {
        locationType = "text"  // default is text
    }

    let textDescription: String?
    if json["description"] !== null {
        guard let _textDescription = json["description"] as? String? else {
            throw JSONDeserializationError.InvalidDataType("description")
        }
        textDescription = _textDescription
    } else {
        textDescription = nil
    }

    let locationAddress: Address?
    switch locationType {
        case "text":
            locationAddress = TextOnlyAddress(textDescription: textDescription)

        case "garett":
            let radialHour: Int?
            if json["radial_hour"] !== null {
                guard let _radialHour = json["radial_hour"] as? Int? else {
                    throw JSONDeserializationError.InvalidDataType("radial_hour")
                }
                radialHour = _radialHour
            } else {
                radialHour = nil
            }

            let radialMinute: Int?
            if json["radial_minute"] !== null {
                guard let _radialMinute = json["radial_minute"] as? Int? else {
                    throw JSONDeserializationError.InvalidDataType("radial_minute")
                }
                radialMinute = _radialMinute
            } else {
                radialMinute = nil
            }

            let concentric: ConcentricStreet?
            if json["concentric"] !== null {
                guard let jsonConcentric = json["concentric"] as? Int? else {
                    throw JSONDeserializationError.InvalidDataType("concentric")
                }
                if jsonConcentric == nil {
                    concentric = nil
                } else {
                    concentric = ConcentricStreet(rawValue: jsonConcentric!)
                }
            } else {
                concentric = nil
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
