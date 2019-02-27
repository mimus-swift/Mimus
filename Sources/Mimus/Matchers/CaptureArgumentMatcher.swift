/// Records are compared values.
/// See https://github.com/AirHelp/Mimus/blob/master/Documentation/Capturing%20Arguments.md for more details. 
public class CaptureArgumentMatcher: Matcher {

    public var capturedValues: [Any?] = []

    public init() { }

    public func matches(argument: Any?) -> Bool {
        capturedValues.append(argument)
        return true
    }
}

public extension CaptureArgumentMatcher {
    func lastValue<T>() -> T? {
        return capturedValues.last as? T
    }
}
