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

## Argument-specific stubbing

Opt a protocol into typed stub builders with `stubbing: .argumentMatching`:

```swift
@Mockable(stubbing: .argumentMatching)
protocol Catalog {
    func title(id: Int) async throws -> String?
}

let mock = MockCatalog()
mock.stub().title(id: .any).returns("Other")
mock.stub().title(id: .value(42)).returns(nil)
mock.stub().title(id: .matching { $0 < 0 }).throws(CatalogError.invalidID)
mock.stub().title(id: .value(7))
    .throws(CatalogError.offline)
    .thenReturn("Recovered")
    .thenAnswer { id in "Item \(id)" }
```

`CatalogError` is an error type defined by the consumer. Matchers are `.any`,
`.value(value)` for Equatable values, and `.matching { argument in ... }` for a
typed predicate. Optional inputs and explicit `nil` responses retain their meaning.
The latest matching registration wins, including when a later broad matcher
overrides an earlier specific one. Configuration does not call or record the method.

`.returns(first, second, ...)` starts a response sequence; `.thenReturn`,
`.thenThrow`, and `.thenAnswer` append to that same rule. The final response repeats.
A separate terminal call, such as another `.returns`, registers a new rule instead.
Nonthrowing methods expose no throwing action. Void methods also support
`.doesNothing()`. Return values, errors, and answer signatures are checked by the
compiler. Async methods are configured synchronously; their answers can suspend.
Typed-throws answers return `Result<Return, Failure>`, like existing handlers.

Rules run before simulated handlers, errors, values, and fixture defaults. If no
rule matches, those existing fallback paths apply. Every actual invocation is
recorded once. `resetMock()` clears rules and sequence positions along with calls
and existing stubs. Register new rules after reset; appending to an old sequence
handle fails with its original configuration location.

Overloads retain their argument and return types:

```swift
mock.stub().fetch(.any(Int.self)).returns("Integer")
mock.stub().fetch(.any(String.self)).returns("String")
mock.stub().identity(.any).returns(42) // Generic Value inferred as Int.
mock.stub().count().returning(Int.self).throws(CatalogError.offline)
```

Use `.returning(Type.self)` when an error-only action or answer needs help selecting
a return-type overload or generic specialization. `.returns(value)` can usually
infer it directly. These examples refer to matching requirements on the consumer's
protocol.

Answers receive the original arguments: `inout` remains mutable, variadics become
arrays, and autoclosures are evaluated once. Escaping callbacks can be retained by
an answer. Non-escaping closures accept only `.any` as a matcher and are forwarded
directly to answers; they are never stored in the rule table or call history.
Concurrent mocks require `@Sendable` predicates and answers. Predicates and answers
run outside the rule-store lock, on the invoking method's executor; sequence
response selection is synchronized. Under concurrent calls, response order follows
selection order, not task completion order. Return values keep their own concurrency
contracts.

The production-source equivalent is `// mimus: stubbing = "argumentMatching"` on
the protocol. The default `.simple` mode adds no builders or rule dispatch. Rule selectors cover
methods, including static and inherited requirements prepared by the adapter.
Properties and subscripts keep their existing stubbing interfaces. With argument
matching enabled, `stub`, `Stubber`, and `StaticStubber` are reserved member names.

## Opt-in call coordination

Add `@MockCallControl` to a method to observe entry and optionally pause async calls:

```swift
@Mockable
protocol Catalog {
    @MockCallControl
    func fetch(id: Int) async -> String
}

let mock = MockCatalog()
mock.simulatedFetchId = "Ready"
mock.fetchIdCalls.pause()
let operation = Task { await mock.fetch(id: 42) }
try await mock.fetchIdCalls.waitForCall()
mock.verify().fetch(id: mEqual(42))
mock.fetchIdCalls.resume()
let value = await operation.value
```

Helpers follow the method's simulated-stub stem with a `Calls` suffix. Overloads
retain their type suffixes. Generic methods expose a helper function, for example
`mock.identityCalls(for: Int.self)` or `mock.convertCalls(for: (Int, String).self)`;
each specialization has independent coordination state.

`waitForCall(count:)` waits for the total number of entries since reset. Calls
that occurred before waiting still count, and multiple observers can wait safely.
Invocation recording precedes notification, so verification is available as soon
as the wait finishes. This observes entry, not completion of the method's response.

Async helpers start unpaused. `pause()` holds future calls before rule selection,
handlers, errors, or defaults run. `resumeNext()` releases the oldest paused call
and keeps pausing future calls. `resume()` releases all paused calls and stops
pausing. Resuming before a call installs its continuation does not lose the release.
No thread is blocked while a call is paused.

Cancelling a waiting observer throws `CancellationError`. Cancelling a paused call
releases its gate and continues the normal response path with cancellation still
set on the task. This preserves nonthrowing and typed-throws method contracts; a
handler can respond to cancellation according to its own declared error type.
`resetMock()` clears counts, releases paused calls, and fails pending observers
with `CallCoordinationError.reset`. Retained helper values observe the new lifetime.
Released calls use the current stubs. Finish operations, or cancel and await them,
before reset when their responses depend on configuration that reset clears.

