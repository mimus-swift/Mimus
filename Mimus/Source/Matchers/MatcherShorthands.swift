//
// Copyright (©) 2018 AirHelp. All rights reserved.
//

import Foundation

// We prefix these functions with m to avoid having a global function named like `equal` -> might not be a good idea.
public func mEqual<T: Equatable>(_ object: T?) -> MockEquatable {
    return EqualTo(object)
}

public func mInstanceOf<T>(_ class: T.Type) -> MockEquatable {
    return InstanceOf<T>()
}

public func mIdentical<T: AnyObject>(_ object: T?) -> MockEquatable {
    return IdenticalTo(object)
}

public func mNot(_ matcher: MockEquatable) -> MockEquatable {
    return NotMatcher(containedMatcher: matcher)
}

public func mClosure<T>(_ closure: @escaping (T?) -> Bool) -> MockEquatable {
    return ClosureMatcher(closure)
}
                                            
