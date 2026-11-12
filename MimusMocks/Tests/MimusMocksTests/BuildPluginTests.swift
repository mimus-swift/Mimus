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

@Test func buildsFixtureDefaultsInADedicatedMocksModule() {
  let mock = MockStorefront()
  let storefront: any Storefront = mock
  #expect(storefront.featured == .mock())
  #expect(storefront.pair.main == .mock())
  #expect(storefront.pair.alternatives.0 == .mock())
  #expect(storefront.pair.alternatives.1 == .mock())
  #expect(storefront.load() == .mock())
  #expect(storefront.special.code == "special")
  #expect(storefront.specialProduct().code == "returned")
  #expect(storefront.formatter is MockLabelFormatter)
  #expect(storefront.optionalFormatter is MockLabelFormatter)
  #expect(storefront.formatter as AnyObject === storefront.formatter as AnyObject)
  mock.verify().load()
}
