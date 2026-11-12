import FixtureContracts
import FixtureMocks
import Mimus
import MimusMocks
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

@Test func generatesRuleBuildersForPublicAndInheritedRequirements() async throws {
  let mock = MockProductCatalog()
  let catalog: any ProductCatalog = mock
  mock.stub().name(id: .value(42)).returns("Selected")
  mock.stub().product(id: .value(42)).throws(.unavailable)
    .thenReturn(FixtureProduct(code: "empty"))
    .thenAnswer { id in .success(FixtureProduct(code: "product-\(id)")) }
  #expect(catalog.name(id: 42) == "Selected")
  #expect(try await catalog.product(id: 1) == .mock())
  await #expect(throws: CatalogFailure.unavailable) { try await catalog.hasStock(id: 42) }
  #expect(try await !catalog.hasStock(id: 42))
  #expect(try await catalog.hasStock(id: 42))
  mock.verify().name(id: mEqual(42))
  mock.verify(mode: .times(3)).product(id: mEqual(42))
  mock.resetMock()
  #expect(try await catalog.product(id: 42) == .mock())
}

@Test func generatesPublicCallControlsFromSourceAnnotations() async throws {
  let mock = MockProductCatalog()
  mock.productIdCalls.pause()
  let operation = Task { try await mock.product(id: 42) }
  try await mock.productIdCalls.waitForCall()
  mock.verify().product(id: mEqual(42))
  #expect(mock.name(id: 42) == "unnamed")
  try await mock.nameIdCalls.waitForCall()
  mock.productIdCalls.resume()
  #expect(try await operation.value == .mock())
}
