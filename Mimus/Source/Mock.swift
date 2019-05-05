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
    case actual([MockEquatable?])
    case none

    public init(arrayLiteral elements: MockEquatable?...) {
        self = .actual(elements)
    }

    public typealias ArrayLiteralElement = MockEquatable?
}

/// Protocol used for verifying equality between objects. Mimus delivers support for base Swift types, check out
/// https://github.com/AirHelp/Mimus/blob/master/Documentation/Using%20Your%20Own%20Types.md if you want to use your own types
public protocol MockEquatable {

    /// Function verifying whether two MockEquatable objects are actually equal.
    ///
    /// - Parameter other: other value for verifying equality
    /// - Returns: true if values are equal, false if not
    func equalTo(other: Any?) -> Bool
}

/// Structure used to hold recorded invocations
public struct RecordedCall {
    let identifier: String
    let arguments: [Any?]?
}

/// Use this protocol to add mocking functionality for your mock objects. You will have to provide storage for recorded 
/// calls in your implementation.
public protocol Mock: AnyObject {
    var storage: [RecordedCall] { get set }
}

public extension Mock {
    /// Records given invocation.
    ///
    /// - Parameters:
    ///   - callIdentifier: call identifier for recorded invocation. You should use the same identifier when verifying call.
    ///   - arguments: Recorded arguments. You can pass nil if no arguments are needed. Supports nils in the array as well.
    func recordCall(withIdentifier callIdentifier: String, arguments: [Any?]? = nil) {
        let record = RecordedCall(identifier: callIdentifier, arguments: arguments)
        storage.append(record)
    }

    /// Verifies whether given call with given arguments was recorded. Will call XCTFail if no invocations matching
    /// given verification mode were recorded.
    ///
    /// - Parameters:
    ///   - callIdentifier: call identifier for recorded invocation. You should use the same one as when recording call.
    ///   - arguments: Expected arguments. You can pass nil if no arguments are needed. Supports nils in the array as well.
    ///   - mode: Verification mode. Defaults to .times(1)
    ///   - file: The file where your verification happens. Defaults to file where given call was made.
    ///   - line: The line where your verification happens. Defaults to line where given call was made.
    func verifyCall(withIdentifier callIdentifier: String, arguments: Arguments = .none, mode: VerificationMode = .times(1), file: StaticString = #file, line: UInt = #line) {
        let testLocation = TestLocation(file: file, line: line)
        TestLocation.internalTestLocation = testLocation
        let mockMatcher = Matcher()

        let callCandidates = storage.filter {
            $0.identifier == callIdentifier
        }

        let matchResults = callCandidates.map({ mockMatcher.match(expected: arguments, actual: $0.arguments) })

        let matchedResults = matchResults.filter({ $0.matching })
        let mismatchedResults = matchResults.filter({ !$0.matching })

        VerificationHandler.shared.verifyCall(callIdentifier: callIdentifier,
            matchedResults: matchedResults,
            mismatchedArgumentsResults: mismatchedResults,
            mode: mode,
            testLocation: testLocation)

        TestLocation.internalTestLocation = nil
    }
}
