//
//  AddReportEntryViewDelegate.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class AddReportEntryViewDelegate: NSObject, NSTextViewDelegate {
    
    var incidentController: IncidentController
    
    
    init(incidentController: IncidentController) {
        self.incidentController = incidentController
    }

    
    func textDidChange(notification: NSNotification) {
        incidentController.updateEdited()
    }

}
