//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import Foundation
import XCTest

@testable import Mimus

extension VerificationMode: @retroactive Equatable {
}

public func ==(lhs: VerificationMode, rhs: VerificationMode) -> Bool {
    switch (lhs, rhs) {
    case (let .times(time1), let .times(time2)):
        return time1 == time2
    case (.never, .never):
        return true
    case (let .atLeast(time1), let .atLeast(time2)):
        return time1 == time2
    case (let .atMost(time1), let .atMost(time2)):
        return time1 == time2
    default:
        return false
    }
}

extension MimusComparator.ComparisonResult.MismatchedComparison {
    func assert<T: Equatable, M: Equatable>(expected: T?, actual: M?, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(actual, self.actual as? M, file: file, line: line)
        XCTAssertEqual(expected, self.expected as? T, file: file, line: line)
    }
}
