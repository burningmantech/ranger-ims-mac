//
//  InMemoryIncidentManagementSystem.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

class InMemoryIncidentManagementSystem: IncidentManagementSystem {

    var incidentTypes: Set<String> {
        return _incidentTypes
    }
    private var _incidentTypes: Set<String> = Set()

    var rangersByHandle: [String: Ranger] {
        return _rangersByHandle
    }
    private var _rangersByHandle: [String: Ranger] = [:]

    var locationsByName: [String: Location] {
        var locationsByName: [String: Location] = [:]

        for incident in incidentsByNumber.values {
            if let location = incident.location {
                if let name = location.name {
                    locationsByName[name] = location
                }
            }
        }

        return locationsByName
    }

    var incidentsByNumber: [Int: Incident] {
        return _incidentsByNumber
    }
    private var _incidentsByNumber: [Int: Incident] = [:]


    func reload() -> Failable {
        return Failable.Success
    }


    func createIncident(incident: Incident) -> Failable {
        if incident.number != nil {
            return Failable(Error("Incident number must be nil"))
        }

        let number = incidentsByNumber.count + 1

        let newIncident = Incident(
            number       : number,
            priority     : incident.priority,
            summary      : incident.summary,
            location     : incident.location,
            rangers      : incident.rangers,
            incidentTypes: incident.incidentTypes,
            reportEntries: incident.reportEntries,
            created      : incident.created,
            state        : incident.state
        )

        _incidentsByNumber[number] = newIncident

        return Failable.Success
    }


    func updateIncident(incident: Incident) -> Failable {
        if let number = incident.number {
            _incidentsByNumber[number] = incident
            return Failable.Success
        }
        else {
            return Failable(Error("Incident number may not be nil"))
        }
    }


    func reloadIncidentWithNumber(number: Int) -> Failable {
        if let incident = _incidentsByNumber[number] {
            return Failable.Success
        } else {
            return Failable(Error("No such incident"))
        }
    }


    // Extensions to IncidentManagementSystem for inserting data

    func addIncidentType(incidentType: String) {
        _incidentTypes.insert(incidentType)
    }


    func addRanger(ranger: Ranger) {
        _rangersByHandle[ranger.handle] = ranger
    }

}
