# Any Matcher

In certain scenarios you might not need to check any specific value of recorded
object, but rather whether it is of a specific class. In this scenario you can
use `InstanceOf<T>` matcher.

In this example we'll use a `ApplicationService`, an abstract class that
represent application service. We'll also use a central repository of those
services, which allows us to register them by calling
`func register(service: Service)`:

```
protocol ApplicationService {

}

protocol ApplicationServiceRegistrator {
  func register(service: Service)
}
```

In our tests we'll use a fake class that impersonates `ApplicationServiceRegistrator`:

```
class FakeApplicationServiceRegistrator: ApplicationServiceRegistrator, Mock {

    var storage: [RecordedCall] = []

    func register(service: ApplicationService) {
        recordCall(withIdentifier: "register", arguments: [service])
    }
}
```

and a fake class that impersonates `ApplicationService`:

```
class FakeApplicationService: ApplicationService { }
```

Now in our test we can check whether correct instance of `ApplicationService` was passed by using a `InstanceOf<FakeApplicationService>()`:

```
let fakeServiceRegistrator = FakeApplicationServiceRegistrator()

fakeServiceRegistrator.register(service: FakeApplicationService())

fakeServiceRegistrator.verifyCall(withIdentifier: "register", arguments: [InstanceOf<FakeApplicationService>()])
```

And that's it!
