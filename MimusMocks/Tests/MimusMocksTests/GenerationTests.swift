import Foundation
import Mimus
import MimusMocks
import Testing

@Mockable
private protocol AuthenticationService {
  var token: String? { get }
  var enabled: Bool { get set }
  func authenticate(email: String, password: String) throws -> String
  func logout()
}

@Mockable
private protocol TypedService {
  func fetch(_ id: Int) -> String
  func fetch(_ id: String) -> String
  func count() -> Int
  func count() -> String
}

private enum ServiceError: Error { case unavailable }

@Mockable
private protocol AsyncService: Sendable {
  var available: Bool { get }
  func fetch(id: Int) async throws(ServiceError) -> String
}

@Mockable
private protocol ClosureService {
  func perform(_ operation: () -> Void)
  func mutate(_ value: inout Int)
  func collect(_ values: Int...) -> [Int]
  func evaluate(_ value: @autoclosure () -> Int) -> Int
}

@Mockable
private protocol GenericService {
  func identity<Value>(_ value: Value) -> Value
}

@Mockable
private protocol Repository {
  associatedtype Element: Equatable
  func load() -> Element
}

@Mockable
private protocol StaticService {
  static func load() throws -> String
}

@Mockable
private protocol IndexedService {
  subscript(index: Int) -> String { get set }
}

@Test func recordsAndVerifiesCalls() throws {
  let mock = MockAuthenticationService()
  mock.simulatedAuthenticateEmailPassword = "Fixture token"
  #expect(
    try mock.authenticate(email: "Fixture email", password: "Fixture password") == "Fixture token")
  mock.verify().authenticate(email: mEqual("Fixture email"), password: mEqual("Fixture password"))
  mock.logout()
  mock.verify().logout()
  #expect(mock.token == nil)
  #expect(!mock.enabled)
  mock.enabled = true
  #expect(mock.enabled)
}

@Test func handlesNonEscapingClosuresAndInout() {
  let mock = MockClosureService()
  var invoked = false
  mock.simulatedPerformHandler = { body in body() }
  mock.perform { invoked = true }
  #expect(invoked)
  mock.verify().perform(mAny())
  mock.simulatedMutateHandler = { $0 += 1 }
  var value = 41
  mock.mutate(&value)
  #expect(value == 42)
  mock.verify().mutate(mEqual(41))
  mock.simulatedCollectHandler = { $0 }
  #expect(mock.collect(1, 2) == [1, 2])
  mock.verify().collect(mEqual([1, 2]))
  var evaluations = 0
  func next() -> Int {
    evaluations += 1
    return 42
  }
  mock.simulatedEvaluateHandler = { $0 }
  #expect(mock.evaluate(next()) == 42)
  #expect(evaluations == 1)
}

@Test func preservesAssociatedTypesAndGenericReturnValues() {
  let repository = MockRepository<Int>()
  repository.simulatedLoad = 42
  #expect(repository.load() == 42)
  repository.verify().load()
  let service = MockGenericService()
  service.stubIdentity(42)
  service.stubIdentity("Fixture value")
  #expect(service.identity(7) == 42)
  #expect(service.identity("input") == "Fixture value")
  service.verify().identity(.value(7))
  service.verify().identity(.value("input"))
}

@Test func supportsSendableStubsAndTypedErrors() async throws {
  let mock = MockAsyncService()
  mock.simulatedFetchIdHandler = { .success("Fixture \($0)") }
  #expect(try await mock.fetch(id: 42) == "Fixture 42")
  mock.verify().fetch(id: mEqual(42))
  mock.simulatedFetchIdHandler = nil
  mock.simulatedFetchIdError = .unavailable
  await #expect(throws: ServiceError.unavailable) { try await mock.fetch(id: 1) }
  mock.verify().fetch(id: mEqual(1))
}

@Test func supportsStaticThrowingMethods() throws {
  MockStaticService.simulatedLoad = "Fixture value"
  #expect(try MockStaticService.load() == "Fixture value")
  MockStaticService.verify().load()
  MockStaticService.simulatedLoadError = ServiceError.unavailable
  #expect(throws: ServiceError.unavailable) { try MockStaticService.load() }
  MockStaticService.verify().load()
  MockStaticService.simulatedLoadError = nil
}

