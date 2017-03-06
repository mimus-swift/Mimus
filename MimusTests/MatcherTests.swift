//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import XCTest
@testable import Mimus

class FoundationMatcherTests: XCTestCase {

    var matcher: Matcher!

    override func setUp() {
        super.setUp()

        matcher = Matcher()
    }

    override func tearDown() {
        matcher = nil
    }

    // MARK: Strings

    func testStringPassingInvocation() {
        let result = matcher.match(expected: ["Fixture String"], actual: ["Fixture String"])
        XCTAssertTrue(result, "Expected strings to match")
    }

    func testStringFailingInvocation() {
        let result = matcher.match(expected: ["Fixture String"], actual: ["Fixture Another String"])
        XCTAssertFalse(result, "Expected strings to not match")
    }

    func testStaticStringPassingInvocation() {
        let expected: StaticString = "Fixture String"
        let actual: StaticString = "Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result, "Expected strings to match")
    }

    func testStaticStringFailingInvocation() {
        let expected: StaticString = "Fixture String"
        let actual: StaticString = "Another Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result, "Expected strings to not match")
    }

    func testStaticStringWithStringPassingInvocation() {
        let expected: StaticString = "Fixture String"
        let actual = "Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result, "Expected strings to match")
    }

    func testStaticStringWithStringFailingInvocation() {
        let expected: StaticString = "Fixture String"
        let actual = "Another Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result, "Expected strings to not match")
    }

    // MARK: Basic Types

    func testIntPassingInvocation() {
        let result = matcher.match(expected: [42], actual: [42])
        XCTAssertTrue(result, "Expected ints to match")
    }

    func testIntFailingInvocation() {
        let result = matcher.match(expected: [42], actual: [43])
        XCTAssertFalse(result, "Expected ints to not match")
    }

    func testDoublePassingInvocation() {
        let result = matcher.match(expected: [42.0], actual: [42.0])
        XCTAssertTrue(result, "Expected doubles to match")
    }

    func testDoubleFailingInvocation() {
        let result = matcher.match(expected: [42.0], actual: [43.0])
        XCTAssertFalse(result, "Expected doubles to not match")
    }

    func testBoolPassingInvocation() {
        let result = matcher.match(expected: [true], actual: [true])
        XCTAssertTrue(result, "Expected booleans to match")
    }

    func testBoolFailingInvocation() {
        let result = matcher.match(expected: [true], actual: [false])
        XCTAssertFalse(result, "Expected booleans to not match")
    }

    // MARK: Index Paths

    func testIndexPathPassingInvocation() {
        let result = matcher.match(
                expected: [IndexPath(row: 42, section: 43)],
                actual: [IndexPath(row: 42, section: 43)]
        )
        XCTAssertTrue(result, "Expected index paths to match")
    }

    func testIndexPathFailingInvocation() {
        let result = matcher.match(
                expected: [IndexPath(row: 42, section: 43)],
                actual: [IndexPath(row: 44, section: 43)]
        )
        XCTAssertFalse(result, "Expected index paths to not match")
    }

    // MARK: Different Types

    func testIncorrectTypes() {
        let result = matcher.match(expected: [42.0], actual: ["Fixture String"])
        XCTAssertFalse(result, "Expected incorrect to not match")
    }

    // MARK: Working with optionals and nil

    func testNilPassingInvocation() {
        let result = matcher.match(expected: [nil], actual: [nil])
        XCTAssertTrue(result, "Expected nils to match")
    }

    func testNilFailingInvocation() {
        let result = matcher.match(expected: [nil], actual: [42])
        XCTAssertFalse(result, "Expected elements to not match")
    }

    // MARK: Arrays

    func testArrayPassingInvocation() {
        let result = matcher.match(
                expected: [["Fixture Value 1", "Fixture Value 2"]],
                actual: [["Fixture Value 1", "Fixture Value 2"]]
        )
        XCTAssertTrue(result, "Expected arrays to match")
    }

    func testArrayFailingInvocation() {
        let result = matcher.match(
                expected: [["Fixture Value 1", "Fixture Value 2"]],
                actual: [["Fixture Value 1", "Another Fixture Value 2"]]
        )
        XCTAssertFalse(result, "Expected arrays to not match")
    }

    // MARK: Dictionaries

    func testDictionaryPassingInvocation() {
        let result = matcher.match(
                expected: [["Fixture Key": "Fixture Value"]],
                actual: [["Fixture Key": "Fixture Value"]]
        )
        XCTAssertTrue(result, "Expected dictionary to match")
    }

    func testDictionaryFailingInvocationDifferentKeys() {
        let result = matcher.match(
                expected: [["Fixture Key": "Fixture Value"]],
                actual: [["Another Fixture Key": "Fixture Value"]]
        )
        XCTAssertFalse(result, "Expected dictionary to not match")
    }

    func testDictionaryFailingInvocationDifferentValues() {
        let result = matcher.match(
                expected: [["Fixture Key": "Fixture Value"]],
                actual: [["Fixture Key": "Another Fixture Value"]]
        )
        XCTAssertFalse(result, "Expected dictionary to not match")
    }

    // MARK: More Complicated Scenarios

    func testPassingInvocation() {
        let result = matcher.match(
                expected:["Fixture String", nil, 42, 1.0, ["Key": "Value"], ["Fixture Element"]],
                actual: ["Fixture String", nil, 42, 1.0, ["Key": "Value"], ["Fixture Element"]]
        )

        XCTAssertTrue(result, "Expected elements to match")
    }

    func testFailingInvocation() {
        let result = matcher.match(
                expected:["Fixture String", nil, 42, 1.0, ["Key": "Value"], ["Fixture Element"]],
                actual: ["Fixture String", nil, 42, 1.0, ["Another Key": "Value"], ["Fixture Another Element"]]
        )

        XCTAssertFalse(result, "Expected elements to match")
    }
}
