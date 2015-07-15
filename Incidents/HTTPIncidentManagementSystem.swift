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
    weak var delegate: IncidentManagementSystemDelegate?

    
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
            let session = HTTPSession(
                userAgent: "Ranger IMS (Mac OS)",
                idleTimeOut: 30, timeOut: 30
            )

            session.authHandler = {
                (host: String, port: Int, realm: String?) -> HTTPCredential? in

                guard let delegate = self.delegate as? HTTPIncidentManagementSystemDelegate else { return nil }

                return delegate.handleAuth(host: host, port: port, realm: realm)
            }

            _httpSession = session
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
                logDebug("reload() while still trying to establish first connection")
                return
            case .Loading:
                logDebug("reload() while still loading: \(loadingState)")
                return
            case .Idle:
                loadingState = IMSLoadingState.Loading([:])
                loadIncidentTypes()
                loadPersonnel()
                loadLocations()
                loadIncidents()
        }
    }


    func createIncident(incident: Incident) throws {
        alert(title: "Unimplemented: Create Incident", message: "\(incident)")
        throw NotImplementedError.NotImplementedYet
    }


    func updateIncident(incident: Incident) throws {
        let json = try incidentAsJSON(incident)
        
        guard let number = incident.number else {
            throw IMSError.IncidentNumberNil
        }
        
        let incidentURL = "\(self.url)incidents/\(number)"

        func onResponse(headers: HTTPHeaders, json: AnyObject?) {
            // FIXME: There's overlap here with loadIncident()'s onResponse…
            
            guard let json = json else {
                logError("Update incident #\(number) request retrieved no JSON data")
                return
            }

            guard let incidentJSON = json as? IncidentDictionary else {
                alert(
                    title: "Update incident #\(number) JSON is non-conforming",
                    message: "\(json)"
                )
                return
            }

            let updatedIncident: Incident
            do {
                updatedIncident = try incidentFromJSON(incidentJSON)
            } catch {
                alert(
                    title: "Unable to parse updated incident #\(number) JSON",
                    message: "\(error)\n\(incidentJSON)"
                )
                return
            }

            guard let updatedNumber = updatedIncident.number else {
                alert(
                    title: "Updated incident #\(number) has no incident number",
                    message: "\(incidentJSON)"
                )
                return
            }
            
            guard updatedNumber == number else {
                alert(
                    title: "Updated incident #\(number) has different incident number",
                    message: "\(incidentJSON)"
                )
                return
            }
            
            let etags = headers["ETag"]
            let etag: String?
                
            // Don't error out completely if we don't get an etag.
            // We will just have to reload the incident from the server in that case.

            if let etags = etags {
                if etags.count != 1 {
                    logError("Updated incident #\(number) response included multiple ETags: \(etags)")
                    etag = nil
                } else {
                    etag = etags[0]
                }
            } else {
                logError("Updated incident #\(number) response did not include an ETag.")
                etag = nil
            }

            if let etag = etag {
                _incidentsByNumber[number] = incident
                incidentETagsByNumber[number] = etag

                logHTTP("Updated incident #\(number)")

                if let delegate = self.delegate {
                    delegate.incidentDidUpdate(self, incident: incident)
                }
            }

            // Read back the server's copy.
            // Should be a no-nop because we should have stored the updated incident and etag above.

            loadIncident(number: number, etag: etag)
        }
        
        func onError(message: String) {
            logError("Error while attempting incident update request: \(message)")
        }

        logHTTP("Sending incident #\(number) update request to: \(incidentURL)")

        guard self.httpSession.sendJSON(
            url: incidentURL,
            method: HTTPMethod.POST,
            json: json,
            responseHandler: onResponse,
            errorHandler: onError
        ) != nil else {
            logError("Unable to create incident #\(number) update connection?")
            return
        }

        // Note we are not adding this connection to a loading group
        // FIXME: make sure that's cool
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

        func onResponse(headers: HTTPHeaders, json: AnyObject?) {
            logInfo("Successfully connected to IMS Server: \(self.url)")
            loadingState = IMSLoadingState.Idle

            reload()
        }

        func onError(message: String) {
            logError("Error while attempting ping request: \(message)")
            resetConnection()
        }

        logHTTP("Sending ping request to: \(pingURL)")

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
        logError("Resetting IMS server session")

        loadingState = IMSLoadingState.Reset

        guard let session = _httpSession else {
            return
        }
        
        _httpSession = nil
        
        session.invalidate()
    }
    
    
    private func loadIncidentTypes() {
        let typesURL = "\(self.url)incident_types/"

        func onResponse(headers: HTTPHeaders, json: AnyObject?) {
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

            logHTTP("Loaded incident types")
        }

        func onError(message: String) {
            logError("Error while attempting incident types request: \(message)")
            // resetConnection()
        }

        logHTTP("Sending incident types request to: \(typesURL)")

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

        func onResponse(headers: HTTPHeaders, json: AnyObject?) {
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

            logHTTP("Loaded personnel")
        }

        func onError(message: String) {
            logError("Error while attempting personnel request: \(message)")
            // resetConnection()
        }

        logHTTP("Sending personnel request to: \(personnelURL)")

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

        func onResponse(headers: HTTPHeaders, json: AnyObject?) {
            removeConnectionForLoadingGroup(
                group: IMSLoadingGroup.Locations,
                id: IMSConnectionID.Locations
            )

            guard let json = json else {
                logError("Locations request retrieved no JSON data")
                return
            }

            guard let locationsJSON = json as? [LocationDictionary] else {
                logError("Locations JSON is non-conforming: \(json)")
                return
            }

            var locationsByName: [String: Location] = [:]

            for locationJSON in locationsJSON {
                let location: Location
                do {
                    location = try locationFromJSON(locationJSON)
                } catch {
                    logError("Unable to parse location JSON: \(error)\n\(locationJSON)")
                    continue
                }
            
                guard let name = location.name else {
                    logDebug("Got location from server with no name: \(locationJSON)")
                    continue
                }
            
                locationsByName[name] = location
            }

            _locationsByName = locationsByName

            logHTTP("Loaded locations")
        }

        func onError(message: String) {
            logError("Error while attempting locations request: \(message)")
            // resetConnection()
        }

        logHTTP("Sending locations request to: \(locationsURL)")

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

        func onResponse(headers: HTTPHeaders, json: AnyObject?) {
            func removeConnection() {
                removeConnectionForLoadingGroup(
                    group: IMSLoadingGroup.Incidents,
                    id: IMSConnectionID.Incidents(-1)
                )
            }

            guard let json = json else {
                logError("Incident list request retrieved no JSON data")
                removeConnection()
                return
            }

            guard let incidentETags = json as? [[AnyObject]] else {
                logError("Incident list JSON is non-conforming: \(json)")
                removeConnection()
                return
            }

            for entry in incidentETags {
                guard entry.count == 2 else {
                    logError("Incident entry JSON is non-conforming: \(entry)")
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

            removeConnection()

            logHTTP("Loaded incident list")
        }

        func onError(message: String) {
            logError("Error while attempting incident list request: \(message)")
            // resetConnection()
        }

        logHTTP("Sending incident list request to: \(incidentsURL)")

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


    func loadIncident(number number: Int, etag: String?) {
        let incidentURL = "\(self.url)incidents/\(number)"

        if
            let etag = etag,
            let loadedEtag = incidentETagsByNumber[number]
        {
            if loadedEtag == etag { return }
        }

        func onResponse(headers: HTTPHeaders, json: AnyObject?) {
            removeConnectionForLoadingGroup(
                group: IMSLoadingGroup.Incidents,
                id: IMSConnectionID.Incidents(number)
            )

            guard let incidentDictionary = json as? IncidentDictionary else {
                logError("Incident #\(number) JSON is non-conforming: \(json)")
                return
            }

            let incident: Incident
            do {
                try incident = incidentFromJSON(incidentDictionary)
            } catch {
                logError("Incident #\(number) JSON failed to parse: \(error)\n\(incidentDictionary)")
                return
            }
            
            guard incident.number == number else {
                logError("Incident #\(number) JSON has incorrect incident number: \(incident.number)")
                return
            }

            guard let etags = headers["ETag"] else {
                logError("Incident #\(number) response did not include an ETag.")
                return
            }

            guard etags.count == 1 else {
                logError("Incident #\(number) response included multiple ETags: \(etags)")
                return
            }

            let etag = etags[0]

            _incidentsByNumber[number] = incident
            incidentETagsByNumber[number] = etag

            logHTTP("Loaded incident #\(number)")

            if let delegate = self.delegate {
                delegate.incidentDidUpdate(self, incident: incident)
            }
        }

        func onError(message: String) {
            logError("Error while attempting incident #\(number) request: \(message)")
            // resetConnection()
        }

        logHTTP("Sending incident #\(number) request to: \(incidentURL)")

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
//                throw HTTPIMSInternalError.IncorrectLoadingState
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
    

    private func logHTTP(message: String) {
        if NSUserDefaults.standardUserDefaults().boolForKey("EnableHTTPLogging") {
            logInfo(message)
        }
    }

}



protocol HTTPIncidentManagementSystemDelegate: IncidentManagementSystemDelegate {
    func handleAuth(host host: String, port: Int, realm: String?) -> HTTPCredential?
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



enum HTTPIMSInternalError: ErrorType {
    case IncorrectLoadingState
    case NoSuchConnection
}
