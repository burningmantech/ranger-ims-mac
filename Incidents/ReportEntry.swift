//
//  ReportEntry.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

struct ReportEntry: Printable, Hashable {
    var author     : Ranger
    var text       : String
    var created    : DateTime
    var systemEntry: Bool

    var hashValue: Int {
        return (
            author.hashValue      ^
            text.hashValue        ^
            created.hashValue     ^
            systemEntry.hashValue
        )
    }

    var description: String {
        if systemEntry {
            return "\(author.handle) @ \(created): \(text)"
        } else {
            return "\(author.handle) @ \(created):\n\(text)"
        }
    }

    
    init(
        author     : Ranger,
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
