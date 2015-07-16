//
//  Incident.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

enum IncidentState: Int, CustomStringConvertible, Comparable {
    case New, OnHold, Dispatched, OnScene, Closed

    var description: String {
        switch self {
            case .New       : return "new"
            case .OnHold    : return "on hold"
            case .Dispatched: return "dispatched"
            case .OnScene   : return "on scene"
            case .Closed    : return "closed"
        }
    }

}


func ==(lhs: IncidentState, rhs: IncidentState) -> Bool {
    return lhs.rawValue == rhs.rawValue
}


func <(lhs: IncidentState, rhs: IncidentState) -> Bool {
    return lhs.rawValue < rhs.rawValue
}



enum IncidentPriority: Int, CustomStringConvertible {
    case High   = 1
    case Normal = 3
    case Low    = 5

    var description: String {
        switch self {
            case .High  : return "⬆︎"
            case .Normal: return "●"
            case .Low   : return "⬇︎"
        }
    }
}


func ==(lhs: IncidentPriority, rhs: IncidentPriority) -> Bool {
    return lhs.rawValue == rhs.rawValue
}


func <(lhs: IncidentPriority, rhs: IncidentPriority) -> Bool {
    return lhs.rawValue < rhs.rawValue
}



struct Incident: CustomStringConvertible, Hashable {
    var number: Int? {
        get { return _number }
        set(number) {
            assert(_number == nil)
            _number = number
        }
    }
    private var _number: Int?

    var priority     : IncidentPriority?
    var summary      : String?
    var location     : Location?
    var rangers      : Set<Ranger>?
    var incidentTypes: Set<String>?
    var reportEntries: [ReportEntry]?
    var created      : DateTime?
    var state        : IncidentState?
    
    var rangersAsText: String {
        guard let rangers = self.rangers else {
            return ""
        }

        var handles: [String] = []
        for ranger in rangers {
            handles.append(ranger.handle)
        }
        return ", ".join(handles.sort())
    }

    var incidentTypesAsText: String {
        guard let incidentTypes = self.incidentTypes else {
            return ""
        }
        return ", ".join(incidentTypes.sort())
    }

    var summaryAsText: String {
        if let summary = self.summary {
            if summary != "" {
                return summary
            }
        }
        if let reportEntries = self.reportEntries {
            for reportEntry in reportEntries {
                var summary: String? = nil
                reportEntry.text.enumerateLines({
                    (line: String, inout stop: Bool) in
                    if line != "" {
                        summary = line
                        stop = true
                    }
                })
                if let s = summary {
                    return s
                }
            }
        }
        return ""
    }

    var hashValue: Int {
        var hash = 0

        if let h = number?  .hashValue { hash ^= h }
        if let h = priority?.hashValue { hash ^= h }
        if let h = summary? .hashValue { hash ^= h }
        if let h = location?.hashValue { hash ^= h }
        if let h = created? .hashValue { hash ^= h }
        if let h = state?   .hashValue { hash ^= h }

        if rangers       != nil { for x in rangers!       { hash ^= x.hashValue } }
        if incidentTypes != nil { for x in incidentTypes! { hash ^= x.hashValue } }
        if reportEntries != nil { for x in reportEntries! { hash ^= x.hashValue } }

        return hash
    }

    var description: String {
        var d = "Incident"
        if number != nil {
            d += " #\(number!)"
        }
        if state != nil {
            d += " (\(state!))"
        }
        if summary != nil {
            d += ": \(summary!)"
        }
        return d
    }
    
    
    init(
        number       : Int?,
        priority     : IncidentPriority? = nil,
        summary      : String?           = nil,
        location     : Location?         = nil,
        rangers      : Set<Ranger>?      = nil,
        incidentTypes: Set<String>?      = nil,
        reportEntries: [ReportEntry]?    = nil,
        created      : DateTime?         = nil,
        state        : IncidentState?    = nil
    ) {
        self.number        = number
        self.priority      = priority
        self.summary       = summary
        self.location      = location
        self.rangers       = rangers
        self.incidentTypes = incidentTypes
        self.reportEntries = reportEntries
        self.created       = created
        self.state         = state
    }


    func diffFrom(other: Incident?) -> Incident {
        guard let other = other else {
            // other is nill; everything is different
            return self
        }
        
        let number   = (self.number   == other.number  ) ? nil : self.number
        let priority = (self.priority == other.priority) ? nil : self.priority
        let summary  = (self.summary  == other.summary ) ? nil : self.summary
        let created  = (self.created  == other.created ) ? nil : self.created
        let state    = (self.state    == other.state   ) ? nil : self.state

        let location      = optionalsEqual     (self.location,      other.location     ) ? nil : self.location
        let rangers       = optionalSetEquals  (self.rangers,       other.rangers      ) ? nil : self.rangers
        let incidentTypes = optionalSetEquals  (self.incidentTypes, other.incidentTypes) ? nil : self.incidentTypes
        let reportEntries = optionalArrayEquals(self.reportEntries, other.reportEntries) ? nil : self.reportEntries

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


    func applyDiff(diff: Incident) -> Incident {
        var newIncident = self
        
        if diff.priority      != nil { newIncident.priority      = diff.priority      }
        if diff.summary       != nil { newIncident.summary       = diff.summary       }
        if diff.location      != nil { newIncident.location      = diff.location      }
        if diff.rangers       != nil { newIncident.rangers       = diff.rangers       }
        if diff.incidentTypes != nil { newIncident.incidentTypes = diff.incidentTypes }
        if diff.reportEntries != nil { newIncident.reportEntries = diff.reportEntries }
        if diff.created       != nil { newIncident.created       = diff.created       }
        if diff.state         != nil { newIncident.state         = diff.state         }
        
        return newIncident
    }

}


func ==(lhs: Incident, rhs: Incident) -> Bool {
    if !(
        lhs.number   == rhs.number   &&
        lhs.priority == rhs.priority &&
        lhs.summary  == rhs.summary  &&
        lhs.created  == rhs.created  &&
        lhs.state    == rhs.state
    ) {
        return false
    }

    if !optionalsEqual(lhs.location, rhs.location) {
        return false
    }

    if !(
        optionalSetEquals  (lhs.rangers      , rhs.rangers      ) &&
        optionalSetEquals  (lhs.incidentTypes, rhs.incidentTypes) &&
        optionalArrayEquals(lhs.reportEntries, rhs.reportEntries)
    ) {
        return false
    }

    return true
}
