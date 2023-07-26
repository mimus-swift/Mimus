import Foundation

public class MimusVerifier {
    public let mock: Mock
    public let mode: VerificationMode
    public let file: StaticString
    public let line: UInt
    
    public init(mock: Mock, mode: VerificationMode, file: StaticString, line: UInt) {
        self.mock = mock
        self.mode = mode
        self.file = file
        self.line = line
    }
}
