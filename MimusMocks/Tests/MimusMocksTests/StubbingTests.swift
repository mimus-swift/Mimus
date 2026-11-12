import Foundation
import Mimus
import MimusMocks
import Testing

private struct RuleEntry: Equatable, Sendable {
  let id: Int
  static func mock() -> Self { Self(id: -1) }
}
private enum RuleFailure: Error, Equatable { case offline, invalid }

@Mockable(stubbing: .rules)
private protocol RuleCatalog: Sendable {
  @MockDefault(RuleEntry.mock())
  func fetch(id: Int) async throws -> RuleEntry
  @MockDefault("fallback")
  func label(id: Int) -> String?
  @MockDefault(-1)
  func compute(value: Int) -> Int
  @MockDefault("unknown")
  func optional(_ token: String?) -> String
  func notify(id: Int)
}

@Mockable(stubbing: .rules)
private protocol TypedRuleCatalog: Sendable {
  func fetch(id: Int) async throws(RuleFailure) -> RuleEntry
}

@Mockable(stubbing: .rules)
private protocol OverloadedRules: Sendable {
  func fetch(_ id: Int) -> String
  func fetch(_ id: String) -> String
  func count() throws(RuleFailure) -> Int
  func count() throws(RuleFailure) -> String
  func identity<Value>(_ value: Value) -> Value
  func convert<Input, Output>(_ input: Input) -> Output
  func make<Value>() -> Value
  func copy<Value>(_ value: Value) -> Value where Value: Equatable & Sendable
}

@Mockable(stubbing: .rules)
private protocol CallbackRules {
  func perform(_ operation: () -> Int) -> Int
  func mutate(_ value: inout Int)
  func collect(_ values: Int...) -> [Int]
  func evaluate(_ value: @autoclosure () -> Int) -> Int
  func request(completion: @escaping (Int) -> Void)
  func forward(handler: Int) -> Int
}

@Mockable(stubbing: .rules)
private protocol ConcurrentCallbackRules: Sendable {
  func request(completion: @escaping @Sendable (Int) -> Void)
}

@Mockable(stubbing: .rules)
private protocol AssociatedRules {
  associatedtype Element: Equatable
  func load() -> Element
}

@Mockable(stubbing: .rules)
private protocol ActorRules: Actor {
  func value(id: Int) async -> Int
}

@MainActor
@Mockable(stubbing: .rules)
private protocol PresenterRules {
  func title(id: Int) -> String
}

@Mockable(stubbing: .rules)
private protocol StaticRules: Sendable {
  static func value(id: Int) -> Int
  func value(id: Int) -> Int
}

@Mockable
private protocol SimpleStubMember {
  var stub: String? { get }
}

@Test func stubbingConfigurationDoesNotInvokeOrRecordMethods() async throws {
  let mock = MockRuleCatalog()
  mock.simulatedFetchIdHandler = { _ in throw RuleFailure.offline }
  mock.stub().fetch(id: .value(42)).returns(RuleEntry(id: 42))
  mock.verify(mode: .never).fetch(id: mAny())
  #expect(try await mock.fetch(id: 42) == RuleEntry(id: 42))
  mock.verify().fetch(id: mEqual(42))
}

@Test func latestMatchingRuleWinsWithoutSpecificityHeuristics() {
  let mock = MockRuleCatalog()
  mock.stub().compute(value: .any).returns(10)
  mock.stub().compute(value: .value(42)).returns(20)
  #expect(mock.compute(value: 42) == 20)
  #expect(mock.compute(value: 7) == 10)
  mock.stub().compute(value: .any).returns(30)
  #expect(mock.compute(value: 42) == 30)
  mock.verify(mode: .times(2)).compute(value: mEqual(42))
}

@Test func matchesArgumentsAndPreservesExplicitNilReturns() {
  let mock = MockRuleCatalog()
  mock.stub().label(id: .value(42)).returns(nil)
  #expect(mock.label(id: 42) == nil)
  #expect(mock.label(id: 1) == "fallback")
  mock.stub().optional(.value(nil)).returns("nil input")
  mock.stub().optional(.matching { $0 != nil }).returns("present input")
  #expect(mock.optional(nil) == "nil input")
  #expect(mock.optional("value") == "present input")
}

