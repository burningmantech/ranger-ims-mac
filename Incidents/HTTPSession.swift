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
                "User-Agent": userAgent!
            ]
        }

        configuration.timeoutIntervalForRequest = NSTimeInterval(idleTimeOut)
        configuration.TLSMinimumSupportedProtocol = kTLSProtocol12

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

        for (name, values) in request.headers {
            for value in values {
                nsRequest.setValue(value, forHTTPHeaderField: name)
            }
        }
        
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
                
                let body = nsData!.asBytes()

                responseHandler(url: request.url, status: status, headers: headers, body: body)
            }
        ) else {
            throw HTTPError.InternalError("Unable to create HTTP task")
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
    
    
    @objc
    func URLSession(
        session: NSURLSession,
        task: NSURLSessionTask,
        didReceiveChallenge challenge: NSURLAuthenticationChallenge,
        completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void
    ) {
        switch challenge.previousFailureCount {
            case 0:
                guard let authHandler = self.session?.authHandler else {
                    completionHandler(
                        NSURLSessionAuthChallengeDisposition.PerformDefaultHandling,
                        nil
                    )
                    return
                }

// FIXME
//                if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
//                    logInfo("Authenticating HTTP server certificate...")
//                    
//                }
                
                logInfo("Authenticating HTTP connection...")
                
                let credential = authHandler(
                    host: challenge.protectionSpace.host,
                    port: challenge.protectionSpace.port,
                    realm: challenge.protectionSpace.realm
                )
                    
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
                return

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
