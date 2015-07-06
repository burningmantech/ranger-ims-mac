//
//  IncidentController_edit.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



extension IncidentController {

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
        reportEntryToAddView?.editable = true
        
        if window?.documentEdited == true {
            saveButton?.enabled = true
        }
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
        reportEntryToAddView?.editable = false
        saveButton?.enabled = false
    }
    
    
    @IBAction func editSummary(sender: AnyObject?) {
        defer { updateView() }
        
        let oldSummary: String
        if let summary = incident!.summary { oldSummary = summary } else { oldSummary = "" }
        let newSummary = summaryField!.stringValue
        
        if newSummary == oldSummary { return }
        
        logDebug("Summary changed to: \(newSummary)")
        
        incident!.summary = newSummary
    }
    
    
    @IBAction func editState(sender: AnyObject?) {
        defer { updateView() }

        let oldState: IncidentState
        if let state = incident!.state { oldState = state } else { oldState = .New }
        
        guard let selectedTag = statePopUp!.selectedItem?.tag else {
            logError("Unable to get selected state tag")
            return
        }
        
        guard let selectedState = IncidentStateTag(rawValue: selectedTag) else {
            logError("Unknown state tag: \(selectedTag)")
            return
        }
        
        let newState: IncidentState
        switch selectedState {
        case .New       : newState = .New
        case .OnHold    : newState = .OnHold
        case .Dispatched: newState = .Dispatched
        case .OnScene   : newState = .OnScene
        case .Closed    : newState = .Closed
        }
        
        if newState == oldState { return }
        
        logDebug("State changed to: \(newState)")
        
        incident!.state = newState
    }
    
    
    @IBAction func editPriority(sender: AnyObject?) {
        defer { updateView() }

        let oldPriority: IncidentPriority
        if let priority = incident!.priority { oldPriority = priority } else { oldPriority = .Normal }
        
        guard let selectedTag = priorityPopUp!.selectedItem?.tag else {
            logError("Unable to get selected priority tag")
            return
        }
        
        guard let selectedPriority = IncidentPriorityTag(rawValue: selectedTag) else {
            logError("Unknown state tag: \(selectedTag)")
            return
        }
        
        let newPriority: IncidentPriority
        switch selectedPriority {
        case .High  : newPriority = .High
        case .Normal: newPriority = .Normal
        case .Low   : newPriority = .Low
        }
        
        if newPriority == oldPriority { return }
        
        logDebug("Priority changed to: \(newPriority)")
        
        incident!.priority = newPriority
    }
    
    
    @IBAction func editLocationName(sender: AnyObject?) {
        defer { updateView() }

        let oldName: String
        if let name = incident!.location?.name { oldName = name } else { oldName = "" }
        let newName = locationNameField!.stringValue
        
        if newName != oldName {
            let newLocation: Location
            if incident!.location == nil {
                newLocation = Location(name: newName)
            } else {
                newLocation = Location(
                    name: newName,
                    address: incident!.location!.address
                )
            }
            
            logDebug("Location changed to: \(newLocation)")
            
            incident!.location = newLocation
        }
    }
    
    
    @IBAction func editAddressDescription(sender: AnyObject?) {
        defer { updateView() }

        let oldDescription: String
        if let description = incident!.location?.address?.textDescription { oldDescription = description } else { oldDescription = "" }
        let newDescription = locationDescriptionField!.stringValue
        
        if newDescription == oldDescription { return }
        
        let newLocation: Location
        if incident!.location == nil || incident!.location!.address == nil {
            newLocation = Location(
                address: TextOnlyAddress(textDescription: newDescription)
            )
        }
        else {
            let newAddress: Address
            let oldAddress = incident!.location!.address
            if let oldAddress = oldAddress as? RodGarettAddress {
                newAddress = RodGarettAddress(
                    concentric: oldAddress.concentric,
                    radialHour: oldAddress.radialHour,
                    radialMinute: oldAddress.radialMinute,
                    textDescription: newDescription
                )
            }
            else if let _ = oldAddress as? TextOnlyAddress {
                newAddress = TextOnlyAddress(textDescription: newDescription)
            }
            else {
                logError("Unable to edit unknown address type: \(oldAddress)")
                return
            }
            
            newLocation = Location(
                name: incident!.location!.name,
                address: newAddress
            )
        }
        
        logDebug("Location changed to: \(newLocation)")
        
        incident!.location = newLocation
    }
    
    
    private func _incidentRodGarrettAddress() -> RodGarettAddress? {
        let oldAddress: RodGarettAddress
        
        if let address = incident!.location?.address {
            if let address = address as? RodGarettAddress {
                oldAddress = address
            }
            else if let address = address as? TextOnlyAddress {
                oldAddress = RodGarettAddress(textDescription: address.textDescription)
            }
            else {
                logError("Unable to edit unknown address type: \(address)")
                return nil
            }
        } else {
            oldAddress = RodGarettAddress()
        }
        
        return oldAddress
    }
    
    
    @IBAction func editAddressRadial(sender: AnyObject?) {
        defer { updateView() }

        guard let oldAddress = _incidentRodGarrettAddress() else { return }
        
        let oldRadialHour: Int, oldRadialMinute: Int
        if let hour = oldAddress.radialHour, minute = oldAddress.radialMinute {
            oldRadialHour   = hour
            oldRadialMinute = minute
        } else {
            oldRadialHour   = -1
            oldRadialMinute = -1
        }
        
        let newRadialName = locationRadialAddressField!.stringValue
        
        let newRadialHour: Int?, newRadialMinute: Int?
        if newRadialName == "" {
            newRadialHour   = nil
            newRadialMinute = nil
        } else {
            let newRadialComponents = split(newRadialName.characters, isSeparator: {$0 == ":"})
            guard newRadialComponents.count == 2 else {
                logError("Unable to parse radial address components: \(newRadialName)")
                return
            }
            guard let hour = Int(String(newRadialComponents[0])) else {
                logError("Unable to parse radial hour: \(newRadialName)")
                return
            }
            guard let minute = Int(String(newRadialComponents[1])) else {
                logError("Unable to parse radial minute: \(newRadialName)")
                return
            }
            newRadialHour   = hour
            newRadialMinute = minute
        }
        
        if newRadialHour == oldRadialHour && newRadialMinute == oldRadialMinute { return }
        
        let newAddress = RodGarettAddress(
            concentric: oldAddress.concentric,
            radialHour: newRadialHour,
            radialMinute: newRadialMinute,
            textDescription: oldAddress.textDescription
        )
        
        let newLocation = Location(
            name: incident!.location!.name,
            address: newAddress
        )
        
        logDebug("Location changed to: \(newLocation)")
        
        incident!.location = newLocation
    }
    
    
    @IBAction func editAddressConcentric(sender: AnyObject?) {
        defer { updateView() }
        
        guard let oldAddress = _incidentRodGarrettAddress() else { return }
        
        let oldConcentricName: String
        if let name = oldAddress.concentric?.description { oldConcentricName = name } else { oldConcentricName = "" }
        let newConcentricName = locationConcentricAddressField!.stringValue
        
        if newConcentricName == oldConcentricName { return }
        
        func matchesEsplanade() -> Bool {
            let esplanade = ConcentricStreet.Esplanade.description
            let e = ConcentricStreet.E.description

            for prefixLength in 1...esplanade.characters.count {
                let prefix = newConcentricName.substringToIndex(advance(esplanade.startIndex, prefixLength))
                
                if e.hasPrefix(prefix) { continue }  // Could be either E or Esplanade

                return esplanade.hasPrefix(prefix)
            }

            return false
        }
        
        let newConcentric: ConcentricStreet?
        if matchesEsplanade() { newConcentric = ConcentricStreet.Esplanade }
        else if newConcentricName.hasPrefix("A") { newConcentric = ConcentricStreet.A }
        else if newConcentricName.hasPrefix("B") { newConcentric = ConcentricStreet.B }
        else if newConcentricName.hasPrefix("C") { newConcentric = ConcentricStreet.C }
        else if newConcentricName.hasPrefix("D") { newConcentric = ConcentricStreet.D }
        else if newConcentricName.hasPrefix("E") { newConcentric = ConcentricStreet.E }
        else if newConcentricName.hasPrefix("F") { newConcentric = ConcentricStreet.F }
        else if newConcentricName.hasPrefix("G") { newConcentric = ConcentricStreet.G }
        else if newConcentricName.hasPrefix("H") { newConcentric = ConcentricStreet.H }
        else if newConcentricName.hasPrefix("I") { newConcentric = ConcentricStreet.I }
        else if newConcentricName.hasPrefix("J") { newConcentric = ConcentricStreet.J }
        else if newConcentricName.hasPrefix("K") { newConcentric = ConcentricStreet.K }
        else if newConcentricName.hasPrefix("L") { newConcentric = ConcentricStreet.L }
        else if newConcentricName.hasPrefix("M") { newConcentric = ConcentricStreet.M }
        else if newConcentricName.hasPrefix("N") { newConcentric = ConcentricStreet.N }
        else if newConcentricName == "" { newConcentric = nil }
        else {
            logDebug("Unknown concentric street name: \(newConcentricName)")
            return
        }
        
        let newAddress = RodGarettAddress(
            concentric: newConcentric,
            radialHour: oldAddress.radialHour,
            radialMinute: oldAddress.radialMinute,
            textDescription: oldAddress.textDescription
        )
        
        let newLocation = Location(
            name: incident!.location!.name,
            address: newAddress
        )
        
        logDebug("Location changed to: \(newLocation)")
        
        incident!.location = newLocation
    }
    
    
    func addReportEntry() {
        defer { updateView() }

        guard let textStorage = reportEntryToAddView?.textStorage else {
            logError("No text storage for report entry to add view?")
            return
        }
        
        let reportTextTrimmed = textStorage.string.stringByTrimmingCharactersInSet(
            NSCharacterSet.whitespaceAndNewlineCharacterSet()
        )
        
        textStorage.setAttributedString(NSAttributedString())
        
        guard reportTextTrimmed.characters.count > 0 else { return }
        
        let entry = ReportEntry(author: nil, text: reportTextTrimmed)
        
        if incident!.reportEntries == nil {
            incident!.reportEntries = []
        }
        
        incident!.reportEntries!.append(entry)
    }

}