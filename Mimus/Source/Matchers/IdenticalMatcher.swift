import Foundation

public final class IdenticalTo<T: AnyObject>: MockEquatable {
    
    let object: T
    
    public init(_ object: T) {
        self.object = object
    }
    
    public func equalTo(other: Any?) -> Bool {
        if let otherObject = other as? T {
            return object === otherObject
        }
        return false
    }
}

// We prefix with m to avoid having a global function named `identical` -> might not be a good idea.
public func mIdentical<T: AnyObject>(_ object: T) -> MockEquatable {
    return IdenticalTo(object)
}
