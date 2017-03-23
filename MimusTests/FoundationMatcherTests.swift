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
        XCTAssertFalse(result, "Expected strings not to match")
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
        XCTAssertFalse(result, "Expected strings not to match")
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
        XCTAssertFalse(result, "Expected strings not to match")
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
        XCTAssertFalse(result, "Expected NSNumbers not to match")
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
        XCTAssertFalse(result, "Expected NSErrors not to match")
    }

    // MARK: NSArray

    func testNSArrayPassingInvocation() {
        let expected = NSArray(objects: NSString(string: "Fixture String"), NSNumber(floatLiteral: 0.5))
        let actual = NSArray(objects: NSString(string: "Fixture String"), NSNumber(floatLiteral: 0.5))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result, "Expected arrays to match")
    }

    func testNSArrayFailingInvocation() {
        let expected = NSArray(objects: NSNumber(floatLiteral: 0.5), NSString(string: "Fixture String"))
        let actual = NSArray(objects: NSString(string: "Fixture String"), NSNumber(floatLiteral: 0.5))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result, "Expected arrays not to match")
    }

    func testIncompatibleSizesNSArrayFailingInvocation() {
        let expected = NSArray(objects: NSNumber(floatLiteral: 0.5))
        let actual = NSArray(objects: NSString(string: "Fixture String"), NSNumber(floatLiteral: 0.5))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result, "Expected arrays not to match")
    }

    func testNestedNSArrayPassingInvocation() {
        let nestedExpectedArray = NSArray(object: NSNumber(floatLiteral: 0.5))
        let nestedActualArray = NSArray(object: NSNumber(floatLiteral: 0.5))
        let expected = NSArray(objects: NSNumber(floatLiteral: 0.5), nestedExpectedArray)
        let actual = NSArray(objects: NSNumber(floatLiteral: 0.5), nestedActualArray)

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result, "Expected arrays to match")
    }

    func testNestedNSArrayFailingInvocation() {
        let nestedExpectedArray = NSArray(objects: NSNumber(floatLiteral: 0.5), NSArray(objects: NSNumber(floatLiteral: 0.5)))
        let nestedActualArray = NSArray(object: NSNumber(floatLiteral: 0.5))
        let expected = NSArray(objects: NSNumber(floatLiteral: 0.5), nestedExpectedArray)
        let actual = NSArray(objects: NSNumber(floatLiteral: 0.5), nestedActualArray)

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result, "Expected arrays not to match")
    }

    // MARK: NSDictionary

    func testNSDictionaryPassingInvocation() {
        let expected = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let actual = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result, "Expected dictionaries to match")
    }

    func testNSDictionaryFailingInvocation() {
        let expected = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let actual = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 2"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 1"), NSNumber(floatLiteral: 0.5)))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result, "Expected dictionaries not to match")
    }

    func testIncompatibleSizesNSDictionaryFailingInvocation() {
        let expected = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")))
        let actual = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 2"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 1"), NSNumber(floatLiteral: 0.5)))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result, "Expected dictionaries not to match")
    }

    func testNestedNSDictionaryPassingInvocation() {
        let nestedExpectedDictionary = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let nestedActualDictionary = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let expected = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), nestedExpectedDictionary))
        let actual = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), nestedActualDictionary))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result, "Expected dictionaries to match")
    }

    func testNestedNSDictionaryFailingInvocation() {
        let nestedExpectedDictionary = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let nestedActualDictionary = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let expected = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), nestedExpectedDictionary))
        let actual = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), nestedActualDictionary), (NSString(string: "Fixture Key 2"), nestedExpectedDictionary))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result, "Expected dictionaries not to match")
    }

    // MARK: More Complicated Scenarios

    func testPassingInvocation() {
        let nestedDictionary = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNull()))
        let nestedArray = NSArray(object: NSNumber(floatLiteral: 0.5))
        let expected = NSArray(objects: NSString(string: "Fixture String"), NSNull(), NSNumber(integerLiteral: 42), NSNumber(floatLiteral: 1.0), nestedArray, nestedDictionary)
        let actual = NSArray(objects: NSString(string: "Fixture String"), NSNull(), NSNumber(integerLiteral: 42), NSNumber(floatLiteral: 1.0), nestedArray, nestedDictionary)
        let result = matcher.match(
                expected: [expected],
                actual: [actual]
        )

        XCTAssertTrue(result, "Expected elements to match")
    }

    func testFailingInvocation() {
        let nestedDictionary = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let nestedArray = NSArray(object: NSNumber(floatLiteral: 0.5))
        let expected = NSArray(objects: NSString(string: "Fixture String"), NSNull(), NSNumber(integerLiteral: 42), NSNumber(floatLiteral: 1.0), nestedArray, nestedDictionary)
        let actual = NSArray(objects: NSString(string: "Fixture String"), NSNull(), nestedArray, nestedDictionary)
        let result = matcher.match(
                expected: [expected],
                actual: [actual]
        )

        XCTAssertFalse(result, "Expected elements to match")
    }
}
