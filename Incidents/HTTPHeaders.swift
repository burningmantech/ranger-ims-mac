//
//  HTTPHeaders.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

enum HTTPHeaderName: String, CustomStringConvertible {
    case Accept      = "Accept"
    case ContentType = "Content-Type"
    case EntityTag   = "ETag"
    case Location    = "Location"
    case UserAgent   = "User-Agent"
    
    var description: String { return self.rawValue }
}



class HTTPHeaders: CollectionType, SequenceType, CustomStringConvertible {

    typealias Index = DictionaryIndex<String, [String]>
    typealias Element = (String, [String])
    typealias Generator = DictionaryGenerator<String, [String]>

    private var storage: [String: [String]]

    var startIndex: Index { return storage.startIndex }
    var endIndex  : Index { return storage.endIndex }
    var count     : Int   { return storage.count }
    var isEmpty   : Bool  { return storage.isEmpty }

    var keys: LazyMapCollection<Dictionary<String, [String]>, String> {
        return storage.keys
    }

    var values: LazyMapCollection<Dictionary<String, [String]>, [String]> {
        return storage.values
    }

    var description: String { return storage.description }


    init() {
        storage = Dictionary()
    }


    subscript(key: String) -> [String]? {
        get {
            return storage[key.lowercaseString]
        }

        set(value) {
            storage[key.lowercaseString] = value
        }
    }


    subscript(position: Index) -> Generator.Element {
        return storage[position]
    }


    func generate() -> Generator {
        return storage.generate()
    }

    
    func set(name name: String, value: String) {
        self[name] = [value]
    }


    func set(name name: String, values: [String]) {
        self[name] = values
    }


    func add(name name: String, value: String) {
        if var values = self[name] {
            values.append(value)
            self[name] = values
        } else {
            self[name] = [value]
        }
    }


    func add(name name: String, values: [String]) {
        if var existing = self[name] {
            existing += values
            self[name] = existing
        } else {
            self[name] = values
        }

    }


    func add(dictionary dictionary: [String: [String]]) {
        for (name, values) in dictionary {
            self.add(name: name, values: values)
        }
    }


    func add(headers headers: HTTPHeaders) {
        for (name, values) in headers {
            self.add(name: name, values: values)
        }
    }
    
}
