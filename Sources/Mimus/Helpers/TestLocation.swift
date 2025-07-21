//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

internal struct TestLocation {

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
        guard let testLocation = TestLocation.internalTestLocation else {
            return TestLocation(file: file, fileId: fileId, line: line, column: column)
        }
        return testLocation
    }

    static var internalTestLocation: TestLocation?
}
