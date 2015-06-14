//
//  InMemoryIncidentManagementSystem.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Foundation



class InMemoryIncidentManagementSystem: NSObject, IncidentManagementSystem {

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

    weak var delegate: IncidentManagementSystemDelegate?


    func reload() {}


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
        guard let number = incident.number else {
            return Failable(Error("Incident number may not be nil"))
        }

        _incidentsByNumber[number] = incident
        return Failable.Success
    }


//    func reloadIncidentWithNumber(number: Int) -> Failable {
//        guard let incident = _incidentsByNumber[number] else {
//            return Failable(Error("No such incident"))
//        }
//        return Failable.Success
//    }


    // Extensions to IncidentManagementSystem for inserting data

    func addIncidentType(incidentType: String) {
        _incidentTypes.insert(incidentType)
    }


    func addRanger(ranger: Ranger) {
        _rangersByHandle[ranger.handle] = ranger
    }

}
