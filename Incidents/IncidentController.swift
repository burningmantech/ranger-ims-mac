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

    @IBOutlet weak var numberField         : NSTextField!
    @IBOutlet weak var statePopUp          : NSPopUpButton!
    @IBOutlet weak var priorityPopUp       : NSPopUpButton!
    @IBOutlet weak var summaryField        : NSTextField!
    @IBOutlet weak var rangersTable        : NSTableView!
    @IBOutlet weak var rangerToAddField    : NSTextField!
    @IBOutlet weak var typesTable          : NSTableView!
    @IBOutlet weak var typeToAddField      : NSTextField!
    @IBOutlet weak var locationNameField   : NSTextField!
//  @IBOutlet weak var locationAddressField: NSTextField!
    @IBOutlet weak var reportEntriesView   : NSTextField!
    @IBOutlet weak var reportEntryToAddView: NSTextField!
    @IBOutlet weak var saveButton          : NSButton!
    @IBOutlet weak var loadingIndicator    : NSProgressIndicator!
    @IBOutlet weak var reloadButton        : NSButton!


    convenience init(dispatchQueueController: DispatchQueueController) {
        self.init(windowNibName: "Incident")

        self.dispatchQueueController = dispatchQueueController
    }


    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}
