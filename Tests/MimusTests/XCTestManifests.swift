#if !canImport(ObjectiveC)
import XCTest

extension FoundationMatcherTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__FoundationMatcherTests = [
        ("testAnyInvocation", testAnyInvocation),
        ("testAnyNoArgumentsInvocation", testAnyNoArgumentsInvocation),
        ("testArrayFailingInvocation", testArrayFailingInvocation),
        ("testArrayPassingInvocation", testArrayPassingInvocation),
        ("testArrayWithComparedWithDifferentType", testArrayWithComparedWithDifferentType),
        ("testBoolFailingInvocation", testBoolFailingInvocation),
        ("testBoolPassingInvocation", testBoolPassingInvocation),
        ("testDictionaryComparedWithDifferentType", testDictionaryComparedWithDifferentType),
        ("testDictionaryFailingInvocationDifferentKeys", testDictionaryFailingInvocationDifferentKeys),
        ("testDictionaryFailingInvocationDifferentValues", testDictionaryFailingInvocationDifferentValues),
        ("testDictionaryPassingInvocation", testDictionaryPassingInvocation),
        ("testDictionaryWithDifferentAmountOfValues", testDictionaryWithDifferentAmountOfValues),
        ("testDoubleFailingInvocation", testDoubleFailingInvocation),
        ("testDoublePassingInvocation", testDoublePassingInvocation),
        ("testFailingInvocation", testFailingInvocation),
        ("testFloatFailingInvocation", testFloatFailingInvocation),
        ("testFloatPassingInvocation", testFloatPassingInvocation),
        ("testIncompatibleSizesArrayFailingInvocation", testIncompatibleSizesArrayFailingInvocation),
        ("testIncorrectTypes", testIncorrectTypes),
        ("testIndexPathFailingInvocation", testIndexPathFailingInvocation),
        ("testIndexPathPassingInvocation", testIndexPathPassingInvocation),
        ("testIntFailingInvocation", testIntFailingInvocation),
        ("testIntPassingInvocation", testIntPassingInvocation),
        ("testNestedArraysFailingInvocation", testNestedArraysFailingInvocation),
        ("testNestedArraysPassingInvocation", testNestedArraysPassingInvocation),
        ("testNilFailingInvocation", testNilFailingInvocation),
        ("testNilPassingInvocation", testNilPassingInvocation),
        ("testNilValues", testNilValues),
        ("testNoneInvocation", testNoneInvocation),
        ("testNoneNoArgumentsInvocation", testNoneNoArgumentsInvocation),
        ("testPassingInvocation", testPassingInvocation),
        ("testStaticStringFailingInvocation", testStaticStringFailingInvocation),
        ("testStaticStringPassingInvocation", testStaticStringPassingInvocation),
        ("testStaticStringWithStringFailingInvocation", testStaticStringWithStringFailingInvocation),
        ("testStaticStringWithStringPassingInvocation", testStaticStringWithStringPassingInvocation),
        ("testStringFailingInvocation", testStringFailingInvocation),
        ("testStringPassingInvocation", testStringPassingInvocation),
        ("testUIntFailingInvocation", testUIntFailingInvocation),
        ("testUIntPassingInvocation", testUIntPassingInvocation),
        ("testUrlCrossTypePassingInvocation", testUrlCrossTypePassingInvocation),
        ("testUrlFailingInvocation", testUrlFailingInvocation),
        ("testUrlPassingInvocation", testUrlPassingInvocation),
    ]
}

extension MatcherExtensionsTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__MatcherExtensionsTests = [
        ("testFailingMatcher", testFailingMatcher),
        ("testPassingMatcher", testPassingMatcher),
    ]
}

