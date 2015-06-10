//
//  Location.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

struct Location: CustomStringConvertible, Hashable, NillishEquatable {

    var name: String?
    var address: Address?
    
    var hashValue: Int {
        var hash = 0
        if let h = name?   .hashValue { hash ^= h }
        if let h = address?.hashValue { hash ^= h }
        return hash
    }

    var description: String {
        var result = ""
        
        if let name = self.name {
            result += name
            if let address = self.address {
                if address.description != name {
                    result += " (\(address))"
                }
            }
        }
        else {
            if let address = self.address {
                result += "(\(address))"
            }
        }

        return result
    }

    
    init(
        name   : String?  = nil,
        address: Address? = nil
    ) {
        self.name    = name
        self.address = address
    }


    func isNillish() -> Bool {
        if name != nil { return false }
        return nillish(address)
//        return (name == nil && nillish(address))
    }

}


func ==(lhs: Location, rhs: Location) -> Bool {
    return (
        lhs.name    == rhs.name    &&
        lhs.address == rhs.address
    )
}


func <(lhs: Location, rhs: Location) -> Bool {
    if lhs.name == nil {
        return true
    } else if lhs.name < rhs.name {
        return true
    } else if lhs.name > rhs.name {
        return false
    } else if lhs.address == nil {
        return true
    } else {
        return lhs.address! < rhs.address!
    }
}
