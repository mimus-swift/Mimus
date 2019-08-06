import Foundation

public final class EqualTo<T: Equatable>: MockEquatable, CustomStringConvertible {

    private let object: T?

    public init(_ object: T?) {
        self.object = object
    }

    public func equalTo(other: Any?) -> Bool {
        if let otherObject = other as? T {
            return object == otherObject
        }
        return other == nil && object == nil
    }

    public var description: String {
        return "\(type(of: self)) - \(object.mimusDescription())"
    }
}