Synchronous methods receive a `CallObserver` with `waitForCall(count:)` and
`callCount`; they are never paused. Only annotated methods emit coordination hooks.
Static controls follow static reset; instance controls remain independent. Actor
ownership of the original method and its response is preserved. The coordination
runtime is Foundation-only and stores no invocation arguments or response values.

Production protocols can opt in with `// mimus: callControl` on a method. The
adapter also recognizes the legacy `// sourcery: includeExpectation` flag,
including annotations on inherited requirements. It emits the generic call-control
helpers described here and does not depend on an application's suspender type.

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

## Protocol compatibility

The source adapter supports protocols nested in concrete namespaces, including
namespace extensions. It emits names such as `MockWarehouse_Client` for
`Warehouse.Client`, resolves inherited protocols in the enclosing namespace, and
qualifies protocol references in requirements and fixture defaults.

Conditional protocol declarations retain their original `#if`, `#elseif`, and
`#else` branches, including nested conditions and conditional imports. Inactive
declarations stay inactive in the mocks target. Use consistent compilation flags
in the production and mocks targets. Conditional parent declarations must resolve
unambiguously in the child's context; unresolved alternatives produce a diagnostic.

An SDK or binary dependency might expose a protocol whose source the adapter
cannot index. Provide a small requirement overlay in the mocks target:

```swift
import Foundation

// mimus: requirementsFor = "Foundation.ProgressReporting"
private protocol ProgressRequirements: NSObjectProtocol {
    var progress: Progress { get }
}
```

The plugin reads mocks-target source for overlays. An overlay supplies requirements
and inherited traits for flattening; generated mocks conform to the real production
protocol. The compiler checks their conformance to the actual external protocol,
so an incomplete or incorrect overlay still fails compilation. Fully qualify the
external protocol name. Keep overlays limited to the external contracts you use.

`NSObjectProtocol` automatically selects `NSObject` as the mock base class. Other
base classes remain explicit through `baseClassName:` or the `mockBaseClass`
source annotation. Mark a redeclared member that should override that base:

```swift
@Mockable(baseClassName: "NSObject")
protocol DescribedService: NSObjectProtocol {
    @MockOverride
    var description: String { get }
}
```

`@MockOverride` supports methods, properties, and subscripts. Production-source
equivalents are `// mimus: override` and the legacy `definedIn = "BaseClass"`
annotation when it identifies the configured base class. The Swift compiler checks
that the member is a valid override. A marker without a base class is diagnosed.

`rethrows` witnesses retain their original signature. With argument matching,
methods with one unambiguous throwing callback that takes no arguments and returns
the method's result also expose `.callsThrough()`:

```swift
mock.stub().perform(.any).callsThrough().thenReturn(42)
```

Use `.thenCallThrough()` to append callback forwarding to a response sequence.
Call-through invokes the original callback, preserving its return value, errors,
and async suspension. Configured return values can suppress callback execution.
Rethrowing selectors expose no arbitrary throwing action, and their custom answers
remain nonthrowing. More complex callback signatures need a consumer adapter or
an explicit nonthrowing answer; the generator does not guess callback inputs.

## Compatibility and limits

- Existing non-overloaded `verify()` calls use Mimus matchers.
- Overloaded methods use typed `Argument<T>` values, e.g. `.fetch(.value(42))`.
  Return-type-only overloads also require `returning: Int.self`.
- Overloaded stub names include parameter and return types, e.g.
  `simulatedFetchIntReturningString`.
- Generic return values use `stubIdentity(42)` or `stubIdentity("Fixture value")`
  in simple mode. Argument matching also supports typed answers and per-specialization
  return sequences; generic methods do not expose a polymorphic handler property.
- Associated types become generic mock parameters, e.g. `MockRepository<Int>()`.
- Properties, initializers, static throwing methods, subscripts, `async`, typed
  throws, variadics, autoclosures, and `inout` parameters are covered by tests.
- `rethrows` requirements retain their signature; zero-argument callback forwarding
  is available through `.callsThrough()` as described above.
- `@Mockable(excluding: ["canReserve"])` retains a protocol extension's
  implementation. The adapter also reads `// mimus: excluding = "canReserve"`.
- A direct macro cannot discover inherited declarations. Use the build-tool
  adapter, or supply a flattened protocol with
  `inheritedRequirementsAreDeclared: true`. The compiler still verifies conformance.
- External inherited protocols whose source is unavailable require an explicit
  requirement overlay or a concrete flattened adapter.
- Generic namespaces, constrained namespace extensions, conditional requirement
  blocks inside protocols, ambiguous conditional parents, operator requirements,
  and static requirements combined with generic associated types require an
  adapter or custom implementation. Unsupported requirements produce diagnostics.
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
