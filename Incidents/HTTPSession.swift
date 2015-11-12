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
        status: HTTPStatus,
        headers: HTTPHeaders,
        body:[UInt8]
    ) -> Void

    typealias ErrorHandler = (message: String) -> Void

    typealias AuthHandler = (
        host: String,
        port: Int,
        realm: String?
    ) -> HTTPCredential?


    private let nsSession: NSURLSession

    var authHandler: AuthHandler?


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
                HTTPHeaderName.UserAgent.rawValue: userAgent!
            ]
        }

        configuration.timeoutIntervalForRequest = NSTimeInterval(idleTimeOut)
        // configuration.TLSMinimumSupportedProtocol = SSLProtocol.TLSProtocol12

        let delegate = SessionDelegate()
        
        nsSession = NSURLSession(
            configuration: configuration,
            delegate: delegate,
            delegateQueue: nil
        )

        super.init()

        delegate.session = self
    }


    func send(
        request request: HTTPRequest,
        responseHandler: ResponseHandler,
        errorHandler: ErrorHandler
    ) throws -> HTTPConnection {

        let nsURL = NSURL(string: request.url)

        if nsURL == nil {
            throw HTTPError.InvalidURL(request.url)
        }

        let nsRequest = NSMutableURLRequest(URL: nsURL!)

        nsRequest.HTTPMethod = request.method.rawValue
        nsRequest.HTTPBody = NSData.fromBytes(request.body)

        for (name, values) in request.headers {
            for value in values {
                nsRequest.setValue(value, forHTTPHeaderField: name)
            }
        }

        let task = nsSession.dataTaskWithRequest(
            nsRequest,
            completionHandler: {
                nsData, nsResponse, nsError -> Void in

                if let e = nsError {
                    errorHandler(message: e.localizedDescription)
                    return
                }

                let status: HTTPStatus
                let headers = HTTPHeaders()

                if let nsHTTPResponse = nsResponse as? NSHTTPURLResponse {
                    let statusInt = nsHTTPResponse.statusCode

                    guard let _status = HTTPStatus(rawValue: statusInt) else {
                        errorHandler(message: "Unknown HTTP status code: \(statusInt)")
                        return
                    }
        
                    status = _status
                    
                    for (name, value) in nsHTTPResponse.allHeaderFields {
                        let stringName  = name  as! String
                        let stringValue = value as! String

                        headers.add(name: stringName, value: stringValue)
                    }
                } else {
                    errorHandler(message: "Internal error: no NSHTTPURLResponse?")
                    return
                }
                
                let body = nsData!.asBytes()

                responseHandler(url: request.url, status: status, headers: headers, body: body)
            }
        )

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



protocol HTTPCredential {
}



class HTTPUsernamePasswordCredential: HTTPCredential {
    let username: String
    let password: String

    
    init(username: String, password:String) {
        self.username = username
        self.password = password
    }
}



private class SessionDelegate: NSObject, NSURLSessionTaskDelegate {
    
    weak var session: HTTPSession?

    private var lastCredential: HTTPCredential?
    
    
    @objc
    func URLSession(
        session: NSURLSession,
        task: NSURLSessionTask,
        didReceiveChallenge challenge: NSURLAuthenticationChallenge,
        completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void
    ) {
        func completeWithCredential(credential: HTTPCredential?) {
            let nsCredential: NSURLCredential?
            
            if let credential = credential as? HTTPUsernamePasswordCredential {
                nsCredential = NSURLCredential(
                    user: credential.username,
                    password: credential.password,
                    persistence: NSURLCredentialPersistence.ForSession
                )
            } else {
                nsCredential = nil
            }
            
            completionHandler(
                NSURLSessionAuthChallengeDisposition.UseCredential,
                nsCredential
            )
        }
        
        switch challenge.previousFailureCount {
            case 0:
                if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                    // This is a request to authenticate *the server* (eg. it's TLS certificate).
                    // We'll ask for the default handling of that here.
                    completionHandler(
                        NSURLSessionAuthChallengeDisposition.PerformDefaultHandling,
                        nil
                    )
                    return
                }
                
                if let lastCredential = lastCredential {
                    return completeWithCredential(lastCredential)
                }
                
                guard let authHandler = self.session?.authHandler else {
                    // The application did not provide an auth handler; use the default handling.
                    completionHandler(
                        NSURLSessionAuthChallengeDisposition.PerformDefaultHandling,
                        nil
                    )
                    return
                }
                
                logInfo("Authenticating HTTP connection...")
                
                lastCredential = authHandler(
                    host: challenge.protectionSpace.host,
                    port: challenge.protectionSpace.port,
                    realm: challenge.protectionSpace.realm
                )

                return completeWithCredential(lastCredential)

            default:
                break
        }
        
        logInfo("Unable to authenticate HTTP connection.")
        completionHandler(
            NSURLSessionAuthChallengeDisposition.CancelAuthenticationChallenge,
            nil
        )
    }

}



enum HTTPError: ErrorType {
    case InternalError(String)
    case InvalidURL(String)
}
