import Foundation
import Mimus
import Testing

@testable import MimusMocks

private enum ControlledFailure: Error, Equatable { case unavailable }

@Mockable(stubbing: .argumentMatching)
private protocol ControlledService: Sendable {
  @MockCallControl
  @MockDefault(-1)
  func fetch(id: Int) async throws(ControlledFailure) -> Int
  @MockCallControl
  func notify(value: Int)
  @MockCallControl
  func finish() async
  @MockCallControl
  func identity<Value: Sendable>(_ value: Value) async -> Value
}

@Mockable
private protocol ControlledOverloads: Sendable {
  @MockCallControl
  func load(_ id: Int) async -> String
  @MockCallControl
  func load(_ id: String) async -> String
  @MockCallControl
  static func signal() async
  @MockCallControl
  func signal() async
}

@Mockable
private protocol ControlledActor: Actor {
  @MockCallControl
  func finish() async
}

@MainActor
@Mockable
private protocol ControlledPresenter {
  @MockCallControl
  func present() async
}

@Suite(.timeLimit(.minutes(1)))
struct CallControlTests {
  @Test func observingDoesNotSuspendCallsByDefault() async throws {
    let mock = MockControlledService()
    #expect(try await mock.fetch(id: 42) == -1)
    try await mock.fetchIdCalls.waitForCall()
    #expect(mock.fetchIdCalls.callCount == 1)
    #expect(mock.fetchIdCalls.pendingCallCount == 0)
    mock.verify().fetch(id: mEqual(42))
  }

  @Test func pausedCallsRecordBeforeRunningTheirResponses() async throws {
    let mock = MockControlledService()
    let responses = MockState()
    mock.stub().fetch(id: .any).answers { id in
      responses.set(true, for: "ran")
      return .success(id)
    }
    mock.fetchIdCalls.pause()
    let operation = Task { try await mock.fetch(id: 42) }
    try await mock.fetchIdCalls.waitForCall()
    #expect(mock.fetchIdCalls.pendingCallCount == 1)
    #expect(responses.value(for: "ran", as: Bool.self) == nil)
    mock.verify().fetch(id: mEqual(42))
    mock.fetchIdCalls.resume()
    #expect(try await operation.value == 42)
    #expect(responses.value(for: "ran", as: Bool.self) == true)
    mock.verify(mode: .never).fetch(id: mEqual(42))
  }

  @Test func resumeNextReleasesEntriesInOrderAndKeepsPausing() async throws {
    let mock = MockControlledService()
    mock.stub().fetch(id: .any).answers { .success($0) }
    let calls = mock.fetchIdCalls
    calls.pause()
    let first = Task { try await mock.fetch(id: 1) }
    try await calls.waitForCall()
    let second = Task { try await mock.fetch(id: 2) }
    try await calls.waitForCall(count: 2)
    #expect(calls.resumeNext())
    #expect(try await first.value == 1)
    #expect(calls.pendingCallCount == 1)
    calls.resume()
    #expect(try await second.value == 2)
    #expect(!calls.resumeNext())
    #expect(try await mock.fetch(id: 3) == 3)
  }

  @Test func observationsRememberCallsBeforeWaitingAndSupportMultipleWaiters() async throws {
    let mock = MockControlledService()
    async let first: Void = mock.notifyValueCalls.waitForCall()
    async let second: Void = mock.notifyValueCalls.waitForCall(count: 2)
    mock.notify(value: 1)
    mock.notify(value: 2)
    try await first
    try await second
    try await mock.notifyValueCalls.waitForCall(count: 2)
    #expect(mock.notifyValueCalls.callCount == 2)
  }

  @Test func cancellingAnObserverDoesNotConsumeAFutureCall() async throws {
    let mock = MockControlledService()
    let waiter = Task { try await mock.finishCalls.waitForCall() }
    waiter.cancel()
    await #expect(throws: CancellationError.self) { try await waiter.value }
    await mock.finish()
    try await mock.finishCalls.waitForCall()
    #expect(mock.finishCalls.callCount == 1)
  }

  @Test func cancellationReleasesPausedCallsWithoutChangingTheirErrorContract() async throws {
    let mock = MockControlledService()
    mock.fetchIdCalls.pause()
    mock.stub().fetch(id: .any).answers { _ in .success(Task.isCancelled ? 7 : 0) }
    let operation = Task { try await mock.fetch(id: 42) }
    try await mock.fetchIdCalls.waitForCall()
    operation.cancel()
    #expect(try await operation.value == 7)
    #expect(mock.fetchIdCalls.pendingCallCount == 0)
    mock.fetchIdCalls.resume()
  }

