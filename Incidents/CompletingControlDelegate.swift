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
    var startsWithMatchOnly         = false

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
        let fieldEditor = notification.userInfo?["NSFieldEditor"]

        if amBackspacing {
            amBackspacing = false
            if let fieldEditor = fieldEditor {
                fieldEditor.complete(self)
            }
            return
        }
        
        if !amCompleting {
            guard let fieldEditor = fieldEditor else {
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
        let input      = control.stringValue
        let inputLower = input.lowercaseString
        
        var completions: [String]

        if inputLower == "?" {
            completions = completionValues
        }
        else {
            var startsWithCompletions: [String] = []
            var containsCompletions  : [String] = []

            for word in completionValues {
                let word = word as NSString
                
                let wordLower = word.lowercaseString

                if wordLower == inputLower { continue } // Will be added below

                if startsWithMatchOnly {
                    if wordLower.hasPrefix(inputLower) {
                        startsWithCompletions.append(word.substringFromIndex(charRange.location))
                    }
                } else {
                    if wordLower.rangeOfString(inputLower) != nil {
                        if wordLower.hasPrefix(inputLower) {
                            startsWithCompletions.append(word.substringFromIndex(charRange.location))
                        } else {
                            containsCompletions.append(word.substringFromIndex(charRange.location))
                        }
                    }
                }
            }

            completions = []

            if input.characters.count > 0 {  // && allowNonMatchingCompletions
                let input = input as NSString
                completions.append(input.substringFromIndex(charRange.location))
            }

            completions.extend(startsWithCompletions)
            completions.extend(containsCompletions)
        }

//        if completions.count == 1 {
//            control.stringValue = completions[0]
//            return []
//        }
        
        return completions
    }
    
}
