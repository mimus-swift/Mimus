import Mimus
import Testing
import XCTest

private final class SharedReportingVerifier: MimusVerifier {
    func ping() {
        mock.verifyCall(withIdentifier: "ping", mode: mode, file: file, fileId: fileId, line: line, column: column)
    }
}

final class XCTestFailureReportingTests: XCTestCase {
    func testRecordsExactlyOneFailure() {
        var issueCount = 0
        let options = XCTExpectedFailure.Options()
        options.issueMatcher = { issue in
            guard issue.compactDescription.contains("Fixture failure") else { return false }
            issueCount += 1
            return true
        }

        XCTExpectFailure("Exercise Mimus's XCTest failure reporting", options: options) {
            recordIssue("Fixture failure")
        }

        XCTAssertEqual(issueCount, 1)
    }
}

@MainActor
struct SwiftTestingFailureReportingTests {
    @Test func recordsIssueAtProvidedLocation() {
        let location = SourceLocation(fileID: #fileID, filePath: #filePath, line: 42, column: 7)

        withKnownIssue("Exercise Mimus's Swift Testing failure reporting") {
            recordIssue("Fixture failure", filePath: #filePath, fileID: #fileID, line: 42, column: 7)
        } matching: { issue in
            issue.sourceLocation == location
        }
    }

    @Test func sharedVerifierPreservesLocation() {
        let verifier = SharedReportingVerifier(
            mock: MockReportingService(), mode: .times(1), file: #filePath, fileId: #fileID, line: 45, column: 10
        )
        let location = SourceLocation(fileID: #fileID, filePath: #filePath, line: 45, column: 10)

        withKnownIssue("Exercise the shared verifier used by custom templates") {
            verifier.ping()
        } matching: { issue in
            issue.sourceLocation == location
        }
    }

    @Test func generatedInstanceVerifierPreservesLocation() {
        let mock = MockReportingService()
        let location = SourceLocation(fileID: #fileID, filePath: #filePath, line: 42, column: 7)

        withKnownIssue("Exercise the generated verifier's default file path and ID") {
            mock.verify(line: 42, column: 7).ping()
        } matching: { issue in
            issue.sourceLocation == location
        }
    }

    @Test func generatedVerifierCapturesDefaultLineAndColumn() {
        let mock = MockReportingService()
        let expectedLine = #line + 2
        withKnownIssue("Exercise the generated verifier's default line and column") {
            mock.verify().ping()
        } matching: { issue in
            issue.sourceLocation == SourceLocation(
                fileID: #fileID, filePath: #filePath, line: expectedLine, column: 24
            )
        }
    }

    @Test func generatedArgumentVerifierPreservesCustomLocation() {
        let mock = MockReportingService()
        let location = SourceLocation(fileID: "Fixtures/Test.swift", filePath: "/Fixtures/Test.swift", line: 43, column: 8)

        withKnownIssue("Exercise source-location forwarding for a method with arguments") {
            mock.verify(file: "/Fixtures/Test.swift", fileId: "Fixtures/Test.swift", line: 43, column: 8).send(value: 42)
        } matching: { issue in
            issue.sourceLocation == location
        }
    }

    @Test func generatedStaticVerifierPreservesLocation() {
        let location = SourceLocation(fileID: #fileID, filePath: #filePath, line: 44, column: 9)

        withKnownIssue("Exercise source-location forwarding for a static method") {
            MockReportingService.verify(line: 44, column: 9).refresh()
        } matching: { issue in
            issue.sourceLocation == location
        }
    }
}
