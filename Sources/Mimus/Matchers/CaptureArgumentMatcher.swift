/// Records are compared values.
/// See https://github.com/AirHelp/Mimus/blob/master/Documentation/Capturing%20Arguments.md for more details. 
public class CaptureArgumentMatcher: MockEquatable {

    public var capturedValues: [Any?] = []

    public init() { }

    public func equalTo(other: Any?) -> Bool {
        capturedValues.append(other)
        return true
    }
}

public extension CaptureArgumentMatcher {
    func lastValue<T>() -> T? {
        return capturedValues.last as? T
    }
}
