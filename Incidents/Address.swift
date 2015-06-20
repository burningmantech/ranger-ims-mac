//
//  Address.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

// NOTE:
// It would be prefereable to define Address as a protocol
// and define TextOnlyAddress and RodGarettAddress as structs
// which implement the protocol.
// This proved infeasible because NillishEquatable inherits
// from Equatable, which cannot be used because… generics
// get involved and you then have to declare Locations as
// having a specific type of address, which is weak.
// To avoid accidental data modifications, properties below
// are made read-only.

class Address: CustomStringConvertible, Hashable, NillishEquatable {

    var hashValue: Int {
        var hash = 0
        if let h = textDescription?.hashValue { hash ^= h }
        return hash
    }

    var textDescription: String? { return _textDescription }

    private var _textDescription: String?

    var description: String {
        if textDescription == nil {
            return ""
        } else {
            return textDescription!
        }
    }


    init(textDescription: String? = nil) {
        self._textDescription = textDescription
    }


    func isNillish() -> Bool {
        return textDescription == nil
    }

}

func ==(lhs: Address, rhs: Address) -> Bool {
    return lhs.textDescription == rhs.textDescription
}

func <(lhs: Address, rhs: Address) -> Bool {
    return lhs.textDescription < rhs.textDescription
}



class TextOnlyAddress: Address {}



class RodGarettAddress: Address {

    override var hashValue: Int {
        var hash = 0
        if let h = concentric?     .hashValue { hash ^= h }
        if let h = radialHour?     .hashValue { hash ^= h }
        if let h = radialMinute?   .hashValue { hash ^= h }
        if let h = textDescription?.hashValue { hash ^= h }
        return hash
    }

    var concentric  : ConcentricStreet? { return _concentric   }
    var radialHour  : Int?              { return _radialHour   }
    var radialMinute: Int?              { return _radialMinute }

    private var _concentric: ConcentricStreet?
    private var _radialHour  : Int?
    private var _radialMinute: Int?

    override var description: String {
        var c = "-"
        var h = "-"
        var m = "-"
        
        if concentric != nil {
            //c = ConcentricStreet(rawValue: concentric!)!.description
            c = concentric!.description
        }
        
        if radialHour   != nil { h = String(radialHour!  ) }
        if radialMinute != nil { m = String(radialMinute!) }
        
        if let d = textDescription {
            return "\(h):\(m)@\(c), \(d)"
        } else {
            return "\(h):\(m)@\(c)"
        }
    }

    
    init(
        concentric      : ConcentricStreet? = nil,
        radialHour      : Int?              = nil,
        radialMinute    : Int?              = nil,
        textDescription : String?           = nil
    ) {
        super.init(textDescription: textDescription)

        self._concentric   = concentric
        self._radialHour   = radialHour
        self._radialMinute = radialMinute
    }


    override func isNillish() -> Bool {
        return (
            concentric      == nil &&
            radialHour      == nil &&
            radialMinute    == nil &&
            textDescription == nil
        )
    }
    
}

func ==(lhs: RodGarettAddress, rhs: RodGarettAddress) -> Bool {
    return (
        lhs.concentric      == rhs.concentric      &&
        lhs.radialHour      == rhs.radialHour      &&
        lhs.radialMinute    == rhs.radialMinute    &&
        lhs.textDescription == rhs.textDescription
    )
}

func <(lhs: RodGarettAddress, rhs: RodGarettAddress) -> Bool {
    if lhs.concentric == nil {
        return true
    } else if lhs.concentric! < rhs.concentric! {
        return true
    } else if lhs.concentric! != rhs.concentric! {
        return false
    } else if lhs.radialHour == nil {
        return true
    } else if lhs.radialHour < rhs.radialHour {
        return true
    } else if lhs.radialHour > rhs.radialHour {
        return false
    } else if lhs.radialMinute == nil {
        return true
    } else if lhs.radialMinute < rhs.radialMinute {
        return true
    } else if lhs.radialMinute > rhs.radialMinute {
        return false
    } else if lhs.textDescription == nil {
        return true
    } else {
        return lhs.textDescription < rhs.textDescription
    }
}



enum ConcentricStreet: Int, CustomStringConvertible {

    case Esplanade = 0
    case A
    case B
    case C
    case D
    case E
    case F
    case G
    case H
    case I
    case J
    case K
    case L
    case M
    case N

    // FIXME: Load names from server instead
    var description: String {
        switch self {
            case Esplanade: return "Esplanade"
            case A        : return "Arcade"
            case B        : return "Ballyhoo"
            case C        : return "Carny"
            case D        : return "Donniker"
            case E        : return "Ersatz"
            case F        : return "Freak Show"
            case G        : return "Geek"
            case H        : return "Hanky Panky"
            case I        : return "Illusion"
            case J        : return "Jolly"
            case K        : return "Kook"
            case L        : return "Laffing Sal"
            case M        : return "M"
            case N        : return "N"
        }
    }

}

func ==(lhs: ConcentricStreet, rhs: ConcentricStreet) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

func <(lhs: ConcentricStreet, rhs: ConcentricStreet) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
