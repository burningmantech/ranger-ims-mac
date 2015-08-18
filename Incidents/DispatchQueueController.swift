//
//  DispatchQueueController.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class DispatchQueueController: NSWindowController {

    var appDelegate: AppDelegate!

    let ims: HTTPIncidentManagementSystem  // FIXME: should be IncidentManagementSystem, but working around a bug
    var imsPassword: String?

    var incidentControllers: [Int: IncidentController] = [:]
    var newIncidentControllers: Set<IncidentController> = []

    var reloadInterval: NSTimeInterval = 10
    var reloadTimer: NSTimer? = nil

    @IBOutlet weak var searchField     : NSSearchField?
    @IBOutlet weak var dispatchTable   : NSTableView?
    @IBOutlet weak var loadingIndicator: NSProgressIndicator?
    @IBOutlet weak var reloadButton    : NSButton?
    @IBOutlet weak var stateFilterPopUp: NSPopUpButton?


    var searchText: String {
        guard let searchFieldCell = searchField?.cell as? NSSearchFieldCell else {
            return ""
        }
        return searchFieldCell.stringValue.lowercaseString
    }


    var sortedIncidents: [Incident] {
        if _sortedIncidents == nil {
            if let sortDescriptors = dispatchTable?.sortDescriptors as [NSSortDescriptor]? {
                func isOrderedBefore(lhs: Incident, rhs: Incident) -> Bool {
                    return incident(lhs, isOrderedBeforeIncident: rhs, usingDescriptors: sortDescriptors)
                }
                _sortedIncidents = ims.incidentsByNumber.values.sort(isOrderedBefore)
            }
            else {
                func isOrderedBefore(i1: Incident, i2: Incident) -> Bool {
                    return i1.number < i2.number
                }
                _sortedIncidents = ims.incidentsByNumber.values.sort(isOrderedBefore)
            }
        }
        guard let sortedIncidents = _sortedIncidents else {
            return []
        }
        return sortedIncidents
    }
    private var _sortedIncidents: [Incident]? = nil


    var filteredIncidentsCache: FilteredIncidentsCache {
        if self._filteredIncidentsCache == nil {
            var filteredAllIncidents   : [Incident] = []
            var filteredOpenIncidents  : [Incident] = []
            var filteredActiveIncidents: [Incident] = []

            for incident in sortedIncidents {
                filteredAllIncidents.append(incident)

                if incident.state != IncidentState.Closed {
                    filteredOpenIncidents.append(incident)

                    if incident.state != IncidentState.OnHold {
                        filteredActiveIncidents.append(incident)
                    }
                }
            }

            self._filteredIncidentsCache = FilteredIncidentsCache(
                allIncidents   : filteredAllIncidents,
                openIncidents  : filteredOpenIncidents,
                activeIncidents: filteredActiveIncidents
            )
        }
        guard let filteredIncidentsCache = _filteredIncidentsCache else {
            return FilteredIncidentsCache(
                allIncidents   : [],
                openIncidents  : [],
                activeIncidents: []
            )
        }
        return filteredIncidentsCache
    }
    private var _filteredIncidentsCache: FilteredIncidentsCache? = nil

    
    var viewableIncidents: [Incident] {
        guard let stateFilterPopUp = stateFilterPopUp else {
            logError("No state filter popup?")
            return []
        }
        
        let selected = stateFilterPopUp.selectedTag()
        
        guard let filterTag = StateFilterTag(rawValue: selected) else {
            logError("Unknown filter tag: \(selected)")
            return []
        }
        
        let filteredIncidents: [Incident]
        
        switch filterTag {
            case .All   : filteredIncidents = filteredIncidentsCache.allIncidents
            case .Open  : filteredIncidents = filteredIncidentsCache.openIncidents
            case .Active: filteredIncidents = filteredIncidentsCache.activeIncidents
        }
        
        let searchText = self.searchText
        
        if searchText.characters.count == 0 { return filteredIncidents; }
        
        if let cache = _viewableIncidentsCache {
            if cache.searchText == searchText && cache.filterTag == filterTag {
                return cache.incidents
            }
        }
        
        let incidents = searchIncidents(incidents: filteredIncidents, searchText: searchText)

        _viewableIncidentsCache = ViewableIncidentsCache(
            searchText: searchText,
            filterTag: filterTag,
            incidents: incidents
        )
        
        return incidents
    }
    private var _viewableIncidentsCache: ViewableIncidentsCache?


    convenience init(appDelegate: AppDelegate) {
        self.init(windowNibName: "DispatchQueue")

        self.appDelegate = appDelegate
    }


    override init(window: NSWindow?) {
        let defaults = NSUserDefaults.standardUserDefaults()

        let scheme: String
        if defaults.boolForKey("IMSServerDisableTLS") {
            scheme = "http"
        } else {
            scheme = "https"
        }

        let host: String
        if let _host = defaults.stringForKey("IMSServerHostName") {
            host = _host
        } else {
            host = "localhost"
        }

        let port: String
        if let _port = defaults.stringForKey("IMSServerPort") {
            port = ":\(_port)"
        } else {
            port = ""
        }

        let path = "/"

        let url = "\(scheme)://\(host)\(port)\(path)"

        logInfo("IMS Server: \(url)")
        ims = HTTPIncidentManagementSystem(url: url)

        super.init(window: window)

        ims.delegate = self
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    func performReload(force: Bool=false) {
        if force && reloadTimer != nil {
            reloadTimer!.invalidate()
            reloadTimer = nil
        }

        if (reloadTimer == nil || !reloadTimer!.valid) {
            ims.reload()

            logDebug("Restarting reload timer")
            reloadTimer = NSTimer.scheduledTimerWithTimeInterval(
                reloadInterval,
                target: self,
                selector: Selector("_reloadTimerFired:"),
                userInfo: self,
                repeats: false
            )
        }
    }


    func _reloadTimerFired(timer: NSTimer) {
        if !NSUserDefaults.standardUserDefaults().boolForKey("IMSDisableReloadTimer") {
            logDebug("Reloading after timer")
            performReload(true)
        }
    }


    func openIncident(incident: Incident) {
        guard let number = incident.number else {
            logError("Can't open an incident without a number")
            return
        }

        let incidentController: IncidentController

        if let _incidentController = incidentControllers[number] {
            // Already have a controller for the incident in question
            incidentController = _incidentController
        } else {
            // Create a controller for the incident in question
            incidentController = IncidentController(
                dispatchQueueController: self,
                incident: incident
            )
            incidentControllers[number] = incidentController

            let incidentWindowWillClose = {
                (notification: NSNotification) -> Void in

                guard let window = notification.object else {
                    logError("Got a window will close notification for a nil window?")
                    return
                }

                guard let controller = window.windowController as? IncidentController else {
                    logError("Got a window will close notification for an incident window with no incident controller?")
                    return
                }

                guard controller == incidentController else {
                    logError("Got a window will close notification for an incident window with a different incident controller?")
                    return
                }

                guard self.incidentControllers.removeValueForKey(number) != nil else {
                    logError("Got a window will close notification for an incident window no longer being tracked?")
                    return
                }
            }

            NSNotificationCenter.defaultCenter().addObserverForName(
                NSWindowWillCloseNotification,
                object: incidentController.window,
                queue: nil,
                usingBlock: incidentWindowWillClose
            )
        }

        incidentController.showWindow(self)
        incidentController.window?.makeKeyAndOrderFront(self)
    }


    func openClickedIncident() {
        guard let dispatchTable = self.dispatchTable else { return }

        let rowIndex = dispatchTable.clickedRow

        let incident: Incident
        do {
            incident = try incidentForTableRow(rowIndex)
        } catch {
            logError("No incident for clicked row index \(rowIndex)")
            return
        }

        openIncident(incident)
    }


    @IBAction func newIncident(sender: AnyObject) {
        let incident = Incident(number: nil)

        let incidentController: IncidentController
        
        // Create a controller for the new incident
        incidentController = IncidentController(
            dispatchQueueController: self,
            incident: incident
        )
        newIncidentControllers.insert(incidentController)
        
        incidentController.showWindow(self)
        incidentController.window?.makeKeyAndOrderFront(self)
        
        let incidentWindowWillClose = {
            (notification: NSNotification) -> Void in
            
            guard let window = notification.object else {
                logError("Got a window will close notification for a nil window?")
                return
            }
            
            guard let controller = window.windowController as? IncidentController else {
                logError("Got a window will close notification for a (new) incident window with no incident controller?")
                return
            }
            
            guard controller == incidentController else {
                logError("Got a window will close notification for a (new) incident window with a different incident controller?")
                return
            }
            
            if let number = incidentController.incident?.number {
                if self.newIncidentControllers.remove(incidentController) != nil {
                    logError("Got a window will close notification for a (new) incident controller with a number but was still tracked as new.")
                }

                guard self.incidentControllers.removeValueForKey(number) != nil else {
                    logError("Got a window will close notification for a (new) incident window not being tracked?")
                    return
                }
            }
            else {
                guard self.newIncidentControllers.remove(incidentController) != nil else {
                    logError("Got a window will close notification for a (new) incident window no longer being tracked?")
                    return
                }
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName(
            NSWindowWillCloseNotification,
            object: incidentController.window,
            queue: nil,
            usingBlock: incidentWindowWillClose
        )
    }


    func incidentControllerDidCreateIncident(incidentController: IncidentController) {
        guard let number = incidentController.incident?.number else {
            alert(
                title: "Internal error",
                message: "Incident controller saved a new incident but still doesn't have an incident number."
            )
            return
        }

        if newIncidentControllers.remove(incidentController) == nil {
            alert(
                title: "Internal error",
                message: "Incident controller saved a new incident (#\(number)) but is not tracked as a new controller."
            )
        }

        if let existing = incidentControllers[number] {
            if existing == incidentController {
                alert(
                    title: "Internal error",
                    message: "Incident controller saved a new incident (#\(number)) that already has another controller?"
                )
            }
            incidentController.window?.close()
        }

        incidentControllers[number] = incidentController
    }

}



extension DispatchQueueController: HTTPIncidentManagementSystemDelegate {

    func incidentDidUpdate(ims ims: IncidentManagementSystem, incident: Incident) {
        guard let number = incident.number else {
            logError("Updated incident has no number: \(incident)")
            return
        }
        
        logDebug("Incident updated: \(incident)")
        
        if let incidentController = incidentControllers[number] {
            incidentController.incidentDidUpdate(ims: ims, updatedIncident: incident)
        }

        resort(self)
    }


    func handleAuth(
        host host: String,
        port: Int,
        realm: String?
    ) -> HTTPCredential? {
        func obtainCredentials() {
            let passwordController = PasswordController(dispatchQueueController: self)
            
            if passwordController.window != nil {
                passwordController.showWindow(self)
                passwordController.window!.makeKeyAndOrderFront(self)
                
                NSApp.runModalForWindow(passwordController.window!)
            }
        }

        if NSThread.currentThread().isMainThread {
            obtainCredentials()
        } else {
            dispatch_sync(dispatch_get_main_queue(), obtainCredentials)
        }
        
        guard let
            username = NSUserDefaults.standardUserDefaults().stringForKey("IMSUserName"),
            password = imsPassword
        else {
            return nil
        }

        return HTTPUsernamePasswordCredential(
            username: username,
            password: password
        )
    }
    
}



extension DispatchQueueController: NSWindowDelegate {

     override func windowDidLoad() {
        super.windowDidLoad()

        func arghEvilDeath(uiElementName: String) {
            fatalError("Dispatch queue controller: no \(uiElementName)?")
        }

        if window           == nil { arghEvilDeath("window"            ) }
        if searchField      == nil { arghEvilDeath("search field"      ) }
        if dispatchTable    == nil { arghEvilDeath("dispatch table"    ) }
        if loadingIndicator == nil { arghEvilDeath("loading indicator" ) }
        if reloadButton     == nil { arghEvilDeath("reload button"     ) }
        if stateFilterPopUp == nil { arghEvilDeath("state filter popup") }

        reloadButton!.hidden     = false
        loadingIndicator!.hidden = true

        stateFilterPopUp!.selectItemWithTag(StateFilterTag.Open.rawValue)
        
        if self.respondsToSelector(Selector("openClickedIncident")) {
            dispatchTable!.doubleAction = Selector("openClickedIncident")
        } else {
            arghEvilDeath("DDispatchQueueController doesn't respond to openClickedIncident()")
        }

        performReload()
    }

}



extension DispatchQueueController: NSTableViewDataSource {

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return viewableIncidents.count
    }


    func tableView(
        tableView: NSTableView,
        objectValueForTableColumn column: NSTableColumn?,
        row rowIndex: Int
    ) -> AnyObject? {
        let incident: Incident
        do {
            incident = try incidentForTableRow(rowIndex)
        } catch {
            logError("No incident for row index \(rowIndex)")
            return nil
        }

        guard let label = column?.identifier else {
            logError("Unidentified column: \(column)")
            return nil
        }

        switch label {
            case "number":
                return incident.number

            case "priority":
                return incident.priority?.description

            case "created":
                return incident.created?.asShortString()

            case "state":
                return incident.state?.description

            case "rangers":
                return incident.rangersAsText

            case "location":
                return incident.location?.description

            case "incidentTypes":
                return incident.incidentTypesAsText

            case "summary":
                return incident.summaryAsText

            default:
                logError("Unknown column: \(label)")
                return nil
        }
    }


    // Not NSTableViewDataSource, but related


    @IBAction func updateViewedIncidents(sender: AnyObject?) {
        if self.dispatchTable != nil {
            // Make sure UI stuff goes to the main thread
            dispatch_async(dispatch_get_main_queue()) {
                () -> Void in
                // Because we are async here, make sure self.dispatchTable is
                // still not nil, or we could crash if it becomes nil (eg. the
                // user logs out).
                guard let dispatchTable = self.dispatchTable else { return }
                dispatchTable.reloadData()
            }
        }
    }


    @IBAction func resort(sender: AnyObject?) {
        _sortedIncidents        = nil
        _filteredIncidentsCache = nil

        updateViewedIncidents(self)
    }


    func incidentForTableRow(rowIndex: Int) throws -> Incident {
        let viewableIncidents = self.viewableIncidents

        guard rowIndex >= 0 else {
            throw DispatchQueueTableSourceError.RowIndexOutOfRange(rowIndex)
        }
        
        guard rowIndex < viewableIncidents.count else {
            throw DispatchQueueTableSourceError.RowIndexOutOfRange(rowIndex)
        }

        return viewableIncidents[rowIndex]
    }


    func selectedIncident() -> Incident? {
        guard let dispatchTable = self.dispatchTable else {
            return nil
        }

        let incident: Incident
        do {
            incident = try incidentForTableRow(dispatchTable.selectedRow)
        } catch {
            logError("Unable to look up selected incident: \(error)")
            return nil
        }
        return incident
    }


    @IBAction func reload(sender: AnyObject?) {
        performReload(true)
    }

}



enum DispatchQueueTableSourceError: ErrorType {
    case RowIndexOutOfRange(Int)
}



extension DispatchQueueController: NSTableViewDelegate {

    func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        resort(self)
    }

}



