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

    @IBOutlet weak var window: NSWindow?
    @IBOutlet weak var debugMenu: NSMenuItem?


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


    @IBAction func serverSettingsDidChange(sender: AnyObject) {
        if _dispatchQueueController != nil {
            _dispatchQueueController.close()
            _dispatchQueueController = nil
        }
    }


    @IBAction func newIncident(sender: AnyObject) {
        dispatchQueueController.newIncident(self)
    }


    func showHideDebugMenu() {
        let defaults = NSUserDefaults.standardUserDefaults()

        if defaults.boolForKey("EnableDebugMenu") {
            debugMenu?.hidden = false
        } else {
            debugMenu?.hidden = true
        }

    }


    @IBAction func showNewIncidents(sender: AnyObject) {
        let count = dispatchQueueController.newIncidentControllers.count
        alert(title: "New Incidents", message: "Total: \(count)")
    }
    
    
    @IBAction func showOpenIncidents(sender: AnyObject) {
        let numbers = Array(dispatchQueueController.incidentControllers.keys)
        alert(title: "Open Incidents", message: "\(numbers)")
    }


    @IBAction func showRangers(sender: AnyObject) {
        let rangers = Array(dispatchQueueController.ims.rangersByHandle.values)
        alert(title: "Rangers", message: "\(rangers)")
    }


    @IBAction func showIncidentTypes(sender: AnyObject) {
        let incidentTypes = Array(dispatchQueueController.ims.incidentTypes)
        alert(title: "Rangers", message: "\(incidentTypes)")
    }


    @IBAction func showLocations(sender: AnyObject) {
        let locations = Array(dispatchQueueController.ims.locationsByName.values)
        alert(title: "Rangers", message: "\(locations)")
    }

}



extension AppDelegate: NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        showHideDebugMenu()

        let defaults = NSUserDefaults.standardUserDefaults()

        if defaults.stringForKey("IMSServerHostName") == nil {
            showPreferences(self)
        } else {
            showDispatchQueue(self)
        }
    }


    func applicationWillTerminate(aNotification: NSNotification) {
    }

}