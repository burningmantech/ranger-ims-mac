//
//  TableManager.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class TableManager: CompletingControlDelegate {
    
    var incidentController: IncidentController
    
    var tableRowValues: [AnyObject] { return [] }  // sorted

    override var completionValues: [String] { return [] }

    init(incidentController: IncidentController) {
        self.incidentController = incidentController
    }
    

    // FIXME
    func addStringValue(value: String) -> Bool {
        assert(false, "Unimplemented by subclass")
    }

    
    // FIXME
    func removeValue(value: AnyObject) {
        assert(false, "Unimplemented by subclass")
    }
    
    
    func objectAtIndex(index: Int) -> AnyObject? {
        guard index >= 0 else {
            logError("Negative table index: \(index)")
            return nil
        }
        
        guard index < tableRowValues.count else {
            logError("Table index out of bounds: \(index)")
            return nil
        }
        
        return tableRowValues[index]
    }
    
}



extension TableManager: TableViewDelegate {
    
    func deleteFromTableView(tableView: TableView) {
        guard tableView.selectedRow != -1 else {
            logError("Deleting from table with no selected row?")
            return
        }
        
        guard tableRowValues.count > tableView.selectedRow else {
            logError("Selected row \(tableView.selectedRow) out of bounds?")
            return
        }
        
        removeValue(tableRowValues[tableView.selectedRow])
        
        incidentController.updateView()
    }
    
    
    // func openFromTableView(tableView: TableView) {}
    
}



extension TableManager: NSTableViewDataSource {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return tableRowValues.count
    }
    
    
    func tableView(
        tableView: NSTableView,
        objectValueForTableColumn tableColumn: NSTableColumn?,
        row: Int
    ) -> AnyObject? {
        if let value = objectAtIndex(row) {
            return value
        } else {
            return nil
        }
    }
    
}



extension TableManager {  // NSTextFieldDelegate
    
    override func control(
        control: NSControl,
        textView: NSTextView,
        doCommandBySelector commandSelector: Selector
    ) -> Bool {
        switch commandSelector {
            case Selector("insertNewline:"):
                let value = control.stringValue
                
                if value.characters.count > 0 {
                    if addStringValue(value) {
                        incidentController.updateView()
                        
                        control.stringValue = ""
                    }
                }
                
                return true
                
            default:
                return super.control(
                    control,
                    textView: textView,
                    doCommandBySelector: commandSelector
                )
        }
    }
    
    }
