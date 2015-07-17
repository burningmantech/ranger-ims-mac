//
//  LocationNameFieldDelegate.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class LocationNameFieldDelegate: CompletingControlDelegate {
    
    var incidentController: IncidentController

    
    init(incidentController: IncidentController) {
        self.incidentController = incidentController
    }
    
    
    override var completionValues: [String] {
        guard let allHandles = incidentController.dispatchQueueController?.ims.locationsByName.keys else {
            logError("Can't complete; no locations?")
            return []
        }
        
        return allHandles.sort()
    }
    
}