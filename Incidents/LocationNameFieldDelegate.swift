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
        guard let locationsByLowercaseName = incidentController.dispatchQueueController?.locationsByLowercaseName else {
            logError("Can't complete; no locations?")
            return []
        }
        
        var locationNames: [String] = []

        for locationLowerName in locationsByLowercaseName.keys {
            guard let location = locationsByLowercaseName[locationLowerName] else { continue }
            guard let name = location.name else { continue }
            locationNames.append(name)
        }

        return locationNames.sort()
    }
    
}
