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
