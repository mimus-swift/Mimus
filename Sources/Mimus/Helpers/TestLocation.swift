//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

internal struct TestLocation {

    let file: StaticString

    let line: UInt

    static func currentTestLocation(file: StaticString = #file, line: UInt = #line) -> TestLocation {
        guard let testLocation = TestLocation.internalTestLocation else {
            return TestLocation(file: file, line: line)
        }
        return testLocation
    }

    static var internalTestLocation: TestLocation?
}
