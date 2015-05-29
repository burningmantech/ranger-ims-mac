//
//  HTTPIncidentManagementSystem.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

class HTTPIncidentManagementSystem: IncidentManagementSystem {

    var incidentTypes: Set<String> {
        assert(false, "Unimplemented")
    }

    var rangersByHandle: [String: Ranger] {
        assert(false, "Unimplemented")
    }

    var locationsByName: [String: Location] {
        assert(false, "Unimplemented")
    }

    var incidentsByNumber: [Int: Incident] {
        assert(false, "Unimplemented")
    }


    func reload() -> Failable {
        assert(false, "Unimplemented")
    }


    func createIncident(incident: Incident) -> Failable {
        assert(false, "Unimplemented")
    }


    func updateIncident(incident: Incident) -> Failable {
        assert(false, "Unimplemented")
    }


    func reloadIncidentWithNumber(number: Int) -> Failable {
        assert(false, "Unimplemented")
    }

}
