//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import XCTest
@testable import Mimus

class MatcherTests: XCTestCase {

    var matcher: Matcher!

    override func setUp() {
        super.setUp()

        matcher = Matcher()
    }

    override func tearDown() {
        matcher = nil
    }

    // MARK: Strings

    func testNSStringPassingInvocation() {
        let expected: NSString = "Fixture String"
        let actual: NSString = "Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result, "Expected strings to match")
    }

    func testStaticStringFailingInvocation() {
        let expected: NSString = "Fixture String"
        let actual: NSString = "Another Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result, "Expected strings to not match")
    }

    func testStaticStringWithNSStringPassingInvocation() {
        let expected: StaticString = "Fixture String"
        let actual: NSString = "Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result, "Expected strings to match")
    }

    func testStaticStringWithNSStringFailingInvocation() {
        let expected: StaticString = "Fixture String"
        let actual: NSString = "Another Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result, "Expected strings to not match")
    }

    func testStringWithNSStringPassingInvocation() {
        let expected = "Fixture String"
        let actual: NSString = "Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result, "Expected strings to match")
    }

    func testStringWithNSStringFailingInvocation() {
        let expected = "Fixture String"
        let actual: NSString = "Another Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result, "Expected strings to not match")
    }

    // MARK: NSNumber

    func testNSNumberPassingInvocation() {
        let expected: NSNumber = 42
        let actual: NSNumber = 42

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result, "Expected NSNumbers to match")
    }

    func testNSNumberFailingInvocation() {
        let expected: NSNumber = 42
        let actual: NSNumber = 43

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result, "Expected NSNumbers to not match")
    }

    // MARK: NSError

    func testNSErrorPassingInvocation() {
        let expected = NSError(domain: "Fixture Domain", code: 42)
        let actual = NSError(domain: "Fixture Domain", code: 42)

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result, "Expected NSErrors to match")
    }

    func testNSErrorFailingInvocation() {
        let expected = NSError(domain: "Fixture Domain", code: 42)
        let actual = NSError(domain: "Fixture Domain", code: 43)

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result, "Expected NSErrors to not match")
    }
    
}