  @Test func typedErrorsStillPropagateAfterRelease() async throws {
    let mock = MockControlledService()
    mock.fetchIdCalls.pause()
    mock.stub().fetch(id: .any).throws(.unavailable)
    let operation = Task { try await mock.fetch(id: 42) }
    try await mock.fetchIdCalls.waitForCall()
    mock.fetchIdCalls.resume()
    await #expect(throws: ControlledFailure.unavailable) { try await operation.value }
  }

  @Test func resetReleasesCallsAndRetainedHelpersObserveTheNewLifetime() async throws {
    let mock = MockControlledService()
    let calls = mock.finishCalls
    calls.pause()
    let operation = Task { await mock.finish() }
    try await calls.waitForCall()
    mock.resetMock()
    await operation.value
    #expect(calls.callCount == 0)
    #expect(calls.pendingCallCount == 0)
    await mock.finish()
    try await calls.waitForCall()
    #expect(calls.callCount == 1)
    mock.verify().finish()
  }

  @Test func resetCompletesObserversEvenBeforeContinuationInstallation() async {
    let state = CallCoordinationState()
    let signal = CoordinationSignal()
    state.registerObserver(id: UUID(), count: 1, signal: signal)
    state.reset()
    await #expect(throws: CallCoordinationError.reset) { try await signal.wait() }
  }

  @Test func releaseBeforeContinuationInstallationIsRememberedExactlyOnce() async throws {
    let signal = CoordinationSignal()
    signal.finish(.success(()))
    signal.finish(.failure(CallCoordinationError.reset))
    try await signal.wait()
  }

  @Test func genericSpecializationsHaveIndependentControls() async throws {
    let mock = MockControlledService()
    mock.stub().identity(.any).returns(7)
    mock.stub().identity(.any).returns("value")
    let numbers = mock.identityCalls(for: Int.self)
    let strings = mock.identityCalls(for: String.self)
    numbers.pause()
    let operation = Task { await mock.identity(42) }
    try await numbers.waitForCall()
    #expect(strings.callCount == 0)
    #expect(await mock.identity("input") == "value")
    try await strings.waitForCall()
    #expect(numbers.pendingCallCount == 1)
    numbers.resume()
    #expect(await operation.value == 7)
  }

  @Test func overloadsAndStaticCallsRemainIndependent() async throws {
    let mock = MockControlledOverloads()
    defer { MockControlledOverloads.resetMock() }
    mock.simulatedLoadIntReturningString = "number"
    mock.simulatedLoadStringReturningString = "string"
    #expect(await mock.load(42) == "number")
    #expect(mock.loadIntReturningStringCalls.callCount == 1)
    #expect(mock.loadStringReturningStringCalls.callCount == 0)
    MockControlledOverloads.signalCalls.pause()
    let operation = Task { await MockControlledOverloads.signal() }
    try await MockControlledOverloads.signalCalls.waitForCall()
    await mock.signal()
    #expect(mock.signalCalls.callCount == 1)
    MockControlledOverloads.resetMock()
    await operation.value
    #expect(MockControlledOverloads.signalCalls.callCount == 0)
    #expect(mock.signalCalls.callCount == 1)
  }

  @Test func actorMocksExposeControlsWithoutAnExecutorHop() async throws {
    let mock = MockControlledActor()
    mock.finishCalls.pause()
    let operation = Task { await mock.finish() }
    try await mock.finishCalls.waitForCall()
    mock.finishCalls.resume()
    await operation.value
    mock.verify().finish()
  }

  @MainActor
  @Test func globalActorMethodsResumeOnTheirOriginalActor() async throws {
    let mock = MockControlledPresenter()
    var presented = false
    mock.simulatedPresentHandler = { presented = true }
    mock.presentCalls.pause()
    let operation = Task { await mock.present() }
    try await mock.presentCalls.waitForCall()
    #expect(!presented)
    mock.presentCalls.resume()
    await operation.value
    #expect(presented)
  }

  @Test func concurrentCallsCanAllBeObservedAndReleased() async throws {
    let mock = MockControlledService()
    mock.finishCalls.pause()
    try await withThrowingTaskGroup(of: Void.self) { group in
      for _ in 0..<40 { group.addTask { await mock.finish() } }
      try await mock.finishCalls.waitForCall(count: 40)
      #expect(mock.finishCalls.pendingCallCount == 40)
      mock.finishCalls.resume()
      try await group.waitForAll()
    }
    #expect(mock.finishCalls.pendingCallCount == 0)
    mock.verify(mode: .times(40)).finish()
  }
}
