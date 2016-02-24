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
//
// To avoid accidental data modifications, properties below
// are made read-only.



class Address: CustomStringConvertible, Comparable, Hashable, NillishEquatable {

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


    func isEqualTo(other: Address) -> Bool {
        return textDescription == other.textDescription
    }

    
    func isLessThan(other: Address) -> Bool {
        return textDescription < other.textDescription
    }

}

func ==(lhs: Address, rhs: Address) -> Bool {
    return lhs.isEqualTo(rhs)
}

func <(lhs: Address, rhs: Address) -> Bool {
    return lhs.isLessThan(rhs)
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
    

    override func isEqualTo(other: Address) -> Bool {
        let _other = other
        guard let other = other as? RodGarettAddress else {
            return super.isEqualTo(_other)
        }
        
        return (
            concentric      == other.concentric      &&
            radialHour      == other.radialHour      &&
            radialMinute    == other.radialMinute    &&
            textDescription == other.textDescription
        )
    }


    override func isLessThan(other: Address) -> Bool {
        let _other = other
        guard let other = other as? RodGarettAddress else {
            return super.isLessThan(_other)
        }

        if concentric == nil {
            return true
        } else if concentric! < other.concentric! {
            return true
        } else if concentric! != other.concentric! {
            return false
        } else if radialHour == nil {
            return true
        } else if radialHour < other.radialHour {
            return true
        } else if radialHour > other.radialHour {
            return false
        } else if radialMinute == nil {
            return true
        } else if radialMinute < other.radialMinute {
            return true
        } else if radialMinute > other.radialMinute {
            return false
        } else if textDescription == nil {
            return true
        } else {
            return textDescription < other.textDescription
        }
    }

}



enum ConcentricStreet: Int, CustomStringConvertible, Comparable {

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

    case Plaza300          = 300
    case PublicPlaza300    = 305
    case Plaza430          = 430
    case CenterCampInner   = 600
    case CenterCampService = 601
    case CenterCampOuter   = 602
    case PublicPlaza600    = 605
    case Plaza730          = 730
    case Plaza900          = 900
    case PublicPlaza900    = 905

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

            case Plaza300         : return "3:00 Plaza"
            case PublicPlaza300   : return "3:00 Public Plaza"
            case Plaza430         : return "4:30 Plaza"
            case CenterCampInner  : return "Center Camp Plaza"
            case CenterCampService: return "Route 66"
            case CenterCampOuter  : return "Rod's Road"
            case PublicPlaza600   : return "6:00 Public Plaza"
            case Plaza730         : return "7:30 Plaza"
            case Plaza900         : return "9:00 Plaza"
            case PublicPlaza900   : return "9:00 Public Plaza"
        }
    }

}

func ==(lhs: ConcentricStreet, rhs: ConcentricStreet) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

func <(lhs: ConcentricStreet, rhs: ConcentricStreet) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
