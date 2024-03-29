## Capturing Arguments

Sometimes you will want to capture argument, rather than check for equality,
as, for instance, you might want to have more granular assertions.

In this case you case use `CaptureArgumentMatcher`. Let's go back to our example
with authentication coordinator:

```swift
func testCaptureArgument() {
    sut.login(with: "Fixture Email", password: "Fixture Password")

    let argumentCaptor = CaptureArgumentMatcher()

    fakeLoginAuthenticationManager.verifyCall(withIdentifier: "BeginAuthentication",
            arguments: ["Fixture Email", "Fixture Password", argumentCaptor])

    let capturedOptions = argumentCaptor.capturedValues.last as? [String: String]

    XCTAssertEqual(capturedOptions?["type"], "login")
}
```

Now, instead of passing an actual expected value we pass `CaptureArgumentMatcher` which records last argument that it verified.

You can then use this captured value to make assertions whether the passed-in object has been correctly configured. You might want to do this to avoid implementing the `Matcher` protocol for custom object comparison (see [Using Your Own Types](https://github.com/mimus-swift/Mimus/blob/master/Documentation/Using%20Your%20Own%20Types.md)), when doing so would make your tests less readable or maybe when you want to simulate additional behaviors on captured object.

## Using `CapturePointerMatcher` matcher

You can alternatively use the `CapturePointerMatcher` matcher to capture values directly into variables. Here's an example with matcher shorthand (`mCaptureInto(pointer:)`) used:

```swift
func testCapturePointerArgument() {
    sut.login(with: "Fixture Email", password: "Fixture Password")
    var capturedEmail: String?

    fakeLoginAuthenticationManager.verifyCall(withIdentifier: "BeginAuthentication",
        arguments: [mCaptureInto(pointer: &capturedEmail), "Fixture Password", mAny()])

    XCTAssertEqual(capturedEmail, "Fixture Email")
}
```
