# Basics

At AirHelp we've employed Test Driven Development as our main philosophy when building the iOS app. This resulted in a large test suite, with over 2200 tests covering most of our functionality.

However the more our test suite grew the more duplicate code we found in our logic. Specifically we kept on repeating logic for verifying calls with multiple arguments. It was always the same dance.

# The Problem

Let's imagine you're about to test `AuthenticationCoordinator`, an object that coordinates communication between objects requesting authentication and actual authentication managers. A simple swift implementation, which currently handles only logging in, could look like this:

```swift
class AuthenticationCoordinator {

    let loginAuthenticationManager: AuthenticationManager

    init(loginAuthenticationManager: AuthenticationManager) {
        self.loginAuthenticationManager = loginAuthenticationManager
    }

    func login(with email: String, password: String) {
        loginAuthenticationManager.beginAuthentication(with: email, password: password, options: ["type": "login"])
    }
}
```

`AuthenticationManager` is a protocol - we don't know how it's implemented, but we do know it will handle logging in. The protocol itself is very simple:

```swift

protocol AuthenticationManager {

    func beginAuthentication(with email: String, password: String, options: [String: Any])
}
```

If we were to test our `AuthenticationCoordinator` and check whether it received correct methods we'd have to create a fake `AuthenticationManager`:

```swift
class FakeAuthenticationManager: AuthenticationManager {

    var lastReceivedEmail: String?

    var lastReceivedPassword: String?

    var lastReceivedOptions: [String: Any]?

    func beginAuthentication(with email: String, password: String, options: [String: Any]) {
        lastReceivedEmail = email
        lastReceivedPassword = password
        lastReceivedOptions = options
    }
}
```

In our fake class we capture all parameters that `beginAuthentication` was invoked with. Then in our tests we can do comparisons to verify whether correct arguments were passed, for instance like this:

```swift
XCTAssertEqual(fakeManager.lastReceivedEmail, "Fixture Email")
XCTAssertEqual(fakeManager.lastReceivedPassword, "Fixture Password")
XCTAssertEqual(fakeManager.lastReceivedOptions, ["Fixture Key": "Fixture Value"])
```

There are a few problems with the code above.

*First of all* is that it won't compile - we can't compare `[String: Any]` as `Any` is not equatable.

We can, of course, do some casting:

```
XCTAssertEqual(fakeManager.lastReceivedOptions as? [String: String], ["Fixture Key": "Fixture Value"])
```

This is not only fragile as we can't really pass other types now but also makes tests less readable.

*Second of all* adding multiple assertions is a tedious job - it's easy to forget that one crucial assertions.

*Third of all* we want to have our tests as concise as possible and thus we want to verify one single call - spreading this over multiple assertions doesn't help with quickly understanding what's the purpose of this test.

# The Solution

In Objective-C we could use frameworks like [OCMockito](https://github.com/jonreid/OCMockito) that allowed us to record called methods and verify whether they were called with specific arguments later on.

However in Swift, mostly because of its static nature, things aren't so easy as we can't introspect objects implementations or create new classes in runtime. This makes building mocks hard.

At AirHelp we decided to build a solution that would allow us to simplify our fake objects implementations (aka our mocks) and thus we built our own tool - Mimus.

Mimus greatly simplifies building mocks as it takes away the responsibility of comparing and recording failure if no calls are matched. All you have to do is record invocation and verify whether it was called with appropriate arguments.

Let's see how our example would look like with Mimus.

First of our `FakeAuthenticationManager` is now much simpler

```swift
class FakeAuthenticationManager: AuthenticationManager, Mock {

    var storage = Mimus.Storage()

    func beginAuthentication(with email: String, password: String, options: [String: Any]) {
        recordCall(withIdentifier: "BeginAuthentication", arguments: [email, password, options])
    }
}
```

As you can see we've inherited from `Mock`, a protocol that has one requirement - `storage` for storing recorded calls. Verification implementation lives in protocol extension - you get all the features of Mimus just by implementing this protocol.

What's cool is that we no longer need any additional vars - our implementation is more readable.

Same goes for verification:

```swift
fakeLoginAuthenticationManager.verifyCall(withIdentifier: "BeginAuthentication",
        arguments: ["Fixture Email", "Fixture Password", ["type": "login"]])
```

We pass call identifier and arguments - Mimus will then compare passed in arguments and fail the test with appropriate error.

# Arguments comparison

Mimus uses a helper protocol to match objects - `Matcher`. By default all base types in Swift conform to this protocol, so things will work out of the box for this case - you can pass in types like `Int` directly.

However for your own types you need to write an extension that conforms to this protocol - check out [Using Your Own Types](https://github.com/AirHelp/Mimus/blob/master/Documentation/Using%20Your%20Own%20Types.md) for more details.

What's great is that your tests will fail to compile if you attempt to use an object that's not conforming to `Matcher` protocol. Unfortunately due to Swift compiler limitations this does not work with Arrays and Dictionaries - check bottom of this document for more details.

# Failure Messages

Mimus has a convenience feature that helps you understand what might be the cause of failure - it reports not only failures, but also if there are invocations with given identifier, but arguments were mismatched (this has been, once again, based on the awesome OCMockito - thanks [Jon](https://twitter.com/qcoding) for the idea!).

# Verification Modes

Mimus supports three distinct verification modes:

```swift
public enum VerificationMode {
    case never
    case atLeast(Int)
    case times(Int)
}
```

`never` will fail the test if there is one or more matching invocation.

`atLeast` will fail the test if there is less invocations than passed in the enum value.

`atMost` will fail the test if there is more invocations than passed in the enum value.

`times` will fail the test if the number of invocations does not equal to the enum value.

# Argument Modes

Mimus supports different argument modes:


```swift
public enum Arguments: ExpressibleByArrayLiteral {
    case any
    case actual([Matcher?])
    case none
}
```

`any` will never fail the test if there are any arguments mismatch (basically it's 'I don't mind what the arguments are).

`actual` will match the arguments one to one.

`none` will fail if there are any recorded arguments.

The default value for this parameter is `none`.

## Array and Dictionary matching

Even though Mimus will fail to compile if you pass it a type that doesn't conform to `Matcher` this is not the case for Array and Dictionaries.

The problem lies with limitations on `Array` and `Dictionary` types. You can't define

```swift
extension Array: Matcher where Element: Matcher {
}
```

which would basically mean that `Array` conforms to `Matcher` only if its elements conform to it. This might be possible with future versions of Swift, but for now we're stuck with what we have.

On the other hand it would make little sense if we didn't have `Array`/`Dictionary` comparison out of the box. That's why Mimus will fail the test during runtime if you don't pass an element that conforms to `Matcher` protocol. Same applies to `Dictionary`.
