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

    private var loadingState: IMSLoadingState = IMSLoadingState.Reset("New")

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
        if !_connected {
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

                if let contentTypes = headers["Content-Type"] {
                    if contentTypes.count != 1 {
                        logError("Multiple Content-Types in response to ping request: \(contentTypes)")
                        return
                    }
                    if contentTypes[0] != "application/json" {
                        logError("Non-JSON Content-Type in response to ping request: \(contentTypes[0])")
                        return
                    }
                }
                else {
                    logError("No Content-Type header in response to ping request")
                    return
                }

                logInfo("Successfully connected to IMS Server: \(self.url)")
                _connected = true
            }

            func onError(message: String) {
                logError("Error while attempting ping request: \(message)")
                _connected = false
            }

            logInfo("Attempting ping request to: \(pingURL)")
            self.httpSession.send(
                request: request,
                responseHandler: onResponse,
                errorHandler: onError
            )
        }
    }
    private var _connected: Bool = false


    func reload() -> Failable {
        connect()



        return Failable.Success
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
    case Reset(String)
    case Idle
    case Loading
}
