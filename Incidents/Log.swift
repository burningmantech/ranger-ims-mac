//
//  Log.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Foundation



func logInfo(format: String? = nil) {
    // FIXME
    if format != nil {
        NSLog("[INFO] " + format!)
    }
}



func logError(format: String? = nil) {
    // FIXME
    if format != nil {
        NSLog("[ERROR] " + format!)
    }
}
