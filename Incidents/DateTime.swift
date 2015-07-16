//
//  DateTime.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Foundation



struct DateTime: CustomStringConvertible, Comparable, Hashable {
    private static let rfc3339Formatter = makeRFC3339Formatter()
    private static let shortFormatter   = makeFormatter("dd/HH:mm")
    private static let formatter        = makeFormatter("yyyy-MM-dd HH:mm")
    private static let longFormatter    = makeFormatter("EEEE, MMMM d, yyyy HH:mm:ss zzz")

    
    static func fromRFC3339String(string: String) -> DateTime {
        let nsDate = rfc3339Formatter.dateFromString(string)
        return DateTime(nsDate: nsDate!)
    }


    static func now() -> DateTime {
        return DateTime(nsDate: NSDate())
    }


    private let nsDate: NSDate


    var hashValue: Int { return nsDate.hashValue }
    var description: String { return asRFC3339String() }


    private init(nsDate: NSDate) {
        self.nsDate = nsDate
    }


    func asRFC3339String() -> String {
        return DateTime.rfc3339Formatter.stringFromDate(nsDate)
    }


    func asShortString() -> String {
        return DateTime.shortFormatter.stringFromDate(nsDate)
    }

    
    func asString() -> String {
        return DateTime.formatter.stringFromDate(nsDate)
    }
    
    func asLongString() -> String {
        return DateTime.longFormatter.stringFromDate(nsDate)
    }

}



func ==(lhs: DateTime, rhs: DateTime) -> Bool {
    return lhs.nsDate.isEqualToDate(rhs.nsDate)
}



func <(lhs: DateTime, rhs: DateTime) -> Bool {
    return lhs.nsDate.isLessThan(rhs.nsDate)
}



private func makeRFC3339Formatter() -> NSDateFormatter {
    let formatter = NSDateFormatter()
    
    formatter.locale     = NSLocale(localeIdentifier: "en_US_POSIX")
    formatter.timeZone   = NSTimeZone(forSecondsFromGMT: 0)
    formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
    
    return formatter
}



private func makeFormatter(format: String) -> NSDateFormatter {
    let formatter = NSDateFormatter()

    formatter.dateFormat = format

    return formatter
}
