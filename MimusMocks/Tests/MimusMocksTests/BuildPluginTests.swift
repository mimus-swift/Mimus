import FixtureContracts
import FixtureMocks
import Mimus
import Testing

@Test func generatesPublicMocksAcrossModuleBoundaries() async throws {
  let mock = MockChildService()
  mock.name = "Fixture service"
  mock.simulatedFetch = "Fixture response"
  let service: any ChildService = mock
  service.ping(value: 42)
  #expect(service.name == "Fixture service")
  #expect(try await service.fetch() == "Fixture response")
  #expect(service.parent() == nil)
  mock.verify().ping(value: mEqual(42))
  mock.verify().fetch()
}

@Test func preservesLegacySourceAnnotationsWithoutSourcery() {
  let mock = MockSelectionStore()
  let store: any SelectionStore = mock
  #expect(store.selection == nil)
  mock.selection = "Fixture selection"
  #expect(store.selection == "Fixture selection")
}
