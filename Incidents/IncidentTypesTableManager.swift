//
//  IncidentTypesTable.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class IncidentTypesTableManager: NSObject {
    
    var incidentController: IncidentController
    
    
    init(incidentController: IncidentController) {
        self.incidentController = incidentController
    }
    

    func incidentTypeAtIndex(index: Int) -> String? {
        guard index >= 0 else {
            logError("Negative incident types table index: \(index)")
            return nil
        }
        
        guard let incidentTypes = incidentController.incident?.incidentTypes else { return nil }
        
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
        guard let incidentTypes = incidentController.incident?.incidentTypes else { return 0 }
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
        
        guard let incidentTypes = incidentController.incident?.incidentTypes else {
            logError("Deleting from incident types table when incident has no incident types?")
            return
        }

        guard let incidentTypeToRemove = incidentTypeAtIndex(tableView.selectedRow) else {
            logError("No incident type in incident types table at selected row \(tableView.selectedRow)?")
            return
        }
        
        var newTypes = incidentTypes
        newTypes.remove(incidentTypeToRemove)
        incidentController.incident!.incidentTypes = newTypes

        incidentController.markEdited()
        incidentController.updateView()
    }
    
    
    func openFromTableView(tableView: TableView) {}
    
}



extension IncidentTypesTableManager: NSControlTextEditingDelegate, NSTextFieldDelegate {

    func control(
        control: NSControl,
        textView: NSTextView,
        doCommandBySelector commandSelector: Selector
    ) -> Bool {
        guard control === incidentController.typeToAddField else {
            logError("doCommandBySelector sent via unknown incident type to add control: \(control)")
            return false
        }
        
        switch commandSelector {
            case Selector("insertNewline:"):
                let incidentType = control.stringValue

                if incidentType.characters.count > 0 {
                    guard incidentController.incident != nil else {
                        logError("doCommandBySelector via incident type to add control with no incident?")
                        return true
                    }
                    
                    // FIXME: Make sure incidentType is a known value
                    
                    var incidentTypes: Set<String>
                    if incidentController.incident!.incidentTypes == nil {
                        incidentTypes = []
                    } else {
                        incidentTypes = incidentController.incident!.incidentTypes!
                    }
                    incidentTypes.insert(incidentType)

                    incidentController.incident!.incidentTypes = incidentTypes
                    
                    incidentController.markEdited()
                    incidentController.updateView()

                    control.stringValue = ""
                }

                return true

            default:
                return false
        }
    }

}
