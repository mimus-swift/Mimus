import Foundation

extension NSError: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let otherError = argument as? NSError {
            return self == otherError
        }
        return false
    }
}

extension NSString: Matcher {
    public func matches(argument: Any?) -> Bool {
        let selfSwiftString = self as String
        return selfSwiftString.matches(argument: argument)
    }
}

extension NSNumber: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let otherNumber = argument as? NSNumber {
            return self == otherNumber
        }
        return false
    }
}

extension NSArray: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let array = self as? Array<Matcher> {
            return array.matches(argument: argument)
        } else {
            return false
        }
    }
}

extension NSDictionary: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let dictionary = self as? Dictionary<AnyHashable, Any> {
            return dictionary.matches(argument: argument)
        } else {
            return false
        }
    }
}

extension NSNull: Matcher {
    public func matches(argument: Any?) -> Bool {
        return argument == nil || argument is NSNull
    }
}

extension NSURL: Matcher {
    public func matches(argument: Any?) -> Bool {
        let selfSwiftUrl = self as URL
        return selfSwiftUrl.matches(argument: argument)
    }
}

extension Data: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let other = argument as? Data {
            return other == self
        }
        return false
    }
}

extension URLRequest: Matcher {
    public func matches(argument: Any?) -> Bool {
        if let other = argument as? URLRequest {
            return other == self
        }
        return false
    }
}
