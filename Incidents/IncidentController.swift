//
//  IncidentController.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class IncidentController: NSWindowController {

    var dispatchQueueController: DispatchQueueController!

    var incident: Incident?

    @IBOutlet weak var numberField                   : NSTextField!
    @IBOutlet weak var statePopUp                    : NSPopUpButton!
    @IBOutlet weak var priorityPopUp                 : NSPopUpButton!
    @IBOutlet weak var summaryField                  : NSTextField!
    @IBOutlet weak var rangersTable                  : NSTableView!
    @IBOutlet weak var rangerToAddField              : NSTextField!
    @IBOutlet weak var typesTable                    : NSTableView!
    @IBOutlet weak var typeToAddField                : NSTextField!
    @IBOutlet weak var locationNameField             : NSTextField!
    @IBOutlet weak var locationRadialAddressField    : NSTextField!
    @IBOutlet weak var locationConcentricAddressField: NSTextField!
    @IBOutlet weak var locationDescriptionField      : NSTextField!
    @IBOutlet weak var reportEntriesScrollView       : NSScrollView!  // Can't connect NSTextView because weak sauce
    @IBOutlet weak var reportEntryToAddScrollView    : NSScrollView!  // Can't connect NSTextView because weak sauce
    @IBOutlet weak var saveButton                    : NSButton!
    @IBOutlet weak var loadingIndicator              : NSProgressIndicator!
    @IBOutlet weak var reloadButton                  : NSButton!


    var reportEntriesView: NSTextView! {
        return reportEntriesScrollView?.contentView.documentView as? NSTextView
    }


    var reportEntryToAddView: NSTextView! {
        return reportEntryToAddScrollView?.contentView.documentView as? NSTextView
    }


    convenience init(dispatchQueueController: DispatchQueueController, incident: Incident) {
        self.init(windowNibName: "Incident")

        self.dispatchQueueController = dispatchQueueController
        self.incident = incident
    }


    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    func updateView() {
        guard let incident = self.incident else {
            logError("Incident controller has no incident?")
            return
        }

        let numberToDisplay: String

        if let number = incident.number {
            numberToDisplay = "\(number)"
        } else {
            numberToDisplay = "(new)"
        }

        numberField?.stringValue = "\(numberToDisplay)"

        window?.title = "\(numberToDisplay): \(incident.summaryAsText)"

        let stateTag: IncidentStateTag

        if let state = incident.state {
            switch state {
            case .New       : stateTag = .New
            case .OnHold    : stateTag = .OnHold
            case .Dispatched: stateTag = .Dispatched
            case .OnScene   : stateTag = .OnScene
            case .Closed    : stateTag = .Closed
            }
        } else {
            stateTag = .New
        }

        statePopUp.selectItemWithTag(stateTag.rawValue)
    }


    func enableEditing() {
        statePopUp?.enabled = true
        priorityPopUp?.enabled = true
        summaryField?.enabled = true
        rangersTable?.enabled = true
        rangerToAddField?.enabled = true
        typesTable?.enabled = true
        typeToAddField?.enabled = true
        locationNameField?.enabled = true
        locationRadialAddressField?.enabled = true
        locationConcentricAddressField?.enabled = true
        locationDescriptionField?.enabled = true
      //reportEntriesView?.editable = true
        reportEntryToAddView?.editable = true
        saveButton?.enabled = true
    }


    func disableEditing() {
        statePopUp?.enabled = false
        priorityPopUp?.enabled = false
        summaryField?.enabled = false
        rangersTable?.enabled = false
        rangerToAddField?.enabled = false
        typesTable?.enabled = false
        typeToAddField?.enabled = false
        locationNameField?.enabled = false
        locationRadialAddressField?.enabled = false
        locationConcentricAddressField?.enabled = false
        locationDescriptionField?.enabled = false
      //reportEntriesView?.editable = false
        reportEntryToAddView?.editable = false
        saveButton?.enabled = false
    }

}



extension IncidentController: NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()

        func arghEvilDeath(uiElementName: String) {
            fatalError("Incident controller: no \(uiElementName)?")
        }

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

        updateView()

        reloadButton.hidden     = false
        loadingIndicator.hidden = true

        enableEditing()
    }

}



enum IncidentStateTag: Int {
    case New        = 1
    case OnHold     = 2
    case Dispatched = 3
    case OnScene    = 4
    case Closed     = 5
}
