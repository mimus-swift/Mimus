# MimusMocks

A separate Swift package in the Mimus repository that generates Mimus mocks with
Swift compiler macros. The parent runtime keeps its Swift 5.5 minimum; this package
uses Swift 6.2+ and is currently tested with Swift 6.3.2 / Xcode 26.5.

## Local integration

Add both the parent Mimus package and this directory as local package dependencies.
Add the `MimusMocks` and `Mimus` products to a test or dedicated mocks target.
Keep Mimus's XCTest dependency in those targets.

For a protocol defined in that target:

```swift
import Mimus
import MimusMocks

@Mockable
protocol AuthenticationService {
    func authenticate(email: String, password: String) throws -> String
}

let mock = MockAuthenticationService()
mock.simulatedAuthenticateEmailPassword = "Fixture token"
let token = try mock.authenticate(email: "Fixture email", password: "Fixture password")
mock.verify().authenticate(email: mEqual("Fixture email"), password: mAny())
```

Each method also has a `simulated…Handler` closure. It can implement callbacks,
async suspension, argument-dependent returns, or `inout` changes. Non-escaping
closures are forwarded directly to the handler and represented by an opaque marker
in call history; verify those arguments with `mAny()`.

For typed throws, handlers return `Result<Return, Failure>`. This preserves the
error type without requiring typed-throws function metadata on older deployment
OSes. Ordinary throwing handlers use `throws`.

`Sendable` and actor mocks keep mutable stub state behind a lock and require
`@Sendable` handlers. Returned objects retain their own concurrency contracts.
Global actor annotations are preserved. Observable properties participate in
Observation tracking. `resetMock()` clears calls and configured stub state.
Static stubs are shared for their generated type; tests that use them must control
that shared lifetime.

## Fixture defaults

Use `@MockDefault` on a property, method, or subscript to supply a lazy default:

```swift
@Mockable
protocol Catalog {
    @MockDefault(Product.mock())
    var featured: Product { get }

    @MockDefault(Product(name: "Featured"))
    func product() -> Product

    @MockDefault(.nestedMock)
    var cache: any Cache { get }
}
```

`Product` and its nonthrowing, synchronous `.mock()` factory are defined by the
consumer. `.nestedMock` constructs the corresponding generated mock, such as
`MockCache()`. Use this choice when referring to another generated mock rather
than placing its constructor in a macro argument.

To apply the `.mock()` convention to a whole protocol, use
`@Mockable(defaults: .fixtures)`. Concrete leaf types must have a visible
no-argument `.mock()` factory. Tuple values are built element by element, retaining
their labels and nesting. Optionals default to `nil`; arrays and dictionaries
default to empty collections. Explicit `any Dependency` types default to
`MockDependency()`. A per-member `@MockDefault` takes precedence; `.fixture` can
also opt an individual requirement into the convention.

Defaults are cached separately for each mock and requirement, including method
return values. Concurrent first reads share one initialization. Explicit property
values and simulated return values override the default, and handlers retain
priority over return values and simulated errors. `resetMock()` clears configured
stubs and cached defaults. Factories should avoid cyclic dependencies. Generic
methods continue to use explicit stubs rather than inferred fixtures.

For production protocols processed by the build plugin, use source comments:

```swift
// mimus: mockable
// mimus: defaults = "fixtures"
public protocol Catalog {
    // mimus: default = "Product.mock()"
    var featured: Product { get }
}
```

The adapter also accepts existing `mockValue` and `forceMock` annotations and
recognizes nested protocols selected for mock generation. Define fixture factories
in the mocks target or a module imported by the generated declarations.

## Opt-in Combine publishers

Annotate an `AnyPublisher<Output, Failure>` property to generate a subject helper:

```swift
import Combine

@Mockable
protocol EventSource {
    @MockPublisher
    var events: AnyPublisher<String, Never> { get }

    @MockPublisher(initial: 0)
    var count: AnyPublisher<Int, Never> { get }
}

let mock = MockEventSource()
mock.eventsSubject.send("connected")
mock.countSubject.send(1)
```

`@MockPublisher` creates a `PassthroughSubject`; `initial:` selects a
`CurrentValueSubject`. The initial expression must match the publisher's Output
and can be `nil` for optional output. `<property>Subject` retains its concrete
Output and Failure types. The subject and erased publisher are initialized lazily
and cached per mock. An explicitly configured publisher overrides the generated
one. Unannotated publisher properties keep ordinary property stubbing, including
when the protocol has other opted-in publishers.

