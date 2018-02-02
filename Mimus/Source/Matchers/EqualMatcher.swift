import Foundation

public final class EqualTo<T: Equatable>: MockEquatable {

    let object: T

    public init(_ object: T) {
        self.object = object
    }

    public func equalTo(other: Any?) -> Bool {
        if let otherObject = other as? T {
            return object == otherObject
        }
        return false
    }
}

// We prefix with m to avoid having a global function named `equal` -> might not be a good idea.
public func mEqual<T: Equatable>(_ object: T) -> MockEquatable {
    return EqualTo(object)
}
