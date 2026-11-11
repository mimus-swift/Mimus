import Foundation
import XCTest
@testable import Mimus

final class VerificationContextTests: XCTestCase {
    private final class Recorder: Mock {
        let storage = Storage()
    }

    func testNestedVerificationRestoresSourceLocation() {
        let outer = Recorder()
        let inner = Recorder()
        outer.recordCall(withIdentifier: "outer", arguments: [42])

        let matcher = ClosureMatcher<Int> { value in
            inner.verifyCall(withIdentifier: "inner", mode: .never, file: "Inner.swift", line: 20)
            let location = TestLocation.currentTestLocation()
            XCTAssertEqual(location.file.description, "Outer.swift")
            XCTAssertEqual(location.fileId.description, "Tests/Outer.swift")
            XCTAssertEqual(location.line, 10)
            XCTAssertEqual(location.column, 3)
            return value == 42
        }

        outer.verifyCall(withIdentifier: "outer", arguments: [matcher], file: "Outer.swift", fileId: "Tests/Outer.swift", line: 10, column: 3)

        let location = TestLocation.currentTestLocation(file: "Fallback.swift", line: 30)
        XCTAssertEqual(location.file.description, "Fallback.swift")
        XCTAssertEqual(location.line, 30)
    }

    func testSourceLocationIsRestoredWhenScopeThrows() {
        enum Failure: Error { case expected }
        let location = TestLocation(file: "Scoped.swift", fileId: "Tests/Scoped.swift", line: 10, column: 1)

        XCTAssertThrowsError(try TestLocation.withLocation(location) {
            throw Failure.expected
        })

        let restored = TestLocation.currentTestLocation(file: "Fallback.swift", line: 30)
        XCTAssertEqual(restored.file.description, "Fallback.swift")
        XCTAssertEqual(restored.line, 30)
    }

    func testConcurrentVerificationsKeepTheirOwnSourceLocations() {
        let firstEntered = DispatchSemaphore(value: 0)
        let secondEntered = DispatchSemaphore(value: 0)
        let firstFinished = DispatchSemaphore(value: 0)
        let completed = DispatchSemaphore(value: 0)

        Thread.detachNewThread {
            defer { completed.signal() }
            let first = Recorder()
            first.recordCall(withIdentifier: "first", arguments: [42])
            let matcher = ClosureMatcher<Int> { _ in
                firstEntered.signal()
                guard secondEntered.wait(timeout: .now() + 5) == .success else {
                    XCTFail("Second verification did not enter its matcher")
                    return false
                }
                let location = TestLocation.currentTestLocation()
                XCTAssertEqual(location.file.description, "First.swift")
                XCTAssertEqual(location.line, 10)
                return true
            }
            first.verifyCall(withIdentifier: "first", arguments: [matcher], file: "First.swift", line: 10)
            firstFinished.signal()
        }

        Thread.detachNewThread {
            defer { completed.signal() }
            guard firstEntered.wait(timeout: .now() + 5) == .success else {
                XCTFail("First verification did not enter its matcher")
                return
            }
            let second = Recorder()
            second.recordCall(withIdentifier: "second", arguments: [42])
            let matcher = ClosureMatcher<Int> { _ in
                secondEntered.signal()
                guard firstFinished.wait(timeout: .now() + 5) == .success else {
                    XCTFail("First verification did not finish")
                    return false
                }
                let location = TestLocation.currentTestLocation()
                XCTAssertEqual(location.file.description, "Second.swift")
                XCTAssertEqual(location.line, 20)
                return true
            }
            second.verifyCall(withIdentifier: "second", arguments: [matcher], file: "Second.swift", line: 20)
        }

        XCTAssertEqual(completed.wait(timeout: .now() + 10), .success)
        XCTAssertEqual(completed.wait(timeout: .now() + 10), .success)
    }

    func testChildTasksInheritSourceLocationAfterSynchronousScopeReturns() async {
        let location = TestLocation(file: "Parent.swift", fileId: "Tests/Parent.swift", line: 10, column: 2)
        let task = TestLocation.withLocation(location) {
            Task {
                await Task.yield()
                return TestLocation.currentTestLocation()
            }
        }

        let inherited = await task.value
        XCTAssertEqual(inherited.file.description, "Parent.swift")
        XCTAssertEqual(inherited.fileId.description, "Tests/Parent.swift")
        XCTAssertEqual(inherited.line, 10)
        XCTAssertEqual(inherited.column, 2)
        XCTAssertNil(TestLocation.current)
    }

    func testConcurrentTasksKeepTheirOwnSourceLocationsAcrossSuspension() async {
        await withTaskGroup(of: Void.self) { group in
            for line in 1...20 {
                group.addTask {
                    let location = TestLocation(file: "Task.swift", fileId: "Tests/Task.swift", line: UInt(line), column: 1)
                    await TestLocation.$current.withValue(location) {
                        await Task.yield()
                        let current = TestLocation.currentTestLocation()
                        XCTAssertEqual(current.file.description, "Task.swift")
                        XCTAssertEqual(current.line, UInt(line))
                    }
                    XCTAssertNil(TestLocation.current)
                }
            }
        }
    }

    func testNestedVerificationsKeepTheirOwnHandlers() {
        let outer = Recorder()
        let inner = Recorder()
        let outerHandler = FakeVerificationHandler()
        let innerHandler = FakeVerificationHandler()
        let outerLocation = TestLocation(file: "Outer.swift", fileId: "Tests/Outer.swift", line: 10, column: 1)
        let innerLocation = TestLocation(file: "Inner.swift", fileId: "Tests/Inner.swift", line: 20, column: 1)
        outer.recordCall(withIdentifier: "outer", arguments: [42])
        inner.recordCall(withIdentifier: "inner")

        let matcher = ClosureMatcher<Int> { value in
            inner.verifyCall(withIdentifier: "inner", testLocation: innerLocation, verificationHandler: innerHandler)
            return value == 42
        }
        outer.verifyCall(withIdentifier: "outer", arguments: [matcher], testLocation: outerLocation, verificationHandler: outerHandler)

        XCTAssertEqual(outerHandler.lastCallIdentifier, "outer")
        XCTAssertEqual(outerHandler.lastTestLocation?.line, 10)
        XCTAssertEqual(innerHandler.lastCallIdentifier, "inner")
        XCTAssertEqual(innerHandler.lastTestLocation?.line, 20)
    }
}
