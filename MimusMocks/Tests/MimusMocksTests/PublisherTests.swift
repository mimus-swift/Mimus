import Combine
import FixtureContracts
import FixtureMocks
import Foundation
import Mimus
import MimusMocks
import Testing

private enum StreamFailure: Error, Equatable { case offline }

@Mockable
private protocol StreamService {
  @MockPublisher
  var messages: AnyPublisher<String, StreamFailure> { get }

  @MockPublisher(initial: 0)
  var count: Combine.AnyPublisher<Int, Never> { get }

  @MimusMocks.MockPublisher(initial: nil)
  var selection: AnyPublisher<String?, Never> { get }

  var ordinary: AnyPublisher<Int, Never> { get }
  var ordinarySubject: String { get }
}

@Mockable(defaults: .fixtures)
private protocol FixtureStreamService {
  @MockPublisher(initial: 2)
  var value: AnyPublisher<Int, Never> { get }
}

@Mockable
private protocol StaticStreamService {
  @MockPublisher(initial: 5)
  static var value: AnyPublisher<Int, Never> { get }
}

@Mockable
private protocol ConcurrentStreamService: Sendable {
  @MockPublisher
  var events: AnyPublisher<Int, Never> { get }
}

@Mockable
private protocol ViewStateService {
  @MainActor
  @MockPublisher(initial: false)
  var isLoading: AnyPublisher<Bool, Never> { get }
}

@Mockable
private protocol ActorStreamService: Actor {
  @MockPublisher
  var events: AnyPublisher<Int, Never> { get }
}

extension MockActorStreamService {
  func receiveEventsInsideActor() -> [Int] {
    var values = [Int]()
    let subscription = events.sink { values.append($0) }
    defer { subscription.cancel() }
    eventsSubject.send(7)
    return values
  }
}

@Mockable
private protocol GenericStreamService {
  associatedtype Element
  associatedtype Failure: Error
  @MockPublisher
  var events: AnyPublisher<Element, Failure> { get }
}

@Test func passthroughPublishersDeliverOnlySubscribedEventsAndCompletion() {
  let mock = MockStreamService()
  mock.messagesSubject.send("before subscription")
  var values = [String]()
  var finished = false
  let subscription = mock.messages.sink(
    receiveCompletion: { if case .finished = $0 { finished = true } },
    receiveValue: { values.append($0) })
  defer { subscription.cancel() }
  #expect(values.isEmpty)
  mock.messagesSubject.send("first")
  mock.messagesSubject.send("second")
  mock.messagesSubject.send(completion: .finished)
  mock.messagesSubject.send("after completion")
  #expect(values == ["first", "second"])
  #expect(finished)
  #expect(mock.messagesSubject === mock.messagesSubject)
}

@Test func currentValuePublishersReplayTheLatestValue() {
  let mock = MockStreamService()
  var first = [Int]()
  var second = [Int]()
  let firstSubscription = mock.count.sink { first.append($0) }
  mock.countSubject.send(7)
  let secondSubscription = mock.count.sink { second.append($0) }
  defer {
    firstSubscription.cancel()
    secondSubscription.cancel()
  }
  #expect(first == [0, 7])
  #expect(second == [7])
  mock.countSubject.value = 9
  #expect(first == [0, 7, 9])
  #expect(second == [7, 9])
}

@Test func publisherInitialValuesCanBeNil() {
  let mock = MockStreamService()
  var values = [String?]()
  let subscription = mock.selection.sink { values.append($0) }
  defer { subscription.cancel() }
  mock.selectionSubject.send("chosen")
  mock.selectionSubject.send(nil)
  #expect(values == [nil, "chosen", nil])
}

@Test func publisherFailuresPreserveTheirDeclaredType() {
  let mock = MockStreamService()
  var error: StreamFailure?
  var values = [String]()
  let subscription = mock.messages.sink(
    receiveCompletion: { if case .failure(let failure) = $0 { error = failure } },
    receiveValue: { values.append($0) })
  defer { subscription.cancel() }
  mock.messagesSubject.send("first")
  mock.messagesSubject.send(completion: .failure(.offline))
  mock.messagesSubject.send("after failure")
  #expect(error == .offline)
  #expect(values == ["first"])
}

@Test func publisherSubjectsAreIndependentBetweenMocks() {
  let first = MockStreamService()
  let second = MockStreamService()
  var firstValues = [Int]()
  var secondValues = [Int]()
  let firstSubscription = first.count.sink { firstValues.append($0) }
  let secondSubscription = second.count.sink { secondValues.append($0) }
  defer {
    firstSubscription.cancel()
    secondSubscription.cancel()
  }
  first.countSubject.send(3)
  #expect(first.countSubject !== second.countSubject)
  #expect(firstValues == [0, 3])
  #expect(secondValues == [0])
}

