//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import Foundation

/// Convenience extension to reduce boilerplate code when writing custom extension matchers.
/// See https://github.com/mimus-swift/Mimus/blob/master/Documentation/Using%20Your%20Own%20Types.md for details. 
public extension Matcher {
    func compare<T: Equatable>(other: T?) -> Bool {
        guard let equatableSelf = self as? T, let other = other else {
            return false
        }
        return equatableSelf == other
    }
}
