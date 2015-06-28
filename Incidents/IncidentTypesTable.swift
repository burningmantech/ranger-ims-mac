//
//  IncidentTypesTable.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class IncidentTypesTableManager: NSObject {
    
    let incident: Incident
    
    
    init(incident: Incident) {
        self.incident = incident
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
        guard row >= 0 else {
            logError("Negative table row: \(row)")
            return nil
        }
        
        guard let incidentTypes = incident.incidentTypes else { return nil }
        
        guard row < incidentTypes.count else {
            logError("Incident types table row out of bounds: \(row)")
            return nil
        }
        
        let sortedIncidentTypes = incidentTypes.sort()
        let incidentType = sortedIncidentTypes[row]
        
        return incidentType
    }
    
}



extension IncidentTypesTableManager: TableViewDelegate {

    func deleteFromTableView(tableView: TableView) {
        // let rowIndex = tableView.selectedRow
        
    }
    
    
    func openFromTableView(tableView: TableView) {}
    
}
