//
//  HTTPJSON.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Foundation



extension HTTPSession {

    typealias JSONResponseHandler = (
        headers: HTTPHeaders,
        json: AnyObject?
    ) -> Void
    typealias JSONErrorHandler = ErrorHandler


    func sendJSON(
        url url: String,
        json: AnyObject?,
        responseHandler: JSONResponseHandler,
        errorHandler: JSONErrorHandler
    ) -> HTTPConnection? {

        var headers = HTTPHeaders()
        headers.add(name: "Accept", value: "application/json")

        let jsonBytes: [UInt8]
        if json == nil {
            jsonBytes = []
        } else {
            // FIXME *********************************
            assert(false, "Unimplemented")
            jsonBytes = []
        }

        let request = HTTPRequest(
            url: url,
            method: HTTPMethod.GET,
            headers: headers,
            body: jsonBytes
        )

        func onResponse(
            url: String,
            status: Int,
            headers: HTTPHeaders,
            body:[UInt8]
        ) {
            if url != url {
                return errorHandler(
                    message: "URL in response does not match URL in JSON request: \(url) != \(url)"
                )
            }

            if status != 200 {
                return errorHandler(
                    message: "Non-OK response status to JSON request: \(status)"
                )
            }

            guard let contentTypes = headers["Content-Type"] else {
                return errorHandler(
                    message: "No Content-Type header in response to JSON request"
                )
            }

            if contentTypes.count != 1 {
                return errorHandler(
                    message: "Multiple Content-Types in response to JSON request: \(contentTypes)"
                )
            }
            if contentTypes[0] != "application/json" {
                return errorHandler(
                    message: "Non-JSON Content-Type in response to JSON request: \(contentTypes[0])"
                )
            }

            let bodyData = NSData.fromBytes(body)
            let json: AnyObject?

            if bodyData.length > 0 {
                do {
                    json = try NSJSONSerialization.JSONObjectWithData(bodyData, options: [.AllowFragments])
                } catch {
                    let jsonText: String
                    if let _jsonText = NSString(data: bodyData, encoding: NSUTF8StringEncoding) {
                        jsonText = _jsonText as String
                    } else {
                        jsonText = "<unable to decode UTF-8>"
                    }

                    return errorHandler(
                        message: "Unable to deserialize JSON response data from \(url): \(jsonText)"
                    )
                }
            } else {
                json = nil
            }

            responseHandler(headers: headers, json: json)
        }

        return self.send(
            request: request,
            responseHandler: onResponse,
            errorHandler: errorHandler
        )
    }
}
