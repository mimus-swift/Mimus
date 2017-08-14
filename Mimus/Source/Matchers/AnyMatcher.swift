/// In some testing scenarios you might decide that you do not need to test for one of the values you've recorded.
/// Rather than providing a concrete value there you can use AnyMatcher
/// See https://github.com/AirHelp/Mimus/blob/master/Documentation/Any%20Matcher.md for more info. 
public class AnyMatcher: MockEquatable {

    public init() {
    }

    public func equalTo(other: MockEquatable?) -> Bool {
        return true
    }
}
