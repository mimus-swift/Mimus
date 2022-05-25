# Sourcery Stencil 

The recommended way of using Mimus is by leveraging Sourcery code generation for generating mocks. Mimus includes [a basic Sourcery Stencil]() that you can use directly (or modify for your own needs). You can find more about integrating Sourcery into your project [here](). 

## Configuration Options

- `imports` - will import all the libraries passed in here. Expects an array.
- `module` - will be imported using `@testable`
- `onlyPublicTypes` - will generate mocks only for public types. Can be useful when generating mocks for projects that structure code using frameworks. This will allow you to generate mocks only for the public interfaces that are exposed by given framework so that they can be used in tests for modules that depend on the that framework.

## Annotation options

This stencil uses Sourcery annotations like:

```swift
// sourcery: mockBaseClass = "UIViewController"
// sourcery: automockable
protocol MyPresentableProtocol: UIViewController {}
```

to pass options into Sourcery stencil. Currently this stencil supports following options:

- `automockable` - annotating a protocol with this annotation will cause generate a mock for it
- `mockBaseClass` - passing a parameter for this annotation will cause the mock to use that type as a base class
- `advancedReturn` - annotating a function with this annotation will cause it to be generated with a more advanced logic for returning values/throwing errors (see below)
- `forceMock` - annotating a function with this annotation will cause the return value for it to be generated with a `Mock<TypeName>` return type. This can be useful when you want to manually provide mocks in your test code (see below)


## Force Mock and function return values

By default Mimus stencil will use following logic for generating return value logic for functions:

1. If the return value is a protocol that is annotated with `automockable` annotation then the stencil will use the generated mock type for that protocol as a return value like so:

```swift
var simulatedValue: MockSomeMockAnnotatedProtocol = MockSomeMockAnnotatedProtocol()

func value() -> SomeMockAnnotatedProtocol {
    recordCall(withIdentifier: "value")
    return simulatedValue
}
```

2. Otherwise it will generate an implicitly unwrapped variable of the return value type like so:

```swift
var simulatedValue: SomeType!

func value() -> SomeType {
    recordCall(withIdentifier: "value")
    return simulatedValue
}
```

You can use `forceMock` annotation to force the first behavior regardless of the return type annotations.

# Advanced Return Logic

This is still very much in the works but the general idea behind this stencil feature is for better control over what values get returned for what arguments. 

This might be especially useful for factory-style functions where you might want to return different values based on input arguments. 

You can use `advancedReturn` annotation on a function with return value to trigger this behavior. Note that all the input arguments have to currently either be Equatable or class types otherwise the stencil will generate code that does not compile. 