# Any Matcher

In certain testing scenarios you might decide that you do not need to test for
one of the values you've recorded. Rather than providing a concrete value there
you can use `AnyMatcher`.

Let's go back to our example with `AuthenticationCoordinator`.

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

Let's assume that in your current scenario you don't really care about the value
passed in options so you want to skip check for it. In order to do so you
can use `AnyMatcher`:

```swift
fakeLoginAuthenticationManager.verifyCall(withIdentifier: "BeginAuthentication",
        arguments: ["Fixture Email", "Fixture Password", AnyMatcher()])
```

`AnyMatcher` always returns true, regardless of object it is matched against and
thus it will not fail if different value is provided.
