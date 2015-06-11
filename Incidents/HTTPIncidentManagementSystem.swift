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


    func connect() {
        switch loadingState {
            case .Reset:
                break
            default:
                return
        }

        let pingURL = "\(self.url)ping/"

        var headers = HTTPHeaders()
        headers.add(name: "Accept", value: "application/json")

        let request = HTTPRequest(
            url: pingURL,
            method: HTTPMethod.GET,
            headers: headers,
            body: []
        )

        func onResponse(
            url: String,
            status: Int,
            headers: HTTPHeaders,
            body:[UInt8]
        ) {
            if url != pingURL {
                logError("URL in response does not match URL in ping request: \(url) != \(pingURL)")
                return
            }

            if status < 200 || status >= 300 {
                logError("Non-success response status to ping request: \(status)")
                return
            }

            guard let contentTypes = headers["Content-Type"] else {
                logError("No Content-Type header in response to ping request")
                return
            }

            if contentTypes.count != 1 {
                logError("Multiple Content-Types in response to ping request: \(contentTypes)")
                return
            }
            if contentTypes[0] != "application/json" {
                logError("Non-JSON Content-Type in response to ping request: \(contentTypes[0])")
                return
            }

            logInfo("Successfully connected to IMS Server: \(self.url)")
            loadingState = IMSLoadingState.Idle

            reload()
        }

        func onError(message: String) {
            logError("Error while attempting ping request: \(message)")
            loadingState = IMSLoadingState.Reset
        }

        logInfo("Sending ping request to: \(pingURL)")

        guard let connection = self.httpSession.send(
            request: request,
            responseHandler: onResponse,
            errorHandler: onError
        ) else {
            logError("Unable to create ping connection?")
            loadingState = IMSLoadingState.Reset
            return
        }

        loadingState = IMSLoadingState.Trying(connection)
    }


    func loadIncidentTypes() {
        var connections: [String: HTTPConnection]

        switch loadingState {
            case .Loading(let loading):
                if loading.indexForKey("incident types") != nil {
                    return
                }
                connections = loading
            default:
                logError("loadIncidentTypes() called while not in loading state")
                return
        }

        let typesURL = "\(self.url)incident_types/"

        var headers = HTTPHeaders()
        headers.add(name: "Accept", value: "application/json")

        let request = HTTPRequest(
            url: typesURL,
            method: HTTPMethod.GET,
            headers: headers,
            body: []
        )

        func onResponse(
            url: String,
            status: Int,
            headers: HTTPHeaders,
            body:[UInt8]
            ) {
                if url != typesURL {
                    logError("URL in response does not match URL in incident types request: \(url) != \(typesURL)")
                    return
                }

                if status < 200 || status >= 300 {
                    logError("Non-success response status to incident types request: \(status)")
                    return
                }

                guard let contentTypes = headers["Content-Type"] else {
                    logError("No Content-Type header in response to incident types request")
                    return
                }

                if contentTypes.count != 1 {
                    logError("Multiple Content-Types in response to incident types request: \(contentTypes)")
                    return
                }
                if contentTypes[0] != "application/json" {
                    logError("Non-JSON Content-Type in response to incident types request: \(contentTypes[0])")
                    return
                }

                logInfo("Loaded incident types")

                // ***********************************
        }

        func onError(message: String) {
            logError("Error while attempting incident types request: \(message)")
            loadingState = IMSLoadingState.Reset
        }

        logInfo("Sending incident types request to: \(typesURL)")

        guard let connection = self.httpSession.send(
            request: request,
            responseHandler: onResponse,
            errorHandler: onError
        ) else {
            logError("Unable to create incident types connection?")
            loadingState = IMSLoadingState.Reset
            return
        }

        connections["incident types"] = connection
        loadingState = IMSLoadingState.Loading(connections)
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
    case Loading([String: HTTPConnection])
}