@Test func resettingPublishersCreatesFreshSubjectsForFutureSubscriptions() {
  let mock = MockStreamService()
  let oldSubject = mock.countSubject
  var oldValues = [Int]()
  var newValues = [Int]()
  let oldSubscription = mock.count.sink { oldValues.append($0) }
  mock.countSubject.send(8)
  mock.resetMock()
  let newSubscription = mock.count.sink { newValues.append($0) }
  defer {
    oldSubscription.cancel()
    newSubscription.cancel()
  }
  #expect(mock.countSubject !== oldSubject)
  oldSubject.send(9)
  mock.countSubject.send(4)
  #expect(oldValues == [0, 8, 9])
  #expect(newValues == [0, 4])
}

@Test func configuredPublishersOverrideGeneratedSubjects() {
  let mock = MockStreamService()
  mock.count = Just(99).eraseToAnyPublisher()
  var values = [Int]()
  let subscription = mock.count.sink { values.append($0) }
  defer { subscription.cancel() }
  mock.countSubject.send(7)
  #expect(values == [99])
  mock.resetMock()
  var resetValues = [Int]()
  let resetSubscription = mock.count.sink { resetValues.append($0) }
  defer { resetSubscription.cancel() }
  #expect(resetValues == [0])
}

@Test func unannotatedPublishersKeepOrdinaryPropertyStubbing() {
  let mock = MockStreamService()
  mock.ordinarySubject = "consumer-owned property"
  mock.ordinary = Just(17).eraseToAnyPublisher()
  var values = [Int]()
  let subscription = mock.ordinary.sink { values.append($0) }
  defer { subscription.cancel() }
  #expect(mock.ordinarySubject == "consumer-owned property")
  #expect(values == [17])
}

@Test func explicitPublisherConfigurationOverridesTheFixturePolicy() {
  let mock = MockFixtureStreamService()
  var values = [Int]()
  let subscription = mock.value.sink { values.append($0) }
  defer { subscription.cancel() }
  mock.valueSubject.send(3)
  #expect(values == [2, 3])
}

@Test func staticPublisherSubjectsFollowStaticResetLifetime() {
  MockStaticStreamService.resetMock()
  defer { MockStaticStreamService.resetMock() }
  let oldSubject = MockStaticStreamService.valueSubject
  var values = [Int]()
  let subscription = MockStaticStreamService.value.sink { values.append($0) }
  defer { subscription.cancel() }
  MockStaticStreamService.valueSubject.send(6)
  #expect(values == [5, 6])
  MockStaticStreamService.resetMock()
  #expect(MockStaticStreamService.valueSubject !== oldSubject)
  #expect(MockStaticStreamService.valueSubject.value == 5)
}

@Test func concurrentFirstAccessesShareTheSamePublisherSubject() async {
  let mock = MockConcurrentStreamService()
  let identities = await withTaskGroup(of: ObjectIdentifier.self) { group in
    for _ in 0..<20 { group.addTask { ObjectIdentifier(mock.eventsSubject) } }
    var identities = Set<ObjectIdentifier>()
    for await identity in group { identities.insert(identity) }
    return identities
  }
  #expect(identities.count == 1)
}

@MainActor
@Test func publisherHelpersPreservePropertyActorIsolation() {
  let mock = MockViewStateService()
  var values = [Bool]()
  let subscription = mock.isLoading.sink { values.append($0) }
  defer { subscription.cancel() }
  mock.isLoadingSubject.send(true)
  #expect(values == [false, true])
}

@Test func publisherHelpersStayWithinTheirActor() async {
  let mock = MockActorStreamService()
  #expect(await mock.receiveEventsInsideActor() == [7])
}

@Test func publisherHelpersPreserveGenericOutputAndFailureTypes() {
  let mock = MockGenericStreamService<String, StreamFailure>()
  var values = [String]()
  var failure: StreamFailure?
  let subscription = mock.events.sink(
    receiveCompletion: { if case .failure(let error) = $0 { failure = error } },
    receiveValue: { values.append($0) })
  defer { subscription.cancel() }
  mock.eventsSubject.send("generic event")
  mock.eventsSubject.send(completion: .failure(.offline))
  #expect(values == ["generic event"])
  #expect(failure == .offline)
}

@Test func generatesOptInPublishersAcrossModuleBoundaries() {
  let mock = MockTelemetryChannel()
  let channel: any TelemetryChannel = mock
  var readings = [Int]()
  var events = [String]()
  var labels = [String?]()
  let readingsSubscription = channel.readings.sink { readings.append($0) }
  let eventsSubscription = channel.events.sink { events.append($0) }
  let labelsSubscription = channel.label.sink { labels.append($0) }
  defer {
    readingsSubscription.cancel()
    eventsSubscription.cancel()
    labelsSubscription.cancel()
  }
  mock.readingsSubject.send(11)
  mock.eventsSubject.send("connected")
  mock.labelSubject.send("sensor")
  #expect(readings == [10, 11])
  #expect(events == ["connected"])
  #expect(labels == [nil, "sensor"])
}
