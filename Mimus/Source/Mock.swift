import XCTest


/// Enum defining all possible verification modes. See https://github.com/AirHelp/Mimus/blob/master/Documentation/Basics.md for more details.
///
/// - never: fails the test if there is one or more matching invocation
/// - atLeast: fails the test if there is less invocations than passed in the enum value
/// - times: fails the test if the number of invocations does not equal to the enum value
public enum VerificationMode {
    case never
    case atLeast(Int)
    case times(Int)
}


/// Protocol used for veryfing equality between objects. Mimus delivers support for base Swift types, check out
/// https://github.com/AirHelp/Mimus/blob/master/Documentation/Using%20Your%20Own%20Types.md if you want to use your own types
public protocol MockEquatable {

    /// Function veryfing whether two MockEquatable objects are actually equal. 
    ///
    /// - Parameter other: other value for veryfing equality
    /// - Returns: true if values are equal, false if not
    func equalTo(other: MockEquatable?) -> Bool
}


/// Structure used to hold recorded invocations
public struct RecordedCall {

    let identifier: String

    let arguments: [MockEquatable?]?

}

/// Use this protocol to add mocking functionality for your mock objects. You will have to provide storage for recorded 
/// calls in your implementation.
public protocol Mock: class {

    var storage: [RecordedCall] { get set }

}

public extension Mock {

    
    /// Records given invocation.
    ///
    /// - Parameters:
    ///   - callIdentifier: call identifier for recorded invocation. You should use the same identifier when veryfing call.
    ///   - arguments: Recorded arguments. You can pass nil if no arguments are needed. Supports nils in the array as well.
    func recordCall(withIdentifier callIdentifier: String, arguments: [MockEquatable?]? = nil) {
        let record = RecordedCall(identifier: callIdentifier, arguments: arguments)
        storage.append(record)
    }

    
    /// Verifies whether given call with given arguments was recored. Will call XCTFail if no invocations matching given
    /// given verification mode were recorded.
    ///
    /// - Parameters:
    ///   - callIdentifier: call identifier for recored invocation. You should use the same one as when recording call.
    ///   - arguments: Expected arguments. You can pass nil if no arguments are needed. Supports nils in the array as well.
    ///   - mode: Verification mode. Defaults to .times(1)
    ///   - file: The file where your verification happens. Defaults to file where given call was made.
    ///   - line: The line where your verification happens. Defaults to line where given call was made.
    func verifyCall(withIdentifier callIdentifier: String, arguments: [MockEquatable?]? = nil, mode: VerificationMode = .times(1), file: StaticString = #file, line: UInt = #line) {
        let testLocation = TestLocation(file: file, line: line)
        TestLocation.internalTestLocation = testLocation
        let mockMatcher = Matcher()

        let callCandidates = storage.filter {
            $0.identifier == callIdentifier
        }
        var matchCount = 0
        var differentArgumentsMatchCount = 0

        for candidate in callCandidates {
            if mockMatcher.match(expected: arguments, actual: candidate.arguments) {
                matchCount += 1
            } else {
                differentArgumentsMatchCount += 1
            }
        }

        VerificationHandler.shared.verifyCall(callIdentifier: callIdentifier,
                matchCount: matchCount,
                differentArgumentsMatchCount: differentArgumentsMatchCount,
                mode: mode,
                testLocation: testLocation)

        TestLocation.internalTestLocation = nil
    }
}
