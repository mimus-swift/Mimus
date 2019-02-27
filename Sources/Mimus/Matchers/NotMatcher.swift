//
// Copyright (©) 2018 AirHelp. All rights reserved.
//

import Foundation

public class NotMatcher: Matcher {
    private let containedMatcher: Matcher

    public init(containedMatcher: Matcher) {
        self.containedMatcher = containedMatcher
    }

    public func matches(argument: Any?) -> Bool {
        return !containedMatcher.matches(argument: argument)
    }

    public var description: String {
        return "\(type(of: self)) - \(containedMatcher)"
    }
}
