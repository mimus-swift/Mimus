import Foundation

extension NSError: MockEquatable {
    public func equalTo(other: Any?) -> Bool {
        if let otherError = other as? NSError {
            return self == otherError
        }
        return false
    }
}

extension NSString: MockEquatable {
    public func equalTo(other: Any?) -> Bool {
        let selfSwiftString = self as String
        return selfSwiftString.equalTo(other: other)
    }
}

extension NSNumber: MockEquatable {
    public func equalTo(other: Any?) -> Bool {
        if let otherNumber = other as? NSNumber {
            return self == otherNumber
        }
        return false
    }
}

extension NSArray: MockEquatable {
    public func equalTo(other: Any?) -> Bool {
        if let array = self as? Array<Any> {
            return array.equalTo(other: other)
        } else {
            return false
        }
    }
}

extension NSDictionary: MockEquatable {
    public func equalTo(other: Any?) -> Bool {
        if let dictionary = self as? Dictionary<AnyHashable, Any> {
            return dictionary.equalTo(other: other)
        } else {
            return false
        }
    }
}

extension NSNull: MockEquatable {
    public func equalTo(other: Any?) -> Bool {
        return other == nil || other is NSNull
    }
}

extension NSURL: MockEquatable {
    public func equalTo(other: Any?) -> Bool {
        let selfSwiftUrl = self as URL
        return selfSwiftUrl.equalTo(other: other)
    }
}

extension Data: MockEquatable {
    public func equalTo(other: Any?) -> Bool {
        if let other = other as? Data {
            return other == self
        }
        return false
    }
}

extension URLRequest: MockEquatable {
    public func equalTo(other: Any?) -> Bool {
        if let other = other as? URLRequest {
            return other == self
        }
        return false
    }
}
