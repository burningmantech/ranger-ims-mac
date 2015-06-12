//
//  NSDataExtensions.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Foundation



extension NSData {
    func asBytes() -> [UInt8] {
        let p = UnsafePointer<UInt8>(self.bytes)
        let c = self.length / 4

        // Get our buffer pointer and make an array out of it
        let buffer = UnsafeBufferPointer<UInt8>(
            start:p, count:c
        )
        return [UInt8](buffer)
    }
}
