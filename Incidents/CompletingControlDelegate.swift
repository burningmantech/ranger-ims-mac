//
//  CompletingControlDelegate.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class CompletingControlDelegate: NSObject, NSTextFieldDelegate {

    var amCompleting  = false
    var amBackspacing = false

    
    var completionValues: [String] { return [] }

    
    func control(
        control: NSControl,
        textView: NSTextView,
        doCommandBySelector commandSelector: Selector
    ) -> Bool {
        switch commandSelector {
        case Selector("deleteBackward:"):
            if control.stringValue.characters.count > 0 {
                amBackspacing = true
            }
            return false
            
        default:
            return false
        }
    }
    
    
    override func controlTextDidChange(notification: NSNotification) {
        if amBackspacing {
            amBackspacing = false
            return
        }
        
        if !amCompleting {
            guard let fieldEditor = notification.userInfo?["NSFieldEditor"] else {
                logError("No field editor?")
                return
            }
            
            // fieldEditor.complete() will trigger another call to
            // controlTextDidChange(), so we avoid infinite recursion with
            // the amCompleting variable.
            
            amCompleting = true
            fieldEditor.complete(self)
            amCompleting = false
        }
    }
    
    
    func control(
        control: NSControl,
        textView: NSTextView,
        completions words: [String],
        forPartialWordRange charRange: NSRange,
        indexOfSelectedItem index: UnsafeMutablePointer<Int>
    ) -> [String] {
        let currentWord = control.stringValue.lowercaseString
        
        if currentWord == "?" { return completionValues }
        
        var result: [String] = []
        for handle in completionValues {
            if handle.lowercaseString.hasPrefix(currentWord) {
                result.append(handle)
            }
        }
        return result
    }
    
}
