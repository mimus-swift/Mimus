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
        XCTAssertTrue(result.matching, "Expected strings to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testStaticStringFailingInvocation() {
        let expected: NSString = "Fixture String"
        let actual: NSString = "Another Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result.matching, "Expected strings not to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 1, "Expected one mismatched results")

        let mismatchedResult = result.mismatchedComparisons[0]
        mismatchedResult.assert(expected: expected, actual: actual)
    }

    func testStaticStringWithNSStringPassingInvocation() {
        let expected: StaticString = "Fixture String"
        let actual: NSString = "Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result.matching, "Expected strings to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testStaticStringWithNSStringFailingInvocation() {
        let expected: StaticString = "Fixture String"
        let actual: NSString = "Another Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result.matching, "Expected strings not to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 1, "Expected one mismatched results")
    }

    func testStringWithNSStringPassingInvocation() {
        let expected = "Fixture String"
        let actual: NSString = "Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result.matching, "Expected strings to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testStringWithNSStringFailingInvocation() {
        let expected = "Fixture String"
        let actual: NSString = "Another Fixture String"

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result.matching, "Expected strings not to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 1, "Expected one mismatched results")

        let mismatchedResult = result.mismatchedComparisons[0]
        mismatchedResult.assert(expected: expected, actual: actual)
    }

    // MARK: NSNumber

    func testNSNumberPassingInvocation() {
        let expected: NSNumber = 42
        let actual: NSNumber = 42

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result.matching, "Expected NSNumbers to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testNSNumberFailingInvocation() {
        let expected: NSNumber = 42
        let actual: NSNumber = 43

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result.matching, "Expected NSNumbers not to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 1, "Expected one mismatched results")

        let mismatchedResult = result.mismatchedComparisons[0]
        mismatchedResult.assert(expected: expected, actual: actual)
    }

    // MARK: NSError

    func testNSErrorPassingInvocation() {
        let expected = NSError(domain: "Fixture Domain", code: 42)
        let actual = NSError(domain: "Fixture Domain", code: 42)

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result.matching, "Expected NSErrors to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testNSErrorFailingInvocation() {
        let expected = NSError(domain: "Fixture Domain", code: 42)
        let actual = NSError(domain: "Fixture Domain", code: 43)

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result.matching, "Expected NSErrors not to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 1, "Expected one mismatched results")

        let mismatchedResult = result.mismatchedComparisons[0]
        mismatchedResult.assert(expected: expected, actual: actual)
    }

    // MARK: NSURL

    func testNSURLPassingInvocation() {
        let expected = NSURL(string: "https://fixture.url.com/fixture/suffix")!
        let actual = NSURL(string: "https://fixture.url.com/fixture/suffix")!

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result.matching, "Expected NSErrors to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testNSURLFailingInvocation() {
        let expected = NSURL(string: "https://fixture.url.com/fixture/suffix")!
        let actual = NSURL(string: "https://fixture.url.eu/fixture/suffix")!

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result.matching, "Expected NSErrors not to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 1, "Expected one mismatched results")

        let mismatchedResult = result.mismatchedComparisons[0]
        mismatchedResult.assert(expected: expected, actual: actual)
    }

    // MARK: NSArray

    func testNSArrayPassingInvocation() {
        let expected = NSArray(objects: NSString(string: "Fixture String"), NSNumber(floatLiteral: 0.5))
        let actual = NSArray(objects: NSString(string: "Fixture String"), NSNumber(floatLiteral: 0.5))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result.matching, "Expected arrays to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testNSArrayFailingInvocation() {
        let expected = NSArray(objects: NSNumber(floatLiteral: 0.5), NSString(string: "Fixture String"))
        let actual = NSArray(objects: NSString(string: "Fixture String"), NSNumber(floatLiteral: 0.5))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result.matching, "Expected arrays not to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 1, "Expected one mismatched results")
    }

    func testIncompatibleSizesNSArrayFailingInvocation() {
        let expected = NSArray(objects: NSNumber(floatLiteral: 0.5))
        let actual = NSArray(objects: NSString(string: "Fixture String"), NSNumber(floatLiteral: 0.5))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result.matching, "Expected arrays not to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 1, "Expected one mismatched results")
    }

    func testNestedNSArrayPassingInvocation() {
        let nestedExpectedArray = NSArray(object: NSNumber(floatLiteral: 0.5))
        let nestedActualArray = NSArray(object: NSNumber(floatLiteral: 0.5))
        let expected = NSArray(objects: NSNumber(floatLiteral: 0.5), nestedExpectedArray)
        let actual = NSArray(objects: NSNumber(floatLiteral: 0.5), nestedActualArray)

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result.matching, "Expected arrays to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testNestedNSArrayFailingInvocation() {
        let nestedExpectedArray = NSArray(objects: NSNumber(floatLiteral: 0.5), NSArray(objects: NSNumber(floatLiteral: 0.5)))
        let nestedActualArray = NSArray(object: NSNumber(floatLiteral: 0.5))
        let expected = NSArray(objects: NSNumber(floatLiteral: 0.5), nestedExpectedArray)
        let actual = NSArray(objects: NSNumber(floatLiteral: 0.5), nestedActualArray)

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result.matching, "Expected arrays not to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 1, "Expected one mismatched results")
    }

    // MARK: NSDictionary

    func testNSDictionaryPassingInvocation() {
        let expected = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let actual = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result.matching, "Expected dictionaries to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testNSDictionaryFailingInvocation() {
        let expected = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let actual = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 2"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 1"), NSNumber(floatLiteral: 0.5)))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result.matching, "Expected dictionaries not to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 1, "Expected one mismatched results")
    }

    func testIncompatibleSizesNSDictionaryFailingInvocation() {
        let expected = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")))
        let actual = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 2"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 1"), NSNumber(floatLiteral: 0.5)))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertFalse(result.matching, "Expected dictionaries not to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 1, "Expected one mismatched results")
    }

    func testNestedNSDictionaryPassingInvocation() {
        let nestedExpectedDictionary = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let nestedActualDictionary = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let expected = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), nestedExpectedDictionary))
        let actual = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), nestedActualDictionary))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result.matching, "Expected dictionaries to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testNestedNSDictionaryFailingInvocation() {
        let nestedExpectedDictionary = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let nestedActualDictionary = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let expected = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), nestedExpectedDictionary))
        let actual = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), nestedActualDictionary), (NSString(string: "Fixture Key 2"), nestedExpectedDictionary))

        let result = matcher.match(expected: [expected], actual: [actual])
        XCTAssertTrue(result.matching, "Expected dictionaries to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    // MARK: More Complicated Scenarios

    func testPassingInvocation() {
        let nestedDictionary = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNull()))
        let nestedArray = NSArray(objects: NSNumber(floatLiteral: 0.5), NSURL(string: "https://fixture.url.com/fixture/suffix")!)
        let expected = NSArray(objects: NSString(string: "Fixture String"), NSNull(), NSNumber(integerLiteral: 42), NSNumber(floatLiteral: 1.0), nestedArray, nestedDictionary)
        let actual = NSArray(objects: NSString(string: "Fixture String"), NSNull(), NSNumber(integerLiteral: 42), NSNumber(floatLiteral: 1.0), nestedArray, nestedDictionary)
        let result = matcher.match(
            expected: [expected],
            actual: [actual]
        )

        XCTAssertTrue(result.matching, "Expected elements to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
    }

    func testFailingInvocation() {
        let nestedDictionary = NSDictionary(dictionaryLiteral: (NSString(string: "Fixture Key 1"), NSString(string: "Fixture Value")), (NSString(string: "Fixture Key 2"), NSNumber(floatLiteral: 0.5)))
        let nestedArray = NSArray(objects: NSNumber(floatLiteral: 0.5), NSURL(string: "https://fixture.url.eu/fixture/suffix")!)
        let expected = NSArray(objects: NSString(string: "Fixture String"), NSNull(), NSNumber(integerLiteral: 42), NSNumber(floatLiteral: 1.0), nestedArray, nestedDictionary)
        let actual = NSArray(objects: NSString(string: "Fixture String"), NSNull(), nestedArray, nestedDictionary)
        let result = matcher.match(
            expected: [expected],
            actual: [actual]
        )

        XCTAssertFalse(result.matching, "Expected elements to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 1, "Expected one mismatched results")
    }
}
