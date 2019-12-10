import XCTest

import MimusExamples
import MimusTests

var tests = [XCTestCaseEntry]()
tests += MimusExamples.__allTests()
tests += MimusTests.__allTests()

XCTMain(tests)
