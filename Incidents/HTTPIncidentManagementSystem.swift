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


    private func connectionsForLoadingGroup(group: IMSLoadingGroup) throws -> [HTTPConnection] {
        switch loadingState {
            case .Loading(let loading):
                guard let connections = loading[group] else {
                    return []
                }
                return connections
            default:
                throw IMSInternalError.IncorrectLoadingState
        }
    }


    // FIXME: This all feels janky
    private func addConnectionForLoadingGroup(
        group: IMSLoadingGroup,
        connection: HTTPConnection
    ) throws -> [HTTPConnection] {

        switch loadingState {
            case .Loading(let loading):
                var connections: [HTTPConnection]

                if let existing = loading[group] {
                    connections = existing
                } else {
                    connections = []
                }

                connections.append(connection)

                return connections

            default:
                throw IMSInternalError.IncorrectLoadingState
        }
    }


    private func loadIncidentTypes() throws {
        let typesURL = "\(self.url)incident_types/"

        func onResponse(json: AnyObject?) {
            logInfo("Loaded incident types")

            guard let json = json else {
                logError("Incident types request retrieved no JSON data")
                return  // *************************
            }

            logInfo("\(json)")
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

        try addConnectionForLoadingGroup(IMSLoadingGroup.IncidentTypes, connection: connection)
    }


    func reload() {
        logInfo("Re-loading; state = \(loadingState)")

        switch loadingState {
            case .Reset:
                connect()
            case .Trying:
                return
            case .Loading:
                return
            case .Idle:
                loadingState = IMSLoadingState.Loading([:])
                do {
                    try loadIncidentTypes()
                } catch {
                    logError("Unexpected error while attempting to reload incident types.")
                }
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



enum IMSLoadingState {
    case Reset
    case Trying(HTTPConnection)
    case Idle
    case Loading([IMSLoadingGroup: [HTTPConnection]])
}



enum IMSLoadingGroup {
    case IncidentTypes
}



enum IMSError: ErrorType {
}



enum IMSInternalError: ErrorType {
    case IncorrectLoadingState
}
