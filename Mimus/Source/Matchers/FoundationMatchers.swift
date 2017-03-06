import Foundation

extension NSError: MockEquatable {

    public func equalTo(other: MockEquatable?) -> Bool {
        if let otherError = other as? NSError {
            return self == otherError
        }
        return false
    }
}

extension NSString: MockEquatable {

    public func equalTo(other: MockEquatable?) -> Bool {
        let selfSwiftString = self as String
        return selfSwiftString.equalTo(other: other)
    }
}

extension NSNumber: MockEquatable {

    public func equalTo(other: MockEquatable?) -> Bool {
        if let otherNumber = other as? NSNumber {
            return self == otherNumber
        }
        return false
    }
}
