//
//  HTTPSessionTests.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import XCTest



class HTTPSessionSendTests: XCTestCase {

    func test_send_badURL() {

        let targetURL = "This is not a URL!"

        var session = MockHTTPSession()

        var request = HTTPRequest(url: targetURL)

        func responseHandler(
            url: String,
            status: Int,
            headers: HTTPHeaders,
            data:[UInt8]
        ) -> Void {
            XCTFail("Response unexpected.")
        }

        func errorHandler(message: String) -> Void {
            XCTAssertEqual(message, "Invalid URL: \(targetURL)")
        }

        session.send(
            request: request,
            responseHandler: responseHandler,
            errorHandler: errorHandler
        )
    }


    func test_send_response() {
        let expectation = expectationWithDescription("Response handler called")

        let targetURL = "http://www.example.com/"

        var session = MockHTTPSession()

        var request = HTTPRequest(url: targetURL)

        func responseHandler(
            url: String,
            status: Int,
            headers: HTTPHeaders,
            body:[UInt8]
        ) -> Void {
            XCTAssertEqual(url, targetURL)
            XCTAssertEqual(status, 200)

            if let values = headers["Content-Type"] {
                XCTAssertEqual(values.count, 1)
                XCTAssertTrue(values[0].hasPrefix("text/html"))
            } else {
                XCTFail("No Content-Type header")
            }

            // Body...
            XCTAssertGreaterThan(body.count, 1)
            XCTAssertEqual(body[0], 60)  // 60 is ASCII '<'

            expectation.fulfill()
        }

        func errorHandler(message: String) -> Void {
            XCTFail("Error unexpected: \(message)")

            expectation.fulfill()
        }

        let connection = session.send(
            request: request,
            responseHandler: responseHandler,
            errorHandler: errorHandler
        )
        XCTAssertNotNil(connection)

        waitForExpectationsWithTimeout(30, handler: {
            (error) in connection!.cancel()
        })
    }

}



class MockNSURLSessionDataTask: NSURLSessionDataTask {
    var completed: Bool
    let request: NSURLRequest
    let completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?

    init(
        request: NSURLRequest,
        completionHandler: ((NSData!, NSURLResponse!, NSError!) -> Void)?
    ) {
        self.request = request
        self.completionHandler = completionHandler
        self.completed = false
    }

    override func cancel () {}
    override func suspend() {}

    override func resume () {
        if !completed {
            self.complete()

            completed = true
        }
    }

    func complete() {
        let errorMessage: String

        if let method = request.HTTPMethod {
            if let url = request.URL {
                if method == "GET" {
                    if request.URL?.absoluteString == "http://www.example.com/" {
                        let response = NSHTTPURLResponse(
                            URL: url,
                            statusCode: 200,
                            HTTPVersion: "HTTP/1.1",
                            headerFields: [
                                "Content-Type": "text/html; charset=utf-8"
                            ]
                        )

                        let data = ("<html></html>" as NSString).dataUsingEncoding(NSUTF8StringEncoding)!

                        return completionHandler!(data, response, nil)
                    } else {
                        errorMessage = "Unknown URL"
                    }
                } else {
                    errorMessage = "No URL"
                }
            } else {
                errorMessage = "Unknown method: \(method)"
            }
        } else {
            errorMessage = "No request method"
        }

        let error = NSError(
            domain: "MockNSURLSession",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: errorMessage]
        )
        completionHandler!(NSData(), nil, error)
    }
}



class MockNSURLSession: NSURLSession {
    override func dataTaskWithRequest(
        request: NSURLRequest,
        completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void
    ) -> NSURLSessionDataTask {
        return MockNSURLSessionDataTask(
            request: request,
            completionHandler: completionHandler
        )
    }
}



class MockHTTPSession: HTTPSession {
    override init(
        userAgent: String? = nil,
        idleTimeOut: Int = 30,
        timeOut: Int = 3600
    ) {
        super.init(nsSession: MockNSURLSession())
    }
}