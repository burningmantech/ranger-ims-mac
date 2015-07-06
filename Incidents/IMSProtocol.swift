//
//  IMSProtocol.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

protocol IncidentManagementSystem {
    var incidentTypes    : Set<String>        { get }
    var rangersByHandle  : [String: Ranger  ] { get }
    var locationsByName  : [String: Location] { get }
    var incidentsByNumber: [Int   : Incident] { get }

    weak var delegate: IncidentManagementSystemDelegate? { get set }

    func reload()

    func createIncident(Incident) throws
    func updateIncident(Incident) throws
//    func reloadIncidentWithNumber(Int) throws
}



protocol IncidentManagementSystemDelegate: class {
    func incidentDidUpdate(ims: IncidentManagementSystem, incident: Incident)
}



enum IMSError: ErrorType {
    case IncidentNumberNil
    case IncidentNumberNotNil(Int)
}
