//
//  HTTPConnection.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

enum HTTPMethod: String, CustomStringConvertible {

    case HEAD = "HEAD"
    case GET  = "GET"
    case POST = "POST"


    var description: String { return self.rawValue }

}



enum HTTPStatus: CustomStringConvertible {
    
    case Continue
    case SwitchingProtocols
    case Processing
    
    case OK
    case Created
    case Accepted
    case NonAuthoritativeInformation
    case NoContent
    case ResetContent
    case PartialContent
    case MultiStatus
    case AlreadyReported
    case IMUsed

    case MultipleChoices
    case MovedPermanently
    case Found
    case SeeOther
    case NotModified
    case UseProxy
    case TemporaryRedirect
    case PermanentRedirect
    
    case BadRequest
    case Unauthorized
    case PaymentRequired
    case Forbidden
    case NotFound
    case MethodNotAllowed
    case NotAcceptable
    case ProxyAuthenticationRequired
    case RequestTimeout
    case Conflict
    case Gone
    case LengthRequired
    case PreconditionFailed
    case PayloadTooLarge
    case URITooLarge
    case UnsupportedMediaType
    case RangeNotSatisfiable
    case ExpectationFailed
    case MisdirectedRequest
    case UnprocessableEntity
    case Locked
    case FailedDependency
    case UpgradeRequired
    case PreconditionRequired
    case TooManyRequests
    case RequestHeaderFieldsTooLarge
    
    case InternalServerError
    case NotImplemented
    case BadGateway
    case ServiceUnavailable
    case GatewayTimeout
    case HTTPVersionNotSupported
    case VariantAlsoNegotiates
    case InsufficientStorage
    case LoopDetected
    case Unassigned
    case NotExtended
    case NetworkAuthenticationRequired
    
    case Unknown(Int)

    
    var code: Int {
        switch self {
            case .Continue                     : return 100
            case .SwitchingProtocols           : return 101
            case .Processing                   : return 102
            
            case .OK                           : return 200
            case .Created                      : return 201
            case .Accepted                     : return 202
            case .NonAuthoritativeInformation  : return 203
            case .NoContent                    : return 204
            case .ResetContent                 : return 205
            case .PartialContent               : return 206
            case .MultiStatus                  : return 207
            case .AlreadyReported              : return 208
            case .IMUsed                       : return 226

            case .MultipleChoices              : return 300
            case .MovedPermanently             : return 301
            case .Found                        : return 302
            case .SeeOther                     : return 303
            case .NotModified                  : return 304
            case .UseProxy                     : return 305
            case .TemporaryRedirect            : return 307
            case .PermanentRedirect            : return 308

            case .BadRequest                   : return 400
            case .Unauthorized                 : return 401
            case .PaymentRequired              : return 402
            case .Forbidden                    : return 403
            case .NotFound                     : return 404
            case .MethodNotAllowed             : return 405
            case .NotAcceptable                : return 406
            case .ProxyAuthenticationRequired  : return 407
            case .RequestTimeout               : return 408
            case .Conflict                     : return 409
            case .Gone                         : return 410
            case .LengthRequired               : return 411
            case .PreconditionFailed           : return 412
            case .PayloadTooLarge              : return 413
            case .URITooLarge                  : return 414
            case .UnsupportedMediaType         : return 415
            case .RangeNotSatisfiable          : return 416
            case .ExpectationFailed            : return 417
            case .MisdirectedRequest           : return 421
            case .UnprocessableEntity          : return 422
            case .Locked                       : return 423
            case .FailedDependency             : return 424
            case .UpgradeRequired              : return 426
            case .PreconditionRequired         : return 428
            case .TooManyRequests              : return 429
            case .RequestHeaderFieldsTooLarge  : return 431

            case .InternalServerError          : return 500
            case .NotImplemented               : return 501
            case .BadGateway                   : return 502
            case .ServiceUnavailable           : return 503
            case .GatewayTimeout               : return 504
            case .HTTPVersionNotSupported      : return 505
            case .VariantAlsoNegotiates        : return 506
            case .InsufficientStorage          : return 507
            case .LoopDetected                 : return 508
            case .Unassigned                   : return 509
            case .NotExtended                  : return 510
            case .NetworkAuthenticationRequired: return 511
            
            case .Unknown(let code): return code
        }
    }
    

