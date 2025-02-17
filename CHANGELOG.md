# Next

# 2.2.0

- Adds simulate callback matchers

# 2.1.0

- Fixes incorrect description of some matchers when they fail
- **POSSIBLY BREAKING** Only verified calls are removed from storage (previously each verification caused all recored calls to be removed)
- Adds capture into pointer matcher
- Makes Mimus Mocks thread safe (thanks @adiki)

# 2.0.1
- Added Sourcery stencil

# 2.0.0
- **BREAKING** `MockEquatable` has been renamed to `Matcher` to more closely express functionality provided (there is a typealias for backwards compatibility _but_ it might still be breaking in some cases)
- **BREAKING** `Mock.storage` type has been changed from `[RecordedCall]` to `Storage` to better support future features (like e.g. the recording of return values)
- **BREAKING** Calling verify will now reset previously recorded values
- Added option to record values that should be returned for specific invocations
- Added option to provide a custom failure message for a matcher

# 1.1.5
- SPM Support

# 1.1.4
- Mismatched arguments are now included in failure message (thanks @Eluss)
- Added shorthand for `AnyMatcher()`

# 1.1.3
- Add '.atMost' VerificationMode (thanks @kamwysoc)
- Make failure messages more detailed (thanks @kamwysoc)
- Allow passing of nil values to Equal and Identical matchers

# 1.1.2
- Added out of the box comparison support for `UInt`
- Fixed issues with comparing dictionary or array with a different yielded an incorrect message

# 1.1.1
- Added out of the box system classes that support `MockEquatable` (thanks @karolus)
- Allow specifying none or any arguments when verifying calls (see [here for details](https://github.com/mimus-swift/Mimus/blob/master/Documentation/Basics.md#argument-modes))
- Added additional `ClosureMatcher` and `NotMatcher` (see [here for details](https://github.com/mimus-swift/Mimus/blob/master/Documentation/Additional%20Matchers.md#not))

# 1.1.0
- *BREAKING* Changed `MockEquatable` equation function to `equalTo(other: Any)`. This allows to record any type of value, not just types that conform to `MockEquatable`, greatly increasing how versatile this framework is
- Added `InstanceOf<T>` matcher
- Added `EqualTo` and `IdenticalTo` matchers
- Fixed issue where matching dictionaries with subset of equal keys could be successful, even if they contained different amount of entires (Thanks @karolus for spotting this!)

# 1.0.2

- Added convenience extension for `MockEquatable` to simplify matching of types that conform to `Equatable`

# 1.0.1

- Added extension for Float type
- Added extension for URL/NSURL types
- Better Carthage support

# 1.0.0

- Initial release
