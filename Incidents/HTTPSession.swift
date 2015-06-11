//
//  HTTPSession.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Foundation



class HTTPSession: NSObject {

    typealias ResponseHandler = (
        url: String,
        status: Int,
        headers: HTTPHeaders,
        body:[UInt8]
    ) -> Void
    typealias ErrorHandler = (message: String) -> Void

    private var nsSession: NSURLSession


    // For mock subclass in unit tests
    internal init(nsSession: NSURLSession) {
        self.nsSession = nsSession
    }


    init(
        userAgent: String? = nil,
        idleTimeOut: Int = 30,
        timeOut: Int = 3600
    ) {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()

        if userAgent != nil {
            configuration.HTTPAdditionalHeaders = [
                "User-Agent": userAgent!
            ]
        }

        configuration.timeoutIntervalForRequest = NSTimeInterval(idleTimeOut)
        configuration.TLSMinimumSupportedProtocol = kTLSProtocol12


        class Delegate: NSObject, NSURLSessionDelegate {
        }

        nsSession = NSURLSession(
            configuration: configuration,
            delegate: Delegate(),
            delegateQueue: nil
        )

        super.init()
    }


    func send(
        request request: HTTPRequest,
        responseHandler: ResponseHandler,
        errorHandler: ErrorHandler
    ) -> HTTPConnection? {

        let nsURL = NSURL(string: request.url)

        if nsURL == nil {
            errorHandler(message: "Invalid URL: \(request.url)")
            return nil
        }

        let nsRequest = NSMutableURLRequest(URL: nsURL!)

        guard let task = nsSession.dataTaskWithRequest(
            nsRequest,
            completionHandler: {
                nsData, nsResponse, nsError -> Void in

                if let e = nsError {
                    errorHandler(message: e.localizedDescription)
                    return
                }

                let status: Int
                let headers = HTTPHeaders()

                if let nsHTTPResponse = nsResponse as? NSHTTPURLResponse {
                    status = nsHTTPResponse.statusCode

                    for (name, value) in nsHTTPResponse.allHeaderFields {
                        let stringName  = name  as! String
                        let stringValue = value as! String

                        headers.add(name: stringName, value: stringValue)
                    }
                } else {
                    status = 0
                }
                
                let p = UnsafePointer<UInt8>(nsData!.bytes)
                let c = nsData!.length / 4

                // Get our buffer pointer and make an array out of it
                let buffer = UnsafeBufferPointer<UInt8>(
                    start:p, count:c
                )
                let body = [UInt8](buffer)

                responseHandler(url: request.url, status: status, headers: headers, body: body)
            }
        ) else {
            return nil
        }

        task.resume()

        return HTTPConnection(nsTask: task)
    }


    func invalidate() {
        nsSession.invalidateAndCancel()
    }

}



class HTTPConnection {

    private let nsTask: NSURLSessionTask


    private init(nsTask: NSURLSessionTask) {
        self.nsTask = nsTask
    }


    func cancel() { nsTask.cancel () }
    func pause () { nsTask.suspend() }
    func resume() { nsTask.resume () }

}
