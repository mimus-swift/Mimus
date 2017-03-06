//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import Foundation
import Mimus
import XCTest

class AuthenticationCoordinatorTests: XCTestCase {

    var fakeLoginAuthenticationManager: FakeAuthenticationManager!

    var sut: AuthenticationCoordinator!

    override func setUp() {
        fakeLoginAuthenticationManager = FakeAuthenticationManager()
        
        sut = AuthenticationCoordinator(loginAuthenticationManager: fakeLoginAuthenticationManager)

        super.setUp()
    }

    override func tearDown() {
        sut = nil
        
        super.tearDown()
    }

    // MARK: Basic Usage

    func testSetup() {
        sut.setup()

        // Simple verification without arguments
        fakeLoginAuthenticationManager.verifyCall(withIdentifier: "Setup")
    }

    func testLogin() {
        sut.login(with: "Fixture Email", password: "Fixture Password")

        // More complicated verification with arguments
        fakeLoginAuthenticationManager.verifyCall(withIdentifier: "BeginAuthentication",
                arguments: ["Fixture Email", "Fixture Password", ["type": "login"]])
    }

    // MARK: Any Matcher

    func testAnyMatcher() {
        sut.login(with: "Fixture Email", password: "Fixture Password")

        fakeLoginAuthenticationManager.verifyCall(withIdentifier: "BeginAuthentication",
                arguments: ["Fixture Email", "Fixture Password", AnyMatcher()])
    }

    // MARK: Argument Captor

    func testCaptureArgument() {
        sut.login(with: "Fixture Email", password: "Fixture Password")

        let argumentCaptor = CaptureArgumentMatcher()

        fakeLoginAuthenticationManager.verifyCall(withIdentifier: "BeginAuthentication",
                arguments: ["Fixture Email", "Fixture Password", argumentCaptor])

        let capturedOptions = argumentCaptor.capturedValues.last as? [String: String]

        XCTAssertEqual(capturedOptions?["type"], "login")
    }
}
