//
// Copyright (©) 2019 AirHelp. All rights reserved.
//

import Foundation

extension Optional {
    func mimusDescription() -> String {
        switch self {
        case .none:
            return "<(nil)>"
        case .some(let value):
            return "<(\(String(describing: value)))>"
        }
    }
}
