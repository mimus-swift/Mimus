import FixtureContracts
import FixtureMocks
import Mimus
import Testing

@Test func keepsDefaultImplementationsThatCallStubbedRequirements() async throws {
  let mock = MockInventoryService()
  mock.simulatedQuantityOf = 12
  let inventory: any InventoryService = mock

  #expect(try await inventory.canReserve(itemID: "item-1", count: 3))
  #expect(try await !inventory.canReserve(itemID: "item-1", count: 13))
  mock.verify(mode: .times(2)).quantity(of: mEqual("item-1"))
}

@Test func propagatesStubbedErrorsThroughDefaultImplementations() async {
  let mock = MockInventoryService()
  mock.simulatedQuantityOfError = InventoryError.unavailable
  let inventory: any InventoryService = mock

  await #expect(throws: InventoryError.unavailable) {
    try await inventory.canReserve(itemID: "item-1", count: 3)
  }
  mock.verify().quantity(of: mEqual("item-1"))
}

@Test func simulatesRecordedEscapingResultCallbacks() throws {
  let mock = MockParcelDispatcher()
  let dispatcher: any ParcelDispatcher = mock
  var received: Result<Int, any Error>?
  dispatcher.dispatch("parcel-1") { received = $0 }

  mock.verify().dispatch(
    mEqual("parcel-1"), completion: mSimulateCallback(Result<Int, any Error>.success(7)))
  #expect(try received?.get() == 7)
}

@Test func returnsAnAsyncSequenceFromASendableHandler() async throws {
  let mock = MockMeasurementFeed()
  mock.simulatedSamplesHandler = {
    AsyncThrowingStream { continuation in
      continuation.yield(10)
      continuation.yield(20)
      continuation.finish()
    }
  }
  let feed: any MeasurementFeed = mock
  var received = [Int]()

  for try await value in feed.samples() { received.append(value) }
  #expect(received == [10, 20])
  mock.verify().samples()
}

@Test func preservesErrorsInStubbedAsyncSequences() async {
  let mock = MockMeasurementFeed()
  mock.simulatedSamples = AsyncThrowingStream { continuation in
    continuation.finish(throwing: InventoryError.unavailable)
  }
  let feed: any MeasurementFeed = mock

  await #expect(throws: InventoryError.unavailable) {
    for try await _ in feed.samples() {}
  }
  mock.verify().samples()
}
