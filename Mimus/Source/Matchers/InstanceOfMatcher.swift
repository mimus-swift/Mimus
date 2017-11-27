//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import Foundation

public class InstanceOf<T>: MockEquatable {
    
    public init() { }
    
    public func equalTo(other: Any?) -> Bool {
        return other is T
    }
}
