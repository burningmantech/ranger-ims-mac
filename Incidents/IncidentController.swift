//
//  IncidentController.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class IncidentController: NSWindowController {

    var dispatchQueueController: DispatchQueueController?

    var incident        : Incident?
    var originalIncident: Incident?

    var rangersTableManager: RangersTableManager?
    var typesTableManager  : IncidentTypesTableManager?

    var locationNameDelegate     : LocationNameFieldDelegate?
    var concentricAddressDelegate: ConcentricStreetFieldDelegate?
    var addReportEntryDelegate   : AddReportEntryViewDelegate?
    
    var amUpdatingView         = false
    
    @IBOutlet weak var numberField                   : NSTextField?
    @IBOutlet weak var statePopUp                    : NSPopUpButton?
    @IBOutlet weak var priorityPopUp                 : NSPopUpButton?
    @IBOutlet weak var summaryField                  : NSTextField?
    @IBOutlet weak var rangersTable                  : NSTableView?
    @IBOutlet weak var rangerToAddField              : NSTextField?
    @IBOutlet weak var typesTable                    : NSTableView?
    @IBOutlet weak var typeToAddField                : NSTextField?
    @IBOutlet weak var locationNameField             : NSTextField?
    @IBOutlet weak var locationRadialAddressField    : NSTextField?
    @IBOutlet weak var locationConcentricAddressField: NSTextField?
    @IBOutlet weak var locationDescriptionField      : NSTextField?
    @IBOutlet weak var reportEntriesScrollView       : NSScrollView?  // Can't connect NSTextView because weak sauce
    @IBOutlet weak var reportEntryToAddScrollView    : NSScrollView?  // Can't connect NSTextView because weak sauce
    @IBOutlet weak var saveButton                    : NSButton?
    @IBOutlet weak var loadingIndicator              : NSProgressIndicator?
    @IBOutlet weak var reloadButton                  : NSButton?


    var reportEntriesView: NSTextView? {
        return reportEntriesScrollView?.contentView.documentView as? NSTextView
    }


    var reportEntryToAddView: NSTextView? {
        return reportEntryToAddScrollView?.contentView.documentView as? NSTextView
    }


    convenience init(dispatchQueueController: DispatchQueueController, incident: Incident) {
        self.init(windowNibName: "Incident")

        self.dispatchQueueController = dispatchQueueController
        self.incident = incident
        self.originalIncident = incident
    }


    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    @IBAction func save(sender: AnyObject?) {
        // Push new report entry into the incident.
        addReportEntry()

        if originalIncident!.number == nil {
            createIncident()
        } else {
            updateIncident()
        }
    }


    @IBAction func reload(sender: AnyObject?) {
        if let number = incident?.number {
            do {
                try dispatchQueueController?.ims.reloadIncidentWithNumber(number)
            } catch {
                alert(title: "Unable to reload incident", message: "\(error)")
            }
        }
    }
        
        
    func updateIncident() {
        var diff = incident!.diffFrom(originalIncident!)
        diff.number = incident!.number
        
        do {
            try dispatchQueueController!.ims.updateIncident(diff)
            disableEditing()
        } catch {
            logError("Unable to update incident: \(error)")
            alert(title: "Unable to update incident", message: "\(error)")
        }
    }

    
    func createIncident() {
        func callback(number: Int) {
            incident!.number = number
            originalIncident = incident

            dispatchQueueController!.incidentControllerDidCreateIncident(self)
        }

        do {
            try dispatchQueueController!.ims.createIncident(incident!, callback: callback)
            disableEditing()
        } catch {
            logError("Unable to create incident: \(error)")
            alert(title: "Unable to create incident", message: "\(error)")
        }
    }
    
    
    func incidentDidUpdate(ims ims: IncidentManagementSystem, updatedIncident: Incident) {
        guard originalIncident!.number == updatedIncident.number else {
            logError("Incident controller for incident \(originalIncident) got an update for a different incident: \(incident)")
            return
        }
        
        // Modify the view such that any changes from originalIncident to
        // updatedIncident are reflected but if there is an unsaved change in
        // the view that wasn't changed in updatedIncident, leave it modified.
        // So if the user modifies a field and someone else saves a change to
        // that field first, the modifications here will get lost, but at least
        // local changes that were not modified by someone else will be
        // preserved.
        
        let diff = updatedIncident.diffFrom(originalIncident!)

        incident = incident!.applyDiff(diff)
        originalIncident = updatedIncident

        func updateView() {
            self.updateView()
            self.enableEditing()
        }
        
        if NSThread.currentThread().isMainThread {
            updateView()
        } else {
            dispatch_sync(dispatch_get_main_queue(), updateView)
        }

        if incident! != originalIncident! {
            do {
                let diff = try incidentAsJSON(incident!.diffFrom(originalIncident!))
                logDebug("Updated incident view but left some changes in place: \(diff)")
            } catch {
                logDebug("Updated incident view but left some changes in place: [ERROR COMPUTING DIFF]")
            }
        } else {
            logDebug("Updated incident view")
        }
    }

}



