import XCTest

/// Enum defining all possible verification modes.
/// See https://github.com/AirHelp/Mimus/blob/master/Documentation/Basics.md for more details.
///
/// - never: fails the test if there is one or more matching invocation
/// - atLeast: fails the test if there is less invocations than passed in the enum value
/// - atMost: fails the test if there is more invocations than passed in the enum value
/// - times: fails the test if the number of invocations does not equal to the enum value
public enum VerificationMode {
    case never
    case atLeast(Int)
    case atMost(Int)
    case times(Int)
}

public enum Arguments: ExpressibleByArrayLiteral {
    case any
    case actual([Matcher?])
    case none

    public init(arrayLiteral elements: Matcher?...) {
        self = .actual(elements)
    }

    public typealias ArrayLiteralElement = Matcher?
}

/// Protocol used for verifying equality between objects. Mimus delivers support for base Swift types, check out
/// https://github.com/AirHelp/Mimus/blob/master/Documentation/Using%20Your%20Own%20Types.md if you want to use your own
/// types
public protocol Matcher {
    /// Function verifying whether this matcher matches passed in argument.
    ///
    /// - Parameter other: other value for comparison
    /// - Returns: true if values matchers this matcher, false if not
    func matches(argument: Any?) -> Bool

    /// Allows modifying error message being reported to Mimus. Will only be called if the arguments didn't match. Default implementation uses description of both
    /// argument and matcher values.
    ///
    /// - Parameter other: other value for comparison
    /// - Returns: Message passed to XCTest for verification failure.
    func mismatchMessage(for argument: Any?) -> String
}

/// Syntax sugar protocol for backwards compatibility with pre-1.2 version.  
public protocol MockEquatable: Matcher { }

/// Use this protocol to add mocking functionality for your mock objects. You will have to provide storage for recorded 
/// calls in your implementation.
public protocol Mock: AnyObject {
    var storage: Storage { get }
}

public extension Mock {
    /// Records given invocation.
    ///
    /// - Parameters:
    ///   - callIdentifier: call identifier for recorded invocation. You should use the same identifier when verifying call.
    ///   - arguments: Recorded arguments. You can pass nil if no arguments are needed. Supports nils in the array as well.
    func recordCall(withIdentifier callIdentifier: String, arguments: [Any?]? = nil) {
        let recordedCall = RecordedCall(identifier: callIdentifier, arguments: arguments)
        storage.record(call: recordedCall)
    }

    /// Verifies whether given call with given arguments was recorded. Will call XCTFail if no invocations matching
    /// given verification mode were recorded.
    ///
    /// - Parameters:
    ///   - callIdentifier: call identifier for recorded invocation. You should use the same one as when recording call.
    ///   - arguments: Expected arguments. You can pass `.none` if no arguments are needed. Supports nils in the array as well.
    ///   - mode: Verification mode. Defaults to .times(1)
    ///   - file: The file where your verification happens. Defaults to file where given call was made.
    ///   - line: The line where your verification happens. Defaults to line where given call was made.
    func verifyCall(withIdentifier callIdentifier: String, arguments: Arguments = .none, mode: VerificationMode = .times(1), file: StaticString = #file, line: UInt = #line) {
        let testLocation = TestLocation(file: file, line: line)
        TestLocation.internalTestLocation = testLocation
        let mockMatcher = MimusComparator()

        let callCandidates = storage.recordedCalls.filter {
            $0.identifier == callIdentifier
        }

        // Note we explicitly remove all calls of a given identified from the storage _before_ triggering verification
        // ... as verification might add new values to the storage which we want to keep around for additional verification
        // (e.g. when simulating callbacks).
        storage.remove(callsWithIdentifier: callIdentifier)

        let matchResults = callCandidates.map({ mockMatcher.match(expected: arguments, actual: $0.arguments) })

        let matchedResults = matchResults.filter({ $0.matching })
        let mismatchedResults = matchResults.filter({ !$0.matching })

        VerificationHandler.shared.verifyCall(
                callIdentifier: callIdentifier,
                matchedResults: matchedResults,
                mismatchedArgumentsResults: mismatchedResults,
                mode: mode,
                testLocation: testLocation
        )

        TestLocation.internalTestLocation = nil
    }

    func record(returnValue: Any?, forCallWithIdentifier identifier: String, arguments: [Any?]? = nil) {
        let recordedCall = RecordedCall(identifier: identifier, arguments: arguments)
        let givenCall = RecordedReturnEntry(returnValue: returnValue, recordedCall: recordedCall, thrownError: nil)
        storage.record(entry: givenCall)
    }

    func record(error: Error, forCallWithIdentifier identifier: String, arguments: [Any?]? = nil) {
        let recordedCall = RecordedCall(identifier: identifier, arguments: arguments)
        let givenCall = RecordedReturnEntry(returnValue: nil, recordedCall: recordedCall, thrownError: error)
        storage.record(entry: givenCall)
    }

    func recordedValue<T: Any>(forCallWithIdentifier identifier: String, arguments: Arguments = .none) -> T? {
        let entry = storage.recordedReturnEntry(matchingIdentifier: identifier, arguments: arguments)
        return entry?.returnValue as? T
    }

    func recordedError(forCallWithIdentifier identifier: String, arguments: Arguments = .none) -> Error? {
        let entry = storage.recordedReturnEntry(matchingIdentifier: identifier, arguments: arguments)
        return entry?.thrownError
    }
}
