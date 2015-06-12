//
//  HTTPJSON.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

extension HTTPSession {

    typealias JSONResponseHandler = (json: AnyObject?) -> Void
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
                logError("URL in response does not match URL in JSON request: \(url) != \(url)")
                return
            }

            if status != 200 {
                logError("Non-OK response status to JSON request: \(status)")
                return
            }

            guard let contentTypes = headers["Content-Type"] else {
                logError("No Content-Type header in response to JSON request")
                return
            }

            if contentTypes.count != 1 {
                logError("Multiple Content-Types in response to JSON request: \(contentTypes)")
                return
            }
            if contentTypes[0] != "application/json" {
                logError("Non-JSON Content-Type in response to JSON request: \(contentTypes[0])")
                return
            }

            // FIXME ***********************************

            responseHandler(json: nil)
        }

        logInfo("Sending JSON request to: \(url)")

        return self.send(
            request: request,
            responseHandler: onResponse,
            errorHandler: errorHandler
        )
    }
}
