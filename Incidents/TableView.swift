//
//  TableView.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class TableView: NSTableView {
    
    override func keyDown(theEvent: NSEvent) {
        guard let delegate = self.delegate() as? TableViewDelegate else {
            logError("Table view has no delegate: \(self)")
            return
        }
        
        if selectedRow == -1 { return }
        
        // We're looking for exactly one character
        
        guard let characterString = theEvent.charactersIgnoringModifiers else { return }
        guard characterString.characters.count == 1 else { return }
        
        let key = characterString[characterString.startIndex]
        
        logDebug("Key: \(key)")
        
        // key == NSDeleteCharacter
        // delegate.deleteFromTableView(self), return
        
        // key == NSCarriageReturnCharacter, NSEnterCharacter, NSNewlineCharacter
        // delegate.openFromTableView(self), return
        
        super.keyDown(theEvent)
    }
    
}



protocol TableViewDelegate: NSTableViewDelegate {

    func deleteFromTableView(tableView: TableView)
    func openFromTableView(tableView: TableView)

}
