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
        method: HTTPMethod = HTTPMethod.GET,
        json: AnyObject?,
        responseHandler: JSONResponseHandler,
        errorHandler: JSONErrorHandler
    ) throws -> HTTPConnection {

        var headers = HTTPHeaders()
        headers.add(name: HTTPHeaderName.ContentType.rawValue, value: "application/json")
        headers.add(name: HTTPHeaderName.Accept.rawValue     , value: "application/json")

        let jsonBytes: [UInt8]
        if let json = json {
            var jsonOptions = NSJSONWritingOptions()
            if NSUserDefaults.standardUserDefaults().boolForKey("EnableHTTPJSONLogging") {
                jsonOptions.insert(NSJSONWritingOptions.PrettyPrinted)
            }
            
            let nsData = try NSJSONSerialization.dataWithJSONObject(json, options: jsonOptions)
            jsonBytes = nsData.asBytes()
        }
        else {
            jsonBytes = []
        }

        let request = HTTPRequest(
            url: url,
            method: method,
            headers: headers,
            body: jsonBytes
        )

        func onResponse(
            url: String,
            status: HTTPStatus,
            headers: HTTPHeaders,
            body:[UInt8]
        ) {
            if let required = headers["x-form-auth-required"] {
                return errorHandler(
                    message: "x-form-auth-required\(required)"
                )
            }
            
            if url != url {
                return errorHandler(
                    message: "URL in response does not match URL in JSON request: \(url) != \(url)"
                )
            }

            let hasContent: Bool

            switch status {
                case .OK       : hasContent = true
                case .Created  : hasContent = true
                case .NoContent: hasContent = false
                default:
                    return errorHandler(
                        message: "Non-successful or unexpected response status to JSON request: \(status)"
                    )
            }

            let json: AnyObject?

            if hasContent {
                guard let contentTypes = headers[HTTPHeaderName.ContentType.rawValue] else {
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
            } else {
                json = nil
            }

            if let json = json {
                logJSON("Received JSON", json)
            }

            responseHandler(headers: headers, json: json)
        }

        if let json = json {
            logJSON("Sending JSON", json)
        }
        
        let connection = try self.send(
            request: request,
            responseHandler: onResponse,
            errorHandler: errorHandler
        )

        return connection
    }


    private func logJSON(message: String, _ json: AnyObject?) {
        if NSUserDefaults.standardUserDefaults().boolForKey("EnableHTTPJSONLogging") {
            logInfo("\(message):\n\(json)")
        }
    }
}
