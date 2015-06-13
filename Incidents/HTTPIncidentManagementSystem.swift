//
//  HTTPIncidentManagementSystem.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Foundation



class HTTPIncidentManagementSystem: NSObject, IncidentManagementSystem {

    let url: String

    private var loadingState: IMSLoadingState = IMSLoadingState.Reset

    var incidentTypes: Set<String> {
        return _incidentTypes
    }
    private var _incidentTypes: Set<String> = Set()

    var rangersByHandle: [String: Ranger] {
        return _rangersByHandle
    }
    private var _rangersByHandle: [String: Ranger] = [:]

    var locationsByName: [String: Location] {
        return _locationsByName
    }
    private var _locationsByName: [String: Location] = [:]

    var incidentsByNumber: [Int: Incident] {
        return _incidentsByNumber
    }
    private var _incidentsByNumber: [Int: Incident] = [:]

    private var incidentETagsByNumber: [Int: String] = [:]

    private var httpSession: HTTPSession {
        if _httpSession == nil {
            _httpSession = HTTPSession(
                userAgent: "Ranger IMS (Mac OS)",
                idleTimeOut: 2, timeOut: 30
            )
        }
        return _httpSession!
    }
    private var _httpSession: HTTPSession? = nil


    init(url: String) {
        self.url = url
    }


    func reload() {
        switch loadingState {
            case .Reset:
                connect()
            case .Trying:
                return
            case .Loading:
                return
            case .Idle:
                loadingState = IMSLoadingState.Loading([:])
                loadIncidentTypes()
                loadPersonnel()
                // loadLocations()
                loadIncidents()
        }
    }


    func createIncident(incident: Incident) -> Failable {
        return Failable(Error("Unimplemented"))
    }


    func updateIncident(incident: Incident) -> Failable {
        return Failable(Error("Unimplemented"))
    }


//    func reloadIncidentWithNumber(number: Int) -> Failable {
//        return Failable(Error("Unimplemented"))
//    }
    
    
    private func connect() {
        switch loadingState {
        case .Reset:
            break
        default:
            return
        }

        let pingURL = "\(self.url)ping/"

        func onResponse(json: AnyObject?) {
            logInfo("Successfully connected to IMS Server: \(self.url)")
            loadingState = IMSLoadingState.Idle

            reload()
        }

        func onError(message: String) {
            logError("Error while attempting ping request: \(message)")
            resetConnection()
        }

        logInfo("Sending ping request to: \(pingURL)")

        guard let connection = self.httpSession.sendJSON(
            url: pingURL,
            json: nil,
            responseHandler: onResponse,
            errorHandler: onError
            ) else {
                logError("Unable to create ping connection?")
                resetConnection()
                return
        }

        loadingState = IMSLoadingState.Trying(connection)
    }