func searchIncidents(incidents incidents: [Incident], searchText: String) -> [Incident] {
    if searchText.characters.count == 0 {
        return incidents
    }
    
    // Tokenine the search text
    let whiteSpace = NSCharacterSet.whitespaceAndNewlineCharacterSet()
    let tokens = searchText.componentsSeparatedByCharactersInSet(whiteSpace)
    
    func tokenMatchesIncident(token token: String, incident: Incident) -> Bool {
        if token.characters.count == 0 { return true }
        
        func matchString(input: String) -> Bool {
            let input = input.lowercaseString
            return input.rangeOfString(token) != nil
        }
        
        if let term = incident.number?.description            { if matchString(term) { return true } }
        if let term = incident.summary                        { if matchString(term) { return true } }
        if let term = incident.location?.name                 { if matchString(term) { return true } }
        if let term = incident.location?.address?.description { if matchString(term) { return true } }
        
        if let rangers = incident.rangers {
            for ranger in rangers {
                if matchString(ranger.handle) { return true}
            }
        }
        
        if let incidentTypes = incident.incidentTypes {
            for incidentType in incidentTypes {
                if matchString(incidentType) { return true }
            }
        }
        
        if let reportEntries = incident.reportEntries {
            for reportEntry in reportEntries {
                if matchString(reportEntry.text) { return true }
            }
        }
        
        return false
    }
    
    func matchIncident(incident: Incident) -> Bool {
        for token in tokens {
            if !tokenMatchesIncident(token: token, incident: incident) {
                return false
            }
        }
        return true
    }
    
    // Search through each incident
    
    var result: [Incident] = []
    
    for incident in incidents where matchIncident(incident) {
        result.append(incident)
    }
    
    return result
}



