//
//  HTTPConnection.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

enum HTTPMethod: String, Printable {

    case HEAD = "HEAD"
    case GET  = "GET"
    case POST = "POST"

    var description: String { return self.rawValue }

}



class HTTPRequest {

    var url    : String
    var method : HTTPMethod
    var headers: HTTPHeaders
    var body   : [UInt8]

    init(
        url    : String,
        method : HTTPMethod   = .GET,
        headers: HTTPHeaders? = nil,
        body   : [UInt8]?     = nil
    ) {
        self.url     = url
        self.method  = method

        if headers == nil {
            self.headers = HTTPHeaders()
        } else {
            self.headers = headers!
        }

        if body == nil {
            self.body = [UInt8]()
        } else {
            self.body = body!
        }
    }

}