`resetMock()` replaces subjects for future subscriptions. It does not complete or
cancel subscriptions that already retain an old subject; subscriptions remain
under the test's control. Property actor isolation and availability are preserved.
Subjects and their output values retain Combine's concurrency contracts; the macro
does not add Sendable conformance to them. The MimusMocks runtime imports only
Foundation; Combine is imported by the target that compiles the generated code.

For production protocols, opt in with one source comment per property:

```swift
// mimus: publisher = "passthrough"
var events: AnyPublisher<String, Never> { get }

// mimus: publisherInitial = "0"
var count: AnyPublisher<Int, Never> { get }
```

Inherited property annotations are retained by the build plugin. Publisher helpers
require a synchronous, nonthrowing property with an explicit `AnyPublisher` type;
aliases and publisher-returning methods keep ordinary stubbing. A publisher helper
and `@MockDefault` on the same property are conflicting choices. The protocol-wide
fixture policy can coexist with opted-in publishers.

## Protocols in production modules

Use `MimusMocksPlugin` on a dedicated mocks target that depends on its production
module, Mimus, and MimusMocks:

```swift
.target(
    name: "DomainMocks",
    dependencies: [
        "Domain",
        .product(name: "Mimus", package: "Mimus"),
        .product(name: "MimusMocks", package: "MimusMocks"),
    ],
    plugins: [.plugin(name: "MimusMocksPlugin", package: "MimusMocks")]
)
```

The production protocol can retain `// sourcery: automockable` or use
`// mimus: mockable`. Sourcery is not executed. The adapter indexes source targets,
flattens inherited requirements, qualifies protocol references, and prepares
private declaration proxies. The compiler macro emits the public mock beside
those proxies in the mocks target. Production sources do not import Mimus or
MimusMocks.

If a mocks target has other source dependencies, select its modules explicitly
in the package root's `.mimus-mocks.json`:

```json
{"targets":{"DomainMocks":{"modules":["Domain"],"includeInternal":false}}}
```

Set `includeInternal` to true for internal mocks built with `@testable` imports.
The plugin supports SwiftPM targets. Xcode project build phases can run the
`MimusMockDeclarations` executable with `--module`, `--input Module=File.swift`,
and `--output` arguments, then compile its output in the mocks target.

## Compatibility and limits

- Existing non-overloaded `verify()` calls use Mimus matchers.
- Overloaded methods use typed `Argument<T>` values, e.g. `.fetch(.value(42))`.
  Return-type-only overloads also require `returning: Int.self`.
- Overloaded stub names include parameter and return types, e.g.
  `simulatedFetchIntReturningString`.
- Generic return values use `stubIdentity(42)` or `stubIdentity("Fixture value")`;
  generic methods do not expose a polymorphic handler property.
- Associated types become generic mock parameters, e.g. `MockRepository<Int>()`.
- Properties, initializers, static throwing methods, subscripts, `async`, typed
  throws, variadics, autoclosures, and `inout` parameters are covered by tests.
- `rethrows` requirements are implemented with nonthrowing witnesses.
- `@Mockable(excluding: ["canReserve"])` retains a protocol extension's
  implementation. The adapter also reads `// mimus: excluding = "canReserve"`.
- A direct macro cannot discover inherited declarations. Use the build-tool
  adapter, or supply a flattened protocol with
  `inheritedRequirementsAreDeclared: true`. The compiler still verifies conformance.
- External inherited protocols whose source is unavailable, nested protocols,
  operator requirements, and static requirements combined with generic associated
  types require an adapter or custom implementation. Unsupported requirements
  should produce a diagnostic rather than silently disappear.
- Fixture factories are opt-in; `defaults: .none` is the default policy.
- Combine subject helpers require `@MockPublisher` or an explicit source comment.
- This nested package currently uses a local path to the parent runtime. Remote
  distribution needs a package/release arrangement that exposes both packages.

## Validation

```sh
swift test --package-path MimusMocks
```

The tests compile and execute expanded mocks, including public mocks emitted into
another module by the build-tool plugin. Diagnostic tests exercise unsupported
inputs.

All fixtures are defined in this package. They exercise inherited requirements,
optional properties, async failures, escaping result callbacks, async sequences,
and protocol extension defaults that call stubbed requirements. The production
fixture module has no dependency on Mimus or MimusMocks; generated mocks live in
a separate fixture module. Run the same command locally and in CI.
