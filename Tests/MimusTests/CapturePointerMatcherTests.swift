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

    func testCapturePointer() {
        var capturedValue: Int?

        let result = comparator.match(expected: [mCaptureInto(pointer: &capturedValue), mAny()], actual: [42, 43])

        XCTAssertTrue(result.matching, "Expected strings to match")
        XCTAssertEqual(result.mismatchedComparisons.count, 0, "Expected no mismatched results")
        XCTAssertEqual(capturedValue, 42, "Expected captured value to hold the right int")
    }
}
