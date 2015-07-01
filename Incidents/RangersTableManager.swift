//
//  RangersTableDelegate.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class RangersTableManager: NSObject {

    var incidentController: IncidentController

    var amCompleting  = false
    var amBackspacing = false
    

    init(incidentController: IncidentController) {
        self.incidentController = incidentController
    }

    
    func rangerAtIndex(index: Int) -> Ranger? {
        guard index >= 0 else {
            logError("Negative table index: \(index)")
            return nil
        }
        
        guard let rangers = incidentController.incident?.rangers else { return nil }
        
        guard index < rangers.count else {
            logError("Rangers table index out of bounds: \(index)")
            return nil
        }
        
        let sortedRangers = rangers.sort()
        let ranger = sortedRangers[index]
        
        return ranger
    }
    
}



extension RangersTableManager: NSTableViewDataSource {

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        guard let rangers = incidentController.incident?.rangers else { return 0 }
        return rangers.count
    }


    func tableView(
        tableView: NSTableView,
        objectValueForTableColumn tableColumn: NSTableColumn?,
        row: Int
    ) -> AnyObject? {
        if let ranger = rangerAtIndex(row) {
            return ObjCObjectContainer(ranger)
        } else {
            return nil
        }
    }

}



extension RangersTableManager: TableViewDelegate {
    
    func deleteFromTableView(tableView: TableView) {
        guard tableView.selectedRow != -1 else {
            logError("Deleting from Rangers table with no selected row?")
            return
        }
        
        guard let rangers = incidentController.incident?.rangers else {
            logError("Deleting from Rangers table when incident has no Rangers?")
            return
        }
        
        guard let rangerToRemove = rangerAtIndex(tableView.selectedRow) else {
            logError("No Ranger in Rangers table at selected row \(tableView.selectedRow)?")
            return
        }

        var newRangers = rangers
        newRangers.remove(rangerToRemove)
        incidentController.incident!.rangers = newRangers

        incidentController.markEdited()
        incidentController.updateView()
    }
    
    
    func openFromTableView(tableView: TableView) {}
    
}



extension RangersTableManager: NSControlTextEditingDelegate, NSTextFieldDelegate {
    
    func control(
        control: NSControl,
        textView: NSTextView,
        doCommandBySelector commandSelector: Selector
        ) -> Bool {
            guard control === incidentController.rangerToAddField else {
                logError("doCommandBySelector sent via unknown Ranger to add control: \(control)")
                return false
            }
            
            switch commandSelector {
                case Selector("deleteBackward:"):
                    if control.stringValue.characters.count > 0 {
                        amBackspacing = true
                    }
                    return false
                
                case Selector("insertNewline:"):
                    let handle = control.stringValue
                    
                    if handle.characters.count > 0 {
                        guard incidentController.incident != nil else {
                            logError("doCommandBySelector via Ranger to add control with no incident?")
                            return true
                        }
                        
                        guard let ranger = incidentController.dispatchQueueController?.ims.rangersByHandle[handle] else {
                            logDebug("Unknown Ranger handle: \(handle)")
                            return true
                        }
                        
                        var rangers: Set<Ranger>
                        if incidentController.incident!.rangers == nil {
                            rangers = []
                        } else {
                            rangers = incidentController.incident!.rangers!
                        }
                        rangers.insert(ranger)
                        
                        incidentController.incident!.rangers = rangers
                        
                        incidentController.markEdited()
                        incidentController.updateView()
                        
                        control.stringValue = ""
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
        
        guard let allHandles = incidentController.dispatchQueueController?.ims.rangersByHandle.keys else {
            logError("Can't complete; no Ranger handles?")
            return []
        }
        
        var result: [String] = []
        
        if currentWord == "?" {
            for handle in allHandles {
                result.append(handle)
            }
        }
        else {
            for handle in allHandles {
                if handle.lowercaseString.hasPrefix(currentWord) {
                    result.append(handle)
                }
            }
        }
        
        return result
    }

}



class ObjCObjectContainer: NSObject, NSCopying {

    var object: CustomStringConvertible
    

    init(_ object: CustomStringConvertible) {
        self.object = object
    }

    
    override var description: String {
        return object.description
    }

    
    func copyWithZone(zone: NSZone) -> AnyObject {
        // FIXME: This seems to work, but shouldn't we be using allocWithZone:?
        return ObjCObjectContainer(object)
    }

}