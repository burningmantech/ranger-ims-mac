//
//  CompletingControlDelegate.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class CompletingControlDelegate: NSObject, NSTextFieldDelegate {

    var allowNonMatchingCompletions = true
    
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
        let input       = control.stringValue
        let currentWord = input.lowercaseString
        
        var completions: [String]

        if currentWord == "?" {
            completions = completionValues
        }
        else {
            completions = []

            if allowNonMatchingCompletions && input.characters.count > 0 {
                completions.append(input)
            }

            for word in completionValues {
                if word.lowercaseString.hasPrefix(currentWord) {
                    completions.append(word)
                }
            }
        }

        if completions.count == 1 {
            control.stringValue = completions[0]
            return []
        }
        
        return completions
    }
    
}
