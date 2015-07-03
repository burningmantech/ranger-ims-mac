//
//  ReportEntry.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

struct ReportEntry: CustomStringConvertible, Hashable {
    var author     : Ranger?
    var text       : String
    var created    : DateTime
    var systemEntry: Bool

    var hashValue: Int {
        var hash = (
            text.hashValue        ^
            created.hashValue     ^
            systemEntry.hashValue
        )
        if let h = author?.hashValue { hash ^= h }
        return hash
    }

    var description: String {
        let author: String
        if self.author == nil {
            author = "<nil>"
        } else {
            author = self.author!.handle
        }
        
        if systemEntry {
            return "\(author) @ \(created): \(text)"
        } else {
            return "\(author) @ \(created):\n\(text)"
        }
    }

    
    init(
        author     : Ranger?,
        text       : String,
        created    : DateTime = DateTime.now(),
        systemEntry: Bool = false
    ) {
        self.author      = author
        self.text        = text
        self.created     = created
        self.systemEntry = systemEntry
    }

}


func ==(lhs: ReportEntry, rhs: ReportEntry) -> Bool {
    return (
        lhs.author      == rhs.author      &&
        lhs.text        == rhs.text        &&
        lhs.created     == rhs.created     &&
        lhs.systemEntry == rhs.systemEntry
    )
}
