//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import XCTest

internal class VerificationHandler {
    
    private let mismatchMessageBuilder = MismatchMessageBuilder()
    
    static var shared: VerificationHandler = VerificationHandler()

    func verifyCall(callIdentifier: String, matchedResults: [MimusComparator.ComparisonResult], mismatchedArgumentsResults: [MimusComparator.ComparisonResult], mode: VerificationMode, testLocation: TestLocation) {
        switch mode {
        case .never:
            assertNever(callIdentifier: callIdentifier,
                    matchCount: matchedResults.count,
                    differentArgumentsMatchCount: mismatchedArgumentsResults.count,
                    testLocation: testLocation)
        case .atLeast(let count):
            assertAtLeast(callIdentifier: callIdentifier,
                    times: count,
                    matchCount: matchedResults.count,
                    differentArgumentsMatch: mismatchedArgumentsResults,
                    testLocation: testLocation)
        case .atMost(let count):
            assertAtMost(callIdentifier: callIdentifier,
                    times: count,
                    matchCount: matchedResults.count,
                    differentArgumentsMatchCount: mismatchedArgumentsResults.count,
                    testLocation: testLocation)
        case .times(let count):
            assert(callIdentifier: callIdentifier,
                    times: count,
                    matchCount: matchedResults.count,
                    differentArgumentsMatch: mismatchedArgumentsResults,
                    testLocation: testLocation)
        }
    }

    // MARK: Actual assertions

    private func assertNever(callIdentifier: String, matchCount: Int, differentArgumentsMatchCount: Int, testLocation: TestLocation) {
        guard matchCount > 0 else {
            return
        }

        recordIssue(
            "Expected to not receive call with identifier \(callIdentifier)",
            filePath: testLocation.file,
            fileID: testLocation.fileId,
            line: testLocation.line,
            column: testLocation.column
        )
    }

    private func assertAtMost(callIdentifier: String, times: Int, matchCount: Int, differentArgumentsMatchCount: Int, testLocation: TestLocation) {
        guard matchCount > times else {
            return
        }

        var message = "No call with identifier \(callIdentifier) was captured"
        if matchCount > 0 {
            message = "Call with identifier \(callIdentifier) was recorded \(matchCount) times, but expected at most \(times)"
        }

        recordIssue(
            message,
            filePath: testLocation.file,
            fileID: testLocation.fileId,
            line: testLocation.line,
            column: testLocation.column
        )
    }

    private func assertAtLeast(callIdentifier: String, times: Int, matchCount: Int, differentArgumentsMatch: [MimusComparator.ComparisonResult], testLocation: TestLocation) {
        guard matchCount < times else {
            return
        }

        let differentArgumentsMatchCount = differentArgumentsMatch.count
        var message = "No call with identifier \(callIdentifier) was captured"
        if matchCount > 0 {
            let mismatchedResultsMessage = mismatchMessageBuilder.message(for: differentArgumentsMatch)
            message = """
                      Call with identifier \(callIdentifier) was recorded \(matchCount) times, but expected at least \(times). 
                      \(differentArgumentsMatchCount) additional call(s) matched identifier, but not arguments:\n\n\(mismatchedResultsMessage)
                      """
        } else if differentArgumentsMatchCount > 0 {
            let mismatchedResultsMessage = mismatchMessageBuilder.message(for: differentArgumentsMatch)
            message = """
                      Call with identifier \(callIdentifier) was recorded \(differentArgumentsMatchCount) times, 
                      but arguments didn't match.\n\(mismatchedResultsMessage)
                      """
        }

        recordIssue(
            message,
            filePath: testLocation.file,
            fileID: testLocation.fileId,
            line: testLocation.line,
            column: testLocation.column
        )
    }

    private func assert(callIdentifier: String, times: Int, matchCount: Int, differentArgumentsMatch: [MimusComparator.ComparisonResult], testLocation: TestLocation) {
        guard matchCount != times else {
            return
        }
        let differentArgumentsMatchCount = differentArgumentsMatch.count
        var message = "No call with identifier \(callIdentifier) was captured"
        if matchCount > 0 {
            let mismatchedResultsMessage = mismatchMessageBuilder.message(for: differentArgumentsMatch)
            message = """
                      Call with identifier was recorded \(matchCount) times, but expected \(times). 
                      \(differentArgumentsMatchCount) additional call(s) matched identifier, but not arguments:\n\n\(mismatchedResultsMessage)
                      """
        } else if differentArgumentsMatchCount > 0 {
            let mismatchedResultsMessage = mismatchMessageBuilder.message(for: differentArgumentsMatch)
            message = """
                      Call with identifier \(callIdentifier) was recorded \(differentArgumentsMatchCount) times, 
                      but arguments didn't match.\n\(mismatchedResultsMessage)
                      """
        }

        recordIssue(
            message,
            filePath: testLocation.file,
            fileID: testLocation.fileId,
            line: testLocation.line,
            column: testLocation.column
        )
    }
}