@Test func unmatchedRulesPreserveHandlerErrorValueAndFixtureFallback() async throws {
  let mock = MockRuleCatalog()
  mock.stub().fetch(id: .value(1)).returns(RuleEntry(id: 1))
  #expect(try await mock.fetch(id: 2) == .mock())
  mock.simulatedFetchId = RuleEntry(id: 20)
  #expect(try await mock.fetch(id: 2).id == 20)
  mock.simulatedFetchIdError = RuleFailure.offline
  await #expect(throws: RuleFailure.offline) { try await mock.fetch(id: 2) }
  mock.simulatedFetchIdHandler = { id in RuleEntry(id: id * 100) }
  #expect(try await mock.fetch(id: 2).id == 200)
  #expect(try await mock.fetch(id: 1).id == 1)
}

@Test func sequencesMixReturnsErrorsAndAnswersAndRepeatTheirLastResponse() async throws {
  let mock = MockRuleCatalog()
  mock.stub().fetch(id: .any)
    .throws(RuleFailure.offline)
    .thenReturn(RuleEntry(id: 2))
    .thenAnswer { id in RuleEntry(id: id * 3) }
  await #expect(throws: RuleFailure.offline) { try await mock.fetch(id: 1) }
  #expect(try await mock.fetch(id: 1).id == 2)
  #expect(try await mock.fetch(id: 4).id == 12)
  #expect(try await mock.fetch(id: 5).id == 15)
  mock.verify(mode: .times(4)).fetch(id: mAny())
}

@Test func returnListsAndLateSequenceAppendsAdvancePredictably() {
  let mock = MockRuleCatalog()
  let sequence = mock.stub().compute(value: .any).returns(1, 2, 3)
  #expect(mock.compute(value: 0) == 1)
  #expect(mock.compute(value: 0) == 2)
  #expect(mock.compute(value: 0) == 3)
  #expect(mock.compute(value: 0) == 3)
  sequence.thenReturn(4)
  #expect(mock.compute(value: 0) == 4)
  mock.stub().compute(value: .any).returns(9)
  #expect(mock.compute(value: 0) == 9)
}

@Test func typedThrowingRulesAcceptTypedErrorsAndResultAnswers() async throws {
  let mock = MockTypedRuleCatalog()
  mock.stub().fetch(id: .value(1)).throws(.offline).thenReturn(RuleEntry(id: 2))
  await #expect(throws: RuleFailure.offline) { try await mock.fetch(id: 1) }
  #expect(try await mock.fetch(id: 1).id == 2)
  mock.stub().fetch(id: .matching { $0 > 1 }).answers { id in
    id == 2 ? .failure(.invalid) : .success(RuleEntry(id: id))
  }
  await #expect(throws: RuleFailure.invalid) { try await mock.fetch(id: 2) }
  #expect(try await mock.fetch(id: 3).id == 3)
}

@Test func stubSelectorsDistinguishOverloadsAndGenericSpecializations() throws {
  let mock = MockOverloadedRules()
  mock.stub().fetch(.value(1)).returns("integer")
  mock.stub().fetch(.any(String.self)).returns("string")
  #expect(mock.fetch(1) == "integer")
  #expect(mock.fetch("1") == "string")
  mock.stub().count().returns(42)
  mock.stub().count().returns("count")
  let count: Int = try mock.count()
  let label: String = try mock.count()
  #expect(count == 42)
  #expect(label == "count")
  mock.stub().count().returning(Int.self).throws(.offline)
  #expect(throws: RuleFailure.offline) { let _: Int = try mock.count() }
  mock.stub().identity(.any).returns(7)
  mock.stub().identity(.value("input")).answers { $0.uppercased() }
  #expect(mock.identity(1) == 7)
  #expect(mock.identity("input") == "INPUT")
  mock.stub().convert(.value(1)).returning(String.self).returns("converted")
  mock.stub().convert(.value(1)).returning(Int.self).returns(8)
  let converted: String = mock.convert(1)
  let number: Int = mock.convert(1)
  #expect(converted == "converted")
  #expect(number == 8)
  mock.stub().make().returns("created")
  let created: String = mock.make()
  #expect(created == "created")
  mock.stub().copy(.value(42)).answers { $0 + 1 }
  #expect(mock.copy(42) == 43)
}

