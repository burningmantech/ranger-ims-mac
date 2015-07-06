//
//  IncidentController_view.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



extension IncidentController {

    func updateView() {
        guard let incident = self.incident else {
            logError("Incident controller has no incident?")
            return
        }
        
        if let number = incident.number {
            window?.title = "\(number): \(incident.summaryAsText)"
        } else {
            window?.title = "New incident: \(incident.summaryAsText)"
        }
        
        updateNumberView(incident.number)
        updateStateView(incident.state)
        updatePriorityView(incident.priority)
        updateSummaryView(incident.summary, alternate: incident.summaryAsText)
        
        rangersTable?.reloadData()
        typesTable?.reloadData()
        
        updateLocationView(incident.location)
        updateReportEntriesView(incident.reportEntries)

        updateEdited()
    }
    
    
    func updateEdited() {
        let edited = incident != originalIncident
        
        window?.documentEdited = edited
        saveButton?.enabled = edited
    }
    
    
    func updateNumberView(number: Int?) {
        let numberToDisplay: String
        
        if let number = number {
            numberToDisplay = "\(number)"
        } else {
            numberToDisplay = "(new)"
        }
        
        numberField?.stringValue = "\(numberToDisplay)"
    }
    
    
    func updateStateView(state: IncidentState?) {
        let stateTag: IncidentStateTag
        
        if let state = state {
            switch state {
            case .New       : stateTag = .New
            case .OnHold    : stateTag = .OnHold
            case .Dispatched: stateTag = .Dispatched
            case .OnScene   : stateTag = .OnScene
            case .Closed    : stateTag = .Closed
            }
        } else {
            stateTag = .New
        }
        
        statePopUp?.selectItemWithTag(stateTag.rawValue)
    }
    
    
    func updatePriorityView(priority: IncidentPriority?) {
        let priorityTag: IncidentPriorityTag
        
        if let priority = priority {
            switch priority {
            case .High  : priorityTag = .High
            case .Normal: priorityTag = .Normal
            case .Low   : priorityTag = .Low
            }
        } else {
            priorityTag = .Normal
        }
        
        priorityPopUp?.selectItemWithTag(priorityTag.rawValue)
    }
    
    
    func updateSummaryView(summary: String?, alternate: String? = nil) {
        if let summary = summary {
            if summary.characters.count != 0 {
                summaryField?.stringValue = summary
                return
            }
        }
        
        summaryField?.stringValue = ""
        
        if let alternate = alternate {
            summaryField?.placeholderString = alternate
        }
    }
    
    
    func updateLocationView(location: Location?) {
        guard let location = location else {
            locationNameField?.stringValue = ""
            locationRadialAddressField?.stringValue = ""
            locationConcentricAddressField?.stringValue = ""
            locationDescriptionField?.stringValue = ""
            return
        }
        
        if let name = location.name {
            locationNameField?.stringValue = name
        } else {
            locationNameField?.stringValue = ""
        }
        
        if let address = location.address as? RodGarettAddress {
            if let radialHour = address.radialHour, radialMinute = address.radialMinute {
                locationRadialAddressField?.stringValue = "\(radialHour):\(radialMinute)"
            } else {
                locationRadialAddressField?.stringValue = ""
            }
            
            if let concentricStreet = address.concentric {
                locationConcentricAddressField?.stringValue = concentricStreet.description
            } else {
                locationConcentricAddressField?.stringValue = ""
            }
        }
        
        if let address = location.address {
            if let description = address.textDescription {
                locationDescriptionField?.stringValue = description
            } else {
                locationDescriptionField?.stringValue = ""
            }
        }
    }
    
    
    func updateReportEntriesView(reportEntries: [ReportEntry]?) {
        guard let reportEntries = reportEntries else {
            reportEntriesView?.textStorage?.setAttributedString(NSAttributedString())
            return
        }
        
        if let text = formattedReport(reportEntries) {
            reportEntriesView?.textStorage?.setAttributedString(text)
        }
        
        if let length = reportEntriesView?.string?.characters.count {
            let end = NSMakeRange(length, 0)
            reportEntriesView?.scrollRangeToVisible(end)
        }
    }
    
    
    func formattedReport(reportEntries: [ReportEntry]?) -> NSAttributedString? {
        let result = NSMutableAttributedString(string: "")
        
        guard let reportEntries = reportEntries else {
            return result
        }
        
        for reportEntry in reportEntries {
            let text = formattedReportEntry(reportEntry)
            result.appendAttributedString(text)
        }
        
        return result
    }
    
    
    func formattedReportEntry(entry: ReportEntry) -> NSAttributedString {
        let newline   = NSAttributedString(string: "\n")
        let dateStamp = dateStampForReportEntry(entry)
        let text      = textForReportEntry(entry)
        let result    = NSMutableAttributedString(string: "")
        
        // Start with a date stamp
        result.appendAttributedString(dateStamp)
        result.appendAttributedString(newline)
        
        // Add the entry text
        result.appendAttributedString(text)
        result.appendAttributedString(newline)
        
        // Make sure we end with a newline
        if let last = text.string.characters.last {
            if last != "\n" {
                result.appendAttributedString(newline)
            }
        } else {
            result.appendAttributedString(newline)
        }
        
        return result
    }
    
    
    func dateStampForReportEntry(entry: ReportEntry) -> NSAttributedString {
        let author: String
        if entry.author == nil {
            author = "<unknown>"
        } else {
            author = entry.author!.description
        }
        
        let dateStamp = "\(entry.created.asString()), \(author):"
        
        let fontName = "Verdana-Bold"
        let fontSize = 10.0
        var textColor = NSColor.textColor()
        let paragraphStyle = NSMutableParagraphStyle()
        
        if entry.systemEntry {
            textColor = textColor.colorWithAlphaComponent(0.5)
            paragraphStyle.alignment = NSCenterTextAlignment
        }
        
        var attributes: [String: AnyObject] = [
            NSForegroundColorAttributeName: textColor,
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        if let font = NSFont(name: fontName, size: CGFloat(fontSize)) {
            attributes[NSFontAttributeName] = font
        } else {
            logError("Unable to create font \(fontName) with size \(fontSize)")
        }
        
        return NSAttributedString(string: dateStamp, attributes: attributes)
    }
    
    
    func textForReportEntry(entry: ReportEntry) -> NSAttributedString {
        let fontName = "Verdana"
        var fontSize = 12.0
        var textColor = NSColor.textColor()
        let paragraphStyle = NSMutableParagraphStyle()
        
        if entry.systemEntry {
            fontSize -= 2.0
            textColor = textColor.colorWithAlphaComponent(0.5)
            paragraphStyle.alignment = NSCenterTextAlignment
        }
        
        var attributes: [String: AnyObject] = [
            NSForegroundColorAttributeName: textColor,
            NSParagraphStyleAttributeName: paragraphStyle
        ]
        
        if let font = NSFont(name: fontName, size: CGFloat(fontSize)) {
            attributes[NSFontAttributeName] = font
        } else {
            logError("Unable to create font \(fontName) with size \(fontSize)")
        }
        
        return NSAttributedString(string: entry.text, attributes: attributes)
    }

}
