//
//  Error.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

public struct Error: Printable {
    public let reason: String

    public init(_ reason: String) {
        self.reason = reason
    }

    public var description: String { return reason }
}
