import Foundation

public struct CapturePointerMatcher<T>: Matcher {
    private let pointer: UnsafeMutablePointer<T?>

    init(pointer: UnsafeMutablePointer<T?>) { self.pointer = pointer }

    public func matches(argument: Any?) -> Bool {
        pointer.pointee = argument as? T
        return true
    }
}

public func mCaptureInto<T>(pointer: UnsafeMutablePointer<T?>) -> Matcher {
    CapturePointerMatcher(pointer: pointer)
}
