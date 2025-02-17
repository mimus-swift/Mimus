//
// Copyright (©) 2018 AirHelp. All rights reserved.
//

import Foundation

// We prefix these functions with m to avoid having a global function named like `equal` -> might not be a good idea.
public func mEqual<T: Equatable>(_ object: T?) -> Matcher {
    return EqualTo(object)
}

public func mInstanceOf<T>(_ class: T.Type) -> Matcher {
    return InstanceOf<T>()
}

public func mIdentical<T: AnyObject>(_ object: T?) -> Matcher {
    return IdenticalTo(object)
}

public func mNot(_ matcher: Matcher) -> Matcher {
    return NotMatcher(containedMatcher: matcher)
}

public func mClosure<T>(_ closure: @escaping (T?) -> Bool) -> Matcher {
    return ClosureMatcher(closure)
}
                                            
public func mAny() -> Matcher {
    return AnyMatcher()
}

public func mCaptureInto<T>(pointer: UnsafeMutablePointer<T?>) -> Matcher {
    CapturePointerMatcher(pointer: pointer)
}

///
/// Simulates a callback if the matched element is a closure of (T1) -> Void type.
/// Note the simulation is triggered when the elements is being matched to actual value.
///
public func mSimulateCallback<T1>(_ arg1: T1) -> Matcher {
    return SimulateCallbackMatcher(arg1, Void(), Void())
}

///
/// Simulates a callback if the matched element is a closure of (T1, T2) -> Void type.
/// Note the simulation is triggered when the elements is being matched to actual value.
///
public func mSimulateCallback<T1, T2>(_ arg1: T1, _ arg2: T2) -> Matcher {
    return SimulateCallbackMatcher(arg1, arg2, Void())
}

///
/// Simulates a callback if the matched element is a closure of (T1, T2, T3) -> Void type.
/// Note the simulation is triggered when the elements is being matched to actual value.
///
public func mSimulateCallback<T1, T2, T3>(_ arg1: T1, _ arg2: T2, _ arg3: T3) -> Matcher {
    return SimulateCallbackMatcher(arg1, arg2, arg3)
}

///
/// Simulates a completion if the matched element is a closure of () -> Void type. Note the simulation is triggered when
/// the elements is being matched to actual value.
///
public func mSimulateCompletion() -> Matcher {
    return SimulateCallbackMatcher(Void(), Void(), Void())
}
