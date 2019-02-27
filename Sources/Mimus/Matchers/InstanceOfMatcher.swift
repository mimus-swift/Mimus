//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import Foundation

public final class InstanceOf<T>: Matcher {

    public init() { }

    public func matches(argument: Any?) -> Bool {
        return argument is T
    }
}
