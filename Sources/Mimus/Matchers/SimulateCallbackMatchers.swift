import Foundation

public class SimulateCallbackMatcher<T1, T2, T3>: Matcher {
    private let arg1: T1
    private let arg2: T2
    private let arg3: T3

    public init(_ arg1: T1, _ arg2: T2, _ arg3: T3) {
        self.arg1 = arg1
        self.arg2 = arg2
        self.arg3 = arg3
    }

    public func matches(argument: Any?) -> Bool {
        switch argument {
        case let callback as (T1, T2, T3) -> Void:
            callback(arg1, arg2, arg3)
        case let callback as (T1, T2) -> Void:
            callback(arg1, arg2)
        case let callback as (T1) -> Void:
            callback(arg1)
        case let callback as () -> Void:
            callback()
        default:
            return false
        }
        return true
    }
}
