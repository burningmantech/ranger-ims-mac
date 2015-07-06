//
//  DateFormatter.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



// NSDateFormatter doesn't allow you to clear out a text field because it
// considers an empty string to be an invalid date and refuses to accep the
// value.  This implementaion treats that as nil.

class DateFormatter: NSDateFormatter {
    
    override func getObjectValue(
        obj: AutoreleasingUnsafeMutablePointer<AnyObject?>,
        forString string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) -> Bool {
        var result = super.getObjectValue(obj, forString: string, errorDescription: error)
        
        if !result && string.characters.count == 0 {
            obj.memory = nil
            result = true
        }
        
        return result
    }
    
}
