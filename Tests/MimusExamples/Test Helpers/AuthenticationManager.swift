//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import Foundation

protocol AuthenticationManager {

    func setup()

    func beginAuthentication(with email: String, password: String, options: [String: Any])
}