extension IncidentController: NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()

        func arghEvilDeath(uiElementName: String) {
            fatalError("Incident controller: no \(uiElementName)?")
        }

        if incident                       == nil { arghEvilDeath("incident"                         ) }
        if dispatchQueueController        == nil { arghEvilDeath("dispatch queue controller"        ) }
        if window                         == nil { arghEvilDeath("window"                           ) }
        if numberField                    == nil { arghEvilDeath("number field"                     ) }
        if statePopUp                     == nil { arghEvilDeath("state pop-up"                     ) }
        if priorityPopUp                  == nil { arghEvilDeath("priority pop-up"                  ) }
        if summaryField                   == nil { arghEvilDeath("summary field"                    ) }
        if rangersTable                   == nil { arghEvilDeath("rangers table"                    ) }
        if rangerToAddField               == nil { arghEvilDeath("ranger field"                     ) }
        if typesTable                     == nil { arghEvilDeath("incident types table"             ) }
        if typeToAddField                 == nil { arghEvilDeath("incident type field"              ) }
        if locationNameField              == nil { arghEvilDeath("location name field"              ) }
        if locationRadialAddressField     == nil { arghEvilDeath("location radial address field"    ) }
        if locationConcentricAddressField == nil { arghEvilDeath("location concentric address field") }
        if locationDescriptionField       == nil { arghEvilDeath("location description field"       ) }
        if reportEntriesView              == nil { arghEvilDeath("report entries view"              ) }
        if reportEntryToAddView           == nil { arghEvilDeath("report entry view"                ) }
        if saveButton                     == nil { arghEvilDeath("save button"                      ) }
        if loadingIndicator               == nil { arghEvilDeath("loading indicator"                ) }
        if reloadButton                   == nil { arghEvilDeath("reload button"                    ) }

        // Data sources and delegates are not retained, so we need to hold a reference to them

        rangersTableManager = RangersTableManager(incidentController: self)
        rangersTable!.setDataSource(rangersTableManager)
        rangersTable!.setDelegate(rangersTableManager)
        rangerToAddField!.delegate = rangersTableManager

        typesTableManager = IncidentTypesTableManager(incidentController: self)
        typesTable!.setDataSource(typesTableManager)
        typesTable!.setDelegate(typesTableManager)
        typeToAddField!.delegate = typesTableManager

        locationNameDelegate = LocationNameFieldDelegate(incidentController: self)
        locationNameField!.delegate = locationNameDelegate
        
        concentricAddressDelegate = ConcentricStreetFieldDelegate()
        locationConcentricAddressField!.delegate = concentricAddressDelegate

        addReportEntryDelegate = AddReportEntryViewDelegate(incidentController: self)
        reportEntryToAddView!.delegate = addReportEntryDelegate
        
        // These values can't be reflected as nil in the UI, so let's set them to a value that can.
        if incident!.priority == nil { incident!.priority = IncidentPriority.Normal }
        if incident!.state    == nil { incident!.state    = IncidentState.New       }

        updateView()

        reloadButton!.hidden     = false
        loadingIndicator!.hidden = true

        enableEditing()
    }

    func windowShouldClose(sender: AnyObject) -> Bool {
        if incident! == originalIncident! {
            return true
        }
        
        let alert = NSAlert()

        alert.alertStyle = NSAlertStyle.InformationalAlertStyle
        alert.showsHelp = false
        alert.messageText = "Incident not saved"
        alert.informativeText = "Are you sure you want to close this without saving?"
        alert.addButtonWithTitle("Save")
        alert.addButtonWithTitle("Cancel")
        alert.addButtonWithTitle("Don't Save")
        
        alert.beginSheetModalForWindow(
            window!,
            completionHandler: {
                response -> Void in

                switch response {
                    case 1000:  // Save
                        self.save(self)
                        self.window!.close()
                    case 1001:  // Cancel
                        break
                    case 1002:  // Don't Save
                        self.window!.close()
                    default:
                        logError("Unknown modal response to save safety sheet: \(response)")
                }
            }
        )
        
        return false
    }

}



enum IncidentStateTag: Int {
    case New        = 1
    case OnHold     = 2
    case Dispatched = 3
    case OnScene    = 4
    case Closed     = 5
}



enum IncidentPriorityTag: Int {
    case High   = 1
    case Normal = 3
    case Low    = 5
}
