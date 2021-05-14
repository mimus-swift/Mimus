//
//  Copyright © 2019 AirHelp. All rights reserved.
//

import XCTest
@testable import Mimus

class MismatchMessageBuilderTests: XCTestCase {

    var mismatchMessageBuilder: MismatchMessageBuilder!
    let numbersComparison1 = MimusComparator.ComparisonResult.MismatchedComparison(argumentIndex: 1, expected: 1, actual: 2)
    let numbersComparison2 = MimusComparator.ComparisonResult.MismatchedComparison(argumentIndex: 2, expected: 2, actual: 3)

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
        let result = MimusComparator.ComparisonResult(matching: false, mismatchedComparisons: [])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = "Unexpected behavior, no arguments comparison to present"
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }

    func testOneComparisonWithExpectedAndActualValues() {
        let result = MimusComparator.ComparisonResult(matching: false, mismatchedComparisons: [numbersComparison1])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = "Mismatch in argument #1 - expected <(1)>, but was <(2)>."
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }
    
    func testOneComparisonWithExpectedValueAsEqualMatcherAndActualValues() {
        let comparison = MimusComparator.ComparisonResult.MismatchedComparison(
            argumentIndex: 1,
            expected: mEqual(Int(1)),
            actual: 2
        )
        let result = MimusComparator.ComparisonResult(matching: false, mismatchedComparisons: [comparison])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = "Mismatch in argument #1 - expected <(EqualTo<Int> - <(1)>)>, but was <(2)>."
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }
    
    func testOneComparisonWithExpectedValueAsNotEqualMatcherAndActualValues() {
        let comparison = MimusComparator.ComparisonResult.MismatchedComparison(
            argumentIndex: 1,
            expected: mNot(mEqual(Int(1))),
            actual: 1
        )
        let result = MimusComparator.ComparisonResult(matching: false, mismatchedComparisons: [comparison])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = "Mismatch in argument #1 - expected <(NotMatcher - EqualTo<Int> - <(1)>)>, but was <(1)>."
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }

    func testOneComparisonWithExpectedNil() {
        let comparison = MimusComparator.ComparisonResult.MismatchedComparison(argumentIndex: 1, expected: nil, actual: 2)
        let result = MimusComparator.ComparisonResult(matching: false, mismatchedComparisons: [comparison])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = "Mismatch in argument #1 - expected <(nil)>, but was <(2)>."
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }

    func testOneComparisonWithActualNil() {
        let comparison = MimusComparator.ComparisonResult.MismatchedComparison(argumentIndex: 1, expected: 1, actual: nil)
        let result = MimusComparator.ComparisonResult(matching: false, mismatchedComparisons: [comparison])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = "Mismatch in argument #1 - expected <(1)>, but was <(nil)>."
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }

    func testMultipleComparisonsInOneResult() {
        let result = MimusComparator.ComparisonResult(matching: false, mismatchedComparisons: [numbersComparison1, numbersComparison2])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = """
                              Mismatch in argument #1 - expected <(1)>, but was <(2)>.
                              Mismatch in argument #2 - expected <(2)>, but was <(3)>.
                              """
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }

    func testOneComparisonInMultipleResults() {
        let result = MimusComparator.ComparisonResult(matching: false, mismatchedComparisons: [numbersComparison1, numbersComparison2])
        let message = mismatchMessageBuilder.message(for: [result, result, result])
        let expectedMessage = """
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
        let comparison = MimusComparator.ComparisonResult.MismatchedComparison(argumentIndex: 1,
            expected: CustomStringConvertibleObject(index: 1),
            actual: CustomStringConvertibleObject(index: 2))
        let result = MimusComparator.ComparisonResult(matching: false, mismatchedComparisons: [comparison])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = "Mismatch in argument #1 - expected <(fixture description 1)>, but was <(fixture description 2)>."
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }

    func testComparisonWithStructs() {
        let comparison = MimusComparator.ComparisonResult.MismatchedComparison(argumentIndex: 1,
            expected: DefaultObject(index: 1),
            actual: DefaultObject(index: 2))
        let result = MimusComparator.ComparisonResult(matching: false, mismatchedComparisons: [comparison])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = "Mismatch in argument #1 - expected <(DefaultObject(index: 1))>, but was <(DefaultObject(index: 2))>."
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }

    func testComparisonWithCustomMessageMatcher() {
        let comparison = MimusComparator.ComparisonResult.MismatchedComparison(argumentIndex: 1,
            expected: DescriptiveEqualTo(FixtureStructure(index: 1)),
            actual: FixtureStructure(index: 2))
        let result = MimusComparator.ComparisonResult(matching: false, mismatchedComparisons: [comparison])
        let message = mismatchMessageBuilder.message(for: [result])
        let expectedMessage = "Mismatch in argument #1 - custom expected <(FixtureStructure(index: 1))>, but was <(FixtureStructure(index: 2))>."
        XCTAssertEqual(message, expectedMessage, "Expected to receive correct mismatch details")
    }
}

// MARK: helpers

private struct CustomStringConvertibleObject: Matcher, CustomStringConvertible {

    let index: Int

    var description: String {
        return "fixture description \(index)"
    }

    func matches(argument: Any?) -> Bool { return true }
}

private struct DefaultObject: Matcher {

    let index: Int

    func matches(argument: Any?) -> Bool { return true }
}

private struct FixtureStructure: Equatable {
    let index: Int
}

public final class DescriptiveEqualTo<T: Equatable>: Matcher {

    private let object: T?

    public init(_ object: T?) {
        self.object = object
    }

    public func matches(argument: Any?) -> Bool {
        if let otherObject = argument as? T {
            return object == otherObject
        }
        return argument == nil && object == nil
    }

    public func mismatchMessage(for argument: Any?) -> String {
        "custom expected \(object.mimusDescription()), but was \(argument.mimusDescription())."
    }
}
