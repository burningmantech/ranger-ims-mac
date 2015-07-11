//
//  PasswordController.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class PasswordController: NSWindowController {
    
    var dispatchQueueController: DispatchQueueController?
    
    
    var imsUsername: String? {
        get { return dispatchQueueController?.imsUsername }
        set { dispatchQueueController?.imsUsername = newValue }
    }

    
    var imsPassword: String? {
        get { return dispatchQueueController?.imsPassword }
        set { dispatchQueueController?.imsPassword = newValue }
    }

    
    convenience init(dispatchQueueController: DispatchQueueController) {
        self.init(windowNibName: "Password")
        self.dispatchQueueController = dispatchQueueController
    }
    
    
    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    @IBAction func done(sender: AnyObject?) {
        self.close()
        NSApp.stopModal()
    }

}



extension PasswordController: NSWindowDelegate {
}