@Test func ordinaryThrowingAnswersCanSuspendAndPropagateErrors() async throws {
  let mock = MockRuleCatalog()
  mock.stub().fetch(id: .any).answers { id in
    await Task.yield()
    if id < 0 { throw RuleFailure.invalid }
    return RuleEntry(id: id)
  }
  #expect(try await mock.fetch(id: 42).id == 42)
  await #expect(throws: RuleFailure.invalid) { try await mock.fetch(id: -1) }
  mock.verify(mode: .times(2)).fetch(id: mAny())
}

@Test func rulePredicatesAndAnswersCanReenterTheSameMock() {
  let mock = MockRuleCatalog()
  defer { mock.resetMock() }
  mock.stub().compute(value: .matching { mock.label(id: $0) == "fallback" }).returns(7)
  mock.stub().compute(value: .value(2)).answers { _ in mock.compute(value: 1) + 1 }
  #expect(mock.compute(value: 2) == 8)
  mock.verify().compute(value: mEqual(2))
  mock.verify().compute(value: mEqual(1))
  mock.verify().label(id: mEqual(1))
}

@Test func resetClearsRulesAndInvocationsAndAllowsFreshRegistration() {
  let mock = MockRuleCatalog()
  mock.stub().compute(value: .any).returns(1, 2)
  #expect(mock.compute(value: 0) == 1)
  mock.resetMock()
  mock.verify(mode: .never).compute(value: mAny())
  #expect(mock.compute(value: 0) == -1)
  mock.stub().compute(value: .any).returns(3, 4)
  #expect(mock.compute(value: 0) == 3)
  #expect(mock.compute(value: 0) == 4)
}

@Test func resettingInsideAMatcherDiscardsItsPendingResponse() {
  let mock = MockRuleCatalog()
  mock.stub().compute(
    value: .matching { _ in
      mock.resetMock()
      return true
    }
  ).returns(99)
  #expect(mock.compute(value: 1) == -1)
}

@Test func voidRulesCanDoNothingOrRunAnswers() {
  let mock = MockRuleCatalog()
  let state = MockState()
  mock.stub().notify(id: .any).doesNothing().thenAnswer { state.set($0, for: "notified") }
  mock.notify(id: 1)
  #expect(state.value(for: "notified", as: Int.self) == nil)
  mock.notify(id: 2)
  #expect(state.value(for: "notified", as: Int.self) == 2)
  mock.verify().notify(id: mEqual(1))
}

@Test func throwingSequencesCanAppendErrorsAfterReturns() async throws {
  let mock = MockTypedRuleCatalog()
  mock.stub().fetch(id: .any).returns(RuleEntry(id: 1)).thenThrow(.invalid)
  #expect(try await mock.fetch(id: 1).id == 1)
  await #expect(throws: RuleFailure.invalid) { try await mock.fetch(id: 1) }
  await #expect(throws: RuleFailure.invalid) { try await mock.fetch(id: 1) }
}

@Test func concurrentCallsConsumeEachSequenceResponseOnce() async {
  let mock = MockRuleCatalog()
  let sequence = mock.stub().compute(value: .any).returns(0)
  for value in 1..<40 { sequence.thenReturn(value) }
  let values = await withTaskGroup(of: Int.self) { group in
    for value in 0..<40 { group.addTask { mock.compute(value: value) } }
    var results = [Int]()
    for await result in group { results.append(result) }
    return results.sorted()
  }
  #expect(values == Array(0..<40))
  #expect(mock.compute(value: 100) == 39)
  mock.verify(mode: .times(41)).compute(value: mAny())
}