    private func resetConnection() {
        logError("Resetting IMS server connection")

        loadingState = IMSLoadingState.Reset

        guard let session = _httpSession else {
            return
        }
        
        _httpSession = nil
        
        session.invalidate()
    }
    
    
    private func loadIncidentTypes() {
        let typesURL = "\(self.url)incident_types/"

        func onResponse(json: AnyObject?) {
            logInfo("Loaded incident types")

            removeConnectionForLoadingGroup(
                group: IMSLoadingGroup.IncidentTypes,
                id: IMSConnectionID.IncidentTypes
            )

            guard let json = json else {
                logError("Incident types request retrieved no JSON data")
                return
            }

            guard let incidentTypes = json as? [String] else {
                logError("Incident Types JSON is non-conforming: \(json)")
                return
            }

            _incidentTypes = Set(incidentTypes)
        }

        func onError(message: String) {
            logError("Error while attempting incident types request: \(message)")
            resetConnection()
        }

        logInfo("Sending incident types request to: \(typesURL)")

        guard let connection = self.httpSession.sendJSON(
            url: typesURL,
            json: nil,
            responseHandler: onResponse,
            errorHandler: onError
            ) else {
                logError("Unable to create incident types connection?")
                resetConnection()
                return
        }

        addConnectionForLoadingGroup(
            group: IMSLoadingGroup.IncidentTypes,
            id: IMSConnectionID.IncidentTypes,
            connection: connection
        )
    }
    
    
    private func loadPersonnel() {
        let personnelURL = "\(self.url)personnel/"

        func onResponse(json: AnyObject?) {
            logInfo("Loaded personnel")

            removeConnectionForLoadingGroup(
                group: IMSLoadingGroup.Personnel,
                id: IMSConnectionID.Personnel
            )

            guard let json = json else {
                logError("Personnel request retrieved no JSON data")
                return
            }

            guard let personnel = json as? [[String: String]] else {
                logError("Personnel JSON is non-conforming: \(json)")
                return
            }

            var rangersByHandle: [String: Ranger] = [:]

            for person in personnel {
                guard
                    let handle = person["handle"],
                    let name   = person["name"  ],
                    let status = person["status"]
                else {
                    logError("Incomplete personnel record: \(person)")
                    continue
                }
                let ranger = Ranger(handle: handle, name: name, status: status)
                rangersByHandle[handle] = ranger
            }

            _rangersByHandle = rangersByHandle
        }

        func onError(message: String) {
            logError("Error while attempting personnel request: \(message)")
            resetConnection()
        }

        logInfo("Sending personnel request to: \(personnelURL)")

        guard let connection = self.httpSession.sendJSON(
            url: personnelURL,
            json: nil,
            responseHandler: onResponse,
            errorHandler: onError
            ) else {
                logError("Unable to create personnel connection?")
                resetConnection()
                return
        }

        addConnectionForLoadingGroup(
            group: IMSLoadingGroup.Personnel,
            id: IMSConnectionID.Personnel,
            connection: connection
        )
    }
    
    
    private func loadLocations() {
        let locationsURL = "\(self.url)locations/"

        func onResponse(json: AnyObject?) {
            logInfo("Loaded locations")

            removeConnectionForLoadingGroup(
                group: IMSLoadingGroup.Locations,
                id: IMSConnectionID.Locations
            )

            guard let json = json else {
                logError("Locations request retrieved no JSON data")
                return
            }

            guard let locations = json as? [[String: String]] else {
                logError("Locations JSON is non-conforming: \(json)")
                return
            }

//            var rangersByHandle: [String: Ranger] = [:]
//
//            for location in locations {
//                guard
//                    let handle = person["handle"],
//                    let name   = person["name"  ],
//                    let status = person["status"]
//                    else {
//                        logError("Incomplete location record: \(person)")
//                        continue
//                }
//                let ranger = Ranger(handle: handle, name: name, status: status)
//                rangersByHandle[handle] = ranger
//            }
//
//            _rangersByHandle = rangersByHandle
        }

        func onError(message: String) {
            logError("Error while attempting locations request: \(message)")
            resetConnection()
        }

        logInfo("Sending locations request to: \(locationsURL)")

        guard let connection = self.httpSession.sendJSON(
            url: locationsURL,
            json: nil,
            responseHandler: onResponse,
            errorHandler: onError
            ) else {
                logError("Unable to create locations connection?")
                resetConnection()
                return
        }

        addConnectionForLoadingGroup(
            group: IMSLoadingGroup.Locations,
            id: IMSConnectionID.Locations,
            connection: connection
        )
    }


    private func loadIncidents() {
        let incidentsURL = "\(self.url)incidents/"

        func onResponse(json: AnyObject?) {
            logInfo("Loaded incident list")

            removeConnectionForLoadingGroup(
                group: IMSLoadingGroup.Incidents,
                id: IMSConnectionID.Incidents(-1)
            )

            guard let json = json else {
                logError("Incident list request retrieved no JSON data")
                return
            }

            guard let incidentETags = json as? [[AnyObject]] else {
                logError("Incident list JSON is non-conforming: \(json)")
                return
            }

            for entry in incidentETags {
                guard entry.count == 2 else {
                    logError("Incident entry is non-conforming: \(entry)")
                    continue
                }
                guard let number = entry[0] as? Int else {
                    logError("Invalid incident number: \(incidentETags[0])")
                    continue
                }
                guard let etag = entry[1] as? String else {
                    logError("Invalid incident ETag: \(incidentETags[1])")
                    continue
                }

                loadIncident(number: number, etag: etag)
            }
        }

        func onError(message: String) {
            logError("Error while attempting incident list request: \(message)")
            resetConnection()
        }

        logInfo("Sending incident list request to: \(incidentsURL)")

        guard let connection = self.httpSession.sendJSON(
            url: incidentsURL,
            json: nil,
            responseHandler: onResponse,
            errorHandler: onError
            ) else {
                logError("Unable to create incident list connection?")
                resetConnection()
                return
        }

        addConnectionForLoadingGroup(
            group: IMSLoadingGroup.Incidents,
            id: IMSConnectionID.Incidents(-1),
            connection: connection
        )
    }


