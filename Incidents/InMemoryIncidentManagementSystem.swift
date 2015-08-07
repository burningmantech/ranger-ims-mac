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


    func createIncident(incident: Incident, callback: IncidentCreatedCallback?) throws {
        guard incident.number == nil else {
            throw IMSError.IncidentNumberNotNil(incident.number!)
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

        if let callback = callback { callback(number: number) }
    }


    func updateIncident(incident: Incident) throws {
        guard let number = incident.number else {
            throw IMSError.IncidentNumberNil
        }

        _incidentsByNumber[number] = incident
    }


    func reloadIncidentWithNumber(number: Int) throws {
        guard _incidentsByNumber[number] != nil else {
            throw IMSError.NoSuchIncident(number)
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
