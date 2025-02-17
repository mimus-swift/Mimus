import Foundation
import XCTest

@testable import Mimus

class CapturePointerMatcherTests: XCTestCase {

    var comparator: MimusComparator!

    override func setUp() {
        super.setUp()

        comparator = MimusComparator()
    }

    override func tearDown() {
        comparator = nil
    }

    func testSimulateCompletion() {
        var completionCalled: Bool = false
        let completion: () -> Void = {
            completionCalled = true
        }

        let result = comparator.match(
            expected: [mSimulateCompletion(), mAny()],
            actual: [completion, 43]
        )

        XCTAssertTrue(result.matching, "Expected values to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
        XCTAssertTrue(completionCalled, "Expected completion to be called")
    }

    func testSimulateCompletionWithSingleArgument() {
        var capturedArgument: String?
        let completion: (String) -> Void = {
            capturedArgument = $0
        }

        let result = comparator.match(
            expected: [mSimulateCallback("Fixture"), mAny()],
            actual: [completion, 43]
        )

        XCTAssertTrue(result.matching, "Expected values to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
        XCTAssertEqual(capturedArgument, "Fixture", "Expected completion to be called")
    }

    func testSimulateCompletionWithSingleIncorrectArgument() {
        var capturedArgument: String?
        let completion: (String) -> Void = {
            capturedArgument = $0
        }

        let result = comparator.match(
            expected: [mSimulateCallback(42), mAny()],
            actual: [completion, 43]
        )

        XCTAssertFalse(result.matching, "Expected values to not match")
        XCTAssertEqual(result.mismatchedComparisons.count, 1, "Expected mismatched results")
        XCTAssertNil(capturedArgument, "Expected completion to not be called")
    }
}
