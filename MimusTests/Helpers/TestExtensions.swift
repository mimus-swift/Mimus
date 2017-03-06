//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import Foundation

@testable import Mimus

extension VerificationMode: Equatable {
}

public func ==(lhs: VerificationMode, rhs: VerificationMode) -> Bool {
    switch (lhs, rhs) {
    case (let .times(time1), let .times(time2)):
        return time1 == time2
    case (.never, .never):
        return true
    case (let .atLeast(time1), let .atLeast(time2)):
        return time1 == time2
    default:
        return false
    }
}

