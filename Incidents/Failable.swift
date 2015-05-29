//
//  Failable.swift
//
// The MIT License (MIT)
//
// © 2014 David Owens II
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation



/**
* A `Failable` should be returned from functions that need to return success or failure information but has no other
* meaning information to return. Functions that need to also return a value on success should use `FailableOf<T>`.
*/
public enum Failable {
    case Success
    case Failure(Error)

    init() {
        self = .Success
    }

    init(_ error: Error) {
        self = .Failure(error)
    }

    public var failed: Bool {
        switch self {
        case .Failure(let error):
            return true

        default:
            return false
        }
    }

    public var error: Error? {
        switch self {
        case .Failure(let error):
            return error

        default:
            return nil
        }
    }
}

/**
* A `FailableOf<T>` should be returned from functions that need to return success or failure information and some
* corresponding data back upon a successful function call.
*/
public enum FailableOf<T> {
    case Success(FailableValueWrapper<T>)
    case Failure(Error)

    public init(_ value: T) {
        self = .Success(FailableValueWrapper(value))
    }

    public init(_ error: Error) {
        self = .Failure(error)
    }

    public var failed: Bool {
        switch self {
        case .Failure(let error):
            return true

        default:
            return false
        }
    }

    public var error: Error? {
        switch self {
        case .Failure(let error):
            return error

        default:
            return nil
        }
    }

    public var value: T? {
        switch self {
        case .Success(let wrapper):
            return wrapper.value

        default:
            return nil
        }
    }
}

/// This is a workaround-wrapper class for a bug in the Swift compiler. DO NOT USE THIS CLASS!!
public class FailableValueWrapper<T> {
    public let value: T
    public init(_ value: T) { self.value = value }
}
