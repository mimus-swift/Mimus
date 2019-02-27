//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import XCTest

@testable import Mimus

class ComparatorTests: XCTestCase {

    var matcher: MimusComparator!

    override func setUp() {
        super.setUp()

        matcher = MimusComparator()
    }

    override func tearDown() {
        matcher = nil
    }

    // MARK: Strings

    func testStringPassingInvocation() {
        let result = matcher.match(expected: ["Fixture String"], actual: ["Fixture String"])
        XCTAssertTrue(result.matching, "Expected strings to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testStringFailingInvocation() {
        let result = matcher.match(expected: ["Fixture String"], actual: ["Fixture Another String"])
        XCTAssertFalse(result.matching, "Expected strings not to match")
    }

    func testStaticStringPassingInvocation() {
        let expected: StaticString = "Fixture String"
        let actual: StaticString = "Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result.matching, "Expected strings to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testStaticStringFailingInvocation() {
        let expected: StaticString = "Fixture String"
        let actual: StaticString = "Another Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result.matching, "Expected strings not to match")
    }

    func testStaticStringWithStringPassingInvocation() {
        let expected: StaticString = "Fixture String"
        let actual = "Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result.matching, "Expected strings to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testStaticStringWithStringFailingInvocation() {
        let expected: StaticString = "Fixture String"
        let actual = "Another Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result.matching, "Expected strings not to match")
    }

    // MARK: Basic Types

    func testIntPassingInvocation() {
        let result = matcher.match(expected: [42], actual: [42])
        XCTAssertTrue(result.matching, "Expected ints to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testIntFailingInvocation() {
        let result = matcher.match(expected: [42], actual: [43])
        XCTAssertFalse(result.matching, "Expected ints not to match")
    }

    func testUIntPassingInvocation() {
        let result = matcher.match(expected: [UInt(42)], actual: [UInt(42)])
        XCTAssertTrue(result.matching, "Expected ints to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testUIntFailingInvocation() {
        let result = matcher.match(expected: [UInt(42)], actual: [UInt(43)])
        XCTAssertFalse(result.matching, "Expected ints not to match")
    }

    func testDoublePassingInvocation() {
        let result = matcher.match(expected: [42.0], actual: [42.0])
        XCTAssertTrue(result.matching, "Expected doubles to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testDoubleFailingInvocation() {
        let result = matcher.match(expected: [42.0], actual: [43.0])
        XCTAssertFalse(result.matching, "Expected doubles not to match")
    }

    func testFloatPassingInvocation() {
        let result = matcher.match(expected: [Float(42.0)], actual: [Float(42.0)])
        XCTAssertTrue(result.matching, "Expected floats to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testFloatFailingInvocation() {
        let result = matcher.match(expected: [Float(42.0)], actual: [Float(43.0)])
        XCTAssertFalse(result.matching, "Expected floats not to match")
    }

    func testBoolPassingInvocation() {
        let result = matcher.match(expected: [true], actual: [true])
        XCTAssertTrue(result.matching, "Expected booleans to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testBoolFailingInvocation() {
        let result = matcher.match(expected: [true], actual: [false])
        XCTAssertFalse(result.matching, "Expected booleans not to match")
    }

    // MARK: Index Paths

    func testIndexPathPassingInvocation() {
        let result = matcher.match(
                expected: [IndexPath(arrayLiteral: 42, 43)],
                actual: [IndexPath(arrayLiteral: 42, 43)]
        )
        XCTAssertTrue(result.matching, "Expected index paths to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testIndexPathFailingInvocation() {
        let result = matcher.match(
                expected: [IndexPath(arrayLiteral: 42, 43)],
                actual: [IndexPath(arrayLiteral: 44, 43)]
        )
        XCTAssertFalse(result.matching, "Expected index paths not to match")
    }

    // MARK: Different Types

    func testIncorrectTypes() {
        let result = matcher.match(expected: [42.0], actual: ["Fixture String"])
        XCTAssertFalse(result.matching, "Expected incorrect not to match")
    }

    // MARK: Url

    func testUrlPassingInvocation() {
        let result = matcher.match(
                expected: [URL(string: "https://fixture.url.com/fixture/suffix")!],
                actual: [URL(string: "https://fixture.url.com/fixture/suffix")!]
        )
        XCTAssertTrue(result.matching, "Expected urls to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testUrlFailingInvocation() {
        let result = matcher.match(
                expected: [URL(string: "https://fixture.url.com/fixture/suffix")!],
                actual: [URL(string: "https://fixture.url.eu/fixture/suffix")!]
        )
        XCTAssertFalse(result.matching, "Expected urls not to match")
    }
    
    func testUrlCrossTypePassingInvocation() {
        let result = matcher.match(
            expected: [URL(string: "https://fixture.url.com/fixture/suffix")!, NSURL(string: "https://fixture.url.pl/fixture/suffix")!],
            actual: [NSURL(string: "https://fixture.url.com/fixture/suffix")!, URL(string: "https://fixture.url.pl/fixture/suffix")!]
        )
        XCTAssertTrue(result.matching, "Expected urls to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    // MARK: Working with optionals and nil

    func testNilPassingInvocation() {
        let result = matcher.match(expected: [nil], actual: [nil])
        XCTAssertTrue(result.matching, "Expected nils to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testNilFailingInvocation() {
        let result = matcher.match(expected: [nil], actual: [42])
        XCTAssertFalse(result.matching, "Expected elements not to match")
    }

    // MARK: Arrays

    func testArrayPassingInvocation() {
        let result = matcher.match(
                expected: [["Fixture Value 1", "Fixture Value 2"]],
                actual: [["Fixture Value 1", "Fixture Value 2"]]
        )
        XCTAssertTrue(result.matching, "Expected arrays to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testArrayFailingInvocation() {
        let result = matcher.match(
                expected: [["Fixture Value 1", "Fixture Value 2"]],
                actual: [["Fixture Value 1", "Another Fixture Value 2"]]
        )
        XCTAssertFalse(result.matching, "Expected arrays not to match")
    }

    func testIncompatibleSizesArrayFailingInvocation() {
        let result = matcher.match(
                expected: [["Fixture Value 1", "Fixture Value 2", "Fixture Value 3"]],
                actual: [["Fixture Value 1", "Fixture Value 2"]]
        )
        XCTAssertFalse(result.matching, "Expected arrays not to match")
    }

    func testNestedArraysPassingInvocation() {
        let result = matcher.match(
                expected: [["Fixture Value 1", "Fixture Value 2", ["Fixture Value 3"]]],
                actual: [["Fixture Value 1", "Fixture Value 2", ["Fixture Value 3"]]]
        )
        XCTAssertTrue(result.matching, "Expected arrays to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testNestedArraysFailingInvocation() {
        let result = matcher.match(
                expected: [["Fixture Value 1", "Fixture Value 2", ["Fixture Value 3"]]],
                actual: [["Fixture Value 1", "Fixture Value 2", ["Fixture Value 4"]]]
        )
        XCTAssertFalse(result.matching, "Expected arrays not to match")
    }

    func testArrayWithComparedWithDifferentType() {
        let result = matcher.match(
                expected: [["Fixture Value 1", "Fixture Value 2", ["Fixture Value 3"]]],
                actual: ["Not an array"]
        )
        XCTAssertFalse(result.matching, "Expected arrays not to match")
    }

    // MARK: Dictionaries

    func testDictionaryPassingInvocation() {
        let result = matcher.match(
                expected: [["Fixture Key": "Fixture Value"]],
                actual: [["Fixture Key": "Fixture Value"]]
        )
        XCTAssertTrue(result.matching, "Expected dictionary to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testDictionaryFailingInvocationDifferentKeys() {
        let result = matcher.match(
                expected: [["Fixture Key": "Fixture Value"]],
                actual: [["Another Fixture Key": "Fixture Value"]]
        )
        XCTAssertFalse(result.matching, "Expected dictionary not to match")
    }

    func testDictionaryFailingInvocationDifferentValues() {
        let result = matcher.match(
                expected: [["Fixture Key": "Fixture Value"]],
                actual: [["Fixture Key": "Another Fixture Value"]]
        )
        XCTAssertFalse(result.matching, "Expected dictionary not to match")
    }

    func testDictionaryWithDifferentAmountOfValues() {
        let result = matcher.match(
            expected: [["Fixture Key": "Fixture Value"]],
            actual: [["Fixture Key": "Fixture Value", "Second Fixture Key": "Fixture Value"]]
        )
        XCTAssertFalse(result.matching, "Expected dictionary not to match")
    }

    func testDictionaryComparedWithDifferentType() {
        let result = matcher.match(
            expected: [["Fixture Key": "Fixture Value"]],
            actual: ["Not a Dictionary"]
        )
        XCTAssertFalse(result.matching, "Expected dictionary not to match")
    }

    // MARK: More Complicated Scenarios

    func testPassingInvocation() {
        let result = matcher.match(
                expected: ["Fixture String", nil, 42, 1.0, ["Key": "Value"], ["Fixture Element", URL(string: "htp://fixture/url")!]],
                actual: ["Fixture String", nil, 42, 1.0, ["Key": "Value"], ["Fixture Element", URL(string: "htp://fixture/url")!]]
        )

        XCTAssertTrue(result.matching, "Expected elements to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testFailingInvocation() {
        let result = matcher.match(
                expected: ["Fixture String", nil, 42, 1.0, ["Key": "Value"], ["Fixture Element", URL(string: "htp://fixture/url")!]],
                actual: ["Fixture String", nil, 42, 1.0, ["Another Key": "Value"], ["Fixture Another Element"]]
        )

        XCTAssertFalse(result.matching, "Expected elements to not match")
    }

    // Mark: None Tests

    func testAnyInvocation() {
        let result = matcher.match(
            expected: .any,
            actual: ["Fixture String", nil, 42, 1.0, ["Key": "Value"], ["Fixture Element", URL(string: "htp://fixture/url")!]]
        )

        XCTAssertTrue(result.matching, "Expected elements to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testAnyNoArgumentsInvocation() {
        let result = matcher.match(
            expected: .any,
            actual: nil
        )

        XCTAssertTrue(result.matching, "Expected elements to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testNoneNoArgumentsInvocation() {
        let result = matcher.match(
            expected: .none,
            actual: nil
        )

        XCTAssertTrue(result.matching, "Expected elements to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testNoneInvocation() {
        let result = matcher.match(
            expected: .none,
            actual: ["Fixture String", nil, 42, 1.0, ["Key": "Value"], ["Fixture Element", URL(string: "htp://fixture/url")!]]
        )
        
        XCTAssertFalse(result.matching, "Expected elements to not match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }


    // MARK: Bugs

    func testNilValues() {
        let result = matcher.match(expected: ["Fixture Value", nil], actual: ["Fixture Another value", nil])

        XCTAssertFalse(result.matching, "Expected elements to not match")
    }
}