func incident(
    lhs: Incident,
    isOrderedBeforeIncident rhs: Incident,
    usingDescriptors descriptors: [NSSortDescriptor]
) -> Bool {
    for descriptor in descriptors {
        guard let keyPath: String = descriptor.key else {
            logError("Sort descriptor specified no key.")
            continue
        }

        if incident(lhs, isOrderedBeforeIncident: rhs, usingKeyPath: keyPath) {
            return descriptor.ascending
        }
        else if incident(rhs, isOrderedBeforeIncident: lhs, usingKeyPath: keyPath) {
            return !descriptor.ascending
        }
    }
    return false
}



func incident(
    lhs: Incident,
    isOrderedBeforeIncident rhs: Incident,
    usingKeyPath keyPath: String
) -> Bool {
    switch keyPath {
        case "number":
            return lhs.number < rhs.number
            
        case "priority":
            if lhs.priority == nil { logError("Ordered incident \(lhs) has nil priority"); return true  }
            if rhs.priority == nil { logError("Ordered incident \(rhs) has nil priority"); return false }
            return lhs.priority! < rhs.priority!
            
        case "summary":
            return lhs.summaryAsText < rhs.summaryAsText
            
        case "location":
            if lhs.location == nil { return true  }
            if rhs.location == nil { return false }
            return lhs.location! < rhs.location!
            
        case "rangers":
            return lhs.rangersAsText < rhs.rangersAsText
            
        case "incidentTypes":
            return lhs.rangersAsText < rhs.rangersAsText
            
        case "reportEntries":
            return false
            
        case "created":
            if lhs.created == nil { logError("Ordered incident \(lhs) has nil created"); return true  }
            if rhs.created == nil { logError("Ordered incident \(rhs) has nil created"); return false }
            return lhs.created! < rhs.created!
            
        case "state":
            if lhs.state == nil { logError("Ordered incident \(lhs) has nil state"); return true  }
            if rhs.state == nil { logError("Ordered incident \(rhs) has nil state"); return false }
            return lhs.state! < rhs.state!
            
        default:
            logError("Unknown sort descriptor key path: \(keyPath)")
            return false
    }
}



struct FilteredIncidentsCache {
    let allIncidents   : [Incident]
    let openIncidents  : [Incident]
    let activeIncidents: [Incident]
}



struct ViewableIncidentsCache {
    let searchText: String
    let filterTag: StateFilterTag
    let incidents: [Incident]
}



enum StateFilterTag: Int {
    case All    = 1
    case Open   = 2
    case Active = 3
}