@Test func concurrentRegistrationsRemainIndependent() async {
  let mock = MockRuleCatalog()
  await withTaskGroup(of: Void.self) { group in
    for value in 0..<30 {
      group.addTask { mock.stub().compute(value: .value(value)).returns(value * 2) }
    }
  }
  for value in 0..<30 { #expect(mock.compute(value: value) == value * 2) }
}

@Test func answersForwardNonEscapingClosuresInoutVariadicsAndAutoclosures() {
  let mock = MockCallbackRules()
  mock.stub().perform(.any).answers { body in body() + 1 }
  var invoked = false
  #expect(
    mock.perform {
      invoked = true
      return 41
    } == 42)
  #expect(invoked)
  mock.verify().perform(mAny())
  mock.stub().mutate(.value(41)).answers { $0 += 1 }
  var value = 41
  mock.mutate(&value)
  #expect(value == 42)
  mock.verify().mutate(mEqual(41))
  mock.stub().collect(.value([1, 2])).answers { $0.reversed() }
  #expect(mock.collect(1, 2) == [2, 1])
  mock.verify().collect(mEqual([1, 2]))
  mock.stub().evaluate(.value(42)).answers { $0 + 1 }
  var evaluations = 0
  func next() -> Int {
    evaluations += 1
    return 42
  }
  #expect(mock.evaluate(next()) == 43)
  #expect(evaluations == 1)
  mock.verify().evaluate(mEqual(42))
  mock.stub().forward(handler: .any).answers { $0 + 1 }
  #expect(mock.forward(handler: 41) == 42)
}

@Test func answersCanRetainEscapingCallbacksAndCaptureOrdinaryMutableState() {
  let mock = MockCallbackRules()
  var pending: ((Int) -> Void)?
  mock.stub().request(completion: .any).answers { pending = $0 }
  var received = 0
  mock.request { received = $0 }
  #expect(received == 0)
  pending?(42)
  #expect(received == 42)
  mock.verify().request(completion: mAny())
}

@Test func sendableAnswersPreserveEscapingCallbackSignatures() {
  let mock = MockConcurrentCallbackRules()
  let state = MockState()
  mock.stub().request(completion: .any).answers { state.set($0, for: "callback") }
  mock.request { state.set($0, for: "received") }
  let pending: (@Sendable (Int) -> Void)? = state.value(for: "callback")
  pending?(42)
  #expect(state.value(for: "received", as: Int.self) == 42)
}

private struct UnmatchedPayload { let id: Int }

@Mockable(stubbing: .rules)
private protocol PayloadRules {
  func identify(_ payload: UnmatchedPayload) -> Int
}

@Test func predicatesAcceptNonEquatableValues() {
  let mock = MockPayloadRules()
  mock.stub().identify(.matching { $0.id == 42 }).returns(7)
  #expect(mock.identify(UnmatchedPayload(id: 42)) == 7)
}

@Test func rulesUseAssociatedTypeSpecializations() {
  let numbers = MockAssociatedRules<Int>()
  let strings = MockAssociatedRules<String>()
  numbers.stub().load().returns(42)
  strings.stub().load().returns("value")
  #expect(numbers.load() == 42)
  #expect(strings.load() == "value")
}

@Test func actorAnswersCanSuspendAndReenterTheirMock() async {
  let mock = MockActorRules()
  defer { mock.resetMock() }
  mock.stub().value(id: .value(1)).returns(41)
  mock.stub().value(id: .value(2)).answers { _ in
    await Task.yield()
    return await mock.value(id: 1) + 1
  }
  #expect(await mock.value(id: 2) == 42)
  mock.verify().value(id: mEqual(1))
  mock.verify().value(id: mEqual(2))
}

@MainActor
@Test func ruleBuildersPreserveGlobalActorIsolation() {
  let mock = MockPresenterRules()
  var count = 0
  mock.stub().title(id: .any).answers { id in
    count += 1
    return "Title \(id)"
  }
  #expect(mock.title(id: 42) == "Title 42")
  #expect(count == 1)
}

@Test func staticAndInstanceRulesHaveSeparateLifetimes() {
  defer { MockStaticRules.resetMock() }
  let mock = MockStaticRules()
  MockStaticRules.stub().value(id: .any).returns(42)
  mock.stub().value(id: .any).returns(7)
  #expect(MockStaticRules.value(id: 1) == 42)
  #expect(mock.value(id: 1) == 7)
  mock.resetMock()
  #expect(MockStaticRules.value(id: 1) == 42)
  MockStaticRules.resetMock()
  MockStaticRules.verify(mode: .never).value(id: mAny())
  MockStaticRules.stub().value(id: .any).returns(8)
  #expect(MockStaticRules.value(id: 1) == 8)
}

@Test func simpleStubbingDoesNotReserveTheStubMemberName() {
  let mock = MockSimpleStubMember()
  #expect(mock.stub == nil)
}
