//
//  AppDelegate.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



@NSApplicationMain
class AppDelegate: NSObject {

    @IBOutlet weak var window: NSWindow!


    var preferencesController: PreferencesController {
        if _preferencesController == nil {
            _preferencesController = PreferencesController(appDelegate: self)
        }
        return _preferencesController!
    }
    private var _preferencesController: PreferencesController!

    var dispatchQueueController: DispatchQueueController {
        if _dispatchQueueController == nil {
            _dispatchQueueController = DispatchQueueController(appDelegate: self)
        }
        return _dispatchQueueController!
    }
    private var _dispatchQueueController: DispatchQueueController!


    @IBAction func showPreferences(sender: AnyObject) {
        preferencesController.showWindow(self)
    }


    @IBAction func showDispatchQueue(sender: AnyObject) {
        dispatchQueueController.showWindow(self)
    }

}



extension AppDelegate: NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        self.showDispatchQueue(self)
    }


    func applicationWillTerminate(aNotification: NSNotification) {
    }

}