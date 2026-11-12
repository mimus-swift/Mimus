import FixtureContracts
import FixtureMocks
import Foundation
import Mimus
import MimusMocks
import Testing

@Test func generatesNamespaceQualifiedMocksAndResolvesNestedParents() async throws {
  let mock = MockWarehouse_Client()
  let client: any Warehouse.Client = mock
  #expect(client.store is MockWarehouse_Store)
  #expect(client.optionalStore is MockWarehouse_Store)
  client.ping()
  mock.verify().ping()
  await client.finish()
  try await mock.finishCalls.waitForCall()
  mock.verify().finish()
  let courier = MockCourier_Store()
  courier.dispatch()
  courier.verify().dispatch()
  let nested = MockWarehouse_Nested_Client()
  nested.ping()
  nested.dispatch()
  nested.verify().ping()
  nested.verify().dispatch()
}

@Test func generatesProtocolsDeclaredInNamespaceExtensions() {
  let mock = MockContractSpace_Service()
  let service: any ContractSpace.Service = mock
  service.ping()
  mock.verify().ping()
}

@Test func preservesConditionalProtocolBranches() {
  let mock = MockPlatformService()
  #if os(macOS)
    mock.simulatedPlatform = "macOS"
    #expect(mock.platform() == "macOS")
    mock.verify().platform()
  #elseif os(Linux)
    mock.simulatedLinuxOnly = 42
    #expect(mock.linuxOnly() == 42)
    mock.verify().linuxOnly()
  #else
    mock.simulatedOtherPlatform = true
    #expect(mock.otherPlatform())
    mock.verify().otherPlatform()
  #endif
}

@Test func externalRequirementOverlaysConformToTheActualFrameworkProtocol() {
  let mock = MockOperationStatus()
  let progress = Progress(totalUnitCount: 10)
  mock.progress = progress
  mock.simulatedReady = true
  let reporting: any ProgressReporting = mock
  #expect(reporting.progress === progress)
  #expect(mock.ready())
  mock.verify().ready()
}

private class OverrideBase {
  var title: String { "Base" }
  func value(id: Int) -> Int { id }
  subscript(index: Int) -> String { "Base \(index)" }
}

@Mockable(baseClassName: "OverrideBase", stubbing: .argumentMatching)
private protocol OverridingService {
  @MockOverride
  var title: String { get }
  @MockOverride
  @MockCallControl
  func value(id: Int) -> Int
  @MockOverride
  subscript(index: Int) -> String { get }
}

@Test func overridesDispatchThroughTheConfiguredSuperclass() async throws {
  let mock = MockOverridingService()
  mock.title = "Configured"
  mock.stub().value(id: .value(42)).returns(7)
  mock.simulatedSubscriptIntIndexHandler = { "Mock \($0)" }
  let base: OverrideBase = mock
  #expect(base.title == "Configured")
  #expect(base.value(id: 42) == 7)
  #expect(base[42] == "Mock 42")
  try await mock.valueIdCalls.waitForCall()
  mock.verify().value(id: mEqual(42))
}

@Test func infersNSObjectAndSupportsLegacyOverrideAnnotations() {
  let mock = MockDescribedService()
  mock.description = "Configured"
  mock.simulatedIsEqualHandler = { $0 is String }
  let base: NSObject = mock
  #expect(base.description == "Configured")
  #expect(base.isEqual("value"))
  mock.verify().isEqual(mAny())
}

private enum CallbackFailure: Error, Equatable { case invalid }

@Mockable(stubbing: .argumentMatching)
private protocol RethrowingService: Sendable {
  func run<Value>(_ operation: () throws -> Value) rethrows -> Value
  func runAsync<Value>(_ operation: () async throws -> Value) async rethrows -> Value
  func finish(_ operation: () throws -> Void) rethrows
}

@Test func rethrowingRulesForwardTheOriginalCallbackAndItsErrors() {
  let mock = MockRethrowingService()
  mock.stub().run(.any).returning(Int.self).callsThrough()
  #expect(mock.run { 42 } == 42)
  #expect(throws: CallbackFailure.invalid) {
    try mock.run { () throws -> Int in throw CallbackFailure.invalid }
  }
  mock.stub().run(.any).returning(String.self).callsThrough()
  #expect(mock.run { "value" } == "value")
  mock.verify(mode: .times(2)).run(Argument<() throws -> Int>.any)
  mock.verify().run(Argument<() throws -> String>.any)
}

@Test func rethrowingSequencesCanReturnWithoutExecutingCallbacks() throws {
  let mock = MockCallbackExecutor()
  mock.stub().perform(.any).callsThrough().thenReturn(7)
  var executions = 0
  #expect(throws: CallbackFailure.invalid) {
    try mock.perform {
      executions += 1
      throw CallbackFailure.invalid
    }
  }
  #expect(
    try mock.perform {
      executions += 1
      throw CallbackFailure.invalid
    } == 7)
  #expect(executions == 1)
  mock.verify(mode: .times(2)).perform(mAny())
}

@Test func asynchronousRethrowingCallbacksCanSuspend() async throws {
  let mock = MockRethrowingService()
  mock.stub().runAsync(.any).returning(Int.self).callsThrough()
  let state = MockState()
  let control = state.asyncCallControl(for: "callback")
  control.pause()
  let operation = Task {
    await mock.runAsync {
      await control.enter()
      return 42
    }
  }
  try await control.waitForCall()
  control.resume()
  #expect(await operation.value == 42)
  await #expect(throws: CallbackFailure.invalid) {
    try await mock.runAsync { () async throws -> Int in throw CallbackFailure.invalid }
  }
}

@Test func voidRethrowingCallbacksCanBeForwardedOrSuppressed() throws {
  let mock = MockRethrowingService()
  var ran = false
  mock.stub().finish(.any).callsThrough()
  mock.finish { ran = true }
  #expect(ran)
  mock.stub().finish(.any).doesNothing().thenCallThrough()
  try mock.finish { throw CallbackFailure.invalid }
  #expect(throws: CallbackFailure.invalid) { try mock.finish { throw CallbackFailure.invalid } }
}
