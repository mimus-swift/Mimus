//
// Copyright (©) 2018 AirHelp. All rights reserved.
//

import Foundation

public class ClosureMatcher<T>: MockEquatable {
    private let closure: (T?) -> Bool

    public init(_ closure: @escaping (T?) -> Bool) {
         self.closure = closure
    }

    public func equalTo(other: Any?) -> Bool {
        guard let otherAsType = other as? T? else {
            return false
        }
        return closure(otherAsType)
    }
}
