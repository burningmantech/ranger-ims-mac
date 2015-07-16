//
//  Alert.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



func alert(title title: String = "Alert", message: String = "") {
    logInfo("\(title): \(message)")
    
    dispatch_async(
        dispatch_get_main_queue(),
        {
            let alert = NSAlert()

            alert.alertStyle = NSAlertStyle.InformationalAlertStyle
            alert.showsHelp = false
            alert.messageText = title
            alert.informativeText = message

            alert.runModal()
        }
    )
}
