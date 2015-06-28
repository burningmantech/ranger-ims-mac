//
//  RangersTableDelegate.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class RangersTableManager: NSObject {

    let incident: Incident
    

    init(incident: Incident) {
        self.incident = incident
    }

}



extension RangersTableManager: NSTableViewDataSource {

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        guard let rangers = incident.rangers else { return 0 }
        return rangers.count
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

        guard let rangers = incident.rangers else { return nil }

        guard row < rangers.count else {
            logError("Rangers table row out of bounds: \(row)")
            return nil
        }

        let sortedRangers = rangers.sort()
        let ranger = sortedRangers[row]

        return ObjCObjectContainer(ranger)
    }

}



extension RangersTableManager: TableViewDelegate {
    
    func deleteFromTableView(tableView: TableView) {
        // let rowIndex = tableView.selectedRow
        
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