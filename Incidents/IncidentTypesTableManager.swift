//
//  IncidentTypesTable.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class IncidentTypesTableManager: TableManager {

    override var tableRowValues: [AnyObject] {
        guard let incidentTypes = incidentController.incident?.incidentTypes else { return [] }
        
        return incidentTypes.sort()
    }
    
    
    override var stringValues: [String] {
        guard let incidentTypes = incidentController.incident?.incidentTypes else { return [] }

        return Array(incidentTypes)
    }
    
    
    override func addStringValue(value: String) -> Bool {
        guard incidentController.incident != nil else {
            logError("Can't add incident type with no incident?")
            return false
        }
        
        guard let knownIncidentTypes = incidentController.dispatchQueueController?.ims.incidentTypes else {
            logError("No incident types?")
            return false
        }

        guard knownIncidentTypes.contains(value) else {
            logDebug("Unknown incident type: \(value)")
            return false
        }
        
        var incidentTypes: Set<String>
        if incidentController.incident!.incidentTypes == nil {
            incidentTypes = []
        } else {
            incidentTypes = incidentController.incident!.incidentTypes!
        }
        incidentTypes.insert(value)
        
        incidentController.incident!.incidentTypes = incidentTypes
        
        return true
    }
    
    
    override func removeValue(value: AnyObject) {
        guard let incidentTypes = incidentController.incident?.incidentTypes else {
            logError("Deleting from incident types table when incident has no incident types?")
            return
        }
        
        guard let incidentTypeToRemove = value as? String else {
            logError("Deleting from incident types expects a String, not \(value)?")
            return
        }

        var newIncidentTypes = incidentTypes
        newIncidentTypes.remove(incidentTypeToRemove)
        incidentController.incident!.incidentTypes = newIncidentTypes
    }
    
}