extension MatcherTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__MatcherTests = [
        ("testDataTypeFailingInvocation", testDataTypeFailingInvocation),
        ("testDataTypePassingInvocation", testDataTypePassingInvocation),
        ("testFailingInvocation", testFailingInvocation),
        ("testIncompatibleSizesNSArrayFailingInvocation", testIncompatibleSizesNSArrayFailingInvocation),
        ("testIncompatibleSizesNSDictionaryFailingInvocation", testIncompatibleSizesNSDictionaryFailingInvocation),
        ("testNestedNSArrayFailingInvocation", testNestedNSArrayFailingInvocation),
        ("testNestedNSArrayPassingInvocation", testNestedNSArrayPassingInvocation),
        ("testNestedNSDictionaryFailingInvocation", testNestedNSDictionaryFailingInvocation),
        ("testNestedNSDictionaryPassingInvocation", testNestedNSDictionaryPassingInvocation),
        ("testNSArrayFailingInvocation", testNSArrayFailingInvocation),
        ("testNSArrayPassingInvocation", testNSArrayPassingInvocation),
        ("testNSDictionaryFailingInvocation", testNSDictionaryFailingInvocation),
        ("testNSDictionaryPassingInvocation", testNSDictionaryPassingInvocation),
        ("testNSErrorFailingInvocation", testNSErrorFailingInvocation),
        ("testNSErrorPassingInvocation", testNSErrorPassingInvocation),
        ("testNSNumberFailingInvocation", testNSNumberFailingInvocation),
        ("testNSNumberPassingInvocation", testNSNumberPassingInvocation),
        ("testNSStringPassingInvocation", testNSStringPassingInvocation),
        ("testNSURLFailingInvocation", testNSURLFailingInvocation),
        ("testNSURLPassingInvocation", testNSURLPassingInvocation),
        ("testPassingInvocation", testPassingInvocation),
        ("testStaticStringFailingInvocation", testStaticStringFailingInvocation),
        ("testStaticStringWithNSStringFailingInvocation", testStaticStringWithNSStringFailingInvocation),
        ("testStaticStringWithNSStringPassingInvocation", testStaticStringWithNSStringPassingInvocation),
        ("testStringWithNSStringFailingInvocation", testStringWithNSStringFailingInvocation),
        ("testStringWithNSStringPassingInvocation", testStringWithNSStringPassingInvocation),
        ("testURLRequestFailingInvocation", testURLRequestFailingInvocation),
        ("testURLRequestPassingInvocation", testURLRequestPassingInvocation),
    ]
}

extension MismatchMessageBuilderTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__MismatchMessageBuilderTests = [
        ("testComparisonWithObjectsImplementingCustomStringConvertible", testComparisonWithObjectsImplementingCustomStringConvertible),
        ("testComparisonWithStructs", testComparisonWithStructs),
        ("testMultipleComparisonsInOneResult", testMultipleComparisonsInOneResult),
        ("testNoMatchResultsProvided", testNoMatchResultsProvided),
        ("testOneComparisonInMultipleResults", testOneComparisonInMultipleResults),
        ("testOneComparisonWithActualNil", testOneComparisonWithActualNil),
        ("testOneComparisonWithExpectedAndActualValues", testOneComparisonWithExpectedAndActualValues),
        ("testOneComparisonWithExpectedNil", testOneComparisonWithExpectedNil),
        ("testResultWithoutComparisons", testResultWithoutComparisons),
    ]
}

extension MockTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__MockTests = [
        ("testArrayEqual", testArrayEqual),
        ("testBaseVerificationMode", testBaseVerificationMode),
        ("testCaptureArgument", testCaptureArgument),
        ("testClosureFailure", testClosureFailure),
        ("testClosureFailureIncorrectTypeCast", testClosureFailureIncorrectTypeCast),
        ("testClosureShorthandSuccess", testClosureShorthandSuccess),
        ("testClosureSuccess", testClosureSuccess),
        ("testClosureSuccessWithNil", testClosureSuccessWithNil),
        ("testCorrectFileLocation", testCorrectFileLocation),
        ("testCorrectNumberOfMatches", testCorrectNumberOfMatches),
        ("testCorrectNumberOfMatchesWithArguments", testCorrectNumberOfMatchesWithArguments),
        ("testCorrectNumberOfMismatchedArguments", testCorrectNumberOfMismatchedArguments),
        ("testCustomVerificationMode", testCustomVerificationMode),
        ("testEqual", testEqual),
        ("testEqualFailure", testEqualFailure),
        ("testEqualFailureDifferentObjects", testEqualFailureDifferentObjects),
        ("testEqualNilObjectFailure", testEqualNilObjectFailure),
        ("testEqualNilObjectInMatcherFailure", testEqualNilObjectInMatcherFailure),
        ("testEqualNilObjects", testEqualNilObjects),
        ("testIdentical", testIdentical),
        ("testIdenticalFailure", testIdenticalFailure),
        ("testIdenticalFailureDifferentObject", testIdenticalFailureDifferentObject),
        ("testIdenticalNilObjectFailure", testIdenticalNilObjectFailure),
        ("testIdenticalNilObjectInMatcherFailure", testIdenticalNilObjectInMatcherFailure),
        ("testIdenticalNilObjects", testIdenticalNilObjects),
        ("testInstanceOf", testInstanceOf),
        ("testInstanceOfFailure", testInstanceOfFailure),
        ("testInstanceOfShorthand", testInstanceOfShorthand),
        ("testNoRecorderInvocations", testNoRecorderInvocations),
        ("testNotFailure", testNotFailure),
        ("testNotSuccess", testNotSuccess),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(FoundationMatcherTests.__allTests__FoundationMatcherTests),
        testCase(MatcherExtensionsTests.__allTests__MatcherExtensionsTests),
        testCase(MatcherTests.__allTests__MatcherTests),
        testCase(MismatchMessageBuilderTests.__allTests__MismatchMessageBuilderTests),
        testCase(MockTests.__allTests__MockTests),
    ]
}
#endif