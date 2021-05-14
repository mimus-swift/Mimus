import Foundation

public final class IdenticalTo<T: AnyObject>: Matcher, CustomStringConvertible {

    private let object: T?

    public init(_ object: T?) {
        self.object = object
    }

    public func matches(argument: Any?) -> Bool {
        if let otherObject = argument as? T {
            return object === otherObject
        }
        return argument == nil && object == nil
    }

    public var description: String {
        return "\(type(of: self)) - \(object.mimusDescription())"
    }
}
