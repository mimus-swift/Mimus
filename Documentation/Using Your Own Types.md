# Using Your Own Types

Even though Mimus comes with support for basic types implemented in Swift you
will probably want to use with custom types defined in your own project.

Implementing this is extremely simple as all you need to do is to define an
extension for your object in your test suite and add conformance to
`Matcher` protocol there.

For instance let's say you have a `User` object defined in your application:

```swift
struct User {
  let id: Int
  let name: String
}
```

All you need to do is create an extension that conforms to `Matcher` and
implement comparison logic there:

```swift
extension User: Matcher {
  func matches(argument: Any?) -> Bool {
    if let otherUser = other as? User {
        return id == otherUser.id && name == otherUser.name
    }
    return false
}
```

And that's it! Mimus will handle all the logic for doing actual comparison. This
will also make your objects work with containers like `Array` and `Dictionary`.
You can read more about support for this in [Basics](https://github.com/mimus-swift/Mimus/blob/master/Documentation/Basics.md).

You can also use convenience comparison function defined in `Matcher`
extension for `Equatable` type:

```swift
func compare<T: Equatable>(other: T?) -> Bool {
    guard let equatableSelf = self as? T, let other = other else {
        return false
    }
    return equatableSelf == other
}
```

For instance, if `User` would also conform to `Equatable` you could just write:

```swift
extension User: Matcher {
  func matches(argument: Any?) -> Bool {
    return compare(other: other as? User)
}
```
