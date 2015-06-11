//
//  Log.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Foundation



// FIXME: Do this better



func logDebug(format: String? = nil) {
    if format != nil {
        NSLog("[DEBUG] " + format!)
    }
}



func logInfo(format: String? = nil) {
    if format != nil {
        NSLog("[INFO] " + format!)
    }
}



func logError(format: String? = nil) {
    if format != nil {
        NSLog("[ERROR] " + format!)
    }
}
