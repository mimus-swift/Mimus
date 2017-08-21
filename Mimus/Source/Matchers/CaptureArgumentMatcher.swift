/// Records are compared values.
/// See https://github.com/AirHelp/Mimus/blob/master/Documentation/Capturing%20Arguments.md for more details. 
public class CaptureArgumentMatcher: MockEquatable {

    public var capturedValues: [Any?] = []

    public init() {
    }

    public func equalTo(other: MockEquatable?) -> Bool {
        capturedValues.append(other as Any)
        return true
    }
}
