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
        
        // FIXME: Seem janky that I have to cast to NSString, etc here
        
        // We're looking for exactly one character
        guard let characterString: NSString = theEvent.charactersIgnoringModifiers else { return }
        guard characterString.length == 1 else { return }
        let key = characterString.characterAtIndex(0)
        
        switch key {
            case unichar(NSDeleteCharacter):
                delegate.deleteFromTableView?(self)
            case unichar(NSCarriageReturnCharacter), unichar(NSEnterCharacter):
                delegate.openFromTableView?(self)
            default:
                break
        }
        
        super.keyDown(theEvent)
    }
    
}



@objc
protocol TableViewDelegate: NSTableViewDelegate {

    optional func deleteFromTableView(tableView: TableView)
    optional func openFromTableView(tableView: TableView)

}