    func loadIncident(number number: Int, etag: String) {
        let incidentURL = "\(self.url)incidents/\(number)"

        if let loadedEtag = incidentETagsByNumber[number] {
            if loadedEtag == etag {
                logDebug("Already loaded incident #\(number)")
                return
            }
        }

        func onResponse(json: AnyObject?) {
            logInfo("Loaded incident #\(number)")

            removeConnectionForLoadingGroup(
                group: IMSLoadingGroup.Incidents,
                id: IMSConnectionID.Incidents(number)
            )

            // FIXME: ****************************
        }

        func onError(message: String) {
            logError("Error while attempting incident #\(number) request: \(message)")
            resetConnection()
        }

        logInfo("Sending incident #\(number) request to: \(incidentURL)")

        guard let connection = self.httpSession.sendJSON(
            url: incidentURL,
            json: nil,
            responseHandler: onResponse,
            errorHandler: onError
        ) else {
            logError("Unable to create incident #\(number) connection?")
            resetConnection()
            return
        }

        addConnectionForLoadingGroup(
            group: IMSLoadingGroup.Incidents,
            id: IMSConnectionID.Incidents(number),
            connection: connection
        )
    }

    
//    private func connectionsForLoadingGroup(
//        group: IMSLoadingGroup
//    ) throws -> [IMSConnectionID: HTTPConnection] {
//
//        switch loadingState {
//            case .Loading(let loading):
//                guard let connections = loading[group] else {
//                    return [:]
//                }
//                return connections
//            default:
//                throw IMSInternalError.IncorrectLoadingState
//        }
//    }


    private func addConnectionForLoadingGroup(
        group group: IMSLoadingGroup,
        id: IMSConnectionID,
        connection: HTTPConnection
        ) {
            guard case .Loading(var loading) = loadingState else {
                logError("Incorrect loading state for adding \(id) connection.")
                return
            }

            if loading[group] == nil {
                loading[group] = [:]
            }

            loading[group]![id] = connection

            loadingState = IMSLoadingState.Loading(loading)
    }


    private func removeConnectionForLoadingGroup(
        group group: IMSLoadingGroup,
        id: IMSConnectionID
        ) {
            guard case .Loading(var loading) = loadingState else {
                logError("Incorrect loading state for removing \(group)/\(id) connection.")
                return
            }

            if loading[group] == nil {
                logError("No such connection.")
                return
            }

            if loading[group]!.removeValueForKey(id) == nil {
                logError("No such connection.")
                return
            }

            if loading[group]!.count == 0 {
                // Nothing left for this group; remove the group
                loading.removeValueForKey(group)

                if loading.count == 0 {
                    // No groups loading data; switch to idle state
                    loadingState = IMSLoadingState.Idle
                    return
                }
            }
            
            loadingState = IMSLoadingState.Loading(loading)
    }
    
}



enum IMSLoadingState: CustomStringConvertible {
    case Reset
    case Trying(HTTPConnection)
    case Idle
    case Loading([IMSLoadingGroup: [IMSConnectionID: HTTPConnection]])

    var description: String {
        switch self {
            case .Reset:
                return "reset"

            case .Trying:
                return "trying"

            case .Idle:
                return "idle"

            case .Loading(let connections):
                var groups: [String] = []
                for (group, connections) in connections {
                    groups.append("\(group)(\(connections.count))")
                }

                var s = "loading("
                s += ", ".join(groups)
                s += ")"

                return s
        }
    }

}



enum IMSLoadingGroup: CustomStringConvertible {
    case IncidentTypes
    case Personnel
    case Locations
    case Incidents

    var description: String {
        switch self {
            case .IncidentTypes: return "incident types"
            case .Personnel    : return "personnel"
            case .Locations    : return "locations"
            case .Incidents    : return "incidents"
        }
    }
}



enum IMSConnectionID: Hashable {
    case IncidentTypes
    case Personnel
    case Locations
    case Incidents(Int)

    var hashValue: Int {
        var hash: Int

        switch self {
            case .IncidentTypes: hash = -1
            case .Personnel    : hash = -2
            case .Locations    : hash = -3

            case .Incidents(let id): hash = id
        }

        return hash
    }
}

func ==(lhs: IMSConnectionID, rhs: IMSConnectionID) -> Bool {
    switch lhs {
        case .IncidentTypes: if case .IncidentTypes = rhs { return true } else { return false }
        case .Personnel    : if case .Personnel     = rhs { return true } else { return false }
        case .Locations    : if case .Locations     = rhs { return true } else { return false }

        case .Incidents(let l_id):
            if case .Incidents(let r_id) = rhs { return l_id == r_id } else { return false }
    }
}



enum IMSError: ErrorType {
}



enum IMSInternalError: ErrorType {
    case IncorrectLoadingState
    case NoSuchConnection
}
