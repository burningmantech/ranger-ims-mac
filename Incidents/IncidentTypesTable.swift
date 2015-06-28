//
//  IncidentTypesTable.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class IncidentTypesTableManager: NSObject {
    
    var incident: Incident

    
    init(incident: Incident) {
        self.incident = incident
    }
    

    func incidentTypeAtIndex(index: Int) -> String? {
        guard index >= 0 else {
            logError("Negative incident types table index: \(index)")
            return nil
        }
        
        guard let incidentTypes = incident.incidentTypes else { return nil }
        
        guard index < incidentTypes.count else {
            logError("Incident types table index out of bounds: \(index)")
            return nil
        }
        
        let sortedIncidentTypes = incidentTypes.sort()
        let incidentType = sortedIncidentTypes[index]
        
        return incidentType
    }

}



extension IncidentTypesTableManager: NSTableViewDataSource {

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        guard let incidentTypes = incident.incidentTypes else { return 0 }
        return incidentTypes.count
    }
    
    
    func tableView(
        tableView: NSTableView,
        objectValueForTableColumn tableColumn: NSTableColumn?,
        row: Int
    ) -> AnyObject? {
        return self.incidentTypeAtIndex(row)
    }
    
}



extension IncidentTypesTableManager: TableViewDelegate {

    func deleteFromTableView(tableView: TableView) {
        guard tableView.selectedRow != -1 else {
            logError("Deleting from incident types table with no selected row?")
            return
        }
        
        guard let incidentTypes = incident.incidentTypes else {
            logError("Deleting from incident types table when incident has no incident types?")
            return
        }

        guard let incidentTypeToRemove = incidentTypeAtIndex(tableView.selectedRow) else {
            logError("No incident type in incident types table at selected row \(tableView.selectedRow)?")
            return
        }
        
        var newTypes = incidentTypes
        newTypes.remove(incidentTypeToRemove)
        incident.incidentTypes = newTypes

        tableView.reloadData()
    }
    
    
    func openFromTableView(tableView: TableView) {}
    
}
