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



enum HTTPStatus: Int, CustomStringConvertible {
    
    // Informational
    case Continue                      = 100
    case SwitchingProtocols            = 101
    case Processing                    = 102

    // Success
    case OK                            = 200
    case Created                       = 201
    case Accepted                      = 202
    case NonAuthoritativeInformation   = 203
    case NoContent                     = 204
    case ResetContent                  = 205
    case PartialContent                = 206
    case MultiStatus                   = 207
    case AlreadyReported               = 208
    case IMUsed                        = 226

    // Redirection
    case MultipleChoices               = 300
    case MovedPermanently              = 301
    case Found                         = 302
    case SeeOther                      = 303
    case NotModified                   = 304
    case UseProxy                      = 305
    case TemporaryRedirect             = 307
    case PermanentRedirect             = 308
    
    // Client Error
    case BadRequest                    = 400
    case Unauthorized                  = 401
    case PaymentRequired               = 402
    case Forbidden                     = 403
    case NotFound                      = 404
    case MethodNotAllowed              = 405
    case NotAcceptable                 = 406
    case ProxyAuthenticationRequired   = 407
    case RequestTimeout                = 408
    case Conflict                      = 409
    case Gone                          = 410
    case LengthRequired                = 411
    case PreconditionFailed            = 412
    case PayloadTooLarge               = 413
    case URITooLarge                   = 414
    case UnsupportedMediaType          = 415
    case RangeNotSatisfiable           = 416
    case ExpectationFailed             = 417
    case MisdirectedRequest            = 421
    case UnprocessableEntity           = 422
    case Locked                        = 423
    case FailedDependency              = 424
    case UpgradeRequired               = 426
    case PreconditionRequired          = 428
    case TooManyRequests               = 429
    case RequestHeaderFieldsTooLarge   = 431
    
    // Server Error
    case InternalServerError           = 500
    case NotImplemented                = 501
    case BadGateway                    = 502
    case ServiceUnavailable            = 503
    case GatewayTimeout                = 504
    case HTTPVersionNotSupported       = 505
    case VariantAlsoNegotiates         = 506
    case InsufficientStorage           = 507
    case LoopDetected                  = 508
    case Unassigned                    = 509
    case NotExtended                   = 510
    case NetworkAuthenticationRequired = 511
    

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
        }
        
        return "\(self.rawValue.description) \(name)"
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
