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

You can then use this captured value to make assertions whether the passed-in object has been correctly configured. You might want to do this to avoid implementing the `Matcher` protocol for custom object comparison (see [Using Your Own Types](https://github.com/AirHelp/Mimus/blob/master/Documentation/Using%20Your%20Own%20Types.md)), when doing so would make your tests less readable or maybe when you want to simulate additional behaviors on captured object.
