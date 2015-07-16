//
//  RangersTableDelegate.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class RangersTableManager: TableManager {

    override var tableRowValues: [AnyObject] {
        guard let rangers = incidentController.incident?.rangers else { return [] }

        var result: [AnyObject] = []
        for ranger in rangers.sort() { result.append(ObjCObjectContainer(ranger)) }
        return result
    }


    override var completionValues: [String] {
        guard let allHandles = incidentController.dispatchQueueController?.ims.rangersByHandle.keys else {
            logError("Can't complete; no Ranger handles?")
            return []
        }

        return allHandles.sort()
    }


    override func addStringValue(value: String) -> Bool {
        guard incidentController.incident != nil else {
            logError("Can't add Ranger with no incident?")
            return false
        }
        
        guard let ranger = incidentController.dispatchQueueController?.ims.rangersByHandle[value] else {
            logDebug("Unknown Ranger handle: \(value)")
            return false
        }
        
        var rangers: Set<Ranger>
        if incidentController.incident!.rangers == nil {
            rangers = []
        } else {
            rangers = incidentController.incident!.rangers!
        }
        rangers.insert(ranger)
        
        incidentController.incident!.rangers = rangers

        return true
    }

    
    override func removeValue(value: AnyObject) {
        guard let rangers = incidentController.incident?.rangers else {
            logError("Deleting from Rangers table when incident has no Rangers?")
            return
        }

        guard let container = value as? ObjCObjectContainer else {
            logError("Deleting from Rangers expects an ObjCObjectContainer, not \(value)?")
            return
        }

        guard let rangerToRemove = container.object as? Ranger else {
            logError("Deleting from Rangers expects an ObjCObjectContainer with a Ranger, not \(container.object)?")
            return
        }

        var newRangers = rangers
        newRangers.remove(rangerToRemove)
        incidentController.incident!.rangers = newRangers
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