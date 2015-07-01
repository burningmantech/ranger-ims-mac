//
//  TableManager.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class TableManager: NSObject {
    
    var incidentController: IncidentController
    
    var amCompleting  = false
    var amBackspacing = false

    var tableRowValues: [AnyObject] { return [] }
    var stringValues: [String] { return [] }
    
    
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
        
        incidentController.markEdited()
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



extension TableManager: NSControlTextEditingDelegate, NSTextFieldDelegate {
    
    func control(
        control: NSControl,
        textView: NSTextView,
        doCommandBySelector commandSelector: Selector
    ) -> Bool {
        switch commandSelector {
            case Selector("deleteBackward:"):
                if control.stringValue.characters.count > 0 {
                    amBackspacing = true
                }
                return false
                
            case Selector("insertNewline:"):
                let value = control.stringValue
                
                if value.characters.count > 0 {
                    if addStringValue(value) {
                        incidentController.markEdited()
                        incidentController.updateView()
                    
                        control.stringValue = ""
                    }
                }
                
                return true
                
            default:
                return false
        }
    }
    
    
    override func controlTextDidChange(notification: NSNotification) {
        if amBackspacing {
            amBackspacing = false
            return
        }
        
        if !amCompleting {
            guard let fieldEditor = notification.userInfo?["NSFieldEditor"] else {
                logError("No field editor?")
                return
            }
            
            // fieldEditor.complete() will trigger another call to
            // controlTextDidChange(), so we avoid infinite recursion with
            // the amCompleting variable.
            
            amCompleting = true
            fieldEditor.complete(self)
            amCompleting = false
        }
    }
    
    
    func control(
        control: NSControl,
        textView: NSTextView,
        completions words: [String],
        forPartialWordRange charRange: NSRange,
        indexOfSelectedItem index: UnsafeMutablePointer<Int>
    ) -> [String] {
        let currentWord = control.stringValue.lowercaseString
        
        if currentWord == "?" { return stringValues }

        var result: [String] = []
        for handle in stringValues {
            if handle.lowercaseString.hasPrefix(currentWord) {
                result.append(handle)
            }
        }
        return result
    }
    
}
