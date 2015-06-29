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
            logError("No incident type in Rangers table at selected row \(tableView.selectedRow)?")
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