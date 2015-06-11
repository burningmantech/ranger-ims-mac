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
    private var _rangersByHandle: [String: Ranger] = Dictionary()

    var locationsByName: [String: Location] {
        return _locationsByName
    }
    private var _locationsByName: [String: Location] = Dictionary()

    var incidentsByNumber: [Int: Incident] {
        return _incidentsByNumber
    }
    private var _incidentsByNumber: [Int: Incident] = Dictionary()

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
            loadingState = IMSLoadingState.Reset
        }

        logInfo("Sending ping request to: \(pingURL)")

        guard let connection = self.httpSession.sendJSON(
            url: pingURL,
            json: nil,
            responseHandler: onResponse,
            errorHandler: onError
        ) else {
            logError("Unable to create ping connection?")
            loadingState = IMSLoadingState.Reset
            return
        }

        loadingState = IMSLoadingState.Trying(connection)
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

        switch loadingState {
            case .Loading(let loading):
                var connections: [IMSConnectionID: HTTPConnection]

                if let existing = loading[group] {
                    connections = existing
                } else {
                    connections = [:]
                }

                connections[id] = connection

            default:
                logError("Incorrect loading state.")
        }
    }


    private func removeConnectionForLoadingGroup(
        group group: IMSLoadingGroup,
        id: IMSConnectionID
    ) {

        switch loadingState {
            case .Loading(let loading):
                var connections: [IMSConnectionID: HTTPConnection]

                guard let _connections = loading[group] else {
                    logError("No such connection.")
                    return
                }
                connections = _connections

                if connections.removeValueForKey(id) == nil {
                    logError("No such connection.")
                }

            default:
                logError("Incorrect loading state.")
        }
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

            logDebug("\(json)")
        }

        func onError(message: String) {
            logError("Error while attempting incident types request: \(message)")
            loadingState = IMSLoadingState.Reset
        }

        logInfo("Sending incident types request to: \(typesURL)")

        guard let connection = self.httpSession.sendJSON(
            url: typesURL,
            json: nil,
            responseHandler: onResponse,
            errorHandler: onError
        ) else {
            logError("Unable to create incident types connection?")
            loadingState = IMSLoadingState.Reset
            return
        }

        addConnectionForLoadingGroup(
            group: IMSLoadingGroup.IncidentTypes,
            id: IMSConnectionID.IncidentTypes,
            connection: connection
        )
    }


    func reload() {
        logDebug("Re-loading; state = \(loadingState)")

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
            case .Loading:
                return "loading"
        }
    }

}



enum IMSLoadingGroup: CustomStringConvertible {
    case IncidentTypes

    var description: String {
        switch self {
            case .IncidentTypes:
                return "incident types"
        }
    }
}



enum IMSConnectionID {
    case IncidentTypes
}



enum IMSError: ErrorType {
}



enum IMSInternalError: ErrorType {
    case IncorrectLoadingState
    case NoSuchConnection
}
