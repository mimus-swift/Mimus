import Foundation
import Mimus
import MimusMocks
import Testing

private struct SampleProduct: Equatable, Sendable {
  let code: String
  static func mock() -> Self { Self(code: "standard") }
}

extension Bool {
  fileprivate static func mock() -> Bool { true }
}

extension Int {
  fileprivate static func mock() -> Int { 42 }
}

extension String {
  fileprivate static func mock() -> String { "sample" }
}

@Mockable
private protocol SampleCache: Sendable {
  func clear()
}

private enum SampleError: Error { case unavailable }

@Mockable(defaults: .fixtures)
private protocol FixtureService: Sendable {
  var product: SampleProduct { get }
  var summary: (primary: SampleProduct, metadata: (enabled: Bool, count: Int)) { get }
  var cache: any SampleCache { get }
  var products: [SampleProduct] { get }
  func load() throws -> SampleProduct
  func pair() -> (SampleProduct, String)
  func dependency() -> any SampleCache
  func identity<Value>(_ value: Value) -> Value
}

@Mockable
private protocol CustomDefaultsService {
  @MockDefault(.fixture)
  func load() -> SampleProduct

  @MockDefault(SampleProduct(code: "custom"))
  var product: SampleProduct { get }

  @MimusMocks.MockDefault("custom")
  var note: String? { get }

  @MockDefault(.nestedMock)
  func dependency() -> any SampleCache

  @MockDefault(.nestedMock)
  var optionalCache: Swift.Optional<any SampleCache> { get }

  @MockDefault((value: 17, text: "fixed"))
  func pair() -> (value: Int, text: String)

  @MockDefault(SampleProduct.mock())
  var asyncProduct: SampleProduct { get async throws }

  @MockDefault(SampleProduct.mock())
  subscript(_ index: Int) -> SampleProduct { get set }
}

@Mockable(defaults: .fixtures)
private protocol StaticFixtureService {
  static var product: SampleProduct { get }
  static func load() -> SampleProduct
}

@Test func buildsFixtureValuesAndNestedLabeledTuples() throws {
  let mock = MockFixtureService()
  #expect(mock.product == .mock())
  #expect(mock.summary.primary == .mock())
  #expect(mock.summary.metadata.enabled)
  #expect(mock.summary.metadata.count == 42)
  #expect(mock.products.isEmpty)
  #expect(try mock.load() == .mock())
  let pair = mock.pair()
  #expect(pair.0 == .mock())
  #expect(pair.1 == "sample")
  mock.verify().load()
  mock.verify().pair()
  mock.stubIdentity(7)
  #expect(mock.identity(1) == 7)
}

@Test func letsValuesHandlersAndErrorsOverrideFixtureDefaults() throws {
  let mock = MockFixtureService()
  #expect(try mock.load().code == "standard")
  mock.product = SampleProduct(code: "property override")
  #expect(mock.product.code == "property override")
  mock.simulatedLoad = SampleProduct(code: "value override")
  #expect(try mock.load().code == "value override")
  mock.simulatedLoadHandler = { SampleProduct(code: "handler override") }
  #expect(try mock.load().code == "handler override")
  mock.simulatedLoadHandler = nil
  mock.simulatedLoadError = SampleError.unavailable
  #expect(throws: SampleError.unavailable) { try mock.load() }
  mock.verify(mode: .times(4)).load()
}

@Test func cachesNestedMocksAndRecreatesThemAfterReset() {
  let mock = MockFixtureService()
  let cache = mock.cache as AnyObject
  let dependency = mock.dependency() as AnyObject
  #expect(mock.cache as AnyObject === cache)
  #expect(mock.dependency() as AnyObject === dependency)
  mock.resetMock()
  #expect(mock.cache as AnyObject !== cache)
  #expect(mock.dependency() as AnyObject !== dependency)
}

@Test func sharesOneNestedDefaultAcrossConcurrentFirstReads() async {
  let mock = MockFixtureService()
  let identities = await withTaskGroup(of: ObjectIdentifier.self) { group in
    for _ in 0..<30 {
      group.addTask { ObjectIdentifier(mock.cache as AnyObject) }
    }
    var identities = Set<ObjectIdentifier>()
    for await identity in group { identities.insert(identity) }
    return identities
  }
  #expect(identities.count == 1)
}

@Test func supportsExplicitDefaultsWithoutAProtocolWidePolicy() async throws {
  let mock = MockCustomDefaultsService()
  #expect(mock.load() == .mock())
  #expect(mock.product.code == "custom")
  #expect(mock.note == "custom")
  mock.note = nil
  #expect(mock.note == nil)
  mock.resetMock()
  #expect(mock.note == "custom")
  let cache = mock.dependency() as AnyObject
  #expect(mock.dependency() as AnyObject === cache)
  #expect(mock.optionalCache is MockSampleCache)
  mock.optionalCache = nil
  #expect(mock.optionalCache == nil)
  #expect(mock.pair().value == 17)
  #expect(mock.pair().text == "fixed")
  #expect(try await mock.asyncProduct == .mock())
  #expect(mock[1] == .mock())
  mock[1] = SampleProduct(code: "indexed override")
  #expect(mock[1].code == "indexed override")
}

@Test func supportsStaticFixtureDefaults() {
  MockStaticFixtureService.resetMock()
  defer { MockStaticFixtureService.resetMock() }
  #expect(MockStaticFixtureService.product == .mock())
  #expect(MockStaticFixtureService.load() == .mock())
  MockStaticFixtureService.simulatedLoad = SampleProduct(code: "static override")
  #expect(MockStaticFixtureService.load().code == "static override")
  MockStaticFixtureService.verify(mode: .times(2)).load()
}

@Test func evaluatesDefaultFactoriesOnceAndAllowsOtherStateReads() {
  let state = MockState()
  var calls = 0
  func makeValue() -> Int {
    calls += 1
    return state.value(for: "base", default: { 20 }) + 1
  }
  #expect(state.value(for: "answer", default: makeValue) == 21)
  #expect(state.value(for: "answer", default: makeValue) == 21)
  #expect(calls == 1)
  state.set(99, for: "answer")
  #expect(state.value(for: "answer", default: makeValue) == 99)
  #expect(calls == 1)
  state.reset()
  #expect(state.value(for: "answer", default: makeValue) == 21)
  #expect(calls == 2)
}
