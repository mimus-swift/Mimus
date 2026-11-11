//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

internal struct TestLocation: Sendable {

    let file: StaticString
    let fileId: StaticString
    let line: UInt
    let column: UInt

    static func currentTestLocation(
        file: StaticString = #filePath, 
        fileId: StaticString = #fileID,
        line: UInt = #line,
        column: UInt = #column
    ) -> TestLocation {
        guard let testLocation = current else {
            return TestLocation(file: file, fileId: fileId, line: line, column: column)
        }
        return testLocation
    }

    @TaskLocal static var current: TestLocation?

    static func withLocation<Result>(_ location: TestLocation, perform operation: () throws -> Result) rethrows -> Result {
        try $current.withValue(location, operation: operation)
    }
}
