//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import Foundation
import Mimus

class FakeAuthenticationManager: AuthenticationManager, Mock {

    var storage = Mimus.Storage()

    func setup() {
        recordCall(withIdentifier: "Setup")
    }

    func beginAuthentication(with email: String, password: String, options: [String: Any]) {
        recordCall(withIdentifier: "BeginAuthentication", arguments: [email, password, options])
    }
}
