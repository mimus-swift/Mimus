//
// Copyright (©) 2018 AirHelp. All rights reserved.
//

import Foundation

public class ClosureMatcher<T>: Matcher {
    private let closure: (T?) -> Bool

    public init(_ closure: @escaping (T?) -> Bool) {
         self.closure = closure
    }

    public func matches(argument: Any?) -> Bool {
        guard let otherAsType = argument as? T? else {
            return false
        }
        return closure(otherAsType)
    }
}