@Test func distinguishesOverloadedMethodsAndReturnTypes() {
  let mock = MockTypedService()
  mock.simulatedFetchIntReturningString = "Fixture integer"
  mock.simulatedFetchStringReturningString = "Fixture string"
  #expect(mock.fetch(42) == "Fixture integer")
  #expect(mock.fetch("42") == "Fixture string")
  mock.verify().fetch(.value(42))
  mock.verify().fetch(.value("42"))
  mock.simulatedCountReturningInt = 42
  mock.simulatedCountReturningString = "Fixture count"
  let count: Int = mock.count()
  let description: String = mock.count()
  #expect(count == 42)
  #expect(description == "Fixture count")
  mock.verify().count(returning: Int.self)
  mock.verify().count(returning: String.self)
}

@Test func supportsSubscripts() {
  let mock = MockIndexedService()
  mock.simulatedSubscriptIntIndexHandler = { "Fixture \($0)" }
  #expect(mock[42] == "Fixture 42")
  mock.simulatedSubscriptIntIndexHandler = nil
  mock[1] = "Fixture stored"
  #expect(mock[1] == "Fixture stored")
}

@Mockable
private protocol ActorService: Actor {
  var enabled: Bool { get }
  func fetch() async -> String
}

@MainActor
@Mockable
private protocol PresenterService {
  func present(value: String)
}

@Mockable
private protocol AsyncPropertyService {
  var title: String { get async throws }
}

@Test func supportsActorRequirements() async {
  let mock = MockActorService()
  mock.enabled = true
  mock.simulatedFetch = "Fixture actor value"
  #expect(mock.enabled)
  #expect(await mock.fetch() == "Fixture actor value")
  mock.verify().fetch()
}

@MainActor
@Test func preservesGlobalActorIsolation() {
  let mock = MockPresenterService()
  mock.present(value: "Fixture value")
  mock.verify().present(value: mEqual("Fixture value"))
}

@Test func supportsEffectfulProperties() async throws {
  let mock = MockAsyncPropertyService()
  mock.simulated_getTitle = "Fixture title"
  #expect(try await mock.title == "Fixture title")
}

@Test func verifiesConcurrentCallsAfterCompletion() async throws {
  let mock = MockAsyncService()
  mock.simulatedFetchIdHandler = { .success("Fixture \($0)") }
  await withTaskGroup(of: Void.self) { group in
    for index in 0..<20 {
      group.addTask { _ = try? await mock.fetch(id: index) }
    }
  }
  mock.verify(mode: .times(20)).fetch(id: mAny())
}

@Test func reportsFailureAtVerificationCallSite() {
  let mock = MockAuthenticationService()
  let expected = SourceLocation(fileID: #fileID, filePath: #filePath, line: 42, column: 7)
  withKnownIssue("Exercise generated source-location forwarding") {
    mock.verify(line: 42, column: 7).logout()
  } matching: {
    $0.sourceLocation == expected
  }
}

@Mockable
private protocol CollectionRepository {
  associatedtype Element: Sequence where Element.Element: Equatable
  func load() -> Element
}

@Mockable
private protocol InitializableService {
  init(value: Int)
  func ignore(_: Int)
}

@Mockable(baseClassName: "NSObject")
private protocol ObjectService: NSObjectProtocol {
  func ping()
}

@Test func handlesAssociatedTypeConstraintsAndUnnamedParameters() {
  let repository = MockCollectionRepository<[Int]>()
  repository.simulatedLoad = [42]
  #expect(repository.load() == [42])
  let service = MockInitializableService(value: 42)
  service.ignore(7)
  service.verify().ignore(mEqual(7))
  let object = MockObjectService()
  object.ping()
  object.verify().ping()
}

@Mockable
private protocol NestedClosureService {
  func update(_ body: (inout Int) -> Void)
  func callbacks(_ bodies: [() -> Void])
}

@Test func preservesNestedFunctionTypes() {
  let mock = MockNestedClosureService()
  mock.simulatedUpdateHandler = { body in
    var value = 41
    body(&value)
    #expect(value == 42)
  }
  mock.update { $0 += 1 }
  mock.verify().update(mAny())
  var invocations = 0
  mock.simulatedCallbacksHandler = { callbacks in
    for callback in callbacks { callback() }
  }
  mock.callbacks([{ invocations += 1 }, { invocations += 1 }])
  #expect(invocations == 2)
  mock.verify().callbacks(mAny())
}
