//
//  Copyright © 2019 AirHelp. All rights reserved.
//

import XCTest
@testable import Mimus

class MismatchMessageBuilderTests: XCTestCase {
    
    var mismatchMessageBuilder: MismatchMessageBuilder!
    let numbersComparison1 = MatchResult.MismatchedComparison(argumentIndex: 1, expected: 1, actual: 2)
    let numbersComparison2 = MatchResult.MismatchedComparison(argumentIndex: 2, expected: 2, actual: 3)
    
    override func setUp() {
        super.setUp()
        mismatchMessageBuilder = MismatchMessageBuilder()
    }
    
    override func tearDown() {
        super.tearDown()
        mismatchMessageBuilder = MismatchMessageBuilder()
    }
    
    func testNoMatchResultsProvided() {
        let message = mismatchMessageBuilder.message(for: [])
        XCTAssertEqual(message, "", "Expected to receive correct mismatch details")
    }
    
    func testResultWithoutComparisons() {
        let result = MatchResult(matching: false, mismatchedComparisons: [])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = """
        Found 1 call(s) with expected identifier, but not matching arguments:
        Mismatched call #1:
        Unexpected behavior, no arguments comparison to present
        """
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }
    
    func testOneComparisonWithExpectedAndActualValues() {
        let result = MatchResult(matching: false, mismatchedComparisons: [numbersComparison1])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = """
        Found 1 call(s) with expected identifier, but not matching arguments:
        Mismatched call #1:
        Mismatch in argument #1 - expected <(1)>, but was <(2)>.
        """
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }
    
    func testOneComparisonWithExpectedNil() {
        let comparison = MatchResult.MismatchedComparison(argumentIndex: 1, expected: nil, actual: 2)
        let result = MatchResult(matching: false, mismatchedComparisons: [comparison])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = """
        Found 1 call(s) with expected identifier, but not matching arguments:
        Mismatched call #1:
        Mismatch in argument #1 - expected <(nil)>, but was <(2)>.
        """
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }
    
    func testOneComparisonWithActualNil() {
        let comparison = MatchResult.MismatchedComparison(argumentIndex: 1, expected: 1, actual: nil)
        let result = MatchResult(matching: false, mismatchedComparisons: [comparison])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = """
        Found 1 call(s) with expected identifier, but not matching arguments:
        Mismatched call #1:
        Mismatch in argument #1 - expected <(1)>, but was <(nil)>.
        """
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }
    
    func testMultipleComparisonsInOneResult() {
        let result = MatchResult(matching: false, mismatchedComparisons: [numbersComparison1, numbersComparison2])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = """
        Found 1 call(s) with expected identifier, but not matching arguments:
        Mismatched call #1:
        Mismatch in argument #1 - expected <(1)>, but was <(2)>.
        Mismatch in argument #2 - expected <(2)>, but was <(3)>.
        """
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }
    
    func testOneComparisonInMultipleResults() {
        let result = MatchResult(matching: false, mismatchedComparisons: [numbersComparison1, numbersComparison2])
        let message = mismatchMessageBuilder.message(for: [result, result, result])
        let expectedMessage = """
        Found 3 call(s) with expected identifier, but not matching arguments:
        Mismatched call #1:
        Mismatch in argument #1 - expected <(1)>, but was <(2)>.
        Mismatch in argument #2 - expected <(2)>, but was <(3)>.
        Mismatched call #2:
        Mismatch in argument #1 - expected <(1)>, but was <(2)>.
        Mismatch in argument #2 - expected <(2)>, but was <(3)>.
        Mismatched call #3:
        Mismatch in argument #1 - expected <(1)>, but was <(2)>.
        Mismatch in argument #2 - expected <(2)>, but was <(3)>.
        """
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }
    
    func testComparisonWithObjectsImplementingCustomStringConvertible() {
        let comparison = MatchResult.MismatchedComparison(argumentIndex: 1,
                                                          expected: CustomStringConvertibleObject(index: 1),
                                                          actual: CustomStringConvertibleObject(index: 2))
        let result = MatchResult(matching: false, mismatchedComparisons: [comparison])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = """
        Found 1 call(s) with expected identifier, but not matching arguments:
        Mismatched call #1:
        Mismatch in argument #1 - expected <(fixture description 1)>, but was <(fixture description 2)>.
        """
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }
    
    func testComparisonWithStructs() {
        let comparison = MatchResult.MismatchedComparison(argumentIndex: 1,
                                                          expected: DefaultObject(index: 1),
                                                          actual: DefaultObject(index: 2))
        let result = MatchResult(matching: false, mismatchedComparisons: [comparison])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = """
        Found 1 call(s) with expected identifier, but not matching arguments:
        Mismatched call #1:
        Mismatch in argument #1 - expected <(DefaultObject(index: 1))>, but was <(DefaultObject(index: 2))>.
        """
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }
}

// MARK: helpers

private struct CustomStringConvertibleObject: MockEquatable, CustomStringConvertible {
    
    let index: Int
    
    var description: String {
        return "fixture description \(index)"
    }
    
    func equalTo(other: Any?) -> Bool { return true }
}

private struct DefaultObject: MockEquatable {
    
    let index: Int
    
    func equalTo(other: Any?) -> Bool { return true }
}
