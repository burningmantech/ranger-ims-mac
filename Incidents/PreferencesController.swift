//
//  PreferencesController.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class PreferencesController: NSWindowController {

    var appDelegate: AppDelegate!


    convenience init(appDelegate: AppDelegate) {
        self.init(windowNibName: "Preferences")
        self.appDelegate = appDelegate
    }


    override init(window: NSWindow?) {
        super.init(window: window)
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    @IBAction func serverSettingsDidChange(sender: AnyObject) {
        if appDelegate != nil {
            appDelegate.serverSettingsDidChange(self)
        }
    }


    @IBAction func toggleDebugMenu(sender: AnyObject) {
        appDelegate.showHideDebugMenu()
    }
    
}



extension PreferencesController: NSWindowDelegate {
}
