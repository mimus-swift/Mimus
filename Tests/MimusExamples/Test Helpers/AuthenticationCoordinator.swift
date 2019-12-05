//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import Foundation

class AuthenticationCoordinator {

    let loginAuthenticationManager: AuthenticationManager

    init(loginAuthenticationManager: AuthenticationManager) {
        self.loginAuthenticationManager = loginAuthenticationManager
    }

    func setup() {
        loginAuthenticationManager.setup()
    }

    func login(with email: String, password: String) {
        loginAuthenticationManager.beginAuthentication(with: email, password: password, options: ["type": "login"])
    }
}
