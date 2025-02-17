import Foundation

///
/// A matcher that captures the argument into a pointer. Useful when you want to grab the argument
/// and perform more complex assertions on it.
///
/// Important caveat - this will not work correctly with property wrappers like, for instance, `@TestState` in Quick.
///
public struct CapturePointerMatcher<T>: Matcher {
    private let pointer: UnsafeMutablePointer<T?>

    public init(pointer: UnsafeMutablePointer<T?>) { self.pointer = pointer }

    public func matches(argument: Any?) -> Bool {
        pointer.pointee = argument as? T
        return true
    }
}
