public struct FixtureProduct: Equatable, Sendable {
  public let code: String
  public init(code: String) { self.code = code }
}

// mimus: mockable
public protocol LabelFormatter: Sendable {
  func format()
}

// mimus: mockable
// mimus: defaults = "fixtures"
public protocol Storefront: Sendable {
  var featured: FixtureProduct { get }
  var pair: (main: FixtureProduct, alternatives: (FixtureProduct, FixtureProduct)) { get }
  var formatter: LabelFormatter { get }
  func load() -> FixtureProduct

  // sourcery: mockValue = "FixtureProduct(code: \"special\")"
  var special: FixtureProduct { get }

  // mimus: default = "FixtureProduct(code: \"returned\")"
  func specialProduct() -> FixtureProduct

  // sourcery: forceMock
  var optionalFormatter: LabelFormatter? { get }
}
