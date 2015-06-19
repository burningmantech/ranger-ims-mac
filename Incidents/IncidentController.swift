//
//  IncidentController.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class IncidentController: NSWindowController {

    var dispatchQueueController: DispatchQueueController!

    var incident: Incident?

    var stateDidChange    = false
    var priorityDidChange = false
    var summaryDidChange  = false
    var rangersDidChange  = false
    var typesDidChange    = false
    var locationDidChange = false
    var reportDidChange   = false
    
    @IBOutlet weak var numberField                   : NSTextField?
    @IBOutlet weak var statePopUp                    : NSPopUpButton?
    @IBOutlet weak var priorityPopUp                 : NSPopUpButton?
    @IBOutlet weak var summaryField                  : NSTextField?
    @IBOutlet weak var rangersTable                  : NSTableView?
    @IBOutlet weak var rangerToAddField              : NSTextField?
    @IBOutlet weak var typesTable                    : NSTableView?
    @IBOutlet weak var typeToAddField                : NSTextField?
    @IBOutlet weak var locationNameField             : NSTextField?
    @IBOutlet weak var locationRadialAddressField    : NSTextField?
    @IBOutlet weak var locationConcentricAddressField: NSTextField?
    @IBOutlet weak var locationDescriptionField      : NSTextField?
    @IBOutlet weak var reportEntriesScrollView       : NSScrollView?  // Can't connect NSTextView because weak sauce
    @IBOutlet weak var reportEntryToAddScrollView    : NSScrollView?  // Can't connect NSTextView because weak sauce
    @IBOutlet weak var saveButton                    : NSButton?
    @IBOutlet weak var loadingIndicator              : NSProgressIndicator?
    @IBOutlet weak var reloadButton                  : NSButton?


    var reportEntriesView: NSTextView? {
        return reportEntriesScrollView?.contentView.documentView as? NSTextView
    }


    var reportEntryToAddView: NSTextView? {
        return reportEntryToAddScrollView?.contentView.documentView as? NSTextView
    }


    convenience init(dispatchQueueController: DispatchQueueController, incident: Incident) {
        self.init(windowNibName: "Incident")

        self.dispatchQueueController = dispatchQueueController
        self.incident = incident.copy()
    }


    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    func updateView() {
        guard let incident = self.incident else {
            logError("Incident controller has no incident?")
            return
        }

        // ➡︎ numberField

        let numberToDisplay: String

        if let number = incident.number {
            numberToDisplay = "\(number)"
        } else {
            numberToDisplay = "(new)"
        }

        numberField?.stringValue = "\(numberToDisplay)"

        // ➡︎ window.title
        
        window?.title = "\(numberToDisplay): \(incident.summaryAsText)"

        // ➡︎ statePopUp
        
        let stateTag: IncidentStateTag

        if let state = incident.state {
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

        // ➡︎ priorityPopUp

        let priorityTag: PriorityTag
        
        if let priority = incident.priority {
            switch priority {
                case .High  : priorityTag = .High
                case .Normal: priorityTag = .Normal
                case .Low   : priorityTag = .Low
            }
        } else {
            priorityTag = .Normal
        }

        priorityPopUp?.selectItemWithTag(priorityTag.rawValue)
        
        // ➡︎ summaryField

        summaryField?.stringValue = incident.summaryAsText
        
        // ➡︎ rangersTable

        rangersTable?.reloadData()
        
        // ➡︎ typesTable

        typesTable?.reloadData()

        // ➡︎ locationNameField
        // ➡︎ locationRadialAddressField
        // ➡︎ locationConcentricAddressField
        // ➡︎ locationDescriptionField

        if let location = incident.location {
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
        } else {
            locationNameField?.stringValue = ""
            locationRadialAddressField?.stringValue = ""
            locationConcentricAddressField?.stringValue = ""
            locationDescriptionField?.stringValue = ""
        }
        
        // ➡︎ reportEntryToAddView

        if let text = formattedReport() {
            reportEntriesView?.textStorage?.setAttributedString(text)
        }

        if let length = reportEntriesView?.string?.characters.count {
            let end = NSMakeRange(length, 0)
            reportEntriesView?.scrollRangeToVisible(end)
        }
    }
    

    func resetChangeTracking() {
        stateDidChange    = false
        priorityDidChange = false
        summaryDidChange  = false
        rangersDidChange  = false
        typesDidChange    = false
        locationDidChange = false
        reportDidChange   = false
    }

    
    func enableEditing() {
        statePopUp?.enabled = true
        priorityPopUp?.enabled = true
        summaryField?.enabled = true
        rangersTable?.enabled = true
        rangerToAddField?.enabled = true
        typesTable?.enabled = true
        typeToAddField?.enabled = true
        locationNameField?.enabled = true
        locationRadialAddressField?.enabled = true
        locationConcentricAddressField?.enabled = true
        locationDescriptionField?.enabled = true
      //reportEntriesView?.editable = true
        reportEntryToAddView?.editable = true
        saveButton?.enabled = true
    }


    func disableEditing() {
        statePopUp?.enabled = false
        priorityPopUp?.enabled = false
        summaryField?.enabled = false
        rangersTable?.enabled = false
        rangerToAddField?.enabled = false
        typesTable?.enabled = false
        typeToAddField?.enabled = false
        locationNameField?.enabled = false
        locationRadialAddressField?.enabled = false
        locationConcentricAddressField?.enabled = false
        locationDescriptionField?.enabled = false
      //reportEntriesView?.editable = false
        reportEntryToAddView?.editable = false
        saveButton?.enabled = false
    }

    
    func formattedReport() -> NSAttributedString? {
        guard let incident = self.incident else {
            logError("Incident controller has no incident?")
            return nil
        }

        guard let reportEntries = incident.reportEntries else {
            logError("Incident has no report entries: \(incident)")
            return nil
        }
        
        let result = NSMutableAttributedString(string: "")
        
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
        let dateStamp = "\(entry.created.asString()), \(entry.author):"
        
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



extension IncidentController: NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()

        func arghEvilDeath(uiElementName: String) {
            fatalError("Incident controller: no \(uiElementName)?")
        }

        if window                         == nil { arghEvilDeath("window"                           ) }
        if numberField                    == nil { arghEvilDeath("number field"                     ) }
        if statePopUp                     == nil { arghEvilDeath("state pop-up"                     ) }
        if priorityPopUp                  == nil { arghEvilDeath("priority pop-up"                  ) }
        if summaryField                   == nil { arghEvilDeath("summary field"                    ) }
        if rangersTable                   == nil { arghEvilDeath("rangers table"                    ) }
        if rangerToAddField               == nil { arghEvilDeath("ranger field"                     ) }
        if typesTable                     == nil { arghEvilDeath("incident types table"             ) }
        if typeToAddField                 == nil { arghEvilDeath("incident type field"              ) }
        if locationNameField              == nil { arghEvilDeath("location name field"              ) }
        if locationRadialAddressField     == nil { arghEvilDeath("location radial address field"    ) }
        if locationConcentricAddressField == nil { arghEvilDeath("location concentric address field") }
        if locationDescriptionField       == nil { arghEvilDeath("location description field"       ) }
        if reportEntriesView              == nil { arghEvilDeath("report entries view"              ) }
        if reportEntryToAddView           == nil { arghEvilDeath("report entry view"                ) }
        if saveButton                     == nil { arghEvilDeath("save button"                      ) }
        if loadingIndicator               == nil { arghEvilDeath("loading indicator"                ) }
        if reloadButton                   == nil { arghEvilDeath("reload button"                    ) }

        resetChangeTracking()
        updateView()

        reloadButton!.hidden     = false
        loadingIndicator!.hidden = true

        enableEditing()
    }

}



extension IncidentController: TableViewDelegate {

    func deleteFromTableView(tableView: TableView) {
        let rowIndex = tableView.selectedRow
        
    }

    
    func openFromTableView(tableView: TableView) {}

}



enum IncidentStateTag: Int {
    case New        = 1
    case OnHold     = 2
    case Dispatched = 3
    case OnScene    = 4
    case Closed     = 5
}



enum PriorityTag: Int {
    case High   = 1
    case Normal = 3
    case Low    = 5
}