    var description: String {
        let name: String
        
        switch self {
            case .Continue                     : name = "Continue"
            case .SwitchingProtocols           : name = "Switching Protocols"
            case .Processing                   : name = "Processing"

            case .OK                           : name = "OK"
            case .Created                      : name = "Created"
            case .Accepted                     : name = "Accepted"
            case .NonAuthoritativeInformation  : name = "Non Authoritative Information"
            case .NoContent                    : name = "No Content"
            case .ResetContent                 : name = "Reset Content"
            case .PartialContent               : name = "Partial Content"
            case .MultiStatus                  : name = "Multi Status"
            case .AlreadyReported              : name = "Already Reported"
            case .IMUsed                       : name = "IM Used"
            
            case .MultipleChoices              : name = "Multiple Choices"
            case .MovedPermanently             : name = "Moved Permanently"
            case .Found                        : name = "Found"
            case .SeeOther                     : name = "See Other"
            case .NotModified                  : name = "Not Modified"
            case .UseProxy                     : name = "Use Proxy"
            case .TemporaryRedirect            : name = "Temporary Redirect"
            case .PermanentRedirect            : name = "Permanent Redirect"
            
            case .BadRequest                   : name = "Bad Request"
            case .Unauthorized                 : name = "Unauthorized"
            case .PaymentRequired              : name = "Payment Required"
            case .Forbidden                    : name = "Forbidden"
            case .NotFound                     : name = "Not Found"
            case .MethodNotAllowed             : name = "Method Not Allowed"
            case .NotAcceptable                : name = "Not Acceptable"
            case .ProxyAuthenticationRequired  : name = "Proxy Authentication Required"
            case .RequestTimeout               : name = "Request Timeout"
            case .Conflict                     : name = "Conflict"
            case .Gone                         : name = "Gone"
            case .LengthRequired               : name = "Length Required"
            case .PreconditionFailed           : name = "Precondition Failed"
            case .PayloadTooLarge              : name = "Payload Too Large"
            case .URITooLarge                  : name = "URI Too Large"
            case .UnsupportedMediaType         : name = "Unsupported Media Type"
            case .RangeNotSatisfiable          : name = "RangeNotSatisfiable"
            case .ExpectationFailed            : name = "Expectation Failed"
            case .MisdirectedRequest           : name = "Misdirected Request"
            case .UnprocessableEntity          : name = "Unprocessable Entity"
            case .Locked                       : name = "Locked"
            case .FailedDependency             : name = "Failed Dependency"
            case .UpgradeRequired              : name = "Upgrade Required"
            case .PreconditionRequired         : name = "Precondition Required"
            case .TooManyRequests              : name = "Too Many Requests"
            case .RequestHeaderFieldsTooLarge  : name = "Request Header Fields Too Large"

            case .InternalServerError          : name = "Internal Server Error"
            case .NotImplemented               : name = "Not Implemented"
            case .BadGateway                   : name = "Bad Gateway"
            case .ServiceUnavailable           : name = "Service Unavailable"
            case .GatewayTimeout               : name = "Gateway Timeout"
            case .HTTPVersionNotSupported      : name = "HTTP Version Not Supported"
            case .VariantAlsoNegotiates        : name = "Variant Also Negotiates"
            case .InsufficientStorage          : name = "Insufficient Storage"
            case .LoopDetected                 : name = "Loop Detected"
            case .Unassigned                   : name = "Unassigned"
            case .NotExtended                  : name = "Not Extended"
            case .NetworkAuthenticationRequired: name = "Network Authentication Required"
            
            case .Unknown                      : name = "(unknown)"
        }
        
        return "\(self.code.description) \(name)"
    }
    
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
