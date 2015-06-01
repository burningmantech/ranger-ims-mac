//
//  Ranger.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

struct Ranger: Printable, Hashable {
    var handle: String
    var name:   String?
    var status: String?

    var hashValue: Int {
        return handle.hashValue
    }

    var description: String {
        var result = handle
        
        if name != nil { result += " (\(name!))" }
        
        if status == "vintage" { result += "*" }
        
        return result
    }

    
    init(
        handle: String,
        name  : String? = nil,
        status: String? = nil
    ) {
        self.handle = handle
        self.name   = name
        self.status = status
    }

}


func ==(lhs: Ranger, rhs: Ranger) -> Bool {
    return lhs.handle == rhs.handle
}