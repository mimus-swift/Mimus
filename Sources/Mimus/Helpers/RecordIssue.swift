//
// Copyright (©) 2017 AirHelp. All rights reserved.
//

import XCTest
#if canImport(Testing)
import Testing
#endif

public func recordIssue(_ message: String, filePath: StaticString = #filePath, fileID: StaticString = #fileID, line: UInt = #line, column: UInt = #column) {
#if canImport(Testing)
    if Test.current != nil {
      Issue.record(
        Comment(rawValue: message),
        sourceLocation: SourceLocation(
          fileID: fileID.description,
          filePath: filePath.description,
          line: Int(line),
          column: Int(column)
        )
      )
    } else {
      XCTFail(message, file: filePath, line: line)
    }
#else
    XCTFail(message, file: filePath, line: line)
#endif
    XCTFail(message, file: filePath, line: line)
}
