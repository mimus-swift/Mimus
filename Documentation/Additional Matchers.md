# EqualTo

You can use `EqualTo` matcher to verify whether given two elements are equal to each other. Note that the type you're using must conform to `Equatable`.

Let's define an equatable struct:

```swift
struct TestStruct: Equatable {
    static func ==(lhs: TestStruct, rhs: TestStruct) -> Bool {
        return lhs.value == rhs.value
    }

    let value: String
}
```

In your tests you can use:

```swift
let object = TestStruct(value: "Fixture Value 1")
let anotherObject = TestStruct(value: "Fixture Value 1")

(...)

delegate.verifyCall(withIdentifier: "Fixture Identifier", arguments: [[EqualTo(anotherObject)]])
```

You can also use shorthand method:

```swift
delegate.verifyCall(withIdentifier: "Fixture Identifier", arguments: [[mEqual(anotherObject)]])
```

# IdenticalTo

You can use `IdenticalTo` matcher to verify whether given two elements are identical to each other. This will only work for classes (as in types conforming to `AnyClass`)
Let's define a class:

```swift
class TestClass {

}
```

In your tests you can use:

```swift
let object = TestStruct()
let anotherObject = TestStruct()

(...)

delegate.verifyCall(withIdentifier: "Fixture Identifier", arguments: [[IdenticalTo(anotherObject)]])
```

You can also use shorthand method:

```swift
delegate.verifyCall(withIdentifier: "Fixture Identifier", arguments: [[mIdentical(anotherObject)]])
```

# InstanceOf

In certain scenarios you might not need to check any specific value of recorded
object, but rather whether it is of a specific class. In this scenario you can
use `InstanceOf<T>` matcher.

In this example we'll use a `ApplicationService`, an abstract class that
represent application service. We'll also use a central repository of those
services, which allows us to register them by calling
`func register(service: Service)`:

```swift
protocol ApplicationService {

}

protocol ApplicationServiceRegistrator {
  func register(service: Service)
}
```

In our tests we'll use a fake class that impersonates `ApplicationServiceRegistrator`:

```swift
class FakeApplicationServiceRegistrator: ApplicationServiceRegistrator, Mock {

    var storage: [RecordedCall] = []

    func register(service: ApplicationService) {
        recordCall(withIdentifier: "register", arguments: [service])
    }
}
```

and a fake class that impersonates `ApplicationService`:

```swift
class FakeApplicationService: ApplicationService { }
```

Now in our test we can check whether correct instance of `ApplicationService` was passed by using a `InstanceOf<FakeApplicationService>()`:

```swift
let fakeServiceRegistrator = FakeApplicationServiceRegistrator()

fakeServiceRegistrator.register(service: FakeApplicationService())

fakeServiceRegistrator.verifyCall(withIdentifier: "register", arguments: [InstanceOf<FakeApplicationService>()])
```

And that's it!
