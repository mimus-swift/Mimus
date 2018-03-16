# Next (1.1.1)


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
