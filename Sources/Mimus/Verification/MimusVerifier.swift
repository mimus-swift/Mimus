import Foundation

open class MimusVerifier {
    public let mock: Mock
    public let mode: VerificationMode
    public let file: StaticString
    public let fileId: StaticString
    public let line: UInt
    public let column: UInt
    
    public init(mock: Mock, mode: VerificationMode, file: StaticString, fileId: StaticString = #fileID, line: UInt, column: UInt = #column) {
        self.mock = mock
        self.mode = mode
        self.file = file
        self.fileId = fileId
        self.line = line
        self.column = column
    }
}
